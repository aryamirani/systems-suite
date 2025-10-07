#include "kernel/types.h"
#include "user/user.h"
#include "kernel/param.h"

// multialloc: spawn N children (default 4). Each child allocates M pages (default 256)
// and touches each page to make it resident and dirty, then pauses to hold memory.

int
main(int argc, char **argv)
{
  int N = 4;
  int M = 256; // pages per child
  if(argc > 1) N = atoi(argv[1]);
  if(argc > 2) M = atoi(argv[2]);

  int i;
  for(i = 0; i < N; i++){
    int pid = fork();
    if(pid < 0){
      printf("multialloc: fork failed\n");
      exit(1);
    }
    if(pid == 0){
      char *pages[M];
      int j;
      for(j = 0; j < M; j++){
        pages[j] = sbrk(4096);
        if(pages[j] == (char*)-1){
          printf("[child %d] sbrk failed at j=%d\n", getpid(), j);
          exit(1);
        }
        // touch page and make it dirty
        pages[j][0] = (char)j;
        if((j & 31) == 0) write(1, ".", 1);
      }
      printf("\n[child %d] done allocations, pausing\n", getpid());
      pause(200); // hold pages
      exit(0);
    }
  }

  // parent: wait for children
  for(i = 0; i < N; i++){
    wait(0);
  }
  printf("multialloc: children finished\n");
  exit(0);
}
