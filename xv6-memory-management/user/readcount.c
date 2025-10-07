#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int initial_count, final_count;
  int fd;
  char buf[100];
  
  // Get initial read count
  initial_count = getreadcount();
  printf("Initial read count: %d\n", initial_count);
  
  // Create a test file and write some data to it
  fd = open("testfile.txt", O_CREATE | O_WRONLY);
  if(fd < 0){
    printf("Error: Cannot create testfile.txt\n");
    exit(1);
  }
  
  // Write 100 bytes to the file
  for(int i = 0; i < 100; i++){
    buf[i] = 'A' + (i % 26); // Fill with letters A-Z repeatedly
  }
  
  if(write(fd, buf, 100) != 100){
    printf("Error: Cannot write to testfile.txt\n");
    close(fd);
    exit(1);
  }
  close(fd);
  
  // Now read the file to trigger read() syscall
  fd = open("testfile.txt", O_RDONLY);
  if(fd < 0){
    printf("Error: Cannot open testfile.txt for reading\n");
    exit(1);
  }
  
  // Read 100 bytes from the file
  int bytes_read = read(fd, buf, 100);
  if(bytes_read != 100){
    printf("Error: Expected to read 100 bytes, but read %d\n", bytes_read);
    close(fd);
    exit(1);
  }
  close(fd);
  
  // Get final read count
  final_count = getreadcount();
  printf("Final read count: %d\n", final_count);
  
  // Verify the increase
  int increase = final_count - initial_count;
  printf("Increase in read count: %d bytes\n", increase);
  
  if(increase >= 100){
    printf("SUCCESS: Read count increased by at least 100 bytes as expected\n");
  } else {
    printf("ERROR: Read count did not increase as expected\n");
  }
  
  // Clean up
  unlink("testfile.txt");
  
  exit(0);
}
