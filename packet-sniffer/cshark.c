// cshark.c - C-Shark Packet Sniffer with Storage and Inspection

#define __FAVOR_BSD

#include <stdio.h>
#include <stdlib.h>
#include <pcap.h>
#ifndef u_char
typedef unsigned char u_char;
#endif
#include <signal.h>
#include <string.h>
#include <time.h>

#include "cshark.h"

// Global variables (definitions)
volatile int keep_sniffing = 1;

void handle_sigint(int sig) {
    (void)sig;
    keep_sniffing = 0;
}

void print_hex(const u_char *data, int len) {
    for (int i = 0; i < len; ++i) {
        printf("%02X ", data[i]);
    }
    for (int i = len; i < 16; ++i) printf("   ");
    printf("\n");
}

// Global storage (definitions)
stored_packet *packet_storage = NULL;
int stored_packet_count = 0;
int session_exists = 0;

char selected_iface[256] = "";

// Free previous session packets
void free_packet_storage() {
    if (packet_storage != NULL) {
        for (int i = 0; i < stored_packet_count; i++) {
            if (packet_storage[i].packet_data != NULL) {
                free(packet_storage[i].packet_data);
            }
        }
        free(packet_storage);
        packet_storage = NULL;
    }
    stored_packet_count = 0;
}

// Initialize new session storage
void init_packet_storage() {
    free_packet_storage();
    packet_storage = (stored_packet *)malloc(MAX_PACKETS * sizeof(stored_packet));
    if (packet_storage == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory for packet storage\n");
        exit(1);
    }
    stored_packet_count = 0;
    session_exists = 1;
}

// Store a packet
void store_packet(const struct pcap_pkthdr *header, const u_char *packet, int pkt_id) {
    if (stored_packet_count >= MAX_PACKETS) {
        return; // Storage full
    }
    
    packet_storage[stored_packet_count].header = *header;
    packet_storage[stored_packet_count].packet_data = (u_char *)malloc(header->caplen);
    if (packet_storage[stored_packet_count].packet_data == NULL) {
        fprintf(stderr, "Warning: Failed to allocate memory for packet %d\n", pkt_id);
        return;
    }
    memcpy(packet_storage[stored_packet_count].packet_data, packet, header->caplen);
    packet_storage[stored_packet_count].packet_id = pkt_id;
    stored_packet_count++;
}

int list_interfaces() {
    pcap_if_t *alldevs, *d;
    char errbuf[PCAP_ERRBUF_SIZE];
    int i = 0;
    iface_info ifaces[MAX_INTERFACES];

    printf("[C-Shark] Searching for available interfaces... ");
    if (pcap_findalldevs(&alldevs, errbuf) == -1) {
        printf("Failed!\nError: %s\n", errbuf);
        exit(1);
    }
    printf("Found!\n\n");

    for (d = alldevs; d != NULL && i < MAX_INTERFACES; d = d->next) {
        strncpy(ifaces[i].name, d->name, sizeof(ifaces[i].name)-1);
        ifaces[i].name[sizeof(ifaces[i].name)-1] = '\0';
        if (d->description) {
            strncpy(ifaces[i].desc, d->description, sizeof(ifaces[i].desc)-1);
            ifaces[i].desc[sizeof(ifaces[i].desc)-1] = '\0';
        } else {
            ifaces[i].desc[0] = '\0';
        }
        printf("%2d. %s", i + 1, ifaces[i].name);
        if (ifaces[i].desc[0])
            printf(" (%s)", ifaces[i].desc);
        printf("\n");
        i++;
    }
    if (i == 0) {
        printf("No interfaces found.\n");
        pcap_freealldevs(alldevs);
        exit(1);
    }

    int choice = 0;
    printf("\nSelect an interface to sniff (1-%d): ", i);
    while (scanf("%d", &choice) != 1 || choice < 1 || choice > i) {
        if (feof(stdin)) {
            printf("\n[C-Shark] Exiting.\n");
            pcap_freealldevs(alldevs);
            exit(0);
        }
        printf("Invalid input. Please enter a number between 1 and %d: ", i);
        while (getchar() != '\n'); // clear input buffer
    }

    strncpy(selected_iface, ifaces[choice-1].name, sizeof(selected_iface)-1);
    selected_iface[sizeof(selected_iface)-1] = '\0';

    printf("\n[C-Shark] Interface '%s' selected.\n", selected_iface);

    pcap_freealldevs(alldevs);
    return 0;
}

