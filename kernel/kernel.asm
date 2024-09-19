
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	f3478793          	addi	a5,a5,-204 # 80005f90 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	5d8080e7          	jalr	1496(ra) # 800026fe <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	968080e7          	jalr	-1688(ra) # 80001b32 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	274080e7          	jalr	628(ra) # 8000244e <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	492080e7          	jalr	1170(ra) # 800026a8 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	45e080e7          	jalr	1118(ra) # 80002754 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	184080e7          	jalr	388(ra) # 800025ce <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	ba458593          	addi	a1,a1,-1116 # 80008000 <etext>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00022797          	auipc	a5,0x22
    80000480:	93478793          	addi	a5,a5,-1740 # 80021db0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b7260613          	addi	a2,a2,-1166 # 80008030 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ab250513          	addi	a0,a0,-1358 # 80008008 <etext+0x8>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b4850513          	addi	a0,a0,-1208 # 800080b8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a46b0b13          	addi	s6,s6,-1466 # 80008030 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a0a50513          	addi	a0,a0,-1526 # 80008018 <etext+0x18>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	90848493          	addi	s1,s1,-1784 # 80008010 <etext+0x10>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8aa58593          	addi	a1,a1,-1878 # 80008028 <etext+0x28>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	87a58593          	addi	a1,a1,-1926 # 80008048 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	d2c080e7          	jalr	-724(ra) # 800025ce <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	b12080e7          	jalr	-1262(ra) # 8000244e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00026797          	auipc	a5,0x26
    80000a2a:	5fa78793          	addi	a5,a5,1530 # 80027020 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5d850513          	addi	a0,a0,1496 # 80008050 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	57e58593          	addi	a1,a1,1406 # 80008058 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00026517          	auipc	a0,0x26
    80000afa:	52a50513          	addi	a0,a0,1322 # 80027020 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	f7e080e7          	jalr	-130(ra) # 80001b16 <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	f4c080e7          	jalr	-180(ra) # 80001b16 <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	f40080e7          	jalr	-192(ra) # 80001b16 <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	f28080e7          	jalr	-216(ra) # 80001b16 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	ee8080e7          	jalr	-280(ra) # 80001b16 <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	41e50513          	addi	a0,a0,1054 # 80008060 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	ebc080e7          	jalr	-324(ra) # 80001b16 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3d650513          	addi	a0,a0,982 # 80008068 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3de50513          	addi	a0,a0,990 # 80008080 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	39e50513          	addi	a0,a0,926 # 80008088 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	c56080e7          	jalr	-938(ra) # 80001b06 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	c3a080e7          	jalr	-966(ra) # 80001b06 <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	1d250513          	addi	a0,a0,466 # 800080a8 <digits+0x78>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0e0080e7          	jalr	224(ra) # 80000fc6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00002097          	auipc	ra,0x2
    80000ef2:	a9c080e7          	jalr	-1380(ra) # 8000298a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	0da080e7          	jalr	218(ra) # 80005fd0 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	25a080e7          	jalr	602(ra) # 80002158 <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    statsinit();
    80000f0e:	00006097          	auipc	ra,0x6
    80000f12:	86e080e7          	jalr	-1938(ra) # 8000677c <statsinit>
    printfinit();
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	856080e7          	jalr	-1962(ra) # 8000076c <printfinit>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	19a50513          	addi	a0,a0,410 # 800080b8 <digits+0x88>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	666080e7          	jalr	1638(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	16250513          	addi	a0,a0,354 # 80008090 <digits+0x60>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	656080e7          	jalr	1622(ra) # 8000058c <printf>
    printf("\n");
    80000f3e:	00007517          	auipc	a0,0x7
    80000f42:	17a50513          	addi	a0,a0,378 # 800080b8 <digits+0x88>
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	646080e7          	jalr	1606(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	b84080e7          	jalr	-1148(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	37a080e7          	jalr	890(ra) # 800012d0 <kvminit>
    kvminithart();   // turn on paging
    80000f5e:	00000097          	auipc	ra,0x0
    80000f62:	068080e7          	jalr	104(ra) # 80000fc6 <kvminithart>
    procinit();      // process table
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	b38080e7          	jalr	-1224(ra) # 80001a9e <procinit>
    trapinit();      // trap vectors
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	9f4080e7          	jalr	-1548(ra) # 80002962 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	a14080e7          	jalr	-1516(ra) # 8000298a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	03c080e7          	jalr	60(ra) # 80005fba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	04a080e7          	jalr	74(ra) # 80005fd0 <plicinithart>
    binit();         // buffer cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	1a0080e7          	jalr	416(ra) # 8000312e <binit>
    iinit();         // inode cache
    80000f96:	00003097          	auipc	ra,0x3
    80000f9a:	830080e7          	jalr	-2000(ra) # 800037c6 <iinit>
    fileinit();      // file table
    80000f9e:	00003097          	auipc	ra,0x3
    80000fa2:	7ca080e7          	jalr	1994(ra) # 80004768 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa6:	00005097          	auipc	ra,0x5
    80000faa:	132080e7          	jalr	306(ra) # 800060d8 <virtio_disk_init>
    userinit();      // first user process
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	eb8080e7          	jalr	-328(ra) # 80001e66 <userinit>
    __sync_synchronize();
    80000fb6:	0ff0000f          	fence
    started = 1;
    80000fba:	4785                	li	a5,1
    80000fbc:	00008717          	auipc	a4,0x8
    80000fc0:	04f72823          	sw	a5,80(a4) # 8000900c <started>
    80000fc4:	bf2d                	j	80000efe <main+0x56>

0000000080000fc6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc6:	1141                	addi	sp,sp,-16
    80000fc8:	e422                	sd	s0,8(sp)
    80000fca:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fcc:	00008797          	auipc	a5,0x8
    80000fd0:	0447b783          	ld	a5,68(a5) # 80009010 <kernel_pagetable>
    80000fd4:	83b1                	srli	a5,a5,0xc
    80000fd6:	577d                	li	a4,-1
    80000fd8:	177e                	slli	a4,a4,0x3f
    80000fda:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fdc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe4:	6422                	ld	s0,8(sp)
    80000fe6:	0141                	addi	sp,sp,16
    80000fe8:	8082                	ret

0000000080000fea <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fea:	7139                	addi	sp,sp,-64
    80000fec:	fc06                	sd	ra,56(sp)
    80000fee:	f822                	sd	s0,48(sp)
    80000ff0:	f426                	sd	s1,40(sp)
    80000ff2:	f04a                	sd	s2,32(sp)
    80000ff4:	ec4e                	sd	s3,24(sp)
    80000ff6:	e852                	sd	s4,16(sp)
    80000ff8:	e456                	sd	s5,8(sp)
    80000ffa:	e05a                	sd	s6,0(sp)
    80000ffc:	0080                	addi	s0,sp,64
    80000ffe:	84aa                	mv	s1,a0
    80001000:	89ae                	mv	s3,a1
    80001002:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001004:	57fd                	li	a5,-1
    80001006:	83e9                	srli	a5,a5,0x1a
    80001008:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100c:	04b7f263          	bgeu	a5,a1,80001050 <walk+0x66>
    panic("walk");
    80001010:	00007517          	auipc	a0,0x7
    80001014:	0b050513          	addi	a0,a0,176 # 800080c0 <digits+0x90>
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	52a080e7          	jalr	1322(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001020:	060a8663          	beqz	s5,8000108c <walk+0xa2>
    80001024:	00000097          	auipc	ra,0x0
    80001028:	aea080e7          	jalr	-1302(ra) # 80000b0e <kalloc>
    8000102c:	84aa                	mv	s1,a0
    8000102e:	c529                	beqz	a0,80001078 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001030:	6605                	lui	a2,0x1
    80001032:	4581                	li	a1,0
    80001034:	00000097          	auipc	ra,0x0
    80001038:	cc6080e7          	jalr	-826(ra) # 80000cfa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103c:	00c4d793          	srli	a5,s1,0xc
    80001040:	07aa                	slli	a5,a5,0xa
    80001042:	0017e793          	ori	a5,a5,1
    80001046:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104a:	3a5d                	addiw	s4,s4,-9
    8000104c:	036a0063          	beq	s4,s6,8000106c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001050:	0149d933          	srl	s2,s3,s4
    80001054:	1ff97913          	andi	s2,s2,511
    80001058:	090e                	slli	s2,s2,0x3
    8000105a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105c:	00093483          	ld	s1,0(s2)
    80001060:	0014f793          	andi	a5,s1,1
    80001064:	dfd5                	beqz	a5,80001020 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001066:	80a9                	srli	s1,s1,0xa
    80001068:	04b2                	slli	s1,s1,0xc
    8000106a:	b7c5                	j	8000104a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106c:	00c9d513          	srli	a0,s3,0xc
    80001070:	1ff57513          	andi	a0,a0,511
    80001074:	050e                	slli	a0,a0,0x3
    80001076:	9526                	add	a0,a0,s1
}
    80001078:	70e2                	ld	ra,56(sp)
    8000107a:	7442                	ld	s0,48(sp)
    8000107c:	74a2                	ld	s1,40(sp)
    8000107e:	7902                	ld	s2,32(sp)
    80001080:	69e2                	ld	s3,24(sp)
    80001082:	6a42                	ld	s4,16(sp)
    80001084:	6aa2                	ld	s5,8(sp)
    80001086:	6b02                	ld	s6,0(sp)
    80001088:	6121                	addi	sp,sp,64
    8000108a:	8082                	ret
        return 0;
    8000108c:	4501                	li	a0,0
    8000108e:	b7ed                	j	80001078 <walk+0x8e>

0000000080001090 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001090:	57fd                	li	a5,-1
    80001092:	83e9                	srli	a5,a5,0x1a
    80001094:	00b7f463          	bgeu	a5,a1,8000109c <walkaddr+0xc>
    return 0;
    80001098:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109a:	8082                	ret
{
    8000109c:	1141                	addi	sp,sp,-16
    8000109e:	e406                	sd	ra,8(sp)
    800010a0:	e022                	sd	s0,0(sp)
    800010a2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a4:	4601                	li	a2,0
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	f44080e7          	jalr	-188(ra) # 80000fea <walk>
  if(pte == 0)
    800010ae:	c105                	beqz	a0,800010ce <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b2:	0117f693          	andi	a3,a5,17
    800010b6:	4745                	li	a4,17
    return 0;
    800010b8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ba:	00e68663          	beq	a3,a4,800010c6 <walkaddr+0x36>
}
    800010be:	60a2                	ld	ra,8(sp)
    800010c0:	6402                	ld	s0,0(sp)
    800010c2:	0141                	addi	sp,sp,16
    800010c4:	8082                	ret
  pa = PTE2PA(*pte);
    800010c6:	00a7d513          	srli	a0,a5,0xa
    800010ca:	0532                	slli	a0,a0,0xc
  return pa;
    800010cc:	bfcd                	j	800010be <walkaddr+0x2e>
    return 0;
    800010ce:	4501                	li	a0,0
    800010d0:	b7fd                	j	800010be <walkaddr+0x2e>

00000000800010d2 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(pagetable_t pgtbl, uint64 va)
{
    800010d2:	1101                	addi	sp,sp,-32
    800010d4:	ec06                	sd	ra,24(sp)
    800010d6:	e822                	sd	s0,16(sp)
    800010d8:	e426                	sd	s1,8(sp)
    800010da:	1000                	addi	s0,sp,32
  uint64 off = va % PGSIZE;
    800010dc:	03459793          	slli	a5,a1,0x34
    800010e0:	0347d493          	srli	s1,a5,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(pgtbl, va, 0);
    800010e4:	4601                	li	a2,0
    800010e6:	00000097          	auipc	ra,0x0
    800010ea:	f04080e7          	jalr	-252(ra) # 80000fea <walk>
  if(pte == 0)
    800010ee:	cd09                	beqz	a0,80001108 <kvmpa+0x36>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010f0:	6108                	ld	a0,0(a0)
    800010f2:	00157793          	andi	a5,a0,1
    800010f6:	c38d                	beqz	a5,80001118 <kvmpa+0x46>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010f8:	8129                	srli	a0,a0,0xa
    800010fa:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010fc:	9526                	add	a0,a0,s1
    800010fe:	60e2                	ld	ra,24(sp)
    80001100:	6442                	ld	s0,16(sp)
    80001102:	64a2                	ld	s1,8(sp)
    80001104:	6105                	addi	sp,sp,32
    80001106:	8082                	ret
    panic("kvmpa");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fc050513          	addi	a0,a0,-64 # 800080c8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	432080e7          	jalr	1074(ra) # 80000542 <panic>
    panic("kvmpa");
    80001118:	00007517          	auipc	a0,0x7
    8000111c:	fb050513          	addi	a0,a0,-80 # 800080c8 <digits+0x98>
    80001120:	fffff097          	auipc	ra,0xfffff
    80001124:	422080e7          	jalr	1058(ra) # 80000542 <panic>

0000000080001128 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001128:	715d                	addi	sp,sp,-80
    8000112a:	e486                	sd	ra,72(sp)
    8000112c:	e0a2                	sd	s0,64(sp)
    8000112e:	fc26                	sd	s1,56(sp)
    80001130:	f84a                	sd	s2,48(sp)
    80001132:	f44e                	sd	s3,40(sp)
    80001134:	f052                	sd	s4,32(sp)
    80001136:	ec56                	sd	s5,24(sp)
    80001138:	e85a                	sd	s6,16(sp)
    8000113a:	e45e                	sd	s7,8(sp)
    8000113c:	0880                	addi	s0,sp,80
    8000113e:	8aaa                	mv	s5,a0
    80001140:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001142:	777d                	lui	a4,0xfffff
    80001144:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001148:	167d                	addi	a2,a2,-1
    8000114a:	00b609b3          	add	s3,a2,a1
    8000114e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001152:	893e                	mv	s2,a5
    80001154:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001158:	6b85                	lui	s7,0x1
    8000115a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115e:	4605                	li	a2,1
    80001160:	85ca                	mv	a1,s2
    80001162:	8556                	mv	a0,s5
    80001164:	00000097          	auipc	ra,0x0
    80001168:	e86080e7          	jalr	-378(ra) # 80000fea <walk>
    8000116c:	c51d                	beqz	a0,8000119a <mappages+0x72>
    if(*pte & PTE_V)
    8000116e:	611c                	ld	a5,0(a0)
    80001170:	8b85                	andi	a5,a5,1
    80001172:	ef81                	bnez	a5,8000118a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001174:	80b1                	srli	s1,s1,0xc
    80001176:	04aa                	slli	s1,s1,0xa
    80001178:	0164e4b3          	or	s1,s1,s6
    8000117c:	0014e493          	ori	s1,s1,1
    80001180:	e104                	sd	s1,0(a0)
    if(a == last)
    80001182:	03390863          	beq	s2,s3,800011b2 <mappages+0x8a>
    a += PGSIZE;
    80001186:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001188:	bfc9                	j	8000115a <mappages+0x32>
      panic("remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f4650513          	addi	a0,a0,-186 # 800080d0 <digits+0xa0>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3b0080e7          	jalr	944(ra) # 80000542 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x74>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(pgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f64080e7          	jalr	-156(ra) # 80001128 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f0250513          	addi	a0,a0,-254 # 800080d8 <digits+0xa8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	364080e7          	jalr	868(ra) # 80000542 <panic>

00000000800011e6 <kvm_map_pagetable>:
void kvm_map_pagetable(pagetable_t pgtbl) {
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
    800011f2:	84aa                	mv	s1,a0
  kvmmap(pgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011f4:	4719                	li	a4,6
    800011f6:	6685                	lui	a3,0x1
    800011f8:	10000637          	lui	a2,0x10000
    800011fc:	100005b7          	lui	a1,0x10000
    80001200:	00000097          	auipc	ra,0x0
    80001204:	fb6080e7          	jalr	-74(ra) # 800011b6 <kvmmap>
  kvmmap(pgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10001637          	lui	a2,0x10001
    80001210:	100015b7          	lui	a1,0x10001
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(pgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	004006b7          	lui	a3,0x400
    80001224:	0c000637          	lui	a2,0xc000
    80001228:	0c0005b7          	lui	a1,0xc000
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	f88080e7          	jalr	-120(ra) # 800011b6 <kvmmap>
  kvmmap(pgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001236:	00007917          	auipc	s2,0x7
    8000123a:	dca90913          	addi	s2,s2,-566 # 80008000 <etext>
    8000123e:	4729                	li	a4,10
    80001240:	80007697          	auipc	a3,0x80007
    80001244:	dc068693          	addi	a3,a3,-576 # 8000 <_entry-0x7fff8000>
    80001248:	4605                	li	a2,1
    8000124a:	067e                	slli	a2,a2,0x1f
    8000124c:	85b2                	mv	a1,a2
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f66080e7          	jalr	-154(ra) # 800011b6 <kvmmap>
  kvmmap(pgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001258:	4719                	li	a4,6
    8000125a:	46c5                	li	a3,17
    8000125c:	06ee                	slli	a3,a3,0x1b
    8000125e:	412686b3          	sub	a3,a3,s2
    80001262:	864a                	mv	a2,s2
    80001264:	85ca                	mv	a1,s2
    80001266:	8526                	mv	a0,s1
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f4e080e7          	jalr	-178(ra) # 800011b6 <kvmmap>
  kvmmap(pgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001270:	4729                	li	a4,10
    80001272:	6685                	lui	a3,0x1
    80001274:	00006617          	auipc	a2,0x6
    80001278:	d8c60613          	addi	a2,a2,-628 # 80007000 <_trampoline>
    8000127c:	040005b7          	lui	a1,0x4000
    80001280:	15fd                	addi	a1,a1,-1
    80001282:	05b2                	slli	a1,a1,0xc
    80001284:	8526                	mv	a0,s1
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f30080e7          	jalr	-208(ra) # 800011b6 <kvmmap>
}
    8000128e:	60e2                	ld	ra,24(sp)
    80001290:	6442                	ld	s0,16(sp)
    80001292:	64a2                	ld	s1,8(sp)
    80001294:	6902                	ld	s2,0(sp)
    80001296:	6105                	addi	sp,sp,32
    80001298:	8082                	ret

000000008000129a <kvminit_newpgtbl>:
{
    8000129a:	1101                	addi	sp,sp,-32
    8000129c:	ec06                	sd	ra,24(sp)
    8000129e:	e822                	sd	s0,16(sp)
    800012a0:	e426                	sd	s1,8(sp)
    800012a2:	1000                	addi	s0,sp,32
  pagetable_t pgtbl = (pagetable_t) kalloc();
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	86a080e7          	jalr	-1942(ra) # 80000b0e <kalloc>
    800012ac:	84aa                	mv	s1,a0
  memset(pgtbl, 0, PGSIZE);
    800012ae:	6605                	lui	a2,0x1
    800012b0:	4581                	li	a1,0
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	a48080e7          	jalr	-1464(ra) # 80000cfa <memset>
  kvm_map_pagetable(pgtbl);
    800012ba:	8526                	mv	a0,s1
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	f2a080e7          	jalr	-214(ra) # 800011e6 <kvm_map_pagetable>
}
    800012c4:	8526                	mv	a0,s1
    800012c6:	60e2                	ld	ra,24(sp)
    800012c8:	6442                	ld	s0,16(sp)
    800012ca:	64a2                	ld	s1,8(sp)
    800012cc:	6105                	addi	sp,sp,32
    800012ce:	8082                	ret

00000000800012d0 <kvminit>:
{
    800012d0:	1141                	addi	sp,sp,-16
    800012d2:	e406                	sd	ra,8(sp)
    800012d4:	e022                	sd	s0,0(sp)
    800012d6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvminit_newpgtbl(); // 仍然需要有全局的内核页表，用于内核 boot 过程，以及无进程在运行时使用。
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	fc2080e7          	jalr	-62(ra) # 8000129a <kvminit_newpgtbl>
    800012e0:	00008797          	auipc	a5,0x8
    800012e4:	d2a7b823          	sd	a0,-720(a5) # 80009010 <kernel_pagetable>
  kvmmap(kernel_pagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012e8:	4719                	li	a4,6
    800012ea:	66c1                	lui	a3,0x10
    800012ec:	02000637          	lui	a2,0x2000
    800012f0:	020005b7          	lui	a1,0x2000
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	ec2080e7          	jalr	-318(ra) # 800011b6 <kvmmap>
}
    800012fc:	60a2                	ld	ra,8(sp)
    800012fe:	6402                	ld	s0,0(sp)
    80001300:	0141                	addi	sp,sp,16
    80001302:	8082                	ret

0000000080001304 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001304:	715d                	addi	sp,sp,-80
    80001306:	e486                	sd	ra,72(sp)
    80001308:	e0a2                	sd	s0,64(sp)
    8000130a:	fc26                	sd	s1,56(sp)
    8000130c:	f84a                	sd	s2,48(sp)
    8000130e:	f44e                	sd	s3,40(sp)
    80001310:	f052                	sd	s4,32(sp)
    80001312:	ec56                	sd	s5,24(sp)
    80001314:	e85a                	sd	s6,16(sp)
    80001316:	e45e                	sd	s7,8(sp)
    80001318:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000131a:	03459793          	slli	a5,a1,0x34
    8000131e:	e795                	bnez	a5,8000134a <uvmunmap+0x46>
    80001320:	8a2a                	mv	s4,a0
    80001322:	892e                	mv	s2,a1
    80001324:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001326:	0632                	slli	a2,a2,0xc
    80001328:	00b609b3          	add	s3,a2,a1
      continue;
      //panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000132e:	6a85                	lui	s5,0x1
    80001330:	0535e263          	bltu	a1,s3,80001374 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001334:	60a6                	ld	ra,72(sp)
    80001336:	6406                	ld	s0,64(sp)
    80001338:	74e2                	ld	s1,56(sp)
    8000133a:	7942                	ld	s2,48(sp)
    8000133c:	79a2                	ld	s3,40(sp)
    8000133e:	7a02                	ld	s4,32(sp)
    80001340:	6ae2                	ld	s5,24(sp)
    80001342:	6b42                	ld	s6,16(sp)
    80001344:	6ba2                	ld	s7,8(sp)
    80001346:	6161                	addi	sp,sp,80
    80001348:	8082                	ret
    panic("uvmunmap: not aligned");
    8000134a:	00007517          	auipc	a0,0x7
    8000134e:	d9650513          	addi	a0,a0,-618 # 800080e0 <digits+0xb0>
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	1f0080e7          	jalr	496(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    8000135a:	00007517          	auipc	a0,0x7
    8000135e:	d9e50513          	addi	a0,a0,-610 # 800080f8 <digits+0xc8>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1e0080e7          	jalr	480(ra) # 80000542 <panic>
    *pte = 0;
    8000136a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136e:	9956                	add	s2,s2,s5
    80001370:	fd3972e3          	bgeu	s2,s3,80001334 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001374:	4601                	li	a2,0
    80001376:	85ca                	mv	a1,s2
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	c70080e7          	jalr	-912(ra) # 80000fea <walk>
    80001382:	84aa                	mv	s1,a0
    80001384:	d56d                	beqz	a0,8000136e <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    80001386:	611c                	ld	a5,0(a0)
    80001388:	0017f713          	andi	a4,a5,1
    8000138c:	d36d                	beqz	a4,8000136e <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138e:	3ff7f713          	andi	a4,a5,1023
    80001392:	fd7704e3          	beq	a4,s7,8000135a <uvmunmap+0x56>
    if(do_free){
    80001396:	fc0b0ae3          	beqz	s6,8000136a <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    8000139a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000139c:	00c79513          	slli	a0,a5,0xc
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	672080e7          	jalr	1650(ra) # 80000a12 <kfree>
    800013a8:	b7c9                	j	8000136a <uvmunmap+0x66>

00000000800013aa <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013aa:	1101                	addi	sp,sp,-32
    800013ac:	ec06                	sd	ra,24(sp)
    800013ae:	e822                	sd	s0,16(sp)
    800013b0:	e426                	sd	s1,8(sp)
    800013b2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b4:	fffff097          	auipc	ra,0xfffff
    800013b8:	75a080e7          	jalr	1882(ra) # 80000b0e <kalloc>
    800013bc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013be:	c519                	beqz	a0,800013cc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	936080e7          	jalr	-1738(ra) # 80000cfa <memset>
  return pagetable;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret

00000000800013d8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d8:	7179                	addi	sp,sp,-48
    800013da:	f406                	sd	ra,40(sp)
    800013dc:	f022                	sd	s0,32(sp)
    800013de:	ec26                	sd	s1,24(sp)
    800013e0:	e84a                	sd	s2,16(sp)
    800013e2:	e44e                	sd	s3,8(sp)
    800013e4:	e052                	sd	s4,0(sp)
    800013e6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e8:	6785                	lui	a5,0x1
    800013ea:	04f67863          	bgeu	a2,a5,8000143a <uvminit+0x62>
    800013ee:	8a2a                	mv	s4,a0
    800013f0:	89ae                	mv	s3,a1
    800013f2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	71a080e7          	jalr	1818(ra) # 80000b0e <kalloc>
    800013fc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	00000097          	auipc	ra,0x0
    80001406:	8f8080e7          	jalr	-1800(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000140a:	4779                	li	a4,30
    8000140c:	86ca                	mv	a3,s2
    8000140e:	6605                	lui	a2,0x1
    80001410:	4581                	li	a1,0
    80001412:	8552                	mv	a0,s4
    80001414:	00000097          	auipc	ra,0x0
    80001418:	d14080e7          	jalr	-748(ra) # 80001128 <mappages>
  memmove(mem, src, sz);
    8000141c:	8626                	mv	a2,s1
    8000141e:	85ce                	mv	a1,s3
    80001420:	854a                	mv	a0,s2
    80001422:	00000097          	auipc	ra,0x0
    80001426:	934080e7          	jalr	-1740(ra) # 80000d56 <memmove>
}
    8000142a:	70a2                	ld	ra,40(sp)
    8000142c:	7402                	ld	s0,32(sp)
    8000142e:	64e2                	ld	s1,24(sp)
    80001430:	6942                	ld	s2,16(sp)
    80001432:	69a2                	ld	s3,8(sp)
    80001434:	6a02                	ld	s4,0(sp)
    80001436:	6145                	addi	sp,sp,48
    80001438:	8082                	ret
    panic("inituvm: more than a page");
    8000143a:	00007517          	auipc	a0,0x7
    8000143e:	cd650513          	addi	a0,a0,-810 # 80008110 <digits+0xe0>
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	100080e7          	jalr	256(ra) # 80000542 <panic>

000000008000144a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000144a:	1101                	addi	sp,sp,-32
    8000144c:	ec06                	sd	ra,24(sp)
    8000144e:	e822                	sd	s0,16(sp)
    80001450:	e426                	sd	s1,8(sp)
    80001452:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001454:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001456:	00b67d63          	bgeu	a2,a1,80001470 <uvmdealloc+0x26>
    8000145a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145c:	6785                	lui	a5,0x1
    8000145e:	17fd                	addi	a5,a5,-1
    80001460:	00f60733          	add	a4,a2,a5
    80001464:	767d                	lui	a2,0xfffff
    80001466:	8f71                	and	a4,a4,a2
    80001468:	97ae                	add	a5,a5,a1
    8000146a:	8ff1                	and	a5,a5,a2
    8000146c:	00f76863          	bltu	a4,a5,8000147c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001470:	8526                	mv	a0,s1
    80001472:	60e2                	ld	ra,24(sp)
    80001474:	6442                	ld	s0,16(sp)
    80001476:	64a2                	ld	s1,8(sp)
    80001478:	6105                	addi	sp,sp,32
    8000147a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147c:	8f99                	sub	a5,a5,a4
    8000147e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001480:	4685                	li	a3,1
    80001482:	0007861b          	sext.w	a2,a5
    80001486:	85ba                	mv	a1,a4
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	e7c080e7          	jalr	-388(ra) # 80001304 <uvmunmap>
    80001490:	b7c5                	j	80001470 <uvmdealloc+0x26>

0000000080001492 <uvmalloc>:
  if(newsz < oldsz)
    80001492:	0ab66163          	bltu	a2,a1,80001534 <uvmalloc+0xa2>
{
    80001496:	7139                	addi	sp,sp,-64
    80001498:	fc06                	sd	ra,56(sp)
    8000149a:	f822                	sd	s0,48(sp)
    8000149c:	f426                	sd	s1,40(sp)
    8000149e:	f04a                	sd	s2,32(sp)
    800014a0:	ec4e                	sd	s3,24(sp)
    800014a2:	e852                	sd	s4,16(sp)
    800014a4:	e456                	sd	s5,8(sp)
    800014a6:	0080                	addi	s0,sp,64
    800014a8:	8aaa                	mv	s5,a0
    800014aa:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ac:	6985                	lui	s3,0x1
    800014ae:	19fd                	addi	s3,s3,-1
    800014b0:	95ce                	add	a1,a1,s3
    800014b2:	79fd                	lui	s3,0xfffff
    800014b4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b8:	08c9f063          	bgeu	s3,a2,80001538 <uvmalloc+0xa6>
    800014bc:	894e                	mv	s2,s3
    mem = kalloc();
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	650080e7          	jalr	1616(ra) # 80000b0e <kalloc>
    800014c6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c8:	c51d                	beqz	a0,800014f6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ca:	6605                	lui	a2,0x1
    800014cc:	4581                	li	a1,0
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	82c080e7          	jalr	-2004(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d6:	4779                	li	a4,30
    800014d8:	86a6                	mv	a3,s1
    800014da:	6605                	lui	a2,0x1
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	c48080e7          	jalr	-952(ra) # 80001128 <mappages>
    800014e8:	e905                	bnez	a0,80001518 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ea:	6785                	lui	a5,0x1
    800014ec:	993e                	add	s2,s2,a5
    800014ee:	fd4968e3          	bltu	s2,s4,800014be <uvmalloc+0x2c>
  return newsz;
    800014f2:	8552                	mv	a0,s4
    800014f4:	a809                	j	80001506 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f6:	864e                	mv	a2,s3
    800014f8:	85ca                	mv	a1,s2
    800014fa:	8556                	mv	a0,s5
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	f4e080e7          	jalr	-178(ra) # 8000144a <uvmdealloc>
      return 0;
    80001504:	4501                	li	a0,0
}
    80001506:	70e2                	ld	ra,56(sp)
    80001508:	7442                	ld	s0,48(sp)
    8000150a:	74a2                	ld	s1,40(sp)
    8000150c:	7902                	ld	s2,32(sp)
    8000150e:	69e2                	ld	s3,24(sp)
    80001510:	6a42                	ld	s4,16(sp)
    80001512:	6aa2                	ld	s5,8(sp)
    80001514:	6121                	addi	sp,sp,64
    80001516:	8082                	ret
      kfree(mem);
    80001518:	8526                	mv	a0,s1
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	4f8080e7          	jalr	1272(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001522:	864e                	mv	a2,s3
    80001524:	85ca                	mv	a1,s2
    80001526:	8556                	mv	a0,s5
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f22080e7          	jalr	-222(ra) # 8000144a <uvmdealloc>
      return 0;
    80001530:	4501                	li	a0,0
    80001532:	bfd1                	j	80001506 <uvmalloc+0x74>
    return oldsz;
    80001534:	852e                	mv	a0,a1
}
    80001536:	8082                	ret
  return newsz;
    80001538:	8532                	mv	a0,a2
    8000153a:	b7f1                	j	80001506 <uvmalloc+0x74>

000000008000153c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153c:	7179                	addi	sp,sp,-48
    8000153e:	f406                	sd	ra,40(sp)
    80001540:	f022                	sd	s0,32(sp)
    80001542:	ec26                	sd	s1,24(sp)
    80001544:	e84a                	sd	s2,16(sp)
    80001546:	e44e                	sd	s3,8(sp)
    80001548:	e052                	sd	s4,0(sp)
    8000154a:	1800                	addi	s0,sp,48
    8000154c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154e:	84aa                	mv	s1,a0
    80001550:	6905                	lui	s2,0x1
    80001552:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001554:	4985                	li	s3,1
    80001556:	a821                	j	8000156e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001558:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000155a:	0532                	slli	a0,a0,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fe0080e7          	jalr	-32(ra) # 8000153c <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000156e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f57793          	andi	a5,a0,15
    80001574:	ff3782e3          	beq	a5,s3,80001558 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8905                	andi	a0,a0,1
    8000157a:	d57d                	beqz	a0,80001568 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bb450513          	addi	a0,a0,-1100 # 80008130 <digits+0x100>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbe080e7          	jalr	-66(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	484080e7          	jalr	1156(ra) # 80000a12 <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f86080e7          	jalr	-122(ra) # 8000153c <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6605                	lui	a2,0x1
    800015ca:	167d                	addi	a2,a2,-1
    800015cc:	962e                	add	a2,a2,a1
    800015ce:	4685                	li	a3,1
    800015d0:	8231                	srli	a2,a2,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	d30080e7          	jalr	-720(ra) # 80001304 <uvmunmap>
    800015dc:	bfe1                	j	800015b4 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	ca4d                	beqz	a2,80001690 <uvmcopy+0xb2>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8aaa                	mv	s5,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4481                	li	s1,0
    800015fe:	a029                	j	80001608 <uvmcopy+0x2a>
    80001600:	6785                	lui	a5,0x1
    80001602:	94be                	add	s1,s1,a5
    80001604:	0744fa63          	bgeu	s1,s4,80001678 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    80001608:	4601                	li	a2,0
    8000160a:	85a6                	mv	a1,s1
    8000160c:	8556                	mv	a0,s5
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	9dc080e7          	jalr	-1572(ra) # 80000fea <walk>
    80001616:	d56d                	beqz	a0,80001600 <uvmcopy+0x22>
      continue;
      //panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001618:	6118                	ld	a4,0(a0)
    8000161a:	00177793          	andi	a5,a4,1
    8000161e:	d3ed                	beqz	a5,80001600 <uvmcopy+0x22>
      continue;
      //panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001620:	00a75593          	srli	a1,a4,0xa
    80001624:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001628:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	4e2080e7          	jalr	1250(ra) # 80000b0e <kalloc>
    80001634:	89aa                	mv	s3,a0
    80001636:	c515                	beqz	a0,80001662 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001638:	6605                	lui	a2,0x1
    8000163a:	85de                	mv	a1,s7
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	71a080e7          	jalr	1818(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001644:	874a                	mv	a4,s2
    80001646:	86ce                	mv	a3,s3
    80001648:	6605                	lui	a2,0x1
    8000164a:	85a6                	mv	a1,s1
    8000164c:	855a                	mv	a0,s6
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	ada080e7          	jalr	-1318(ra) # 80001128 <mappages>
    80001656:	d54d                	beqz	a0,80001600 <uvmcopy+0x22>
      kfree(mem);
    80001658:	854e                	mv	a0,s3
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	3b8080e7          	jalr	952(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001662:	4685                	li	a3,1
    80001664:	00c4d613          	srli	a2,s1,0xc
    80001668:	4581                	li	a1,0
    8000166a:	855a                	mv	a0,s6
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	c98080e7          	jalr	-872(ra) # 80001304 <uvmunmap>
  return -1;
    80001674:	557d                	li	a0,-1
    80001676:	a011                	j	8000167a <uvmcopy+0x9c>
  return 0;
    80001678:	4501                	li	a0,0
}
    8000167a:	60a6                	ld	ra,72(sp)
    8000167c:	6406                	ld	s0,64(sp)
    8000167e:	74e2                	ld	s1,56(sp)
    80001680:	7942                	ld	s2,48(sp)
    80001682:	79a2                	ld	s3,40(sp)
    80001684:	7a02                	ld	s4,32(sp)
    80001686:	6ae2                	ld	s5,24(sp)
    80001688:	6b42                	ld	s6,16(sp)
    8000168a:	6ba2                	ld	s7,8(sp)
    8000168c:	6161                	addi	sp,sp,80
    8000168e:	8082                	ret
  return 0;
    80001690:	4501                	li	a0,0
}
    80001692:	8082                	ret

0000000080001694 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001694:	1141                	addi	sp,sp,-16
    80001696:	e406                	sd	ra,8(sp)
    80001698:	e022                	sd	s0,0(sp)
    8000169a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000169c:	4601                	li	a2,0
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	94c080e7          	jalr	-1716(ra) # 80000fea <walk>
  if(pte == 0)
    800016a6:	c901                	beqz	a0,800016b6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016a8:	611c                	ld	a5,0(a0)
    800016aa:	9bbd                	andi	a5,a5,-17
    800016ac:	e11c                	sd	a5,0(a0)
}
    800016ae:	60a2                	ld	ra,8(sp)
    800016b0:	6402                	ld	s0,0(sp)
    800016b2:	0141                	addi	sp,sp,16
    800016b4:	8082                	ret
    panic("uvmclear");
    800016b6:	00007517          	auipc	a0,0x7
    800016ba:	a8a50513          	addi	a0,a0,-1398 # 80008140 <digits+0x110>
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	e84080e7          	jalr	-380(ra) # 80000542 <panic>

00000000800016c6 <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    800016c6:	715d                	addi	sp,sp,-80
    800016c8:	e486                	sd	ra,72(sp)
    800016ca:	e0a2                	sd	s0,64(sp)
    800016cc:	fc26                	sd	s1,56(sp)
    800016ce:	f84a                	sd	s2,48(sp)
    800016d0:	f44e                	sd	s3,40(sp)
    800016d2:	f052                	sd	s4,32(sp)
    800016d4:	ec56                	sd	s5,24(sp)
    800016d6:	e85a                	sd	s6,16(sp)
    800016d8:	e45e                	sd	s7,8(sp)
    800016da:	e062                	sd	s8,0(sp)
    800016dc:	0880                	addi	s0,sp,80
    800016de:	8b2a                	mv	s6,a0
    800016e0:	8c2e                	mv	s8,a1
    800016e2:	8a32                	mv	s4,a2
    800016e4:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(uvmshouldtouch(dstva))
    800016e6:	852e                	mv	a0,a1
    800016e8:	00001097          	auipc	ra,0x1
    800016ec:	1be080e7          	jalr	446(ra) # 800028a6 <uvmshouldtouch>
    800016f0:	e511                	bnez	a0,800016fc <copyout+0x36>
    uvmlazytouch(dstva);

  while(len > 0){
    800016f2:	04098e63          	beqz	s3,8000174e <copyout+0x88>
    va0 = PGROUNDDOWN(dstva);
    800016f6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016f8:	6a85                	lui	s5,0x1
    800016fa:	a805                	j	8000172a <copyout+0x64>
    uvmlazytouch(dstva);
    800016fc:	8562                	mv	a0,s8
    800016fe:	00001097          	auipc	ra,0x1
    80001702:	104080e7          	jalr	260(ra) # 80002802 <uvmlazytouch>
    80001706:	b7f5                	j	800016f2 <copyout+0x2c>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001708:	9562                	add	a0,a0,s8
    8000170a:	0004861b          	sext.w	a2,s1
    8000170e:	85d2                	mv	a1,s4
    80001710:	41250533          	sub	a0,a0,s2
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	642080e7          	jalr	1602(ra) # 80000d56 <memmove>

    len -= n;
    8000171c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001720:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001722:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001726:	02098263          	beqz	s3,8000174a <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    8000172a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000172e:	85ca                	mv	a1,s2
    80001730:	855a                	mv	a0,s6
    80001732:	00000097          	auipc	ra,0x0
    80001736:	95e080e7          	jalr	-1698(ra) # 80001090 <walkaddr>
    if(pa0 == 0)
    8000173a:	cd01                	beqz	a0,80001752 <copyout+0x8c>
    n = PGSIZE - (dstva - va0);
    8000173c:	418904b3          	sub	s1,s2,s8
    80001740:	94d6                	add	s1,s1,s5
    if(n > len)
    80001742:	fc99f3e3          	bgeu	s3,s1,80001708 <copyout+0x42>
    80001746:	84ce                	mv	s1,s3
    80001748:	b7c1                	j	80001708 <copyout+0x42>
  }
  return 0;
    8000174a:	4501                	li	a0,0
    8000174c:	a021                	j	80001754 <copyout+0x8e>
    8000174e:	4501                	li	a0,0
    80001750:	a011                	j	80001754 <copyout+0x8e>
      return -1;
    80001752:	557d                	li	a0,-1
}
    80001754:	60a6                	ld	ra,72(sp)
    80001756:	6406                	ld	s0,64(sp)
    80001758:	74e2                	ld	s1,56(sp)
    8000175a:	7942                	ld	s2,48(sp)
    8000175c:	79a2                	ld	s3,40(sp)
    8000175e:	7a02                	ld	s4,32(sp)
    80001760:	6ae2                	ld	s5,24(sp)
    80001762:	6b42                	ld	s6,16(sp)
    80001764:	6ba2                	ld	s7,8(sp)
    80001766:	6c02                	ld	s8,0(sp)
    80001768:	6161                	addi	sp,sp,80
    8000176a:	8082                	ret

000000008000176c <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000176c:	7179                	addi	sp,sp,-48
    8000176e:	f406                	sd	ra,40(sp)
    80001770:	f022                	sd	s0,32(sp)
    80001772:	ec26                	sd	s1,24(sp)
    80001774:	e84a                	sd	s2,16(sp)
    80001776:	e44e                	sd	s3,8(sp)
    80001778:	e052                	sd	s4,0(sp)
    8000177a:	1800                	addi	s0,sp,48
    8000177c:	892a                	mv	s2,a0
    8000177e:	89ae                	mv	s3,a1
    80001780:	84b2                	mv	s1,a2
    80001782:	8a36                	mv	s4,a3
  int i = uvmshouldtouch(srcva);
    80001784:	8532                	mv	a0,a2
    80001786:	00001097          	auipc	ra,0x1
    8000178a:	120080e7          	jalr	288(ra) # 800028a6 <uvmshouldtouch>
  if(i){
    8000178e:	e10d                	bnez	a0,800017b0 <copyin+0x44>
    uvmlazytouch(srcva);
  }

  return copyin_new(pagetable, dst, srcva, len);
    80001790:	86d2                	mv	a3,s4
    80001792:	8626                	mv	a2,s1
    80001794:	85ce                	mv	a1,s3
    80001796:	854a                	mv	a0,s2
    80001798:	00005097          	auipc	ra,0x5
    8000179c:	e32080e7          	jalr	-462(ra) # 800065ca <copyin_new>
}
    800017a0:	70a2                	ld	ra,40(sp)
    800017a2:	7402                	ld	s0,32(sp)
    800017a4:	64e2                	ld	s1,24(sp)
    800017a6:	6942                	ld	s2,16(sp)
    800017a8:	69a2                	ld	s3,8(sp)
    800017aa:	6a02                	ld	s4,0(sp)
    800017ac:	6145                	addi	sp,sp,48
    800017ae:	8082                	ret
    uvmlazytouch(srcva);
    800017b0:	8526                	mv	a0,s1
    800017b2:	00001097          	auipc	ra,0x1
    800017b6:	050080e7          	jalr	80(ra) # 80002802 <uvmlazytouch>
    800017ba:	bfd9                	j	80001790 <copyin+0x24>

00000000800017bc <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800017bc:	7179                	addi	sp,sp,-48
    800017be:	f406                	sd	ra,40(sp)
    800017c0:	f022                	sd	s0,32(sp)
    800017c2:	ec26                	sd	s1,24(sp)
    800017c4:	e84a                	sd	s2,16(sp)
    800017c6:	e44e                	sd	s3,8(sp)
    800017c8:	e052                	sd	s4,0(sp)
    800017ca:	1800                	addi	s0,sp,48
    800017cc:	892a                	mv	s2,a0
    800017ce:	89ae                	mv	s3,a1
    800017d0:	84b2                	mv	s1,a2
    800017d2:	8a36                	mv	s4,a3
  if(uvmshouldtouch(srcva)){
    800017d4:	8532                	mv	a0,a2
    800017d6:	00001097          	auipc	ra,0x1
    800017da:	0d0080e7          	jalr	208(ra) # 800028a6 <uvmshouldtouch>
    800017de:	e10d                	bnez	a0,80001800 <copyinstr+0x44>
    uvmlazytouch(srcva);
  }
    
  return copyinstr_new(pagetable, dst, srcva, max);
    800017e0:	86d2                	mv	a3,s4
    800017e2:	8626                	mv	a2,s1
    800017e4:	85ce                	mv	a1,s3
    800017e6:	854a                	mv	a0,s2
    800017e8:	00005097          	auipc	ra,0x5
    800017ec:	e4a080e7          	jalr	-438(ra) # 80006632 <copyinstr_new>
}
    800017f0:	70a2                	ld	ra,40(sp)
    800017f2:	7402                	ld	s0,32(sp)
    800017f4:	64e2                	ld	s1,24(sp)
    800017f6:	6942                	ld	s2,16(sp)
    800017f8:	69a2                	ld	s3,8(sp)
    800017fa:	6a02                	ld	s4,0(sp)
    800017fc:	6145                	addi	sp,sp,48
    800017fe:	8082                	ret
    uvmlazytouch(srcva);
    80001800:	8526                	mv	a0,s1
    80001802:	00001097          	auipc	ra,0x1
    80001806:	000080e7          	jalr	ra # 80002802 <uvmlazytouch>
    8000180a:	bfd9                	j	800017e0 <copyinstr+0x24>

000000008000180c <pgtblprint>:

int pgtblprint(pagetable_t pagetable, int depth) {
    8000180c:	7159                	addi	sp,sp,-112
    8000180e:	f486                	sd	ra,104(sp)
    80001810:	f0a2                	sd	s0,96(sp)
    80001812:	eca6                	sd	s1,88(sp)
    80001814:	e8ca                	sd	s2,80(sp)
    80001816:	e4ce                	sd	s3,72(sp)
    80001818:	e0d2                	sd	s4,64(sp)
    8000181a:	fc56                	sd	s5,56(sp)
    8000181c:	f85a                	sd	s6,48(sp)
    8000181e:	f45e                	sd	s7,40(sp)
    80001820:	f062                	sd	s8,32(sp)
    80001822:	ec66                	sd	s9,24(sp)
    80001824:	e86a                	sd	s10,16(sp)
    80001826:	e46e                	sd	s11,8(sp)
    80001828:	1880                	addi	s0,sp,112
    8000182a:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000182c:	89aa                	mv	s3,a0
    8000182e:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) { // 如果页表项有效
      // 按格式打印页表项
      printf("..");
    80001830:	00007c97          	auipc	s9,0x7
    80001834:	920c8c93          	addi	s9,s9,-1760 # 80008150 <digits+0x120>
      for(int j=0;j<depth;j++) {
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001838:	00007c17          	auipc	s8,0x7
    8000183c:	928c0c13          	addi	s8,s8,-1752 # 80008160 <digits+0x130>

      // 如果该节点不是叶节点，递归打印其子节点。
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
        // this PTE points to a lower-level page table.
        uint64 child = PTE2PA(pte);
        pgtblprint((pagetable_t)child,depth+1);
    80001840:	00158d9b          	addiw	s11,a1,1
      for(int j=0;j<depth;j++) {
    80001844:	4d01                	li	s10,0
        printf(" ..");
    80001846:	00007b17          	auipc	s6,0x7
    8000184a:	912b0b13          	addi	s6,s6,-1774 # 80008158 <digits+0x128>
  for(int i = 0; i < 512; i++){
    8000184e:	20000b93          	li	s7,512
    80001852:	a029                	j	8000185c <pgtblprint+0x50>
    80001854:	2905                	addiw	s2,s2,1
    80001856:	09a1                	addi	s3,s3,8
    80001858:	05790d63          	beq	s2,s7,800018b2 <pgtblprint+0xa6>
    pte_t pte = pagetable[i];
    8000185c:	0009ba03          	ld	s4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if(pte & PTE_V) { // 如果页表项有效
    80001860:	001a7793          	andi	a5,s4,1
    80001864:	dbe5                	beqz	a5,80001854 <pgtblprint+0x48>
      printf("..");
    80001866:	8566                	mv	a0,s9
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	d24080e7          	jalr	-732(ra) # 8000058c <printf>
      for(int j=0;j<depth;j++) {
    80001870:	01505b63          	blez	s5,80001886 <pgtblprint+0x7a>
    80001874:	84ea                	mv	s1,s10
        printf(" ..");
    80001876:	855a                	mv	a0,s6
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	d14080e7          	jalr	-748(ra) # 8000058c <printf>
      for(int j=0;j<depth;j++) {
    80001880:	2485                	addiw	s1,s1,1
    80001882:	fe9a9ae3          	bne	s5,s1,80001876 <pgtblprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001886:	00aa5493          	srli	s1,s4,0xa
    8000188a:	04b2                	slli	s1,s1,0xc
    8000188c:	86a6                	mv	a3,s1
    8000188e:	8652                	mv	a2,s4
    80001890:	85ca                	mv	a1,s2
    80001892:	8562                	mv	a0,s8
    80001894:	fffff097          	auipc	ra,0xfffff
    80001898:	cf8080e7          	jalr	-776(ra) # 8000058c <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000189c:	00ea7a13          	andi	s4,s4,14
    800018a0:	fa0a1ae3          	bnez	s4,80001854 <pgtblprint+0x48>
        pgtblprint((pagetable_t)child,depth+1);
    800018a4:	85ee                	mv	a1,s11
    800018a6:	8526                	mv	a0,s1
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	f64080e7          	jalr	-156(ra) # 8000180c <pgtblprint>
    800018b0:	b755                	j	80001854 <pgtblprint+0x48>
      }
    }
  }
  return 0;
}
    800018b2:	4501                	li	a0,0
    800018b4:	70a6                	ld	ra,104(sp)
    800018b6:	7406                	ld	s0,96(sp)
    800018b8:	64e6                	ld	s1,88(sp)
    800018ba:	6946                	ld	s2,80(sp)
    800018bc:	69a6                	ld	s3,72(sp)
    800018be:	6a06                	ld	s4,64(sp)
    800018c0:	7ae2                	ld	s5,56(sp)
    800018c2:	7b42                	ld	s6,48(sp)
    800018c4:	7ba2                	ld	s7,40(sp)
    800018c6:	7c02                	ld	s8,32(sp)
    800018c8:	6ce2                	ld	s9,24(sp)
    800018ca:	6d42                	ld	s10,16(sp)
    800018cc:	6da2                	ld	s11,8(sp)
    800018ce:	6165                	addi	sp,sp,112
    800018d0:	8082                	ret

00000000800018d2 <vmprint>:

int vmprint(pagetable_t pagetable) {
    800018d2:	1101                	addi	sp,sp,-32
    800018d4:	ec06                	sd	ra,24(sp)
    800018d6:	e822                	sd	s0,16(sp)
    800018d8:	e426                	sd	s1,8(sp)
    800018da:	1000                	addi	s0,sp,32
    800018dc:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800018de:	85aa                	mv	a1,a0
    800018e0:	00007517          	auipc	a0,0x7
    800018e4:	89850513          	addi	a0,a0,-1896 # 80008178 <digits+0x148>
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	ca4080e7          	jalr	-860(ra) # 8000058c <printf>
  return pgtblprint(pagetable, 0);
    800018f0:	4581                	li	a1,0
    800018f2:	8526                	mv	a0,s1
    800018f4:	00000097          	auipc	ra,0x0
    800018f8:	f18080e7          	jalr	-232(ra) # 8000180c <pgtblprint>
}
    800018fc:	60e2                	ld	ra,24(sp)
    800018fe:	6442                	ld	s0,16(sp)
    80001900:	64a2                	ld	s1,8(sp)
    80001902:	6105                	addi	sp,sp,32
    80001904:	8082                	ret

0000000080001906 <kvm_free_kernelpgtbl>:

// 递归释放一个内核页表中的所有 mapping，但是不释放其指向的物理页
void
kvm_free_kernelpgtbl(pagetable_t pagetable)
{
    80001906:	7179                	addi	sp,sp,-48
    80001908:	f406                	sd	ra,40(sp)
    8000190a:	f022                	sd	s0,32(sp)
    8000190c:	ec26                	sd	s1,24(sp)
    8000190e:	e84a                	sd	s2,16(sp)
    80001910:	e44e                	sd	s3,8(sp)
    80001912:	e052                	sd	s4,0(sp)
    80001914:	1800                	addi	s0,sp,48
    80001916:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001918:	84aa                	mv	s1,a0
    8000191a:	6905                	lui	s2,0x1
    8000191c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    uint64 child = PTE2PA(pte);
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    8000191e:	4985                	li	s3,1
    80001920:	a021                	j	80001928 <kvm_free_kernelpgtbl+0x22>
  for(int i = 0; i < 512; i++){
    80001922:	04a1                	addi	s1,s1,8
    80001924:	03248063          	beq	s1,s2,80001944 <kvm_free_kernelpgtbl+0x3e>
    pte_t pte = pagetable[i];
    80001928:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    8000192a:	00f57793          	andi	a5,a0,15
    8000192e:	ff379ae3          	bne	a5,s3,80001922 <kvm_free_kernelpgtbl+0x1c>
    uint64 child = PTE2PA(pte);
    80001932:	8129                	srli	a0,a0,0xa
      // 递归释放低一级页表及其页表项
      kvm_free_kernelpgtbl((pagetable_t)child);
    80001934:	0532                	slli	a0,a0,0xc
    80001936:	00000097          	auipc	ra,0x0
    8000193a:	fd0080e7          	jalr	-48(ra) # 80001906 <kvm_free_kernelpgtbl>
      pagetable[i] = 0;
    8000193e:	0004b023          	sd	zero,0(s1)
    80001942:	b7c5                	j	80001922 <kvm_free_kernelpgtbl+0x1c>
    }
  }
  kfree((void*)pagetable); // 释放当前级别页表所占用空间
    80001944:	8552                	mv	a0,s4
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	0cc080e7          	jalr	204(ra) # 80000a12 <kfree>
}
    8000194e:	70a2                	ld	ra,40(sp)
    80001950:	7402                	ld	s0,32(sp)
    80001952:	64e2                	ld	s1,24(sp)
    80001954:	6942                	ld	s2,16(sp)
    80001956:	69a2                	ld	s3,8(sp)
    80001958:	6a02                	ld	s4,0(sp)
    8000195a:	6145                	addi	sp,sp,48
    8000195c:	8082                	ret

000000008000195e <kvmcopymappings>:
// 将用户页表的一部分页映射关系拷贝到内核页表中。
// 只拷贝页表项，不拷贝实际的物理页内存。
// 成功返回0，失败返回 -1
int
kvmcopymappings(pagetable_t pagetable, pagetable_t kpagetable, uint64 oldsz, uint64 len)
{
    8000195e:	7139                	addi	sp,sp,-64
    80001960:	fc06                	sd	ra,56(sp)
    80001962:	f822                	sd	s0,48(sp)
    80001964:	f426                	sd	s1,40(sp)
    80001966:	f04a                	sd	s2,32(sp)
    80001968:	ec4e                	sd	s3,24(sp)
    8000196a:	e852                	sd	s4,16(sp)
    8000196c:	e456                	sd	s5,8(sp)
    8000196e:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  // PGROUNDUP: prevent re-mapping already mapped pages (eg. when doing growproc)
  for(i = PGROUNDUP(oldsz); i < oldsz + len; i += PGSIZE){
    80001970:	6a05                	lui	s4,0x1
    80001972:	1a7d                	addi	s4,s4,-1
    80001974:	9a32                	add	s4,s4,a2
    80001976:	77fd                	lui	a5,0xfffff
    80001978:	00fa7a33          	and	s4,s4,a5
    8000197c:	00d60933          	add	s2,a2,a3
    80001980:	092a7763          	bgeu	s4,s2,80001a0e <kvmcopymappings+0xb0>
    80001984:	8aaa                	mv	s5,a0
    80001986:	89ae                	mv	s3,a1
    80001988:	84d2                	mv	s1,s4
    if((pte = walk(pagetable, i, 0)) == 0)
    8000198a:	4601                	li	a2,0
    8000198c:	85a6                	mv	a1,s1
    8000198e:	8556                	mv	a0,s5
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	65a080e7          	jalr	1626(ra) # 80000fea <walk>
    80001998:	c51d                	beqz	a0,800019c6 <kvmcopymappings+0x68>
      panic("kvmcopymappings: pte should exist");
    if((*pte & PTE_V) == 0)
    8000199a:	6118                	ld	a4,0(a0)
    8000199c:	00177793          	andi	a5,a4,1
    800019a0:	cb9d                	beqz	a5,800019d6 <kvmcopymappings+0x78>
      panic("kvmcopymappings: page not present");
      
    pa = PTE2PA(*pte);
    800019a2:	00a75693          	srli	a3,a4,0xa
    // `& ~PTE_U` 表示将该页的权限设置为非用户页 
    // 必须设置该权限，RISC-V 中内核是无法直接访问用户页的。
    flags = PTE_FLAGS(*pte) & ~PTE_U;
    if(mappages(kpagetable, i, PGSIZE, pa, flags) != 0){
    800019a6:	3ef77713          	andi	a4,a4,1007
    800019aa:	06b2                	slli	a3,a3,0xc
    800019ac:	6605                	lui	a2,0x1
    800019ae:	85a6                	mv	a1,s1
    800019b0:	854e                	mv	a0,s3
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	776080e7          	jalr	1910(ra) # 80001128 <mappages>
    800019ba:	e515                	bnez	a0,800019e6 <kvmcopymappings+0x88>
  for(i = PGROUNDUP(oldsz); i < oldsz + len; i += PGSIZE){
    800019bc:	6785                	lui	a5,0x1
    800019be:	94be                	add	s1,s1,a5
    800019c0:	fd24e5e3          	bltu	s1,s2,8000198a <kvmcopymappings+0x2c>
    800019c4:	a825                	j	800019fc <kvmcopymappings+0x9e>
      panic("kvmcopymappings: pte should exist");
    800019c6:	00006517          	auipc	a0,0x6
    800019ca:	7c250513          	addi	a0,a0,1986 # 80008188 <digits+0x158>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	b74080e7          	jalr	-1164(ra) # 80000542 <panic>
      panic("kvmcopymappings: page not present");
    800019d6:	00006517          	auipc	a0,0x6
    800019da:	7da50513          	addi	a0,a0,2010 # 800081b0 <digits+0x180>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	b64080e7          	jalr	-1180(ra) # 80000542 <panic>
  return 0;

 err:
  // thanks @hdrkna for pointing out a mistake here.
  // original code incorrectly starts unmapping from 0 instead of PGROUNDUP(oldsz)
  uvmunmap(kpagetable, PGROUNDUP(oldsz), (i - PGROUNDUP(oldsz)) / PGSIZE, 0);
    800019e6:	41448633          	sub	a2,s1,s4
    800019ea:	4681                	li	a3,0
    800019ec:	8231                	srli	a2,a2,0xc
    800019ee:	85d2                	mv	a1,s4
    800019f0:	854e                	mv	a0,s3
    800019f2:	00000097          	auipc	ra,0x0
    800019f6:	912080e7          	jalr	-1774(ra) # 80001304 <uvmunmap>
  return -1;
    800019fa:	557d                	li	a0,-1
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6121                	addi	sp,sp,64
    80001a0c:	8082                	ret
  return 0;
    80001a0e:	4501                	li	a0,0
    80001a10:	b7f5                	j	800019fc <kvmcopymappings+0x9e>

0000000080001a12 <kvmdealloc>:

// 与 uvmdealloc 功能类似，将程序内存从 oldsz 缩减到 newsz。但区别在于不释放实际内存
// 用于内核页表内程序内存映射与用户页表程序内存映射之间的同步
uint64
kvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001a12:	1101                	addi	sp,sp,-32
    80001a14:	ec06                	sd	ra,24(sp)
    80001a16:	e822                	sd	s0,16(sp)
    80001a18:	e426                	sd	s1,8(sp)
    80001a1a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001a1c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001a1e:	00b67d63          	bgeu	a2,a1,80001a38 <kvmdealloc+0x26>
    80001a22:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001a24:	6785                	lui	a5,0x1
    80001a26:	17fd                	addi	a5,a5,-1
    80001a28:	00f60733          	add	a4,a2,a5
    80001a2c:	767d                	lui	a2,0xfffff
    80001a2e:	8f71                	and	a4,a4,a2
    80001a30:	97ae                	add	a5,a5,a1
    80001a32:	8ff1                	and	a5,a5,a2
    80001a34:	00f76863          	bltu	a4,a5,80001a44 <kvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE; //要删掉的页表大小
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
  }

  return newsz;
    80001a38:	8526                	mv	a0,s1
    80001a3a:	60e2                	ld	ra,24(sp)
    80001a3c:	6442                	ld	s0,16(sp)
    80001a3e:	64a2                	ld	s1,8(sp)
    80001a40:	6105                	addi	sp,sp,32
    80001a42:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE; //要删掉的页表大小
    80001a44:	8f99                	sub	a5,a5,a4
    80001a46:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
    80001a48:	4681                	li	a3,0
    80001a4a:	0007861b          	sext.w	a2,a5
    80001a4e:	85ba                	mv	a1,a4
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b4080e7          	jalr	-1868(ra) # 80001304 <uvmunmap>
    80001a58:	b7c5                	j	80001a38 <kvmdealloc+0x26>

0000000080001a5a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	11e080e7          	jalr	286(ra) # 80000b84 <holding>
    80001a6e:	c909                	beqz	a0,80001a80 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a70:	749c                	ld	a5,40(s1)
    80001a72:	00978f63          	beq	a5,s1,80001a90 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a76:	60e2                	ld	ra,24(sp)
    80001a78:	6442                	ld	s0,16(sp)
    80001a7a:	64a2                	ld	s1,8(sp)
    80001a7c:	6105                	addi	sp,sp,32
    80001a7e:	8082                	ret
    panic("wakeup1");
    80001a80:	00006517          	auipc	a0,0x6
    80001a84:	75850513          	addi	a0,a0,1880 # 800081d8 <digits+0x1a8>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	aba080e7          	jalr	-1350(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a90:	4c98                	lw	a4,24(s1)
    80001a92:	4785                	li	a5,1
    80001a94:	fef711e3          	bne	a4,a5,80001a76 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a98:	4789                	li	a5,2
    80001a9a:	cc9c                	sw	a5,24(s1)
}
    80001a9c:	bfe9                	j	80001a76 <wakeup1+0x1c>

0000000080001a9e <procinit>:
{
    80001a9e:	7179                	addi	sp,sp,-48
    80001aa0:	f406                	sd	ra,40(sp)
    80001aa2:	f022                	sd	s0,32(sp)
    80001aa4:	ec26                	sd	s1,24(sp)
    80001aa6:	e84a                	sd	s2,16(sp)
    80001aa8:	e44e                	sd	s3,8(sp)
    80001aaa:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001aac:	00006597          	auipc	a1,0x6
    80001ab0:	73458593          	addi	a1,a1,1844 # 800081e0 <digits+0x1b0>
    80001ab4:	00010517          	auipc	a0,0x10
    80001ab8:	e9c50513          	addi	a0,a0,-356 # 80011950 <pid_lock>
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	0b2080e7          	jalr	178(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ac4:	00010497          	auipc	s1,0x10
    80001ac8:	2a448493          	addi	s1,s1,676 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001acc:	00006997          	auipc	s3,0x6
    80001ad0:	71c98993          	addi	s3,s3,1820 # 800081e8 <digits+0x1b8>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad4:	00016917          	auipc	s2,0x16
    80001ad8:	09490913          	addi	s2,s2,148 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001adc:	85ce                	mv	a1,s3
    80001ade:	8526                	mv	a0,s1
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	08e080e7          	jalr	142(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae8:	17848493          	addi	s1,s1,376
    80001aec:	ff2498e3          	bne	s1,s2,80001adc <procinit+0x3e>
  kvminithart();
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	4d6080e7          	jalr	1238(ra) # 80000fc6 <kvminithart>
}
    80001af8:	70a2                	ld	ra,40(sp)
    80001afa:	7402                	ld	s0,32(sp)
    80001afc:	64e2                	ld	s1,24(sp)
    80001afe:	6942                	ld	s2,16(sp)
    80001b00:	69a2                	ld	s3,8(sp)
    80001b02:	6145                	addi	sp,sp,48
    80001b04:	8082                	ret

0000000080001b06 <cpuid>:
{
    80001b06:	1141                	addi	sp,sp,-16
    80001b08:	e422                	sd	s0,8(sp)
    80001b0a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b0c:	8512                	mv	a0,tp
}
    80001b0e:	2501                	sext.w	a0,a0
    80001b10:	6422                	ld	s0,8(sp)
    80001b12:	0141                	addi	sp,sp,16
    80001b14:	8082                	ret

0000000080001b16 <mycpu>:
mycpu(void) {
    80001b16:	1141                	addi	sp,sp,-16
    80001b18:	e422                	sd	s0,8(sp)
    80001b1a:	0800                	addi	s0,sp,16
    80001b1c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b1e:	2781                	sext.w	a5,a5
    80001b20:	079e                	slli	a5,a5,0x7
}
    80001b22:	00010517          	auipc	a0,0x10
    80001b26:	e4650513          	addi	a0,a0,-442 # 80011968 <cpus>
    80001b2a:	953e                	add	a0,a0,a5
    80001b2c:	6422                	ld	s0,8(sp)
    80001b2e:	0141                	addi	sp,sp,16
    80001b30:	8082                	ret

0000000080001b32 <myproc>:
myproc(void) {
    80001b32:	1101                	addi	sp,sp,-32
    80001b34:	ec06                	sd	ra,24(sp)
    80001b36:	e822                	sd	s0,16(sp)
    80001b38:	e426                	sd	s1,8(sp)
    80001b3a:	1000                	addi	s0,sp,32
  push_off();
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	076080e7          	jalr	118(ra) # 80000bb2 <push_off>
    80001b44:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b46:	2781                	sext.w	a5,a5
    80001b48:	079e                	slli	a5,a5,0x7
    80001b4a:	00010717          	auipc	a4,0x10
    80001b4e:	e0670713          	addi	a4,a4,-506 # 80011950 <pid_lock>
    80001b52:	97ba                	add	a5,a5,a4
    80001b54:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	0fc080e7          	jalr	252(ra) # 80000c52 <pop_off>
}
    80001b5e:	8526                	mv	a0,s1
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret

0000000080001b6a <forkret>:
{
    80001b6a:	1141                	addi	sp,sp,-16
    80001b6c:	e406                	sd	ra,8(sp)
    80001b6e:	e022                	sd	s0,0(sp)
    80001b70:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	fc0080e7          	jalr	-64(ra) # 80001b32 <myproc>
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	138080e7          	jalr	312(ra) # 80000cb2 <release>
  if (first) {
    80001b82:	00007797          	auipc	a5,0x7
    80001b86:	d1e7a783          	lw	a5,-738(a5) # 800088a0 <first.1>
    80001b8a:	eb89                	bnez	a5,80001b9c <forkret+0x32>
  usertrapret();
    80001b8c:	00001097          	auipc	ra,0x1
    80001b90:	e16080e7          	jalr	-490(ra) # 800029a2 <usertrapret>
}
    80001b94:	60a2                	ld	ra,8(sp)
    80001b96:	6402                	ld	s0,0(sp)
    80001b98:	0141                	addi	sp,sp,16
    80001b9a:	8082                	ret
    first = 0;
    80001b9c:	00007797          	auipc	a5,0x7
    80001ba0:	d007a223          	sw	zero,-764(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001ba4:	4505                	li	a0,1
    80001ba6:	00002097          	auipc	ra,0x2
    80001baa:	ba0080e7          	jalr	-1120(ra) # 80003746 <fsinit>
    80001bae:	bff9                	j	80001b8c <forkret+0x22>

0000000080001bb0 <allocpid>:
allocpid() {
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bbc:	00010917          	auipc	s2,0x10
    80001bc0:	d9490913          	addi	s2,s2,-620 # 80011950 <pid_lock>
    80001bc4:	854a                	mv	a0,s2
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	038080e7          	jalr	56(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001bce:	00007797          	auipc	a5,0x7
    80001bd2:	cd678793          	addi	a5,a5,-810 # 800088a4 <nextpid>
    80001bd6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bd8:	0014871b          	addiw	a4,s1,1
    80001bdc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bde:	854a                	mv	a0,s2
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	0d2080e7          	jalr	210(ra) # 80000cb2 <release>
}
    80001be8:	8526                	mv	a0,s1
    80001bea:	60e2                	ld	ra,24(sp)
    80001bec:	6442                	ld	s0,16(sp)
    80001bee:	64a2                	ld	s1,8(sp)
    80001bf0:	6902                	ld	s2,0(sp)
    80001bf2:	6105                	addi	sp,sp,32
    80001bf4:	8082                	ret

0000000080001bf6 <proc_pagetable>:
{
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	e04a                	sd	s2,0(sp)
    80001c00:	1000                	addi	s0,sp,32
    80001c02:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	7a6080e7          	jalr	1958(ra) # 800013aa <uvmcreate>
    80001c0c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c0e:	c121                	beqz	a0,80001c4e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c10:	4729                	li	a4,10
    80001c12:	00005697          	auipc	a3,0x5
    80001c16:	3ee68693          	addi	a3,a3,1006 # 80007000 <_trampoline>
    80001c1a:	6605                	lui	a2,0x1
    80001c1c:	040005b7          	lui	a1,0x4000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b2                	slli	a1,a1,0xc
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	504080e7          	jalr	1284(ra) # 80001128 <mappages>
    80001c2c:	02054863          	bltz	a0,80001c5c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c30:	4719                	li	a4,6
    80001c32:	06893683          	ld	a3,104(s2)
    80001c36:	6605                	lui	a2,0x1
    80001c38:	020005b7          	lui	a1,0x2000
    80001c3c:	15fd                	addi	a1,a1,-1
    80001c3e:	05b6                	slli	a1,a1,0xd
    80001c40:	8526                	mv	a0,s1
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	4e6080e7          	jalr	1254(ra) # 80001128 <mappages>
    80001c4a:	02054163          	bltz	a0,80001c6c <proc_pagetable+0x76>
}
    80001c4e:	8526                	mv	a0,s1
    80001c50:	60e2                	ld	ra,24(sp)
    80001c52:	6442                	ld	s0,16(sp)
    80001c54:	64a2                	ld	s1,8(sp)
    80001c56:	6902                	ld	s2,0(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c5c:	4581                	li	a1,0
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	946080e7          	jalr	-1722(ra) # 800015a6 <uvmfree>
    return 0;
    80001c68:	4481                	li	s1,0
    80001c6a:	b7d5                	j	80001c4e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4605                	li	a2,1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	68a080e7          	jalr	1674(ra) # 80001304 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c82:	4581                	li	a1,0
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	920080e7          	jalr	-1760(ra) # 800015a6 <uvmfree>
    return 0;
    80001c8e:	4481                	li	s1,0
    80001c90:	bf7d                	j	80001c4e <proc_pagetable+0x58>

0000000080001c92 <proc_freepagetable>:
{
    80001c92:	1101                	addi	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	e04a                	sd	s2,0(sp)
    80001c9c:	1000                	addi	s0,sp,32
    80001c9e:	84aa                	mv	s1,a0
    80001ca0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca2:	4681                	li	a3,0
    80001ca4:	4605                	li	a2,1
    80001ca6:	040005b7          	lui	a1,0x4000
    80001caa:	15fd                	addi	a1,a1,-1
    80001cac:	05b2                	slli	a1,a1,0xc
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	656080e7          	jalr	1622(ra) # 80001304 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cb6:	4681                	li	a3,0
    80001cb8:	4605                	li	a2,1
    80001cba:	020005b7          	lui	a1,0x2000
    80001cbe:	15fd                	addi	a1,a1,-1
    80001cc0:	05b6                	slli	a1,a1,0xd
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	640080e7          	jalr	1600(ra) # 80001304 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ccc:	85ca                	mv	a1,s2
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	8d6080e7          	jalr	-1834(ra) # 800015a6 <uvmfree>
}
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6902                	ld	s2,0(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret

0000000080001ce4 <freeproc>:
{
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	1000                	addi	s0,sp,32
    80001cee:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cf0:	7528                	ld	a0,104(a0)
    80001cf2:	c509                	beqz	a0,80001cfc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	d1e080e7          	jalr	-738(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001cfc:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001d00:	6ca8                	ld	a0,88(s1)
    80001d02:	c511                	beqz	a0,80001d0e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d04:	64ac                	ld	a1,72(s1)
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	f8c080e7          	jalr	-116(ra) # 80001c92 <proc_freepagetable>
  p->pagetable = 0;
    80001d0e:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001d12:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d16:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d1a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d1e:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001d22:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d26:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d2a:	0204aa23          	sw	zero,52(s1)
  void *kstack_pa = (void *)kvmpa(p->kpagetable, p->kstack);
    80001d2e:	60ac                	ld	a1,64(s1)
    80001d30:	70a8                	ld	a0,96(s1)
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	3a0080e7          	jalr	928(ra) # 800010d2 <kvmpa>
  kfree(kstack_pa);
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	cd8080e7          	jalr	-808(ra) # 80000a12 <kfree>
  p->kstack = 0;
    80001d42:	0404b023          	sd	zero,64(s1)
  kvm_free_kernelpgtbl(p->kpagetable);
    80001d46:	70a8                	ld	a0,96(s1)
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	bbe080e7          	jalr	-1090(ra) # 80001906 <kvm_free_kernelpgtbl>
  p->kpagetable = 0;
    80001d50:	0604b023          	sd	zero,96(s1)
  p->state = UNUSED;
    80001d54:	0004ac23          	sw	zero,24(s1)
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret

0000000080001d62 <allocproc>:
{
    80001d62:	1101                	addi	sp,sp,-32
    80001d64:	ec06                	sd	ra,24(sp)
    80001d66:	e822                	sd	s0,16(sp)
    80001d68:	e426                	sd	s1,8(sp)
    80001d6a:	e04a                	sd	s2,0(sp)
    80001d6c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d6e:	00010497          	auipc	s1,0x10
    80001d72:	ffa48493          	addi	s1,s1,-6 # 80011d68 <proc>
    80001d76:	00016917          	auipc	s2,0x16
    80001d7a:	df290913          	addi	s2,s2,-526 # 80017b68 <tickslock>
    acquire(&p->lock);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	e7e080e7          	jalr	-386(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001d88:	4c9c                	lw	a5,24(s1)
    80001d8a:	cf81                	beqz	a5,80001da2 <allocproc+0x40>
      release(&p->lock);
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	f24080e7          	jalr	-220(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d96:	17848493          	addi	s1,s1,376
    80001d9a:	ff2492e3          	bne	s1,s2,80001d7e <allocproc+0x1c>
  return 0;
    80001d9e:	4481                	li	s1,0
    80001da0:	a049                	j	80001e22 <allocproc+0xc0>
  p->pid = allocpid();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	e0e080e7          	jalr	-498(ra) # 80001bb0 <allocpid>
    80001daa:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	d62080e7          	jalr	-670(ra) # 80000b0e <kalloc>
    80001db4:	892a                	mv	s2,a0
    80001db6:	f4a8                	sd	a0,104(s1)
    80001db8:	cd25                	beqz	a0,80001e30 <allocproc+0xce>
  p->pagetable = proc_pagetable(p);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e3a080e7          	jalr	-454(ra) # 80001bf6 <proc_pagetable>
    80001dc4:	892a                	mv	s2,a0
    80001dc6:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001dc8:	c93d                	beqz	a0,80001e3e <allocproc+0xdc>
  p->kpagetable = kvminit_newpgtbl();
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	4d0080e7          	jalr	1232(ra) # 8000129a <kvminit_newpgtbl>
    80001dd2:	f0a8                	sd	a0,96(s1)
  char *pa = kalloc();
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	d3a080e7          	jalr	-710(ra) # 80000b0e <kalloc>
    80001ddc:	862a                	mv	a2,a0
  if(pa == 0)
    80001dde:	cd25                	beqz	a0,80001e56 <allocproc+0xf4>
  kvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001de0:	4719                	li	a4,6
    80001de2:	6685                	lui	a3,0x1
    80001de4:	04000937          	lui	s2,0x4000
    80001de8:	1975                	addi	s2,s2,-3
    80001dea:	00c91593          	slli	a1,s2,0xc
    80001dee:	70a8                	ld	a0,96(s1)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	3c6080e7          	jalr	966(ra) # 800011b6 <kvmmap>
  p->kstack = va; // 记录内核栈的逻辑地址，其实已经是固定的了，依然这样记录是为了避免需要修改其他部分 xv6 代码
    80001df8:	0932                	slli	s2,s2,0xc
    80001dfa:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001dfe:	07000613          	li	a2,112
    80001e02:	4581                	li	a1,0
    80001e04:	07048513          	addi	a0,s1,112
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	ef2080e7          	jalr	-270(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001e10:	00000797          	auipc	a5,0x0
    80001e14:	d5a78793          	addi	a5,a5,-678 # 80001b6a <forkret>
    80001e18:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e1a:	60bc                	ld	a5,64(s1)
    80001e1c:	6705                	lui	a4,0x1
    80001e1e:	97ba                	add	a5,a5,a4
    80001e20:	fcbc                	sd	a5,120(s1)
}
    80001e22:	8526                	mv	a0,s1
    80001e24:	60e2                	ld	ra,24(sp)
    80001e26:	6442                	ld	s0,16(sp)
    80001e28:	64a2                	ld	s1,8(sp)
    80001e2a:	6902                	ld	s2,0(sp)
    80001e2c:	6105                	addi	sp,sp,32
    80001e2e:	8082                	ret
    release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e80080e7          	jalr	-384(ra) # 80000cb2 <release>
    return 0;
    80001e3a:	84ca                	mv	s1,s2
    80001e3c:	b7dd                	j	80001e22 <allocproc+0xc0>
    freeproc(p);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	ea4080e7          	jalr	-348(ra) # 80001ce4 <freeproc>
    release(&p->lock);
    80001e48:	8526                	mv	a0,s1
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e68080e7          	jalr	-408(ra) # 80000cb2 <release>
    return 0;
    80001e52:	84ca                	mv	s1,s2
    80001e54:	b7f9                	j	80001e22 <allocproc+0xc0>
    panic("kalloc");
    80001e56:	00006517          	auipc	a0,0x6
    80001e5a:	39a50513          	addi	a0,a0,922 # 800081f0 <digits+0x1c0>
    80001e5e:	ffffe097          	auipc	ra,0xffffe
    80001e62:	6e4080e7          	jalr	1764(ra) # 80000542 <panic>

0000000080001e66 <userinit>:
{
    80001e66:	1101                	addi	sp,sp,-32
    80001e68:	ec06                	sd	ra,24(sp)
    80001e6a:	e822                	sd	s0,16(sp)
    80001e6c:	e426                	sd	s1,8(sp)
    80001e6e:	e04a                	sd	s2,0(sp)
    80001e70:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	ef0080e7          	jalr	-272(ra) # 80001d62 <allocproc>
    80001e7a:	84aa                	mv	s1,a0
  initproc = p;
    80001e7c:	00007797          	auipc	a5,0x7
    80001e80:	18a7be23          	sd	a0,412(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e84:	03400613          	li	a2,52
    80001e88:	00007597          	auipc	a1,0x7
    80001e8c:	a2858593          	addi	a1,a1,-1496 # 800088b0 <initcode>
    80001e90:	6d28                	ld	a0,88(a0)
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	546080e7          	jalr	1350(ra) # 800013d8 <uvminit>
  p->sz = PGSIZE;
    80001e9a:	6905                	lui	s2,0x1
    80001e9c:	0524b423          	sd	s2,72(s1)
  kvmcopymappings(p->pagetable, p->kpagetable, 0, p->sz); // 同步程序内存映射到进程内核页表中
    80001ea0:	6685                	lui	a3,0x1
    80001ea2:	4601                	li	a2,0
    80001ea4:	70ac                	ld	a1,96(s1)
    80001ea6:	6ca8                	ld	a0,88(s1)
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	ab6080e7          	jalr	-1354(ra) # 8000195e <kvmcopymappings>
  p->trapframe->epc = 0;      // user program counter
    80001eb0:	74bc                	ld	a5,104(s1)
    80001eb2:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001eb6:	74bc                	ld	a5,104(s1)
    80001eb8:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ebc:	4641                	li	a2,16
    80001ebe:	00006597          	auipc	a1,0x6
    80001ec2:	33a58593          	addi	a1,a1,826 # 800081f8 <digits+0x1c8>
    80001ec6:	16848513          	addi	a0,s1,360
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	f82080e7          	jalr	-126(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001ed2:	00006517          	auipc	a0,0x6
    80001ed6:	33650513          	addi	a0,a0,822 # 80008208 <digits+0x1d8>
    80001eda:	00002097          	auipc	ra,0x2
    80001ede:	294080e7          	jalr	660(ra) # 8000416e <namei>
    80001ee2:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001ee6:	4789                	li	a5,2
    80001ee8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	dc6080e7          	jalr	-570(ra) # 80000cb2 <release>
}
    80001ef4:	60e2                	ld	ra,24(sp)
    80001ef6:	6442                	ld	s0,16(sp)
    80001ef8:	64a2                	ld	s1,8(sp)
    80001efa:	6902                	ld	s2,0(sp)
    80001efc:	6105                	addi	sp,sp,32
    80001efe:	8082                	ret

0000000080001f00 <growproc>:
{
    80001f00:	7179                	addi	sp,sp,-48
    80001f02:	f406                	sd	ra,40(sp)
    80001f04:	f022                	sd	s0,32(sp)
    80001f06:	ec26                	sd	s1,24(sp)
    80001f08:	e84a                	sd	s2,16(sp)
    80001f0a:	e44e                	sd	s3,8(sp)
    80001f0c:	e052                	sd	s4,0(sp)
    80001f0e:	1800                	addi	s0,sp,48
    80001f10:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	c20080e7          	jalr	-992(ra) # 80001b32 <myproc>
    80001f1a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f1c:	652c                	ld	a1,72(a0)
    80001f1e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f22:	03204363          	bgtz	s2,80001f48 <growproc+0x48>
  } else if(n < 0){
    80001f26:	06094563          	bltz	s2,80001f90 <growproc+0x90>
  p->sz = sz;
    80001f2a:	02061913          	slli	s2,a2,0x20
    80001f2e:	02095913          	srli	s2,s2,0x20
    80001f32:	0524b423          	sd	s2,72(s1)
  return 0;
    80001f36:	4501                	li	a0,0
}
    80001f38:	70a2                	ld	ra,40(sp)
    80001f3a:	7402                	ld	s0,32(sp)
    80001f3c:	64e2                	ld	s1,24(sp)
    80001f3e:	6942                	ld	s2,16(sp)
    80001f40:	69a2                	ld	s3,8(sp)
    80001f42:	6a02                	ld	s4,0(sp)
    80001f44:	6145                	addi	sp,sp,48
    80001f46:	8082                	ret
    if((newsz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f48:	02059993          	slli	s3,a1,0x20
    80001f4c:	0209d993          	srli	s3,s3,0x20
    80001f50:	00c9063b          	addw	a2,s2,a2
    80001f54:	1602                	slli	a2,a2,0x20
    80001f56:	9201                	srli	a2,a2,0x20
    80001f58:	85ce                	mv	a1,s3
    80001f5a:	6d28                	ld	a0,88(a0)
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	536080e7          	jalr	1334(ra) # 80001492 <uvmalloc>
    80001f64:	8a2a                	mv	s4,a0
    80001f66:	cd39                	beqz	a0,80001fc4 <growproc+0xc4>
    if(kvmcopymappings(p->pagetable, p->kpagetable, sz, n) != 0) {
    80001f68:	86ca                	mv	a3,s2
    80001f6a:	864e                	mv	a2,s3
    80001f6c:	70ac                	ld	a1,96(s1)
    80001f6e:	6ca8                	ld	a0,88(s1)
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	9ee080e7          	jalr	-1554(ra) # 8000195e <kvmcopymappings>
    sz = newsz;
    80001f78:	000a061b          	sext.w	a2,s4
    if(kvmcopymappings(p->pagetable, p->kpagetable, sz, n) != 0) {
    80001f7c:	d55d                	beqz	a0,80001f2a <growproc+0x2a>
      uvmdealloc(p->pagetable, newsz, sz);
    80001f7e:	864e                	mv	a2,s3
    80001f80:	85d2                	mv	a1,s4
    80001f82:	6ca8                	ld	a0,88(s1)
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	4c6080e7          	jalr	1222(ra) # 8000144a <uvmdealloc>
      return -1;
    80001f8c:	557d                	li	a0,-1
    80001f8e:	b76d                	j	80001f38 <growproc+0x38>
    uvmdealloc(p->pagetable, sz, sz + n);
    80001f90:	02059993          	slli	s3,a1,0x20
    80001f94:	0209d993          	srli	s3,s3,0x20
    80001f98:	00c9093b          	addw	s2,s2,a2
    80001f9c:	1902                	slli	s2,s2,0x20
    80001f9e:	02095913          	srli	s2,s2,0x20
    80001fa2:	864a                	mv	a2,s2
    80001fa4:	85ce                	mv	a1,s3
    80001fa6:	6d28                	ld	a0,88(a0)
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	4a2080e7          	jalr	1186(ra) # 8000144a <uvmdealloc>
    sz = kvmdealloc(p->kpagetable, sz, sz + n);
    80001fb0:	864a                	mv	a2,s2
    80001fb2:	85ce                	mv	a1,s3
    80001fb4:	70a8                	ld	a0,96(s1)
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	a5c080e7          	jalr	-1444(ra) # 80001a12 <kvmdealloc>
    80001fbe:	0005061b          	sext.w	a2,a0
    80001fc2:	b7a5                	j	80001f2a <growproc+0x2a>
      return -1;
    80001fc4:	557d                	li	a0,-1
    80001fc6:	bf8d                	j	80001f38 <growproc+0x38>

0000000080001fc8 <fork>:
{
    80001fc8:	7139                	addi	sp,sp,-64
    80001fca:	fc06                	sd	ra,56(sp)
    80001fcc:	f822                	sd	s0,48(sp)
    80001fce:	f426                	sd	s1,40(sp)
    80001fd0:	f04a                	sd	s2,32(sp)
    80001fd2:	ec4e                	sd	s3,24(sp)
    80001fd4:	e852                	sd	s4,16(sp)
    80001fd6:	e456                	sd	s5,8(sp)
    80001fd8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	b58080e7          	jalr	-1192(ra) # 80001b32 <myproc>
    80001fe2:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	d7e080e7          	jalr	-642(ra) # 80001d62 <allocproc>
    80001fec:	10050163          	beqz	a0,800020ee <fork+0x126>
    80001ff0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001ff2:	048ab603          	ld	a2,72(s5) # 1048 <_entry-0x7fffefb8>
    80001ff6:	6d2c                	ld	a1,88(a0)
    80001ff8:	058ab503          	ld	a0,88(s5)
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	5e2080e7          	jalr	1506(ra) # 800015de <uvmcopy>
    80002004:	06054763          	bltz	a0,80002072 <fork+0xaa>
    kvmcopymappings(np->pagetable, np->kpagetable, 0, p->sz) < 0){
    80002008:	048ab683          	ld	a3,72(s5)
    8000200c:	4601                	li	a2,0
    8000200e:	0609b583          	ld	a1,96(s3)
    80002012:	0589b503          	ld	a0,88(s3)
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	948080e7          	jalr	-1720(ra) # 8000195e <kvmcopymappings>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    8000201e:	04054a63          	bltz	a0,80002072 <fork+0xaa>
  np->sz = p->sz;
    80002022:	048ab783          	ld	a5,72(s5)
    80002026:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    8000202a:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    8000202e:	068ab683          	ld	a3,104(s5)
    80002032:	87b6                	mv	a5,a3
    80002034:	0689b703          	ld	a4,104(s3)
    80002038:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    8000203c:	0007b803          	ld	a6,0(a5)
    80002040:	6788                	ld	a0,8(a5)
    80002042:	6b8c                	ld	a1,16(a5)
    80002044:	6f90                	ld	a2,24(a5)
    80002046:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    8000204a:	e708                	sd	a0,8(a4)
    8000204c:	eb0c                	sd	a1,16(a4)
    8000204e:	ef10                	sd	a2,24(a4)
    80002050:	02078793          	addi	a5,a5,32
    80002054:	02070713          	addi	a4,a4,32
    80002058:	fed792e3          	bne	a5,a3,8000203c <fork+0x74>
  np->trapframe->a0 = 0;
    8000205c:	0689b783          	ld	a5,104(s3)
    80002060:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002064:	0e0a8493          	addi	s1,s5,224
    80002068:	0e098913          	addi	s2,s3,224
    8000206c:	160a8a13          	addi	s4,s5,352
    80002070:	a00d                	j	80002092 <fork+0xca>
    freeproc(np);
    80002072:	854e                	mv	a0,s3
    80002074:	00000097          	auipc	ra,0x0
    80002078:	c70080e7          	jalr	-912(ra) # 80001ce4 <freeproc>
    release(&np->lock);
    8000207c:	854e                	mv	a0,s3
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c34080e7          	jalr	-972(ra) # 80000cb2 <release>
    return -1;
    80002086:	54fd                	li	s1,-1
    80002088:	a889                	j	800020da <fork+0x112>
  for(i = 0; i < NOFILE; i++)
    8000208a:	04a1                	addi	s1,s1,8
    8000208c:	0921                	addi	s2,s2,8
    8000208e:	01448b63          	beq	s1,s4,800020a4 <fork+0xdc>
    if(p->ofile[i])
    80002092:	6088                	ld	a0,0(s1)
    80002094:	d97d                	beqz	a0,8000208a <fork+0xc2>
      np->ofile[i] = filedup(p->ofile[i]);
    80002096:	00002097          	auipc	ra,0x2
    8000209a:	764080e7          	jalr	1892(ra) # 800047fa <filedup>
    8000209e:	00a93023          	sd	a0,0(s2) # 1000 <_entry-0x7ffff000>
    800020a2:	b7e5                	j	8000208a <fork+0xc2>
  np->cwd = idup(p->cwd);
    800020a4:	160ab503          	ld	a0,352(s5)
    800020a8:	00002097          	auipc	ra,0x2
    800020ac:	8d8080e7          	jalr	-1832(ra) # 80003980 <idup>
    800020b0:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020b4:	4641                	li	a2,16
    800020b6:	168a8593          	addi	a1,s5,360
    800020ba:	16898513          	addi	a0,s3,360
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	d8e080e7          	jalr	-626(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    800020c6:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800020ca:	4789                	li	a5,2
    800020cc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020d0:	854e                	mv	a0,s3
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	be0080e7          	jalr	-1056(ra) # 80000cb2 <release>
}
    800020da:	8526                	mv	a0,s1
    800020dc:	70e2                	ld	ra,56(sp)
    800020de:	7442                	ld	s0,48(sp)
    800020e0:	74a2                	ld	s1,40(sp)
    800020e2:	7902                	ld	s2,32(sp)
    800020e4:	69e2                	ld	s3,24(sp)
    800020e6:	6a42                	ld	s4,16(sp)
    800020e8:	6aa2                	ld	s5,8(sp)
    800020ea:	6121                	addi	sp,sp,64
    800020ec:	8082                	ret
    return -1;
    800020ee:	54fd                	li	s1,-1
    800020f0:	b7ed                	j	800020da <fork+0x112>

00000000800020f2 <reparent>:
{
    800020f2:	7179                	addi	sp,sp,-48
    800020f4:	f406                	sd	ra,40(sp)
    800020f6:	f022                	sd	s0,32(sp)
    800020f8:	ec26                	sd	s1,24(sp)
    800020fa:	e84a                	sd	s2,16(sp)
    800020fc:	e44e                	sd	s3,8(sp)
    800020fe:	e052                	sd	s4,0(sp)
    80002100:	1800                	addi	s0,sp,48
    80002102:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002104:	00010497          	auipc	s1,0x10
    80002108:	c6448493          	addi	s1,s1,-924 # 80011d68 <proc>
      pp->parent = initproc;
    8000210c:	00007a17          	auipc	s4,0x7
    80002110:	f0ca0a13          	addi	s4,s4,-244 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002114:	00016997          	auipc	s3,0x16
    80002118:	a5498993          	addi	s3,s3,-1452 # 80017b68 <tickslock>
    8000211c:	a029                	j	80002126 <reparent+0x34>
    8000211e:	17848493          	addi	s1,s1,376
    80002122:	03348363          	beq	s1,s3,80002148 <reparent+0x56>
    if(pp->parent == p){
    80002126:	709c                	ld	a5,32(s1)
    80002128:	ff279be3          	bne	a5,s2,8000211e <reparent+0x2c>
      acquire(&pp->lock);
    8000212c:	8526                	mv	a0,s1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	ad0080e7          	jalr	-1328(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80002136:	000a3783          	ld	a5,0(s4)
    8000213a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b74080e7          	jalr	-1164(ra) # 80000cb2 <release>
    80002146:	bfe1                	j	8000211e <reparent+0x2c>
}
    80002148:	70a2                	ld	ra,40(sp)
    8000214a:	7402                	ld	s0,32(sp)
    8000214c:	64e2                	ld	s1,24(sp)
    8000214e:	6942                	ld	s2,16(sp)
    80002150:	69a2                	ld	s3,8(sp)
    80002152:	6a02                	ld	s4,0(sp)
    80002154:	6145                	addi	sp,sp,48
    80002156:	8082                	ret

0000000080002158 <scheduler>:
{
    80002158:	715d                	addi	sp,sp,-80
    8000215a:	e486                	sd	ra,72(sp)
    8000215c:	e0a2                	sd	s0,64(sp)
    8000215e:	fc26                	sd	s1,56(sp)
    80002160:	f84a                	sd	s2,48(sp)
    80002162:	f44e                	sd	s3,40(sp)
    80002164:	f052                	sd	s4,32(sp)
    80002166:	ec56                	sd	s5,24(sp)
    80002168:	e85a                	sd	s6,16(sp)
    8000216a:	e45e                	sd	s7,8(sp)
    8000216c:	e062                	sd	s8,0(sp)
    8000216e:	0880                	addi	s0,sp,80
    80002170:	8792                	mv	a5,tp
  int id = r_tp();
    80002172:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002174:	00779b13          	slli	s6,a5,0x7
    80002178:	0000f717          	auipc	a4,0xf
    8000217c:	7d870713          	addi	a4,a4,2008 # 80011950 <pid_lock>
    80002180:	975a                	add	a4,a4,s6
    80002182:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002186:	0000f717          	auipc	a4,0xf
    8000218a:	7ea70713          	addi	a4,a4,2026 # 80011970 <cpus+0x8>
    8000218e:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002190:	079e                	slli	a5,a5,0x7
    80002192:	0000fa17          	auipc	s4,0xf
    80002196:	7bea0a13          	addi	s4,s4,1982 # 80011950 <pid_lock>
    8000219a:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    8000219c:	5bfd                	li	s7,-1
    8000219e:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    800021a0:	00016997          	auipc	s3,0x16
    800021a4:	9c898993          	addi	s3,s3,-1592 # 80017b68 <tickslock>
    800021a8:	a0bd                	j	80002216 <scheduler+0xbe>
      release(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	b06080e7          	jalr	-1274(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021b4:	17848493          	addi	s1,s1,376
    800021b8:	05348563          	beq	s1,s3,80002202 <scheduler+0xaa>
      acquire(&p->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	a40080e7          	jalr	-1472(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    800021c6:	4c9c                	lw	a5,24(s1)
    800021c8:	ff2791e3          	bne	a5,s2,800021aa <scheduler+0x52>
        p->state = RUNNING;
    800021cc:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800021d0:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    800021d4:	70bc                	ld	a5,96(s1)
    800021d6:	83b1                	srli	a5,a5,0xc
    800021d8:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    800021dc:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800021e0:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800021e4:	07048593          	addi	a1,s1,112
    800021e8:	855a                	mv	a0,s6
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	70e080e7          	jalr	1806(ra) # 800028f8 <swtch>
        kvminithart();
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	dd4080e7          	jalr	-556(ra) # 80000fc6 <kvminithart>
        c->proc = 0;
    800021fa:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800021fe:	4c05                	li	s8,1
    80002200:	b76d                	j	800021aa <scheduler+0x52>
    if(found == 0) {
    80002202:	000c1a63          	bnez	s8,80002216 <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002206:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000220a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000220e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002212:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002216:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000221a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000221e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002222:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002224:	00010497          	auipc	s1,0x10
    80002228:	b4448493          	addi	s1,s1,-1212 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000222c:	4909                	li	s2,2
        p->state = RUNNING;
    8000222e:	4a8d                	li	s5,3
    80002230:	b771                	j	800021bc <scheduler+0x64>

0000000080002232 <sched>:
{
    80002232:	7179                	addi	sp,sp,-48
    80002234:	f406                	sd	ra,40(sp)
    80002236:	f022                	sd	s0,32(sp)
    80002238:	ec26                	sd	s1,24(sp)
    8000223a:	e84a                	sd	s2,16(sp)
    8000223c:	e44e                	sd	s3,8(sp)
    8000223e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	8f2080e7          	jalr	-1806(ra) # 80001b32 <myproc>
    80002248:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	93a080e7          	jalr	-1734(ra) # 80000b84 <holding>
    80002252:	c93d                	beqz	a0,800022c8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002254:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002256:	2781                	sext.w	a5,a5
    80002258:	079e                	slli	a5,a5,0x7
    8000225a:	0000f717          	auipc	a4,0xf
    8000225e:	6f670713          	addi	a4,a4,1782 # 80011950 <pid_lock>
    80002262:	97ba                	add	a5,a5,a4
    80002264:	0907a703          	lw	a4,144(a5)
    80002268:	4785                	li	a5,1
    8000226a:	06f71763          	bne	a4,a5,800022d8 <sched+0xa6>
  if(p->state == RUNNING)
    8000226e:	4c98                	lw	a4,24(s1)
    80002270:	478d                	li	a5,3
    80002272:	06f70b63          	beq	a4,a5,800022e8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002276:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000227a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000227c:	efb5                	bnez	a5,800022f8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000227e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002280:	0000f917          	auipc	s2,0xf
    80002284:	6d090913          	addi	s2,s2,1744 # 80011950 <pid_lock>
    80002288:	2781                	sext.w	a5,a5
    8000228a:	079e                	slli	a5,a5,0x7
    8000228c:	97ca                	add	a5,a5,s2
    8000228e:	0947a983          	lw	s3,148(a5)
    80002292:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002294:	2781                	sext.w	a5,a5
    80002296:	079e                	slli	a5,a5,0x7
    80002298:	0000f597          	auipc	a1,0xf
    8000229c:	6d858593          	addi	a1,a1,1752 # 80011970 <cpus+0x8>
    800022a0:	95be                	add	a1,a1,a5
    800022a2:	07048513          	addi	a0,s1,112
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	652080e7          	jalr	1618(ra) # 800028f8 <swtch>
    800022ae:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022b0:	2781                	sext.w	a5,a5
    800022b2:	079e                	slli	a5,a5,0x7
    800022b4:	97ca                	add	a5,a5,s2
    800022b6:	0937aa23          	sw	s3,148(a5)
}
    800022ba:	70a2                	ld	ra,40(sp)
    800022bc:	7402                	ld	s0,32(sp)
    800022be:	64e2                	ld	s1,24(sp)
    800022c0:	6942                	ld	s2,16(sp)
    800022c2:	69a2                	ld	s3,8(sp)
    800022c4:	6145                	addi	sp,sp,48
    800022c6:	8082                	ret
    panic("sched p->lock");
    800022c8:	00006517          	auipc	a0,0x6
    800022cc:	f4850513          	addi	a0,a0,-184 # 80008210 <digits+0x1e0>
    800022d0:	ffffe097          	auipc	ra,0xffffe
    800022d4:	272080e7          	jalr	626(ra) # 80000542 <panic>
    panic("sched locks");
    800022d8:	00006517          	auipc	a0,0x6
    800022dc:	f4850513          	addi	a0,a0,-184 # 80008220 <digits+0x1f0>
    800022e0:	ffffe097          	auipc	ra,0xffffe
    800022e4:	262080e7          	jalr	610(ra) # 80000542 <panic>
    panic("sched running");
    800022e8:	00006517          	auipc	a0,0x6
    800022ec:	f4850513          	addi	a0,a0,-184 # 80008230 <digits+0x200>
    800022f0:	ffffe097          	auipc	ra,0xffffe
    800022f4:	252080e7          	jalr	594(ra) # 80000542 <panic>
    panic("sched interruptible");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f4850513          	addi	a0,a0,-184 # 80008240 <digits+0x210>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	242080e7          	jalr	578(ra) # 80000542 <panic>

0000000080002308 <exit>:
{
    80002308:	7179                	addi	sp,sp,-48
    8000230a:	f406                	sd	ra,40(sp)
    8000230c:	f022                	sd	s0,32(sp)
    8000230e:	ec26                	sd	s1,24(sp)
    80002310:	e84a                	sd	s2,16(sp)
    80002312:	e44e                	sd	s3,8(sp)
    80002314:	e052                	sd	s4,0(sp)
    80002316:	1800                	addi	s0,sp,48
    80002318:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	818080e7          	jalr	-2024(ra) # 80001b32 <myproc>
    80002322:	89aa                	mv	s3,a0
  if(p == initproc)
    80002324:	00007797          	auipc	a5,0x7
    80002328:	cf47b783          	ld	a5,-780(a5) # 80009018 <initproc>
    8000232c:	0e050493          	addi	s1,a0,224
    80002330:	16050913          	addi	s2,a0,352
    80002334:	02a79363          	bne	a5,a0,8000235a <exit+0x52>
    panic("init exiting");
    80002338:	00006517          	auipc	a0,0x6
    8000233c:	f2050513          	addi	a0,a0,-224 # 80008258 <digits+0x228>
    80002340:	ffffe097          	auipc	ra,0xffffe
    80002344:	202080e7          	jalr	514(ra) # 80000542 <panic>
      fileclose(f);
    80002348:	00002097          	auipc	ra,0x2
    8000234c:	504080e7          	jalr	1284(ra) # 8000484c <fileclose>
      p->ofile[fd] = 0;
    80002350:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002354:	04a1                	addi	s1,s1,8
    80002356:	01248563          	beq	s1,s2,80002360 <exit+0x58>
    if(p->ofile[fd]){
    8000235a:	6088                	ld	a0,0(s1)
    8000235c:	f575                	bnez	a0,80002348 <exit+0x40>
    8000235e:	bfdd                	j	80002354 <exit+0x4c>
  begin_op();
    80002360:	00002097          	auipc	ra,0x2
    80002364:	01a080e7          	jalr	26(ra) # 8000437a <begin_op>
  iput(p->cwd);
    80002368:	1609b503          	ld	a0,352(s3)
    8000236c:	00002097          	auipc	ra,0x2
    80002370:	80c080e7          	jalr	-2036(ra) # 80003b78 <iput>
  end_op();
    80002374:	00002097          	auipc	ra,0x2
    80002378:	086080e7          	jalr	134(ra) # 800043fa <end_op>
  p->cwd = 0;
    8000237c:	1609b023          	sd	zero,352(s3)
  acquire(&initproc->lock);
    80002380:	00007497          	auipc	s1,0x7
    80002384:	c9848493          	addi	s1,s1,-872 # 80009018 <initproc>
    80002388:	6088                	ld	a0,0(s1)
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	874080e7          	jalr	-1932(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    80002392:	6088                	ld	a0,0(s1)
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	6c6080e7          	jalr	1734(ra) # 80001a5a <wakeup1>
  release(&initproc->lock);
    8000239c:	6088                	ld	a0,0(s1)
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	914080e7          	jalr	-1772(ra) # 80000cb2 <release>
  acquire(&p->lock);
    800023a6:	854e                	mv	a0,s3
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	856080e7          	jalr	-1962(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    800023b0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023b4:	854e                	mv	a0,s3
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8fc080e7          	jalr	-1796(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	83e080e7          	jalr	-1986(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    800023c8:	854e                	mv	a0,s3
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	834080e7          	jalr	-1996(ra) # 80000bfe <acquire>
  reparent(p);
    800023d2:	854e                	mv	a0,s3
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	d1e080e7          	jalr	-738(ra) # 800020f2 <reparent>
  wakeup1(original_parent);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	67c080e7          	jalr	1660(ra) # 80001a5a <wakeup1>
  p->xstate = status;
    800023e6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023ea:	4791                	li	a5,4
    800023ec:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8c0080e7          	jalr	-1856(ra) # 80000cb2 <release>
  sched();
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	e38080e7          	jalr	-456(ra) # 80002232 <sched>
  panic("zombie exit");
    80002402:	00006517          	auipc	a0,0x6
    80002406:	e6650513          	addi	a0,a0,-410 # 80008268 <digits+0x238>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	138080e7          	jalr	312(ra) # 80000542 <panic>

0000000080002412 <yield>:
{
    80002412:	1101                	addi	sp,sp,-32
    80002414:	ec06                	sd	ra,24(sp)
    80002416:	e822                	sd	s0,16(sp)
    80002418:	e426                	sd	s1,8(sp)
    8000241a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	716080e7          	jalr	1814(ra) # 80001b32 <myproc>
    80002424:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	7d8080e7          	jalr	2008(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    8000242e:	4789                	li	a5,2
    80002430:	cc9c                	sw	a5,24(s1)
  sched();
    80002432:	00000097          	auipc	ra,0x0
    80002436:	e00080e7          	jalr	-512(ra) # 80002232 <sched>
  release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	876080e7          	jalr	-1930(ra) # 80000cb2 <release>
}
    80002444:	60e2                	ld	ra,24(sp)
    80002446:	6442                	ld	s0,16(sp)
    80002448:	64a2                	ld	s1,8(sp)
    8000244a:	6105                	addi	sp,sp,32
    8000244c:	8082                	ret

000000008000244e <sleep>:
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	89aa                	mv	s3,a0
    8000245e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	6d2080e7          	jalr	1746(ra) # 80001b32 <myproc>
    80002468:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000246a:	05250663          	beq	a0,s2,800024b6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	790080e7          	jalr	1936(ra) # 80000bfe <acquire>
    release(lk);
    80002476:	854a                	mv	a0,s2
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	83a080e7          	jalr	-1990(ra) # 80000cb2 <release>
  p->chan = chan;
    80002480:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002484:	4785                	li	a5,1
    80002486:	cc9c                	sw	a5,24(s1)
  sched();
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	daa080e7          	jalr	-598(ra) # 80002232 <sched>
  p->chan = 0;
    80002490:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	81c080e7          	jalr	-2020(ra) # 80000cb2 <release>
    acquire(lk);
    8000249e:	854a                	mv	a0,s2
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	75e080e7          	jalr	1886(ra) # 80000bfe <acquire>
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6145                	addi	sp,sp,48
    800024b4:	8082                	ret
  p->chan = chan;
    800024b6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800024ba:	4785                	li	a5,1
    800024bc:	cd1c                	sw	a5,24(a0)
  sched();
    800024be:	00000097          	auipc	ra,0x0
    800024c2:	d74080e7          	jalr	-652(ra) # 80002232 <sched>
  p->chan = 0;
    800024c6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800024ca:	bff9                	j	800024a8 <sleep+0x5a>

00000000800024cc <wait>:
{
    800024cc:	715d                	addi	sp,sp,-80
    800024ce:	e486                	sd	ra,72(sp)
    800024d0:	e0a2                	sd	s0,64(sp)
    800024d2:	fc26                	sd	s1,56(sp)
    800024d4:	f84a                	sd	s2,48(sp)
    800024d6:	f44e                	sd	s3,40(sp)
    800024d8:	f052                	sd	s4,32(sp)
    800024da:	ec56                	sd	s5,24(sp)
    800024dc:	e85a                	sd	s6,16(sp)
    800024de:	e45e                	sd	s7,8(sp)
    800024e0:	0880                	addi	s0,sp,80
    800024e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	64e080e7          	jalr	1614(ra) # 80001b32 <myproc>
    800024ec:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	710080e7          	jalr	1808(ra) # 80000bfe <acquire>
    havekids = 0;
    800024f6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024f8:	4a11                	li	s4,4
        havekids = 1;
    800024fa:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800024fc:	00015997          	auipc	s3,0x15
    80002500:	66c98993          	addi	s3,s3,1644 # 80017b68 <tickslock>
    havekids = 0;
    80002504:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002506:	00010497          	auipc	s1,0x10
    8000250a:	86248493          	addi	s1,s1,-1950 # 80011d68 <proc>
    8000250e:	a08d                	j	80002570 <wait+0xa4>
          pid = np->pid;
    80002510:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002514:	000b0e63          	beqz	s6,80002530 <wait+0x64>
    80002518:	4691                	li	a3,4
    8000251a:	03448613          	addi	a2,s1,52
    8000251e:	85da                	mv	a1,s6
    80002520:	05893503          	ld	a0,88(s2)
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	1a2080e7          	jalr	418(ra) # 800016c6 <copyout>
    8000252c:	02054263          	bltz	a0,80002550 <wait+0x84>
          freeproc(np);
    80002530:	8526                	mv	a0,s1
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	7b2080e7          	jalr	1970(ra) # 80001ce4 <freeproc>
          release(&np->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	776080e7          	jalr	1910(ra) # 80000cb2 <release>
          release(&p->lock);
    80002544:	854a                	mv	a0,s2
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	76c080e7          	jalr	1900(ra) # 80000cb2 <release>
          return pid;
    8000254e:	a8a9                	j	800025a8 <wait+0xdc>
            release(&np->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	760080e7          	jalr	1888(ra) # 80000cb2 <release>
            release(&p->lock);
    8000255a:	854a                	mv	a0,s2
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	756080e7          	jalr	1878(ra) # 80000cb2 <release>
            return -1;
    80002564:	59fd                	li	s3,-1
    80002566:	a089                	j	800025a8 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002568:	17848493          	addi	s1,s1,376
    8000256c:	03348463          	beq	s1,s3,80002594 <wait+0xc8>
      if(np->parent == p){
    80002570:	709c                	ld	a5,32(s1)
    80002572:	ff279be3          	bne	a5,s2,80002568 <wait+0x9c>
        acquire(&np->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	686080e7          	jalr	1670(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    80002580:	4c9c                	lw	a5,24(s1)
    80002582:	f94787e3          	beq	a5,s4,80002510 <wait+0x44>
        release(&np->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	72a080e7          	jalr	1834(ra) # 80000cb2 <release>
        havekids = 1;
    80002590:	8756                	mv	a4,s5
    80002592:	bfd9                	j	80002568 <wait+0x9c>
    if(!havekids || p->killed){
    80002594:	c701                	beqz	a4,8000259c <wait+0xd0>
    80002596:	03092783          	lw	a5,48(s2)
    8000259a:	c39d                	beqz	a5,800025c0 <wait+0xf4>
      release(&p->lock);
    8000259c:	854a                	mv	a0,s2
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	714080e7          	jalr	1812(ra) # 80000cb2 <release>
      return -1;
    800025a6:	59fd                	li	s3,-1
}
    800025a8:	854e                	mv	a0,s3
    800025aa:	60a6                	ld	ra,72(sp)
    800025ac:	6406                	ld	s0,64(sp)
    800025ae:	74e2                	ld	s1,56(sp)
    800025b0:	7942                	ld	s2,48(sp)
    800025b2:	79a2                	ld	s3,40(sp)
    800025b4:	7a02                	ld	s4,32(sp)
    800025b6:	6ae2                	ld	s5,24(sp)
    800025b8:	6b42                	ld	s6,16(sp)
    800025ba:	6ba2                	ld	s7,8(sp)
    800025bc:	6161                	addi	sp,sp,80
    800025be:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800025c0:	85ca                	mv	a1,s2
    800025c2:	854a                	mv	a0,s2
    800025c4:	00000097          	auipc	ra,0x0
    800025c8:	e8a080e7          	jalr	-374(ra) # 8000244e <sleep>
    havekids = 0;
    800025cc:	bf25                	j	80002504 <wait+0x38>

00000000800025ce <wakeup>:
{
    800025ce:	7139                	addi	sp,sp,-64
    800025d0:	fc06                	sd	ra,56(sp)
    800025d2:	f822                	sd	s0,48(sp)
    800025d4:	f426                	sd	s1,40(sp)
    800025d6:	f04a                	sd	s2,32(sp)
    800025d8:	ec4e                	sd	s3,24(sp)
    800025da:	e852                	sd	s4,16(sp)
    800025dc:	e456                	sd	s5,8(sp)
    800025de:	0080                	addi	s0,sp,64
    800025e0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025e2:	0000f497          	auipc	s1,0xf
    800025e6:	78648493          	addi	s1,s1,1926 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800025ea:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025ec:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800025ee:	00015917          	auipc	s2,0x15
    800025f2:	57a90913          	addi	s2,s2,1402 # 80017b68 <tickslock>
    800025f6:	a811                	j	8000260a <wakeup+0x3c>
    release(&p->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	6b8080e7          	jalr	1720(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002602:	17848493          	addi	s1,s1,376
    80002606:	03248063          	beq	s1,s2,80002626 <wakeup+0x58>
    acquire(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5f2080e7          	jalr	1522(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002614:	4c9c                	lw	a5,24(s1)
    80002616:	ff3791e3          	bne	a5,s3,800025f8 <wakeup+0x2a>
    8000261a:	749c                	ld	a5,40(s1)
    8000261c:	fd479ee3          	bne	a5,s4,800025f8 <wakeup+0x2a>
      p->state = RUNNABLE;
    80002620:	0154ac23          	sw	s5,24(s1)
    80002624:	bfd1                	j	800025f8 <wakeup+0x2a>
}
    80002626:	70e2                	ld	ra,56(sp)
    80002628:	7442                	ld	s0,48(sp)
    8000262a:	74a2                	ld	s1,40(sp)
    8000262c:	7902                	ld	s2,32(sp)
    8000262e:	69e2                	ld	s3,24(sp)
    80002630:	6a42                	ld	s4,16(sp)
    80002632:	6aa2                	ld	s5,8(sp)
    80002634:	6121                	addi	sp,sp,64
    80002636:	8082                	ret

0000000080002638 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	72048493          	addi	s1,s1,1824 # 80011d68 <proc>
    80002650:	00015997          	auipc	s3,0x15
    80002654:	51898993          	addi	s3,s3,1304 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	5a4080e7          	jalr	1444(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    80002662:	5c9c                	lw	a5,56(s1)
    80002664:	01278d63          	beq	a5,s2,8000267e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	648080e7          	jalr	1608(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	17848493          	addi	s1,s1,376
    80002676:	ff3491e3          	bne	s1,s3,80002658 <kill+0x20>
  }
  return -1;
    8000267a:	557d                	li	a0,-1
    8000267c:	a821                	j	80002694 <kill+0x5c>
      p->killed = 1;
    8000267e:	4785                	li	a5,1
    80002680:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002682:	4c98                	lw	a4,24(s1)
    80002684:	00f70f63          	beq	a4,a5,800026a2 <kill+0x6a>
      release(&p->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	628080e7          	jalr	1576(ra) # 80000cb2 <release>
      return 0;
    80002692:	4501                	li	a0,0
}
    80002694:	70a2                	ld	ra,40(sp)
    80002696:	7402                	ld	s0,32(sp)
    80002698:	64e2                	ld	s1,24(sp)
    8000269a:	6942                	ld	s2,16(sp)
    8000269c:	69a2                	ld	s3,8(sp)
    8000269e:	6145                	addi	sp,sp,48
    800026a0:	8082                	ret
        p->state = RUNNABLE;
    800026a2:	4789                	li	a5,2
    800026a4:	cc9c                	sw	a5,24(s1)
    800026a6:	b7cd                	j	80002688 <kill+0x50>

00000000800026a8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a8:	7179                	addi	sp,sp,-48
    800026aa:	f406                	sd	ra,40(sp)
    800026ac:	f022                	sd	s0,32(sp)
    800026ae:	ec26                	sd	s1,24(sp)
    800026b0:	e84a                	sd	s2,16(sp)
    800026b2:	e44e                	sd	s3,8(sp)
    800026b4:	e052                	sd	s4,0(sp)
    800026b6:	1800                	addi	s0,sp,48
    800026b8:	84aa                	mv	s1,a0
    800026ba:	892e                	mv	s2,a1
    800026bc:	89b2                	mv	s3,a2
    800026be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	472080e7          	jalr	1138(ra) # 80001b32 <myproc>
  if(user_dst){
    800026c8:	c08d                	beqz	s1,800026ea <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026ca:	86d2                	mv	a3,s4
    800026cc:	864e                	mv	a2,s3
    800026ce:	85ca                	mv	a1,s2
    800026d0:	6d28                	ld	a0,88(a0)
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	ff4080e7          	jalr	-12(ra) # 800016c6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6942                	ld	s2,16(sp)
    800026e2:	69a2                	ld	s3,8(sp)
    800026e4:	6a02                	ld	s4,0(sp)
    800026e6:	6145                	addi	sp,sp,48
    800026e8:	8082                	ret
    memmove((char *)dst, src, len);
    800026ea:	000a061b          	sext.w	a2,s4
    800026ee:	85ce                	mv	a1,s3
    800026f0:	854a                	mv	a0,s2
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	664080e7          	jalr	1636(ra) # 80000d56 <memmove>
    return 0;
    800026fa:	8526                	mv	a0,s1
    800026fc:	bff9                	j	800026da <either_copyout+0x32>

00000000800026fe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026fe:	7179                	addi	sp,sp,-48
    80002700:	f406                	sd	ra,40(sp)
    80002702:	f022                	sd	s0,32(sp)
    80002704:	ec26                	sd	s1,24(sp)
    80002706:	e84a                	sd	s2,16(sp)
    80002708:	e44e                	sd	s3,8(sp)
    8000270a:	e052                	sd	s4,0(sp)
    8000270c:	1800                	addi	s0,sp,48
    8000270e:	892a                	mv	s2,a0
    80002710:	84ae                	mv	s1,a1
    80002712:	89b2                	mv	s3,a2
    80002714:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	41c080e7          	jalr	1052(ra) # 80001b32 <myproc>
  if(user_src){
    8000271e:	c08d                	beqz	s1,80002740 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002720:	86d2                	mv	a3,s4
    80002722:	864e                	mv	a2,s3
    80002724:	85ca                	mv	a1,s2
    80002726:	6d28                	ld	a0,88(a0)
    80002728:	fffff097          	auipc	ra,0xfffff
    8000272c:	044080e7          	jalr	68(ra) # 8000176c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002730:	70a2                	ld	ra,40(sp)
    80002732:	7402                	ld	s0,32(sp)
    80002734:	64e2                	ld	s1,24(sp)
    80002736:	6942                	ld	s2,16(sp)
    80002738:	69a2                	ld	s3,8(sp)
    8000273a:	6a02                	ld	s4,0(sp)
    8000273c:	6145                	addi	sp,sp,48
    8000273e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002740:	000a061b          	sext.w	a2,s4
    80002744:	85ce                	mv	a1,s3
    80002746:	854a                	mv	a0,s2
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	60e080e7          	jalr	1550(ra) # 80000d56 <memmove>
    return 0;
    80002750:	8526                	mv	a0,s1
    80002752:	bff9                	j	80002730 <either_copyin+0x32>

0000000080002754 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002754:	715d                	addi	sp,sp,-80
    80002756:	e486                	sd	ra,72(sp)
    80002758:	e0a2                	sd	s0,64(sp)
    8000275a:	fc26                	sd	s1,56(sp)
    8000275c:	f84a                	sd	s2,48(sp)
    8000275e:	f44e                	sd	s3,40(sp)
    80002760:	f052                	sd	s4,32(sp)
    80002762:	ec56                	sd	s5,24(sp)
    80002764:	e85a                	sd	s6,16(sp)
    80002766:	e45e                	sd	s7,8(sp)
    80002768:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000276a:	00006517          	auipc	a0,0x6
    8000276e:	94e50513          	addi	a0,a0,-1714 # 800080b8 <digits+0x88>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	e1a080e7          	jalr	-486(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000277a:	0000f497          	auipc	s1,0xf
    8000277e:	75648493          	addi	s1,s1,1878 # 80011ed0 <proc+0x168>
    80002782:	00015917          	auipc	s2,0x15
    80002786:	54e90913          	addi	s2,s2,1358 # 80017cd0 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000278c:	00006997          	auipc	s3,0x6
    80002790:	aec98993          	addi	s3,s3,-1300 # 80008278 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002794:	00006a97          	auipc	s5,0x6
    80002798:	aeca8a93          	addi	s5,s5,-1300 # 80008280 <digits+0x250>
    printf("\n");
    8000279c:	00006a17          	auipc	s4,0x6
    800027a0:	91ca0a13          	addi	s4,s4,-1764 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a4:	00006b97          	auipc	s7,0x6
    800027a8:	b54b8b93          	addi	s7,s7,-1196 # 800082f8 <states.0>
    800027ac:	a00d                	j	800027ce <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027ae:	ed06a583          	lw	a1,-304(a3)
    800027b2:	8556                	mv	a0,s5
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd8080e7          	jalr	-552(ra) # 8000058c <printf>
    printf("\n");
    800027bc:	8552                	mv	a0,s4
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	dce080e7          	jalr	-562(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c6:	17848493          	addi	s1,s1,376
    800027ca:	03248163          	beq	s1,s2,800027ec <procdump+0x98>
    if(p->state == UNUSED)
    800027ce:	86a6                	mv	a3,s1
    800027d0:	eb04a783          	lw	a5,-336(s1)
    800027d4:	dbed                	beqz	a5,800027c6 <procdump+0x72>
      state = "???";
    800027d6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d8:	fcfb6be3          	bltu	s6,a5,800027ae <procdump+0x5a>
    800027dc:	1782                	slli	a5,a5,0x20
    800027de:	9381                	srli	a5,a5,0x20
    800027e0:	078e                	slli	a5,a5,0x3
    800027e2:	97de                	add	a5,a5,s7
    800027e4:	6390                	ld	a2,0(a5)
    800027e6:	f661                	bnez	a2,800027ae <procdump+0x5a>
      state = "???";
    800027e8:	864e                	mv	a2,s3
    800027ea:	b7d1                	j	800027ae <procdump+0x5a>
  }
}
    800027ec:	60a6                	ld	ra,72(sp)
    800027ee:	6406                	ld	s0,64(sp)
    800027f0:	74e2                	ld	s1,56(sp)
    800027f2:	7942                	ld	s2,48(sp)
    800027f4:	79a2                	ld	s3,40(sp)
    800027f6:	7a02                	ld	s4,32(sp)
    800027f8:	6ae2                	ld	s5,24(sp)
    800027fa:	6b42                	ld	s6,16(sp)
    800027fc:	6ba2                	ld	s7,8(sp)
    800027fe:	6161                	addi	sp,sp,80
    80002800:	8082                	ret

0000000080002802 <uvmlazytouch>:

// touch a lazy-allocated page so it's mapped to an actual physical page.
void uvmlazytouch(uint64 va) {
    80002802:	7179                	addi	sp,sp,-48
    80002804:	f406                	sd	ra,40(sp)
    80002806:	f022                	sd	s0,32(sp)
    80002808:	ec26                	sd	s1,24(sp)
    8000280a:	e84a                	sd	s2,16(sp)
    8000280c:	e44e                	sd	s3,8(sp)
    8000280e:	1800                	addi	s0,sp,48
    80002810:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	320080e7          	jalr	800(ra) # 80001b32 <myproc>
    8000281a:	84aa                	mv	s1,a0
  char *mem = kalloc();
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	2f2080e7          	jalr	754(ra) # 80000b0e <kalloc>
  if(mem == 0) {
    80002824:	c531                	beqz	a0,80002870 <uvmlazytouch+0x6e>
    80002826:	892a                	mv	s2,a0
    // failed to allocate physical memory
    printf("lazy alloc: out of memory\n");
    p->killed = 1;
  } else {
    memset(mem, 0, PGSIZE);
    80002828:	6605                	lui	a2,0x1
    8000282a:	4581                	li	a1,0
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	4ce080e7          	jalr	1230(ra) # 80000cfa <memset>
    if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80002834:	4779                	li	a4,30
    80002836:	86ca                	mv	a3,s2
    80002838:	6605                	lui	a2,0x1
    8000283a:	75fd                	lui	a1,0xfffff
    8000283c:	00b9f5b3          	and	a1,s3,a1
    80002840:	6ca8                	ld	a0,88(s1)
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	8e6080e7          	jalr	-1818(ra) # 80001128 <mappages>
    8000284a:	ed15                	bnez	a0,80002886 <uvmlazytouch+0x84>
      kfree(mem);
      p->killed = 1;
    }
    //同步扩大出错，need fix

    if(kvmcopymappings(p->pagetable, p->kpagetable, p->lazysz, PGSIZE) != 0){
    8000284c:	6685                	lui	a3,0x1
    8000284e:	68b0                	ld	a2,80(s1)
    80002850:	70ac                	ld	a1,96(s1)
    80002852:	6ca8                	ld	a0,88(s1)
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	10a080e7          	jalr	266(ra) # 8000195e <kvmcopymappings>
    8000285c:	c119                	beqz	a0,80002862 <uvmlazytouch+0x60>
      p->killed = 1;      
    8000285e:	4785                	li	a5,1
    80002860:	d89c                	sw	a5,48(s1)
    }

  }
}
    80002862:	70a2                	ld	ra,40(sp)
    80002864:	7402                	ld	s0,32(sp)
    80002866:	64e2                	ld	s1,24(sp)
    80002868:	6942                	ld	s2,16(sp)
    8000286a:	69a2                	ld	s3,8(sp)
    8000286c:	6145                	addi	sp,sp,48
    8000286e:	8082                	ret
    printf("lazy alloc: out of memory\n");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	a2050513          	addi	a0,a0,-1504 # 80008290 <digits+0x260>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d14080e7          	jalr	-748(ra) # 8000058c <printf>
    p->killed = 1;
    80002880:	4785                	li	a5,1
    80002882:	d89c                	sw	a5,48(s1)
    80002884:	bff9                	j	80002862 <uvmlazytouch+0x60>
      printf("lazy alloc: failed to map page\n");
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	a2a50513          	addi	a0,a0,-1494 # 800082b0 <digits+0x280>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	cfe080e7          	jalr	-770(ra) # 8000058c <printf>
      kfree(mem);
    80002896:	854a                	mv	a0,s2
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	17a080e7          	jalr	378(ra) # 80000a12 <kfree>
      p->killed = 1;
    800028a0:	4785                	li	a5,1
    800028a2:	d89c                	sw	a5,48(s1)
    800028a4:	b765                	j	8000284c <uvmlazytouch+0x4a>

00000000800028a6 <uvmshouldtouch>:

// whether a page is previously lazy-allocated and needed to be touched before use.
int uvmshouldtouch(uint64 va) {
    800028a6:	1101                	addi	sp,sp,-32
    800028a8:	ec06                	sd	ra,24(sp)
    800028aa:	e822                	sd	s0,16(sp)
    800028ac:	e426                	sd	s1,8(sp)
    800028ae:	1000                	addi	s0,sp,32
    800028b0:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	280080e7          	jalr	640(ra) # 80001b32 <myproc>
  
  return va < p->sz // within size of memory for the process
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    800028ba:	6538                	ld	a4,72(a0)
    800028bc:	02e4f863          	bgeu	s1,a4,800028ec <uvmshouldtouch+0x46>
    800028c0:	87aa                	mv	a5,a0
  asm volatile("mv %0, sp" : "=r" (x) );
    800028c2:	868a                	mv	a3,sp
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    800028c4:	777d                	lui	a4,0xfffff
    800028c6:	8f65                	and	a4,a4,s1
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    800028c8:	4501                	li	a0,0
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    800028ca:	02d70263          	beq	a4,a3,800028ee <uvmshouldtouch+0x48>
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    800028ce:	4601                	li	a2,0
    800028d0:	85a6                	mv	a1,s1
    800028d2:	6fa8                	ld	a0,88(a5)
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	716080e7          	jalr	1814(ra) # 80000fea <walk>
    800028dc:	87aa                	mv	a5,a0
    800028de:	4505                	li	a0,1
    800028e0:	c799                	beqz	a5,800028ee <uvmshouldtouch+0x48>
    800028e2:	6388                	ld	a0,0(a5)
    800028e4:	00154513          	xori	a0,a0,1
    800028e8:	8905                	andi	a0,a0,1
    800028ea:	a011                	j	800028ee <uvmshouldtouch+0x48>
    800028ec:	4501                	li	a0,0
}
    800028ee:	60e2                	ld	ra,24(sp)
    800028f0:	6442                	ld	s0,16(sp)
    800028f2:	64a2                	ld	s1,8(sp)
    800028f4:	6105                	addi	sp,sp,32
    800028f6:	8082                	ret

00000000800028f8 <swtch>:
    800028f8:	00153023          	sd	ra,0(a0)
    800028fc:	00253423          	sd	sp,8(a0)
    80002900:	e900                	sd	s0,16(a0)
    80002902:	ed04                	sd	s1,24(a0)
    80002904:	03253023          	sd	s2,32(a0)
    80002908:	03353423          	sd	s3,40(a0)
    8000290c:	03453823          	sd	s4,48(a0)
    80002910:	03553c23          	sd	s5,56(a0)
    80002914:	05653023          	sd	s6,64(a0)
    80002918:	05753423          	sd	s7,72(a0)
    8000291c:	05853823          	sd	s8,80(a0)
    80002920:	05953c23          	sd	s9,88(a0)
    80002924:	07a53023          	sd	s10,96(a0)
    80002928:	07b53423          	sd	s11,104(a0)
    8000292c:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002930:	0085b103          	ld	sp,8(a1)
    80002934:	6980                	ld	s0,16(a1)
    80002936:	6d84                	ld	s1,24(a1)
    80002938:	0205b903          	ld	s2,32(a1)
    8000293c:	0285b983          	ld	s3,40(a1)
    80002940:	0305ba03          	ld	s4,48(a1)
    80002944:	0385ba83          	ld	s5,56(a1)
    80002948:	0405bb03          	ld	s6,64(a1)
    8000294c:	0485bb83          	ld	s7,72(a1)
    80002950:	0505bc03          	ld	s8,80(a1)
    80002954:	0585bc83          	ld	s9,88(a1)
    80002958:	0605bd03          	ld	s10,96(a1)
    8000295c:	0685bd83          	ld	s11,104(a1)
    80002960:	8082                	ret

0000000080002962 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002962:	1141                	addi	sp,sp,-16
    80002964:	e406                	sd	ra,8(sp)
    80002966:	e022                	sd	s0,0(sp)
    80002968:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296a:	00006597          	auipc	a1,0x6
    8000296e:	9b658593          	addi	a1,a1,-1610 # 80008320 <states.0+0x28>
    80002972:	00015517          	auipc	a0,0x15
    80002976:	1f650513          	addi	a0,a0,502 # 80017b68 <tickslock>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	1f4080e7          	jalr	500(ra) # 80000b6e <initlock>
}
    80002982:	60a2                	ld	ra,8(sp)
    80002984:	6402                	ld	s0,0(sp)
    80002986:	0141                	addi	sp,sp,16
    80002988:	8082                	ret

000000008000298a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298a:	1141                	addi	sp,sp,-16
    8000298c:	e422                	sd	s0,8(sp)
    8000298e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002990:	00003797          	auipc	a5,0x3
    80002994:	57078793          	addi	a5,a5,1392 # 80005f00 <kernelvec>
    80002998:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299c:	6422                	ld	s0,8(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e406                	sd	ra,8(sp)
    800029a6:	e022                	sd	s0,0(sp)
    800029a8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	188080e7          	jalr	392(ra) # 80001b32 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029bc:	00004617          	auipc	a2,0x4
    800029c0:	64460613          	addi	a2,a2,1604 # 80007000 <_trampoline>
    800029c4:	00004697          	auipc	a3,0x4
    800029c8:	63c68693          	addi	a3,a3,1596 # 80007000 <_trampoline>
    800029cc:	8e91                	sub	a3,a3,a2
    800029ce:	040007b7          	lui	a5,0x4000
    800029d2:	17fd                	addi	a5,a5,-1
    800029d4:	07b2                	slli	a5,a5,0xc
    800029d6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029dc:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029de:	180026f3          	csrr	a3,satp
    800029e2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e4:	7538                	ld	a4,104(a0)
    800029e6:	6134                	ld	a3,64(a0)
    800029e8:	6585                	lui	a1,0x1
    800029ea:	96ae                	add	a3,a3,a1
    800029ec:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ee:	7538                	ld	a4,104(a0)
    800029f0:	00000697          	auipc	a3,0x0
    800029f4:	13868693          	addi	a3,a3,312 # 80002b28 <usertrap>
    800029f8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fa:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fc:	8692                	mv	a3,tp
    800029fe:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a00:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a04:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a08:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a10:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a12:	6f18                	ld	a4,24(a4)
    80002a14:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a18:	6d2c                	ld	a1,88(a0)
    80002a1a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1c:	00004717          	auipc	a4,0x4
    80002a20:	67470713          	addi	a4,a4,1652 # 80007090 <userret>
    80002a24:	8f11                	sub	a4,a4,a2
    80002a26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a28:	577d                	li	a4,-1
    80002a2a:	177e                	slli	a4,a4,0x3f
    80002a2c:	8dd9                	or	a1,a1,a4
    80002a2e:	02000537          	lui	a0,0x2000
    80002a32:	157d                	addi	a0,a0,-1
    80002a34:	0536                	slli	a0,a0,0xd
    80002a36:	9782                	jalr	a5
}
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4a:	00015497          	auipc	s1,0x15
    80002a4e:	11e48493          	addi	s1,s1,286 # 80017b68 <tickslock>
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	1aa080e7          	jalr	426(ra) # 80000bfe <acquire>
  ticks++;
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	5c450513          	addi	a0,a0,1476 # 80009020 <ticks>
    80002a64:	411c                	lw	a5,0(a0)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	b64080e7          	jalr	-1180(ra) # 800025ce <wakeup>
  release(&tickslock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	23e080e7          	jalr	574(ra) # 80000cb2 <release>
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret

0000000080002a86 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a90:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a94:	00074d63          	bltz	a4,80002aae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a98:	57fd                	li	a5,-1
    80002a9a:	17fe                	slli	a5,a5,0x3f
    80002a9c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa0:	06f70363          	beq	a4,a5,80002b06 <devintr+0x80>
  }
}
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
     (scause & 0xff) == 9){
    80002aae:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab2:	46a5                	li	a3,9
    80002ab4:	fed792e3          	bne	a5,a3,80002a98 <devintr+0x12>
    int irq = plic_claim();
    80002ab8:	00003097          	auipc	ra,0x3
    80002abc:	550080e7          	jalr	1360(ra) # 80006008 <plic_claim>
    80002ac0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac2:	47a9                	li	a5,10
    80002ac4:	02f50763          	beq	a0,a5,80002af2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac8:	4785                	li	a5,1
    80002aca:	02f50963          	beq	a0,a5,80002afc <devintr+0x76>
    return 1;
    80002ace:	4505                	li	a0,1
    } else if(irq){
    80002ad0:	d8f1                	beqz	s1,80002aa4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	85450513          	addi	a0,a0,-1964 # 80008328 <states.0+0x30>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	ab0080e7          	jalr	-1360(ra) # 8000058c <printf>
      plic_complete(irq);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	00003097          	auipc	ra,0x3
    80002aea:	546080e7          	jalr	1350(ra) # 8000602c <plic_complete>
    return 1;
    80002aee:	4505                	li	a0,1
    80002af0:	bf55                	j	80002aa4 <devintr+0x1e>
      uartintr();
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	ed0080e7          	jalr	-304(ra) # 800009c2 <uartintr>
    80002afa:	b7ed                	j	80002ae4 <devintr+0x5e>
      virtio_disk_intr();
    80002afc:	00004097          	auipc	ra,0x4
    80002b00:	9b4080e7          	jalr	-1612(ra) # 800064b0 <virtio_disk_intr>
    80002b04:	b7c5                	j	80002ae4 <devintr+0x5e>
    if(cpuid() == 0){
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	000080e7          	jalr	ra # 80001b06 <cpuid>
    80002b0e:	c901                	beqz	a0,80002b1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b16:	14479073          	csrw	sip,a5
    return 2;
    80002b1a:	4509                	li	a0,2
    80002b1c:	b761                	j	80002aa4 <devintr+0x1e>
      clockintr();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	f22080e7          	jalr	-222(ra) # 80002a40 <clockintr>
    80002b26:	b7ed                	j	80002b10 <devintr+0x8a>

0000000080002b28 <usertrap>:
{
    80002b28:	7179                	addi	sp,sp,-48
    80002b2a:	f406                	sd	ra,40(sp)
    80002b2c:	f022                	sd	s0,32(sp)
    80002b2e:	ec26                	sd	s1,24(sp)
    80002b30:	e84a                	sd	s2,16(sp)
    80002b32:	e44e                	sd	s3,8(sp)
    80002b34:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b3a:	1007f793          	andi	a5,a5,256
    80002b3e:	e3b5                	bnez	a5,80002ba2 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b40:	00003797          	auipc	a5,0x3
    80002b44:	3c078793          	addi	a5,a5,960 # 80005f00 <kernelvec>
    80002b48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	fe6080e7          	jalr	-26(ra) # 80001b32 <myproc>
    80002b54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b56:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102773          	csrr	a4,sepc
    80002b5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b62:	47a1                	li	a5,8
    80002b64:	04f71d63          	bne	a4,a5,80002bbe <usertrap+0x96>
    if(p->killed)
    80002b68:	591c                	lw	a5,48(a0)
    80002b6a:	e7a1                	bnez	a5,80002bb2 <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002b6c:	74b8                	ld	a4,104(s1)
    80002b6e:	6f1c                	ld	a5,24(a4)
    80002b70:	0791                	addi	a5,a5,4
    80002b72:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	316080e7          	jalr	790(ra) # 80002e96 <syscall>
  if(p->killed)
    80002b88:	589c                	lw	a5,48(s1)
    80002b8a:	e3f9                	bnez	a5,80002c50 <usertrap+0x128>
  usertrapret();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	e16080e7          	jalr	-490(ra) # 800029a2 <usertrapret>
}
    80002b94:	70a2                	ld	ra,40(sp)
    80002b96:	7402                	ld	s0,32(sp)
    80002b98:	64e2                	ld	s1,24(sp)
    80002b9a:	6942                	ld	s2,16(sp)
    80002b9c:	69a2                	ld	s3,8(sp)
    80002b9e:	6145                	addi	sp,sp,48
    80002ba0:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba2:	00005517          	auipc	a0,0x5
    80002ba6:	7a650513          	addi	a0,a0,1958 # 80008348 <states.0+0x50>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	998080e7          	jalr	-1640(ra) # 80000542 <panic>
      exit(-1);
    80002bb2:	557d                	li	a0,-1
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	754080e7          	jalr	1876(ra) # 80002308 <exit>
    80002bbc:	bf45                	j	80002b6c <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	ec8080e7          	jalr	-312(ra) # 80002a86 <devintr>
    80002bc6:	892a                	mv	s2,a0
    80002bc8:	e149                	bnez	a0,80002c4a <usertrap+0x122>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bca:	14302573          	csrr	a0,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bce:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause()== 15) && uvmshouldtouch(va)){
    80002bd2:	47b5                	li	a5,13
    80002bd4:	04f70d63          	beq	a4,a5,80002c2e <usertrap+0x106>
    80002bd8:	14202773          	csrr	a4,scause
    80002bdc:	47bd                	li	a5,15
    80002bde:	04f70863          	beq	a4,a5,80002c2e <usertrap+0x106>
    80002be2:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002be6:	5c90                	lw	a2,56(s1)
    80002be8:	00005517          	auipc	a0,0x5
    80002bec:	78050513          	addi	a0,a0,1920 # 80008368 <states.0+0x70>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	99c080e7          	jalr	-1636(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bfc:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c00:	00005517          	auipc	a0,0x5
    80002c04:	79850513          	addi	a0,a0,1944 # 80008398 <states.0+0xa0>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	984080e7          	jalr	-1660(ra) # 8000058c <printf>
      p->killed = 1;      
    80002c10:	4785                	li	a5,1
    80002c12:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c14:	557d                	li	a0,-1
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	6f2080e7          	jalr	1778(ra) # 80002308 <exit>
  if(which_dev == 2)
    80002c1e:	4789                	li	a5,2
    80002c20:	f6f916e3          	bne	s2,a5,80002b8c <usertrap+0x64>
    yield();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	7ee080e7          	jalr	2030(ra) # 80002412 <yield>
    80002c2c:	b785                	j	80002b8c <usertrap+0x64>
    if((r_scause() == 13 || r_scause()== 15) && uvmshouldtouch(va)){
    80002c2e:	0005099b          	sext.w	s3,a0
    80002c32:	854e                	mv	a0,s3
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	c72080e7          	jalr	-910(ra) # 800028a6 <uvmshouldtouch>
    80002c3c:	d15d                	beqz	a0,80002be2 <usertrap+0xba>
      uvmlazytouch(va);
    80002c3e:	854e                	mv	a0,s3
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	bc2080e7          	jalr	-1086(ra) # 80002802 <uvmlazytouch>
    80002c48:	b781                	j	80002b88 <usertrap+0x60>
  if(p->killed)
    80002c4a:	589c                	lw	a5,48(s1)
    80002c4c:	dbe9                	beqz	a5,80002c1e <usertrap+0xf6>
    80002c4e:	b7d9                	j	80002c14 <usertrap+0xec>
    80002c50:	4901                	li	s2,0
    80002c52:	b7c9                	j	80002c14 <usertrap+0xec>

0000000080002c54 <kerneltrap>:
{
    80002c54:	7179                	addi	sp,sp,-48
    80002c56:	f406                	sd	ra,40(sp)
    80002c58:	f022                	sd	s0,32(sp)
    80002c5a:	ec26                	sd	s1,24(sp)
    80002c5c:	e84a                	sd	s2,16(sp)
    80002c5e:	e44e                	sd	s3,8(sp)
    80002c60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c62:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c66:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c6a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c6e:	1004f793          	andi	a5,s1,256
    80002c72:	cb85                	beqz	a5,80002ca2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c78:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c7a:	ef85                	bnez	a5,80002cb2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	e0a080e7          	jalr	-502(ra) # 80002a86 <devintr>
    80002c84:	cd1d                	beqz	a0,80002cc2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c86:	4789                	li	a5,2
    80002c88:	06f50a63          	beq	a0,a5,80002cfc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c8c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c90:	10049073          	csrw	sstatus,s1
}
    80002c94:	70a2                	ld	ra,40(sp)
    80002c96:	7402                	ld	s0,32(sp)
    80002c98:	64e2                	ld	s1,24(sp)
    80002c9a:	6942                	ld	s2,16(sp)
    80002c9c:	69a2                	ld	s3,8(sp)
    80002c9e:	6145                	addi	sp,sp,48
    80002ca0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	71650513          	addi	a0,a0,1814 # 800083b8 <states.0+0xc0>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	72e50513          	addi	a0,a0,1838 # 800083e0 <states.0+0xe8>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	888080e7          	jalr	-1912(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002cc2:	85ce                	mv	a1,s3
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	73c50513          	addi	a0,a0,1852 # 80008400 <states.0+0x108>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	8c0080e7          	jalr	-1856(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	73450513          	addi	a0,a0,1844 # 80008410 <states.0+0x118>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	8a8080e7          	jalr	-1880(ra) # 8000058c <printf>
    panic("kerneltrap");      
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	73c50513          	addi	a0,a0,1852 # 80008428 <states.0+0x130>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	84e080e7          	jalr	-1970(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	e36080e7          	jalr	-458(ra) # 80001b32 <myproc>
    80002d04:	d541                	beqz	a0,80002c8c <kerneltrap+0x38>
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	e2c080e7          	jalr	-468(ra) # 80001b32 <myproc>
    80002d0e:	4d18                	lw	a4,24(a0)
    80002d10:	478d                	li	a5,3
    80002d12:	f6f71de3          	bne	a4,a5,80002c8c <kerneltrap+0x38>
    yield();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	6fc080e7          	jalr	1788(ra) # 80002412 <yield>
    80002d1e:	b7bd                	j	80002c8c <kerneltrap+0x38>

0000000080002d20 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	1000                	addi	s0,sp,32
    80002d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	e06080e7          	jalr	-506(ra) # 80001b32 <myproc>
  switch (n) {
    80002d34:	4795                	li	a5,5
    80002d36:	0497e163          	bltu	a5,s1,80002d78 <argraw+0x58>
    80002d3a:	048a                	slli	s1,s1,0x2
    80002d3c:	00005717          	auipc	a4,0x5
    80002d40:	72470713          	addi	a4,a4,1828 # 80008460 <states.0+0x168>
    80002d44:	94ba                	add	s1,s1,a4
    80002d46:	409c                	lw	a5,0(s1)
    80002d48:	97ba                	add	a5,a5,a4
    80002d4a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d4c:	753c                	ld	a5,104(a0)
    80002d4e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d50:	60e2                	ld	ra,24(sp)
    80002d52:	6442                	ld	s0,16(sp)
    80002d54:	64a2                	ld	s1,8(sp)
    80002d56:	6105                	addi	sp,sp,32
    80002d58:	8082                	ret
    return p->trapframe->a1;
    80002d5a:	753c                	ld	a5,104(a0)
    80002d5c:	7fa8                	ld	a0,120(a5)
    80002d5e:	bfcd                	j	80002d50 <argraw+0x30>
    return p->trapframe->a2;
    80002d60:	753c                	ld	a5,104(a0)
    80002d62:	63c8                	ld	a0,128(a5)
    80002d64:	b7f5                	j	80002d50 <argraw+0x30>
    return p->trapframe->a3;
    80002d66:	753c                	ld	a5,104(a0)
    80002d68:	67c8                	ld	a0,136(a5)
    80002d6a:	b7dd                	j	80002d50 <argraw+0x30>
    return p->trapframe->a4;
    80002d6c:	753c                	ld	a5,104(a0)
    80002d6e:	6bc8                	ld	a0,144(a5)
    80002d70:	b7c5                	j	80002d50 <argraw+0x30>
    return p->trapframe->a5;
    80002d72:	753c                	ld	a5,104(a0)
    80002d74:	6fc8                	ld	a0,152(a5)
    80002d76:	bfe9                	j	80002d50 <argraw+0x30>
  panic("argraw");
    80002d78:	00005517          	auipc	a0,0x5
    80002d7c:	6c050513          	addi	a0,a0,1728 # 80008438 <states.0+0x140>
    80002d80:	ffffd097          	auipc	ra,0xffffd
    80002d84:	7c2080e7          	jalr	1986(ra) # 80000542 <panic>

0000000080002d88 <fetchaddr>:
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	e04a                	sd	s2,0(sp)
    80002d92:	1000                	addi	s0,sp,32
    80002d94:	84aa                	mv	s1,a0
    80002d96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	d9a080e7          	jalr	-614(ra) # 80001b32 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002da0:	653c                	ld	a5,72(a0)
    80002da2:	02f4f863          	bgeu	s1,a5,80002dd2 <fetchaddr+0x4a>
    80002da6:	00848713          	addi	a4,s1,8
    80002daa:	02e7e663          	bltu	a5,a4,80002dd6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dae:	46a1                	li	a3,8
    80002db0:	8626                	mv	a2,s1
    80002db2:	85ca                	mv	a1,s2
    80002db4:	6d28                	ld	a0,88(a0)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	9b6080e7          	jalr	-1610(ra) # 8000176c <copyin>
    80002dbe:	00a03533          	snez	a0,a0
    80002dc2:	40a00533          	neg	a0,a0
}
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6902                	ld	s2,0(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret
    return -1;
    80002dd2:	557d                	li	a0,-1
    80002dd4:	bfcd                	j	80002dc6 <fetchaddr+0x3e>
    80002dd6:	557d                	li	a0,-1
    80002dd8:	b7fd                	j	80002dc6 <fetchaddr+0x3e>

0000000080002dda <fetchstr>:
{
    80002dda:	7179                	addi	sp,sp,-48
    80002ddc:	f406                	sd	ra,40(sp)
    80002dde:	f022                	sd	s0,32(sp)
    80002de0:	ec26                	sd	s1,24(sp)
    80002de2:	e84a                	sd	s2,16(sp)
    80002de4:	e44e                	sd	s3,8(sp)
    80002de6:	1800                	addi	s0,sp,48
    80002de8:	892a                	mv	s2,a0
    80002dea:	84ae                	mv	s1,a1
    80002dec:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	d44080e7          	jalr	-700(ra) # 80001b32 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002df6:	86ce                	mv	a3,s3
    80002df8:	864a                	mv	a2,s2
    80002dfa:	85a6                	mv	a1,s1
    80002dfc:	6d28                	ld	a0,88(a0)
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	9be080e7          	jalr	-1602(ra) # 800017bc <copyinstr>
  if(err < 0)
    80002e06:	00054763          	bltz	a0,80002e14 <fetchstr+0x3a>
  return strlen(buf);
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	072080e7          	jalr	114(ra) # 80000e7e <strlen>
}
    80002e14:	70a2                	ld	ra,40(sp)
    80002e16:	7402                	ld	s0,32(sp)
    80002e18:	64e2                	ld	s1,24(sp)
    80002e1a:	6942                	ld	s2,16(sp)
    80002e1c:	69a2                	ld	s3,8(sp)
    80002e1e:	6145                	addi	sp,sp,48
    80002e20:	8082                	ret

0000000080002e22 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	e426                	sd	s1,8(sp)
    80002e2a:	1000                	addi	s0,sp,32
    80002e2c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	ef2080e7          	jalr	-270(ra) # 80002d20 <argraw>
    80002e36:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e38:	4501                	li	a0,0
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	1000                	addi	s0,sp,32
    80002e4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	ed0080e7          	jalr	-304(ra) # 80002d20 <argraw>
    80002e58:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e5a:	4501                	li	a0,0
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	64a2                	ld	s1,8(sp)
    80002e62:	6105                	addi	sp,sp,32
    80002e64:	8082                	ret

0000000080002e66 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	e04a                	sd	s2,0(sp)
    80002e70:	1000                	addi	s0,sp,32
    80002e72:	84ae                	mv	s1,a1
    80002e74:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	eaa080e7          	jalr	-342(ra) # 80002d20 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e7e:	864a                	mv	a2,s2
    80002e80:	85a6                	mv	a1,s1
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	f58080e7          	jalr	-168(ra) # 80002dda <fetchstr>
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6902                	ld	s2,0(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	e04a                	sd	s2,0(sp)
    80002ea0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	c90080e7          	jalr	-880(ra) # 80001b32 <myproc>
    80002eaa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002eac:	06853903          	ld	s2,104(a0)
    80002eb0:	0a893783          	ld	a5,168(s2)
    80002eb4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eb8:	37fd                	addiw	a5,a5,-1
    80002eba:	4751                	li	a4,20
    80002ebc:	00f76f63          	bltu	a4,a5,80002eda <syscall+0x44>
    80002ec0:	00369713          	slli	a4,a3,0x3
    80002ec4:	00005797          	auipc	a5,0x5
    80002ec8:	5b478793          	addi	a5,a5,1460 # 80008478 <syscalls>
    80002ecc:	97ba                	add	a5,a5,a4
    80002ece:	639c                	ld	a5,0(a5)
    80002ed0:	c789                	beqz	a5,80002eda <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ed2:	9782                	jalr	a5
    80002ed4:	06a93823          	sd	a0,112(s2)
    80002ed8:	a839                	j	80002ef6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eda:	16848613          	addi	a2,s1,360
    80002ede:	5c8c                	lw	a1,56(s1)
    80002ee0:	00005517          	auipc	a0,0x5
    80002ee4:	56050513          	addi	a0,a0,1376 # 80008440 <states.0+0x148>
    80002ee8:	ffffd097          	auipc	ra,0xffffd
    80002eec:	6a4080e7          	jalr	1700(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ef0:	74bc                	ld	a5,104(s1)
    80002ef2:	577d                	li	a4,-1
    80002ef4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6902                	ld	s2,0(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret

0000000080002f02 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f0a:	fec40593          	addi	a1,s0,-20
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	f12080e7          	jalr	-238(ra) # 80002e22 <argint>
    return -1;
    80002f18:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f1a:	00054963          	bltz	a0,80002f2c <sys_exit+0x2a>
  exit(n);
    80002f1e:	fec42503          	lw	a0,-20(s0)
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	3e6080e7          	jalr	998(ra) # 80002308 <exit>
  return 0;  // not reached
    80002f2a:	4781                	li	a5,0
}
    80002f2c:	853e                	mv	a0,a5
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f36:	1141                	addi	sp,sp,-16
    80002f38:	e406                	sd	ra,8(sp)
    80002f3a:	e022                	sd	s0,0(sp)
    80002f3c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	bf4080e7          	jalr	-1036(ra) # 80001b32 <myproc>
}
    80002f46:	5d08                	lw	a0,56(a0)
    80002f48:	60a2                	ld	ra,8(sp)
    80002f4a:	6402                	ld	s0,0(sp)
    80002f4c:	0141                	addi	sp,sp,16
    80002f4e:	8082                	ret

0000000080002f50 <sys_fork>:

uint64
sys_fork(void)
{
    80002f50:	1141                	addi	sp,sp,-16
    80002f52:	e406                	sd	ra,8(sp)
    80002f54:	e022                	sd	s0,0(sp)
    80002f56:	0800                	addi	s0,sp,16
  return fork();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	070080e7          	jalr	112(ra) # 80001fc8 <fork>
}
    80002f60:	60a2                	ld	ra,8(sp)
    80002f62:	6402                	ld	s0,0(sp)
    80002f64:	0141                	addi	sp,sp,16
    80002f66:	8082                	ret

0000000080002f68 <sys_wait>:

uint64
sys_wait(void)
{
    80002f68:	1101                	addi	sp,sp,-32
    80002f6a:	ec06                	sd	ra,24(sp)
    80002f6c:	e822                	sd	s0,16(sp)
    80002f6e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f70:	fe840593          	addi	a1,s0,-24
    80002f74:	4501                	li	a0,0
    80002f76:	00000097          	auipc	ra,0x0
    80002f7a:	ece080e7          	jalr	-306(ra) # 80002e44 <argaddr>
    80002f7e:	87aa                	mv	a5,a0
    return -1;
    80002f80:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f82:	0007c863          	bltz	a5,80002f92 <sys_wait+0x2a>
  return wait(p);
    80002f86:	fe843503          	ld	a0,-24(s0)
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	542080e7          	jalr	1346(ra) # 800024cc <wait>
}
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	1800                	addi	s0,sp,48
  int addr;
  int n;
  struct proc* p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	b8c080e7          	jalr	-1140(ra) # 80001b32 <myproc>
    80002fae:	84aa                	mv	s1,a0

  if(argint(0, &n) < 0)
    80002fb0:	fdc40593          	addi	a1,s0,-36
    80002fb4:	4501                	li	a0,0
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	e6c080e7          	jalr	-404(ra) # 80002e22 <argint>
    80002fbe:	04054663          	bltz	a0,8000300a <sys_sbrk+0x70>
    return -1;
  addr = p->sz;
    80002fc2:	64ac                	ld	a1,72(s1)
    80002fc4:	0005891b          	sext.w	s2,a1
  /*if(growproc(n) < 0)
    return -1;*/
  if(n < 0){ // 若减小页表数立刻执行
    80002fc8:	fdc42603          	lw	a2,-36(s0)
    80002fcc:	00064f63          	bltz	a2,80002fea <sys_sbrk+0x50>
    uvmalloc(p->pagetable, p->sz, p->sz+n);
    kvmdealloc(p->kpagetable, p->sz, p->sz+n);
  }
  p->lazysz = p->sz;  
    80002fd0:	64b8                	ld	a4,72(s1)
    80002fd2:	e8b8                	sd	a4,80(s1)
  p->sz += n; //只改变了技术大小不实际改变内存
    80002fd4:	fdc42783          	lw	a5,-36(s0)
    80002fd8:	97ba                	add	a5,a5,a4
    80002fda:	e4bc                	sd	a5,72(s1)
  return addr;
    80002fdc:	854a                	mv	a0,s2
}
    80002fde:	70a2                	ld	ra,40(sp)
    80002fe0:	7402                	ld	s0,32(sp)
    80002fe2:	64e2                	ld	s1,24(sp)
    80002fe4:	6942                	ld	s2,16(sp)
    80002fe6:	6145                	addi	sp,sp,48
    80002fe8:	8082                	ret
    uvmalloc(p->pagetable, p->sz, p->sz+n);
    80002fea:	962e                	add	a2,a2,a1
    80002fec:	6ca8                	ld	a0,88(s1)
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	4a4080e7          	jalr	1188(ra) # 80001492 <uvmalloc>
    kvmdealloc(p->kpagetable, p->sz, p->sz+n);
    80002ff6:	64ac                	ld	a1,72(s1)
    80002ff8:	fdc42603          	lw	a2,-36(s0)
    80002ffc:	962e                	add	a2,a2,a1
    80002ffe:	70a8                	ld	a0,96(s1)
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	a12080e7          	jalr	-1518(ra) # 80001a12 <kvmdealloc>
    80003008:	b7e1                	j	80002fd0 <sys_sbrk+0x36>
    return -1;
    8000300a:	557d                	li	a0,-1
    8000300c:	bfc9                	j	80002fde <sys_sbrk+0x44>

000000008000300e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000300e:	7139                	addi	sp,sp,-64
    80003010:	fc06                	sd	ra,56(sp)
    80003012:	f822                	sd	s0,48(sp)
    80003014:	f426                	sd	s1,40(sp)
    80003016:	f04a                	sd	s2,32(sp)
    80003018:	ec4e                	sd	s3,24(sp)
    8000301a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000301c:	fcc40593          	addi	a1,s0,-52
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	e00080e7          	jalr	-512(ra) # 80002e22 <argint>
    return -1;
    8000302a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000302c:	06054563          	bltz	a0,80003096 <sys_sleep+0x88>
  acquire(&tickslock);
    80003030:	00015517          	auipc	a0,0x15
    80003034:	b3850513          	addi	a0,a0,-1224 # 80017b68 <tickslock>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	bc6080e7          	jalr	-1082(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80003040:	00006917          	auipc	s2,0x6
    80003044:	fe092903          	lw	s2,-32(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003048:	fcc42783          	lw	a5,-52(s0)
    8000304c:	cf85                	beqz	a5,80003084 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000304e:	00015997          	auipc	s3,0x15
    80003052:	b1a98993          	addi	s3,s3,-1254 # 80017b68 <tickslock>
    80003056:	00006497          	auipc	s1,0x6
    8000305a:	fca48493          	addi	s1,s1,-54 # 80009020 <ticks>
    if(myproc()->killed){
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	ad4080e7          	jalr	-1324(ra) # 80001b32 <myproc>
    80003066:	591c                	lw	a5,48(a0)
    80003068:	ef9d                	bnez	a5,800030a6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000306a:	85ce                	mv	a1,s3
    8000306c:	8526                	mv	a0,s1
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	3e0080e7          	jalr	992(ra) # 8000244e <sleep>
  while(ticks - ticks0 < n){
    80003076:	409c                	lw	a5,0(s1)
    80003078:	412787bb          	subw	a5,a5,s2
    8000307c:	fcc42703          	lw	a4,-52(s0)
    80003080:	fce7efe3          	bltu	a5,a4,8000305e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003084:	00015517          	auipc	a0,0x15
    80003088:	ae450513          	addi	a0,a0,-1308 # 80017b68 <tickslock>
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	c26080e7          	jalr	-986(ra) # 80000cb2 <release>
  return 0;
    80003094:	4781                	li	a5,0
}
    80003096:	853e                	mv	a0,a5
    80003098:	70e2                	ld	ra,56(sp)
    8000309a:	7442                	ld	s0,48(sp)
    8000309c:	74a2                	ld	s1,40(sp)
    8000309e:	7902                	ld	s2,32(sp)
    800030a0:	69e2                	ld	s3,24(sp)
    800030a2:	6121                	addi	sp,sp,64
    800030a4:	8082                	ret
      release(&tickslock);
    800030a6:	00015517          	auipc	a0,0x15
    800030aa:	ac250513          	addi	a0,a0,-1342 # 80017b68 <tickslock>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	c04080e7          	jalr	-1020(ra) # 80000cb2 <release>
      return -1;
    800030b6:	57fd                	li	a5,-1
    800030b8:	bff9                	j	80003096 <sys_sleep+0x88>

00000000800030ba <sys_kill>:

uint64
sys_kill(void)
{
    800030ba:	1101                	addi	sp,sp,-32
    800030bc:	ec06                	sd	ra,24(sp)
    800030be:	e822                	sd	s0,16(sp)
    800030c0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030c2:	fec40593          	addi	a1,s0,-20
    800030c6:	4501                	li	a0,0
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	d5a080e7          	jalr	-678(ra) # 80002e22 <argint>
    800030d0:	87aa                	mv	a5,a0
    return -1;
    800030d2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030d4:	0007c863          	bltz	a5,800030e4 <sys_kill+0x2a>
  return kill(pid);
    800030d8:	fec42503          	lw	a0,-20(s0)
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	55c080e7          	jalr	1372(ra) # 80002638 <kill>
}
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030f6:	00015517          	auipc	a0,0x15
    800030fa:	a7250513          	addi	a0,a0,-1422 # 80017b68 <tickslock>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b00080e7          	jalr	-1280(ra) # 80000bfe <acquire>
  xticks = ticks;
    80003106:	00006497          	auipc	s1,0x6
    8000310a:	f1a4a483          	lw	s1,-230(s1) # 80009020 <ticks>
  release(&tickslock);
    8000310e:	00015517          	auipc	a0,0x15
    80003112:	a5a50513          	addi	a0,a0,-1446 # 80017b68 <tickslock>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b9c080e7          	jalr	-1124(ra) # 80000cb2 <release>
  return xticks;
}
    8000311e:	02049513          	slli	a0,s1,0x20
    80003122:	9101                	srli	a0,a0,0x20
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret

000000008000312e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000312e:	7179                	addi	sp,sp,-48
    80003130:	f406                	sd	ra,40(sp)
    80003132:	f022                	sd	s0,32(sp)
    80003134:	ec26                	sd	s1,24(sp)
    80003136:	e84a                	sd	s2,16(sp)
    80003138:	e44e                	sd	s3,8(sp)
    8000313a:	e052                	sd	s4,0(sp)
    8000313c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000313e:	00005597          	auipc	a1,0x5
    80003142:	3ea58593          	addi	a1,a1,1002 # 80008528 <syscalls+0xb0>
    80003146:	00015517          	auipc	a0,0x15
    8000314a:	a3a50513          	addi	a0,a0,-1478 # 80017b80 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	a20080e7          	jalr	-1504(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003156:	0001d797          	auipc	a5,0x1d
    8000315a:	a2a78793          	addi	a5,a5,-1494 # 8001fb80 <bcache+0x8000>
    8000315e:	0001d717          	auipc	a4,0x1d
    80003162:	c8a70713          	addi	a4,a4,-886 # 8001fde8 <bcache+0x8268>
    80003166:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000316a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000316e:	00015497          	auipc	s1,0x15
    80003172:	a2a48493          	addi	s1,s1,-1494 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    80003176:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003178:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000317a:	00005a17          	auipc	s4,0x5
    8000317e:	3b6a0a13          	addi	s4,s4,950 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003182:	2b893783          	ld	a5,696(s2)
    80003186:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003188:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000318c:	85d2                	mv	a1,s4
    8000318e:	01048513          	addi	a0,s1,16
    80003192:	00001097          	auipc	ra,0x1
    80003196:	4ac080e7          	jalr	1196(ra) # 8000463e <initsleeplock>
    bcache.head.next->prev = b;
    8000319a:	2b893783          	ld	a5,696(s2)
    8000319e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031a4:	45848493          	addi	s1,s1,1112
    800031a8:	fd349de3          	bne	s1,s3,80003182 <binit+0x54>
  }
}
    800031ac:	70a2                	ld	ra,40(sp)
    800031ae:	7402                	ld	s0,32(sp)
    800031b0:	64e2                	ld	s1,24(sp)
    800031b2:	6942                	ld	s2,16(sp)
    800031b4:	69a2                	ld	s3,8(sp)
    800031b6:	6a02                	ld	s4,0(sp)
    800031b8:	6145                	addi	sp,sp,48
    800031ba:	8082                	ret

00000000800031bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031bc:	7179                	addi	sp,sp,-48
    800031be:	f406                	sd	ra,40(sp)
    800031c0:	f022                	sd	s0,32(sp)
    800031c2:	ec26                	sd	s1,24(sp)
    800031c4:	e84a                	sd	s2,16(sp)
    800031c6:	e44e                	sd	s3,8(sp)
    800031c8:	1800                	addi	s0,sp,48
    800031ca:	892a                	mv	s2,a0
    800031cc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031ce:	00015517          	auipc	a0,0x15
    800031d2:	9b250513          	addi	a0,a0,-1614 # 80017b80 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	a28080e7          	jalr	-1496(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031de:	0001d497          	auipc	s1,0x1d
    800031e2:	c5a4b483          	ld	s1,-934(s1) # 8001fe38 <bcache+0x82b8>
    800031e6:	0001d797          	auipc	a5,0x1d
    800031ea:	c0278793          	addi	a5,a5,-1022 # 8001fde8 <bcache+0x8268>
    800031ee:	02f48f63          	beq	s1,a5,8000322c <bread+0x70>
    800031f2:	873e                	mv	a4,a5
    800031f4:	a021                	j	800031fc <bread+0x40>
    800031f6:	68a4                	ld	s1,80(s1)
    800031f8:	02e48a63          	beq	s1,a4,8000322c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031fc:	449c                	lw	a5,8(s1)
    800031fe:	ff279ce3          	bne	a5,s2,800031f6 <bread+0x3a>
    80003202:	44dc                	lw	a5,12(s1)
    80003204:	ff3799e3          	bne	a5,s3,800031f6 <bread+0x3a>
      b->refcnt++;
    80003208:	40bc                	lw	a5,64(s1)
    8000320a:	2785                	addiw	a5,a5,1
    8000320c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000320e:	00015517          	auipc	a0,0x15
    80003212:	97250513          	addi	a0,a0,-1678 # 80017b80 <bcache>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	a9c080e7          	jalr	-1380(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    8000321e:	01048513          	addi	a0,s1,16
    80003222:	00001097          	auipc	ra,0x1
    80003226:	456080e7          	jalr	1110(ra) # 80004678 <acquiresleep>
      return b;
    8000322a:	a8b9                	j	80003288 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000322c:	0001d497          	auipc	s1,0x1d
    80003230:	c044b483          	ld	s1,-1020(s1) # 8001fe30 <bcache+0x82b0>
    80003234:	0001d797          	auipc	a5,0x1d
    80003238:	bb478793          	addi	a5,a5,-1100 # 8001fde8 <bcache+0x8268>
    8000323c:	00f48863          	beq	s1,a5,8000324c <bread+0x90>
    80003240:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003242:	40bc                	lw	a5,64(s1)
    80003244:	cf81                	beqz	a5,8000325c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003246:	64a4                	ld	s1,72(s1)
    80003248:	fee49de3          	bne	s1,a4,80003242 <bread+0x86>
  panic("bget: no buffers");
    8000324c:	00005517          	auipc	a0,0x5
    80003250:	2ec50513          	addi	a0,a0,748 # 80008538 <syscalls+0xc0>
    80003254:	ffffd097          	auipc	ra,0xffffd
    80003258:	2ee080e7          	jalr	750(ra) # 80000542 <panic>
      b->dev = dev;
    8000325c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003260:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003264:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003268:	4785                	li	a5,1
    8000326a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000326c:	00015517          	auipc	a0,0x15
    80003270:	91450513          	addi	a0,a0,-1772 # 80017b80 <bcache>
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	a3e080e7          	jalr	-1474(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    8000327c:	01048513          	addi	a0,s1,16
    80003280:	00001097          	auipc	ra,0x1
    80003284:	3f8080e7          	jalr	1016(ra) # 80004678 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003288:	409c                	lw	a5,0(s1)
    8000328a:	cb89                	beqz	a5,8000329c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000328c:	8526                	mv	a0,s1
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6942                	ld	s2,16(sp)
    80003296:	69a2                	ld	s3,8(sp)
    80003298:	6145                	addi	sp,sp,48
    8000329a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000329c:	4581                	li	a1,0
    8000329e:	8526                	mv	a0,s1
    800032a0:	00003097          	auipc	ra,0x3
    800032a4:	f7c080e7          	jalr	-132(ra) # 8000621c <virtio_disk_rw>
    b->valid = 1;
    800032a8:	4785                	li	a5,1
    800032aa:	c09c                	sw	a5,0(s1)
  return b;
    800032ac:	b7c5                	j	8000328c <bread+0xd0>

00000000800032ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	e426                	sd	s1,8(sp)
    800032b6:	1000                	addi	s0,sp,32
    800032b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ba:	0541                	addi	a0,a0,16
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	456080e7          	jalr	1110(ra) # 80004712 <holdingsleep>
    800032c4:	cd01                	beqz	a0,800032dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032c6:	4585                	li	a1,1
    800032c8:	8526                	mv	a0,s1
    800032ca:	00003097          	auipc	ra,0x3
    800032ce:	f52080e7          	jalr	-174(ra) # 8000621c <virtio_disk_rw>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6105                	addi	sp,sp,32
    800032da:	8082                	ret
    panic("bwrite");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	27450513          	addi	a0,a0,628 # 80008550 <syscalls+0xd8>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	25e080e7          	jalr	606(ra) # 80000542 <panic>

00000000800032ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032ec:	1101                	addi	sp,sp,-32
    800032ee:	ec06                	sd	ra,24(sp)
    800032f0:	e822                	sd	s0,16(sp)
    800032f2:	e426                	sd	s1,8(sp)
    800032f4:	e04a                	sd	s2,0(sp)
    800032f6:	1000                	addi	s0,sp,32
    800032f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032fa:	01050913          	addi	s2,a0,16
    800032fe:	854a                	mv	a0,s2
    80003300:	00001097          	auipc	ra,0x1
    80003304:	412080e7          	jalr	1042(ra) # 80004712 <holdingsleep>
    80003308:	c92d                	beqz	a0,8000337a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	3c2080e7          	jalr	962(ra) # 800046ce <releasesleep>

  acquire(&bcache.lock);
    80003314:	00015517          	auipc	a0,0x15
    80003318:	86c50513          	addi	a0,a0,-1940 # 80017b80 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	8e2080e7          	jalr	-1822(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003324:	40bc                	lw	a5,64(s1)
    80003326:	37fd                	addiw	a5,a5,-1
    80003328:	0007871b          	sext.w	a4,a5
    8000332c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000332e:	eb05                	bnez	a4,8000335e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003330:	68bc                	ld	a5,80(s1)
    80003332:	64b8                	ld	a4,72(s1)
    80003334:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003336:	64bc                	ld	a5,72(s1)
    80003338:	68b8                	ld	a4,80(s1)
    8000333a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000333c:	0001d797          	auipc	a5,0x1d
    80003340:	84478793          	addi	a5,a5,-1980 # 8001fb80 <bcache+0x8000>
    80003344:	2b87b703          	ld	a4,696(a5)
    80003348:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000334a:	0001d717          	auipc	a4,0x1d
    8000334e:	a9e70713          	addi	a4,a4,-1378 # 8001fde8 <bcache+0x8268>
    80003352:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003354:	2b87b703          	ld	a4,696(a5)
    80003358:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000335a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000335e:	00015517          	auipc	a0,0x15
    80003362:	82250513          	addi	a0,a0,-2014 # 80017b80 <bcache>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	94c080e7          	jalr	-1716(ra) # 80000cb2 <release>
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6902                	ld	s2,0(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret
    panic("brelse");
    8000337a:	00005517          	auipc	a0,0x5
    8000337e:	1de50513          	addi	a0,a0,478 # 80008558 <syscalls+0xe0>
    80003382:	ffffd097          	auipc	ra,0xffffd
    80003386:	1c0080e7          	jalr	448(ra) # 80000542 <panic>

000000008000338a <bpin>:

void
bpin(struct buf *b) {
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	e426                	sd	s1,8(sp)
    80003392:	1000                	addi	s0,sp,32
    80003394:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	7ea50513          	addi	a0,a0,2026 # 80017b80 <bcache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	860080e7          	jalr	-1952(ra) # 80000bfe <acquire>
  b->refcnt++;
    800033a6:	40bc                	lw	a5,64(s1)
    800033a8:	2785                	addiw	a5,a5,1
    800033aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033ac:	00014517          	auipc	a0,0x14
    800033b0:	7d450513          	addi	a0,a0,2004 # 80017b80 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	8fe080e7          	jalr	-1794(ra) # 80000cb2 <release>
}
    800033bc:	60e2                	ld	ra,24(sp)
    800033be:	6442                	ld	s0,16(sp)
    800033c0:	64a2                	ld	s1,8(sp)
    800033c2:	6105                	addi	sp,sp,32
    800033c4:	8082                	ret

00000000800033c6 <bunpin>:

void
bunpin(struct buf *b) {
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	1000                	addi	s0,sp,32
    800033d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033d2:	00014517          	auipc	a0,0x14
    800033d6:	7ae50513          	addi	a0,a0,1966 # 80017b80 <bcache>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	824080e7          	jalr	-2012(ra) # 80000bfe <acquire>
  b->refcnt--;
    800033e2:	40bc                	lw	a5,64(s1)
    800033e4:	37fd                	addiw	a5,a5,-1
    800033e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033e8:	00014517          	auipc	a0,0x14
    800033ec:	79850513          	addi	a0,a0,1944 # 80017b80 <bcache>
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	8c2080e7          	jalr	-1854(ra) # 80000cb2 <release>
}
    800033f8:	60e2                	ld	ra,24(sp)
    800033fa:	6442                	ld	s0,16(sp)
    800033fc:	64a2                	ld	s1,8(sp)
    800033fe:	6105                	addi	sp,sp,32
    80003400:	8082                	ret

0000000080003402 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	e04a                	sd	s2,0(sp)
    8000340c:	1000                	addi	s0,sp,32
    8000340e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003410:	00d5d59b          	srliw	a1,a1,0xd
    80003414:	0001d797          	auipc	a5,0x1d
    80003418:	e487a783          	lw	a5,-440(a5) # 8002025c <sb+0x1c>
    8000341c:	9dbd                	addw	a1,a1,a5
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	d9e080e7          	jalr	-610(ra) # 800031bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003426:	0074f713          	andi	a4,s1,7
    8000342a:	4785                	li	a5,1
    8000342c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003430:	14ce                	slli	s1,s1,0x33
    80003432:	90d9                	srli	s1,s1,0x36
    80003434:	00950733          	add	a4,a0,s1
    80003438:	05874703          	lbu	a4,88(a4)
    8000343c:	00e7f6b3          	and	a3,a5,a4
    80003440:	c69d                	beqz	a3,8000346e <bfree+0x6c>
    80003442:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003444:	94aa                	add	s1,s1,a0
    80003446:	fff7c793          	not	a5,a5
    8000344a:	8ff9                	and	a5,a5,a4
    8000344c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003450:	00001097          	auipc	ra,0x1
    80003454:	100080e7          	jalr	256(ra) # 80004550 <log_write>
  brelse(bp);
    80003458:	854a                	mv	a0,s2
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	e92080e7          	jalr	-366(ra) # 800032ec <brelse>
}
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6902                	ld	s2,0(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret
    panic("freeing free block");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	0f250513          	addi	a0,a0,242 # 80008560 <syscalls+0xe8>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	0cc080e7          	jalr	204(ra) # 80000542 <panic>

000000008000347e <balloc>:
{
    8000347e:	711d                	addi	sp,sp,-96
    80003480:	ec86                	sd	ra,88(sp)
    80003482:	e8a2                	sd	s0,80(sp)
    80003484:	e4a6                	sd	s1,72(sp)
    80003486:	e0ca                	sd	s2,64(sp)
    80003488:	fc4e                	sd	s3,56(sp)
    8000348a:	f852                	sd	s4,48(sp)
    8000348c:	f456                	sd	s5,40(sp)
    8000348e:	f05a                	sd	s6,32(sp)
    80003490:	ec5e                	sd	s7,24(sp)
    80003492:	e862                	sd	s8,16(sp)
    80003494:	e466                	sd	s9,8(sp)
    80003496:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003498:	0001d797          	auipc	a5,0x1d
    8000349c:	dac7a783          	lw	a5,-596(a5) # 80020244 <sb+0x4>
    800034a0:	cbd1                	beqz	a5,80003534 <balloc+0xb6>
    800034a2:	8baa                	mv	s7,a0
    800034a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034a6:	0001db17          	auipc	s6,0x1d
    800034aa:	d9ab0b13          	addi	s6,s6,-614 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034b4:	6c89                	lui	s9,0x2
    800034b6:	a831                	j	800034d2 <balloc+0x54>
    brelse(bp);
    800034b8:	854a                	mv	a0,s2
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e32080e7          	jalr	-462(ra) # 800032ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034c2:	015c87bb          	addw	a5,s9,s5
    800034c6:	00078a9b          	sext.w	s5,a5
    800034ca:	004b2703          	lw	a4,4(s6)
    800034ce:	06eaf363          	bgeu	s5,a4,80003534 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034d2:	41fad79b          	sraiw	a5,s5,0x1f
    800034d6:	0137d79b          	srliw	a5,a5,0x13
    800034da:	015787bb          	addw	a5,a5,s5
    800034de:	40d7d79b          	sraiw	a5,a5,0xd
    800034e2:	01cb2583          	lw	a1,28(s6)
    800034e6:	9dbd                	addw	a1,a1,a5
    800034e8:	855e                	mv	a0,s7
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	cd2080e7          	jalr	-814(ra) # 800031bc <bread>
    800034f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f4:	004b2503          	lw	a0,4(s6)
    800034f8:	000a849b          	sext.w	s1,s5
    800034fc:	8662                	mv	a2,s8
    800034fe:	faa4fde3          	bgeu	s1,a0,800034b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003502:	41f6579b          	sraiw	a5,a2,0x1f
    80003506:	01d7d69b          	srliw	a3,a5,0x1d
    8000350a:	00c6873b          	addw	a4,a3,a2
    8000350e:	00777793          	andi	a5,a4,7
    80003512:	9f95                	subw	a5,a5,a3
    80003514:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003518:	4037571b          	sraiw	a4,a4,0x3
    8000351c:	00e906b3          	add	a3,s2,a4
    80003520:	0586c683          	lbu	a3,88(a3)
    80003524:	00d7f5b3          	and	a1,a5,a3
    80003528:	cd91                	beqz	a1,80003544 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352a:	2605                	addiw	a2,a2,1
    8000352c:	2485                	addiw	s1,s1,1
    8000352e:	fd4618e3          	bne	a2,s4,800034fe <balloc+0x80>
    80003532:	b759                	j	800034b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	04450513          	addi	a0,a0,68 # 80008578 <syscalls+0x100>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	006080e7          	jalr	6(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003544:	974a                	add	a4,a4,s2
    80003546:	8fd5                	or	a5,a5,a3
    80003548:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000354c:	854a                	mv	a0,s2
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	002080e7          	jalr	2(ra) # 80004550 <log_write>
        brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	d94080e7          	jalr	-620(ra) # 800032ec <brelse>
  bp = bread(dev, bno);
    80003560:	85a6                	mv	a1,s1
    80003562:	855e                	mv	a0,s7
    80003564:	00000097          	auipc	ra,0x0
    80003568:	c58080e7          	jalr	-936(ra) # 800031bc <bread>
    8000356c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000356e:	40000613          	li	a2,1024
    80003572:	4581                	li	a1,0
    80003574:	05850513          	addi	a0,a0,88
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	782080e7          	jalr	1922(ra) # 80000cfa <memset>
  log_write(bp);
    80003580:	854a                	mv	a0,s2
    80003582:	00001097          	auipc	ra,0x1
    80003586:	fce080e7          	jalr	-50(ra) # 80004550 <log_write>
  brelse(bp);
    8000358a:	854a                	mv	a0,s2
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	d60080e7          	jalr	-672(ra) # 800032ec <brelse>
}
    80003594:	8526                	mv	a0,s1
    80003596:	60e6                	ld	ra,88(sp)
    80003598:	6446                	ld	s0,80(sp)
    8000359a:	64a6                	ld	s1,72(sp)
    8000359c:	6906                	ld	s2,64(sp)
    8000359e:	79e2                	ld	s3,56(sp)
    800035a0:	7a42                	ld	s4,48(sp)
    800035a2:	7aa2                	ld	s5,40(sp)
    800035a4:	7b02                	ld	s6,32(sp)
    800035a6:	6be2                	ld	s7,24(sp)
    800035a8:	6c42                	ld	s8,16(sp)
    800035aa:	6ca2                	ld	s9,8(sp)
    800035ac:	6125                	addi	sp,sp,96
    800035ae:	8082                	ret

00000000800035b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035b0:	7179                	addi	sp,sp,-48
    800035b2:	f406                	sd	ra,40(sp)
    800035b4:	f022                	sd	s0,32(sp)
    800035b6:	ec26                	sd	s1,24(sp)
    800035b8:	e84a                	sd	s2,16(sp)
    800035ba:	e44e                	sd	s3,8(sp)
    800035bc:	e052                	sd	s4,0(sp)
    800035be:	1800                	addi	s0,sp,48
    800035c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035c2:	47ad                	li	a5,11
    800035c4:	04b7fe63          	bgeu	a5,a1,80003620 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035c8:	ff45849b          	addiw	s1,a1,-12
    800035cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035d0:	0ff00793          	li	a5,255
    800035d4:	0ae7e363          	bltu	a5,a4,8000367a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035d8:	08052583          	lw	a1,128(a0)
    800035dc:	c5ad                	beqz	a1,80003646 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035de:	00092503          	lw	a0,0(s2)
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	bda080e7          	jalr	-1062(ra) # 800031bc <bread>
    800035ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035f0:	02049593          	slli	a1,s1,0x20
    800035f4:	9181                	srli	a1,a1,0x20
    800035f6:	058a                	slli	a1,a1,0x2
    800035f8:	00b784b3          	add	s1,a5,a1
    800035fc:	0004a983          	lw	s3,0(s1)
    80003600:	04098d63          	beqz	s3,8000365a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003604:	8552                	mv	a0,s4
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	ce6080e7          	jalr	-794(ra) # 800032ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000360e:	854e                	mv	a0,s3
    80003610:	70a2                	ld	ra,40(sp)
    80003612:	7402                	ld	s0,32(sp)
    80003614:	64e2                	ld	s1,24(sp)
    80003616:	6942                	ld	s2,16(sp)
    80003618:	69a2                	ld	s3,8(sp)
    8000361a:	6a02                	ld	s4,0(sp)
    8000361c:	6145                	addi	sp,sp,48
    8000361e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003620:	02059493          	slli	s1,a1,0x20
    80003624:	9081                	srli	s1,s1,0x20
    80003626:	048a                	slli	s1,s1,0x2
    80003628:	94aa                	add	s1,s1,a0
    8000362a:	0504a983          	lw	s3,80(s1)
    8000362e:	fe0990e3          	bnez	s3,8000360e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003632:	4108                	lw	a0,0(a0)
    80003634:	00000097          	auipc	ra,0x0
    80003638:	e4a080e7          	jalr	-438(ra) # 8000347e <balloc>
    8000363c:	0005099b          	sext.w	s3,a0
    80003640:	0534a823          	sw	s3,80(s1)
    80003644:	b7e9                	j	8000360e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003646:	4108                	lw	a0,0(a0)
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	e36080e7          	jalr	-458(ra) # 8000347e <balloc>
    80003650:	0005059b          	sext.w	a1,a0
    80003654:	08b92023          	sw	a1,128(s2)
    80003658:	b759                	j	800035de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000365a:	00092503          	lw	a0,0(s2)
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	e20080e7          	jalr	-480(ra) # 8000347e <balloc>
    80003666:	0005099b          	sext.w	s3,a0
    8000366a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000366e:	8552                	mv	a0,s4
    80003670:	00001097          	auipc	ra,0x1
    80003674:	ee0080e7          	jalr	-288(ra) # 80004550 <log_write>
    80003678:	b771                	j	80003604 <bmap+0x54>
  panic("bmap: out of range");
    8000367a:	00005517          	auipc	a0,0x5
    8000367e:	f1650513          	addi	a0,a0,-234 # 80008590 <syscalls+0x118>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	ec0080e7          	jalr	-320(ra) # 80000542 <panic>

000000008000368a <iget>:
{
    8000368a:	7179                	addi	sp,sp,-48
    8000368c:	f406                	sd	ra,40(sp)
    8000368e:	f022                	sd	s0,32(sp)
    80003690:	ec26                	sd	s1,24(sp)
    80003692:	e84a                	sd	s2,16(sp)
    80003694:	e44e                	sd	s3,8(sp)
    80003696:	e052                	sd	s4,0(sp)
    80003698:	1800                	addi	s0,sp,48
    8000369a:	89aa                	mv	s3,a0
    8000369c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000369e:	0001d517          	auipc	a0,0x1d
    800036a2:	bc250513          	addi	a0,a0,-1086 # 80020260 <icache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	558080e7          	jalr	1368(ra) # 80000bfe <acquire>
  empty = 0;
    800036ae:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036b0:	0001d497          	auipc	s1,0x1d
    800036b4:	bc848493          	addi	s1,s1,-1080 # 80020278 <icache+0x18>
    800036b8:	0001e697          	auipc	a3,0x1e
    800036bc:	65068693          	addi	a3,a3,1616 # 80021d08 <log>
    800036c0:	a039                	j	800036ce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c2:	02090b63          	beqz	s2,800036f8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036c6:	08848493          	addi	s1,s1,136
    800036ca:	02d48a63          	beq	s1,a3,800036fe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036ce:	449c                	lw	a5,8(s1)
    800036d0:	fef059e3          	blez	a5,800036c2 <iget+0x38>
    800036d4:	4098                	lw	a4,0(s1)
    800036d6:	ff3716e3          	bne	a4,s3,800036c2 <iget+0x38>
    800036da:	40d8                	lw	a4,4(s1)
    800036dc:	ff4713e3          	bne	a4,s4,800036c2 <iget+0x38>
      ip->ref++;
    800036e0:	2785                	addiw	a5,a5,1
    800036e2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036e4:	0001d517          	auipc	a0,0x1d
    800036e8:	b7c50513          	addi	a0,a0,-1156 # 80020260 <icache>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5c6080e7          	jalr	1478(ra) # 80000cb2 <release>
      return ip;
    800036f4:	8926                	mv	s2,s1
    800036f6:	a03d                	j	80003724 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036f8:	f7f9                	bnez	a5,800036c6 <iget+0x3c>
    800036fa:	8926                	mv	s2,s1
    800036fc:	b7e9                	j	800036c6 <iget+0x3c>
  if(empty == 0)
    800036fe:	02090c63          	beqz	s2,80003736 <iget+0xac>
  ip->dev = dev;
    80003702:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003706:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000370a:	4785                	li	a5,1
    8000370c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003710:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003714:	0001d517          	auipc	a0,0x1d
    80003718:	b4c50513          	addi	a0,a0,-1204 # 80020260 <icache>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	596080e7          	jalr	1430(ra) # 80000cb2 <release>
}
    80003724:	854a                	mv	a0,s2
    80003726:	70a2                	ld	ra,40(sp)
    80003728:	7402                	ld	s0,32(sp)
    8000372a:	64e2                	ld	s1,24(sp)
    8000372c:	6942                	ld	s2,16(sp)
    8000372e:	69a2                	ld	s3,8(sp)
    80003730:	6a02                	ld	s4,0(sp)
    80003732:	6145                	addi	sp,sp,48
    80003734:	8082                	ret
    panic("iget: no inodes");
    80003736:	00005517          	auipc	a0,0x5
    8000373a:	e7250513          	addi	a0,a0,-398 # 800085a8 <syscalls+0x130>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	e04080e7          	jalr	-508(ra) # 80000542 <panic>

0000000080003746 <fsinit>:
fsinit(int dev) {
    80003746:	7179                	addi	sp,sp,-48
    80003748:	f406                	sd	ra,40(sp)
    8000374a:	f022                	sd	s0,32(sp)
    8000374c:	ec26                	sd	s1,24(sp)
    8000374e:	e84a                	sd	s2,16(sp)
    80003750:	e44e                	sd	s3,8(sp)
    80003752:	1800                	addi	s0,sp,48
    80003754:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003756:	4585                	li	a1,1
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	a64080e7          	jalr	-1436(ra) # 800031bc <bread>
    80003760:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003762:	0001d997          	auipc	s3,0x1d
    80003766:	ade98993          	addi	s3,s3,-1314 # 80020240 <sb>
    8000376a:	02000613          	li	a2,32
    8000376e:	05850593          	addi	a1,a0,88
    80003772:	854e                	mv	a0,s3
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	5e2080e7          	jalr	1506(ra) # 80000d56 <memmove>
  brelse(bp);
    8000377c:	8526                	mv	a0,s1
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	b6e080e7          	jalr	-1170(ra) # 800032ec <brelse>
  if(sb.magic != FSMAGIC)
    80003786:	0009a703          	lw	a4,0(s3)
    8000378a:	102037b7          	lui	a5,0x10203
    8000378e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003792:	02f71263          	bne	a4,a5,800037b6 <fsinit+0x70>
  initlog(dev, &sb);
    80003796:	0001d597          	auipc	a1,0x1d
    8000379a:	aaa58593          	addi	a1,a1,-1366 # 80020240 <sb>
    8000379e:	854a                	mv	a0,s2
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	b38080e7          	jalr	-1224(ra) # 800042d8 <initlog>
}
    800037a8:	70a2                	ld	ra,40(sp)
    800037aa:	7402                	ld	s0,32(sp)
    800037ac:	64e2                	ld	s1,24(sp)
    800037ae:	6942                	ld	s2,16(sp)
    800037b0:	69a2                	ld	s3,8(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    panic("invalid file system");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	e0250513          	addi	a0,a0,-510 # 800085b8 <syscalls+0x140>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d84080e7          	jalr	-636(ra) # 80000542 <panic>

00000000800037c6 <iinit>:
{
    800037c6:	7179                	addi	sp,sp,-48
    800037c8:	f406                	sd	ra,40(sp)
    800037ca:	f022                	sd	s0,32(sp)
    800037cc:	ec26                	sd	s1,24(sp)
    800037ce:	e84a                	sd	s2,16(sp)
    800037d0:	e44e                	sd	s3,8(sp)
    800037d2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800037d4:	00005597          	auipc	a1,0x5
    800037d8:	dfc58593          	addi	a1,a1,-516 # 800085d0 <syscalls+0x158>
    800037dc:	0001d517          	auipc	a0,0x1d
    800037e0:	a8450513          	addi	a0,a0,-1404 # 80020260 <icache>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	38a080e7          	jalr	906(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ec:	0001d497          	auipc	s1,0x1d
    800037f0:	a9c48493          	addi	s1,s1,-1380 # 80020288 <icache+0x28>
    800037f4:	0001e997          	auipc	s3,0x1e
    800037f8:	52498993          	addi	s3,s3,1316 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037fc:	00005917          	auipc	s2,0x5
    80003800:	ddc90913          	addi	s2,s2,-548 # 800085d8 <syscalls+0x160>
    80003804:	85ca                	mv	a1,s2
    80003806:	8526                	mv	a0,s1
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	e36080e7          	jalr	-458(ra) # 8000463e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003810:	08848493          	addi	s1,s1,136
    80003814:	ff3498e3          	bne	s1,s3,80003804 <iinit+0x3e>
}
    80003818:	70a2                	ld	ra,40(sp)
    8000381a:	7402                	ld	s0,32(sp)
    8000381c:	64e2                	ld	s1,24(sp)
    8000381e:	6942                	ld	s2,16(sp)
    80003820:	69a2                	ld	s3,8(sp)
    80003822:	6145                	addi	sp,sp,48
    80003824:	8082                	ret

0000000080003826 <ialloc>:
{
    80003826:	715d                	addi	sp,sp,-80
    80003828:	e486                	sd	ra,72(sp)
    8000382a:	e0a2                	sd	s0,64(sp)
    8000382c:	fc26                	sd	s1,56(sp)
    8000382e:	f84a                	sd	s2,48(sp)
    80003830:	f44e                	sd	s3,40(sp)
    80003832:	f052                	sd	s4,32(sp)
    80003834:	ec56                	sd	s5,24(sp)
    80003836:	e85a                	sd	s6,16(sp)
    80003838:	e45e                	sd	s7,8(sp)
    8000383a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000383c:	0001d717          	auipc	a4,0x1d
    80003840:	a1072703          	lw	a4,-1520(a4) # 8002024c <sb+0xc>
    80003844:	4785                	li	a5,1
    80003846:	04e7fa63          	bgeu	a5,a4,8000389a <ialloc+0x74>
    8000384a:	8aaa                	mv	s5,a0
    8000384c:	8bae                	mv	s7,a1
    8000384e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003850:	0001da17          	auipc	s4,0x1d
    80003854:	9f0a0a13          	addi	s4,s4,-1552 # 80020240 <sb>
    80003858:	00048b1b          	sext.w	s6,s1
    8000385c:	0044d793          	srli	a5,s1,0x4
    80003860:	018a2583          	lw	a1,24(s4)
    80003864:	9dbd                	addw	a1,a1,a5
    80003866:	8556                	mv	a0,s5
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	954080e7          	jalr	-1708(ra) # 800031bc <bread>
    80003870:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003872:	05850993          	addi	s3,a0,88
    80003876:	00f4f793          	andi	a5,s1,15
    8000387a:	079a                	slli	a5,a5,0x6
    8000387c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000387e:	00099783          	lh	a5,0(s3)
    80003882:	c785                	beqz	a5,800038aa <ialloc+0x84>
    brelse(bp);
    80003884:	00000097          	auipc	ra,0x0
    80003888:	a68080e7          	jalr	-1432(ra) # 800032ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000388c:	0485                	addi	s1,s1,1
    8000388e:	00ca2703          	lw	a4,12(s4)
    80003892:	0004879b          	sext.w	a5,s1
    80003896:	fce7e1e3          	bltu	a5,a4,80003858 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	d4650513          	addi	a0,a0,-698 # 800085e0 <syscalls+0x168>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	ca0080e7          	jalr	-864(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800038aa:	04000613          	li	a2,64
    800038ae:	4581                	li	a1,0
    800038b0:	854e                	mv	a0,s3
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	448080e7          	jalr	1096(ra) # 80000cfa <memset>
      dip->type = type;
    800038ba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038be:	854a                	mv	a0,s2
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	c90080e7          	jalr	-880(ra) # 80004550 <log_write>
      brelse(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	a22080e7          	jalr	-1502(ra) # 800032ec <brelse>
      return iget(dev, inum);
    800038d2:	85da                	mv	a1,s6
    800038d4:	8556                	mv	a0,s5
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	db4080e7          	jalr	-588(ra) # 8000368a <iget>
}
    800038de:	60a6                	ld	ra,72(sp)
    800038e0:	6406                	ld	s0,64(sp)
    800038e2:	74e2                	ld	s1,56(sp)
    800038e4:	7942                	ld	s2,48(sp)
    800038e6:	79a2                	ld	s3,40(sp)
    800038e8:	7a02                	ld	s4,32(sp)
    800038ea:	6ae2                	ld	s5,24(sp)
    800038ec:	6b42                	ld	s6,16(sp)
    800038ee:	6ba2                	ld	s7,8(sp)
    800038f0:	6161                	addi	sp,sp,80
    800038f2:	8082                	ret

00000000800038f4 <iupdate>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003902:	415c                	lw	a5,4(a0)
    80003904:	0047d79b          	srliw	a5,a5,0x4
    80003908:	0001d597          	auipc	a1,0x1d
    8000390c:	9505a583          	lw	a1,-1712(a1) # 80020258 <sb+0x18>
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	4108                	lw	a0,0(a0)
    80003914:	00000097          	auipc	ra,0x0
    80003918:	8a8080e7          	jalr	-1880(ra) # 800031bc <bread>
    8000391c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000391e:	05850793          	addi	a5,a0,88
    80003922:	40c8                	lw	a0,4(s1)
    80003924:	893d                	andi	a0,a0,15
    80003926:	051a                	slli	a0,a0,0x6
    80003928:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000392a:	04449703          	lh	a4,68(s1)
    8000392e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003932:	04649703          	lh	a4,70(s1)
    80003936:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000393a:	04849703          	lh	a4,72(s1)
    8000393e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003942:	04a49703          	lh	a4,74(s1)
    80003946:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000394a:	44f8                	lw	a4,76(s1)
    8000394c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000394e:	03400613          	li	a2,52
    80003952:	05048593          	addi	a1,s1,80
    80003956:	0531                	addi	a0,a0,12
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	3fe080e7          	jalr	1022(ra) # 80000d56 <memmove>
  log_write(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	00001097          	auipc	ra,0x1
    80003966:	bee080e7          	jalr	-1042(ra) # 80004550 <log_write>
  brelse(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	980080e7          	jalr	-1664(ra) # 800032ec <brelse>
}
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6902                	ld	s2,0(sp)
    8000397c:	6105                	addi	sp,sp,32
    8000397e:	8082                	ret

0000000080003980 <idup>:
{
    80003980:	1101                	addi	sp,sp,-32
    80003982:	ec06                	sd	ra,24(sp)
    80003984:	e822                	sd	s0,16(sp)
    80003986:	e426                	sd	s1,8(sp)
    80003988:	1000                	addi	s0,sp,32
    8000398a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000398c:	0001d517          	auipc	a0,0x1d
    80003990:	8d450513          	addi	a0,a0,-1836 # 80020260 <icache>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	26a080e7          	jalr	618(ra) # 80000bfe <acquire>
  ip->ref++;
    8000399c:	449c                	lw	a5,8(s1)
    8000399e:	2785                	addiw	a5,a5,1
    800039a0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039a2:	0001d517          	auipc	a0,0x1d
    800039a6:	8be50513          	addi	a0,a0,-1858 # 80020260 <icache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	308080e7          	jalr	776(ra) # 80000cb2 <release>
}
    800039b2:	8526                	mv	a0,s1
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6105                	addi	sp,sp,32
    800039bc:	8082                	ret

00000000800039be <ilock>:
{
    800039be:	1101                	addi	sp,sp,-32
    800039c0:	ec06                	sd	ra,24(sp)
    800039c2:	e822                	sd	s0,16(sp)
    800039c4:	e426                	sd	s1,8(sp)
    800039c6:	e04a                	sd	s2,0(sp)
    800039c8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039ca:	c115                	beqz	a0,800039ee <ilock+0x30>
    800039cc:	84aa                	mv	s1,a0
    800039ce:	451c                	lw	a5,8(a0)
    800039d0:	00f05f63          	blez	a5,800039ee <ilock+0x30>
  acquiresleep(&ip->lock);
    800039d4:	0541                	addi	a0,a0,16
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	ca2080e7          	jalr	-862(ra) # 80004678 <acquiresleep>
  if(ip->valid == 0){
    800039de:	40bc                	lw	a5,64(s1)
    800039e0:	cf99                	beqz	a5,800039fe <ilock+0x40>
}
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6902                	ld	s2,0(sp)
    800039ea:	6105                	addi	sp,sp,32
    800039ec:	8082                	ret
    panic("ilock");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	c0a50513          	addi	a0,a0,-1014 # 800085f8 <syscalls+0x180>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b4c080e7          	jalr	-1204(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039fe:	40dc                	lw	a5,4(s1)
    80003a00:	0047d79b          	srliw	a5,a5,0x4
    80003a04:	0001d597          	auipc	a1,0x1d
    80003a08:	8545a583          	lw	a1,-1964(a1) # 80020258 <sb+0x18>
    80003a0c:	9dbd                	addw	a1,a1,a5
    80003a0e:	4088                	lw	a0,0(s1)
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	7ac080e7          	jalr	1964(ra) # 800031bc <bread>
    80003a18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a1a:	05850593          	addi	a1,a0,88
    80003a1e:	40dc                	lw	a5,4(s1)
    80003a20:	8bbd                	andi	a5,a5,15
    80003a22:	079a                	slli	a5,a5,0x6
    80003a24:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a26:	00059783          	lh	a5,0(a1)
    80003a2a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a2e:	00259783          	lh	a5,2(a1)
    80003a32:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a36:	00459783          	lh	a5,4(a1)
    80003a3a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a3e:	00659783          	lh	a5,6(a1)
    80003a42:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a46:	459c                	lw	a5,8(a1)
    80003a48:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a4a:	03400613          	li	a2,52
    80003a4e:	05b1                	addi	a1,a1,12
    80003a50:	05048513          	addi	a0,s1,80
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	302080e7          	jalr	770(ra) # 80000d56 <memmove>
    brelse(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	88e080e7          	jalr	-1906(ra) # 800032ec <brelse>
    ip->valid = 1;
    80003a66:	4785                	li	a5,1
    80003a68:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a6a:	04449783          	lh	a5,68(s1)
    80003a6e:	fbb5                	bnez	a5,800039e2 <ilock+0x24>
      panic("ilock: no type");
    80003a70:	00005517          	auipc	a0,0x5
    80003a74:	b9050513          	addi	a0,a0,-1136 # 80008600 <syscalls+0x188>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	aca080e7          	jalr	-1334(ra) # 80000542 <panic>

0000000080003a80 <iunlock>:
{
    80003a80:	1101                	addi	sp,sp,-32
    80003a82:	ec06                	sd	ra,24(sp)
    80003a84:	e822                	sd	s0,16(sp)
    80003a86:	e426                	sd	s1,8(sp)
    80003a88:	e04a                	sd	s2,0(sp)
    80003a8a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a8c:	c905                	beqz	a0,80003abc <iunlock+0x3c>
    80003a8e:	84aa                	mv	s1,a0
    80003a90:	01050913          	addi	s2,a0,16
    80003a94:	854a                	mv	a0,s2
    80003a96:	00001097          	auipc	ra,0x1
    80003a9a:	c7c080e7          	jalr	-900(ra) # 80004712 <holdingsleep>
    80003a9e:	cd19                	beqz	a0,80003abc <iunlock+0x3c>
    80003aa0:	449c                	lw	a5,8(s1)
    80003aa2:	00f05d63          	blez	a5,80003abc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	c26080e7          	jalr	-986(ra) # 800046ce <releasesleep>
}
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	64a2                	ld	s1,8(sp)
    80003ab6:	6902                	ld	s2,0(sp)
    80003ab8:	6105                	addi	sp,sp,32
    80003aba:	8082                	ret
    panic("iunlock");
    80003abc:	00005517          	auipc	a0,0x5
    80003ac0:	b5450513          	addi	a0,a0,-1196 # 80008610 <syscalls+0x198>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	a7e080e7          	jalr	-1410(ra) # 80000542 <panic>

0000000080003acc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003acc:	7179                	addi	sp,sp,-48
    80003ace:	f406                	sd	ra,40(sp)
    80003ad0:	f022                	sd	s0,32(sp)
    80003ad2:	ec26                	sd	s1,24(sp)
    80003ad4:	e84a                	sd	s2,16(sp)
    80003ad6:	e44e                	sd	s3,8(sp)
    80003ad8:	e052                	sd	s4,0(sp)
    80003ada:	1800                	addi	s0,sp,48
    80003adc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ade:	05050493          	addi	s1,a0,80
    80003ae2:	08050913          	addi	s2,a0,128
    80003ae6:	a021                	j	80003aee <itrunc+0x22>
    80003ae8:	0491                	addi	s1,s1,4
    80003aea:	01248d63          	beq	s1,s2,80003b04 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aee:	408c                	lw	a1,0(s1)
    80003af0:	dde5                	beqz	a1,80003ae8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003af2:	0009a503          	lw	a0,0(s3)
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	90c080e7          	jalr	-1780(ra) # 80003402 <bfree>
      ip->addrs[i] = 0;
    80003afe:	0004a023          	sw	zero,0(s1)
    80003b02:	b7dd                	j	80003ae8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b04:	0809a583          	lw	a1,128(s3)
    80003b08:	e185                	bnez	a1,80003b28 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b0a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b0e:	854e                	mv	a0,s3
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	de4080e7          	jalr	-540(ra) # 800038f4 <iupdate>
}
    80003b18:	70a2                	ld	ra,40(sp)
    80003b1a:	7402                	ld	s0,32(sp)
    80003b1c:	64e2                	ld	s1,24(sp)
    80003b1e:	6942                	ld	s2,16(sp)
    80003b20:	69a2                	ld	s3,8(sp)
    80003b22:	6a02                	ld	s4,0(sp)
    80003b24:	6145                	addi	sp,sp,48
    80003b26:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b28:	0009a503          	lw	a0,0(s3)
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	690080e7          	jalr	1680(ra) # 800031bc <bread>
    80003b34:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b36:	05850493          	addi	s1,a0,88
    80003b3a:	45850913          	addi	s2,a0,1112
    80003b3e:	a021                	j	80003b46 <itrunc+0x7a>
    80003b40:	0491                	addi	s1,s1,4
    80003b42:	01248b63          	beq	s1,s2,80003b58 <itrunc+0x8c>
      if(a[j])
    80003b46:	408c                	lw	a1,0(s1)
    80003b48:	dde5                	beqz	a1,80003b40 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b4a:	0009a503          	lw	a0,0(s3)
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	8b4080e7          	jalr	-1868(ra) # 80003402 <bfree>
    80003b56:	b7ed                	j	80003b40 <itrunc+0x74>
    brelse(bp);
    80003b58:	8552                	mv	a0,s4
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	792080e7          	jalr	1938(ra) # 800032ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b62:	0809a583          	lw	a1,128(s3)
    80003b66:	0009a503          	lw	a0,0(s3)
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	898080e7          	jalr	-1896(ra) # 80003402 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b72:	0809a023          	sw	zero,128(s3)
    80003b76:	bf51                	j	80003b0a <itrunc+0x3e>

0000000080003b78 <iput>:
{
    80003b78:	1101                	addi	sp,sp,-32
    80003b7a:	ec06                	sd	ra,24(sp)
    80003b7c:	e822                	sd	s0,16(sp)
    80003b7e:	e426                	sd	s1,8(sp)
    80003b80:	e04a                	sd	s2,0(sp)
    80003b82:	1000                	addi	s0,sp,32
    80003b84:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b86:	0001c517          	auipc	a0,0x1c
    80003b8a:	6da50513          	addi	a0,a0,1754 # 80020260 <icache>
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	070080e7          	jalr	112(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b96:	4498                	lw	a4,8(s1)
    80003b98:	4785                	li	a5,1
    80003b9a:	02f70363          	beq	a4,a5,80003bc0 <iput+0x48>
  ip->ref--;
    80003b9e:	449c                	lw	a5,8(s1)
    80003ba0:	37fd                	addiw	a5,a5,-1
    80003ba2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ba4:	0001c517          	auipc	a0,0x1c
    80003ba8:	6bc50513          	addi	a0,a0,1724 # 80020260 <icache>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	106080e7          	jalr	262(ra) # 80000cb2 <release>
}
    80003bb4:	60e2                	ld	ra,24(sp)
    80003bb6:	6442                	ld	s0,16(sp)
    80003bb8:	64a2                	ld	s1,8(sp)
    80003bba:	6902                	ld	s2,0(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc0:	40bc                	lw	a5,64(s1)
    80003bc2:	dff1                	beqz	a5,80003b9e <iput+0x26>
    80003bc4:	04a49783          	lh	a5,74(s1)
    80003bc8:	fbf9                	bnez	a5,80003b9e <iput+0x26>
    acquiresleep(&ip->lock);
    80003bca:	01048913          	addi	s2,s1,16
    80003bce:	854a                	mv	a0,s2
    80003bd0:	00001097          	auipc	ra,0x1
    80003bd4:	aa8080e7          	jalr	-1368(ra) # 80004678 <acquiresleep>
    release(&icache.lock);
    80003bd8:	0001c517          	auipc	a0,0x1c
    80003bdc:	68850513          	addi	a0,a0,1672 # 80020260 <icache>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	0d2080e7          	jalr	210(ra) # 80000cb2 <release>
    itrunc(ip);
    80003be8:	8526                	mv	a0,s1
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	ee2080e7          	jalr	-286(ra) # 80003acc <itrunc>
    ip->type = 0;
    80003bf2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	cfc080e7          	jalr	-772(ra) # 800038f4 <iupdate>
    ip->valid = 0;
    80003c00:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00001097          	auipc	ra,0x1
    80003c0a:	ac8080e7          	jalr	-1336(ra) # 800046ce <releasesleep>
    acquire(&icache.lock);
    80003c0e:	0001c517          	auipc	a0,0x1c
    80003c12:	65250513          	addi	a0,a0,1618 # 80020260 <icache>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	fe8080e7          	jalr	-24(ra) # 80000bfe <acquire>
    80003c1e:	b741                	j	80003b9e <iput+0x26>

0000000080003c20 <iunlockput>:
{
    80003c20:	1101                	addi	sp,sp,-32
    80003c22:	ec06                	sd	ra,24(sp)
    80003c24:	e822                	sd	s0,16(sp)
    80003c26:	e426                	sd	s1,8(sp)
    80003c28:	1000                	addi	s0,sp,32
    80003c2a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	e54080e7          	jalr	-428(ra) # 80003a80 <iunlock>
  iput(ip);
    80003c34:	8526                	mv	a0,s1
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	f42080e7          	jalr	-190(ra) # 80003b78 <iput>
}
    80003c3e:	60e2                	ld	ra,24(sp)
    80003c40:	6442                	ld	s0,16(sp)
    80003c42:	64a2                	ld	s1,8(sp)
    80003c44:	6105                	addi	sp,sp,32
    80003c46:	8082                	ret

0000000080003c48 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c48:	1141                	addi	sp,sp,-16
    80003c4a:	e422                	sd	s0,8(sp)
    80003c4c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c4e:	411c                	lw	a5,0(a0)
    80003c50:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c52:	415c                	lw	a5,4(a0)
    80003c54:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c56:	04451783          	lh	a5,68(a0)
    80003c5a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c5e:	04a51783          	lh	a5,74(a0)
    80003c62:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c66:	04c56783          	lwu	a5,76(a0)
    80003c6a:	e99c                	sd	a5,16(a1)
}
    80003c6c:	6422                	ld	s0,8(sp)
    80003c6e:	0141                	addi	sp,sp,16
    80003c70:	8082                	ret

0000000080003c72 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c72:	457c                	lw	a5,76(a0)
    80003c74:	0ed7e863          	bltu	a5,a3,80003d64 <readi+0xf2>
{
    80003c78:	7159                	addi	sp,sp,-112
    80003c7a:	f486                	sd	ra,104(sp)
    80003c7c:	f0a2                	sd	s0,96(sp)
    80003c7e:	eca6                	sd	s1,88(sp)
    80003c80:	e8ca                	sd	s2,80(sp)
    80003c82:	e4ce                	sd	s3,72(sp)
    80003c84:	e0d2                	sd	s4,64(sp)
    80003c86:	fc56                	sd	s5,56(sp)
    80003c88:	f85a                	sd	s6,48(sp)
    80003c8a:	f45e                	sd	s7,40(sp)
    80003c8c:	f062                	sd	s8,32(sp)
    80003c8e:	ec66                	sd	s9,24(sp)
    80003c90:	e86a                	sd	s10,16(sp)
    80003c92:	e46e                	sd	s11,8(sp)
    80003c94:	1880                	addi	s0,sp,112
    80003c96:	8baa                	mv	s7,a0
    80003c98:	8c2e                	mv	s8,a1
    80003c9a:	8ab2                	mv	s5,a2
    80003c9c:	84b6                	mv	s1,a3
    80003c9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ca0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ca2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ca4:	08d76f63          	bltu	a4,a3,80003d42 <readi+0xd0>
  if(off + n > ip->size)
    80003ca8:	00e7f463          	bgeu	a5,a4,80003cb0 <readi+0x3e>
    n = ip->size - off;
    80003cac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb0:	0a0b0863          	beqz	s6,80003d60 <readi+0xee>
    80003cb4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cba:	5cfd                	li	s9,-1
    80003cbc:	a82d                	j	80003cf6 <readi+0x84>
    80003cbe:	020a1d93          	slli	s11,s4,0x20
    80003cc2:	020ddd93          	srli	s11,s11,0x20
    80003cc6:	05890793          	addi	a5,s2,88
    80003cca:	86ee                	mv	a3,s11
    80003ccc:	963e                	add	a2,a2,a5
    80003cce:	85d6                	mv	a1,s5
    80003cd0:	8562                	mv	a0,s8
    80003cd2:	fffff097          	auipc	ra,0xfffff
    80003cd6:	9d6080e7          	jalr	-1578(ra) # 800026a8 <either_copyout>
    80003cda:	05950d63          	beq	a0,s9,80003d34 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003cde:	854a                	mv	a0,s2
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	60c080e7          	jalr	1548(ra) # 800032ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce8:	013a09bb          	addw	s3,s4,s3
    80003cec:	009a04bb          	addw	s1,s4,s1
    80003cf0:	9aee                	add	s5,s5,s11
    80003cf2:	0569f663          	bgeu	s3,s6,80003d3e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cf6:	000ba903          	lw	s2,0(s7)
    80003cfa:	00a4d59b          	srliw	a1,s1,0xa
    80003cfe:	855e                	mv	a0,s7
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	8b0080e7          	jalr	-1872(ra) # 800035b0 <bmap>
    80003d08:	0005059b          	sext.w	a1,a0
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	4ae080e7          	jalr	1198(ra) # 800031bc <bread>
    80003d16:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d18:	3ff4f613          	andi	a2,s1,1023
    80003d1c:	40cd07bb          	subw	a5,s10,a2
    80003d20:	413b073b          	subw	a4,s6,s3
    80003d24:	8a3e                	mv	s4,a5
    80003d26:	2781                	sext.w	a5,a5
    80003d28:	0007069b          	sext.w	a3,a4
    80003d2c:	f8f6f9e3          	bgeu	a3,a5,80003cbe <readi+0x4c>
    80003d30:	8a3a                	mv	s4,a4
    80003d32:	b771                	j	80003cbe <readi+0x4c>
      brelse(bp);
    80003d34:	854a                	mv	a0,s2
    80003d36:	fffff097          	auipc	ra,0xfffff
    80003d3a:	5b6080e7          	jalr	1462(ra) # 800032ec <brelse>
  }
  return tot;
    80003d3e:	0009851b          	sext.w	a0,s3
}
    80003d42:	70a6                	ld	ra,104(sp)
    80003d44:	7406                	ld	s0,96(sp)
    80003d46:	64e6                	ld	s1,88(sp)
    80003d48:	6946                	ld	s2,80(sp)
    80003d4a:	69a6                	ld	s3,72(sp)
    80003d4c:	6a06                	ld	s4,64(sp)
    80003d4e:	7ae2                	ld	s5,56(sp)
    80003d50:	7b42                	ld	s6,48(sp)
    80003d52:	7ba2                	ld	s7,40(sp)
    80003d54:	7c02                	ld	s8,32(sp)
    80003d56:	6ce2                	ld	s9,24(sp)
    80003d58:	6d42                	ld	s10,16(sp)
    80003d5a:	6da2                	ld	s11,8(sp)
    80003d5c:	6165                	addi	sp,sp,112
    80003d5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d60:	89da                	mv	s3,s6
    80003d62:	bff1                	j	80003d3e <readi+0xcc>
    return 0;
    80003d64:	4501                	li	a0,0
}
    80003d66:	8082                	ret

0000000080003d68 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d68:	457c                	lw	a5,76(a0)
    80003d6a:	10d7e663          	bltu	a5,a3,80003e76 <writei+0x10e>
{
    80003d6e:	7159                	addi	sp,sp,-112
    80003d70:	f486                	sd	ra,104(sp)
    80003d72:	f0a2                	sd	s0,96(sp)
    80003d74:	eca6                	sd	s1,88(sp)
    80003d76:	e8ca                	sd	s2,80(sp)
    80003d78:	e4ce                	sd	s3,72(sp)
    80003d7a:	e0d2                	sd	s4,64(sp)
    80003d7c:	fc56                	sd	s5,56(sp)
    80003d7e:	f85a                	sd	s6,48(sp)
    80003d80:	f45e                	sd	s7,40(sp)
    80003d82:	f062                	sd	s8,32(sp)
    80003d84:	ec66                	sd	s9,24(sp)
    80003d86:	e86a                	sd	s10,16(sp)
    80003d88:	e46e                	sd	s11,8(sp)
    80003d8a:	1880                	addi	s0,sp,112
    80003d8c:	8baa                	mv	s7,a0
    80003d8e:	8c2e                	mv	s8,a1
    80003d90:	8ab2                	mv	s5,a2
    80003d92:	8936                	mv	s2,a3
    80003d94:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d96:	00e687bb          	addw	a5,a3,a4
    80003d9a:	0ed7e063          	bltu	a5,a3,80003e7a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d9e:	00043737          	lui	a4,0x43
    80003da2:	0cf76e63          	bltu	a4,a5,80003e7e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da6:	0a0b0763          	beqz	s6,80003e54 <writei+0xec>
    80003daa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dac:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003db0:	5cfd                	li	s9,-1
    80003db2:	a091                	j	80003df6 <writei+0x8e>
    80003db4:	02099d93          	slli	s11,s3,0x20
    80003db8:	020ddd93          	srli	s11,s11,0x20
    80003dbc:	05848793          	addi	a5,s1,88
    80003dc0:	86ee                	mv	a3,s11
    80003dc2:	8656                	mv	a2,s5
    80003dc4:	85e2                	mv	a1,s8
    80003dc6:	953e                	add	a0,a0,a5
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	936080e7          	jalr	-1738(ra) # 800026fe <either_copyin>
    80003dd0:	07950263          	beq	a0,s9,80003e34 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	77a080e7          	jalr	1914(ra) # 80004550 <log_write>
    brelse(bp);
    80003dde:	8526                	mv	a0,s1
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	50c080e7          	jalr	1292(ra) # 800032ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de8:	01498a3b          	addw	s4,s3,s4
    80003dec:	0129893b          	addw	s2,s3,s2
    80003df0:	9aee                	add	s5,s5,s11
    80003df2:	056a7663          	bgeu	s4,s6,80003e3e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003df6:	000ba483          	lw	s1,0(s7)
    80003dfa:	00a9559b          	srliw	a1,s2,0xa
    80003dfe:	855e                	mv	a0,s7
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	7b0080e7          	jalr	1968(ra) # 800035b0 <bmap>
    80003e08:	0005059b          	sext.w	a1,a0
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	fffff097          	auipc	ra,0xfffff
    80003e12:	3ae080e7          	jalr	942(ra) # 800031bc <bread>
    80003e16:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e18:	3ff97513          	andi	a0,s2,1023
    80003e1c:	40ad07bb          	subw	a5,s10,a0
    80003e20:	414b073b          	subw	a4,s6,s4
    80003e24:	89be                	mv	s3,a5
    80003e26:	2781                	sext.w	a5,a5
    80003e28:	0007069b          	sext.w	a3,a4
    80003e2c:	f8f6f4e3          	bgeu	a3,a5,80003db4 <writei+0x4c>
    80003e30:	89ba                	mv	s3,a4
    80003e32:	b749                	j	80003db4 <writei+0x4c>
      brelse(bp);
    80003e34:	8526                	mv	a0,s1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	4b6080e7          	jalr	1206(ra) # 800032ec <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e3e:	04cba783          	lw	a5,76(s7)
    80003e42:	0127f463          	bgeu	a5,s2,80003e4a <writei+0xe2>
      ip->size = off;
    80003e46:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e4a:	855e                	mv	a0,s7
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	aa8080e7          	jalr	-1368(ra) # 800038f4 <iupdate>
  }

  return n;
    80003e54:	000b051b          	sext.w	a0,s6
}
    80003e58:	70a6                	ld	ra,104(sp)
    80003e5a:	7406                	ld	s0,96(sp)
    80003e5c:	64e6                	ld	s1,88(sp)
    80003e5e:	6946                	ld	s2,80(sp)
    80003e60:	69a6                	ld	s3,72(sp)
    80003e62:	6a06                	ld	s4,64(sp)
    80003e64:	7ae2                	ld	s5,56(sp)
    80003e66:	7b42                	ld	s6,48(sp)
    80003e68:	7ba2                	ld	s7,40(sp)
    80003e6a:	7c02                	ld	s8,32(sp)
    80003e6c:	6ce2                	ld	s9,24(sp)
    80003e6e:	6d42                	ld	s10,16(sp)
    80003e70:	6da2                	ld	s11,8(sp)
    80003e72:	6165                	addi	sp,sp,112
    80003e74:	8082                	ret
    return -1;
    80003e76:	557d                	li	a0,-1
}
    80003e78:	8082                	ret
    return -1;
    80003e7a:	557d                	li	a0,-1
    80003e7c:	bff1                	j	80003e58 <writei+0xf0>
    return -1;
    80003e7e:	557d                	li	a0,-1
    80003e80:	bfe1                	j	80003e58 <writei+0xf0>

0000000080003e82 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e82:	1141                	addi	sp,sp,-16
    80003e84:	e406                	sd	ra,8(sp)
    80003e86:	e022                	sd	s0,0(sp)
    80003e88:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e8a:	4639                	li	a2,14
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	f46080e7          	jalr	-186(ra) # 80000dd2 <strncmp>
}
    80003e94:	60a2                	ld	ra,8(sp)
    80003e96:	6402                	ld	s0,0(sp)
    80003e98:	0141                	addi	sp,sp,16
    80003e9a:	8082                	ret

0000000080003e9c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e9c:	7139                	addi	sp,sp,-64
    80003e9e:	fc06                	sd	ra,56(sp)
    80003ea0:	f822                	sd	s0,48(sp)
    80003ea2:	f426                	sd	s1,40(sp)
    80003ea4:	f04a                	sd	s2,32(sp)
    80003ea6:	ec4e                	sd	s3,24(sp)
    80003ea8:	e852                	sd	s4,16(sp)
    80003eaa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eac:	04451703          	lh	a4,68(a0)
    80003eb0:	4785                	li	a5,1
    80003eb2:	00f71a63          	bne	a4,a5,80003ec6 <dirlookup+0x2a>
    80003eb6:	892a                	mv	s2,a0
    80003eb8:	89ae                	mv	s3,a1
    80003eba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebc:	457c                	lw	a5,76(a0)
    80003ebe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ec0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec2:	e79d                	bnez	a5,80003ef0 <dirlookup+0x54>
    80003ec4:	a8a5                	j	80003f3c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ec6:	00004517          	auipc	a0,0x4
    80003eca:	75250513          	addi	a0,a0,1874 # 80008618 <syscalls+0x1a0>
    80003ece:	ffffc097          	auipc	ra,0xffffc
    80003ed2:	674080e7          	jalr	1652(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003ed6:	00004517          	auipc	a0,0x4
    80003eda:	75a50513          	addi	a0,a0,1882 # 80008630 <syscalls+0x1b8>
    80003ede:	ffffc097          	auipc	ra,0xffffc
    80003ee2:	664080e7          	jalr	1636(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	24c1                	addiw	s1,s1,16
    80003ee8:	04c92783          	lw	a5,76(s2)
    80003eec:	04f4f763          	bgeu	s1,a5,80003f3a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef0:	4741                	li	a4,16
    80003ef2:	86a6                	mv	a3,s1
    80003ef4:	fc040613          	addi	a2,s0,-64
    80003ef8:	4581                	li	a1,0
    80003efa:	854a                	mv	a0,s2
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	d76080e7          	jalr	-650(ra) # 80003c72 <readi>
    80003f04:	47c1                	li	a5,16
    80003f06:	fcf518e3          	bne	a0,a5,80003ed6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f0a:	fc045783          	lhu	a5,-64(s0)
    80003f0e:	dfe1                	beqz	a5,80003ee6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f10:	fc240593          	addi	a1,s0,-62
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	f6c080e7          	jalr	-148(ra) # 80003e82 <namecmp>
    80003f1e:	f561                	bnez	a0,80003ee6 <dirlookup+0x4a>
      if(poff)
    80003f20:	000a0463          	beqz	s4,80003f28 <dirlookup+0x8c>
        *poff = off;
    80003f24:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f28:	fc045583          	lhu	a1,-64(s0)
    80003f2c:	00092503          	lw	a0,0(s2)
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	75a080e7          	jalr	1882(ra) # 8000368a <iget>
    80003f38:	a011                	j	80003f3c <dirlookup+0xa0>
  return 0;
    80003f3a:	4501                	li	a0,0
}
    80003f3c:	70e2                	ld	ra,56(sp)
    80003f3e:	7442                	ld	s0,48(sp)
    80003f40:	74a2                	ld	s1,40(sp)
    80003f42:	7902                	ld	s2,32(sp)
    80003f44:	69e2                	ld	s3,24(sp)
    80003f46:	6a42                	ld	s4,16(sp)
    80003f48:	6121                	addi	sp,sp,64
    80003f4a:	8082                	ret

0000000080003f4c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f4c:	711d                	addi	sp,sp,-96
    80003f4e:	ec86                	sd	ra,88(sp)
    80003f50:	e8a2                	sd	s0,80(sp)
    80003f52:	e4a6                	sd	s1,72(sp)
    80003f54:	e0ca                	sd	s2,64(sp)
    80003f56:	fc4e                	sd	s3,56(sp)
    80003f58:	f852                	sd	s4,48(sp)
    80003f5a:	f456                	sd	s5,40(sp)
    80003f5c:	f05a                	sd	s6,32(sp)
    80003f5e:	ec5e                	sd	s7,24(sp)
    80003f60:	e862                	sd	s8,16(sp)
    80003f62:	e466                	sd	s9,8(sp)
    80003f64:	1080                	addi	s0,sp,96
    80003f66:	84aa                	mv	s1,a0
    80003f68:	8aae                	mv	s5,a1
    80003f6a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f6c:	00054703          	lbu	a4,0(a0)
    80003f70:	02f00793          	li	a5,47
    80003f74:	02f70363          	beq	a4,a5,80003f9a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f78:	ffffe097          	auipc	ra,0xffffe
    80003f7c:	bba080e7          	jalr	-1094(ra) # 80001b32 <myproc>
    80003f80:	16053503          	ld	a0,352(a0)
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	9fc080e7          	jalr	-1540(ra) # 80003980 <idup>
    80003f8c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f8e:	02f00913          	li	s2,47
  len = path - s;
    80003f92:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f94:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f96:	4b85                	li	s7,1
    80003f98:	a865                	j	80004050 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f9a:	4585                	li	a1,1
    80003f9c:	4505                	li	a0,1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	6ec080e7          	jalr	1772(ra) # 8000368a <iget>
    80003fa6:	89aa                	mv	s3,a0
    80003fa8:	b7dd                	j	80003f8e <namex+0x42>
      iunlockput(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	c74080e7          	jalr	-908(ra) # 80003c20 <iunlockput>
      return 0;
    80003fb4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	60e6                	ld	ra,88(sp)
    80003fba:	6446                	ld	s0,80(sp)
    80003fbc:	64a6                	ld	s1,72(sp)
    80003fbe:	6906                	ld	s2,64(sp)
    80003fc0:	79e2                	ld	s3,56(sp)
    80003fc2:	7a42                	ld	s4,48(sp)
    80003fc4:	7aa2                	ld	s5,40(sp)
    80003fc6:	7b02                	ld	s6,32(sp)
    80003fc8:	6be2                	ld	s7,24(sp)
    80003fca:	6c42                	ld	s8,16(sp)
    80003fcc:	6ca2                	ld	s9,8(sp)
    80003fce:	6125                	addi	sp,sp,96
    80003fd0:	8082                	ret
      iunlock(ip);
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	aac080e7          	jalr	-1364(ra) # 80003a80 <iunlock>
      return ip;
    80003fdc:	bfe9                	j	80003fb6 <namex+0x6a>
      iunlockput(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	c40080e7          	jalr	-960(ra) # 80003c20 <iunlockput>
      return 0;
    80003fe8:	89e6                	mv	s3,s9
    80003fea:	b7f1                	j	80003fb6 <namex+0x6a>
  len = path - s;
    80003fec:	40b48633          	sub	a2,s1,a1
    80003ff0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ff4:	099c5463          	bge	s8,s9,8000407c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ff8:	4639                	li	a2,14
    80003ffa:	8552                	mv	a0,s4
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	d5a080e7          	jalr	-678(ra) # 80000d56 <memmove>
  while(*path == '/')
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	01279763          	bne	a5,s2,80004016 <namex+0xca>
    path++;
    8000400c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	ff278de3          	beq	a5,s2,8000400c <namex+0xc0>
    ilock(ip);
    80004016:	854e                	mv	a0,s3
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	9a6080e7          	jalr	-1626(ra) # 800039be <ilock>
    if(ip->type != T_DIR){
    80004020:	04499783          	lh	a5,68(s3)
    80004024:	f97793e3          	bne	a5,s7,80003faa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004028:	000a8563          	beqz	s5,80004032 <namex+0xe6>
    8000402c:	0004c783          	lbu	a5,0(s1)
    80004030:	d3cd                	beqz	a5,80003fd2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004032:	865a                	mv	a2,s6
    80004034:	85d2                	mv	a1,s4
    80004036:	854e                	mv	a0,s3
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	e64080e7          	jalr	-412(ra) # 80003e9c <dirlookup>
    80004040:	8caa                	mv	s9,a0
    80004042:	dd51                	beqz	a0,80003fde <namex+0x92>
    iunlockput(ip);
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	bda080e7          	jalr	-1062(ra) # 80003c20 <iunlockput>
    ip = next;
    8000404e:	89e6                	mv	s3,s9
  while(*path == '/')
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	05279763          	bne	a5,s2,800040a2 <namex+0x156>
    path++;
    80004058:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000405a:	0004c783          	lbu	a5,0(s1)
    8000405e:	ff278de3          	beq	a5,s2,80004058 <namex+0x10c>
  if(*path == 0)
    80004062:	c79d                	beqz	a5,80004090 <namex+0x144>
    path++;
    80004064:	85a6                	mv	a1,s1
  len = path - s;
    80004066:	8cda                	mv	s9,s6
    80004068:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000406a:	01278963          	beq	a5,s2,8000407c <namex+0x130>
    8000406e:	dfbd                	beqz	a5,80003fec <namex+0xa0>
    path++;
    80004070:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004072:	0004c783          	lbu	a5,0(s1)
    80004076:	ff279ce3          	bne	a5,s2,8000406e <namex+0x122>
    8000407a:	bf8d                	j	80003fec <namex+0xa0>
    memmove(name, s, len);
    8000407c:	2601                	sext.w	a2,a2
    8000407e:	8552                	mv	a0,s4
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	cd6080e7          	jalr	-810(ra) # 80000d56 <memmove>
    name[len] = 0;
    80004088:	9cd2                	add	s9,s9,s4
    8000408a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000408e:	bf9d                	j	80004004 <namex+0xb8>
  if(nameiparent){
    80004090:	f20a83e3          	beqz	s5,80003fb6 <namex+0x6a>
    iput(ip);
    80004094:	854e                	mv	a0,s3
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	ae2080e7          	jalr	-1310(ra) # 80003b78 <iput>
    return 0;
    8000409e:	4981                	li	s3,0
    800040a0:	bf19                	j	80003fb6 <namex+0x6a>
  if(*path == 0)
    800040a2:	d7fd                	beqz	a5,80004090 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040a4:	0004c783          	lbu	a5,0(s1)
    800040a8:	85a6                	mv	a1,s1
    800040aa:	b7d1                	j	8000406e <namex+0x122>

00000000800040ac <dirlink>:
{
    800040ac:	7139                	addi	sp,sp,-64
    800040ae:	fc06                	sd	ra,56(sp)
    800040b0:	f822                	sd	s0,48(sp)
    800040b2:	f426                	sd	s1,40(sp)
    800040b4:	f04a                	sd	s2,32(sp)
    800040b6:	ec4e                	sd	s3,24(sp)
    800040b8:	e852                	sd	s4,16(sp)
    800040ba:	0080                	addi	s0,sp,64
    800040bc:	892a                	mv	s2,a0
    800040be:	8a2e                	mv	s4,a1
    800040c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040c2:	4601                	li	a2,0
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	dd8080e7          	jalr	-552(ra) # 80003e9c <dirlookup>
    800040cc:	e93d                	bnez	a0,80004142 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ce:	04c92483          	lw	s1,76(s2)
    800040d2:	c49d                	beqz	s1,80004100 <dirlink+0x54>
    800040d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d6:	4741                	li	a4,16
    800040d8:	86a6                	mv	a3,s1
    800040da:	fc040613          	addi	a2,s0,-64
    800040de:	4581                	li	a1,0
    800040e0:	854a                	mv	a0,s2
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	b90080e7          	jalr	-1136(ra) # 80003c72 <readi>
    800040ea:	47c1                	li	a5,16
    800040ec:	06f51163          	bne	a0,a5,8000414e <dirlink+0xa2>
    if(de.inum == 0)
    800040f0:	fc045783          	lhu	a5,-64(s0)
    800040f4:	c791                	beqz	a5,80004100 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f6:	24c1                	addiw	s1,s1,16
    800040f8:	04c92783          	lw	a5,76(s2)
    800040fc:	fcf4ede3          	bltu	s1,a5,800040d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004100:	4639                	li	a2,14
    80004102:	85d2                	mv	a1,s4
    80004104:	fc240513          	addi	a0,s0,-62
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	d06080e7          	jalr	-762(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80004110:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004114:	4741                	li	a4,16
    80004116:	86a6                	mv	a3,s1
    80004118:	fc040613          	addi	a2,s0,-64
    8000411c:	4581                	li	a1,0
    8000411e:	854a                	mv	a0,s2
    80004120:	00000097          	auipc	ra,0x0
    80004124:	c48080e7          	jalr	-952(ra) # 80003d68 <writei>
    80004128:	872a                	mv	a4,a0
    8000412a:	47c1                	li	a5,16
  return 0;
    8000412c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412e:	02f71863          	bne	a4,a5,8000415e <dirlink+0xb2>
}
    80004132:	70e2                	ld	ra,56(sp)
    80004134:	7442                	ld	s0,48(sp)
    80004136:	74a2                	ld	s1,40(sp)
    80004138:	7902                	ld	s2,32(sp)
    8000413a:	69e2                	ld	s3,24(sp)
    8000413c:	6a42                	ld	s4,16(sp)
    8000413e:	6121                	addi	sp,sp,64
    80004140:	8082                	ret
    iput(ip);
    80004142:	00000097          	auipc	ra,0x0
    80004146:	a36080e7          	jalr	-1482(ra) # 80003b78 <iput>
    return -1;
    8000414a:	557d                	li	a0,-1
    8000414c:	b7dd                	j	80004132 <dirlink+0x86>
      panic("dirlink read");
    8000414e:	00004517          	auipc	a0,0x4
    80004152:	4f250513          	addi	a0,a0,1266 # 80008640 <syscalls+0x1c8>
    80004156:	ffffc097          	auipc	ra,0xffffc
    8000415a:	3ec080e7          	jalr	1004(ra) # 80000542 <panic>
    panic("dirlink");
    8000415e:	00004517          	auipc	a0,0x4
    80004162:	5fa50513          	addi	a0,a0,1530 # 80008758 <syscalls+0x2e0>
    80004166:	ffffc097          	auipc	ra,0xffffc
    8000416a:	3dc080e7          	jalr	988(ra) # 80000542 <panic>

000000008000416e <namei>:

struct inode*
namei(char *path)
{
    8000416e:	1101                	addi	sp,sp,-32
    80004170:	ec06                	sd	ra,24(sp)
    80004172:	e822                	sd	s0,16(sp)
    80004174:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004176:	fe040613          	addi	a2,s0,-32
    8000417a:	4581                	li	a1,0
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	dd0080e7          	jalr	-560(ra) # 80003f4c <namex>
}
    80004184:	60e2                	ld	ra,24(sp)
    80004186:	6442                	ld	s0,16(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000418c:	1141                	addi	sp,sp,-16
    8000418e:	e406                	sd	ra,8(sp)
    80004190:	e022                	sd	s0,0(sp)
    80004192:	0800                	addi	s0,sp,16
    80004194:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004196:	4585                	li	a1,1
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	db4080e7          	jalr	-588(ra) # 80003f4c <namex>
}
    800041a0:	60a2                	ld	ra,8(sp)
    800041a2:	6402                	ld	s0,0(sp)
    800041a4:	0141                	addi	sp,sp,16
    800041a6:	8082                	ret

00000000800041a8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041a8:	1101                	addi	sp,sp,-32
    800041aa:	ec06                	sd	ra,24(sp)
    800041ac:	e822                	sd	s0,16(sp)
    800041ae:	e426                	sd	s1,8(sp)
    800041b0:	e04a                	sd	s2,0(sp)
    800041b2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041b4:	0001e917          	auipc	s2,0x1e
    800041b8:	b5490913          	addi	s2,s2,-1196 # 80021d08 <log>
    800041bc:	01892583          	lw	a1,24(s2)
    800041c0:	02892503          	lw	a0,40(s2)
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	ff8080e7          	jalr	-8(ra) # 800031bc <bread>
    800041cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041ce:	02c92683          	lw	a3,44(s2)
    800041d2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041d4:	02d05763          	blez	a3,80004202 <write_head+0x5a>
    800041d8:	0001e797          	auipc	a5,0x1e
    800041dc:	b6078793          	addi	a5,a5,-1184 # 80021d38 <log+0x30>
    800041e0:	05c50713          	addi	a4,a0,92
    800041e4:	36fd                	addiw	a3,a3,-1
    800041e6:	1682                	slli	a3,a3,0x20
    800041e8:	9281                	srli	a3,a3,0x20
    800041ea:	068a                	slli	a3,a3,0x2
    800041ec:	0001e617          	auipc	a2,0x1e
    800041f0:	b5060613          	addi	a2,a2,-1200 # 80021d3c <log+0x34>
    800041f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041f6:	4390                	lw	a2,0(a5)
    800041f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041fa:	0791                	addi	a5,a5,4
    800041fc:	0711                	addi	a4,a4,4
    800041fe:	fed79ce3          	bne	a5,a3,800041f6 <write_head+0x4e>
  }
  bwrite(buf);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	0aa080e7          	jalr	170(ra) # 800032ae <bwrite>
  brelse(buf);
    8000420c:	8526                	mv	a0,s1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	0de080e7          	jalr	222(ra) # 800032ec <brelse>
}
    80004216:	60e2                	ld	ra,24(sp)
    80004218:	6442                	ld	s0,16(sp)
    8000421a:	64a2                	ld	s1,8(sp)
    8000421c:	6902                	ld	s2,0(sp)
    8000421e:	6105                	addi	sp,sp,32
    80004220:	8082                	ret

0000000080004222 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	0001e797          	auipc	a5,0x1e
    80004226:	b127a783          	lw	a5,-1262(a5) # 80021d34 <log+0x2c>
    8000422a:	0af05663          	blez	a5,800042d6 <install_trans+0xb4>
{
    8000422e:	7139                	addi	sp,sp,-64
    80004230:	fc06                	sd	ra,56(sp)
    80004232:	f822                	sd	s0,48(sp)
    80004234:	f426                	sd	s1,40(sp)
    80004236:	f04a                	sd	s2,32(sp)
    80004238:	ec4e                	sd	s3,24(sp)
    8000423a:	e852                	sd	s4,16(sp)
    8000423c:	e456                	sd	s5,8(sp)
    8000423e:	0080                	addi	s0,sp,64
    80004240:	0001ea97          	auipc	s5,0x1e
    80004244:	af8a8a93          	addi	s5,s5,-1288 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004248:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000424a:	0001e997          	auipc	s3,0x1e
    8000424e:	abe98993          	addi	s3,s3,-1346 # 80021d08 <log>
    80004252:	0189a583          	lw	a1,24(s3)
    80004256:	014585bb          	addw	a1,a1,s4
    8000425a:	2585                	addiw	a1,a1,1
    8000425c:	0289a503          	lw	a0,40(s3)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	f5c080e7          	jalr	-164(ra) # 800031bc <bread>
    80004268:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000426a:	000aa583          	lw	a1,0(s5)
    8000426e:	0289a503          	lw	a0,40(s3)
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	f4a080e7          	jalr	-182(ra) # 800031bc <bread>
    8000427a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000427c:	40000613          	li	a2,1024
    80004280:	05890593          	addi	a1,s2,88
    80004284:	05850513          	addi	a0,a0,88
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	ace080e7          	jalr	-1330(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004290:	8526                	mv	a0,s1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	01c080e7          	jalr	28(ra) # 800032ae <bwrite>
    bunpin(dbuf);
    8000429a:	8526                	mv	a0,s1
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	12a080e7          	jalr	298(ra) # 800033c6 <bunpin>
    brelse(lbuf);
    800042a4:	854a                	mv	a0,s2
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	046080e7          	jalr	70(ra) # 800032ec <brelse>
    brelse(dbuf);
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	03c080e7          	jalr	60(ra) # 800032ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b8:	2a05                	addiw	s4,s4,1
    800042ba:	0a91                	addi	s5,s5,4
    800042bc:	02c9a783          	lw	a5,44(s3)
    800042c0:	f8fa49e3          	blt	s4,a5,80004252 <install_trans+0x30>
}
    800042c4:	70e2                	ld	ra,56(sp)
    800042c6:	7442                	ld	s0,48(sp)
    800042c8:	74a2                	ld	s1,40(sp)
    800042ca:	7902                	ld	s2,32(sp)
    800042cc:	69e2                	ld	s3,24(sp)
    800042ce:	6a42                	ld	s4,16(sp)
    800042d0:	6aa2                	ld	s5,8(sp)
    800042d2:	6121                	addi	sp,sp,64
    800042d4:	8082                	ret
    800042d6:	8082                	ret

00000000800042d8 <initlog>:
{
    800042d8:	7179                	addi	sp,sp,-48
    800042da:	f406                	sd	ra,40(sp)
    800042dc:	f022                	sd	s0,32(sp)
    800042de:	ec26                	sd	s1,24(sp)
    800042e0:	e84a                	sd	s2,16(sp)
    800042e2:	e44e                	sd	s3,8(sp)
    800042e4:	1800                	addi	s0,sp,48
    800042e6:	892a                	mv	s2,a0
    800042e8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ea:	0001e497          	auipc	s1,0x1e
    800042ee:	a1e48493          	addi	s1,s1,-1506 # 80021d08 <log>
    800042f2:	00004597          	auipc	a1,0x4
    800042f6:	35e58593          	addi	a1,a1,862 # 80008650 <syscalls+0x1d8>
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	872080e7          	jalr	-1934(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80004304:	0149a583          	lw	a1,20(s3)
    80004308:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000430a:	0109a783          	lw	a5,16(s3)
    8000430e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004310:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004314:	854a                	mv	a0,s2
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	ea6080e7          	jalr	-346(ra) # 800031bc <bread>
  log.lh.n = lh->n;
    8000431e:	4d34                	lw	a3,88(a0)
    80004320:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004322:	02d05563          	blez	a3,8000434c <initlog+0x74>
    80004326:	05c50793          	addi	a5,a0,92
    8000432a:	0001e717          	auipc	a4,0x1e
    8000432e:	a0e70713          	addi	a4,a4,-1522 # 80021d38 <log+0x30>
    80004332:	36fd                	addiw	a3,a3,-1
    80004334:	1682                	slli	a3,a3,0x20
    80004336:	9281                	srli	a3,a3,0x20
    80004338:	068a                	slli	a3,a3,0x2
    8000433a:	06050613          	addi	a2,a0,96
    8000433e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004340:	4390                	lw	a2,0(a5)
    80004342:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004344:	0791                	addi	a5,a5,4
    80004346:	0711                	addi	a4,a4,4
    80004348:	fed79ce3          	bne	a5,a3,80004340 <initlog+0x68>
  brelse(buf);
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	fa0080e7          	jalr	-96(ra) # 800032ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004354:	00000097          	auipc	ra,0x0
    80004358:	ece080e7          	jalr	-306(ra) # 80004222 <install_trans>
  log.lh.n = 0;
    8000435c:	0001e797          	auipc	a5,0x1e
    80004360:	9c07ac23          	sw	zero,-1576(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    80004364:	00000097          	auipc	ra,0x0
    80004368:	e44080e7          	jalr	-444(ra) # 800041a8 <write_head>
}
    8000436c:	70a2                	ld	ra,40(sp)
    8000436e:	7402                	ld	s0,32(sp)
    80004370:	64e2                	ld	s1,24(sp)
    80004372:	6942                	ld	s2,16(sp)
    80004374:	69a2                	ld	s3,8(sp)
    80004376:	6145                	addi	sp,sp,48
    80004378:	8082                	ret

000000008000437a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000437a:	1101                	addi	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	e426                	sd	s1,8(sp)
    80004382:	e04a                	sd	s2,0(sp)
    80004384:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004386:	0001e517          	auipc	a0,0x1e
    8000438a:	98250513          	addi	a0,a0,-1662 # 80021d08 <log>
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	870080e7          	jalr	-1936(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    80004396:	0001e497          	auipc	s1,0x1e
    8000439a:	97248493          	addi	s1,s1,-1678 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000439e:	4979                	li	s2,30
    800043a0:	a039                	j	800043ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800043a2:	85a6                	mv	a1,s1
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffe097          	auipc	ra,0xffffe
    800043aa:	0a8080e7          	jalr	168(ra) # 8000244e <sleep>
    if(log.committing){
    800043ae:	50dc                	lw	a5,36(s1)
    800043b0:	fbed                	bnez	a5,800043a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043b2:	509c                	lw	a5,32(s1)
    800043b4:	0017871b          	addiw	a4,a5,1
    800043b8:	0007069b          	sext.w	a3,a4
    800043bc:	0027179b          	slliw	a5,a4,0x2
    800043c0:	9fb9                	addw	a5,a5,a4
    800043c2:	0017979b          	slliw	a5,a5,0x1
    800043c6:	54d8                	lw	a4,44(s1)
    800043c8:	9fb9                	addw	a5,a5,a4
    800043ca:	00f95963          	bge	s2,a5,800043dc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043ce:	85a6                	mv	a1,s1
    800043d0:	8526                	mv	a0,s1
    800043d2:	ffffe097          	auipc	ra,0xffffe
    800043d6:	07c080e7          	jalr	124(ra) # 8000244e <sleep>
    800043da:	bfd1                	j	800043ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043dc:	0001e517          	auipc	a0,0x1e
    800043e0:	92c50513          	addi	a0,a0,-1748 # 80021d08 <log>
    800043e4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8cc080e7          	jalr	-1844(ra) # 80000cb2 <release>
      break;
    }
  }
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043fa:	7139                	addi	sp,sp,-64
    800043fc:	fc06                	sd	ra,56(sp)
    800043fe:	f822                	sd	s0,48(sp)
    80004400:	f426                	sd	s1,40(sp)
    80004402:	f04a                	sd	s2,32(sp)
    80004404:	ec4e                	sd	s3,24(sp)
    80004406:	e852                	sd	s4,16(sp)
    80004408:	e456                	sd	s5,8(sp)
    8000440a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000440c:	0001e497          	auipc	s1,0x1e
    80004410:	8fc48493          	addi	s1,s1,-1796 # 80021d08 <log>
    80004414:	8526                	mv	a0,s1
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7e8080e7          	jalr	2024(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    8000441e:	509c                	lw	a5,32(s1)
    80004420:	37fd                	addiw	a5,a5,-1
    80004422:	0007891b          	sext.w	s2,a5
    80004426:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004428:	50dc                	lw	a5,36(s1)
    8000442a:	e7b9                	bnez	a5,80004478 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000442c:	04091e63          	bnez	s2,80004488 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004430:	0001e497          	auipc	s1,0x1e
    80004434:	8d848493          	addi	s1,s1,-1832 # 80021d08 <log>
    80004438:	4785                	li	a5,1
    8000443a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000443c:	8526                	mv	a0,s1
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	874080e7          	jalr	-1932(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004446:	54dc                	lw	a5,44(s1)
    80004448:	06f04763          	bgtz	a5,800044b6 <end_op+0xbc>
    acquire(&log.lock);
    8000444c:	0001e497          	auipc	s1,0x1e
    80004450:	8bc48493          	addi	s1,s1,-1860 # 80021d08 <log>
    80004454:	8526                	mv	a0,s1
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	7a8080e7          	jalr	1960(ra) # 80000bfe <acquire>
    log.committing = 0;
    8000445e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	16a080e7          	jalr	362(ra) # 800025ce <wakeup>
    release(&log.lock);
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	844080e7          	jalr	-1980(ra) # 80000cb2 <release>
}
    80004476:	a03d                	j	800044a4 <end_op+0xaa>
    panic("log.committing");
    80004478:	00004517          	auipc	a0,0x4
    8000447c:	1e050513          	addi	a0,a0,480 # 80008658 <syscalls+0x1e0>
    80004480:	ffffc097          	auipc	ra,0xffffc
    80004484:	0c2080e7          	jalr	194(ra) # 80000542 <panic>
    wakeup(&log);
    80004488:	0001e497          	auipc	s1,0x1e
    8000448c:	88048493          	addi	s1,s1,-1920 # 80021d08 <log>
    80004490:	8526                	mv	a0,s1
    80004492:	ffffe097          	auipc	ra,0xffffe
    80004496:	13c080e7          	jalr	316(ra) # 800025ce <wakeup>
  release(&log.lock);
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	816080e7          	jalr	-2026(ra) # 80000cb2 <release>
}
    800044a4:	70e2                	ld	ra,56(sp)
    800044a6:	7442                	ld	s0,48(sp)
    800044a8:	74a2                	ld	s1,40(sp)
    800044aa:	7902                	ld	s2,32(sp)
    800044ac:	69e2                	ld	s3,24(sp)
    800044ae:	6a42                	ld	s4,16(sp)
    800044b0:	6aa2                	ld	s5,8(sp)
    800044b2:	6121                	addi	sp,sp,64
    800044b4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b6:	0001ea97          	auipc	s5,0x1e
    800044ba:	882a8a93          	addi	s5,s5,-1918 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044be:	0001ea17          	auipc	s4,0x1e
    800044c2:	84aa0a13          	addi	s4,s4,-1974 # 80021d08 <log>
    800044c6:	018a2583          	lw	a1,24(s4)
    800044ca:	012585bb          	addw	a1,a1,s2
    800044ce:	2585                	addiw	a1,a1,1
    800044d0:	028a2503          	lw	a0,40(s4)
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	ce8080e7          	jalr	-792(ra) # 800031bc <bread>
    800044dc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044de:	000aa583          	lw	a1,0(s5)
    800044e2:	028a2503          	lw	a0,40(s4)
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	cd6080e7          	jalr	-810(ra) # 800031bc <bread>
    800044ee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044f0:	40000613          	li	a2,1024
    800044f4:	05850593          	addi	a1,a0,88
    800044f8:	05848513          	addi	a0,s1,88
    800044fc:	ffffd097          	auipc	ra,0xffffd
    80004500:	85a080e7          	jalr	-1958(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    80004504:	8526                	mv	a0,s1
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	da8080e7          	jalr	-600(ra) # 800032ae <bwrite>
    brelse(from);
    8000450e:	854e                	mv	a0,s3
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	ddc080e7          	jalr	-548(ra) # 800032ec <brelse>
    brelse(to);
    80004518:	8526                	mv	a0,s1
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	dd2080e7          	jalr	-558(ra) # 800032ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004522:	2905                	addiw	s2,s2,1
    80004524:	0a91                	addi	s5,s5,4
    80004526:	02ca2783          	lw	a5,44(s4)
    8000452a:	f8f94ee3          	blt	s2,a5,800044c6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	c7a080e7          	jalr	-902(ra) # 800041a8 <write_head>
    install_trans(); // Now install writes to home locations
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	cec080e7          	jalr	-788(ra) # 80004222 <install_trans>
    log.lh.n = 0;
    8000453e:	0001d797          	auipc	a5,0x1d
    80004542:	7e07ab23          	sw	zero,2038(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	c62080e7          	jalr	-926(ra) # 800041a8 <write_head>
    8000454e:	bdfd                	j	8000444c <end_op+0x52>

0000000080004550 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	e04a                	sd	s2,0(sp)
    8000455a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000455c:	0001d717          	auipc	a4,0x1d
    80004560:	7d872703          	lw	a4,2008(a4) # 80021d34 <log+0x2c>
    80004564:	47f5                	li	a5,29
    80004566:	08e7c063          	blt	a5,a4,800045e6 <log_write+0x96>
    8000456a:	84aa                	mv	s1,a0
    8000456c:	0001d797          	auipc	a5,0x1d
    80004570:	7b87a783          	lw	a5,1976(a5) # 80021d24 <log+0x1c>
    80004574:	37fd                	addiw	a5,a5,-1
    80004576:	06f75863          	bge	a4,a5,800045e6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000457a:	0001d797          	auipc	a5,0x1d
    8000457e:	7ae7a783          	lw	a5,1966(a5) # 80021d28 <log+0x20>
    80004582:	06f05a63          	blez	a5,800045f6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004586:	0001d917          	auipc	s2,0x1d
    8000458a:	78290913          	addi	s2,s2,1922 # 80021d08 <log>
    8000458e:	854a                	mv	a0,s2
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	66e080e7          	jalr	1646(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004598:	02c92603          	lw	a2,44(s2)
    8000459c:	06c05563          	blez	a2,80004606 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045a0:	44cc                	lw	a1,12(s1)
    800045a2:	0001d717          	auipc	a4,0x1d
    800045a6:	79670713          	addi	a4,a4,1942 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045aa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045ac:	4314                	lw	a3,0(a4)
    800045ae:	04b68d63          	beq	a3,a1,80004608 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800045b2:	2785                	addiw	a5,a5,1
    800045b4:	0711                	addi	a4,a4,4
    800045b6:	fec79be3          	bne	a5,a2,800045ac <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045ba:	0621                	addi	a2,a2,8
    800045bc:	060a                	slli	a2,a2,0x2
    800045be:	0001d797          	auipc	a5,0x1d
    800045c2:	74a78793          	addi	a5,a5,1866 # 80021d08 <log>
    800045c6:	963e                	add	a2,a2,a5
    800045c8:	44dc                	lw	a5,12(s1)
    800045ca:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045cc:	8526                	mv	a0,s1
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	dbc080e7          	jalr	-580(ra) # 8000338a <bpin>
    log.lh.n++;
    800045d6:	0001d717          	auipc	a4,0x1d
    800045da:	73270713          	addi	a4,a4,1842 # 80021d08 <log>
    800045de:	575c                	lw	a5,44(a4)
    800045e0:	2785                	addiw	a5,a5,1
    800045e2:	d75c                	sw	a5,44(a4)
    800045e4:	a83d                	j	80004622 <log_write+0xd2>
    panic("too big a transaction");
    800045e6:	00004517          	auipc	a0,0x4
    800045ea:	08250513          	addi	a0,a0,130 # 80008668 <syscalls+0x1f0>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	f54080e7          	jalr	-172(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    800045f6:	00004517          	auipc	a0,0x4
    800045fa:	08a50513          	addi	a0,a0,138 # 80008680 <syscalls+0x208>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	f44080e7          	jalr	-188(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004606:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004608:	00878713          	addi	a4,a5,8
    8000460c:	00271693          	slli	a3,a4,0x2
    80004610:	0001d717          	auipc	a4,0x1d
    80004614:	6f870713          	addi	a4,a4,1784 # 80021d08 <log>
    80004618:	9736                	add	a4,a4,a3
    8000461a:	44d4                	lw	a3,12(s1)
    8000461c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000461e:	faf607e3          	beq	a2,a5,800045cc <log_write+0x7c>
  }
  release(&log.lock);
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	6e650513          	addi	a0,a0,1766 # 80021d08 <log>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	688080e7          	jalr	1672(ra) # 80000cb2 <release>
}
    80004632:	60e2                	ld	ra,24(sp)
    80004634:	6442                	ld	s0,16(sp)
    80004636:	64a2                	ld	s1,8(sp)
    80004638:	6902                	ld	s2,0(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
    8000464a:	84aa                	mv	s1,a0
    8000464c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000464e:	00004597          	auipc	a1,0x4
    80004652:	05258593          	addi	a1,a1,82 # 800086a0 <syscalls+0x228>
    80004656:	0521                	addi	a0,a0,8
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	516080e7          	jalr	1302(ra) # 80000b6e <initlock>
  lk->name = name;
    80004660:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004664:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004668:	0204a423          	sw	zero,40(s1)
}
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6902                	ld	s2,0(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	e04a                	sd	s2,0(sp)
    80004682:	1000                	addi	s0,sp,32
    80004684:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004686:	00850913          	addi	s2,a0,8
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	572080e7          	jalr	1394(ra) # 80000bfe <acquire>
  while (lk->locked) {
    80004694:	409c                	lw	a5,0(s1)
    80004696:	cb89                	beqz	a5,800046a8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004698:	85ca                	mv	a1,s2
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffe097          	auipc	ra,0xffffe
    800046a0:	db2080e7          	jalr	-590(ra) # 8000244e <sleep>
  while (lk->locked) {
    800046a4:	409c                	lw	a5,0(s1)
    800046a6:	fbed                	bnez	a5,80004698 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046a8:	4785                	li	a5,1
    800046aa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046ac:	ffffd097          	auipc	ra,0xffffd
    800046b0:	486080e7          	jalr	1158(ra) # 80001b32 <myproc>
    800046b4:	5d1c                	lw	a5,56(a0)
    800046b6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5f8080e7          	jalr	1528(ra) # 80000cb2 <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046ce:	1101                	addi	sp,sp,-32
    800046d0:	ec06                	sd	ra,24(sp)
    800046d2:	e822                	sd	s0,16(sp)
    800046d4:	e426                	sd	s1,8(sp)
    800046d6:	e04a                	sd	s2,0(sp)
    800046d8:	1000                	addi	s0,sp,32
    800046da:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046dc:	00850913          	addi	s2,a0,8
    800046e0:	854a                	mv	a0,s2
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	51c080e7          	jalr	1308(ra) # 80000bfe <acquire>
  lk->locked = 0;
    800046ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ee:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	eda080e7          	jalr	-294(ra) # 800025ce <wakeup>
  release(&lk->lk);
    800046fc:	854a                	mv	a0,s2
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	5b4080e7          	jalr	1460(ra) # 80000cb2 <release>
}
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6902                	ld	s2,0(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret

0000000080004712 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004712:	7179                	addi	sp,sp,-48
    80004714:	f406                	sd	ra,40(sp)
    80004716:	f022                	sd	s0,32(sp)
    80004718:	ec26                	sd	s1,24(sp)
    8000471a:	e84a                	sd	s2,16(sp)
    8000471c:	e44e                	sd	s3,8(sp)
    8000471e:	1800                	addi	s0,sp,48
    80004720:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004722:	00850913          	addi	s2,a0,8
    80004726:	854a                	mv	a0,s2
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	4d6080e7          	jalr	1238(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004730:	409c                	lw	a5,0(s1)
    80004732:	ef99                	bnez	a5,80004750 <holdingsleep+0x3e>
    80004734:	4481                	li	s1,0
  release(&lk->lk);
    80004736:	854a                	mv	a0,s2
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	57a080e7          	jalr	1402(ra) # 80000cb2 <release>
  return r;
}
    80004740:	8526                	mv	a0,s1
    80004742:	70a2                	ld	ra,40(sp)
    80004744:	7402                	ld	s0,32(sp)
    80004746:	64e2                	ld	s1,24(sp)
    80004748:	6942                	ld	s2,16(sp)
    8000474a:	69a2                	ld	s3,8(sp)
    8000474c:	6145                	addi	sp,sp,48
    8000474e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004750:	0284a983          	lw	s3,40(s1)
    80004754:	ffffd097          	auipc	ra,0xffffd
    80004758:	3de080e7          	jalr	990(ra) # 80001b32 <myproc>
    8000475c:	5d04                	lw	s1,56(a0)
    8000475e:	413484b3          	sub	s1,s1,s3
    80004762:	0014b493          	seqz	s1,s1
    80004766:	bfc1                	j	80004736 <holdingsleep+0x24>

0000000080004768 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004768:	1141                	addi	sp,sp,-16
    8000476a:	e406                	sd	ra,8(sp)
    8000476c:	e022                	sd	s0,0(sp)
    8000476e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004770:	00004597          	auipc	a1,0x4
    80004774:	f4058593          	addi	a1,a1,-192 # 800086b0 <syscalls+0x238>
    80004778:	0001d517          	auipc	a0,0x1d
    8000477c:	6d850513          	addi	a0,a0,1752 # 80021e50 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	3ee080e7          	jalr	1006(ra) # 80000b6e <initlock>
}
    80004788:	60a2                	ld	ra,8(sp)
    8000478a:	6402                	ld	s0,0(sp)
    8000478c:	0141                	addi	sp,sp,16
    8000478e:	8082                	ret

0000000080004790 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004790:	1101                	addi	sp,sp,-32
    80004792:	ec06                	sd	ra,24(sp)
    80004794:	e822                	sd	s0,16(sp)
    80004796:	e426                	sd	s1,8(sp)
    80004798:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000479a:	0001d517          	auipc	a0,0x1d
    8000479e:	6b650513          	addi	a0,a0,1718 # 80021e50 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	45c080e7          	jalr	1116(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047aa:	0001d497          	auipc	s1,0x1d
    800047ae:	6be48493          	addi	s1,s1,1726 # 80021e68 <ftable+0x18>
    800047b2:	0001e717          	auipc	a4,0x1e
    800047b6:	65670713          	addi	a4,a4,1622 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    800047ba:	40dc                	lw	a5,4(s1)
    800047bc:	cf99                	beqz	a5,800047da <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047be:	02848493          	addi	s1,s1,40
    800047c2:	fee49ce3          	bne	s1,a4,800047ba <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	68a50513          	addi	a0,a0,1674 # 80021e50 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4e4080e7          	jalr	1252(ra) # 80000cb2 <release>
  return 0;
    800047d6:	4481                	li	s1,0
    800047d8:	a819                	j	800047ee <filealloc+0x5e>
      f->ref = 1;
    800047da:	4785                	li	a5,1
    800047dc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	67250513          	addi	a0,a0,1650 # 80021e50 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	4cc080e7          	jalr	1228(ra) # 80000cb2 <release>
}
    800047ee:	8526                	mv	a0,s1
    800047f0:	60e2                	ld	ra,24(sp)
    800047f2:	6442                	ld	s0,16(sp)
    800047f4:	64a2                	ld	s1,8(sp)
    800047f6:	6105                	addi	sp,sp,32
    800047f8:	8082                	ret

00000000800047fa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047fa:	1101                	addi	sp,sp,-32
    800047fc:	ec06                	sd	ra,24(sp)
    800047fe:	e822                	sd	s0,16(sp)
    80004800:	e426                	sd	s1,8(sp)
    80004802:	1000                	addi	s0,sp,32
    80004804:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	64a50513          	addi	a0,a0,1610 # 80021e50 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	3f0080e7          	jalr	1008(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004816:	40dc                	lw	a5,4(s1)
    80004818:	02f05263          	blez	a5,8000483c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000481c:	2785                	addiw	a5,a5,1
    8000481e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004820:	0001d517          	auipc	a0,0x1d
    80004824:	63050513          	addi	a0,a0,1584 # 80021e50 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	48a080e7          	jalr	1162(ra) # 80000cb2 <release>
  return f;
}
    80004830:	8526                	mv	a0,s1
    80004832:	60e2                	ld	ra,24(sp)
    80004834:	6442                	ld	s0,16(sp)
    80004836:	64a2                	ld	s1,8(sp)
    80004838:	6105                	addi	sp,sp,32
    8000483a:	8082                	ret
    panic("filedup");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	e7c50513          	addi	a0,a0,-388 # 800086b8 <syscalls+0x240>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	cfe080e7          	jalr	-770(ra) # 80000542 <panic>

000000008000484c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000484c:	7139                	addi	sp,sp,-64
    8000484e:	fc06                	sd	ra,56(sp)
    80004850:	f822                	sd	s0,48(sp)
    80004852:	f426                	sd	s1,40(sp)
    80004854:	f04a                	sd	s2,32(sp)
    80004856:	ec4e                	sd	s3,24(sp)
    80004858:	e852                	sd	s4,16(sp)
    8000485a:	e456                	sd	s5,8(sp)
    8000485c:	0080                	addi	s0,sp,64
    8000485e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004860:	0001d517          	auipc	a0,0x1d
    80004864:	5f050513          	addi	a0,a0,1520 # 80021e50 <ftable>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	396080e7          	jalr	918(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004870:	40dc                	lw	a5,4(s1)
    80004872:	06f05163          	blez	a5,800048d4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004876:	37fd                	addiw	a5,a5,-1
    80004878:	0007871b          	sext.w	a4,a5
    8000487c:	c0dc                	sw	a5,4(s1)
    8000487e:	06e04363          	bgtz	a4,800048e4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004882:	0004a903          	lw	s2,0(s1)
    80004886:	0094ca83          	lbu	s5,9(s1)
    8000488a:	0104ba03          	ld	s4,16(s1)
    8000488e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004892:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004896:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000489a:	0001d517          	auipc	a0,0x1d
    8000489e:	5b650513          	addi	a0,a0,1462 # 80021e50 <ftable>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	410080e7          	jalr	1040(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    800048aa:	4785                	li	a5,1
    800048ac:	04f90d63          	beq	s2,a5,80004906 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048b0:	3979                	addiw	s2,s2,-2
    800048b2:	4785                	li	a5,1
    800048b4:	0527e063          	bltu	a5,s2,800048f4 <fileclose+0xa8>
    begin_op();
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	ac2080e7          	jalr	-1342(ra) # 8000437a <begin_op>
    iput(ff.ip);
    800048c0:	854e                	mv	a0,s3
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	2b6080e7          	jalr	694(ra) # 80003b78 <iput>
    end_op();
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	b30080e7          	jalr	-1232(ra) # 800043fa <end_op>
    800048d2:	a00d                	j	800048f4 <fileclose+0xa8>
    panic("fileclose");
    800048d4:	00004517          	auipc	a0,0x4
    800048d8:	dec50513          	addi	a0,a0,-532 # 800086c0 <syscalls+0x248>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	c66080e7          	jalr	-922(ra) # 80000542 <panic>
    release(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	56c50513          	addi	a0,a0,1388 # 80021e50 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	3c6080e7          	jalr	966(ra) # 80000cb2 <release>
  }
}
    800048f4:	70e2                	ld	ra,56(sp)
    800048f6:	7442                	ld	s0,48(sp)
    800048f8:	74a2                	ld	s1,40(sp)
    800048fa:	7902                	ld	s2,32(sp)
    800048fc:	69e2                	ld	s3,24(sp)
    800048fe:	6a42                	ld	s4,16(sp)
    80004900:	6aa2                	ld	s5,8(sp)
    80004902:	6121                	addi	sp,sp,64
    80004904:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004906:	85d6                	mv	a1,s5
    80004908:	8552                	mv	a0,s4
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	372080e7          	jalr	882(ra) # 80004c7c <pipeclose>
    80004912:	b7cd                	j	800048f4 <fileclose+0xa8>

0000000080004914 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004914:	715d                	addi	sp,sp,-80
    80004916:	e486                	sd	ra,72(sp)
    80004918:	e0a2                	sd	s0,64(sp)
    8000491a:	fc26                	sd	s1,56(sp)
    8000491c:	f84a                	sd	s2,48(sp)
    8000491e:	f44e                	sd	s3,40(sp)
    80004920:	0880                	addi	s0,sp,80
    80004922:	84aa                	mv	s1,a0
    80004924:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	20c080e7          	jalr	524(ra) # 80001b32 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000492e:	409c                	lw	a5,0(s1)
    80004930:	37f9                	addiw	a5,a5,-2
    80004932:	4705                	li	a4,1
    80004934:	04f76763          	bltu	a4,a5,80004982 <filestat+0x6e>
    80004938:	892a                	mv	s2,a0
    ilock(f->ip);
    8000493a:	6c88                	ld	a0,24(s1)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	082080e7          	jalr	130(ra) # 800039be <ilock>
    stati(f->ip, &st);
    80004944:	fb840593          	addi	a1,s0,-72
    80004948:	6c88                	ld	a0,24(s1)
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	2fe080e7          	jalr	766(ra) # 80003c48 <stati>
    iunlock(f->ip);
    80004952:	6c88                	ld	a0,24(s1)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	12c080e7          	jalr	300(ra) # 80003a80 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000495c:	46e1                	li	a3,24
    8000495e:	fb840613          	addi	a2,s0,-72
    80004962:	85ce                	mv	a1,s3
    80004964:	05893503          	ld	a0,88(s2)
    80004968:	ffffd097          	auipc	ra,0xffffd
    8000496c:	d5e080e7          	jalr	-674(ra) # 800016c6 <copyout>
    80004970:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004974:	60a6                	ld	ra,72(sp)
    80004976:	6406                	ld	s0,64(sp)
    80004978:	74e2                	ld	s1,56(sp)
    8000497a:	7942                	ld	s2,48(sp)
    8000497c:	79a2                	ld	s3,40(sp)
    8000497e:	6161                	addi	sp,sp,80
    80004980:	8082                	ret
  return -1;
    80004982:	557d                	li	a0,-1
    80004984:	bfc5                	j	80004974 <filestat+0x60>

0000000080004986 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004986:	7179                	addi	sp,sp,-48
    80004988:	f406                	sd	ra,40(sp)
    8000498a:	f022                	sd	s0,32(sp)
    8000498c:	ec26                	sd	s1,24(sp)
    8000498e:	e84a                	sd	s2,16(sp)
    80004990:	e44e                	sd	s3,8(sp)
    80004992:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004994:	00854783          	lbu	a5,8(a0)
    80004998:	c3d5                	beqz	a5,80004a3c <fileread+0xb6>
    8000499a:	84aa                	mv	s1,a0
    8000499c:	89ae                	mv	s3,a1
    8000499e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049a0:	411c                	lw	a5,0(a0)
    800049a2:	4705                	li	a4,1
    800049a4:	04e78963          	beq	a5,a4,800049f6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a8:	470d                	li	a4,3
    800049aa:	04e78d63          	beq	a5,a4,80004a04 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ae:	4709                	li	a4,2
    800049b0:	06e79e63          	bne	a5,a4,80004a2c <fileread+0xa6>
    ilock(f->ip);
    800049b4:	6d08                	ld	a0,24(a0)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	008080e7          	jalr	8(ra) # 800039be <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049be:	874a                	mv	a4,s2
    800049c0:	5094                	lw	a3,32(s1)
    800049c2:	864e                	mv	a2,s3
    800049c4:	4585                	li	a1,1
    800049c6:	6c88                	ld	a0,24(s1)
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	2aa080e7          	jalr	682(ra) # 80003c72 <readi>
    800049d0:	892a                	mv	s2,a0
    800049d2:	00a05563          	blez	a0,800049dc <fileread+0x56>
      f->off += r;
    800049d6:	509c                	lw	a5,32(s1)
    800049d8:	9fa9                	addw	a5,a5,a0
    800049da:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049dc:	6c88                	ld	a0,24(s1)
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	0a2080e7          	jalr	162(ra) # 80003a80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049e6:	854a                	mv	a0,s2
    800049e8:	70a2                	ld	ra,40(sp)
    800049ea:	7402                	ld	s0,32(sp)
    800049ec:	64e2                	ld	s1,24(sp)
    800049ee:	6942                	ld	s2,16(sp)
    800049f0:	69a2                	ld	s3,8(sp)
    800049f2:	6145                	addi	sp,sp,48
    800049f4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049f6:	6908                	ld	a0,16(a0)
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	3f4080e7          	jalr	1012(ra) # 80004dec <piperead>
    80004a00:	892a                	mv	s2,a0
    80004a02:	b7d5                	j	800049e6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a04:	02451783          	lh	a5,36(a0)
    80004a08:	03079693          	slli	a3,a5,0x30
    80004a0c:	92c1                	srli	a3,a3,0x30
    80004a0e:	4725                	li	a4,9
    80004a10:	02d76863          	bltu	a4,a3,80004a40 <fileread+0xba>
    80004a14:	0792                	slli	a5,a5,0x4
    80004a16:	0001d717          	auipc	a4,0x1d
    80004a1a:	39a70713          	addi	a4,a4,922 # 80021db0 <devsw>
    80004a1e:	97ba                	add	a5,a5,a4
    80004a20:	639c                	ld	a5,0(a5)
    80004a22:	c38d                	beqz	a5,80004a44 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a24:	4505                	li	a0,1
    80004a26:	9782                	jalr	a5
    80004a28:	892a                	mv	s2,a0
    80004a2a:	bf75                	j	800049e6 <fileread+0x60>
    panic("fileread");
    80004a2c:	00004517          	auipc	a0,0x4
    80004a30:	ca450513          	addi	a0,a0,-860 # 800086d0 <syscalls+0x258>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	b0e080e7          	jalr	-1266(ra) # 80000542 <panic>
    return -1;
    80004a3c:	597d                	li	s2,-1
    80004a3e:	b765                	j	800049e6 <fileread+0x60>
      return -1;
    80004a40:	597d                	li	s2,-1
    80004a42:	b755                	j	800049e6 <fileread+0x60>
    80004a44:	597d                	li	s2,-1
    80004a46:	b745                	j	800049e6 <fileread+0x60>

0000000080004a48 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a48:	00954783          	lbu	a5,9(a0)
    80004a4c:	14078563          	beqz	a5,80004b96 <filewrite+0x14e>
{
    80004a50:	715d                	addi	sp,sp,-80
    80004a52:	e486                	sd	ra,72(sp)
    80004a54:	e0a2                	sd	s0,64(sp)
    80004a56:	fc26                	sd	s1,56(sp)
    80004a58:	f84a                	sd	s2,48(sp)
    80004a5a:	f44e                	sd	s3,40(sp)
    80004a5c:	f052                	sd	s4,32(sp)
    80004a5e:	ec56                	sd	s5,24(sp)
    80004a60:	e85a                	sd	s6,16(sp)
    80004a62:	e45e                	sd	s7,8(sp)
    80004a64:	e062                	sd	s8,0(sp)
    80004a66:	0880                	addi	s0,sp,80
    80004a68:	892a                	mv	s2,a0
    80004a6a:	8aae                	mv	s5,a1
    80004a6c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a6e:	411c                	lw	a5,0(a0)
    80004a70:	4705                	li	a4,1
    80004a72:	02e78263          	beq	a5,a4,80004a96 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a76:	470d                	li	a4,3
    80004a78:	02e78563          	beq	a5,a4,80004aa2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a7c:	4709                	li	a4,2
    80004a7e:	10e79463          	bne	a5,a4,80004b86 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a82:	0ec05e63          	blez	a2,80004b7e <filewrite+0x136>
    int i = 0;
    80004a86:	4981                	li	s3,0
    80004a88:	6b05                	lui	s6,0x1
    80004a8a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a8e:	6b85                	lui	s7,0x1
    80004a90:	c00b8b9b          	addiw	s7,s7,-1024
    80004a94:	a851                	j	80004b28 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a96:	6908                	ld	a0,16(a0)
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	254080e7          	jalr	596(ra) # 80004cec <pipewrite>
    80004aa0:	a85d                	j	80004b56 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aa2:	02451783          	lh	a5,36(a0)
    80004aa6:	03079693          	slli	a3,a5,0x30
    80004aaa:	92c1                	srli	a3,a3,0x30
    80004aac:	4725                	li	a4,9
    80004aae:	0ed76663          	bltu	a4,a3,80004b9a <filewrite+0x152>
    80004ab2:	0792                	slli	a5,a5,0x4
    80004ab4:	0001d717          	auipc	a4,0x1d
    80004ab8:	2fc70713          	addi	a4,a4,764 # 80021db0 <devsw>
    80004abc:	97ba                	add	a5,a5,a4
    80004abe:	679c                	ld	a5,8(a5)
    80004ac0:	cff9                	beqz	a5,80004b9e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004ac2:	4505                	li	a0,1
    80004ac4:	9782                	jalr	a5
    80004ac6:	a841                	j	80004b56 <filewrite+0x10e>
    80004ac8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	8ae080e7          	jalr	-1874(ra) # 8000437a <begin_op>
      ilock(f->ip);
    80004ad4:	01893503          	ld	a0,24(s2)
    80004ad8:	fffff097          	auipc	ra,0xfffff
    80004adc:	ee6080e7          	jalr	-282(ra) # 800039be <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ae0:	8762                	mv	a4,s8
    80004ae2:	02092683          	lw	a3,32(s2)
    80004ae6:	01598633          	add	a2,s3,s5
    80004aea:	4585                	li	a1,1
    80004aec:	01893503          	ld	a0,24(s2)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	278080e7          	jalr	632(ra) # 80003d68 <writei>
    80004af8:	84aa                	mv	s1,a0
    80004afa:	02a05f63          	blez	a0,80004b38 <filewrite+0xf0>
        f->off += r;
    80004afe:	02092783          	lw	a5,32(s2)
    80004b02:	9fa9                	addw	a5,a5,a0
    80004b04:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b08:	01893503          	ld	a0,24(s2)
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	f74080e7          	jalr	-140(ra) # 80003a80 <iunlock>
      end_op();
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	8e6080e7          	jalr	-1818(ra) # 800043fa <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004b1c:	049c1963          	bne	s8,s1,80004b6e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004b20:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b24:	0349d663          	bge	s3,s4,80004b50 <filewrite+0x108>
      int n1 = n - i;
    80004b28:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b2c:	84be                	mv	s1,a5
    80004b2e:	2781                	sext.w	a5,a5
    80004b30:	f8fb5ce3          	bge	s6,a5,80004ac8 <filewrite+0x80>
    80004b34:	84de                	mv	s1,s7
    80004b36:	bf49                	j	80004ac8 <filewrite+0x80>
      iunlock(f->ip);
    80004b38:	01893503          	ld	a0,24(s2)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	f44080e7          	jalr	-188(ra) # 80003a80 <iunlock>
      end_op();
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	8b6080e7          	jalr	-1866(ra) # 800043fa <end_op>
      if(r < 0)
    80004b4c:	fc04d8e3          	bgez	s1,80004b1c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b50:	8552                	mv	a0,s4
    80004b52:	033a1863          	bne	s4,s3,80004b82 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b56:	60a6                	ld	ra,72(sp)
    80004b58:	6406                	ld	s0,64(sp)
    80004b5a:	74e2                	ld	s1,56(sp)
    80004b5c:	7942                	ld	s2,48(sp)
    80004b5e:	79a2                	ld	s3,40(sp)
    80004b60:	7a02                	ld	s4,32(sp)
    80004b62:	6ae2                	ld	s5,24(sp)
    80004b64:	6b42                	ld	s6,16(sp)
    80004b66:	6ba2                	ld	s7,8(sp)
    80004b68:	6c02                	ld	s8,0(sp)
    80004b6a:	6161                	addi	sp,sp,80
    80004b6c:	8082                	ret
        panic("short filewrite");
    80004b6e:	00004517          	auipc	a0,0x4
    80004b72:	b7250513          	addi	a0,a0,-1166 # 800086e0 <syscalls+0x268>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	9cc080e7          	jalr	-1588(ra) # 80000542 <panic>
    int i = 0;
    80004b7e:	4981                	li	s3,0
    80004b80:	bfc1                	j	80004b50 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b82:	557d                	li	a0,-1
    80004b84:	bfc9                	j	80004b56 <filewrite+0x10e>
    panic("filewrite");
    80004b86:	00004517          	auipc	a0,0x4
    80004b8a:	b6a50513          	addi	a0,a0,-1174 # 800086f0 <syscalls+0x278>
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	9b4080e7          	jalr	-1612(ra) # 80000542 <panic>
    return -1;
    80004b96:	557d                	li	a0,-1
}
    80004b98:	8082                	ret
      return -1;
    80004b9a:	557d                	li	a0,-1
    80004b9c:	bf6d                	j	80004b56 <filewrite+0x10e>
    80004b9e:	557d                	li	a0,-1
    80004ba0:	bf5d                	j	80004b56 <filewrite+0x10e>

0000000080004ba2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ba2:	7179                	addi	sp,sp,-48
    80004ba4:	f406                	sd	ra,40(sp)
    80004ba6:	f022                	sd	s0,32(sp)
    80004ba8:	ec26                	sd	s1,24(sp)
    80004baa:	e84a                	sd	s2,16(sp)
    80004bac:	e44e                	sd	s3,8(sp)
    80004bae:	e052                	sd	s4,0(sp)
    80004bb0:	1800                	addi	s0,sp,48
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bb6:	0005b023          	sd	zero,0(a1)
    80004bba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	bd2080e7          	jalr	-1070(ra) # 80004790 <filealloc>
    80004bc6:	e088                	sd	a0,0(s1)
    80004bc8:	c551                	beqz	a0,80004c54 <pipealloc+0xb2>
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	bc6080e7          	jalr	-1082(ra) # 80004790 <filealloc>
    80004bd2:	00aa3023          	sd	a0,0(s4)
    80004bd6:	c92d                	beqz	a0,80004c48 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	f36080e7          	jalr	-202(ra) # 80000b0e <kalloc>
    80004be0:	892a                	mv	s2,a0
    80004be2:	c125                	beqz	a0,80004c42 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004be4:	4985                	li	s3,1
    80004be6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bf2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bf6:	00004597          	auipc	a1,0x4
    80004bfa:	b0a58593          	addi	a1,a1,-1270 # 80008700 <syscalls+0x288>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	f70080e7          	jalr	-144(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004c06:	609c                	ld	a5,0(s1)
    80004c08:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c18:	609c                	ld	a5,0(s1)
    80004c1a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c1e:	000a3783          	ld	a5,0(s4)
    80004c22:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c26:	000a3783          	ld	a5,0(s4)
    80004c2a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c2e:	000a3783          	ld	a5,0(s4)
    80004c32:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c36:	000a3783          	ld	a5,0(s4)
    80004c3a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c3e:	4501                	li	a0,0
    80004c40:	a025                	j	80004c68 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c42:	6088                	ld	a0,0(s1)
    80004c44:	e501                	bnez	a0,80004c4c <pipealloc+0xaa>
    80004c46:	a039                	j	80004c54 <pipealloc+0xb2>
    80004c48:	6088                	ld	a0,0(s1)
    80004c4a:	c51d                	beqz	a0,80004c78 <pipealloc+0xd6>
    fileclose(*f0);
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	c00080e7          	jalr	-1024(ra) # 8000484c <fileclose>
  if(*f1)
    80004c54:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c58:	557d                	li	a0,-1
  if(*f1)
    80004c5a:	c799                	beqz	a5,80004c68 <pipealloc+0xc6>
    fileclose(*f1);
    80004c5c:	853e                	mv	a0,a5
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	bee080e7          	jalr	-1042(ra) # 8000484c <fileclose>
  return -1;
    80004c66:	557d                	li	a0,-1
}
    80004c68:	70a2                	ld	ra,40(sp)
    80004c6a:	7402                	ld	s0,32(sp)
    80004c6c:	64e2                	ld	s1,24(sp)
    80004c6e:	6942                	ld	s2,16(sp)
    80004c70:	69a2                	ld	s3,8(sp)
    80004c72:	6a02                	ld	s4,0(sp)
    80004c74:	6145                	addi	sp,sp,48
    80004c76:	8082                	ret
  return -1;
    80004c78:	557d                	li	a0,-1
    80004c7a:	b7fd                	j	80004c68 <pipealloc+0xc6>

0000000080004c7c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c7c:	1101                	addi	sp,sp,-32
    80004c7e:	ec06                	sd	ra,24(sp)
    80004c80:	e822                	sd	s0,16(sp)
    80004c82:	e426                	sd	s1,8(sp)
    80004c84:	e04a                	sd	s2,0(sp)
    80004c86:	1000                	addi	s0,sp,32
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	f72080e7          	jalr	-142(ra) # 80000bfe <acquire>
  if(writable){
    80004c94:	02090d63          	beqz	s2,80004cce <pipeclose+0x52>
    pi->writeopen = 0;
    80004c98:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c9c:	21848513          	addi	a0,s1,536
    80004ca0:	ffffe097          	auipc	ra,0xffffe
    80004ca4:	92e080e7          	jalr	-1746(ra) # 800025ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ca8:	2204b783          	ld	a5,544(s1)
    80004cac:	eb95                	bnez	a5,80004ce0 <pipeclose+0x64>
    release(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	002080e7          	jalr	2(ra) # 80000cb2 <release>
    kfree((char*)pi);
    80004cb8:	8526                	mv	a0,s1
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	d58080e7          	jalr	-680(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004cc2:	60e2                	ld	ra,24(sp)
    80004cc4:	6442                	ld	s0,16(sp)
    80004cc6:	64a2                	ld	s1,8(sp)
    80004cc8:	6902                	ld	s2,0(sp)
    80004cca:	6105                	addi	sp,sp,32
    80004ccc:	8082                	ret
    pi->readopen = 0;
    80004cce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cd2:	21c48513          	addi	a0,s1,540
    80004cd6:	ffffe097          	auipc	ra,0xffffe
    80004cda:	8f8080e7          	jalr	-1800(ra) # 800025ce <wakeup>
    80004cde:	b7e9                	j	80004ca8 <pipeclose+0x2c>
    release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	fd0080e7          	jalr	-48(ra) # 80000cb2 <release>
}
    80004cea:	bfe1                	j	80004cc2 <pipeclose+0x46>

0000000080004cec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cec:	711d                	addi	sp,sp,-96
    80004cee:	ec86                	sd	ra,88(sp)
    80004cf0:	e8a2                	sd	s0,80(sp)
    80004cf2:	e4a6                	sd	s1,72(sp)
    80004cf4:	e0ca                	sd	s2,64(sp)
    80004cf6:	fc4e                	sd	s3,56(sp)
    80004cf8:	f852                	sd	s4,48(sp)
    80004cfa:	f456                	sd	s5,40(sp)
    80004cfc:	f05a                	sd	s6,32(sp)
    80004cfe:	ec5e                	sd	s7,24(sp)
    80004d00:	e862                	sd	s8,16(sp)
    80004d02:	1080                	addi	s0,sp,96
    80004d04:	84aa                	mv	s1,a0
    80004d06:	8b2e                	mv	s6,a1
    80004d08:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	e28080e7          	jalr	-472(ra) # 80001b32 <myproc>
    80004d12:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	ee8080e7          	jalr	-280(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004d1e:	09505763          	blez	s5,80004dac <pipewrite+0xc0>
    80004d22:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d24:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d28:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d2c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d2e:	2184a783          	lw	a5,536(s1)
    80004d32:	21c4a703          	lw	a4,540(s1)
    80004d36:	2007879b          	addiw	a5,a5,512
    80004d3a:	02f71b63          	bne	a4,a5,80004d70 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d3e:	2204a783          	lw	a5,544(s1)
    80004d42:	c3d1                	beqz	a5,80004dc6 <pipewrite+0xda>
    80004d44:	03092783          	lw	a5,48(s2)
    80004d48:	efbd                	bnez	a5,80004dc6 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d4a:	8552                	mv	a0,s4
    80004d4c:	ffffe097          	auipc	ra,0xffffe
    80004d50:	882080e7          	jalr	-1918(ra) # 800025ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d54:	85a6                	mv	a1,s1
    80004d56:	854e                	mv	a0,s3
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	6f6080e7          	jalr	1782(ra) # 8000244e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d60:	2184a783          	lw	a5,536(s1)
    80004d64:	21c4a703          	lw	a4,540(s1)
    80004d68:	2007879b          	addiw	a5,a5,512
    80004d6c:	fcf709e3          	beq	a4,a5,80004d3e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d70:	4685                	li	a3,1
    80004d72:	865a                	mv	a2,s6
    80004d74:	faf40593          	addi	a1,s0,-81
    80004d78:	05893503          	ld	a0,88(s2)
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	9f0080e7          	jalr	-1552(ra) # 8000176c <copyin>
    80004d84:	03850563          	beq	a0,s8,80004dae <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d88:	21c4a783          	lw	a5,540(s1)
    80004d8c:	0017871b          	addiw	a4,a5,1
    80004d90:	20e4ae23          	sw	a4,540(s1)
    80004d94:	1ff7f793          	andi	a5,a5,511
    80004d98:	97a6                	add	a5,a5,s1
    80004d9a:	faf44703          	lbu	a4,-81(s0)
    80004d9e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004da2:	2b85                	addiw	s7,s7,1
    80004da4:	0b05                	addi	s6,s6,1
    80004da6:	f97a94e3          	bne	s5,s7,80004d2e <pipewrite+0x42>
    80004daa:	a011                	j	80004dae <pipewrite+0xc2>
    80004dac:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004dae:	21848513          	addi	a0,s1,536
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	81c080e7          	jalr	-2020(ra) # 800025ce <wakeup>
  release(&pi->lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	ef6080e7          	jalr	-266(ra) # 80000cb2 <release>
  return i;
    80004dc4:	a039                	j	80004dd2 <pipewrite+0xe6>
        release(&pi->lock);
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	eea080e7          	jalr	-278(ra) # 80000cb2 <release>
        return -1;
    80004dd0:	5bfd                	li	s7,-1
}
    80004dd2:	855e                	mv	a0,s7
    80004dd4:	60e6                	ld	ra,88(sp)
    80004dd6:	6446                	ld	s0,80(sp)
    80004dd8:	64a6                	ld	s1,72(sp)
    80004dda:	6906                	ld	s2,64(sp)
    80004ddc:	79e2                	ld	s3,56(sp)
    80004dde:	7a42                	ld	s4,48(sp)
    80004de0:	7aa2                	ld	s5,40(sp)
    80004de2:	7b02                	ld	s6,32(sp)
    80004de4:	6be2                	ld	s7,24(sp)
    80004de6:	6c42                	ld	s8,16(sp)
    80004de8:	6125                	addi	sp,sp,96
    80004dea:	8082                	ret

0000000080004dec <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dec:	715d                	addi	sp,sp,-80
    80004dee:	e486                	sd	ra,72(sp)
    80004df0:	e0a2                	sd	s0,64(sp)
    80004df2:	fc26                	sd	s1,56(sp)
    80004df4:	f84a                	sd	s2,48(sp)
    80004df6:	f44e                	sd	s3,40(sp)
    80004df8:	f052                	sd	s4,32(sp)
    80004dfa:	ec56                	sd	s5,24(sp)
    80004dfc:	e85a                	sd	s6,16(sp)
    80004dfe:	0880                	addi	s0,sp,80
    80004e00:	84aa                	mv	s1,a0
    80004e02:	892e                	mv	s2,a1
    80004e04:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	d2c080e7          	jalr	-724(ra) # 80001b32 <myproc>
    80004e0e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e10:	8526                	mv	a0,s1
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	dec080e7          	jalr	-532(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1a:	2184a703          	lw	a4,536(s1)
    80004e1e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e22:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e26:	02f71463          	bne	a4,a5,80004e4e <piperead+0x62>
    80004e2a:	2244a783          	lw	a5,548(s1)
    80004e2e:	c385                	beqz	a5,80004e4e <piperead+0x62>
    if(pr->killed){
    80004e30:	030a2783          	lw	a5,48(s4)
    80004e34:	ebc1                	bnez	a5,80004ec4 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e36:	85a6                	mv	a1,s1
    80004e38:	854e                	mv	a0,s3
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	614080e7          	jalr	1556(ra) # 8000244e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e42:	2184a703          	lw	a4,536(s1)
    80004e46:	21c4a783          	lw	a5,540(s1)
    80004e4a:	fef700e3          	beq	a4,a5,80004e2a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e50:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e52:	05505363          	blez	s5,80004e98 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e56:	2184a783          	lw	a5,536(s1)
    80004e5a:	21c4a703          	lw	a4,540(s1)
    80004e5e:	02f70d63          	beq	a4,a5,80004e98 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e62:	0017871b          	addiw	a4,a5,1
    80004e66:	20e4ac23          	sw	a4,536(s1)
    80004e6a:	1ff7f793          	andi	a5,a5,511
    80004e6e:	97a6                	add	a5,a5,s1
    80004e70:	0187c783          	lbu	a5,24(a5)
    80004e74:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e78:	4685                	li	a3,1
    80004e7a:	fbf40613          	addi	a2,s0,-65
    80004e7e:	85ca                	mv	a1,s2
    80004e80:	058a3503          	ld	a0,88(s4)
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	842080e7          	jalr	-1982(ra) # 800016c6 <copyout>
    80004e8c:	01650663          	beq	a0,s6,80004e98 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e90:	2985                	addiw	s3,s3,1
    80004e92:	0905                	addi	s2,s2,1
    80004e94:	fd3a91e3          	bne	s5,s3,80004e56 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e98:	21c48513          	addi	a0,s1,540
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	732080e7          	jalr	1842(ra) # 800025ce <wakeup>
  release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	e0c080e7          	jalr	-500(ra) # 80000cb2 <release>
  return i;
}
    80004eae:	854e                	mv	a0,s3
    80004eb0:	60a6                	ld	ra,72(sp)
    80004eb2:	6406                	ld	s0,64(sp)
    80004eb4:	74e2                	ld	s1,56(sp)
    80004eb6:	7942                	ld	s2,48(sp)
    80004eb8:	79a2                	ld	s3,40(sp)
    80004eba:	7a02                	ld	s4,32(sp)
    80004ebc:	6ae2                	ld	s5,24(sp)
    80004ebe:	6b42                	ld	s6,16(sp)
    80004ec0:	6161                	addi	sp,sp,80
    80004ec2:	8082                	ret
      release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	dec080e7          	jalr	-532(ra) # 80000cb2 <release>
      return -1;
    80004ece:	59fd                	li	s3,-1
    80004ed0:	bff9                	j	80004eae <piperead+0xc2>

0000000080004ed2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ed2:	dd010113          	addi	sp,sp,-560
    80004ed6:	22113423          	sd	ra,552(sp)
    80004eda:	22813023          	sd	s0,544(sp)
    80004ede:	20913c23          	sd	s1,536(sp)
    80004ee2:	21213823          	sd	s2,528(sp)
    80004ee6:	21313423          	sd	s3,520(sp)
    80004eea:	21413023          	sd	s4,512(sp)
    80004eee:	ffd6                	sd	s5,504(sp)
    80004ef0:	fbda                	sd	s6,496(sp)
    80004ef2:	f7de                	sd	s7,488(sp)
    80004ef4:	f3e2                	sd	s8,480(sp)
    80004ef6:	efe6                	sd	s9,472(sp)
    80004ef8:	ebea                	sd	s10,464(sp)
    80004efa:	e7ee                	sd	s11,456(sp)
    80004efc:	1c00                	addi	s0,sp,560
    80004efe:	892a                	mv	s2,a0
    80004f00:	dea43423          	sd	a0,-536(s0)
    80004f04:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	c2a080e7          	jalr	-982(ra) # 80001b32 <myproc>
    80004f10:	84aa                	mv	s1,a0

  begin_op();
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	468080e7          	jalr	1128(ra) # 8000437a <begin_op>

  if((ip = namei(path)) == 0){
    80004f1a:	854a                	mv	a0,s2
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	252080e7          	jalr	594(ra) # 8000416e <namei>
    80004f24:	cd2d                	beqz	a0,80004f9e <exec+0xcc>
    80004f26:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	a96080e7          	jalr	-1386(ra) # 800039be <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f30:	04000713          	li	a4,64
    80004f34:	4681                	li	a3,0
    80004f36:	e4840613          	addi	a2,s0,-440
    80004f3a:	4581                	li	a1,0
    80004f3c:	8552                	mv	a0,s4
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	d34080e7          	jalr	-716(ra) # 80003c72 <readi>
    80004f46:	04000793          	li	a5,64
    80004f4a:	00f51a63          	bne	a0,a5,80004f5e <exec+0x8c>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f4e:	e4842703          	lw	a4,-440(s0)
    80004f52:	464c47b7          	lui	a5,0x464c4
    80004f56:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f5a:	04f70863          	beq	a4,a5,80004faa <exec+0xd8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f5e:	8552                	mv	a0,s4
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	cc0080e7          	jalr	-832(ra) # 80003c20 <iunlockput>
    end_op();
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	492080e7          	jalr	1170(ra) # 800043fa <end_op>
  }
  return -1;
    80004f70:	557d                	li	a0,-1
}
    80004f72:	22813083          	ld	ra,552(sp)
    80004f76:	22013403          	ld	s0,544(sp)
    80004f7a:	21813483          	ld	s1,536(sp)
    80004f7e:	21013903          	ld	s2,528(sp)
    80004f82:	20813983          	ld	s3,520(sp)
    80004f86:	20013a03          	ld	s4,512(sp)
    80004f8a:	7afe                	ld	s5,504(sp)
    80004f8c:	7b5e                	ld	s6,496(sp)
    80004f8e:	7bbe                	ld	s7,488(sp)
    80004f90:	7c1e                	ld	s8,480(sp)
    80004f92:	6cfe                	ld	s9,472(sp)
    80004f94:	6d5e                	ld	s10,464(sp)
    80004f96:	6dbe                	ld	s11,456(sp)
    80004f98:	23010113          	addi	sp,sp,560
    80004f9c:	8082                	ret
    end_op();
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	45c080e7          	jalr	1116(ra) # 800043fa <end_op>
    return -1;
    80004fa6:	557d                	li	a0,-1
    80004fa8:	b7e9                	j	80004f72 <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004faa:	8526                	mv	a0,s1
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	c4a080e7          	jalr	-950(ra) # 80001bf6 <proc_pagetable>
    80004fb4:	8b2a                	mv	s6,a0
    80004fb6:	d545                	beqz	a0,80004f5e <exec+0x8c>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb8:	e6842783          	lw	a5,-408(s0)
    80004fbc:	e8045703          	lhu	a4,-384(s0)
    80004fc0:	cb35                	beqz	a4,80005034 <exec+0x162>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fc2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc4:	e0043423          	sd	zero,-504(s0)
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fc8:	0c000737          	lui	a4,0xc000
    80004fcc:	1779                	addi	a4,a4,-2
    80004fce:	dee43023          	sd	a4,-544(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fd2:	6a85                	lui	s5,0x1
    80004fd4:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80004fd8:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fdc:	6d85                	lui	s11,0x1
    80004fde:	aca5                	j	80005256 <exec+0x384>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fe0:	00003517          	auipc	a0,0x3
    80004fe4:	72850513          	addi	a0,a0,1832 # 80008708 <syscalls+0x290>
    80004fe8:	ffffb097          	auipc	ra,0xffffb
    80004fec:	55a080e7          	jalr	1370(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ff0:	874a                	mv	a4,s2
    80004ff2:	009c86bb          	addw	a3,s9,s1
    80004ff6:	4581                	li	a1,0
    80004ff8:	8552                	mv	a0,s4
    80004ffa:	fffff097          	auipc	ra,0xfffff
    80004ffe:	c78080e7          	jalr	-904(ra) # 80003c72 <readi>
    80005002:	2501                	sext.w	a0,a0
    80005004:	1ea91963          	bne	s2,a0,800051f6 <exec+0x324>
  for(i = 0; i < sz; i += PGSIZE){
    80005008:	009d84bb          	addw	s1,s11,s1
    8000500c:	013d09bb          	addw	s3,s10,s3
    80005010:	2374f363          	bgeu	s1,s7,80005236 <exec+0x364>
    pa = walkaddr(pagetable, va + i);
    80005014:	02049593          	slli	a1,s1,0x20
    80005018:	9181                	srli	a1,a1,0x20
    8000501a:	95e2                	add	a1,a1,s8
    8000501c:	855a                	mv	a0,s6
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	072080e7          	jalr	114(ra) # 80001090 <walkaddr>
    80005026:	862a                	mv	a2,a0
    if(pa == 0)
    80005028:	dd45                	beqz	a0,80004fe0 <exec+0x10e>
      n = PGSIZE;
    8000502a:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    8000502c:	fd59f2e3          	bgeu	s3,s5,80004ff0 <exec+0x11e>
      n = sz - i;
    80005030:	894e                	mv	s2,s3
    80005032:	bf7d                	j	80004ff0 <exec+0x11e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005034:	4481                	li	s1,0
  iunlockput(ip);
    80005036:	8552                	mv	a0,s4
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	be8080e7          	jalr	-1048(ra) # 80003c20 <iunlockput>
  end_op();
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	3ba080e7          	jalr	954(ra) # 800043fa <end_op>
  p = myproc();
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	aea080e7          	jalr	-1302(ra) # 80001b32 <myproc>
    80005050:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005052:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005056:	6785                	lui	a5,0x1
    80005058:	17fd                	addi	a5,a5,-1
    8000505a:	94be                	add	s1,s1,a5
    8000505c:	77fd                	lui	a5,0xfffff
    8000505e:	8fe5                	and	a5,a5,s1
    80005060:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005064:	6609                	lui	a2,0x2
    80005066:	963e                	add	a2,a2,a5
    80005068:	85be                	mv	a1,a5
    8000506a:	855a                	mv	a0,s6
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	426080e7          	jalr	1062(ra) # 80001492 <uvmalloc>
    80005074:	8baa                	mv	s7,a0
  ip = 0;
    80005076:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005078:	16050f63          	beqz	a0,800051f6 <exec+0x324>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000507c:	75f9                	lui	a1,0xffffe
    8000507e:	95aa                	add	a1,a1,a0
    80005080:	855a                	mv	a0,s6
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	612080e7          	jalr	1554(ra) # 80001694 <uvmclear>
  stackbase = sp - PGSIZE;
    8000508a:	7c7d                	lui	s8,0xfffff
    8000508c:	9c5e                	add	s8,s8,s7
  for(argc = 0; argv[argc]; argc++) {
    8000508e:	df043783          	ld	a5,-528(s0)
    80005092:	6388                	ld	a0,0(a5)
    80005094:	c925                	beqz	a0,80005104 <exec+0x232>
    80005096:	e8840993          	addi	s3,s0,-376
    8000509a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000509e:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    800050a0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	ddc080e7          	jalr	-548(ra) # 80000e7e <strlen>
    800050aa:	0015079b          	addiw	a5,a0,1
    800050ae:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050b2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050b6:	17896463          	bltu	s2,s8,8000521e <exec+0x34c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050ba:	df043d83          	ld	s11,-528(s0)
    800050be:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050c2:	8552                	mv	a0,s4
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	dba080e7          	jalr	-582(ra) # 80000e7e <strlen>
    800050cc:	0015069b          	addiw	a3,a0,1
    800050d0:	8652                	mv	a2,s4
    800050d2:	85ca                	mv	a1,s2
    800050d4:	855a                	mv	a0,s6
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	5f0080e7          	jalr	1520(ra) # 800016c6 <copyout>
    800050de:	14054463          	bltz	a0,80005226 <exec+0x354>
    ustack[argc] = sp;
    800050e2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050e6:	0485                	addi	s1,s1,1
    800050e8:	008d8793          	addi	a5,s11,8
    800050ec:	def43823          	sd	a5,-528(s0)
    800050f0:	008db503          	ld	a0,8(s11)
    800050f4:	c911                	beqz	a0,80005108 <exec+0x236>
    if(argc >= MAXARG)
    800050f6:	09a1                	addi	s3,s3,8
    800050f8:	fb3c95e3          	bne	s9,s3,800050a2 <exec+0x1d0>
  sz = sz1;
    800050fc:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005100:	4a01                	li	s4,0
    80005102:	a8d5                	j	800051f6 <exec+0x324>
  sp = sz;
    80005104:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80005106:	4481                	li	s1,0
  ustack[argc] = 0;
    80005108:	00349793          	slli	a5,s1,0x3
    8000510c:	f9040713          	addi	a4,s0,-112
    80005110:	97ba                	add	a5,a5,a4
    80005112:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ed8>
  sp -= (argc+1) * sizeof(uint64);
    80005116:	00148693          	addi	a3,s1,1
    8000511a:	068e                	slli	a3,a3,0x3
    8000511c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005120:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005124:	01897663          	bgeu	s2,s8,80005130 <exec+0x25e>
  sz = sz1;
    80005128:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    8000512c:	4a01                	li	s4,0
    8000512e:	a0e1                	j	800051f6 <exec+0x324>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005130:	e8840613          	addi	a2,s0,-376
    80005134:	85ca                	mv	a1,s2
    80005136:	855a                	mv	a0,s6
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	58e080e7          	jalr	1422(ra) # 800016c6 <copyout>
    80005140:	0e054763          	bltz	a0,8000522e <exec+0x35c>
  p->trapframe->a1 = sp;
    80005144:	068ab783          	ld	a5,104(s5)
    80005148:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000514c:	de843783          	ld	a5,-536(s0)
    80005150:	0007c703          	lbu	a4,0(a5)
    80005154:	cf11                	beqz	a4,80005170 <exec+0x29e>
    80005156:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005158:	02f00693          	li	a3,47
    8000515c:	a039                	j	8000516a <exec+0x298>
      last = s+1;
    8000515e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005162:	0785                	addi	a5,a5,1
    80005164:	fff7c703          	lbu	a4,-1(a5)
    80005168:	c701                	beqz	a4,80005170 <exec+0x29e>
    if(*s == '/')
    8000516a:	fed71ce3          	bne	a4,a3,80005162 <exec+0x290>
    8000516e:	bfc5                	j	8000515e <exec+0x28c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005170:	4641                	li	a2,16
    80005172:	de843583          	ld	a1,-536(s0)
    80005176:	168a8513          	addi	a0,s5,360
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	cd2080e7          	jalr	-814(ra) # 80000e4c <safestrcpy>
  uvmunmap(p->kpagetable, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    80005182:	6605                	lui	a2,0x1
    80005184:	167d                	addi	a2,a2,-1
    80005186:	966a                	add	a2,a2,s10
    80005188:	4681                	li	a3,0
    8000518a:	8231                	srli	a2,a2,0xc
    8000518c:	4581                	li	a1,0
    8000518e:	060ab503          	ld	a0,96(s5)
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	172080e7          	jalr	370(ra) # 80001304 <uvmunmap>
  kvmcopymappings(pagetable, p->kpagetable, 0, sz);
    8000519a:	86de                	mv	a3,s7
    8000519c:	4601                	li	a2,0
    8000519e:	060ab583          	ld	a1,96(s5)
    800051a2:	855a                	mv	a0,s6
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	7ba080e7          	jalr	1978(ra) # 8000195e <kvmcopymappings>
  oldpagetable = p->pagetable;
    800051ac:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800051b0:	056abc23          	sd	s6,88(s5)
  p->sz = sz;
    800051b4:	057ab423          	sd	s7,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051b8:	068ab783          	ld	a5,104(s5)
    800051bc:	e6043703          	ld	a4,-416(s0)
    800051c0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051c2:	068ab783          	ld	a5,104(s5)
    800051c6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ca:	85ea                	mv	a1,s10
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	ac6080e7          	jalr	-1338(ra) # 80001c92 <proc_freepagetable>
  if(p->pid == 1)
    800051d4:	038aa703          	lw	a4,56(s5)
    800051d8:	4785                	li	a5,1
    800051da:	00f70563          	beq	a4,a5,800051e4 <exec+0x312>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051de:	0004851b          	sext.w	a0,s1
    800051e2:	bb41                	j	80004f72 <exec+0xa0>
    vmprint(p->pagetable);
    800051e4:	058ab503          	ld	a0,88(s5)
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	6ea080e7          	jalr	1770(ra) # 800018d2 <vmprint>
    800051f0:	b7fd                	j	800051de <exec+0x30c>
    800051f2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051f6:	df843583          	ld	a1,-520(s0)
    800051fa:	855a                	mv	a0,s6
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	a96080e7          	jalr	-1386(ra) # 80001c92 <proc_freepagetable>
  if(ip){
    80005204:	d40a1de3          	bnez	s4,80004f5e <exec+0x8c>
  return -1;
    80005208:	557d                	li	a0,-1
    8000520a:	b3a5                	j	80004f72 <exec+0xa0>
    8000520c:	de943c23          	sd	s1,-520(s0)
    80005210:	b7dd                	j	800051f6 <exec+0x324>
    80005212:	de943c23          	sd	s1,-520(s0)
    80005216:	b7c5                	j	800051f6 <exec+0x324>
    80005218:	de943c23          	sd	s1,-520(s0)
    8000521c:	bfe9                	j	800051f6 <exec+0x324>
  sz = sz1;
    8000521e:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005222:	4a01                	li	s4,0
    80005224:	bfc9                	j	800051f6 <exec+0x324>
  sz = sz1;
    80005226:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    8000522a:	4a01                	li	s4,0
    8000522c:	b7e9                	j	800051f6 <exec+0x324>
  sz = sz1;
    8000522e:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80005232:	4a01                	li	s4,0
    80005234:	b7c9                	j	800051f6 <exec+0x324>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005236:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000523a:	e0843783          	ld	a5,-504(s0)
    8000523e:	0017869b          	addiw	a3,a5,1
    80005242:	e0d43423          	sd	a3,-504(s0)
    80005246:	e0043783          	ld	a5,-512(s0)
    8000524a:	0387879b          	addiw	a5,a5,56
    8000524e:	e8045703          	lhu	a4,-384(s0)
    80005252:	dee6d2e3          	bge	a3,a4,80005036 <exec+0x164>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005256:	2781                	sext.w	a5,a5
    80005258:	e0f43023          	sd	a5,-512(s0)
    8000525c:	03800713          	li	a4,56
    80005260:	86be                	mv	a3,a5
    80005262:	e1040613          	addi	a2,s0,-496
    80005266:	4581                	li	a1,0
    80005268:	8552                	mv	a0,s4
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	a08080e7          	jalr	-1528(ra) # 80003c72 <readi>
    80005272:	03800793          	li	a5,56
    80005276:	f6f51ee3          	bne	a0,a5,800051f2 <exec+0x320>
    if(ph.type != ELF_PROG_LOAD)
    8000527a:	e1042783          	lw	a5,-496(s0)
    8000527e:	4705                	li	a4,1
    80005280:	fae79de3          	bne	a5,a4,8000523a <exec+0x368>
    if(ph.memsz < ph.filesz)
    80005284:	e3843603          	ld	a2,-456(s0)
    80005288:	e3043783          	ld	a5,-464(s0)
    8000528c:	f8f660e3          	bltu	a2,a5,8000520c <exec+0x33a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005290:	e2043783          	ld	a5,-480(s0)
    80005294:	963e                	add	a2,a2,a5
    80005296:	f6f66ee3          	bltu	a2,a5,80005212 <exec+0x340>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000529a:	85a6                	mv	a1,s1
    8000529c:	855a                	mv	a0,s6
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	1f4080e7          	jalr	500(ra) # 80001492 <uvmalloc>
    800052a6:	dea43c23          	sd	a0,-520(s0)
    800052aa:	fff50793          	addi	a5,a0,-1
    800052ae:	de043703          	ld	a4,-544(s0)
    800052b2:	f6f763e3          	bltu	a4,a5,80005218 <exec+0x346>
    if(ph.vaddr % PGSIZE != 0)
    800052b6:	e2043c03          	ld	s8,-480(s0)
    800052ba:	dd843783          	ld	a5,-552(s0)
    800052be:	00fc77b3          	and	a5,s8,a5
    800052c2:	fb95                	bnez	a5,800051f6 <exec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052c4:	e1842c83          	lw	s9,-488(s0)
    800052c8:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052cc:	f60b85e3          	beqz	s7,80005236 <exec+0x364>
    800052d0:	89de                	mv	s3,s7
    800052d2:	4481                	li	s1,0
    800052d4:	7d7d                	lui	s10,0xfffff
    800052d6:	bb3d                	j	80005014 <exec+0x142>

00000000800052d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052d8:	7179                	addi	sp,sp,-48
    800052da:	f406                	sd	ra,40(sp)
    800052dc:	f022                	sd	s0,32(sp)
    800052de:	ec26                	sd	s1,24(sp)
    800052e0:	e84a                	sd	s2,16(sp)
    800052e2:	1800                	addi	s0,sp,48
    800052e4:	892e                	mv	s2,a1
    800052e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052e8:	fdc40593          	addi	a1,s0,-36
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	b36080e7          	jalr	-1226(ra) # 80002e22 <argint>
    800052f4:	04054063          	bltz	a0,80005334 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052f8:	fdc42703          	lw	a4,-36(s0)
    800052fc:	47bd                	li	a5,15
    800052fe:	02e7ed63          	bltu	a5,a4,80005338 <argfd+0x60>
    80005302:	ffffd097          	auipc	ra,0xffffd
    80005306:	830080e7          	jalr	-2000(ra) # 80001b32 <myproc>
    8000530a:	fdc42703          	lw	a4,-36(s0)
    8000530e:	01c70793          	addi	a5,a4,28 # c00001c <_entry-0x73ffffe4>
    80005312:	078e                	slli	a5,a5,0x3
    80005314:	953e                	add	a0,a0,a5
    80005316:	611c                	ld	a5,0(a0)
    80005318:	c395                	beqz	a5,8000533c <argfd+0x64>
    return -1;
  if(pfd)
    8000531a:	00090463          	beqz	s2,80005322 <argfd+0x4a>
    *pfd = fd;
    8000531e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005322:	4501                	li	a0,0
  if(pf)
    80005324:	c091                	beqz	s1,80005328 <argfd+0x50>
    *pf = f;
    80005326:	e09c                	sd	a5,0(s1)
}
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	64e2                	ld	s1,24(sp)
    8000532e:	6942                	ld	s2,16(sp)
    80005330:	6145                	addi	sp,sp,48
    80005332:	8082                	ret
    return -1;
    80005334:	557d                	li	a0,-1
    80005336:	bfcd                	j	80005328 <argfd+0x50>
    return -1;
    80005338:	557d                	li	a0,-1
    8000533a:	b7fd                	j	80005328 <argfd+0x50>
    8000533c:	557d                	li	a0,-1
    8000533e:	b7ed                	j	80005328 <argfd+0x50>

0000000080005340 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005340:	1101                	addi	sp,sp,-32
    80005342:	ec06                	sd	ra,24(sp)
    80005344:	e822                	sd	s0,16(sp)
    80005346:	e426                	sd	s1,8(sp)
    80005348:	1000                	addi	s0,sp,32
    8000534a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	7e6080e7          	jalr	2022(ra) # 80001b32 <myproc>
    80005354:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005356:	0e050793          	addi	a5,a0,224
    8000535a:	4501                	li	a0,0
    8000535c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000535e:	6398                	ld	a4,0(a5)
    80005360:	cb19                	beqz	a4,80005376 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005362:	2505                	addiw	a0,a0,1
    80005364:	07a1                	addi	a5,a5,8
    80005366:	fed51ce3          	bne	a0,a3,8000535e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000536a:	557d                	li	a0,-1
}
    8000536c:	60e2                	ld	ra,24(sp)
    8000536e:	6442                	ld	s0,16(sp)
    80005370:	64a2                	ld	s1,8(sp)
    80005372:	6105                	addi	sp,sp,32
    80005374:	8082                	ret
      p->ofile[fd] = f;
    80005376:	01c50793          	addi	a5,a0,28
    8000537a:	078e                	slli	a5,a5,0x3
    8000537c:	963e                	add	a2,a2,a5
    8000537e:	e204                	sd	s1,0(a2)
      return fd;
    80005380:	b7f5                	j	8000536c <fdalloc+0x2c>

0000000080005382 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005382:	715d                	addi	sp,sp,-80
    80005384:	e486                	sd	ra,72(sp)
    80005386:	e0a2                	sd	s0,64(sp)
    80005388:	fc26                	sd	s1,56(sp)
    8000538a:	f84a                	sd	s2,48(sp)
    8000538c:	f44e                	sd	s3,40(sp)
    8000538e:	f052                	sd	s4,32(sp)
    80005390:	ec56                	sd	s5,24(sp)
    80005392:	0880                	addi	s0,sp,80
    80005394:	89ae                	mv	s3,a1
    80005396:	8ab2                	mv	s5,a2
    80005398:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000539a:	fb040593          	addi	a1,s0,-80
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	dee080e7          	jalr	-530(ra) # 8000418c <nameiparent>
    800053a6:	892a                	mv	s2,a0
    800053a8:	12050e63          	beqz	a0,800054e4 <create+0x162>
    return 0;

  ilock(dp);
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	612080e7          	jalr	1554(ra) # 800039be <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053b4:	4601                	li	a2,0
    800053b6:	fb040593          	addi	a1,s0,-80
    800053ba:	854a                	mv	a0,s2
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	ae0080e7          	jalr	-1312(ra) # 80003e9c <dirlookup>
    800053c4:	84aa                	mv	s1,a0
    800053c6:	c921                	beqz	a0,80005416 <create+0x94>
    iunlockput(dp);
    800053c8:	854a                	mv	a0,s2
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	856080e7          	jalr	-1962(ra) # 80003c20 <iunlockput>
    ilock(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	5ea080e7          	jalr	1514(ra) # 800039be <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053dc:	2981                	sext.w	s3,s3
    800053de:	4789                	li	a5,2
    800053e0:	02f99463          	bne	s3,a5,80005408 <create+0x86>
    800053e4:	0444d783          	lhu	a5,68(s1)
    800053e8:	37f9                	addiw	a5,a5,-2
    800053ea:	17c2                	slli	a5,a5,0x30
    800053ec:	93c1                	srli	a5,a5,0x30
    800053ee:	4705                	li	a4,1
    800053f0:	00f76c63          	bltu	a4,a5,80005408 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053f4:	8526                	mv	a0,s1
    800053f6:	60a6                	ld	ra,72(sp)
    800053f8:	6406                	ld	s0,64(sp)
    800053fa:	74e2                	ld	s1,56(sp)
    800053fc:	7942                	ld	s2,48(sp)
    800053fe:	79a2                	ld	s3,40(sp)
    80005400:	7a02                	ld	s4,32(sp)
    80005402:	6ae2                	ld	s5,24(sp)
    80005404:	6161                	addi	sp,sp,80
    80005406:	8082                	ret
    iunlockput(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	816080e7          	jalr	-2026(ra) # 80003c20 <iunlockput>
    return 0;
    80005412:	4481                	li	s1,0
    80005414:	b7c5                	j	800053f4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005416:	85ce                	mv	a1,s3
    80005418:	00092503          	lw	a0,0(s2)
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	40a080e7          	jalr	1034(ra) # 80003826 <ialloc>
    80005424:	84aa                	mv	s1,a0
    80005426:	c521                	beqz	a0,8000546e <create+0xec>
  ilock(ip);
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	596080e7          	jalr	1430(ra) # 800039be <ilock>
  ip->major = major;
    80005430:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005434:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005438:	4a05                	li	s4,1
    8000543a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000543e:	8526                	mv	a0,s1
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	4b4080e7          	jalr	1204(ra) # 800038f4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005448:	2981                	sext.w	s3,s3
    8000544a:	03498a63          	beq	s3,s4,8000547e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000544e:	40d0                	lw	a2,4(s1)
    80005450:	fb040593          	addi	a1,s0,-80
    80005454:	854a                	mv	a0,s2
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	c56080e7          	jalr	-938(ra) # 800040ac <dirlink>
    8000545e:	06054b63          	bltz	a0,800054d4 <create+0x152>
  iunlockput(dp);
    80005462:	854a                	mv	a0,s2
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	7bc080e7          	jalr	1980(ra) # 80003c20 <iunlockput>
  return ip;
    8000546c:	b761                	j	800053f4 <create+0x72>
    panic("create: ialloc");
    8000546e:	00003517          	auipc	a0,0x3
    80005472:	2ba50513          	addi	a0,a0,698 # 80008728 <syscalls+0x2b0>
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	0cc080e7          	jalr	204(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000547e:	04a95783          	lhu	a5,74(s2)
    80005482:	2785                	addiw	a5,a5,1
    80005484:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005488:	854a                	mv	a0,s2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	46a080e7          	jalr	1130(ra) # 800038f4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005492:	40d0                	lw	a2,4(s1)
    80005494:	00003597          	auipc	a1,0x3
    80005498:	2a458593          	addi	a1,a1,676 # 80008738 <syscalls+0x2c0>
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	c0e080e7          	jalr	-1010(ra) # 800040ac <dirlink>
    800054a6:	00054f63          	bltz	a0,800054c4 <create+0x142>
    800054aa:	00492603          	lw	a2,4(s2)
    800054ae:	00003597          	auipc	a1,0x3
    800054b2:	ca258593          	addi	a1,a1,-862 # 80008150 <digits+0x120>
    800054b6:	8526                	mv	a0,s1
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	bf4080e7          	jalr	-1036(ra) # 800040ac <dirlink>
    800054c0:	f80557e3          	bgez	a0,8000544e <create+0xcc>
      panic("create dots");
    800054c4:	00003517          	auipc	a0,0x3
    800054c8:	27c50513          	addi	a0,a0,636 # 80008740 <syscalls+0x2c8>
    800054cc:	ffffb097          	auipc	ra,0xffffb
    800054d0:	076080e7          	jalr	118(ra) # 80000542 <panic>
    panic("create: dirlink");
    800054d4:	00003517          	auipc	a0,0x3
    800054d8:	27c50513          	addi	a0,a0,636 # 80008750 <syscalls+0x2d8>
    800054dc:	ffffb097          	auipc	ra,0xffffb
    800054e0:	066080e7          	jalr	102(ra) # 80000542 <panic>
    return 0;
    800054e4:	84aa                	mv	s1,a0
    800054e6:	b739                	j	800053f4 <create+0x72>

00000000800054e8 <sys_dup>:
{
    800054e8:	7179                	addi	sp,sp,-48
    800054ea:	f406                	sd	ra,40(sp)
    800054ec:	f022                	sd	s0,32(sp)
    800054ee:	ec26                	sd	s1,24(sp)
    800054f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054f2:	fd840613          	addi	a2,s0,-40
    800054f6:	4581                	li	a1,0
    800054f8:	4501                	li	a0,0
    800054fa:	00000097          	auipc	ra,0x0
    800054fe:	dde080e7          	jalr	-546(ra) # 800052d8 <argfd>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005504:	02054363          	bltz	a0,8000552a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005508:	fd843503          	ld	a0,-40(s0)
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	e34080e7          	jalr	-460(ra) # 80005340 <fdalloc>
    80005514:	84aa                	mv	s1,a0
    return -1;
    80005516:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005518:	00054963          	bltz	a0,8000552a <sys_dup+0x42>
  filedup(f);
    8000551c:	fd843503          	ld	a0,-40(s0)
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	2da080e7          	jalr	730(ra) # 800047fa <filedup>
  return fd;
    80005528:	87a6                	mv	a5,s1
}
    8000552a:	853e                	mv	a0,a5
    8000552c:	70a2                	ld	ra,40(sp)
    8000552e:	7402                	ld	s0,32(sp)
    80005530:	64e2                	ld	s1,24(sp)
    80005532:	6145                	addi	sp,sp,48
    80005534:	8082                	ret

0000000080005536 <sys_read>:
{
    80005536:	7179                	addi	sp,sp,-48
    80005538:	f406                	sd	ra,40(sp)
    8000553a:	f022                	sd	s0,32(sp)
    8000553c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553e:	fe840613          	addi	a2,s0,-24
    80005542:	4581                	li	a1,0
    80005544:	4501                	li	a0,0
    80005546:	00000097          	auipc	ra,0x0
    8000554a:	d92080e7          	jalr	-622(ra) # 800052d8 <argfd>
    return -1;
    8000554e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005550:	04054163          	bltz	a0,80005592 <sys_read+0x5c>
    80005554:	fe440593          	addi	a1,s0,-28
    80005558:	4509                	li	a0,2
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	8c8080e7          	jalr	-1848(ra) # 80002e22 <argint>
    return -1;
    80005562:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005564:	02054763          	bltz	a0,80005592 <sys_read+0x5c>
    80005568:	fd840593          	addi	a1,s0,-40
    8000556c:	4505                	li	a0,1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	8d6080e7          	jalr	-1834(ra) # 80002e44 <argaddr>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005578:	00054d63          	bltz	a0,80005592 <sys_read+0x5c>
  return fileread(f, p, n);
    8000557c:	fe442603          	lw	a2,-28(s0)
    80005580:	fd843583          	ld	a1,-40(s0)
    80005584:	fe843503          	ld	a0,-24(s0)
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	3fe080e7          	jalr	1022(ra) # 80004986 <fileread>
    80005590:	87aa                	mv	a5,a0
}
    80005592:	853e                	mv	a0,a5
    80005594:	70a2                	ld	ra,40(sp)
    80005596:	7402                	ld	s0,32(sp)
    80005598:	6145                	addi	sp,sp,48
    8000559a:	8082                	ret

000000008000559c <sys_write>:
{
    8000559c:	7179                	addi	sp,sp,-48
    8000559e:	f406                	sd	ra,40(sp)
    800055a0:	f022                	sd	s0,32(sp)
    800055a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a4:	fe840613          	addi	a2,s0,-24
    800055a8:	4581                	li	a1,0
    800055aa:	4501                	li	a0,0
    800055ac:	00000097          	auipc	ra,0x0
    800055b0:	d2c080e7          	jalr	-724(ra) # 800052d8 <argfd>
    return -1;
    800055b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b6:	04054163          	bltz	a0,800055f8 <sys_write+0x5c>
    800055ba:	fe440593          	addi	a1,s0,-28
    800055be:	4509                	li	a0,2
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	862080e7          	jalr	-1950(ra) # 80002e22 <argint>
    return -1;
    800055c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ca:	02054763          	bltz	a0,800055f8 <sys_write+0x5c>
    800055ce:	fd840593          	addi	a1,s0,-40
    800055d2:	4505                	li	a0,1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	870080e7          	jalr	-1936(ra) # 80002e44 <argaddr>
    return -1;
    800055dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055de:	00054d63          	bltz	a0,800055f8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055e2:	fe442603          	lw	a2,-28(s0)
    800055e6:	fd843583          	ld	a1,-40(s0)
    800055ea:	fe843503          	ld	a0,-24(s0)
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	45a080e7          	jalr	1114(ra) # 80004a48 <filewrite>
    800055f6:	87aa                	mv	a5,a0
}
    800055f8:	853e                	mv	a0,a5
    800055fa:	70a2                	ld	ra,40(sp)
    800055fc:	7402                	ld	s0,32(sp)
    800055fe:	6145                	addi	sp,sp,48
    80005600:	8082                	ret

0000000080005602 <sys_close>:
{
    80005602:	1101                	addi	sp,sp,-32
    80005604:	ec06                	sd	ra,24(sp)
    80005606:	e822                	sd	s0,16(sp)
    80005608:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000560a:	fe040613          	addi	a2,s0,-32
    8000560e:	fec40593          	addi	a1,s0,-20
    80005612:	4501                	li	a0,0
    80005614:	00000097          	auipc	ra,0x0
    80005618:	cc4080e7          	jalr	-828(ra) # 800052d8 <argfd>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000561e:	02054463          	bltz	a0,80005646 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005622:	ffffc097          	auipc	ra,0xffffc
    80005626:	510080e7          	jalr	1296(ra) # 80001b32 <myproc>
    8000562a:	fec42783          	lw	a5,-20(s0)
    8000562e:	07f1                	addi	a5,a5,28
    80005630:	078e                	slli	a5,a5,0x3
    80005632:	97aa                	add	a5,a5,a0
    80005634:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005638:	fe043503          	ld	a0,-32(s0)
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	210080e7          	jalr	528(ra) # 8000484c <fileclose>
  return 0;
    80005644:	4781                	li	a5,0
}
    80005646:	853e                	mv	a0,a5
    80005648:	60e2                	ld	ra,24(sp)
    8000564a:	6442                	ld	s0,16(sp)
    8000564c:	6105                	addi	sp,sp,32
    8000564e:	8082                	ret

0000000080005650 <sys_fstat>:
{
    80005650:	1101                	addi	sp,sp,-32
    80005652:	ec06                	sd	ra,24(sp)
    80005654:	e822                	sd	s0,16(sp)
    80005656:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005658:	fe840613          	addi	a2,s0,-24
    8000565c:	4581                	li	a1,0
    8000565e:	4501                	li	a0,0
    80005660:	00000097          	auipc	ra,0x0
    80005664:	c78080e7          	jalr	-904(ra) # 800052d8 <argfd>
    return -1;
    80005668:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000566a:	02054563          	bltz	a0,80005694 <sys_fstat+0x44>
    8000566e:	fe040593          	addi	a1,s0,-32
    80005672:	4505                	li	a0,1
    80005674:	ffffd097          	auipc	ra,0xffffd
    80005678:	7d0080e7          	jalr	2000(ra) # 80002e44 <argaddr>
    return -1;
    8000567c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000567e:	00054b63          	bltz	a0,80005694 <sys_fstat+0x44>
  return filestat(f, st);
    80005682:	fe043583          	ld	a1,-32(s0)
    80005686:	fe843503          	ld	a0,-24(s0)
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	28a080e7          	jalr	650(ra) # 80004914 <filestat>
    80005692:	87aa                	mv	a5,a0
}
    80005694:	853e                	mv	a0,a5
    80005696:	60e2                	ld	ra,24(sp)
    80005698:	6442                	ld	s0,16(sp)
    8000569a:	6105                	addi	sp,sp,32
    8000569c:	8082                	ret

000000008000569e <sys_link>:
{
    8000569e:	7169                	addi	sp,sp,-304
    800056a0:	f606                	sd	ra,296(sp)
    800056a2:	f222                	sd	s0,288(sp)
    800056a4:	ee26                	sd	s1,280(sp)
    800056a6:	ea4a                	sd	s2,272(sp)
    800056a8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056aa:	08000613          	li	a2,128
    800056ae:	ed040593          	addi	a1,s0,-304
    800056b2:	4501                	li	a0,0
    800056b4:	ffffd097          	auipc	ra,0xffffd
    800056b8:	7b2080e7          	jalr	1970(ra) # 80002e66 <argstr>
    return -1;
    800056bc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056be:	10054e63          	bltz	a0,800057da <sys_link+0x13c>
    800056c2:	08000613          	li	a2,128
    800056c6:	f5040593          	addi	a1,s0,-176
    800056ca:	4505                	li	a0,1
    800056cc:	ffffd097          	auipc	ra,0xffffd
    800056d0:	79a080e7          	jalr	1946(ra) # 80002e66 <argstr>
    return -1;
    800056d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d6:	10054263          	bltz	a0,800057da <sys_link+0x13c>
  begin_op();
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	ca0080e7          	jalr	-864(ra) # 8000437a <begin_op>
  if((ip = namei(old)) == 0){
    800056e2:	ed040513          	addi	a0,s0,-304
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	a88080e7          	jalr	-1400(ra) # 8000416e <namei>
    800056ee:	84aa                	mv	s1,a0
    800056f0:	c551                	beqz	a0,8000577c <sys_link+0xde>
  ilock(ip);
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	2cc080e7          	jalr	716(ra) # 800039be <ilock>
  if(ip->type == T_DIR){
    800056fa:	04449703          	lh	a4,68(s1)
    800056fe:	4785                	li	a5,1
    80005700:	08f70463          	beq	a4,a5,80005788 <sys_link+0xea>
  ip->nlink++;
    80005704:	04a4d783          	lhu	a5,74(s1)
    80005708:	2785                	addiw	a5,a5,1
    8000570a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	1e4080e7          	jalr	484(ra) # 800038f4 <iupdate>
  iunlock(ip);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	366080e7          	jalr	870(ra) # 80003a80 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005722:	fd040593          	addi	a1,s0,-48
    80005726:	f5040513          	addi	a0,s0,-176
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	a62080e7          	jalr	-1438(ra) # 8000418c <nameiparent>
    80005732:	892a                	mv	s2,a0
    80005734:	c935                	beqz	a0,800057a8 <sys_link+0x10a>
  ilock(dp);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	288080e7          	jalr	648(ra) # 800039be <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000573e:	00092703          	lw	a4,0(s2)
    80005742:	409c                	lw	a5,0(s1)
    80005744:	04f71d63          	bne	a4,a5,8000579e <sys_link+0x100>
    80005748:	40d0                	lw	a2,4(s1)
    8000574a:	fd040593          	addi	a1,s0,-48
    8000574e:	854a                	mv	a0,s2
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	95c080e7          	jalr	-1700(ra) # 800040ac <dirlink>
    80005758:	04054363          	bltz	a0,8000579e <sys_link+0x100>
  iunlockput(dp);
    8000575c:	854a                	mv	a0,s2
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	4c2080e7          	jalr	1218(ra) # 80003c20 <iunlockput>
  iput(ip);
    80005766:	8526                	mv	a0,s1
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	410080e7          	jalr	1040(ra) # 80003b78 <iput>
  end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	c8a080e7          	jalr	-886(ra) # 800043fa <end_op>
  return 0;
    80005778:	4781                	li	a5,0
    8000577a:	a085                	j	800057da <sys_link+0x13c>
    end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	c7e080e7          	jalr	-898(ra) # 800043fa <end_op>
    return -1;
    80005784:	57fd                	li	a5,-1
    80005786:	a891                	j	800057da <sys_link+0x13c>
    iunlockput(ip);
    80005788:	8526                	mv	a0,s1
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	496080e7          	jalr	1174(ra) # 80003c20 <iunlockput>
    end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	c68080e7          	jalr	-920(ra) # 800043fa <end_op>
    return -1;
    8000579a:	57fd                	li	a5,-1
    8000579c:	a83d                	j	800057da <sys_link+0x13c>
    iunlockput(dp);
    8000579e:	854a                	mv	a0,s2
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	480080e7          	jalr	1152(ra) # 80003c20 <iunlockput>
  ilock(ip);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	214080e7          	jalr	532(ra) # 800039be <ilock>
  ip->nlink--;
    800057b2:	04a4d783          	lhu	a5,74(s1)
    800057b6:	37fd                	addiw	a5,a5,-1
    800057b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	136080e7          	jalr	310(ra) # 800038f4 <iupdate>
  iunlockput(ip);
    800057c6:	8526                	mv	a0,s1
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	458080e7          	jalr	1112(ra) # 80003c20 <iunlockput>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	c2a080e7          	jalr	-982(ra) # 800043fa <end_op>
  return -1;
    800057d8:	57fd                	li	a5,-1
}
    800057da:	853e                	mv	a0,a5
    800057dc:	70b2                	ld	ra,296(sp)
    800057de:	7412                	ld	s0,288(sp)
    800057e0:	64f2                	ld	s1,280(sp)
    800057e2:	6952                	ld	s2,272(sp)
    800057e4:	6155                	addi	sp,sp,304
    800057e6:	8082                	ret

00000000800057e8 <sys_unlink>:
{
    800057e8:	7151                	addi	sp,sp,-240
    800057ea:	f586                	sd	ra,232(sp)
    800057ec:	f1a2                	sd	s0,224(sp)
    800057ee:	eda6                	sd	s1,216(sp)
    800057f0:	e9ca                	sd	s2,208(sp)
    800057f2:	e5ce                	sd	s3,200(sp)
    800057f4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057f6:	08000613          	li	a2,128
    800057fa:	f3040593          	addi	a1,s0,-208
    800057fe:	4501                	li	a0,0
    80005800:	ffffd097          	auipc	ra,0xffffd
    80005804:	666080e7          	jalr	1638(ra) # 80002e66 <argstr>
    80005808:	18054163          	bltz	a0,8000598a <sys_unlink+0x1a2>
  begin_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	b6e080e7          	jalr	-1170(ra) # 8000437a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005814:	fb040593          	addi	a1,s0,-80
    80005818:	f3040513          	addi	a0,s0,-208
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	970080e7          	jalr	-1680(ra) # 8000418c <nameiparent>
    80005824:	84aa                	mv	s1,a0
    80005826:	c979                	beqz	a0,800058fc <sys_unlink+0x114>
  ilock(dp);
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	196080e7          	jalr	406(ra) # 800039be <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005830:	00003597          	auipc	a1,0x3
    80005834:	f0858593          	addi	a1,a1,-248 # 80008738 <syscalls+0x2c0>
    80005838:	fb040513          	addi	a0,s0,-80
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	646080e7          	jalr	1606(ra) # 80003e82 <namecmp>
    80005844:	14050a63          	beqz	a0,80005998 <sys_unlink+0x1b0>
    80005848:	00003597          	auipc	a1,0x3
    8000584c:	90858593          	addi	a1,a1,-1784 # 80008150 <digits+0x120>
    80005850:	fb040513          	addi	a0,s0,-80
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	62e080e7          	jalr	1582(ra) # 80003e82 <namecmp>
    8000585c:	12050e63          	beqz	a0,80005998 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005860:	f2c40613          	addi	a2,s0,-212
    80005864:	fb040593          	addi	a1,s0,-80
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	632080e7          	jalr	1586(ra) # 80003e9c <dirlookup>
    80005872:	892a                	mv	s2,a0
    80005874:	12050263          	beqz	a0,80005998 <sys_unlink+0x1b0>
  ilock(ip);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	146080e7          	jalr	326(ra) # 800039be <ilock>
  if(ip->nlink < 1)
    80005880:	04a91783          	lh	a5,74(s2)
    80005884:	08f05263          	blez	a5,80005908 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005888:	04491703          	lh	a4,68(s2)
    8000588c:	4785                	li	a5,1
    8000588e:	08f70563          	beq	a4,a5,80005918 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005892:	4641                	li	a2,16
    80005894:	4581                	li	a1,0
    80005896:	fc040513          	addi	a0,s0,-64
    8000589a:	ffffb097          	auipc	ra,0xffffb
    8000589e:	460080e7          	jalr	1120(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a2:	4741                	li	a4,16
    800058a4:	f2c42683          	lw	a3,-212(s0)
    800058a8:	fc040613          	addi	a2,s0,-64
    800058ac:	4581                	li	a1,0
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	4b8080e7          	jalr	1208(ra) # 80003d68 <writei>
    800058b8:	47c1                	li	a5,16
    800058ba:	0af51563          	bne	a0,a5,80005964 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058be:	04491703          	lh	a4,68(s2)
    800058c2:	4785                	li	a5,1
    800058c4:	0af70863          	beq	a4,a5,80005974 <sys_unlink+0x18c>
  iunlockput(dp);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	356080e7          	jalr	854(ra) # 80003c20 <iunlockput>
  ip->nlink--;
    800058d2:	04a95783          	lhu	a5,74(s2)
    800058d6:	37fd                	addiw	a5,a5,-1
    800058d8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	016080e7          	jalr	22(ra) # 800038f4 <iupdate>
  iunlockput(ip);
    800058e6:	854a                	mv	a0,s2
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	338080e7          	jalr	824(ra) # 80003c20 <iunlockput>
  end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	b0a080e7          	jalr	-1270(ra) # 800043fa <end_op>
  return 0;
    800058f8:	4501                	li	a0,0
    800058fa:	a84d                	j	800059ac <sys_unlink+0x1c4>
    end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	afe080e7          	jalr	-1282(ra) # 800043fa <end_op>
    return -1;
    80005904:	557d                	li	a0,-1
    80005906:	a05d                	j	800059ac <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005908:	00003517          	auipc	a0,0x3
    8000590c:	e5850513          	addi	a0,a0,-424 # 80008760 <syscalls+0x2e8>
    80005910:	ffffb097          	auipc	ra,0xffffb
    80005914:	c32080e7          	jalr	-974(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005918:	04c92703          	lw	a4,76(s2)
    8000591c:	02000793          	li	a5,32
    80005920:	f6e7f9e3          	bgeu	a5,a4,80005892 <sys_unlink+0xaa>
    80005924:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005928:	4741                	li	a4,16
    8000592a:	86ce                	mv	a3,s3
    8000592c:	f1840613          	addi	a2,s0,-232
    80005930:	4581                	li	a1,0
    80005932:	854a                	mv	a0,s2
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	33e080e7          	jalr	830(ra) # 80003c72 <readi>
    8000593c:	47c1                	li	a5,16
    8000593e:	00f51b63          	bne	a0,a5,80005954 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005942:	f1845783          	lhu	a5,-232(s0)
    80005946:	e7a1                	bnez	a5,8000598e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005948:	29c1                	addiw	s3,s3,16
    8000594a:	04c92783          	lw	a5,76(s2)
    8000594e:	fcf9ede3          	bltu	s3,a5,80005928 <sys_unlink+0x140>
    80005952:	b781                	j	80005892 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005954:	00003517          	auipc	a0,0x3
    80005958:	e2450513          	addi	a0,a0,-476 # 80008778 <syscalls+0x300>
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	be6080e7          	jalr	-1050(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005964:	00003517          	auipc	a0,0x3
    80005968:	e2c50513          	addi	a0,a0,-468 # 80008790 <syscalls+0x318>
    8000596c:	ffffb097          	auipc	ra,0xffffb
    80005970:	bd6080e7          	jalr	-1066(ra) # 80000542 <panic>
    dp->nlink--;
    80005974:	04a4d783          	lhu	a5,74(s1)
    80005978:	37fd                	addiw	a5,a5,-1
    8000597a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000597e:	8526                	mv	a0,s1
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	f74080e7          	jalr	-140(ra) # 800038f4 <iupdate>
    80005988:	b781                	j	800058c8 <sys_unlink+0xe0>
    return -1;
    8000598a:	557d                	li	a0,-1
    8000598c:	a005                	j	800059ac <sys_unlink+0x1c4>
    iunlockput(ip);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	290080e7          	jalr	656(ra) # 80003c20 <iunlockput>
  iunlockput(dp);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	286080e7          	jalr	646(ra) # 80003c20 <iunlockput>
  end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	a58080e7          	jalr	-1448(ra) # 800043fa <end_op>
  return -1;
    800059aa:	557d                	li	a0,-1
}
    800059ac:	70ae                	ld	ra,232(sp)
    800059ae:	740e                	ld	s0,224(sp)
    800059b0:	64ee                	ld	s1,216(sp)
    800059b2:	694e                	ld	s2,208(sp)
    800059b4:	69ae                	ld	s3,200(sp)
    800059b6:	616d                	addi	sp,sp,240
    800059b8:	8082                	ret

00000000800059ba <sys_open>:

uint64
sys_open(void)
{
    800059ba:	7131                	addi	sp,sp,-192
    800059bc:	fd06                	sd	ra,184(sp)
    800059be:	f922                	sd	s0,176(sp)
    800059c0:	f526                	sd	s1,168(sp)
    800059c2:	f14a                	sd	s2,160(sp)
    800059c4:	ed4e                	sd	s3,152(sp)
    800059c6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059c8:	08000613          	li	a2,128
    800059cc:	f5040593          	addi	a1,s0,-176
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	494080e7          	jalr	1172(ra) # 80002e66 <argstr>
    return -1;
    800059da:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059dc:	0c054163          	bltz	a0,80005a9e <sys_open+0xe4>
    800059e0:	f4c40593          	addi	a1,s0,-180
    800059e4:	4505                	li	a0,1
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	43c080e7          	jalr	1084(ra) # 80002e22 <argint>
    800059ee:	0a054863          	bltz	a0,80005a9e <sys_open+0xe4>

  begin_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	988080e7          	jalr	-1656(ra) # 8000437a <begin_op>

  if(omode & O_CREATE){
    800059fa:	f4c42783          	lw	a5,-180(s0)
    800059fe:	2007f793          	andi	a5,a5,512
    80005a02:	cbdd                	beqz	a5,80005ab8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a04:	4681                	li	a3,0
    80005a06:	4601                	li	a2,0
    80005a08:	4589                	li	a1,2
    80005a0a:	f5040513          	addi	a0,s0,-176
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	974080e7          	jalr	-1676(ra) # 80005382 <create>
    80005a16:	892a                	mv	s2,a0
    if(ip == 0){
    80005a18:	c959                	beqz	a0,80005aae <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a1a:	04491703          	lh	a4,68(s2)
    80005a1e:	478d                	li	a5,3
    80005a20:	00f71763          	bne	a4,a5,80005a2e <sys_open+0x74>
    80005a24:	04695703          	lhu	a4,70(s2)
    80005a28:	47a5                	li	a5,9
    80005a2a:	0ce7ec63          	bltu	a5,a4,80005b02 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	d62080e7          	jalr	-670(ra) # 80004790 <filealloc>
    80005a36:	89aa                	mv	s3,a0
    80005a38:	10050263          	beqz	a0,80005b3c <sys_open+0x182>
    80005a3c:	00000097          	auipc	ra,0x0
    80005a40:	904080e7          	jalr	-1788(ra) # 80005340 <fdalloc>
    80005a44:	84aa                	mv	s1,a0
    80005a46:	0e054663          	bltz	a0,80005b32 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a4a:	04491703          	lh	a4,68(s2)
    80005a4e:	478d                	li	a5,3
    80005a50:	0cf70463          	beq	a4,a5,80005b18 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a54:	4789                	li	a5,2
    80005a56:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a5a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a5e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a62:	f4c42783          	lw	a5,-180(s0)
    80005a66:	0017c713          	xori	a4,a5,1
    80005a6a:	8b05                	andi	a4,a4,1
    80005a6c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a70:	0037f713          	andi	a4,a5,3
    80005a74:	00e03733          	snez	a4,a4
    80005a78:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a7c:	4007f793          	andi	a5,a5,1024
    80005a80:	c791                	beqz	a5,80005a8c <sys_open+0xd2>
    80005a82:	04491703          	lh	a4,68(s2)
    80005a86:	4789                	li	a5,2
    80005a88:	08f70f63          	beq	a4,a5,80005b26 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	ff2080e7          	jalr	-14(ra) # 80003a80 <iunlock>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	964080e7          	jalr	-1692(ra) # 800043fa <end_op>

  return fd;
}
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	70ea                	ld	ra,184(sp)
    80005aa2:	744a                	ld	s0,176(sp)
    80005aa4:	74aa                	ld	s1,168(sp)
    80005aa6:	790a                	ld	s2,160(sp)
    80005aa8:	69ea                	ld	s3,152(sp)
    80005aaa:	6129                	addi	sp,sp,192
    80005aac:	8082                	ret
      end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	94c080e7          	jalr	-1716(ra) # 800043fa <end_op>
      return -1;
    80005ab6:	b7e5                	j	80005a9e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ab8:	f5040513          	addi	a0,s0,-176
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	6b2080e7          	jalr	1714(ra) # 8000416e <namei>
    80005ac4:	892a                	mv	s2,a0
    80005ac6:	c905                	beqz	a0,80005af6 <sys_open+0x13c>
    ilock(ip);
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	ef6080e7          	jalr	-266(ra) # 800039be <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ad0:	04491703          	lh	a4,68(s2)
    80005ad4:	4785                	li	a5,1
    80005ad6:	f4f712e3          	bne	a4,a5,80005a1a <sys_open+0x60>
    80005ada:	f4c42783          	lw	a5,-180(s0)
    80005ade:	dba1                	beqz	a5,80005a2e <sys_open+0x74>
      iunlockput(ip);
    80005ae0:	854a                	mv	a0,s2
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	13e080e7          	jalr	318(ra) # 80003c20 <iunlockput>
      end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	910080e7          	jalr	-1776(ra) # 800043fa <end_op>
      return -1;
    80005af2:	54fd                	li	s1,-1
    80005af4:	b76d                	j	80005a9e <sys_open+0xe4>
      end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	904080e7          	jalr	-1788(ra) # 800043fa <end_op>
      return -1;
    80005afe:	54fd                	li	s1,-1
    80005b00:	bf79                	j	80005a9e <sys_open+0xe4>
    iunlockput(ip);
    80005b02:	854a                	mv	a0,s2
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	11c080e7          	jalr	284(ra) # 80003c20 <iunlockput>
    end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	8ee080e7          	jalr	-1810(ra) # 800043fa <end_op>
    return -1;
    80005b14:	54fd                	li	s1,-1
    80005b16:	b761                	j	80005a9e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b18:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b1c:	04691783          	lh	a5,70(s2)
    80005b20:	02f99223          	sh	a5,36(s3)
    80005b24:	bf2d                	j	80005a5e <sys_open+0xa4>
    itrunc(ip);
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	fa4080e7          	jalr	-92(ra) # 80003acc <itrunc>
    80005b30:	bfb1                	j	80005a8c <sys_open+0xd2>
      fileclose(f);
    80005b32:	854e                	mv	a0,s3
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	d18080e7          	jalr	-744(ra) # 8000484c <fileclose>
    iunlockput(ip);
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	0e2080e7          	jalr	226(ra) # 80003c20 <iunlockput>
    end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	8b4080e7          	jalr	-1868(ra) # 800043fa <end_op>
    return -1;
    80005b4e:	54fd                	li	s1,-1
    80005b50:	b7b9                	j	80005a9e <sys_open+0xe4>

0000000080005b52 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b52:	7175                	addi	sp,sp,-144
    80005b54:	e506                	sd	ra,136(sp)
    80005b56:	e122                	sd	s0,128(sp)
    80005b58:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	820080e7          	jalr	-2016(ra) # 8000437a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b62:	08000613          	li	a2,128
    80005b66:	f7040593          	addi	a1,s0,-144
    80005b6a:	4501                	li	a0,0
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	2fa080e7          	jalr	762(ra) # 80002e66 <argstr>
    80005b74:	02054963          	bltz	a0,80005ba6 <sys_mkdir+0x54>
    80005b78:	4681                	li	a3,0
    80005b7a:	4601                	li	a2,0
    80005b7c:	4585                	li	a1,1
    80005b7e:	f7040513          	addi	a0,s0,-144
    80005b82:	00000097          	auipc	ra,0x0
    80005b86:	800080e7          	jalr	-2048(ra) # 80005382 <create>
    80005b8a:	cd11                	beqz	a0,80005ba6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	094080e7          	jalr	148(ra) # 80003c20 <iunlockput>
  end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	866080e7          	jalr	-1946(ra) # 800043fa <end_op>
  return 0;
    80005b9c:	4501                	li	a0,0
}
    80005b9e:	60aa                	ld	ra,136(sp)
    80005ba0:	640a                	ld	s0,128(sp)
    80005ba2:	6149                	addi	sp,sp,144
    80005ba4:	8082                	ret
    end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	854080e7          	jalr	-1964(ra) # 800043fa <end_op>
    return -1;
    80005bae:	557d                	li	a0,-1
    80005bb0:	b7fd                	j	80005b9e <sys_mkdir+0x4c>

0000000080005bb2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bb2:	7135                	addi	sp,sp,-160
    80005bb4:	ed06                	sd	ra,152(sp)
    80005bb6:	e922                	sd	s0,144(sp)
    80005bb8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	7c0080e7          	jalr	1984(ra) # 8000437a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bc2:	08000613          	li	a2,128
    80005bc6:	f7040593          	addi	a1,s0,-144
    80005bca:	4501                	li	a0,0
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	29a080e7          	jalr	666(ra) # 80002e66 <argstr>
    80005bd4:	04054a63          	bltz	a0,80005c28 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bd8:	f6c40593          	addi	a1,s0,-148
    80005bdc:	4505                	li	a0,1
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	244080e7          	jalr	580(ra) # 80002e22 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005be6:	04054163          	bltz	a0,80005c28 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bea:	f6840593          	addi	a1,s0,-152
    80005bee:	4509                	li	a0,2
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	232080e7          	jalr	562(ra) # 80002e22 <argint>
     argint(1, &major) < 0 ||
    80005bf8:	02054863          	bltz	a0,80005c28 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bfc:	f6841683          	lh	a3,-152(s0)
    80005c00:	f6c41603          	lh	a2,-148(s0)
    80005c04:	458d                	li	a1,3
    80005c06:	f7040513          	addi	a0,s0,-144
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	778080e7          	jalr	1912(ra) # 80005382 <create>
     argint(2, &minor) < 0 ||
    80005c12:	c919                	beqz	a0,80005c28 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	00c080e7          	jalr	12(ra) # 80003c20 <iunlockput>
  end_op();
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	7de080e7          	jalr	2014(ra) # 800043fa <end_op>
  return 0;
    80005c24:	4501                	li	a0,0
    80005c26:	a031                	j	80005c32 <sys_mknod+0x80>
    end_op();
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	7d2080e7          	jalr	2002(ra) # 800043fa <end_op>
    return -1;
    80005c30:	557d                	li	a0,-1
}
    80005c32:	60ea                	ld	ra,152(sp)
    80005c34:	644a                	ld	s0,144(sp)
    80005c36:	610d                	addi	sp,sp,160
    80005c38:	8082                	ret

0000000080005c3a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c3a:	7135                	addi	sp,sp,-160
    80005c3c:	ed06                	sd	ra,152(sp)
    80005c3e:	e922                	sd	s0,144(sp)
    80005c40:	e526                	sd	s1,136(sp)
    80005c42:	e14a                	sd	s2,128(sp)
    80005c44:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c46:	ffffc097          	auipc	ra,0xffffc
    80005c4a:	eec080e7          	jalr	-276(ra) # 80001b32 <myproc>
    80005c4e:	892a                	mv	s2,a0
  
  begin_op();
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	72a080e7          	jalr	1834(ra) # 8000437a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c58:	08000613          	li	a2,128
    80005c5c:	f6040593          	addi	a1,s0,-160
    80005c60:	4501                	li	a0,0
    80005c62:	ffffd097          	auipc	ra,0xffffd
    80005c66:	204080e7          	jalr	516(ra) # 80002e66 <argstr>
    80005c6a:	04054b63          	bltz	a0,80005cc0 <sys_chdir+0x86>
    80005c6e:	f6040513          	addi	a0,s0,-160
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	4fc080e7          	jalr	1276(ra) # 8000416e <namei>
    80005c7a:	84aa                	mv	s1,a0
    80005c7c:	c131                	beqz	a0,80005cc0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	d40080e7          	jalr	-704(ra) # 800039be <ilock>
  if(ip->type != T_DIR){
    80005c86:	04449703          	lh	a4,68(s1)
    80005c8a:	4785                	li	a5,1
    80005c8c:	04f71063          	bne	a4,a5,80005ccc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c90:	8526                	mv	a0,s1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	dee080e7          	jalr	-530(ra) # 80003a80 <iunlock>
  iput(p->cwd);
    80005c9a:	16093503          	ld	a0,352(s2)
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	eda080e7          	jalr	-294(ra) # 80003b78 <iput>
  end_op();
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	754080e7          	jalr	1876(ra) # 800043fa <end_op>
  p->cwd = ip;
    80005cae:	16993023          	sd	s1,352(s2)
  return 0;
    80005cb2:	4501                	li	a0,0
}
    80005cb4:	60ea                	ld	ra,152(sp)
    80005cb6:	644a                	ld	s0,144(sp)
    80005cb8:	64aa                	ld	s1,136(sp)
    80005cba:	690a                	ld	s2,128(sp)
    80005cbc:	610d                	addi	sp,sp,160
    80005cbe:	8082                	ret
    end_op();
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	73a080e7          	jalr	1850(ra) # 800043fa <end_op>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	b7ed                	j	80005cb4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ccc:	8526                	mv	a0,s1
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	f52080e7          	jalr	-174(ra) # 80003c20 <iunlockput>
    end_op();
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	724080e7          	jalr	1828(ra) # 800043fa <end_op>
    return -1;
    80005cde:	557d                	li	a0,-1
    80005ce0:	bfd1                	j	80005cb4 <sys_chdir+0x7a>

0000000080005ce2 <sys_exec>:

uint64
sys_exec(void)
{
    80005ce2:	7145                	addi	sp,sp,-464
    80005ce4:	e786                	sd	ra,456(sp)
    80005ce6:	e3a2                	sd	s0,448(sp)
    80005ce8:	ff26                	sd	s1,440(sp)
    80005cea:	fb4a                	sd	s2,432(sp)
    80005cec:	f74e                	sd	s3,424(sp)
    80005cee:	f352                	sd	s4,416(sp)
    80005cf0:	ef56                	sd	s5,408(sp)
    80005cf2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f4040593          	addi	a1,s0,-192
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	168080e7          	jalr	360(ra) # 80002e66 <argstr>
    return -1;
    80005d06:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d08:	0c054a63          	bltz	a0,80005ddc <sys_exec+0xfa>
    80005d0c:	e3840593          	addi	a1,s0,-456
    80005d10:	4505                	li	a0,1
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	132080e7          	jalr	306(ra) # 80002e44 <argaddr>
    80005d1a:	0c054163          	bltz	a0,80005ddc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d1e:	10000613          	li	a2,256
    80005d22:	4581                	li	a1,0
    80005d24:	e4040513          	addi	a0,s0,-448
    80005d28:	ffffb097          	auipc	ra,0xffffb
    80005d2c:	fd2080e7          	jalr	-46(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d30:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d34:	89a6                	mv	s3,s1
    80005d36:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d38:	02000a13          	li	s4,32
    80005d3c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d40:	00391793          	slli	a5,s2,0x3
    80005d44:	e3040593          	addi	a1,s0,-464
    80005d48:	e3843503          	ld	a0,-456(s0)
    80005d4c:	953e                	add	a0,a0,a5
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	03a080e7          	jalr	58(ra) # 80002d88 <fetchaddr>
    80005d56:	02054a63          	bltz	a0,80005d8a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d5a:	e3043783          	ld	a5,-464(s0)
    80005d5e:	c3b9                	beqz	a5,80005da4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d60:	ffffb097          	auipc	ra,0xffffb
    80005d64:	dae080e7          	jalr	-594(ra) # 80000b0e <kalloc>
    80005d68:	85aa                	mv	a1,a0
    80005d6a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d6e:	cd11                	beqz	a0,80005d8a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d70:	6605                	lui	a2,0x1
    80005d72:	e3043503          	ld	a0,-464(s0)
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	064080e7          	jalr	100(ra) # 80002dda <fetchstr>
    80005d7e:	00054663          	bltz	a0,80005d8a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d82:	0905                	addi	s2,s2,1
    80005d84:	09a1                	addi	s3,s3,8
    80005d86:	fb491be3          	bne	s2,s4,80005d3c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8a:	10048913          	addi	s2,s1,256
    80005d8e:	6088                	ld	a0,0(s1)
    80005d90:	c529                	beqz	a0,80005dda <sys_exec+0xf8>
    kfree(argv[i]);
    80005d92:	ffffb097          	auipc	ra,0xffffb
    80005d96:	c80080e7          	jalr	-896(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9a:	04a1                	addi	s1,s1,8
    80005d9c:	ff2499e3          	bne	s1,s2,80005d8e <sys_exec+0xac>
  return -1;
    80005da0:	597d                	li	s2,-1
    80005da2:	a82d                	j	80005ddc <sys_exec+0xfa>
      argv[i] = 0;
    80005da4:	0a8e                	slli	s5,s5,0x3
    80005da6:	fc040793          	addi	a5,s0,-64
    80005daa:	9abe                	add	s5,s5,a5
    80005dac:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005db0:	e4040593          	addi	a1,s0,-448
    80005db4:	f4040513          	addi	a0,s0,-192
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	11a080e7          	jalr	282(ra) # 80004ed2 <exec>
    80005dc0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc2:	10048993          	addi	s3,s1,256
    80005dc6:	6088                	ld	a0,0(s1)
    80005dc8:	c911                	beqz	a0,80005ddc <sys_exec+0xfa>
    kfree(argv[i]);
    80005dca:	ffffb097          	auipc	ra,0xffffb
    80005dce:	c48080e7          	jalr	-952(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd2:	04a1                	addi	s1,s1,8
    80005dd4:	ff3499e3          	bne	s1,s3,80005dc6 <sys_exec+0xe4>
    80005dd8:	a011                	j	80005ddc <sys_exec+0xfa>
  return -1;
    80005dda:	597d                	li	s2,-1
}
    80005ddc:	854a                	mv	a0,s2
    80005dde:	60be                	ld	ra,456(sp)
    80005de0:	641e                	ld	s0,448(sp)
    80005de2:	74fa                	ld	s1,440(sp)
    80005de4:	795a                	ld	s2,432(sp)
    80005de6:	79ba                	ld	s3,424(sp)
    80005de8:	7a1a                	ld	s4,416(sp)
    80005dea:	6afa                	ld	s5,408(sp)
    80005dec:	6179                	addi	sp,sp,464
    80005dee:	8082                	ret

0000000080005df0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005df0:	7139                	addi	sp,sp,-64
    80005df2:	fc06                	sd	ra,56(sp)
    80005df4:	f822                	sd	s0,48(sp)
    80005df6:	f426                	sd	s1,40(sp)
    80005df8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dfa:	ffffc097          	auipc	ra,0xffffc
    80005dfe:	d38080e7          	jalr	-712(ra) # 80001b32 <myproc>
    80005e02:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e04:	fd840593          	addi	a1,s0,-40
    80005e08:	4501                	li	a0,0
    80005e0a:	ffffd097          	auipc	ra,0xffffd
    80005e0e:	03a080e7          	jalr	58(ra) # 80002e44 <argaddr>
    return -1;
    80005e12:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e14:	0e054063          	bltz	a0,80005ef4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e18:	fc840593          	addi	a1,s0,-56
    80005e1c:	fd040513          	addi	a0,s0,-48
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	d82080e7          	jalr	-638(ra) # 80004ba2 <pipealloc>
    return -1;
    80005e28:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e2a:	0c054563          	bltz	a0,80005ef4 <sys_pipe+0x104>
  fd0 = -1;
    80005e2e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e32:	fd043503          	ld	a0,-48(s0)
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	50a080e7          	jalr	1290(ra) # 80005340 <fdalloc>
    80005e3e:	fca42223          	sw	a0,-60(s0)
    80005e42:	08054c63          	bltz	a0,80005eda <sys_pipe+0xea>
    80005e46:	fc843503          	ld	a0,-56(s0)
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	4f6080e7          	jalr	1270(ra) # 80005340 <fdalloc>
    80005e52:	fca42023          	sw	a0,-64(s0)
    80005e56:	06054863          	bltz	a0,80005ec6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5a:	4691                	li	a3,4
    80005e5c:	fc440613          	addi	a2,s0,-60
    80005e60:	fd843583          	ld	a1,-40(s0)
    80005e64:	6ca8                	ld	a0,88(s1)
    80005e66:	ffffc097          	auipc	ra,0xffffc
    80005e6a:	860080e7          	jalr	-1952(ra) # 800016c6 <copyout>
    80005e6e:	02054063          	bltz	a0,80005e8e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e72:	4691                	li	a3,4
    80005e74:	fc040613          	addi	a2,s0,-64
    80005e78:	fd843583          	ld	a1,-40(s0)
    80005e7c:	0591                	addi	a1,a1,4
    80005e7e:	6ca8                	ld	a0,88(s1)
    80005e80:	ffffc097          	auipc	ra,0xffffc
    80005e84:	846080e7          	jalr	-1978(ra) # 800016c6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e88:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e8a:	06055563          	bgez	a0,80005ef4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e8e:	fc442783          	lw	a5,-60(s0)
    80005e92:	07f1                	addi	a5,a5,28
    80005e94:	078e                	slli	a5,a5,0x3
    80005e96:	97a6                	add	a5,a5,s1
    80005e98:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e9c:	fc042503          	lw	a0,-64(s0)
    80005ea0:	0571                	addi	a0,a0,28
    80005ea2:	050e                	slli	a0,a0,0x3
    80005ea4:	9526                	add	a0,a0,s1
    80005ea6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005eaa:	fd043503          	ld	a0,-48(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	99e080e7          	jalr	-1634(ra) # 8000484c <fileclose>
    fileclose(wf);
    80005eb6:	fc843503          	ld	a0,-56(s0)
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	992080e7          	jalr	-1646(ra) # 8000484c <fileclose>
    return -1;
    80005ec2:	57fd                	li	a5,-1
    80005ec4:	a805                	j	80005ef4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ec6:	fc442783          	lw	a5,-60(s0)
    80005eca:	0007c863          	bltz	a5,80005eda <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ece:	01c78513          	addi	a0,a5,28
    80005ed2:	050e                	slli	a0,a0,0x3
    80005ed4:	9526                	add	a0,a0,s1
    80005ed6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005eda:	fd043503          	ld	a0,-48(s0)
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	96e080e7          	jalr	-1682(ra) # 8000484c <fileclose>
    fileclose(wf);
    80005ee6:	fc843503          	ld	a0,-56(s0)
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	962080e7          	jalr	-1694(ra) # 8000484c <fileclose>
    return -1;
    80005ef2:	57fd                	li	a5,-1
}
    80005ef4:	853e                	mv	a0,a5
    80005ef6:	70e2                	ld	ra,56(sp)
    80005ef8:	7442                	ld	s0,48(sp)
    80005efa:	74a2                	ld	s1,40(sp)
    80005efc:	6121                	addi	sp,sp,64
    80005efe:	8082                	ret

0000000080005f00 <kernelvec>:
    80005f00:	7111                	addi	sp,sp,-256
    80005f02:	e006                	sd	ra,0(sp)
    80005f04:	e40a                	sd	sp,8(sp)
    80005f06:	e80e                	sd	gp,16(sp)
    80005f08:	ec12                	sd	tp,24(sp)
    80005f0a:	f016                	sd	t0,32(sp)
    80005f0c:	f41a                	sd	t1,40(sp)
    80005f0e:	f81e                	sd	t2,48(sp)
    80005f10:	fc22                	sd	s0,56(sp)
    80005f12:	e0a6                	sd	s1,64(sp)
    80005f14:	e4aa                	sd	a0,72(sp)
    80005f16:	e8ae                	sd	a1,80(sp)
    80005f18:	ecb2                	sd	a2,88(sp)
    80005f1a:	f0b6                	sd	a3,96(sp)
    80005f1c:	f4ba                	sd	a4,104(sp)
    80005f1e:	f8be                	sd	a5,112(sp)
    80005f20:	fcc2                	sd	a6,120(sp)
    80005f22:	e146                	sd	a7,128(sp)
    80005f24:	e54a                	sd	s2,136(sp)
    80005f26:	e94e                	sd	s3,144(sp)
    80005f28:	ed52                	sd	s4,152(sp)
    80005f2a:	f156                	sd	s5,160(sp)
    80005f2c:	f55a                	sd	s6,168(sp)
    80005f2e:	f95e                	sd	s7,176(sp)
    80005f30:	fd62                	sd	s8,184(sp)
    80005f32:	e1e6                	sd	s9,192(sp)
    80005f34:	e5ea                	sd	s10,200(sp)
    80005f36:	e9ee                	sd	s11,208(sp)
    80005f38:	edf2                	sd	t3,216(sp)
    80005f3a:	f1f6                	sd	t4,224(sp)
    80005f3c:	f5fa                	sd	t5,232(sp)
    80005f3e:	f9fe                	sd	t6,240(sp)
    80005f40:	d15fc0ef          	jal	ra,80002c54 <kerneltrap>
    80005f44:	6082                	ld	ra,0(sp)
    80005f46:	6122                	ld	sp,8(sp)
    80005f48:	61c2                	ld	gp,16(sp)
    80005f4a:	7282                	ld	t0,32(sp)
    80005f4c:	7322                	ld	t1,40(sp)
    80005f4e:	73c2                	ld	t2,48(sp)
    80005f50:	7462                	ld	s0,56(sp)
    80005f52:	6486                	ld	s1,64(sp)
    80005f54:	6526                	ld	a0,72(sp)
    80005f56:	65c6                	ld	a1,80(sp)
    80005f58:	6666                	ld	a2,88(sp)
    80005f5a:	7686                	ld	a3,96(sp)
    80005f5c:	7726                	ld	a4,104(sp)
    80005f5e:	77c6                	ld	a5,112(sp)
    80005f60:	7866                	ld	a6,120(sp)
    80005f62:	688a                	ld	a7,128(sp)
    80005f64:	692a                	ld	s2,136(sp)
    80005f66:	69ca                	ld	s3,144(sp)
    80005f68:	6a6a                	ld	s4,152(sp)
    80005f6a:	7a8a                	ld	s5,160(sp)
    80005f6c:	7b2a                	ld	s6,168(sp)
    80005f6e:	7bca                	ld	s7,176(sp)
    80005f70:	7c6a                	ld	s8,184(sp)
    80005f72:	6c8e                	ld	s9,192(sp)
    80005f74:	6d2e                	ld	s10,200(sp)
    80005f76:	6dce                	ld	s11,208(sp)
    80005f78:	6e6e                	ld	t3,216(sp)
    80005f7a:	7e8e                	ld	t4,224(sp)
    80005f7c:	7f2e                	ld	t5,232(sp)
    80005f7e:	7fce                	ld	t6,240(sp)
    80005f80:	6111                	addi	sp,sp,256
    80005f82:	10200073          	sret
    80005f86:	00000013          	nop
    80005f8a:	00000013          	nop
    80005f8e:	0001                	nop

0000000080005f90 <timervec>:
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	e10c                	sd	a1,0(a0)
    80005f96:	e510                	sd	a2,8(a0)
    80005f98:	e914                	sd	a3,16(a0)
    80005f9a:	710c                	ld	a1,32(a0)
    80005f9c:	7510                	ld	a2,40(a0)
    80005f9e:	6194                	ld	a3,0(a1)
    80005fa0:	96b2                	add	a3,a3,a2
    80005fa2:	e194                	sd	a3,0(a1)
    80005fa4:	4589                	li	a1,2
    80005fa6:	14459073          	csrw	sip,a1
    80005faa:	6914                	ld	a3,16(a0)
    80005fac:	6510                	ld	a2,8(a0)
    80005fae:	610c                	ld	a1,0(a0)
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	30200073          	mret
	...

0000000080005fba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fc0:	0c0007b7          	lui	a5,0xc000
    80005fc4:	4705                	li	a4,1
    80005fc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fc8:	c3d8                	sw	a4,4(a5)
}
    80005fca:	6422                	ld	s0,8(sp)
    80005fcc:	0141                	addi	sp,sp,16
    80005fce:	8082                	ret

0000000080005fd0 <plicinithart>:

void
plicinithart(void)
{
    80005fd0:	1141                	addi	sp,sp,-16
    80005fd2:	e406                	sd	ra,8(sp)
    80005fd4:	e022                	sd	s0,0(sp)
    80005fd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	b2e080e7          	jalr	-1234(ra) # 80001b06 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fe0:	0085171b          	slliw	a4,a0,0x8
    80005fe4:	0c0027b7          	lui	a5,0xc002
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	40200713          	li	a4,1026
    80005fee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ff2:	00d5151b          	slliw	a0,a0,0xd
    80005ff6:	0c2017b7          	lui	a5,0xc201
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	00052023          	sw	zero,0(a0)
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret

0000000080006008 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006008:	1141                	addi	sp,sp,-16
    8000600a:	e406                	sd	ra,8(sp)
    8000600c:	e022                	sd	s0,0(sp)
    8000600e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	af6080e7          	jalr	-1290(ra) # 80001b06 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006018:	00d5179b          	slliw	a5,a0,0xd
    8000601c:	0c201537          	lui	a0,0xc201
    80006020:	953e                	add	a0,a0,a5
  return irq;
}
    80006022:	4148                	lw	a0,4(a0)
    80006024:	60a2                	ld	ra,8(sp)
    80006026:	6402                	ld	s0,0(sp)
    80006028:	0141                	addi	sp,sp,16
    8000602a:	8082                	ret

000000008000602c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000602c:	1101                	addi	sp,sp,-32
    8000602e:	ec06                	sd	ra,24(sp)
    80006030:	e822                	sd	s0,16(sp)
    80006032:	e426                	sd	s1,8(sp)
    80006034:	1000                	addi	s0,sp,32
    80006036:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	ace080e7          	jalr	-1330(ra) # 80001b06 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006040:	00d5151b          	slliw	a0,a0,0xd
    80006044:	0c2017b7          	lui	a5,0xc201
    80006048:	97aa                	add	a5,a5,a0
    8000604a:	c3c4                	sw	s1,4(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret

0000000080006056 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006056:	1141                	addi	sp,sp,-16
    80006058:	e406                	sd	ra,8(sp)
    8000605a:	e022                	sd	s0,0(sp)
    8000605c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000605e:	479d                	li	a5,7
    80006060:	04a7cc63          	blt	a5,a0,800060b8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006064:	0001d797          	auipc	a5,0x1d
    80006068:	f9c78793          	addi	a5,a5,-100 # 80023000 <disk>
    8000606c:	00a78733          	add	a4,a5,a0
    80006070:	6789                	lui	a5,0x2
    80006072:	97ba                	add	a5,a5,a4
    80006074:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006078:	eba1                	bnez	a5,800060c8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000607a:	00451713          	slli	a4,a0,0x4
    8000607e:	0001f797          	auipc	a5,0x1f
    80006082:	f827b783          	ld	a5,-126(a5) # 80025000 <disk+0x2000>
    80006086:	97ba                	add	a5,a5,a4
    80006088:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000608c:	0001d797          	auipc	a5,0x1d
    80006090:	f7478793          	addi	a5,a5,-140 # 80023000 <disk>
    80006094:	97aa                	add	a5,a5,a0
    80006096:	6509                	lui	a0,0x2
    80006098:	953e                	add	a0,a0,a5
    8000609a:	4785                	li	a5,1
    8000609c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060a0:	0001f517          	auipc	a0,0x1f
    800060a4:	f7850513          	addi	a0,a0,-136 # 80025018 <disk+0x2018>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	526080e7          	jalr	1318(ra) # 800025ce <wakeup>
}
    800060b0:	60a2                	ld	ra,8(sp)
    800060b2:	6402                	ld	s0,0(sp)
    800060b4:	0141                	addi	sp,sp,16
    800060b6:	8082                	ret
    panic("virtio_disk_intr 1");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	6e850513          	addi	a0,a0,1768 # 800087a0 <syscalls+0x328>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	482080e7          	jalr	1154(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	6f050513          	addi	a0,a0,1776 # 800087b8 <syscalls+0x340>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	472080e7          	jalr	1138(ra) # 80000542 <panic>

00000000800060d8 <virtio_disk_init>:
{
    800060d8:	1101                	addi	sp,sp,-32
    800060da:	ec06                	sd	ra,24(sp)
    800060dc:	e822                	sd	s0,16(sp)
    800060de:	e426                	sd	s1,8(sp)
    800060e0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060e2:	00002597          	auipc	a1,0x2
    800060e6:	6ee58593          	addi	a1,a1,1774 # 800087d0 <syscalls+0x358>
    800060ea:	0001f517          	auipc	a0,0x1f
    800060ee:	fbe50513          	addi	a0,a0,-66 # 800250a8 <disk+0x20a8>
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	a7c080e7          	jalr	-1412(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	4398                	lw	a4,0(a5)
    80006100:	2701                	sext.w	a4,a4
    80006102:	747277b7          	lui	a5,0x74727
    80006106:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000610a:	0ef71163          	bne	a4,a5,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	43dc                	lw	a5,4(a5)
    80006114:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006116:	4705                	li	a4,1
    80006118:	0ce79a63          	bne	a5,a4,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	479c                	lw	a5,8(a5)
    80006122:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006124:	4709                	li	a4,2
    80006126:	0ce79363          	bne	a5,a4,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000612a:	100017b7          	lui	a5,0x10001
    8000612e:	47d8                	lw	a4,12(a5)
    80006130:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006132:	554d47b7          	lui	a5,0x554d4
    80006136:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000613a:	0af71963          	bne	a4,a5,800061ec <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	4705                	li	a4,1
    80006144:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006146:	470d                	li	a4,3
    80006148:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000614a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000614c:	c7ffe737          	lui	a4,0xc7ffe
    80006150:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006154:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006156:	2701                	sext.w	a4,a4
    80006158:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615a:	472d                	li	a4,11
    8000615c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615e:	473d                	li	a4,15
    80006160:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006162:	6705                	lui	a4,0x1
    80006164:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006166:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000616a:	5bdc                	lw	a5,52(a5)
    8000616c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000616e:	c7d9                	beqz	a5,800061fc <virtio_disk_init+0x124>
  if(max < NUM)
    80006170:	471d                	li	a4,7
    80006172:	08f77d63          	bgeu	a4,a5,8000620c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006176:	100014b7          	lui	s1,0x10001
    8000617a:	47a1                	li	a5,8
    8000617c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000617e:	6609                	lui	a2,0x2
    80006180:	4581                	li	a1,0
    80006182:	0001d517          	auipc	a0,0x1d
    80006186:	e7e50513          	addi	a0,a0,-386 # 80023000 <disk>
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	b70080e7          	jalr	-1168(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006192:	0001d717          	auipc	a4,0x1d
    80006196:	e6e70713          	addi	a4,a4,-402 # 80023000 <disk>
    8000619a:	00c75793          	srli	a5,a4,0xc
    8000619e:	2781                	sext.w	a5,a5
    800061a0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800061a2:	0001f797          	auipc	a5,0x1f
    800061a6:	e5e78793          	addi	a5,a5,-418 # 80025000 <disk+0x2000>
    800061aa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800061ac:	0001d717          	auipc	a4,0x1d
    800061b0:	ed470713          	addi	a4,a4,-300 # 80023080 <disk+0x80>
    800061b4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800061b6:	0001e717          	auipc	a4,0x1e
    800061ba:	e4a70713          	addi	a4,a4,-438 # 80024000 <disk+0x1000>
    800061be:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061c0:	4705                	li	a4,1
    800061c2:	00e78c23          	sb	a4,24(a5)
    800061c6:	00e78ca3          	sb	a4,25(a5)
    800061ca:	00e78d23          	sb	a4,26(a5)
    800061ce:	00e78da3          	sb	a4,27(a5)
    800061d2:	00e78e23          	sb	a4,28(a5)
    800061d6:	00e78ea3          	sb	a4,29(a5)
    800061da:	00e78f23          	sb	a4,30(a5)
    800061de:	00e78fa3          	sb	a4,31(a5)
}
    800061e2:	60e2                	ld	ra,24(sp)
    800061e4:	6442                	ld	s0,16(sp)
    800061e6:	64a2                	ld	s1,8(sp)
    800061e8:	6105                	addi	sp,sp,32
    800061ea:	8082                	ret
    panic("could not find virtio disk");
    800061ec:	00002517          	auipc	a0,0x2
    800061f0:	5f450513          	addi	a0,a0,1524 # 800087e0 <syscalls+0x368>
    800061f4:	ffffa097          	auipc	ra,0xffffa
    800061f8:	34e080e7          	jalr	846(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    800061fc:	00002517          	auipc	a0,0x2
    80006200:	60450513          	addi	a0,a0,1540 # 80008800 <syscalls+0x388>
    80006204:	ffffa097          	auipc	ra,0xffffa
    80006208:	33e080e7          	jalr	830(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    8000620c:	00002517          	auipc	a0,0x2
    80006210:	61450513          	addi	a0,a0,1556 # 80008820 <syscalls+0x3a8>
    80006214:	ffffa097          	auipc	ra,0xffffa
    80006218:	32e080e7          	jalr	814(ra) # 80000542 <panic>

000000008000621c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000621c:	7175                	addi	sp,sp,-144
    8000621e:	e506                	sd	ra,136(sp)
    80006220:	e122                	sd	s0,128(sp)
    80006222:	fca6                	sd	s1,120(sp)
    80006224:	f8ca                	sd	s2,112(sp)
    80006226:	f4ce                	sd	s3,104(sp)
    80006228:	f0d2                	sd	s4,96(sp)
    8000622a:	ecd6                	sd	s5,88(sp)
    8000622c:	e8da                	sd	s6,80(sp)
    8000622e:	e4de                	sd	s7,72(sp)
    80006230:	e0e2                	sd	s8,64(sp)
    80006232:	fc66                	sd	s9,56(sp)
    80006234:	f86a                	sd	s10,48(sp)
    80006236:	f46e                	sd	s11,40(sp)
    80006238:	0900                	addi	s0,sp,144
    8000623a:	8aaa                	mv	s5,a0
    8000623c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000623e:	00c52c83          	lw	s9,12(a0)
    80006242:	001c9c9b          	slliw	s9,s9,0x1
    80006246:	1c82                	slli	s9,s9,0x20
    80006248:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000624c:	0001f517          	auipc	a0,0x1f
    80006250:	e5c50513          	addi	a0,a0,-420 # 800250a8 <disk+0x20a8>
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	9aa080e7          	jalr	-1622(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    8000625c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000625e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006260:	0001dc17          	auipc	s8,0x1d
    80006264:	da0c0c13          	addi	s8,s8,-608 # 80023000 <disk>
    80006268:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000626a:	4b0d                	li	s6,3
    8000626c:	a0ad                	j	800062d6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000626e:	00fc0733          	add	a4,s8,a5
    80006272:	975e                	add	a4,a4,s7
    80006274:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006278:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000627a:	0207c563          	bltz	a5,800062a4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000627e:	2905                	addiw	s2,s2,1
    80006280:	0611                	addi	a2,a2,4
    80006282:	19690d63          	beq	s2,s6,8000641c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006286:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006288:	0001f717          	auipc	a4,0x1f
    8000628c:	d9070713          	addi	a4,a4,-624 # 80025018 <disk+0x2018>
    80006290:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006292:	00074683          	lbu	a3,0(a4)
    80006296:	fee1                	bnez	a3,8000626e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006298:	2785                	addiw	a5,a5,1
    8000629a:	0705                	addi	a4,a4,1
    8000629c:	fe979be3          	bne	a5,s1,80006292 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062a0:	57fd                	li	a5,-1
    800062a2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062a4:	01205d63          	blez	s2,800062be <virtio_disk_rw+0xa2>
    800062a8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062aa:	000a2503          	lw	a0,0(s4)
    800062ae:	00000097          	auipc	ra,0x0
    800062b2:	da8080e7          	jalr	-600(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062b6:	2d85                	addiw	s11,s11,1
    800062b8:	0a11                	addi	s4,s4,4
    800062ba:	ffb918e3          	bne	s2,s11,800062aa <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062be:	0001f597          	auipc	a1,0x1f
    800062c2:	dea58593          	addi	a1,a1,-534 # 800250a8 <disk+0x20a8>
    800062c6:	0001f517          	auipc	a0,0x1f
    800062ca:	d5250513          	addi	a0,a0,-686 # 80025018 <disk+0x2018>
    800062ce:	ffffc097          	auipc	ra,0xffffc
    800062d2:	180080e7          	jalr	384(ra) # 8000244e <sleep>
  for(int i = 0; i < 3; i++){
    800062d6:	f8040a13          	addi	s4,s0,-128
{
    800062da:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062dc:	894e                	mv	s2,s3
    800062de:	b765                	j	80006286 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062e0:	0001f717          	auipc	a4,0x1f
    800062e4:	d2073703          	ld	a4,-736(a4) # 80025000 <disk+0x2000>
    800062e8:	973e                	add	a4,a4,a5
    800062ea:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ee:	0001d517          	auipc	a0,0x1d
    800062f2:	d1250513          	addi	a0,a0,-750 # 80023000 <disk>
    800062f6:	0001f717          	auipc	a4,0x1f
    800062fa:	d0a70713          	addi	a4,a4,-758 # 80025000 <disk+0x2000>
    800062fe:	6314                	ld	a3,0(a4)
    80006300:	96be                	add	a3,a3,a5
    80006302:	00c6d603          	lhu	a2,12(a3)
    80006306:	00166613          	ori	a2,a2,1
    8000630a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000630e:	f8842683          	lw	a3,-120(s0)
    80006312:	6310                	ld	a2,0(a4)
    80006314:	97b2                	add	a5,a5,a2
    80006316:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000631a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000631e:	0612                	slli	a2,a2,0x4
    80006320:	962a                	add	a2,a2,a0
    80006322:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006326:	00469793          	slli	a5,a3,0x4
    8000632a:	630c                	ld	a1,0(a4)
    8000632c:	95be                	add	a1,a1,a5
    8000632e:	6689                	lui	a3,0x2
    80006330:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006334:	96ca                	add	a3,a3,s2
    80006336:	96aa                	add	a3,a3,a0
    80006338:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000633a:	6314                	ld	a3,0(a4)
    8000633c:	96be                	add	a3,a3,a5
    8000633e:	4585                	li	a1,1
    80006340:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006342:	6314                	ld	a3,0(a4)
    80006344:	96be                	add	a3,a3,a5
    80006346:	4509                	li	a0,2
    80006348:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000634c:	6314                	ld	a3,0(a4)
    8000634e:	97b6                	add	a5,a5,a3
    80006350:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006354:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006358:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000635c:	6714                	ld	a3,8(a4)
    8000635e:	0026d783          	lhu	a5,2(a3)
    80006362:	8b9d                	andi	a5,a5,7
    80006364:	0789                	addi	a5,a5,2
    80006366:	0786                	slli	a5,a5,0x1
    80006368:	97b6                	add	a5,a5,a3
    8000636a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000636e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006372:	6718                	ld	a4,8(a4)
    80006374:	00275783          	lhu	a5,2(a4)
    80006378:	2785                	addiw	a5,a5,1
    8000637a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000637e:	100017b7          	lui	a5,0x10001
    80006382:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006386:	004aa783          	lw	a5,4(s5)
    8000638a:	02b79163          	bne	a5,a1,800063ac <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000638e:	0001f917          	auipc	s2,0x1f
    80006392:	d1a90913          	addi	s2,s2,-742 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006396:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006398:	85ca                	mv	a1,s2
    8000639a:	8556                	mv	a0,s5
    8000639c:	ffffc097          	auipc	ra,0xffffc
    800063a0:	0b2080e7          	jalr	178(ra) # 8000244e <sleep>
  while(b->disk == 1) {
    800063a4:	004aa783          	lw	a5,4(s5)
    800063a8:	fe9788e3          	beq	a5,s1,80006398 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800063ac:	f8042483          	lw	s1,-128(s0)
    800063b0:	20048793          	addi	a5,s1,512
    800063b4:	00479713          	slli	a4,a5,0x4
    800063b8:	0001d797          	auipc	a5,0x1d
    800063bc:	c4878793          	addi	a5,a5,-952 # 80023000 <disk>
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063c6:	0001f917          	auipc	s2,0x1f
    800063ca:	c3a90913          	addi	s2,s2,-966 # 80025000 <disk+0x2000>
    800063ce:	a019                	j	800063d4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800063d0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800063d4:	8526                	mv	a0,s1
    800063d6:	00000097          	auipc	ra,0x0
    800063da:	c80080e7          	jalr	-896(ra) # 80006056 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063de:	0492                	slli	s1,s1,0x4
    800063e0:	00093783          	ld	a5,0(s2)
    800063e4:	94be                	add	s1,s1,a5
    800063e6:	00c4d783          	lhu	a5,12(s1)
    800063ea:	8b85                	andi	a5,a5,1
    800063ec:	f3f5                	bnez	a5,800063d0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ee:	0001f517          	auipc	a0,0x1f
    800063f2:	cba50513          	addi	a0,a0,-838 # 800250a8 <disk+0x20a8>
    800063f6:	ffffb097          	auipc	ra,0xffffb
    800063fa:	8bc080e7          	jalr	-1860(ra) # 80000cb2 <release>
}
    800063fe:	60aa                	ld	ra,136(sp)
    80006400:	640a                	ld	s0,128(sp)
    80006402:	74e6                	ld	s1,120(sp)
    80006404:	7946                	ld	s2,112(sp)
    80006406:	79a6                	ld	s3,104(sp)
    80006408:	7a06                	ld	s4,96(sp)
    8000640a:	6ae6                	ld	s5,88(sp)
    8000640c:	6b46                	ld	s6,80(sp)
    8000640e:	6ba6                	ld	s7,72(sp)
    80006410:	6c06                	ld	s8,64(sp)
    80006412:	7ce2                	ld	s9,56(sp)
    80006414:	7d42                	ld	s10,48(sp)
    80006416:	7da2                	ld	s11,40(sp)
    80006418:	6149                	addi	sp,sp,144
    8000641a:	8082                	ret
  if(write)
    8000641c:	01a037b3          	snez	a5,s10
    80006420:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006424:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006428:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa(myproc()->kpagetable, (uint64) &buf0); // 调用 myproc()，获取进程内核页表
    8000642c:	ffffb097          	auipc	ra,0xffffb
    80006430:	706080e7          	jalr	1798(ra) # 80001b32 <myproc>
    80006434:	f8042483          	lw	s1,-128(s0)
    80006438:	00449913          	slli	s2,s1,0x4
    8000643c:	0001f997          	auipc	s3,0x1f
    80006440:	bc498993          	addi	s3,s3,-1084 # 80025000 <disk+0x2000>
    80006444:	0009ba03          	ld	s4,0(s3)
    80006448:	9a4a                	add	s4,s4,s2
    8000644a:	f7040593          	addi	a1,s0,-144
    8000644e:	7128                	ld	a0,96(a0)
    80006450:	ffffb097          	auipc	ra,0xffffb
    80006454:	c82080e7          	jalr	-894(ra) # 800010d2 <kvmpa>
    80006458:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000645c:	0009b783          	ld	a5,0(s3)
    80006460:	97ca                	add	a5,a5,s2
    80006462:	4741                	li	a4,16
    80006464:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006466:	0009b783          	ld	a5,0(s3)
    8000646a:	97ca                	add	a5,a5,s2
    8000646c:	4705                	li	a4,1
    8000646e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006472:	f8442783          	lw	a5,-124(s0)
    80006476:	0009b703          	ld	a4,0(s3)
    8000647a:	974a                	add	a4,a4,s2
    8000647c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006480:	0792                	slli	a5,a5,0x4
    80006482:	0009b703          	ld	a4,0(s3)
    80006486:	973e                	add	a4,a4,a5
    80006488:	058a8693          	addi	a3,s5,88
    8000648c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000648e:	0009b703          	ld	a4,0(s3)
    80006492:	973e                	add	a4,a4,a5
    80006494:	40000693          	li	a3,1024
    80006498:	c714                	sw	a3,8(a4)
  if(write)
    8000649a:	e40d13e3          	bnez	s10,800062e0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000649e:	0001f717          	auipc	a4,0x1f
    800064a2:	b6273703          	ld	a4,-1182(a4) # 80025000 <disk+0x2000>
    800064a6:	973e                	add	a4,a4,a5
    800064a8:	4689                	li	a3,2
    800064aa:	00d71623          	sh	a3,12(a4)
    800064ae:	b581                	j	800062ee <virtio_disk_rw+0xd2>

00000000800064b0 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064b0:	1101                	addi	sp,sp,-32
    800064b2:	ec06                	sd	ra,24(sp)
    800064b4:	e822                	sd	s0,16(sp)
    800064b6:	e426                	sd	s1,8(sp)
    800064b8:	e04a                	sd	s2,0(sp)
    800064ba:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064bc:	0001f517          	auipc	a0,0x1f
    800064c0:	bec50513          	addi	a0,a0,-1044 # 800250a8 <disk+0x20a8>
    800064c4:	ffffa097          	auipc	ra,0xffffa
    800064c8:	73a080e7          	jalr	1850(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064cc:	0001f717          	auipc	a4,0x1f
    800064d0:	b3470713          	addi	a4,a4,-1228 # 80025000 <disk+0x2000>
    800064d4:	02075783          	lhu	a5,32(a4)
    800064d8:	6b18                	ld	a4,16(a4)
    800064da:	00275683          	lhu	a3,2(a4)
    800064de:	8ebd                	xor	a3,a3,a5
    800064e0:	8a9d                	andi	a3,a3,7
    800064e2:	cab9                	beqz	a3,80006538 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800064e4:	0001d917          	auipc	s2,0x1d
    800064e8:	b1c90913          	addi	s2,s2,-1252 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064ec:	0001f497          	auipc	s1,0x1f
    800064f0:	b1448493          	addi	s1,s1,-1260 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800064f4:	078e                	slli	a5,a5,0x3
    800064f6:	97ba                	add	a5,a5,a4
    800064f8:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064fa:	20078713          	addi	a4,a5,512
    800064fe:	0712                	slli	a4,a4,0x4
    80006500:	974a                	add	a4,a4,s2
    80006502:	03074703          	lbu	a4,48(a4)
    80006506:	ef21                	bnez	a4,8000655e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006508:	20078793          	addi	a5,a5,512
    8000650c:	0792                	slli	a5,a5,0x4
    8000650e:	97ca                	add	a5,a5,s2
    80006510:	7798                	ld	a4,40(a5)
    80006512:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006516:	7788                	ld	a0,40(a5)
    80006518:	ffffc097          	auipc	ra,0xffffc
    8000651c:	0b6080e7          	jalr	182(ra) # 800025ce <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006520:	0204d783          	lhu	a5,32(s1)
    80006524:	2785                	addiw	a5,a5,1
    80006526:	8b9d                	andi	a5,a5,7
    80006528:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000652c:	6898                	ld	a4,16(s1)
    8000652e:	00275683          	lhu	a3,2(a4)
    80006532:	8a9d                	andi	a3,a3,7
    80006534:	fcf690e3          	bne	a3,a5,800064f4 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006538:	10001737          	lui	a4,0x10001
    8000653c:	533c                	lw	a5,96(a4)
    8000653e:	8b8d                	andi	a5,a5,3
    80006540:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006542:	0001f517          	auipc	a0,0x1f
    80006546:	b6650513          	addi	a0,a0,-1178 # 800250a8 <disk+0x20a8>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	768080e7          	jalr	1896(ra) # 80000cb2 <release>
}
    80006552:	60e2                	ld	ra,24(sp)
    80006554:	6442                	ld	s0,16(sp)
    80006556:	64a2                	ld	s1,8(sp)
    80006558:	6902                	ld	s2,0(sp)
    8000655a:	6105                	addi	sp,sp,32
    8000655c:	8082                	ret
      panic("virtio_disk_intr status");
    8000655e:	00002517          	auipc	a0,0x2
    80006562:	2e250513          	addi	a0,a0,738 # 80008840 <syscalls+0x3c8>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	fdc080e7          	jalr	-36(ra) # 80000542 <panic>

000000008000656e <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000656e:	7179                	addi	sp,sp,-48
    80006570:	f406                	sd	ra,40(sp)
    80006572:	f022                	sd	s0,32(sp)
    80006574:	ec26                	sd	s1,24(sp)
    80006576:	e84a                	sd	s2,16(sp)
    80006578:	e44e                	sd	s3,8(sp)
    8000657a:	e052                	sd	s4,0(sp)
    8000657c:	1800                	addi	s0,sp,48
    8000657e:	892a                	mv	s2,a0
    80006580:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006582:	00003a17          	auipc	s4,0x3
    80006586:	aa6a0a13          	addi	s4,s4,-1370 # 80009028 <stats>
    8000658a:	000a2683          	lw	a3,0(s4)
    8000658e:	00002617          	auipc	a2,0x2
    80006592:	2ca60613          	addi	a2,a2,714 # 80008858 <syscalls+0x3e0>
    80006596:	00000097          	auipc	ra,0x0
    8000659a:	2c2080e7          	jalr	706(ra) # 80006858 <snprintf>
    8000659e:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800065a0:	004a2683          	lw	a3,4(s4)
    800065a4:	00002617          	auipc	a2,0x2
    800065a8:	2c460613          	addi	a2,a2,708 # 80008868 <syscalls+0x3f0>
    800065ac:	85ce                	mv	a1,s3
    800065ae:	954a                	add	a0,a0,s2
    800065b0:	00000097          	auipc	ra,0x0
    800065b4:	2a8080e7          	jalr	680(ra) # 80006858 <snprintf>
  return n;
}
    800065b8:	9d25                	addw	a0,a0,s1
    800065ba:	70a2                	ld	ra,40(sp)
    800065bc:	7402                	ld	s0,32(sp)
    800065be:	64e2                	ld	s1,24(sp)
    800065c0:	6942                	ld	s2,16(sp)
    800065c2:	69a2                	ld	s3,8(sp)
    800065c4:	6a02                	ld	s4,0(sp)
    800065c6:	6145                	addi	sp,sp,48
    800065c8:	8082                	ret

00000000800065ca <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800065ca:	7179                	addi	sp,sp,-48
    800065cc:	f406                	sd	ra,40(sp)
    800065ce:	f022                	sd	s0,32(sp)
    800065d0:	ec26                	sd	s1,24(sp)
    800065d2:	e84a                	sd	s2,16(sp)
    800065d4:	e44e                	sd	s3,8(sp)
    800065d6:	1800                	addi	s0,sp,48
    800065d8:	89ae                	mv	s3,a1
    800065da:	84b2                	mv	s1,a2
    800065dc:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800065de:	ffffb097          	auipc	ra,0xffffb
    800065e2:	554080e7          	jalr	1364(ra) # 80001b32 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800065e6:	653c                	ld	a5,72(a0)
    800065e8:	02f4ff63          	bgeu	s1,a5,80006626 <copyin_new+0x5c>
    800065ec:	01248733          	add	a4,s1,s2
    800065f0:	02f77d63          	bgeu	a4,a5,8000662a <copyin_new+0x60>
    800065f4:	02976d63          	bltu	a4,s1,8000662e <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800065f8:	0009061b          	sext.w	a2,s2
    800065fc:	85a6                	mv	a1,s1
    800065fe:	854e                	mv	a0,s3
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	756080e7          	jalr	1878(ra) # 80000d56 <memmove>
  stats.ncopyin++;   // XXX lock
    80006608:	00003717          	auipc	a4,0x3
    8000660c:	a2070713          	addi	a4,a4,-1504 # 80009028 <stats>
    80006610:	431c                	lw	a5,0(a4)
    80006612:	2785                	addiw	a5,a5,1
    80006614:	c31c                	sw	a5,0(a4)
  return 0;
    80006616:	4501                	li	a0,0
}
    80006618:	70a2                	ld	ra,40(sp)
    8000661a:	7402                	ld	s0,32(sp)
    8000661c:	64e2                	ld	s1,24(sp)
    8000661e:	6942                	ld	s2,16(sp)
    80006620:	69a2                	ld	s3,8(sp)
    80006622:	6145                	addi	sp,sp,48
    80006624:	8082                	ret
    return -1;
    80006626:	557d                	li	a0,-1
    80006628:	bfc5                	j	80006618 <copyin_new+0x4e>
    8000662a:	557d                	li	a0,-1
    8000662c:	b7f5                	j	80006618 <copyin_new+0x4e>
    8000662e:	557d                	li	a0,-1
    80006630:	b7e5                	j	80006618 <copyin_new+0x4e>

0000000080006632 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006632:	7179                	addi	sp,sp,-48
    80006634:	f406                	sd	ra,40(sp)
    80006636:	f022                	sd	s0,32(sp)
    80006638:	ec26                	sd	s1,24(sp)
    8000663a:	e84a                	sd	s2,16(sp)
    8000663c:	e44e                	sd	s3,8(sp)
    8000663e:	1800                	addi	s0,sp,48
    80006640:	89ae                	mv	s3,a1
    80006642:	8932                	mv	s2,a2
    80006644:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006646:	ffffb097          	auipc	ra,0xffffb
    8000664a:	4ec080e7          	jalr	1260(ra) # 80001b32 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    8000664e:	00003717          	auipc	a4,0x3
    80006652:	9da70713          	addi	a4,a4,-1574 # 80009028 <stats>
    80006656:	435c                	lw	a5,4(a4)
    80006658:	2785                	addiw	a5,a5,1
    8000665a:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000665c:	cc85                	beqz	s1,80006694 <copyinstr_new+0x62>
    8000665e:	00990833          	add	a6,s2,s1
    80006662:	87ca                	mv	a5,s2
    80006664:	6538                	ld	a4,72(a0)
    80006666:	00e7ff63          	bgeu	a5,a4,80006684 <copyinstr_new+0x52>
    dst[i] = s[i];
    8000666a:	0007c683          	lbu	a3,0(a5)
    8000666e:	41278733          	sub	a4,a5,s2
    80006672:	974e                	add	a4,a4,s3
    80006674:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    80006678:	c285                	beqz	a3,80006698 <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000667a:	0785                	addi	a5,a5,1
    8000667c:	ff0794e3          	bne	a5,a6,80006664 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006680:	557d                	li	a0,-1
    80006682:	a011                	j	80006686 <copyinstr_new+0x54>
    80006684:	557d                	li	a0,-1
}
    80006686:	70a2                	ld	ra,40(sp)
    80006688:	7402                	ld	s0,32(sp)
    8000668a:	64e2                	ld	s1,24(sp)
    8000668c:	6942                	ld	s2,16(sp)
    8000668e:	69a2                	ld	s3,8(sp)
    80006690:	6145                	addi	sp,sp,48
    80006692:	8082                	ret
  return -1;
    80006694:	557d                	li	a0,-1
    80006696:	bfc5                	j	80006686 <copyinstr_new+0x54>
      return 0;
    80006698:	4501                	li	a0,0
    8000669a:	b7f5                	j	80006686 <copyinstr_new+0x54>

000000008000669c <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000669c:	1141                	addi	sp,sp,-16
    8000669e:	e422                	sd	s0,8(sp)
    800066a0:	0800                	addi	s0,sp,16
  return -1;
}
    800066a2:	557d                	li	a0,-1
    800066a4:	6422                	ld	s0,8(sp)
    800066a6:	0141                	addi	sp,sp,16
    800066a8:	8082                	ret

00000000800066aa <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800066aa:	7179                	addi	sp,sp,-48
    800066ac:	f406                	sd	ra,40(sp)
    800066ae:	f022                	sd	s0,32(sp)
    800066b0:	ec26                	sd	s1,24(sp)
    800066b2:	e84a                	sd	s2,16(sp)
    800066b4:	e44e                	sd	s3,8(sp)
    800066b6:	e052                	sd	s4,0(sp)
    800066b8:	1800                	addi	s0,sp,48
    800066ba:	892a                	mv	s2,a0
    800066bc:	89ae                	mv	s3,a1
    800066be:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800066c0:	00020517          	auipc	a0,0x20
    800066c4:	94050513          	addi	a0,a0,-1728 # 80026000 <stats>
    800066c8:	ffffa097          	auipc	ra,0xffffa
    800066cc:	536080e7          	jalr	1334(ra) # 80000bfe <acquire>

  if(stats.sz == 0) {
    800066d0:	00021797          	auipc	a5,0x21
    800066d4:	9487a783          	lw	a5,-1720(a5) # 80027018 <stats+0x1018>
    800066d8:	cbb5                	beqz	a5,8000674c <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800066da:	00021797          	auipc	a5,0x21
    800066de:	92678793          	addi	a5,a5,-1754 # 80027000 <stats+0x1000>
    800066e2:	4fd8                	lw	a4,28(a5)
    800066e4:	4f9c                	lw	a5,24(a5)
    800066e6:	9f99                	subw	a5,a5,a4
    800066e8:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800066ec:	06d05e63          	blez	a3,80006768 <statsread+0xbe>
    if(m > n)
    800066f0:	8a3e                	mv	s4,a5
    800066f2:	00d4d363          	bge	s1,a3,800066f8 <statsread+0x4e>
    800066f6:	8a26                	mv	s4,s1
    800066f8:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066fc:	86a6                	mv	a3,s1
    800066fe:	00020617          	auipc	a2,0x20
    80006702:	91a60613          	addi	a2,a2,-1766 # 80026018 <stats+0x18>
    80006706:	963a                	add	a2,a2,a4
    80006708:	85ce                	mv	a1,s3
    8000670a:	854a                	mv	a0,s2
    8000670c:	ffffc097          	auipc	ra,0xffffc
    80006710:	f9c080e7          	jalr	-100(ra) # 800026a8 <either_copyout>
    80006714:	57fd                	li	a5,-1
    80006716:	00f50a63          	beq	a0,a5,8000672a <statsread+0x80>
      stats.off += m;
    8000671a:	00021717          	auipc	a4,0x21
    8000671e:	8e670713          	addi	a4,a4,-1818 # 80027000 <stats+0x1000>
    80006722:	4f5c                	lw	a5,28(a4)
    80006724:	014787bb          	addw	a5,a5,s4
    80006728:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    8000672a:	00020517          	auipc	a0,0x20
    8000672e:	8d650513          	addi	a0,a0,-1834 # 80026000 <stats>
    80006732:	ffffa097          	auipc	ra,0xffffa
    80006736:	580080e7          	jalr	1408(ra) # 80000cb2 <release>
  return m;
}
    8000673a:	8526                	mv	a0,s1
    8000673c:	70a2                	ld	ra,40(sp)
    8000673e:	7402                	ld	s0,32(sp)
    80006740:	64e2                	ld	s1,24(sp)
    80006742:	6942                	ld	s2,16(sp)
    80006744:	69a2                	ld	s3,8(sp)
    80006746:	6a02                	ld	s4,0(sp)
    80006748:	6145                	addi	sp,sp,48
    8000674a:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    8000674c:	6585                	lui	a1,0x1
    8000674e:	00020517          	auipc	a0,0x20
    80006752:	8ca50513          	addi	a0,a0,-1846 # 80026018 <stats+0x18>
    80006756:	00000097          	auipc	ra,0x0
    8000675a:	e18080e7          	jalr	-488(ra) # 8000656e <statscopyin>
    8000675e:	00021797          	auipc	a5,0x21
    80006762:	8aa7ad23          	sw	a0,-1862(a5) # 80027018 <stats+0x1018>
    80006766:	bf95                	j	800066da <statsread+0x30>
    stats.sz = 0;
    80006768:	00021797          	auipc	a5,0x21
    8000676c:	89878793          	addi	a5,a5,-1896 # 80027000 <stats+0x1000>
    80006770:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006774:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006778:	54fd                	li	s1,-1
    8000677a:	bf45                	j	8000672a <statsread+0x80>

000000008000677c <statsinit>:

void
statsinit(void)
{
    8000677c:	1141                	addi	sp,sp,-16
    8000677e:	e406                	sd	ra,8(sp)
    80006780:	e022                	sd	s0,0(sp)
    80006782:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006784:	00002597          	auipc	a1,0x2
    80006788:	0f458593          	addi	a1,a1,244 # 80008878 <syscalls+0x400>
    8000678c:	00020517          	auipc	a0,0x20
    80006790:	87450513          	addi	a0,a0,-1932 # 80026000 <stats>
    80006794:	ffffa097          	auipc	ra,0xffffa
    80006798:	3da080e7          	jalr	986(ra) # 80000b6e <initlock>

  devsw[STATS].read = statsread;
    8000679c:	0001b797          	auipc	a5,0x1b
    800067a0:	61478793          	addi	a5,a5,1556 # 80021db0 <devsw>
    800067a4:	00000717          	auipc	a4,0x0
    800067a8:	f0670713          	addi	a4,a4,-250 # 800066aa <statsread>
    800067ac:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800067ae:	00000717          	auipc	a4,0x0
    800067b2:	eee70713          	addi	a4,a4,-274 # 8000669c <statswrite>
    800067b6:	f798                	sd	a4,40(a5)
}
    800067b8:	60a2                	ld	ra,8(sp)
    800067ba:	6402                	ld	s0,0(sp)
    800067bc:	0141                	addi	sp,sp,16
    800067be:	8082                	ret

00000000800067c0 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800067c0:	1101                	addi	sp,sp,-32
    800067c2:	ec22                	sd	s0,24(sp)
    800067c4:	1000                	addi	s0,sp,32
    800067c6:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800067c8:	c299                	beqz	a3,800067ce <sprintint+0xe>
    800067ca:	0805c163          	bltz	a1,8000684c <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800067ce:	2581                	sext.w	a1,a1
    800067d0:	4301                	li	t1,0

  i = 0;
    800067d2:	fe040713          	addi	a4,s0,-32
    800067d6:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800067d8:	2601                	sext.w	a2,a2
    800067da:	00002697          	auipc	a3,0x2
    800067de:	0a668693          	addi	a3,a3,166 # 80008880 <digits>
    800067e2:	88aa                	mv	a7,a0
    800067e4:	2505                	addiw	a0,a0,1
    800067e6:	02c5f7bb          	remuw	a5,a1,a2
    800067ea:	1782                	slli	a5,a5,0x20
    800067ec:	9381                	srli	a5,a5,0x20
    800067ee:	97b6                	add	a5,a5,a3
    800067f0:	0007c783          	lbu	a5,0(a5)
    800067f4:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067f8:	0005879b          	sext.w	a5,a1
    800067fc:	02c5d5bb          	divuw	a1,a1,a2
    80006800:	0705                	addi	a4,a4,1
    80006802:	fec7f0e3          	bgeu	a5,a2,800067e2 <sprintint+0x22>

  if(sign)
    80006806:	00030b63          	beqz	t1,8000681c <sprintint+0x5c>
    buf[i++] = '-';
    8000680a:	ff040793          	addi	a5,s0,-16
    8000680e:	97aa                	add	a5,a5,a0
    80006810:	02d00713          	li	a4,45
    80006814:	fee78823          	sb	a4,-16(a5)
    80006818:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    8000681c:	02a05c63          	blez	a0,80006854 <sprintint+0x94>
    80006820:	fe040793          	addi	a5,s0,-32
    80006824:	00a78733          	add	a4,a5,a0
    80006828:	87c2                	mv	a5,a6
    8000682a:	0805                	addi	a6,a6,1
    8000682c:	fff5061b          	addiw	a2,a0,-1
    80006830:	1602                	slli	a2,a2,0x20
    80006832:	9201                	srli	a2,a2,0x20
    80006834:	9642                	add	a2,a2,a6
  *s = c;
    80006836:	fff74683          	lbu	a3,-1(a4)
    8000683a:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    8000683e:	177d                	addi	a4,a4,-1
    80006840:	0785                	addi	a5,a5,1
    80006842:	fec79ae3          	bne	a5,a2,80006836 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006846:	6462                	ld	s0,24(sp)
    80006848:	6105                	addi	sp,sp,32
    8000684a:	8082                	ret
    x = -xx;
    8000684c:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006850:	4305                	li	t1,1
    x = -xx;
    80006852:	b741                	j	800067d2 <sprintint+0x12>
  while(--i >= 0)
    80006854:	4501                	li	a0,0
    80006856:	bfc5                	j	80006846 <sprintint+0x86>

0000000080006858 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006858:	7135                	addi	sp,sp,-160
    8000685a:	f486                	sd	ra,104(sp)
    8000685c:	f0a2                	sd	s0,96(sp)
    8000685e:	eca6                	sd	s1,88(sp)
    80006860:	e8ca                	sd	s2,80(sp)
    80006862:	e4ce                	sd	s3,72(sp)
    80006864:	e0d2                	sd	s4,64(sp)
    80006866:	fc56                	sd	s5,56(sp)
    80006868:	f85a                	sd	s6,48(sp)
    8000686a:	f45e                	sd	s7,40(sp)
    8000686c:	f062                	sd	s8,32(sp)
    8000686e:	ec66                	sd	s9,24(sp)
    80006870:	e86a                	sd	s10,16(sp)
    80006872:	1880                	addi	s0,sp,112
    80006874:	e414                	sd	a3,8(s0)
    80006876:	e818                	sd	a4,16(s0)
    80006878:	ec1c                	sd	a5,24(s0)
    8000687a:	03043023          	sd	a6,32(s0)
    8000687e:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006882:	c61d                	beqz	a2,800068b0 <snprintf+0x58>
    80006884:	8baa                	mv	s7,a0
    80006886:	89ae                	mv	s3,a1
    80006888:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000688a:	00840793          	addi	a5,s0,8
    8000688e:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    80006892:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006894:	4901                	li	s2,0
    80006896:	02b05563          	blez	a1,800068c0 <snprintf+0x68>
    if(c != '%'){
    8000689a:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000689e:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800068a2:	02800d13          	li	s10,40
    switch(c){
    800068a6:	07800c93          	li	s9,120
    800068aa:	06400c13          	li	s8,100
    800068ae:	a01d                	j	800068d4 <snprintf+0x7c>
    panic("null fmt");
    800068b0:	00001517          	auipc	a0,0x1
    800068b4:	76850513          	addi	a0,a0,1896 # 80008018 <etext+0x18>
    800068b8:	ffffa097          	auipc	ra,0xffffa
    800068bc:	c8a080e7          	jalr	-886(ra) # 80000542 <panic>
  int off = 0;
    800068c0:	4481                	li	s1,0
    800068c2:	a86d                	j	8000697c <snprintf+0x124>
  *s = c;
    800068c4:	009b8733          	add	a4,s7,s1
    800068c8:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068cc:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068ce:	2905                	addiw	s2,s2,1
    800068d0:	0b34d663          	bge	s1,s3,8000697c <snprintf+0x124>
    800068d4:	012a07b3          	add	a5,s4,s2
    800068d8:	0007c783          	lbu	a5,0(a5)
    800068dc:	0007871b          	sext.w	a4,a5
    800068e0:	cfd1                	beqz	a5,8000697c <snprintf+0x124>
    if(c != '%'){
    800068e2:	ff5711e3          	bne	a4,s5,800068c4 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800068e6:	2905                	addiw	s2,s2,1
    800068e8:	012a07b3          	add	a5,s4,s2
    800068ec:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800068f0:	c7d1                	beqz	a5,8000697c <snprintf+0x124>
    switch(c){
    800068f2:	05678c63          	beq	a5,s6,8000694a <snprintf+0xf2>
    800068f6:	02fb6763          	bltu	s6,a5,80006924 <snprintf+0xcc>
    800068fa:	0b578663          	beq	a5,s5,800069a6 <snprintf+0x14e>
    800068fe:	0b879a63          	bne	a5,s8,800069b2 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006902:	f9843783          	ld	a5,-104(s0)
    80006906:	00878713          	addi	a4,a5,8
    8000690a:	f8e43c23          	sd	a4,-104(s0)
    8000690e:	4685                	li	a3,1
    80006910:	4629                	li	a2,10
    80006912:	438c                	lw	a1,0(a5)
    80006914:	009b8533          	add	a0,s7,s1
    80006918:	00000097          	auipc	ra,0x0
    8000691c:	ea8080e7          	jalr	-344(ra) # 800067c0 <sprintint>
    80006920:	9ca9                	addw	s1,s1,a0
      break;
    80006922:	b775                	j	800068ce <snprintf+0x76>
    switch(c){
    80006924:	09979763          	bne	a5,s9,800069b2 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006928:	f9843783          	ld	a5,-104(s0)
    8000692c:	00878713          	addi	a4,a5,8
    80006930:	f8e43c23          	sd	a4,-104(s0)
    80006934:	4685                	li	a3,1
    80006936:	4641                	li	a2,16
    80006938:	438c                	lw	a1,0(a5)
    8000693a:	009b8533          	add	a0,s7,s1
    8000693e:	00000097          	auipc	ra,0x0
    80006942:	e82080e7          	jalr	-382(ra) # 800067c0 <sprintint>
    80006946:	9ca9                	addw	s1,s1,a0
      break;
    80006948:	b759                	j	800068ce <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    8000694a:	f9843783          	ld	a5,-104(s0)
    8000694e:	00878713          	addi	a4,a5,8
    80006952:	f8e43c23          	sd	a4,-104(s0)
    80006956:	639c                	ld	a5,0(a5)
    80006958:	c3a9                	beqz	a5,8000699a <snprintf+0x142>
      for(; *s && off < sz; s++)
    8000695a:	0007c703          	lbu	a4,0(a5)
    8000695e:	db25                	beqz	a4,800068ce <snprintf+0x76>
    80006960:	0134de63          	bge	s1,s3,8000697c <snprintf+0x124>
    80006964:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006968:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    8000696c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000696e:	0785                	addi	a5,a5,1
    80006970:	0007c703          	lbu	a4,0(a5)
    80006974:	df29                	beqz	a4,800068ce <snprintf+0x76>
    80006976:	0685                	addi	a3,a3,1
    80006978:	fe9998e3          	bne	s3,s1,80006968 <snprintf+0x110>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    8000697c:	8526                	mv	a0,s1
    8000697e:	70a6                	ld	ra,104(sp)
    80006980:	7406                	ld	s0,96(sp)
    80006982:	64e6                	ld	s1,88(sp)
    80006984:	6946                	ld	s2,80(sp)
    80006986:	69a6                	ld	s3,72(sp)
    80006988:	6a06                	ld	s4,64(sp)
    8000698a:	7ae2                	ld	s5,56(sp)
    8000698c:	7b42                	ld	s6,48(sp)
    8000698e:	7ba2                	ld	s7,40(sp)
    80006990:	7c02                	ld	s8,32(sp)
    80006992:	6ce2                	ld	s9,24(sp)
    80006994:	6d42                	ld	s10,16(sp)
    80006996:	610d                	addi	sp,sp,160
    80006998:	8082                	ret
        s = "(null)";
    8000699a:	00001797          	auipc	a5,0x1
    8000699e:	67678793          	addi	a5,a5,1654 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    800069a2:	876a                	mv	a4,s10
    800069a4:	bf75                	j	80006960 <snprintf+0x108>
  *s = c;
    800069a6:	009b87b3          	add	a5,s7,s1
    800069aa:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800069ae:	2485                	addiw	s1,s1,1
      break;
    800069b0:	bf39                	j	800068ce <snprintf+0x76>
  *s = c;
    800069b2:	009b8733          	add	a4,s7,s1
    800069b6:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800069ba:	0014871b          	addiw	a4,s1,1
  *s = c;
    800069be:	975e                	add	a4,a4,s7
    800069c0:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069c4:	2489                	addiw	s1,s1,2
      break;
    800069c6:	b721                	j	800068ce <snprintf+0x76>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
