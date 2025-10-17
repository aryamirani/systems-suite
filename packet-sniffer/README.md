# C-Shark: The Terminal Packet Sniffer

## Overview
C-Shark is a command-line packet sniffer built with libpcap that captures and analyzes network traffic with detailed protocol inspection.

## Features
- Interface selection from available network devices
- Live packet capture (all packets or filtered)
- Multi-layer protocol analysis (L2-L7)
- Packet filtering (HTTP, HTTPS, DNS, ARP, TCP, UDP)
- Session storage and inspection
- Detailed packet hex dumps

## Compilation
```bash
gcc cshark.c -o cshark -lpcap
```

## Usage
```bash
sudo ./cshark
```

Note: Root/sudo privileges required for packet capture.

## Controls
- **Ctrl+C**: Stop packet capture (returns to main menu)
- **Ctrl+D**: Exit program completely at any time
- During capture: User input is disabled except for Ctrl+C/Ctrl+D

## Implementation Details

### Protocol Support
- **Layer 2**: Ethernet (MAC addresses, EtherType)
- **Layer 3**: IPv4, IPv6, ARP
- **Layer 4**: TCP, UDP (with port identification)
- **Layer 7**: Application protocol detection (HTTP, HTTPS, DNS, DHCP, etc.)

### Session Management
- Last capture session is stored in memory
- Can inspect individual packets with detailed analysis
- Session replaced when new capture starts
- No persistent storage across program runs

### Filtering
Supports BPF-style filtering for:
1. HTTP (port 80)
2. HTTPS (port 443)
3. DNS (port 53)
4. ARP
5. TCP (all)
6. UDP (all)

## Assumptions

1. **Platform**: Designed for Linux/Ubuntu environment
2. **Interface Buffer**: 256 bytes allocated for interface names (sufficient for standard interfaces)
3. **BSD Headers**: Uses `__FAVOR_BSD` macro for consistent TCP/UDP header structures
4. **Non-standard Interfaces**: Special interfaces (e.g., bluetooth-monitor) may show pcap errors but will still be openable
5. **Last Session**: "Inspect Last Session" shows the most recent capture, even if it captured zero packets (will display error)
6. **Packet Numbering**: Filtered packets numbered sequentially (1, 2, 3...)

## Error Handling
- No interfaces found: Displays error and exits
- Invalid interface selection: Prompts for valid input
- Filter parse errors: Displays pcap error message
- Empty session inspection: Shows appropriate error message

## Testing Recommendations
- Test with various network interfaces (WiFi, Ethernet, loopback)
- Test Ctrl+C during heavy packet capture
- Test filters on interfaces with different traffic patterns
- Test session inspection after empty capture sessions
