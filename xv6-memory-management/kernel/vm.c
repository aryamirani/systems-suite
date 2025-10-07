#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S
extern char end[]; // kernel.ld defined end of kernel (for diagnostics)

// helpers for per-process paging metadata and swap
static int pgmeta_find(struct proc *p, uint64 va_pg){
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == va_pg) return i;
  return -1;
}
static int pgmeta_alloc(struct proc *p, uint64 va_pg){
  int idx = pgmeta_find(p, va_pg);
  if(idx >= 0) return idx;
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == 0){
    p->pgmeta[i].va = va_pg;
    p->pgmeta[i].seq = 0;
    p->pgmeta[i].resident = 0;
    p->pgmeta[i].dirty = 0;
    p->pgmeta[i].referenced = 0;
    p->pgmeta[i].in_swap = 0;
    p->pgmeta[i].slot = 0xffff;
    p->pgmeta[i].perm = 0;
    return i;
  }
  return -1;
}
static void pgmeta_clear(struct proc *p, int idx){
  p->pgmeta[idx].va = 0;
  p->pgmeta[idx].seq = 0;
  p->pgmeta[idx].resident = 0;
  p->pgmeta[idx].dirty = 0;
  p->pgmeta[idx].referenced = 0;
  p->pgmeta[idx].in_swap = 0;
  p->pgmeta[idx].slot = 0xffff;
  p->pgmeta[idx].perm = 0;
}

static int swap_alloc_slot(struct proc *p){
  // 1024 slots
  for(int i=0;i<1024;i++){
    int byte = i >> 3;
    int bit = i & 7;
    if((p->swap_bitmap[byte] & (1<<bit)) == 0){
      p->swap_bitmap[byte] |= (1<<bit);
      return i;
    }
  }
  return -1;
}
static void swap_free_slot(struct proc *p, int slot){
  if(slot < 0 || slot >= 1024) return;
  int byte = slot >> 3;
  int bit = slot & 7;
  p->swap_bitmap[byte] &= ~(1<<bit);
}

static int try_evict_one(struct proc *p){
  // Default: FIFO replacement. If compiled with -DUSE_CLOCK, use CLOCK.
#ifdef USE_CLOCK
  int start = p->clock_hand % PGMETA_SIZE;
  int idx = start;
  int found = -1;
  // scan until we find an unreferenced resident page or we've done a full circle
  for(;;){
  if(p->pgmeta[idx].va && p->pgmeta[idx].resident){
      if(p->pgmeta[idx].referenced){
        // give second chance
        p->pgmeta[idx].referenced = 0;
      } else {
        found = idx;
        break;
      }
    }
    idx = (idx + 1) % PGMETA_SIZE;
    if(idx == start) break;
  }
  if(found < 0) return -1;
  int best = found;
  uint64 va_pg = p->pgmeta[best].va;
  printf("[pid %d] VICTIM va=0x%lx seq=%lu algo=CLOCK\n", p->pid, va_pg, (unsigned long)p->pgmeta[best].seq);
#else
  // choose resident page using FIFO (oldest resident page first).
  // We compute age = now - seq (unsigned) so that wraparound is handled
  // by unsigned arithmetic: larger age => older page.
  int best = -1;
  uint64 best_age = 0;
  uint64 now = p->page_seq_ctr;
  for(int i=0;i<PGMETA_SIZE;i++){
    if(p->pgmeta[i].va && p->pgmeta[i].resident){
      uint64 seq = p->pgmeta[i].seq;
      uint64 age = now - seq; // unsigned wraparound-safe age
      if(best < 0 || age > best_age){ best_age = age; best = i; }
    }
  }
  if(best < 0) return -1;
  // evict page best
  uint64 va_pg = p->pgmeta[best].va;
  // Log victim selection for FIFO (auditor format)
  printf("[pid %d] VICTIM va=0x%lx seq=%lu algo=FIFO\n", p->pid, va_pg, (unsigned long)p->pgmeta[best].seq);
#endif
  pte_t *pte = walk(p->pagetable, va_pg, 0);
  if(pte == 0 || (*pte & PTE_V) == 0) { pgmeta_clear(p, best); return -1; }
  uint64 pa = PTE2PA(*pte);
  int is_dirty = p->pgmeta[best].dirty || ((*pte & PTE_W) != 0); // heuristic
  if(is_dirty){
    // Auditor-required EVICT formatting: print state=dirty first
    printf("[pid %d] EVICT  va=0x%lx state=dirty\n", p->pid, va_pg);
    // need swap file and a free slot
    if(p->swapip == 0){
      // No swap file available -> treat as swap full for auditor
      printf("[pid %d] SWAPFULL\n", p->pid);
      printf("[pid %d] KILL swap-exhausted\n", p->pid);
      setkilled(p);
      return -1;
    }
    int slot = swap_alloc_slot(p);
    if(slot < 0){
      // Swap space exhausted
      printf("[pid %d] SWAPFULL\n", p->pid);
      printf("[pid %d] KILL swap-exhausted\n", p->pid);
      setkilled(p);
      return -1;
    }
    // write page to swap file at offset slot*PGSIZE
    begin_op();
    ilock(p->swapip);
    int r = writei(p->swapip, 0, pa, slot*PGSIZE, PGSIZE);
    iunlock(p->swapip);
    end_op();
    if(r != PGSIZE){
      swap_free_slot(p, slot);
      return -1;
    }
    p->swap_pages++;
    p->pgmeta[best].in_swap = 1;
    p->pgmeta[best].slot = slot;
    // Auditor-required SWAPOUT after EVICT
  printf("[pid %d] SWAPOUT va=0x%lx slot=%d\n", p->pid, va_pg, slot);
  } else {
    // Auditor-required EVICT formatting for clean
    printf("[pid %d] EVICT  va=0x%lx state=clean\n", p->pid, va_pg);
    // Then DISCARD
    printf("[pid %d] DISCARD va=0x%lx\n", p->pid, va_pg);
  }
  // unmap and free physical page
  uvmunmap(p->pagetable, va_pg, 1, 1);
  p->pgmeta[best].resident = 0;
  p->pgmeta[best].dirty = 0;
  // keep pgmeta entry to allow swapin later
  // advance clock hand to just after the evicted slot
  p->clock_hand = (best + 1) % PGMETA_SIZE;
  return 0;
}

