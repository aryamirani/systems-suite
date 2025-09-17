#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>  // For va_list and related functions
#include <time.h>    // For nanosleep
#include <sys/time.h>  // For gettimeofday

// Global log file pointer for detailed logging
FILE *log_file = NULL;

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdint.h>
#define close closesocket // For Windows compatibility
typedef int ssize_t;
#define F_GETFL 3
#define F_SETFL 4
#define O_NONBLOCK 1
// Stub for fcntl on Windows
int fcntl(int fd, int cmd, ...) { return 0; }
#else
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>  // For ssize_t
#include <sys/select.h> // For select()
#endif
#include <time.h> // <-- ADDED for nanosleep
#include "sham.h"

#define CHAT_BUFFER_SIZE 1024

#define CONGESTION_WINDOW_SIZE 10
#define TIMEOUT_MS 500

// Function to simulate packet loss
bool should_drop_packet(float loss_rate) {
    // Generate a random number between 0 and 1
    float r = (float)rand() / RAND_MAX;
    // Drop packet if r is less than loss_rate
    return r < loss_rate;
}

// Simple checksum calculation function for file verification
void calculate_file_checksum(const char* filename, char* checksum_str) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        strcpy(checksum_str, "ERROR: Unable to open file for checksum");
        return;
    }
    
    // Simple checksum calculation (not a true MD5, just for demonstration)
    unsigned long checksum = 0;
    int ch;
    
    while ((ch = fgetc(file)) != EOF) {
        checksum = ((checksum << 5) + checksum) + ch; // A simple hash function
    }
    
    fclose(file);
    sprintf(checksum_str, "%08lx", checksum); // Format as 8-digit hex
}

void die(char *s) {
    perror(s);
    exit(1);
}

struct in_flight_packet {
    bool is_valid;
    struct sham_packet packet;
    size_t packet_size;
    struct timeval time_sent;
};

// Function to check if a string is "--chat"
bool is_chat_mode(const char *str) {
    return strcmp(str, "--chat") == 0;
}

// Function to parse a loss rate argument
float parse_loss_rate(const char *str) {
    float loss_rate = atof(str);
    if (loss_rate < 0.0f) loss_rate = 0.0f;
    if (loss_rate > 1.0f) loss_rate = 1.0f;
    return loss_rate;
}

// Function for verbose logging to console
void log_verbose(bool verbose, const char* format, ...) {
    if (!verbose) return;
    
    va_list args;
    va_start(args, format);
    printf("[VERBOSE] ");
    vprintf(format, args);
    va_end(args);
}

// Function for detailed timestamped logging to file
void log_to_file(const char* format, ...) {
    if (!log_file) return;
    
    char time_buffer[30];
    struct timeval tv;
    time_t curtime;
    
    gettimeofday(&tv, NULL);
    curtime = tv.tv_sec;
    
    // Format the time part
    strftime(time_buffer, 30, "%Y-%m-%d %H:%M:%S", localtime(&curtime));
    
    // Print the timestamp prefix
    fprintf(log_file, "[%s.%06ld] [LOG] ", time_buffer, tv.tv_usec);
    
    // Print the actual message
    va_list args;
    va_start(args, format);
    vfprintf(log_file, format, args);
    va_end(args);
    
    // Ensure the log is written immediately
    fflush(log_file);
}

bool verbose_mode = false;

