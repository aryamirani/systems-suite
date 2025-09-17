#ifndef SHAM_H
#define SHAM_H

#include <stdint.h> // For fixed-width integer types

// Control flags for the S.H.A.M. protocol
#define SHAM_SYN 0x1 // Synchronise flag for initiating a connection
#define SHAM_ACK 0x2 // Acknowledge flag
#define SHAM_FIN 0x4 // Finish flag for terminating a connection

// The header structure for every S.H.A.M. packet.
// This will be the first part of every UDP datagram's payload.
struct sham_header {
    uint32_t seq_num;     // Sequence Number
    uint32_t ack_num;     // Acknowledgment Number
    uint16_t flags;       // Control flags (SYN, ACK, FIN)
    uint16_t window_size; // Flow control window size
};

// The full S.H.A.M. packet structure, including the data payload.
// We define a standard data size for segmentation.
#define SHAM_DATA_SIZE 1024
struct sham_packet {
    struct sham_header header;
    char data[SHAM_DATA_SIZE];
};

#endif // SHAM_H