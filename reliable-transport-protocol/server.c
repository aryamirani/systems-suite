#define _POSIX_C_SOURCE 199309L  // Add this line at the top
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <stdbool.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/select.h>  // For select()
#include <stdarg.h>      // For va_list and related functions
#include "sham.h"

// Global log file pointer for detailed logging
FILE *log_file = NULL;

#define CHAT_BUFFER_SIZE 1024

#define OUTPUT_FILENAME "received_file.txt"
#define MAX_BUFFERED_PACKETS 50
#define RECEIVER_BUFFER_SIZE 20480 

// Global variables for custom filename handling
char custom_output_filename[SHAM_DATA_SIZE];
bool use_custom_filename = false;

// Function to simulate packet loss
bool should_drop_packet(float loss_rate) {
    // Generate a random number between 0 and 1
    float r = (float)rand() / RAND_MAX;
    // Drop packet if r is less than loss_rate
    return r < loss_rate;
}

void die(char *s) {
    perror(s);
    exit(1);
}

struct buffered_packet {
    bool is_valid;
    struct sham_packet packet;
    ssize_t packet_size;
};

// Function to check if a string is "--chat"
bool is_chat_mode(const char *str) {
    return strcmp(str, "--chat") == 0;
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

// Function to parse a loss rate argument
float parse_loss_rate(const char *str) {
    float loss_rate = atof(str);
    if (loss_rate < 0.0f) loss_rate = 0.0f;
    if (loss_rate > 1.0f) loss_rate = 1.0f;
    return loss_rate;
}

int main(int argc, char *argv[]) {
    bool chat_mode = false;
    bool verbose_mode = false;
    float loss_rate = 0.0f;
    
    // Initialize logging
    printf("Initializing logging...\n");
    log_file = fopen("server_log.txt", "w");
    if (log_file == NULL) {
        printf("Failed to open log file: %s\n", strerror(errno));
    } else {
        printf("Logging enabled. Writing to server_log.txt\n");
    }
    
    // Initialize random number generator for packet loss simulation
    srand(time(NULL));
    
    // Validate minimum arguments
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <port> [--chat] [loss_rate]\n", argv[0]);
        exit(1);
    }
    
    // Parse port number (directly use argv[1] when setting up the socket)
    
    // Check for chat mode
    if (argc >= 3) {
        if (is_chat_mode(argv[2])) {
            chat_mode = true;
            
            // Check for optional parameters in chat mode
            for (int i = 3; i < argc; i++) {
                if (strncmp(argv[i], "--verbose", 9) == 0 || strncmp(argv[i], "-v", 2) == 0) {
                    verbose_mode = true;
                } else {
                    // Assume it's loss_rate if not a flag
                    loss_rate = parse_loss_rate(argv[i]);
                }
            }
        } else {
            // No chat mode, check for other parameters
            for (int i = 2; i < argc; i++) {
                if (strncmp(argv[i], "--verbose", 9) == 0 || strncmp(argv[i], "-v", 2) == 0) {
                    verbose_mode = true;
                } else {
                    // Assume it's loss_rate if not a flag
                    loss_rate = parse_loss_rate(argv[i]);
                }
            }
        }
    }
    
    printf("Mode: %s\n", chat_mode ? "Chat" : "File Transfer");
    printf("Loss rate: %.2f\n", loss_rate);
    printf("Verbose mode: %s\n", verbose_mode ? "ON" : "OFF");
    
    struct sockaddr_in si_me, si_other;
    int s;
    socklen_t slen = sizeof(si_other);
    struct sham_packet packet;

    if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1) die("socket");

    memset((char *) &si_me, 0, sizeof(si_me));
    si_me.sin_family = AF_INET;
    si_me.sin_port = htons(atoi(argv[1]));
    si_me.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(s, (struct sockaddr*)&si_me, sizeof(si_me)) == -1) die("bind");
    printf("Server listening on port %s...\n", argv[1]);

    // --- HANDSHAKE ---
    if (recvfrom(s, &packet, sizeof(packet), 0, (struct sockaddr *) &si_other, &slen) == -1) die("recvfrom()");
    if (packet.header.flags & SHAM_SYN) {
        log_to_file("RCV SYN SEQ=%u\n", packet.header.seq_num);
        
        uint32_t client_seq = packet.header.seq_num;
        struct sham_packet response_packet;
        response_packet.header.flags = SHAM_SYN | SHAM_ACK;
        response_packet.header.seq_num = 5000;
        response_packet.header.ack_num = client_seq + 1;
        
        log_to_file("SND SYN-ACK SEQ=%u ACK=%u\n", response_packet.header.seq_num, response_packet.header.ack_num);
        
        if (sendto(s, &response_packet, sizeof(response_packet.header), 0, (struct sockaddr*) &si_other, slen) == -1) die("sendto()");
        if (recvfrom(s, &packet, sizeof(packet), 0, (struct sockaddr *) &si_other, &slen) == -1) die("recvfrom()");
        if ((packet.header.flags & SHAM_ACK) && (packet.header.ack_num == 5001)) {
            log_to_file("RCV ACK=%u\n", packet.header.ack_num);
            printf("Connection established with %s:%d\n", inet_ntoa(si_other.sin_addr), ntohs(si_other.sin_port));
            
            // In file transfer mode, wait for client to send output filename
            if (!chat_mode) {
                // Set a short timeout for receiving the filename
                struct timeval tv_filename;
                tv_filename.tv_sec = 2;
                tv_filename.tv_usec = 0;
                if (setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv_filename, sizeof(tv_filename)) < 0) {
                    die("setsockopt for filename");
                }
                
                // Wait to receive the filename packet
                struct sham_packet filename_packet;
                if (recvfrom(s, &filename_packet, sizeof(filename_packet), 0, (struct sockaddr *) &si_other, &slen) > 0) {
                    if (filename_packet.header.seq_num == 0) {
                        // Acknowledge the filename
                        struct sham_packet ack_filename;
                        ack_filename.header.flags = SHAM_ACK;
                        ack_filename.header.ack_num = 1;  // Arbitrary for filename ACK
                        if (sendto(s, &ack_filename, sizeof(ack_filename.header), 0, (struct sockaddr *) &si_other, slen) == -1) {
                            die("sendto() filename ACK");
                        }
                        
                        // Extract the filename (stored globally so it persists)
                        strncpy(custom_output_filename, filename_packet.data, SHAM_DATA_SIZE - 1);
                        custom_output_filename[SHAM_DATA_SIZE - 1] = '\0';
                        use_custom_filename = true;
                        
                        printf("Will save received file as: %s\n", custom_output_filename);
                    }
                }
            }
        } else {
            printf("Handshake failed: Did not receive final ACK.\n");
            if (log_file) {
                log_to_file("Handshake failed: Did not receive final ACK.\n");
                fclose(log_file);
                log_file = NULL;
            }
            close(s); return 1;
        }
    } else {
        printf("Handshake failed: Did not receive SYN.\n");
        if (log_file) {
            log_to_file("Handshake failed: Did not receive SYN.\n");
            fclose(log_file);
            log_file = NULL;
        }
        close(s); return 1;
    }

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
                ssize_t bytes_received = recvfrom(s, &received_packet, sizeof(received_packet), 0, (struct sockaddr *) &si_other, &slen);
                
                if (bytes_received > 0) {
                    // Simulate packet loss for non-control packets in chat mode
                    if (loss_rate > 0.0f && received_packet.header.flags == 0 && should_drop_packet(loss_rate)) {
                        log_verbose(verbose_mode, "Dropping packet: chat message from client\n");
                        if (!verbose_mode) printf("Simulating packet loss for chat message\n");
                        continue; // Skip processing this packet
                    }
                    
                    // Check if it's a regular message (not control packet)
                    if (received_packet.header.flags == 0) {
                        // Log and print the message
                        size_t msg_len = strlen(received_packet.data);
                        log_to_file("RCV CHAT SEQ=%u LEN=%u\n", received_packet.header.seq_num, (unsigned int)msg_len);
                        
                        printf("Client: %s\n", received_packet.data);
                        log_verbose(verbose_mode, "Received chat message from client, length=%zu bytes\n", 
                                   msg_len);
                    } else if (received_packet.header.flags & SHAM_FIN) {
                        // Client wants to close connection
                        printf("Client has initiated connection teardown.\n");
                        
                        // Send ACK for FIN
                        struct sham_packet ack_fin;
                        ack_fin.header.flags = SHAM_ACK;
                        ack_fin.header.ack_num = received_packet.header.seq_num + 1;
                        if (sendto(s, &ack_fin, sizeof(ack_fin.header), 0, (struct sockaddr *) &si_other, slen) == -1) {
                            perror("sendto() ACK for FIN");
                        }
                        
                        // Send server's FIN
                        struct sham_packet server_fin;
                        server_fin.header.flags = SHAM_FIN;
                        server_fin.header.seq_num = 9000;
                        if (sendto(s, &server_fin, sizeof(server_fin.header), 0, (struct sockaddr *) &si_other, slen) == -1) {
                            perror("sendto() server FIN");
                        }
                        
                        running = false;
                        break;
                    }
                }
            }
            
            // Small sleep to prevent CPU hogging
            struct timespec sleep_time = {0, 10000000}; // 10ms
            nanosleep(&sleep_time, NULL);
        }
        
        // Wait for final ACK in teardown
        printf("Waiting for final ACK in teardown...\n");
        struct timeval wait_time;
        wait_time.tv_sec = 2;  // Wait up to 2 seconds for final ACK
        wait_time.tv_usec = 0;
        
        setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &wait_time, sizeof(wait_time));
        
        struct sham_packet final_ack;
        if (recvfrom(s, &final_ack, sizeof(final_ack), 0, (struct sockaddr *) &si_other, &slen) > 0) {
            if (final_ack.header.flags & SHAM_ACK) {
                printf("Received final ACK. Connection closed.\n");
            }
        }
        
        printf("Chat session ended.\n");
        if (log_file) {
            log_to_file("Chat session ended.\n");
            fclose(log_file);
            log_file = NULL;
        }
        close(s);
        return 0;
    }
    
    // --- FILE RECEIVING WITH FLOW CONTROL ---
    FILE* output_file;
    
    if (use_custom_filename) {
        output_file = fopen(custom_output_filename, "wb");
    } else {
        output_file = fopen(OUTPUT_FILENAME, "wb");
    }
    
    if (output_file == NULL) die("fopen");
    printf("Ready to receive file with Flow Control...\n");

    uint32_t expected_seq_num = 1;
    struct buffered_packet packet_buffer[MAX_BUFFERED_PACKETS] = {0};
    uint32_t client_fin_seq = 0;
    size_t bytes_in_buffer = 0;

    while (1) {
        ssize_t bytes_received = recvfrom(s, &packet, sizeof(packet), 0, (struct sockaddr *) &si_other, &slen);
        if (bytes_received == -1) die("recvfrom()");

        // Handle FIN packet (don't apply packet loss to control packets)
        if (packet.header.flags & SHAM_FIN) {
            client_fin_seq = packet.header.seq_num;
            break;
        }
        
        // Simulate packet loss for data packets based on loss_rate
        if (loss_rate > 0.0f && should_drop_packet(loss_rate)) {
            log_verbose(verbose_mode, "Dropping packet: SEQ=%u, ACK=%u, flags=%u, size=%zu bytes\n", 
                      packet.header.seq_num, packet.header.ack_num, packet.header.flags, bytes_received);
            log_to_file("DROP DATA SEQ=%u\n", packet.header.seq_num);
            if (!verbose_mode) printf("Simulating packet loss for SEQ=%u\n", packet.header.seq_num);
            // Artificially drop this packet by continuing the loop without processing it
            continue;
        }

        size_t data_size = bytes_received - sizeof(struct sham_header);
        
        if (packet.header.seq_num == expected_seq_num) {
            log_to_file("RCV DATA SEQ=%u LEN=%u\n", packet.header.seq_num, (unsigned int)data_size);
            
            fwrite(packet.data, 1, data_size, output_file);
            log_verbose(verbose_mode, "Received expected packet SEQ=%u, wrote %zu bytes to file\n", 
                      packet.header.seq_num, data_size);
            
            // This line is for testing flow control. You can comment it out for fast transfers.
            struct timespec req = {0, 50000000L}; // 50ms sleep
            nanosleep(&req, NULL);
            
            expected_seq_num += data_size;
            
            while (1) {
                bool found_next = false;
                for (int i = 0; i < MAX_BUFFERED_PACKETS; i++) {
                    if (packet_buffer[i].is_valid && packet_buffer[i].packet.header.seq_num == expected_seq_num) {
                        size_t buffered_data_size = packet_buffer[i].packet_size - sizeof(struct sham_header);
                        fwrite(packet_buffer[i].packet.data, 1, buffered_data_size, output_file);
                        expected_seq_num += buffered_data_size;
                        bytes_in_buffer -= buffered_data_size;
                        packet_buffer[i].is_valid = false;
                        found_next = true;
                        break;
                    }
                }
                if (!found_next) break;
            }
        } else if (packet.header.seq_num > expected_seq_num) {
            bytes_in_buffer += data_size;
            bool buffered = false;
            for (int i = 0; i < MAX_BUFFERED_PACKETS; i++) {
                if (!packet_buffer[i].is_valid) {
                    packet_buffer[i].is_valid = true;
                    packet_buffer[i].packet = packet;
                    packet_buffer[i].packet_size = bytes_received;
                    buffered = true;
                    break;
                }
            }
            if (!buffered) printf("Buffer full! Packet discarded.\n");
        }

        struct sham_packet ack_packet;
        ack_packet.header.flags = SHAM_ACK;
        ack_packet.header.ack_num = expected_seq_num;
        ack_packet.header.window_size = (RECEIVER_BUFFER_SIZE > bytes_in_buffer) ? (RECEIVER_BUFFER_SIZE - bytes_in_buffer) : 0;
        
        log_to_file("SND ACK=%u WIN=%u\n", ack_packet.header.ack_num, ack_packet.header.window_size);
        
        if (sendto(s, &ack_packet, sizeof(ack_packet.header), 0, (struct sockaddr*) &si_other, slen) == -1) {
            die("sendto() ACK");
        }
    }
    fclose(output_file);
    
    // Calculate and display checksum for the received file
    char checksum[9]; // 8 hex digits + null terminator
    if (use_custom_filename) {
        calculate_file_checksum(custom_output_filename, checksum);
        printf("File reception complete.\n");
        printf("Received file checksum: %s\n", checksum);
    } else {
        calculate_file_checksum(OUTPUT_FILENAME, checksum);
        printf("File reception complete.\n");
        printf("Received file checksum: %s\n", checksum);
    }

    // --- 4-WAY HANDSHAKE TEARDOWN ---
    printf("Initiating 4-way teardown...\n");

    // Also set non-blocking socket for the teardown to avoid hanging
    int flags = fcntl(s, F_GETFL, 0);
    fcntl(s, F_SETFL, flags | O_NONBLOCK);
    
    // Step 1: Send ACK for client's FIN
    struct sham_packet ack_for_fin;
    ack_for_fin.header.flags = SHAM_ACK;
    ack_for_fin.header.ack_num = client_fin_seq + 1;
    printf("Sending ACK for client FIN...\n");
    if (sendto(s, &ack_for_fin, sizeof(ack_for_fin.header), 0, (struct sockaddr*) &si_other, slen) == -1) {
        printf("Failed to send ACK for FIN: %s\n", strerror(errno));
        close(s);
        return 1;
    }
    
    // Sleep a bit to ensure the ACK has time to reach the client
    struct timespec sleep_time = {0, 100000000}; // 100ms
    nanosleep(&sleep_time, NULL);
    
    // Step 2: Send server's FIN
    struct sham_packet server_fin;
    server_fin.header.flags = SHAM_FIN;
    server_fin.header.seq_num = 9000;
    printf("Sending server FIN...\n");
    if (sendto(s, &server_fin, sizeof(server_fin.header), 0, (struct sockaddr*) &si_other, slen) == -1) {
        printf("Failed to send server FIN: %s\n", strerror(errno));
        close(s);
        return 1;
    }
    
    // Step 3: Wait for client's final ACK
    printf("Waiting for final ACK...\n");
    int max_tries = 10; // Try for about 1 second (10 * 100ms)
    for (int i = 0; i < max_tries; i++) {
        ssize_t recv_res = recvfrom(s, &packet, sizeof(packet), 0, (struct sockaddr *) &si_other, &slen);
        if (recv_res > 0) {
            if ((packet.header.flags & SHAM_ACK) && (packet.header.ack_num == server_fin.header.seq_num + 1)) {
                printf("Received final ACK. Connection gracefully closed.\n");
                if (log_file) {
                    log_to_file("Connection gracefully closed.\n");
                    fclose(log_file);
                    log_file = NULL;
                }
                close(s);
                return 0;
            }
        } else if (recv_res == -1 && (errno != EAGAIN && errno != EWOULDBLOCK)) {
            printf("Error in recvfrom for final ACK: %s\n", strerror(errno));
            break;
        }
        
        // Wait a bit before trying again
        nanosleep(&sleep_time, NULL);
    }
    
    printf("Timeout waiting for final ACK, assuming connection closed.\n");
    if (log_file) {
        log_to_file("Timeout waiting for final ACK, assuming connection closed.\n");
        fclose(log_file);
        log_file = NULL;
    }
    close(s);
    return 0;
}