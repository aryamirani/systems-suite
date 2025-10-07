#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "vm.h"
#include "memstat.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  kexit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return kfork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return kwait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
  argint(1, &t);
  struct proc *p = myproc();
  addr = p->sz;

  if(t == SBRK_EAGER || n < 0) {
    if(growproc(n) < 0) {
      return -1;
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
      return -1;
    p->sz += n;
  }

  // Keep heap_brk consistent and clamped to the end of program segments.
  // Compute program end from recorded segments (lazy exec).
  uint64 prog_end = 0;
  for(int i = 0; i < p->nsegs; i++){
    uint64 end = p->segs[i].va + p->segs[i].memsz;
    if(end > prog_end) prog_end = end;
  }
  // Update heap_brk by n and clamp to at least prog_end.
  // Upper bound is implicitly limited by p->sz (heap_brk < sz - stack/guard window).
  if(n != 0){
    long long newbrk = (long long)p->heap_brk + (long long)n;
    if(newbrk < (long long)prog_end)
      newbrk = (long long)prog_end;
    // Also, avoid exceeding p->sz in pathological cases.
    if(newbrk > (long long)p->sz)
      newbrk = (long long)p->sz;
    p->heap_brk = (uint64)newbrk;
  }
  return addr;
}

uint64
sys_pause(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  if(n < 0)
    n = 0;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kkill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_getreadcount(void)
{
  extern int read_count;
  extern struct spinlock read_count_lock;
  int count;
  
  acquire(&read_count_lock);
  count = read_count;
  release(&read_count_lock);
  
  return count;
}

// memstat syscall: int memstat(struct proc_mem_stat *info);
uint64
sys_memstat(void)
{
  uint64 user_addr;
  argaddr(0, &user_addr);
  struct proc *p = myproc();
  struct proc_mem_stat kms;
  // initialize
  memset(&kms, 0, sizeof(kms));
  kms.pid = p->pid;
  // Take a brief snapshot of process memory metadata under p->lock
  acquire(&p->lock);
  kms.next_fifo_seq = p->page_seq_ctr;

  // total pages between 0 and p->sz (round up)
  int total_pages = PGROUNDUP(p->sz) / PGSIZE;
  kms.num_pages_total = total_pages;

  // iterate over virtual pages from 0..p->sz and collect up to MAX_PAGES_INFO lowest pages
  int reported = 0;
  int resident = 0;
  int swapped = 0;

  // Count resident and swapped pages by iterating all virtual pages.
  // This ensures pages that are mapped but not present in pgmeta are
  // accounted for in the totals.
  for(int pg = 0; pg < total_pages; pg++){
    uint64 va_pg = (uint64)pg * PGSIZE;
    // try to find pgmeta entry
    int midx = -1;
    for(int mi = 0; mi < PGMETA_SIZE; mi++){
        if(p->pgmeta[mi].va == va_pg){ midx = mi; break; }
      }
    if(midx >= 0){
      if(p->pgmeta[midx].resident) resident++;
      if(p->pgmeta[midx].in_swap) swapped++;
    } else {
      // if not in pgmeta, consult the page table
      if(ismapped(p->pagetable, va_pg)) resident++;
    }
    // Build pages[] report for the lowest pages only
    if(reported < MAX_PAGES_INFO){
      struct page_stat ps;
      ps.va = (uint)va_pg;
      ps.state = UNMAPPED;
      ps.is_dirty = 0;
      ps.seq = 0;
      ps.swap_slot = -1;

      if(midx >= 0){
        if(p->pgmeta[midx].resident) ps.state = RESIDENT;
        else if(p->pgmeta[midx].in_swap) ps.state = SWAPPED;
        ps.is_dirty = p->pgmeta[midx].dirty ? 1 : 0;
        ps.seq = (int)p->pgmeta[midx].seq;
        ps.swap_slot = p->pgmeta[midx].in_swap ? (int)p->pgmeta[midx].slot : -1;
      } else {
        if(ismapped(p->pagetable, va_pg)){
          ps.state = RESIDENT;
        }
      }
      kms.pages[reported++] = ps;
    }
  }
  kms.num_resident_pages = resident;
  kms.num_swapped_pages = swapped;
  release(&p->lock);

  // copy out to user space
  if(either_copyout(1, user_addr, (void*)&kms, sizeof(kms)) < 0)
    return -1;
  return 0;
}
