// Memory statistics structures exposed via memstat syscall
#ifndef MEMSTAT_H
#define MEMSTAT_H

#include "types.h"

#define MAX_PAGES_INFO 128

// Page states
#define UNMAPPED 0
#define RESIDENT 1
#define SWAPPED  2

struct page_stat {
  uint va;        // page-aligned virtual address
  int state;      // UNMAPPED | RESIDENT | SWAPPED
  int is_dirty;   // 1 if page has been written since resident
  int seq;        // sequence value for FIFO ordering
  int swap_slot;  // swap slot id or -1
};

struct proc_mem_stat {
  int pid;
  int num_pages_total;     // pages in [0, proc->sz)
  int num_resident_pages;
  int num_swapped_pages;
  int next_fifo_seq;       // next page_seq_ctr for the process
  struct page_stat pages[MAX_PAGES_INFO];
};

#endif