#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/ip6.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <net/if_arp.h>
#include <arpa/inet.h>

void print_mac(const u_char *mac) {
    for (int i = 0; i < 6; ++i) {
        printf("%02X", mac[i]);
        if (i != 5) printf(":");
    }
}

void print_hex_dump(const u_char *data, int len, int bytes_per_line) {
    for (int i = 0; i < len; i += bytes_per_line) {
        printf("%04X:  ", i);
        
        // Hex portion
        for (int j = 0; j < bytes_per_line; j++) {
            if (i + j < len) {
                printf("%02X ", data[i + j]);
            } else {
                printf("   ");
            }
            if (j == bytes_per_line / 2 - 1) printf(" ");
        }
        
        printf(" |  ");
        
        // ASCII portion
        for (int j = 0; j < bytes_per_line && i + j < len; j++) {
            unsigned char c = data[i + j];
            printf("%c", (c >= 32 && c <= 126) ? c : '.');
        }
        printf("\n");
    }
}

void process_packet(const struct pcap_pkthdr *header, const u_char *packet, int *pkt_id, int store) {
    struct tm *ltime;
    char timestr[64];
    time_t local_tv_sec = header->ts.tv_sec;
    ltime = localtime(&local_tv_sec);
    strftime(timestr, sizeof timestr, "%H:%M:%S", ltime);
    printf("-----------------------------------------\n");
    printf("Packet #%d | Timestamp: %s.%06ld | Length: %d bytes\n",
           *pkt_id, timestr, header->ts.tv_usec, header->caplen);

    // Store packet if requested
    if (store) {
        store_packet(header, packet, *pkt_id);
    }
    (*pkt_id)++;

    // Layer 2: Ethernet header
    uint16_t eth_type = 0;
    if (header->caplen >= 14) {
        const struct ether_header *eth = (const struct ether_header *)packet;
        printf("L2 (Ethernet): Dst MAC: ");
        print_mac(eth->ether_dhost);
        printf(" | Src MAC: ");
        print_mac(eth->ether_shost);
        printf(" | EtherType: ");
        eth_type = ntohs(eth->ether_type);
        switch (eth_type) {
            case ETHERTYPE_IP:
                printf("IPv4 (0x0800)");
                break;
            case ETHERTYPE_IPV6:
                printf("IPv6 (0x86DD)");
                break;
            case ETHERTYPE_ARP:
                printf("ARP (0x0806)");
                break;
            default:
                printf("Unknown (0x%04X)", eth_type);
        }
        printf("\n");
    } else {
        printf("L2 (Ethernet): Packet too short for Ethernet header\n");
    }

    // Layer 3: Network Layer
    int l4_proto = -1;
    int l4_offset = 0;
    int l4_len = 0;
    char l3_src[INET6_ADDRSTRLEN] = "", l3_dst[INET6_ADDRSTRLEN] = "";
    if (header->caplen >= 14) {
        const u_char *l3 = packet + 14;
        int l3_len = header->caplen - 14;
        if (eth_type == ETHERTYPE_IP && l3_len >= (int)sizeof(struct iphdr)) {
            const struct iphdr *iph = (const struct iphdr *)l3;
            struct in_addr saddr, daddr;
            saddr.s_addr = iph->saddr;
            daddr.s_addr = iph->daddr;
            inet_ntop(AF_INET, &saddr, l3_src, sizeof(l3_src));
            inet_ntop(AF_INET, &daddr, l3_dst, sizeof(l3_dst));
            printf("L3 (IPv4): Src IP: %s | Dst IP: %s | Protocol: ", l3_src, l3_dst);
            switch (iph->protocol) {
                case 6: printf("TCP (6)"); break;
                case 17: printf("UDP (17)"); break;
                default: printf("Unknown (%d)", iph->protocol);
            }
            printf(" | TTL: %d\n", iph->ttl);
            printf("ID: 0x%04X | Total Length: %d | Header Length: %d bytes\n",
                ntohs(iph->id), ntohs(iph->tot_len), iph->ihl * 4);
            // Flags
            int flags = ntohs(iph->frag_off) & 0xE000;
            printf("Flags: ");
            if (flags & 0x8000) printf("[Reserved] ");
            if (flags & 0x4000) printf("[DF] ");
            if (flags & 0x2000) printf("[MF] ");
            if (!(flags & 0xE000)) printf("[None] ");
            printf("\n");
            l4_proto = iph->protocol;
            l4_offset = iph->ihl * 4;
            l4_len = l3_len - l4_offset;
        } else if (eth_type == ETHERTYPE_IPV6 && l3_len >= (int)sizeof(struct ip6_hdr)) {
            const struct ip6_hdr *ip6h = (const struct ip6_hdr *)l3;
            inet_ntop(AF_INET6, &ip6h->ip6_src, l3_src, sizeof(l3_src));
            inet_ntop(AF_INET6, &ip6h->ip6_dst, l3_dst, sizeof(l3_dst));
            printf("L3 (IPv6): Src IP: %s | Dst IP: %s | Next Header: ", l3_src, l3_dst);
            switch (ip6h->ip6_nxt) {
                case 6: printf("TCP (6)"); break;
                case 17: printf("UDP (17)"); break;
                default: printf("Unknown (%d)", ip6h->ip6_nxt);
            }
            printf(" | Hop Limit: %d\n", ip6h->ip6_hlim);
            uint32_t flow = ntohl(*(uint32_t *)ip6h) & 0x000FFFFF;
            uint8_t tclass = (ntohl(*(uint32_t *)ip6h) & 0x0FF00000) >> 20;
            printf("Traffic Class: %d | Flow Label: 0x%05X | Payload Length: %d\n",
                tclass, flow, ntohs(ip6h->ip6_plen));
            l4_proto = ip6h->ip6_nxt;
            l4_offset = sizeof(struct ip6_hdr);
            l4_len = l3_len - l4_offset;
        } else if (eth_type == ETHERTYPE_ARP && l3_len >= (int)sizeof(struct arphdr)) {
            const struct arphdr *arph = (const struct arphdr *)l3;
            uint16_t op = ntohs(*(uint16_t *)(l3 + 6));
            printf("L3 (ARP): Operation: ");
            if (op == 1) printf("Request (1)");
            else if (op == 2) printf("Reply (2)");
            else printf("Unknown (%d)", op);
            // Hardware/Protocol types/lengths
            printf(" | HW Type: %d | Proto Type: 0x%04X | HW Len: %d | Proto Len: %d\n",
                ntohs(arph->ar_hrd), ntohs(arph->ar_pro), arph->ar_hln, arph->ar_pln);
            // Sender/Target MAC/IP
            const u_char *arp_ptr = l3 + 8;
            printf("Sender MAC: "); print_mac(arp_ptr); printf(" | ");
            printf("Sender IP: %d.%d.%d.%d\n", arp_ptr[6], arp_ptr[7], arp_ptr[8], arp_ptr[9]);
            printf("Target MAC: "); print_mac(arp_ptr+10); printf(" | ");
            printf("Target IP: %d.%d.%d.%d\n",
                arp_ptr[16], arp_ptr[17], arp_ptr[18], arp_ptr[19]);
        }
    }

    // Layer 4: TCP/UDP header decoding
    int l7_offset = 0;
    int l7_len = 0;
    uint16_t l7_src_port = 0, l7_dst_port = 0;
    int l7_proto = 0; // 1=TCP, 2=UDP
    if (l4_proto == 6 && l4_len >= 20) { // TCP
        const u_char *l4 = packet + 14 + l4_offset;
        uint16_t src_port = ntohs(*(uint16_t *)(l4));
        uint16_t dst_port = ntohs(*(uint16_t *)(l4 + 2));
        uint32_t seq = ntohl(*(uint32_t *)(l4 + 4));
        uint32_t ack = ntohl(*(uint32_t *)(l4 + 8));
        uint8_t data_offset = ((l4[12] & 0xF0) >> 4) * 4;
        uint8_t flags = l4[13];
        uint16_t checksum = ntohs(*(uint16_t *)(l4 + 16));
        
        printf("L4 (TCP): Src Port: %u", src_port);
        // Identify common ports
        if (src_port == 80) printf(" (HTTP)");
        else if (src_port == 443) printf(" (HTTPS)");
        else if (src_port == 22) printf(" (SSH)");
        else if (src_port == 25) printf(" (SMTP)");
        else if (src_port == 110) printf(" (POP3)");
        else if (src_port == 143) printf(" (IMAP)");
        else if (src_port == 21) printf(" (FTP)");
        else if (src_port == 23) printf(" (TELNET)");
        else if (src_port == 53) printf(" (DNS)");
        
        printf(" | Dst Port: %u", dst_port);
        if (dst_port == 80) printf(" (HTTP)");
        else if (dst_port == 443) printf(" (HTTPS)");
        else if (dst_port == 22) printf(" (SSH)");
        else if (dst_port == 25) printf(" (SMTP)");
        else if (dst_port == 110) printf(" (POP3)");
        else if (dst_port == 143) printf(" (IMAP)");
        else if (dst_port == 21) printf(" (FTP)");
        else if (dst_port == 23) printf(" (TELNET)");
        else if (dst_port == 53) printf(" (DNS)");
        
        printf(" | Seq: %u | Ack: %u\n", seq, ack);
        printf("Flags: ");
        if (flags & 0x01) printf("FIN ");
        if (flags & 0x02) printf("SYN ");
        if (flags & 0x04) printf("RST ");
        if (flags & 0x08) printf("PSH ");
        if (flags & 0x10) printf("ACK ");
        if (flags & 0x20) printf("URG ");
        if (flags & 0x40) printf("ECE ");
        if (flags & 0x80) printf("CWR ");
        printf("| Window: %u | Checksum: 0x%04X | Data Offset: %u bytes\n", 
               ntohs(*(uint16_t *)(l4 + 14)), checksum, data_offset);
        l7_offset = 14 + l4_offset + data_offset;
        l7_len = header->caplen - l7_offset;
        l7_src_port = src_port;
        l7_dst_port = dst_port;
        l7_proto = 1;
    } else if (l4_proto == 17 && l4_len >= 8) { // UDP
        const u_char *l4 = packet + 14 + l4_offset;
        uint16_t src_port = ntohs(*(uint16_t *)(l4));
        uint16_t dst_port = ntohs(*(uint16_t *)(l4 + 2));
        uint16_t len = ntohs(*(uint16_t *)(l4 + 4));
        uint16_t checksum = ntohs(*(uint16_t *)(l4 + 6));
        
        printf("L4 (UDP): Src Port: %u", src_port);
        if (src_port == 53) printf(" (DNS)");
        else if (src_port == 67 || src_port == 68) printf(" (DHCP)");
        else if (src_port == 123) printf(" (NTP)");
        else if (src_port == 69) printf(" (TFTP)");
        
        printf(" | Dst Port: %u", dst_port);
        if (dst_port == 53) printf(" (DNS)");
        else if (dst_port == 67 || dst_port == 68) printf(" (DHCP)");
        else if (dst_port == 123) printf(" (NTP)");
        else if (dst_port == 69) printf(" (TFTP)");
        
        printf(" | Length: %u | Checksum: 0x%04X\n", len, checksum);
        l7_offset = 14 + l4_offset + 8;
        l7_len = header->caplen - l7_offset;
        l7_src_port = src_port;
        l7_dst_port = dst_port;
        l7_proto = 2;
    }

    // Layer 7: Application protocol and payload
    if (l7_len > 0 && l7_offset < (int)header->caplen) {
        const u_char *l7 = packet + l7_offset;
        // Identify protocol by port
        const char *proto = "Unknown";
        uint16_t port = l7_src_port;
        uint16_t dport = l7_dst_port;
        if (l7_proto == 1) { // TCP
            if (port == 80 || dport == 80) proto = "HTTP";
            else if (port == 443 || dport == 443) proto = "HTTPS";
            else if (port == 22 || dport == 22) proto = "SSH";
            else if (port == 25 || dport == 25) proto = "SMTP";
            else if (port == 110 || dport == 110) proto = "POP3";
            else if (port == 143 || dport == 143) proto = "IMAP";
            else if (port == 21 || dport == 21) proto = "FTP";
            else if (port == 23 || dport == 23) proto = "TELNET";
            else if (port == 53 || dport == 53) proto = "DNS";
        } else if (l7_proto == 2) { // UDP
            if (port == 53 || dport == 53) proto = "DNS";
            else if (port == 67 || dport == 67 || port == 68 || dport == 68) proto = "DHCP";
            else if (port == 123 || dport == 123) proto = "NTP";
            else if (port == 69 || dport == 69) proto = "TFTP";
        }
        printf("L7 (App): Protocol: %s | Payload (%d bytes):\n", proto, l7_len > 64 ? 64 : l7_len);
        // Print first 64 bytes as hex
        int show = l7_len > 64 ? 64 : l7_len;
        printf("  Hex:   ");
        for (int i = 0; i < show; ++i) printf("%02X ", l7[i]);
        for (int i = show; i < 64; ++i) printf("   ");
        printf("\n  ASCII: ");
        for (int i = 0; i < show; ++i) printf("%c", (l7[i] >= 32 && l7[i] <= 126) ? l7[i] : '.');
        printf("\n");
    }

    printf("First 16 bytes: ");
    print_hex(packet, header->caplen < 16 ? header->caplen : 16);
}

