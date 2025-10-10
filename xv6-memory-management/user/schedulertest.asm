
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main() {
   0:	7159                	addi	sp,sp,-112
   2:	f486                	sd	ra,104(sp)
   4:	f0a2                	sd	s0,96(sp)
   6:	1880                	addi	s0,sp,112
  int p[2];
  int created = 0;

  // Create a pipe to act as a start barrier.
  // Children will block on reading p[0] until parent closes p[1].
  if (pipe(p) < 0) {
   8:	fa840513          	addi	a0,s0,-88
   c:	4c2000ef          	jal	4ce <pipe>
  10:	04054863          	bltz	a0,60 <main+0x60>
  14:	eca6                	sd	s1,88(sp)
  16:	e8ca                	sd	s2,80(sp)
  18:	e4ce                	sd	s3,72(sp)
  1a:	e0d2                	sd	s4,64(sp)
  1c:	fc56                	sd	s5,56(sp)
  1e:	f85a                	sd	s6,48(sp)
  20:	f45e                	sd	s7,40(sp)
    printf("pipe failed\n");
    exit(1);
  }

  printf("Scheduler Test Starting...\n");
  22:	00001517          	auipc	a0,0x1
  26:	aa650513          	addi	a0,a0,-1370 # ac8 <malloc+0x11e>
  2a:	0cd000ef          	jal	8f6 <printf>
  printf("Creating %d processes (%d IO-bound, %d CPU-bound)\n", NFORK, IO, NFORK-IO);
  2e:	4695                	li	a3,5
  30:	4615                	li	a2,5
  32:	45a9                	li	a1,10
  34:	00001517          	auipc	a0,0x1
  38:	ab450513          	addi	a0,a0,-1356 # ae8 <malloc+0x13e>
  3c:	0bb000ef          	jal	8f6 <printf>
  int created = 0;
  40:	4901                	li	s2,0
        printf("Process %d (PID %d): CPU-bound finished\n", n, getpid());
      }
      exit(0);
    } else {
      // Parent process
      printf("Created process %d with PID %d (%s)\n", n, pid, (n < IO) ? "IO-bound" : "CPU-bound");
  42:	4991                	li	s3,4
  44:	00001b97          	auipc	s7,0x1
  48:	c8cb8b93          	addi	s7,s7,-884 # cd0 <malloc+0x326>
  4c:	00001a17          	auipc	s4,0x1
  50:	c24a0a13          	addi	s4,s4,-988 # c70 <malloc+0x2c6>
  54:	00001b17          	auipc	s6,0x1
  58:	c0cb0b13          	addi	s6,s6,-1012 # c60 <malloc+0x2b6>
  for (n = 0; n < NFORK; n++) {
  5c:	4aa9                	li	s5,10
  5e:	a2b5                	j	1ca <main+0x1ca>
  60:	eca6                	sd	s1,88(sp)
  62:	e8ca                	sd	s2,80(sp)
  64:	e4ce                	sd	s3,72(sp)
  66:	e0d2                	sd	s4,64(sp)
  68:	fc56                	sd	s5,56(sp)
  6a:	f85a                	sd	s6,48(sp)
  6c:	f45e                	sd	s7,40(sp)
    printf("pipe failed\n");
  6e:	00001517          	auipc	a0,0x1
  72:	a4250513          	addi	a0,a0,-1470 # ab0 <malloc+0x106>
  76:	081000ef          	jal	8f6 <printf>
    exit(1);
  7a:	4505                	li	a0,1
  7c:	442000ef          	jal	4be <exit>
      printf("Fork failed for process %d\n", n);
  80:	85ca                	mv	a1,s2
  82:	00001517          	auipc	a0,0x1
  86:	a9e50513          	addi	a0,a0,-1378 # b20 <malloc+0x176>
  8a:	06d000ef          	jal	8f6 <printf>
      created++;
    }
  }

  // Parent: close the read end; then release the barrier by closing the write end.
  close(p[0]);
  8e:	fa842503          	lw	a0,-88(s0)
  92:	454000ef          	jal	4e6 <close>
  // Option A (broadcast via EOF): close write end to let all children proceed at once.
  // Option B (token): write 'created' bytes and keep open. We prefer EOF broadcast.
  close(p[1]);
  96:	fac42503          	lw	a0,-84(s0)
  9a:	44c000ef          	jal	4e6 <close>

  // Parent waits for exactly the number of successfully created children.
  printf("Parent waiting for all children to complete...\n");
  9e:	00001517          	auipc	a0,0x1
  a2:	aa250513          	addi	a0,a0,-1374 # b40 <malloc+0x196>
  a6:	051000ef          	jal	8f6 <printf>
  for (n = 0; n < created; n++) {
  aa:	17204063          	bgtz	s2,20a <main+0x20a>
  ae:	a2ad                	j	218 <main+0x218>
      close(p[1]);
  b0:	fac42503          	lw	a0,-84(s0)
  b4:	432000ef          	jal	4e6 <close>
      read(p[0], &dummy, 1);
  b8:	4605                	li	a2,1
  ba:	f9f40593          	addi	a1,s0,-97
  be:	fa842503          	lw	a0,-88(s0)
  c2:	414000ef          	jal	4d6 <read>
      close(p[0]);
  c6:	fa842503          	lw	a0,-88(s0)
  ca:	41c000ef          	jal	4e6 <close>
      if (n < IO) {
  ce:	4791                	li	a5,4
  d0:	0727cd63          	blt	a5,s2,14a <main+0x14a>
        printf("Process %d (PID %d): IO-bound starting\n", n, getpid());
  d4:	46a000ef          	jal	53e <getpid>
  d8:	862a                	mv	a2,a0
  da:	85ca                	mv	a1,s2
  dc:	00001517          	auipc	a0,0x1
  e0:	a9450513          	addi	a0,a0,-1388 # b70 <malloc+0x1c6>
  e4:	013000ef          	jal	8f6 <printf>
          printf("IO-bound %d: iteration %d\n", getpid(), i);
  e8:	00001a97          	auipc	s5,0x1
  ec:	ab0a8a93          	addi	s5,s5,-1360 # b98 <malloc+0x1ee>
          for (volatile int j = 0; j < 50000000; j++) {}
  f0:	02faf9b7          	lui	s3,0x2faf
  f4:	07f98993          	addi	s3,s3,127 # 2faf07f <base+0x2fad06f>
        for (int i = 0; i < 3; i++) {
  f8:	4a0d                	li	s4,3
          printf("IO-bound %d: iteration %d\n", getpid(), i);
  fa:	444000ef          	jal	53e <getpid>
  fe:	85aa                	mv	a1,a0
 100:	8626                	mv	a2,s1
 102:	8556                	mv	a0,s5
 104:	7f2000ef          	jal	8f6 <printf>
          for (volatile int j = 0; j < 50000000; j++) {}
 108:	fa042023          	sw	zero,-96(s0)
 10c:	fa042783          	lw	a5,-96(s0)
 110:	2781                	sext.w	a5,a5
 112:	00f9cc63          	blt	s3,a5,12a <main+0x12a>
 116:	fa042783          	lw	a5,-96(s0)
 11a:	2785                	addiw	a5,a5,1
 11c:	faf42023          	sw	a5,-96(s0)
 120:	fa042783          	lw	a5,-96(s0)
 124:	2781                	sext.w	a5,a5
 126:	fef9d8e3          	bge	s3,a5,116 <main+0x116>
        for (int i = 0; i < 3; i++) {
 12a:	2485                	addiw	s1,s1,1
 12c:	fd4497e3          	bne	s1,s4,fa <main+0xfa>
        printf("Process %d (PID %d): IO-bound finished\n", n, getpid());
 130:	40e000ef          	jal	53e <getpid>
 134:	862a                	mv	a2,a0
 136:	85ca                	mv	a1,s2
 138:	00001517          	auipc	a0,0x1
 13c:	a8050513          	addi	a0,a0,-1408 # bb8 <malloc+0x20e>
 140:	7b6000ef          	jal	8f6 <printf>
      exit(0);
 144:	4501                	li	a0,0
 146:	378000ef          	jal	4be <exit>
        printf("Process %d (PID %d): CPU-bound starting\n", n, getpid());
 14a:	3f4000ef          	jal	53e <getpid>
 14e:	862a                	mv	a2,a0
 150:	85ca                	mv	a1,s2
 152:	00001517          	auipc	a0,0x1
 156:	a8e50513          	addi	a0,a0,-1394 # be0 <malloc+0x236>
 15a:	79c000ef          	jal	8f6 <printf>
          printf("CPU-bound %d: iteration %d\n", getpid(), i);
 15e:	00001a97          	auipc	s5,0x1
 162:	ab2a8a93          	addi	s5,s5,-1358 # c10 <malloc+0x266>
          for (volatile int j = 0; j < 100000000; j++) {}
 166:	05f5e9b7          	lui	s3,0x5f5e
 16a:	0ff98993          	addi	s3,s3,255 # 5f5e0ff <base+0x5f5c0ef>
        for (int i = 0; i < 3; i++) {
 16e:	4a0d                	li	s4,3
          printf("CPU-bound %d: iteration %d\n", getpid(), i);
 170:	3ce000ef          	jal	53e <getpid>
 174:	85aa                	mv	a1,a0
 176:	8626                	mv	a2,s1
 178:	8556                	mv	a0,s5
 17a:	77c000ef          	jal	8f6 <printf>
          for (volatile int j = 0; j < 100000000; j++) {}
 17e:	fa042223          	sw	zero,-92(s0)
 182:	fa442783          	lw	a5,-92(s0)
 186:	2781                	sext.w	a5,a5
 188:	00f9cc63          	blt	s3,a5,1a0 <main+0x1a0>
 18c:	fa442783          	lw	a5,-92(s0)
 190:	2785                	addiw	a5,a5,1
 192:	faf42223          	sw	a5,-92(s0)
 196:	fa442783          	lw	a5,-92(s0)
 19a:	2781                	sext.w	a5,a5
 19c:	fef9d8e3          	bge	s3,a5,18c <main+0x18c>
        for (int i = 0; i < 3; i++) {
 1a0:	2485                	addiw	s1,s1,1
 1a2:	fd4497e3          	bne	s1,s4,170 <main+0x170>
        printf("Process %d (PID %d): CPU-bound finished\n", n, getpid());
 1a6:	398000ef          	jal	53e <getpid>
 1aa:	862a                	mv	a2,a0
 1ac:	85ca                	mv	a1,s2
 1ae:	00001517          	auipc	a0,0x1
 1b2:	a8250513          	addi	a0,a0,-1406 # c30 <malloc+0x286>
 1b6:	740000ef          	jal	8f6 <printf>
 1ba:	b769                	j	144 <main+0x144>
      printf("Created process %d with PID %d (%s)\n", n, pid, (n < IO) ? "IO-bound" : "CPU-bound");
 1bc:	86de                	mv	a3,s7
 1be:	862a                	mv	a2,a0
 1c0:	85ca                	mv	a1,s2
 1c2:	8552                	mv	a0,s4
 1c4:	732000ef          	jal	8f6 <printf>
      created++;
 1c8:	2905                	addiw	s2,s2,1
    pid = fork();
 1ca:	2ec000ef          	jal	4b6 <fork>
 1ce:	84aa                	mv	s1,a0
    if (pid < 0) {
 1d0:	ea0548e3          	bltz	a0,80 <main+0x80>
    if (pid == 0) {
 1d4:	ec050ee3          	beqz	a0,b0 <main+0xb0>
      printf("Created process %d with PID %d (%s)\n", n, pid, (n < IO) ? "IO-bound" : "CPU-bound");
 1d8:	ff29d2e3          	bge	s3,s2,1bc <main+0x1bc>
 1dc:	86da                	mv	a3,s6
 1de:	862a                	mv	a2,a0
 1e0:	85ca                	mv	a1,s2
 1e2:	8552                	mv	a0,s4
 1e4:	712000ef          	jal	8f6 <printf>
      created++;
 1e8:	2905                	addiw	s2,s2,1
  for (n = 0; n < NFORK; n++) {
 1ea:	ff5910e3          	bne	s2,s5,1ca <main+0x1ca>
  close(p[0]);
 1ee:	fa842503          	lw	a0,-88(s0)
 1f2:	2f4000ef          	jal	4e6 <close>
  close(p[1]);
 1f6:	fac42503          	lw	a0,-84(s0)
 1fa:	2ec000ef          	jal	4e6 <close>
  printf("Parent waiting for all children to complete...\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	94250513          	addi	a0,a0,-1726 # b40 <malloc+0x196>
 206:	6f0000ef          	jal	8f6 <printf>
  int created = 0;
 20a:	4481                	li	s1,0
    wait(0);
 20c:	4501                	li	a0,0
 20e:	2b8000ef          	jal	4c6 <wait>
  for (n = 0; n < created; n++) {
 212:	2485                	addiw	s1,s1,1
 214:	fe991ce3          	bne	s2,s1,20c <main+0x20c>
  }
  
  printf("Scheduler Test Completed - All processes finished\n");
 218:	00001517          	auipc	a0,0x1
 21c:	a8050513          	addi	a0,a0,-1408 # c98 <malloc+0x2ee>
 220:	6d6000ef          	jal	8f6 <printf>
  exit(0);
 224:	4501                	li	a0,0
 226:	298000ef          	jal	4be <exit>

000000000000022a <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e406                	sd	ra,8(sp)
 22e:	e022                	sd	s0,0(sp)
 230:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 232:	dcfff0ef          	jal	0 <main>
  exit(r);
 236:	288000ef          	jal	4be <exit>

000000000000023a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 23a:	1141                	addi	sp,sp,-16
 23c:	e422                	sd	s0,8(sp)
 23e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 240:	87aa                	mv	a5,a0
 242:	0585                	addi	a1,a1,1
 244:	0785                	addi	a5,a5,1
 246:	fff5c703          	lbu	a4,-1(a1)
 24a:	fee78fa3          	sb	a4,-1(a5)
 24e:	fb75                	bnez	a4,242 <strcpy+0x8>
    ;
  return os;
}
 250:	6422                	ld	s0,8(sp)
 252:	0141                	addi	sp,sp,16
 254:	8082                	ret

0000000000000256 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 256:	1141                	addi	sp,sp,-16
 258:	e422                	sd	s0,8(sp)
 25a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 25c:	00054783          	lbu	a5,0(a0)
 260:	cb91                	beqz	a5,274 <strcmp+0x1e>
 262:	0005c703          	lbu	a4,0(a1)
 266:	00f71763          	bne	a4,a5,274 <strcmp+0x1e>
    p++, q++;
 26a:	0505                	addi	a0,a0,1
 26c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 26e:	00054783          	lbu	a5,0(a0)
 272:	fbe5                	bnez	a5,262 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 274:	0005c503          	lbu	a0,0(a1)
}
 278:	40a7853b          	subw	a0,a5,a0
 27c:	6422                	ld	s0,8(sp)
 27e:	0141                	addi	sp,sp,16
 280:	8082                	ret

0000000000000282 <strlen>:

uint
strlen(const char *s)
{
 282:	1141                	addi	sp,sp,-16
 284:	e422                	sd	s0,8(sp)
 286:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 288:	00054783          	lbu	a5,0(a0)
 28c:	cf91                	beqz	a5,2a8 <strlen+0x26>
 28e:	0505                	addi	a0,a0,1
 290:	87aa                	mv	a5,a0
 292:	86be                	mv	a3,a5
 294:	0785                	addi	a5,a5,1
 296:	fff7c703          	lbu	a4,-1(a5)
 29a:	ff65                	bnez	a4,292 <strlen+0x10>
 29c:	40a6853b          	subw	a0,a3,a0
 2a0:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 2a2:	6422                	ld	s0,8(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret
  for(n = 0; s[n]; n++)
 2a8:	4501                	li	a0,0
 2aa:	bfe5                	j	2a2 <strlen+0x20>

00000000000002ac <memset>:

void*
memset(void *dst, int c, uint n)
{
 2ac:	1141                	addi	sp,sp,-16
 2ae:	e422                	sd	s0,8(sp)
 2b0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2b2:	ca19                	beqz	a2,2c8 <memset+0x1c>
 2b4:	87aa                	mv	a5,a0
 2b6:	1602                	slli	a2,a2,0x20
 2b8:	9201                	srli	a2,a2,0x20
 2ba:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2be:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2c2:	0785                	addi	a5,a5,1
 2c4:	fee79de3          	bne	a5,a4,2be <memset+0x12>
  }
  return dst;
}
 2c8:	6422                	ld	s0,8(sp)
 2ca:	0141                	addi	sp,sp,16
 2cc:	8082                	ret

00000000000002ce <strchr>:

char*
strchr(const char *s, char c)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2d4:	00054783          	lbu	a5,0(a0)
 2d8:	cb99                	beqz	a5,2ee <strchr+0x20>
    if(*s == c)
 2da:	00f58763          	beq	a1,a5,2e8 <strchr+0x1a>
  for(; *s; s++)
 2de:	0505                	addi	a0,a0,1
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	fbfd                	bnez	a5,2da <strchr+0xc>
      return (char*)s;
  return 0;
 2e6:	4501                	li	a0,0
}
 2e8:	6422                	ld	s0,8(sp)
 2ea:	0141                	addi	sp,sp,16
 2ec:	8082                	ret
  return 0;
 2ee:	4501                	li	a0,0
 2f0:	bfe5                	j	2e8 <strchr+0x1a>

00000000000002f2 <gets>:

char*
gets(char *buf, int max)
{
 2f2:	711d                	addi	sp,sp,-96
 2f4:	ec86                	sd	ra,88(sp)
 2f6:	e8a2                	sd	s0,80(sp)
 2f8:	e4a6                	sd	s1,72(sp)
 2fa:	e0ca                	sd	s2,64(sp)
 2fc:	fc4e                	sd	s3,56(sp)
 2fe:	f852                	sd	s4,48(sp)
 300:	f456                	sd	s5,40(sp)
 302:	f05a                	sd	s6,32(sp)
 304:	ec5e                	sd	s7,24(sp)
 306:	1080                	addi	s0,sp,96
 308:	8baa                	mv	s7,a0
 30a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 30c:	892a                	mv	s2,a0
 30e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 310:	4aa9                	li	s5,10
 312:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 314:	89a6                	mv	s3,s1
 316:	2485                	addiw	s1,s1,1
 318:	0344d663          	bge	s1,s4,344 <gets+0x52>
    cc = read(0, &c, 1);
 31c:	4605                	li	a2,1
 31e:	faf40593          	addi	a1,s0,-81
 322:	4501                	li	a0,0
 324:	1b2000ef          	jal	4d6 <read>
    if(cc < 1)
 328:	00a05e63          	blez	a0,344 <gets+0x52>
    buf[i++] = c;
 32c:	faf44783          	lbu	a5,-81(s0)
 330:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 334:	01578763          	beq	a5,s5,342 <gets+0x50>
 338:	0905                	addi	s2,s2,1
 33a:	fd679de3          	bne	a5,s6,314 <gets+0x22>
    buf[i++] = c;
 33e:	89a6                	mv	s3,s1
 340:	a011                	j	344 <gets+0x52>
 342:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 344:	99de                	add	s3,s3,s7
 346:	00098023          	sb	zero,0(s3)
  return buf;
}
 34a:	855e                	mv	a0,s7
 34c:	60e6                	ld	ra,88(sp)
 34e:	6446                	ld	s0,80(sp)
 350:	64a6                	ld	s1,72(sp)
 352:	6906                	ld	s2,64(sp)
 354:	79e2                	ld	s3,56(sp)
 356:	7a42                	ld	s4,48(sp)
 358:	7aa2                	ld	s5,40(sp)
 35a:	7b02                	ld	s6,32(sp)
 35c:	6be2                	ld	s7,24(sp)
 35e:	6125                	addi	sp,sp,96
 360:	8082                	ret

0000000000000362 <stat>:

int
stat(const char *n, struct stat *st)
{
 362:	1101                	addi	sp,sp,-32
 364:	ec06                	sd	ra,24(sp)
 366:	e822                	sd	s0,16(sp)
 368:	e04a                	sd	s2,0(sp)
 36a:	1000                	addi	s0,sp,32
 36c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 36e:	4581                	li	a1,0
 370:	18e000ef          	jal	4fe <open>
  if(fd < 0)
 374:	02054263          	bltz	a0,398 <stat+0x36>
 378:	e426                	sd	s1,8(sp)
 37a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 37c:	85ca                	mv	a1,s2
 37e:	198000ef          	jal	516 <fstat>
 382:	892a                	mv	s2,a0
  close(fd);
 384:	8526                	mv	a0,s1
 386:	160000ef          	jal	4e6 <close>
  return r;
 38a:	64a2                	ld	s1,8(sp)
}
 38c:	854a                	mv	a0,s2
 38e:	60e2                	ld	ra,24(sp)
 390:	6442                	ld	s0,16(sp)
 392:	6902                	ld	s2,0(sp)
 394:	6105                	addi	sp,sp,32
 396:	8082                	ret
    return -1;
 398:	597d                	li	s2,-1
 39a:	bfcd                	j	38c <stat+0x2a>

000000000000039c <atoi>:

int
atoi(const char *s)
{
 39c:	1141                	addi	sp,sp,-16
 39e:	e422                	sd	s0,8(sp)
 3a0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3a2:	00054683          	lbu	a3,0(a0)
 3a6:	fd06879b          	addiw	a5,a3,-48
 3aa:	0ff7f793          	zext.b	a5,a5
 3ae:	4625                	li	a2,9
 3b0:	02f66863          	bltu	a2,a5,3e0 <atoi+0x44>
 3b4:	872a                	mv	a4,a0
  n = 0;
 3b6:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 3b8:	0705                	addi	a4,a4,1
 3ba:	0025179b          	slliw	a5,a0,0x2
 3be:	9fa9                	addw	a5,a5,a0
 3c0:	0017979b          	slliw	a5,a5,0x1
 3c4:	9fb5                	addw	a5,a5,a3
 3c6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3ca:	00074683          	lbu	a3,0(a4)
 3ce:	fd06879b          	addiw	a5,a3,-48
 3d2:	0ff7f793          	zext.b	a5,a5
 3d6:	fef671e3          	bgeu	a2,a5,3b8 <atoi+0x1c>
  return n;
}
 3da:	6422                	ld	s0,8(sp)
 3dc:	0141                	addi	sp,sp,16
 3de:	8082                	ret
  n = 0;
 3e0:	4501                	li	a0,0
 3e2:	bfe5                	j	3da <atoi+0x3e>

00000000000003e4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3e4:	1141                	addi	sp,sp,-16
 3e6:	e422                	sd	s0,8(sp)
 3e8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3ea:	02b57463          	bgeu	a0,a1,412 <memmove+0x2e>
    while(n-- > 0)
 3ee:	00c05f63          	blez	a2,40c <memmove+0x28>
 3f2:	1602                	slli	a2,a2,0x20
 3f4:	9201                	srli	a2,a2,0x20
 3f6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 3fa:	872a                	mv	a4,a0
      *dst++ = *src++;
 3fc:	0585                	addi	a1,a1,1
 3fe:	0705                	addi	a4,a4,1
 400:	fff5c683          	lbu	a3,-1(a1)
 404:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 408:	fef71ae3          	bne	a4,a5,3fc <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 40c:	6422                	ld	s0,8(sp)
 40e:	0141                	addi	sp,sp,16
 410:	8082                	ret
    dst += n;
 412:	00c50733          	add	a4,a0,a2
    src += n;
 416:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 418:	fec05ae3          	blez	a2,40c <memmove+0x28>
 41c:	fff6079b          	addiw	a5,a2,-1
 420:	1782                	slli	a5,a5,0x20
 422:	9381                	srli	a5,a5,0x20
 424:	fff7c793          	not	a5,a5
 428:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 42a:	15fd                	addi	a1,a1,-1
 42c:	177d                	addi	a4,a4,-1
 42e:	0005c683          	lbu	a3,0(a1)
 432:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 436:	fee79ae3          	bne	a5,a4,42a <memmove+0x46>
 43a:	bfc9                	j	40c <memmove+0x28>

000000000000043c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 43c:	1141                	addi	sp,sp,-16
 43e:	e422                	sd	s0,8(sp)
 440:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 442:	ca05                	beqz	a2,472 <memcmp+0x36>
 444:	fff6069b          	addiw	a3,a2,-1
 448:	1682                	slli	a3,a3,0x20
 44a:	9281                	srli	a3,a3,0x20
 44c:	0685                	addi	a3,a3,1
 44e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 450:	00054783          	lbu	a5,0(a0)
 454:	0005c703          	lbu	a4,0(a1)
 458:	00e79863          	bne	a5,a4,468 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 45c:	0505                	addi	a0,a0,1
    p2++;
 45e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 460:	fed518e3          	bne	a0,a3,450 <memcmp+0x14>
  }
  return 0;
 464:	4501                	li	a0,0
 466:	a019                	j	46c <memcmp+0x30>
      return *p1 - *p2;
 468:	40e7853b          	subw	a0,a5,a4
}
 46c:	6422                	ld	s0,8(sp)
 46e:	0141                	addi	sp,sp,16
 470:	8082                	ret
  return 0;
 472:	4501                	li	a0,0
 474:	bfe5                	j	46c <memcmp+0x30>

0000000000000476 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 476:	1141                	addi	sp,sp,-16
 478:	e406                	sd	ra,8(sp)
 47a:	e022                	sd	s0,0(sp)
 47c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 47e:	f67ff0ef          	jal	3e4 <memmove>
}
 482:	60a2                	ld	ra,8(sp)
 484:	6402                	ld	s0,0(sp)
 486:	0141                	addi	sp,sp,16
 488:	8082                	ret

000000000000048a <sbrk>:

char *
sbrk(int n) {
 48a:	1141                	addi	sp,sp,-16
 48c:	e406                	sd	ra,8(sp)
 48e:	e022                	sd	s0,0(sp)
 490:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 492:	4585                	li	a1,1
 494:	0b2000ef          	jal	546 <sys_sbrk>
}
 498:	60a2                	ld	ra,8(sp)
 49a:	6402                	ld	s0,0(sp)
 49c:	0141                	addi	sp,sp,16
 49e:	8082                	ret

00000000000004a0 <sbrklazy>:

char *
sbrklazy(int n) {
 4a0:	1141                	addi	sp,sp,-16
 4a2:	e406                	sd	ra,8(sp)
 4a4:	e022                	sd	s0,0(sp)
 4a6:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 4a8:	4589                	li	a1,2
 4aa:	09c000ef          	jal	546 <sys_sbrk>
}
 4ae:	60a2                	ld	ra,8(sp)
 4b0:	6402                	ld	s0,0(sp)
 4b2:	0141                	addi	sp,sp,16
 4b4:	8082                	ret

00000000000004b6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4b6:	4885                	li	a7,1
 ecall
 4b8:	00000073          	ecall
 ret
 4bc:	8082                	ret

00000000000004be <exit>:
.global exit
exit:
 li a7, SYS_exit
 4be:	4889                	li	a7,2
 ecall
 4c0:	00000073          	ecall
 ret
 4c4:	8082                	ret

00000000000004c6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4c6:	488d                	li	a7,3
 ecall
 4c8:	00000073          	ecall
 ret
 4cc:	8082                	ret

00000000000004ce <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4ce:	4891                	li	a7,4
 ecall
 4d0:	00000073          	ecall
 ret
 4d4:	8082                	ret

00000000000004d6 <read>:
.global read
read:
 li a7, SYS_read
 4d6:	4895                	li	a7,5
 ecall
 4d8:	00000073          	ecall
 ret
 4dc:	8082                	ret

00000000000004de <write>:
.global write
write:
 li a7, SYS_write
 4de:	48c1                	li	a7,16
 ecall
 4e0:	00000073          	ecall
 ret
 4e4:	8082                	ret

00000000000004e6 <close>:
.global close
close:
 li a7, SYS_close
 4e6:	48d5                	li	a7,21
 ecall
 4e8:	00000073          	ecall
 ret
 4ec:	8082                	ret

00000000000004ee <kill>:
.global kill
kill:
 li a7, SYS_kill
 4ee:	4899                	li	a7,6
 ecall
 4f0:	00000073          	ecall
 ret
 4f4:	8082                	ret

00000000000004f6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4f6:	489d                	li	a7,7
 ecall
 4f8:	00000073          	ecall
 ret
 4fc:	8082                	ret

00000000000004fe <open>:
.global open
open:
 li a7, SYS_open
 4fe:	48bd                	li	a7,15
 ecall
 500:	00000073          	ecall
 ret
 504:	8082                	ret

0000000000000506 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 506:	48c5                	li	a7,17
 ecall
 508:	00000073          	ecall
 ret
 50c:	8082                	ret

000000000000050e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 50e:	48c9                	li	a7,18
 ecall
 510:	00000073          	ecall
 ret
 514:	8082                	ret

0000000000000516 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 516:	48a1                	li	a7,8
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <link>:
.global link
link:
 li a7, SYS_link
 51e:	48cd                	li	a7,19
 ecall
 520:	00000073          	ecall
 ret
 524:	8082                	ret

0000000000000526 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 526:	48d1                	li	a7,20
 ecall
 528:	00000073          	ecall
 ret
 52c:	8082                	ret

000000000000052e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 52e:	48a5                	li	a7,9
 ecall
 530:	00000073          	ecall
 ret
 534:	8082                	ret

0000000000000536 <dup>:
.global dup
dup:
 li a7, SYS_dup
 536:	48a9                	li	a7,10
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 53e:	48ad                	li	a7,11
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 546:	48b1                	li	a7,12
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <pause>:
.global pause
pause:
 li a7, SYS_pause
 54e:	48b5                	li	a7,13
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 556:	48b9                	li	a7,14
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 55e:	48d9                	li	a7,22
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <memstat>:
.global memstat
memstat:
 li a7, SYS_memstat
 566:	48dd                	li	a7,23
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 56e:	1101                	addi	sp,sp,-32
 570:	ec06                	sd	ra,24(sp)
 572:	e822                	sd	s0,16(sp)
 574:	1000                	addi	s0,sp,32
 576:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 57a:	4605                	li	a2,1
 57c:	fef40593          	addi	a1,s0,-17
 580:	f5fff0ef          	jal	4de <write>
}
 584:	60e2                	ld	ra,24(sp)
 586:	6442                	ld	s0,16(sp)
 588:	6105                	addi	sp,sp,32
 58a:	8082                	ret

000000000000058c <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 58c:	715d                	addi	sp,sp,-80
 58e:	e486                	sd	ra,72(sp)
 590:	e0a2                	sd	s0,64(sp)
 592:	f84a                	sd	s2,48(sp)
 594:	0880                	addi	s0,sp,80
 596:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 598:	c299                	beqz	a3,59e <printint+0x12>
 59a:	0805c363          	bltz	a1,620 <printint+0x94>
  neg = 0;
 59e:	4881                	li	a7,0
 5a0:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 5a4:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 5a6:	00000517          	auipc	a0,0x0
 5aa:	74250513          	addi	a0,a0,1858 # ce8 <digits>
 5ae:	883e                	mv	a6,a5
 5b0:	2785                	addiw	a5,a5,1
 5b2:	02c5f733          	remu	a4,a1,a2
 5b6:	972a                	add	a4,a4,a0
 5b8:	00074703          	lbu	a4,0(a4)
 5bc:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 5c0:	872e                	mv	a4,a1
 5c2:	02c5d5b3          	divu	a1,a1,a2
 5c6:	0685                	addi	a3,a3,1
 5c8:	fec773e3          	bgeu	a4,a2,5ae <printint+0x22>
  if(neg)
 5cc:	00088b63          	beqz	a7,5e2 <printint+0x56>
    buf[i++] = '-';
 5d0:	fd078793          	addi	a5,a5,-48
 5d4:	97a2                	add	a5,a5,s0
 5d6:	02d00713          	li	a4,45
 5da:	fee78423          	sb	a4,-24(a5)
 5de:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 5e2:	02f05a63          	blez	a5,616 <printint+0x8a>
 5e6:	fc26                	sd	s1,56(sp)
 5e8:	f44e                	sd	s3,40(sp)
 5ea:	fb840713          	addi	a4,s0,-72
 5ee:	00f704b3          	add	s1,a4,a5
 5f2:	fff70993          	addi	s3,a4,-1
 5f6:	99be                	add	s3,s3,a5
 5f8:	37fd                	addiw	a5,a5,-1
 5fa:	1782                	slli	a5,a5,0x20
 5fc:	9381                	srli	a5,a5,0x20
 5fe:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 602:	fff4c583          	lbu	a1,-1(s1)
 606:	854a                	mv	a0,s2
 608:	f67ff0ef          	jal	56e <putc>
  while(--i >= 0)
 60c:	14fd                	addi	s1,s1,-1
 60e:	ff349ae3          	bne	s1,s3,602 <printint+0x76>
 612:	74e2                	ld	s1,56(sp)
 614:	79a2                	ld	s3,40(sp)
}
 616:	60a6                	ld	ra,72(sp)
 618:	6406                	ld	s0,64(sp)
 61a:	7942                	ld	s2,48(sp)
 61c:	6161                	addi	sp,sp,80
 61e:	8082                	ret
    x = -xx;
 620:	40b005b3          	neg	a1,a1
    neg = 1;
 624:	4885                	li	a7,1
    x = -xx;
 626:	bfad                	j	5a0 <printint+0x14>

0000000000000628 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 628:	711d                	addi	sp,sp,-96
 62a:	ec86                	sd	ra,88(sp)
 62c:	e8a2                	sd	s0,80(sp)
 62e:	e0ca                	sd	s2,64(sp)
 630:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 632:	0005c903          	lbu	s2,0(a1)
 636:	28090663          	beqz	s2,8c2 <vprintf+0x29a>
 63a:	e4a6                	sd	s1,72(sp)
 63c:	fc4e                	sd	s3,56(sp)
 63e:	f852                	sd	s4,48(sp)
 640:	f456                	sd	s5,40(sp)
 642:	f05a                	sd	s6,32(sp)
 644:	ec5e                	sd	s7,24(sp)
 646:	e862                	sd	s8,16(sp)
 648:	e466                	sd	s9,8(sp)
 64a:	8b2a                	mv	s6,a0
 64c:	8a2e                	mv	s4,a1
 64e:	8bb2                	mv	s7,a2
  state = 0;
 650:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 652:	4481                	li	s1,0
 654:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 656:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 65a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 65e:	06c00c93          	li	s9,108
 662:	a005                	j	682 <vprintf+0x5a>
        putc(fd, c0);
 664:	85ca                	mv	a1,s2
 666:	855a                	mv	a0,s6
 668:	f07ff0ef          	jal	56e <putc>
 66c:	a019                	j	672 <vprintf+0x4a>
    } else if(state == '%'){
 66e:	03598263          	beq	s3,s5,692 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
 672:	2485                	addiw	s1,s1,1
 674:	8726                	mv	a4,s1
 676:	009a07b3          	add	a5,s4,s1
 67a:	0007c903          	lbu	s2,0(a5)
 67e:	22090a63          	beqz	s2,8b2 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
 682:	0009079b          	sext.w	a5,s2
    if(state == 0){
 686:	fe0994e3          	bnez	s3,66e <vprintf+0x46>
      if(c0 == '%'){
 68a:	fd579de3          	bne	a5,s5,664 <vprintf+0x3c>
        state = '%';
 68e:	89be                	mv	s3,a5
 690:	b7cd                	j	672 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
 692:	00ea06b3          	add	a3,s4,a4
 696:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 69a:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 69c:	c681                	beqz	a3,6a4 <vprintf+0x7c>
 69e:	9752                	add	a4,a4,s4
 6a0:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 6a4:	05878363          	beq	a5,s8,6ea <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
 6a8:	05978d63          	beq	a5,s9,702 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 6ac:	07500713          	li	a4,117
 6b0:	0ee78763          	beq	a5,a4,79e <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 6b4:	07800713          	li	a4,120
 6b8:	12e78963          	beq	a5,a4,7ea <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 6bc:	07000713          	li	a4,112
 6c0:	14e78e63          	beq	a5,a4,81c <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 6c4:	06300713          	li	a4,99
 6c8:	18e78e63          	beq	a5,a4,864 <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 6cc:	07300713          	li	a4,115
 6d0:	1ae78463          	beq	a5,a4,878 <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 6d4:	02500713          	li	a4,37
 6d8:	04e79563          	bne	a5,a4,722 <vprintf+0xfa>
        putc(fd, '%');
 6dc:	02500593          	li	a1,37
 6e0:	855a                	mv	a0,s6
 6e2:	e8dff0ef          	jal	56e <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 6e6:	4981                	li	s3,0
 6e8:	b769                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
 6ea:	008b8913          	addi	s2,s7,8
 6ee:	4685                	li	a3,1
 6f0:	4629                	li	a2,10
 6f2:	000ba583          	lw	a1,0(s7)
 6f6:	855a                	mv	a0,s6
 6f8:	e95ff0ef          	jal	58c <printint>
 6fc:	8bca                	mv	s7,s2
      state = 0;
 6fe:	4981                	li	s3,0
 700:	bf8d                	j	672 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
 702:	06400793          	li	a5,100
 706:	02f68963          	beq	a3,a5,738 <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 70a:	06c00793          	li	a5,108
 70e:	04f68263          	beq	a3,a5,752 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
 712:	07500793          	li	a5,117
 716:	0af68063          	beq	a3,a5,7b6 <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
 71a:	07800793          	li	a5,120
 71e:	0ef68263          	beq	a3,a5,802 <vprintf+0x1da>
        putc(fd, '%');
 722:	02500593          	li	a1,37
 726:	855a                	mv	a0,s6
 728:	e47ff0ef          	jal	56e <putc>
        putc(fd, c0);
 72c:	85ca                	mv	a1,s2
 72e:	855a                	mv	a0,s6
 730:	e3fff0ef          	jal	56e <putc>
      state = 0;
 734:	4981                	li	s3,0
 736:	bf35                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 738:	008b8913          	addi	s2,s7,8
 73c:	4685                	li	a3,1
 73e:	4629                	li	a2,10
 740:	000bb583          	ld	a1,0(s7)
 744:	855a                	mv	a0,s6
 746:	e47ff0ef          	jal	58c <printint>
        i += 1;
 74a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 74c:	8bca                	mv	s7,s2
      state = 0;
 74e:	4981                	li	s3,0
        i += 1;
 750:	b70d                	j	672 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 752:	06400793          	li	a5,100
 756:	02f60763          	beq	a2,a5,784 <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 75a:	07500793          	li	a5,117
 75e:	06f60963          	beq	a2,a5,7d0 <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 762:	07800793          	li	a5,120
 766:	faf61ee3          	bne	a2,a5,722 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 76a:	008b8913          	addi	s2,s7,8
 76e:	4681                	li	a3,0
 770:	4641                	li	a2,16
 772:	000bb583          	ld	a1,0(s7)
 776:	855a                	mv	a0,s6
 778:	e15ff0ef          	jal	58c <printint>
        i += 2;
 77c:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 77e:	8bca                	mv	s7,s2
      state = 0;
 780:	4981                	li	s3,0
        i += 2;
 782:	bdc5                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 784:	008b8913          	addi	s2,s7,8
 788:	4685                	li	a3,1
 78a:	4629                	li	a2,10
 78c:	000bb583          	ld	a1,0(s7)
 790:	855a                	mv	a0,s6
 792:	dfbff0ef          	jal	58c <printint>
        i += 2;
 796:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 798:	8bca                	mv	s7,s2
      state = 0;
 79a:	4981                	li	s3,0
        i += 2;
 79c:	bdd9                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 79e:	008b8913          	addi	s2,s7,8
 7a2:	4681                	li	a3,0
 7a4:	4629                	li	a2,10
 7a6:	000be583          	lwu	a1,0(s7)
 7aa:	855a                	mv	a0,s6
 7ac:	de1ff0ef          	jal	58c <printint>
 7b0:	8bca                	mv	s7,s2
      state = 0;
 7b2:	4981                	li	s3,0
 7b4:	bd7d                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7b6:	008b8913          	addi	s2,s7,8
 7ba:	4681                	li	a3,0
 7bc:	4629                	li	a2,10
 7be:	000bb583          	ld	a1,0(s7)
 7c2:	855a                	mv	a0,s6
 7c4:	dc9ff0ef          	jal	58c <printint>
        i += 1;
 7c8:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 7ca:	8bca                	mv	s7,s2
      state = 0;
 7cc:	4981                	li	s3,0
        i += 1;
 7ce:	b555                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7d0:	008b8913          	addi	s2,s7,8
 7d4:	4681                	li	a3,0
 7d6:	4629                	li	a2,10
 7d8:	000bb583          	ld	a1,0(s7)
 7dc:	855a                	mv	a0,s6
 7de:	dafff0ef          	jal	58c <printint>
        i += 2;
 7e2:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 7e4:	8bca                	mv	s7,s2
      state = 0;
 7e6:	4981                	li	s3,0
        i += 2;
 7e8:	b569                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 7ea:	008b8913          	addi	s2,s7,8
 7ee:	4681                	li	a3,0
 7f0:	4641                	li	a2,16
 7f2:	000be583          	lwu	a1,0(s7)
 7f6:	855a                	mv	a0,s6
 7f8:	d95ff0ef          	jal	58c <printint>
 7fc:	8bca                	mv	s7,s2
      state = 0;
 7fe:	4981                	li	s3,0
 800:	bd8d                	j	672 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 802:	008b8913          	addi	s2,s7,8
 806:	4681                	li	a3,0
 808:	4641                	li	a2,16
 80a:	000bb583          	ld	a1,0(s7)
 80e:	855a                	mv	a0,s6
 810:	d7dff0ef          	jal	58c <printint>
        i += 1;
 814:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 816:	8bca                	mv	s7,s2
      state = 0;
 818:	4981                	li	s3,0
        i += 1;
 81a:	bda1                	j	672 <vprintf+0x4a>
 81c:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
 81e:	008b8d13          	addi	s10,s7,8
 822:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 826:	03000593          	li	a1,48
 82a:	855a                	mv	a0,s6
 82c:	d43ff0ef          	jal	56e <putc>
  putc(fd, 'x');
 830:	07800593          	li	a1,120
 834:	855a                	mv	a0,s6
 836:	d39ff0ef          	jal	56e <putc>
 83a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 83c:	00000b97          	auipc	s7,0x0
 840:	4acb8b93          	addi	s7,s7,1196 # ce8 <digits>
 844:	03c9d793          	srli	a5,s3,0x3c
 848:	97de                	add	a5,a5,s7
 84a:	0007c583          	lbu	a1,0(a5)
 84e:	855a                	mv	a0,s6
 850:	d1fff0ef          	jal	56e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 854:	0992                	slli	s3,s3,0x4
 856:	397d                	addiw	s2,s2,-1
 858:	fe0916e3          	bnez	s2,844 <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
 85c:	8bea                	mv	s7,s10
      state = 0;
 85e:	4981                	li	s3,0
 860:	6d02                	ld	s10,0(sp)
 862:	bd01                	j	672 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
 864:	008b8913          	addi	s2,s7,8
 868:	000bc583          	lbu	a1,0(s7)
 86c:	855a                	mv	a0,s6
 86e:	d01ff0ef          	jal	56e <putc>
 872:	8bca                	mv	s7,s2
      state = 0;
 874:	4981                	li	s3,0
 876:	bbf5                	j	672 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
 878:	008b8993          	addi	s3,s7,8
 87c:	000bb903          	ld	s2,0(s7)
 880:	00090f63          	beqz	s2,89e <vprintf+0x276>
        for(; *s; s++)
 884:	00094583          	lbu	a1,0(s2)
 888:	c195                	beqz	a1,8ac <vprintf+0x284>
          putc(fd, *s);
 88a:	855a                	mv	a0,s6
 88c:	ce3ff0ef          	jal	56e <putc>
        for(; *s; s++)
 890:	0905                	addi	s2,s2,1
 892:	00094583          	lbu	a1,0(s2)
 896:	f9f5                	bnez	a1,88a <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 898:	8bce                	mv	s7,s3
      state = 0;
 89a:	4981                	li	s3,0
 89c:	bbd9                	j	672 <vprintf+0x4a>
          s = "(null)";
 89e:	00000917          	auipc	s2,0x0
 8a2:	44290913          	addi	s2,s2,1090 # ce0 <malloc+0x336>
        for(; *s; s++)
 8a6:	02800593          	li	a1,40
 8aa:	b7c5                	j	88a <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 8ac:	8bce                	mv	s7,s3
      state = 0;
 8ae:	4981                	li	s3,0
 8b0:	b3c9                	j	672 <vprintf+0x4a>
 8b2:	64a6                	ld	s1,72(sp)
 8b4:	79e2                	ld	s3,56(sp)
 8b6:	7a42                	ld	s4,48(sp)
 8b8:	7aa2                	ld	s5,40(sp)
 8ba:	7b02                	ld	s6,32(sp)
 8bc:	6be2                	ld	s7,24(sp)
 8be:	6c42                	ld	s8,16(sp)
 8c0:	6ca2                	ld	s9,8(sp)
    }
  }
}
 8c2:	60e6                	ld	ra,88(sp)
 8c4:	6446                	ld	s0,80(sp)
 8c6:	6906                	ld	s2,64(sp)
 8c8:	6125                	addi	sp,sp,96
 8ca:	8082                	ret

00000000000008cc <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8cc:	715d                	addi	sp,sp,-80
 8ce:	ec06                	sd	ra,24(sp)
 8d0:	e822                	sd	s0,16(sp)
 8d2:	1000                	addi	s0,sp,32
 8d4:	e010                	sd	a2,0(s0)
 8d6:	e414                	sd	a3,8(s0)
 8d8:	e818                	sd	a4,16(s0)
 8da:	ec1c                	sd	a5,24(s0)
 8dc:	03043023          	sd	a6,32(s0)
 8e0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8e4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8e8:	8622                	mv	a2,s0
 8ea:	d3fff0ef          	jal	628 <vprintf>
}
 8ee:	60e2                	ld	ra,24(sp)
 8f0:	6442                	ld	s0,16(sp)
 8f2:	6161                	addi	sp,sp,80
 8f4:	8082                	ret

00000000000008f6 <printf>:

void
printf(const char *fmt, ...)
{
 8f6:	711d                	addi	sp,sp,-96
 8f8:	ec06                	sd	ra,24(sp)
 8fa:	e822                	sd	s0,16(sp)
 8fc:	1000                	addi	s0,sp,32
 8fe:	e40c                	sd	a1,8(s0)
 900:	e810                	sd	a2,16(s0)
 902:	ec14                	sd	a3,24(s0)
 904:	f018                	sd	a4,32(s0)
 906:	f41c                	sd	a5,40(s0)
 908:	03043823          	sd	a6,48(s0)
 90c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 910:	00840613          	addi	a2,s0,8
 914:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 918:	85aa                	mv	a1,a0
 91a:	4505                	li	a0,1
 91c:	d0dff0ef          	jal	628 <vprintf>
}
 920:	60e2                	ld	ra,24(sp)
 922:	6442                	ld	s0,16(sp)
 924:	6125                	addi	sp,sp,96
 926:	8082                	ret

0000000000000928 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 928:	1141                	addi	sp,sp,-16
 92a:	e422                	sd	s0,8(sp)
 92c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 92e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 932:	00001797          	auipc	a5,0x1
 936:	6ce7b783          	ld	a5,1742(a5) # 2000 <freep>
 93a:	a02d                	j	964 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 93c:	4618                	lw	a4,8(a2)
 93e:	9f2d                	addw	a4,a4,a1
 940:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 944:	6398                	ld	a4,0(a5)
 946:	6310                	ld	a2,0(a4)
 948:	a83d                	j	986 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 94a:	ff852703          	lw	a4,-8(a0)
 94e:	9f31                	addw	a4,a4,a2
 950:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 952:	ff053683          	ld	a3,-16(a0)
 956:	a091                	j	99a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 958:	6398                	ld	a4,0(a5)
 95a:	00e7e463          	bltu	a5,a4,962 <free+0x3a>
 95e:	00e6ea63          	bltu	a3,a4,972 <free+0x4a>
{
 962:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 964:	fed7fae3          	bgeu	a5,a3,958 <free+0x30>
 968:	6398                	ld	a4,0(a5)
 96a:	00e6e463          	bltu	a3,a4,972 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 96e:	fee7eae3          	bltu	a5,a4,962 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 972:	ff852583          	lw	a1,-8(a0)
 976:	6390                	ld	a2,0(a5)
 978:	02059813          	slli	a6,a1,0x20
 97c:	01c85713          	srli	a4,a6,0x1c
 980:	9736                	add	a4,a4,a3
 982:	fae60de3          	beq	a2,a4,93c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 986:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 98a:	4790                	lw	a2,8(a5)
 98c:	02061593          	slli	a1,a2,0x20
 990:	01c5d713          	srli	a4,a1,0x1c
 994:	973e                	add	a4,a4,a5
 996:	fae68ae3          	beq	a3,a4,94a <free+0x22>
    p->s.ptr = bp->s.ptr;
 99a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 99c:	00001717          	auipc	a4,0x1
 9a0:	66f73223          	sd	a5,1636(a4) # 2000 <freep>
}
 9a4:	6422                	ld	s0,8(sp)
 9a6:	0141                	addi	sp,sp,16
 9a8:	8082                	ret

00000000000009aa <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9aa:	7139                	addi	sp,sp,-64
 9ac:	fc06                	sd	ra,56(sp)
 9ae:	f822                	sd	s0,48(sp)
 9b0:	f426                	sd	s1,40(sp)
 9b2:	ec4e                	sd	s3,24(sp)
 9b4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9b6:	02051493          	slli	s1,a0,0x20
 9ba:	9081                	srli	s1,s1,0x20
 9bc:	04bd                	addi	s1,s1,15
 9be:	8091                	srli	s1,s1,0x4
 9c0:	0014899b          	addiw	s3,s1,1
 9c4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9c6:	00001517          	auipc	a0,0x1
 9ca:	63a53503          	ld	a0,1594(a0) # 2000 <freep>
 9ce:	c915                	beqz	a0,a02 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9d0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9d2:	4798                	lw	a4,8(a5)
 9d4:	08977a63          	bgeu	a4,s1,a68 <malloc+0xbe>
 9d8:	f04a                	sd	s2,32(sp)
 9da:	e852                	sd	s4,16(sp)
 9dc:	e456                	sd	s5,8(sp)
 9de:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 9e0:	8a4e                	mv	s4,s3
 9e2:	0009871b          	sext.w	a4,s3
 9e6:	6685                	lui	a3,0x1
 9e8:	00d77363          	bgeu	a4,a3,9ee <malloc+0x44>
 9ec:	6a05                	lui	s4,0x1
 9ee:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9f2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9f6:	00001917          	auipc	s2,0x1
 9fa:	60a90913          	addi	s2,s2,1546 # 2000 <freep>
  if(p == SBRK_ERROR)
 9fe:	5afd                	li	s5,-1
 a00:	a081                	j	a40 <malloc+0x96>
 a02:	f04a                	sd	s2,32(sp)
 a04:	e852                	sd	s4,16(sp)
 a06:	e456                	sd	s5,8(sp)
 a08:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 a0a:	00001797          	auipc	a5,0x1
 a0e:	60678793          	addi	a5,a5,1542 # 2010 <base>
 a12:	00001717          	auipc	a4,0x1
 a16:	5ef73723          	sd	a5,1518(a4) # 2000 <freep>
 a1a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a1c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a20:	b7c1                	j	9e0 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 a22:	6398                	ld	a4,0(a5)
 a24:	e118                	sd	a4,0(a0)
 a26:	a8a9                	j	a80 <malloc+0xd6>
  hp->s.size = nu;
 a28:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a2c:	0541                	addi	a0,a0,16
 a2e:	efbff0ef          	jal	928 <free>
  return freep;
 a32:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a36:	c12d                	beqz	a0,a98 <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a38:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a3a:	4798                	lw	a4,8(a5)
 a3c:	02977263          	bgeu	a4,s1,a60 <malloc+0xb6>
    if(p == freep)
 a40:	00093703          	ld	a4,0(s2)
 a44:	853e                	mv	a0,a5
 a46:	fef719e3          	bne	a4,a5,a38 <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
 a4a:	8552                	mv	a0,s4
 a4c:	a3fff0ef          	jal	48a <sbrk>
  if(p == SBRK_ERROR)
 a50:	fd551ce3          	bne	a0,s5,a28 <malloc+0x7e>
        return 0;
 a54:	4501                	li	a0,0
 a56:	7902                	ld	s2,32(sp)
 a58:	6a42                	ld	s4,16(sp)
 a5a:	6aa2                	ld	s5,8(sp)
 a5c:	6b02                	ld	s6,0(sp)
 a5e:	a03d                	j	a8c <malloc+0xe2>
 a60:	7902                	ld	s2,32(sp)
 a62:	6a42                	ld	s4,16(sp)
 a64:	6aa2                	ld	s5,8(sp)
 a66:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 a68:	fae48de3          	beq	s1,a4,a22 <malloc+0x78>
        p->s.size -= nunits;
 a6c:	4137073b          	subw	a4,a4,s3
 a70:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a72:	02071693          	slli	a3,a4,0x20
 a76:	01c6d713          	srli	a4,a3,0x1c
 a7a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a7c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a80:	00001717          	auipc	a4,0x1
 a84:	58a73023          	sd	a0,1408(a4) # 2000 <freep>
      return (void*)(p + 1);
 a88:	01078513          	addi	a0,a5,16
  }
}
 a8c:	70e2                	ld	ra,56(sp)
 a8e:	7442                	ld	s0,48(sp)
 a90:	74a2                	ld	s1,40(sp)
 a92:	69e2                	ld	s3,24(sp)
 a94:	6121                	addi	sp,sp,64
 a96:	8082                	ret
 a98:	7902                	ld	s2,32(sp)
 a9a:	6a42                	ld	s4,16(sp)
 a9c:	6aa2                	ld	s5,8(sp)
 a9e:	6b02                	ld	s6,0(sp)
 aa0:	b7f5                	j	a8c <malloc+0xe2>
