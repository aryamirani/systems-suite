// cshark.h - C-Shark Packet Sniffer Header File

#ifndef CSHARK_H
#define CSHARK_H

#include <pcap.h>
#include <stdint.h>

// ============================================================
// CONFIGURATION CONSTANTS
// ============================================================

#define MAX_INTERFACES 32    // Maximum number of network interfaces
#define SNAPLEN 65535        // Maximum bytes to capture per packet
#define PROMISC 1            // Promiscuous mode enabled
#define TIMEOUT_MS 1000      // Packet capture timeout in milliseconds
#define MAX_PACKETS 10000    // Maximum packets to store in session

// ============================================================
// DATA STRUCTURES
// ============================================================

/**
 * Structure to hold network interface information
 */
typedef struct {
    char name[256];          // Interface name (e.g., "wlan0", "eth0")
    char desc[256];          // Interface description
} iface_info;

/**
 * Structure to store captured packet data
 */
typedef struct {
    struct pcap_pkthdr header;  // Packet header (timestamp, lengths)
    u_char *packet_data;         // Actual packet data
    int packet_id;               // Unique packet identifier
} stored_packet;

// ============================================================
// GLOBAL VARIABLES (extern declarations)
// ============================================================

extern stored_packet *packet_storage;    // Array of stored packets
extern int stored_packet_count;          // Number of packets currently stored
extern int session_exists;               // Flag indicating if a session exists
extern char selected_iface[256];         // Currently selected interface name
extern volatile int keep_sniffing;       // Flag to control packet capture loop

// ============================================================
// FUNCTION PROTOTYPES - Interface Management
// ============================================================

/**
 * Lists all available network interfaces
 * Returns: 0 on success, -1 on failure
 */
int list_interfaces(void);

// ============================================================
// FUNCTION PROTOTYPES - Packet Storage Management
// ============================================================

/**
 * Frees memory allocated for stored packets
 */
void free_packet_storage(void);

/**
 * Initializes packet storage for a new capture session
 */
void init_packet_storage(void);

/**
 * Stores a captured packet in memory
 * @param header: Packet header information
 * @param packet: Packet data
 * @param pkt_id: Packet identifier
 */
void store_packet(const struct pcap_pkthdr *header, const u_char *packet, int pkt_id);

// ============================================================
// FUNCTION PROTOTYPES - Packet Capture
// ============================================================

/**
 * Starts packet capture without filters (captures all packets)
 * @param iface: Network interface name
 */
void sniff_all_packets(const char *iface);

/**
 * Starts packet capture with user-selected filter
 * @param iface: Network interface name
 */
void sniff_with_filter(const char *iface);

// ============================================================
// FUNCTION PROTOTYPES - Packet Analysis
// ============================================================

/**
 * Processes and displays packet information layer by layer
 * @param header: Packet header
 * @param packet: Packet data
 * @param pkt_id: Pointer to packet ID counter
 * @param store: Flag to indicate if packet should be stored
 */
void process_packet(const struct pcap_pkthdr *header, const u_char *packet, 
                   int *pkt_id, int store);

/**
 * Extracts protocol information from packet
 * @param packet: Packet data
 * @param caplen: Captured packet length
 * @param proto_str: Buffer to store protocol string
 * @param proto_str_size: Size of protocol string buffer
 */
void get_protocol_info(const u_char *packet, int caplen, 
                      char *proto_str, size_t proto_str_size);

/**
 * Extracts source and destination IP addresses from packet
 * @param packet: Packet data
 * @param caplen: Captured packet length
 * @param src_ip: Buffer for source IP
 * @param dst_ip: Buffer for destination IP
 * @param ip_size: Size of IP buffers
 */
void get_src_dst_ips(const u_char *packet, int caplen, 
                    char *src_ip, char *dst_ip, size_t ip_size);

// ============================================================
// FUNCTION PROTOTYPES - Session Inspection
// ============================================================

/**
 * Displays stored packets and allows detailed inspection
 */
void inspect_last_session(void);

// ============================================================
// FUNCTION PROTOTYPES - Display Utilities
// ============================================================

/**
 * Prints MAC address in standard format
 * @param mac: 6-byte MAC address
 */
void print_mac(const u_char *mac);

/**
 * Prints data in hexadecimal format
 * @param data: Data buffer
 * @param len: Length of data
 */
void print_hex(const u_char *data, int len);

/**
 * Prints data as hex dump with ASCII representation
 * @param data: Data buffer
 * @param len: Length of data
 * @param bytes_per_line: Number of bytes per line (typically 16)
 */
void print_hex_dump(const u_char *data, int len, int bytes_per_line);

// ============================================================
// FUNCTION PROTOTYPES - User Interface
// ============================================================

/**
 * Displays main menu and handles user input
 * Returns: 0 if user wants to change interface, never returns otherwise
 */
int main_menu(void);

// ============================================================
// FUNCTION PROTOTYPES - Signal Handling
// ============================================================

/**
 * Signal handler for SIGINT (Ctrl+C)
 * @param sig: Signal number
 */
void handle_sigint(int sig);

#endif // CSHARK_H