void sniff_all_packets(const char *iface) {
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle;
    struct pcap_pkthdr *header;
    const u_char *packet;
    int res;
    int pkt_id = 1;

    // Initialize storage for new session
    init_packet_storage();

    printf("\n[C-Shark] Starting live capture on '%s'. Press Ctrl+C to stop.\n\n", iface);

    handle = pcap_open_live(iface, SNAPLEN, PROMISC, TIMEOUT_MS, errbuf);
    if (!handle) {
        printf("Error opening device: %s\n", errbuf);
        return;
    }

    keep_sniffing = 1;
    signal(SIGINT, handle_sigint);

    while (keep_sniffing && (res = pcap_next_ex(handle, &header, &packet)) >= 0) {
        if (res == 0) continue; // Timeout elapsed
        process_packet(header, packet, &pkt_id, 1); // 1 = store packet
    }

    if (!keep_sniffing)
        printf("\n[C-Shark] Capture stopped. %d packets stored. Returning to main menu.\n", stored_packet_count);
    else
        printf("\n[C-Shark] Capture ended or error occurred.\n");

    signal(SIGINT, SIG_DFL);
    pcap_close(handle);
}

void sniff_with_filter(const char *iface) {
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle;
    struct pcap_pkthdr *header;
    const u_char *packet;
    int res;
    int pkt_id = 1;

    printf("\n[C-Shark] Filter Options:\n");
    printf("1. HTTP (port 80)\n");
    printf("2. HTTPS (port 443)\n");
    printf("3. DNS (port 53)\n");
    printf("4. ARP\n");
    printf("5. TCP (all TCP packets)\n");
    printf("6. UDP (all UDP packets)\n");
    printf("\nSelect a filter (1-6): ");
    
    int filter_choice;
    if (scanf("%d", &filter_choice) == EOF) {
        printf("\n[C-Shark] Returning to main menu.\n");
        while (getchar() != '\n');
        return;
    }
    while (getchar() != '\n'); // clear input buffer

    const char *filter_str = NULL;
    const char *filter_name = NULL;

    switch (filter_choice) {
        case 1:
            filter_str = "tcp port 80";
            filter_name = "HTTP";
            break;
        case 2:
            filter_str = "tcp port 443";
            filter_name = "HTTPS";
            break;
        case 3:
            filter_str = "port 53";
            filter_name = "DNS";
            break;
        case 4:
            filter_str = "arp";
            filter_name = "ARP";
            break;
        case 5:
            filter_str = "tcp";
            filter_name = "TCP";
            break;
        case 6:
            filter_str = "udp";
            filter_name = "UDP";
            break;
        default:
            printf("Invalid filter choice. Returning to main menu.\n");
            return;
    }

    // Initialize storage for new session
    init_packet_storage();

    printf("\n[C-Shark] Starting filtered capture on '%s' (Filter: %s). Press Ctrl+C to stop.\n\n", 
           iface, filter_name);

    handle = pcap_open_live(iface, SNAPLEN, PROMISC, TIMEOUT_MS, errbuf);
    if (!handle) {
        printf("Error opening device: %s\n", errbuf);
        return;
    }

    // Compile and apply the filter
    struct bpf_program fp;
    bpf_u_int32 net, mask;
    
    if (pcap_lookupnet(iface, &net, &mask, errbuf) == -1) {
        fprintf(stderr, "Warning: Can't get netmask for device %s: %s\n", iface, errbuf);
        net = 0;
        mask = 0;
    }

    if (pcap_compile(handle, &fp, filter_str, 0, net) == -1) {
        fprintf(stderr, "Error: Couldn't parse filter %s: %s\n", filter_str, pcap_geterr(handle));
        pcap_close(handle);
        return;
    }

    if (pcap_setfilter(handle, &fp) == -1) {
        fprintf(stderr, "Error: Couldn't install filter %s: %s\n", filter_str, pcap_geterr(handle));
        pcap_freecode(&fp);
        pcap_close(handle);
        return;
    }

    pcap_freecode(&fp);

    keep_sniffing = 1;
    signal(SIGINT, handle_sigint);

    while (keep_sniffing && (res = pcap_next_ex(handle, &header, &packet)) >= 0) {
        if (res == 0) continue; // Timeout elapsed
        process_packet(header, packet, &pkt_id, 1); // 1 = store packet
    }

    if (!keep_sniffing)
        printf("\n[C-Shark] Filtered capture stopped. %d packets stored. Returning to main menu.\n", stored_packet_count);
    else
        printf("\n[C-Shark] Capture ended or error occurred.\n");

    signal(SIGINT, SIG_DFL);
    pcap_close(handle);
}