int main(int argc, char *argv[]) {
    bool chat_mode = false;
    float loss_rate = 0.0f;
    const char *input_filename = NULL;
    const char *output_filename = NULL;
    
    // Initialize logging
    printf("Initializing logging...\n");
    log_file = fopen("client_log.txt", "w");
    if (log_file == NULL) {
        printf("Failed to open log file: %s\n", strerror(errno));
    } else {
        printf("Logging enabled. Writing to client_log.txt\n");
    }
    
    // Initialize random number generator for packet loss simulation
    srand(time(NULL));
    
    // Validate minimum arguments
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <server_ip> <server_port> [<input_file> <output_file_name> | --chat] [loss_rate]\n", argv[0]);
        exit(1);
    }
    
    // Parse server IP and port (server_ip will be used directly)
    // Note: We'll use argv[2] directly for the port when setting up the socket
    
    // Check for chat mode or file transfer mode
    if (argc >= 4 && is_chat_mode(argv[3])) {
        chat_mode = true;
        
        // Check for optional parameters in chat mode
        for (int i = 4; i < argc; i++) {
            if (strncmp(argv[i], "--verbose", 9) == 0 || strncmp(argv[i], "-v", 2) == 0) {
                verbose_mode = true;
            } else {
                // Assume it's loss_rate if not a flag
                loss_rate = parse_loss_rate(argv[i]);
            }
        }
    } else {
        // File transfer mode
        if (argc < 5) {
            fprintf(stderr, "Usage: %s <server_ip> <server_port> <input_file> <output_file_name> [loss_rate]\n", argv[0]);
            exit(1);
        }
        
        input_filename = argv[3];
        output_filename = argv[4];
        
        // Check for optional parameters in file transfer mode
        for (int i = 5; i < argc; i++) {
            if (strncmp(argv[i], "--verbose", 9) == 0 || strncmp(argv[i], "-v", 2) == 0) {
                verbose_mode = true;
            } else {
                // Assume it's loss_rate if not a flag
                loss_rate = parse_loss_rate(argv[i]);
            }
        }
    }
    
    printf("Mode: %s\n", chat_mode ? "Chat" : "File Transfer");
    if (!chat_mode) {
        printf("Input file: %s\n", input_filename);
        printf("Output file: %s\n", output_filename);
    }
    printf("Loss rate: %.2f\n", loss_rate);
    
    struct sockaddr_in si_other;
    int s;
    socklen_t slen = sizeof(si_other);
    const char *filename = input_filename;
    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) die("socket");

    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    si_other.sin_port = htons(atoi(argv[2]));
    if (inet_pton(AF_INET, argv[1], &si_other.sin_addr) <= 0) die("inet_pton() failed");

    // --- 3-WAY HANDSHAKE ---
    struct sham_packet syn_packet;
    syn_packet.header.flags = SHAM_SYN;
    syn_packet.header.seq_num = 1000;
    
    log_to_file("SND SYN SEQ=%u\n", syn_packet.header.seq_num);
    
    if (sendto(s, &syn_packet, sizeof(syn_packet.header), 0, (struct sockaddr *) &si_other, slen) == -1) die("sendto() SYN");
    
    struct timeval tv_handshake;
    tv_handshake.tv_sec = 2; tv_handshake.tv_usec = 0;
    if (setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv_handshake, sizeof(tv_handshake)) < 0) die("setsockopt handshake");

    struct sham_packet synack_packet;
    if (recvfrom(s, &synack_packet, sizeof(synack_packet), 0, NULL, NULL) == -1) die("recvfrom() SYN-ACK");
    
    log_to_file("RCV SYN-ACK SEQ=%u ACK=%u\n", synack_packet.header.seq_num, synack_packet.header.ack_num);
    
    if ((synack_packet.header.flags & (SHAM_SYN | SHAM_ACK)) && 
        (synack_packet.header.ack_num == syn_packet.header.seq_num + 1)) {
        
        struct sham_packet ack_packet;
        ack_packet.header.flags = SHAM_ACK;
        ack_packet.header.ack_num = synack_packet.header.seq_num + 1;
        
        log_to_file("SND ACK=%u\n", ack_packet.header.ack_num);
        
        if (sendto(s, &ack_packet, sizeof(ack_packet.header), 0, (struct sockaddr *) &si_other, slen) == -1) die("sendto() final ACK");
        printf("Connection established.\n");
        
        if (!chat_mode && output_filename != NULL) {
            // Send the output filename to the server so it knows what to name the received file
            struct sham_packet filename_packet;
            filename_packet.header.flags = 0; // Regular data packet
            filename_packet.header.seq_num = 0; // Special sequence number for metadata
            
            // Copy the filename to packet data
            strncpy(filename_packet.data, output_filename, SHAM_DATA_SIZE - 1);
            size_t name_len = strlen(output_filename);
            
            log_to_file("SND FILENAME SEQ=%u LEN=%u\n", filename_packet.header.seq_num, (unsigned int)name_len + 1);
            
            // Send the filename packet
            if (sendto(s, &filename_packet, sizeof(filename_packet.header) + name_len + 1, 0, (struct sockaddr *) &si_other, slen) == -1) {
                die("sendto() filename");
            }
            
            // Wait for acknowledgment
            struct sham_packet ack_filename;
            if (recvfrom(s, &ack_filename, sizeof(ack_filename), 0, NULL, NULL) == -1) {
                die("recvfrom() filename ACK");
            }
            
            if (!(ack_filename.header.flags & SHAM_ACK)) {
                printf("Warning: Server did not acknowledge filename\n");
            } else {
                printf("Server will save the file as: %s\n", output_filename);
            }
        }
    } else {
        printf("Handshake failed: Did not receive proper SYN-ACK.\n");
        if (log_file) {
            log_to_file("Handshake failed: Did not receive proper SYN-ACK.\n");
            fclose(log_file);
        }
        close(s); return 1;
    }

    // Set socket to non-blocking for data transfer
    int flags = fcntl(s, F_GETFL, 0);
    fcntl(s, F_SETFL, flags | O_NONBLOCK);

    // --- SLIDING WINDOW WITH FLOW CONTROL ---
    FILE* input_file = NULL;
    
    if (chat_mode) {
        printf("Starting chat mode...\n");
        printf("Type your messages. Type /quit to exit.\n");
        
        // Set socket to non-blocking for chat mode
        int flags = fcntl(s, F_GETFL, 0);
        fcntl(s, F_SETFL, flags | O_NONBLOCK);
        
        char chat_buffer[CHAT_BUFFER_SIZE];
        fd_set read_fds;
        bool running = true;
        
        while (running) {
            FD_ZERO(&read_fds);
            FD_SET(0, &read_fds);  // Add stdin to file descriptor set
            FD_SET(s, &read_fds);  // Add socket to file descriptor set
            
            struct timeval tv;
            tv.tv_sec = 0;
            tv.tv_usec = 100000;  // 100ms timeout for responsive UI
            
            int select_result = select(s + 1, &read_fds, NULL, NULL, &tv);
            
            if (select_result == -1) {
                perror("select");
                break;
            }
            
            // Check if there's data to read from stdin
            if (FD_ISSET(0, &read_fds)) {
                if (fgets(chat_buffer, CHAT_BUFFER_SIZE, stdin) != NULL) {
                    // Remove newline character
                    size_t len = strlen(chat_buffer);
                    if (len > 0 && chat_buffer[len - 1] == '\n') {
                        chat_buffer[len - 1] = '\0';
                    }
                    
                    // Check if user wants to quit
                    if (strcmp(chat_buffer, "/quit") == 0) {
                        printf("Initiating connection teardown...\n");
                        running = false;
                        break;
                    }
                    
                    // Prepare and send the message
                    struct sham_packet chat_packet;
                    memset(&chat_packet, 0, sizeof(chat_packet));
                    chat_packet.header.seq_num = 1; // Simple sequence for chat
                    chat_packet.header.flags = 0;   // Regular data packet
                    
                    // Copy message to packet data
                    strncpy(chat_packet.data, chat_buffer, SHAM_DATA_SIZE - 1);
                    size_t msg_len = strlen(chat_buffer);
                    
                    // Log and send the message
                    log_to_file("SND CHAT SEQ=%u LEN=%u\n", chat_packet.header.seq_num, (unsigned int)msg_len);
                    
                    if (sendto(s, &chat_packet, sizeof(chat_packet.header) + msg_len + 1, 0, (struct sockaddr *) &si_other, slen) == -1) {
                        perror("sendto() failed");
                    }
                }
            }
            
            // Check if there's data to read from the socket
            if (FD_ISSET(s, &read_fds)) {
                struct sham_packet received_packet;
                ssize_t bytes_received = recvfrom(s, &received_packet, sizeof(received_packet), 0, NULL, NULL);
                
                if (bytes_received > 0) {
                    // Simulate packet loss for non-control packets in chat mode
                    if (loss_rate > 0.0f && received_packet.header.flags == 0 && should_drop_packet(loss_rate)) {
                        log_verbose(verbose_mode, "Dropping packet: chat message from server\n");
                        log_to_file("DROP DATA SEQ=%u\n", received_packet.header.seq_num);
                        if (!verbose_mode) printf("Simulating packet loss for chat message\n");
                        continue; // Skip processing this packet
                    }
                    
                    // Check if it's a regular message (not control packet)
                    if (received_packet.header.flags == 0) {
                        // Log and print the message
                        size_t msg_len = strlen(received_packet.data);
                        log_to_file("RCV CHAT SEQ=%u LEN=%u\n", received_packet.header.seq_num, (unsigned int)msg_len);
                        
                        printf("Server: %s\n", received_packet.data);
                        log_verbose(verbose_mode, "Received chat message from server, length=%zu bytes\n", 
                                   msg_len);
                    } else if (received_packet.header.flags & SHAM_FIN) {
                        // Server wants to close connection
                        printf("Server has initiated connection teardown.\n");
                        running = false;
                        break;
                    }
                }
            }
            
            // Small sleep to prevent CPU hogging
            struct timespec sleep_time = {0, 10000000}; // 10ms
            nanosleep(&sleep_time, NULL);
        }
        
        // Initiate the 4-way handshake teardown
        struct sham_packet fin_packet;
        fin_packet.header.flags = SHAM_FIN;
        fin_packet.header.seq_num = 1000;
        if (sendto(s, &fin_packet, sizeof(fin_packet.header), 0, (struct sockaddr *) &si_other, slen) == -1) {
            perror("sendto() FIN");
        }
        
        printf("Chat session ended.\n");
        if (log_file) {
            log_to_file("Chat session ended.\n");
            fclose(log_file);
        }
        close(s);
        return 0;
    } else {
        // File transfer mode
        input_file = fopen(filename, "rb");
        if (input_file == NULL) die("fopen");
        printf("Sending file %s with Flow Control...\n", filename);
    }

    uint32_t base = 1;
    uint32_t next_seq_num = 1;
    bool file_read_complete = false;
    struct in_flight_packet window_buffer[CONGESTION_WINDOW_SIZE] = {0};
    uint16_t server_window = 65535;
    uint32_t last_acked = 0;

    while (!file_read_complete || base < next_seq_num) {
        uint32_t unacknowledged_bytes = next_seq_num - base;
        
        while ((next_seq_num < base + (CONGESTION_WINDOW_SIZE * SHAM_DATA_SIZE)) && 
               (unacknowledged_bytes < server_window) && !file_read_complete) {
            
            int buffer_index = ((next_seq_num - 1) / SHAM_DATA_SIZE) % CONGESTION_WINDOW_SIZE;
            
            size_t bytes_read = fread(window_buffer[buffer_index].packet.data, 1, SHAM_DATA_SIZE, input_file);
            if (bytes_read > 0) {
                window_buffer[buffer_index].packet.header.seq_num = next_seq_num;
                window_buffer[buffer_index].packet.header.flags = 0;
                window_buffer[buffer_index].packet_size = sizeof(struct sham_header) + bytes_read;
                window_buffer[buffer_index].is_valid = true;
                gettimeofday(&window_buffer[buffer_index].time_sent, NULL);

                log_to_file("SND DATA SEQ=%u LEN=%u\n", window_buffer[buffer_index].packet.header.seq_num, (unsigned int)bytes_read);
                
                if (sendto(s, &window_buffer[buffer_index].packet, window_buffer[buffer_index].packet_size, 0, (struct sockaddr *) &si_other, slen) == -1) die("sendto() data");
                next_seq_num += bytes_read;
                unacknowledged_bytes = next_seq_num - base;
            } else {
                file_read_complete = true;
                break;
            }
        }
        
        struct sham_packet ack_packet_recv;
        ssize_t ack_bytes = recvfrom(s, &ack_packet_recv, sizeof(ack_packet_recv), 0, NULL, NULL);
        if (ack_bytes > 0 && (ack_packet_recv.header.flags & SHAM_ACK)) {
            if (ack_packet_recv.header.ack_num > base && ack_packet_recv.header.ack_num > last_acked) {
                log_to_file("RCV ACK=%u WIN=%u\n", ack_packet_recv.header.ack_num, ack_packet_recv.header.window_size);
                
                base = ack_packet_recv.header.ack_num;
                server_window = ack_packet_recv.header.window_size;
                last_acked = base;
                printf("  - ACK for seq up to %u, server window is %u\n", base, server_window);
            }
        } else if (ack_bytes == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            // --- THIS IS THE FIX ---
            struct timespec req = {0, 1000000L}; // 1ms delay
            nanosleep(&req, NULL);
            // ---------------------
        }
        
        struct timeval now;
        gettimeofday(&now, NULL);
        for (int i = 0; i < CONGESTION_WINDOW_SIZE; i++) {
            if (window_buffer[i].is_valid && window_buffer[i].packet.header.seq_num < base) {
                window_buffer[i].is_valid = false;
            }
            if (window_buffer[i].is_valid && window_buffer[i].packet.header.seq_num >= base) {
                long elapsed_ms = (now.tv_sec - window_buffer[i].time_sent.tv_sec) * 1000 + (now.tv_usec - window_buffer[i].time_sent.tv_usec) / 1000;
                if (elapsed_ms > TIMEOUT_MS) {
                    if (sendto(s, &window_buffer[i].packet, window_buffer[i].packet_size, 0, (struct sockaddr *) &si_other, slen) == -1) die("sendto() retransmit");
                    gettimeofday(&window_buffer[i].time_sent, NULL);
                }
            }
        }
    }
    fclose(input_file);

    // Final wait loop for ACKs
    int wait_count = 0;
    int max_wait = 5000; // 5 seconds max
    while (base < next_seq_num && wait_count < max_wait) {
        struct sham_packet ack_packet_recv;
        ssize_t ack_bytes = recvfrom(s, &ack_packet_recv, sizeof(ack_packet_recv), 0, NULL, NULL);
        if (ack_bytes > 0 && (ack_packet_recv.header.flags & SHAM_ACK)) {
            if (ack_packet_recv.header.ack_num > base) {
                base = ack_packet_recv.header.ack_num;
            }
        } else {
            struct timespec req = {0, 1000000L}; // 1ms delay
            nanosleep(&req, NULL);
            wait_count++;
        }
    }

    // We'll keep socket in non-blocking mode for teardown
    struct sham_packet fin_packet;
    fin_packet.header.flags = SHAM_FIN;
    fin_packet.header.seq_num = next_seq_num;
    if (sendto(s, &fin_packet, sizeof(fin_packet.header), 0, (struct sockaddr *) &si_other, slen) == -1) die("sendto() FIN");
    printf("FIN sent.\n");

    // --- 4-WAY HANDSHAKE TEARDOWN ---
    // Keep a short timeout to avoid hanging
    struct timeval tv;
    tv.tv_sec = 2; tv.tv_usec = 0;
    if (setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) die("setsockopt");
    
    // We'll use polling with short sleeps to wait for responses
    struct timespec sleep_time = {0, 100000000}; // 100ms sleep between polls
    
    // Step 1: Wait for server's ACK of our FIN
    printf("Waiting for server's ACK...\n");
    struct sham_packet server_ack_packet;
    bool got_ack = false;
    int max_tries_ack = 10;
    
    for (int i = 0; i < max_tries_ack; i++) {
        ssize_t recv_res = recvfrom(s, &server_ack_packet, sizeof(server_ack_packet), 0, NULL, NULL);
        if (recv_res > 0) {
            if (server_ack_packet.header.flags & SHAM_ACK) {
                printf("Received ACK from server.\n");
                got_ack = true;
                break;
            }
        } else if (recv_res == -1 && (errno != EAGAIN && errno != EWOULDBLOCK)) {
            printf("Error in recvfrom for server's ACK: %s\n", strerror(errno));
        }
        nanosleep(&sleep_time, NULL);
    }
    
    if (!got_ack) {
        printf("Did not receive ACK for FIN, continuing with connection close.\n");
    }
    
    // Step 2: Wait for server's FIN
    printf("Waiting for server's FIN...\n");
    struct sham_packet server_fin_packet;
    bool got_fin = false;
    int max_tries_fin = 10;
    
    for (int i = 0; i < max_tries_fin; i++) {
        ssize_t recv_res = recvfrom(s, &server_fin_packet, sizeof(server_fin_packet), 0, NULL, NULL);
        if (recv_res > 0) {
            if (server_fin_packet.header.flags & SHAM_FIN) {
                printf("Received FIN from server.\n");
                got_fin = true;
                break;
            }
        } else if (recv_res == -1 && (errno != EAGAIN && errno != EWOULDBLOCK)) {
            printf("Error in recvfrom for server's FIN: %s\n", strerror(errno));
        }
        nanosleep(&sleep_time, NULL);
    }
    
    // Step 3: Send final ACK whether we got FIN or not
    struct sham_packet final_ack_packet;
    final_ack_packet.header.flags = SHAM_ACK;
    if (got_fin) {
        final_ack_packet.header.ack_num = server_fin_packet.header.seq_num + 1;
    } else {
        // If we didn't get FIN, use the typical sequence number
        printf("Did not receive server's FIN, sending final ACK anyway.\n");
        final_ack_packet.header.ack_num = 9001; // Typical server FIN seq + 1
    }
    
    printf("Sending final ACK...\n");
    if (sendto(s, &final_ack_packet, sizeof(final_ack_packet.header), 0, (struct sockaddr *) &si_other, slen) == -1) {
        printf("Failed to send final ACK: %s\n", strerror(errno));
    }
    
    // Wait a bit to ensure the ACK has time to be sent
    nanosleep(&sleep_time, NULL);
    
    // Calculate and display checksum for file transfers
    if (!chat_mode && input_filename) {
        char checksum[9]; // 8 hex digits + null terminator
        calculate_file_checksum(input_filename, checksum);
        printf("File transfer complete.\n");
        printf("File checksum: %s\n", checksum);
    }
    
    printf("Connection gracefully closed.\n");

    // Close the log file if it was opened
    if (log_file) {
        fclose(log_file);
    }

    close(s);
    return 0;
}