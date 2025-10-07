#include "kernel/param.h"
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/memlayout.h"

int
main(int argc, char **argv)
{
  // allocate many pages via sbrk to try to exhaust physical memory
  int i;
  char *p[512];
  for(i = 0; i < 512; i++){
    p[i] = sbrk(4096);
    if(p[i] == (char*)-1){
      printf("alloctest: sbrk failed at i=%d\n", i);
      exit(1);
    }
    // touch the page to fault it in
    p[i][0] = 1;
    if((i & 31) == 0) write(1, ".", 1);
  }
  printf("\nalloctest: done allocations\n");
  // hold a bit, then exit
  pause(100);
  exit(0);
}
