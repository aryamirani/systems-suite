#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main() {
  int n, pid;
  int p[2];
  int created = 0;

  // Create a pipe to act as a start barrier.
  // Children will block on reading p[0] until parent closes p[1].
  if (pipe(p) < 0) {
    printf("pipe failed\n");
    exit(1);
  }

  printf("Scheduler Test Starting...\n");
  printf("Creating %d processes (%d IO-bound, %d CPU-bound)\n", NFORK, IO, NFORK-IO);
  
  for (n = 0; n < NFORK; n++) {
    pid = fork();
    if (pid < 0) {
      printf("Fork failed for process %d\n", n);
      break;
    }
    if (pid == 0) {
      // Child process: close write end and wait for start signal on read end.
      close(p[1]);
      char dummy;
      // Read will block until parent closes p[1] (EOF) or writes a byte.
      // We don't care about the data; any read/EOF releases the barrier.
      read(p[0], &dummy, 1);
      close(p[0]);

      if (n < IO) {
        printf("Process %d (PID %d): IO-bound starting\n", n, getpid());
        // IO-bound process - simulate I/O with shorter delay and some output
        for (int i = 0; i < 3; i++) {
          printf("IO-bound %d: iteration %d\n", getpid(), i);
          for (volatile int j = 0; j < 50000000; j++) {}
        }
        printf("Process %d (PID %d): IO-bound finished\n", n, getpid());
      } else {
        printf("Process %d (PID %d): CPU-bound starting\n", n, getpid());
        // CPU-bound process
        for (int i = 0; i < 3; i++) {
          printf("CPU-bound %d: iteration %d\n", getpid(), i);
          for (volatile int j = 0; j < 100000000; j++) {}
        }
        printf("Process %d (PID %d): CPU-bound finished\n", n, getpid());
      }
      exit(0);
    } else {
      // Parent process
      printf("Created process %d with PID %d (%s)\n", n, pid, (n < IO) ? "IO-bound" : "CPU-bound");
      created++;
    }
  }

  // Parent: close the read end; then release the barrier by closing the write end.
  close(p[0]);
  // Option A (broadcast via EOF): close write end to let all children proceed at once.
  // Option B (token): write 'created' bytes and keep open. We prefer EOF broadcast.
  close(p[1]);

  // Parent waits for exactly the number of successfully created children.
  printf("Parent waiting for all children to complete...\n");
  for (n = 0; n < created; n++) {
    wait(0);
  }
  
  printf("Scheduler Test Completed - All processes finished\n");
  exit(0);
}
