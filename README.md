# xv6 Kernel Extensions & Systems Suite

This repository contains a comprehensive suite of systems programming projects built in **C, RISC-V, xv6, pthreads, and libpcap**. It showcases modifications to the xv6 kernel, the development of a POSIX-compliant shell, a custom UDP reliable transport protocol, a packet sniffer, and multithreaded synchronization simulators.

## Components

### 1. xv6 Kernel: CPU Scheduling (`xv6-scheduling/`)
Extended the xv6 RISC-V kernel with three compile-time CPU schedulers:
- **First Come First Serve (FCFS)**
- **Round Robin (RR)**
- **Completely Fair Scheduler (CFS)** with vruntime-based nice weights.
- Includes a custom `getreadcount()` system call.

### 2. xv6 Kernel: Memory Management (`xv6-memory-management/`)
Extended the xv6 RISC-V kernel with advanced memory management capabilities:
- **Demand Paging**
- **FIFO & CLOCK Page Replacement Algorithms**
- **Per-process Swap Files**

### 3. POSIX Shell (`posix-shell/`)
Built a custom POSIX-compliant shell from scratch featuring:
- Input parsing and command execution
- **Piping** between processes
- **I/O Redirection**
- **Job Control** (background processing)

### 4. Reliable Transport Protocol (`reliable-transport-protocol/`)
Developed a custom reliable transport protocol (S.H.A.M.) over UDP:
- **Sliding-window flow control**
- **Retransmission** logic for dropped/corrupted packets
- Client-server architecture handling robust data transfer

### 5. C-Shark Packet Sniffer (`packet-sniffer/`)
A terminal-based packet sniffer built using `libpcap`:
- Captures and analyzes live network traffic across interfaces
- Multi-layer protocol inspection (L2-L7: Ethernet, IP, TCP, UDP, HTTP, DNS)
- Support for BPF-style packet filtering and session storage

### 6. Bakery Simulator (`bakery-simulator/`)
A multithreaded concurrency simulator modeling an office bakery:
- Utilizes POSIX threads (`pthreads`), **mutexes**, **semaphores**, and **condition variables**.
- Manages complex resource constraints (ovens, seating, cash registers) without race conditions or deadlocks.
- Implements a priority system for chef operations.

---
*Note: This project is a combination of two mini-projects developed during the Operating Systems and Networks course at IIIT-Hyderabad.*
