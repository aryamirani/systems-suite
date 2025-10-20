
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000c117          	auipc	sp,0xc
    80000004:	99813103          	ld	sp,-1640(sp) # 8000b998 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fe4e4d7>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dca78793          	addi	a5,a5,-566 # 80000e4a <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32];
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	1b2030ef          	jal	800032c4 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00014517          	auipc	a0,0x14
    80000190:	86450513          	addi	a0,a0,-1948 # 800139f0 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00014497          	auipc	s1,0x14
    8000019c:	85848493          	addi	s1,s1,-1960 # 800139f0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00014917          	auipc	s2,0x14
    800001a4:	8e890913          	addi	s2,s2,-1816 # 80013a88 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	270020ef          	jal	80002428 <myproc>
    800001bc:	799020ef          	jal	80003154 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	4f5020ef          	jal	80002eba <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00014717          	auipc	a4,0x14
    800001dc:	81870713          	addi	a4,a4,-2024 # 800139f0 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	070030ef          	jal	8000327a <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00013517          	auipc	a0,0x13
    80000226:	7ce50513          	addi	a0,a0,1998 # 800139f0 <cons>
    8000022a:	24b000ef          	jal	80000c74 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00014717          	auipc	a4,0x14
    80000250:	82f72e23          	sw	a5,-1988(a4) # 80013a88 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00013517          	auipc	a0,0x13
    80000266:	78e50513          	addi	a0,a0,1934 # 800139f0 <cons>
    8000026a:	20b000ef          	jal	80000c74 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00013517          	auipc	a0,0x13
    800002ba:	73a50513          	addi	a0,a0,1850 # 800139f0 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	036030ef          	jal	8000330e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00013517          	auipc	a0,0x13
    800002e0:	71450513          	addi	a0,a0,1812 # 800139f0 <cons>
    800002e4:	191000ef          	jal	80000c74 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00013717          	auipc	a4,0x13
    800002fe:	6f670713          	addi	a4,a4,1782 # 800139f0 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00013797          	auipc	a5,0x13
    80000324:	6d078793          	addi	a5,a5,1744 # 800139f0 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00013797          	auipc	a5,0x13
    80000352:	73a7a783          	lw	a5,1850(a5) # 80013a88 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00013717          	auipc	a4,0x13
    80000368:	68c70713          	addi	a4,a4,1676 # 800139f0 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00013497          	auipc	s1,0x13
    80000378:	67c48493          	addi	s1,s1,1660 # 800139f0 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00013717          	auipc	a4,0x13
    800003ba:	63a70713          	addi	a4,a4,1594 # 800139f0 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00013717          	auipc	a4,0x13
    800003d0:	6cf72223          	sw	a5,1732(a4) # 80013a90 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00013797          	auipc	a5,0x13
    800003ee:	60678793          	addi	a5,a5,1542 # 800139f0 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00013797          	auipc	a5,0x13
    80000412:	66c7af23          	sw	a2,1662(a5) # 80013a8c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00013517          	auipc	a0,0x13
    8000041a:	67250513          	addi	a0,a0,1650 # 80013a88 <cons+0x98>
    8000041e:	2e9020ef          	jal	80002f06 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00008597          	auipc	a1,0x8
    80000430:	bd458593          	addi	a1,a1,-1068 # 80008000 <etext>
    80000434:	00013517          	auipc	a0,0x13
    80000438:	5bc50513          	addi	a0,a0,1468 # 800139f0 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	001af797          	auipc	a5,0x1af
    80000448:	d4c78793          	addi	a5,a5,-692 # 801af190 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00008617          	auipc	a2,0x8
    80000482:	67260613          	addi	a2,a2,1650 # 80008af0 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000b797          	auipc	a5,0xb
    8000051c:	49c7a783          	lw	a5,1180(a5) # 8000b9b4 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00013517          	auipc	a0,0x13
    80000564:	53850513          	addi	a0,a0,1336 # 80013a98 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00008b97          	auipc	s7,0x8
    8000072c:	3c8b8b93          	addi	s7,s7,968 # 80008af0 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00008917          	auipc	s2,0x8
    8000078c:	88090913          	addi	s2,s2,-1920 # 80008008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000b797          	auipc	a5,0xb
    800007c0:	1f87a783          	lw	a5,504(a5) # 8000b9b4 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00013517          	auipc	a0,0x13
    800007d6:	2c650513          	addi	a0,a0,710 # 80013a98 <pr>
    800007da:	49a000ef          	jal	80000c74 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000b797          	auipc	a5,0xb
    800007f4:	1d27a223          	sw	s2,452(a5) # 8000b9b4 <panicking>
  printf("panic: ");
    800007f8:	00008517          	auipc	a0,0x8
    800007fc:	82050513          	addi	a0,a0,-2016 # 80008018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00008517          	auipc	a0,0x8
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80008020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000b797          	auipc	a5,0xb
    80000816:	1927af23          	sw	s2,414(a5) # 8000b9b0 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00008597          	auipc	a1,0x8
    80000828:	80458593          	addi	a1,a1,-2044 # 80008028 <etext+0x28>
    8000082c:	00013517          	auipc	a0,0x13
    80000830:	26c50513          	addi	a0,a0,620 # 80013a98 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00007597          	auipc	a1,0x7
    80000880:	7b458593          	addi	a1,a1,1972 # 80008030 <etext+0x30>
    80000884:	00013517          	auipc	a0,0x13
    80000888:	22c50513          	addi	a0,a0,556 # 80013ab0 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00013517          	auipc	a0,0x13
    800008ac:	20850513          	addi	a0,a0,520 # 80013ab0 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000b497          	auipc	s1,0xb
    800008ca:	0f648493          	addi	s1,s1,246 # 8000b9bc <tx_busy>
        acquire(&tx_lock);
      } else {
        sleep(&tx_chan, &tx_lock);
      }
#else
      sleep(&tx_chan, &tx_lock);
    800008ce:	00013997          	auipc	s3,0x13
    800008d2:	1e298993          	addi	s3,s3,482 # 80013ab0 <tx_lock>
    800008d6:	0000b917          	auipc	s2,0xb
    800008da:	0e290913          	addi	s2,s2,226 # 8000b9b8 <tx_chan>
#endif
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	5d0020ef          	jal	80002eba <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00013517          	auipc	a0,0x13
    80000918:	19c50513          	addi	a0,a0,412 # 80013ab0 <tx_lock>
    8000091c:	358000ef          	jal	80000c74 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000b797          	auipc	a5,0xb
    8000093c:	07c7a783          	lw	a5,124(a5) # 8000b9b4 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000b797          	auipc	a5,0xb
    80000946:	06e7a783          	lw	a5,110(a5) # 8000b9b0 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000b797          	auipc	a5,0xb
    8000096c:	04c7a783          	lw	a5,76(a5) # 8000b9b4 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	29c000ef          	jal	80000c20 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00013517          	auipc	a0,0x13
    800009c8:	0ec50513          	addi	a0,a0,236 # 80013ab0 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00013517          	auipc	a0,0x13
    800009e4:	0d050513          	addi	a0,a0,208 # 80013ab0 <tx_lock>
    800009e8:	28c000ef          	jal	80000c74 <release>

  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000b797          	auipc	a5,0xb
    800009f4:	fc07a623          	sw	zero,-52(a5) # 8000b9bc <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000b517          	auipc	a0,0xb
    800009fc:	fc050513          	addi	a0,a0,-64 # 8000b9b8 <tx_chan>
    80000a00:	506020ef          	jal	80002f06 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	001b0797          	auipc	a5,0x1b0
    80000a34:	8f878793          	addi	a5,a5,-1800 # 801b0328 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	268000ef          	jal	80000cb0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00013917          	auipc	s2,0x13
    80000a50:	07c90913          	addi	s2,s2,124 # 80013ac8 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	20e000ef          	jal	80000c74 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80008038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00007597          	auipc	a1,0x7
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80008040 <etext+0x40>
    80000ada:	00013517          	auipc	a0,0x13
    80000ade:	fee50513          	addi	a0,a0,-18 # 80013ac8 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	001b0517          	auipc	a0,0x1b0
    80000aee:	83e50513          	addi	a0,a0,-1986 # 801b0328 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00013497          	auipc	s1,0x13
    80000b0c:	fc048493          	addi	s1,s1,-64 # 80013ac8 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00013517          	auipc	a0,0x13
    80000b20:	fac50513          	addi	a0,a0,-84 # 80013ac8 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	14e000ef          	jal	80000c74 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	180000ef          	jal	80000cb0 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00013517          	auipc	a0,0x13
    80000b44:	f8850513          	addi	a0,a0,-120 # 80013ac8 <kmem>
    80000b48:	12c000ef          	jal	80000c74 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	095010ef          	jal	8000240c <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	067010ef          	jal	8000240c <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	05f010ef          	jal	8000240c <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	04b010ef          	jal	8000240c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk)){
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk)){
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf6:	017010ef          	jal	8000240c <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    printf("lock already held: %s\n", lk->name);
    80000c06:	648c                	ld	a1,8(s1)
    80000c08:	00007517          	auipc	a0,0x7
    80000c0c:	44050513          	addi	a0,a0,1088 # 80008048 <etext+0x48>
    80000c10:	8ebff0ef          	jal	800004fa <printf>
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	44c50513          	addi	a0,a0,1100 # 80008060 <etext+0x60>
    80000c1c:	bc5ff0ef          	jal	800007e0 <panic>

0000000080000c20 <pop_off>:

void
pop_off(void)
{
    80000c20:	1141                	addi	sp,sp,-16
    80000c22:	e406                	sd	ra,8(sp)
    80000c24:	e022                	sd	s0,0(sp)
    80000c26:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c28:	7e4010ef          	jal	8000240c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c2c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c32:	e78d                	bnez	a5,80000c5c <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c34:	5d3c                	lw	a5,120(a0)
    80000c36:	02f05963          	blez	a5,80000c68 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c3a:	37fd                	addiw	a5,a5,-1
    80000c3c:	0007871b          	sext.w	a4,a5
    80000c40:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c42:	eb09                	bnez	a4,80000c54 <pop_off+0x34>
    80000c44:	5d7c                	lw	a5,124(a0)
    80000c46:	c799                	beqz	a5,80000c54 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c50:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c54:	60a2                	ld	ra,8(sp)
    80000c56:	6402                	ld	s0,0(sp)
    80000c58:	0141                	addi	sp,sp,16
    80000c5a:	8082                	ret
    panic("pop_off - interruptible");
    80000c5c:	00007517          	auipc	a0,0x7
    80000c60:	40c50513          	addi	a0,a0,1036 # 80008068 <etext+0x68>
    80000c64:	b7dff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c68:	00007517          	auipc	a0,0x7
    80000c6c:	41850513          	addi	a0,a0,1048 # 80008080 <etext+0x80>
    80000c70:	b71ff0ef          	jal	800007e0 <panic>

0000000080000c74 <release>:
{
    80000c74:	1101                	addi	sp,sp,-32
    80000c76:	ec06                	sd	ra,24(sp)
    80000c78:	e822                	sd	s0,16(sp)
    80000c7a:	e426                	sd	s1,8(sp)
    80000c7c:	1000                	addi	s0,sp,32
    80000c7e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c80:	ee5ff0ef          	jal	80000b64 <holding>
    80000c84:	c105                	beqz	a0,80000ca4 <release+0x30>
  lk->cpu = 0;
    80000c86:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c8a:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c8e:	0310000f          	fence	rw,w
    80000c92:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c96:	f8bff0ef          	jal	80000c20 <pop_off>
}
    80000c9a:	60e2                	ld	ra,24(sp)
    80000c9c:	6442                	ld	s0,16(sp)
    80000c9e:	64a2                	ld	s1,8(sp)
    80000ca0:	6105                	addi	sp,sp,32
    80000ca2:	8082                	ret
    panic("release");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3e450513          	addi	a0,a0,996 # 80008088 <etext+0x88>
    80000cac:	b35ff0ef          	jal	800007e0 <panic>

0000000080000cb0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cb0:	1141                	addi	sp,sp,-16
    80000cb2:	e422                	sd	s0,8(sp)
    80000cb4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cb6:	ca19                	beqz	a2,80000ccc <memset+0x1c>
    80000cb8:	87aa                	mv	a5,a0
    80000cba:	1602                	slli	a2,a2,0x20
    80000cbc:	9201                	srli	a2,a2,0x20
    80000cbe:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cc2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cc6:	0785                	addi	a5,a5,1
    80000cc8:	fee79de3          	bne	a5,a4,80000cc2 <memset+0x12>
  }
  return dst;
}
    80000ccc:	6422                	ld	s0,8(sp)
    80000cce:	0141                	addi	sp,sp,16
    80000cd0:	8082                	ret

0000000080000cd2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cd8:	ca05                	beqz	a2,80000d08 <memcmp+0x36>
    80000cda:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cde:	1682                	slli	a3,a3,0x20
    80000ce0:	9281                	srli	a3,a3,0x20
    80000ce2:	0685                	addi	a3,a3,1
    80000ce4:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ce6:	00054783          	lbu	a5,0(a0)
    80000cea:	0005c703          	lbu	a4,0(a1)
    80000cee:	00e79863          	bne	a5,a4,80000cfe <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000cf2:	0505                	addi	a0,a0,1
    80000cf4:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000cf6:	fed518e3          	bne	a0,a3,80000ce6 <memcmp+0x14>
  }

  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	a019                	j	80000d02 <memcmp+0x30>
      return *s1 - *s2;
    80000cfe:	40e7853b          	subw	a0,a5,a4
}
    80000d02:	6422                	ld	s0,8(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret
  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	bfe5                	j	80000d02 <memcmp+0x30>

0000000080000d0c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d12:	c205                	beqz	a2,80000d32 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d14:	02a5e263          	bltu	a1,a0,80000d38 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d18:	1602                	slli	a2,a2,0x20
    80000d1a:	9201                	srli	a2,a2,0x20
    80000d1c:	00c587b3          	add	a5,a1,a2
{
    80000d20:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d22:	0585                	addi	a1,a1,1
    80000d24:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fe4ecd9>
    80000d26:	fff5c683          	lbu	a3,-1(a1)
    80000d2a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d2e:	feb79ae3          	bne	a5,a1,80000d22 <memmove+0x16>

  return dst;
}
    80000d32:	6422                	ld	s0,8(sp)
    80000d34:	0141                	addi	sp,sp,16
    80000d36:	8082                	ret
  if(s < d && s + n > d){
    80000d38:	02061693          	slli	a3,a2,0x20
    80000d3c:	9281                	srli	a3,a3,0x20
    80000d3e:	00d58733          	add	a4,a1,a3
    80000d42:	fce57be3          	bgeu	a0,a4,80000d18 <memmove+0xc>
    d += n;
    80000d46:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d48:	fff6079b          	addiw	a5,a2,-1
    80000d4c:	1782                	slli	a5,a5,0x20
    80000d4e:	9381                	srli	a5,a5,0x20
    80000d50:	fff7c793          	not	a5,a5
    80000d54:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d56:	177d                	addi	a4,a4,-1
    80000d58:	16fd                	addi	a3,a3,-1
    80000d5a:	00074603          	lbu	a2,0(a4)
    80000d5e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d62:	fef71ae3          	bne	a4,a5,80000d56 <memmove+0x4a>
    80000d66:	b7f1                	j	80000d32 <memmove+0x26>

0000000080000d68 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d68:	1141                	addi	sp,sp,-16
    80000d6a:	e406                	sd	ra,8(sp)
    80000d6c:	e022                	sd	s0,0(sp)
    80000d6e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d70:	f9dff0ef          	jal	80000d0c <memmove>
}
    80000d74:	60a2                	ld	ra,8(sp)
    80000d76:	6402                	ld	s0,0(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d82:	ce11                	beqz	a2,80000d9e <strncmp+0x22>
    80000d84:	00054783          	lbu	a5,0(a0)
    80000d88:	cf89                	beqz	a5,80000da2 <strncmp+0x26>
    80000d8a:	0005c703          	lbu	a4,0(a1)
    80000d8e:	00f71a63          	bne	a4,a5,80000da2 <strncmp+0x26>
    n--, p++, q++;
    80000d92:	367d                	addiw	a2,a2,-1
    80000d94:	0505                	addi	a0,a0,1
    80000d96:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d98:	f675                	bnez	a2,80000d84 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d9a:	4501                	li	a0,0
    80000d9c:	a801                	j	80000dac <strncmp+0x30>
    80000d9e:	4501                	li	a0,0
    80000da0:	a031                	j	80000dac <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000da2:	00054503          	lbu	a0,0(a0)
    80000da6:	0005c783          	lbu	a5,0(a1)
    80000daa:	9d1d                	subw	a0,a0,a5
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret

0000000080000db2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e422                	sd	s0,8(sp)
    80000db6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000db8:	87aa                	mv	a5,a0
    80000dba:	86b2                	mv	a3,a2
    80000dbc:	367d                	addiw	a2,a2,-1
    80000dbe:	02d05563          	blez	a3,80000de8 <strncpy+0x36>
    80000dc2:	0785                	addi	a5,a5,1
    80000dc4:	0005c703          	lbu	a4,0(a1)
    80000dc8:	fee78fa3          	sb	a4,-1(a5)
    80000dcc:	0585                	addi	a1,a1,1
    80000dce:	f775                	bnez	a4,80000dba <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dd0:	873e                	mv	a4,a5
    80000dd2:	9fb5                	addw	a5,a5,a3
    80000dd4:	37fd                	addiw	a5,a5,-1
    80000dd6:	00c05963          	blez	a2,80000de8 <strncpy+0x36>
    *s++ = 0;
    80000dda:	0705                	addi	a4,a4,1
    80000ddc:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000de0:	40e786bb          	subw	a3,a5,a4
    80000de4:	fed04be3          	bgtz	a3,80000dda <strncpy+0x28>
  return os;
}
    80000de8:	6422                	ld	s0,8(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret

0000000080000dee <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000dee:	1141                	addi	sp,sp,-16
    80000df0:	e422                	sd	s0,8(sp)
    80000df2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000df4:	02c05363          	blez	a2,80000e1a <safestrcpy+0x2c>
    80000df8:	fff6069b          	addiw	a3,a2,-1
    80000dfc:	1682                	slli	a3,a3,0x20
    80000dfe:	9281                	srli	a3,a3,0x20
    80000e00:	96ae                	add	a3,a3,a1
    80000e02:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e04:	00d58963          	beq	a1,a3,80000e16 <safestrcpy+0x28>
    80000e08:	0585                	addi	a1,a1,1
    80000e0a:	0785                	addi	a5,a5,1
    80000e0c:	fff5c703          	lbu	a4,-1(a1)
    80000e10:	fee78fa3          	sb	a4,-1(a5)
    80000e14:	fb65                	bnez	a4,80000e04 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e16:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret

0000000080000e20 <strlen>:

int
strlen(const char *s)
{
    80000e20:	1141                	addi	sp,sp,-16
    80000e22:	e422                	sd	s0,8(sp)
    80000e24:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e26:	00054783          	lbu	a5,0(a0)
    80000e2a:	cf91                	beqz	a5,80000e46 <strlen+0x26>
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	87aa                	mv	a5,a0
    80000e30:	86be                	mv	a3,a5
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff7c703          	lbu	a4,-1(a5)
    80000e38:	ff65                	bnez	a4,80000e30 <strlen+0x10>
    80000e3a:	40a6853b          	subw	a0,a3,a0
    80000e3e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e40:	6422                	ld	s0,8(sp)
    80000e42:	0141                	addi	sp,sp,16
    80000e44:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e46:	4501                	li	a0,0
    80000e48:	bfe5                	j	80000e40 <strlen+0x20>

0000000080000e4a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e406                	sd	ra,8(sp)
    80000e4e:	e022                	sd	s0,0(sp)
    80000e50:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e52:	5aa010ef          	jal	800023fc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e56:	0000b717          	auipc	a4,0xb
    80000e5a:	b6a70713          	addi	a4,a4,-1174 # 8000b9c0 <started>
  if(cpuid() == 0){
    80000e5e:	c51d                	beqz	a0,80000e8c <main+0x42>
    while(started == 0)
    80000e60:	431c                	lw	a5,0(a4)
    80000e62:	2781                	sext.w	a5,a5
    80000e64:	dff5                	beqz	a5,80000e60 <main+0x16>
      ;
    __sync_synchronize();
    80000e66:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e6a:	592010ef          	jal	800023fc <cpuid>
    80000e6e:	85aa                	mv	a1,a0
    80000e70:	00007517          	auipc	a0,0x7
    80000e74:	23850513          	addi	a0,a0,568 # 800080a8 <etext+0xa8>
    80000e78:	e82ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e7c:	0f6000ef          	jal	80000f72 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e80:	5c8020ef          	jal	80003448 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e84:	185050ef          	jal	80006808 <plicinithart>
  }

  scheduler();        
    80000e88:	64d010ef          	jal	80002cd4 <scheduler>
    consoleinit();
    80000e8c:	d98ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e90:	98dff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e94:	00007517          	auipc	a0,0x7
    80000e98:	37450513          	addi	a0,a0,884 # 80008208 <etext+0x208>
    80000e9c:	e5eff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	1f050513          	addi	a0,a0,496 # 80008090 <etext+0x90>
    80000ea8:	e52ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000eac:	00007517          	auipc	a0,0x7
    80000eb0:	35c50513          	addi	a0,a0,860 # 80008208 <etext+0x208>
    80000eb4:	e46ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eb8:	c13ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000ebc:	3a6000ef          	jal	80001262 <kvminit>
    kvminithart();   // turn on paging
    80000ec0:	0b2000ef          	jal	80000f72 <kvminithart>
    procinit();      // process table
    80000ec4:	466010ef          	jal	8000232a <procinit>
    trapinit();      // trap vectors
    80000ec8:	55c020ef          	jal	80003424 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ecc:	57c020ef          	jal	80003448 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ed0:	11f050ef          	jal	800067ee <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ed4:	135050ef          	jal	80006808 <plicinithart>
    binit();         // buffer cache
    80000ed8:	775020ef          	jal	80003e4c <binit>
    iinit();         // inode table
    80000edc:	4fa030ef          	jal	800043d6 <iinit>
    fileinit();      // file table
    80000ee0:	3ec040ef          	jal	800052cc <fileinit>
    syscall_init();  // initialize syscall infrastructure
    80000ee4:	295020ef          	jal	80003978 <syscall_init>
    virtio_disk_init(); // emulated hard disk
    80000ee8:	211050ef          	jal	800068f8 <virtio_disk_init>
    userinit();      // first user process
    80000eec:	381010ef          	jal	80002a6c <userinit>
    __sync_synchronize();
    80000ef0:	0330000f          	fence	rw,rw
    started = 1;
    80000ef4:	4785                	li	a5,1
    80000ef6:	0000b717          	auipc	a4,0xb
    80000efa:	acf72523          	sw	a5,-1334(a4) # 8000b9c0 <started>
    80000efe:	b769                	j	80000e88 <main+0x3e>

0000000080000f00 <pgmeta_alloc>:
// helpers for per-process paging metadata and swap
static int pgmeta_find(struct proc *p, uint64 va_pg){
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == va_pg) return i;
  return -1;
}
static int pgmeta_alloc(struct proc *p, uint64 va_pg){
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e422                	sd	s0,8(sp)
    80000f04:	0800                	addi	s0,sp,16
    80000f06:	882a                	mv	a6,a0
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == va_pg) return i;
    80000f08:	43850693          	addi	a3,a0,1080
static int pgmeta_alloc(struct proc *p, uint64 va_pg){
    80000f0c:	87b6                	mv	a5,a3
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == va_pg) return i;
    80000f0e:	4501                	li	a0,0
    80000f10:	40000613          	li	a2,1024
    80000f14:	6398                	ld	a4,0(a5)
    80000f16:	00e58863          	beq	a1,a4,80000f26 <pgmeta_alloc+0x26>
    80000f1a:	2505                	addiw	a0,a0,1
    80000f1c:	07e1                	addi	a5,a5,24
    80000f1e:	fec51be3          	bne	a0,a2,80000f14 <pgmeta_alloc+0x14>
  int idx = pgmeta_find(p, va_pg);
  if(idx >= 0) return idx;
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == 0){
    80000f22:	4501                	li	a0,0
    80000f24:	a021                	j	80000f2c <pgmeta_alloc+0x2c>
  if(idx >= 0) return idx;
    80000f26:	04055363          	bgez	a0,80000f6c <pgmeta_alloc+0x6c>
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == 0){
    80000f2a:	4501                	li	a0,0
    80000f2c:	40000713          	li	a4,1024
    80000f30:	629c                	ld	a5,0(a3)
    80000f32:	c799                	beqz	a5,80000f40 <pgmeta_alloc+0x40>
    80000f34:	2505                	addiw	a0,a0,1
    80000f36:	06e1                	addi	a3,a3,24
    80000f38:	fee51ce3          	bne	a0,a4,80000f30 <pgmeta_alloc+0x30>
    p->pgmeta[i].in_swap = 0;
    p->pgmeta[i].slot = 0xffff;
    p->pgmeta[i].perm = 0;
    return i;
  }
  return -1;
    80000f3c:	557d                	li	a0,-1
    80000f3e:	a03d                	j	80000f6c <pgmeta_alloc+0x6c>
    p->pgmeta[i].va = va_pg;
    80000f40:	00151793          	slli	a5,a0,0x1
    80000f44:	97aa                	add	a5,a5,a0
    80000f46:	078e                	slli	a5,a5,0x3
    80000f48:	97c2                	add	a5,a5,a6
    80000f4a:	42b7bc23          	sd	a1,1080(a5)
    p->pgmeta[i].seq = 0;
    80000f4e:	4407b023          	sd	zero,1088(a5)
    p->pgmeta[i].resident = 0;
    80000f52:	44078423          	sb	zero,1096(a5)
    p->pgmeta[i].dirty = 0;
    80000f56:	440784a3          	sb	zero,1097(a5)
    p->pgmeta[i].referenced = 0;
    80000f5a:	44078523          	sb	zero,1098(a5)
    p->pgmeta[i].in_swap = 0;
    80000f5e:	440785a3          	sb	zero,1099(a5)
    p->pgmeta[i].slot = 0xffff;
    80000f62:	577d                	li	a4,-1
    80000f64:	44e79623          	sh	a4,1100(a5)
    p->pgmeta[i].perm = 0;
    80000f68:	44079723          	sh	zero,1102(a5)
}
    80000f6c:	6422                	ld	s0,8(sp)
    80000f6e:	0141                	addi	sp,sp,16
    80000f70:	8082                	ret

0000000080000f72 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f72:	1141                	addi	sp,sp,-16
    80000f74:	e422                	sd	s0,8(sp)
    80000f76:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f78:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f7c:	0000b797          	auipc	a5,0xb
    80000f80:	a4c7b783          	ld	a5,-1460(a5) # 8000b9c8 <kernel_pagetable>
    80000f84:	83b1                	srli	a5,a5,0xc
    80000f86:	577d                	li	a4,-1
    80000f88:	177e                	slli	a4,a4,0x3f
    80000f8a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f8c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f90:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f94:	6422                	ld	s0,8(sp)
    80000f96:	0141                	addi	sp,sp,16
    80000f98:	8082                	ret

0000000080000f9a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f9a:	7139                	addi	sp,sp,-64
    80000f9c:	fc06                	sd	ra,56(sp)
    80000f9e:	f822                	sd	s0,48(sp)
    80000fa0:	f426                	sd	s1,40(sp)
    80000fa2:	f04a                	sd	s2,32(sp)
    80000fa4:	ec4e                	sd	s3,24(sp)
    80000fa6:	e852                	sd	s4,16(sp)
    80000fa8:	e456                	sd	s5,8(sp)
    80000faa:	e05a                	sd	s6,0(sp)
    80000fac:	0080                	addi	s0,sp,64
    80000fae:	84aa                	mv	s1,a0
    80000fb0:	89ae                	mv	s3,a1
    80000fb2:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    80000fb4:	57fd                	li	a5,-1
    80000fb6:	83e9                	srli	a5,a5,0x1a
    80000fb8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fba:	4a89                	li	s5,2
  if(va >= MAXVA)
    80000fbc:	00b7ff63          	bgeu	a5,a1,80000fda <walk+0x40>
    panic("walk");
    80000fc0:	00007517          	auipc	a0,0x7
    80000fc4:	10050513          	addi	a0,a0,256 # 800080c0 <etext+0xc0>
    80000fc8:	819ff0ef          	jal	800007e0 <panic>
      if((*pte & (PTE_R|PTE_W|PTE_X)) != 0){
        uint64 pteval = *pte;
        printf("walk: corrupted internal PTE at level %d for va=0x%lx pte=0x%lx\n", level, va, pteval);
        return 0;
      }
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fcc:	82a9                	srli	a3,a3,0xa
    80000fce:	00c69493          	slli	s1,a3,0xc
  for(int level = 2; level > 0; level--) {
    80000fd2:	3afd                	addiw	s5,s5,-1
    80000fd4:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fe4eccf>
    80000fd6:	040a8c63          	beqz	s5,8000102e <walk+0x94>
    pte_t *pte = &pagetable[PX(level, va)];
    80000fda:	0149d933          	srl	s2,s3,s4
    80000fde:	1ff97913          	andi	s2,s2,511
    80000fe2:	090e                	slli	s2,s2,0x3
    80000fe4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fe6:	00093683          	ld	a3,0(s2)
    80000fea:	0016f793          	andi	a5,a3,1
    80000fee:	cf91                	beqz	a5,8000100a <walk+0x70>
      if((*pte & (PTE_R|PTE_W|PTE_X)) != 0){
    80000ff0:	00e6f793          	andi	a5,a3,14
    80000ff4:	dfe1                	beqz	a5,80000fcc <walk+0x32>
        printf("walk: corrupted internal PTE at level %d for va=0x%lx pte=0x%lx\n", level, va, pteval);
    80000ff6:	864e                	mv	a2,s3
    80000ff8:	85d6                	mv	a1,s5
    80000ffa:	00007517          	auipc	a0,0x7
    80000ffe:	0ce50513          	addi	a0,a0,206 # 800080c8 <etext+0xc8>
    80001002:	cf8ff0ef          	jal	800004fa <printf>
        return 0;
    80001006:	4501                	li	a0,0
    80001008:	a80d                	j	8000103a <walk+0xa0>
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100a:	040b0263          	beqz	s6,8000104e <walk+0xb4>
    8000100e:	af1ff0ef          	jal	80000afe <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c11d                	beqz	a0,8000103a <walk+0xa0>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	c97ff0ef          	jal	80000cb0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101e:	00c4d793          	srli	a5,s1,0xc
    80001022:	07aa                	slli	a5,a5,0xa
    80001024:	0017e793          	ori	a5,a5,1
    80001028:	00f93023          	sd	a5,0(s2)
    8000102c:	b75d                	j	80000fd2 <walk+0x38>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0xa0>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	f33ff0ef          	jal	80000f9a <walk>
  if(pte == 0)
    8000106c:	c105                	beqz	a0,8000108c <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    8000106e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001070:	0117f693          	andi	a3,a5,17
    80001074:	4745                	li	a4,17
    return 0;
    80001076:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001078:	00e68663          	beq	a3,a4,80001084 <walkaddr+0x32>
}
    8000107c:	60a2                	ld	ra,8(sp)
    8000107e:	6402                	ld	s0,0(sp)
    80001080:	0141                	addi	sp,sp,16
    80001082:	8082                	ret
  pa = PTE2PA(*pte);
    80001084:	83a9                	srli	a5,a5,0xa
    80001086:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108a:	bfcd                	j	8000107c <walkaddr+0x2a>
    return 0;
    8000108c:	4501                	li	a0,0
    8000108e:	b7fd                	j	8000107c <walkaddr+0x2a>

0000000080001090 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001090:	711d                	addi	sp,sp,-96
    80001092:	ec86                	sd	ra,88(sp)
    80001094:	e8a2                	sd	s0,80(sp)
    80001096:	e4a6                	sd	s1,72(sp)
    80001098:	e0ca                	sd	s2,64(sp)
    8000109a:	fc4e                	sd	s3,56(sp)
    8000109c:	f852                	sd	s4,48(sp)
    8000109e:	f456                	sd	s5,40(sp)
    800010a0:	f05a                	sd	s6,32(sp)
    800010a2:	ec5e                	sd	s7,24(sp)
    800010a4:	e862                	sd	s8,16(sp)
    800010a6:	e466                	sd	s9,8(sp)
    800010a8:	e06a                	sd	s10,0(sp)
    800010aa:	1080                	addi	s0,sp,96
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800010ac:	03459793          	slli	a5,a1,0x34
    800010b0:	eb8d                	bnez	a5,800010e2 <mappages+0x52>
    800010b2:	8b2a                	mv	s6,a0
    800010b4:	89ae                	mv	s3,a1
    800010b6:	8936                	mv	s2,a3
    800010b8:	8bba                	mv	s7,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    800010ba:	03461793          	slli	a5,a2,0x34
    800010be:	eb85                	bnez	a5,800010ee <mappages+0x5e>
    panic("mappages: size not aligned");

  if(size == 0)
    800010c0:	ce0d                	beqz	a2,800010fa <mappages+0x6a>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    800010c2:	77fd                	lui	a5,0xfffff
    800010c4:	963e                	add	a2,a2,a5
    800010c6:	00b60ab3          	add	s5,a2,a1
      // Diagnostic: someone is trying to remap an already-mapped page.
      printf("mappages: remap detected va=0x%lx existing_pte=0x%lx\n", a, *pte);
      panic("mappages: remap");
    }
    if(pa == 0 || ((uint64)pa < (uint64)end && (uint64)pa >= (uint64)PHYSTOP)){
      printf("mappages: suspicious pa=0x%lx for va=0x%lx\n", pa, a);
    800010ca:	00007c97          	auipc	s9,0x7
    800010ce:	0dec8c93          	addi	s9,s9,222 # 800081a8 <etext+0x1a8>
    if(pa == 0 || ((uint64)pa < (uint64)end && (uint64)pa >= (uint64)PHYSTOP)){
    800010d2:	001afc17          	auipc	s8,0x1af
    800010d6:	256c0c13          	addi	s8,s8,598 # 801b0328 <end>
    800010da:	4d45                	li	s10,17
    800010dc:	0d6e                	slli	s10,s10,0x1b
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010de:	6a05                	lui	s4,0x1
    800010e0:	a08d                	j	80001142 <mappages+0xb2>
    panic("mappages: va not aligned");
    800010e2:	00007517          	auipc	a0,0x7
    800010e6:	02e50513          	addi	a0,a0,46 # 80008110 <etext+0x110>
    800010ea:	ef6ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	04250513          	addi	a0,a0,66 # 80008130 <etext+0x130>
    800010f6:	eeaff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    800010fa:	00007517          	auipc	a0,0x7
    800010fe:	05650513          	addi	a0,a0,86 # 80008150 <etext+0x150>
    80001102:	edeff0ef          	jal	800007e0 <panic>
      printf("mappages: remap detected va=0x%lx existing_pte=0x%lx\n", a, *pte);
    80001106:	85ce                	mv	a1,s3
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	05850513          	addi	a0,a0,88 # 80008160 <etext+0x160>
    80001110:	beaff0ef          	jal	800004fa <printf>
      panic("mappages: remap");
    80001114:	00007517          	auipc	a0,0x7
    80001118:	08450513          	addi	a0,a0,132 # 80008198 <etext+0x198>
    8000111c:	ec4ff0ef          	jal	800007e0 <panic>
      printf("mappages: suspicious pa=0x%lx for va=0x%lx\n", pa, a);
    80001120:	864e                	mv	a2,s3
    80001122:	85ca                	mv	a1,s2
    80001124:	8566                	mv	a0,s9
    80001126:	bd4ff0ef          	jal	800004fa <printf>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	00c95793          	srli	a5,s2,0xc
    8000112e:	07aa                	slli	a5,a5,0xa
    80001130:	0177e7b3          	or	a5,a5,s7
    80001134:	0017e793          	ori	a5,a5,1
    80001138:	e09c                	sd	a5,0(s1)
    if(a == last)
    8000113a:	05598563          	beq	s3,s5,80001184 <mappages+0xf4>
    a += PGSIZE;
    8000113e:	99d2                	add	s3,s3,s4
    pa += PGSIZE;
    80001140:	9952                	add	s2,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001142:	4605                	li	a2,1
    80001144:	85ce                	mv	a1,s3
    80001146:	855a                	mv	a0,s6
    80001148:	e53ff0ef          	jal	80000f9a <walk>
    8000114c:	84aa                	mv	s1,a0
    8000114e:	cd01                	beqz	a0,80001166 <mappages+0xd6>
    if(*pte & PTE_V){
    80001150:	6110                	ld	a2,0(a0)
    80001152:	00167793          	andi	a5,a2,1
    80001156:	fbc5                	bnez	a5,80001106 <mappages+0x76>
    if(pa == 0 || ((uint64)pa < (uint64)end && (uint64)pa >= (uint64)PHYSTOP)){
    80001158:	fc0904e3          	beqz	s2,80001120 <mappages+0x90>
    8000115c:	fd8977e3          	bgeu	s2,s8,8000112a <mappages+0x9a>
    80001160:	fda965e3          	bltu	s2,s10,8000112a <mappages+0x9a>
    80001164:	bf75                	j	80001120 <mappages+0x90>
      return -1;
    80001166:	557d                	li	a0,-1
  }
  return 0;
}
    80001168:	60e6                	ld	ra,88(sp)
    8000116a:	6446                	ld	s0,80(sp)
    8000116c:	64a6                	ld	s1,72(sp)
    8000116e:	6906                	ld	s2,64(sp)
    80001170:	79e2                	ld	s3,56(sp)
    80001172:	7a42                	ld	s4,48(sp)
    80001174:	7aa2                	ld	s5,40(sp)
    80001176:	7b02                	ld	s6,32(sp)
    80001178:	6be2                	ld	s7,24(sp)
    8000117a:	6c42                	ld	s8,16(sp)
    8000117c:	6ca2                	ld	s9,8(sp)
    8000117e:	6d02                	ld	s10,0(sp)
    80001180:	6125                	addi	sp,sp,96
    80001182:	8082                	ret
  return 0;
    80001184:	4501                	li	a0,0
    80001186:	b7cd                	j	80001168 <mappages+0xd8>

0000000080001188 <kvmmap>:
{
    80001188:	1141                	addi	sp,sp,-16
    8000118a:	e406                	sd	ra,8(sp)
    8000118c:	e022                	sd	s0,0(sp)
    8000118e:	0800                	addi	s0,sp,16
    80001190:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001192:	86b2                	mv	a3,a2
    80001194:	863e                	mv	a2,a5
    80001196:	efbff0ef          	jal	80001090 <mappages>
    8000119a:	e509                	bnez	a0,800011a4 <kvmmap+0x1c>
}
    8000119c:	60a2                	ld	ra,8(sp)
    8000119e:	6402                	ld	s0,0(sp)
    800011a0:	0141                	addi	sp,sp,16
    800011a2:	8082                	ret
    panic("kvmmap");
    800011a4:	00007517          	auipc	a0,0x7
    800011a8:	03450513          	addi	a0,a0,52 # 800081d8 <etext+0x1d8>
    800011ac:	e34ff0ef          	jal	800007e0 <panic>

00000000800011b0 <kvmmake>:
{
    800011b0:	1101                	addi	sp,sp,-32
    800011b2:	ec06                	sd	ra,24(sp)
    800011b4:	e822                	sd	s0,16(sp)
    800011b6:	e426                	sd	s1,8(sp)
    800011b8:	e04a                	sd	s2,0(sp)
    800011ba:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011bc:	943ff0ef          	jal	80000afe <kalloc>
    800011c0:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011c2:	6605                	lui	a2,0x1
    800011c4:	4581                	li	a1,0
    800011c6:	aebff0ef          	jal	80000cb0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ca:	4719                	li	a4,6
    800011cc:	6685                	lui	a3,0x1
    800011ce:	10000637          	lui	a2,0x10000
    800011d2:	100005b7          	lui	a1,0x10000
    800011d6:	8526                	mv	a0,s1
    800011d8:	fb1ff0ef          	jal	80001188 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10001637          	lui	a2,0x10001
    800011e4:	100015b7          	lui	a1,0x10001
    800011e8:	8526                	mv	a0,s1
    800011ea:	f9fff0ef          	jal	80001188 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    800011ee:	4719                	li	a4,6
    800011f0:	040006b7          	lui	a3,0x4000
    800011f4:	0c000637          	lui	a2,0xc000
    800011f8:	0c0005b7          	lui	a1,0xc000
    800011fc:	8526                	mv	a0,s1
    800011fe:	f8bff0ef          	jal	80001188 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001202:	00007917          	auipc	s2,0x7
    80001206:	dfe90913          	addi	s2,s2,-514 # 80008000 <etext>
    8000120a:	4729                	li	a4,10
    8000120c:	80007697          	auipc	a3,0x80007
    80001210:	df468693          	addi	a3,a3,-524 # 8000 <_entry-0x7fff8000>
    80001214:	4605                	li	a2,1
    80001216:	067e                	slli	a2,a2,0x1f
    80001218:	85b2                	mv	a1,a2
    8000121a:	8526                	mv	a0,s1
    8000121c:	f6dff0ef          	jal	80001188 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001220:	46c5                	li	a3,17
    80001222:	06ee                	slli	a3,a3,0x1b
    80001224:	4719                	li	a4,6
    80001226:	412686b3          	sub	a3,a3,s2
    8000122a:	864a                	mv	a2,s2
    8000122c:	85ca                	mv	a1,s2
    8000122e:	8526                	mv	a0,s1
    80001230:	f59ff0ef          	jal	80001188 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001234:	4729                	li	a4,10
    80001236:	6685                	lui	a3,0x1
    80001238:	00006617          	auipc	a2,0x6
    8000123c:	dc860613          	addi	a2,a2,-568 # 80007000 <_trampoline>
    80001240:	040005b7          	lui	a1,0x4000
    80001244:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001246:	05b2                	slli	a1,a1,0xc
    80001248:	8526                	mv	a0,s1
    8000124a:	f3fff0ef          	jal	80001188 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124e:	8526                	mv	a0,s1
    80001250:	03a010ef          	jal	8000228a <proc_mapstacks>
}
    80001254:	8526                	mv	a0,s1
    80001256:	60e2                	ld	ra,24(sp)
    80001258:	6442                	ld	s0,16(sp)
    8000125a:	64a2                	ld	s1,8(sp)
    8000125c:	6902                	ld	s2,0(sp)
    8000125e:	6105                	addi	sp,sp,32
    80001260:	8082                	ret

0000000080001262 <kvminit>:
{
    80001262:	1141                	addi	sp,sp,-16
    80001264:	e406                	sd	ra,8(sp)
    80001266:	e022                	sd	s0,0(sp)
    80001268:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126a:	f47ff0ef          	jal	800011b0 <kvmmake>
    8000126e:	0000a797          	auipc	a5,0xa
    80001272:	74a7bd23          	sd	a0,1882(a5) # 8000b9c8 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000127e:	1101                	addi	sp,sp,-32
    80001280:	ec06                	sd	ra,24(sp)
    80001282:	e822                	sd	s0,16(sp)
    80001284:	e426                	sd	s1,8(sp)
    80001286:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001288:	877ff0ef          	jal	80000afe <kalloc>
    8000128c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000128e:	c509                	beqz	a0,80001298 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001290:	6605                	lui	a2,0x1
    80001292:	4581                	li	a1,0
    80001294:	a1dff0ef          	jal	80000cb0 <memset>
  return pagetable;
}
    80001298:	8526                	mv	a0,s1
    8000129a:	60e2                	ld	ra,24(sp)
    8000129c:	6442                	ld	s0,16(sp)
    8000129e:	64a2                	ld	s1,8(sp)
    800012a0:	6105                	addi	sp,sp,32
    800012a2:	8082                	ret

00000000800012a4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012a4:	7139                	addi	sp,sp,-64
    800012a6:	fc06                	sd	ra,56(sp)
    800012a8:	f822                	sd	s0,48(sp)
    800012aa:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ac:	03459793          	slli	a5,a1,0x34
    800012b0:	e38d                	bnez	a5,800012d2 <uvmunmap+0x2e>
    800012b2:	f04a                	sd	s2,32(sp)
    800012b4:	ec4e                	sd	s3,24(sp)
    800012b6:	e852                	sd	s4,16(sp)
    800012b8:	e456                	sd	s5,8(sp)
    800012ba:	e05a                	sd	s6,0(sp)
    800012bc:	8a2a                	mv	s4,a0
    800012be:	892e                	mv	s2,a1
    800012c0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c2:	0632                	slli	a2,a2,0xc
    800012c4:	00b609b3          	add	s3,a2,a1
    800012c8:	6b05                	lui	s6,0x1
    800012ca:	0535f963          	bgeu	a1,s3,8000131c <uvmunmap+0x78>
    800012ce:	f426                	sd	s1,40(sp)
    800012d0:	a015                	j	800012f4 <uvmunmap+0x50>
    800012d2:	f426                	sd	s1,40(sp)
    800012d4:	f04a                	sd	s2,32(sp)
    800012d6:	ec4e                	sd	s3,24(sp)
    800012d8:	e852                	sd	s4,16(sp)
    800012da:	e456                	sd	s5,8(sp)
    800012dc:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	f0250513          	addi	a0,a0,-254 # 800081e0 <etext+0x1e0>
    800012e6:	cfaff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	03397563          	bgeu	s2,s3,8000131a <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	ca1ff0ef          	jal	80000f9a <walk>
    800012fe:	84aa                	mv	s1,a0
    80001300:	d57d                	beqz	a0,800012ee <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001302:	611c                	ld	a5,0(a0)
    80001304:	0017f713          	andi	a4,a5,1
    80001308:	d37d                	beqz	a4,800012ee <uvmunmap+0x4a>
    if(do_free){
    8000130a:	fe0a80e3          	beqz	s5,800012ea <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000130e:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001310:	00c79513          	slli	a0,a5,0xc
    80001314:	f08ff0ef          	jal	80000a1c <kfree>
    80001318:	bfc9                	j	800012ea <uvmunmap+0x46>
    8000131a:	74a2                	ld	s1,40(sp)
    8000131c:	7902                	ld	s2,32(sp)
    8000131e:	69e2                	ld	s3,24(sp)
    80001320:	6a42                	ld	s4,16(sp)
    80001322:	6aa2                	ld	s5,8(sp)
    80001324:	6b02                	ld	s6,0(sp)
  }
}
    80001326:	70e2                	ld	ra,56(sp)
    80001328:	7442                	ld	s0,48(sp)
    8000132a:	6121                	addi	sp,sp,64
    8000132c:	8082                	ret

000000008000132e <kalloc_or_evict>:
static char *kalloc_or_evict(struct proc *p){
    8000132e:	7139                	addi	sp,sp,-64
    80001330:	fc06                	sd	ra,56(sp)
    80001332:	f822                	sd	s0,48(sp)
    80001334:	f04a                	sd	s2,32(sp)
    80001336:	ec4e                	sd	s3,24(sp)
    80001338:	0080                	addi	s0,sp,64
    8000133a:	892a                	mv	s2,a0
  char *mem = kalloc();
    8000133c:	fc2ff0ef          	jal	80000afe <kalloc>
    80001340:	89aa                	mv	s3,a0
  if(mem) return mem;
    80001342:	c901                	beqz	a0,80001352 <kalloc_or_evict+0x24>
}
    80001344:	854e                	mv	a0,s3
    80001346:	70e2                	ld	ra,56(sp)
    80001348:	7442                	ld	s0,48(sp)
    8000134a:	7902                	ld	s2,32(sp)
    8000134c:	69e2                	ld	s3,24(sp)
    8000134e:	6121                	addi	sp,sp,64
    80001350:	8082                	ret
    80001352:	f426                	sd	s1,40(sp)
  printf("[pid %d] MEMFULL\n", p->pid);
    80001354:	03092583          	lw	a1,48(s2)
    80001358:	00007517          	auipc	a0,0x7
    8000135c:	ea050513          	addi	a0,a0,-352 # 800081f8 <etext+0x1f8>
    80001360:	99aff0ef          	jal	800004fa <printf>
  uint64 now = p->page_seq_ctr;
    80001364:	3a093803          	ld	a6,928(s2)
  for(int i=0;i<PGMETA_SIZE;i++){
    80001368:	43890793          	addi	a5,s2,1080
  uint64 best_age = 0;
    8000136c:	4501                	li	a0,0
  int best = -1;
    8000136e:	54fd                	li	s1,-1
  for(int i=0;i<PGMETA_SIZE;i++){
    80001370:	4701                	li	a4,0
    80001372:	40000593          	li	a1,1024
    80001376:	a039                	j	80001384 <kalloc_or_evict+0x56>
      if(best < 0 || age > best_age){ best_age = age; best = i; }
    80001378:	8536                	mv	a0,a3
    8000137a:	84ba                	mv	s1,a4
  for(int i=0;i<PGMETA_SIZE;i++){
    8000137c:	2705                	addiw	a4,a4,1
    8000137e:	07e1                	addi	a5,a5,24
    80001380:	02b70163          	beq	a4,a1,800013a2 <kalloc_or_evict+0x74>
    if(p->pgmeta[i].va && p->pgmeta[i].resident){
    80001384:	6394                	ld	a3,0(a5)
    80001386:	dafd                	beqz	a3,8000137c <kalloc_or_evict+0x4e>
    80001388:	0107c683          	lbu	a3,16(a5)
    8000138c:	dae5                	beqz	a3,8000137c <kalloc_or_evict+0x4e>
      uint64 age = now - seq; // unsigned wraparound-safe age
    8000138e:	6794                	ld	a3,8(a5)
    80001390:	40d806b3          	sub	a3,a6,a3
      if(best < 0 || age > best_age){ best_age = age; best = i; }
    80001394:	fe04c2e3          	bltz	s1,80001378 <kalloc_or_evict+0x4a>
    80001398:	fed572e3          	bgeu	a0,a3,8000137c <kalloc_or_evict+0x4e>
    8000139c:	8536                	mv	a0,a3
    8000139e:	84ba                	mv	s1,a4
    800013a0:	bff1                	j	8000137c <kalloc_or_evict+0x4e>
  if(best < 0) return -1;
    800013a2:	2604c363          	bltz	s1,80001608 <kalloc_or_evict+0x2da>
    800013a6:	e456                	sd	s5,8(sp)
  uint64 va_pg = p->pgmeta[best].va;
    800013a8:	00149793          	slli	a5,s1,0x1
    800013ac:	97a6                	add	a5,a5,s1
    800013ae:	078e                	slli	a5,a5,0x3
    800013b0:	97ca                	add	a5,a5,s2
    800013b2:	4387ba83          	ld	s5,1080(a5)
  printf("[pid %d] VICTIM va=0x%lx seq=%lu algo=FIFO\n", p->pid, va_pg, (unsigned long)p->pgmeta[best].seq);
    800013b6:	4407b683          	ld	a3,1088(a5)
    800013ba:	8656                	mv	a2,s5
    800013bc:	03092583          	lw	a1,48(s2)
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	e5050513          	addi	a0,a0,-432 # 80008210 <etext+0x210>
    800013c8:	932ff0ef          	jal	800004fa <printf>
  pte_t *pte = walk(p->pagetable, va_pg, 0);
    800013cc:	4601                	li	a2,0
    800013ce:	85d6                	mv	a1,s5
    800013d0:	05093503          	ld	a0,80(s2)
    800013d4:	bc7ff0ef          	jal	80000f9a <walk>
  if(pte == 0 || (*pte & PTE_V) == 0) { pgmeta_clear(p, best); return -1; }
    800013d8:	14050063          	beqz	a0,80001518 <kalloc_or_evict+0x1ea>
    800013dc:	6118                	ld	a4,0(a0)
    800013de:	00177793          	andi	a5,a4,1
    800013e2:	12078b63          	beqz	a5,80001518 <kalloc_or_evict+0x1ea>
    800013e6:	e05a                	sd	s6,0(sp)
  uint64 pa = PTE2PA(*pte);
    800013e8:	00a75b13          	srli	s6,a4,0xa
    800013ec:	0b32                	slli	s6,s6,0xc
  int is_dirty = p->pgmeta[best].dirty || ((*pte & PTE_W) != 0); // heuristic
    800013ee:	00149793          	slli	a5,s1,0x1
    800013f2:	97a6                	add	a5,a5,s1
    800013f4:	078e                	slli	a5,a5,0x3
    800013f6:	97ca                	add	a5,a5,s2
    800013f8:	4497c783          	lbu	a5,1097(a5)
    800013fc:	e781                	bnez	a5,80001404 <kalloc_or_evict+0xd6>
    800013fe:	8b11                	andi	a4,a4,4
    80001400:	14070a63          	beqz	a4,80001554 <kalloc_or_evict+0x226>
    printf("[pid %d] EVICT  va=0x%lx state=dirty\n", p->pid, va_pg);
    80001404:	8656                	mv	a2,s5
    80001406:	03092583          	lw	a1,48(s2)
    8000140a:	00007517          	auipc	a0,0x7
    8000140e:	e7e50513          	addi	a0,a0,-386 # 80008288 <etext+0x288>
    80001412:	8e8ff0ef          	jal	800004fa <printf>
    if(p->swapip == 0){
    80001416:	3a893783          	ld	a5,936(s2)
    8000141a:	16078063          	beqz	a5,8000157a <kalloc_or_evict+0x24c>
    8000141e:	e852                	sd	s4,16(sp)
    if((p->swap_bitmap[byte] & (1<<bit)) == 0){
    80001420:	3b494683          	lbu	a3,948(s2)
    80001424:	0016f793          	andi	a5,a3,1
    80001428:	18078063          	beqz	a5,800015a8 <kalloc_or_evict+0x27a>
  for(int i=0;i<1024;i++){
    8000142c:	4a01                	li	s4,0
    8000142e:	40000593          	li	a1,1024
    80001432:	001a079b          	addiw	a5,s4,1 # 1001 <_entry-0x7fffefff>
    80001436:	00078a1b          	sext.w	s4,a5
    8000143a:	16ba0b63          	beq	s4,a1,800015b0 <kalloc_or_evict+0x282>
    int byte = i >> 3;
    8000143e:	4037d79b          	sraiw	a5,a5,0x3
    int bit = i & 7;
    80001442:	007a7613          	andi	a2,s4,7
    if((p->swap_bitmap[byte] & (1<<bit)) == 0){
    80001446:	00f90733          	add	a4,s2,a5
    8000144a:	3b474683          	lbu	a3,948(a4)
    8000144e:	40c6d73b          	sraw	a4,a3,a2
    80001452:	8b05                	andi	a4,a4,1
    80001454:	ff79                	bnez	a4,80001432 <kalloc_or_evict+0x104>
      p->swap_bitmap[byte] |= (1<<bit);
    80001456:	97ca                	add	a5,a5,s2
    80001458:	4705                	li	a4,1
    8000145a:	00c7173b          	sllw	a4,a4,a2
    8000145e:	8ed9                	or	a3,a3,a4
    80001460:	3ad78a23          	sb	a3,948(a5)
    if(slot < 0){
    80001464:	140a4663          	bltz	s4,800015b0 <kalloc_or_evict+0x282>
    begin_op();
    80001468:	321030ef          	jal	80004f88 <begin_op>
    ilock(p->swapip);
    8000146c:	3a893503          	ld	a0,936(s2)
    80001470:	12e030ef          	jal	8000459e <ilock>
    int r = writei(p->swapip, 0, pa, slot*PGSIZE, PGSIZE);
    80001474:	6705                	lui	a4,0x1
    80001476:	00ca169b          	slliw	a3,s4,0xc
    8000147a:	865a                	mv	a2,s6
    8000147c:	4581                	li	a1,0
    8000147e:	3a893503          	ld	a0,936(s2)
    80001482:	5a8030ef          	jal	80004a2a <writei>
    80001486:	8b2a                	mv	s6,a0
    iunlock(p->swapip);
    80001488:	3a893503          	ld	a0,936(s2)
    8000148c:	1c0030ef          	jal	8000464c <iunlock>
    end_op();
    80001490:	363030ef          	jal	80004ff2 <end_op>
    if(r != PGSIZE){
    80001494:	6785                	lui	a5,0x1
    80001496:	14fb1563          	bne	s6,a5,800015e0 <kalloc_or_evict+0x2b2>
    p->swap_pages++;
    8000149a:	3b092783          	lw	a5,944(s2)
    8000149e:	2785                	addiw	a5,a5,1 # 1001 <_entry-0x7fffefff>
    800014a0:	3af92823          	sw	a5,944(s2)
    p->pgmeta[best].in_swap = 1;
    800014a4:	00149793          	slli	a5,s1,0x1
    800014a8:	97a6                	add	a5,a5,s1
    800014aa:	078e                	slli	a5,a5,0x3
    800014ac:	97ca                	add	a5,a5,s2
    800014ae:	4705                	li	a4,1
    800014b0:	44e785a3          	sb	a4,1099(a5)
    p->pgmeta[best].slot = slot;
    800014b4:	45479623          	sh	s4,1100(a5)
  printf("[pid %d] SWAPOUT va=0x%lx slot=%d\n", p->pid, va_pg, slot);
    800014b8:	86d2                	mv	a3,s4
    800014ba:	8656                	mv	a2,s5
    800014bc:	03092583          	lw	a1,48(s2)
    800014c0:	00007517          	auipc	a0,0x7
    800014c4:	e2850513          	addi	a0,a0,-472 # 800082e8 <etext+0x2e8>
    800014c8:	832ff0ef          	jal	800004fa <printf>
    800014cc:	6a42                	ld	s4,16(sp)
  uvmunmap(p->pagetable, va_pg, 1, 1);
    800014ce:	4685                	li	a3,1
    800014d0:	4605                	li	a2,1
    800014d2:	85d6                	mv	a1,s5
    800014d4:	05093503          	ld	a0,80(s2)
    800014d8:	dcdff0ef          	jal	800012a4 <uvmunmap>
  p->pgmeta[best].resident = 0;
    800014dc:	00149793          	slli	a5,s1,0x1
    800014e0:	97a6                	add	a5,a5,s1
    800014e2:	078e                	slli	a5,a5,0x3
    800014e4:	97ca                	add	a5,a5,s2
    800014e6:	44078423          	sb	zero,1096(a5)
  p->pgmeta[best].dirty = 0;
    800014ea:	440784a3          	sb	zero,1097(a5)
  p->clock_hand = (best + 1) % PGMETA_SIZE;
    800014ee:	6799                	lui	a5,0x6
    800014f0:	993e                	add	s2,s2,a5
    800014f2:	2485                	addiw	s1,s1,1
    800014f4:	41f4d71b          	sraiw	a4,s1,0x1f
    800014f8:	0167571b          	srliw	a4,a4,0x16
    800014fc:	00e487bb          	addw	a5,s1,a4
    80001500:	3ff7f793          	andi	a5,a5,1023
    80001504:	9f99                	subw	a5,a5,a4
    80001506:	42f92c23          	sw	a5,1080(s2)
    mem = kalloc();
    8000150a:	df4ff0ef          	jal	80000afe <kalloc>
    8000150e:	89aa                	mv	s3,a0
    80001510:	74a2                	ld	s1,40(sp)
    80001512:	6aa2                	ld	s5,8(sp)
    80001514:	6b02                	ld	s6,0(sp)
    80001516:	b53d                	j	80001344 <kalloc_or_evict+0x16>
  p->pgmeta[idx].va = 0;
    80001518:	00149713          	slli	a4,s1,0x1
    8000151c:	009707b3          	add	a5,a4,s1
    80001520:	078e                	slli	a5,a5,0x3
    80001522:	97ca                	add	a5,a5,s2
    80001524:	4207bc23          	sd	zero,1080(a5) # 6438 <_entry-0x7fff9bc8>
  p->pgmeta[idx].seq = 0;
    80001528:	4407b023          	sd	zero,1088(a5)
  p->pgmeta[idx].resident = 0;
    8000152c:	44078423          	sb	zero,1096(a5)
  p->pgmeta[idx].dirty = 0;
    80001530:	440784a3          	sb	zero,1097(a5)
  p->pgmeta[idx].referenced = 0;
    80001534:	44078523          	sb	zero,1098(a5)
  p->pgmeta[idx].in_swap = 0;
    80001538:	440785a3          	sb	zero,1099(a5)
  p->pgmeta[idx].slot = 0xffff;
    8000153c:	56fd                	li	a3,-1
    8000153e:	44d79623          	sh	a3,1100(a5)
  p->pgmeta[idx].perm = 0;
    80001542:	009707b3          	add	a5,a4,s1
    80001546:	078e                	slli	a5,a5,0x3
    80001548:	97ca                	add	a5,a5,s2
    8000154a:	44079723          	sh	zero,1102(a5)
}
    8000154e:	74a2                	ld	s1,40(sp)
    80001550:	6aa2                	ld	s5,8(sp)
    80001552:	bbcd                	j	80001344 <kalloc_or_evict+0x16>
    printf("[pid %d] EVICT  va=0x%lx state=clean\n", p->pid, va_pg);
    80001554:	8656                	mv	a2,s5
    80001556:	03092583          	lw	a1,48(s2)
    8000155a:	00007517          	auipc	a0,0x7
    8000155e:	ce650513          	addi	a0,a0,-794 # 80008240 <etext+0x240>
    80001562:	f99fe0ef          	jal	800004fa <printf>
    printf("[pid %d] DISCARD va=0x%lx\n", p->pid, va_pg);
    80001566:	8656                	mv	a2,s5
    80001568:	03092583          	lw	a1,48(s2)
    8000156c:	00007517          	auipc	a0,0x7
    80001570:	cfc50513          	addi	a0,a0,-772 # 80008268 <etext+0x268>
    80001574:	f87fe0ef          	jal	800004fa <printf>
    80001578:	bf99                	j	800014ce <kalloc_or_evict+0x1a0>
      printf("[pid %d] SWAPFULL\n", p->pid);
    8000157a:	03092583          	lw	a1,48(s2)
    8000157e:	00007517          	auipc	a0,0x7
    80001582:	d3250513          	addi	a0,a0,-718 # 800082b0 <etext+0x2b0>
    80001586:	f75fe0ef          	jal	800004fa <printf>
      printf("[pid %d] KILL swap-exhausted\n", p->pid);
    8000158a:	03092583          	lw	a1,48(s2)
    8000158e:	00007517          	auipc	a0,0x7
    80001592:	d3a50513          	addi	a0,a0,-710 # 800082c8 <etext+0x2c8>
    80001596:	f65fe0ef          	jal	800004fa <printf>
      setkilled(p);
    8000159a:	854a                	mv	a0,s2
    8000159c:	395010ef          	jal	80003130 <setkilled>
      return -1;
    800015a0:	74a2                	ld	s1,40(sp)
    800015a2:	6aa2                	ld	s5,8(sp)
    800015a4:	6b02                	ld	s6,0(sp)
    800015a6:	bb79                	j	80001344 <kalloc_or_evict+0x16>
    int bit = i & 7;
    800015a8:	4601                	li	a2,0
    int byte = i >> 3;
    800015aa:	4781                	li	a5,0
  for(int i=0;i<1024;i++){
    800015ac:	4a01                	li	s4,0
    800015ae:	b565                	j	80001456 <kalloc_or_evict+0x128>
      printf("[pid %d] SWAPFULL\n", p->pid);
    800015b0:	03092583          	lw	a1,48(s2)
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	cfc50513          	addi	a0,a0,-772 # 800082b0 <etext+0x2b0>
    800015bc:	f3ffe0ef          	jal	800004fa <printf>
      printf("[pid %d] KILL swap-exhausted\n", p->pid);
    800015c0:	03092583          	lw	a1,48(s2)
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	d0450513          	addi	a0,a0,-764 # 800082c8 <etext+0x2c8>
    800015cc:	f2ffe0ef          	jal	800004fa <printf>
      setkilled(p);
    800015d0:	854a                	mv	a0,s2
    800015d2:	35f010ef          	jal	80003130 <setkilled>
      return -1;
    800015d6:	74a2                	ld	s1,40(sp)
    800015d8:	6a42                	ld	s4,16(sp)
    800015da:	6aa2                	ld	s5,8(sp)
    800015dc:	6b02                	ld	s6,0(sp)
    800015de:	b39d                	j	80001344 <kalloc_or_evict+0x16>
  int byte = slot >> 3;
    800015e0:	403a571b          	sraiw	a4,s4,0x3
  p->swap_bitmap[byte] &= ~(1<<bit);
    800015e4:	974a                	add	a4,a4,s2
  int bit = slot & 7;
    800015e6:	007a7a13          	andi	s4,s4,7
  p->swap_bitmap[byte] &= ~(1<<bit);
    800015ea:	4785                	li	a5,1
    800015ec:	014797bb          	sllw	a5,a5,s4
    800015f0:	fff7c793          	not	a5,a5
    800015f4:	3b474683          	lbu	a3,948(a4) # 13b4 <_entry-0x7fffec4c>
    800015f8:	8ff5                	and	a5,a5,a3
    800015fa:	3af70a23          	sb	a5,948(a4)
    800015fe:	74a2                	ld	s1,40(sp)
    80001600:	6a42                	ld	s4,16(sp)
    80001602:	6aa2                	ld	s5,8(sp)
    80001604:	6b02                	ld	s6,0(sp)
    80001606:	bb3d                	j	80001344 <kalloc_or_evict+0x16>
    80001608:	74a2                	ld	s1,40(sp)
    8000160a:	bb2d                	j	80001344 <kalloc_or_evict+0x16>

000000008000160c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000160c:	1101                	addi	sp,sp,-32
    8000160e:	ec06                	sd	ra,24(sp)
    80001610:	e822                	sd	s0,16(sp)
    80001612:	e426                	sd	s1,8(sp)
    80001614:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001616:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001618:	00b67d63          	bgeu	a2,a1,80001632 <uvmdealloc+0x26>
    8000161c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000161e:	6785                	lui	a5,0x1
    80001620:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001622:	00f60733          	add	a4,a2,a5
    80001626:	76fd                	lui	a3,0xfffff
    80001628:	8f75                	and	a4,a4,a3
    8000162a:	97ae                	add	a5,a5,a1
    8000162c:	8ff5                	and	a5,a5,a3
    8000162e:	00f76863          	bltu	a4,a5,8000163e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001632:	8526                	mv	a0,s1
    80001634:	60e2                	ld	ra,24(sp)
    80001636:	6442                	ld	s0,16(sp)
    80001638:	64a2                	ld	s1,8(sp)
    8000163a:	6105                	addi	sp,sp,32
    8000163c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000163e:	8f99                	sub	a5,a5,a4
    80001640:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001642:	4685                	li	a3,1
    80001644:	0007861b          	sext.w	a2,a5
    80001648:	85ba                	mv	a1,a4
    8000164a:	c5bff0ef          	jal	800012a4 <uvmunmap>
    8000164e:	b7d5                	j	80001632 <uvmdealloc+0x26>

0000000080001650 <uvmalloc>:
  if(newsz < oldsz)
    80001650:	0eb66d63          	bltu	a2,a1,8000174a <uvmalloc+0xfa>
{
    80001654:	715d                	addi	sp,sp,-80
    80001656:	e486                	sd	ra,72(sp)
    80001658:	e0a2                	sd	s0,64(sp)
    8000165a:	f052                	sd	s4,32(sp)
    8000165c:	ec56                	sd	s5,24(sp)
    8000165e:	e85a                	sd	s6,16(sp)
    80001660:	0880                	addi	s0,sp,80
    80001662:	8b2a                	mv	s6,a0
    80001664:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    80001666:	6785                	lui	a5,0x1
    80001668:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000166a:	95be                	add	a1,a1,a5
    8000166c:	77fd                	lui	a5,0xfffff
    8000166e:	00f5fa33          	and	s4,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001672:	0cca7e63          	bgeu	s4,a2,8000174e <uvmalloc+0xfe>
    80001676:	fc26                	sd	s1,56(sp)
    80001678:	f84a                	sd	s2,48(sp)
    8000167a:	f44e                	sd	s3,40(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	8952                	mv	s2,s4
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001682:	0126ec13          	ori	s8,a3,18
    80001686:	89e2                	mv	s3,s8
        p->pgmeta[midx].resident = 1;
    80001688:	4b85                	li	s7,1
    8000168a:	a0b1                	j	800016d6 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    8000168c:	8652                	mv	a2,s4
    8000168e:	85ca                	mv	a1,s2
    80001690:	855a                	mv	a0,s6
    80001692:	f7bff0ef          	jal	8000160c <uvmdealloc>
      return 0;
    80001696:	4501                	li	a0,0
    80001698:	74e2                	ld	s1,56(sp)
    8000169a:	7942                	ld	s2,48(sp)
    8000169c:	79a2                	ld	s3,40(sp)
    8000169e:	6ba2                	ld	s7,8(sp)
    800016a0:	6c02                	ld	s8,0(sp)
}
    800016a2:	60a6                	ld	ra,72(sp)
    800016a4:	6406                	ld	s0,64(sp)
    800016a6:	7a02                	ld	s4,32(sp)
    800016a8:	6ae2                	ld	s5,24(sp)
    800016aa:	6b42                	ld	s6,16(sp)
    800016ac:	6161                	addi	sp,sp,80
    800016ae:	8082                	ret
      kfree(mem);
    800016b0:	8526                	mv	a0,s1
    800016b2:	b6aff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016b6:	8652                	mv	a2,s4
    800016b8:	85ca                	mv	a1,s2
    800016ba:	855a                	mv	a0,s6
    800016bc:	f51ff0ef          	jal	8000160c <uvmdealloc>
      return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	74e2                	ld	s1,56(sp)
    800016c4:	7942                	ld	s2,48(sp)
    800016c6:	79a2                	ld	s3,40(sp)
    800016c8:	6ba2                	ld	s7,8(sp)
    800016ca:	6c02                	ld	s8,0(sp)
    800016cc:	bfd9                	j	800016a2 <uvmalloc+0x52>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016ce:	6785                	lui	a5,0x1
    800016d0:	993e                	add	s2,s2,a5
    800016d2:	07597563          	bgeu	s2,s5,8000173c <uvmalloc+0xec>
    mem = kalloc_or_evict(myproc());
    800016d6:	553000ef          	jal	80002428 <myproc>
    800016da:	c55ff0ef          	jal	8000132e <kalloc_or_evict>
    800016de:	84aa                	mv	s1,a0
    if(mem == 0){
    800016e0:	d555                	beqz	a0,8000168c <uvmalloc+0x3c>
    memset(mem, 0, PGSIZE);
    800016e2:	6605                	lui	a2,0x1
    800016e4:	4581                	li	a1,0
    800016e6:	dcaff0ef          	jal	80000cb0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800016ea:	874e                	mv	a4,s3
    800016ec:	86a6                	mv	a3,s1
    800016ee:	6605                	lui	a2,0x1
    800016f0:	85ca                	mv	a1,s2
    800016f2:	855a                	mv	a0,s6
    800016f4:	99dff0ef          	jal	80001090 <mappages>
    800016f8:	fd45                	bnez	a0,800016b0 <uvmalloc+0x60>
    struct proc *p = myproc();
    800016fa:	52f000ef          	jal	80002428 <myproc>
    800016fe:	84aa                	mv	s1,a0
    if(p){
    80001700:	d579                	beqz	a0,800016ce <uvmalloc+0x7e>
      int midx = pgmeta_alloc(p, a);
    80001702:	85ca                	mv	a1,s2
    80001704:	ffcff0ef          	jal	80000f00 <pgmeta_alloc>
      if(midx >= 0){
    80001708:	fc0543e3          	bltz	a0,800016ce <uvmalloc+0x7e>
        p->pgmeta[midx].resident = 1;
    8000170c:	00151713          	slli	a4,a0,0x1
    80001710:	00a707b3          	add	a5,a4,a0
    80001714:	078e                	slli	a5,a5,0x3
    80001716:	97a6                	add	a5,a5,s1
    80001718:	45778423          	sb	s7,1096(a5) # 1448 <_entry-0x7fffebb8>
        p->pgmeta[midx].perm = PTE_R|PTE_U|xperm;
    8000171c:	45879723          	sh	s8,1102(a5)
        p->pgmeta[midx].dirty = 0;
    80001720:	440784a3          	sb	zero,1097(a5)
        p->pgmeta[midx].seq = p->page_seq_ctr++;
    80001724:	3a04b783          	ld	a5,928(s1)
    80001728:	00178693          	addi	a3,a5,1
    8000172c:	3ad4b023          	sd	a3,928(s1)
    80001730:	972a                	add	a4,a4,a0
    80001732:	070e                	slli	a4,a4,0x3
    80001734:	94ba                	add	s1,s1,a4
    80001736:	44f4b023          	sd	a5,1088(s1)
    8000173a:	bf51                	j	800016ce <uvmalloc+0x7e>
  return newsz;
    8000173c:	8556                	mv	a0,s5
    8000173e:	74e2                	ld	s1,56(sp)
    80001740:	7942                	ld	s2,48(sp)
    80001742:	79a2                	ld	s3,40(sp)
    80001744:	6ba2                	ld	s7,8(sp)
    80001746:	6c02                	ld	s8,0(sp)
    80001748:	bfa9                	j	800016a2 <uvmalloc+0x52>
    return oldsz;
    8000174a:	852e                	mv	a0,a1
}
    8000174c:	8082                	ret
  return newsz;
    8000174e:	8532                	mv	a0,a2
    80001750:	bf89                	j	800016a2 <uvmalloc+0x52>

0000000080001752 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001752:	715d                	addi	sp,sp,-80
    80001754:	e486                	sd	ra,72(sp)
    80001756:	e0a2                	sd	s0,64(sp)
    80001758:	fc26                	sd	s1,56(sp)
    8000175a:	f84a                	sd	s2,48(sp)
    8000175c:	f44e                	sd	s3,40(sp)
    8000175e:	f052                	sd	s4,32(sp)
    80001760:	ec56                	sd	s5,24(sp)
    80001762:	e85a                	sd	s6,16(sp)
    80001764:	e45e                	sd	s7,8(sp)
    80001766:	e062                	sd	s8,0(sp)
    80001768:	0880                	addi	s0,sp,80
    8000176a:	8c2a                	mv	s8,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000176c:	84aa                	mv	s1,a0
    8000176e:	4981                	li	s3,0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001770:	4b05                	li	s6,1
      uint64 pa = PTE2PA(pte);
      if(pte & PTE_U){
        // free the user page backing this PTE
        kfree((void*)pa);
      }
      printf("freewalk: warning: unexpected leaf PTE at index %d (pte=0x%lx), clearing\n", i, pte);
    80001772:	00007b97          	auipc	s7,0x7
    80001776:	b9eb8b93          	addi	s7,s7,-1122 # 80008310 <etext+0x310>
  for(int i = 0; i < 512; i++){
    8000177a:	20000a93          	li	s5,512
    8000177e:	a025                	j	800017a6 <freewalk+0x54>
      uint64 child = PTE2PA(pte);
    80001780:	00a95513          	srli	a0,s2,0xa
      freewalk((pagetable_t)child);
    80001784:	0532                	slli	a0,a0,0xc
    80001786:	fcdff0ef          	jal	80001752 <freewalk>
      pagetable[i] = 0;
    8000178a:	0004b023          	sd	zero,0(s1)
    8000178e:	a801                	j	8000179e <freewalk+0x4c>
      printf("freewalk: warning: unexpected leaf PTE at index %d (pte=0x%lx), clearing\n", i, pte);
    80001790:	864a                	mv	a2,s2
    80001792:	85ce                	mv	a1,s3
    80001794:	855e                	mv	a0,s7
    80001796:	d65fe0ef          	jal	800004fa <printf>
      pagetable[i] = 0;
    8000179a:	000a3023          	sd	zero,0(s4)
  for(int i = 0; i < 512; i++){
    8000179e:	2985                	addiw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    800017a0:	04a1                	addi	s1,s1,8
    800017a2:	03598563          	beq	s3,s5,800017cc <freewalk+0x7a>
    pte_t pte = pagetable[i];
    800017a6:	8a26                	mv	s4,s1
    800017a8:	0004b903          	ld	s2,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800017ac:	00f97793          	andi	a5,s2,15
    800017b0:	fd6788e3          	beq	a5,s6,80001780 <freewalk+0x2e>
    } else if(pte & PTE_V){
    800017b4:	00197793          	andi	a5,s2,1
    800017b8:	d3fd                	beqz	a5,8000179e <freewalk+0x4c>
      if(pte & PTE_U){
    800017ba:	01097793          	andi	a5,s2,16
    800017be:	dbe9                	beqz	a5,80001790 <freewalk+0x3e>
      uint64 pa = PTE2PA(pte);
    800017c0:	00a95513          	srli	a0,s2,0xa
        kfree((void*)pa);
    800017c4:	0532                	slli	a0,a0,0xc
    800017c6:	a56ff0ef          	jal	80000a1c <kfree>
    800017ca:	b7d9                	j	80001790 <freewalk+0x3e>
    }
  }
  kfree((void*)pagetable);
    800017cc:	8562                	mv	a0,s8
    800017ce:	a4eff0ef          	jal	80000a1c <kfree>
}
    800017d2:	60a6                	ld	ra,72(sp)
    800017d4:	6406                	ld	s0,64(sp)
    800017d6:	74e2                	ld	s1,56(sp)
    800017d8:	7942                	ld	s2,48(sp)
    800017da:	79a2                	ld	s3,40(sp)
    800017dc:	7a02                	ld	s4,32(sp)
    800017de:	6ae2                	ld	s5,24(sp)
    800017e0:	6b42                	ld	s6,16(sp)
    800017e2:	6ba2                	ld	s7,8(sp)
    800017e4:	6c02                	ld	s8,0(sp)
    800017e6:	6161                	addi	sp,sp,80
    800017e8:	8082                	ret

00000000800017ea <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800017ea:	1101                	addi	sp,sp,-32
    800017ec:	ec06                	sd	ra,24(sp)
    800017ee:	e822                	sd	s0,16(sp)
    800017f0:	e426                	sd	s1,8(sp)
    800017f2:	1000                	addi	s0,sp,32
    800017f4:	84aa                	mv	s1,a0
  if(sz > 0)
    800017f6:	e989                	bnez	a1,80001808 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800017f8:	8526                	mv	a0,s1
    800017fa:	f59ff0ef          	jal	80001752 <freewalk>
}
    800017fe:	60e2                	ld	ra,24(sp)
    80001800:	6442                	ld	s0,16(sp)
    80001802:	64a2                	ld	s1,8(sp)
    80001804:	6105                	addi	sp,sp,32
    80001806:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001808:	6785                	lui	a5,0x1
    8000180a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000180c:	95be                	add	a1,a1,a5
    8000180e:	4685                	li	a3,1
    80001810:	00c5d613          	srli	a2,a1,0xc
    80001814:	4581                	li	a1,0
    80001816:	a8fff0ef          	jal	800012a4 <uvmunmap>
    8000181a:	bff9                	j	800017f8 <uvmfree+0xe>

000000008000181c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000181c:	0e060863          	beqz	a2,8000190c <uvmcopy+0xf0>
{
    80001820:	711d                	addi	sp,sp,-96
    80001822:	ec86                	sd	ra,88(sp)
    80001824:	e8a2                	sd	s0,80(sp)
    80001826:	e4a6                	sd	s1,72(sp)
    80001828:	e0ca                	sd	s2,64(sp)
    8000182a:	fc4e                	sd	s3,56(sp)
    8000182c:	f852                	sd	s4,48(sp)
    8000182e:	f456                	sd	s5,40(sp)
    80001830:	f05a                	sd	s6,32(sp)
    80001832:	ec5e                	sd	s7,24(sp)
    80001834:	e862                	sd	s8,16(sp)
    80001836:	e466                	sd	s9,8(sp)
    80001838:	1080                	addi	s0,sp,96
    8000183a:	8b2a                	mv	s6,a0
    8000183c:	8bae                	mv	s7,a1
    8000183e:	8ab2                	mv	s5,a2
    80001840:	8a36                	mv	s4,a3
  for(i = 0; i < sz; i += PGSIZE){
    80001842:	4481                	li	s1,0
    }
    // record resident page in child's pgmeta
    if(child){
      int midx = pgmeta_alloc(child, i);
      if(midx >= 0){
        child->pgmeta[midx].resident = 1;
    80001844:	4c05                	li	s8,1
    80001846:	a00d                	j	80001868 <uvmcopy+0x4c>
      kfree(mem);
    80001848:	854e                	mv	a0,s3
    8000184a:	9d2ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000184e:	4685                	li	a3,1
    80001850:	00c4d613          	srli	a2,s1,0xc
    80001854:	4581                	li	a1,0
    80001856:	855e                	mv	a0,s7
    80001858:	a4dff0ef          	jal	800012a4 <uvmunmap>
  return -1;
    8000185c:	557d                	li	a0,-1
    8000185e:	a851                	j	800018f2 <uvmcopy+0xd6>
  for(i = 0; i < sz; i += PGSIZE){
    80001860:	6785                	lui	a5,0x1
    80001862:	94be                	add	s1,s1,a5
    80001864:	0954f663          	bgeu	s1,s5,800018f0 <uvmcopy+0xd4>
    if((pte = walk(old, i, 0)) == 0)
    80001868:	4601                	li	a2,0
    8000186a:	85a6                	mv	a1,s1
    8000186c:	855a                	mv	a0,s6
    8000186e:	f2cff0ef          	jal	80000f9a <walk>
    80001872:	d57d                	beqz	a0,80001860 <uvmcopy+0x44>
    if((*pte & PTE_V) == 0)
    80001874:	6118                	ld	a4,0(a0)
    80001876:	00177793          	andi	a5,a4,1
    8000187a:	d3fd                	beqz	a5,80001860 <uvmcopy+0x44>
    pa = PTE2PA(*pte);
    8000187c:	00a75593          	srli	a1,a4,0xa
    80001880:	00c59c93          	slli	s9,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001884:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc_or_evict(myproc())) == 0)
    80001888:	3a1000ef          	jal	80002428 <myproc>
    8000188c:	aa3ff0ef          	jal	8000132e <kalloc_or_evict>
    80001890:	89aa                	mv	s3,a0
    80001892:	dd55                	beqz	a0,8000184e <uvmcopy+0x32>
    memmove(mem, (char*)pa, PGSIZE);
    80001894:	6605                	lui	a2,0x1
    80001896:	85e6                	mv	a1,s9
    80001898:	c74ff0ef          	jal	80000d0c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000189c:	874a                	mv	a4,s2
    8000189e:	86ce                	mv	a3,s3
    800018a0:	6605                	lui	a2,0x1
    800018a2:	85a6                	mv	a1,s1
    800018a4:	855e                	mv	a0,s7
    800018a6:	feaff0ef          	jal	80001090 <mappages>
    800018aa:	fd59                	bnez	a0,80001848 <uvmcopy+0x2c>
    if(child){
    800018ac:	fa0a0ae3          	beqz	s4,80001860 <uvmcopy+0x44>
      int midx = pgmeta_alloc(child, i);
    800018b0:	85a6                	mv	a1,s1
    800018b2:	8552                	mv	a0,s4
    800018b4:	e4cff0ef          	jal	80000f00 <pgmeta_alloc>
      if(midx >= 0){
    800018b8:	fa0544e3          	bltz	a0,80001860 <uvmcopy+0x44>
        child->pgmeta[midx].resident = 1;
    800018bc:	00151793          	slli	a5,a0,0x1
    800018c0:	00a78733          	add	a4,a5,a0
    800018c4:	070e                	slli	a4,a4,0x3
    800018c6:	9752                	add	a4,a4,s4
    800018c8:	45870423          	sb	s8,1096(a4)
        child->pgmeta[midx].perm = flags;
    800018cc:	45271723          	sh	s2,1102(a4)
        child->pgmeta[midx].dirty = 0;
    800018d0:	440704a3          	sb	zero,1097(a4)
        child->pgmeta[midx].referenced = 1;
    800018d4:	45870523          	sb	s8,1098(a4)
        child->pgmeta[midx].seq = child->page_seq_ctr++;
    800018d8:	3a0a3703          	ld	a4,928(s4)
    800018dc:	00170693          	addi	a3,a4,1
    800018e0:	3ada3023          	sd	a3,928(s4)
    800018e4:	97aa                	add	a5,a5,a0
    800018e6:	078e                	slli	a5,a5,0x3
    800018e8:	97d2                	add	a5,a5,s4
    800018ea:	44e7b023          	sd	a4,1088(a5) # 1440 <_entry-0x7fffebc0>
    800018ee:	bf8d                	j	80001860 <uvmcopy+0x44>
  return 0;
    800018f0:	4501                	li	a0,0
}
    800018f2:	60e6                	ld	ra,88(sp)
    800018f4:	6446                	ld	s0,80(sp)
    800018f6:	64a6                	ld	s1,72(sp)
    800018f8:	6906                	ld	s2,64(sp)
    800018fa:	79e2                	ld	s3,56(sp)
    800018fc:	7a42                	ld	s4,48(sp)
    800018fe:	7aa2                	ld	s5,40(sp)
    80001900:	7b02                	ld	s6,32(sp)
    80001902:	6be2                	ld	s7,24(sp)
    80001904:	6c42                	ld	s8,16(sp)
    80001906:	6ca2                	ld	s9,8(sp)
    80001908:	6125                	addi	sp,sp,96
    8000190a:	8082                	ret
  return 0;
    8000190c:	4501                	li	a0,0
}
    8000190e:	8082                	ret

0000000080001910 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001910:	1141                	addi	sp,sp,-16
    80001912:	e406                	sd	ra,8(sp)
    80001914:	e022                	sd	s0,0(sp)
    80001916:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001918:	4601                	li	a2,0
    8000191a:	e80ff0ef          	jal	80000f9a <walk>
  if(pte == 0)
    8000191e:	c901                	beqz	a0,8000192e <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001920:	611c                	ld	a5,0(a0)
    80001922:	9bbd                	andi	a5,a5,-17
    80001924:	e11c                	sd	a5,0(a0)
}
    80001926:	60a2                	ld	ra,8(sp)
    80001928:	6402                	ld	s0,0(sp)
    8000192a:	0141                	addi	sp,sp,16
    8000192c:	8082                	ret
    panic("uvmclear");
    8000192e:	00007517          	auipc	a0,0x7
    80001932:	a3250513          	addi	a0,a0,-1486 # 80008360 <etext+0x360>
    80001936:	eabfe0ef          	jal	800007e0 <panic>

000000008000193a <vmfault>:
// - If within heap (va < p->heap_brk and va < p->sz): map zero page.
// - If within stack (within one page below current user sp and below sz upper bound): map zero page.
// Returns physical address mapped (>0) on success, 0 on invalid or failure.
uint64
vmfault(pagetable_t pagetable, uint64 va, int is_write)
{
    8000193a:	711d                	addi	sp,sp,-96
    8000193c:	ec86                	sd	ra,88(sp)
    8000193e:	e8a2                	sd	s0,80(sp)
    80001940:	e4a6                	sd	s1,72(sp)
    80001942:	f852                	sd	s4,48(sp)
    80001944:	f456                	sd	s5,40(sp)
    80001946:	f05a                	sd	s6,32(sp)
    80001948:	1080                	addi	s0,sp,96
    8000194a:	8aaa                	mv	s5,a0
    8000194c:	84ae                	mv	s1,a1
    8000194e:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80001950:	2d9000ef          	jal	80002428 <myproc>
  if(va >= MAXVA)
    80001954:	57fd                	li	a5,-1
    80001956:	83e9                	srli	a5,a5,0x1a
    return 0;
    80001958:	4b01                	li	s6,0
  if(va >= MAXVA)
    8000195a:	3297e063          	bltu	a5,s1,80001c7a <vmfault+0x340>
    8000195e:	e0ca                	sd	s2,64(sp)
    80001960:	fc4e                	sd	s3,56(sp)
    80001962:	ec5e                	sd	s7,24(sp)
    80001964:	e862                	sd	s8,16(sp)
    80001966:	89aa                	mv	s3,a0

  uint64 va_pg = PGROUNDDOWN(va);
    80001968:	77fd                	lui	a5,0xfffff
    8000196a:	8cfd                	and	s1,s1,a5

  // Determine region classification first
  // Invalid if above process size and not a stack growth below current SP.
  // We'll allow exactly one page below current SP for stack.
  int is_stack = 0;
  uint64 usp = p->trapframe ? p->trapframe->sp : 0;
    8000196c:	6d3c                	ld	a5,88(a0)
  int is_stack = 0;
    8000196e:	4b01                	li	s6,0
  uint64 usp = p->trapframe ? p->trapframe->sp : 0;
    80001970:	c799                	beqz	a5,8000197e <vmfault+0x44>
  // Allow growth only for the page immediately below current SP
  uint64 sp_page = PGROUNDDOWN(usp);
    80001972:	777d                	lui	a4,0xfffff
    80001974:	7b9c                	ld	a5,48(a5)
    80001976:	8ff9                	and	a5,a5,a4
  if(va_pg == sp_page - PGSIZE && va_pg < p->sz)
    80001978:	97ba                	add	a5,a5,a4
    8000197a:	00978c63          	beq	a5,s1,80001992 <vmfault+0x58>
    is_stack = 1;

  // Determine end of program segments (initial brk base)
  uint64 prog_end = 0;
  for(int i = 0; i < p->nsegs; i++){
    8000197e:	1989a603          	lw	a2,408(s3)
    80001982:	62c05f63          	blez	a2,80001fc0 <vmfault+0x686>
    80001986:	87ce                	mv	a5,s3
    80001988:	00561513          	slli	a0,a2,0x5
    8000198c:	954e                	add	a0,a0,s3
  uint64 prog_end = 0;
    8000198e:	4581                	li	a1,0
    80001990:	a811                	j	800019a4 <vmfault+0x6a>
  if(va_pg == sp_page - PGSIZE && va_pg < p->sz)
    80001992:	04853b03          	ld	s6,72(a0)
    80001996:	0164bb33          	sltu	s6,s1,s6
    8000199a:	b7d5                	j	8000197e <vmfault+0x44>
  for(int i = 0; i < p->nsegs; i++){
    8000199c:	02078793          	addi	a5,a5,32 # fffffffffffff020 <end+0xffffffff7fe4ecf8>
    800019a0:	00a78b63          	beq	a5,a0,800019b6 <vmfault+0x7c>
    uint64 end = p->segs[i].va + p->segs[i].memsz;
    800019a4:	1a07b703          	ld	a4,416(a5)
    800019a8:	1a87b683          	ld	a3,424(a5)
    800019ac:	9736                	add	a4,a4,a3
    if(end > prog_end) prog_end = end;
    800019ae:	fee5f7e3          	bgeu	a1,a4,8000199c <vmfault+0x62>
    800019b2:	85ba                	mv	a1,a4
    800019b4:	b7e5                	j	8000199c <vmfault+0x62>
  }
  // Heap pages are valid only within [prog_end, heap_brk)
  int is_heap = (va_pg >= prog_end && va_pg < p->heap_brk && va_pg < p->sz);
    800019b6:	4c01                	li	s8,0
    800019b8:	60b4fb63          	bgeu	s1,a1,80001fce <vmfault+0x694>
    800019bc:	1a098793          	addi	a5,s3,416

  // Check if inside an exec segment recorded in p->segs
  int seg_idx = -1;
  for(int i = 0; i < p->nsegs; i++){
    800019c0:	4901                	li	s2,0
    800019c2:	a031                	j	800019ce <vmfault+0x94>
    800019c4:	2905                	addiw	s2,s2,1
    800019c6:	02078793          	addi	a5,a5,32
    800019ca:	00c90a63          	beq	s2,a2,800019de <vmfault+0xa4>
    uint64 sva = p->segs[i].va;
    800019ce:	6398                	ld	a4,0(a5)
    uint64 ev = p->segs[i].va + p->segs[i].memsz;
    if(va_pg >= sva && va_pg < ev){
    800019d0:	fee4eae3          	bltu	s1,a4,800019c4 <vmfault+0x8a>
    uint64 ev = p->segs[i].va + p->segs[i].memsz;
    800019d4:	6794                	ld	a3,8(a5)
    800019d6:	9736                	add	a4,a4,a3
    if(va_pg >= sva && va_pg < ev){
    800019d8:	fee4f6e3          	bgeu	s1,a4,800019c4 <vmfault+0x8a>
    800019dc:	a011                	j	800019e0 <vmfault+0xa6>
  int seg_idx = -1;
    800019de:	597d                	li	s2,-1
      break;
    }
  }

  // Already mapped? Maybe a permission fault; consider upgrading.
  pte_t *pte_present = walk(pagetable, va_pg, 0);
    800019e0:	4601                	li	a2,0
    800019e2:	85a6                	mv	a1,s1
    800019e4:	8556                	mv	a0,s5
    800019e6:	db4ff0ef          	jal	80000f9a <walk>
    800019ea:	8baa                	mv	s7,a0
  if(pte_present && (*pte_present & PTE_V)){
    800019ec:	c971                	beqz	a0,80001ac0 <vmfault+0x186>
    800019ee:	611c                	ld	a5,0(a0)
    800019f0:	0017f713          	andi	a4,a5,1
    800019f4:	c771                	beqz	a4,80001ac0 <vmfault+0x186>
    int allow_w = (is_heap || is_stack) || (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_W));
    800019f6:	018b6c33          	or	s8,s6,s8
    800019fa:	060c1363          	bnez	s8,80001a60 <vmfault+0x126>
    int allow_x = (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_X));
    800019fe:	8762                	mv	a4,s8
    int allow_w = (is_heap || is_stack) || (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_W));
    80001a00:	02094363          	bltz	s2,80001a26 <vmfault+0xec>
    80001a04:	00591713          	slli	a4,s2,0x5
    80001a08:	974e                	add	a4,a4,s3
    80001a0a:	1bc72c03          	lw	s8,444(a4) # fffffffffffff1bc <end+0xffffffff7fe4ee94>
    80001a0e:	402c5c1b          	sraiw	s8,s8,0x2
    80001a12:	001c7c13          	andi	s8,s8,1
    int allow_x = (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_X));
    80001a16:	00591713          	slli	a4,s2,0x5
    80001a1a:	974e                	add	a4,a4,s3
    80001a1c:	1bc72703          	lw	a4,444(a4)
    80001a20:	4037571b          	sraiw	a4,a4,0x3
    80001a24:	8b05                	andi	a4,a4,1
    if(is_write == 1 && ((*pte_present & PTE_W) == 0) && allow_w){
    80001a26:	4685                	li	a3,1
    80001a28:	04da0063          	beq	s4,a3,80001a68 <vmfault+0x12e>
  sfence_vma();
      int midx = pgmeta_alloc(p, va_pg);
      if(midx >= 0) { p->pgmeta[midx].dirty = 1; p->pgmeta[midx].referenced = 1; }
      return PTE2PA(*pte_present);
    }
    if(is_write == -1 && ((*pte_present & PTE_X) == 0) && allow_x){
    80001a2c:	56fd                	li	a3,-1
  *pte_present |= PTE_X;
  sfence_vma();
      return PTE2PA(*pte_present);
    }
    // otherwise, mapped but invalid access
    return 0;
    80001a2e:	4b01                	li	s6,0
    if(is_write == -1 && ((*pte_present & PTE_X) == 0) && allow_x){
    80001a30:	5ada1c63          	bne	s4,a3,80001fe8 <vmfault+0x6ae>
    80001a34:	0087fb13          	andi	s6,a5,8
    80001a38:	540b1863          	bnez	s6,80001f88 <vmfault+0x64e>
    80001a3c:	5a070b63          	beqz	a4,80001ff2 <vmfault+0x6b8>
  *pte_present |= PTE_X;
    80001a40:	0087e793          	ori	a5,a5,8
    80001a44:	00fbb023          	sd	a5,0(s7)
    80001a48:	12000073          	sfence.vma
      return PTE2PA(*pte_present);
    80001a4c:	000bbb03          	ld	s6,0(s7)
    80001a50:	00ab5b13          	srli	s6,s6,0xa
    80001a54:	0b32                	slli	s6,s6,0xc
    80001a56:	6906                	ld	s2,64(sp)
    80001a58:	79e2                	ld	s3,56(sp)
    80001a5a:	6be2                	ld	s7,24(sp)
    80001a5c:	6c42                	ld	s8,16(sp)
    80001a5e:	ac31                	j	80001c7a <vmfault+0x340>
    int allow_x = (seg_idx >= 0 && (p->segs[seg_idx].perm & PTE_X));
    80001a60:	4701                	li	a4,0
    80001a62:	fc0942e3          	bltz	s2,80001a26 <vmfault+0xec>
    80001a66:	bf45                	j	80001a16 <vmfault+0xdc>
    if(is_write == 1 && ((*pte_present & PTE_W) == 0) && allow_w){
    80001a68:	0047fb13          	andi	s6,a5,4
    80001a6c:	500b1863          	bnez	s6,80001f7c <vmfault+0x642>
    80001a70:	000c1763          	bnez	s8,80001a7e <vmfault+0x144>
    80001a74:	6906                	ld	s2,64(sp)
    80001a76:	79e2                	ld	s3,56(sp)
    80001a78:	6be2                	ld	s7,24(sp)
    80001a7a:	6c42                	ld	s8,16(sp)
    80001a7c:	aafd                	j	80001c7a <vmfault+0x340>
  *pte_present |= PTE_W;
    80001a7e:	0047e793          	ori	a5,a5,4
    80001a82:	00fbb023          	sd	a5,0(s7)
    80001a86:	12000073          	sfence.vma
      int midx = pgmeta_alloc(p, va_pg);
    80001a8a:	85a6                	mv	a1,s1
    80001a8c:	854e                	mv	a0,s3
    80001a8e:	c72ff0ef          	jal	80000f00 <pgmeta_alloc>
      if(midx >= 0) { p->pgmeta[midx].dirty = 1; p->pgmeta[midx].referenced = 1; }
    80001a92:	00054d63          	bltz	a0,80001aac <vmfault+0x172>
    80001a96:	00151793          	slli	a5,a0,0x1
    80001a9a:	00a786b3          	add	a3,a5,a0
    80001a9e:	068e                	slli	a3,a3,0x3
    80001aa0:	96ce                	add	a3,a3,s3
    80001aa2:	4605                	li	a2,1
    80001aa4:	44c684a3          	sb	a2,1097(a3) # fffffffffffff449 <end+0xffffffff7fe4f121>
    80001aa8:	44c68523          	sb	a2,1098(a3)
      return PTE2PA(*pte_present);
    80001aac:	000bbb03          	ld	s6,0(s7)
    80001ab0:	00ab5b13          	srli	s6,s6,0xa
    80001ab4:	0b32                	slli	s6,s6,0xc
    80001ab6:	6906                	ld	s2,64(sp)
    80001ab8:	79e2                	ld	s3,56(sp)
    80001aba:	6be2                	ld	s7,24(sp)
    80001abc:	6c42                	ld	s8,16(sp)
    80001abe:	aa75                	j	80001c7a <vmfault+0x340>
  }

  // Determine action
  // Log PAGEFAULT with cause classification
  const char *access_str = (is_write == -1 ? "exec" : (is_write ? "write" : "read"));
    80001ac0:	57fd                	li	a5,-1
    80001ac2:	00007697          	auipc	a3,0x7
    80001ac6:	8ae68693          	addi	a3,a3,-1874 # 80008370 <etext+0x370>
    80001aca:	00fa0c63          	beq	s4,a5,80001ae2 <vmfault+0x1a8>
    80001ace:	00007697          	auipc	a3,0x7
    80001ad2:	da268693          	addi	a3,a3,-606 # 80008870 <etext+0x870>
    80001ad6:	000a0663          	beqz	s4,80001ae2 <vmfault+0x1a8>
    80001ada:	00007697          	auipc	a3,0x7
    80001ade:	89e68693          	addi	a3,a3,-1890 # 80008378 <etext+0x378>
  for(int i=0;i<PGMETA_SIZE;i++) if(p->pgmeta[i].va == va_pg) return i;
    80001ae2:	43898793          	addi	a5,s3,1080
    80001ae6:	4b81                	li	s7,0
    80001ae8:	40000613          	li	a2,1024
    80001aec:	6398                	ld	a4,0(a5)
    80001aee:	00e48863          	beq	s1,a4,80001afe <vmfault+0x1c4>
    80001af2:	2b85                	addiw	s7,s7,1
    80001af4:	07e1                	addi	a5,a5,24
    80001af6:	fecb9be3          	bne	s7,a2,80001aec <vmfault+0x1b2>
  return -1;
    80001afa:	5bfd                	li	s7,-1
    80001afc:	a821                	j	80001b14 <vmfault+0x1da>
  const char *cause_str = "exec";
  int midx_find = pgmeta_find(p, va_pg);
  if(midx_find >= 0 && p->pgmeta[midx_find].in_swap){
    80001afe:	000bcb63          	bltz	s7,80001b14 <vmfault+0x1da>
    80001b02:	001b9793          	slli	a5,s7,0x1
    80001b06:	97de                	add	a5,a5,s7
    80001b08:	078e                	slli	a5,a5,0x3
    80001b0a:	97ce                	add	a5,a5,s3
    80001b0c:	44b7c783          	lbu	a5,1099(a5)
    80001b10:	16079e63          	bnez	a5,80001c8c <vmfault+0x352>
    cause_str = "swap";
  } else if(seg_idx >= 0){
    80001b14:	12094163          	bltz	s2,80001c36 <vmfault+0x2fc>
  } else if(is_stack){
    cause_str = "stack";
  } else {
    cause_str = "exec"; // default, will be treated invalid later if truly invalid
  }
  printf("[pid %d] PAGEFAULT va=0x%lx access=%s cause=%s\n", p->pid, va_pg, access_str, cause_str);
    80001b18:	00007717          	auipc	a4,0x7
    80001b1c:	85870713          	addi	a4,a4,-1960 # 80008370 <etext+0x370>
    80001b20:	8626                	mv	a2,s1
    80001b22:	0309a583          	lw	a1,48(s3)
    80001b26:	00007517          	auipc	a0,0x7
    80001b2a:	87250513          	addi	a0,a0,-1934 # 80008398 <etext+0x398>
    80001b2e:	9cdfe0ef          	jal	800004fa <printf>

  if(seg_idx >= 0){
    // Instruction or data page backed by the executable file
    if(p->execip == 0)
    80001b32:	1909b783          	ld	a5,400(s3)
    80001b36:	44078f63          	beqz	a5,80001f94 <vmfault+0x65a>
      return 0;
    // if page is swapped, swap it in
    int midx = midx_find;
    if(midx >= 0 && p->pgmeta[midx].in_swap){
    80001b3a:	000bcb63          	bltz	s7,80001b50 <vmfault+0x216>
    80001b3e:	001b9793          	slli	a5,s7,0x1
    80001b42:	97de                	add	a5,a5,s7
    80001b44:	078e                	slli	a5,a5,0x3
    80001b46:	97ce                	add	a5,a5,s3
    80001b48:	44b7c783          	lbu	a5,1099(a5)
    80001b4c:	16079963          	bnez	a5,80001cbe <vmfault+0x384>
      p->pgmeta[midx].referenced = 1;
  printf("[pid %d] SWAPIN va=0x%lx slot=%d\n", p->pid, va_pg, slot);
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
      return (uint64)mem;
    }
    char *mem = kalloc_or_evict(p);
    80001b50:	854e                	mv	a0,s3
    80001b52:	fdcff0ef          	jal	8000132e <kalloc_or_evict>
    80001b56:	8c2a                	mv	s8,a0
    if(mem == 0){
      // allocation failed despite eviction attempt; return 0 so trap prints KILL
      return 0;
    80001b58:	4b01                	li	s6,0
    if(mem == 0){
    80001b5a:	4a050663          	beqz	a0,80002006 <vmfault+0x6cc>
    80001b5e:	e466                	sd	s9,8(sp)
    }
    memset(mem, 0, PGSIZE);
    80001b60:	6605                	lui	a2,0x1
    80001b62:	4581                	li	a1,0
    80001b64:	94cff0ef          	jal	80000cb0 <memset>

    // Read the page portion that is file-backed.
    uint64 page_off = va_pg - p->segs[seg_idx].va; // offset into segment
    80001b68:	00d90793          	addi	a5,s2,13
    80001b6c:	0796                	slli	a5,a5,0x5
    80001b6e:	97ce                	add	a5,a5,s3
    80001b70:	0007bb03          	ld	s6,0(a5)
    80001b74:	41648b33          	sub	s6,s1,s6
    uint64 file_off = p->segs[seg_idx].off + page_off;
    80001b78:	00591793          	slli	a5,s2,0x5
    80001b7c:	97ce                	add	a5,a5,s3
    80001b7e:	1b87ac83          	lw	s9,440(a5)
    uint n = 0;
    if(page_off < p->segs[seg_idx].filesz){
    80001b82:	1b07b783          	ld	a5,432(a5)
    80001b86:	28fb6b63          	bltu	s6,a5,80001e1c <vmfault+0x4e2>
        kfree(mem);
        return 0;
      }
    }
    int perm = PTE_U | PTE_R;
    if(p->segs[seg_idx].perm & PTE_X) perm |= PTE_X;
    80001b8a:	00591793          	slli	a5,s2,0x5
    80001b8e:	97ce                	add	a5,a5,s3
    80001b90:	1bc7a783          	lw	a5,444(a5)
    80001b94:	0087f713          	andi	a4,a5,8
    80001b98:	4ce9                	li	s9,26
    80001b9a:	e311                	bnez	a4,80001b9e <vmfault+0x264>
    int perm = PTE_U | PTE_R;
    80001b9c:	4cc9                	li	s9,18
    if(p->segs[seg_idx].perm & PTE_W) perm |= PTE_W;
    80001b9e:	8b91                	andi	a5,a5,4
    80001ba0:	c399                	beqz	a5,80001ba6 <vmfault+0x26c>
    80001ba2:	004cec93          	ori	s9,s9,4
    // If this was an execute fault but the segment isn't executable, it's invalid
    if(is_write == -1 && (perm & PTE_X) == 0){
    80001ba6:	57fd                	li	a5,-1
    80001ba8:	00fa1663          	bne	s4,a5,80001bb4 <vmfault+0x27a>
    80001bac:	008cf793          	andi	a5,s9,8
    80001bb0:	2c078363          	beqz	a5,80001e76 <vmfault+0x53c>
      kfree(mem);
      return 0;
    }
    if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
    80001bb4:	8b62                	mv	s6,s8
    80001bb6:	8766                	mv	a4,s9
    80001bb8:	86e2                	mv	a3,s8
    80001bba:	6605                	lui	a2,0x1
    80001bbc:	85a6                	mv	a1,s1
    80001bbe:	8556                	mv	a0,s5
    80001bc0:	cd0ff0ef          	jal	80001090 <mappages>
    80001bc4:	2c051363          	bnez	a0,80001e8a <vmfault+0x550>
    80001bc8:	12000073          	sfence.vma
      kfree(mem);
      return 0;
    }
    sfence_vma();
    // update pgmeta
    if(midx < 0) midx = pgmeta_alloc(p, va_pg);
    80001bcc:	2c0bc963          	bltz	s7,80001e9e <vmfault+0x564>
    if(midx >= 0){
      p->pgmeta[midx].resident = 1;
    80001bd0:	001b9913          	slli	s2,s7,0x1
    80001bd4:	017907b3          	add	a5,s2,s7
    80001bd8:	078e                	slli	a5,a5,0x3
    80001bda:	97ce                	add	a5,a5,s3
    80001bdc:	4705                	li	a4,1
    80001bde:	44e78423          	sb	a4,1096(a5)
      p->pgmeta[midx].perm = perm;
    80001be2:	45979723          	sh	s9,1102(a5)
      // mark clean until a write occurs
      p->pgmeta[midx].dirty = 0;
    80001be6:	440784a3          	sb	zero,1097(a5)
      p->pgmeta[midx].referenced = 1;
    80001bea:	44e78523          	sb	a4,1098(a5)
    }
    // Logging: LOADEXEC and RESIDENT per required format
  printf("[pid %d] LOADEXEC va=0x%lx\n", p->pid, va_pg);
    80001bee:	8626                	mv	a2,s1
    80001bf0:	0309a583          	lw	a1,48(s3)
    80001bf4:	00007517          	auipc	a0,0x7
    80001bf8:	82450513          	addi	a0,a0,-2012 # 80008418 <etext+0x418>
    80001bfc:	8fffe0ef          	jal	800004fa <printf>
  uint64 seq = p->page_seq_ctr++;
    80001c00:	3a09b683          	ld	a3,928(s3)
    80001c04:	00168793          	addi	a5,a3,1
    80001c08:	3af9b023          	sd	a5,928(s3)
    if(midx >= 0) p->pgmeta[midx].seq = seq;
    80001c0c:	017907b3          	add	a5,s2,s7
    80001c10:	078e                	slli	a5,a5,0x3
    80001c12:	97ce                	add	a5,a5,s3
    80001c14:	44d7b023          	sd	a3,1088(a5)
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    80001c18:	8626                	mv	a2,s1
    80001c1a:	0309a583          	lw	a1,48(s3)
    80001c1e:	00006517          	auipc	a0,0x6
    80001c22:	7d250513          	addi	a0,a0,2002 # 800083f0 <etext+0x3f0>
    80001c26:	8d5fe0ef          	jal	800004fa <printf>
    return (uint64)mem;
    80001c2a:	6906                	ld	s2,64(sp)
    80001c2c:	79e2                	ld	s3,56(sp)
    80001c2e:	6be2                	ld	s7,24(sp)
    80001c30:	6c42                	ld	s8,16(sp)
    80001c32:	6ca2                	ld	s9,8(sp)
    80001c34:	a099                	j	80001c7a <vmfault+0x340>
    cause_str = "heap";
    80001c36:	00006717          	auipc	a4,0x6
    80001c3a:	75270713          	addi	a4,a4,1874 # 80008388 <etext+0x388>
  } else if(is_heap){
    80001c3e:	000c1c63          	bnez	s8,80001c56 <vmfault+0x31c>
    cause_str = "exec"; // default, will be treated invalid later if truly invalid
    80001c42:	00006717          	auipc	a4,0x6
    80001c46:	72e70713          	addi	a4,a4,1838 # 80008370 <etext+0x370>
  } else if(is_stack){
    80001c4a:	000b0663          	beqz	s6,80001c56 <vmfault+0x31c>
    cause_str = "stack";
    80001c4e:	00006717          	auipc	a4,0x6
    80001c52:	73270713          	addi	a4,a4,1842 # 80008380 <etext+0x380>
  printf("[pid %d] PAGEFAULT va=0x%lx access=%s cause=%s\n", p->pid, va_pg, access_str, cause_str);
    80001c56:	8626                	mv	a2,s1
    80001c58:	0309a583          	lw	a1,48(s3)
    80001c5c:	00006517          	auipc	a0,0x6
    80001c60:	73c50513          	addi	a0,a0,1852 # 80008398 <etext+0x398>
    80001c64:	897fe0ef          	jal	800004fa <printf>
  } else if(is_heap || is_stack){
    80001c68:	018b6c33          	or	s8,s6,s8
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    return (uint64)mem;
  }

  // Invalid access
  return 0;
    80001c6c:	4b01                	li	s6,0
  } else if(is_heap || is_stack){
    80001c6e:	240c1f63          	bnez	s8,80001ecc <vmfault+0x592>
    80001c72:	6906                	ld	s2,64(sp)
    80001c74:	79e2                	ld	s3,56(sp)
    80001c76:	6be2                	ld	s7,24(sp)
    80001c78:	6c42                	ld	s8,16(sp)
}
    80001c7a:	855a                	mv	a0,s6
    80001c7c:	60e6                	ld	ra,88(sp)
    80001c7e:	6446                	ld	s0,80(sp)
    80001c80:	64a6                	ld	s1,72(sp)
    80001c82:	7a42                	ld	s4,48(sp)
    80001c84:	7aa2                	ld	s5,40(sp)
    80001c86:	7b02                	ld	s6,32(sp)
    80001c88:	6125                	addi	sp,sp,96
    80001c8a:	8082                	ret
  printf("[pid %d] PAGEFAULT va=0x%lx access=%s cause=%s\n", p->pid, va_pg, access_str, cause_str);
    80001c8c:	00006717          	auipc	a4,0x6
    80001c90:	70470713          	addi	a4,a4,1796 # 80008390 <etext+0x390>
    80001c94:	8626                	mv	a2,s1
    80001c96:	0309a583          	lw	a1,48(s3)
    80001c9a:	00006517          	auipc	a0,0x6
    80001c9e:	6fe50513          	addi	a0,a0,1790 # 80008398 <etext+0x398>
    80001ca2:	859fe0ef          	jal	800004fa <printf>
  if(seg_idx >= 0){
    80001ca6:	fc0941e3          	bltz	s2,80001c68 <vmfault+0x32e>
    if(p->execip == 0)
    80001caa:	1909b783          	ld	a5,400(s3)
    80001cae:	e80798e3          	bnez	a5,80001b3e <vmfault+0x204>
      return 0;
    80001cb2:	4b01                	li	s6,0
    80001cb4:	6906                	ld	s2,64(sp)
    80001cb6:	79e2                	ld	s3,56(sp)
    80001cb8:	6be2                	ld	s7,24(sp)
    80001cba:	6c42                	ld	s8,16(sp)
    80001cbc:	bf7d                	j	80001c7a <vmfault+0x340>
      char *mem = kalloc_or_evict(p);
    80001cbe:	854e                	mv	a0,s3
    80001cc0:	e6eff0ef          	jal	8000132e <kalloc_or_evict>
    80001cc4:	8a2a                	mv	s4,a0
        return 0;
    80001cc6:	4b01                	li	s6,0
      if(mem == 0){
    80001cc8:	32050a63          	beqz	a0,80001ffc <vmfault+0x6c2>
    80001ccc:	e466                	sd	s9,8(sp)
    80001cce:	e06a                	sd	s10,0(sp)
      ilock(p->swapip);
    80001cd0:	3a89b503          	ld	a0,936(s3)
    80001cd4:	0cb020ef          	jal	8000459e <ilock>
      int slot = p->pgmeta[midx].slot;
    80001cd8:	001b9793          	slli	a5,s7,0x1
    80001cdc:	97de                	add	a5,a5,s7
    80001cde:	078e                	slli	a5,a5,0x3
    80001ce0:	97ce                	add	a5,a5,s3
    80001ce2:	44c7dc03          	lhu	s8,1100(a5)
    80001ce6:	000c0c9b          	sext.w	s9,s8
      int r = readi(p->swapip, 0, (uint64)mem, slot*PGSIZE, PGSIZE);
    80001cea:	8b52                	mv	s6,s4
    80001cec:	6705                	lui	a4,0x1
    80001cee:	00cc1693          	slli	a3,s8,0xc
    80001cf2:	8652                	mv	a2,s4
    80001cf4:	4581                	li	a1,0
    80001cf6:	3a89b503          	ld	a0,936(s3)
    80001cfa:	435020ef          	jal	8000492e <readi>
    80001cfe:	8d2a                	mv	s10,a0
      iunlock(p->swapip);
    80001d00:	3a89b503          	ld	a0,936(s3)
    80001d04:	149020ef          	jal	8000464c <iunlock>
      if(r != PGSIZE){
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	04fd1663          	bne	s10,a5,80001d56 <vmfault+0x41c>
      int perm = (p->pgmeta[midx].perm ? p->pgmeta[midx].perm : (PTE_U|PTE_R| (p->segs[seg_idx].perm & PTE_X) | (p->segs[seg_idx].perm & PTE_W)));
    80001d0e:	001b9793          	slli	a5,s7,0x1
    80001d12:	97de                	add	a5,a5,s7
    80001d14:	078e                	slli	a5,a5,0x3
    80001d16:	97ce                	add	a5,a5,s3
    80001d18:	44e7d783          	lhu	a5,1102(a5) # 144e <_entry-0x7fffebb2>
    80001d1c:	0007871b          	sext.w	a4,a5
    80001d20:	eb89                	bnez	a5,80001d32 <vmfault+0x3f8>
    80001d22:	00591793          	slli	a5,s2,0x5
    80001d26:	97ce                	add	a5,a5,s3
    80001d28:	1bc7a783          	lw	a5,444(a5)
    80001d2c:	8bb1                	andi	a5,a5,12
    80001d2e:	0127e713          	ori	a4,a5,18
      if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
    80001d32:	86d2                	mv	a3,s4
    80001d34:	6605                	lui	a2,0x1
    80001d36:	85a6                	mv	a1,s1
    80001d38:	8556                	mv	a0,s5
    80001d3a:	b56ff0ef          	jal	80001090 <mappages>
    80001d3e:	c51d                	beqz	a0,80001d6c <vmfault+0x432>
        kfree(mem);
    80001d40:	8552                	mv	a0,s4
    80001d42:	cdbfe0ef          	jal	80000a1c <kfree>
        return 0;
    80001d46:	4b01                	li	s6,0
    80001d48:	6906                	ld	s2,64(sp)
    80001d4a:	79e2                	ld	s3,56(sp)
    80001d4c:	6be2                	ld	s7,24(sp)
    80001d4e:	6c42                	ld	s8,16(sp)
    80001d50:	6ca2                	ld	s9,8(sp)
    80001d52:	6d02                	ld	s10,0(sp)
    80001d54:	b71d                	j	80001c7a <vmfault+0x340>
        kfree(mem);
    80001d56:	8552                	mv	a0,s4
    80001d58:	cc5fe0ef          	jal	80000a1c <kfree>
        return 0;
    80001d5c:	4b01                	li	s6,0
    80001d5e:	6906                	ld	s2,64(sp)
    80001d60:	79e2                	ld	s3,56(sp)
    80001d62:	6be2                	ld	s7,24(sp)
    80001d64:	6c42                	ld	s8,16(sp)
    80001d66:	6ca2                	ld	s9,8(sp)
    80001d68:	6d02                	ld	s10,0(sp)
    80001d6a:	bf01                	j	80001c7a <vmfault+0x340>
    80001d6c:	12000073          	sfence.vma
      p->pgmeta[midx].resident = 1;
    80001d70:	001b9793          	slli	a5,s7,0x1
    80001d74:	97de                	add	a5,a5,s7
    80001d76:	078e                	slli	a5,a5,0x3
    80001d78:	97ce                	add	a5,a5,s3
    80001d7a:	4705                	li	a4,1
    80001d7c:	44e78423          	sb	a4,1096(a5)
      p->pgmeta[midx].in_swap = 0;
    80001d80:	440785a3          	sb	zero,1099(a5)
      p->pgmeta[midx].slot = 0xffff;
    80001d84:	577d                	li	a4,-1
    80001d86:	44e79623          	sh	a4,1100(a5)
  if(slot < 0 || slot >= 1024) return;
    80001d8a:	000c079b          	sext.w	a5,s8
    80001d8e:	3ff00713          	li	a4,1023
    80001d92:	02f76163          	bltu	a4,a5,80001db4 <vmfault+0x47a>
  int byte = slot >> 3;
    80001d96:	003cd713          	srli	a4,s9,0x3
  p->swap_bitmap[byte] &= ~(1<<bit);
    80001d9a:	974e                	add	a4,a4,s3
  int bit = slot & 7;
    80001d9c:	007c7c13          	andi	s8,s8,7
  p->swap_bitmap[byte] &= ~(1<<bit);
    80001da0:	4785                	li	a5,1
    80001da2:	018797bb          	sllw	a5,a5,s8
    80001da6:	fff7c793          	not	a5,a5
    80001daa:	3b474683          	lbu	a3,948(a4) # 13b4 <_entry-0x7fffec4c>
    80001dae:	8ff5                	and	a5,a5,a3
    80001db0:	3af70a23          	sb	a5,948(a4)
      if(p->swap_pages > 0) p->swap_pages--;
    80001db4:	3b09a783          	lw	a5,944(s3)
    80001db8:	00f05563          	blez	a5,80001dc2 <vmfault+0x488>
    80001dbc:	37fd                	addiw	a5,a5,-1
    80001dbe:	3af9a823          	sw	a5,944(s3)
      uint64 seq = p->page_seq_ctr++;
    80001dc2:	3a09b903          	ld	s2,928(s3)
    80001dc6:	00190793          	addi	a5,s2,1
    80001dca:	3af9b023          	sd	a5,928(s3)
      p->pgmeta[midx].seq = seq;
    80001dce:	001b9793          	slli	a5,s7,0x1
    80001dd2:	01778733          	add	a4,a5,s7
    80001dd6:	070e                	slli	a4,a4,0x3
    80001dd8:	974e                	add	a4,a4,s3
    80001dda:	45273023          	sd	s2,1088(a4)
      p->pgmeta[midx].referenced = 1;
    80001dde:	87ba                	mv	a5,a4
    80001de0:	4705                	li	a4,1
    80001de2:	44e78523          	sb	a4,1098(a5)
  printf("[pid %d] SWAPIN va=0x%lx slot=%d\n", p->pid, va_pg, slot);
    80001de6:	86e6                	mv	a3,s9
    80001de8:	8626                	mv	a2,s1
    80001dea:	0309a583          	lw	a1,48(s3)
    80001dee:	00006517          	auipc	a0,0x6
    80001df2:	5da50513          	addi	a0,a0,1498 # 800083c8 <etext+0x3c8>
    80001df6:	f04fe0ef          	jal	800004fa <printf>
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    80001dfa:	86ca                	mv	a3,s2
    80001dfc:	8626                	mv	a2,s1
    80001dfe:	0309a583          	lw	a1,48(s3)
    80001e02:	00006517          	auipc	a0,0x6
    80001e06:	5ee50513          	addi	a0,a0,1518 # 800083f0 <etext+0x3f0>
    80001e0a:	ef0fe0ef          	jal	800004fa <printf>
      return (uint64)mem;
    80001e0e:	6906                	ld	s2,64(sp)
    80001e10:	79e2                	ld	s3,56(sp)
    80001e12:	6be2                	ld	s7,24(sp)
    80001e14:	6c42                	ld	s8,16(sp)
    80001e16:	6ca2                	ld	s9,8(sp)
    80001e18:	6d02                	ld	s10,0(sp)
    80001e1a:	b585                	j	80001c7a <vmfault+0x340>
    80001e1c:	e06a                	sd	s10,0(sp)
      uint remain = p->segs[seg_idx].filesz - page_off;
    80001e1e:	416787bb          	subw	a5,a5,s6
      n = remain < PGSIZE ? remain : PGSIZE;
    80001e22:	0007869b          	sext.w	a3,a5
    80001e26:	6705                	lui	a4,0x1
    80001e28:	00d77363          	bgeu	a4,a3,80001e2e <vmfault+0x4f4>
    80001e2c:	6785                	lui	a5,0x1
    80001e2e:	00078d1b          	sext.w	s10,a5
      ilock(p->execip);
    80001e32:	1909b503          	ld	a0,400(s3)
    80001e36:	768020ef          	jal	8000459e <ilock>
      int r = readi(p->execip, 0, (uint64)mem, file_off, n);
    80001e3a:	876a                	mv	a4,s10
    80001e3c:	016c86bb          	addw	a3,s9,s6
    80001e40:	8662                	mv	a2,s8
    80001e42:	4581                	li	a1,0
    80001e44:	1909b503          	ld	a0,400(s3)
    80001e48:	2e7020ef          	jal	8000492e <readi>
    80001e4c:	8b2a                	mv	s6,a0
      iunlock(p->execip);
    80001e4e:	1909b503          	ld	a0,400(s3)
    80001e52:	7fa020ef          	jal	8000464c <iunlock>
      if(r != n){
    80001e56:	2b01                	sext.w	s6,s6
    80001e58:	01ab1463          	bne	s6,s10,80001e60 <vmfault+0x526>
    80001e5c:	6d02                	ld	s10,0(sp)
    80001e5e:	b335                	j	80001b8a <vmfault+0x250>
        kfree(mem);
    80001e60:	8562                	mv	a0,s8
    80001e62:	bbbfe0ef          	jal	80000a1c <kfree>
        return 0;
    80001e66:	4b01                	li	s6,0
    80001e68:	6906                	ld	s2,64(sp)
    80001e6a:	79e2                	ld	s3,56(sp)
    80001e6c:	6be2                	ld	s7,24(sp)
    80001e6e:	6c42                	ld	s8,16(sp)
    80001e70:	6ca2                	ld	s9,8(sp)
    80001e72:	6d02                	ld	s10,0(sp)
    80001e74:	b519                	j	80001c7a <vmfault+0x340>
      kfree(mem);
    80001e76:	8562                	mv	a0,s8
    80001e78:	ba5fe0ef          	jal	80000a1c <kfree>
      return 0;
    80001e7c:	4b01                	li	s6,0
    80001e7e:	6906                	ld	s2,64(sp)
    80001e80:	79e2                	ld	s3,56(sp)
    80001e82:	6be2                	ld	s7,24(sp)
    80001e84:	6c42                	ld	s8,16(sp)
    80001e86:	6ca2                	ld	s9,8(sp)
    80001e88:	bbcd                	j	80001c7a <vmfault+0x340>
      kfree(mem);
    80001e8a:	8562                	mv	a0,s8
    80001e8c:	b91fe0ef          	jal	80000a1c <kfree>
      return 0;
    80001e90:	4b01                	li	s6,0
    80001e92:	6906                	ld	s2,64(sp)
    80001e94:	79e2                	ld	s3,56(sp)
    80001e96:	6be2                	ld	s7,24(sp)
    80001e98:	6c42                	ld	s8,16(sp)
    80001e9a:	6ca2                	ld	s9,8(sp)
    80001e9c:	bbf9                	j	80001c7a <vmfault+0x340>
    if(midx < 0) midx = pgmeta_alloc(p, va_pg);
    80001e9e:	85a6                	mv	a1,s1
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	85eff0ef          	jal	80000f00 <pgmeta_alloc>
    80001ea6:	8baa                	mv	s7,a0
    if(midx >= 0){
    80001ea8:	d20554e3          	bgez	a0,80001bd0 <vmfault+0x296>
  printf("[pid %d] LOADEXEC va=0x%lx\n", p->pid, va_pg);
    80001eac:	8626                	mv	a2,s1
    80001eae:	0309a583          	lw	a1,48(s3)
    80001eb2:	00006517          	auipc	a0,0x6
    80001eb6:	56650513          	addi	a0,a0,1382 # 80008418 <etext+0x418>
    80001eba:	e40fe0ef          	jal	800004fa <printf>
  uint64 seq = p->page_seq_ctr++;
    80001ebe:	3a09b683          	ld	a3,928(s3)
    80001ec2:	00168793          	addi	a5,a3,1
    80001ec6:	3af9b023          	sd	a5,928(s3)
    if(midx >= 0) p->pgmeta[midx].seq = seq;
    80001eca:	b3b9                	j	80001c18 <vmfault+0x2de>
    int midx = pgmeta_alloc(p, va_pg);
    80001ecc:	85a6                	mv	a1,s1
    80001ece:	854e                	mv	a0,s3
    80001ed0:	830ff0ef          	jal	80000f00 <pgmeta_alloc>
    80001ed4:	8a2a                	mv	s4,a0
    char *mem = kalloc_or_evict(p);
    80001ed6:	854e                	mv	a0,s3
    80001ed8:	c56ff0ef          	jal	8000132e <kalloc_or_evict>
    80001edc:	892a                	mv	s2,a0
    if(mem == 0){
    80001ede:	12050963          	beqz	a0,80002010 <vmfault+0x6d6>
    memset(mem, 0, PGSIZE);
    80001ee2:	6605                	lui	a2,0x1
    80001ee4:	4581                	li	a1,0
    80001ee6:	dcbfe0ef          	jal	80000cb0 <memset>
    if(mappages(pagetable, va_pg, PGSIZE, (uint64)mem, perm) != 0){
    80001eea:	8b4a                	mv	s6,s2
    80001eec:	4749                	li	a4,18
    80001eee:	86ca                	mv	a3,s2
    80001ef0:	6605                	lui	a2,0x1
    80001ef2:	85a6                	mv	a1,s1
    80001ef4:	8556                	mv	a0,s5
    80001ef6:	99aff0ef          	jal	80001090 <mappages>
    80001efa:	e925                	bnez	a0,80001f6a <vmfault+0x630>
    80001efc:	12000073          	sfence.vma
    if(midx >= 0){
    80001f00:	0a0a4063          	bltz	s4,80001fa0 <vmfault+0x666>
      p->pgmeta[midx].resident = 1;
    80001f04:	001a1913          	slli	s2,s4,0x1
    80001f08:	014907b3          	add	a5,s2,s4
    80001f0c:	078e                	slli	a5,a5,0x3
    80001f0e:	97ce                	add	a5,a5,s3
    80001f10:	4705                	li	a4,1
    80001f12:	44e78423          	sb	a4,1096(a5) # 1448 <_entry-0x7fffebb8>
      p->pgmeta[midx].perm = perm;
    80001f16:	46c9                	li	a3,18
    80001f18:	44d79723          	sh	a3,1102(a5)
      p->pgmeta[midx].dirty = 0; // start clean; mark dirty on first write
    80001f1c:	440784a3          	sb	zero,1097(a5)
      p->pgmeta[midx].referenced = 1;
    80001f20:	44e78523          	sb	a4,1098(a5)
  printf("[pid %d] ALLOC va=0x%lx\n", p->pid, va_pg);
    80001f24:	8626                	mv	a2,s1
    80001f26:	0309a583          	lw	a1,48(s3)
    80001f2a:	00006517          	auipc	a0,0x6
    80001f2e:	50e50513          	addi	a0,a0,1294 # 80008438 <etext+0x438>
    80001f32:	dc8fe0ef          	jal	800004fa <printf>
  uint64 seq = p->page_seq_ctr++;
    80001f36:	3a09b683          	ld	a3,928(s3)
    80001f3a:	00168793          	addi	a5,a3,1
    80001f3e:	3af9b023          	sd	a5,928(s3)
    if(midx >= 0) p->pgmeta[midx].seq = seq;
    80001f42:	014907b3          	add	a5,s2,s4
    80001f46:	078e                	slli	a5,a5,0x3
    80001f48:	97ce                	add	a5,a5,s3
    80001f4a:	44d7b023          	sd	a3,1088(a5)
  printf("[pid %d] RESIDENT va=0x%lx seq=%lu\n", p->pid, va_pg, (unsigned long)seq);
    80001f4e:	8626                	mv	a2,s1
    80001f50:	0309a583          	lw	a1,48(s3)
    80001f54:	00006517          	auipc	a0,0x6
    80001f58:	49c50513          	addi	a0,a0,1180 # 800083f0 <etext+0x3f0>
    80001f5c:	d9efe0ef          	jal	800004fa <printf>
    return (uint64)mem;
    80001f60:	6906                	ld	s2,64(sp)
    80001f62:	79e2                	ld	s3,56(sp)
    80001f64:	6be2                	ld	s7,24(sp)
    80001f66:	6c42                	ld	s8,16(sp)
    80001f68:	bb09                	j	80001c7a <vmfault+0x340>
      kfree(mem);
    80001f6a:	854a                	mv	a0,s2
    80001f6c:	ab1fe0ef          	jal	80000a1c <kfree>
      return 0;
    80001f70:	4b01                	li	s6,0
    80001f72:	6906                	ld	s2,64(sp)
    80001f74:	79e2                	ld	s3,56(sp)
    80001f76:	6be2                	ld	s7,24(sp)
    80001f78:	6c42                	ld	s8,16(sp)
    80001f7a:	b301                	j	80001c7a <vmfault+0x340>
    return 0;
    80001f7c:	4b01                	li	s6,0
    80001f7e:	6906                	ld	s2,64(sp)
    80001f80:	79e2                	ld	s3,56(sp)
    80001f82:	6be2                	ld	s7,24(sp)
    80001f84:	6c42                	ld	s8,16(sp)
    80001f86:	b9d5                	j	80001c7a <vmfault+0x340>
    80001f88:	4b01                	li	s6,0
    80001f8a:	6906                	ld	s2,64(sp)
    80001f8c:	79e2                	ld	s3,56(sp)
    80001f8e:	6be2                	ld	s7,24(sp)
    80001f90:	6c42                	ld	s8,16(sp)
    80001f92:	b1e5                	j	80001c7a <vmfault+0x340>
      return 0;
    80001f94:	4b01                	li	s6,0
    80001f96:	6906                	ld	s2,64(sp)
    80001f98:	79e2                	ld	s3,56(sp)
    80001f9a:	6be2                	ld	s7,24(sp)
    80001f9c:	6c42                	ld	s8,16(sp)
    80001f9e:	b9f1                	j	80001c7a <vmfault+0x340>
  printf("[pid %d] ALLOC va=0x%lx\n", p->pid, va_pg);
    80001fa0:	8626                	mv	a2,s1
    80001fa2:	0309a583          	lw	a1,48(s3)
    80001fa6:	00006517          	auipc	a0,0x6
    80001faa:	49250513          	addi	a0,a0,1170 # 80008438 <etext+0x438>
    80001fae:	d4cfe0ef          	jal	800004fa <printf>
  uint64 seq = p->page_seq_ctr++;
    80001fb2:	3a09b683          	ld	a3,928(s3)
    80001fb6:	00168793          	addi	a5,a3,1
    80001fba:	3af9b023          	sd	a5,928(s3)
    if(midx >= 0) p->pgmeta[midx].seq = seq;
    80001fbe:	bf41                	j	80001f4e <vmfault+0x614>
  int is_heap = (va_pg >= prog_end && va_pg < p->heap_brk && va_pg < p->sz);
    80001fc0:	1889b783          	ld	a5,392(s3)
    80001fc4:	00f4ea63          	bltu	s1,a5,80001fd8 <vmfault+0x69e>
    80001fc8:	4c01                	li	s8,0
  int seg_idx = -1;
    80001fca:	597d                	li	s2,-1
    80001fcc:	bc11                	j	800019e0 <vmfault+0xa6>
  int is_heap = (va_pg >= prog_end && va_pg < p->heap_brk && va_pg < p->sz);
    80001fce:	1889b783          	ld	a5,392(s3)
    80001fd2:	4c01                	li	s8,0
    80001fd4:	9ef4f4e3          	bgeu	s1,a5,800019bc <vmfault+0x82>
    80001fd8:	0489bc03          	ld	s8,72(s3)
    80001fdc:	0184bc33          	sltu	s8,s1,s8
  for(int i = 0; i < p->nsegs; i++){
    80001fe0:	9cc04ee3          	bgtz	a2,800019bc <vmfault+0x82>
  int seg_idx = -1;
    80001fe4:	597d                	li	s2,-1
    80001fe6:	baed                	j	800019e0 <vmfault+0xa6>
    80001fe8:	6906                	ld	s2,64(sp)
    80001fea:	79e2                	ld	s3,56(sp)
    80001fec:	6be2                	ld	s7,24(sp)
    80001fee:	6c42                	ld	s8,16(sp)
    80001ff0:	b169                	j	80001c7a <vmfault+0x340>
    80001ff2:	6906                	ld	s2,64(sp)
    80001ff4:	79e2                	ld	s3,56(sp)
    80001ff6:	6be2                	ld	s7,24(sp)
    80001ff8:	6c42                	ld	s8,16(sp)
    80001ffa:	b141                	j	80001c7a <vmfault+0x340>
    80001ffc:	6906                	ld	s2,64(sp)
    80001ffe:	79e2                	ld	s3,56(sp)
    80002000:	6be2                	ld	s7,24(sp)
    80002002:	6c42                	ld	s8,16(sp)
    80002004:	b99d                	j	80001c7a <vmfault+0x340>
    80002006:	6906                	ld	s2,64(sp)
    80002008:	79e2                	ld	s3,56(sp)
    8000200a:	6be2                	ld	s7,24(sp)
    8000200c:	6c42                	ld	s8,16(sp)
    8000200e:	b1b5                	j	80001c7a <vmfault+0x340>
    80002010:	6906                	ld	s2,64(sp)
    80002012:	79e2                	ld	s3,56(sp)
    80002014:	6be2                	ld	s7,24(sp)
    80002016:	6c42                	ld	s8,16(sp)
    80002018:	b18d                	j	80001c7a <vmfault+0x340>

000000008000201a <copyout>:
  while(len > 0){
    8000201a:	c6cd                	beqz	a3,800020c4 <copyout+0xaa>
{
    8000201c:	711d                	addi	sp,sp,-96
    8000201e:	ec86                	sd	ra,88(sp)
    80002020:	e8a2                	sd	s0,80(sp)
    80002022:	e4a6                	sd	s1,72(sp)
    80002024:	f852                	sd	s4,48(sp)
    80002026:	f05a                	sd	s6,32(sp)
    80002028:	ec5e                	sd	s7,24(sp)
    8000202a:	e862                	sd	s8,16(sp)
    8000202c:	1080                	addi	s0,sp,96
    8000202e:	8b2a                	mv	s6,a0
    80002030:	8bae                	mv	s7,a1
    80002032:	8c32                	mv	s8,a2
    80002034:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80002036:	74fd                	lui	s1,0xfffff
    80002038:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    8000203a:	57fd                	li	a5,-1
    8000203c:	83e9                	srli	a5,a5,0x1a
    8000203e:	0897e563          	bltu	a5,s1,800020c8 <copyout+0xae>
    80002042:	e0ca                	sd	s2,64(sp)
    80002044:	fc4e                	sd	s3,56(sp)
    80002046:	f456                	sd	s5,40(sp)
    80002048:	e466                	sd	s9,8(sp)
    8000204a:	e06a                	sd	s10,0(sp)
    8000204c:	6d05                	lui	s10,0x1
    8000204e:	8cbe                	mv	s9,a5
    80002050:	a015                	j	80002074 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80002052:	409b8533          	sub	a0,s7,s1
    80002056:	0009861b          	sext.w	a2,s3
    8000205a:	85e2                	mv	a1,s8
    8000205c:	954a                	add	a0,a0,s2
    8000205e:	caffe0ef          	jal	80000d0c <memmove>
    len -= n;
    80002062:	413a0a33          	sub	s4,s4,s3
    src += n;
    80002066:	9c4e                	add	s8,s8,s3
  while(len > 0){
    80002068:	040a0763          	beqz	s4,800020b6 <copyout+0x9c>
    if(va0 >= MAXVA)
    8000206c:	075ce063          	bltu	s9,s5,800020cc <copyout+0xb2>
    80002070:	84d6                	mv	s1,s5
    80002072:	8bd6                	mv	s7,s5
    pa0 = walkaddr(pagetable, va0);
    80002074:	85a6                	mv	a1,s1
    80002076:	855a                	mv	a0,s6
    80002078:	fdbfe0ef          	jal	80001052 <walkaddr>
    8000207c:	892a                	mv	s2,a0
    if(pa0 == 0){
    8000207e:	ed01                	bnez	a0,80002096 <copyout+0x7c>
      vmfault(pagetable, va0, 1);
    80002080:	4605                	li	a2,1
    80002082:	85a6                	mv	a1,s1
    80002084:	855a                	mv	a0,s6
    80002086:	8b5ff0ef          	jal	8000193a <vmfault>
      pa0 = walkaddr(pagetable, va0);
    8000208a:	85a6                	mv	a1,s1
    8000208c:	855a                	mv	a0,s6
    8000208e:	fc5fe0ef          	jal	80001052 <walkaddr>
    80002092:	892a                	mv	s2,a0
      if(pa0 == 0)
    80002094:	c139                	beqz	a0,800020da <copyout+0xc0>
    pte = walk(pagetable, va0, 0);
    80002096:	4601                	li	a2,0
    80002098:	85a6                	mv	a1,s1
    8000209a:	855a                	mv	a0,s6
    8000209c:	efffe0ef          	jal	80000f9a <walk>
    if((*pte & PTE_W) == 0)
    800020a0:	611c                	ld	a5,0(a0)
    800020a2:	8b91                	andi	a5,a5,4
    800020a4:	c3b1                	beqz	a5,800020e8 <copyout+0xce>
    n = PGSIZE - (dstva - va0);
    800020a6:	01a48ab3          	add	s5,s1,s10
    800020aa:	417a89b3          	sub	s3,s5,s7
    if(n > len)
    800020ae:	fb3a72e3          	bgeu	s4,s3,80002052 <copyout+0x38>
    800020b2:	89d2                	mv	s3,s4
    800020b4:	bf79                	j	80002052 <copyout+0x38>
  return 0;
    800020b6:	4501                	li	a0,0
    800020b8:	6906                	ld	s2,64(sp)
    800020ba:	79e2                	ld	s3,56(sp)
    800020bc:	7aa2                	ld	s5,40(sp)
    800020be:	6ca2                	ld	s9,8(sp)
    800020c0:	6d02                	ld	s10,0(sp)
    800020c2:	a80d                	j	800020f4 <copyout+0xda>
    800020c4:	4501                	li	a0,0
}
    800020c6:	8082                	ret
      return -1;
    800020c8:	557d                	li	a0,-1
    800020ca:	a02d                	j	800020f4 <copyout+0xda>
    800020cc:	557d                	li	a0,-1
    800020ce:	6906                	ld	s2,64(sp)
    800020d0:	79e2                	ld	s3,56(sp)
    800020d2:	7aa2                	ld	s5,40(sp)
    800020d4:	6ca2                	ld	s9,8(sp)
    800020d6:	6d02                	ld	s10,0(sp)
    800020d8:	a831                	j	800020f4 <copyout+0xda>
        return -1;
    800020da:	557d                	li	a0,-1
    800020dc:	6906                	ld	s2,64(sp)
    800020de:	79e2                	ld	s3,56(sp)
    800020e0:	7aa2                	ld	s5,40(sp)
    800020e2:	6ca2                	ld	s9,8(sp)
    800020e4:	6d02                	ld	s10,0(sp)
    800020e6:	a039                	j	800020f4 <copyout+0xda>
      return -1;
    800020e8:	557d                	li	a0,-1
    800020ea:	6906                	ld	s2,64(sp)
    800020ec:	79e2                	ld	s3,56(sp)
    800020ee:	7aa2                	ld	s5,40(sp)
    800020f0:	6ca2                	ld	s9,8(sp)
    800020f2:	6d02                	ld	s10,0(sp)
}
    800020f4:	60e6                	ld	ra,88(sp)
    800020f6:	6446                	ld	s0,80(sp)
    800020f8:	64a6                	ld	s1,72(sp)
    800020fa:	7a42                	ld	s4,48(sp)
    800020fc:	7b02                	ld	s6,32(sp)
    800020fe:	6be2                	ld	s7,24(sp)
    80002100:	6c42                	ld	s8,16(sp)
    80002102:	6125                	addi	sp,sp,96
    80002104:	8082                	ret

0000000080002106 <copyin>:
  while(len > 0){
    80002106:	cac9                	beqz	a3,80002198 <copyin+0x92>
{
    80002108:	715d                	addi	sp,sp,-80
    8000210a:	e486                	sd	ra,72(sp)
    8000210c:	e0a2                	sd	s0,64(sp)
    8000210e:	fc26                	sd	s1,56(sp)
    80002110:	f84a                	sd	s2,48(sp)
    80002112:	f44e                	sd	s3,40(sp)
    80002114:	f052                	sd	s4,32(sp)
    80002116:	ec56                	sd	s5,24(sp)
    80002118:	e85a                	sd	s6,16(sp)
    8000211a:	e45e                	sd	s7,8(sp)
    8000211c:	e062                	sd	s8,0(sp)
    8000211e:	0880                	addi	s0,sp,80
    80002120:	8b2a                	mv	s6,a0
    80002122:	8aae                	mv	s5,a1
    80002124:	8932                	mv	s2,a2
    80002126:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80002128:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    8000212a:	6b85                	lui	s7,0x1
    8000212c:	a035                	j	80002158 <copyin+0x52>
    8000212e:	412984b3          	sub	s1,s3,s2
    80002132:	94de                	add	s1,s1,s7
    if(n > len)
    80002134:	009a7363          	bgeu	s4,s1,8000213a <copyin+0x34>
    80002138:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000213a:	413905b3          	sub	a1,s2,s3
    8000213e:	0004861b          	sext.w	a2,s1
    80002142:	95aa                	add	a1,a1,a0
    80002144:	8556                	mv	a0,s5
    80002146:	bc7fe0ef          	jal	80000d0c <memmove>
    len -= n;
    8000214a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000214e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80002150:	01798933          	add	s2,s3,s7
  while(len > 0){
    80002154:	020a0563          	beqz	s4,8000217e <copyin+0x78>
    va0 = PGROUNDDOWN(srcva);
    80002158:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000215c:	85ce                	mv	a1,s3
    8000215e:	855a                	mv	a0,s6
    80002160:	ef3fe0ef          	jal	80001052 <walkaddr>
    if(pa0 == 0){
    80002164:	f569                	bnez	a0,8000212e <copyin+0x28>
      vmfault(pagetable, va0, 0);
    80002166:	4601                	li	a2,0
    80002168:	85ce                	mv	a1,s3
    8000216a:	855a                	mv	a0,s6
    8000216c:	fceff0ef          	jal	8000193a <vmfault>
      pa0 = walkaddr(pagetable, va0);
    80002170:	85ce                	mv	a1,s3
    80002172:	855a                	mv	a0,s6
    80002174:	edffe0ef          	jal	80001052 <walkaddr>
      if(pa0 == 0)
    80002178:	f95d                	bnez	a0,8000212e <copyin+0x28>
        return -1;
    8000217a:	557d                	li	a0,-1
    8000217c:	a011                	j	80002180 <copyin+0x7a>
  return 0;
    8000217e:	4501                	li	a0,0
}
    80002180:	60a6                	ld	ra,72(sp)
    80002182:	6406                	ld	s0,64(sp)
    80002184:	74e2                	ld	s1,56(sp)
    80002186:	7942                	ld	s2,48(sp)
    80002188:	79a2                	ld	s3,40(sp)
    8000218a:	7a02                	ld	s4,32(sp)
    8000218c:	6ae2                	ld	s5,24(sp)
    8000218e:	6b42                	ld	s6,16(sp)
    80002190:	6ba2                	ld	s7,8(sp)
    80002192:	6c02                	ld	s8,0(sp)
    80002194:	6161                	addi	sp,sp,80
    80002196:	8082                	ret
  return 0;
    80002198:	4501                	li	a0,0
}
    8000219a:	8082                	ret

000000008000219c <copyinstr>:
  while(got_null == 0 && max > 0){
    8000219c:	c2f1                	beqz	a3,80002260 <copyinstr+0xc4>
{
    8000219e:	715d                	addi	sp,sp,-80
    800021a0:	e486                	sd	ra,72(sp)
    800021a2:	e0a2                	sd	s0,64(sp)
    800021a4:	fc26                	sd	s1,56(sp)
    800021a6:	f84a                	sd	s2,48(sp)
    800021a8:	f44e                	sd	s3,40(sp)
    800021aa:	f052                	sd	s4,32(sp)
    800021ac:	ec56                	sd	s5,24(sp)
    800021ae:	e85a                	sd	s6,16(sp)
    800021b0:	e45e                	sd	s7,8(sp)
    800021b2:	0880                	addi	s0,sp,80
    800021b4:	8a2a                	mv	s4,a0
    800021b6:	8bae                	mv	s7,a1
    800021b8:	8b32                	mv	s6,a2
    800021ba:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800021bc:	7afd                	lui	s5,0xfffff
    n = PGSIZE - (srcva - va0);
    800021be:	6985                	lui	s3,0x1
    800021c0:	a881                	j	80002210 <copyinstr+0x74>
      vmfault(pagetable, va0, 0);
    800021c2:	4601                	li	a2,0
    800021c4:	85a6                	mv	a1,s1
    800021c6:	8552                	mv	a0,s4
    800021c8:	f72ff0ef          	jal	8000193a <vmfault>
      pa0 = walkaddr(pagetable, va0);
    800021cc:	85a6                	mv	a1,s1
    800021ce:	8552                	mv	a0,s4
    800021d0:	e83fe0ef          	jal	80001052 <walkaddr>
      if(pa0 == 0)
    800021d4:	e529                	bnez	a0,8000221e <copyinstr+0x82>
        return -1;
    800021d6:	557d                	li	a0,-1
    800021d8:	a039                	j	800021e6 <copyinstr+0x4a>
        *dst = '\0';
    800021da:	00078023          	sb	zero,0(a5)
    800021de:	4785                	li	a5,1
  if(got_null){
    800021e0:	37fd                	addiw	a5,a5,-1
    800021e2:	0007851b          	sext.w	a0,a5
}
    800021e6:	60a6                	ld	ra,72(sp)
    800021e8:	6406                	ld	s0,64(sp)
    800021ea:	74e2                	ld	s1,56(sp)
    800021ec:	7942                	ld	s2,48(sp)
    800021ee:	79a2                	ld	s3,40(sp)
    800021f0:	7a02                	ld	s4,32(sp)
    800021f2:	6ae2                	ld	s5,24(sp)
    800021f4:	6b42                	ld	s6,16(sp)
    800021f6:	6ba2                	ld	s7,8(sp)
    800021f8:	6161                	addi	sp,sp,80
    800021fa:	8082                	ret
    800021fc:	fff90713          	addi	a4,s2,-1
    80002200:	972a                	add	a4,a4,a0
      --max;
    80002202:	40c70933          	sub	s2,a4,a2
    srcva = va0 + PGSIZE;
    80002206:	01348b33          	add	s6,s1,s3
  while(got_null == 0 && max > 0){
    8000220a:	04e60563          	beq	a2,a4,80002254 <copyinstr+0xb8>
{
    8000220e:	8bbe                	mv	s7,a5
    va0 = PGROUNDDOWN(srcva);
    80002210:	015b74b3          	and	s1,s6,s5
    pa0 = walkaddr(pagetable, va0);
    80002214:	85a6                	mv	a1,s1
    80002216:	8552                	mv	a0,s4
    80002218:	e3bfe0ef          	jal	80001052 <walkaddr>
    if(pa0 == 0){
    8000221c:	d15d                	beqz	a0,800021c2 <copyinstr+0x26>
    n = PGSIZE - (srcva - va0);
    8000221e:	416485b3          	sub	a1,s1,s6
    80002222:	95ce                	add	a1,a1,s3
    if(n > max)
    80002224:	00b97363          	bgeu	s2,a1,8000222a <copyinstr+0x8e>
    80002228:	85ca                	mv	a1,s2
    char *p = (char *) (pa0 + (srcva - va0));
    8000222a:	409b0b33          	sub	s6,s6,s1
    8000222e:	9b2a                	add	s6,s6,a0
    while(n > 0){
    80002230:	c585                	beqz	a1,80002258 <copyinstr+0xbc>
    80002232:	87de                	mv	a5,s7
    80002234:	855e                	mv	a0,s7
      if(*p == '\0'){
    80002236:	417b06b3          	sub	a3,s6,s7
    while(n > 0){
    8000223a:	95de                	add	a1,a1,s7
    8000223c:	863e                	mv	a2,a5
      if(*p == '\0'){
    8000223e:	00f68733          	add	a4,a3,a5
    80002242:	00074703          	lbu	a4,0(a4) # 1000 <_entry-0x7ffff000>
    80002246:	db51                	beqz	a4,800021da <copyinstr+0x3e>
        *dst = *p;
    80002248:	00e78023          	sb	a4,0(a5)
      dst++;
    8000224c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000224e:	feb797e3          	bne	a5,a1,8000223c <copyinstr+0xa0>
    80002252:	b76d                	j	800021fc <copyinstr+0x60>
    80002254:	4781                	li	a5,0
    80002256:	b769                	j	800021e0 <copyinstr+0x44>
    srcva = va0 + PGSIZE;
    80002258:	6b05                	lui	s6,0x1
    8000225a:	9b26                	add	s6,s6,s1
    8000225c:	87de                	mv	a5,s7
    8000225e:	bf45                	j	8000220e <copyinstr+0x72>
  int got_null = 0;
    80002260:	4781                	li	a5,0
  if(got_null){
    80002262:	37fd                	addiw	a5,a5,-1
    80002264:	0007851b          	sext.w	a0,a5
}
    80002268:	8082                	ret

000000008000226a <ismapped>:

int
ismapped(pagetable_t pagetable, uint64 va)
{
    8000226a:	1141                	addi	sp,sp,-16
    8000226c:	e406                	sd	ra,8(sp)
    8000226e:	e022                	sd	s0,0(sp)
    80002270:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80002272:	4601                	li	a2,0
    80002274:	d27fe0ef          	jal	80000f9a <walk>
  if (pte == 0) {
    80002278:	c519                	beqz	a0,80002286 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    8000227a:	6108                	ld	a0,0(a0)
    8000227c:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000227e:	60a2                	ld	ra,8(sp)
    80002280:	6402                	ld	s0,0(sp)
    80002282:	0141                	addi	sp,sp,16
    80002284:	8082                	ret
    return 0;
    80002286:	4501                	li	a0,0
    80002288:	bfdd                	j	8000227e <ismapped+0x14>

000000008000228a <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000228a:	715d                	addi	sp,sp,-80
    8000228c:	e486                	sd	ra,72(sp)
    8000228e:	e0a2                	sd	s0,64(sp)
    80002290:	fc26                	sd	s1,56(sp)
    80002292:	f84a                	sd	s2,48(sp)
    80002294:	f44e                	sd	s3,40(sp)
    80002296:	f052                	sd	s4,32(sp)
    80002298:	ec56                	sd	s5,24(sp)
    8000229a:	e85a                	sd	s6,16(sp)
    8000229c:	e45e                	sd	s7,8(sp)
    8000229e:	0880                	addi	s0,sp,80
    800022a0:	8aaa                	mv	s5,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800022a2:	00012497          	auipc	s1,0x12
    800022a6:	c8e48493          	addi	s1,s1,-882 # 80013f30 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800022aa:	8ba6                	mv	s7,s1
    800022ac:	002cb937          	lui	s2,0x2cb
    800022b0:	03390913          	addi	s2,s2,51 # 2cb033 <_entry-0x7fd34fcd>
    800022b4:	093a                	slli	s2,s2,0xe
    800022b6:	4a190913          	addi	s2,s2,1185
    800022ba:	0936                	slli	s2,s2,0xd
    800022bc:	c1790913          	addi	s2,s2,-1001
    800022c0:	0936                	slli	s2,s2,0xd
    800022c2:	f7190913          	addi	s2,s2,-143
    800022c6:	040009b7          	lui	s3,0x4000
    800022ca:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800022cc:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ce:	6a19                	lui	s4,0x6
    800022d0:	440a0a13          	addi	s4,s4,1088 # 6440 <_entry-0x7fff9bc0>
    800022d4:	001a3b17          	auipc	s6,0x1a3
    800022d8:	c5cb0b13          	addi	s6,s6,-932 # 801a4f30 <tickslock>
    char *pa = kalloc();
    800022dc:	823fe0ef          	jal	80000afe <kalloc>
    800022e0:	862a                	mv	a2,a0
    if(pa == 0)
    800022e2:	cd15                	beqz	a0,8000231e <proc_mapstacks+0x94>
    uint64 va = KSTACK((int) (p - proc));
    800022e4:	417485b3          	sub	a1,s1,s7
    800022e8:	8599                	srai	a1,a1,0x6
    800022ea:	032585b3          	mul	a1,a1,s2
    800022ee:	2585                	addiw	a1,a1,1
    800022f0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800022f4:	4719                	li	a4,6
    800022f6:	6685                	lui	a3,0x1
    800022f8:	40b985b3          	sub	a1,s3,a1
    800022fc:	8556                	mv	a0,s5
    800022fe:	e8bfe0ef          	jal	80001188 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002302:	94d2                	add	s1,s1,s4
    80002304:	fd649ce3          	bne	s1,s6,800022dc <proc_mapstacks+0x52>
  }
}
    80002308:	60a6                	ld	ra,72(sp)
    8000230a:	6406                	ld	s0,64(sp)
    8000230c:	74e2                	ld	s1,56(sp)
    8000230e:	7942                	ld	s2,48(sp)
    80002310:	79a2                	ld	s3,40(sp)
    80002312:	7a02                	ld	s4,32(sp)
    80002314:	6ae2                	ld	s5,24(sp)
    80002316:	6b42                	ld	s6,16(sp)
    80002318:	6ba2                	ld	s7,8(sp)
    8000231a:	6161                	addi	sp,sp,80
    8000231c:	8082                	ret
      panic("kalloc");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	13a50513          	addi	a0,a0,314 # 80008458 <etext+0x458>
    80002326:	cbafe0ef          	jal	800007e0 <panic>

000000008000232a <procinit>:

// initialize the proc table.
void
procinit(void)
{
    8000232a:	715d                	addi	sp,sp,-80
    8000232c:	e486                	sd	ra,72(sp)
    8000232e:	e0a2                	sd	s0,64(sp)
    80002330:	fc26                	sd	s1,56(sp)
    80002332:	f84a                	sd	s2,48(sp)
    80002334:	f44e                	sd	s3,40(sp)
    80002336:	f052                	sd	s4,32(sp)
    80002338:	ec56                	sd	s5,24(sp)
    8000233a:	e85a                	sd	s6,16(sp)
    8000233c:	e45e                	sd	s7,8(sp)
    8000233e:	0880                	addi	s0,sp,80
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80002340:	00006597          	auipc	a1,0x6
    80002344:	12058593          	addi	a1,a1,288 # 80008460 <etext+0x460>
    80002348:	00011517          	auipc	a0,0x11
    8000234c:	7a050513          	addi	a0,a0,1952 # 80013ae8 <pid_lock>
    80002350:	ffefe0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80002354:	00006597          	auipc	a1,0x6
    80002358:	11458593          	addi	a1,a1,276 # 80008468 <etext+0x468>
    8000235c:	00011517          	auipc	a0,0x11
    80002360:	7a450513          	addi	a0,a0,1956 # 80013b00 <wait_lock>
    80002364:	feafe0ef          	jal	80000b4e <initlock>
  initlock(&creation_time_lock, "creation_time");   // ADDED
    80002368:	00006597          	auipc	a1,0x6
    8000236c:	11058593          	addi	a1,a1,272 # 80008478 <etext+0x478>
    80002370:	00011517          	auipc	a0,0x11
    80002374:	7a850513          	addi	a0,a0,1960 # 80013b18 <creation_time_lock>
    80002378:	fd6fe0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000237c:	00012497          	auipc	s1,0x12
    80002380:	bb448493          	addi	s1,s1,-1100 # 80013f30 <proc>
      initlock(&p->lock, "proc");
    80002384:	00006b97          	auipc	s7,0x6
    80002388:	104b8b93          	addi	s7,s7,260 # 80008488 <etext+0x488>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000238c:	8b26                	mv	s6,s1
    8000238e:	002cb937          	lui	s2,0x2cb
    80002392:	03390913          	addi	s2,s2,51 # 2cb033 <_entry-0x7fd34fcd>
    80002396:	093a                	slli	s2,s2,0xe
    80002398:	4a190913          	addi	s2,s2,1185
    8000239c:	0936                	slli	s2,s2,0xd
    8000239e:	c1790913          	addi	s2,s2,-1001
    800023a2:	0936                	slli	s2,s2,0xd
    800023a4:	f7190913          	addi	s2,s2,-143
    800023a8:	040009b7          	lui	s3,0x4000
    800023ac:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800023ae:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b0:	6a19                	lui	s4,0x6
    800023b2:	440a0a13          	addi	s4,s4,1088 # 6440 <_entry-0x7fff9bc0>
    800023b6:	001a3a97          	auipc	s5,0x1a3
    800023ba:	b7aa8a93          	addi	s5,s5,-1158 # 801a4f30 <tickslock>
      initlock(&p->lock, "proc");
    800023be:	85de                	mv	a1,s7
    800023c0:	8526                	mv	a0,s1
    800023c2:	f8cfe0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    800023c6:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800023ca:	416487b3          	sub	a5,s1,s6
    800023ce:	8799                	srai	a5,a5,0x6
    800023d0:	032787b3          	mul	a5,a5,s2
    800023d4:	2785                	addiw	a5,a5,1
    800023d6:	00d7979b          	slliw	a5,a5,0xd
    800023da:	40f987b3          	sub	a5,s3,a5
    800023de:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e0:	94d2                	add	s1,s1,s4
    800023e2:	fd549ee3          	bne	s1,s5,800023be <procinit+0x94>
  }
}
    800023e6:	60a6                	ld	ra,72(sp)
    800023e8:	6406                	ld	s0,64(sp)
    800023ea:	74e2                	ld	s1,56(sp)
    800023ec:	7942                	ld	s2,48(sp)
    800023ee:	79a2                	ld	s3,40(sp)
    800023f0:	7a02                	ld	s4,32(sp)
    800023f2:	6ae2                	ld	s5,24(sp)
    800023f4:	6b42                	ld	s6,16(sp)
    800023f6:	6ba2                	ld	s7,8(sp)
    800023f8:	6161                	addi	sp,sp,80
    800023fa:	8082                	ret

00000000800023fc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800023fc:	1141                	addi	sp,sp,-16
    800023fe:	e422                	sd	s0,8(sp)
    80002400:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80002402:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80002404:	2501                	sext.w	a0,a0
    80002406:	6422                	ld	s0,8(sp)
    80002408:	0141                	addi	sp,sp,16
    8000240a:	8082                	ret

000000008000240c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000240c:	1141                	addi	sp,sp,-16
    8000240e:	e422                	sd	s0,8(sp)
    80002410:	0800                	addi	s0,sp,16
    80002412:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80002414:	2781                	sext.w	a5,a5
    80002416:	079e                	slli	a5,a5,0x7
  return c;
}
    80002418:	00011517          	auipc	a0,0x11
    8000241c:	71850513          	addi	a0,a0,1816 # 80013b30 <cpus>
    80002420:	953e                	add	a0,a0,a5
    80002422:	6422                	ld	s0,8(sp)
    80002424:	0141                	addi	sp,sp,16
    80002426:	8082                	ret

0000000080002428 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80002428:	1101                	addi	sp,sp,-32
    8000242a:	ec06                	sd	ra,24(sp)
    8000242c:	e822                	sd	s0,16(sp)
    8000242e:	e426                	sd	s1,8(sp)
    80002430:	1000                	addi	s0,sp,32
  push_off();
    80002432:	f5cfe0ef          	jal	80000b8e <push_off>
    80002436:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002438:	2781                	sext.w	a5,a5
    8000243a:	079e                	slli	a5,a5,0x7
    8000243c:	00011717          	auipc	a4,0x11
    80002440:	6ac70713          	addi	a4,a4,1708 # 80013ae8 <pid_lock>
    80002444:	97ba                	add	a5,a5,a4
    80002446:	67a4                	ld	s1,72(a5)
  pop_off();
    80002448:	fd8fe0ef          	jal	80000c20 <pop_off>
  return p;
}
    8000244c:	8526                	mv	a0,s1
    8000244e:	60e2                	ld	ra,24(sp)
    80002450:	6442                	ld	s0,16(sp)
    80002452:	64a2                	ld	s1,8(sp)
    80002454:	6105                	addi	sp,sp,32
    80002456:	8082                	ret

0000000080002458 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80002462:	fc7ff0ef          	jal	80002428 <myproc>
    80002466:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80002468:	80dfe0ef          	jal	80000c74 <release>

  if (first) {
    8000246c:	00009797          	auipc	a5,0x9
    80002470:	5047a783          	lw	a5,1284(a5) # 8000b970 <first.1>
    80002474:	cf8d                	beqz	a5,800024ae <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80002476:	4505                	li	a0,1
    80002478:	41a020ef          	jal	80004892 <fsinit>

    first = 0;
    8000247c:	00009797          	auipc	a5,0x9
    80002480:	4e07aa23          	sw	zero,1268(a5) # 8000b970 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80002484:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	00850513          	addi	a0,a0,8 # 80008490 <etext+0x490>
    80002490:	fca43823          	sd	a0,-48(s0)
    80002494:	fc043c23          	sd	zero,-40(s0)
    80002498:	fd040593          	addi	a1,s0,-48
    8000249c:	4f6030ef          	jal	80005992 <kexec>
    800024a0:	6cbc                	ld	a5,88(s1)
    800024a2:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    800024a4:	6cbc                	ld	a5,88(s1)
    800024a6:	7bb8                	ld	a4,112(a5)
    800024a8:	57fd                	li	a5,-1
    800024aa:	02f70d63          	beq	a4,a5,800024e4 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    800024ae:	7b3000ef          	jal	80003460 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800024b2:	68a8                	ld	a0,80(s1)
    800024b4:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800024b6:	04000737          	lui	a4,0x4000
    800024ba:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800024bc:	0732                	slli	a4,a4,0xc
    800024be:	00005797          	auipc	a5,0x5
    800024c2:	bde78793          	addi	a5,a5,-1058 # 8000709c <userret>
    800024c6:	00005697          	auipc	a3,0x5
    800024ca:	b3a68693          	addi	a3,a3,-1222 # 80007000 <_trampoline>
    800024ce:	8f95                	sub	a5,a5,a3
    800024d0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800024d2:	577d                	li	a4,-1
    800024d4:	177e                	slli	a4,a4,0x3f
    800024d6:	8d59                	or	a0,a0,a4
    800024d8:	9782                	jalr	a5
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
      panic("exec");
    800024e4:	00006517          	auipc	a0,0x6
    800024e8:	e8c50513          	addi	a0,a0,-372 # 80008370 <etext+0x370>
    800024ec:	af4fe0ef          	jal	800007e0 <panic>

00000000800024f0 <allocpid>:
{
    800024f0:	1101                	addi	sp,sp,-32
    800024f2:	ec06                	sd	ra,24(sp)
    800024f4:	e822                	sd	s0,16(sp)
    800024f6:	e426                	sd	s1,8(sp)
    800024f8:	e04a                	sd	s2,0(sp)
    800024fa:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800024fc:	00011917          	auipc	s2,0x11
    80002500:	5ec90913          	addi	s2,s2,1516 # 80013ae8 <pid_lock>
    80002504:	854a                	mv	a0,s2
    80002506:	ec8fe0ef          	jal	80000bce <acquire>
  pid = nextpid;
    8000250a:	00009797          	auipc	a5,0x9
    8000250e:	47678793          	addi	a5,a5,1142 # 8000b980 <nextpid>
    80002512:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80002514:	0014871b          	addiw	a4,s1,1
    80002518:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    8000251a:	854a                	mv	a0,s2
    8000251c:	f58fe0ef          	jal	80000c74 <release>
}
    80002520:	8526                	mv	a0,s1
    80002522:	60e2                	ld	ra,24(sp)
    80002524:	6442                	ld	s0,16(sp)
    80002526:	64a2                	ld	s1,8(sp)
    80002528:	6902                	ld	s2,0(sp)
    8000252a:	6105                	addi	sp,sp,32
    8000252c:	8082                	ret

000000008000252e <proc_swapon>:
  if(p->swapip) return 0; // already present
    8000252e:	3a853783          	ld	a5,936(a0)
    80002532:	c399                	beqz	a5,80002538 <proc_swapon+0xa>
    80002534:	4501                	li	a0,0
}
    80002536:	8082                	ret
{
    80002538:	7159                	addi	sp,sp,-112
    8000253a:	f486                	sd	ra,104(sp)
    8000253c:	f0a2                	sd	s0,96(sp)
    8000253e:	eca6                	sd	s1,88(sp)
    80002540:	e8ca                	sd	s2,80(sp)
    80002542:	e4ce                	sd	s3,72(sp)
    80002544:	1880                	addi	s0,sp,112
    80002546:	84aa                	mv	s1,a0
  safestrcpy(name, "/pgswp00000", sizeof(name));
    80002548:	02000613          	li	a2,32
    8000254c:	00006597          	auipc	a1,0x6
    80002550:	f4c58593          	addi	a1,a1,-180 # 80008498 <etext+0x498>
    80002554:	fb040513          	addi	a0,s0,-80
    80002558:	897fe0ef          	jal	80000dee <safestrcpy>
  int pid = p->pid;
    8000255c:	5894                	lw	a3,48(s1)
  for(int i=0;i<5;i++){
    8000255e:	fbf40793          	addi	a5,s0,-65
    80002562:	fba40593          	addi	a1,s0,-70
    name[11+4-i] = '0' + (pid%10);
    80002566:	4629                	li	a2,10
    80002568:	02c6e73b          	remw	a4,a3,a2
    8000256c:	0307071b          	addiw	a4,a4,48
    80002570:	00e78023          	sb	a4,0(a5)
    pid/=10;
    80002574:	02c6c6bb          	divw	a3,a3,a2
  for(int i=0;i<5;i++){
    80002578:	17fd                	addi	a5,a5,-1
    8000257a:	feb797e3          	bne	a5,a1,80002568 <proc_swapon+0x3a>
  begin_op();
    8000257e:	20b020ef          	jal	80004f88 <begin_op>
  struct inode *dp = nameiparent(name, nm);
    80002582:	fa040593          	addi	a1,s0,-96
    80002586:	fb040513          	addi	a0,s0,-80
    8000258a:	045020ef          	jal	80004dce <nameiparent>
    8000258e:	892a                	mv	s2,a0
  if(dp == 0){
    80002590:	c139                	beqz	a0,800025d6 <proc_swapon+0xa8>
  ilock(dp);
    80002592:	00c020ef          	jal	8000459e <ilock>
  struct inode *ip = dirlookup(dp, nm, &off);
    80002596:	f9c40613          	addi	a2,s0,-100
    8000259a:	fa040593          	addi	a1,s0,-96
    8000259e:	854a                	mv	a0,s2
    800025a0:	5ae020ef          	jal	80004b4e <dirlookup>
    800025a4:	89aa                	mv	s3,a0
  if(ip){
    800025a6:	cd05                	beqz	a0,800025de <proc_swapon+0xb0>
    ilock(ip);
    800025a8:	7f7010ef          	jal	8000459e <ilock>
    itrunc(ip);
    800025ac:	854e                	mv	a0,s3
    800025ae:	0de020ef          	jal	8000468c <itrunc>
    iunlock(ip);
    800025b2:	854e                	mv	a0,s3
    800025b4:	098020ef          	jal	8000464c <iunlock>
    iunlockput(dp);
    800025b8:	854a                	mv	a0,s2
    800025ba:	1ee020ef          	jal	800047a8 <iunlockput>
    p->swapip = ip;
    800025be:	3b34b423          	sd	s3,936(s1)
    end_op();
    800025c2:	231020ef          	jal	80004ff2 <end_op>
    return 0;
    800025c6:	4501                	li	a0,0
}
    800025c8:	70a6                	ld	ra,104(sp)
    800025ca:	7406                	ld	s0,96(sp)
    800025cc:	64e6                	ld	s1,88(sp)
    800025ce:	6946                	ld	s2,80(sp)
    800025d0:	69a6                	ld	s3,72(sp)
    800025d2:	6165                	addi	sp,sp,112
    800025d4:	8082                	ret
    end_op();
    800025d6:	21d020ef          	jal	80004ff2 <end_op>
    return -1;
    800025da:	557d                	li	a0,-1
    800025dc:	b7f5                	j	800025c8 <proc_swapon+0x9a>
  ip = ialloc(dp->dev, T_FILE);
    800025de:	4589                	li	a1,2
    800025e0:	00092503          	lw	a0,0(s2)
    800025e4:	64b010ef          	jal	8000442e <ialloc>
    800025e8:	89aa                	mv	s3,a0
  if(ip == 0){
    800025ea:	c131                	beqz	a0,8000262e <proc_swapon+0x100>
  ilock(ip);
    800025ec:	7b3010ef          	jal	8000459e <ilock>
  ip->major = 0; ip->minor = 0;
    800025f0:	04099323          	sh	zero,70(s3)
    800025f4:	04099423          	sh	zero,72(s3)
  ip->nlink = 1;
    800025f8:	4785                	li	a5,1
    800025fa:	04f99523          	sh	a5,74(s3)
  iupdate(ip);
    800025fe:	854e                	mv	a0,s3
    80002600:	6eb010ef          	jal	800044ea <iupdate>
  if(dirlink(dp, nm, ip->inum) < 0){
    80002604:	0049a603          	lw	a2,4(s3)
    80002608:	fa040593          	addi	a1,s0,-96
    8000260c:	854a                	mv	a0,s2
    8000260e:	70c020ef          	jal	80004d1a <dirlink>
    80002612:	02054563          	bltz	a0,8000263c <proc_swapon+0x10e>
  iunlockput(dp);
    80002616:	854a                	mv	a0,s2
    80002618:	190020ef          	jal	800047a8 <iunlockput>
  iunlock(ip);
    8000261c:	854e                	mv	a0,s3
    8000261e:	02e020ef          	jal	8000464c <iunlock>
  p->swapip = ip;
    80002622:	3b34b423          	sd	s3,936(s1)
  end_op();
    80002626:	1cd020ef          	jal	80004ff2 <end_op>
  return 0;
    8000262a:	4501                	li	a0,0
    8000262c:	bf71                	j	800025c8 <proc_swapon+0x9a>
    iunlockput(dp);
    8000262e:	854a                	mv	a0,s2
    80002630:	178020ef          	jal	800047a8 <iunlockput>
    end_op();
    80002634:	1bf020ef          	jal	80004ff2 <end_op>
    return -1;
    80002638:	557d                	li	a0,-1
    8000263a:	b779                	j	800025c8 <proc_swapon+0x9a>
    ip->nlink = 0;
    8000263c:	04099523          	sh	zero,74(s3)
    iupdate(ip);
    80002640:	854e                	mv	a0,s3
    80002642:	6a9010ef          	jal	800044ea <iupdate>
    iunlockput(ip);
    80002646:	854e                	mv	a0,s3
    80002648:	160020ef          	jal	800047a8 <iunlockput>
    iunlockput(dp);
    8000264c:	854a                	mv	a0,s2
    8000264e:	15a020ef          	jal	800047a8 <iunlockput>
    end_op();
    80002652:	1a1020ef          	jal	80004ff2 <end_op>
    return -1;
    80002656:	557d                	li	a0,-1
    80002658:	bf85                	j	800025c8 <proc_swapon+0x9a>

000000008000265a <proc_swapoff>:
  if(p->swapip == 0)
    8000265a:	3a853783          	ld	a5,936(a0)
    8000265e:	14078363          	beqz	a5,800027a4 <proc_swapoff+0x14a>
{
    80002662:	7119                	addi	sp,sp,-128
    80002664:	fc86                	sd	ra,120(sp)
    80002666:	f8a2                	sd	s0,112(sp)
    80002668:	f4a6                	sd	s1,104(sp)
    8000266a:	f0ca                	sd	s2,96(sp)
    8000266c:	0100                	addi	s0,sp,128
    8000266e:	84aa                	mv	s1,a0
  safestrcpy(name, "/pgswp00000", sizeof(name));
    80002670:	02000613          	li	a2,32
    80002674:	00006597          	auipc	a1,0x6
    80002678:	e2458593          	addi	a1,a1,-476 # 80008498 <etext+0x498>
    8000267c:	fb040513          	addi	a0,s0,-80
    80002680:	f6efe0ef          	jal	80000dee <safestrcpy>
  int pid = p->pid;
    80002684:	5894                	lw	a3,48(s1)
  for(int i=0;i<5;i++){
    80002686:	fbf40793          	addi	a5,s0,-65
    8000268a:	fba40593          	addi	a1,s0,-70
    name[11+4-i] = '0' + (pid%10);
    8000268e:	4629                	li	a2,10
    80002690:	02c6e73b          	remw	a4,a3,a2
    80002694:	0307071b          	addiw	a4,a4,48
    80002698:	00e78023          	sb	a4,0(a5)
    pid/=10;
    8000269c:	02c6c6bb          	divw	a3,a3,a2
  for(int i=0;i<5;i++){
    800026a0:	17fd                	addi	a5,a5,-1
    800026a2:	feb797e3          	bne	a5,a1,80002690 <proc_swapoff+0x36>
  begin_op();
    800026a6:	0e3020ef          	jal	80004f88 <begin_op>
  if((dp = nameiparent(name, nm)) != 0){
    800026aa:	f9040593          	addi	a1,s0,-112
    800026ae:	fb040513          	addi	a0,s0,-80
    800026b2:	71c020ef          	jal	80004dce <nameiparent>
    800026b6:	892a                	mv	s2,a0
    800026b8:	cd21                	beqz	a0,80002710 <proc_swapoff+0xb6>
    800026ba:	ecce                	sd	s3,88(sp)
    ilock(dp);
    800026bc:	6e3010ef          	jal	8000459e <ilock>
    struct inode *ip = dirlookup(dp, nm, &off);
    800026c0:	f8c40613          	addi	a2,s0,-116
    800026c4:	f9040593          	addi	a1,s0,-112
    800026c8:	854a                	mv	a0,s2
    800026ca:	484020ef          	jal	80004b4e <dirlookup>
    800026ce:	89aa                	mv	s3,a0
    if(ip){
    800026d0:	c92d                	beqz	a0,80002742 <proc_swapoff+0xe8>
      ilock(ip);
    800026d2:	6cd010ef          	jal	8000459e <ilock>
      memset(&de, 0, sizeof(de));
    800026d6:	4641                	li	a2,16
    800026d8:	4581                	li	a1,0
    800026da:	fa040513          	addi	a0,s0,-96
    800026de:	dd2fe0ef          	jal	80000cb0 <memset>
      if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800026e2:	4741                	li	a4,16
    800026e4:	f8c42683          	lw	a3,-116(s0)
    800026e8:	fa040613          	addi	a2,s0,-96
    800026ec:	4581                	li	a1,0
    800026ee:	854a                	mv	a0,s2
    800026f0:	33a020ef          	jal	80004a2a <writei>
    800026f4:	47c1                	li	a5,16
    800026f6:	02f51963          	bne	a0,a5,80002728 <proc_swapoff+0xce>
      iunlockput(dp);
    800026fa:	854a                	mv	a0,s2
    800026fc:	0ac020ef          	jal	800047a8 <iunlockput>
      if(ip->nlink > 0){
    80002700:	04a99783          	lh	a5,74(s3)
    80002704:	02f04863          	bgtz	a5,80002734 <proc_swapoff+0xda>
      iunlockput(ip);
    80002708:	854e                	mv	a0,s3
    8000270a:	09e020ef          	jal	800047a8 <iunlockput>
    8000270e:	69e6                	ld	s3,88(sp)
  iput(p->swapip);
    80002710:	3a84b503          	ld	a0,936(s1)
    80002714:	00c020ef          	jal	80004720 <iput>
  end_op();
    80002718:	0db020ef          	jal	80004ff2 <end_op>
  int freed = 0;
    8000271c:	4601                	li	a2,0
  for(int i = 0; i < 1024; i++){
    8000271e:	4781                	li	a5,0
      p->swap_bitmap[byte] &= ~(1<<bit);
    80002720:	4885                	li	a7,1
  for(int i = 0; i < 1024; i++){
    80002722:	40000513          	li	a0,1024
    80002726:	a035                	j	80002752 <proc_swapoff+0xf8>
        panic("swap unlink: writei");
    80002728:	00006517          	auipc	a0,0x6
    8000272c:	d8050513          	addi	a0,a0,-640 # 800084a8 <etext+0x4a8>
    80002730:	8b0fe0ef          	jal	800007e0 <panic>
        ip->nlink--;
    80002734:	37fd                	addiw	a5,a5,-1
    80002736:	04f99523          	sh	a5,74(s3)
        iupdate(ip);
    8000273a:	854e                	mv	a0,s3
    8000273c:	5af010ef          	jal	800044ea <iupdate>
    80002740:	b7e1                	j	80002708 <proc_swapoff+0xae>
      iunlockput(dp);
    80002742:	854a                	mv	a0,s2
    80002744:	064020ef          	jal	800047a8 <iunlockput>
    80002748:	69e6                	ld	s3,88(sp)
    8000274a:	b7d9                	j	80002710 <proc_swapoff+0xb6>
  for(int i = 0; i < 1024; i++){
    8000274c:	2785                	addiw	a5,a5,1
    8000274e:	02a78963          	beq	a5,a0,80002780 <proc_swapoff+0x126>
    int byte = i >> 3;
    80002752:	4037d59b          	sraiw	a1,a5,0x3
    int bit = i & 7;
    80002756:	0077f713          	andi	a4,a5,7
    if(p->swap_bitmap[byte] & (1<<bit)){
    8000275a:	00b486b3          	add	a3,s1,a1
    8000275e:	3b46c803          	lbu	a6,948(a3)
    80002762:	40e856bb          	sraw	a3,a6,a4
    80002766:	8a85                	andi	a3,a3,1
    80002768:	d2f5                	beqz	a3,8000274c <proc_swapoff+0xf2>
      freed++;
    8000276a:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
      p->swap_bitmap[byte] &= ~(1<<bit);
    8000276c:	95a6                	add	a1,a1,s1
    8000276e:	00e8973b          	sllw	a4,a7,a4
    80002772:	fff74713          	not	a4,a4
    80002776:	00e87833          	and	a6,a6,a4
    8000277a:	3b058a23          	sb	a6,948(a1)
    8000277e:	b7f9                	j	8000274c <proc_swapoff+0xf2>
  p->swapip = 0;
    80002780:	3a04b423          	sd	zero,936(s1)
  if(freed > 0)
    80002784:	00c04863          	bgtz	a2,80002794 <proc_swapoff+0x13a>
}
    80002788:	70e6                	ld	ra,120(sp)
    8000278a:	7446                	ld	s0,112(sp)
    8000278c:	74a6                	ld	s1,104(sp)
    8000278e:	7906                	ld	s2,96(sp)
    80002790:	6109                	addi	sp,sp,128
    80002792:	8082                	ret
    printf("[pid %d] SWAPCLEANUP freed_slots=%d\n", p->pid, freed);
    80002794:	588c                	lw	a1,48(s1)
    80002796:	00006517          	auipc	a0,0x6
    8000279a:	d2a50513          	addi	a0,a0,-726 # 800084c0 <etext+0x4c0>
    8000279e:	d5dfd0ef          	jal	800004fa <printf>
}
    800027a2:	b7dd                	j	80002788 <proc_swapoff+0x12e>
    800027a4:	8082                	ret

00000000800027a6 <proc_pagetable>:
{
    800027a6:	1101                	addi	sp,sp,-32
    800027a8:	ec06                	sd	ra,24(sp)
    800027aa:	e822                	sd	s0,16(sp)
    800027ac:	e426                	sd	s1,8(sp)
    800027ae:	e04a                	sd	s2,0(sp)
    800027b0:	1000                	addi	s0,sp,32
    800027b2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800027b4:	acbfe0ef          	jal	8000127e <uvmcreate>
    800027b8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800027ba:	cd05                	beqz	a0,800027f2 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800027bc:	4729                	li	a4,10
    800027be:	00005697          	auipc	a3,0x5
    800027c2:	84268693          	addi	a3,a3,-1982 # 80007000 <_trampoline>
    800027c6:	6605                	lui	a2,0x1
    800027c8:	040005b7          	lui	a1,0x4000
    800027cc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800027ce:	05b2                	slli	a1,a1,0xc
    800027d0:	8c1fe0ef          	jal	80001090 <mappages>
    800027d4:	02054663          	bltz	a0,80002800 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800027d8:	4719                	li	a4,6
    800027da:	05893683          	ld	a3,88(s2)
    800027de:	6605                	lui	a2,0x1
    800027e0:	020005b7          	lui	a1,0x2000
    800027e4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800027e6:	05b6                	slli	a1,a1,0xd
    800027e8:	8526                	mv	a0,s1
    800027ea:	8a7fe0ef          	jal	80001090 <mappages>
    800027ee:	00054f63          	bltz	a0,8000280c <proc_pagetable+0x66>
}
    800027f2:	8526                	mv	a0,s1
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6902                	ld	s2,0(sp)
    800027fc:	6105                	addi	sp,sp,32
    800027fe:	8082                	ret
    uvmfree(pagetable, 0);
    80002800:	4581                	li	a1,0
    80002802:	8526                	mv	a0,s1
    80002804:	fe7fe0ef          	jal	800017ea <uvmfree>
    return 0;
    80002808:	4481                	li	s1,0
    8000280a:	b7e5                	j	800027f2 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000280c:	4681                	li	a3,0
    8000280e:	4605                	li	a2,1
    80002810:	040005b7          	lui	a1,0x4000
    80002814:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002816:	05b2                	slli	a1,a1,0xc
    80002818:	8526                	mv	a0,s1
    8000281a:	a8bfe0ef          	jal	800012a4 <uvmunmap>
    uvmfree(pagetable, 0);
    8000281e:	4581                	li	a1,0
    80002820:	8526                	mv	a0,s1
    80002822:	fc9fe0ef          	jal	800017ea <uvmfree>
    return 0;
    80002826:	4481                	li	s1,0
    80002828:	b7e9                	j	800027f2 <proc_pagetable+0x4c>

000000008000282a <proc_freepagetable>:
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	e04a                	sd	s2,0(sp)
    80002834:	1000                	addi	s0,sp,32
    80002836:	84aa                	mv	s1,a0
    80002838:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000283a:	4681                	li	a3,0
    8000283c:	4605                	li	a2,1
    8000283e:	040005b7          	lui	a1,0x4000
    80002842:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002844:	05b2                	slli	a1,a1,0xc
    80002846:	a5ffe0ef          	jal	800012a4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000284a:	4681                	li	a3,0
    8000284c:	4605                	li	a2,1
    8000284e:	020005b7          	lui	a1,0x2000
    80002852:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80002854:	05b6                	slli	a1,a1,0xd
    80002856:	8526                	mv	a0,s1
    80002858:	a4dfe0ef          	jal	800012a4 <uvmunmap>
  uvmfree(pagetable, sz);
    8000285c:	85ca                	mv	a1,s2
    8000285e:	8526                	mv	a0,s1
    80002860:	f8bfe0ef          	jal	800017ea <uvmfree>
}
    80002864:	60e2                	ld	ra,24(sp)
    80002866:	6442                	ld	s0,16(sp)
    80002868:	64a2                	ld	s1,8(sp)
    8000286a:	6902                	ld	s2,0(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret

0000000080002870 <freeproc>:
{
    80002870:	1101                	addi	sp,sp,-32
    80002872:	ec06                	sd	ra,24(sp)
    80002874:	e822                	sd	s0,16(sp)
    80002876:	e426                	sd	s1,8(sp)
    80002878:	1000                	addi	s0,sp,32
    8000287a:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000287c:	6d28                	ld	a0,88(a0)
    8000287e:	c119                	beqz	a0,80002884 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80002880:	99cfe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80002884:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002888:	68a8                	ld	a0,80(s1)
    8000288a:	c501                	beqz	a0,80002892 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    8000288c:	64ac                	ld	a1,72(s1)
    8000288e:	f9dff0ef          	jal	8000282a <proc_freepagetable>
  p->pagetable = 0;
    80002892:	0404b823          	sd	zero,80(s1)
  p->execip = 0;
    80002896:	1804b823          	sd	zero,400(s1)
  p->sz = 0;
    8000289a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000289e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800028a2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800028a6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800028aa:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800028ae:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800028b2:	0204a623          	sw	zero,44(s1)
  p->creation_time = 0; // ADDED
    800028b6:	1604b423          	sd	zero,360(s1)
  p->state = UNUSED;
    800028ba:	0004ac23          	sw	zero,24(s1)
}
    800028be:	60e2                	ld	ra,24(sp)
    800028c0:	6442                	ld	s0,16(sp)
    800028c2:	64a2                	ld	s1,8(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret

00000000800028c8 <allocproc>:
{
    800028c8:	7179                	addi	sp,sp,-48
    800028ca:	f406                	sd	ra,40(sp)
    800028cc:	f022                	sd	s0,32(sp)
    800028ce:	ec26                	sd	s1,24(sp)
    800028d0:	e84a                	sd	s2,16(sp)
    800028d2:	e44e                	sd	s3,8(sp)
    800028d4:	e052                	sd	s4,0(sp)
    800028d6:	1800                	addi	s0,sp,48
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    800028d8:	00011797          	auipc	a5,0x11
    800028dc:	65878793          	addi	a5,a5,1624 # 80013f30 <proc>
  int found_runnable = 0;
    800028e0:	4801                	li	a6,0
  uint64 min_vruntime = 0;
    800028e2:	4901                	li	s2,0
    if(p_search->state == RUNNABLE && p_search->pid > 2) {  // Exclude init and shell processes
    800028e4:	458d                	li	a1,3
    800028e6:	4509                	li	a0,2
        found_runnable = 1;
    800028e8:	4885                	li	a7,1
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    800028ea:	6699                	lui	a3,0x6
    800028ec:	44068693          	addi	a3,a3,1088 # 6440 <_entry-0x7fff9bc0>
    800028f0:	001a2617          	auipc	a2,0x1a2
    800028f4:	64060613          	addi	a2,a2,1600 # 801a4f30 <tickslock>
    800028f8:	a039                	j	80002906 <allocproc+0x3e>
        min_vruntime = p_search->vruntime;
    800028fa:	1787b903          	ld	s2,376(a5)
        found_runnable = 1;
    800028fe:	8846                	mv	a6,a7
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    80002900:	97b6                	add	a5,a5,a3
    80002902:	00c78f63          	beq	a5,a2,80002920 <allocproc+0x58>
    if(p_search->state == RUNNABLE && p_search->pid > 2) {  // Exclude init and shell processes
    80002906:	4f98                	lw	a4,24(a5)
    80002908:	feb71ce3          	bne	a4,a1,80002900 <allocproc+0x38>
    8000290c:	5b98                	lw	a4,48(a5)
    8000290e:	fee559e3          	bge	a0,a4,80002900 <allocproc+0x38>
      if(found_runnable == 0 || p_search->vruntime < min_vruntime) {
    80002912:	fe0804e3          	beqz	a6,800028fa <allocproc+0x32>
    80002916:	1787b703          	ld	a4,376(a5)
    8000291a:	ff2773e3          	bgeu	a4,s2,80002900 <allocproc+0x38>
    8000291e:	bff1                	j	800028fa <allocproc+0x32>
  if (min_vruntime == -1) {
    80002920:	57fd                	li	a5,-1
    80002922:	02f90a63          	beq	s2,a5,80002956 <allocproc+0x8e>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002926:	00011497          	auipc	s1,0x11
    8000292a:	60a48493          	addi	s1,s1,1546 # 80013f30 <proc>
    8000292e:	6999                	lui	s3,0x6
    80002930:	44098993          	addi	s3,s3,1088 # 6440 <_entry-0x7fff9bc0>
    80002934:	001a2a17          	auipc	s4,0x1a2
    80002938:	5fca0a13          	addi	s4,s4,1532 # 801a4f30 <tickslock>
    acquire(&p->lock);
    8000293c:	8526                	mv	a0,s1
    8000293e:	a90fe0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80002942:	4c9c                	lw	a5,24(s1)
    80002944:	cb99                	beqz	a5,8000295a <allocproc+0x92>
      release(&p->lock);
    80002946:	8526                	mv	a0,s1
    80002948:	b2cfe0ef          	jal	80000c74 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000294c:	94ce                	add	s1,s1,s3
    8000294e:	ff4497e3          	bne	s1,s4,8000293c <allocproc+0x74>
  return 0;
    80002952:	4481                	li	s1,0
    80002954:	a0dd                	j	80002a3a <allocproc+0x172>
    min_vruntime = 0;
    80002956:	4901                	li	s2,0
    80002958:	b7f9                	j	80002926 <allocproc+0x5e>
  p->pid = allocpid();
    8000295a:	b97ff0ef          	jal	800024f0 <allocpid>
    8000295e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002960:	4785                	li	a5,1
    80002962:	cc9c                	sw	a5,24(s1)
  p->nice = 0; // Default nice value
    80002964:	1604a823          	sw	zero,368(s1)
  p->weight = nice_to_weight[p->nice + 20];
    80002968:	40000793          	li	a5,1024
    8000296c:	16f4aa23          	sw	a5,372(s1)
  p->vruntime = min_vruntime; // Start with 0, will be updated
    80002970:	1724bc23          	sd	s2,376(s1)
  p->time_slice = 0;
    80002974:	1804a023          	sw	zero,384(s1)
  acquire(&creation_time_lock);
    80002978:	00011917          	auipc	s2,0x11
    8000297c:	1a090913          	addi	s2,s2,416 # 80013b18 <creation_time_lock>
    80002980:	854a                	mv	a0,s2
    80002982:	a4cfe0ef          	jal	80000bce <acquire>
  p->creation_time = next_creation_time++;
    80002986:	00009717          	auipc	a4,0x9
    8000298a:	ff270713          	addi	a4,a4,-14 # 8000b978 <next_creation_time>
    8000298e:	631c                	ld	a5,0(a4)
    80002990:	00178693          	addi	a3,a5,1
    80002994:	e314                	sd	a3,0(a4)
    80002996:	16f4b423          	sd	a5,360(s1)
  release(&creation_time_lock);
    8000299a:	854a                	mv	a0,s2
    8000299c:	ad8fe0ef          	jal	80000c74 <release>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800029a0:	95efe0ef          	jal	80000afe <kalloc>
    800029a4:	892a                	mv	s2,a0
    800029a6:	eca8                	sd	a0,88(s1)
    800029a8:	c155                	beqz	a0,80002a4c <allocproc+0x184>
  p->pagetable = proc_pagetable(p);
    800029aa:	8526                	mv	a0,s1
    800029ac:	dfbff0ef          	jal	800027a6 <proc_pagetable>
    800029b0:	892a                	mv	s2,a0
    800029b2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800029b4:	c545                	beqz	a0,80002a5c <allocproc+0x194>
  memset(&p->context, 0, sizeof(p->context));
    800029b6:	07000613          	li	a2,112
    800029ba:	4581                	li	a1,0
    800029bc:	06048513          	addi	a0,s1,96
    800029c0:	af0fe0ef          	jal	80000cb0 <memset>
  p->context.ra = (uint64)forkret;
    800029c4:	00000797          	auipc	a5,0x0
    800029c8:	a9478793          	addi	a5,a5,-1388 # 80002458 <forkret>
    800029cc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800029ce:	60bc                	ld	a5,64(s1)
    800029d0:	6705                	lui	a4,0x1
    800029d2:	97ba                	add	a5,a5,a4
    800029d4:	f4bc                	sd	a5,104(s1)
  p->heap_brk = 0;
    800029d6:	1804b423          	sd	zero,392(s1)
  p->execip = 0;
    800029da:	1804b823          	sd	zero,400(s1)
  p->nsegs = 0;
    800029de:	1804ac23          	sw	zero,408(s1)
  p->page_seq_ctr = 1;
    800029e2:	4785                	li	a5,1
    800029e4:	3af4b023          	sd	a5,928(s1)
  p->swapip = 0;
    800029e8:	3a04b423          	sd	zero,936(s1)
  p->swap_pages = 0;
    800029ec:	3a04a823          	sw	zero,944(s1)
  memset(p->swap_bitmap, 0, sizeof(p->swap_bitmap));
    800029f0:	08000613          	li	a2,128
    800029f4:	4581                	li	a1,0
    800029f6:	3b448513          	addi	a0,s1,948
    800029fa:	ab6fe0ef          	jal	80000cb0 <memset>
  for(int mi=0; mi<PGMETA_SIZE; mi++){
    800029fe:	43848793          	addi	a5,s1,1080
    80002a02:	6719                	lui	a4,0x6
    80002a04:	43870713          	addi	a4,a4,1080 # 6438 <_entry-0x7fff9bc8>
    80002a08:	9726                	add	a4,a4,s1
    p->pgmeta[mi].slot = 0xffff;
    80002a0a:	56fd                	li	a3,-1
    p->pgmeta[mi].va = 0;
    80002a0c:	0007b023          	sd	zero,0(a5)
    p->pgmeta[mi].seq = 0;
    80002a10:	0007b423          	sd	zero,8(a5)
    p->pgmeta[mi].resident = 0;
    80002a14:	00078823          	sb	zero,16(a5)
    p->pgmeta[mi].dirty = 0;
    80002a18:	000788a3          	sb	zero,17(a5)
    p->pgmeta[mi].referenced = 0;
    80002a1c:	00078923          	sb	zero,18(a5)
    p->pgmeta[mi].in_swap = 0;
    80002a20:	000789a3          	sb	zero,19(a5)
    p->pgmeta[mi].slot = 0xffff;
    80002a24:	00d79a23          	sh	a3,20(a5)
    p->pgmeta[mi].perm = 0;
    80002a28:	00079b23          	sh	zero,22(a5)
  for(int mi=0; mi<PGMETA_SIZE; mi++){
    80002a2c:	07e1                	addi	a5,a5,24
    80002a2e:	fce79fe3          	bne	a5,a4,80002a0c <allocproc+0x144>
  p->clock_hand = 0;
    80002a32:	6799                	lui	a5,0x6
    80002a34:	97a6                	add	a5,a5,s1
    80002a36:	4207ac23          	sw	zero,1080(a5) # 6438 <_entry-0x7fff9bc8>
}
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	70a2                	ld	ra,40(sp)
    80002a3e:	7402                	ld	s0,32(sp)
    80002a40:	64e2                	ld	s1,24(sp)
    80002a42:	6942                	ld	s2,16(sp)
    80002a44:	69a2                	ld	s3,8(sp)
    80002a46:	6a02                	ld	s4,0(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret
    freeproc(p);
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	e23ff0ef          	jal	80002870 <freeproc>
    release(&p->lock);
    80002a52:	8526                	mv	a0,s1
    80002a54:	a20fe0ef          	jal	80000c74 <release>
    return 0;
    80002a58:	84ca                	mv	s1,s2
    80002a5a:	b7c5                	j	80002a3a <allocproc+0x172>
    freeproc(p);
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	e13ff0ef          	jal	80002870 <freeproc>
    release(&p->lock);
    80002a62:	8526                	mv	a0,s1
    80002a64:	a10fe0ef          	jal	80000c74 <release>
    return 0;
    80002a68:	84ca                	mv	s1,s2
    80002a6a:	bfc1                	j	80002a3a <allocproc+0x172>

0000000080002a6c <userinit>:
{
    80002a6c:	1101                	addi	sp,sp,-32
    80002a6e:	ec06                	sd	ra,24(sp)
    80002a70:	e822                	sd	s0,16(sp)
    80002a72:	e426                	sd	s1,8(sp)
    80002a74:	1000                	addi	s0,sp,32
  p = allocproc();
    80002a76:	e53ff0ef          	jal	800028c8 <allocproc>
    80002a7a:	84aa                	mv	s1,a0
  initproc = p;
    80002a7c:	00009797          	auipc	a5,0x9
    80002a80:	f4a7ba23          	sd	a0,-172(a5) # 8000b9d0 <initproc>
  p->cwd = namei("/");
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	a6450513          	addi	a0,a0,-1436 # 800084e8 <etext+0x4e8>
    80002a8c:	328020ef          	jal	80004db4 <namei>
    80002a90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002a94:	478d                	li	a5,3
    80002a96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002a98:	8526                	mv	a0,s1
    80002a9a:	9dafe0ef          	jal	80000c74 <release>
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret

0000000080002aa8 <growproc>:
{
    80002aa8:	1101                	addi	sp,sp,-32
    80002aaa:	ec06                	sd	ra,24(sp)
    80002aac:	e822                	sd	s0,16(sp)
    80002aae:	e426                	sd	s1,8(sp)
    80002ab0:	e04a                	sd	s2,0(sp)
    80002ab2:	1000                	addi	s0,sp,32
    80002ab4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002ab6:	973ff0ef          	jal	80002428 <myproc>
    80002aba:	84aa                	mv	s1,a0
  sz = p->sz;
    80002abc:	652c                	ld	a1,72(a0)
  if(n > 0){
    80002abe:	01204c63          	bgtz	s2,80002ad6 <growproc+0x2e>
  } else if(n < 0){
    80002ac2:	02094463          	bltz	s2,80002aea <growproc+0x42>
  p->sz = sz;
    80002ac6:	e4ac                	sd	a1,72(s1)
  return 0;
    80002ac8:	4501                	li	a0,0
}
    80002aca:	60e2                	ld	ra,24(sp)
    80002acc:	6442                	ld	s0,16(sp)
    80002ace:	64a2                	ld	s1,8(sp)
    80002ad0:	6902                	ld	s2,0(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80002ad6:	4691                	li	a3,4
    80002ad8:	00b90633          	add	a2,s2,a1
    80002adc:	6928                	ld	a0,80(a0)
    80002ade:	b73fe0ef          	jal	80001650 <uvmalloc>
    80002ae2:	85aa                	mv	a1,a0
    80002ae4:	f16d                	bnez	a0,80002ac6 <growproc+0x1e>
      return -1;
    80002ae6:	557d                	li	a0,-1
    80002ae8:	b7cd                	j	80002aca <growproc+0x22>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002aea:	00b90633          	add	a2,s2,a1
    80002aee:	6928                	ld	a0,80(a0)
    80002af0:	b1dfe0ef          	jal	8000160c <uvmdealloc>
    80002af4:	85aa                	mv	a1,a0
    80002af6:	bfc1                	j	80002ac6 <growproc+0x1e>

0000000080002af8 <kfork>:
{
    80002af8:	7139                	addi	sp,sp,-64
    80002afa:	fc06                	sd	ra,56(sp)
    80002afc:	f822                	sd	s0,48(sp)
    80002afe:	f04a                	sd	s2,32(sp)
    80002b00:	e852                	sd	s4,16(sp)
    80002b02:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002b04:	925ff0ef          	jal	80002428 <myproc>
    80002b08:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002b0a:	dbfff0ef          	jal	800028c8 <allocproc>
    80002b0e:	1c050163          	beqz	a0,80002cd0 <kfork+0x1d8>
    80002b12:	ec4e                	sd	s3,24(sp)
    80002b14:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz, np) < 0){
    80002b16:	86aa                	mv	a3,a0
    80002b18:	04893603          	ld	a2,72(s2)
    80002b1c:	692c                	ld	a1,80(a0)
    80002b1e:	05093503          	ld	a0,80(s2)
    80002b22:	cfbfe0ef          	jal	8000181c <uvmcopy>
    80002b26:	04054063          	bltz	a0,80002b66 <kfork+0x6e>
    80002b2a:	f426                	sd	s1,40(sp)
    80002b2c:	e456                	sd	s5,8(sp)
  np->sz = p->sz;
    80002b2e:	04893783          	ld	a5,72(s2)
    80002b32:	04f9b423          	sd	a5,72(s3)
  np->nice = p->nice;
    80002b36:	17092783          	lw	a5,368(s2)
    80002b3a:	16f9a823          	sw	a5,368(s3)
  np->weight = p->weight;
    80002b3e:	17492783          	lw	a5,372(s2)
    80002b42:	16f9aa23          	sw	a5,372(s3)
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    80002b46:	00011797          	auipc	a5,0x11
    80002b4a:	3ea78793          	addi	a5,a5,1002 # 80013f30 <proc>
  uint64 min_vruntime = -1;
    80002b4e:	557d                	li	a0,-1
    if(p_search->state == RUNNABLE && p_search->pid > 2) {  // Exclude init and shell processes
    80002b50:	458d                	li	a1,3
    80002b52:	4809                	li	a6,2
      if(min_vruntime == -1 || p_search->vruntime < min_vruntime) {
    80002b54:	58fd                	li	a7,-1
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    80002b56:	6699                	lui	a3,0x6
    80002b58:	44068693          	addi	a3,a3,1088 # 6440 <_entry-0x7fff9bc0>
    80002b5c:	001a2617          	auipc	a2,0x1a2
    80002b60:	3d460613          	addi	a2,a2,980 # 801a4f30 <tickslock>
    80002b64:	a839                	j	80002b82 <kfork+0x8a>
    freeproc(np);
    80002b66:	854e                	mv	a0,s3
    80002b68:	d09ff0ef          	jal	80002870 <freeproc>
    release(&np->lock);
    80002b6c:	854e                	mv	a0,s3
    80002b6e:	906fe0ef          	jal	80000c74 <release>
    return -1;
    80002b72:	5a7d                	li	s4,-1
    80002b74:	69e2                	ld	s3,24(sp)
    80002b76:	a2b1                	j	80002cc2 <kfork+0x1ca>
        min_vruntime = p_search->vruntime;
    80002b78:	1787b503          	ld	a0,376(a5)
  for(struct proc *p_search = proc; p_search < &proc[NPROC]; p_search++) {
    80002b7c:	97b6                	add	a5,a5,a3
    80002b7e:	00c78f63          	beq	a5,a2,80002b9c <kfork+0xa4>
    if(p_search->state == RUNNABLE && p_search->pid > 2) {  // Exclude init and shell processes
    80002b82:	4f98                	lw	a4,24(a5)
    80002b84:	feb71ce3          	bne	a4,a1,80002b7c <kfork+0x84>
    80002b88:	5b98                	lw	a4,48(a5)
    80002b8a:	fee859e3          	bge	a6,a4,80002b7c <kfork+0x84>
      if(min_vruntime == -1 || p_search->vruntime < min_vruntime) {
    80002b8e:	ff1505e3          	beq	a0,a7,80002b78 <kfork+0x80>
    80002b92:	1787b703          	ld	a4,376(a5)
    80002b96:	fea773e3          	bgeu	a4,a0,80002b7c <kfork+0x84>
    80002b9a:	bff9                	j	80002b78 <kfork+0x80>
  if(min_vruntime == -1) {
    80002b9c:	57fd                	li	a5,-1
    80002b9e:	04f50663          	beq	a0,a5,80002bea <kfork+0xf2>
    80002ba2:	16a9bc23          	sd	a0,376(s3)
  *(np->trapframe) = *(p->trapframe);
    80002ba6:	05893683          	ld	a3,88(s2)
    80002baa:	87b6                	mv	a5,a3
    80002bac:	0589b703          	ld	a4,88(s3)
    80002bb0:	12068693          	addi	a3,a3,288
    80002bb4:	0007b803          	ld	a6,0(a5)
    80002bb8:	6788                	ld	a0,8(a5)
    80002bba:	6b8c                	ld	a1,16(a5)
    80002bbc:	6f90                	ld	a2,24(a5)
    80002bbe:	01073023          	sd	a6,0(a4)
    80002bc2:	e708                	sd	a0,8(a4)
    80002bc4:	eb0c                	sd	a1,16(a4)
    80002bc6:	ef10                	sd	a2,24(a4)
    80002bc8:	02078793          	addi	a5,a5,32
    80002bcc:	02070713          	addi	a4,a4,32
    80002bd0:	fed792e3          	bne	a5,a3,80002bb4 <kfork+0xbc>
  np->trapframe->a0 = 0;
    80002bd4:	0589b783          	ld	a5,88(s3)
    80002bd8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002bdc:	0d090493          	addi	s1,s2,208
    80002be0:	0d098a13          	addi	s4,s3,208
    80002be4:	15090a93          	addi	s5,s2,336
    80002be8:	a801                	j	80002bf8 <kfork+0x100>
    np->vruntime = p->vruntime;
    80002bea:	17893503          	ld	a0,376(s2)
    80002bee:	bf55                	j	80002ba2 <kfork+0xaa>
  for(i = 0; i < NOFILE; i++)
    80002bf0:	04a1                	addi	s1,s1,8
    80002bf2:	0a21                	addi	s4,s4,8
    80002bf4:	01548963          	beq	s1,s5,80002c06 <kfork+0x10e>
    if(p->ofile[i])
    80002bf8:	6088                	ld	a0,0(s1)
    80002bfa:	d97d                	beqz	a0,80002bf0 <kfork+0xf8>
      np->ofile[i] = filedup(p->ofile[i]);
    80002bfc:	752020ef          	jal	8000534e <filedup>
    80002c00:	00aa3023          	sd	a0,0(s4)
    80002c04:	b7f5                	j	80002bf0 <kfork+0xf8>
  np->cwd = idup(p->cwd);
    80002c06:	15093503          	ld	a0,336(s2)
    80002c0a:	15f010ef          	jal	80004568 <idup>
    80002c0e:	14a9b823          	sd	a0,336(s3)
  np->heap_brk = p->heap_brk;
    80002c12:	18893783          	ld	a5,392(s2)
    80002c16:	18f9b423          	sd	a5,392(s3)
  np->nsegs = p->nsegs;
    80002c1a:	19892783          	lw	a5,408(s2)
    80002c1e:	18f9ac23          	sw	a5,408(s3)
  for(int si = 0; si < p->nsegs && si < 16; si++){
    80002c22:	19892783          	lw	a5,408(s2)
    80002c26:	02f05d63          	blez	a5,80002c60 <kfork+0x168>
    80002c2a:	1a090713          	addi	a4,s2,416
    80002c2e:	1a098793          	addi	a5,s3,416
    80002c32:	4681                	li	a3,0
    80002c34:	48c1                	li	a7,16
    np->segs[si] = p->segs[si];
    80002c36:	00073803          	ld	a6,0(a4)
    80002c3a:	6708                	ld	a0,8(a4)
    80002c3c:	6b0c                	ld	a1,16(a4)
    80002c3e:	6f10                	ld	a2,24(a4)
    80002c40:	0107b023          	sd	a6,0(a5)
    80002c44:	e788                	sd	a0,8(a5)
    80002c46:	eb8c                	sd	a1,16(a5)
    80002c48:	ef90                	sd	a2,24(a5)
  for(int si = 0; si < p->nsegs && si < 16; si++){
    80002c4a:	2685                	addiw	a3,a3,1
    80002c4c:	19892603          	lw	a2,408(s2)
    80002c50:	00c6d863          	bge	a3,a2,80002c60 <kfork+0x168>
    80002c54:	02070713          	addi	a4,a4,32
    80002c58:	02078793          	addi	a5,a5,32
    80002c5c:	fd169de3          	bne	a3,a7,80002c36 <kfork+0x13e>
  if(p->execip){
    80002c60:	19093503          	ld	a0,400(s2)
    80002c64:	c119                	beqz	a0,80002c6a <kfork+0x172>
    np->execip = idup(p->execip);
    80002c66:	103010ef          	jal	80004568 <idup>
    80002c6a:	18a9b823          	sd	a0,400(s3)
  np->page_seq_ctr = 1;
    80002c6e:	4785                	li	a5,1
    80002c70:	3af9b023          	sd	a5,928(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002c74:	4641                	li	a2,16
    80002c76:	15890593          	addi	a1,s2,344
    80002c7a:	15898513          	addi	a0,s3,344
    80002c7e:	970fe0ef          	jal	80000dee <safestrcpy>
  pid = np->pid;
    80002c82:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002c86:	854e                	mv	a0,s3
    80002c88:	fedfd0ef          	jal	80000c74 <release>
  proc_swapon(np);
    80002c8c:	854e                	mv	a0,s3
    80002c8e:	8a1ff0ef          	jal	8000252e <proc_swapon>
  acquire(&wait_lock);
    80002c92:	00011497          	auipc	s1,0x11
    80002c96:	e6e48493          	addi	s1,s1,-402 # 80013b00 <wait_lock>
    80002c9a:	8526                	mv	a0,s1
    80002c9c:	f33fd0ef          	jal	80000bce <acquire>
  np->parent = p;
    80002ca0:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	fcffd0ef          	jal	80000c74 <release>
  acquire(&np->lock);
    80002caa:	854e                	mv	a0,s3
    80002cac:	f23fd0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80002cb0:	478d                	li	a5,3
    80002cb2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002cb6:	854e                	mv	a0,s3
    80002cb8:	fbdfd0ef          	jal	80000c74 <release>
  return pid;
    80002cbc:	74a2                	ld	s1,40(sp)
    80002cbe:	69e2                	ld	s3,24(sp)
    80002cc0:	6aa2                	ld	s5,8(sp)
}
    80002cc2:	8552                	mv	a0,s4
    80002cc4:	70e2                	ld	ra,56(sp)
    80002cc6:	7442                	ld	s0,48(sp)
    80002cc8:	7902                	ld	s2,32(sp)
    80002cca:	6a42                	ld	s4,16(sp)
    80002ccc:	6121                	addi	sp,sp,64
    80002cce:	8082                	ret
    return -1;
    80002cd0:	5a7d                	li	s4,-1
    80002cd2:	bfc5                	j	80002cc2 <kfork+0x1ca>

0000000080002cd4 <scheduler>:
{
    80002cd4:	711d                	addi	sp,sp,-96
    80002cd6:	ec86                	sd	ra,88(sp)
    80002cd8:	e8a2                	sd	s0,80(sp)
    80002cda:	e4a6                	sd	s1,72(sp)
    80002cdc:	e0ca                	sd	s2,64(sp)
    80002cde:	fc4e                	sd	s3,56(sp)
    80002ce0:	f852                	sd	s4,48(sp)
    80002ce2:	f456                	sd	s5,40(sp)
    80002ce4:	f05a                	sd	s6,32(sp)
    80002ce6:	ec5e                	sd	s7,24(sp)
    80002ce8:	e862                	sd	s8,16(sp)
    80002cea:	e466                	sd	s9,8(sp)
    80002cec:	1080                	addi	s0,sp,96
    80002cee:	8792                	mv	a5,tp
  int id = r_tp();
    80002cf0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002cf2:	00779c13          	slli	s8,a5,0x7
    80002cf6:	00011717          	auipc	a4,0x11
    80002cfa:	df270713          	addi	a4,a4,-526 # 80013ae8 <pid_lock>
    80002cfe:	9762                	add	a4,a4,s8
    80002d00:	04073423          	sd	zero,72(a4)
        swtch(&c->context, &p->context);
    80002d04:	00011717          	auipc	a4,0x11
    80002d08:	e3470713          	addi	a4,a4,-460 # 80013b38 <cpus+0x8>
    80002d0c:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE && p->pid > 2) {  // Exclude init and shell processes
    80002d0e:	4a89                	li	s5,2
        c->proc = p;
    80002d10:	079e                	slli	a5,a5,0x7
    80002d12:	00011b17          	auipc	s6,0x11
    80002d16:	dd6b0b13          	addi	s6,s6,-554 # 80013ae8 <pid_lock>
    80002d1a:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002d1c:	6919                	lui	s2,0x6
    80002d1e:	44090913          	addi	s2,s2,1088 # 6440 <_entry-0x7fff9bc0>
    80002d22:	a065                	j	80002dca <scheduler+0xf6>
      release(&p->lock);
    80002d24:	8526                	mv	a0,s1
    80002d26:	f4ffd0ef          	jal	80000c74 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002d2a:	94ca                	add	s1,s1,s2
    80002d2c:	03448863          	beq	s1,s4,80002d5c <scheduler+0x88>
      acquire(&p->lock);
    80002d30:	8526                	mv	a0,s1
    80002d32:	e9dfd0ef          	jal	80000bce <acquire>
      if(p->state == RUNNABLE && p->pid > 2) {  // Exclude init and shell processes
    80002d36:	4c9c                	lw	a5,24(s1)
    80002d38:	ff3796e3          	bne	a5,s3,80002d24 <scheduler+0x50>
    80002d3c:	589c                	lw	a5,48(s1)
    80002d3e:	fefad3e3          	bge	s5,a5,80002d24 <scheduler+0x50>
        p->state = RUNNING;
    80002d42:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    80002d46:	049b3423          	sd	s1,72(s6)
        swtch(&c->context, &p->context);
    80002d4a:	06048593          	addi	a1,s1,96
    80002d4e:	8562                	mv	a0,s8
    80002d50:	66a000ef          	jal	800033ba <swtch>
        c->proc = 0;
    80002d54:	040b3423          	sd	zero,72(s6)
        found = 1;
    80002d58:	4b85                	li	s7,1
    80002d5a:	b7e9                	j	80002d24 <scheduler+0x50>
    if(found == 0) {
    80002d5c:	020b8063          	beqz	s7,80002d7c <scheduler+0xa8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d68:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002d6c:	4b81                	li	s7,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002d6e:	00011497          	auipc	s1,0x11
    80002d72:	1c248493          	addi	s1,s1,450 # 80013f30 <proc>
      if(p->state == RUNNABLE && p->pid > 2) {  // Exclude init and shell processes
    80002d76:	498d                	li	s3,3
        p->state = RUNNING;
    80002d78:	4c91                	li	s9,4
    80002d7a:	bf5d                	j	80002d30 <scheduler+0x5c>
      for(p = proc; p < &proc[NPROC]; p++) {
    80002d7c:	00011497          	auipc	s1,0x11
    80002d80:	1b448493          	addi	s1,s1,436 # 80013f30 <proc>
        if(p->state == RUNNABLE) {
    80002d84:	498d                	li	s3,3
      for(p = proc; p < &proc[NPROC]; p++) {
    80002d86:	001a2a17          	auipc	s4,0x1a2
    80002d8a:	1aaa0a13          	addi	s4,s4,426 # 801a4f30 <tickslock>
    80002d8e:	a811                	j	80002da2 <scheduler+0xce>
        asm volatile("wfi");
    80002d90:	10500073          	wfi
    80002d94:	a81d                	j	80002dca <scheduler+0xf6>
        release(&p->lock);
    80002d96:	8526                	mv	a0,s1
    80002d98:	eddfd0ef          	jal	80000c74 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80002d9c:	94ca                	add	s1,s1,s2
    80002d9e:	ff4489e3          	beq	s1,s4,80002d90 <scheduler+0xbc>
        acquire(&p->lock);
    80002da2:	8526                	mv	a0,s1
    80002da4:	e2bfd0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE) {
    80002da8:	4c9c                	lw	a5,24(s1)
    80002daa:	ff3796e3          	bne	a5,s3,80002d96 <scheduler+0xc2>
          p->state = RUNNING;
    80002dae:	4791                	li	a5,4
    80002db0:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80002db2:	049b3423          	sd	s1,72(s6)
          swtch(&c->context, &p->context);
    80002db6:	06048593          	addi	a1,s1,96
    80002dba:	8562                	mv	a0,s8
    80002dbc:	5fe000ef          	jal	800033ba <swtch>
          c->proc = 0;
    80002dc0:	040b3423          	sd	zero,72(s6)
        release(&p->lock);
    80002dc4:	8526                	mv	a0,s1
    80002dc6:	eaffd0ef          	jal	80000c74 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002dca:	001a2a17          	auipc	s4,0x1a2
    80002dce:	166a0a13          	addi	s4,s4,358 # 801a4f30 <tickslock>
    80002dd2:	b779                	j	80002d60 <scheduler+0x8c>

0000000080002dd4 <sched>:
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	ec26                	sd	s1,24(sp)
    80002ddc:	e84a                	sd	s2,16(sp)
    80002dde:	e44e                	sd	s3,8(sp)
    80002de0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002de2:	e46ff0ef          	jal	80002428 <myproc>
    80002de6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002de8:	d7dfd0ef          	jal	80000b64 <holding>
    80002dec:	c92d                	beqz	a0,80002e5e <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002dee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002df0:	2781                	sext.w	a5,a5
    80002df2:	079e                	slli	a5,a5,0x7
    80002df4:	00011717          	auipc	a4,0x11
    80002df8:	cf470713          	addi	a4,a4,-780 # 80013ae8 <pid_lock>
    80002dfc:	97ba                	add	a5,a5,a4
    80002dfe:	0c07a703          	lw	a4,192(a5)
    80002e02:	4785                	li	a5,1
    80002e04:	06f71363          	bne	a4,a5,80002e6a <sched+0x96>
  if(p->state == RUNNING)
    80002e08:	4c98                	lw	a4,24(s1)
    80002e0a:	4791                	li	a5,4
    80002e0c:	06f70563          	beq	a4,a5,80002e76 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e14:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002e16:	e7b5                	bnez	a5,80002e82 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e18:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002e1a:	00011917          	auipc	s2,0x11
    80002e1e:	cce90913          	addi	s2,s2,-818 # 80013ae8 <pid_lock>
    80002e22:	2781                	sext.w	a5,a5
    80002e24:	079e                	slli	a5,a5,0x7
    80002e26:	97ca                	add	a5,a5,s2
    80002e28:	0c47a983          	lw	s3,196(a5)
    80002e2c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002e2e:	2781                	sext.w	a5,a5
    80002e30:	079e                	slli	a5,a5,0x7
    80002e32:	00011597          	auipc	a1,0x11
    80002e36:	d0658593          	addi	a1,a1,-762 # 80013b38 <cpus+0x8>
    80002e3a:	95be                	add	a1,a1,a5
    80002e3c:	06048513          	addi	a0,s1,96
    80002e40:	57a000ef          	jal	800033ba <swtch>
    80002e44:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002e46:	2781                	sext.w	a5,a5
    80002e48:	079e                	slli	a5,a5,0x7
    80002e4a:	993e                	add	s2,s2,a5
    80002e4c:	0d392223          	sw	s3,196(s2)
}
    80002e50:	70a2                	ld	ra,40(sp)
    80002e52:	7402                	ld	s0,32(sp)
    80002e54:	64e2                	ld	s1,24(sp)
    80002e56:	6942                	ld	s2,16(sp)
    80002e58:	69a2                	ld	s3,8(sp)
    80002e5a:	6145                	addi	sp,sp,48
    80002e5c:	8082                	ret
    panic("sched p->lock");
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	69250513          	addi	a0,a0,1682 # 800084f0 <etext+0x4f0>
    80002e66:	97bfd0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	69650513          	addi	a0,a0,1686 # 80008500 <etext+0x500>
    80002e72:	96ffd0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	69a50513          	addi	a0,a0,1690 # 80008510 <etext+0x510>
    80002e7e:	963fd0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80002e82:	00005517          	auipc	a0,0x5
    80002e86:	69e50513          	addi	a0,a0,1694 # 80008520 <etext+0x520>
    80002e8a:	957fd0ef          	jal	800007e0 <panic>

0000000080002e8e <yield>:
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	e426                	sd	s1,8(sp)
    80002e96:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002e98:	d90ff0ef          	jal	80002428 <myproc>
    80002e9c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002e9e:	d31fd0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80002ea2:	478d                	li	a5,3
    80002ea4:	cc9c                	sw	a5,24(s1)
  sched();
    80002ea6:	f2fff0ef          	jal	80002dd4 <sched>
  release(&p->lock);
    80002eaa:	8526                	mv	a0,s1
    80002eac:	dc9fd0ef          	jal	80000c74 <release>
}
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002eba:	7179                	addi	sp,sp,-48
    80002ebc:	f406                	sd	ra,40(sp)
    80002ebe:	f022                	sd	s0,32(sp)
    80002ec0:	ec26                	sd	s1,24(sp)
    80002ec2:	e84a                	sd	s2,16(sp)
    80002ec4:	e44e                	sd	s3,8(sp)
    80002ec6:	1800                	addi	s0,sp,48
    80002ec8:	89aa                	mv	s3,a0
    80002eca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ecc:	d5cff0ef          	jal	80002428 <myproc>
    80002ed0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002ed2:	cfdfd0ef          	jal	80000bce <acquire>
  release(lk);
    80002ed6:	854a                	mv	a0,s2
    80002ed8:	d9dfd0ef          	jal	80000c74 <release>

  // Go to sleep.
  p->chan = chan;
    80002edc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002ee0:	4789                	li	a5,2
    80002ee2:	cc9c                	sw	a5,24(s1)

  sched();
    80002ee4:	ef1ff0ef          	jal	80002dd4 <sched>

  // Tidy up.
  p->chan = 0;
    80002ee8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002eec:	8526                	mv	a0,s1
    80002eee:	d87fd0ef          	jal	80000c74 <release>
  acquire(lk);
    80002ef2:	854a                	mv	a0,s2
    80002ef4:	cdbfd0ef          	jal	80000bce <acquire>
}
    80002ef8:	70a2                	ld	ra,40(sp)
    80002efa:	7402                	ld	s0,32(sp)
    80002efc:	64e2                	ld	s1,24(sp)
    80002efe:	6942                	ld	s2,16(sp)
    80002f00:	69a2                	ld	s3,8(sp)
    80002f02:	6145                	addi	sp,sp,48
    80002f04:	8082                	ret

0000000080002f06 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80002f06:	7139                	addi	sp,sp,-64
    80002f08:	fc06                	sd	ra,56(sp)
    80002f0a:	f822                	sd	s0,48(sp)
    80002f0c:	f426                	sd	s1,40(sp)
    80002f0e:	f04a                	sd	s2,32(sp)
    80002f10:	ec4e                	sd	s3,24(sp)
    80002f12:	e852                	sd	s4,16(sp)
    80002f14:	e456                	sd	s5,8(sp)
    80002f16:	e05a                	sd	s6,0(sp)
    80002f18:	0080                	addi	s0,sp,64
    80002f1a:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002f1c:	00011497          	auipc	s1,0x11
    80002f20:	01448493          	addi	s1,s1,20 # 80013f30 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002f24:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80002f26:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002f28:	6919                	lui	s2,0x6
    80002f2a:	44090913          	addi	s2,s2,1088 # 6440 <_entry-0x7fff9bc0>
    80002f2e:	001a2997          	auipc	s3,0x1a2
    80002f32:	00298993          	addi	s3,s3,2 # 801a4f30 <tickslock>
    80002f36:	a039                	j	80002f44 <wakeup+0x3e>
      }
      release(&p->lock);
    80002f38:	8526                	mv	a0,s1
    80002f3a:	d3bfd0ef          	jal	80000c74 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002f3e:	94ca                	add	s1,s1,s2
    80002f40:	03348263          	beq	s1,s3,80002f64 <wakeup+0x5e>
    if(p != myproc()){
    80002f44:	ce4ff0ef          	jal	80002428 <myproc>
    80002f48:	fea48be3          	beq	s1,a0,80002f3e <wakeup+0x38>
      acquire(&p->lock);
    80002f4c:	8526                	mv	a0,s1
    80002f4e:	c81fd0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002f52:	4c9c                	lw	a5,24(s1)
    80002f54:	ff4792e3          	bne	a5,s4,80002f38 <wakeup+0x32>
    80002f58:	709c                	ld	a5,32(s1)
    80002f5a:	fd579fe3          	bne	a5,s5,80002f38 <wakeup+0x32>
        p->state = RUNNABLE;
    80002f5e:	0164ac23          	sw	s6,24(s1)
    80002f62:	bfd9                	j	80002f38 <wakeup+0x32>
    }
  }
}
    80002f64:	70e2                	ld	ra,56(sp)
    80002f66:	7442                	ld	s0,48(sp)
    80002f68:	74a2                	ld	s1,40(sp)
    80002f6a:	7902                	ld	s2,32(sp)
    80002f6c:	69e2                	ld	s3,24(sp)
    80002f6e:	6a42                	ld	s4,16(sp)
    80002f70:	6aa2                	ld	s5,8(sp)
    80002f72:	6b02                	ld	s6,0(sp)
    80002f74:	6121                	addi	sp,sp,64
    80002f76:	8082                	ret

0000000080002f78 <reparent>:
{
    80002f78:	715d                	addi	sp,sp,-80
    80002f7a:	e486                	sd	ra,72(sp)
    80002f7c:	e0a2                	sd	s0,64(sp)
    80002f7e:	fc26                	sd	s1,56(sp)
    80002f80:	f84a                	sd	s2,48(sp)
    80002f82:	f44e                	sd	s3,40(sp)
    80002f84:	f052                	sd	s4,32(sp)
    80002f86:	ec56                	sd	s5,24(sp)
    80002f88:	e85a                	sd	s6,16(sp)
    80002f8a:	e45e                	sd	s7,8(sp)
    80002f8c:	0880                	addi	s0,sp,80
    80002f8e:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002f90:	00011497          	auipc	s1,0x11
    80002f94:	fa048493          	addi	s1,s1,-96 # 80013f30 <proc>
      pp->parent = initproc;
    80002f98:	00009b17          	auipc	s6,0x9
    80002f9c:	a38b0b13          	addi	s6,s6,-1480 # 8000b9d0 <initproc>
      if(isz)
    80002fa0:	4b95                	li	s7,5
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002fa2:	6919                	lui	s2,0x6
    80002fa4:	44090913          	addi	s2,s2,1088 # 6440 <_entry-0x7fff9bc0>
    80002fa8:	001a2a17          	auipc	s4,0x1a2
    80002fac:	f88a0a13          	addi	s4,s4,-120 # 801a4f30 <tickslock>
    80002fb0:	a831                	j	80002fcc <reparent+0x54>
      pp->parent = initproc;
    80002fb2:	000b3783          	ld	a5,0(s6)
    80002fb6:	fc9c                	sd	a5,56(s1)
      int isz = (pp->state == ZOMBIE);
    80002fb8:	0184aa83          	lw	s5,24(s1)
      release(&pp->lock);
    80002fbc:	8526                	mv	a0,s1
    80002fbe:	cb7fd0ef          	jal	80000c74 <release>
      if(isz)
    80002fc2:	017a8f63          	beq	s5,s7,80002fe0 <reparent+0x68>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002fc6:	94ca                	add	s1,s1,s2
    80002fc8:	03448163          	beq	s1,s4,80002fea <reparent+0x72>
    acquire(&pp->lock);
    80002fcc:	8526                	mv	a0,s1
    80002fce:	c01fd0ef          	jal	80000bce <acquire>
    if(pp->parent == p){
    80002fd2:	7c9c                	ld	a5,56(s1)
    80002fd4:	fd378fe3          	beq	a5,s3,80002fb2 <reparent+0x3a>
      release(&pp->lock);
    80002fd8:	8526                	mv	a0,s1
    80002fda:	c9bfd0ef          	jal	80000c74 <release>
    80002fde:	b7e5                	j	80002fc6 <reparent+0x4e>
        wakeup(initproc);
    80002fe0:	000b3503          	ld	a0,0(s6)
    80002fe4:	f23ff0ef          	jal	80002f06 <wakeup>
    80002fe8:	bff9                	j	80002fc6 <reparent+0x4e>
}
    80002fea:	60a6                	ld	ra,72(sp)
    80002fec:	6406                	ld	s0,64(sp)
    80002fee:	74e2                	ld	s1,56(sp)
    80002ff0:	7942                	ld	s2,48(sp)
    80002ff2:	79a2                	ld	s3,40(sp)
    80002ff4:	7a02                	ld	s4,32(sp)
    80002ff6:	6ae2                	ld	s5,24(sp)
    80002ff8:	6b42                	ld	s6,16(sp)
    80002ffa:	6ba2                	ld	s7,8(sp)
    80002ffc:	6161                	addi	sp,sp,80
    80002ffe:	8082                	ret

0000000080003000 <kexit>:
{
    80003000:	7179                	addi	sp,sp,-48
    80003002:	f406                	sd	ra,40(sp)
    80003004:	f022                	sd	s0,32(sp)
    80003006:	ec26                	sd	s1,24(sp)
    80003008:	e84a                	sd	s2,16(sp)
    8000300a:	e44e                	sd	s3,8(sp)
    8000300c:	e052                	sd	s4,0(sp)
    8000300e:	1800                	addi	s0,sp,48
    80003010:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80003012:	c16ff0ef          	jal	80002428 <myproc>
    80003016:	89aa                	mv	s3,a0
  if(p == initproc)
    80003018:	00009797          	auipc	a5,0x9
    8000301c:	9b87b783          	ld	a5,-1608(a5) # 8000b9d0 <initproc>
    80003020:	0d050493          	addi	s1,a0,208
    80003024:	15050913          	addi	s2,a0,336
    80003028:	00a79f63          	bne	a5,a0,80003046 <kexit+0x46>
    panic("init exiting");
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	50c50513          	addi	a0,a0,1292 # 80008538 <etext+0x538>
    80003034:	facfd0ef          	jal	800007e0 <panic>
      fileclose(f);
    80003038:	35c020ef          	jal	80005394 <fileclose>
      p->ofile[fd] = 0;
    8000303c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003040:	04a1                	addi	s1,s1,8
    80003042:	01248563          	beq	s1,s2,8000304c <kexit+0x4c>
    if(p->ofile[fd]){
    80003046:	6088                	ld	a0,0(s1)
    80003048:	f965                	bnez	a0,80003038 <kexit+0x38>
    8000304a:	bfdd                	j	80003040 <kexit+0x40>
  begin_op();
    8000304c:	73d010ef          	jal	80004f88 <begin_op>
  iput(p->cwd);
    80003050:	1509b503          	ld	a0,336(s3)
    80003054:	6cc010ef          	jal	80004720 <iput>
  end_op();
    80003058:	79b010ef          	jal	80004ff2 <end_op>
  p->cwd = 0;
    8000305c:	1409b823          	sd	zero,336(s3)
  if(p->execip){
    80003060:	1909b783          	ld	a5,400(s3)
    80003064:	cb99                	beqz	a5,8000307a <kexit+0x7a>
    begin_op();
    80003066:	723010ef          	jal	80004f88 <begin_op>
    iput(p->execip);
    8000306a:	1909b503          	ld	a0,400(s3)
    8000306e:	6b2010ef          	jal	80004720 <iput>
    end_op();
    80003072:	781010ef          	jal	80004ff2 <end_op>
    p->execip = 0;
    80003076:	1809b823          	sd	zero,400(s3)
  proc_swapoff(p);
    8000307a:	854e                	mv	a0,s3
    8000307c:	ddeff0ef          	jal	8000265a <proc_swapoff>
  acquire(&wait_lock);
    80003080:	00011497          	auipc	s1,0x11
    80003084:	a8048493          	addi	s1,s1,-1408 # 80013b00 <wait_lock>
    80003088:	8526                	mv	a0,s1
    8000308a:	b45fd0ef          	jal	80000bce <acquire>
  reparent(p);
    8000308e:	854e                	mv	a0,s3
    80003090:	ee9ff0ef          	jal	80002f78 <reparent>
  wakeup(p->parent);
    80003094:	0389b503          	ld	a0,56(s3)
    80003098:	e6fff0ef          	jal	80002f06 <wakeup>
  acquire(&p->lock);
    8000309c:	854e                	mv	a0,s3
    8000309e:	b31fd0ef          	jal	80000bce <acquire>
  p->xstate = status;
    800030a2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800030a6:	4795                	li	a5,5
    800030a8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800030ac:	8526                	mv	a0,s1
    800030ae:	bc7fd0ef          	jal	80000c74 <release>
  sched();
    800030b2:	d23ff0ef          	jal	80002dd4 <sched>
  panic("zombie exit");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	49250513          	addi	a0,a0,1170 # 80008548 <etext+0x548>
    800030be:	f22fd0ef          	jal	800007e0 <panic>

00000000800030c2 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800030c2:	7179                	addi	sp,sp,-48
    800030c4:	f406                	sd	ra,40(sp)
    800030c6:	f022                	sd	s0,32(sp)
    800030c8:	ec26                	sd	s1,24(sp)
    800030ca:	e84a                	sd	s2,16(sp)
    800030cc:	e44e                	sd	s3,8(sp)
    800030ce:	e052                	sd	s4,0(sp)
    800030d0:	1800                	addi	s0,sp,48
    800030d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800030d4:	00011497          	auipc	s1,0x11
    800030d8:	e5c48493          	addi	s1,s1,-420 # 80013f30 <proc>
    800030dc:	6999                	lui	s3,0x6
    800030de:	44098993          	addi	s3,s3,1088 # 6440 <_entry-0x7fff9bc0>
    800030e2:	001a2a17          	auipc	s4,0x1a2
    800030e6:	e4ea0a13          	addi	s4,s4,-434 # 801a4f30 <tickslock>
    acquire(&p->lock);
    800030ea:	8526                	mv	a0,s1
    800030ec:	ae3fd0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    800030f0:	589c                	lw	a5,48(s1)
    800030f2:	01278a63          	beq	a5,s2,80003106 <kkill+0x44>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800030f6:	8526                	mv	a0,s1
    800030f8:	b7dfd0ef          	jal	80000c74 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800030fc:	94ce                	add	s1,s1,s3
    800030fe:	ff4496e3          	bne	s1,s4,800030ea <kkill+0x28>
  }
  return -1;
    80003102:	557d                	li	a0,-1
    80003104:	a819                	j	8000311a <kkill+0x58>
      p->killed = 1;
    80003106:	4785                	li	a5,1
    80003108:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000310a:	4c98                	lw	a4,24(s1)
    8000310c:	4789                	li	a5,2
    8000310e:	00f70e63          	beq	a4,a5,8000312a <kkill+0x68>
      release(&p->lock);
    80003112:	8526                	mv	a0,s1
    80003114:	b61fd0ef          	jal	80000c74 <release>
      return 0;
    80003118:	4501                	li	a0,0
}
    8000311a:	70a2                	ld	ra,40(sp)
    8000311c:	7402                	ld	s0,32(sp)
    8000311e:	64e2                	ld	s1,24(sp)
    80003120:	6942                	ld	s2,16(sp)
    80003122:	69a2                	ld	s3,8(sp)
    80003124:	6a02                	ld	s4,0(sp)
    80003126:	6145                	addi	sp,sp,48
    80003128:	8082                	ret
        p->state = RUNNABLE;
    8000312a:	478d                	li	a5,3
    8000312c:	cc9c                	sw	a5,24(s1)
    8000312e:	b7d5                	j	80003112 <kkill+0x50>

0000000080003130 <setkilled>:

void
setkilled(struct proc *p)
{
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	e426                	sd	s1,8(sp)
    80003138:	1000                	addi	s0,sp,32
    8000313a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000313c:	a93fd0ef          	jal	80000bce <acquire>
  p->killed = 1;
    80003140:	4785                	li	a5,1
    80003142:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80003144:	8526                	mv	a0,s1
    80003146:	b2ffd0ef          	jal	80000c74 <release>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <killed>:

int
killed(struct proc *p)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	e04a                	sd	s2,0(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80003162:	a6dfd0ef          	jal	80000bce <acquire>
  k = p->killed;
    80003166:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000316a:	8526                	mv	a0,s1
    8000316c:	b09fd0ef          	jal	80000c74 <release>
  return k;
}
    80003170:	854a                	mv	a0,s2
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	64a2                	ld	s1,8(sp)
    80003178:	6902                	ld	s2,0(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <kwait>:
{
    8000317e:	715d                	addi	sp,sp,-80
    80003180:	e486                	sd	ra,72(sp)
    80003182:	e0a2                	sd	s0,64(sp)
    80003184:	fc26                	sd	s1,56(sp)
    80003186:	f84a                	sd	s2,48(sp)
    80003188:	f44e                	sd	s3,40(sp)
    8000318a:	f052                	sd	s4,32(sp)
    8000318c:	ec56                	sd	s5,24(sp)
    8000318e:	e85a                	sd	s6,16(sp)
    80003190:	e45e                	sd	s7,8(sp)
    80003192:	e062                	sd	s8,0(sp)
    80003194:	0880                	addi	s0,sp,80
    80003196:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80003198:	a90ff0ef          	jal	80002428 <myproc>
    8000319c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000319e:	00011517          	auipc	a0,0x11
    800031a2:	96250513          	addi	a0,a0,-1694 # 80013b00 <wait_lock>
    800031a6:	a29fd0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800031aa:	4a95                	li	s5,5
        havekids = 1;
    800031ac:	4b05                	li	s6,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800031ae:	6999                	lui	s3,0x6
    800031b0:	44098993          	addi	s3,s3,1088 # 6440 <_entry-0x7fff9bc0>
    800031b4:	001a2a17          	auipc	s4,0x1a2
    800031b8:	d7ca0a13          	addi	s4,s4,-644 # 801a4f30 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800031bc:	00011c17          	auipc	s8,0x11
    800031c0:	944c0c13          	addi	s8,s8,-1724 # 80013b00 <wait_lock>
    800031c4:	a869                	j	8000325e <kwait+0xe0>
          pid = pp->pid;
    800031c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800031ca:	000b8c63          	beqz	s7,800031e2 <kwait+0x64>
    800031ce:	4691                	li	a3,4
    800031d0:	02c48613          	addi	a2,s1,44
    800031d4:	85de                	mv	a1,s7
    800031d6:	05093503          	ld	a0,80(s2)
    800031da:	e41fe0ef          	jal	8000201a <copyout>
    800031de:	02054b63          	bltz	a0,80003214 <kwait+0x96>
          freeproc(pp);
    800031e2:	8526                	mv	a0,s1
    800031e4:	e8cff0ef          	jal	80002870 <freeproc>
          release(&pp->lock);
    800031e8:	8526                	mv	a0,s1
    800031ea:	a8bfd0ef          	jal	80000c74 <release>
          release(&wait_lock);
    800031ee:	00011517          	auipc	a0,0x11
    800031f2:	91250513          	addi	a0,a0,-1774 # 80013b00 <wait_lock>
    800031f6:	a7ffd0ef          	jal	80000c74 <release>
}
    800031fa:	854e                	mv	a0,s3
    800031fc:	60a6                	ld	ra,72(sp)
    800031fe:	6406                	ld	s0,64(sp)
    80003200:	74e2                	ld	s1,56(sp)
    80003202:	7942                	ld	s2,48(sp)
    80003204:	79a2                	ld	s3,40(sp)
    80003206:	7a02                	ld	s4,32(sp)
    80003208:	6ae2                	ld	s5,24(sp)
    8000320a:	6b42                	ld	s6,16(sp)
    8000320c:	6ba2                	ld	s7,8(sp)
    8000320e:	6c02                	ld	s8,0(sp)
    80003210:	6161                	addi	sp,sp,80
    80003212:	8082                	ret
            release(&pp->lock);
    80003214:	8526                	mv	a0,s1
    80003216:	a5ffd0ef          	jal	80000c74 <release>
            release(&wait_lock);
    8000321a:	00011517          	auipc	a0,0x11
    8000321e:	8e650513          	addi	a0,a0,-1818 # 80013b00 <wait_lock>
    80003222:	a53fd0ef          	jal	80000c74 <release>
            return -1;
    80003226:	59fd                	li	s3,-1
    80003228:	bfc9                	j	800031fa <kwait+0x7c>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000322a:	94ce                	add	s1,s1,s3
    8000322c:	03448063          	beq	s1,s4,8000324c <kwait+0xce>
      if(pp->parent == p){
    80003230:	7c9c                	ld	a5,56(s1)
    80003232:	ff279ce3          	bne	a5,s2,8000322a <kwait+0xac>
        acquire(&pp->lock);
    80003236:	8526                	mv	a0,s1
    80003238:	997fd0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    8000323c:	4c9c                	lw	a5,24(s1)
    8000323e:	f95784e3          	beq	a5,s5,800031c6 <kwait+0x48>
        release(&pp->lock);
    80003242:	8526                	mv	a0,s1
    80003244:	a31fd0ef          	jal	80000c74 <release>
        havekids = 1;
    80003248:	875a                	mv	a4,s6
    8000324a:	b7c5                	j	8000322a <kwait+0xac>
    if(!havekids || killed(p)){
    8000324c:	cf19                	beqz	a4,8000326a <kwait+0xec>
    8000324e:	854a                	mv	a0,s2
    80003250:	f05ff0ef          	jal	80003154 <killed>
    80003254:	e919                	bnez	a0,8000326a <kwait+0xec>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80003256:	85e2                	mv	a1,s8
    80003258:	854a                	mv	a0,s2
    8000325a:	c61ff0ef          	jal	80002eba <sleep>
    havekids = 0;
    8000325e:	4701                	li	a4,0
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80003260:	00011497          	auipc	s1,0x11
    80003264:	cd048493          	addi	s1,s1,-816 # 80013f30 <proc>
    80003268:	b7e1                	j	80003230 <kwait+0xb2>
      release(&wait_lock);
    8000326a:	00011517          	auipc	a0,0x11
    8000326e:	89650513          	addi	a0,a0,-1898 # 80013b00 <wait_lock>
    80003272:	a03fd0ef          	jal	80000c74 <release>
      return -1;
    80003276:	59fd                	li	s3,-1
    80003278:	b749                	j	800031fa <kwait+0x7c>

000000008000327a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000327a:	7179                	addi	sp,sp,-48
    8000327c:	f406                	sd	ra,40(sp)
    8000327e:	f022                	sd	s0,32(sp)
    80003280:	ec26                	sd	s1,24(sp)
    80003282:	e84a                	sd	s2,16(sp)
    80003284:	e44e                	sd	s3,8(sp)
    80003286:	e052                	sd	s4,0(sp)
    80003288:	1800                	addi	s0,sp,48
    8000328a:	84aa                	mv	s1,a0
    8000328c:	892e                	mv	s2,a1
    8000328e:	89b2                	mv	s3,a2
    80003290:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003292:	996ff0ef          	jal	80002428 <myproc>
  if(user_dst){
    80003296:	cc99                	beqz	s1,800032b4 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80003298:	86d2                	mv	a3,s4
    8000329a:	864e                	mv	a2,s3
    8000329c:	85ca                	mv	a1,s2
    8000329e:	6928                	ld	a0,80(a0)
    800032a0:	d7bfe0ef          	jal	8000201a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6942                	ld	s2,16(sp)
    800032ac:	69a2                	ld	s3,8(sp)
    800032ae:	6a02                	ld	s4,0(sp)
    800032b0:	6145                	addi	sp,sp,48
    800032b2:	8082                	ret
    memmove((char *)dst, src, len);
    800032b4:	000a061b          	sext.w	a2,s4
    800032b8:	85ce                	mv	a1,s3
    800032ba:	854a                	mv	a0,s2
    800032bc:	a51fd0ef          	jal	80000d0c <memmove>
    return 0;
    800032c0:	8526                	mv	a0,s1
    800032c2:	b7cd                	j	800032a4 <either_copyout+0x2a>

00000000800032c4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800032c4:	7179                	addi	sp,sp,-48
    800032c6:	f406                	sd	ra,40(sp)
    800032c8:	f022                	sd	s0,32(sp)
    800032ca:	ec26                	sd	s1,24(sp)
    800032cc:	e84a                	sd	s2,16(sp)
    800032ce:	e44e                	sd	s3,8(sp)
    800032d0:	e052                	sd	s4,0(sp)
    800032d2:	1800                	addi	s0,sp,48
    800032d4:	892a                	mv	s2,a0
    800032d6:	84ae                	mv	s1,a1
    800032d8:	89b2                	mv	s3,a2
    800032da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800032dc:	94cff0ef          	jal	80002428 <myproc>
  if(user_src){
    800032e0:	cc99                	beqz	s1,800032fe <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800032e2:	86d2                	mv	a3,s4
    800032e4:	864e                	mv	a2,s3
    800032e6:	85ca                	mv	a1,s2
    800032e8:	6928                	ld	a0,80(a0)
    800032ea:	e1dfe0ef          	jal	80002106 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800032ee:	70a2                	ld	ra,40(sp)
    800032f0:	7402                	ld	s0,32(sp)
    800032f2:	64e2                	ld	s1,24(sp)
    800032f4:	6942                	ld	s2,16(sp)
    800032f6:	69a2                	ld	s3,8(sp)
    800032f8:	6a02                	ld	s4,0(sp)
    800032fa:	6145                	addi	sp,sp,48
    800032fc:	8082                	ret
    memmove(dst, (char*)src, len);
    800032fe:	000a061b          	sext.w	a2,s4
    80003302:	85ce                	mv	a1,s3
    80003304:	854a                	mv	a0,s2
    80003306:	a07fd0ef          	jal	80000d0c <memmove>
    return 0;
    8000330a:	8526                	mv	a0,s1
    8000330c:	b7cd                	j	800032ee <either_copyin+0x2a>

000000008000330e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000330e:	715d                	addi	sp,sp,-80
    80003310:	e486                	sd	ra,72(sp)
    80003312:	e0a2                	sd	s0,64(sp)
    80003314:	fc26                	sd	s1,56(sp)
    80003316:	f84a                	sd	s2,48(sp)
    80003318:	f44e                	sd	s3,40(sp)
    8000331a:	f052                	sd	s4,32(sp)
    8000331c:	ec56                	sd	s5,24(sp)
    8000331e:	e85a                	sd	s6,16(sp)
    80003320:	e45e                	sd	s7,8(sp)
    80003322:	e062                	sd	s8,0(sp)
    80003324:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	ee250513          	addi	a0,a0,-286 # 80008208 <etext+0x208>
    8000332e:	9ccfd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003332:	00011497          	auipc	s1,0x11
    80003336:	d5648493          	addi	s1,s1,-682 # 80014088 <proc+0x158>
    8000333a:	001a2997          	auipc	s3,0x1a2
    8000333e:	d4e98993          	addi	s3,s3,-690 # 801a5088 <bcache+0x128>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003342:	4b95                	li	s7,5
      state = states[p->state];
    else
      state = "???";
    80003344:	00005a17          	auipc	s4,0x5
    80003348:	214a0a13          	addi	s4,s4,532 # 80008558 <etext+0x558>
    #if defined(CFS)
    printf("%d %s %s nice=%d vruntime=%ld", p->pid, state, p->name, p->nice, p->vruntime);
    #elif defined(FCFS)
    printf("%d %s %s (creation time: %ld)", p->pid, state, p->name, p->creation_time);
    #else
    printf("%d %s %s", p->pid, state, p->name);
    8000334c:	00005b17          	auipc	s6,0x5
    80003350:	214b0b13          	addi	s6,s6,532 # 80008560 <etext+0x560>
    #endif
    printf("\n");
    80003354:	00005a97          	auipc	s5,0x5
    80003358:	eb4a8a93          	addi	s5,s5,-332 # 80008208 <etext+0x208>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000335c:	00005c17          	auipc	s8,0x5
    80003360:	7acc0c13          	addi	s8,s8,1964 # 80008b08 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80003364:	6919                	lui	s2,0x6
    80003366:	44090913          	addi	s2,s2,1088 # 6440 <_entry-0x7fff9bc0>
    8000336a:	a821                	j	80003382 <procdump+0x74>
    printf("%d %s %s", p->pid, state, p->name);
    8000336c:	ed86a583          	lw	a1,-296(a3)
    80003370:	855a                	mv	a0,s6
    80003372:	988fd0ef          	jal	800004fa <printf>
    printf("\n");
    80003376:	8556                	mv	a0,s5
    80003378:	982fd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000337c:	94ca                	add	s1,s1,s2
    8000337e:	03348263          	beq	s1,s3,800033a2 <procdump+0x94>
    if(p->state == UNUSED)
    80003382:	86a6                	mv	a3,s1
    80003384:	ec04a783          	lw	a5,-320(s1)
    80003388:	dbf5                	beqz	a5,8000337c <procdump+0x6e>
      state = "???";
    8000338a:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000338c:	fefbe0e3          	bltu	s7,a5,8000336c <procdump+0x5e>
    80003390:	02079713          	slli	a4,a5,0x20
    80003394:	01d75793          	srli	a5,a4,0x1d
    80003398:	97e2                	add	a5,a5,s8
    8000339a:	6390                	ld	a2,0(a5)
    8000339c:	fa61                	bnez	a2,8000336c <procdump+0x5e>
      state = "???";
    8000339e:	8652                	mv	a2,s4
    800033a0:	b7f1                	j	8000336c <procdump+0x5e>
  }
}
    800033a2:	60a6                	ld	ra,72(sp)
    800033a4:	6406                	ld	s0,64(sp)
    800033a6:	74e2                	ld	s1,56(sp)
    800033a8:	7942                	ld	s2,48(sp)
    800033aa:	79a2                	ld	s3,40(sp)
    800033ac:	7a02                	ld	s4,32(sp)
    800033ae:	6ae2                	ld	s5,24(sp)
    800033b0:	6b42                	ld	s6,16(sp)
    800033b2:	6ba2                	ld	s7,8(sp)
    800033b4:	6c02                	ld	s8,0(sp)
    800033b6:	6161                	addi	sp,sp,80
    800033b8:	8082                	ret

00000000800033ba <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800033ba:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800033be:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800033c2:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800033c4:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800033c6:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800033ca:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800033ce:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800033d2:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800033d6:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800033da:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800033de:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800033e2:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800033e6:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800033ea:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800033ee:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800033f2:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800033f6:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800033f8:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800033fa:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800033fe:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80003402:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80003406:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    8000340a:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    8000340e:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80003412:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80003416:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    8000341a:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    8000341e:	0685bd83          	ld	s11,104(a1)
        
        ret
    80003422:	8082                	ret

0000000080003424 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003424:	1141                	addi	sp,sp,-16
    80003426:	e406                	sd	ra,8(sp)
    80003428:	e022                	sd	s0,0(sp)
    8000342a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000342c:	00005597          	auipc	a1,0x5
    80003430:	17458593          	addi	a1,a1,372 # 800085a0 <etext+0x5a0>
    80003434:	001a2517          	auipc	a0,0x1a2
    80003438:	afc50513          	addi	a0,a0,-1284 # 801a4f30 <tickslock>
    8000343c:	f12fd0ef          	jal	80000b4e <initlock>
}
    80003440:	60a2                	ld	ra,8(sp)
    80003442:	6402                	ld	s0,0(sp)
    80003444:	0141                	addi	sp,sp,16
    80003446:	8082                	ret

0000000080003448 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003448:	1141                	addi	sp,sp,-16
    8000344a:	e422                	sd	s0,8(sp)
    8000344c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000344e:	00003797          	auipc	a5,0x3
    80003452:	34278793          	addi	a5,a5,834 # 80006790 <kernelvec>
    80003456:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000345a:	6422                	ld	s0,8(sp)
    8000345c:	0141                	addi	sp,sp,16
    8000345e:	8082                	ret

0000000080003460 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80003460:	1141                	addi	sp,sp,-16
    80003462:	e406                	sd	ra,8(sp)
    80003464:	e022                	sd	s0,0(sp)
    80003466:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003468:	fc1fe0ef          	jal	80002428 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000346c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003470:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003472:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003476:	04000737          	lui	a4,0x4000
    8000347a:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000347c:	0732                	slli	a4,a4,0xc
    8000347e:	00004797          	auipc	a5,0x4
    80003482:	b8278793          	addi	a5,a5,-1150 # 80007000 <_trampoline>
    80003486:	00004697          	auipc	a3,0x4
    8000348a:	b7a68693          	addi	a3,a3,-1158 # 80007000 <_trampoline>
    8000348e:	8f95                	sub	a5,a5,a3
    80003490:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003492:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003496:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003498:	18002773          	csrr	a4,satp
    8000349c:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000349e:	6d38                	ld	a4,88(a0)
    800034a0:	613c                	ld	a5,64(a0)
    800034a2:	6685                	lui	a3,0x1
    800034a4:	97b6                	add	a5,a5,a3
    800034a6:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800034a8:	6d3c                	ld	a5,88(a0)
    800034aa:	00000717          	auipc	a4,0x0
    800034ae:	0f870713          	addi	a4,a4,248 # 800035a2 <usertrap>
    800034b2:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800034b4:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800034b6:	8712                	mv	a4,tp
    800034b8:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034ba:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800034be:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800034c2:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034c6:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800034ca:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800034cc:	6f9c                	ld	a5,24(a5)
    800034ce:	14179073          	csrw	sepc,a5
}
    800034d2:	60a2                	ld	ra,8(sp)
    800034d4:	6402                	ld	s0,0(sp)
    800034d6:	0141                	addi	sp,sp,16
    800034d8:	8082                	ret

00000000800034da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800034da:	1101                	addi	sp,sp,-32
    800034dc:	ec06                	sd	ra,24(sp)
    800034de:	e822                	sd	s0,16(sp)
    800034e0:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800034e2:	f1bfe0ef          	jal	800023fc <cpuid>
    800034e6:	cd11                	beqz	a0,80003502 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    800034e8:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800034ec:	000f4737          	lui	a4,0xf4
    800034f0:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800034f4:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800034f6:	14d79073          	csrw	stimecmp,a5
}
    800034fa:	60e2                	ld	ra,24(sp)
    800034fc:	6442                	ld	s0,16(sp)
    800034fe:	6105                	addi	sp,sp,32
    80003500:	8082                	ret
    80003502:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80003504:	001a2497          	auipc	s1,0x1a2
    80003508:	a2c48493          	addi	s1,s1,-1492 # 801a4f30 <tickslock>
    8000350c:	8526                	mv	a0,s1
    8000350e:	ec0fd0ef          	jal	80000bce <acquire>
    ticks++;
    80003512:	00008517          	auipc	a0,0x8
    80003516:	4c650513          	addi	a0,a0,1222 # 8000b9d8 <ticks>
    8000351a:	411c                	lw	a5,0(a0)
    8000351c:	2785                	addiw	a5,a5,1
    8000351e:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80003520:	9e7ff0ef          	jal	80002f06 <wakeup>
    release(&tickslock);
    80003524:	8526                	mv	a0,s1
    80003526:	f4efd0ef          	jal	80000c74 <release>
    8000352a:	64a2                	ld	s1,8(sp)
    8000352c:	bf75                	j	800034e8 <clockintr+0xe>

000000008000352e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003536:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    8000353a:	57fd                	li	a5,-1
    8000353c:	17fe                	slli	a5,a5,0x3f
    8000353e:	07a5                	addi	a5,a5,9
    80003540:	00f70c63          	beq	a4,a5,80003558 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80003544:	57fd                	li	a5,-1
    80003546:	17fe                	slli	a5,a5,0x3f
    80003548:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    8000354a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    8000354c:	04f70763          	beq	a4,a5,8000359a <devintr+0x6c>
  }
}
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret
    80003558:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    8000355a:	2e2030ef          	jal	8000683c <plic_claim>
    8000355e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003560:	47a9                	li	a5,10
    80003562:	00f50963          	beq	a0,a5,80003574 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80003566:	4785                	li	a5,1
    80003568:	00f50963          	beq	a0,a5,8000357a <devintr+0x4c>
    return 1;
    8000356c:	4505                	li	a0,1
    } else if(irq){
    8000356e:	e889                	bnez	s1,80003580 <devintr+0x52>
    80003570:	64a2                	ld	s1,8(sp)
    80003572:	bff9                	j	80003550 <devintr+0x22>
      uartintr();
    80003574:	c3cfd0ef          	jal	800009b0 <uartintr>
    if(irq)
    80003578:	a819                	j	8000358e <devintr+0x60>
      virtio_disk_intr();
    8000357a:	788030ef          	jal	80006d02 <virtio_disk_intr>
    if(irq)
    8000357e:	a801                	j	8000358e <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    80003580:	85a6                	mv	a1,s1
    80003582:	00005517          	auipc	a0,0x5
    80003586:	02650513          	addi	a0,a0,38 # 800085a8 <etext+0x5a8>
    8000358a:	f71fc0ef          	jal	800004fa <printf>
      plic_complete(irq);
    8000358e:	8526                	mv	a0,s1
    80003590:	2cc030ef          	jal	8000685c <plic_complete>
    return 1;
    80003594:	4505                	li	a0,1
    80003596:	64a2                	ld	s1,8(sp)
    80003598:	bf65                	j	80003550 <devintr+0x22>
    clockintr();
    8000359a:	f41ff0ef          	jal	800034da <clockintr>
    return 2;
    8000359e:	4509                	li	a0,2
    800035a0:	bf45                	j	80003550 <devintr+0x22>

00000000800035a2 <usertrap>:
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035aa:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800035ae:	1007f793          	andi	a5,a5,256
    800035b2:	e7c5                	bnez	a5,8000365a <usertrap+0xb8>
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
  asm volatile("csrw stvec, %0" : : "r" (x));
    800035b8:	00003797          	auipc	a5,0x3
    800035bc:	1d878793          	addi	a5,a5,472 # 80006790 <kernelvec>
    800035c0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800035c4:	e65fe0ef          	jal	80002428 <myproc>
    800035c8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800035ca:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035cc:	14102773          	csrr	a4,sepc
    800035d0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035d2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800035d6:	47a1                	li	a5,8
    800035d8:	08f70b63          	beq	a4,a5,8000366e <usertrap+0xcc>
  } else if((which_dev = devintr()) != 0){
    800035dc:	f53ff0ef          	jal	8000352e <devintr>
    800035e0:	892a                	mv	s2,a0
    800035e2:	12051763          	bnez	a0,80003710 <usertrap+0x16e>
    800035e6:	14202773          	csrr	a4,scause
  } else if(r_scause() == 12 || r_scause() == 15 || r_scause() == 13){
    800035ea:	47b1                	li	a5,12
    800035ec:	00f70c63          	beq	a4,a5,80003604 <usertrap+0x62>
    800035f0:	14202773          	csrr	a4,scause
    800035f4:	47bd                	li	a5,15
    800035f6:	00f70763          	beq	a4,a5,80003604 <usertrap+0x62>
    800035fa:	14202773          	csrr	a4,scause
    800035fe:	47b5                	li	a5,13
    80003600:	0ef71163          	bne	a4,a5,800036e2 <usertrap+0x140>
    80003604:	e44e                	sd	s3,8(sp)
    80003606:	14202773          	csrr	a4,scause
    int acc = (r_scause() == 12 ? -1 : (r_scause() == 15 ? 1 : 0)); // -1 exec, 0 read, 1 write
    8000360a:	47b1                	li	a5,12
    8000360c:	597d                	li	s2,-1
    8000360e:	00f70763          	beq	a4,a5,8000361c <usertrap+0x7a>
    80003612:	14202973          	csrr	s2,scause
    80003616:	1945                	addi	s2,s2,-15
    80003618:	00193913          	seqz	s2,s2
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000361c:	143029f3          	csrr	s3,stval
    uint64 pa = vmfault(p->pagetable, stval, acc);
    80003620:	864a                	mv	a2,s2
    80003622:	85ce                	mv	a1,s3
    80003624:	68a8                	ld	a0,80(s1)
    80003626:	b14fe0ef          	jal	8000193a <vmfault>
    if(pa == 0){
    8000362a:	10051263          	bnez	a0,8000372e <usertrap+0x18c>
    8000362e:	e052                	sd	s4,0(sp)
      const char *access = (acc == -1 ? "exec" : (acc == 1 ? "write" : "read"));
    80003630:	57fd                	li	a5,-1
    80003632:	00005a17          	auipc	s4,0x5
    80003636:	d3ea0a13          	addi	s4,s4,-706 # 80008370 <etext+0x370>
    8000363a:	00f90963          	beq	s2,a5,8000364c <usertrap+0xaa>
    8000363e:	4785                	li	a5,1
    80003640:	00005a17          	auipc	s4,0x5
    80003644:	230a0a13          	addi	s4,s4,560 # 80008870 <etext+0x870>
    80003648:	06f90763          	beq	s2,a5,800036b6 <usertrap+0x114>
      if(!killed(p)){
    8000364c:	8526                	mv	a0,s1
    8000364e:	b07ff0ef          	jal	80003154 <killed>
    80003652:	c53d                	beqz	a0,800036c0 <usertrap+0x11e>
    80003654:	69a2                	ld	s3,8(sp)
    80003656:	6a02                	ld	s4,0(sp)
    80003658:	a815                	j	8000368c <usertrap+0xea>
    8000365a:	ec26                	sd	s1,24(sp)
    8000365c:	e84a                	sd	s2,16(sp)
    8000365e:	e44e                	sd	s3,8(sp)
    80003660:	e052                	sd	s4,0(sp)
    panic("usertrap: not from user mode");
    80003662:	00005517          	auipc	a0,0x5
    80003666:	f6650513          	addi	a0,a0,-154 # 800085c8 <etext+0x5c8>
    8000366a:	976fd0ef          	jal	800007e0 <panic>
    if(killed(p))
    8000366e:	ae7ff0ef          	jal	80003154 <killed>
    80003672:	ed15                	bnez	a0,800036ae <usertrap+0x10c>
    p->trapframe->epc += 4;
    80003674:	6cb8                	ld	a4,88(s1)
    80003676:	6f1c                	ld	a5,24(a4)
    80003678:	0791                	addi	a5,a5,4
    8000367a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000367c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003680:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003684:	10079073          	csrw	sstatus,a5
    syscall();
    80003688:	28c000ef          	jal	80003914 <syscall>
  if(killed(p))
    8000368c:	8526                	mv	a0,s1
    8000368e:	ac7ff0ef          	jal	80003154 <killed>
    80003692:	e541                	bnez	a0,8000371a <usertrap+0x178>
  prepare_return();
    80003694:	dcdff0ef          	jal	80003460 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80003698:	68a8                	ld	a0,80(s1)
    8000369a:	8131                	srli	a0,a0,0xc
    8000369c:	57fd                	li	a5,-1
    8000369e:	17fe                	slli	a5,a5,0x3f
    800036a0:	8d5d                	or	a0,a0,a5
}
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	70a2                	ld	ra,40(sp)
    800036a8:	7402                	ld	s0,32(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret
      kexit(-1);
    800036ae:	557d                	li	a0,-1
    800036b0:	951ff0ef          	jal	80003000 <kexit>
    800036b4:	b7c1                	j	80003674 <usertrap+0xd2>
      const char *access = (acc == -1 ? "exec" : (acc == 1 ? "write" : "read"));
    800036b6:	00005a17          	auipc	s4,0x5
    800036ba:	cc2a0a13          	addi	s4,s4,-830 # 80008378 <etext+0x378>
    800036be:	b779                	j	8000364c <usertrap+0xaa>
        printf("[pid %d] KILL invalid-access va=0x%lx access=%s\n", p->pid, fva, access);
    800036c0:	86d2                	mv	a3,s4
    800036c2:	767d                	lui	a2,0xfffff
    800036c4:	00c9f633          	and	a2,s3,a2
    800036c8:	588c                	lw	a1,48(s1)
    800036ca:	00005517          	auipc	a0,0x5
    800036ce:	f1e50513          	addi	a0,a0,-226 # 800085e8 <etext+0x5e8>
    800036d2:	e29fc0ef          	jal	800004fa <printf>
        setkilled(p);
    800036d6:	8526                	mv	a0,s1
    800036d8:	a59ff0ef          	jal	80003130 <setkilled>
    800036dc:	69a2                	ld	s3,8(sp)
    800036de:	6a02                	ld	s4,0(sp)
    800036e0:	b775                	j	8000368c <usertrap+0xea>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800036e2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800036e6:	5890                	lw	a2,48(s1)
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	f3850513          	addi	a0,a0,-200 # 80008620 <etext+0x620>
    800036f0:	e0bfc0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800036f4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800036f8:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	f5450513          	addi	a0,a0,-172 # 80008650 <etext+0x650>
    80003704:	df7fc0ef          	jal	800004fa <printf>
    setkilled(p);
    80003708:	8526                	mv	a0,s1
    8000370a:	a27ff0ef          	jal	80003130 <setkilled>
    8000370e:	bfbd                	j	8000368c <usertrap+0xea>
  if(killed(p))
    80003710:	8526                	mv	a0,s1
    80003712:	a43ff0ef          	jal	80003154 <killed>
    80003716:	c511                	beqz	a0,80003722 <usertrap+0x180>
    80003718:	a011                	j	8000371c <usertrap+0x17a>
    8000371a:	4901                	li	s2,0
    kexit(-1);
    8000371c:	557d                	li	a0,-1
    8000371e:	8e3ff0ef          	jal	80003000 <kexit>
  if(which_dev == 2)
    80003722:	4789                	li	a5,2
    80003724:	f6f918e3          	bne	s2,a5,80003694 <usertrap+0xf2>
    yield();
    80003728:	f66ff0ef          	jal	80002e8e <yield>
    8000372c:	b7a5                	j	80003694 <usertrap+0xf2>
    8000372e:	69a2                	ld	s3,8(sp)
    80003730:	bfb1                	j	8000368c <usertrap+0xea>

0000000080003732 <kerneltrap>:
{
    80003732:	7179                	addi	sp,sp,-48
    80003734:	f406                	sd	ra,40(sp)
    80003736:	f022                	sd	s0,32(sp)
    80003738:	ec26                	sd	s1,24(sp)
    8000373a:	e84a                	sd	s2,16(sp)
    8000373c:	e44e                	sd	s3,8(sp)
    8000373e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003740:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003744:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003748:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000374c:	1004f793          	andi	a5,s1,256
    80003750:	c795                	beqz	a5,8000377c <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003752:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003756:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003758:	eb85                	bnez	a5,80003788 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000375a:	dd5ff0ef          	jal	8000352e <devintr>
    8000375e:	c91d                	beqz	a0,80003794 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80003760:	4789                	li	a5,2
    80003762:	04f50a63          	beq	a0,a5,800037b6 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003766:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000376a:	10049073          	csrw	sstatus,s1
}
    8000376e:	70a2                	ld	ra,40(sp)
    80003770:	7402                	ld	s0,32(sp)
    80003772:	64e2                	ld	s1,24(sp)
    80003774:	6942                	ld	s2,16(sp)
    80003776:	69a2                	ld	s3,8(sp)
    80003778:	6145                	addi	sp,sp,48
    8000377a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	efc50513          	addi	a0,a0,-260 # 80008678 <etext+0x678>
    80003784:	85cfd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80003788:	00005517          	auipc	a0,0x5
    8000378c:	f1850513          	addi	a0,a0,-232 # 800086a0 <etext+0x6a0>
    80003790:	850fd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003794:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003798:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000379c:	85ce                	mv	a1,s3
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	f2250513          	addi	a0,a0,-222 # 800086c0 <etext+0x6c0>
    800037a6:	d55fc0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800037aa:	00005517          	auipc	a0,0x5
    800037ae:	f3e50513          	addi	a0,a0,-194 # 800086e8 <etext+0x6e8>
    800037b2:	82efd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    800037b6:	c73fe0ef          	jal	80002428 <myproc>
    800037ba:	d555                	beqz	a0,80003766 <kerneltrap+0x34>
    yield();
    800037bc:	ed2ff0ef          	jal	80002e8e <yield>
    800037c0:	b75d                	j	80003766 <kerneltrap+0x34>

00000000800037c2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800037c2:	1101                	addi	sp,sp,-32
    800037c4:	ec06                	sd	ra,24(sp)
    800037c6:	e822                	sd	s0,16(sp)
    800037c8:	e426                	sd	s1,8(sp)
    800037ca:	1000                	addi	s0,sp,32
    800037cc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800037ce:	c5bfe0ef          	jal	80002428 <myproc>
  switch (n) {
    800037d2:	4795                	li	a5,5
    800037d4:	0497e163          	bltu	a5,s1,80003816 <argraw+0x54>
    800037d8:	048a                	slli	s1,s1,0x2
    800037da:	00005717          	auipc	a4,0x5
    800037de:	3fe70713          	addi	a4,a4,1022 # 80008bd8 <nice_to_weight+0xa0>
    800037e2:	94ba                	add	s1,s1,a4
    800037e4:	409c                	lw	a5,0(s1)
    800037e6:	97ba                	add	a5,a5,a4
    800037e8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800037ea:	6d3c                	ld	a5,88(a0)
    800037ec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6105                	addi	sp,sp,32
    800037f6:	8082                	ret
    return p->trapframe->a1;
    800037f8:	6d3c                	ld	a5,88(a0)
    800037fa:	7fa8                	ld	a0,120(a5)
    800037fc:	bfcd                	j	800037ee <argraw+0x2c>
    return p->trapframe->a2;
    800037fe:	6d3c                	ld	a5,88(a0)
    80003800:	63c8                	ld	a0,128(a5)
    80003802:	b7f5                	j	800037ee <argraw+0x2c>
    return p->trapframe->a3;
    80003804:	6d3c                	ld	a5,88(a0)
    80003806:	67c8                	ld	a0,136(a5)
    80003808:	b7dd                	j	800037ee <argraw+0x2c>
    return p->trapframe->a4;
    8000380a:	6d3c                	ld	a5,88(a0)
    8000380c:	6bc8                	ld	a0,144(a5)
    8000380e:	b7c5                	j	800037ee <argraw+0x2c>
    return p->trapframe->a5;
    80003810:	6d3c                	ld	a5,88(a0)
    80003812:	6fc8                	ld	a0,152(a5)
    80003814:	bfe9                	j	800037ee <argraw+0x2c>
  panic("argraw");
    80003816:	00005517          	auipc	a0,0x5
    8000381a:	ee250513          	addi	a0,a0,-286 # 800086f8 <etext+0x6f8>
    8000381e:	fc3fc0ef          	jal	800007e0 <panic>

0000000080003822 <fetchaddr>:
{
    80003822:	1101                	addi	sp,sp,-32
    80003824:	ec06                	sd	ra,24(sp)
    80003826:	e822                	sd	s0,16(sp)
    80003828:	e426                	sd	s1,8(sp)
    8000382a:	e04a                	sd	s2,0(sp)
    8000382c:	1000                	addi	s0,sp,32
    8000382e:	84aa                	mv	s1,a0
    80003830:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003832:	bf7fe0ef          	jal	80002428 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003836:	653c                	ld	a5,72(a0)
    80003838:	02f4f663          	bgeu	s1,a5,80003864 <fetchaddr+0x42>
    8000383c:	00848713          	addi	a4,s1,8
    80003840:	02e7e463          	bltu	a5,a4,80003868 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003844:	46a1                	li	a3,8
    80003846:	8626                	mv	a2,s1
    80003848:	85ca                	mv	a1,s2
    8000384a:	6928                	ld	a0,80(a0)
    8000384c:	8bbfe0ef          	jal	80002106 <copyin>
    80003850:	00a03533          	snez	a0,a0
    80003854:	40a00533          	neg	a0,a0
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6902                	ld	s2,0(sp)
    80003860:	6105                	addi	sp,sp,32
    80003862:	8082                	ret
    return -1;
    80003864:	557d                	li	a0,-1
    80003866:	bfcd                	j	80003858 <fetchaddr+0x36>
    80003868:	557d                	li	a0,-1
    8000386a:	b7fd                	j	80003858 <fetchaddr+0x36>

000000008000386c <fetchstr>:
{
    8000386c:	7179                	addi	sp,sp,-48
    8000386e:	f406                	sd	ra,40(sp)
    80003870:	f022                	sd	s0,32(sp)
    80003872:	ec26                	sd	s1,24(sp)
    80003874:	e84a                	sd	s2,16(sp)
    80003876:	e44e                	sd	s3,8(sp)
    80003878:	1800                	addi	s0,sp,48
    8000387a:	892a                	mv	s2,a0
    8000387c:	84ae                	mv	s1,a1
    8000387e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003880:	ba9fe0ef          	jal	80002428 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003884:	86ce                	mv	a3,s3
    80003886:	864a                	mv	a2,s2
    80003888:	85a6                	mv	a1,s1
    8000388a:	6928                	ld	a0,80(a0)
    8000388c:	911fe0ef          	jal	8000219c <copyinstr>
    80003890:	00054c63          	bltz	a0,800038a8 <fetchstr+0x3c>
  return strlen(buf);
    80003894:	8526                	mv	a0,s1
    80003896:	d8afd0ef          	jal	80000e20 <strlen>
}
    8000389a:	70a2                	ld	ra,40(sp)
    8000389c:	7402                	ld	s0,32(sp)
    8000389e:	64e2                	ld	s1,24(sp)
    800038a0:	6942                	ld	s2,16(sp)
    800038a2:	69a2                	ld	s3,8(sp)
    800038a4:	6145                	addi	sp,sp,48
    800038a6:	8082                	ret
    return -1;
    800038a8:	557d                	li	a0,-1
    800038aa:	bfc5                	j	8000389a <fetchstr+0x2e>

00000000800038ac <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	1000                	addi	s0,sp,32
    800038b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800038b8:	f0bff0ef          	jal	800037c2 <argraw>
    800038bc:	c088                	sw	a0,0(s1)
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6105                	addi	sp,sp,32
    800038c6:	8082                	ret

00000000800038c8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800038c8:	1101                	addi	sp,sp,-32
    800038ca:	ec06                	sd	ra,24(sp)
    800038cc:	e822                	sd	s0,16(sp)
    800038ce:	e426                	sd	s1,8(sp)
    800038d0:	1000                	addi	s0,sp,32
    800038d2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800038d4:	eefff0ef          	jal	800037c2 <argraw>
    800038d8:	e088                	sd	a0,0(s1)
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret

00000000800038e4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800038e4:	7179                	addi	sp,sp,-48
    800038e6:	f406                	sd	ra,40(sp)
    800038e8:	f022                	sd	s0,32(sp)
    800038ea:	ec26                	sd	s1,24(sp)
    800038ec:	e84a                	sd	s2,16(sp)
    800038ee:	1800                	addi	s0,sp,48
    800038f0:	84ae                	mv	s1,a1
    800038f2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800038f4:	fd840593          	addi	a1,s0,-40
    800038f8:	fd1ff0ef          	jal	800038c8 <argaddr>
  return fetchstr(addr, buf, max);
    800038fc:	864a                	mv	a2,s2
    800038fe:	85a6                	mv	a1,s1
    80003900:	fd843503          	ld	a0,-40(s0)
    80003904:	f69ff0ef          	jal	8000386c <fetchstr>
}
    80003908:	70a2                	ld	ra,40(sp)
    8000390a:	7402                	ld	s0,32(sp)
    8000390c:	64e2                	ld	s1,24(sp)
    8000390e:	6942                	ld	s2,16(sp)
    80003910:	6145                	addi	sp,sp,48
    80003912:	8082                	ret

0000000080003914 <syscall>:
[SYS_memstat] sys_memstat,
};

void
syscall(void)
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	e426                	sd	s1,8(sp)
    8000391c:	e04a                	sd	s2,0(sp)
    8000391e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003920:	b09fe0ef          	jal	80002428 <myproc>
    80003924:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003926:	05853903          	ld	s2,88(a0)
    8000392a:	0a893783          	ld	a5,168(s2)
    8000392e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003932:	37fd                	addiw	a5,a5,-1
    80003934:	4759                	li	a4,22
    80003936:	00f76f63          	bltu	a4,a5,80003954 <syscall+0x40>
    8000393a:	00369713          	slli	a4,a3,0x3
    8000393e:	00005797          	auipc	a5,0x5
    80003942:	2b278793          	addi	a5,a5,690 # 80008bf0 <syscalls>
    80003946:	97ba                	add	a5,a5,a4
    80003948:	639c                	ld	a5,0(a5)
    8000394a:	c789                	beqz	a5,80003954 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000394c:	9782                	jalr	a5
    8000394e:	06a93823          	sd	a0,112(s2)
    80003952:	a829                	j	8000396c <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003954:	15848613          	addi	a2,s1,344
    80003958:	588c                	lw	a1,48(s1)
    8000395a:	00005517          	auipc	a0,0x5
    8000395e:	da650513          	addi	a0,a0,-602 # 80008700 <etext+0x700>
    80003962:	b99fc0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003966:	6cbc                	ld	a5,88(s1)
    80003968:	577d                	li	a4,-1
    8000396a:	fbb8                	sd	a4,112(a5)
  }
}
    8000396c:	60e2                	ld	ra,24(sp)
    8000396e:	6442                	ld	s0,16(sp)
    80003970:	64a2                	ld	s1,8(sp)
    80003972:	6902                	ld	s2,0(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret

0000000080003978 <syscall_init>:

// Initialize the read count lock (called from main)
void
syscall_init(void)
{
    80003978:	1141                	addi	sp,sp,-16
    8000397a:	e406                	sd	ra,8(sp)
    8000397c:	e022                	sd	s0,0(sp)
    8000397e:	0800                	addi	s0,sp,16
  initlock(&read_count_lock, "read_count");
    80003980:	00005597          	auipc	a1,0x5
    80003984:	da058593          	addi	a1,a1,-608 # 80008720 <etext+0x720>
    80003988:	001a1517          	auipc	a0,0x1a1
    8000398c:	5c050513          	addi	a0,a0,1472 # 801a4f48 <read_count_lock>
    80003990:	9befd0ef          	jal	80000b4e <initlock>
}
    80003994:	60a2                	ld	ra,8(sp)
    80003996:	6402                	ld	s0,0(sp)
    80003998:	0141                	addi	sp,sp,16
    8000399a:	8082                	ret

000000008000399c <update_read_count>:

// Update read count (called from sys_read)
void
update_read_count(int bytes)
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	e04a                	sd	s2,0(sp)
    800039a6:	1000                	addi	s0,sp,32
    800039a8:	84aa                	mv	s1,a0
  acquire(&read_count_lock);
    800039aa:	001a1917          	auipc	s2,0x1a1
    800039ae:	59e90913          	addi	s2,s2,1438 # 801a4f48 <read_count_lock>
    800039b2:	854a                	mv	a0,s2
    800039b4:	a1afd0ef          	jal	80000bce <acquire>
  read_count += bytes;
    800039b8:	00008717          	auipc	a4,0x8
    800039bc:	02870713          	addi	a4,a4,40 # 8000b9e0 <read_count>
    800039c0:	631c                	ld	a5,0(a4)
    800039c2:	00978533          	add	a0,a5,s1
    800039c6:	e308                	sd	a0,0(a4)
  release(&read_count_lock);
    800039c8:	854a                	mv	a0,s2
    800039ca:	aaafd0ef          	jal	80000c74 <release>
}
    800039ce:	60e2                	ld	ra,24(sp)
    800039d0:	6442                	ld	s0,16(sp)
    800039d2:	64a2                	ld	s1,8(sp)
    800039d4:	6902                	ld	s2,0(sp)
    800039d6:	6105                	addi	sp,sp,32
    800039d8:	8082                	ret

00000000800039da <sys_exit>:
#include "vm.h"
#include "memstat.h"

uint64
sys_exit(void)
{
    800039da:	1101                	addi	sp,sp,-32
    800039dc:	ec06                	sd	ra,24(sp)
    800039de:	e822                	sd	s0,16(sp)
    800039e0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800039e2:	fec40593          	addi	a1,s0,-20
    800039e6:	4501                	li	a0,0
    800039e8:	ec5ff0ef          	jal	800038ac <argint>
  kexit(n);
    800039ec:	fec42503          	lw	a0,-20(s0)
    800039f0:	e10ff0ef          	jal	80003000 <kexit>
  return 0;  // not reached
}
    800039f4:	4501                	li	a0,0
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret

00000000800039fe <sys_getpid>:

uint64
sys_getpid(void)
{
    800039fe:	1141                	addi	sp,sp,-16
    80003a00:	e406                	sd	ra,8(sp)
    80003a02:	e022                	sd	s0,0(sp)
    80003a04:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003a06:	a23fe0ef          	jal	80002428 <myproc>
}
    80003a0a:	5908                	lw	a0,48(a0)
    80003a0c:	60a2                	ld	ra,8(sp)
    80003a0e:	6402                	ld	s0,0(sp)
    80003a10:	0141                	addi	sp,sp,16
    80003a12:	8082                	ret

0000000080003a14 <sys_fork>:

uint64
sys_fork(void)
{
    80003a14:	1141                	addi	sp,sp,-16
    80003a16:	e406                	sd	ra,8(sp)
    80003a18:	e022                	sd	s0,0(sp)
    80003a1a:	0800                	addi	s0,sp,16
  return kfork();
    80003a1c:	8dcff0ef          	jal	80002af8 <kfork>
}
    80003a20:	60a2                	ld	ra,8(sp)
    80003a22:	6402                	ld	s0,0(sp)
    80003a24:	0141                	addi	sp,sp,16
    80003a26:	8082                	ret

0000000080003a28 <sys_wait>:

uint64
sys_wait(void)
{
    80003a28:	1101                	addi	sp,sp,-32
    80003a2a:	ec06                	sd	ra,24(sp)
    80003a2c:	e822                	sd	s0,16(sp)
    80003a2e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003a30:	fe840593          	addi	a1,s0,-24
    80003a34:	4501                	li	a0,0
    80003a36:	e93ff0ef          	jal	800038c8 <argaddr>
  return kwait(p);
    80003a3a:	fe843503          	ld	a0,-24(s0)
    80003a3e:	f40ff0ef          	jal	8000317e <kwait>
}
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	6105                	addi	sp,sp,32
    80003a48:	8082                	ret

0000000080003a4a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003a4a:	7179                	addi	sp,sp,-48
    80003a4c:	f406                	sd	ra,40(sp)
    80003a4e:	f022                	sd	s0,32(sp)
    80003a50:	ec26                	sd	s1,24(sp)
    80003a52:	e84a                	sd	s2,16(sp)
    80003a54:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80003a56:	fd840593          	addi	a1,s0,-40
    80003a5a:	4501                	li	a0,0
    80003a5c:	e51ff0ef          	jal	800038ac <argint>
  argint(1, &t);
    80003a60:	fdc40593          	addi	a1,s0,-36
    80003a64:	4505                	li	a0,1
    80003a66:	e47ff0ef          	jal	800038ac <argint>
  struct proc *p = myproc();
    80003a6a:	9bffe0ef          	jal	80002428 <myproc>
    80003a6e:	84aa                	mv	s1,a0
  addr = p->sz;
    80003a70:	04853903          	ld	s2,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80003a74:	fdc42703          	lw	a4,-36(s0)
    80003a78:	4785                	li	a5,1
    80003a7a:	00f70b63          	beq	a4,a5,80003a90 <sys_sbrk+0x46>
    80003a7e:	fd842783          	lw	a5,-40(s0)
    80003a82:	0007c763          	bltz	a5,80003a90 <sys_sbrk+0x46>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80003a86:	97ca                	add	a5,a5,s2
    80003a88:	0727e963          	bltu	a5,s2,80003afa <sys_sbrk+0xb0>
      return -1;
    p->sz += n;
    80003a8c:	e53c                	sd	a5,72(a0)
    80003a8e:	a039                	j	80003a9c <sys_sbrk+0x52>
    if(growproc(n) < 0) {
    80003a90:	fd842503          	lw	a0,-40(s0)
    80003a94:	814ff0ef          	jal	80002aa8 <growproc>
    80003a98:	04054f63          	bltz	a0,80003af6 <sys_sbrk+0xac>
  }

  // Keep heap_brk consistent and clamped to the end of program segments.
  // Compute program end from recorded segments (lazy exec).
  uint64 prog_end = 0;
  for(int i = 0; i < p->nsegs; i++){
    80003a9c:	1984a583          	lw	a1,408(s1)
    80003aa0:	02b05463          	blez	a1,80003ac8 <sys_sbrk+0x7e>
    80003aa4:	87a6                	mv	a5,s1
    80003aa6:	0596                	slli	a1,a1,0x5
    80003aa8:	95a6                	add	a1,a1,s1
  uint64 prog_end = 0;
    80003aaa:	4601                	li	a2,0
    80003aac:	a029                	j	80003ab6 <sys_sbrk+0x6c>
  for(int i = 0; i < p->nsegs; i++){
    80003aae:	02078793          	addi	a5,a5,32
    80003ab2:	00b78c63          	beq	a5,a1,80003aca <sys_sbrk+0x80>
    uint64 end = p->segs[i].va + p->segs[i].memsz;
    80003ab6:	1a07b703          	ld	a4,416(a5)
    80003aba:	1a87b683          	ld	a3,424(a5)
    80003abe:	9736                	add	a4,a4,a3
    if(end > prog_end) prog_end = end;
    80003ac0:	fee677e3          	bgeu	a2,a4,80003aae <sys_sbrk+0x64>
    80003ac4:	863a                	mv	a2,a4
    80003ac6:	b7e5                	j	80003aae <sys_sbrk+0x64>
  uint64 prog_end = 0;
    80003ac8:	4601                	li	a2,0
  }
  // Update heap_brk by n and clamp to at least prog_end.
  // Upper bound is implicitly limited by p->sz (heap_brk < sz - stack/guard window).
  if(n != 0){
    80003aca:	fd842783          	lw	a5,-40(s0)
    80003ace:	cf89                	beqz	a5,80003ae8 <sys_sbrk+0x9e>
    long long newbrk = (long long)p->heap_brk + (long long)n;
    80003ad0:	1884b703          	ld	a4,392(s1)
    80003ad4:	97ba                	add	a5,a5,a4
    if(newbrk < (long long)prog_end)
    80003ad6:	00c7d363          	bge	a5,a2,80003adc <sys_sbrk+0x92>
    80003ada:	87b2                	mv	a5,a2
      newbrk = (long long)prog_end;
    // Also, avoid exceeding p->sz in pathological cases.
    if(newbrk > (long long)p->sz)
    80003adc:	64b8                	ld	a4,72(s1)
    80003ade:	00f75363          	bge	a4,a5,80003ae4 <sys_sbrk+0x9a>
    80003ae2:	87ba                	mv	a5,a4
      newbrk = (long long)p->sz;
    p->heap_brk = (uint64)newbrk;
    80003ae4:	18f4b423          	sd	a5,392(s1)
  }
  return addr;
}
    80003ae8:	854a                	mv	a0,s2
    80003aea:	70a2                	ld	ra,40(sp)
    80003aec:	7402                	ld	s0,32(sp)
    80003aee:	64e2                	ld	s1,24(sp)
    80003af0:	6942                	ld	s2,16(sp)
    80003af2:	6145                	addi	sp,sp,48
    80003af4:	8082                	ret
      return -1;
    80003af6:	597d                	li	s2,-1
    80003af8:	bfc5                	j	80003ae8 <sys_sbrk+0x9e>
      return -1;
    80003afa:	597d                	li	s2,-1
    80003afc:	b7f5                	j	80003ae8 <sys_sbrk+0x9e>

0000000080003afe <sys_pause>:

uint64
sys_pause(void)
{
    80003afe:	7139                	addi	sp,sp,-64
    80003b00:	fc06                	sd	ra,56(sp)
    80003b02:	f822                	sd	s0,48(sp)
    80003b04:	f04a                	sd	s2,32(sp)
    80003b06:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003b08:	fcc40593          	addi	a1,s0,-52
    80003b0c:	4501                	li	a0,0
    80003b0e:	d9fff0ef          	jal	800038ac <argint>
  if(n < 0)
    80003b12:	fcc42783          	lw	a5,-52(s0)
    80003b16:	0607c763          	bltz	a5,80003b84 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80003b1a:	001a1517          	auipc	a0,0x1a1
    80003b1e:	41650513          	addi	a0,a0,1046 # 801a4f30 <tickslock>
    80003b22:	8acfd0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80003b26:	00008917          	auipc	s2,0x8
    80003b2a:	eb292903          	lw	s2,-334(s2) # 8000b9d8 <ticks>
  while(ticks - ticks0 < n){
    80003b2e:	fcc42783          	lw	a5,-52(s0)
    80003b32:	cf8d                	beqz	a5,80003b6c <sys_pause+0x6e>
    80003b34:	f426                	sd	s1,40(sp)
    80003b36:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003b38:	001a1997          	auipc	s3,0x1a1
    80003b3c:	3f898993          	addi	s3,s3,1016 # 801a4f30 <tickslock>
    80003b40:	00008497          	auipc	s1,0x8
    80003b44:	e9848493          	addi	s1,s1,-360 # 8000b9d8 <ticks>
    if(killed(myproc())){
    80003b48:	8e1fe0ef          	jal	80002428 <myproc>
    80003b4c:	e08ff0ef          	jal	80003154 <killed>
    80003b50:	ed0d                	bnez	a0,80003b8a <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80003b52:	85ce                	mv	a1,s3
    80003b54:	8526                	mv	a0,s1
    80003b56:	b64ff0ef          	jal	80002eba <sleep>
  while(ticks - ticks0 < n){
    80003b5a:	409c                	lw	a5,0(s1)
    80003b5c:	412787bb          	subw	a5,a5,s2
    80003b60:	fcc42703          	lw	a4,-52(s0)
    80003b64:	fee7e2e3          	bltu	a5,a4,80003b48 <sys_pause+0x4a>
    80003b68:	74a2                	ld	s1,40(sp)
    80003b6a:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80003b6c:	001a1517          	auipc	a0,0x1a1
    80003b70:	3c450513          	addi	a0,a0,964 # 801a4f30 <tickslock>
    80003b74:	900fd0ef          	jal	80000c74 <release>
  return 0;
    80003b78:	4501                	li	a0,0
}
    80003b7a:	70e2                	ld	ra,56(sp)
    80003b7c:	7442                	ld	s0,48(sp)
    80003b7e:	7902                	ld	s2,32(sp)
    80003b80:	6121                	addi	sp,sp,64
    80003b82:	8082                	ret
    n = 0;
    80003b84:	fc042623          	sw	zero,-52(s0)
    80003b88:	bf49                	j	80003b1a <sys_pause+0x1c>
      release(&tickslock);
    80003b8a:	001a1517          	auipc	a0,0x1a1
    80003b8e:	3a650513          	addi	a0,a0,934 # 801a4f30 <tickslock>
    80003b92:	8e2fd0ef          	jal	80000c74 <release>
      return -1;
    80003b96:	557d                	li	a0,-1
    80003b98:	74a2                	ld	s1,40(sp)
    80003b9a:	69e2                	ld	s3,24(sp)
    80003b9c:	bff9                	j	80003b7a <sys_pause+0x7c>

0000000080003b9e <sys_kill>:

uint64
sys_kill(void)
{
    80003b9e:	1101                	addi	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003ba6:	fec40593          	addi	a1,s0,-20
    80003baa:	4501                	li	a0,0
    80003bac:	d01ff0ef          	jal	800038ac <argint>
  return kkill(pid);
    80003bb0:	fec42503          	lw	a0,-20(s0)
    80003bb4:	d0eff0ef          	jal	800030c2 <kkill>
}
    80003bb8:	60e2                	ld	ra,24(sp)
    80003bba:	6442                	ld	s0,16(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret

0000000080003bc0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003bc0:	1101                	addi	sp,sp,-32
    80003bc2:	ec06                	sd	ra,24(sp)
    80003bc4:	e822                	sd	s0,16(sp)
    80003bc6:	e426                	sd	s1,8(sp)
    80003bc8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003bca:	001a1517          	auipc	a0,0x1a1
    80003bce:	36650513          	addi	a0,a0,870 # 801a4f30 <tickslock>
    80003bd2:	ffdfc0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80003bd6:	00008497          	auipc	s1,0x8
    80003bda:	e024a483          	lw	s1,-510(s1) # 8000b9d8 <ticks>
  release(&tickslock);
    80003bde:	001a1517          	auipc	a0,0x1a1
    80003be2:	35250513          	addi	a0,a0,850 # 801a4f30 <tickslock>
    80003be6:	88efd0ef          	jal	80000c74 <release>
  return xticks;
}
    80003bea:	02049513          	slli	a0,s1,0x20
    80003bee:	9101                	srli	a0,a0,0x20
    80003bf0:	60e2                	ld	ra,24(sp)
    80003bf2:	6442                	ld	s0,16(sp)
    80003bf4:	64a2                	ld	s1,8(sp)
    80003bf6:	6105                	addi	sp,sp,32
    80003bf8:	8082                	ret

0000000080003bfa <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    80003bfa:	1101                	addi	sp,sp,-32
    80003bfc:	ec06                	sd	ra,24(sp)
    80003bfe:	e822                	sd	s0,16(sp)
    80003c00:	e426                	sd	s1,8(sp)
    80003c02:	1000                	addi	s0,sp,32
  extern int read_count;
  extern struct spinlock read_count_lock;
  int count;
  
  acquire(&read_count_lock);
    80003c04:	001a1517          	auipc	a0,0x1a1
    80003c08:	34450513          	addi	a0,a0,836 # 801a4f48 <read_count_lock>
    80003c0c:	fc3fc0ef          	jal	80000bce <acquire>
  count = read_count;
    80003c10:	00008497          	auipc	s1,0x8
    80003c14:	dd04a483          	lw	s1,-560(s1) # 8000b9e0 <read_count>
  release(&read_count_lock);
    80003c18:	001a1517          	auipc	a0,0x1a1
    80003c1c:	33050513          	addi	a0,a0,816 # 801a4f48 <read_count_lock>
    80003c20:	854fd0ef          	jal	80000c74 <release>
  
  return count;
}
    80003c24:	8526                	mv	a0,s1
    80003c26:	60e2                	ld	ra,24(sp)
    80003c28:	6442                	ld	s0,16(sp)
    80003c2a:	64a2                	ld	s1,8(sp)
    80003c2c:	6105                	addi	sp,sp,32
    80003c2e:	8082                	ret

0000000080003c30 <sys_memstat>:

// memstat syscall: int memstat(struct proc_mem_stat *info);
uint64
sys_memstat(void)
{
    80003c30:	81010113          	addi	sp,sp,-2032
    80003c34:	7e113423          	sd	ra,2024(sp)
    80003c38:	7e813023          	sd	s0,2016(sp)
    80003c3c:	7c913c23          	sd	s1,2008(sp)
    80003c40:	7d213823          	sd	s2,2000(sp)
    80003c44:	7d313423          	sd	s3,1992(sp)
    80003c48:	7d413023          	sd	s4,1984(sp)
    80003c4c:	7b513c23          	sd	s5,1976(sp)
    80003c50:	7b613823          	sd	s6,1968(sp)
    80003c54:	7b713423          	sd	s7,1960(sp)
    80003c58:	7b813023          	sd	s8,1952(sp)
    80003c5c:	79913c23          	sd	s9,1944(sp)
    80003c60:	79a13823          	sd	s10,1936(sp)
    80003c64:	79b13423          	sd	s11,1928(sp)
    80003c68:	7f010413          	addi	s0,sp,2032
    80003c6c:	d5010113          	addi	sp,sp,-688
  uint64 user_addr;
  argaddr(0, &user_addr);
    80003c70:	f8840593          	addi	a1,s0,-120
    80003c74:	4501                	li	a0,0
    80003c76:	c53ff0ef          	jal	800038c8 <argaddr>
  struct proc *p = myproc();
    80003c7a:	faefe0ef          	jal	80002428 <myproc>
    80003c7e:	89aa                	mv	s3,a0
  struct proc_mem_stat kms;
  // initialize
  memset(&kms, 0, sizeof(kms));
    80003c80:	757d                	lui	a0,0xfffff
    80003c82:	6485                	lui	s1,0x1
    80003c84:	6605                	lui	a2,0x1
    80003c86:	a1460613          	addi	a2,a2,-1516 # a14 <_entry-0x7ffff5ec>
    80003c8a:	4581                	li	a1,0
    80003c8c:	57050793          	addi	a5,a0,1392 # fffffffffffff570 <end+0xffffffff7fe4f248>
    80003c90:	00878533          	add	a0,a5,s0
    80003c94:	81cfd0ef          	jal	80000cb0 <memset>
  kms.pid = p->pid;
    80003c98:	0309a783          	lw	a5,48(s3)
    80003c9c:	797d                	lui	s2,0xfffff
    80003c9e:	57090713          	addi	a4,s2,1392 # fffffffffffff570 <end+0xffffffff7fe4f248>
    80003ca2:	9722                	add	a4,a4,s0
    80003ca4:	c31c                	sw	a5,0(a4)
  // Take a brief snapshot of process memory metadata under p->lock
  acquire(&p->lock);
    80003ca6:	854e                	mv	a0,s3
    80003ca8:	f27fc0ef          	jal	80000bce <acquire>
  kms.next_fifo_seq = p->page_seq_ctr;
    80003cac:	3a09b783          	ld	a5,928(s3)
    80003cb0:	58090713          	addi	a4,s2,1408
    80003cb4:	9722                	add	a4,a4,s0
    80003cb6:	c31c                	sw	a5,0(a4)

  // total pages between 0 and p->sz (round up)
  int total_pages = PGROUNDUP(p->sz) / PGSIZE;
    80003cb8:	0489b783          	ld	a5,72(s3)
    80003cbc:	14fd                	addi	s1,s1,-1 # fff <_entry-0x7ffff001>
    80003cbe:	97a6                	add	a5,a5,s1
    80003cc0:	83b1                	srli	a5,a5,0xc
    80003cc2:	0007871b          	sext.w	a4,a5
  kms.num_pages_total = total_pages;
    80003cc6:	57490693          	addi	a3,s2,1396
    80003cca:	96a2                	add	a3,a3,s0
    80003ccc:	c298                	sw	a4,0(a3)
  int swapped = 0;

  // Count resident and swapped pages by iterating all virtual pages.
  // This ensures pages that are mapped but not present in pgmeta are
  // accounted for in the totals.
  for(int pg = 0; pg < total_pages; pg++){
    80003cce:	0ee05e63          	blez	a4,80003dca <sys_memstat+0x19a>
    80003cd2:	fff78a9b          	addiw	s5,a5,-1
    80003cd6:	1a82                	slli	s5,s5,0x20
    80003cd8:	020ada93          	srli	s5,s5,0x20
    80003cdc:	0a85                	addi	s5,s5,1
    80003cde:	0ab2                	slli	s5,s5,0xc
    80003ce0:	4481                	li	s1,0
  int swapped = 0;
    80003ce2:	4d01                	li	s10,0
  int resident = 0;
    80003ce4:	4c01                	li	s8,0
  int reported = 0;
    80003ce6:	4a01                	li	s4,0
    uint64 va_pg = (uint64)pg * PGSIZE;
    // try to find pgmeta entry
    int midx = -1;
    for(int mi = 0; mi < PGMETA_SIZE; mi++){
    80003ce8:	4b01                	li	s6,0
    80003cea:	40000913          	li	s2,1024
      } else {
        if(ismapped(p->pagetable, va_pg)){
          ps.state = RESIDENT;
        }
      }
      kms.pages[reported++] = ps;
    80003cee:	7bfd                	lui	s7,0xfffff
    80003cf0:	f90b8793          	addi	a5,s7,-112 # ffffffffffffef90 <end+0xffffffff7fe4ec68>
    80003cf4:	00878bb3          	add	s7,a5,s0
    if(reported < MAX_PAGES_INFO){
    80003cf8:	07f00c93          	li	s9,127
    80003cfc:	a079                	j	80003d8a <sys_memstat+0x15a>
    if(midx >= 0){
    80003cfe:	0a07c063          	bltz	a5,80003d9e <sys_memstat+0x16e>
      if(p->pgmeta[midx].resident) resident++;
    80003d02:	00179713          	slli	a4,a5,0x1
    80003d06:	973e                	add	a4,a4,a5
    80003d08:	070e                	slli	a4,a4,0x3
    80003d0a:	974e                	add	a4,a4,s3
    80003d0c:	44874603          	lbu	a2,1096(a4)
    80003d10:	c211                	beqz	a2,80003d14 <sys_memstat+0xe4>
    80003d12:	2c05                	addiw	s8,s8,1
      if(p->pgmeta[midx].in_swap) swapped++;
    80003d14:	00179713          	slli	a4,a5,0x1
    80003d18:	973e                	add	a4,a4,a5
    80003d1a:	070e                	slli	a4,a4,0x3
    80003d1c:	974e                	add	a4,a4,s3
    80003d1e:	44b74683          	lbu	a3,1099(a4)
    80003d22:	c291                	beqz	a3,80003d26 <sys_memstat+0xf6>
    80003d24:	2d05                	addiw	s10,s10,1 # 1001 <_entry-0x7fffefff>
    if(reported < MAX_PAGES_INFO){
    80003d26:	054cce63          	blt	s9,s4,80003d82 <sys_memstat+0x152>
      ps.va = (uint)va_pg;
    80003d2a:	00048d9b          	sext.w	s11,s1
        if(p->pgmeta[midx].resident) ps.state = RESIDENT;
    80003d2e:	4585                	li	a1,1
    80003d30:	e601                	bnez	a2,80003d38 <sys_memstat+0x108>
        else if(p->pgmeta[midx].in_swap) ps.state = SWAPPED;
    80003d32:	00d035b3          	snez	a1,a3
    80003d36:	0586                	slli	a1,a1,0x1
        ps.is_dirty = p->pgmeta[midx].dirty ? 1 : 0;
    80003d38:	00179713          	slli	a4,a5,0x1
    80003d3c:	973e                	add	a4,a4,a5
    80003d3e:	070e                	slli	a4,a4,0x3
    80003d40:	974e                	add	a4,a4,s3
    80003d42:	44974603          	lbu	a2,1097(a4)
    80003d46:	00c03633          	snez	a2,a2
        ps.seq = (int)p->pgmeta[midx].seq;
    80003d4a:	44072803          	lw	a6,1088(a4)
        ps.swap_slot = p->pgmeta[midx].in_swap ? (int)p->pgmeta[midx].slot : -1;
    80003d4e:	557d                	li	a0,-1
    80003d50:	ca81                	beqz	a3,80003d60 <sys_memstat+0x130>
    80003d52:	00179713          	slli	a4,a5,0x1
    80003d56:	97ba                	add	a5,a5,a4
    80003d58:	078e                	slli	a5,a5,0x3
    80003d5a:	97ce                	add	a5,a5,s3
    80003d5c:	44c7d503          	lhu	a0,1100(a5)
      kms.pages[reported++] = ps;
    80003d60:	002a1793          	slli	a5,s4,0x2
    80003d64:	01478733          	add	a4,a5,s4
    80003d68:	070a                	slli	a4,a4,0x2
    80003d6a:	975e                	add	a4,a4,s7
    80003d6c:	5fb72a23          	sw	s11,1524(a4)
    80003d70:	5eb72c23          	sw	a1,1528(a4)
    80003d74:	5ec72e23          	sw	a2,1532(a4)
    80003d78:	61072023          	sw	a6,1536(a4)
    80003d7c:	60a72223          	sw	a0,1540(a4)
    80003d80:	2a05                	addiw	s4,s4,1
  for(int pg = 0; pg < total_pages; pg++){
    80003d82:	6785                	lui	a5,0x1
    80003d84:	94be                	add	s1,s1,a5
    80003d86:	05548463          	beq	s1,s5,80003dce <sys_memstat+0x19e>
    for(int mi = 0; mi < PGMETA_SIZE; mi++){
    80003d8a:	43898713          	addi	a4,s3,1080
    80003d8e:	87da                	mv	a5,s6
        if(p->pgmeta[mi].va == va_pg){ midx = mi; break; }
    80003d90:	6314                	ld	a3,0(a4)
    80003d92:	f69686e3          	beq	a3,s1,80003cfe <sys_memstat+0xce>
    for(int mi = 0; mi < PGMETA_SIZE; mi++){
    80003d96:	2785                	addiw	a5,a5,1 # 1001 <_entry-0x7fffefff>
    80003d98:	0761                	addi	a4,a4,24
    80003d9a:	ff279be3          	bne	a5,s2,80003d90 <sys_memstat+0x160>
      if(ismapped(p->pagetable, va_pg)) resident++;
    80003d9e:	85a6                	mv	a1,s1
    80003da0:	0509b503          	ld	a0,80(s3)
    80003da4:	cc6fe0ef          	jal	8000226a <ismapped>
    80003da8:	c111                	beqz	a0,80003dac <sys_memstat+0x17c>
    80003daa:	2c05                	addiw	s8,s8,1
    if(reported < MAX_PAGES_INFO){
    80003dac:	fd4ccbe3          	blt	s9,s4,80003d82 <sys_memstat+0x152>
      ps.va = (uint)va_pg;
    80003db0:	00048d9b          	sext.w	s11,s1
        if(ismapped(p->pagetable, va_pg)){
    80003db4:	85a6                	mv	a1,s1
    80003db6:	0509b503          	ld	a0,80(s3)
    80003dba:	cb0fe0ef          	jal	8000226a <ismapped>
    80003dbe:	00a035b3          	snez	a1,a0
      ps.swap_slot = -1;
    80003dc2:	557d                	li	a0,-1
      ps.seq = 0;
    80003dc4:	885a                	mv	a6,s6
      ps.is_dirty = 0;
    80003dc6:	865a                	mv	a2,s6
    80003dc8:	bf61                	j	80003d60 <sys_memstat+0x130>
  int swapped = 0;
    80003dca:	4d01                	li	s10,0
  int resident = 0;
    80003dcc:	4c01                	li	s8,0
    }
  }
  kms.num_resident_pages = resident;
    80003dce:	77fd                	lui	a5,0xfffff
    80003dd0:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fe4ec68>
    80003dd4:	97a2                	add	a5,a5,s0
    80003dd6:	777d                	lui	a4,0xfffff
    80003dd8:	56870693          	addi	a3,a4,1384 # fffffffffffff568 <end+0xffffffff7fe4f240>
    80003ddc:	96a2                	add	a3,a3,s0
    80003dde:	e29c                	sd	a5,0(a3)
    80003de0:	629c                	ld	a5,0(a3)
    80003de2:	5f87a423          	sw	s8,1512(a5)
  kms.num_swapped_pages = swapped;
    80003de6:	629c                	ld	a5,0(a3)
    80003de8:	5fa7a623          	sw	s10,1516(a5)
  release(&p->lock);
    80003dec:	854e                	mv	a0,s3
    80003dee:	e87fc0ef          	jal	80000c74 <release>

  // copy out to user space
  if(either_copyout(1, user_addr, (void*)&kms, sizeof(kms)) < 0)
    80003df2:	767d                	lui	a2,0xfffff
    80003df4:	6685                	lui	a3,0x1
    80003df6:	a1468693          	addi	a3,a3,-1516 # a14 <_entry-0x7ffff5ec>
    80003dfa:	57060793          	addi	a5,a2,1392 # fffffffffffff570 <end+0xffffffff7fe4f248>
    80003dfe:	00878633          	add	a2,a5,s0
    80003e02:	f8843583          	ld	a1,-120(s0)
    80003e06:	4505                	li	a0,1
    80003e08:	c72ff0ef          	jal	8000327a <either_copyout>
    80003e0c:	957d                	srai	a0,a0,0x3f
    return -1;
  return 0;
}
    80003e0e:	2b010113          	addi	sp,sp,688
    80003e12:	7e813083          	ld	ra,2024(sp)
    80003e16:	7e013403          	ld	s0,2016(sp)
    80003e1a:	7d813483          	ld	s1,2008(sp)
    80003e1e:	7d013903          	ld	s2,2000(sp)
    80003e22:	7c813983          	ld	s3,1992(sp)
    80003e26:	7c013a03          	ld	s4,1984(sp)
    80003e2a:	7b813a83          	ld	s5,1976(sp)
    80003e2e:	7b013b03          	ld	s6,1968(sp)
    80003e32:	7a813b83          	ld	s7,1960(sp)
    80003e36:	7a013c03          	ld	s8,1952(sp)
    80003e3a:	79813c83          	ld	s9,1944(sp)
    80003e3e:	79013d03          	ld	s10,1936(sp)
    80003e42:	78813d83          	ld	s11,1928(sp)
    80003e46:	7f010113          	addi	sp,sp,2032
    80003e4a:	8082                	ret

0000000080003e4c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003e4c:	7179                	addi	sp,sp,-48
    80003e4e:	f406                	sd	ra,40(sp)
    80003e50:	f022                	sd	s0,32(sp)
    80003e52:	ec26                	sd	s1,24(sp)
    80003e54:	e84a                	sd	s2,16(sp)
    80003e56:	e44e                	sd	s3,8(sp)
    80003e58:	e052                	sd	s4,0(sp)
    80003e5a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003e5c:	00005597          	auipc	a1,0x5
    80003e60:	8d458593          	addi	a1,a1,-1836 # 80008730 <etext+0x730>
    80003e64:	001a1517          	auipc	a0,0x1a1
    80003e68:	0fc50513          	addi	a0,a0,252 # 801a4f60 <bcache>
    80003e6c:	ce3fc0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003e70:	001a9797          	auipc	a5,0x1a9
    80003e74:	0f078793          	addi	a5,a5,240 # 801acf60 <bcache+0x8000>
    80003e78:	001a9717          	auipc	a4,0x1a9
    80003e7c:	35070713          	addi	a4,a4,848 # 801ad1c8 <bcache+0x8268>
    80003e80:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003e84:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003e88:	001a1497          	auipc	s1,0x1a1
    80003e8c:	0f048493          	addi	s1,s1,240 # 801a4f78 <bcache+0x18>
    b->next = bcache.head.next;
    80003e90:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003e92:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003e94:	00005a17          	auipc	s4,0x5
    80003e98:	8a4a0a13          	addi	s4,s4,-1884 # 80008738 <etext+0x738>
    b->next = bcache.head.next;
    80003e9c:	2b893783          	ld	a5,696(s2)
    80003ea0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ea2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ea6:	85d2                	mv	a1,s4
    80003ea8:	01048513          	addi	a0,s1,16
    80003eac:	322010ef          	jal	800051ce <initsleeplock>
    bcache.head.next->prev = b;
    80003eb0:	2b893783          	ld	a5,696(s2)
    80003eb4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003eb6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003eba:	45848493          	addi	s1,s1,1112
    80003ebe:	fd349fe3          	bne	s1,s3,80003e9c <binit+0x50>
  }
}
    80003ec2:	70a2                	ld	ra,40(sp)
    80003ec4:	7402                	ld	s0,32(sp)
    80003ec6:	64e2                	ld	s1,24(sp)
    80003ec8:	6942                	ld	s2,16(sp)
    80003eca:	69a2                	ld	s3,8(sp)
    80003ecc:	6a02                	ld	s4,0(sp)
    80003ece:	6145                	addi	sp,sp,48
    80003ed0:	8082                	ret

0000000080003ed2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003ed2:	7179                	addi	sp,sp,-48
    80003ed4:	f406                	sd	ra,40(sp)
    80003ed6:	f022                	sd	s0,32(sp)
    80003ed8:	ec26                	sd	s1,24(sp)
    80003eda:	e84a                	sd	s2,16(sp)
    80003edc:	e44e                	sd	s3,8(sp)
    80003ede:	1800                	addi	s0,sp,48
    80003ee0:	892a                	mv	s2,a0
    80003ee2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003ee4:	001a1517          	auipc	a0,0x1a1
    80003ee8:	07c50513          	addi	a0,a0,124 # 801a4f60 <bcache>
    80003eec:	ce3fc0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003ef0:	001a9497          	auipc	s1,0x1a9
    80003ef4:	3284b483          	ld	s1,808(s1) # 801ad218 <bcache+0x82b8>
    80003ef8:	001a9797          	auipc	a5,0x1a9
    80003efc:	2d078793          	addi	a5,a5,720 # 801ad1c8 <bcache+0x8268>
    80003f00:	02f48b63          	beq	s1,a5,80003f36 <bread+0x64>
    80003f04:	873e                	mv	a4,a5
    80003f06:	a021                	j	80003f0e <bread+0x3c>
    80003f08:	68a4                	ld	s1,80(s1)
    80003f0a:	02e48663          	beq	s1,a4,80003f36 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80003f0e:	449c                	lw	a5,8(s1)
    80003f10:	ff279ce3          	bne	a5,s2,80003f08 <bread+0x36>
    80003f14:	44dc                	lw	a5,12(s1)
    80003f16:	ff3799e3          	bne	a5,s3,80003f08 <bread+0x36>
      b->refcnt++;
    80003f1a:	40bc                	lw	a5,64(s1)
    80003f1c:	2785                	addiw	a5,a5,1
    80003f1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003f20:	001a1517          	auipc	a0,0x1a1
    80003f24:	04050513          	addi	a0,a0,64 # 801a4f60 <bcache>
    80003f28:	d4dfc0ef          	jal	80000c74 <release>
      acquiresleep(&b->lock);
    80003f2c:	01048513          	addi	a0,s1,16
    80003f30:	2d4010ef          	jal	80005204 <acquiresleep>
      return b;
    80003f34:	a889                	j	80003f86 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003f36:	001a9497          	auipc	s1,0x1a9
    80003f3a:	2da4b483          	ld	s1,730(s1) # 801ad210 <bcache+0x82b0>
    80003f3e:	001a9797          	auipc	a5,0x1a9
    80003f42:	28a78793          	addi	a5,a5,650 # 801ad1c8 <bcache+0x8268>
    80003f46:	00f48863          	beq	s1,a5,80003f56 <bread+0x84>
    80003f4a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003f4c:	40bc                	lw	a5,64(s1)
    80003f4e:	cb91                	beqz	a5,80003f62 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003f50:	64a4                	ld	s1,72(s1)
    80003f52:	fee49de3          	bne	s1,a4,80003f4c <bread+0x7a>
  panic("bget: no buffers");
    80003f56:	00004517          	auipc	a0,0x4
    80003f5a:	7ea50513          	addi	a0,a0,2026 # 80008740 <etext+0x740>
    80003f5e:	883fc0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80003f62:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003f66:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003f6a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003f6e:	4785                	li	a5,1
    80003f70:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003f72:	001a1517          	auipc	a0,0x1a1
    80003f76:	fee50513          	addi	a0,a0,-18 # 801a4f60 <bcache>
    80003f7a:	cfbfc0ef          	jal	80000c74 <release>
      acquiresleep(&b->lock);
    80003f7e:	01048513          	addi	a0,s1,16
    80003f82:	282010ef          	jal	80005204 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003f86:	409c                	lw	a5,0(s1)
    80003f88:	cb89                	beqz	a5,80003f9a <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	70a2                	ld	ra,40(sp)
    80003f8e:	7402                	ld	s0,32(sp)
    80003f90:	64e2                	ld	s1,24(sp)
    80003f92:	6942                	ld	s2,16(sp)
    80003f94:	69a2                	ld	s3,8(sp)
    80003f96:	6145                	addi	sp,sp,48
    80003f98:	8082                	ret
    virtio_disk_rw(b, 0);
    80003f9a:	4581                	li	a1,0
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	353020ef          	jal	80006af0 <virtio_disk_rw>
    b->valid = 1;
    80003fa2:	4785                	li	a5,1
    80003fa4:	c09c                	sw	a5,0(s1)
  return b;
    80003fa6:	b7d5                	j	80003f8a <bread+0xb8>

0000000080003fa8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003fa8:	1101                	addi	sp,sp,-32
    80003faa:	ec06                	sd	ra,24(sp)
    80003fac:	e822                	sd	s0,16(sp)
    80003fae:	e426                	sd	s1,8(sp)
    80003fb0:	1000                	addi	s0,sp,32
    80003fb2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003fb4:	0541                	addi	a0,a0,16
    80003fb6:	2cc010ef          	jal	80005282 <holdingsleep>
    80003fba:	c911                	beqz	a0,80003fce <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003fbc:	4585                	li	a1,1
    80003fbe:	8526                	mv	a0,s1
    80003fc0:	331020ef          	jal	80006af0 <virtio_disk_rw>
}
    80003fc4:	60e2                	ld	ra,24(sp)
    80003fc6:	6442                	ld	s0,16(sp)
    80003fc8:	64a2                	ld	s1,8(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret
    panic("bwrite");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	78a50513          	addi	a0,a0,1930 # 80008758 <etext+0x758>
    80003fd6:	80bfc0ef          	jal	800007e0 <panic>

0000000080003fda <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	e04a                	sd	s2,0(sp)
    80003fe4:	1000                	addi	s0,sp,32
    80003fe6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003fe8:	01050913          	addi	s2,a0,16
    80003fec:	854a                	mv	a0,s2
    80003fee:	294010ef          	jal	80005282 <holdingsleep>
    80003ff2:	c135                	beqz	a0,80004056 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	254010ef          	jal	8000524a <releasesleep>

  acquire(&bcache.lock);
    80003ffa:	001a1517          	auipc	a0,0x1a1
    80003ffe:	f6650513          	addi	a0,a0,-154 # 801a4f60 <bcache>
    80004002:	bcdfc0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80004006:	40bc                	lw	a5,64(s1)
    80004008:	37fd                	addiw	a5,a5,-1
    8000400a:	0007871b          	sext.w	a4,a5
    8000400e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80004010:	e71d                	bnez	a4,8000403e <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80004012:	68b8                	ld	a4,80(s1)
    80004014:	64bc                	ld	a5,72(s1)
    80004016:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80004018:	68b8                	ld	a4,80(s1)
    8000401a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000401c:	001a9797          	auipc	a5,0x1a9
    80004020:	f4478793          	addi	a5,a5,-188 # 801acf60 <bcache+0x8000>
    80004024:	2b87b703          	ld	a4,696(a5)
    80004028:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000402a:	001a9717          	auipc	a4,0x1a9
    8000402e:	19e70713          	addi	a4,a4,414 # 801ad1c8 <bcache+0x8268>
    80004032:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80004034:	2b87b703          	ld	a4,696(a5)
    80004038:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000403a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000403e:	001a1517          	auipc	a0,0x1a1
    80004042:	f2250513          	addi	a0,a0,-222 # 801a4f60 <bcache>
    80004046:	c2ffc0ef          	jal	80000c74 <release>
}
    8000404a:	60e2                	ld	ra,24(sp)
    8000404c:	6442                	ld	s0,16(sp)
    8000404e:	64a2                	ld	s1,8(sp)
    80004050:	6902                	ld	s2,0(sp)
    80004052:	6105                	addi	sp,sp,32
    80004054:	8082                	ret
    panic("brelse");
    80004056:	00004517          	auipc	a0,0x4
    8000405a:	70a50513          	addi	a0,a0,1802 # 80008760 <etext+0x760>
    8000405e:	f82fc0ef          	jal	800007e0 <panic>

0000000080004062 <bpin>:

void
bpin(struct buf *b) {
    80004062:	1101                	addi	sp,sp,-32
    80004064:	ec06                	sd	ra,24(sp)
    80004066:	e822                	sd	s0,16(sp)
    80004068:	e426                	sd	s1,8(sp)
    8000406a:	1000                	addi	s0,sp,32
    8000406c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000406e:	001a1517          	auipc	a0,0x1a1
    80004072:	ef250513          	addi	a0,a0,-270 # 801a4f60 <bcache>
    80004076:	b59fc0ef          	jal	80000bce <acquire>
  b->refcnt++;
    8000407a:	40bc                	lw	a5,64(s1)
    8000407c:	2785                	addiw	a5,a5,1
    8000407e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004080:	001a1517          	auipc	a0,0x1a1
    80004084:	ee050513          	addi	a0,a0,-288 # 801a4f60 <bcache>
    80004088:	bedfc0ef          	jal	80000c74 <release>
}
    8000408c:	60e2                	ld	ra,24(sp)
    8000408e:	6442                	ld	s0,16(sp)
    80004090:	64a2                	ld	s1,8(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <bunpin>:

void
bunpin(struct buf *b) {
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	1000                	addi	s0,sp,32
    800040a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800040a2:	001a1517          	auipc	a0,0x1a1
    800040a6:	ebe50513          	addi	a0,a0,-322 # 801a4f60 <bcache>
    800040aa:	b25fc0ef          	jal	80000bce <acquire>
  b->refcnt--;
    800040ae:	40bc                	lw	a5,64(s1)
    800040b0:	37fd                	addiw	a5,a5,-1
    800040b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800040b4:	001a1517          	auipc	a0,0x1a1
    800040b8:	eac50513          	addi	a0,a0,-340 # 801a4f60 <bcache>
    800040bc:	bb9fc0ef          	jal	80000c74 <release>
}
    800040c0:	60e2                	ld	ra,24(sp)
    800040c2:	6442                	ld	s0,16(sp)
    800040c4:	64a2                	ld	s1,8(sp)
    800040c6:	6105                	addi	sp,sp,32
    800040c8:	8082                	ret

00000000800040ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	e426                	sd	s1,8(sp)
    800040d2:	e04a                	sd	s2,0(sp)
    800040d4:	1000                	addi	s0,sp,32
    800040d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800040d8:	00d5d59b          	srliw	a1,a1,0xd
    800040dc:	001a9797          	auipc	a5,0x1a9
    800040e0:	5607a783          	lw	a5,1376(a5) # 801ad63c <sb+0x1c>
    800040e4:	9dbd                	addw	a1,a1,a5
    800040e6:	dedff0ef          	jal	80003ed2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800040ea:	0074f713          	andi	a4,s1,7
    800040ee:	4785                	li	a5,1
    800040f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800040f4:	14ce                	slli	s1,s1,0x33
    800040f6:	90d9                	srli	s1,s1,0x36
    800040f8:	00950733          	add	a4,a0,s1
    800040fc:	05874703          	lbu	a4,88(a4)
    80004100:	00e7f6b3          	and	a3,a5,a4
    80004104:	c29d                	beqz	a3,8000412a <bfree+0x60>
    80004106:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80004108:	94aa                	add	s1,s1,a0
    8000410a:	fff7c793          	not	a5,a5
    8000410e:	8f7d                	and	a4,a4,a5
    80004110:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80004114:	7f9000ef          	jal	8000510c <log_write>
  brelse(bp);
    80004118:	854a                	mv	a0,s2
    8000411a:	ec1ff0ef          	jal	80003fda <brelse>
}
    8000411e:	60e2                	ld	ra,24(sp)
    80004120:	6442                	ld	s0,16(sp)
    80004122:	64a2                	ld	s1,8(sp)
    80004124:	6902                	ld	s2,0(sp)
    80004126:	6105                	addi	sp,sp,32
    80004128:	8082                	ret
    panic("freeing free block");
    8000412a:	00004517          	auipc	a0,0x4
    8000412e:	63e50513          	addi	a0,a0,1598 # 80008768 <etext+0x768>
    80004132:	eaefc0ef          	jal	800007e0 <panic>

0000000080004136 <balloc>:
{
    80004136:	711d                	addi	sp,sp,-96
    80004138:	ec86                	sd	ra,88(sp)
    8000413a:	e8a2                	sd	s0,80(sp)
    8000413c:	e4a6                	sd	s1,72(sp)
    8000413e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80004140:	001a9797          	auipc	a5,0x1a9
    80004144:	4e47a783          	lw	a5,1252(a5) # 801ad624 <sb+0x4>
    80004148:	0e078f63          	beqz	a5,80004246 <balloc+0x110>
    8000414c:	e0ca                	sd	s2,64(sp)
    8000414e:	fc4e                	sd	s3,56(sp)
    80004150:	f852                	sd	s4,48(sp)
    80004152:	f456                	sd	s5,40(sp)
    80004154:	f05a                	sd	s6,32(sp)
    80004156:	ec5e                	sd	s7,24(sp)
    80004158:	e862                	sd	s8,16(sp)
    8000415a:	e466                	sd	s9,8(sp)
    8000415c:	8baa                	mv	s7,a0
    8000415e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80004160:	001a9b17          	auipc	s6,0x1a9
    80004164:	4c0b0b13          	addi	s6,s6,1216 # 801ad620 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004168:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000416a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000416c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000416e:	6c89                	lui	s9,0x2
    80004170:	a0b5                	j	800041dc <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004172:	97ca                	add	a5,a5,s2
    80004174:	8e55                	or	a2,a2,a3
    80004176:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000417a:	854a                	mv	a0,s2
    8000417c:	791000ef          	jal	8000510c <log_write>
        brelse(bp);
    80004180:	854a                	mv	a0,s2
    80004182:	e59ff0ef          	jal	80003fda <brelse>
  bp = bread(dev, bno);
    80004186:	85a6                	mv	a1,s1
    80004188:	855e                	mv	a0,s7
    8000418a:	d49ff0ef          	jal	80003ed2 <bread>
    8000418e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80004190:	40000613          	li	a2,1024
    80004194:	4581                	li	a1,0
    80004196:	05850513          	addi	a0,a0,88
    8000419a:	b17fc0ef          	jal	80000cb0 <memset>
  log_write(bp);
    8000419e:	854a                	mv	a0,s2
    800041a0:	76d000ef          	jal	8000510c <log_write>
  brelse(bp);
    800041a4:	854a                	mv	a0,s2
    800041a6:	e35ff0ef          	jal	80003fda <brelse>
}
    800041aa:	6906                	ld	s2,64(sp)
    800041ac:	79e2                	ld	s3,56(sp)
    800041ae:	7a42                	ld	s4,48(sp)
    800041b0:	7aa2                	ld	s5,40(sp)
    800041b2:	7b02                	ld	s6,32(sp)
    800041b4:	6be2                	ld	s7,24(sp)
    800041b6:	6c42                	ld	s8,16(sp)
    800041b8:	6ca2                	ld	s9,8(sp)
}
    800041ba:	8526                	mv	a0,s1
    800041bc:	60e6                	ld	ra,88(sp)
    800041be:	6446                	ld	s0,80(sp)
    800041c0:	64a6                	ld	s1,72(sp)
    800041c2:	6125                	addi	sp,sp,96
    800041c4:	8082                	ret
    brelse(bp);
    800041c6:	854a                	mv	a0,s2
    800041c8:	e13ff0ef          	jal	80003fda <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800041cc:	015c87bb          	addw	a5,s9,s5
    800041d0:	00078a9b          	sext.w	s5,a5
    800041d4:	004b2703          	lw	a4,4(s6)
    800041d8:	04eaff63          	bgeu	s5,a4,80004236 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    800041dc:	41fad79b          	sraiw	a5,s5,0x1f
    800041e0:	0137d79b          	srliw	a5,a5,0x13
    800041e4:	015787bb          	addw	a5,a5,s5
    800041e8:	40d7d79b          	sraiw	a5,a5,0xd
    800041ec:	01cb2583          	lw	a1,28(s6)
    800041f0:	9dbd                	addw	a1,a1,a5
    800041f2:	855e                	mv	a0,s7
    800041f4:	cdfff0ef          	jal	80003ed2 <bread>
    800041f8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800041fa:	004b2503          	lw	a0,4(s6)
    800041fe:	000a849b          	sext.w	s1,s5
    80004202:	8762                	mv	a4,s8
    80004204:	fca4f1e3          	bgeu	s1,a0,800041c6 <balloc+0x90>
      m = 1 << (bi % 8);
    80004208:	00777693          	andi	a3,a4,7
    8000420c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004210:	41f7579b          	sraiw	a5,a4,0x1f
    80004214:	01d7d79b          	srliw	a5,a5,0x1d
    80004218:	9fb9                	addw	a5,a5,a4
    8000421a:	4037d79b          	sraiw	a5,a5,0x3
    8000421e:	00f90633          	add	a2,s2,a5
    80004222:	05864603          	lbu	a2,88(a2)
    80004226:	00c6f5b3          	and	a1,a3,a2
    8000422a:	d5a1                	beqz	a1,80004172 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000422c:	2705                	addiw	a4,a4,1
    8000422e:	2485                	addiw	s1,s1,1
    80004230:	fd471ae3          	bne	a4,s4,80004204 <balloc+0xce>
    80004234:	bf49                	j	800041c6 <balloc+0x90>
    80004236:	6906                	ld	s2,64(sp)
    80004238:	79e2                	ld	s3,56(sp)
    8000423a:	7a42                	ld	s4,48(sp)
    8000423c:	7aa2                	ld	s5,40(sp)
    8000423e:	7b02                	ld	s6,32(sp)
    80004240:	6be2                	ld	s7,24(sp)
    80004242:	6c42                	ld	s8,16(sp)
    80004244:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80004246:	00004517          	auipc	a0,0x4
    8000424a:	53a50513          	addi	a0,a0,1338 # 80008780 <etext+0x780>
    8000424e:	aacfc0ef          	jal	800004fa <printf>
  return 0;
    80004252:	4481                	li	s1,0
    80004254:	b79d                	j	800041ba <balloc+0x84>

0000000080004256 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80004256:	7179                	addi	sp,sp,-48
    80004258:	f406                	sd	ra,40(sp)
    8000425a:	f022                	sd	s0,32(sp)
    8000425c:	ec26                	sd	s1,24(sp)
    8000425e:	e84a                	sd	s2,16(sp)
    80004260:	e44e                	sd	s3,8(sp)
    80004262:	1800                	addi	s0,sp,48
    80004264:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80004266:	47ad                	li	a5,11
    80004268:	02b7e663          	bltu	a5,a1,80004294 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    8000426c:	02059793          	slli	a5,a1,0x20
    80004270:	01e7d593          	srli	a1,a5,0x1e
    80004274:	00b504b3          	add	s1,a0,a1
    80004278:	0504a903          	lw	s2,80(s1)
    8000427c:	06091a63          	bnez	s2,800042f0 <bmap+0x9a>
      addr = balloc(ip->dev);
    80004280:	4108                	lw	a0,0(a0)
    80004282:	eb5ff0ef          	jal	80004136 <balloc>
    80004286:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000428a:	06090363          	beqz	s2,800042f0 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    8000428e:	0524a823          	sw	s2,80(s1)
    80004292:	a8b9                	j	800042f0 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004294:	ff45849b          	addiw	s1,a1,-12
    80004298:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000429c:	0ff00793          	li	a5,255
    800042a0:	06e7ee63          	bltu	a5,a4,8000431c <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800042a4:	08052903          	lw	s2,128(a0)
    800042a8:	00091d63          	bnez	s2,800042c2 <bmap+0x6c>
      addr = balloc(ip->dev);
    800042ac:	4108                	lw	a0,0(a0)
    800042ae:	e89ff0ef          	jal	80004136 <balloc>
    800042b2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800042b6:	02090d63          	beqz	s2,800042f0 <bmap+0x9a>
    800042ba:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800042bc:	0929a023          	sw	s2,128(s3)
    800042c0:	a011                	j	800042c4 <bmap+0x6e>
    800042c2:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800042c4:	85ca                	mv	a1,s2
    800042c6:	0009a503          	lw	a0,0(s3)
    800042ca:	c09ff0ef          	jal	80003ed2 <bread>
    800042ce:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800042d0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800042d4:	02049713          	slli	a4,s1,0x20
    800042d8:	01e75593          	srli	a1,a4,0x1e
    800042dc:	00b784b3          	add	s1,a5,a1
    800042e0:	0004a903          	lw	s2,0(s1)
    800042e4:	00090e63          	beqz	s2,80004300 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800042e8:	8552                	mv	a0,s4
    800042ea:	cf1ff0ef          	jal	80003fda <brelse>
    return addr;
    800042ee:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800042f0:	854a                	mv	a0,s2
    800042f2:	70a2                	ld	ra,40(sp)
    800042f4:	7402                	ld	s0,32(sp)
    800042f6:	64e2                	ld	s1,24(sp)
    800042f8:	6942                	ld	s2,16(sp)
    800042fa:	69a2                	ld	s3,8(sp)
    800042fc:	6145                	addi	sp,sp,48
    800042fe:	8082                	ret
      addr = balloc(ip->dev);
    80004300:	0009a503          	lw	a0,0(s3)
    80004304:	e33ff0ef          	jal	80004136 <balloc>
    80004308:	0005091b          	sext.w	s2,a0
      if(addr){
    8000430c:	fc090ee3          	beqz	s2,800042e8 <bmap+0x92>
        a[bn] = addr;
    80004310:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004314:	8552                	mv	a0,s4
    80004316:	5f7000ef          	jal	8000510c <log_write>
    8000431a:	b7f9                	j	800042e8 <bmap+0x92>
    8000431c:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    8000431e:	00004517          	auipc	a0,0x4
    80004322:	47a50513          	addi	a0,a0,1146 # 80008798 <etext+0x798>
    80004326:	cbafc0ef          	jal	800007e0 <panic>

000000008000432a <iget>:
{
    8000432a:	7179                	addi	sp,sp,-48
    8000432c:	f406                	sd	ra,40(sp)
    8000432e:	f022                	sd	s0,32(sp)
    80004330:	ec26                	sd	s1,24(sp)
    80004332:	e84a                	sd	s2,16(sp)
    80004334:	e44e                	sd	s3,8(sp)
    80004336:	e052                	sd	s4,0(sp)
    80004338:	1800                	addi	s0,sp,48
    8000433a:	89aa                	mv	s3,a0
    8000433c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000433e:	001a9517          	auipc	a0,0x1a9
    80004342:	30250513          	addi	a0,a0,770 # 801ad640 <itable>
    80004346:	889fc0ef          	jal	80000bce <acquire>
  empty = 0;
    8000434a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000434c:	001a9497          	auipc	s1,0x1a9
    80004350:	30c48493          	addi	s1,s1,780 # 801ad658 <itable+0x18>
    80004354:	001ab697          	auipc	a3,0x1ab
    80004358:	d9468693          	addi	a3,a3,-620 # 801af0e8 <log>
    8000435c:	a039                	j	8000436a <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000435e:	02090963          	beqz	s2,80004390 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004362:	08848493          	addi	s1,s1,136
    80004366:	02d48863          	beq	s1,a3,80004396 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000436a:	449c                	lw	a5,8(s1)
    8000436c:	fef059e3          	blez	a5,8000435e <iget+0x34>
    80004370:	4098                	lw	a4,0(s1)
    80004372:	ff3716e3          	bne	a4,s3,8000435e <iget+0x34>
    80004376:	40d8                	lw	a4,4(s1)
    80004378:	ff4713e3          	bne	a4,s4,8000435e <iget+0x34>
      ip->ref++;
    8000437c:	2785                	addiw	a5,a5,1
    8000437e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004380:	001a9517          	auipc	a0,0x1a9
    80004384:	2c050513          	addi	a0,a0,704 # 801ad640 <itable>
    80004388:	8edfc0ef          	jal	80000c74 <release>
      return ip;
    8000438c:	8926                	mv	s2,s1
    8000438e:	a02d                	j	800043b8 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004390:	fbe9                	bnez	a5,80004362 <iget+0x38>
      empty = ip;
    80004392:	8926                	mv	s2,s1
    80004394:	b7f9                	j	80004362 <iget+0x38>
  if(empty == 0)
    80004396:	02090a63          	beqz	s2,800043ca <iget+0xa0>
  ip->dev = dev;
    8000439a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000439e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800043a2:	4785                	li	a5,1
    800043a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800043a8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800043ac:	001a9517          	auipc	a0,0x1a9
    800043b0:	29450513          	addi	a0,a0,660 # 801ad640 <itable>
    800043b4:	8c1fc0ef          	jal	80000c74 <release>
}
    800043b8:	854a                	mv	a0,s2
    800043ba:	70a2                	ld	ra,40(sp)
    800043bc:	7402                	ld	s0,32(sp)
    800043be:	64e2                	ld	s1,24(sp)
    800043c0:	6942                	ld	s2,16(sp)
    800043c2:	69a2                	ld	s3,8(sp)
    800043c4:	6a02                	ld	s4,0(sp)
    800043c6:	6145                	addi	sp,sp,48
    800043c8:	8082                	ret
    panic("iget: no inodes");
    800043ca:	00004517          	auipc	a0,0x4
    800043ce:	3e650513          	addi	a0,a0,998 # 800087b0 <etext+0x7b0>
    800043d2:	c0efc0ef          	jal	800007e0 <panic>

00000000800043d6 <iinit>:
{
    800043d6:	7179                	addi	sp,sp,-48
    800043d8:	f406                	sd	ra,40(sp)
    800043da:	f022                	sd	s0,32(sp)
    800043dc:	ec26                	sd	s1,24(sp)
    800043de:	e84a                	sd	s2,16(sp)
    800043e0:	e44e                	sd	s3,8(sp)
    800043e2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800043e4:	00004597          	auipc	a1,0x4
    800043e8:	3dc58593          	addi	a1,a1,988 # 800087c0 <etext+0x7c0>
    800043ec:	001a9517          	auipc	a0,0x1a9
    800043f0:	25450513          	addi	a0,a0,596 # 801ad640 <itable>
    800043f4:	f5afc0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    800043f8:	001a9497          	auipc	s1,0x1a9
    800043fc:	27048493          	addi	s1,s1,624 # 801ad668 <itable+0x28>
    80004400:	001ab997          	auipc	s3,0x1ab
    80004404:	cf898993          	addi	s3,s3,-776 # 801af0f8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004408:	00004917          	auipc	s2,0x4
    8000440c:	3c090913          	addi	s2,s2,960 # 800087c8 <etext+0x7c8>
    80004410:	85ca                	mv	a1,s2
    80004412:	8526                	mv	a0,s1
    80004414:	5bb000ef          	jal	800051ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004418:	08848493          	addi	s1,s1,136
    8000441c:	ff349ae3          	bne	s1,s3,80004410 <iinit+0x3a>
}
    80004420:	70a2                	ld	ra,40(sp)
    80004422:	7402                	ld	s0,32(sp)
    80004424:	64e2                	ld	s1,24(sp)
    80004426:	6942                	ld	s2,16(sp)
    80004428:	69a2                	ld	s3,8(sp)
    8000442a:	6145                	addi	sp,sp,48
    8000442c:	8082                	ret

000000008000442e <ialloc>:
{
    8000442e:	7139                	addi	sp,sp,-64
    80004430:	fc06                	sd	ra,56(sp)
    80004432:	f822                	sd	s0,48(sp)
    80004434:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80004436:	001a9717          	auipc	a4,0x1a9
    8000443a:	1f672703          	lw	a4,502(a4) # 801ad62c <sb+0xc>
    8000443e:	4785                	li	a5,1
    80004440:	06e7f063          	bgeu	a5,a4,800044a0 <ialloc+0x72>
    80004444:	f426                	sd	s1,40(sp)
    80004446:	f04a                	sd	s2,32(sp)
    80004448:	ec4e                	sd	s3,24(sp)
    8000444a:	e852                	sd	s4,16(sp)
    8000444c:	e456                	sd	s5,8(sp)
    8000444e:	e05a                	sd	s6,0(sp)
    80004450:	8aaa                	mv	s5,a0
    80004452:	8b2e                	mv	s6,a1
    80004454:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004456:	001a9a17          	auipc	s4,0x1a9
    8000445a:	1caa0a13          	addi	s4,s4,458 # 801ad620 <sb>
    8000445e:	00495593          	srli	a1,s2,0x4
    80004462:	018a2783          	lw	a5,24(s4)
    80004466:	9dbd                	addw	a1,a1,a5
    80004468:	8556                	mv	a0,s5
    8000446a:	a69ff0ef          	jal	80003ed2 <bread>
    8000446e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004470:	05850993          	addi	s3,a0,88
    80004474:	00f97793          	andi	a5,s2,15
    80004478:	079a                	slli	a5,a5,0x6
    8000447a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000447c:	00099783          	lh	a5,0(s3)
    80004480:	cb9d                	beqz	a5,800044b6 <ialloc+0x88>
    brelse(bp);
    80004482:	b59ff0ef          	jal	80003fda <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004486:	0905                	addi	s2,s2,1
    80004488:	00ca2703          	lw	a4,12(s4)
    8000448c:	0009079b          	sext.w	a5,s2
    80004490:	fce7e7e3          	bltu	a5,a4,8000445e <ialloc+0x30>
    80004494:	74a2                	ld	s1,40(sp)
    80004496:	7902                	ld	s2,32(sp)
    80004498:	69e2                	ld	s3,24(sp)
    8000449a:	6a42                	ld	s4,16(sp)
    8000449c:	6aa2                	ld	s5,8(sp)
    8000449e:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800044a0:	00004517          	auipc	a0,0x4
    800044a4:	33050513          	addi	a0,a0,816 # 800087d0 <etext+0x7d0>
    800044a8:	852fc0ef          	jal	800004fa <printf>
  return 0;
    800044ac:	4501                	li	a0,0
}
    800044ae:	70e2                	ld	ra,56(sp)
    800044b0:	7442                	ld	s0,48(sp)
    800044b2:	6121                	addi	sp,sp,64
    800044b4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800044b6:	04000613          	li	a2,64
    800044ba:	4581                	li	a1,0
    800044bc:	854e                	mv	a0,s3
    800044be:	ff2fc0ef          	jal	80000cb0 <memset>
      dip->type = type;
    800044c2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800044c6:	8526                	mv	a0,s1
    800044c8:	445000ef          	jal	8000510c <log_write>
      brelse(bp);
    800044cc:	8526                	mv	a0,s1
    800044ce:	b0dff0ef          	jal	80003fda <brelse>
      return iget(dev, inum);
    800044d2:	0009059b          	sext.w	a1,s2
    800044d6:	8556                	mv	a0,s5
    800044d8:	e53ff0ef          	jal	8000432a <iget>
    800044dc:	74a2                	ld	s1,40(sp)
    800044de:	7902                	ld	s2,32(sp)
    800044e0:	69e2                	ld	s3,24(sp)
    800044e2:	6a42                	ld	s4,16(sp)
    800044e4:	6aa2                	ld	s5,8(sp)
    800044e6:	6b02                	ld	s6,0(sp)
    800044e8:	b7d9                	j	800044ae <ialloc+0x80>

00000000800044ea <iupdate>:
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
    800044f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800044f8:	415c                	lw	a5,4(a0)
    800044fa:	0047d79b          	srliw	a5,a5,0x4
    800044fe:	001a9597          	auipc	a1,0x1a9
    80004502:	13a5a583          	lw	a1,314(a1) # 801ad638 <sb+0x18>
    80004506:	9dbd                	addw	a1,a1,a5
    80004508:	4108                	lw	a0,0(a0)
    8000450a:	9c9ff0ef          	jal	80003ed2 <bread>
    8000450e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004510:	05850793          	addi	a5,a0,88
    80004514:	40d8                	lw	a4,4(s1)
    80004516:	8b3d                	andi	a4,a4,15
    80004518:	071a                	slli	a4,a4,0x6
    8000451a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000451c:	04449703          	lh	a4,68(s1)
    80004520:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80004524:	04649703          	lh	a4,70(s1)
    80004528:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000452c:	04849703          	lh	a4,72(s1)
    80004530:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80004534:	04a49703          	lh	a4,74(s1)
    80004538:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000453c:	44f8                	lw	a4,76(s1)
    8000453e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004540:	03400613          	li	a2,52
    80004544:	05048593          	addi	a1,s1,80
    80004548:	00c78513          	addi	a0,a5,12
    8000454c:	fc0fc0ef          	jal	80000d0c <memmove>
  log_write(bp);
    80004550:	854a                	mv	a0,s2
    80004552:	3bb000ef          	jal	8000510c <log_write>
  brelse(bp);
    80004556:	854a                	mv	a0,s2
    80004558:	a83ff0ef          	jal	80003fda <brelse>
}
    8000455c:	60e2                	ld	ra,24(sp)
    8000455e:	6442                	ld	s0,16(sp)
    80004560:	64a2                	ld	s1,8(sp)
    80004562:	6902                	ld	s2,0(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret

0000000080004568 <idup>:
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	1000                	addi	s0,sp,32
    80004572:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004574:	001a9517          	auipc	a0,0x1a9
    80004578:	0cc50513          	addi	a0,a0,204 # 801ad640 <itable>
    8000457c:	e52fc0ef          	jal	80000bce <acquire>
  ip->ref++;
    80004580:	449c                	lw	a5,8(s1)
    80004582:	2785                	addiw	a5,a5,1
    80004584:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004586:	001a9517          	auipc	a0,0x1a9
    8000458a:	0ba50513          	addi	a0,a0,186 # 801ad640 <itable>
    8000458e:	ee6fc0ef          	jal	80000c74 <release>
}
    80004592:	8526                	mv	a0,s1
    80004594:	60e2                	ld	ra,24(sp)
    80004596:	6442                	ld	s0,16(sp)
    80004598:	64a2                	ld	s1,8(sp)
    8000459a:	6105                	addi	sp,sp,32
    8000459c:	8082                	ret

000000008000459e <ilock>:
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800045a8:	cd19                	beqz	a0,800045c6 <ilock+0x28>
    800045aa:	84aa                	mv	s1,a0
    800045ac:	451c                	lw	a5,8(a0)
    800045ae:	00f05c63          	blez	a5,800045c6 <ilock+0x28>
  acquiresleep(&ip->lock);
    800045b2:	0541                	addi	a0,a0,16
    800045b4:	451000ef          	jal	80005204 <acquiresleep>
  if(ip->valid == 0){
    800045b8:	40bc                	lw	a5,64(s1)
    800045ba:	cf89                	beqz	a5,800045d4 <ilock+0x36>
}
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret
    800045c6:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	22050513          	addi	a0,a0,544 # 800087e8 <etext+0x7e8>
    800045d0:	a10fc0ef          	jal	800007e0 <panic>
    800045d4:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800045d6:	40dc                	lw	a5,4(s1)
    800045d8:	0047d79b          	srliw	a5,a5,0x4
    800045dc:	001a9597          	auipc	a1,0x1a9
    800045e0:	05c5a583          	lw	a1,92(a1) # 801ad638 <sb+0x18>
    800045e4:	9dbd                	addw	a1,a1,a5
    800045e6:	4088                	lw	a0,0(s1)
    800045e8:	8ebff0ef          	jal	80003ed2 <bread>
    800045ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800045ee:	05850593          	addi	a1,a0,88
    800045f2:	40dc                	lw	a5,4(s1)
    800045f4:	8bbd                	andi	a5,a5,15
    800045f6:	079a                	slli	a5,a5,0x6
    800045f8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800045fa:	00059783          	lh	a5,0(a1)
    800045fe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004602:	00259783          	lh	a5,2(a1)
    80004606:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000460a:	00459783          	lh	a5,4(a1)
    8000460e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004612:	00659783          	lh	a5,6(a1)
    80004616:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000461a:	459c                	lw	a5,8(a1)
    8000461c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000461e:	03400613          	li	a2,52
    80004622:	05b1                	addi	a1,a1,12
    80004624:	05048513          	addi	a0,s1,80
    80004628:	ee4fc0ef          	jal	80000d0c <memmove>
    brelse(bp);
    8000462c:	854a                	mv	a0,s2
    8000462e:	9adff0ef          	jal	80003fda <brelse>
    ip->valid = 1;
    80004632:	4785                	li	a5,1
    80004634:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004636:	04449783          	lh	a5,68(s1)
    8000463a:	c399                	beqz	a5,80004640 <ilock+0xa2>
    8000463c:	6902                	ld	s2,0(sp)
    8000463e:	bfbd                	j	800045bc <ilock+0x1e>
      panic("ilock: no type");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	1b050513          	addi	a0,a0,432 # 800087f0 <etext+0x7f0>
    80004648:	998fc0ef          	jal	800007e0 <panic>

000000008000464c <iunlock>:
{
    8000464c:	1101                	addi	sp,sp,-32
    8000464e:	ec06                	sd	ra,24(sp)
    80004650:	e822                	sd	s0,16(sp)
    80004652:	e426                	sd	s1,8(sp)
    80004654:	e04a                	sd	s2,0(sp)
    80004656:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004658:	c505                	beqz	a0,80004680 <iunlock+0x34>
    8000465a:	84aa                	mv	s1,a0
    8000465c:	01050913          	addi	s2,a0,16
    80004660:	854a                	mv	a0,s2
    80004662:	421000ef          	jal	80005282 <holdingsleep>
    80004666:	cd09                	beqz	a0,80004680 <iunlock+0x34>
    80004668:	449c                	lw	a5,8(s1)
    8000466a:	00f05b63          	blez	a5,80004680 <iunlock+0x34>
  releasesleep(&ip->lock);
    8000466e:	854a                	mv	a0,s2
    80004670:	3db000ef          	jal	8000524a <releasesleep>
}
    80004674:	60e2                	ld	ra,24(sp)
    80004676:	6442                	ld	s0,16(sp)
    80004678:	64a2                	ld	s1,8(sp)
    8000467a:	6902                	ld	s2,0(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret
    panic("iunlock");
    80004680:	00004517          	auipc	a0,0x4
    80004684:	18050513          	addi	a0,a0,384 # 80008800 <etext+0x800>
    80004688:	958fc0ef          	jal	800007e0 <panic>

000000008000468c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000468c:	7179                	addi	sp,sp,-48
    8000468e:	f406                	sd	ra,40(sp)
    80004690:	f022                	sd	s0,32(sp)
    80004692:	ec26                	sd	s1,24(sp)
    80004694:	e84a                	sd	s2,16(sp)
    80004696:	e44e                	sd	s3,8(sp)
    80004698:	1800                	addi	s0,sp,48
    8000469a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000469c:	05050493          	addi	s1,a0,80
    800046a0:	08050913          	addi	s2,a0,128
    800046a4:	a021                	j	800046ac <itrunc+0x20>
    800046a6:	0491                	addi	s1,s1,4
    800046a8:	01248b63          	beq	s1,s2,800046be <itrunc+0x32>
    if(ip->addrs[i]){
    800046ac:	408c                	lw	a1,0(s1)
    800046ae:	dde5                	beqz	a1,800046a6 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800046b0:	0009a503          	lw	a0,0(s3)
    800046b4:	a17ff0ef          	jal	800040ca <bfree>
      ip->addrs[i] = 0;
    800046b8:	0004a023          	sw	zero,0(s1)
    800046bc:	b7ed                	j	800046a6 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800046be:	0809a583          	lw	a1,128(s3)
    800046c2:	ed89                	bnez	a1,800046dc <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800046c4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800046c8:	854e                	mv	a0,s3
    800046ca:	e21ff0ef          	jal	800044ea <iupdate>
}
    800046ce:	70a2                	ld	ra,40(sp)
    800046d0:	7402                	ld	s0,32(sp)
    800046d2:	64e2                	ld	s1,24(sp)
    800046d4:	6942                	ld	s2,16(sp)
    800046d6:	69a2                	ld	s3,8(sp)
    800046d8:	6145                	addi	sp,sp,48
    800046da:	8082                	ret
    800046dc:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800046de:	0009a503          	lw	a0,0(s3)
    800046e2:	ff0ff0ef          	jal	80003ed2 <bread>
    800046e6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800046e8:	05850493          	addi	s1,a0,88
    800046ec:	45850913          	addi	s2,a0,1112
    800046f0:	a021                	j	800046f8 <itrunc+0x6c>
    800046f2:	0491                	addi	s1,s1,4
    800046f4:	01248963          	beq	s1,s2,80004706 <itrunc+0x7a>
      if(a[j])
    800046f8:	408c                	lw	a1,0(s1)
    800046fa:	dde5                	beqz	a1,800046f2 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800046fc:	0009a503          	lw	a0,0(s3)
    80004700:	9cbff0ef          	jal	800040ca <bfree>
    80004704:	b7fd                	j	800046f2 <itrunc+0x66>
    brelse(bp);
    80004706:	8552                	mv	a0,s4
    80004708:	8d3ff0ef          	jal	80003fda <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000470c:	0809a583          	lw	a1,128(s3)
    80004710:	0009a503          	lw	a0,0(s3)
    80004714:	9b7ff0ef          	jal	800040ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80004718:	0809a023          	sw	zero,128(s3)
    8000471c:	6a02                	ld	s4,0(sp)
    8000471e:	b75d                	j	800046c4 <itrunc+0x38>

0000000080004720 <iput>:
{
    80004720:	1101                	addi	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	1000                	addi	s0,sp,32
    8000472a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000472c:	001a9517          	auipc	a0,0x1a9
    80004730:	f1450513          	addi	a0,a0,-236 # 801ad640 <itable>
    80004734:	c9afc0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004738:	4498                	lw	a4,8(s1)
    8000473a:	4785                	li	a5,1
    8000473c:	02f70063          	beq	a4,a5,8000475c <iput+0x3c>
  ip->ref--;
    80004740:	449c                	lw	a5,8(s1)
    80004742:	37fd                	addiw	a5,a5,-1
    80004744:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004746:	001a9517          	auipc	a0,0x1a9
    8000474a:	efa50513          	addi	a0,a0,-262 # 801ad640 <itable>
    8000474e:	d26fc0ef          	jal	80000c74 <release>
}
    80004752:	60e2                	ld	ra,24(sp)
    80004754:	6442                	ld	s0,16(sp)
    80004756:	64a2                	ld	s1,8(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000475c:	40bc                	lw	a5,64(s1)
    8000475e:	d3ed                	beqz	a5,80004740 <iput+0x20>
    80004760:	04a49783          	lh	a5,74(s1)
    80004764:	fff1                	bnez	a5,80004740 <iput+0x20>
    80004766:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80004768:	01048913          	addi	s2,s1,16
    8000476c:	854a                	mv	a0,s2
    8000476e:	297000ef          	jal	80005204 <acquiresleep>
    release(&itable.lock);
    80004772:	001a9517          	auipc	a0,0x1a9
    80004776:	ece50513          	addi	a0,a0,-306 # 801ad640 <itable>
    8000477a:	cfafc0ef          	jal	80000c74 <release>
    itrunc(ip);
    8000477e:	8526                	mv	a0,s1
    80004780:	f0dff0ef          	jal	8000468c <itrunc>
    ip->type = 0;
    80004784:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004788:	8526                	mv	a0,s1
    8000478a:	d61ff0ef          	jal	800044ea <iupdate>
    ip->valid = 0;
    8000478e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004792:	854a                	mv	a0,s2
    80004794:	2b7000ef          	jal	8000524a <releasesleep>
    acquire(&itable.lock);
    80004798:	001a9517          	auipc	a0,0x1a9
    8000479c:	ea850513          	addi	a0,a0,-344 # 801ad640 <itable>
    800047a0:	c2efc0ef          	jal	80000bce <acquire>
    800047a4:	6902                	ld	s2,0(sp)
    800047a6:	bf69                	j	80004740 <iput+0x20>

00000000800047a8 <iunlockput>:
{
    800047a8:	1101                	addi	sp,sp,-32
    800047aa:	ec06                	sd	ra,24(sp)
    800047ac:	e822                	sd	s0,16(sp)
    800047ae:	e426                	sd	s1,8(sp)
    800047b0:	1000                	addi	s0,sp,32
    800047b2:	84aa                	mv	s1,a0
  iunlock(ip);
    800047b4:	e99ff0ef          	jal	8000464c <iunlock>
  iput(ip);
    800047b8:	8526                	mv	a0,s1
    800047ba:	f67ff0ef          	jal	80004720 <iput>
}
    800047be:	60e2                	ld	ra,24(sp)
    800047c0:	6442                	ld	s0,16(sp)
    800047c2:	64a2                	ld	s1,8(sp)
    800047c4:	6105                	addi	sp,sp,32
    800047c6:	8082                	ret

00000000800047c8 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800047c8:	001a9717          	auipc	a4,0x1a9
    800047cc:	e6472703          	lw	a4,-412(a4) # 801ad62c <sb+0xc>
    800047d0:	4785                	li	a5,1
    800047d2:	0ae7ff63          	bgeu	a5,a4,80004890 <ireclaim+0xc8>
{
    800047d6:	7139                	addi	sp,sp,-64
    800047d8:	fc06                	sd	ra,56(sp)
    800047da:	f822                	sd	s0,48(sp)
    800047dc:	f426                	sd	s1,40(sp)
    800047de:	f04a                	sd	s2,32(sp)
    800047e0:	ec4e                	sd	s3,24(sp)
    800047e2:	e852                	sd	s4,16(sp)
    800047e4:	e456                	sd	s5,8(sp)
    800047e6:	e05a                	sd	s6,0(sp)
    800047e8:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800047ea:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800047ec:	00050a1b          	sext.w	s4,a0
    800047f0:	001a9a97          	auipc	s5,0x1a9
    800047f4:	e30a8a93          	addi	s5,s5,-464 # 801ad620 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800047f8:	00004b17          	auipc	s6,0x4
    800047fc:	010b0b13          	addi	s6,s6,16 # 80008808 <etext+0x808>
    80004800:	a099                	j	80004846 <ireclaim+0x7e>
    80004802:	85ce                	mv	a1,s3
    80004804:	855a                	mv	a0,s6
    80004806:	cf5fb0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    8000480a:	85ce                	mv	a1,s3
    8000480c:	8552                	mv	a0,s4
    8000480e:	b1dff0ef          	jal	8000432a <iget>
    80004812:	89aa                	mv	s3,a0
    brelse(bp);
    80004814:	854a                	mv	a0,s2
    80004816:	fc4ff0ef          	jal	80003fda <brelse>
    if (ip) {
    8000481a:	00098f63          	beqz	s3,80004838 <ireclaim+0x70>
      begin_op();
    8000481e:	76a000ef          	jal	80004f88 <begin_op>
      ilock(ip);
    80004822:	854e                	mv	a0,s3
    80004824:	d7bff0ef          	jal	8000459e <ilock>
      iunlock(ip);
    80004828:	854e                	mv	a0,s3
    8000482a:	e23ff0ef          	jal	8000464c <iunlock>
      iput(ip);
    8000482e:	854e                	mv	a0,s3
    80004830:	ef1ff0ef          	jal	80004720 <iput>
      end_op();
    80004834:	7be000ef          	jal	80004ff2 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80004838:	0485                	addi	s1,s1,1
    8000483a:	00caa703          	lw	a4,12(s5)
    8000483e:	0004879b          	sext.w	a5,s1
    80004842:	02e7fd63          	bgeu	a5,a4,8000487c <ireclaim+0xb4>
    80004846:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000484a:	0044d593          	srli	a1,s1,0x4
    8000484e:	018aa783          	lw	a5,24(s5)
    80004852:	9dbd                	addw	a1,a1,a5
    80004854:	8552                	mv	a0,s4
    80004856:	e7cff0ef          	jal	80003ed2 <bread>
    8000485a:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000485c:	05850793          	addi	a5,a0,88
    80004860:	00f9f713          	andi	a4,s3,15
    80004864:	071a                	slli	a4,a4,0x6
    80004866:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80004868:	00079703          	lh	a4,0(a5)
    8000486c:	c701                	beqz	a4,80004874 <ireclaim+0xac>
    8000486e:	00679783          	lh	a5,6(a5)
    80004872:	dbc1                	beqz	a5,80004802 <ireclaim+0x3a>
    brelse(bp);
    80004874:	854a                	mv	a0,s2
    80004876:	f64ff0ef          	jal	80003fda <brelse>
    if (ip) {
    8000487a:	bf7d                	j	80004838 <ireclaim+0x70>
}
    8000487c:	70e2                	ld	ra,56(sp)
    8000487e:	7442                	ld	s0,48(sp)
    80004880:	74a2                	ld	s1,40(sp)
    80004882:	7902                	ld	s2,32(sp)
    80004884:	69e2                	ld	s3,24(sp)
    80004886:	6a42                	ld	s4,16(sp)
    80004888:	6aa2                	ld	s5,8(sp)
    8000488a:	6b02                	ld	s6,0(sp)
    8000488c:	6121                	addi	sp,sp,64
    8000488e:	8082                	ret
    80004890:	8082                	ret

0000000080004892 <fsinit>:
fsinit(int dev) {
    80004892:	7179                	addi	sp,sp,-48
    80004894:	f406                	sd	ra,40(sp)
    80004896:	f022                	sd	s0,32(sp)
    80004898:	ec26                	sd	s1,24(sp)
    8000489a:	e84a                	sd	s2,16(sp)
    8000489c:	e44e                	sd	s3,8(sp)
    8000489e:	1800                	addi	s0,sp,48
    800048a0:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800048a2:	4585                	li	a1,1
    800048a4:	e2eff0ef          	jal	80003ed2 <bread>
    800048a8:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800048aa:	001a9997          	auipc	s3,0x1a9
    800048ae:	d7698993          	addi	s3,s3,-650 # 801ad620 <sb>
    800048b2:	02000613          	li	a2,32
    800048b6:	05850593          	addi	a1,a0,88
    800048ba:	854e                	mv	a0,s3
    800048bc:	c50fc0ef          	jal	80000d0c <memmove>
  brelse(bp);
    800048c0:	854a                	mv	a0,s2
    800048c2:	f18ff0ef          	jal	80003fda <brelse>
  if(sb.magic != FSMAGIC)
    800048c6:	0009a703          	lw	a4,0(s3)
    800048ca:	102037b7          	lui	a5,0x10203
    800048ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800048d2:	02f71363          	bne	a4,a5,800048f8 <fsinit+0x66>
  initlog(dev, &sb);
    800048d6:	001a9597          	auipc	a1,0x1a9
    800048da:	d4a58593          	addi	a1,a1,-694 # 801ad620 <sb>
    800048de:	8526                	mv	a0,s1
    800048e0:	62a000ef          	jal	80004f0a <initlog>
  ireclaim(dev);
    800048e4:	8526                	mv	a0,s1
    800048e6:	ee3ff0ef          	jal	800047c8 <ireclaim>
}
    800048ea:	70a2                	ld	ra,40(sp)
    800048ec:	7402                	ld	s0,32(sp)
    800048ee:	64e2                	ld	s1,24(sp)
    800048f0:	6942                	ld	s2,16(sp)
    800048f2:	69a2                	ld	s3,8(sp)
    800048f4:	6145                	addi	sp,sp,48
    800048f6:	8082                	ret
    panic("invalid file system");
    800048f8:	00004517          	auipc	a0,0x4
    800048fc:	f3050513          	addi	a0,a0,-208 # 80008828 <etext+0x828>
    80004900:	ee1fb0ef          	jal	800007e0 <panic>

0000000080004904 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004904:	1141                	addi	sp,sp,-16
    80004906:	e422                	sd	s0,8(sp)
    80004908:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000490a:	411c                	lw	a5,0(a0)
    8000490c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000490e:	415c                	lw	a5,4(a0)
    80004910:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004912:	04451783          	lh	a5,68(a0)
    80004916:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000491a:	04a51783          	lh	a5,74(a0)
    8000491e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004922:	04c56783          	lwu	a5,76(a0)
    80004926:	e99c                	sd	a5,16(a1)
}
    80004928:	6422                	ld	s0,8(sp)
    8000492a:	0141                	addi	sp,sp,16
    8000492c:	8082                	ret

000000008000492e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000492e:	457c                	lw	a5,76(a0)
    80004930:	0ed7eb63          	bltu	a5,a3,80004a26 <readi+0xf8>
{
    80004934:	7159                	addi	sp,sp,-112
    80004936:	f486                	sd	ra,104(sp)
    80004938:	f0a2                	sd	s0,96(sp)
    8000493a:	eca6                	sd	s1,88(sp)
    8000493c:	e0d2                	sd	s4,64(sp)
    8000493e:	fc56                	sd	s5,56(sp)
    80004940:	f85a                	sd	s6,48(sp)
    80004942:	f45e                	sd	s7,40(sp)
    80004944:	1880                	addi	s0,sp,112
    80004946:	8b2a                	mv	s6,a0
    80004948:	8bae                	mv	s7,a1
    8000494a:	8a32                	mv	s4,a2
    8000494c:	84b6                	mv	s1,a3
    8000494e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004950:	9f35                	addw	a4,a4,a3
    return 0;
    80004952:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004954:	0cd76063          	bltu	a4,a3,80004a14 <readi+0xe6>
    80004958:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    8000495a:	00e7f463          	bgeu	a5,a4,80004962 <readi+0x34>
    n = ip->size - off;
    8000495e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004962:	080a8f63          	beqz	s5,80004a00 <readi+0xd2>
    80004966:	e8ca                	sd	s2,80(sp)
    80004968:	f062                	sd	s8,32(sp)
    8000496a:	ec66                	sd	s9,24(sp)
    8000496c:	e86a                	sd	s10,16(sp)
    8000496e:	e46e                	sd	s11,8(sp)
    80004970:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004972:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004976:	5c7d                	li	s8,-1
    80004978:	a80d                	j	800049aa <readi+0x7c>
    8000497a:	020d1d93          	slli	s11,s10,0x20
    8000497e:	020ddd93          	srli	s11,s11,0x20
    80004982:	05890613          	addi	a2,s2,88
    80004986:	86ee                	mv	a3,s11
    80004988:	963a                	add	a2,a2,a4
    8000498a:	85d2                	mv	a1,s4
    8000498c:	855e                	mv	a0,s7
    8000498e:	8edfe0ef          	jal	8000327a <either_copyout>
    80004992:	05850763          	beq	a0,s8,800049e0 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004996:	854a                	mv	a0,s2
    80004998:	e42ff0ef          	jal	80003fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000499c:	013d09bb          	addw	s3,s10,s3
    800049a0:	009d04bb          	addw	s1,s10,s1
    800049a4:	9a6e                	add	s4,s4,s11
    800049a6:	0559f763          	bgeu	s3,s5,800049f4 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    800049aa:	00a4d59b          	srliw	a1,s1,0xa
    800049ae:	855a                	mv	a0,s6
    800049b0:	8a7ff0ef          	jal	80004256 <bmap>
    800049b4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800049b8:	c5b1                	beqz	a1,80004a04 <readi+0xd6>
    bp = bread(ip->dev, addr);
    800049ba:	000b2503          	lw	a0,0(s6)
    800049be:	d14ff0ef          	jal	80003ed2 <bread>
    800049c2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800049c4:	3ff4f713          	andi	a4,s1,1023
    800049c8:	40ec87bb          	subw	a5,s9,a4
    800049cc:	413a86bb          	subw	a3,s5,s3
    800049d0:	8d3e                	mv	s10,a5
    800049d2:	2781                	sext.w	a5,a5
    800049d4:	0006861b          	sext.w	a2,a3
    800049d8:	faf671e3          	bgeu	a2,a5,8000497a <readi+0x4c>
    800049dc:	8d36                	mv	s10,a3
    800049de:	bf71                	j	8000497a <readi+0x4c>
      brelse(bp);
    800049e0:	854a                	mv	a0,s2
    800049e2:	df8ff0ef          	jal	80003fda <brelse>
      tot = -1;
    800049e6:	59fd                	li	s3,-1
      break;
    800049e8:	6946                	ld	s2,80(sp)
    800049ea:	7c02                	ld	s8,32(sp)
    800049ec:	6ce2                	ld	s9,24(sp)
    800049ee:	6d42                	ld	s10,16(sp)
    800049f0:	6da2                	ld	s11,8(sp)
    800049f2:	a831                	j	80004a0e <readi+0xe0>
    800049f4:	6946                	ld	s2,80(sp)
    800049f6:	7c02                	ld	s8,32(sp)
    800049f8:	6ce2                	ld	s9,24(sp)
    800049fa:	6d42                	ld	s10,16(sp)
    800049fc:	6da2                	ld	s11,8(sp)
    800049fe:	a801                	j	80004a0e <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a00:	89d6                	mv	s3,s5
    80004a02:	a031                	j	80004a0e <readi+0xe0>
    80004a04:	6946                	ld	s2,80(sp)
    80004a06:	7c02                	ld	s8,32(sp)
    80004a08:	6ce2                	ld	s9,24(sp)
    80004a0a:	6d42                	ld	s10,16(sp)
    80004a0c:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80004a0e:	0009851b          	sext.w	a0,s3
    80004a12:	69a6                	ld	s3,72(sp)
}
    80004a14:	70a6                	ld	ra,104(sp)
    80004a16:	7406                	ld	s0,96(sp)
    80004a18:	64e6                	ld	s1,88(sp)
    80004a1a:	6a06                	ld	s4,64(sp)
    80004a1c:	7ae2                	ld	s5,56(sp)
    80004a1e:	7b42                	ld	s6,48(sp)
    80004a20:	7ba2                	ld	s7,40(sp)
    80004a22:	6165                	addi	sp,sp,112
    80004a24:	8082                	ret
    return 0;
    80004a26:	4501                	li	a0,0
}
    80004a28:	8082                	ret

0000000080004a2a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004a2a:	457c                	lw	a5,76(a0)
    80004a2c:	10d7e063          	bltu	a5,a3,80004b2c <writei+0x102>
{
    80004a30:	7159                	addi	sp,sp,-112
    80004a32:	f486                	sd	ra,104(sp)
    80004a34:	f0a2                	sd	s0,96(sp)
    80004a36:	e8ca                	sd	s2,80(sp)
    80004a38:	e0d2                	sd	s4,64(sp)
    80004a3a:	fc56                	sd	s5,56(sp)
    80004a3c:	f85a                	sd	s6,48(sp)
    80004a3e:	f45e                	sd	s7,40(sp)
    80004a40:	1880                	addi	s0,sp,112
    80004a42:	8aaa                	mv	s5,a0
    80004a44:	8bae                	mv	s7,a1
    80004a46:	8a32                	mv	s4,a2
    80004a48:	8936                	mv	s2,a3
    80004a4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004a4c:	00e687bb          	addw	a5,a3,a4
    80004a50:	0ed7e063          	bltu	a5,a3,80004b30 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004a54:	00043737          	lui	a4,0x43
    80004a58:	0cf76e63          	bltu	a4,a5,80004b34 <writei+0x10a>
    80004a5c:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004a5e:	0a0b0f63          	beqz	s6,80004b1c <writei+0xf2>
    80004a62:	eca6                	sd	s1,88(sp)
    80004a64:	f062                	sd	s8,32(sp)
    80004a66:	ec66                	sd	s9,24(sp)
    80004a68:	e86a                	sd	s10,16(sp)
    80004a6a:	e46e                	sd	s11,8(sp)
    80004a6c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a6e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004a72:	5c7d                	li	s8,-1
    80004a74:	a825                	j	80004aac <writei+0x82>
    80004a76:	020d1d93          	slli	s11,s10,0x20
    80004a7a:	020ddd93          	srli	s11,s11,0x20
    80004a7e:	05848513          	addi	a0,s1,88
    80004a82:	86ee                	mv	a3,s11
    80004a84:	8652                	mv	a2,s4
    80004a86:	85de                	mv	a1,s7
    80004a88:	953a                	add	a0,a0,a4
    80004a8a:	83bfe0ef          	jal	800032c4 <either_copyin>
    80004a8e:	05850a63          	beq	a0,s8,80004ae2 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004a92:	8526                	mv	a0,s1
    80004a94:	678000ef          	jal	8000510c <log_write>
    brelse(bp);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	d40ff0ef          	jal	80003fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004a9e:	013d09bb          	addw	s3,s10,s3
    80004aa2:	012d093b          	addw	s2,s10,s2
    80004aa6:	9a6e                	add	s4,s4,s11
    80004aa8:	0569f063          	bgeu	s3,s6,80004ae8 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80004aac:	00a9559b          	srliw	a1,s2,0xa
    80004ab0:	8556                	mv	a0,s5
    80004ab2:	fa4ff0ef          	jal	80004256 <bmap>
    80004ab6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004aba:	c59d                	beqz	a1,80004ae8 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80004abc:	000aa503          	lw	a0,0(s5)
    80004ac0:	c12ff0ef          	jal	80003ed2 <bread>
    80004ac4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004ac6:	3ff97713          	andi	a4,s2,1023
    80004aca:	40ec87bb          	subw	a5,s9,a4
    80004ace:	413b06bb          	subw	a3,s6,s3
    80004ad2:	8d3e                	mv	s10,a5
    80004ad4:	2781                	sext.w	a5,a5
    80004ad6:	0006861b          	sext.w	a2,a3
    80004ada:	f8f67ee3          	bgeu	a2,a5,80004a76 <writei+0x4c>
    80004ade:	8d36                	mv	s10,a3
    80004ae0:	bf59                	j	80004a76 <writei+0x4c>
      brelse(bp);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	cf6ff0ef          	jal	80003fda <brelse>
  }

  if(off > ip->size)
    80004ae8:	04caa783          	lw	a5,76(s5)
    80004aec:	0327fa63          	bgeu	a5,s2,80004b20 <writei+0xf6>
    ip->size = off;
    80004af0:	052aa623          	sw	s2,76(s5)
    80004af4:	64e6                	ld	s1,88(sp)
    80004af6:	7c02                	ld	s8,32(sp)
    80004af8:	6ce2                	ld	s9,24(sp)
    80004afa:	6d42                	ld	s10,16(sp)
    80004afc:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004afe:	8556                	mv	a0,s5
    80004b00:	9ebff0ef          	jal	800044ea <iupdate>

  return tot;
    80004b04:	0009851b          	sext.w	a0,s3
    80004b08:	69a6                	ld	s3,72(sp)
}
    80004b0a:	70a6                	ld	ra,104(sp)
    80004b0c:	7406                	ld	s0,96(sp)
    80004b0e:	6946                	ld	s2,80(sp)
    80004b10:	6a06                	ld	s4,64(sp)
    80004b12:	7ae2                	ld	s5,56(sp)
    80004b14:	7b42                	ld	s6,48(sp)
    80004b16:	7ba2                	ld	s7,40(sp)
    80004b18:	6165                	addi	sp,sp,112
    80004b1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b1c:	89da                	mv	s3,s6
    80004b1e:	b7c5                	j	80004afe <writei+0xd4>
    80004b20:	64e6                	ld	s1,88(sp)
    80004b22:	7c02                	ld	s8,32(sp)
    80004b24:	6ce2                	ld	s9,24(sp)
    80004b26:	6d42                	ld	s10,16(sp)
    80004b28:	6da2                	ld	s11,8(sp)
    80004b2a:	bfd1                	j	80004afe <writei+0xd4>
    return -1;
    80004b2c:	557d                	li	a0,-1
}
    80004b2e:	8082                	ret
    return -1;
    80004b30:	557d                	li	a0,-1
    80004b32:	bfe1                	j	80004b0a <writei+0xe0>
    return -1;
    80004b34:	557d                	li	a0,-1
    80004b36:	bfd1                	j	80004b0a <writei+0xe0>

0000000080004b38 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004b38:	1141                	addi	sp,sp,-16
    80004b3a:	e406                	sd	ra,8(sp)
    80004b3c:	e022                	sd	s0,0(sp)
    80004b3e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004b40:	4639                	li	a2,14
    80004b42:	a3afc0ef          	jal	80000d7c <strncmp>
}
    80004b46:	60a2                	ld	ra,8(sp)
    80004b48:	6402                	ld	s0,0(sp)
    80004b4a:	0141                	addi	sp,sp,16
    80004b4c:	8082                	ret

0000000080004b4e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004b4e:	7139                	addi	sp,sp,-64
    80004b50:	fc06                	sd	ra,56(sp)
    80004b52:	f822                	sd	s0,48(sp)
    80004b54:	f426                	sd	s1,40(sp)
    80004b56:	f04a                	sd	s2,32(sp)
    80004b58:	ec4e                	sd	s3,24(sp)
    80004b5a:	e852                	sd	s4,16(sp)
    80004b5c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004b5e:	04451703          	lh	a4,68(a0)
    80004b62:	4785                	li	a5,1
    80004b64:	00f71a63          	bne	a4,a5,80004b78 <dirlookup+0x2a>
    80004b68:	892a                	mv	s2,a0
    80004b6a:	89ae                	mv	s3,a1
    80004b6c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b6e:	457c                	lw	a5,76(a0)
    80004b70:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004b72:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b74:	e39d                	bnez	a5,80004b9a <dirlookup+0x4c>
    80004b76:	a095                	j	80004bda <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80004b78:	00004517          	auipc	a0,0x4
    80004b7c:	cc850513          	addi	a0,a0,-824 # 80008840 <etext+0x840>
    80004b80:	c61fb0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80004b84:	00004517          	auipc	a0,0x4
    80004b88:	cd450513          	addi	a0,a0,-812 # 80008858 <etext+0x858>
    80004b8c:	c55fb0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b90:	24c1                	addiw	s1,s1,16
    80004b92:	04c92783          	lw	a5,76(s2)
    80004b96:	04f4f163          	bgeu	s1,a5,80004bd8 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b9a:	4741                	li	a4,16
    80004b9c:	86a6                	mv	a3,s1
    80004b9e:	fc040613          	addi	a2,s0,-64
    80004ba2:	4581                	li	a1,0
    80004ba4:	854a                	mv	a0,s2
    80004ba6:	d89ff0ef          	jal	8000492e <readi>
    80004baa:	47c1                	li	a5,16
    80004bac:	fcf51ce3          	bne	a0,a5,80004b84 <dirlookup+0x36>
    if(de.inum == 0)
    80004bb0:	fc045783          	lhu	a5,-64(s0)
    80004bb4:	dff1                	beqz	a5,80004b90 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80004bb6:	fc240593          	addi	a1,s0,-62
    80004bba:	854e                	mv	a0,s3
    80004bbc:	f7dff0ef          	jal	80004b38 <namecmp>
    80004bc0:	f961                	bnez	a0,80004b90 <dirlookup+0x42>
      if(poff)
    80004bc2:	000a0463          	beqz	s4,80004bca <dirlookup+0x7c>
        *poff = off;
    80004bc6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004bca:	fc045583          	lhu	a1,-64(s0)
    80004bce:	00092503          	lw	a0,0(s2)
    80004bd2:	f58ff0ef          	jal	8000432a <iget>
    80004bd6:	a011                	j	80004bda <dirlookup+0x8c>
  return 0;
    80004bd8:	4501                	li	a0,0
}
    80004bda:	70e2                	ld	ra,56(sp)
    80004bdc:	7442                	ld	s0,48(sp)
    80004bde:	74a2                	ld	s1,40(sp)
    80004be0:	7902                	ld	s2,32(sp)
    80004be2:	69e2                	ld	s3,24(sp)
    80004be4:	6a42                	ld	s4,16(sp)
    80004be6:	6121                	addi	sp,sp,64
    80004be8:	8082                	ret

0000000080004bea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004bea:	711d                	addi	sp,sp,-96
    80004bec:	ec86                	sd	ra,88(sp)
    80004bee:	e8a2                	sd	s0,80(sp)
    80004bf0:	e4a6                	sd	s1,72(sp)
    80004bf2:	e0ca                	sd	s2,64(sp)
    80004bf4:	fc4e                	sd	s3,56(sp)
    80004bf6:	f852                	sd	s4,48(sp)
    80004bf8:	f456                	sd	s5,40(sp)
    80004bfa:	f05a                	sd	s6,32(sp)
    80004bfc:	ec5e                	sd	s7,24(sp)
    80004bfe:	e862                	sd	s8,16(sp)
    80004c00:	e466                	sd	s9,8(sp)
    80004c02:	1080                	addi	s0,sp,96
    80004c04:	84aa                	mv	s1,a0
    80004c06:	8b2e                	mv	s6,a1
    80004c08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004c0a:	00054703          	lbu	a4,0(a0)
    80004c0e:	02f00793          	li	a5,47
    80004c12:	00f70e63          	beq	a4,a5,80004c2e <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004c16:	813fd0ef          	jal	80002428 <myproc>
    80004c1a:	15053503          	ld	a0,336(a0)
    80004c1e:	94bff0ef          	jal	80004568 <idup>
    80004c22:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004c24:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004c28:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004c2a:	4b85                	li	s7,1
    80004c2c:	a871                	j	80004cc8 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80004c2e:	4585                	li	a1,1
    80004c30:	4505                	li	a0,1
    80004c32:	ef8ff0ef          	jal	8000432a <iget>
    80004c36:	8a2a                	mv	s4,a0
    80004c38:	b7f5                	j	80004c24 <namex+0x3a>
      iunlockput(ip);
    80004c3a:	8552                	mv	a0,s4
    80004c3c:	b6dff0ef          	jal	800047a8 <iunlockput>
      return 0;
    80004c40:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004c42:	8552                	mv	a0,s4
    80004c44:	60e6                	ld	ra,88(sp)
    80004c46:	6446                	ld	s0,80(sp)
    80004c48:	64a6                	ld	s1,72(sp)
    80004c4a:	6906                	ld	s2,64(sp)
    80004c4c:	79e2                	ld	s3,56(sp)
    80004c4e:	7a42                	ld	s4,48(sp)
    80004c50:	7aa2                	ld	s5,40(sp)
    80004c52:	7b02                	ld	s6,32(sp)
    80004c54:	6be2                	ld	s7,24(sp)
    80004c56:	6c42                	ld	s8,16(sp)
    80004c58:	6ca2                	ld	s9,8(sp)
    80004c5a:	6125                	addi	sp,sp,96
    80004c5c:	8082                	ret
      iunlock(ip);
    80004c5e:	8552                	mv	a0,s4
    80004c60:	9edff0ef          	jal	8000464c <iunlock>
      return ip;
    80004c64:	bff9                	j	80004c42 <namex+0x58>
      iunlockput(ip);
    80004c66:	8552                	mv	a0,s4
    80004c68:	b41ff0ef          	jal	800047a8 <iunlockput>
      return 0;
    80004c6c:	8a4e                	mv	s4,s3
    80004c6e:	bfd1                	j	80004c42 <namex+0x58>
  len = path - s;
    80004c70:	40998633          	sub	a2,s3,s1
    80004c74:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004c78:	099c5063          	bge	s8,s9,80004cf8 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80004c7c:	4639                	li	a2,14
    80004c7e:	85a6                	mv	a1,s1
    80004c80:	8556                	mv	a0,s5
    80004c82:	88afc0ef          	jal	80000d0c <memmove>
    80004c86:	84ce                	mv	s1,s3
  while(*path == '/')
    80004c88:	0004c783          	lbu	a5,0(s1)
    80004c8c:	01279763          	bne	a5,s2,80004c9a <namex+0xb0>
    path++;
    80004c90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004c92:	0004c783          	lbu	a5,0(s1)
    80004c96:	ff278de3          	beq	a5,s2,80004c90 <namex+0xa6>
    ilock(ip);
    80004c9a:	8552                	mv	a0,s4
    80004c9c:	903ff0ef          	jal	8000459e <ilock>
    if(ip->type != T_DIR){
    80004ca0:	044a1783          	lh	a5,68(s4)
    80004ca4:	f9779be3          	bne	a5,s7,80004c3a <namex+0x50>
    if(nameiparent && *path == '\0'){
    80004ca8:	000b0563          	beqz	s6,80004cb2 <namex+0xc8>
    80004cac:	0004c783          	lbu	a5,0(s1)
    80004cb0:	d7dd                	beqz	a5,80004c5e <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004cb2:	4601                	li	a2,0
    80004cb4:	85d6                	mv	a1,s5
    80004cb6:	8552                	mv	a0,s4
    80004cb8:	e97ff0ef          	jal	80004b4e <dirlookup>
    80004cbc:	89aa                	mv	s3,a0
    80004cbe:	d545                	beqz	a0,80004c66 <namex+0x7c>
    iunlockput(ip);
    80004cc0:	8552                	mv	a0,s4
    80004cc2:	ae7ff0ef          	jal	800047a8 <iunlockput>
    ip = next;
    80004cc6:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004cc8:	0004c783          	lbu	a5,0(s1)
    80004ccc:	01279763          	bne	a5,s2,80004cda <namex+0xf0>
    path++;
    80004cd0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004cd2:	0004c783          	lbu	a5,0(s1)
    80004cd6:	ff278de3          	beq	a5,s2,80004cd0 <namex+0xe6>
  if(*path == 0)
    80004cda:	cb8d                	beqz	a5,80004d0c <namex+0x122>
  while(*path != '/' && *path != 0)
    80004cdc:	0004c783          	lbu	a5,0(s1)
    80004ce0:	89a6                	mv	s3,s1
  len = path - s;
    80004ce2:	4c81                	li	s9,0
    80004ce4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004ce6:	01278963          	beq	a5,s2,80004cf8 <namex+0x10e>
    80004cea:	d3d9                	beqz	a5,80004c70 <namex+0x86>
    path++;
    80004cec:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004cee:	0009c783          	lbu	a5,0(s3)
    80004cf2:	ff279ce3          	bne	a5,s2,80004cea <namex+0x100>
    80004cf6:	bfad                	j	80004c70 <namex+0x86>
    memmove(name, s, len);
    80004cf8:	2601                	sext.w	a2,a2
    80004cfa:	85a6                	mv	a1,s1
    80004cfc:	8556                	mv	a0,s5
    80004cfe:	80efc0ef          	jal	80000d0c <memmove>
    name[len] = 0;
    80004d02:	9cd6                	add	s9,s9,s5
    80004d04:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004d08:	84ce                	mv	s1,s3
    80004d0a:	bfbd                	j	80004c88 <namex+0x9e>
  if(nameiparent){
    80004d0c:	f20b0be3          	beqz	s6,80004c42 <namex+0x58>
    iput(ip);
    80004d10:	8552                	mv	a0,s4
    80004d12:	a0fff0ef          	jal	80004720 <iput>
    return 0;
    80004d16:	4a01                	li	s4,0
    80004d18:	b72d                	j	80004c42 <namex+0x58>

0000000080004d1a <dirlink>:
{
    80004d1a:	7139                	addi	sp,sp,-64
    80004d1c:	fc06                	sd	ra,56(sp)
    80004d1e:	f822                	sd	s0,48(sp)
    80004d20:	f04a                	sd	s2,32(sp)
    80004d22:	ec4e                	sd	s3,24(sp)
    80004d24:	e852                	sd	s4,16(sp)
    80004d26:	0080                	addi	s0,sp,64
    80004d28:	892a                	mv	s2,a0
    80004d2a:	8a2e                	mv	s4,a1
    80004d2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004d2e:	4601                	li	a2,0
    80004d30:	e1fff0ef          	jal	80004b4e <dirlookup>
    80004d34:	e535                	bnez	a0,80004da0 <dirlink+0x86>
    80004d36:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004d38:	04c92483          	lw	s1,76(s2)
    80004d3c:	c48d                	beqz	s1,80004d66 <dirlink+0x4c>
    80004d3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d40:	4741                	li	a4,16
    80004d42:	86a6                	mv	a3,s1
    80004d44:	fc040613          	addi	a2,s0,-64
    80004d48:	4581                	li	a1,0
    80004d4a:	854a                	mv	a0,s2
    80004d4c:	be3ff0ef          	jal	8000492e <readi>
    80004d50:	47c1                	li	a5,16
    80004d52:	04f51b63          	bne	a0,a5,80004da8 <dirlink+0x8e>
    if(de.inum == 0)
    80004d56:	fc045783          	lhu	a5,-64(s0)
    80004d5a:	c791                	beqz	a5,80004d66 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004d5c:	24c1                	addiw	s1,s1,16
    80004d5e:	04c92783          	lw	a5,76(s2)
    80004d62:	fcf4efe3          	bltu	s1,a5,80004d40 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80004d66:	4639                	li	a2,14
    80004d68:	85d2                	mv	a1,s4
    80004d6a:	fc240513          	addi	a0,s0,-62
    80004d6e:	844fc0ef          	jal	80000db2 <strncpy>
  de.inum = inum;
    80004d72:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d76:	4741                	li	a4,16
    80004d78:	86a6                	mv	a3,s1
    80004d7a:	fc040613          	addi	a2,s0,-64
    80004d7e:	4581                	li	a1,0
    80004d80:	854a                	mv	a0,s2
    80004d82:	ca9ff0ef          	jal	80004a2a <writei>
    80004d86:	1541                	addi	a0,a0,-16
    80004d88:	00a03533          	snez	a0,a0
    80004d8c:	40a00533          	neg	a0,a0
    80004d90:	74a2                	ld	s1,40(sp)
}
    80004d92:	70e2                	ld	ra,56(sp)
    80004d94:	7442                	ld	s0,48(sp)
    80004d96:	7902                	ld	s2,32(sp)
    80004d98:	69e2                	ld	s3,24(sp)
    80004d9a:	6a42                	ld	s4,16(sp)
    80004d9c:	6121                	addi	sp,sp,64
    80004d9e:	8082                	ret
    iput(ip);
    80004da0:	981ff0ef          	jal	80004720 <iput>
    return -1;
    80004da4:	557d                	li	a0,-1
    80004da6:	b7f5                	j	80004d92 <dirlink+0x78>
      panic("dirlink read");
    80004da8:	00004517          	auipc	a0,0x4
    80004dac:	ac050513          	addi	a0,a0,-1344 # 80008868 <etext+0x868>
    80004db0:	a31fb0ef          	jal	800007e0 <panic>

0000000080004db4 <namei>:

struct inode*
namei(char *path)
{
    80004db4:	1101                	addi	sp,sp,-32
    80004db6:	ec06                	sd	ra,24(sp)
    80004db8:	e822                	sd	s0,16(sp)
    80004dba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004dbc:	fe040613          	addi	a2,s0,-32
    80004dc0:	4581                	li	a1,0
    80004dc2:	e29ff0ef          	jal	80004bea <namex>
}
    80004dc6:	60e2                	ld	ra,24(sp)
    80004dc8:	6442                	ld	s0,16(sp)
    80004dca:	6105                	addi	sp,sp,32
    80004dcc:	8082                	ret

0000000080004dce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004dce:	1141                	addi	sp,sp,-16
    80004dd0:	e406                	sd	ra,8(sp)
    80004dd2:	e022                	sd	s0,0(sp)
    80004dd4:	0800                	addi	s0,sp,16
    80004dd6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004dd8:	4585                	li	a1,1
    80004dda:	e11ff0ef          	jal	80004bea <namex>
}
    80004dde:	60a2                	ld	ra,8(sp)
    80004de0:	6402                	ld	s0,0(sp)
    80004de2:	0141                	addi	sp,sp,16
    80004de4:	8082                	ret

0000000080004de6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004de6:	1101                	addi	sp,sp,-32
    80004de8:	ec06                	sd	ra,24(sp)
    80004dea:	e822                	sd	s0,16(sp)
    80004dec:	e426                	sd	s1,8(sp)
    80004dee:	e04a                	sd	s2,0(sp)
    80004df0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004df2:	001aa917          	auipc	s2,0x1aa
    80004df6:	2f690913          	addi	s2,s2,758 # 801af0e8 <log>
    80004dfa:	01892583          	lw	a1,24(s2)
    80004dfe:	02492503          	lw	a0,36(s2)
    80004e02:	8d0ff0ef          	jal	80003ed2 <bread>
    80004e06:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004e08:	02892603          	lw	a2,40(s2)
    80004e0c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004e0e:	00c05f63          	blez	a2,80004e2c <write_head+0x46>
    80004e12:	001aa717          	auipc	a4,0x1aa
    80004e16:	30270713          	addi	a4,a4,770 # 801af114 <log+0x2c>
    80004e1a:	87aa                	mv	a5,a0
    80004e1c:	060a                	slli	a2,a2,0x2
    80004e1e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004e20:	4314                	lw	a3,0(a4)
    80004e22:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004e24:	0711                	addi	a4,a4,4
    80004e26:	0791                	addi	a5,a5,4
    80004e28:	fec79ce3          	bne	a5,a2,80004e20 <write_head+0x3a>
  }
  bwrite(buf);
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	97aff0ef          	jal	80003fa8 <bwrite>
  brelse(buf);
    80004e32:	8526                	mv	a0,s1
    80004e34:	9a6ff0ef          	jal	80003fda <brelse>
}
    80004e38:	60e2                	ld	ra,24(sp)
    80004e3a:	6442                	ld	s0,16(sp)
    80004e3c:	64a2                	ld	s1,8(sp)
    80004e3e:	6902                	ld	s2,0(sp)
    80004e40:	6105                	addi	sp,sp,32
    80004e42:	8082                	ret

0000000080004e44 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e44:	001aa797          	auipc	a5,0x1aa
    80004e48:	2cc7a783          	lw	a5,716(a5) # 801af110 <log+0x28>
    80004e4c:	0af05e63          	blez	a5,80004f08 <install_trans+0xc4>
{
    80004e50:	715d                	addi	sp,sp,-80
    80004e52:	e486                	sd	ra,72(sp)
    80004e54:	e0a2                	sd	s0,64(sp)
    80004e56:	fc26                	sd	s1,56(sp)
    80004e58:	f84a                	sd	s2,48(sp)
    80004e5a:	f44e                	sd	s3,40(sp)
    80004e5c:	f052                	sd	s4,32(sp)
    80004e5e:	ec56                	sd	s5,24(sp)
    80004e60:	e85a                	sd	s6,16(sp)
    80004e62:	e45e                	sd	s7,8(sp)
    80004e64:	0880                	addi	s0,sp,80
    80004e66:	8b2a                	mv	s6,a0
    80004e68:	001aaa97          	auipc	s5,0x1aa
    80004e6c:	2aca8a93          	addi	s5,s5,684 # 801af114 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e70:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80004e72:	00004b97          	auipc	s7,0x4
    80004e76:	a06b8b93          	addi	s7,s7,-1530 # 80008878 <etext+0x878>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004e7a:	001aaa17          	auipc	s4,0x1aa
    80004e7e:	26ea0a13          	addi	s4,s4,622 # 801af0e8 <log>
    80004e82:	a025                	j	80004eaa <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80004e84:	000aa603          	lw	a2,0(s5)
    80004e88:	85ce                	mv	a1,s3
    80004e8a:	855e                	mv	a0,s7
    80004e8c:	e6efb0ef          	jal	800004fa <printf>
    80004e90:	a839                	j	80004eae <install_trans+0x6a>
    brelse(lbuf);
    80004e92:	854a                	mv	a0,s2
    80004e94:	946ff0ef          	jal	80003fda <brelse>
    brelse(dbuf);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	940ff0ef          	jal	80003fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e9e:	2985                	addiw	s3,s3,1
    80004ea0:	0a91                	addi	s5,s5,4
    80004ea2:	028a2783          	lw	a5,40(s4)
    80004ea6:	04f9d663          	bge	s3,a5,80004ef2 <install_trans+0xae>
    if(recovering) {
    80004eaa:	fc0b1de3          	bnez	s6,80004e84 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004eae:	018a2583          	lw	a1,24(s4)
    80004eb2:	013585bb          	addw	a1,a1,s3
    80004eb6:	2585                	addiw	a1,a1,1
    80004eb8:	024a2503          	lw	a0,36(s4)
    80004ebc:	816ff0ef          	jal	80003ed2 <bread>
    80004ec0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004ec2:	000aa583          	lw	a1,0(s5)
    80004ec6:	024a2503          	lw	a0,36(s4)
    80004eca:	808ff0ef          	jal	80003ed2 <bread>
    80004ece:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ed0:	40000613          	li	a2,1024
    80004ed4:	05890593          	addi	a1,s2,88
    80004ed8:	05850513          	addi	a0,a0,88
    80004edc:	e31fb0ef          	jal	80000d0c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	8c6ff0ef          	jal	80003fa8 <bwrite>
    if(recovering == 0)
    80004ee6:	fa0b16e3          	bnez	s6,80004e92 <install_trans+0x4e>
      bunpin(dbuf);
    80004eea:	8526                	mv	a0,s1
    80004eec:	9aaff0ef          	jal	80004096 <bunpin>
    80004ef0:	b74d                	j	80004e92 <install_trans+0x4e>
}
    80004ef2:	60a6                	ld	ra,72(sp)
    80004ef4:	6406                	ld	s0,64(sp)
    80004ef6:	74e2                	ld	s1,56(sp)
    80004ef8:	7942                	ld	s2,48(sp)
    80004efa:	79a2                	ld	s3,40(sp)
    80004efc:	7a02                	ld	s4,32(sp)
    80004efe:	6ae2                	ld	s5,24(sp)
    80004f00:	6b42                	ld	s6,16(sp)
    80004f02:	6ba2                	ld	s7,8(sp)
    80004f04:	6161                	addi	sp,sp,80
    80004f06:	8082                	ret
    80004f08:	8082                	ret

0000000080004f0a <initlog>:
{
    80004f0a:	7179                	addi	sp,sp,-48
    80004f0c:	f406                	sd	ra,40(sp)
    80004f0e:	f022                	sd	s0,32(sp)
    80004f10:	ec26                	sd	s1,24(sp)
    80004f12:	e84a                	sd	s2,16(sp)
    80004f14:	e44e                	sd	s3,8(sp)
    80004f16:	1800                	addi	s0,sp,48
    80004f18:	892a                	mv	s2,a0
    80004f1a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004f1c:	001aa497          	auipc	s1,0x1aa
    80004f20:	1cc48493          	addi	s1,s1,460 # 801af0e8 <log>
    80004f24:	00004597          	auipc	a1,0x4
    80004f28:	97458593          	addi	a1,a1,-1676 # 80008898 <etext+0x898>
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	c21fb0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80004f32:	0149a583          	lw	a1,20(s3)
    80004f36:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80004f38:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004f3c:	854a                	mv	a0,s2
    80004f3e:	f95fe0ef          	jal	80003ed2 <bread>
  log.lh.n = lh->n;
    80004f42:	4d30                	lw	a2,88(a0)
    80004f44:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004f46:	00c05f63          	blez	a2,80004f64 <initlog+0x5a>
    80004f4a:	87aa                	mv	a5,a0
    80004f4c:	001aa717          	auipc	a4,0x1aa
    80004f50:	1c870713          	addi	a4,a4,456 # 801af114 <log+0x2c>
    80004f54:	060a                	slli	a2,a2,0x2
    80004f56:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004f58:	4ff4                	lw	a3,92(a5)
    80004f5a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004f5c:	0791                	addi	a5,a5,4
    80004f5e:	0711                	addi	a4,a4,4
    80004f60:	fec79ce3          	bne	a5,a2,80004f58 <initlog+0x4e>
  brelse(buf);
    80004f64:	876ff0ef          	jal	80003fda <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004f68:	4505                	li	a0,1
    80004f6a:	edbff0ef          	jal	80004e44 <install_trans>
  log.lh.n = 0;
    80004f6e:	001aa797          	auipc	a5,0x1aa
    80004f72:	1a07a123          	sw	zero,418(a5) # 801af110 <log+0x28>
  write_head(); // clear the log
    80004f76:	e71ff0ef          	jal	80004de6 <write_head>
}
    80004f7a:	70a2                	ld	ra,40(sp)
    80004f7c:	7402                	ld	s0,32(sp)
    80004f7e:	64e2                	ld	s1,24(sp)
    80004f80:	6942                	ld	s2,16(sp)
    80004f82:	69a2                	ld	s3,8(sp)
    80004f84:	6145                	addi	sp,sp,48
    80004f86:	8082                	ret

0000000080004f88 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004f88:	1101                	addi	sp,sp,-32
    80004f8a:	ec06                	sd	ra,24(sp)
    80004f8c:	e822                	sd	s0,16(sp)
    80004f8e:	e426                	sd	s1,8(sp)
    80004f90:	e04a                	sd	s2,0(sp)
    80004f92:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004f94:	001aa517          	auipc	a0,0x1aa
    80004f98:	15450513          	addi	a0,a0,340 # 801af0e8 <log>
    80004f9c:	c33fb0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80004fa0:	001aa497          	auipc	s1,0x1aa
    80004fa4:	14848493          	addi	s1,s1,328 # 801af0e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004fa8:	4979                	li	s2,30
    80004faa:	a029                	j	80004fb4 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80004fac:	85a6                	mv	a1,s1
    80004fae:	8526                	mv	a0,s1
    80004fb0:	f0bfd0ef          	jal	80002eba <sleep>
    if(log.committing){
    80004fb4:	509c                	lw	a5,32(s1)
    80004fb6:	fbfd                	bnez	a5,80004fac <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004fb8:	4cd8                	lw	a4,28(s1)
    80004fba:	2705                	addiw	a4,a4,1
    80004fbc:	0027179b          	slliw	a5,a4,0x2
    80004fc0:	9fb9                	addw	a5,a5,a4
    80004fc2:	0017979b          	slliw	a5,a5,0x1
    80004fc6:	5494                	lw	a3,40(s1)
    80004fc8:	9fb5                	addw	a5,a5,a3
    80004fca:	00f95763          	bge	s2,a5,80004fd8 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004fce:	85a6                	mv	a1,s1
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ee9fd0ef          	jal	80002eba <sleep>
    80004fd6:	bff9                	j	80004fb4 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80004fd8:	001aa517          	auipc	a0,0x1aa
    80004fdc:	11050513          	addi	a0,a0,272 # 801af0e8 <log>
    80004fe0:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80004fe2:	c93fb0ef          	jal	80000c74 <release>
      break;
    }
  }
}
    80004fe6:	60e2                	ld	ra,24(sp)
    80004fe8:	6442                	ld	s0,16(sp)
    80004fea:	64a2                	ld	s1,8(sp)
    80004fec:	6902                	ld	s2,0(sp)
    80004fee:	6105                	addi	sp,sp,32
    80004ff0:	8082                	ret

0000000080004ff2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004ff2:	7139                	addi	sp,sp,-64
    80004ff4:	fc06                	sd	ra,56(sp)
    80004ff6:	f822                	sd	s0,48(sp)
    80004ff8:	f426                	sd	s1,40(sp)
    80004ffa:	f04a                	sd	s2,32(sp)
    80004ffc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004ffe:	001aa497          	auipc	s1,0x1aa
    80005002:	0ea48493          	addi	s1,s1,234 # 801af0e8 <log>
    80005006:	8526                	mv	a0,s1
    80005008:	bc7fb0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    8000500c:	4cdc                	lw	a5,28(s1)
    8000500e:	37fd                	addiw	a5,a5,-1
    80005010:	0007891b          	sext.w	s2,a5
    80005014:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80005016:	509c                	lw	a5,32(s1)
    80005018:	ef9d                	bnez	a5,80005056 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    8000501a:	04091763          	bnez	s2,80005068 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    8000501e:	001aa497          	auipc	s1,0x1aa
    80005022:	0ca48493          	addi	s1,s1,202 # 801af0e8 <log>
    80005026:	4785                	li	a5,1
    80005028:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000502a:	8526                	mv	a0,s1
    8000502c:	c49fb0ef          	jal	80000c74 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005030:	549c                	lw	a5,40(s1)
    80005032:	04f04b63          	bgtz	a5,80005088 <end_op+0x96>
    acquire(&log.lock);
    80005036:	001aa497          	auipc	s1,0x1aa
    8000503a:	0b248493          	addi	s1,s1,178 # 801af0e8 <log>
    8000503e:	8526                	mv	a0,s1
    80005040:	b8ffb0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80005044:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80005048:	8526                	mv	a0,s1
    8000504a:	ebdfd0ef          	jal	80002f06 <wakeup>
    release(&log.lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	c25fb0ef          	jal	80000c74 <release>
}
    80005054:	a025                	j	8000507c <end_op+0x8a>
    80005056:	ec4e                	sd	s3,24(sp)
    80005058:	e852                	sd	s4,16(sp)
    8000505a:	e456                	sd	s5,8(sp)
    panic("log.committing");
    8000505c:	00004517          	auipc	a0,0x4
    80005060:	84450513          	addi	a0,a0,-1980 # 800088a0 <etext+0x8a0>
    80005064:	f7cfb0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80005068:	001aa497          	auipc	s1,0x1aa
    8000506c:	08048493          	addi	s1,s1,128 # 801af0e8 <log>
    80005070:	8526                	mv	a0,s1
    80005072:	e95fd0ef          	jal	80002f06 <wakeup>
  release(&log.lock);
    80005076:	8526                	mv	a0,s1
    80005078:	bfdfb0ef          	jal	80000c74 <release>
}
    8000507c:	70e2                	ld	ra,56(sp)
    8000507e:	7442                	ld	s0,48(sp)
    80005080:	74a2                	ld	s1,40(sp)
    80005082:	7902                	ld	s2,32(sp)
    80005084:	6121                	addi	sp,sp,64
    80005086:	8082                	ret
    80005088:	ec4e                	sd	s3,24(sp)
    8000508a:	e852                	sd	s4,16(sp)
    8000508c:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    8000508e:	001aaa97          	auipc	s5,0x1aa
    80005092:	086a8a93          	addi	s5,s5,134 # 801af114 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005096:	001aaa17          	auipc	s4,0x1aa
    8000509a:	052a0a13          	addi	s4,s4,82 # 801af0e8 <log>
    8000509e:	018a2583          	lw	a1,24(s4)
    800050a2:	012585bb          	addw	a1,a1,s2
    800050a6:	2585                	addiw	a1,a1,1
    800050a8:	024a2503          	lw	a0,36(s4)
    800050ac:	e27fe0ef          	jal	80003ed2 <bread>
    800050b0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800050b2:	000aa583          	lw	a1,0(s5)
    800050b6:	024a2503          	lw	a0,36(s4)
    800050ba:	e19fe0ef          	jal	80003ed2 <bread>
    800050be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800050c0:	40000613          	li	a2,1024
    800050c4:	05850593          	addi	a1,a0,88
    800050c8:	05848513          	addi	a0,s1,88
    800050cc:	c41fb0ef          	jal	80000d0c <memmove>
    bwrite(to);  // write the log
    800050d0:	8526                	mv	a0,s1
    800050d2:	ed7fe0ef          	jal	80003fa8 <bwrite>
    brelse(from);
    800050d6:	854e                	mv	a0,s3
    800050d8:	f03fe0ef          	jal	80003fda <brelse>
    brelse(to);
    800050dc:	8526                	mv	a0,s1
    800050de:	efdfe0ef          	jal	80003fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800050e2:	2905                	addiw	s2,s2,1
    800050e4:	0a91                	addi	s5,s5,4
    800050e6:	028a2783          	lw	a5,40(s4)
    800050ea:	faf94ae3          	blt	s2,a5,8000509e <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800050ee:	cf9ff0ef          	jal	80004de6 <write_head>
    install_trans(0); // Now install writes to home locations
    800050f2:	4501                	li	a0,0
    800050f4:	d51ff0ef          	jal	80004e44 <install_trans>
    log.lh.n = 0;
    800050f8:	001aa797          	auipc	a5,0x1aa
    800050fc:	0007ac23          	sw	zero,24(a5) # 801af110 <log+0x28>
    write_head();    // Erase the transaction from the log
    80005100:	ce7ff0ef          	jal	80004de6 <write_head>
    80005104:	69e2                	ld	s3,24(sp)
    80005106:	6a42                	ld	s4,16(sp)
    80005108:	6aa2                	ld	s5,8(sp)
    8000510a:	b735                	j	80005036 <end_op+0x44>

000000008000510c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000510c:	1101                	addi	sp,sp,-32
    8000510e:	ec06                	sd	ra,24(sp)
    80005110:	e822                	sd	s0,16(sp)
    80005112:	e426                	sd	s1,8(sp)
    80005114:	e04a                	sd	s2,0(sp)
    80005116:	1000                	addi	s0,sp,32
    80005118:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000511a:	001aa917          	auipc	s2,0x1aa
    8000511e:	fce90913          	addi	s2,s2,-50 # 801af0e8 <log>
    80005122:	854a                	mv	a0,s2
    80005124:	aabfb0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80005128:	02892603          	lw	a2,40(s2)
    8000512c:	47f5                	li	a5,29
    8000512e:	04c7cc63          	blt	a5,a2,80005186 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005132:	001aa797          	auipc	a5,0x1aa
    80005136:	fd27a783          	lw	a5,-46(a5) # 801af104 <log+0x1c>
    8000513a:	04f05c63          	blez	a5,80005192 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000513e:	4781                	li	a5,0
    80005140:	04c05f63          	blez	a2,8000519e <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005144:	44cc                	lw	a1,12(s1)
    80005146:	001aa717          	auipc	a4,0x1aa
    8000514a:	fce70713          	addi	a4,a4,-50 # 801af114 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    8000514e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005150:	4314                	lw	a3,0(a4)
    80005152:	04b68663          	beq	a3,a1,8000519e <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80005156:	2785                	addiw	a5,a5,1
    80005158:	0711                	addi	a4,a4,4
    8000515a:	fef61be3          	bne	a2,a5,80005150 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000515e:	0621                	addi	a2,a2,8
    80005160:	060a                	slli	a2,a2,0x2
    80005162:	001aa797          	auipc	a5,0x1aa
    80005166:	f8678793          	addi	a5,a5,-122 # 801af0e8 <log>
    8000516a:	97b2                	add	a5,a5,a2
    8000516c:	44d8                	lw	a4,12(s1)
    8000516e:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005170:	8526                	mv	a0,s1
    80005172:	ef1fe0ef          	jal	80004062 <bpin>
    log.lh.n++;
    80005176:	001aa717          	auipc	a4,0x1aa
    8000517a:	f7270713          	addi	a4,a4,-142 # 801af0e8 <log>
    8000517e:	571c                	lw	a5,40(a4)
    80005180:	2785                	addiw	a5,a5,1
    80005182:	d71c                	sw	a5,40(a4)
    80005184:	a80d                	j	800051b6 <log_write+0xaa>
    panic("too big a transaction");
    80005186:	00003517          	auipc	a0,0x3
    8000518a:	72a50513          	addi	a0,a0,1834 # 800088b0 <etext+0x8b0>
    8000518e:	e52fb0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80005192:	00003517          	auipc	a0,0x3
    80005196:	73650513          	addi	a0,a0,1846 # 800088c8 <etext+0x8c8>
    8000519a:	e46fb0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    8000519e:	00878693          	addi	a3,a5,8
    800051a2:	068a                	slli	a3,a3,0x2
    800051a4:	001aa717          	auipc	a4,0x1aa
    800051a8:	f4470713          	addi	a4,a4,-188 # 801af0e8 <log>
    800051ac:	9736                	add	a4,a4,a3
    800051ae:	44d4                	lw	a3,12(s1)
    800051b0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800051b2:	faf60fe3          	beq	a2,a5,80005170 <log_write+0x64>
  }
  release(&log.lock);
    800051b6:	001aa517          	auipc	a0,0x1aa
    800051ba:	f3250513          	addi	a0,a0,-206 # 801af0e8 <log>
    800051be:	ab7fb0ef          	jal	80000c74 <release>
}
    800051c2:	60e2                	ld	ra,24(sp)
    800051c4:	6442                	ld	s0,16(sp)
    800051c6:	64a2                	ld	s1,8(sp)
    800051c8:	6902                	ld	s2,0(sp)
    800051ca:	6105                	addi	sp,sp,32
    800051cc:	8082                	ret

00000000800051ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800051ce:	1101                	addi	sp,sp,-32
    800051d0:	ec06                	sd	ra,24(sp)
    800051d2:	e822                	sd	s0,16(sp)
    800051d4:	e426                	sd	s1,8(sp)
    800051d6:	e04a                	sd	s2,0(sp)
    800051d8:	1000                	addi	s0,sp,32
    800051da:	84aa                	mv	s1,a0
    800051dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800051de:	00003597          	auipc	a1,0x3
    800051e2:	70a58593          	addi	a1,a1,1802 # 800088e8 <etext+0x8e8>
    800051e6:	0521                	addi	a0,a0,8
    800051e8:	967fb0ef          	jal	80000b4e <initlock>
  lk->name = name;
    800051ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800051f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800051f4:	0204a423          	sw	zero,40(s1)
}
    800051f8:	60e2                	ld	ra,24(sp)
    800051fa:	6442                	ld	s0,16(sp)
    800051fc:	64a2                	ld	s1,8(sp)
    800051fe:	6902                	ld	s2,0(sp)
    80005200:	6105                	addi	sp,sp,32
    80005202:	8082                	ret

0000000080005204 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005204:	1101                	addi	sp,sp,-32
    80005206:	ec06                	sd	ra,24(sp)
    80005208:	e822                	sd	s0,16(sp)
    8000520a:	e426                	sd	s1,8(sp)
    8000520c:	e04a                	sd	s2,0(sp)
    8000520e:	1000                	addi	s0,sp,32
    80005210:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005212:	00850913          	addi	s2,a0,8
    80005216:	854a                	mv	a0,s2
    80005218:	9b7fb0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    8000521c:	409c                	lw	a5,0(s1)
    8000521e:	c799                	beqz	a5,8000522c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80005220:	85ca                	mv	a1,s2
    80005222:	8526                	mv	a0,s1
    80005224:	c97fd0ef          	jal	80002eba <sleep>
  while (lk->locked) {
    80005228:	409c                	lw	a5,0(s1)
    8000522a:	fbfd                	bnez	a5,80005220 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    8000522c:	4785                	li	a5,1
    8000522e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005230:	9f8fd0ef          	jal	80002428 <myproc>
    80005234:	591c                	lw	a5,48(a0)
    80005236:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005238:	854a                	mv	a0,s2
    8000523a:	a3bfb0ef          	jal	80000c74 <release>
}
    8000523e:	60e2                	ld	ra,24(sp)
    80005240:	6442                	ld	s0,16(sp)
    80005242:	64a2                	ld	s1,8(sp)
    80005244:	6902                	ld	s2,0(sp)
    80005246:	6105                	addi	sp,sp,32
    80005248:	8082                	ret

000000008000524a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000524a:	1101                	addi	sp,sp,-32
    8000524c:	ec06                	sd	ra,24(sp)
    8000524e:	e822                	sd	s0,16(sp)
    80005250:	e426                	sd	s1,8(sp)
    80005252:	e04a                	sd	s2,0(sp)
    80005254:	1000                	addi	s0,sp,32
    80005256:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005258:	00850913          	addi	s2,a0,8
    8000525c:	854a                	mv	a0,s2
    8000525e:	971fb0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    80005262:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005266:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000526a:	8526                	mv	a0,s1
    8000526c:	c9bfd0ef          	jal	80002f06 <wakeup>
  release(&lk->lk);
    80005270:	854a                	mv	a0,s2
    80005272:	a03fb0ef          	jal	80000c74 <release>
}
    80005276:	60e2                	ld	ra,24(sp)
    80005278:	6442                	ld	s0,16(sp)
    8000527a:	64a2                	ld	s1,8(sp)
    8000527c:	6902                	ld	s2,0(sp)
    8000527e:	6105                	addi	sp,sp,32
    80005280:	8082                	ret

0000000080005282 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005282:	7179                	addi	sp,sp,-48
    80005284:	f406                	sd	ra,40(sp)
    80005286:	f022                	sd	s0,32(sp)
    80005288:	ec26                	sd	s1,24(sp)
    8000528a:	e84a                	sd	s2,16(sp)
    8000528c:	1800                	addi	s0,sp,48
    8000528e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005290:	00850913          	addi	s2,a0,8
    80005294:	854a                	mv	a0,s2
    80005296:	939fb0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000529a:	409c                	lw	a5,0(s1)
    8000529c:	ef81                	bnez	a5,800052b4 <holdingsleep+0x32>
    8000529e:	4481                	li	s1,0
  release(&lk->lk);
    800052a0:	854a                	mv	a0,s2
    800052a2:	9d3fb0ef          	jal	80000c74 <release>
  return r;
}
    800052a6:	8526                	mv	a0,s1
    800052a8:	70a2                	ld	ra,40(sp)
    800052aa:	7402                	ld	s0,32(sp)
    800052ac:	64e2                	ld	s1,24(sp)
    800052ae:	6942                	ld	s2,16(sp)
    800052b0:	6145                	addi	sp,sp,48
    800052b2:	8082                	ret
    800052b4:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    800052b6:	0284a983          	lw	s3,40(s1)
    800052ba:	96efd0ef          	jal	80002428 <myproc>
    800052be:	5904                	lw	s1,48(a0)
    800052c0:	413484b3          	sub	s1,s1,s3
    800052c4:	0014b493          	seqz	s1,s1
    800052c8:	69a2                	ld	s3,8(sp)
    800052ca:	bfd9                	j	800052a0 <holdingsleep+0x1e>

00000000800052cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800052cc:	1141                	addi	sp,sp,-16
    800052ce:	e406                	sd	ra,8(sp)
    800052d0:	e022                	sd	s0,0(sp)
    800052d2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800052d4:	00003597          	auipc	a1,0x3
    800052d8:	62458593          	addi	a1,a1,1572 # 800088f8 <etext+0x8f8>
    800052dc:	001aa517          	auipc	a0,0x1aa
    800052e0:	f5450513          	addi	a0,a0,-172 # 801af230 <ftable>
    800052e4:	86bfb0ef          	jal	80000b4e <initlock>
}
    800052e8:	60a2                	ld	ra,8(sp)
    800052ea:	6402                	ld	s0,0(sp)
    800052ec:	0141                	addi	sp,sp,16
    800052ee:	8082                	ret

00000000800052f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800052f0:	1101                	addi	sp,sp,-32
    800052f2:	ec06                	sd	ra,24(sp)
    800052f4:	e822                	sd	s0,16(sp)
    800052f6:	e426                	sd	s1,8(sp)
    800052f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800052fa:	001aa517          	auipc	a0,0x1aa
    800052fe:	f3650513          	addi	a0,a0,-202 # 801af230 <ftable>
    80005302:	8cdfb0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005306:	001aa497          	auipc	s1,0x1aa
    8000530a:	f4248493          	addi	s1,s1,-190 # 801af248 <ftable+0x18>
    8000530e:	001ab717          	auipc	a4,0x1ab
    80005312:	eda70713          	addi	a4,a4,-294 # 801b01e8 <disk>
    if(f->ref == 0){
    80005316:	40dc                	lw	a5,4(s1)
    80005318:	cf89                	beqz	a5,80005332 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000531a:	02848493          	addi	s1,s1,40
    8000531e:	fee49ce3          	bne	s1,a4,80005316 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005322:	001aa517          	auipc	a0,0x1aa
    80005326:	f0e50513          	addi	a0,a0,-242 # 801af230 <ftable>
    8000532a:	94bfb0ef          	jal	80000c74 <release>
  return 0;
    8000532e:	4481                	li	s1,0
    80005330:	a809                	j	80005342 <filealloc+0x52>
      f->ref = 1;
    80005332:	4785                	li	a5,1
    80005334:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005336:	001aa517          	auipc	a0,0x1aa
    8000533a:	efa50513          	addi	a0,a0,-262 # 801af230 <ftable>
    8000533e:	937fb0ef          	jal	80000c74 <release>
}
    80005342:	8526                	mv	a0,s1
    80005344:	60e2                	ld	ra,24(sp)
    80005346:	6442                	ld	s0,16(sp)
    80005348:	64a2                	ld	s1,8(sp)
    8000534a:	6105                	addi	sp,sp,32
    8000534c:	8082                	ret

000000008000534e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000534e:	1101                	addi	sp,sp,-32
    80005350:	ec06                	sd	ra,24(sp)
    80005352:	e822                	sd	s0,16(sp)
    80005354:	e426                	sd	s1,8(sp)
    80005356:	1000                	addi	s0,sp,32
    80005358:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000535a:	001aa517          	auipc	a0,0x1aa
    8000535e:	ed650513          	addi	a0,a0,-298 # 801af230 <ftable>
    80005362:	86dfb0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80005366:	40dc                	lw	a5,4(s1)
    80005368:	02f05063          	blez	a5,80005388 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000536c:	2785                	addiw	a5,a5,1
    8000536e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005370:	001aa517          	auipc	a0,0x1aa
    80005374:	ec050513          	addi	a0,a0,-320 # 801af230 <ftable>
    80005378:	8fdfb0ef          	jal	80000c74 <release>
  return f;
}
    8000537c:	8526                	mv	a0,s1
    8000537e:	60e2                	ld	ra,24(sp)
    80005380:	6442                	ld	s0,16(sp)
    80005382:	64a2                	ld	s1,8(sp)
    80005384:	6105                	addi	sp,sp,32
    80005386:	8082                	ret
    panic("filedup");
    80005388:	00003517          	auipc	a0,0x3
    8000538c:	57850513          	addi	a0,a0,1400 # 80008900 <etext+0x900>
    80005390:	c50fb0ef          	jal	800007e0 <panic>

0000000080005394 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005394:	7139                	addi	sp,sp,-64
    80005396:	fc06                	sd	ra,56(sp)
    80005398:	f822                	sd	s0,48(sp)
    8000539a:	f426                	sd	s1,40(sp)
    8000539c:	0080                	addi	s0,sp,64
    8000539e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800053a0:	001aa517          	auipc	a0,0x1aa
    800053a4:	e9050513          	addi	a0,a0,-368 # 801af230 <ftable>
    800053a8:	827fb0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800053ac:	40dc                	lw	a5,4(s1)
    800053ae:	04f05a63          	blez	a5,80005402 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    800053b2:	37fd                	addiw	a5,a5,-1
    800053b4:	0007871b          	sext.w	a4,a5
    800053b8:	c0dc                	sw	a5,4(s1)
    800053ba:	04e04e63          	bgtz	a4,80005416 <fileclose+0x82>
    800053be:	f04a                	sd	s2,32(sp)
    800053c0:	ec4e                	sd	s3,24(sp)
    800053c2:	e852                	sd	s4,16(sp)
    800053c4:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800053c6:	0004a903          	lw	s2,0(s1)
    800053ca:	0094ca83          	lbu	s5,9(s1)
    800053ce:	0104ba03          	ld	s4,16(s1)
    800053d2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800053d6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800053da:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800053de:	001aa517          	auipc	a0,0x1aa
    800053e2:	e5250513          	addi	a0,a0,-430 # 801af230 <ftable>
    800053e6:	88ffb0ef          	jal	80000c74 <release>

  if(ff.type == FD_PIPE){
    800053ea:	4785                	li	a5,1
    800053ec:	04f90063          	beq	s2,a5,8000542c <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800053f0:	3979                	addiw	s2,s2,-2
    800053f2:	4785                	li	a5,1
    800053f4:	0527f563          	bgeu	a5,s2,8000543e <fileclose+0xaa>
    800053f8:	7902                	ld	s2,32(sp)
    800053fa:	69e2                	ld	s3,24(sp)
    800053fc:	6a42                	ld	s4,16(sp)
    800053fe:	6aa2                	ld	s5,8(sp)
    80005400:	a00d                	j	80005422 <fileclose+0x8e>
    80005402:	f04a                	sd	s2,32(sp)
    80005404:	ec4e                	sd	s3,24(sp)
    80005406:	e852                	sd	s4,16(sp)
    80005408:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000540a:	00003517          	auipc	a0,0x3
    8000540e:	4fe50513          	addi	a0,a0,1278 # 80008908 <etext+0x908>
    80005412:	bcefb0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    80005416:	001aa517          	auipc	a0,0x1aa
    8000541a:	e1a50513          	addi	a0,a0,-486 # 801af230 <ftable>
    8000541e:	857fb0ef          	jal	80000c74 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80005422:	70e2                	ld	ra,56(sp)
    80005424:	7442                	ld	s0,48(sp)
    80005426:	74a2                	ld	s1,40(sp)
    80005428:	6121                	addi	sp,sp,64
    8000542a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000542c:	85d6                	mv	a1,s5
    8000542e:	8552                	mv	a0,s4
    80005430:	336000ef          	jal	80005766 <pipeclose>
    80005434:	7902                	ld	s2,32(sp)
    80005436:	69e2                	ld	s3,24(sp)
    80005438:	6a42                	ld	s4,16(sp)
    8000543a:	6aa2                	ld	s5,8(sp)
    8000543c:	b7dd                	j	80005422 <fileclose+0x8e>
    begin_op();
    8000543e:	b4bff0ef          	jal	80004f88 <begin_op>
    iput(ff.ip);
    80005442:	854e                	mv	a0,s3
    80005444:	adcff0ef          	jal	80004720 <iput>
    end_op();
    80005448:	babff0ef          	jal	80004ff2 <end_op>
    8000544c:	7902                	ld	s2,32(sp)
    8000544e:	69e2                	ld	s3,24(sp)
    80005450:	6a42                	ld	s4,16(sp)
    80005452:	6aa2                	ld	s5,8(sp)
    80005454:	b7f9                	j	80005422 <fileclose+0x8e>

0000000080005456 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005456:	715d                	addi	sp,sp,-80
    80005458:	e486                	sd	ra,72(sp)
    8000545a:	e0a2                	sd	s0,64(sp)
    8000545c:	fc26                	sd	s1,56(sp)
    8000545e:	f44e                	sd	s3,40(sp)
    80005460:	0880                	addi	s0,sp,80
    80005462:	84aa                	mv	s1,a0
    80005464:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005466:	fc3fc0ef          	jal	80002428 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000546a:	409c                	lw	a5,0(s1)
    8000546c:	37f9                	addiw	a5,a5,-2
    8000546e:	4705                	li	a4,1
    80005470:	04f76063          	bltu	a4,a5,800054b0 <filestat+0x5a>
    80005474:	f84a                	sd	s2,48(sp)
    80005476:	892a                	mv	s2,a0
    ilock(f->ip);
    80005478:	6c88                	ld	a0,24(s1)
    8000547a:	924ff0ef          	jal	8000459e <ilock>
    stati(f->ip, &st);
    8000547e:	fb840593          	addi	a1,s0,-72
    80005482:	6c88                	ld	a0,24(s1)
    80005484:	c80ff0ef          	jal	80004904 <stati>
    iunlock(f->ip);
    80005488:	6c88                	ld	a0,24(s1)
    8000548a:	9c2ff0ef          	jal	8000464c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000548e:	46e1                	li	a3,24
    80005490:	fb840613          	addi	a2,s0,-72
    80005494:	85ce                	mv	a1,s3
    80005496:	05093503          	ld	a0,80(s2)
    8000549a:	b81fc0ef          	jal	8000201a <copyout>
    8000549e:	41f5551b          	sraiw	a0,a0,0x1f
    800054a2:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800054a4:	60a6                	ld	ra,72(sp)
    800054a6:	6406                	ld	s0,64(sp)
    800054a8:	74e2                	ld	s1,56(sp)
    800054aa:	79a2                	ld	s3,40(sp)
    800054ac:	6161                	addi	sp,sp,80
    800054ae:	8082                	ret
  return -1;
    800054b0:	557d                	li	a0,-1
    800054b2:	bfcd                	j	800054a4 <filestat+0x4e>

00000000800054b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800054b4:	7179                	addi	sp,sp,-48
    800054b6:	f406                	sd	ra,40(sp)
    800054b8:	f022                	sd	s0,32(sp)
    800054ba:	e84a                	sd	s2,16(sp)
    800054bc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800054be:	00854783          	lbu	a5,8(a0)
    800054c2:	cfd1                	beqz	a5,8000555e <fileread+0xaa>
    800054c4:	ec26                	sd	s1,24(sp)
    800054c6:	e44e                	sd	s3,8(sp)
    800054c8:	84aa                	mv	s1,a0
    800054ca:	89ae                	mv	s3,a1
    800054cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054ce:	411c                	lw	a5,0(a0)
    800054d0:	4705                	li	a4,1
    800054d2:	04e78363          	beq	a5,a4,80005518 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054d6:	470d                	li	a4,3
    800054d8:	04e78763          	beq	a5,a4,80005526 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054dc:	4709                	li	a4,2
    800054de:	06e79a63          	bne	a5,a4,80005552 <fileread+0x9e>
    ilock(f->ip);
    800054e2:	6d08                	ld	a0,24(a0)
    800054e4:	8baff0ef          	jal	8000459e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800054e8:	874a                	mv	a4,s2
    800054ea:	5094                	lw	a3,32(s1)
    800054ec:	864e                	mv	a2,s3
    800054ee:	4585                	li	a1,1
    800054f0:	6c88                	ld	a0,24(s1)
    800054f2:	c3cff0ef          	jal	8000492e <readi>
    800054f6:	892a                	mv	s2,a0
    800054f8:	00a05563          	blez	a0,80005502 <fileread+0x4e>
      f->off += r;
    800054fc:	509c                	lw	a5,32(s1)
    800054fe:	9fa9                	addw	a5,a5,a0
    80005500:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005502:	6c88                	ld	a0,24(s1)
    80005504:	948ff0ef          	jal	8000464c <iunlock>
    80005508:	64e2                	ld	s1,24(sp)
    8000550a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    8000550c:	854a                	mv	a0,s2
    8000550e:	70a2                	ld	ra,40(sp)
    80005510:	7402                	ld	s0,32(sp)
    80005512:	6942                	ld	s2,16(sp)
    80005514:	6145                	addi	sp,sp,48
    80005516:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005518:	6908                	ld	a0,16(a0)
    8000551a:	388000ef          	jal	800058a2 <piperead>
    8000551e:	892a                	mv	s2,a0
    80005520:	64e2                	ld	s1,24(sp)
    80005522:	69a2                	ld	s3,8(sp)
    80005524:	b7e5                	j	8000550c <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005526:	02451783          	lh	a5,36(a0)
    8000552a:	03079693          	slli	a3,a5,0x30
    8000552e:	92c1                	srli	a3,a3,0x30
    80005530:	4725                	li	a4,9
    80005532:	02d76863          	bltu	a4,a3,80005562 <fileread+0xae>
    80005536:	0792                	slli	a5,a5,0x4
    80005538:	001aa717          	auipc	a4,0x1aa
    8000553c:	c5870713          	addi	a4,a4,-936 # 801af190 <devsw>
    80005540:	97ba                	add	a5,a5,a4
    80005542:	639c                	ld	a5,0(a5)
    80005544:	c39d                	beqz	a5,8000556a <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80005546:	4505                	li	a0,1
    80005548:	9782                	jalr	a5
    8000554a:	892a                	mv	s2,a0
    8000554c:	64e2                	ld	s1,24(sp)
    8000554e:	69a2                	ld	s3,8(sp)
    80005550:	bf75                	j	8000550c <fileread+0x58>
    panic("fileread");
    80005552:	00003517          	auipc	a0,0x3
    80005556:	3c650513          	addi	a0,a0,966 # 80008918 <etext+0x918>
    8000555a:	a86fb0ef          	jal	800007e0 <panic>
    return -1;
    8000555e:	597d                	li	s2,-1
    80005560:	b775                	j	8000550c <fileread+0x58>
      return -1;
    80005562:	597d                	li	s2,-1
    80005564:	64e2                	ld	s1,24(sp)
    80005566:	69a2                	ld	s3,8(sp)
    80005568:	b755                	j	8000550c <fileread+0x58>
    8000556a:	597d                	li	s2,-1
    8000556c:	64e2                	ld	s1,24(sp)
    8000556e:	69a2                	ld	s3,8(sp)
    80005570:	bf71                	j	8000550c <fileread+0x58>

0000000080005572 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80005572:	00954783          	lbu	a5,9(a0)
    80005576:	10078b63          	beqz	a5,8000568c <filewrite+0x11a>
{
    8000557a:	715d                	addi	sp,sp,-80
    8000557c:	e486                	sd	ra,72(sp)
    8000557e:	e0a2                	sd	s0,64(sp)
    80005580:	f84a                	sd	s2,48(sp)
    80005582:	f052                	sd	s4,32(sp)
    80005584:	e85a                	sd	s6,16(sp)
    80005586:	0880                	addi	s0,sp,80
    80005588:	892a                	mv	s2,a0
    8000558a:	8b2e                	mv	s6,a1
    8000558c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000558e:	411c                	lw	a5,0(a0)
    80005590:	4705                	li	a4,1
    80005592:	02e78763          	beq	a5,a4,800055c0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005596:	470d                	li	a4,3
    80005598:	02e78863          	beq	a5,a4,800055c8 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000559c:	4709                	li	a4,2
    8000559e:	0ce79c63          	bne	a5,a4,80005676 <filewrite+0x104>
    800055a2:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800055a4:	0ac05863          	blez	a2,80005654 <filewrite+0xe2>
    800055a8:	fc26                	sd	s1,56(sp)
    800055aa:	ec56                	sd	s5,24(sp)
    800055ac:	e45e                	sd	s7,8(sp)
    800055ae:	e062                	sd	s8,0(sp)
    int i = 0;
    800055b0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800055b2:	6b85                	lui	s7,0x1
    800055b4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800055b8:	6c05                	lui	s8,0x1
    800055ba:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800055be:	a8b5                	j	8000563a <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    800055c0:	6908                	ld	a0,16(a0)
    800055c2:	1fc000ef          	jal	800057be <pipewrite>
    800055c6:	a04d                	j	80005668 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055c8:	02451783          	lh	a5,36(a0)
    800055cc:	03079693          	slli	a3,a5,0x30
    800055d0:	92c1                	srli	a3,a3,0x30
    800055d2:	4725                	li	a4,9
    800055d4:	0ad76e63          	bltu	a4,a3,80005690 <filewrite+0x11e>
    800055d8:	0792                	slli	a5,a5,0x4
    800055da:	001aa717          	auipc	a4,0x1aa
    800055de:	bb670713          	addi	a4,a4,-1098 # 801af190 <devsw>
    800055e2:	97ba                	add	a5,a5,a4
    800055e4:	679c                	ld	a5,8(a5)
    800055e6:	c7dd                	beqz	a5,80005694 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    800055e8:	4505                	li	a0,1
    800055ea:	9782                	jalr	a5
    800055ec:	a8b5                	j	80005668 <filewrite+0xf6>
      if(n1 > max)
    800055ee:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800055f2:	997ff0ef          	jal	80004f88 <begin_op>
      ilock(f->ip);
    800055f6:	01893503          	ld	a0,24(s2)
    800055fa:	fa5fe0ef          	jal	8000459e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800055fe:	8756                	mv	a4,s5
    80005600:	02092683          	lw	a3,32(s2)
    80005604:	01698633          	add	a2,s3,s6
    80005608:	4585                	li	a1,1
    8000560a:	01893503          	ld	a0,24(s2)
    8000560e:	c1cff0ef          	jal	80004a2a <writei>
    80005612:	84aa                	mv	s1,a0
    80005614:	00a05763          	blez	a0,80005622 <filewrite+0xb0>
        f->off += r;
    80005618:	02092783          	lw	a5,32(s2)
    8000561c:	9fa9                	addw	a5,a5,a0
    8000561e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005622:	01893503          	ld	a0,24(s2)
    80005626:	826ff0ef          	jal	8000464c <iunlock>
      end_op();
    8000562a:	9c9ff0ef          	jal	80004ff2 <end_op>

      if(r != n1){
    8000562e:	029a9563          	bne	s5,s1,80005658 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    80005632:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005636:	0149da63          	bge	s3,s4,8000564a <filewrite+0xd8>
      int n1 = n - i;
    8000563a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000563e:	0004879b          	sext.w	a5,s1
    80005642:	fafbd6e3          	bge	s7,a5,800055ee <filewrite+0x7c>
    80005646:	84e2                	mv	s1,s8
    80005648:	b75d                	j	800055ee <filewrite+0x7c>
    8000564a:	74e2                	ld	s1,56(sp)
    8000564c:	6ae2                	ld	s5,24(sp)
    8000564e:	6ba2                	ld	s7,8(sp)
    80005650:	6c02                	ld	s8,0(sp)
    80005652:	a039                	j	80005660 <filewrite+0xee>
    int i = 0;
    80005654:	4981                	li	s3,0
    80005656:	a029                	j	80005660 <filewrite+0xee>
    80005658:	74e2                	ld	s1,56(sp)
    8000565a:	6ae2                	ld	s5,24(sp)
    8000565c:	6ba2                	ld	s7,8(sp)
    8000565e:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80005660:	033a1c63          	bne	s4,s3,80005698 <filewrite+0x126>
    80005664:	8552                	mv	a0,s4
    80005666:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005668:	60a6                	ld	ra,72(sp)
    8000566a:	6406                	ld	s0,64(sp)
    8000566c:	7942                	ld	s2,48(sp)
    8000566e:	7a02                	ld	s4,32(sp)
    80005670:	6b42                	ld	s6,16(sp)
    80005672:	6161                	addi	sp,sp,80
    80005674:	8082                	ret
    80005676:	fc26                	sd	s1,56(sp)
    80005678:	f44e                	sd	s3,40(sp)
    8000567a:	ec56                	sd	s5,24(sp)
    8000567c:	e45e                	sd	s7,8(sp)
    8000567e:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80005680:	00003517          	auipc	a0,0x3
    80005684:	2a850513          	addi	a0,a0,680 # 80008928 <etext+0x928>
    80005688:	958fb0ef          	jal	800007e0 <panic>
    return -1;
    8000568c:	557d                	li	a0,-1
}
    8000568e:	8082                	ret
      return -1;
    80005690:	557d                	li	a0,-1
    80005692:	bfd9                	j	80005668 <filewrite+0xf6>
    80005694:	557d                	li	a0,-1
    80005696:	bfc9                	j	80005668 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80005698:	557d                	li	a0,-1
    8000569a:	79a2                	ld	s3,40(sp)
    8000569c:	b7f1                	j	80005668 <filewrite+0xf6>

000000008000569e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000569e:	7179                	addi	sp,sp,-48
    800056a0:	f406                	sd	ra,40(sp)
    800056a2:	f022                	sd	s0,32(sp)
    800056a4:	ec26                	sd	s1,24(sp)
    800056a6:	e052                	sd	s4,0(sp)
    800056a8:	1800                	addi	s0,sp,48
    800056aa:	84aa                	mv	s1,a0
    800056ac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800056ae:	0005b023          	sd	zero,0(a1)
    800056b2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056b6:	c3bff0ef          	jal	800052f0 <filealloc>
    800056ba:	e088                	sd	a0,0(s1)
    800056bc:	c549                	beqz	a0,80005746 <pipealloc+0xa8>
    800056be:	c33ff0ef          	jal	800052f0 <filealloc>
    800056c2:	00aa3023          	sd	a0,0(s4)
    800056c6:	cd25                	beqz	a0,8000573e <pipealloc+0xa0>
    800056c8:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056ca:	c34fb0ef          	jal	80000afe <kalloc>
    800056ce:	892a                	mv	s2,a0
    800056d0:	c12d                	beqz	a0,80005732 <pipealloc+0x94>
    800056d2:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800056d4:	4985                	li	s3,1
    800056d6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056da:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056e6:	00003597          	auipc	a1,0x3
    800056ea:	25258593          	addi	a1,a1,594 # 80008938 <etext+0x938>
    800056ee:	c60fb0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800056f2:	609c                	ld	a5,0(s1)
    800056f4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056f8:	609c                	ld	a5,0(s1)
    800056fa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800056fe:	609c                	ld	a5,0(s1)
    80005700:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005704:	609c                	ld	a5,0(s1)
    80005706:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000570a:	000a3783          	ld	a5,0(s4)
    8000570e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005712:	000a3783          	ld	a5,0(s4)
    80005716:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000571a:	000a3783          	ld	a5,0(s4)
    8000571e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005722:	000a3783          	ld	a5,0(s4)
    80005726:	0127b823          	sd	s2,16(a5)
  return 0;
    8000572a:	4501                	li	a0,0
    8000572c:	6942                	ld	s2,16(sp)
    8000572e:	69a2                	ld	s3,8(sp)
    80005730:	a01d                	j	80005756 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005732:	6088                	ld	a0,0(s1)
    80005734:	c119                	beqz	a0,8000573a <pipealloc+0x9c>
    80005736:	6942                	ld	s2,16(sp)
    80005738:	a029                	j	80005742 <pipealloc+0xa4>
    8000573a:	6942                	ld	s2,16(sp)
    8000573c:	a029                	j	80005746 <pipealloc+0xa8>
    8000573e:	6088                	ld	a0,0(s1)
    80005740:	c10d                	beqz	a0,80005762 <pipealloc+0xc4>
    fileclose(*f0);
    80005742:	c53ff0ef          	jal	80005394 <fileclose>
  if(*f1)
    80005746:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000574a:	557d                	li	a0,-1
  if(*f1)
    8000574c:	c789                	beqz	a5,80005756 <pipealloc+0xb8>
    fileclose(*f1);
    8000574e:	853e                	mv	a0,a5
    80005750:	c45ff0ef          	jal	80005394 <fileclose>
  return -1;
    80005754:	557d                	li	a0,-1
}
    80005756:	70a2                	ld	ra,40(sp)
    80005758:	7402                	ld	s0,32(sp)
    8000575a:	64e2                	ld	s1,24(sp)
    8000575c:	6a02                	ld	s4,0(sp)
    8000575e:	6145                	addi	sp,sp,48
    80005760:	8082                	ret
  return -1;
    80005762:	557d                	li	a0,-1
    80005764:	bfcd                	j	80005756 <pipealloc+0xb8>

0000000080005766 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005766:	1101                	addi	sp,sp,-32
    80005768:	ec06                	sd	ra,24(sp)
    8000576a:	e822                	sd	s0,16(sp)
    8000576c:	e426                	sd	s1,8(sp)
    8000576e:	e04a                	sd	s2,0(sp)
    80005770:	1000                	addi	s0,sp,32
    80005772:	84aa                	mv	s1,a0
    80005774:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005776:	c58fb0ef          	jal	80000bce <acquire>
  if(writable){
    8000577a:	02090763          	beqz	s2,800057a8 <pipeclose+0x42>
    pi->writeopen = 0;
    8000577e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005782:	21848513          	addi	a0,s1,536
    80005786:	f80fd0ef          	jal	80002f06 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000578a:	2204b783          	ld	a5,544(s1)
    8000578e:	e785                	bnez	a5,800057b6 <pipeclose+0x50>
    release(&pi->lock);
    80005790:	8526                	mv	a0,s1
    80005792:	ce2fb0ef          	jal	80000c74 <release>
    kfree((char*)pi);
    80005796:	8526                	mv	a0,s1
    80005798:	a84fb0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    8000579c:	60e2                	ld	ra,24(sp)
    8000579e:	6442                	ld	s0,16(sp)
    800057a0:	64a2                	ld	s1,8(sp)
    800057a2:	6902                	ld	s2,0(sp)
    800057a4:	6105                	addi	sp,sp,32
    800057a6:	8082                	ret
    pi->readopen = 0;
    800057a8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057ac:	21c48513          	addi	a0,s1,540
    800057b0:	f56fd0ef          	jal	80002f06 <wakeup>
    800057b4:	bfd9                	j	8000578a <pipeclose+0x24>
    release(&pi->lock);
    800057b6:	8526                	mv	a0,s1
    800057b8:	cbcfb0ef          	jal	80000c74 <release>
}
    800057bc:	b7c5                	j	8000579c <pipeclose+0x36>

00000000800057be <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057be:	711d                	addi	sp,sp,-96
    800057c0:	ec86                	sd	ra,88(sp)
    800057c2:	e8a2                	sd	s0,80(sp)
    800057c4:	e4a6                	sd	s1,72(sp)
    800057c6:	e0ca                	sd	s2,64(sp)
    800057c8:	fc4e                	sd	s3,56(sp)
    800057ca:	f852                	sd	s4,48(sp)
    800057cc:	f456                	sd	s5,40(sp)
    800057ce:	1080                	addi	s0,sp,96
    800057d0:	84aa                	mv	s1,a0
    800057d2:	8aae                	mv	s5,a1
    800057d4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057d6:	c53fc0ef          	jal	80002428 <myproc>
    800057da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800057dc:	8526                	mv	a0,s1
    800057de:	bf0fb0ef          	jal	80000bce <acquire>
  while(i < n){
    800057e2:	0b405a63          	blez	s4,80005896 <pipewrite+0xd8>
    800057e6:	f05a                	sd	s6,32(sp)
    800057e8:	ec5e                	sd	s7,24(sp)
    800057ea:	e862                	sd	s8,16(sp)
  int i = 0;
    800057ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800057f0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800057f4:	21c48b93          	addi	s7,s1,540
    800057f8:	a81d                	j	8000582e <pipewrite+0x70>
      release(&pi->lock);
    800057fa:	8526                	mv	a0,s1
    800057fc:	c78fb0ef          	jal	80000c74 <release>
      return -1;
    80005800:	597d                	li	s2,-1
    80005802:	7b02                	ld	s6,32(sp)
    80005804:	6be2                	ld	s7,24(sp)
    80005806:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005808:	854a                	mv	a0,s2
    8000580a:	60e6                	ld	ra,88(sp)
    8000580c:	6446                	ld	s0,80(sp)
    8000580e:	64a6                	ld	s1,72(sp)
    80005810:	6906                	ld	s2,64(sp)
    80005812:	79e2                	ld	s3,56(sp)
    80005814:	7a42                	ld	s4,48(sp)
    80005816:	7aa2                	ld	s5,40(sp)
    80005818:	6125                	addi	sp,sp,96
    8000581a:	8082                	ret
      wakeup(&pi->nread);
    8000581c:	8562                	mv	a0,s8
    8000581e:	ee8fd0ef          	jal	80002f06 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005822:	85a6                	mv	a1,s1
    80005824:	855e                	mv	a0,s7
    80005826:	e94fd0ef          	jal	80002eba <sleep>
  while(i < n){
    8000582a:	05495b63          	bge	s2,s4,80005880 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    8000582e:	2204a783          	lw	a5,544(s1)
    80005832:	d7e1                	beqz	a5,800057fa <pipewrite+0x3c>
    80005834:	854e                	mv	a0,s3
    80005836:	91ffd0ef          	jal	80003154 <killed>
    8000583a:	f161                	bnez	a0,800057fa <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000583c:	2184a783          	lw	a5,536(s1)
    80005840:	21c4a703          	lw	a4,540(s1)
    80005844:	2007879b          	addiw	a5,a5,512
    80005848:	fcf70ae3          	beq	a4,a5,8000581c <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000584c:	4685                	li	a3,1
    8000584e:	01590633          	add	a2,s2,s5
    80005852:	faf40593          	addi	a1,s0,-81
    80005856:	0509b503          	ld	a0,80(s3)
    8000585a:	8adfc0ef          	jal	80002106 <copyin>
    8000585e:	03650e63          	beq	a0,s6,8000589a <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005862:	21c4a783          	lw	a5,540(s1)
    80005866:	0017871b          	addiw	a4,a5,1
    8000586a:	20e4ae23          	sw	a4,540(s1)
    8000586e:	1ff7f793          	andi	a5,a5,511
    80005872:	97a6                	add	a5,a5,s1
    80005874:	faf44703          	lbu	a4,-81(s0)
    80005878:	00e78c23          	sb	a4,24(a5)
      i++;
    8000587c:	2905                	addiw	s2,s2,1
    8000587e:	b775                	j	8000582a <pipewrite+0x6c>
    80005880:	7b02                	ld	s6,32(sp)
    80005882:	6be2                	ld	s7,24(sp)
    80005884:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80005886:	21848513          	addi	a0,s1,536
    8000588a:	e7cfd0ef          	jal	80002f06 <wakeup>
  release(&pi->lock);
    8000588e:	8526                	mv	a0,s1
    80005890:	be4fb0ef          	jal	80000c74 <release>
  return i;
    80005894:	bf95                	j	80005808 <pipewrite+0x4a>
  int i = 0;
    80005896:	4901                	li	s2,0
    80005898:	b7fd                	j	80005886 <pipewrite+0xc8>
    8000589a:	7b02                	ld	s6,32(sp)
    8000589c:	6be2                	ld	s7,24(sp)
    8000589e:	6c42                	ld	s8,16(sp)
    800058a0:	b7dd                	j	80005886 <pipewrite+0xc8>

00000000800058a2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058a2:	715d                	addi	sp,sp,-80
    800058a4:	e486                	sd	ra,72(sp)
    800058a6:	e0a2                	sd	s0,64(sp)
    800058a8:	fc26                	sd	s1,56(sp)
    800058aa:	f84a                	sd	s2,48(sp)
    800058ac:	f44e                	sd	s3,40(sp)
    800058ae:	f052                	sd	s4,32(sp)
    800058b0:	ec56                	sd	s5,24(sp)
    800058b2:	0880                	addi	s0,sp,80
    800058b4:	84aa                	mv	s1,a0
    800058b6:	892e                	mv	s2,a1
    800058b8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058ba:	b6ffc0ef          	jal	80002428 <myproc>
    800058be:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058c0:	8526                	mv	a0,s1
    800058c2:	b0cfb0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058c6:	2184a703          	lw	a4,536(s1)
    800058ca:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058ce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058d2:	02f71563          	bne	a4,a5,800058fc <piperead+0x5a>
    800058d6:	2244a783          	lw	a5,548(s1)
    800058da:	cb85                	beqz	a5,8000590a <piperead+0x68>
    if(killed(pr)){
    800058dc:	8552                	mv	a0,s4
    800058de:	877fd0ef          	jal	80003154 <killed>
    800058e2:	ed19                	bnez	a0,80005900 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058e4:	85a6                	mv	a1,s1
    800058e6:	854e                	mv	a0,s3
    800058e8:	dd2fd0ef          	jal	80002eba <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058ec:	2184a703          	lw	a4,536(s1)
    800058f0:	21c4a783          	lw	a5,540(s1)
    800058f4:	fef701e3          	beq	a4,a5,800058d6 <piperead+0x34>
    800058f8:	e85a                	sd	s6,16(sp)
    800058fa:	a809                	j	8000590c <piperead+0x6a>
    800058fc:	e85a                	sd	s6,16(sp)
    800058fe:	a039                	j	8000590c <piperead+0x6a>
      release(&pi->lock);
    80005900:	8526                	mv	a0,s1
    80005902:	b72fb0ef          	jal	80000c74 <release>
      return -1;
    80005906:	59fd                	li	s3,-1
    80005908:	a8b1                	j	80005964 <piperead+0xc2>
    8000590a:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000590c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000590e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005910:	05505263          	blez	s5,80005954 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005914:	2184a783          	lw	a5,536(s1)
    80005918:	21c4a703          	lw	a4,540(s1)
    8000591c:	02f70c63          	beq	a4,a5,80005954 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005920:	0017871b          	addiw	a4,a5,1
    80005924:	20e4ac23          	sw	a4,536(s1)
    80005928:	1ff7f793          	andi	a5,a5,511
    8000592c:	97a6                	add	a5,a5,s1
    8000592e:	0187c783          	lbu	a5,24(a5)
    80005932:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005936:	4685                	li	a3,1
    80005938:	fbf40613          	addi	a2,s0,-65
    8000593c:	85ca                	mv	a1,s2
    8000593e:	050a3503          	ld	a0,80(s4)
    80005942:	ed8fc0ef          	jal	8000201a <copyout>
    80005946:	01650763          	beq	a0,s6,80005954 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000594a:	2985                	addiw	s3,s3,1
    8000594c:	0905                	addi	s2,s2,1
    8000594e:	fd3a93e3          	bne	s5,s3,80005914 <piperead+0x72>
    80005952:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005954:	21c48513          	addi	a0,s1,540
    80005958:	daefd0ef          	jal	80002f06 <wakeup>
  release(&pi->lock);
    8000595c:	8526                	mv	a0,s1
    8000595e:	b16fb0ef          	jal	80000c74 <release>
    80005962:	6b42                	ld	s6,16(sp)
  return i;
}
    80005964:	854e                	mv	a0,s3
    80005966:	60a6                	ld	ra,72(sp)
    80005968:	6406                	ld	s0,64(sp)
    8000596a:	74e2                	ld	s1,56(sp)
    8000596c:	7942                	ld	s2,48(sp)
    8000596e:	79a2                	ld	s3,40(sp)
    80005970:	7a02                	ld	s4,32(sp)
    80005972:	6ae2                	ld	s5,24(sp)
    80005974:	6161                	addi	sp,sp,80
    80005976:	8082                	ret

0000000080005978 <flags2perm>:

// no eager segment loading; demand paging will load from inode as needed

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80005978:	1141                	addi	sp,sp,-16
    8000597a:	e422                	sd	s0,8(sp)
    8000597c:	0800                	addi	s0,sp,16
    8000597e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005980:	8905                	andi	a0,a0,1
    80005982:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005984:	8b89                	andi	a5,a5,2
    80005986:	c399                	beqz	a5,8000598c <flags2perm+0x14>
      perm |= PTE_W;
    80005988:	00456513          	ori	a0,a0,4
    return perm;
}
    8000598c:	6422                	ld	s0,8(sp)
    8000598e:	0141                	addi	sp,sp,16
    80005990:	8082                	ret

0000000080005992 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80005992:	df010113          	addi	sp,sp,-528
    80005996:	20113423          	sd	ra,520(sp)
    8000599a:	20813023          	sd	s0,512(sp)
    8000599e:	ffa6                	sd	s1,504(sp)
    800059a0:	f7ce                	sd	s3,488(sp)
    800059a2:	0c00                	addi	s0,sp,528
    800059a4:	84aa                	mv	s1,a0
    800059a6:	e0a43023          	sd	a0,-512(s0)
    800059aa:	e0b43423          	sd	a1,-504(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059ae:	a7bfc0ef          	jal	80002428 <myproc>
    800059b2:	89aa                	mv	s3,a0

  begin_op();
    800059b4:	dd4ff0ef          	jal	80004f88 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800059b8:	8526                	mv	a0,s1
    800059ba:	bfaff0ef          	jal	80004db4 <namei>
    800059be:	cd39                	beqz	a0,80005a1c <kexec+0x8a>
    800059c0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800059c2:	bddfe0ef          	jal	8000459e <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800059c6:	04000713          	li	a4,64
    800059ca:	4681                	li	a3,0
    800059cc:	e5040613          	addi	a2,s0,-432
    800059d0:	4581                	li	a1,0
    800059d2:	8526                	mv	a0,s1
    800059d4:	f5bfe0ef          	jal	8000492e <readi>
    800059d8:	04000793          	li	a5,64
    800059dc:	00f51a63          	bne	a0,a5,800059f0 <kexec+0x5e>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800059e0:	e5042703          	lw	a4,-432(s0)
    800059e4:	464c47b7          	lui	a5,0x464c4
    800059e8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800059ec:	02f70c63          	beq	a4,a5,80005a24 <kexec+0x92>
 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    // If we recorded execip, we must drop the reference but ip is still locked.
    if(p->execip){
    800059f0:	1909b783          	ld	a5,400(s3)
    800059f4:	38078063          	beqz	a5,80005d74 <kexec+0x3e2>
      iunlock(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	c53fe0ef          	jal	8000464c <iunlock>
      iput(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	d21fe0ef          	jal	80004720 <iput>
    } else {
      // drop both the lock and reference on error
      iunlockput(ip);
    }
    end_op();
    80005a04:	deeff0ef          	jal	80004ff2 <end_op>
  }
  return -1;
    80005a08:	557d                	li	a0,-1
}
    80005a0a:	20813083          	ld	ra,520(sp)
    80005a0e:	20013403          	ld	s0,512(sp)
    80005a12:	74fe                	ld	s1,504(sp)
    80005a14:	79be                	ld	s3,488(sp)
    80005a16:	21010113          	addi	sp,sp,528
    80005a1a:	8082                	ret
    end_op();
    80005a1c:	dd6ff0ef          	jal	80004ff2 <end_op>
    return -1;
    80005a20:	557d                	li	a0,-1
    80005a22:	b7e5                	j	80005a0a <kexec+0x78>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a24:	854e                	mv	a0,s3
    80005a26:	d81fc0ef          	jal	800027a6 <proc_pagetable>
    80005a2a:	dea43c23          	sd	a0,-520(s0)
    80005a2e:	d169                	beqz	a0,800059f0 <kexec+0x5e>
    80005a30:	fbca                	sd	s2,496(sp)
    80005a32:	f3d2                	sd	s4,480(sp)
    80005a34:	efd6                	sd	s5,472(sp)
    80005a36:	ebda                	sd	s6,464(sp)
    80005a38:	e7de                	sd	s7,456(sp)
    80005a3a:	e3e2                	sd	s8,448(sp)
    80005a3c:	ff66                	sd	s9,440(sp)
    80005a3e:	fb6a                	sd	s10,432(sp)
    80005a40:	f76e                	sd	s11,424(sp)
  p->nsegs = 0;
    80005a42:	1809ac23          	sw	zero,408(s3)
  p->execip = ip;
    80005a46:	1899b823          	sd	s1,400(s3)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a4a:	e7042903          	lw	s2,-400(s0)
    80005a4e:	e8845783          	lhu	a5,-376(s0)
    80005a52:	cfd1                	beqz	a5,80005aee <kexec+0x15c>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005a54:	4c01                	li	s8,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a56:	4a01                	li	s4,0
    if(ph.type != ELF_PROG_LOAD)
    80005a58:	4c85                	li	s9,1
    if(ph.vaddr % PGSIZE != 0)
    80005a5a:	6d85                	lui	s11,0x1
    80005a5c:	1dfd                	addi	s11,s11,-1 # fff <_entry-0x7ffff001>
    if(p->nsegs < 16){
    80005a5e:	4d3d                	li	s10,15
    80005a60:	a819                	j	80005a76 <kexec+0xe4>
    if(end > sz) sz = end;
    80005a62:	017c7363          	bgeu	s8,s7,80005a68 <kexec+0xd6>
    80005a66:	8c5e                	mv	s8,s7
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a68:	2a05                	addiw	s4,s4,1
    80005a6a:	0389091b          	addiw	s2,s2,56
    80005a6e:	e8845783          	lhu	a5,-376(s0)
    80005a72:	06fa5f63          	bge	s4,a5,80005af0 <kexec+0x15e>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a76:	2901                	sext.w	s2,s2
    80005a78:	03800713          	li	a4,56
    80005a7c:	86ca                	mv	a3,s2
    80005a7e:	e1840613          	addi	a2,s0,-488
    80005a82:	4581                	li	a1,0
    80005a84:	8526                	mv	a0,s1
    80005a86:	ea9fe0ef          	jal	8000492e <readi>
    80005a8a:	03800793          	li	a5,56
    80005a8e:	08f51e63          	bne	a0,a5,80005b2a <kexec+0x198>
    if(ph.type != ELF_PROG_LOAD)
    80005a92:	e1842783          	lw	a5,-488(s0)
    80005a96:	fd9799e3          	bne	a5,s9,80005a68 <kexec+0xd6>
    if(ph.memsz < ph.filesz)
    80005a9a:	e4043703          	ld	a4,-448(s0)
    80005a9e:	e3843683          	ld	a3,-456(s0)
    80005aa2:	08d76463          	bltu	a4,a3,80005b2a <kexec+0x198>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005aa6:	e2843783          	ld	a5,-472(s0)
    80005aaa:	00f70bb3          	add	s7,a4,a5
    80005aae:	06fbee63          	bltu	s7,a5,80005b2a <kexec+0x198>
    if(ph.vaddr % PGSIZE != 0)
    80005ab2:	01b7f633          	and	a2,a5,s11
    80005ab6:	ea35                	bnez	a2,80005b2a <kexec+0x198>
    if(p->nsegs < 16){
    80005ab8:	1989aa83          	lw	s5,408(s3)
    80005abc:	fb5d43e3          	blt	s10,s5,80005a62 <kexec+0xd0>
      p->segs[p->nsegs].va = ph.vaddr;
    80005ac0:	005a9b13          	slli	s6,s5,0x5
    80005ac4:	9b4e                	add	s6,s6,s3
    80005ac6:	1afb3023          	sd	a5,416(s6)
      p->segs[p->nsegs].memsz = ph.memsz;
    80005aca:	1aeb3423          	sd	a4,424(s6)
      p->segs[p->nsegs].filesz = ph.filesz;
    80005ace:	1adb3823          	sd	a3,432(s6)
      p->segs[p->nsegs].off = ph.off;
    80005ad2:	e2043783          	ld	a5,-480(s0)
    80005ad6:	1afb2c23          	sw	a5,440(s6)
      p->segs[p->nsegs].perm = flags2perm(ph.flags);
    80005ada:	e1c42503          	lw	a0,-484(s0)
    80005ade:	e9bff0ef          	jal	80005978 <flags2perm>
    80005ae2:	1aab2e23          	sw	a0,444(s6)
      p->nsegs++;
    80005ae6:	2a85                	addiw	s5,s5,1
    80005ae8:	1959ac23          	sw	s5,408(s3)
    80005aec:	bf9d                	j	80005a62 <kexec+0xd0>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005aee:	4c01                	li	s8,0
  iunlock(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	b5bfe0ef          	jal	8000464c <iunlock>
  end_op();
    80005af6:	cfcff0ef          	jal	80004ff2 <end_op>
  p = myproc();
    80005afa:	92ffc0ef          	jal	80002428 <myproc>
    80005afe:	89aa                	mv	s3,a0
  uint64 oldsz = p->sz;
    80005b00:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b04:	6a05                	lui	s4,0x1
    80005b06:	1a7d                	addi	s4,s4,-1 # fff <_entry-0x7ffff001>
    80005b08:	9a62                	add	s4,s4,s8
    80005b0a:	77fd                	lui	a5,0xfffff
    80005b0c:	00fa7a33          	and	s4,s4,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80005b10:	4691                	li	a3,4
    80005b12:	6609                	lui	a2,0x2
    80005b14:	9652                	add	a2,a2,s4
    80005b16:	85d2                	mv	a1,s4
    80005b18:	df843483          	ld	s1,-520(s0)
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	b33fb0ef          	jal	80001650 <uvmalloc>
    80005b22:	8c2a                	mv	s8,a0
    80005b24:	e50d                	bnez	a0,80005b4e <kexec+0x1bc>
  ip = 0;
    80005b26:	8c52                	mv	s8,s4
    80005b28:	4481                	li	s1,0
    proc_freepagetable(pagetable, sz);
    80005b2a:	85e2                	mv	a1,s8
    80005b2c:	df843503          	ld	a0,-520(s0)
    80005b30:	cfbfc0ef          	jal	8000282a <proc_freepagetable>
  return -1;
    80005b34:	557d                	li	a0,-1
  if(ip){
    80005b36:	22049563          	bnez	s1,80005d60 <kexec+0x3ce>
    80005b3a:	795e                	ld	s2,496(sp)
    80005b3c:	7a1e                	ld	s4,480(sp)
    80005b3e:	6afe                	ld	s5,472(sp)
    80005b40:	6b5e                	ld	s6,464(sp)
    80005b42:	6bbe                	ld	s7,456(sp)
    80005b44:	6c1e                	ld	s8,448(sp)
    80005b46:	7cfa                	ld	s9,440(sp)
    80005b48:	7d5a                	ld	s10,432(sp)
    80005b4a:	7dba                	ld	s11,424(sp)
    80005b4c:	bd7d                	j	80005a0a <kexec+0x78>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80005b4e:	77f9                	lui	a5,0xffffe
    80005b50:	00f50db3          	add	s11,a0,a5
    80005b54:	85ee                	mv	a1,s11
    80005b56:	8526                	mv	a0,s1
    80005b58:	db9fb0ef          	jal	80001910 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80005b5c:	7b7d                	lui	s6,0xfffff
    80005b5e:	9b62                	add	s6,s6,s8
  for(argc = 0; argv[argc]; argc++) {
    80005b60:	e0843783          	ld	a5,-504(s0)
    80005b64:	6388                	ld	a0,0(a5)
    80005b66:	c125                	beqz	a0,80005bc6 <kexec+0x234>
    80005b68:	e9040a13          	addi	s4,s0,-368
    80005b6c:	f9040b93          	addi	s7,s0,-112
  sp = sz;
    80005b70:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005b72:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b74:	aacfb0ef          	jal	80000e20 <strlen>
    80005b78:	2505                	addiw	a0,a0,1
    80005b7a:	40a90533          	sub	a0,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005b7e:	ff057913          	andi	s2,a0,-16
    if(sp < stackbase)
    80005b82:	1d696b63          	bltu	s2,s6,80005d58 <kexec+0x3c6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005b86:	e0843d03          	ld	s10,-504(s0)
    80005b8a:	000d3a83          	ld	s5,0(s10)
    80005b8e:	8556                	mv	a0,s5
    80005b90:	a90fb0ef          	jal	80000e20 <strlen>
    80005b94:	0015069b          	addiw	a3,a0,1
    80005b98:	8656                	mv	a2,s5
    80005b9a:	85ca                	mv	a1,s2
    80005b9c:	df843503          	ld	a0,-520(s0)
    80005ba0:	c7afc0ef          	jal	8000201a <copyout>
    80005ba4:	1a054c63          	bltz	a0,80005d5c <kexec+0x3ca>
    ustack[argc] = sp;
    80005ba8:	012a3023          	sd	s2,0(s4)
  for(argc = 0; argv[argc]; argc++) {
    80005bac:	0485                	addi	s1,s1,1
    80005bae:	008d0793          	addi	a5,s10,8
    80005bb2:	e0f43423          	sd	a5,-504(s0)
    80005bb6:	008d3503          	ld	a0,8(s10)
    80005bba:	c901                	beqz	a0,80005bca <kexec+0x238>
    if(argc >= MAXARG)
    80005bbc:	0a21                	addi	s4,s4,8
    80005bbe:	fb7a1be3          	bne	s4,s7,80005b74 <kexec+0x1e2>
  ip = 0;
    80005bc2:	4481                	li	s1,0
    80005bc4:	b79d                	j	80005b2a <kexec+0x198>
  sp = sz;
    80005bc6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005bc8:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bca:	00349793          	slli	a5,s1,0x3
    80005bce:	f9078793          	addi	a5,a5,-112 # ffffffffffffdf90 <end+0xffffffff7fe4dc68>
    80005bd2:	97a2                	add	a5,a5,s0
    80005bd4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005bd8:	00148693          	addi	a3,s1,1
    80005bdc:	068e                	slli	a3,a3,0x3
    80005bde:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005be2:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005be6:	8a62                	mv	s4,s8
  if(sp < stackbase)
    80005be8:	f3696fe3          	bltu	s2,s6,80005b26 <kexec+0x194>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005bec:	e9040613          	addi	a2,s0,-368
    80005bf0:	85ca                	mv	a1,s2
    80005bf2:	df843503          	ld	a0,-520(s0)
    80005bf6:	c24fc0ef          	jal	8000201a <copyout>
    80005bfa:	f20546e3          	bltz	a0,80005b26 <kexec+0x194>
  p->trapframe->a1 = sp;
    80005bfe:	0589b783          	ld	a5,88(s3)
    80005c02:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c06:	e0043783          	ld	a5,-512(s0)
    80005c0a:	0007c703          	lbu	a4,0(a5)
    80005c0e:	cf11                	beqz	a4,80005c2a <kexec+0x298>
    80005c10:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c12:	02f00693          	li	a3,47
    80005c16:	a029                	j	80005c20 <kexec+0x28e>
  for(last=s=path; *s; s++)
    80005c18:	0785                	addi	a5,a5,1
    80005c1a:	fff7c703          	lbu	a4,-1(a5)
    80005c1e:	c711                	beqz	a4,80005c2a <kexec+0x298>
    if(*s == '/')
    80005c20:	fed71ce3          	bne	a4,a3,80005c18 <kexec+0x286>
      last = s+1;
    80005c24:	e0f43023          	sd	a5,-512(s0)
    80005c28:	bfc5                	j	80005c18 <kexec+0x286>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c2a:	4641                	li	a2,16
    80005c2c:	e0043583          	ld	a1,-512(s0)
    80005c30:	15898513          	addi	a0,s3,344
    80005c34:	9bafb0ef          	jal	80000dee <safestrcpy>
  oldpagetable = p->pagetable;
    80005c38:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005c3c:	df843783          	ld	a5,-520(s0)
    80005c40:	04f9b823          	sd	a5,80(s3)
  p->sz = sz;
    80005c44:	0589b423          	sd	s8,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c48:	0589b783          	ld	a5,88(s3)
    80005c4c:	e6843703          	ld	a4,-408(s0)
    80005c50:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c52:	0589b783          	ld	a5,88(s3)
    80005c56:	0327b823          	sd	s2,48(a5)
  p->heap_brk = sz - (USERSTACK+1)*PGSIZE; // heap end at end of program segments
    80005c5a:	19b9b423          	sd	s11,392(s3)
  p->page_seq_ctr = 1; // reset per-process RESIDENT sequence after exec
    80005c5e:	4785                	li	a5,1
    80005c60:	3af9b023          	sd	a5,928(s3)
  proc_freepagetable(oldpagetable, oldsz);
    80005c64:	85e6                	mv	a1,s9
    80005c66:	bc5fc0ef          	jal	8000282a <proc_freepagetable>
  memset(p->swap_bitmap, 0, sizeof(p->swap_bitmap));
    80005c6a:	08000613          	li	a2,128
    80005c6e:	4581                	li	a1,0
    80005c70:	3b498513          	addi	a0,s3,948
    80005c74:	83cfb0ef          	jal	80000cb0 <memset>
  p->swap_pages = 0;
    80005c78:	3a09a823          	sw	zero,944(s3)
  for(int mi=0; mi<PGMETA_SIZE; mi++){
    80005c7c:	43898793          	addi	a5,s3,1080
    80005c80:	894e                	mv	s2,s3
    80005c82:	6719                	lui	a4,0x6
    80005c84:	43870713          	addi	a4,a4,1080 # 6438 <_entry-0x7fff9bc8>
    80005c88:	974e                	add	a4,a4,s3
    p->pgmeta[mi].slot = 0xffff;
    80005c8a:	56fd                	li	a3,-1
    p->pgmeta[mi].va = 0;
    80005c8c:	0007b023          	sd	zero,0(a5)
    p->pgmeta[mi].seq = 0;
    80005c90:	0007b423          	sd	zero,8(a5)
    p->pgmeta[mi].resident = 0;
    80005c94:	00078823          	sb	zero,16(a5)
    p->pgmeta[mi].dirty = 0;
    80005c98:	000788a3          	sb	zero,17(a5)
    p->pgmeta[mi].referenced = 0;
    80005c9c:	00078923          	sb	zero,18(a5)
    p->pgmeta[mi].in_swap = 0;
    80005ca0:	000789a3          	sb	zero,19(a5)
    p->pgmeta[mi].slot = 0xffff;
    80005ca4:	00d79a23          	sh	a3,20(a5)
    p->pgmeta[mi].perm = 0;
    80005ca8:	00079b23          	sh	zero,22(a5)
  for(int mi=0; mi<PGMETA_SIZE; mi++){
    80005cac:	07e1                	addi	a5,a5,24
    80005cae:	fce79fe3          	bne	a5,a4,80005c8c <kexec+0x2fa>
  p->clock_hand = 0;
    80005cb2:	6799                	lui	a5,0x6
    80005cb4:	97ce                	add	a5,a5,s3
    80005cb6:	4207ac23          	sw	zero,1080(a5) # 6438 <_entry-0x7fff9bc8>
  proc_swapon(p);
    80005cba:	854e                	mv	a0,s3
    80005cbc:	873fc0ef          	jal	8000252e <proc_swapon>
  for(int i = 0; i < p->nsegs; i++){
    80005cc0:	1989a783          	lw	a5,408(s3)
    80005cc4:	04f05c63          	blez	a5,80005d1c <kexec+0x38a>
    80005cc8:	0796                	slli	a5,a5,0x5
    80005cca:	01278333          	add	t1,a5,s2
  uint64 text_lo = 0, text_hi = 0, data_lo = 0, data_hi = 0;
    80005cce:	4781                	li	a5,0
    80005cd0:	4701                	li	a4,0
    80005cd2:	4681                	li	a3,0
    80005cd4:	4601                	li	a2,0
    80005cd6:	a01d                	j	80005cfc <kexec+0x36a>
      if(text_lo == 0 || sva < text_lo) text_lo = sva;
    80005cd8:	8642                	mv	a2,a6
      if(ev > text_hi) text_hi = ev;
    80005cda:	00a6f363          	bgeu	a3,a0,80005ce0 <kexec+0x34e>
    80005cde:	86aa                	mv	a3,a0
    if(p->segs[i].perm & PTE_W){
    80005ce0:	8991                	andi	a1,a1,4
    80005ce2:	c989                	beqz	a1,80005cf4 <kexec+0x362>
      if(data_lo == 0 || sva < data_lo) data_lo = sva;
    80005ce4:	c701                	beqz	a4,80005cec <kexec+0x35a>
    80005ce6:	01077363          	bgeu	a4,a6,80005cec <kexec+0x35a>
    80005cea:	883a                	mv	a6,a4
      if(ev > data_hi) data_hi = ev;
    80005cec:	00a7f363          	bgeu	a5,a0,80005cf2 <kexec+0x360>
    80005cf0:	87aa                	mv	a5,a0
    80005cf2:	8742                	mv	a4,a6
  for(int i = 0; i < p->nsegs; i++){
    80005cf4:	02090913          	addi	s2,s2,32
    80005cf8:	02690663          	beq	s2,t1,80005d24 <kexec+0x392>
    uint64 sva = p->segs[i].va;
    80005cfc:	1a093803          	ld	a6,416(s2)
    uint64 ev = p->segs[i].va + p->segs[i].memsz;
    80005d00:	1a893503          	ld	a0,424(s2)
    80005d04:	9542                	add	a0,a0,a6
    if(p->segs[i].perm & PTE_X){
    80005d06:	1bc92583          	lw	a1,444(s2)
    80005d0a:	0085f893          	andi	a7,a1,8
    80005d0e:	fc0889e3          	beqz	a7,80005ce0 <kexec+0x34e>
      if(text_lo == 0 || sva < text_lo) text_lo = sva;
    80005d12:	d279                	beqz	a2,80005cd8 <kexec+0x346>
    80005d14:	fcc873e3          	bgeu	a6,a2,80005cda <kexec+0x348>
    80005d18:	8642                	mv	a2,a6
    80005d1a:	b7c1                	j	80005cda <kexec+0x348>
  uint64 text_lo = 0, text_hi = 0, data_lo = 0, data_hi = 0;
    80005d1c:	4781                	li	a5,0
    80005d1e:	4701                	li	a4,0
    80005d20:	4681                	li	a3,0
    80005d22:	4601                	li	a2,0
  uint64 stack_top = p->trapframe->sp;
    80005d24:	0589b583          	ld	a1,88(s3)
  printf("[pid %d] INIT-LAZYMAP text=[0x%lx,0x%lx) data=[0x%lx,0x%lx) heap_start=0x%lx stack_top=0x%lx\n",
    80005d28:	0305b883          	ld	a7,48(a1)
    80005d2c:	1889b803          	ld	a6,392(s3)
    80005d30:	0309a583          	lw	a1,48(s3)
    80005d34:	00003517          	auipc	a0,0x3
    80005d38:	c0c50513          	addi	a0,a0,-1012 # 80008940 <etext+0x940>
    80005d3c:	fbefa0ef          	jal	800004fa <printf>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005d40:	0004851b          	sext.w	a0,s1
    80005d44:	795e                	ld	s2,496(sp)
    80005d46:	7a1e                	ld	s4,480(sp)
    80005d48:	6afe                	ld	s5,472(sp)
    80005d4a:	6b5e                	ld	s6,464(sp)
    80005d4c:	6bbe                	ld	s7,456(sp)
    80005d4e:	6c1e                	ld	s8,448(sp)
    80005d50:	7cfa                	ld	s9,440(sp)
    80005d52:	7d5a                	ld	s10,432(sp)
    80005d54:	7dba                	ld	s11,424(sp)
    80005d56:	b955                	j	80005a0a <kexec+0x78>
  ip = 0;
    80005d58:	4481                	li	s1,0
    80005d5a:	bbc1                	j	80005b2a <kexec+0x198>
    80005d5c:	4481                	li	s1,0
  if(pagetable)
    80005d5e:	b3f1                	j	80005b2a <kexec+0x198>
    80005d60:	795e                	ld	s2,496(sp)
    80005d62:	7a1e                	ld	s4,480(sp)
    80005d64:	6afe                	ld	s5,472(sp)
    80005d66:	6b5e                	ld	s6,464(sp)
    80005d68:	6bbe                	ld	s7,456(sp)
    80005d6a:	6c1e                	ld	s8,448(sp)
    80005d6c:	7cfa                	ld	s9,440(sp)
    80005d6e:	7d5a                	ld	s10,432(sp)
    80005d70:	7dba                	ld	s11,424(sp)
    80005d72:	b9bd                	j	800059f0 <kexec+0x5e>
      iunlockput(ip);
    80005d74:	8526                	mv	a0,s1
    80005d76:	a33fe0ef          	jal	800047a8 <iunlockput>
    80005d7a:	b169                	j	80005a04 <kexec+0x72>

0000000080005d7c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d7c:	7179                	addi	sp,sp,-48
    80005d7e:	f406                	sd	ra,40(sp)
    80005d80:	f022                	sd	s0,32(sp)
    80005d82:	ec26                	sd	s1,24(sp)
    80005d84:	e84a                	sd	s2,16(sp)
    80005d86:	1800                	addi	s0,sp,48
    80005d88:	892e                	mv	s2,a1
    80005d8a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005d8c:	fdc40593          	addi	a1,s0,-36
    80005d90:	b1dfd0ef          	jal	800038ac <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d94:	fdc42703          	lw	a4,-36(s0)
    80005d98:	47bd                	li	a5,15
    80005d9a:	02e7e963          	bltu	a5,a4,80005dcc <argfd+0x50>
    80005d9e:	e8afc0ef          	jal	80002428 <myproc>
    80005da2:	fdc42703          	lw	a4,-36(s0)
    80005da6:	01a70793          	addi	a5,a4,26
    80005daa:	078e                	slli	a5,a5,0x3
    80005dac:	953e                	add	a0,a0,a5
    80005dae:	611c                	ld	a5,0(a0)
    80005db0:	c385                	beqz	a5,80005dd0 <argfd+0x54>
    return -1;
  if(pfd)
    80005db2:	00090463          	beqz	s2,80005dba <argfd+0x3e>
    *pfd = fd;
    80005db6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005dba:	4501                	li	a0,0
  if(pf)
    80005dbc:	c091                	beqz	s1,80005dc0 <argfd+0x44>
    *pf = f;
    80005dbe:	e09c                	sd	a5,0(s1)
}
    80005dc0:	70a2                	ld	ra,40(sp)
    80005dc2:	7402                	ld	s0,32(sp)
    80005dc4:	64e2                	ld	s1,24(sp)
    80005dc6:	6942                	ld	s2,16(sp)
    80005dc8:	6145                	addi	sp,sp,48
    80005dca:	8082                	ret
    return -1;
    80005dcc:	557d                	li	a0,-1
    80005dce:	bfcd                	j	80005dc0 <argfd+0x44>
    80005dd0:	557d                	li	a0,-1
    80005dd2:	b7fd                	j	80005dc0 <argfd+0x44>

0000000080005dd4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005dd4:	1101                	addi	sp,sp,-32
    80005dd6:	ec06                	sd	ra,24(sp)
    80005dd8:	e822                	sd	s0,16(sp)
    80005dda:	e426                	sd	s1,8(sp)
    80005ddc:	1000                	addi	s0,sp,32
    80005dde:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005de0:	e48fc0ef          	jal	80002428 <myproc>
    80005de4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005de6:	0d050793          	addi	a5,a0,208
    80005dea:	4501                	li	a0,0
    80005dec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005dee:	6398                	ld	a4,0(a5)
    80005df0:	cb19                	beqz	a4,80005e06 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80005df2:	2505                	addiw	a0,a0,1
    80005df4:	07a1                	addi	a5,a5,8
    80005df6:	fed51ce3          	bne	a0,a3,80005dee <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005dfa:	557d                	li	a0,-1
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret
      p->ofile[fd] = f;
    80005e06:	01a50793          	addi	a5,a0,26
    80005e0a:	078e                	slli	a5,a5,0x3
    80005e0c:	963e                	add	a2,a2,a5
    80005e0e:	e204                	sd	s1,0(a2)
      return fd;
    80005e10:	b7f5                	j	80005dfc <fdalloc+0x28>

0000000080005e12 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005e12:	715d                	addi	sp,sp,-80
    80005e14:	e486                	sd	ra,72(sp)
    80005e16:	e0a2                	sd	s0,64(sp)
    80005e18:	fc26                	sd	s1,56(sp)
    80005e1a:	f84a                	sd	s2,48(sp)
    80005e1c:	f44e                	sd	s3,40(sp)
    80005e1e:	ec56                	sd	s5,24(sp)
    80005e20:	e85a                	sd	s6,16(sp)
    80005e22:	0880                	addi	s0,sp,80
    80005e24:	8b2e                	mv	s6,a1
    80005e26:	89b2                	mv	s3,a2
    80005e28:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005e2a:	fb040593          	addi	a1,s0,-80
    80005e2e:	fa1fe0ef          	jal	80004dce <nameiparent>
    80005e32:	84aa                	mv	s1,a0
    80005e34:	10050a63          	beqz	a0,80005f48 <create+0x136>
    return 0;

  ilock(dp);
    80005e38:	f66fe0ef          	jal	8000459e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005e3c:	4601                	li	a2,0
    80005e3e:	fb040593          	addi	a1,s0,-80
    80005e42:	8526                	mv	a0,s1
    80005e44:	d0bfe0ef          	jal	80004b4e <dirlookup>
    80005e48:	8aaa                	mv	s5,a0
    80005e4a:	c129                	beqz	a0,80005e8c <create+0x7a>
    iunlockput(dp);
    80005e4c:	8526                	mv	a0,s1
    80005e4e:	95bfe0ef          	jal	800047a8 <iunlockput>
    ilock(ip);
    80005e52:	8556                	mv	a0,s5
    80005e54:	f4afe0ef          	jal	8000459e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005e58:	4789                	li	a5,2
    80005e5a:	02fb1463          	bne	s6,a5,80005e82 <create+0x70>
    80005e5e:	044ad783          	lhu	a5,68(s5)
    80005e62:	37f9                	addiw	a5,a5,-2
    80005e64:	17c2                	slli	a5,a5,0x30
    80005e66:	93c1                	srli	a5,a5,0x30
    80005e68:	4705                	li	a4,1
    80005e6a:	00f76c63          	bltu	a4,a5,80005e82 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005e6e:	8556                	mv	a0,s5
    80005e70:	60a6                	ld	ra,72(sp)
    80005e72:	6406                	ld	s0,64(sp)
    80005e74:	74e2                	ld	s1,56(sp)
    80005e76:	7942                	ld	s2,48(sp)
    80005e78:	79a2                	ld	s3,40(sp)
    80005e7a:	6ae2                	ld	s5,24(sp)
    80005e7c:	6b42                	ld	s6,16(sp)
    80005e7e:	6161                	addi	sp,sp,80
    80005e80:	8082                	ret
    iunlockput(ip);
    80005e82:	8556                	mv	a0,s5
    80005e84:	925fe0ef          	jal	800047a8 <iunlockput>
    return 0;
    80005e88:	4a81                	li	s5,0
    80005e8a:	b7d5                	j	80005e6e <create+0x5c>
    80005e8c:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005e8e:	85da                	mv	a1,s6
    80005e90:	4088                	lw	a0,0(s1)
    80005e92:	d9cfe0ef          	jal	8000442e <ialloc>
    80005e96:	8a2a                	mv	s4,a0
    80005e98:	cd15                	beqz	a0,80005ed4 <create+0xc2>
  ilock(ip);
    80005e9a:	f04fe0ef          	jal	8000459e <ilock>
  ip->major = major;
    80005e9e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005ea2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005ea6:	4905                	li	s2,1
    80005ea8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005eac:	8552                	mv	a0,s4
    80005eae:	e3cfe0ef          	jal	800044ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005eb2:	032b0763          	beq	s6,s2,80005ee0 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80005eb6:	004a2603          	lw	a2,4(s4)
    80005eba:	fb040593          	addi	a1,s0,-80
    80005ebe:	8526                	mv	a0,s1
    80005ec0:	e5bfe0ef          	jal	80004d1a <dirlink>
    80005ec4:	06054563          	bltz	a0,80005f2e <create+0x11c>
  iunlockput(dp);
    80005ec8:	8526                	mv	a0,s1
    80005eca:	8dffe0ef          	jal	800047a8 <iunlockput>
  return ip;
    80005ece:	8ad2                	mv	s5,s4
    80005ed0:	7a02                	ld	s4,32(sp)
    80005ed2:	bf71                	j	80005e6e <create+0x5c>
    iunlockput(dp);
    80005ed4:	8526                	mv	a0,s1
    80005ed6:	8d3fe0ef          	jal	800047a8 <iunlockput>
    return 0;
    80005eda:	8ad2                	mv	s5,s4
    80005edc:	7a02                	ld	s4,32(sp)
    80005ede:	bf41                	j	80005e6e <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ee0:	004a2603          	lw	a2,4(s4)
    80005ee4:	00003597          	auipc	a1,0x3
    80005ee8:	abc58593          	addi	a1,a1,-1348 # 800089a0 <etext+0x9a0>
    80005eec:	8552                	mv	a0,s4
    80005eee:	e2dfe0ef          	jal	80004d1a <dirlink>
    80005ef2:	02054e63          	bltz	a0,80005f2e <create+0x11c>
    80005ef6:	40d0                	lw	a2,4(s1)
    80005ef8:	00003597          	auipc	a1,0x3
    80005efc:	ab058593          	addi	a1,a1,-1360 # 800089a8 <etext+0x9a8>
    80005f00:	8552                	mv	a0,s4
    80005f02:	e19fe0ef          	jal	80004d1a <dirlink>
    80005f06:	02054463          	bltz	a0,80005f2e <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005f0a:	004a2603          	lw	a2,4(s4)
    80005f0e:	fb040593          	addi	a1,s0,-80
    80005f12:	8526                	mv	a0,s1
    80005f14:	e07fe0ef          	jal	80004d1a <dirlink>
    80005f18:	00054b63          	bltz	a0,80005f2e <create+0x11c>
    dp->nlink++;  // for ".."
    80005f1c:	04a4d783          	lhu	a5,74(s1)
    80005f20:	2785                	addiw	a5,a5,1
    80005f22:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f26:	8526                	mv	a0,s1
    80005f28:	dc2fe0ef          	jal	800044ea <iupdate>
    80005f2c:	bf71                	j	80005ec8 <create+0xb6>
  ip->nlink = 0;
    80005f2e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005f32:	8552                	mv	a0,s4
    80005f34:	db6fe0ef          	jal	800044ea <iupdate>
  iunlockput(ip);
    80005f38:	8552                	mv	a0,s4
    80005f3a:	86ffe0ef          	jal	800047a8 <iunlockput>
  iunlockput(dp);
    80005f3e:	8526                	mv	a0,s1
    80005f40:	869fe0ef          	jal	800047a8 <iunlockput>
  return 0;
    80005f44:	7a02                	ld	s4,32(sp)
    80005f46:	b725                	j	80005e6e <create+0x5c>
    return 0;
    80005f48:	8aaa                	mv	s5,a0
    80005f4a:	b715                	j	80005e6e <create+0x5c>

0000000080005f4c <sys_dup>:
{
    80005f4c:	7179                	addi	sp,sp,-48
    80005f4e:	f406                	sd	ra,40(sp)
    80005f50:	f022                	sd	s0,32(sp)
    80005f52:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005f54:	fd840613          	addi	a2,s0,-40
    80005f58:	4581                	li	a1,0
    80005f5a:	4501                	li	a0,0
    80005f5c:	e21ff0ef          	jal	80005d7c <argfd>
    return -1;
    80005f60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005f62:	02054363          	bltz	a0,80005f88 <sys_dup+0x3c>
    80005f66:	ec26                	sd	s1,24(sp)
    80005f68:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005f6a:	fd843903          	ld	s2,-40(s0)
    80005f6e:	854a                	mv	a0,s2
    80005f70:	e65ff0ef          	jal	80005dd4 <fdalloc>
    80005f74:	84aa                	mv	s1,a0
    return -1;
    80005f76:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005f78:	00054d63          	bltz	a0,80005f92 <sys_dup+0x46>
  filedup(f);
    80005f7c:	854a                	mv	a0,s2
    80005f7e:	bd0ff0ef          	jal	8000534e <filedup>
  return fd;
    80005f82:	87a6                	mv	a5,s1
    80005f84:	64e2                	ld	s1,24(sp)
    80005f86:	6942                	ld	s2,16(sp)
}
    80005f88:	853e                	mv	a0,a5
    80005f8a:	70a2                	ld	ra,40(sp)
    80005f8c:	7402                	ld	s0,32(sp)
    80005f8e:	6145                	addi	sp,sp,48
    80005f90:	8082                	ret
    80005f92:	64e2                	ld	s1,24(sp)
    80005f94:	6942                	ld	s2,16(sp)
    80005f96:	bfcd                	j	80005f88 <sys_dup+0x3c>

0000000080005f98 <sys_read>:
{
    80005f98:	7139                	addi	sp,sp,-64
    80005f9a:	fc06                	sd	ra,56(sp)
    80005f9c:	f822                	sd	s0,48(sp)
    80005f9e:	0080                	addi	s0,sp,64
  argaddr(1, &p);
    80005fa0:	fc840593          	addi	a1,s0,-56
    80005fa4:	4505                	li	a0,1
    80005fa6:	923fd0ef          	jal	800038c8 <argaddr>
  argint(2, &n);
    80005faa:	fd440593          	addi	a1,s0,-44
    80005fae:	4509                	li	a0,2
    80005fb0:	8fdfd0ef          	jal	800038ac <argint>
  if(argfd(0, 0, &f) < 0)
    80005fb4:	fd840613          	addi	a2,s0,-40
    80005fb8:	4581                	li	a1,0
    80005fba:	4501                	li	a0,0
    80005fbc:	dc1ff0ef          	jal	80005d7c <argfd>
    80005fc0:	87aa                	mv	a5,a0
    return -1;
    80005fc2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005fc4:	0207c063          	bltz	a5,80005fe4 <sys_read+0x4c>
    80005fc8:	f426                	sd	s1,40(sp)
  result = fileread(f, p, n);
    80005fca:	fd442603          	lw	a2,-44(s0)
    80005fce:	fc843583          	ld	a1,-56(s0)
    80005fd2:	fd843503          	ld	a0,-40(s0)
    80005fd6:	cdeff0ef          	jal	800054b4 <fileread>
    80005fda:	84aa                	mv	s1,a0
  if(result > 0) {
    80005fdc:	00a04863          	bgtz	a0,80005fec <sys_read+0x54>
  return result;
    80005fe0:	8526                	mv	a0,s1
    80005fe2:	74a2                	ld	s1,40(sp)
}
    80005fe4:	70e2                	ld	ra,56(sp)
    80005fe6:	7442                	ld	s0,48(sp)
    80005fe8:	6121                	addi	sp,sp,64
    80005fea:	8082                	ret
    update_read_count(result);
    80005fec:	9b1fd0ef          	jal	8000399c <update_read_count>
    80005ff0:	bfc5                	j	80005fe0 <sys_read+0x48>

0000000080005ff2 <sys_write>:
{
    80005ff2:	7179                	addi	sp,sp,-48
    80005ff4:	f406                	sd	ra,40(sp)
    80005ff6:	f022                	sd	s0,32(sp)
    80005ff8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ffa:	fd840593          	addi	a1,s0,-40
    80005ffe:	4505                	li	a0,1
    80006000:	8c9fd0ef          	jal	800038c8 <argaddr>
  argint(2, &n);
    80006004:	fe440593          	addi	a1,s0,-28
    80006008:	4509                	li	a0,2
    8000600a:	8a3fd0ef          	jal	800038ac <argint>
  if(argfd(0, 0, &f) < 0)
    8000600e:	fe840613          	addi	a2,s0,-24
    80006012:	4581                	li	a1,0
    80006014:	4501                	li	a0,0
    80006016:	d67ff0ef          	jal	80005d7c <argfd>
    8000601a:	87aa                	mv	a5,a0
    return -1;
    8000601c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000601e:	0007ca63          	bltz	a5,80006032 <sys_write+0x40>
  return filewrite(f, p, n);
    80006022:	fe442603          	lw	a2,-28(s0)
    80006026:	fd843583          	ld	a1,-40(s0)
    8000602a:	fe843503          	ld	a0,-24(s0)
    8000602e:	d44ff0ef          	jal	80005572 <filewrite>
}
    80006032:	70a2                	ld	ra,40(sp)
    80006034:	7402                	ld	s0,32(sp)
    80006036:	6145                	addi	sp,sp,48
    80006038:	8082                	ret

000000008000603a <sys_close>:
{
    8000603a:	1101                	addi	sp,sp,-32
    8000603c:	ec06                	sd	ra,24(sp)
    8000603e:	e822                	sd	s0,16(sp)
    80006040:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006042:	fe040613          	addi	a2,s0,-32
    80006046:	fec40593          	addi	a1,s0,-20
    8000604a:	4501                	li	a0,0
    8000604c:	d31ff0ef          	jal	80005d7c <argfd>
    return -1;
    80006050:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006052:	02054063          	bltz	a0,80006072 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80006056:	bd2fc0ef          	jal	80002428 <myproc>
    8000605a:	fec42783          	lw	a5,-20(s0)
    8000605e:	07e9                	addi	a5,a5,26
    80006060:	078e                	slli	a5,a5,0x3
    80006062:	953e                	add	a0,a0,a5
    80006064:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80006068:	fe043503          	ld	a0,-32(s0)
    8000606c:	b28ff0ef          	jal	80005394 <fileclose>
  return 0;
    80006070:	4781                	li	a5,0
}
    80006072:	853e                	mv	a0,a5
    80006074:	60e2                	ld	ra,24(sp)
    80006076:	6442                	ld	s0,16(sp)
    80006078:	6105                	addi	sp,sp,32
    8000607a:	8082                	ret

000000008000607c <sys_fstat>:
{
    8000607c:	1101                	addi	sp,sp,-32
    8000607e:	ec06                	sd	ra,24(sp)
    80006080:	e822                	sd	s0,16(sp)
    80006082:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80006084:	fe040593          	addi	a1,s0,-32
    80006088:	4505                	li	a0,1
    8000608a:	83ffd0ef          	jal	800038c8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000608e:	fe840613          	addi	a2,s0,-24
    80006092:	4581                	li	a1,0
    80006094:	4501                	li	a0,0
    80006096:	ce7ff0ef          	jal	80005d7c <argfd>
    8000609a:	87aa                	mv	a5,a0
    return -1;
    8000609c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000609e:	0007c863          	bltz	a5,800060ae <sys_fstat+0x32>
  return filestat(f, st);
    800060a2:	fe043583          	ld	a1,-32(s0)
    800060a6:	fe843503          	ld	a0,-24(s0)
    800060aa:	bacff0ef          	jal	80005456 <filestat>
}
    800060ae:	60e2                	ld	ra,24(sp)
    800060b0:	6442                	ld	s0,16(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret

00000000800060b6 <sys_link>:
{
    800060b6:	7169                	addi	sp,sp,-304
    800060b8:	f606                	sd	ra,296(sp)
    800060ba:	f222                	sd	s0,288(sp)
    800060bc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060be:	08000613          	li	a2,128
    800060c2:	ed040593          	addi	a1,s0,-304
    800060c6:	4501                	li	a0,0
    800060c8:	81dfd0ef          	jal	800038e4 <argstr>
    return -1;
    800060cc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060ce:	0c054e63          	bltz	a0,800061aa <sys_link+0xf4>
    800060d2:	08000613          	li	a2,128
    800060d6:	f5040593          	addi	a1,s0,-176
    800060da:	4505                	li	a0,1
    800060dc:	809fd0ef          	jal	800038e4 <argstr>
    return -1;
    800060e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060e2:	0c054463          	bltz	a0,800061aa <sys_link+0xf4>
    800060e6:	ee26                	sd	s1,280(sp)
  begin_op();
    800060e8:	ea1fe0ef          	jal	80004f88 <begin_op>
  if((ip = namei(old)) == 0){
    800060ec:	ed040513          	addi	a0,s0,-304
    800060f0:	cc5fe0ef          	jal	80004db4 <namei>
    800060f4:	84aa                	mv	s1,a0
    800060f6:	c53d                	beqz	a0,80006164 <sys_link+0xae>
  ilock(ip);
    800060f8:	ca6fe0ef          	jal	8000459e <ilock>
  if(ip->type == T_DIR){
    800060fc:	04449703          	lh	a4,68(s1)
    80006100:	4785                	li	a5,1
    80006102:	06f70663          	beq	a4,a5,8000616e <sys_link+0xb8>
    80006106:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80006108:	04a4d783          	lhu	a5,74(s1)
    8000610c:	2785                	addiw	a5,a5,1
    8000610e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006112:	8526                	mv	a0,s1
    80006114:	bd6fe0ef          	jal	800044ea <iupdate>
  iunlock(ip);
    80006118:	8526                	mv	a0,s1
    8000611a:	d32fe0ef          	jal	8000464c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000611e:	fd040593          	addi	a1,s0,-48
    80006122:	f5040513          	addi	a0,s0,-176
    80006126:	ca9fe0ef          	jal	80004dce <nameiparent>
    8000612a:	892a                	mv	s2,a0
    8000612c:	cd21                	beqz	a0,80006184 <sys_link+0xce>
  ilock(dp);
    8000612e:	c70fe0ef          	jal	8000459e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006132:	00092703          	lw	a4,0(s2)
    80006136:	409c                	lw	a5,0(s1)
    80006138:	04f71363          	bne	a4,a5,8000617e <sys_link+0xc8>
    8000613c:	40d0                	lw	a2,4(s1)
    8000613e:	fd040593          	addi	a1,s0,-48
    80006142:	854a                	mv	a0,s2
    80006144:	bd7fe0ef          	jal	80004d1a <dirlink>
    80006148:	02054b63          	bltz	a0,8000617e <sys_link+0xc8>
  iunlockput(dp);
    8000614c:	854a                	mv	a0,s2
    8000614e:	e5afe0ef          	jal	800047a8 <iunlockput>
  iput(ip);
    80006152:	8526                	mv	a0,s1
    80006154:	dccfe0ef          	jal	80004720 <iput>
  end_op();
    80006158:	e9bfe0ef          	jal	80004ff2 <end_op>
  return 0;
    8000615c:	4781                	li	a5,0
    8000615e:	64f2                	ld	s1,280(sp)
    80006160:	6952                	ld	s2,272(sp)
    80006162:	a0a1                	j	800061aa <sys_link+0xf4>
    end_op();
    80006164:	e8ffe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006168:	57fd                	li	a5,-1
    8000616a:	64f2                	ld	s1,280(sp)
    8000616c:	a83d                	j	800061aa <sys_link+0xf4>
    iunlockput(ip);
    8000616e:	8526                	mv	a0,s1
    80006170:	e38fe0ef          	jal	800047a8 <iunlockput>
    end_op();
    80006174:	e7ffe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006178:	57fd                	li	a5,-1
    8000617a:	64f2                	ld	s1,280(sp)
    8000617c:	a03d                	j	800061aa <sys_link+0xf4>
    iunlockput(dp);
    8000617e:	854a                	mv	a0,s2
    80006180:	e28fe0ef          	jal	800047a8 <iunlockput>
  ilock(ip);
    80006184:	8526                	mv	a0,s1
    80006186:	c18fe0ef          	jal	8000459e <ilock>
  ip->nlink--;
    8000618a:	04a4d783          	lhu	a5,74(s1)
    8000618e:	37fd                	addiw	a5,a5,-1
    80006190:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006194:	8526                	mv	a0,s1
    80006196:	b54fe0ef          	jal	800044ea <iupdate>
  iunlockput(ip);
    8000619a:	8526                	mv	a0,s1
    8000619c:	e0cfe0ef          	jal	800047a8 <iunlockput>
  end_op();
    800061a0:	e53fe0ef          	jal	80004ff2 <end_op>
  return -1;
    800061a4:	57fd                	li	a5,-1
    800061a6:	64f2                	ld	s1,280(sp)
    800061a8:	6952                	ld	s2,272(sp)
}
    800061aa:	853e                	mv	a0,a5
    800061ac:	70b2                	ld	ra,296(sp)
    800061ae:	7412                	ld	s0,288(sp)
    800061b0:	6155                	addi	sp,sp,304
    800061b2:	8082                	ret

00000000800061b4 <sys_unlink>:
{
    800061b4:	7151                	addi	sp,sp,-240
    800061b6:	f586                	sd	ra,232(sp)
    800061b8:	f1a2                	sd	s0,224(sp)
    800061ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800061bc:	08000613          	li	a2,128
    800061c0:	f3040593          	addi	a1,s0,-208
    800061c4:	4501                	li	a0,0
    800061c6:	f1efd0ef          	jal	800038e4 <argstr>
    800061ca:	16054063          	bltz	a0,8000632a <sys_unlink+0x176>
    800061ce:	eda6                	sd	s1,216(sp)
  begin_op();
    800061d0:	db9fe0ef          	jal	80004f88 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061d4:	fb040593          	addi	a1,s0,-80
    800061d8:	f3040513          	addi	a0,s0,-208
    800061dc:	bf3fe0ef          	jal	80004dce <nameiparent>
    800061e0:	84aa                	mv	s1,a0
    800061e2:	c945                	beqz	a0,80006292 <sys_unlink+0xde>
  ilock(dp);
    800061e4:	bbafe0ef          	jal	8000459e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061e8:	00002597          	auipc	a1,0x2
    800061ec:	7b858593          	addi	a1,a1,1976 # 800089a0 <etext+0x9a0>
    800061f0:	fb040513          	addi	a0,s0,-80
    800061f4:	945fe0ef          	jal	80004b38 <namecmp>
    800061f8:	10050e63          	beqz	a0,80006314 <sys_unlink+0x160>
    800061fc:	00002597          	auipc	a1,0x2
    80006200:	7ac58593          	addi	a1,a1,1964 # 800089a8 <etext+0x9a8>
    80006204:	fb040513          	addi	a0,s0,-80
    80006208:	931fe0ef          	jal	80004b38 <namecmp>
    8000620c:	10050463          	beqz	a0,80006314 <sys_unlink+0x160>
    80006210:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006212:	f2c40613          	addi	a2,s0,-212
    80006216:	fb040593          	addi	a1,s0,-80
    8000621a:	8526                	mv	a0,s1
    8000621c:	933fe0ef          	jal	80004b4e <dirlookup>
    80006220:	892a                	mv	s2,a0
    80006222:	0e050863          	beqz	a0,80006312 <sys_unlink+0x15e>
  ilock(ip);
    80006226:	b78fe0ef          	jal	8000459e <ilock>
  if(ip->nlink < 1)
    8000622a:	04a91783          	lh	a5,74(s2)
    8000622e:	06f05763          	blez	a5,8000629c <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006232:	04491703          	lh	a4,68(s2)
    80006236:	4785                	li	a5,1
    80006238:	06f70963          	beq	a4,a5,800062aa <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    8000623c:	4641                	li	a2,16
    8000623e:	4581                	li	a1,0
    80006240:	fc040513          	addi	a0,s0,-64
    80006244:	a6dfa0ef          	jal	80000cb0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006248:	4741                	li	a4,16
    8000624a:	f2c42683          	lw	a3,-212(s0)
    8000624e:	fc040613          	addi	a2,s0,-64
    80006252:	4581                	li	a1,0
    80006254:	8526                	mv	a0,s1
    80006256:	fd4fe0ef          	jal	80004a2a <writei>
    8000625a:	47c1                	li	a5,16
    8000625c:	08f51b63          	bne	a0,a5,800062f2 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80006260:	04491703          	lh	a4,68(s2)
    80006264:	4785                	li	a5,1
    80006266:	08f70d63          	beq	a4,a5,80006300 <sys_unlink+0x14c>
  iunlockput(dp);
    8000626a:	8526                	mv	a0,s1
    8000626c:	d3cfe0ef          	jal	800047a8 <iunlockput>
  ip->nlink--;
    80006270:	04a95783          	lhu	a5,74(s2)
    80006274:	37fd                	addiw	a5,a5,-1
    80006276:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000627a:	854a                	mv	a0,s2
    8000627c:	a6efe0ef          	jal	800044ea <iupdate>
  iunlockput(ip);
    80006280:	854a                	mv	a0,s2
    80006282:	d26fe0ef          	jal	800047a8 <iunlockput>
  end_op();
    80006286:	d6dfe0ef          	jal	80004ff2 <end_op>
  return 0;
    8000628a:	4501                	li	a0,0
    8000628c:	64ee                	ld	s1,216(sp)
    8000628e:	694e                	ld	s2,208(sp)
    80006290:	a849                	j	80006322 <sys_unlink+0x16e>
    end_op();
    80006292:	d61fe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006296:	557d                	li	a0,-1
    80006298:	64ee                	ld	s1,216(sp)
    8000629a:	a061                	j	80006322 <sys_unlink+0x16e>
    8000629c:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    8000629e:	00002517          	auipc	a0,0x2
    800062a2:	71250513          	addi	a0,a0,1810 # 800089b0 <etext+0x9b0>
    800062a6:	d3afa0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062aa:	04c92703          	lw	a4,76(s2)
    800062ae:	02000793          	li	a5,32
    800062b2:	f8e7f5e3          	bgeu	a5,a4,8000623c <sys_unlink+0x88>
    800062b6:	e5ce                	sd	s3,200(sp)
    800062b8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062bc:	4741                	li	a4,16
    800062be:	86ce                	mv	a3,s3
    800062c0:	f1840613          	addi	a2,s0,-232
    800062c4:	4581                	li	a1,0
    800062c6:	854a                	mv	a0,s2
    800062c8:	e66fe0ef          	jal	8000492e <readi>
    800062cc:	47c1                	li	a5,16
    800062ce:	00f51c63          	bne	a0,a5,800062e6 <sys_unlink+0x132>
    if(de.inum != 0)
    800062d2:	f1845783          	lhu	a5,-232(s0)
    800062d6:	efa1                	bnez	a5,8000632e <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062d8:	29c1                	addiw	s3,s3,16
    800062da:	04c92783          	lw	a5,76(s2)
    800062de:	fcf9efe3          	bltu	s3,a5,800062bc <sys_unlink+0x108>
    800062e2:	69ae                	ld	s3,200(sp)
    800062e4:	bfa1                	j	8000623c <sys_unlink+0x88>
      panic("isdirempty: readi");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	6e250513          	addi	a0,a0,1762 # 800089c8 <etext+0x9c8>
    800062ee:	cf2fa0ef          	jal	800007e0 <panic>
    800062f2:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    800062f4:	00002517          	auipc	a0,0x2
    800062f8:	6ec50513          	addi	a0,a0,1772 # 800089e0 <etext+0x9e0>
    800062fc:	ce4fa0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80006300:	04a4d783          	lhu	a5,74(s1)
    80006304:	37fd                	addiw	a5,a5,-1
    80006306:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000630a:	8526                	mv	a0,s1
    8000630c:	9defe0ef          	jal	800044ea <iupdate>
    80006310:	bfa9                	j	8000626a <sys_unlink+0xb6>
    80006312:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80006314:	8526                	mv	a0,s1
    80006316:	c92fe0ef          	jal	800047a8 <iunlockput>
  end_op();
    8000631a:	cd9fe0ef          	jal	80004ff2 <end_op>
  return -1;
    8000631e:	557d                	li	a0,-1
    80006320:	64ee                	ld	s1,216(sp)
}
    80006322:	70ae                	ld	ra,232(sp)
    80006324:	740e                	ld	s0,224(sp)
    80006326:	616d                	addi	sp,sp,240
    80006328:	8082                	ret
    return -1;
    8000632a:	557d                	li	a0,-1
    8000632c:	bfdd                	j	80006322 <sys_unlink+0x16e>
    iunlockput(ip);
    8000632e:	854a                	mv	a0,s2
    80006330:	c78fe0ef          	jal	800047a8 <iunlockput>
    goto bad;
    80006334:	694e                	ld	s2,208(sp)
    80006336:	69ae                	ld	s3,200(sp)
    80006338:	bff1                	j	80006314 <sys_unlink+0x160>

000000008000633a <sys_open>:

uint64
sys_open(void)
{
    8000633a:	7131                	addi	sp,sp,-192
    8000633c:	fd06                	sd	ra,184(sp)
    8000633e:	f922                	sd	s0,176(sp)
    80006340:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006342:	f4c40593          	addi	a1,s0,-180
    80006346:	4505                	li	a0,1
    80006348:	d64fd0ef          	jal	800038ac <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000634c:	08000613          	li	a2,128
    80006350:	f5040593          	addi	a1,s0,-176
    80006354:	4501                	li	a0,0
    80006356:	d8efd0ef          	jal	800038e4 <argstr>
    8000635a:	87aa                	mv	a5,a0
    return -1;
    8000635c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000635e:	0a07c263          	bltz	a5,80006402 <sys_open+0xc8>
    80006362:	f526                	sd	s1,168(sp)

  begin_op();
    80006364:	c25fe0ef          	jal	80004f88 <begin_op>

  if(omode & O_CREATE){
    80006368:	f4c42783          	lw	a5,-180(s0)
    8000636c:	2007f793          	andi	a5,a5,512
    80006370:	c3d5                	beqz	a5,80006414 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80006372:	4681                	li	a3,0
    80006374:	4601                	li	a2,0
    80006376:	4589                	li	a1,2
    80006378:	f5040513          	addi	a0,s0,-176
    8000637c:	a97ff0ef          	jal	80005e12 <create>
    80006380:	84aa                	mv	s1,a0
    if(ip == 0){
    80006382:	c541                	beqz	a0,8000640a <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006384:	04449703          	lh	a4,68(s1)
    80006388:	478d                	li	a5,3
    8000638a:	00f71763          	bne	a4,a5,80006398 <sys_open+0x5e>
    8000638e:	0464d703          	lhu	a4,70(s1)
    80006392:	47a5                	li	a5,9
    80006394:	0ae7ed63          	bltu	a5,a4,8000644e <sys_open+0x114>
    80006398:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000639a:	f57fe0ef          	jal	800052f0 <filealloc>
    8000639e:	892a                	mv	s2,a0
    800063a0:	c179                	beqz	a0,80006466 <sys_open+0x12c>
    800063a2:	ed4e                	sd	s3,152(sp)
    800063a4:	a31ff0ef          	jal	80005dd4 <fdalloc>
    800063a8:	89aa                	mv	s3,a0
    800063aa:	0a054a63          	bltz	a0,8000645e <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063ae:	04449703          	lh	a4,68(s1)
    800063b2:	478d                	li	a5,3
    800063b4:	0cf70263          	beq	a4,a5,80006478 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063b8:	4789                	li	a5,2
    800063ba:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800063be:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800063c2:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800063c6:	f4c42783          	lw	a5,-180(s0)
    800063ca:	0017c713          	xori	a4,a5,1
    800063ce:	8b05                	andi	a4,a4,1
    800063d0:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063d4:	0037f713          	andi	a4,a5,3
    800063d8:	00e03733          	snez	a4,a4
    800063dc:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063e0:	4007f793          	andi	a5,a5,1024
    800063e4:	c791                	beqz	a5,800063f0 <sys_open+0xb6>
    800063e6:	04449703          	lh	a4,68(s1)
    800063ea:	4789                	li	a5,2
    800063ec:	08f70d63          	beq	a4,a5,80006486 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    800063f0:	8526                	mv	a0,s1
    800063f2:	a5afe0ef          	jal	8000464c <iunlock>
  end_op();
    800063f6:	bfdfe0ef          	jal	80004ff2 <end_op>

  return fd;
    800063fa:	854e                	mv	a0,s3
    800063fc:	74aa                	ld	s1,168(sp)
    800063fe:	790a                	ld	s2,160(sp)
    80006400:	69ea                	ld	s3,152(sp)
}
    80006402:	70ea                	ld	ra,184(sp)
    80006404:	744a                	ld	s0,176(sp)
    80006406:	6129                	addi	sp,sp,192
    80006408:	8082                	ret
      end_op();
    8000640a:	be9fe0ef          	jal	80004ff2 <end_op>
      return -1;
    8000640e:	557d                	li	a0,-1
    80006410:	74aa                	ld	s1,168(sp)
    80006412:	bfc5                	j	80006402 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80006414:	f5040513          	addi	a0,s0,-176
    80006418:	99dfe0ef          	jal	80004db4 <namei>
    8000641c:	84aa                	mv	s1,a0
    8000641e:	c11d                	beqz	a0,80006444 <sys_open+0x10a>
    ilock(ip);
    80006420:	97efe0ef          	jal	8000459e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006424:	04449703          	lh	a4,68(s1)
    80006428:	4785                	li	a5,1
    8000642a:	f4f71de3          	bne	a4,a5,80006384 <sys_open+0x4a>
    8000642e:	f4c42783          	lw	a5,-180(s0)
    80006432:	d3bd                	beqz	a5,80006398 <sys_open+0x5e>
      iunlockput(ip);
    80006434:	8526                	mv	a0,s1
    80006436:	b72fe0ef          	jal	800047a8 <iunlockput>
      end_op();
    8000643a:	bb9fe0ef          	jal	80004ff2 <end_op>
      return -1;
    8000643e:	557d                	li	a0,-1
    80006440:	74aa                	ld	s1,168(sp)
    80006442:	b7c1                	j	80006402 <sys_open+0xc8>
      end_op();
    80006444:	baffe0ef          	jal	80004ff2 <end_op>
      return -1;
    80006448:	557d                	li	a0,-1
    8000644a:	74aa                	ld	s1,168(sp)
    8000644c:	bf5d                	j	80006402 <sys_open+0xc8>
    iunlockput(ip);
    8000644e:	8526                	mv	a0,s1
    80006450:	b58fe0ef          	jal	800047a8 <iunlockput>
    end_op();
    80006454:	b9ffe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006458:	557d                	li	a0,-1
    8000645a:	74aa                	ld	s1,168(sp)
    8000645c:	b75d                	j	80006402 <sys_open+0xc8>
      fileclose(f);
    8000645e:	854a                	mv	a0,s2
    80006460:	f35fe0ef          	jal	80005394 <fileclose>
    80006464:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80006466:	8526                	mv	a0,s1
    80006468:	b40fe0ef          	jal	800047a8 <iunlockput>
    end_op();
    8000646c:	b87fe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006470:	557d                	li	a0,-1
    80006472:	74aa                	ld	s1,168(sp)
    80006474:	790a                	ld	s2,160(sp)
    80006476:	b771                	j	80006402 <sys_open+0xc8>
    f->type = FD_DEVICE;
    80006478:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000647c:	04649783          	lh	a5,70(s1)
    80006480:	02f91223          	sh	a5,36(s2)
    80006484:	bf3d                	j	800063c2 <sys_open+0x88>
    itrunc(ip);
    80006486:	8526                	mv	a0,s1
    80006488:	a04fe0ef          	jal	8000468c <itrunc>
    8000648c:	b795                	j	800063f0 <sys_open+0xb6>

000000008000648e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000648e:	7175                	addi	sp,sp,-144
    80006490:	e506                	sd	ra,136(sp)
    80006492:	e122                	sd	s0,128(sp)
    80006494:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006496:	af3fe0ef          	jal	80004f88 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000649a:	08000613          	li	a2,128
    8000649e:	f7040593          	addi	a1,s0,-144
    800064a2:	4501                	li	a0,0
    800064a4:	c40fd0ef          	jal	800038e4 <argstr>
    800064a8:	02054363          	bltz	a0,800064ce <sys_mkdir+0x40>
    800064ac:	4681                	li	a3,0
    800064ae:	4601                	li	a2,0
    800064b0:	4585                	li	a1,1
    800064b2:	f7040513          	addi	a0,s0,-144
    800064b6:	95dff0ef          	jal	80005e12 <create>
    800064ba:	c911                	beqz	a0,800064ce <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064bc:	aecfe0ef          	jal	800047a8 <iunlockput>
  end_op();
    800064c0:	b33fe0ef          	jal	80004ff2 <end_op>
  return 0;
    800064c4:	4501                	li	a0,0
}
    800064c6:	60aa                	ld	ra,136(sp)
    800064c8:	640a                	ld	s0,128(sp)
    800064ca:	6149                	addi	sp,sp,144
    800064cc:	8082                	ret
    end_op();
    800064ce:	b25fe0ef          	jal	80004ff2 <end_op>
    return -1;
    800064d2:	557d                	li	a0,-1
    800064d4:	bfcd                	j	800064c6 <sys_mkdir+0x38>

00000000800064d6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800064d6:	7135                	addi	sp,sp,-160
    800064d8:	ed06                	sd	ra,152(sp)
    800064da:	e922                	sd	s0,144(sp)
    800064dc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064de:	aabfe0ef          	jal	80004f88 <begin_op>
  argint(1, &major);
    800064e2:	f6c40593          	addi	a1,s0,-148
    800064e6:	4505                	li	a0,1
    800064e8:	bc4fd0ef          	jal	800038ac <argint>
  argint(2, &minor);
    800064ec:	f6840593          	addi	a1,s0,-152
    800064f0:	4509                	li	a0,2
    800064f2:	bbafd0ef          	jal	800038ac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064f6:	08000613          	li	a2,128
    800064fa:	f7040593          	addi	a1,s0,-144
    800064fe:	4501                	li	a0,0
    80006500:	be4fd0ef          	jal	800038e4 <argstr>
    80006504:	02054563          	bltz	a0,8000652e <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006508:	f6841683          	lh	a3,-152(s0)
    8000650c:	f6c41603          	lh	a2,-148(s0)
    80006510:	458d                	li	a1,3
    80006512:	f7040513          	addi	a0,s0,-144
    80006516:	8fdff0ef          	jal	80005e12 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000651a:	c911                	beqz	a0,8000652e <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000651c:	a8cfe0ef          	jal	800047a8 <iunlockput>
  end_op();
    80006520:	ad3fe0ef          	jal	80004ff2 <end_op>
  return 0;
    80006524:	4501                	li	a0,0
}
    80006526:	60ea                	ld	ra,152(sp)
    80006528:	644a                	ld	s0,144(sp)
    8000652a:	610d                	addi	sp,sp,160
    8000652c:	8082                	ret
    end_op();
    8000652e:	ac5fe0ef          	jal	80004ff2 <end_op>
    return -1;
    80006532:	557d                	li	a0,-1
    80006534:	bfcd                	j	80006526 <sys_mknod+0x50>

0000000080006536 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006536:	7135                	addi	sp,sp,-160
    80006538:	ed06                	sd	ra,152(sp)
    8000653a:	e922                	sd	s0,144(sp)
    8000653c:	e14a                	sd	s2,128(sp)
    8000653e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006540:	ee9fb0ef          	jal	80002428 <myproc>
    80006544:	892a                	mv	s2,a0
  
  begin_op();
    80006546:	a43fe0ef          	jal	80004f88 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000654a:	08000613          	li	a2,128
    8000654e:	f6040593          	addi	a1,s0,-160
    80006552:	4501                	li	a0,0
    80006554:	b90fd0ef          	jal	800038e4 <argstr>
    80006558:	04054363          	bltz	a0,8000659e <sys_chdir+0x68>
    8000655c:	e526                	sd	s1,136(sp)
    8000655e:	f6040513          	addi	a0,s0,-160
    80006562:	853fe0ef          	jal	80004db4 <namei>
    80006566:	84aa                	mv	s1,a0
    80006568:	c915                	beqz	a0,8000659c <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000656a:	834fe0ef          	jal	8000459e <ilock>
  if(ip->type != T_DIR){
    8000656e:	04449703          	lh	a4,68(s1)
    80006572:	4785                	li	a5,1
    80006574:	02f71963          	bne	a4,a5,800065a6 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006578:	8526                	mv	a0,s1
    8000657a:	8d2fe0ef          	jal	8000464c <iunlock>
  iput(p->cwd);
    8000657e:	15093503          	ld	a0,336(s2)
    80006582:	99efe0ef          	jal	80004720 <iput>
  end_op();
    80006586:	a6dfe0ef          	jal	80004ff2 <end_op>
  p->cwd = ip;
    8000658a:	14993823          	sd	s1,336(s2)
  return 0;
    8000658e:	4501                	li	a0,0
    80006590:	64aa                	ld	s1,136(sp)
}
    80006592:	60ea                	ld	ra,152(sp)
    80006594:	644a                	ld	s0,144(sp)
    80006596:	690a                	ld	s2,128(sp)
    80006598:	610d                	addi	sp,sp,160
    8000659a:	8082                	ret
    8000659c:	64aa                	ld	s1,136(sp)
    end_op();
    8000659e:	a55fe0ef          	jal	80004ff2 <end_op>
    return -1;
    800065a2:	557d                	li	a0,-1
    800065a4:	b7fd                	j	80006592 <sys_chdir+0x5c>
    iunlockput(ip);
    800065a6:	8526                	mv	a0,s1
    800065a8:	a00fe0ef          	jal	800047a8 <iunlockput>
    end_op();
    800065ac:	a47fe0ef          	jal	80004ff2 <end_op>
    return -1;
    800065b0:	557d                	li	a0,-1
    800065b2:	64aa                	ld	s1,136(sp)
    800065b4:	bff9                	j	80006592 <sys_chdir+0x5c>

00000000800065b6 <sys_exec>:

uint64
sys_exec(void)
{
    800065b6:	7121                	addi	sp,sp,-448
    800065b8:	ff06                	sd	ra,440(sp)
    800065ba:	fb22                	sd	s0,432(sp)
    800065bc:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800065be:	e4840593          	addi	a1,s0,-440
    800065c2:	4505                	li	a0,1
    800065c4:	b04fd0ef          	jal	800038c8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800065c8:	08000613          	li	a2,128
    800065cc:	f5040593          	addi	a1,s0,-176
    800065d0:	4501                	li	a0,0
    800065d2:	b12fd0ef          	jal	800038e4 <argstr>
    800065d6:	87aa                	mv	a5,a0
    return -1;
    800065d8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800065da:	0c07c463          	bltz	a5,800066a2 <sys_exec+0xec>
    800065de:	f726                	sd	s1,424(sp)
    800065e0:	f34a                	sd	s2,416(sp)
    800065e2:	ef4e                	sd	s3,408(sp)
    800065e4:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800065e6:	10000613          	li	a2,256
    800065ea:	4581                	li	a1,0
    800065ec:	e5040513          	addi	a0,s0,-432
    800065f0:	ec0fa0ef          	jal	80000cb0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800065f4:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800065f8:	89a6                	mv	s3,s1
    800065fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800065fc:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006600:	00391513          	slli	a0,s2,0x3
    80006604:	e4040593          	addi	a1,s0,-448
    80006608:	e4843783          	ld	a5,-440(s0)
    8000660c:	953e                	add	a0,a0,a5
    8000660e:	a14fd0ef          	jal	80003822 <fetchaddr>
    80006612:	02054663          	bltz	a0,8000663e <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80006616:	e4043783          	ld	a5,-448(s0)
    8000661a:	c3a9                	beqz	a5,8000665c <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000661c:	ce2fa0ef          	jal	80000afe <kalloc>
    80006620:	85aa                	mv	a1,a0
    80006622:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006626:	cd01                	beqz	a0,8000663e <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006628:	6605                	lui	a2,0x1
    8000662a:	e4043503          	ld	a0,-448(s0)
    8000662e:	a3efd0ef          	jal	8000386c <fetchstr>
    80006632:	00054663          	bltz	a0,8000663e <sys_exec+0x88>
    if(i >= NELEM(argv)){
    80006636:	0905                	addi	s2,s2,1
    80006638:	09a1                	addi	s3,s3,8
    8000663a:	fd4913e3          	bne	s2,s4,80006600 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000663e:	f5040913          	addi	s2,s0,-176
    80006642:	6088                	ld	a0,0(s1)
    80006644:	c931                	beqz	a0,80006698 <sys_exec+0xe2>
    kfree(argv[i]);
    80006646:	bd6fa0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000664a:	04a1                	addi	s1,s1,8
    8000664c:	ff249be3          	bne	s1,s2,80006642 <sys_exec+0x8c>
  return -1;
    80006650:	557d                	li	a0,-1
    80006652:	74ba                	ld	s1,424(sp)
    80006654:	791a                	ld	s2,416(sp)
    80006656:	69fa                	ld	s3,408(sp)
    80006658:	6a5a                	ld	s4,400(sp)
    8000665a:	a0a1                	j	800066a2 <sys_exec+0xec>
      argv[i] = 0;
    8000665c:	0009079b          	sext.w	a5,s2
    80006660:	078e                	slli	a5,a5,0x3
    80006662:	fd078793          	addi	a5,a5,-48
    80006666:	97a2                	add	a5,a5,s0
    80006668:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    8000666c:	e5040593          	addi	a1,s0,-432
    80006670:	f5040513          	addi	a0,s0,-176
    80006674:	b1eff0ef          	jal	80005992 <kexec>
    80006678:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000667a:	f5040993          	addi	s3,s0,-176
    8000667e:	6088                	ld	a0,0(s1)
    80006680:	c511                	beqz	a0,8000668c <sys_exec+0xd6>
    kfree(argv[i]);
    80006682:	b9afa0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006686:	04a1                	addi	s1,s1,8
    80006688:	ff349be3          	bne	s1,s3,8000667e <sys_exec+0xc8>
  return ret;
    8000668c:	854a                	mv	a0,s2
    8000668e:	74ba                	ld	s1,424(sp)
    80006690:	791a                	ld	s2,416(sp)
    80006692:	69fa                	ld	s3,408(sp)
    80006694:	6a5a                	ld	s4,400(sp)
    80006696:	a031                	j	800066a2 <sys_exec+0xec>
  return -1;
    80006698:	557d                	li	a0,-1
    8000669a:	74ba                	ld	s1,424(sp)
    8000669c:	791a                	ld	s2,416(sp)
    8000669e:	69fa                	ld	s3,408(sp)
    800066a0:	6a5a                	ld	s4,400(sp)
}
    800066a2:	70fa                	ld	ra,440(sp)
    800066a4:	745a                	ld	s0,432(sp)
    800066a6:	6139                	addi	sp,sp,448
    800066a8:	8082                	ret

00000000800066aa <sys_pipe>:

uint64
sys_pipe(void)
{
    800066aa:	7139                	addi	sp,sp,-64
    800066ac:	fc06                	sd	ra,56(sp)
    800066ae:	f822                	sd	s0,48(sp)
    800066b0:	f426                	sd	s1,40(sp)
    800066b2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800066b4:	d75fb0ef          	jal	80002428 <myproc>
    800066b8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800066ba:	fd840593          	addi	a1,s0,-40
    800066be:	4501                	li	a0,0
    800066c0:	a08fd0ef          	jal	800038c8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800066c4:	fc840593          	addi	a1,s0,-56
    800066c8:	fd040513          	addi	a0,s0,-48
    800066cc:	fd3fe0ef          	jal	8000569e <pipealloc>
    return -1;
    800066d0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800066d2:	0a054463          	bltz	a0,8000677a <sys_pipe+0xd0>
  fd0 = -1;
    800066d6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800066da:	fd043503          	ld	a0,-48(s0)
    800066de:	ef6ff0ef          	jal	80005dd4 <fdalloc>
    800066e2:	fca42223          	sw	a0,-60(s0)
    800066e6:	08054163          	bltz	a0,80006768 <sys_pipe+0xbe>
    800066ea:	fc843503          	ld	a0,-56(s0)
    800066ee:	ee6ff0ef          	jal	80005dd4 <fdalloc>
    800066f2:	fca42023          	sw	a0,-64(s0)
    800066f6:	06054063          	bltz	a0,80006756 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066fa:	4691                	li	a3,4
    800066fc:	fc440613          	addi	a2,s0,-60
    80006700:	fd843583          	ld	a1,-40(s0)
    80006704:	68a8                	ld	a0,80(s1)
    80006706:	915fb0ef          	jal	8000201a <copyout>
    8000670a:	00054e63          	bltz	a0,80006726 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000670e:	4691                	li	a3,4
    80006710:	fc040613          	addi	a2,s0,-64
    80006714:	fd843583          	ld	a1,-40(s0)
    80006718:	0591                	addi	a1,a1,4
    8000671a:	68a8                	ld	a0,80(s1)
    8000671c:	8fffb0ef          	jal	8000201a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006720:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006722:	04055c63          	bgez	a0,8000677a <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80006726:	fc442783          	lw	a5,-60(s0)
    8000672a:	07e9                	addi	a5,a5,26
    8000672c:	078e                	slli	a5,a5,0x3
    8000672e:	97a6                	add	a5,a5,s1
    80006730:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006734:	fc042783          	lw	a5,-64(s0)
    80006738:	07e9                	addi	a5,a5,26
    8000673a:	078e                	slli	a5,a5,0x3
    8000673c:	94be                	add	s1,s1,a5
    8000673e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006742:	fd043503          	ld	a0,-48(s0)
    80006746:	c4ffe0ef          	jal	80005394 <fileclose>
    fileclose(wf);
    8000674a:	fc843503          	ld	a0,-56(s0)
    8000674e:	c47fe0ef          	jal	80005394 <fileclose>
    return -1;
    80006752:	57fd                	li	a5,-1
    80006754:	a01d                	j	8000677a <sys_pipe+0xd0>
    if(fd0 >= 0)
    80006756:	fc442783          	lw	a5,-60(s0)
    8000675a:	0007c763          	bltz	a5,80006768 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000675e:	07e9                	addi	a5,a5,26
    80006760:	078e                	slli	a5,a5,0x3
    80006762:	97a6                	add	a5,a5,s1
    80006764:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006768:	fd043503          	ld	a0,-48(s0)
    8000676c:	c29fe0ef          	jal	80005394 <fileclose>
    fileclose(wf);
    80006770:	fc843503          	ld	a0,-56(s0)
    80006774:	c21fe0ef          	jal	80005394 <fileclose>
    return -1;
    80006778:	57fd                	li	a5,-1
}
    8000677a:	853e                	mv	a0,a5
    8000677c:	70e2                	ld	ra,56(sp)
    8000677e:	7442                	ld	s0,48(sp)
    80006780:	74a2                	ld	s1,40(sp)
    80006782:	6121                	addi	sp,sp,64
    80006784:	8082                	ret
	...

0000000080006790 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80006790:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80006792:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80006794:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80006796:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80006798:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000679a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000679c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000679e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800067a0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800067a2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800067a4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800067a6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800067a8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800067aa:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800067ac:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800067ae:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800067b0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800067b2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800067b4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800067b6:	f7dfc0ef          	jal	80003732 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800067ba:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800067bc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800067be:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800067c0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800067c2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800067c4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800067c6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800067c8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800067ca:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800067cc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800067ce:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800067d0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800067d2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800067d4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800067d6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800067d8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800067da:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800067dc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800067de:	10200073          	sret
	...

00000000800067ee <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800067ee:	1141                	addi	sp,sp,-16
    800067f0:	e422                	sd	s0,8(sp)
    800067f2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800067f4:	0c0007b7          	lui	a5,0xc000
    800067f8:	4705                	li	a4,1
    800067fa:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800067fc:	0c0007b7          	lui	a5,0xc000
    80006800:	c3d8                	sw	a4,4(a5)
}
    80006802:	6422                	ld	s0,8(sp)
    80006804:	0141                	addi	sp,sp,16
    80006806:	8082                	ret

0000000080006808 <plicinithart>:

void
plicinithart(void)
{
    80006808:	1141                	addi	sp,sp,-16
    8000680a:	e406                	sd	ra,8(sp)
    8000680c:	e022                	sd	s0,0(sp)
    8000680e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006810:	bedfb0ef          	jal	800023fc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006814:	0085171b          	slliw	a4,a0,0x8
    80006818:	0c0027b7          	lui	a5,0xc002
    8000681c:	97ba                	add	a5,a5,a4
    8000681e:	40200713          	li	a4,1026
    80006822:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006826:	00d5151b          	slliw	a0,a0,0xd
    8000682a:	0c2017b7          	lui	a5,0xc201
    8000682e:	97aa                	add	a5,a5,a0
    80006830:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006834:	60a2                	ld	ra,8(sp)
    80006836:	6402                	ld	s0,0(sp)
    80006838:	0141                	addi	sp,sp,16
    8000683a:	8082                	ret

000000008000683c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000683c:	1141                	addi	sp,sp,-16
    8000683e:	e406                	sd	ra,8(sp)
    80006840:	e022                	sd	s0,0(sp)
    80006842:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006844:	bb9fb0ef          	jal	800023fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006848:	00d5151b          	slliw	a0,a0,0xd
    8000684c:	0c2017b7          	lui	a5,0xc201
    80006850:	97aa                	add	a5,a5,a0
  return irq;
}
    80006852:	43c8                	lw	a0,4(a5)
    80006854:	60a2                	ld	ra,8(sp)
    80006856:	6402                	ld	s0,0(sp)
    80006858:	0141                	addi	sp,sp,16
    8000685a:	8082                	ret

000000008000685c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000685c:	1101                	addi	sp,sp,-32
    8000685e:	ec06                	sd	ra,24(sp)
    80006860:	e822                	sd	s0,16(sp)
    80006862:	e426                	sd	s1,8(sp)
    80006864:	1000                	addi	s0,sp,32
    80006866:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006868:	b95fb0ef          	jal	800023fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000686c:	00d5151b          	slliw	a0,a0,0xd
    80006870:	0c2017b7          	lui	a5,0xc201
    80006874:	97aa                	add	a5,a5,a0
    80006876:	c3c4                	sw	s1,4(a5)
}
    80006878:	60e2                	ld	ra,24(sp)
    8000687a:	6442                	ld	s0,16(sp)
    8000687c:	64a2                	ld	s1,8(sp)
    8000687e:	6105                	addi	sp,sp,32
    80006880:	8082                	ret

0000000080006882 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006882:	1141                	addi	sp,sp,-16
    80006884:	e406                	sd	ra,8(sp)
    80006886:	e022                	sd	s0,0(sp)
    80006888:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000688a:	479d                	li	a5,7
    8000688c:	04a7ca63          	blt	a5,a0,800068e0 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80006890:	001aa797          	auipc	a5,0x1aa
    80006894:	95878793          	addi	a5,a5,-1704 # 801b01e8 <disk>
    80006898:	97aa                	add	a5,a5,a0
    8000689a:	0187c783          	lbu	a5,24(a5)
    8000689e:	e7b9                	bnez	a5,800068ec <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068a0:	00451693          	slli	a3,a0,0x4
    800068a4:	001aa797          	auipc	a5,0x1aa
    800068a8:	94478793          	addi	a5,a5,-1724 # 801b01e8 <disk>
    800068ac:	6398                	ld	a4,0(a5)
    800068ae:	9736                	add	a4,a4,a3
    800068b0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800068b4:	6398                	ld	a4,0(a5)
    800068b6:	9736                	add	a4,a4,a3
    800068b8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800068bc:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800068c0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800068c4:	97aa                	add	a5,a5,a0
    800068c6:	4705                	li	a4,1
    800068c8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800068cc:	001aa517          	auipc	a0,0x1aa
    800068d0:	93450513          	addi	a0,a0,-1740 # 801b0200 <disk+0x18>
    800068d4:	e32fc0ef          	jal	80002f06 <wakeup>
}
    800068d8:	60a2                	ld	ra,8(sp)
    800068da:	6402                	ld	s0,0(sp)
    800068dc:	0141                	addi	sp,sp,16
    800068de:	8082                	ret
    panic("free_desc 1");
    800068e0:	00002517          	auipc	a0,0x2
    800068e4:	11050513          	addi	a0,a0,272 # 800089f0 <etext+0x9f0>
    800068e8:	ef9f90ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    800068ec:	00002517          	auipc	a0,0x2
    800068f0:	11450513          	addi	a0,a0,276 # 80008a00 <etext+0xa00>
    800068f4:	eedf90ef          	jal	800007e0 <panic>

00000000800068f8 <virtio_disk_init>:
{
    800068f8:	1101                	addi	sp,sp,-32
    800068fa:	ec06                	sd	ra,24(sp)
    800068fc:	e822                	sd	s0,16(sp)
    800068fe:	e426                	sd	s1,8(sp)
    80006900:	e04a                	sd	s2,0(sp)
    80006902:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006904:	00002597          	auipc	a1,0x2
    80006908:	10c58593          	addi	a1,a1,268 # 80008a10 <etext+0xa10>
    8000690c:	001aa517          	auipc	a0,0x1aa
    80006910:	a0450513          	addi	a0,a0,-1532 # 801b0310 <disk+0x128>
    80006914:	a3afa0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006918:	100017b7          	lui	a5,0x10001
    8000691c:	4398                	lw	a4,0(a5)
    8000691e:	2701                	sext.w	a4,a4
    80006920:	747277b7          	lui	a5,0x74727
    80006924:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006928:	18f71063          	bne	a4,a5,80006aa8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000692c:	100017b7          	lui	a5,0x10001
    80006930:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80006932:	439c                	lw	a5,0(a5)
    80006934:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006936:	4709                	li	a4,2
    80006938:	16e79863          	bne	a5,a4,80006aa8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000693c:	100017b7          	lui	a5,0x10001
    80006940:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80006942:	439c                	lw	a5,0(a5)
    80006944:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006946:	16e79163          	bne	a5,a4,80006aa8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000694a:	100017b7          	lui	a5,0x10001
    8000694e:	47d8                	lw	a4,12(a5)
    80006950:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006952:	554d47b7          	lui	a5,0x554d4
    80006956:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000695a:	14f71763          	bne	a4,a5,80006aa8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000695e:	100017b7          	lui	a5,0x10001
    80006962:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006966:	4705                	li	a4,1
    80006968:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000696a:	470d                	li	a4,3
    8000696c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000696e:	10001737          	lui	a4,0x10001
    80006972:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006974:	c7ffe737          	lui	a4,0xc7ffe
    80006978:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47e4e437>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000697c:	8ef9                	and	a3,a3,a4
    8000697e:	10001737          	lui	a4,0x10001
    80006982:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006984:	472d                	li	a4,11
    80006986:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006988:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000698c:	439c                	lw	a5,0(a5)
    8000698e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006992:	8ba1                	andi	a5,a5,8
    80006994:	12078063          	beqz	a5,80006ab4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006998:	100017b7          	lui	a5,0x10001
    8000699c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800069a0:	100017b7          	lui	a5,0x10001
    800069a4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800069a8:	439c                	lw	a5,0(a5)
    800069aa:	2781                	sext.w	a5,a5
    800069ac:	10079a63          	bnez	a5,80006ac0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069b0:	100017b7          	lui	a5,0x10001
    800069b4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800069b8:	439c                	lw	a5,0(a5)
    800069ba:	2781                	sext.w	a5,a5
  if(max == 0)
    800069bc:	10078863          	beqz	a5,80006acc <virtio_disk_init+0x1d4>
  if(max < NUM)
    800069c0:	471d                	li	a4,7
    800069c2:	10f77b63          	bgeu	a4,a5,80006ad8 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800069c6:	938fa0ef          	jal	80000afe <kalloc>
    800069ca:	001aa497          	auipc	s1,0x1aa
    800069ce:	81e48493          	addi	s1,s1,-2018 # 801b01e8 <disk>
    800069d2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800069d4:	92afa0ef          	jal	80000afe <kalloc>
    800069d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800069da:	924fa0ef          	jal	80000afe <kalloc>
    800069de:	87aa                	mv	a5,a0
    800069e0:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800069e2:	6088                	ld	a0,0(s1)
    800069e4:	10050063          	beqz	a0,80006ae4 <virtio_disk_init+0x1ec>
    800069e8:	001aa717          	auipc	a4,0x1aa
    800069ec:	80873703          	ld	a4,-2040(a4) # 801b01f0 <disk+0x8>
    800069f0:	0e070a63          	beqz	a4,80006ae4 <virtio_disk_init+0x1ec>
    800069f4:	0e078863          	beqz	a5,80006ae4 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    800069f8:	6605                	lui	a2,0x1
    800069fa:	4581                	li	a1,0
    800069fc:	ab4fa0ef          	jal	80000cb0 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a00:	001a9497          	auipc	s1,0x1a9
    80006a04:	7e848493          	addi	s1,s1,2024 # 801b01e8 <disk>
    80006a08:	6605                	lui	a2,0x1
    80006a0a:	4581                	li	a1,0
    80006a0c:	6488                	ld	a0,8(s1)
    80006a0e:	aa2fa0ef          	jal	80000cb0 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a12:	6605                	lui	a2,0x1
    80006a14:	4581                	li	a1,0
    80006a16:	6888                	ld	a0,16(s1)
    80006a18:	a98fa0ef          	jal	80000cb0 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a1c:	100017b7          	lui	a5,0x10001
    80006a20:	4721                	li	a4,8
    80006a22:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006a24:	4098                	lw	a4,0(s1)
    80006a26:	100017b7          	lui	a5,0x10001
    80006a2a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006a2e:	40d8                	lw	a4,4(s1)
    80006a30:	100017b7          	lui	a5,0x10001
    80006a34:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006a38:	649c                	ld	a5,8(s1)
    80006a3a:	0007869b          	sext.w	a3,a5
    80006a3e:	10001737          	lui	a4,0x10001
    80006a42:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006a46:	9781                	srai	a5,a5,0x20
    80006a48:	10001737          	lui	a4,0x10001
    80006a4c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006a50:	689c                	ld	a5,16(s1)
    80006a52:	0007869b          	sext.w	a3,a5
    80006a56:	10001737          	lui	a4,0x10001
    80006a5a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006a5e:	9781                	srai	a5,a5,0x20
    80006a60:	10001737          	lui	a4,0x10001
    80006a64:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006a68:	10001737          	lui	a4,0x10001
    80006a6c:	4785                	li	a5,1
    80006a6e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006a70:	00f48c23          	sb	a5,24(s1)
    80006a74:	00f48ca3          	sb	a5,25(s1)
    80006a78:	00f48d23          	sb	a5,26(s1)
    80006a7c:	00f48da3          	sb	a5,27(s1)
    80006a80:	00f48e23          	sb	a5,28(s1)
    80006a84:	00f48ea3          	sb	a5,29(s1)
    80006a88:	00f48f23          	sb	a5,30(s1)
    80006a8c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006a90:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a94:	100017b7          	lui	a5,0x10001
    80006a98:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80006a9c:	60e2                	ld	ra,24(sp)
    80006a9e:	6442                	ld	s0,16(sp)
    80006aa0:	64a2                	ld	s1,8(sp)
    80006aa2:	6902                	ld	s2,0(sp)
    80006aa4:	6105                	addi	sp,sp,32
    80006aa6:	8082                	ret
    panic("could not find virtio disk");
    80006aa8:	00002517          	auipc	a0,0x2
    80006aac:	f7850513          	addi	a0,a0,-136 # 80008a20 <etext+0xa20>
    80006ab0:	d31f90ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ab4:	00002517          	auipc	a0,0x2
    80006ab8:	f8c50513          	addi	a0,a0,-116 # 80008a40 <etext+0xa40>
    80006abc:	d25f90ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80006ac0:	00002517          	auipc	a0,0x2
    80006ac4:	fa050513          	addi	a0,a0,-96 # 80008a60 <etext+0xa60>
    80006ac8:	d19f90ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80006acc:	00002517          	auipc	a0,0x2
    80006ad0:	fb450513          	addi	a0,a0,-76 # 80008a80 <etext+0xa80>
    80006ad4:	d0df90ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80006ad8:	00002517          	auipc	a0,0x2
    80006adc:	fc850513          	addi	a0,a0,-56 # 80008aa0 <etext+0xaa0>
    80006ae0:	d01f90ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80006ae4:	00002517          	auipc	a0,0x2
    80006ae8:	fdc50513          	addi	a0,a0,-36 # 80008ac0 <etext+0xac0>
    80006aec:	cf5f90ef          	jal	800007e0 <panic>

0000000080006af0 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006af0:	7159                	addi	sp,sp,-112
    80006af2:	f486                	sd	ra,104(sp)
    80006af4:	f0a2                	sd	s0,96(sp)
    80006af6:	eca6                	sd	s1,88(sp)
    80006af8:	e8ca                	sd	s2,80(sp)
    80006afa:	e4ce                	sd	s3,72(sp)
    80006afc:	e0d2                	sd	s4,64(sp)
    80006afe:	fc56                	sd	s5,56(sp)
    80006b00:	f85a                	sd	s6,48(sp)
    80006b02:	f45e                	sd	s7,40(sp)
    80006b04:	f062                	sd	s8,32(sp)
    80006b06:	ec66                	sd	s9,24(sp)
    80006b08:	1880                	addi	s0,sp,112
    80006b0a:	8a2a                	mv	s4,a0
    80006b0c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b0e:	00c52c83          	lw	s9,12(a0)
    80006b12:	001c9c9b          	slliw	s9,s9,0x1
    80006b16:	1c82                	slli	s9,s9,0x20
    80006b18:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b1c:	001a9517          	auipc	a0,0x1a9
    80006b20:	7f450513          	addi	a0,a0,2036 # 801b0310 <disk+0x128>
    80006b24:	8aafa0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80006b28:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b2a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006b2c:	001a9b17          	auipc	s6,0x1a9
    80006b30:	6bcb0b13          	addi	s6,s6,1724 # 801b01e8 <disk>
  for(int i = 0; i < 3; i++){
    80006b34:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b36:	001a9c17          	auipc	s8,0x1a9
    80006b3a:	7dac0c13          	addi	s8,s8,2010 # 801b0310 <disk+0x128>
    80006b3e:	a8b9                	j	80006b9c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80006b40:	00fb0733          	add	a4,s6,a5
    80006b44:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006b48:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006b4a:	0207c563          	bltz	a5,80006b74 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80006b4e:	2905                	addiw	s2,s2,1
    80006b50:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006b52:	05590963          	beq	s2,s5,80006ba4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80006b56:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006b58:	001a9717          	auipc	a4,0x1a9
    80006b5c:	69070713          	addi	a4,a4,1680 # 801b01e8 <disk>
    80006b60:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006b62:	01874683          	lbu	a3,24(a4)
    80006b66:	fee9                	bnez	a3,80006b40 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006b68:	2785                	addiw	a5,a5,1
    80006b6a:	0705                	addi	a4,a4,1
    80006b6c:	fe979be3          	bne	a5,s1,80006b62 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80006b70:	57fd                	li	a5,-1
    80006b72:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006b74:	01205d63          	blez	s2,80006b8e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80006b78:	f9042503          	lw	a0,-112(s0)
    80006b7c:	d07ff0ef          	jal	80006882 <free_desc>
      for(int j = 0; j < i; j++)
    80006b80:	4785                	li	a5,1
    80006b82:	0127d663          	bge	a5,s2,80006b8e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80006b86:	f9442503          	lw	a0,-108(s0)
    80006b8a:	cf9ff0ef          	jal	80006882 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b8e:	85e2                	mv	a1,s8
    80006b90:	001a9517          	auipc	a0,0x1a9
    80006b94:	67050513          	addi	a0,a0,1648 # 801b0200 <disk+0x18>
    80006b98:	b22fc0ef          	jal	80002eba <sleep>
  for(int i = 0; i < 3; i++){
    80006b9c:	f9040613          	addi	a2,s0,-112
    80006ba0:	894e                	mv	s2,s3
    80006ba2:	bf55                	j	80006b56 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ba4:	f9042503          	lw	a0,-112(s0)
    80006ba8:	00451693          	slli	a3,a0,0x4

  if(write)
    80006bac:	001a9797          	auipc	a5,0x1a9
    80006bb0:	63c78793          	addi	a5,a5,1596 # 801b01e8 <disk>
    80006bb4:	00a50713          	addi	a4,a0,10
    80006bb8:	0712                	slli	a4,a4,0x4
    80006bba:	973e                	add	a4,a4,a5
    80006bbc:	01703633          	snez	a2,s7
    80006bc0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006bc2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006bc6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bca:	6398                	ld	a4,0(a5)
    80006bcc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bce:	0a868613          	addi	a2,a3,168
    80006bd2:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bd4:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006bd6:	6390                	ld	a2,0(a5)
    80006bd8:	00d605b3          	add	a1,a2,a3
    80006bdc:	4741                	li	a4,16
    80006bde:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006be0:	4805                	li	a6,1
    80006be2:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80006be6:	f9442703          	lw	a4,-108(s0)
    80006bea:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006bee:	0712                	slli	a4,a4,0x4
    80006bf0:	963a                	add	a2,a2,a4
    80006bf2:	058a0593          	addi	a1,s4,88
    80006bf6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006bf8:	0007b883          	ld	a7,0(a5)
    80006bfc:	9746                	add	a4,a4,a7
    80006bfe:	40000613          	li	a2,1024
    80006c02:	c710                	sw	a2,8(a4)
  if(write)
    80006c04:	001bb613          	seqz	a2,s7
    80006c08:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c0c:	00166613          	ori	a2,a2,1
    80006c10:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006c14:	f9842583          	lw	a1,-104(s0)
    80006c18:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c1c:	00250613          	addi	a2,a0,2
    80006c20:	0612                	slli	a2,a2,0x4
    80006c22:	963e                	add	a2,a2,a5
    80006c24:	577d                	li	a4,-1
    80006c26:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c2a:	0592                	slli	a1,a1,0x4
    80006c2c:	98ae                	add	a7,a7,a1
    80006c2e:	03068713          	addi	a4,a3,48
    80006c32:	973e                	add	a4,a4,a5
    80006c34:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006c38:	6398                	ld	a4,0(a5)
    80006c3a:	972e                	add	a4,a4,a1
    80006c3c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c40:	4689                	li	a3,2
    80006c42:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80006c46:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c4a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006c4e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c52:	6794                	ld	a3,8(a5)
    80006c54:	0026d703          	lhu	a4,2(a3)
    80006c58:	8b1d                	andi	a4,a4,7
    80006c5a:	0706                	slli	a4,a4,0x1
    80006c5c:	96ba                	add	a3,a3,a4
    80006c5e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006c62:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c66:	6798                	ld	a4,8(a5)
    80006c68:	00275783          	lhu	a5,2(a4)
    80006c6c:	2785                	addiw	a5,a5,1
    80006c6e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c72:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c76:	100017b7          	lui	a5,0x10001
    80006c7a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c7e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006c82:	001a9917          	auipc	s2,0x1a9
    80006c86:	68e90913          	addi	s2,s2,1678 # 801b0310 <disk+0x128>
  while(b->disk == 1) {
    80006c8a:	4485                	li	s1,1
    80006c8c:	01079a63          	bne	a5,a6,80006ca0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80006c90:	85ca                	mv	a1,s2
    80006c92:	8552                	mv	a0,s4
    80006c94:	a26fc0ef          	jal	80002eba <sleep>
  while(b->disk == 1) {
    80006c98:	004a2783          	lw	a5,4(s4)
    80006c9c:	fe978ae3          	beq	a5,s1,80006c90 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80006ca0:	f9042903          	lw	s2,-112(s0)
    80006ca4:	00290713          	addi	a4,s2,2
    80006ca8:	0712                	slli	a4,a4,0x4
    80006caa:	001a9797          	auipc	a5,0x1a9
    80006cae:	53e78793          	addi	a5,a5,1342 # 801b01e8 <disk>
    80006cb2:	97ba                	add	a5,a5,a4
    80006cb4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006cb8:	001a9997          	auipc	s3,0x1a9
    80006cbc:	53098993          	addi	s3,s3,1328 # 801b01e8 <disk>
    80006cc0:	00491713          	slli	a4,s2,0x4
    80006cc4:	0009b783          	ld	a5,0(s3)
    80006cc8:	97ba                	add	a5,a5,a4
    80006cca:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006cce:	854a                	mv	a0,s2
    80006cd0:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006cd4:	bafff0ef          	jal	80006882 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006cd8:	8885                	andi	s1,s1,1
    80006cda:	f0fd                	bnez	s1,80006cc0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006cdc:	001a9517          	auipc	a0,0x1a9
    80006ce0:	63450513          	addi	a0,a0,1588 # 801b0310 <disk+0x128>
    80006ce4:	f91f90ef          	jal	80000c74 <release>
}
    80006ce8:	70a6                	ld	ra,104(sp)
    80006cea:	7406                	ld	s0,96(sp)
    80006cec:	64e6                	ld	s1,88(sp)
    80006cee:	6946                	ld	s2,80(sp)
    80006cf0:	69a6                	ld	s3,72(sp)
    80006cf2:	6a06                	ld	s4,64(sp)
    80006cf4:	7ae2                	ld	s5,56(sp)
    80006cf6:	7b42                	ld	s6,48(sp)
    80006cf8:	7ba2                	ld	s7,40(sp)
    80006cfa:	7c02                	ld	s8,32(sp)
    80006cfc:	6ce2                	ld	s9,24(sp)
    80006cfe:	6165                	addi	sp,sp,112
    80006d00:	8082                	ret

0000000080006d02 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d02:	1101                	addi	sp,sp,-32
    80006d04:	ec06                	sd	ra,24(sp)
    80006d06:	e822                	sd	s0,16(sp)
    80006d08:	e426                	sd	s1,8(sp)
    80006d0a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d0c:	001a9497          	auipc	s1,0x1a9
    80006d10:	4dc48493          	addi	s1,s1,1244 # 801b01e8 <disk>
    80006d14:	001a9517          	auipc	a0,0x1a9
    80006d18:	5fc50513          	addi	a0,a0,1532 # 801b0310 <disk+0x128>
    80006d1c:	eb3f90ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d20:	100017b7          	lui	a5,0x10001
    80006d24:	53b8                	lw	a4,96(a5)
    80006d26:	8b0d                	andi	a4,a4,3
    80006d28:	100017b7          	lui	a5,0x10001
    80006d2c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006d2e:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d32:	689c                	ld	a5,16(s1)
    80006d34:	0204d703          	lhu	a4,32(s1)
    80006d38:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006d3c:	04f70663          	beq	a4,a5,80006d88 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80006d40:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d44:	6898                	ld	a4,16(s1)
    80006d46:	0204d783          	lhu	a5,32(s1)
    80006d4a:	8b9d                	andi	a5,a5,7
    80006d4c:	078e                	slli	a5,a5,0x3
    80006d4e:	97ba                	add	a5,a5,a4
    80006d50:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d52:	00278713          	addi	a4,a5,2
    80006d56:	0712                	slli	a4,a4,0x4
    80006d58:	9726                	add	a4,a4,s1
    80006d5a:	01074703          	lbu	a4,16(a4)
    80006d5e:	e321                	bnez	a4,80006d9e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d60:	0789                	addi	a5,a5,2
    80006d62:	0792                	slli	a5,a5,0x4
    80006d64:	97a6                	add	a5,a5,s1
    80006d66:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006d68:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d6c:	99afc0ef          	jal	80002f06 <wakeup>

    disk.used_idx += 1;
    80006d70:	0204d783          	lhu	a5,32(s1)
    80006d74:	2785                	addiw	a5,a5,1
    80006d76:	17c2                	slli	a5,a5,0x30
    80006d78:	93c1                	srli	a5,a5,0x30
    80006d7a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d7e:	6898                	ld	a4,16(s1)
    80006d80:	00275703          	lhu	a4,2(a4)
    80006d84:	faf71ee3          	bne	a4,a5,80006d40 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006d88:	001a9517          	auipc	a0,0x1a9
    80006d8c:	58850513          	addi	a0,a0,1416 # 801b0310 <disk+0x128>
    80006d90:	ee5f90ef          	jal	80000c74 <release>
}
    80006d94:	60e2                	ld	ra,24(sp)
    80006d96:	6442                	ld	s0,16(sp)
    80006d98:	64a2                	ld	s1,8(sp)
    80006d9a:	6105                	addi	sp,sp,32
    80006d9c:	8082                	ret
      panic("virtio_disk_intr status");
    80006d9e:	00002517          	auipc	a0,0x2
    80006da2:	d3a50513          	addi	a0,a0,-710 # 80008ad8 <etext+0xad8>
    80006da6:	a3bf90ef          	jal	800007e0 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	9282                	jalr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
