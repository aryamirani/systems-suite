#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

// no eager segment loading; demand paging will load from inode as needed

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    int perm = 0;
    if(flags & 0x1)
      perm = PTE_X;
    if(flags & 0x2)
      perm |= PTE_W;
    return perm;
}

//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
  char *s, *last;
  int i, off;
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();

  begin_op();

  // Open the executable file.
  if((ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    goto bad;

  if((pagetable = proc_pagetable(p)) == 0)
    goto bad;

  // Lazily load program segments: don't map or load now. Record segments.
  p->nsegs = 0;
  // Hold executable inode in process to serve demand faults (keep one ref)
  p->execip = ip;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    if(p->nsegs < 16){
      p->segs[p->nsegs].va = ph.vaddr;
      p->segs[p->nsegs].memsz = ph.memsz;
      p->segs[p->nsegs].filesz = ph.filesz;
      p->segs[p->nsegs].off = ph.off;
      p->segs[p->nsegs].perm = flags2perm(ph.flags);
      p->nsegs++;
    }
    // update process size to cover highest program segment end
    uint64 end = ph.vaddr + ph.memsz;
    if(end > sz) sz = end;
  }
  // release lock but keep a reference via p->execip for demand paging
  iunlock(ip);
  end_op();
  ip = 0;

  p = myproc();
  uint64 oldsz = p->sz;

  // Allocate only the guard + stack pages eagerly; program text/data are demand-paged.
  sz = PGROUNDUP(sz);
  uint64 sz1;
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    goto bad;
  sz = sz1;
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
  sp = sz;
  stackbase = sp - USERSTACK*PGSIZE;

  // Copy argument strings into new stack, remember their
  // addresses in ustack[].
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    if(sp < stackbase)
      goto bad;
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[argc] = sp;
  }
  ustack[argc] = 0;

  // push a copy of ustack[], the array of argv[] pointers.
  sp -= (argc+1) * sizeof(uint64);
  sp -= sp % 16;
  if(sp < stackbase)
    goto bad;
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    goto bad;

  // a0 and a1 contain arguments to user main(argc, argv)
  // argc is returned via the system call return
  // value, which goes in a0.
  p->trapframe->a1 = sp;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
    if(*s == '/')
      last = s+1;
  safestrcpy(p->name, last, sizeof(p->name));
    
  // Commit to the user image.
  oldpagetable = p->pagetable;
  p->pagetable = pagetable;
  p->sz = sz;
  p->trapframe->epc = elf.entry;  // initial program counter = main
  p->trapframe->sp = sp; // initial stack pointer
  p->heap_brk = sz - (USERSTACK+1)*PGSIZE; // heap end at end of program segments
  p->page_seq_ctr = 1; // reset per-process RESIDENT sequence after exec
  proc_freepagetable(oldpagetable, oldsz);

  // initialize swap metadata and create per-process swap file
  memset(p->swap_bitmap, 0, sizeof(p->swap_bitmap));
  p->swap_pages = 0;
  for(int mi=0; mi<PGMETA_SIZE; mi++){
    p->pgmeta[mi].va = 0;
    p->pgmeta[mi].seq = 0;
    p->pgmeta[mi].resident = 0;
    p->pgmeta[mi].dirty = 0;
    p->pgmeta[mi].referenced = 0;
    p->pgmeta[mi].in_swap = 0;
    p->pgmeta[mi].slot = 0xffff;
    p->pgmeta[mi].perm = 0;
  }
  p->clock_hand = 0;
  proc_swapon(p);

  // Emit INIT-LAZYMAP log: text and data ranges, heap_start and stack_top
  uint64 text_lo = 0, text_hi = 0, data_lo = 0, data_hi = 0;
  for(int i = 0; i < p->nsegs; i++){
    uint64 sva = p->segs[i].va;
    uint64 ev = p->segs[i].va + p->segs[i].memsz;
    if(p->segs[i].perm & PTE_X){
      if(text_lo == 0 || sva < text_lo) text_lo = sva;
      if(ev > text_hi) text_hi = ev;
    }
    if(p->segs[i].perm & PTE_W){
      if(data_lo == 0 || sva < data_lo) data_lo = sva;
      if(ev > data_hi) data_hi = ev;
    }
  }
  // heap_start is the end of program segments (p->heap_brk)
  uint64 heap_start = p->heap_brk;
  // stack_top is initial sp
  uint64 stack_top = p->trapframe->sp;
  // print in required bracketed format
  printf("[pid %d] INIT-LAZYMAP text=[0x%lx,0x%lx) data=[0x%lx,0x%lx) heap_start=0x%lx stack_top=0x%lx\n",
         p->pid, text_lo, text_hi, data_lo, data_hi, heap_start, stack_top);

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    // If we recorded execip, we must drop the reference but ip is still locked.
    if(p->execip){
      iunlock(ip);
      iput(ip);
    } else {
      // drop both the lock and reference on error
      iunlockput(ip);
    }
    end_op();
  }
  return -1;
}

// Load an ELF program segment into pagetable at virtual address va.
// va must be page-aligned
// and the pages from va to va+sz must already be mapped.
// Returns 0 on success, -1 on failure.
// removed loadseg: segments are loaded on-demand by vmfault()
