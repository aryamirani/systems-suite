#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main() {
  int n, pid;
  
  printf("Scheduler Test Starting...\n");
  printf("Creating %d processes (%d IO-bound, %d CPU-bound)\n", NFORK, IO, NFORK-IO);
  
  for (n = 0; n < NFORK; n++) {
    pid = fork();
    if (pid < 0) {
      printf("Fork failed for process %d\n", n);
      break;
    }
    if (pid == 0) {
      // Child process
      if (n < IO) {
        printf("Process %d (PID %d): IO-bound starting\n", n, getpid());
        // IO-bound process - simulate I/O with shorter delay and some output
        for (int i = 0; i < 3; i++) {
          printf("IO-bound %d: iteration %d\n", getpid(), i);
          for (volatile int j = 0; j < 50000000; j++) {}  // Shorter delay
        }
        printf("Process %d (PID %d): IO-bound finished\n", n, getpid());
      } else {
        printf("Process %d (PID %d): CPU-bound starting\n", n, getpid());
        // CPU-bound process
        for (int i = 0; i < 3; i++) {
          printf("CPU-bound %d: iteration %d\n", getpid(), i);
          for (volatile int j = 0; j < 100000000; j++) {} // CPU-intensive work
        }
        printf("Process %d (PID %d): CPU-bound finished\n", n, getpid());
      }
      exit(0);
    } else {
      // Parent process
      printf("Created process %d with PID %d (%s)\n", n, pid, (n < IO) ? "IO-bound" : "CPU-bound");
    }
  }
  
  // Parent waits for all children
  printf("Parent waiting for all children to complete...\n");
  for (n = 0; n < NFORK; n++) {
    wait(0);
  }
  
  printf("Scheduler Test Completed - All processes finished\n");
  exit(0);
}