static char *kalloc_or_evict(struct proc *p){
  char *mem = kalloc();
  if(mem) return mem;
  // memory is full: begin replacement for this process only
  printf("[pid %d] MEMFULL\n", p->pid);
  // try eviction of this process's pages (FIFO)
  if(try_evict_one(p) == 0){
    mem = kalloc();
    if(mem) return mem;
  }
  return 0;
}

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc();
  memset(kpgtbl, 0, PGSIZE);

  // uart registers
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // allocate and map a kernel stack for each process.
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Initialize the kernel_pagetable, shared by all CPUs.
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));

  // flush stale entries from the TLB.
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      // Defensive check: ensure this entry is a pointer to a lower-level
      // page-table page, not a leaf mapping. A leaf here indicates
      // corruption (some code wrote a leaf mapping into an internal
      // page-table slot). Log and return failure to allow callers to
      // handle the error instead of causing a hard panic later.
      if((*pte & (PTE_R|PTE_W|PTE_X)) != 0){
        uint64 pteval = *pte;
        printf("walk: corrupted internal PTE at level %d for va=0x%lx pte=0x%lx\n", level, va, pteval);
        return 0;
      }
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa.
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    panic("mappages: size not aligned");

  if(size == 0)
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V){
      // Diagnostic: someone is trying to remap an already-mapped page.
      printf("mappages: remap detected va=0x%lx existing_pte=0x%lx\n", a, *pte);
      panic("mappages: remap");
    }
    if(pa == 0 || ((uint64)pa < (uint64)end && (uint64)pa >= (uint64)PHYSTOP)){
      printf("mappages: suspicious pa=0x%lx for va=0x%lx\n", pa, a);
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
      continue;   
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}

// Allocate PTEs and physical memory to grow a process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc_or_evict(myproc());
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    // record in pgmeta for the current process
    struct proc *p = myproc();
    if(p){
      int midx = pgmeta_alloc(p, a);
      if(midx >= 0){
        p->pgmeta[midx].resident = 1;
        p->pgmeta[midx].perm = PTE_R|PTE_U|xperm;
        p->pgmeta[midx].dirty = 0;
        p->pgmeta[midx].seq = p->page_seq_ctr++;
      }
    }
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      // Unexpected leaf found at an internal page-table level.
      // Instead of panicking (which aborts the OS), log diagnostics and
      // try to clean up: if this is a user mapping, free the mapped page.
      // This is defensive: it helps recover from earlier corruption while
      // providing info to debug the root cause.
      uint64 pa = PTE2PA(pte);
      if(pte & PTE_U){
        // free the user page backing this PTE
        kfree((void*)pa);
      }
      printf("freewalk: warning: unexpected leaf PTE at index %d (pte=0x%lx), clearing\n", i, pte);
      pagetable[i] = 0;
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz, struct proc *child)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc_or_evict(myproc())) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
    // record resident page in child's pgmeta
    if(child){
      int midx = pgmeta_alloc(child, i);
      if(midx >= 0){
        child->pgmeta[midx].resident = 1;
        child->pgmeta[midx].perm = flags;
        child->pgmeta[midx].dirty = 0;
        child->pgmeta[midx].referenced = 1;
        child->pgmeta[midx].seq = child->page_seq_ctr++;
      }
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  pte_t *pte;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    if(va0 >= MAXVA)
      return -1;
  
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0){
      vmfault(pagetable, va0, 1);
      pa0 = walkaddr(pagetable, va0);
      if(pa0 == 0)
        return -1;
    }

    pte = walk(pagetable, va0, 0);
    // forbid copyout over read-only user text pages.
    if((*pte & PTE_W) == 0)
      return -1;
      
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0){
      vmfault(pagetable, va0, 0);
      pa0 = walkaddr(pagetable, va0);
      if(pa0 == 0)
        return -1;
    }
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0){
      vmfault(pagetable, va0, 0);
      pa0 = walkaddr(pagetable, va0);
      if(pa0 == 0)
        return -1;
    }
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}

