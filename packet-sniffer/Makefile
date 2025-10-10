# C-Shark Packet Sniffer Makefile

CC = gcc
CFLAGS = -Wall -Wextra -g
LDFLAGS = -lpcap

CSHARK_SRC = cshark.c
CSHARK_BIN = cshark

all: $(CSHARK_BIN)

$(CSHARK_BIN): $(CSHARK_SRC)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(CSHARK_BIN)