void get_protocol_info(const u_char *packet, int caplen, char *proto_str, size_t proto_str_size) {
    if (caplen < 14) {
        snprintf(proto_str, proto_str_size, "Unknown");
        return;
    }

    const struct ether_header *eth = (const struct ether_header *)packet;
    uint16_t eth_type = ntohs(eth->ether_type);
    
    if (eth_type == ETHERTYPE_ARP) {
        snprintf(proto_str, proto_str_size, "ARP");
        return;
    }
    
    if (eth_type == ETHERTYPE_IP && caplen >= 34) {
        const struct iphdr *iph = (const struct iphdr *)(packet + 14);
        if (iph->protocol == 6) { // TCP
            const u_char *tcp = packet + 14 + (iph->ihl * 4);
            if (caplen >= 14 + (iph->ihl * 4) + 4) {
                uint16_t sport = ntohs(*(uint16_t *)(tcp));
                uint16_t dport = ntohs(*(uint16_t *)(tcp + 2));
                if (sport == 80 || dport == 80) snprintf(proto_str, proto_str_size, "HTTP");
                else if (sport == 443 || dport == 443) snprintf(proto_str, proto_str_size, "HTTPS");
                else if (sport == 53 || dport == 53) snprintf(proto_str, proto_str_size, "DNS");
                else snprintf(proto_str, proto_str_size, "TCP");
            } else {
                snprintf(proto_str, proto_str_size, "TCP");
            }
        } else if (iph->protocol == 17) { // UDP
            const u_char *udp = packet + 14 + (iph->ihl * 4);
            if (caplen >= 14 + (iph->ihl * 4) + 4) {
                uint16_t sport = ntohs(*(uint16_t *)(udp));
                uint16_t dport = ntohs(*(uint16_t *)(udp + 2));
                if (sport == 53 || dport == 53) snprintf(proto_str, proto_str_size, "DNS");
                else if (sport == 67 || dport == 67 || sport == 68 || dport == 68) 
                    snprintf(proto_str, proto_str_size, "DHCP");
                else snprintf(proto_str, proto_str_size, "UDP");
            } else {
                snprintf(proto_str, proto_str_size, "UDP");
            }
        } else {
            snprintf(proto_str, proto_str_size, "IPv4");
        }
    } else if (eth_type == ETHERTYPE_IPV6 && caplen >= 54) {
        const struct ip6_hdr *ip6h = (const struct ip6_hdr *)(packet + 14);
        if (ip6h->ip6_nxt == 6) { // TCP
            const u_char *tcp = packet + 14 + sizeof(struct ip6_hdr);
            if (caplen >= (int)(14 + sizeof(struct ip6_hdr) + 4)) {
                uint16_t sport = ntohs(*(uint16_t *)(tcp));
                uint16_t dport = ntohs(*(uint16_t *)(tcp + 2));
                if (sport == 80 || dport == 80) snprintf(proto_str, proto_str_size, "HTTP");
                else if (sport == 443 || dport == 443) snprintf(proto_str, proto_str_size, "HTTPS");
                else if (sport == 53 || dport == 53) snprintf(proto_str, proto_str_size, "DNS");
                else snprintf(proto_str, proto_str_size, "TCP");
            } else {
                snprintf(proto_str, proto_str_size, "TCP");
            }
        } else if (ip6h->ip6_nxt == 17) { // UDP
            const u_char *udp = packet + 14 + sizeof(struct ip6_hdr);
            if (caplen >= (int)(14 + sizeof(struct ip6_hdr) + 4)) {
                uint16_t sport = ntohs(*(uint16_t *)(udp));
                uint16_t dport = ntohs(*(uint16_t *)(udp + 2));
                if (sport == 53 || dport == 53) snprintf(proto_str, proto_str_size, "DNS");
                else if (sport == 67 || dport == 67 || sport == 68 || dport == 68) 
                    snprintf(proto_str, proto_str_size, "DHCP");
                else snprintf(proto_str, proto_str_size, "UDP");
            } else {
                snprintf(proto_str, proto_str_size, "UDP");
            }
        } else {
            snprintf(proto_str, proto_str_size, "IPv6");
        }
    } else {
        snprintf(proto_str, proto_str_size, "Unknown");
    }
}