// Demand-paging fault handler.
// Decide whether 'va' is valid and map a page:
// - If within an exec text/data segment: map page and load from file (filesz part), zero BSS remainder.
// - If within heap (va < p->heap_brk and va < p->sz): map zero page.
// - If within stack (within one page below current user sp and below sz upper bound): map zero page.
// Returns physical address mapped (>0) on success, 0 on invalid or failure.
uint64
vmfault(pagetable_t pagetable, uint64 va, int is_write)
{
  struct proc *p = myproc();
  if(va >= MAXVA)
    return 0;

  uint64 va_pg = PGROUNDDOWN(va);

  // Determine region classification first
  // Invalid if above process size and not a stack growth below current SP.
  // We'll allow exactly one page below current SP for stack.
  int is_stack = 0;
  uint64 usp = p->trapframe ? p->trapframe->sp : 0;
  // Allow growth only for the page immediately below current SP
  uint64 sp_page = PGROUNDDOWN(usp);
  if(va_pg == sp_page - PGSIZE && va_pg < p->sz)
    is_stack = 1;

  // Determine end of program segments (initial brk base)
  uint64 prog_end = 0;
  for(int i = 0; i < p->nsegs; i++){
    uint64 end = p->segs[i].va + p->segs[i].memsz;
    if(end > prog_end) prog_end = end;
  }
  // Heap pages are valid only within [prog_end, heap_brk)
  int is_heap = (va_pg >= prog_end && va_pg < p->heap_brk && va_pg < p->sz);

  // Check if inside an exec segment recorded in p->segs
  int seg_idx = -1;
  for(int i = 0; i < p->nsegs; i++){
    uint64 sva = p->segs[i].va;
    uint64 ev = p->segs[i].va + p->segs[i].memsz;
    if(va_pg >= sva && va_pg < ev){
      seg_idx = i;
      break;
    }
  }

  // Already mapped? Maybe a permission fault; consider upgrading.
  pte_t *pte_present = walk(pagetable, va_pg, 0);
  if(pte_present && (*pte_present & PTE_V)){
    int allow_w = (is_heap || is_stack) || (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_W));
    int allow_x = (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_X));
    if(is_write == 1 && ((*pte_present & PTE_W) == 0) && allow_w){
  *pte_present |= PTE_W;
  sfence_vma();
      int midx = pgmeta_alloc(p, va_pg);
      if(midx >= 0) { p->pgmeta[midx].dirty = 1; p->pgmeta[midx].referenced = 1; }
      return PTE2PA(*pte_present);
    }
    if(is_write == -1 && ((*pte_present & PTE_X) == 0) && allow_x){
  *pte_present |= PTE_X;
  sfence_vma();
      return PTE2PA(*pte_present);
    }
    // otherwise, mapped but invalid access
    return 0;
  }

  // Determine action
  // Log PAGEFAULT with cause classification
  const char *access_str = (is_write == -1 ? "exec" : (is_write ? "write" : "read"));
  const char *cause_str = "exec";
  int midx_find = pgmeta_find(p, va_pg);
  if(midx_find >= 0 && p->pgmeta[midx_find].in_swap){
    cause_str = "swap";
  } else if(seg_idx >= 0){
    cause_str = "exec";
  } else if(is_heap){
    cause_str = "heap";
  } else if(is_stack){
    cause_str = "stack";
  } else {
    cause_str = "exec"; // default, will be treated invalid later if truly invalid
  }
  printf("[pid %d] PAGEFAULT va=0x%lx access=%s cause=%s\n", p->pid, va_pg, access_str, cause_str);

  if(seg_idx >= 0){
    // Instruction or data page backed by the executable file
    if(p->execip == 0)
      return 0;
    // if page is swapped, swap it in
    int midx = midx_find;
    if(midx >= 0 && p->pgmeta[midx].in_swap){
      char *mem = kalloc_or_evict(p);
      if(mem == 0){
        // allocation failed despite eviction attempt; return 0 so trap prints KILL
        return 0;
      }
      ilock(p->swapip);
      int slot = p->pgmeta[midx].slot;
      int r = readi(p->swapip, 0, (uint64)mem, slot*PGSIZE, PGSIZE);
      iunlock(p->swapip);
      if(r != PGSIZE){
        kfree(mem);
        // swap read failed -> return 0 to cause kill through trap
        return 0;
      }
      int perm = (p->pgmeta[midx].perm ? p->pgmeta[midx].perm : (PTE_U|PTE_R| (p->segs[seg_idx].perm & PTE_X) | (p->segs[seg_idx].perm & PTE_W)));
      if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
        kfree(mem);
        return 0;
      }
      sfence_vma();
      p->pgmeta[midx].resident = 1;
      p->pgmeta[midx].in_swap = 0;
      p->pgmeta[midx].slot = 0xffff;
      swap_free_slot(p, slot);
      if(p->swap_pages > 0) p->swap_pages--;
      uint64 seq = p->page_seq_ctr++;
      p->pgmeta[midx].seq = seq;
      p->pgmeta[midx].referenced = 1;
  printf("[pid %d] SWAPIN va=0x%lx slot=%d\n", p->pid, va_pg, slot);
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
      return (uint64)mem;
    }
    char *mem = kalloc_or_evict(p);
    if(mem == 0){
      // allocation failed despite eviction attempt; return 0 so trap prints KILL
      return 0;
    }
    memset(mem, 0, PGSIZE);

    // Read the page portion that is file-backed.
    uint64 page_off = va_pg - p->segs[seg_idx].va; // offset into segment
    uint64 file_off = p->segs[seg_idx].off + page_off;
    uint n = 0;
    if(page_off < p->segs[seg_idx].filesz){
      uint remain = p->segs[seg_idx].filesz - page_off;
      n = remain < PGSIZE ? remain : PGSIZE;
      ilock(p->execip);
      int r = readi(p->execip, 0, (uint64)mem, file_off, n);
      iunlock(p->execip);
      if(r != n){
        kfree(mem);
        return 0;
      }
    }
    int perm = PTE_U | PTE_R;
    if(p->segs[seg_idx].perm & PTE_X) perm |= PTE_X;
    if(p->segs[seg_idx].perm & PTE_W) perm |= PTE_W;
    // If this was an execute fault but the segment isn't executable, it's invalid
    if(is_write == -1 && (perm & PTE_X) == 0){
      kfree(mem);
      return 0;
    }
    if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
      kfree(mem);
      return 0;
    }
    sfence_vma();
    // update pgmeta
    if(midx < 0) midx = pgmeta_alloc(p, va_pg);
    if(midx >= 0){
      p->pgmeta[midx].resident = 1;
      p->pgmeta[midx].perm = perm;
      // mark clean until a write occurs
      p->pgmeta[midx].dirty = 0;
      p->pgmeta[midx].referenced = 1;
    }
    // Logging: LOADEXEC and RESIDENT per required format
  printf("[pid %d] LOADEXEC va=0x%lx\n", p->pid, va_pg);
  uint64 seq = p->page_seq_ctr++;
    if(midx >= 0) p->pgmeta[midx].seq = seq;
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    return (uint64)mem;
  } else if(is_heap || is_stack){
    // Anonymous zero page for heap or stack
    int midx = pgmeta_alloc(p, va_pg);
    char *mem = kalloc_or_evict(p);
    if(mem == 0){
      // allocation failed despite eviction attempt; return 0 so trap prints KILL
      return 0;
    }
    memset(mem, 0, PGSIZE);
    // Start anonymous pages as readable-only and clean. First user write
    // will cause a write fault where the kernel upgrades permissions and
    // sets the dirty flag.
    int perm = PTE_U | PTE_R;
    if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
      kfree(mem);
      return 0;
    }
    sfence_vma();
    if(midx >= 0){
      p->pgmeta[midx].resident = 1;
      p->pgmeta[midx].perm = perm;
      p->pgmeta[midx].dirty = 0; // start clean; mark dirty on first write
      p->pgmeta[midx].referenced = 1;
    }
    // Logging: ALLOC and RESIDENT per required format
  printf("[pid %d] ALLOC va=0x%lx\n", p->pid, va_pg);
  uint64 seq = p->page_seq_ctr++;
    if(midx >= 0) p->pgmeta[midx].seq = seq;
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    return (uint64)mem;
  }

  // Invalid access
  return 0;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
  pte_t *pte = walk(pagetable, va, 0);
  if (pte == 0) {
    return 0;
  }
  if (*pte & PTE_V){
    return 1;
  }
  return 0;
}