void get_src_dst_ips(const u_char *packet, int caplen, char *src_ip, char *dst_ip, size_t ip_size) {
    src_ip[0] = '\0';
    dst_ip[0] = '\0';
    
    if (caplen < 14) return;

    const struct ether_header *eth = (const struct ether_header *)packet;
    uint16_t eth_type = ntohs(eth->ether_type);
    
    if (eth_type == ETHERTYPE_IP && caplen >= 34) {
        const struct iphdr *iph = (const struct iphdr *)(packet + 14);
        struct in_addr saddr, daddr;
        saddr.s_addr = iph->saddr;
        daddr.s_addr = iph->daddr;
        inet_ntop(AF_INET, &saddr, src_ip, ip_size);
        inet_ntop(AF_INET, &daddr, dst_ip, ip_size);
    } else if (eth_type == ETHERTYPE_IPV6 && caplen >= 54) {
        const struct ip6_hdr *ip6h = (const struct ip6_hdr *)(packet + 14);
        inet_ntop(AF_INET6, &ip6h->ip6_src, src_ip, ip_size);
        inet_ntop(AF_INET6, &ip6h->ip6_dst, dst_ip, ip_size);
    }
}

void inspect_last_session() {
    if (!session_exists || stored_packet_count == 0) {
        printf("\n[C-Shark] Error: No session data available. Please run a capture first.\n");
        return;
    }

    printf("\n[C-Shark] Last Session Summary (%d packets stored)\n", stored_packet_count);
    printf("================================================================================\n");
    printf("%-8s %-20s %-10s %-15s %-15s %-10s\n", 
           "ID", "Timestamp", "Length", "Src IP", "Dst IP", "Protocol");
    printf("--------------------------------------------------------------------------------\n");

    for (int i = 0; i < stored_packet_count; i++) {
        struct tm *ltime;
        char timestr[64];
        time_t local_tv_sec = packet_storage[i].header.ts.tv_sec;
        ltime = localtime(&local_tv_sec);
        strftime(timestr, sizeof timestr, "%H:%M:%S", ltime);
        
        char proto_str[32];
        get_protocol_info(packet_storage[i].packet_data, packet_storage[i].header.caplen, 
                         proto_str, sizeof(proto_str));
        
        char src_ip[INET6_ADDRSTRLEN], dst_ip[INET6_ADDRSTRLEN];
        get_src_dst_ips(packet_storage[i].packet_data, packet_storage[i].header.caplen,
                       src_ip, dst_ip, INET6_ADDRSTRLEN);
        
        // Truncate long IPs for display
        if (strlen(src_ip) > 15) {
            src_ip[12] = '.';
            src_ip[13] = '.';
            src_ip[14] = '.';
            src_ip[15] = '\0';
        }
        if (strlen(dst_ip) > 15) {
            dst_ip[12] = '.';
            dst_ip[13] = '.';
            dst_ip[14] = '.';
            dst_ip[15] = '\0';
        }
        
        printf("%-8d %-20s %-10u %-15s %-15s %-10s\n",
               packet_storage[i].packet_id,
               timestr,
               packet_storage[i].header.caplen,
               src_ip[0] ? src_ip : "N/A",
               dst_ip[0] ? dst_ip : "N/A",
               proto_str);
    }
    
    printf("================================================================================\n");
    printf("\nEnter Packet ID to inspect (or 0 to return to menu): ");
    
    int pkt_id;
    if (scanf("%d", &pkt_id) == EOF) {
        printf("\n[C-Shark] Returning to main menu.\n");
        while (getchar() != '\n');
        return;
    }
    while (getchar() != '\n');
    
    if (pkt_id == 0) {
        printf("[C-Shark] Returning to main menu.\n");
        return;
    }
    
    // Find the packet
    int found = -1;
    for (int i = 0; i < stored_packet_count; i++) {
        if (packet_storage[i].packet_id == pkt_id) {
            found = i;
            break;
        }
    }
    
    if (found == -1) {
        printf("\n[C-Shark] Error: Packet ID %d not found in storage.\n", pkt_id);
        return;
    }
    
    // Display detailed inspection
    printf("\n");
    printf("================================================================================\n");
    printf("                    DETAILED PACKET INSPECTION - Packet #%d\n", pkt_id);
    printf("================================================================================\n");
    printf("\n");
    
    stored_packet *pkt = &packet_storage[found];
    int tmp_id = pkt_id;
    
    // Display full packet analysis
    process_packet(&pkt->header, pkt->packet_data, &tmp_id, 0); // 0 = don't store again
    
    // Display full hex dump
    printf("\n");
    printf("=== COMPLETE HEX DUMP (%u bytes) ===\n", pkt->header.caplen);
    print_hex_dump(pkt->packet_data, pkt->header.caplen, 16);
    
    printf("\n");
    printf("================================================================================\n");
    printf("                         END OF PACKET INSPECTION\n");
    printf("================================================================================\n");
    
    // Ask if user wants to inspect another packet
    printf("\nInspect another packet? (y/n): ");
    char choice;
    if (scanf(" %c", &choice) == EOF) {
        while (getchar() != '\n');
        return;
    }
    while (getchar() != '\n');
    
    if (choice == 'y' || choice == 'Y') {
        inspect_last_session();
    }
}

int main_menu() {
    while (1) {
        printf("\n[C-Shark] Interface '%s' selected. What's next?\n", selected_iface);
        printf("\n1. Start Sniffing (All Packets)\n");
        printf("2. Start Sniffing (With Filters)\n");
        printf("3. Inspect Last Session\n");
        printf("4. Change Interface\n");
        printf("5. Exit C-Shark\n");
        printf("\nEnter your choice: ");
        int choice;
        if (scanf("%d", &choice) == EOF) {
            printf("\n[C-Shark] Exiting.\n");
            free_packet_storage();
            exit(0);
        }
        while (getchar() != '\n'); // clear input buffer
        switch (choice) {
            case 1:
                sniff_all_packets(selected_iface);
                break;
            case 2:
                sniff_with_filter(selected_iface);
                break;
            case 3:
                inspect_last_session();
                break;
            case 4:
                printf("\n[C-Shark] Returning to interface selection...\n");
                return 0; // Return to main to reselect interface
            case 5:
                printf("[C-Shark] Exiting.\n");
                free_packet_storage();
                exit(0);
            default:
                printf("Invalid choice. Please try again.\n");
        }
    }
}

int main() {
    printf("[C-Shark] The Command-Line Packet Predator\n");
    printf("==============================================\n");
    printf("Welcome to C-Shark!\n");
    
    while (1) {
        list_interfaces();
        if (main_menu() == 0) {
            // User chose to change interface, loop continues
            continue;
        }
        // If main_menu returns non-zero (shouldn't happen), exit
        break;
    }
    
    free_packet_storage();
    return 0;
}