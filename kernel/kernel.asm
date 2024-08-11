
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
    80000060:	dd478793          	addi	a5,a5,-556 # 80005e30 <timervec>
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
    8000012a:	46a080e7          	jalr	1130(ra) # 80002590 <either_copyin>
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
    800001ce:	86a080e7          	jalr	-1942(ra) # 80001a34 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	106080e7          	jalr	262(ra) # 800022e0 <sleep>
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
    8000021a:	324080e7          	jalr	804(ra) # 8000253a <either_copyout>
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
    800002fa:	2f0080e7          	jalr	752(ra) # 800025e6 <procdump>
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
    8000044e:	016080e7          	jalr	22(ra) # 80002460 <wakeup>
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
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	73478793          	addi	a5,a5,1844 # 80021bb0 <devsw>
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
    800008a6:	bbe080e7          	jalr	-1090(ra) # 80002460 <wakeup>
    
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
    80000940:	9a4080e7          	jalr	-1628(ra) # 800022e0 <sleep>
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
    80000b9c:	e80080e7          	jalr	-384(ra) # 80001a18 <mycpu>
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
    80000bce:	e4e080e7          	jalr	-434(ra) # 80001a18 <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	e42080e7          	jalr	-446(ra) # 80001a18 <mycpu>
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
    80000bf2:	e2a080e7          	jalr	-470(ra) # 80001a18 <mycpu>
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
    80000c32:	dea080e7          	jalr	-534(ra) # 80001a18 <mycpu>
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
    80000c5e:	dbe080e7          	jalr	-578(ra) # 80001a18 <mycpu>
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
    80000eb4:	b58080e7          	jalr	-1192(ra) # 80001a08 <cpuid>
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
    80000ed0:	b3c080e7          	jalr	-1220(ra) # 80001a08 <cpuid>
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
    80000ef2:	936080e7          	jalr	-1738(ra) # 80002824 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	f7a080e7          	jalr	-134(ra) # 80005e70 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	0ec080e7          	jalr	236(ra) # 80001fea <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    statsinit();
    80000f0e:	00005097          	auipc	ra,0x5
    80000f12:	750080e7          	jalr	1872(ra) # 8000665e <statsinit>
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
    80000f6a:	a3a080e7          	jalr	-1478(ra) # 800019a0 <procinit>
    trapinit();      // trap vectors
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	88e080e7          	jalr	-1906(ra) # 800027fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	8ae080e7          	jalr	-1874(ra) # 80002824 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	edc080e7          	jalr	-292(ra) # 80005e5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	eea080e7          	jalr	-278(ra) # 80005e70 <plicinithart>
    binit();         // buffer cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	034080e7          	jalr	52(ra) # 80002fc2 <binit>
    iinit();         // inode cache
    80000f96:	00002097          	auipc	ra,0x2
    80000f9a:	6c4080e7          	jalr	1732(ra) # 8000365a <iinit>
    fileinit();      // file table
    80000f9e:	00003097          	auipc	ra,0x3
    80000fa2:	65e080e7          	jalr	1630(ra) # 800045fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa6:	00005097          	auipc	ra,0x5
    80000faa:	fd2080e7          	jalr	-46(ra) # 80005f78 <virtio_disk_init>
    userinit();      // first user process
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	e12080e7          	jalr	-494(ra) # 80001dc0 <userinit>
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
}

// kvmpa 将内核逻辑地址转换为物理地址（添加第一个参数 kernelpgtbl）
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
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c6:	c6bd                	beqz	a3,80001734 <copyout+0x6e>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8b2a                	mv	s6,a0
    800016e2:	8c2e                	mv	s8,a1
    800016e4:	8a32                	mv	s4,a2
    800016e6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016e8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ea:	6a85                	lui	s5,0x1
    800016ec:	a015                	j	80001710 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ee:	9562                	add	a0,a0,s8
    800016f0:	0004861b          	sext.w	a2,s1
    800016f4:	85d2                	mv	a1,s4
    800016f6:	41250533          	sub	a0,a0,s2
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	65c080e7          	jalr	1628(ra) # 80000d56 <memmove>

    len -= n;
    80001702:	409989b3          	sub	s3,s3,s1
    src += n;
    80001706:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001708:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170c:	02098263          	beqz	s3,80001730 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001710:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001714:	85ca                	mv	a1,s2
    80001716:	855a                	mv	a0,s6
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	978080e7          	jalr	-1672(ra) # 80001090 <walkaddr>
    if(pa0 == 0)
    80001720:	cd01                	beqz	a0,80001738 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001722:	418904b3          	sub	s1,s2,s8
    80001726:	94d6                	add	s1,s1,s5
    if(n > len)
    80001728:	fc99f3e3          	bgeu	s3,s1,800016ee <copyout+0x28>
    8000172c:	84ce                	mv	s1,s3
    8000172e:	b7c1                	j	800016ee <copyout+0x28>
  }
  return 0;
    80001730:	4501                	li	a0,0
    80001732:	a021                	j	8000173a <copyout+0x74>
    80001734:	4501                	li	a0,0
}
    80001736:	8082                	ret
      return -1;
    80001738:	557d                	li	a0,-1
}
    8000173a:	60a6                	ld	ra,72(sp)
    8000173c:	6406                	ld	s0,64(sp)
    8000173e:	74e2                	ld	s1,56(sp)
    80001740:	7942                	ld	s2,48(sp)
    80001742:	79a2                	ld	s3,40(sp)
    80001744:	7a02                	ld	s4,32(sp)
    80001746:	6ae2                	ld	s5,24(sp)
    80001748:	6b42                	ld	s6,16(sp)
    8000174a:	6ba2                	ld	s7,8(sp)
    8000174c:	6c02                	ld	s8,0(sp)
    8000174e:	6161                	addi	sp,sp,80
    80001750:	8082                	ret

0000000080001752 <kvmcopymappings>:
// 将 src 页表的一部分页映射关系拷贝到 dst 页表中。
// 只拷贝页表项，不拷贝实际的物理页内存。
// 成功返回0，失败返回 -1
int
kvmcopymappings(pagetable_t src, pagetable_t dst, uint64 start, uint64 sz)
{
    80001752:	7139                	addi	sp,sp,-64
    80001754:	fc06                	sd	ra,56(sp)
    80001756:	f822                	sd	s0,48(sp)
    80001758:	f426                	sd	s1,40(sp)
    8000175a:	f04a                	sd	s2,32(sp)
    8000175c:	ec4e                	sd	s3,24(sp)
    8000175e:	e852                	sd	s4,16(sp)
    80001760:	e456                	sd	s5,8(sp)
    80001762:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  // PGROUNDUP: prevent re-mapping already mapped pages (eg. when doing growproc)
  for(i = PGROUNDUP(start); i < start + sz; i += PGSIZE){
    80001764:	6a05                	lui	s4,0x1
    80001766:	1a7d                	addi	s4,s4,-1
    80001768:	9a32                	add	s4,s4,a2
    8000176a:	77fd                	lui	a5,0xfffff
    8000176c:	00fa7a33          	and	s4,s4,a5
    80001770:	00d60933          	add	s2,a2,a3
    80001774:	072a7963          	bgeu	s4,s2,800017e6 <kvmcopymappings+0x94>
    80001778:	89aa                	mv	s3,a0
    8000177a:	8aae                	mv	s5,a1
    8000177c:	84d2                	mv	s1,s4
    8000177e:	a029                	j	80001788 <kvmcopymappings+0x36>
    80001780:	6785                	lui	a5,0x1
    80001782:	94be                	add	s1,s1,a5
    80001784:	0524f763          	bgeu	s1,s2,800017d2 <kvmcopymappings+0x80>
    if((pte = walk(src, i, 0)) == 0)
    80001788:	4601                	li	a2,0
    8000178a:	85a6                	mv	a1,s1
    8000178c:	854e                	mv	a0,s3
    8000178e:	00000097          	auipc	ra,0x0
    80001792:	85c080e7          	jalr	-1956(ra) # 80000fea <walk>
    80001796:	d56d                	beqz	a0,80001780 <kvmcopymappings+0x2e>
      continue;
      //panic("kvmcopymappings: pte should exist");
    if((*pte & PTE_V) == 0)
    80001798:	6118                	ld	a4,0(a0)
    8000179a:	00177793          	andi	a5,a4,1
    8000179e:	d3ed                	beqz	a5,80001780 <kvmcopymappings+0x2e>
      continue;
      //panic("kvmcopymappings: page not present");
    pa = PTE2PA(*pte);
    800017a0:	00a75693          	srli	a3,a4,0xa
    // `& ~PTE_U` 表示将该页的权限设置为非用户页
    // 必须设置该权限，RISC-V 中内核是无法直接访问用户页的。
    flags = PTE_FLAGS(*pte) & ~PTE_U;
    if(mappages(dst, i, PGSIZE, pa, flags) != 0){
    800017a4:	3ef77713          	andi	a4,a4,1007
    800017a8:	06b2                	slli	a3,a3,0xc
    800017aa:	6605                	lui	a2,0x1
    800017ac:	85a6                	mv	a1,s1
    800017ae:	8556                	mv	a0,s5
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	978080e7          	jalr	-1672(ra) # 80001128 <mappages>
    800017b8:	d561                	beqz	a0,80001780 <kvmcopymappings+0x2e>
  return 0;

 err:
  // thanks @hdrkna for pointing out a mistake here.
  // original code incorrectly starts unmapping from 0 instead of PGROUNDUP(start)
  uvmunmap(dst, PGROUNDUP(start), (i - PGROUNDUP(start)) / PGSIZE, 0);
    800017ba:	41448633          	sub	a2,s1,s4
    800017be:	4681                	li	a3,0
    800017c0:	8231                	srli	a2,a2,0xc
    800017c2:	85d2                	mv	a1,s4
    800017c4:	8556                	mv	a0,s5
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	b3e080e7          	jalr	-1218(ra) # 80001304 <uvmunmap>
  return -1;
    800017ce:	557d                	li	a0,-1
    800017d0:	a011                	j	800017d4 <kvmcopymappings+0x82>
  return 0;
    800017d2:	4501                	li	a0,0
}
    800017d4:	70e2                	ld	ra,56(sp)
    800017d6:	7442                	ld	s0,48(sp)
    800017d8:	74a2                	ld	s1,40(sp)
    800017da:	7902                	ld	s2,32(sp)
    800017dc:	69e2                	ld	s3,24(sp)
    800017de:	6a42                	ld	s4,16(sp)
    800017e0:	6aa2                	ld	s5,8(sp)
    800017e2:	6121                	addi	sp,sp,64
    800017e4:	8082                	ret
  return 0;
    800017e6:	4501                	li	a0,0
    800017e8:	b7f5                	j	800017d4 <kvmcopymappings+0x82>

00000000800017ea <kvmdealloc>:

// 与 uvmdealloc 功能类似，将程序内存从 oldsz 缩减到 newsz。但区别在于不释放实际内存
// 用于内核页表内程序内存映射与用户页表程序内存映射之间的同步
uint64
kvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800017ea:	1101                	addi	sp,sp,-32
    800017ec:	ec06                	sd	ra,24(sp)
    800017ee:	e822                	sd	s0,16(sp)
    800017f0:	e426                	sd	s1,8(sp)
    800017f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017f6:	00b67d63          	bgeu	a2,a1,80001810 <kvmdealloc+0x26>
    800017fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017fc:	6785                	lui	a5,0x1
    800017fe:	17fd                	addi	a5,a5,-1
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	767d                	lui	a2,0xfffff
    80001806:	8f71                	and	a4,a4,a2
    80001808:	97ae                	add	a5,a5,a1
    8000180a:	8ff1                	and	a5,a5,a2
    8000180c:	00f76863          	bltu	a4,a5,8000181c <kvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
  }

  return newsz;
}
    80001810:	8526                	mv	a0,s1
    80001812:	60e2                	ld	ra,24(sp)
    80001814:	6442                	ld	s0,16(sp)
    80001816:	64a2                	ld	s1,8(sp)
    80001818:	6105                	addi	sp,sp,32
    8000181a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000181c:	8f99                	sub	a5,a5,a4
    8000181e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
    80001820:	4681                	li	a3,0
    80001822:	0007861b          	sext.w	a2,a5
    80001826:	85ba                	mv	a1,a4
    80001828:	00000097          	auipc	ra,0x0
    8000182c:	adc080e7          	jalr	-1316(ra) # 80001304 <uvmunmap>
    80001830:	b7c5                	j	80001810 <kvmdealloc+0x26>

0000000080001832 <copyin>:

// 将 copyin、copyinstr 改为转发到新函数
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001832:	1141                	addi	sp,sp,-16
    80001834:	e406                	sd	ra,8(sp)
    80001836:	e022                	sd	s0,0(sp)
    80001838:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    8000183a:	00005097          	auipc	ra,0x5
    8000183e:	c30080e7          	jalr	-976(ra) # 8000646a <copyin_new>
}
    80001842:	60a2                	ld	ra,8(sp)
    80001844:	6402                	ld	s0,0(sp)
    80001846:	0141                	addi	sp,sp,16
    80001848:	8082                	ret

000000008000184a <copyinstr>:

int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    8000184a:	1141                	addi	sp,sp,-16
    8000184c:	e406                	sd	ra,8(sp)
    8000184e:	e022                	sd	s0,0(sp)
    80001850:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    80001852:	00005097          	auipc	ra,0x5
    80001856:	ca0080e7          	jalr	-864(ra) # 800064f2 <copyinstr_new>
}
    8000185a:	60a2                	ld	ra,8(sp)
    8000185c:	6402                	ld	s0,0(sp)
    8000185e:	0141                	addi	sp,sp,16
    80001860:	8082                	ret

0000000080001862 <pgtblprint>:

// kernel/vm.c
int pgtblprint(pagetable_t pagetable, int depth) {
    80001862:	7159                	addi	sp,sp,-112
    80001864:	f486                	sd	ra,104(sp)
    80001866:	f0a2                	sd	s0,96(sp)
    80001868:	eca6                	sd	s1,88(sp)
    8000186a:	e8ca                	sd	s2,80(sp)
    8000186c:	e4ce                	sd	s3,72(sp)
    8000186e:	e0d2                	sd	s4,64(sp)
    80001870:	fc56                	sd	s5,56(sp)
    80001872:	f85a                	sd	s6,48(sp)
    80001874:	f45e                	sd	s7,40(sp)
    80001876:	f062                	sd	s8,32(sp)
    80001878:	ec66                	sd	s9,24(sp)
    8000187a:	e86a                	sd	s10,16(sp)
    8000187c:	e46e                	sd	s11,8(sp)
    8000187e:	1880                	addi	s0,sp,112
    80001880:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001882:	89aa                	mv	s3,a0
    80001884:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) { // 如果页表项有效
      // 按格式打印页表项
      printf("..");
    80001886:	00007c97          	auipc	s9,0x7
    8000188a:	8cac8c93          	addi	s9,s9,-1846 # 80008150 <digits+0x120>
      for(int j=0;j<depth;j++) {
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    8000188e:	00007c17          	auipc	s8,0x7
    80001892:	8d2c0c13          	addi	s8,s8,-1838 # 80008160 <digits+0x130>

      // 如果该节点不是叶节点，递归打印其子节点。
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
        // this PTE points to a lower-level page table.
        uint64 child = PTE2PA(pte);
        pgtblprint((pagetable_t)child,depth+1);
    80001896:	00158d9b          	addiw	s11,a1,1
      for(int j=0;j<depth;j++) {
    8000189a:	4d01                	li	s10,0
        printf(" ..");
    8000189c:	00007b17          	auipc	s6,0x7
    800018a0:	8bcb0b13          	addi	s6,s6,-1860 # 80008158 <digits+0x128>
  for(int i = 0; i < 512; i++){
    800018a4:	20000b93          	li	s7,512
    800018a8:	a029                	j	800018b2 <pgtblprint+0x50>
    800018aa:	2905                	addiw	s2,s2,1
    800018ac:	09a1                	addi	s3,s3,8
    800018ae:	05790d63          	beq	s2,s7,80001908 <pgtblprint+0xa6>
    pte_t pte = pagetable[i];
    800018b2:	0009ba03          	ld	s4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if(pte & PTE_V) { // 如果页表项有效
    800018b6:	001a7793          	andi	a5,s4,1
    800018ba:	dbe5                	beqz	a5,800018aa <pgtblprint+0x48>
      printf("..");
    800018bc:	8566                	mv	a0,s9
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	cce080e7          	jalr	-818(ra) # 8000058c <printf>
      for(int j=0;j<depth;j++) {
    800018c6:	01505b63          	blez	s5,800018dc <pgtblprint+0x7a>
    800018ca:	84ea                	mv	s1,s10
        printf(" ..");
    800018cc:	855a                	mv	a0,s6
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	cbe080e7          	jalr	-834(ra) # 8000058c <printf>
      for(int j=0;j<depth;j++) {
    800018d6:	2485                	addiw	s1,s1,1
    800018d8:	fe9a9ae3          	bne	s5,s1,800018cc <pgtblprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    800018dc:	00aa5493          	srli	s1,s4,0xa
    800018e0:	04b2                	slli	s1,s1,0xc
    800018e2:	86a6                	mv	a3,s1
    800018e4:	8652                	mv	a2,s4
    800018e6:	85ca                	mv	a1,s2
    800018e8:	8562                	mv	a0,s8
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	ca2080e7          	jalr	-862(ra) # 8000058c <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018f2:	00ea7a13          	andi	s4,s4,14
    800018f6:	fa0a1ae3          	bnez	s4,800018aa <pgtblprint+0x48>
        pgtblprint((pagetable_t)child,depth+1);
    800018fa:	85ee                	mv	a1,s11
    800018fc:	8526                	mv	a0,s1
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	f64080e7          	jalr	-156(ra) # 80001862 <pgtblprint>
    80001906:	b755                	j	800018aa <pgtblprint+0x48>
      }
    }
  }
  return 0;
}
    80001908:	4501                	li	a0,0
    8000190a:	70a6                	ld	ra,104(sp)
    8000190c:	7406                	ld	s0,96(sp)
    8000190e:	64e6                	ld	s1,88(sp)
    80001910:	6946                	ld	s2,80(sp)
    80001912:	69a6                	ld	s3,72(sp)
    80001914:	6a06                	ld	s4,64(sp)
    80001916:	7ae2                	ld	s5,56(sp)
    80001918:	7b42                	ld	s6,48(sp)
    8000191a:	7ba2                	ld	s7,40(sp)
    8000191c:	7c02                	ld	s8,32(sp)
    8000191e:	6ce2                	ld	s9,24(sp)
    80001920:	6d42                	ld	s10,16(sp)
    80001922:	6da2                	ld	s11,8(sp)
    80001924:	6165                	addi	sp,sp,112
    80001926:	8082                	ret

0000000080001928 <vmprint>:

int vmprint(pagetable_t pagetable) {
    80001928:	1101                	addi	sp,sp,-32
    8000192a:	ec06                	sd	ra,24(sp)
    8000192c:	e822                	sd	s0,16(sp)
    8000192e:	e426                	sd	s1,8(sp)
    80001930:	1000                	addi	s0,sp,32
    80001932:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001934:	85aa                	mv	a1,a0
    80001936:	00007517          	auipc	a0,0x7
    8000193a:	84250513          	addi	a0,a0,-1982 # 80008178 <digits+0x148>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	c4e080e7          	jalr	-946(ra) # 8000058c <printf>
  return pgtblprint(pagetable, 0);
    80001946:	4581                	li	a1,0
    80001948:	8526                	mv	a0,s1
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	f18080e7          	jalr	-232(ra) # 80001862 <pgtblprint>
    80001952:	60e2                	ld	ra,24(sp)
    80001954:	6442                	ld	s0,16(sp)
    80001956:	64a2                	ld	s1,8(sp)
    80001958:	6105                	addi	sp,sp,32
    8000195a:	8082                	ret

000000008000195c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000195c:	1101                	addi	sp,sp,-32
    8000195e:	ec06                	sd	ra,24(sp)
    80001960:	e822                	sd	s0,16(sp)
    80001962:	e426                	sd	s1,8(sp)
    80001964:	1000                	addi	s0,sp,32
    80001966:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	21c080e7          	jalr	540(ra) # 80000b84 <holding>
    80001970:	c909                	beqz	a0,80001982 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001972:	749c                	ld	a5,40(s1)
    80001974:	00978f63          	beq	a5,s1,80001992 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001978:	60e2                	ld	ra,24(sp)
    8000197a:	6442                	ld	s0,16(sp)
    8000197c:	64a2                	ld	s1,8(sp)
    8000197e:	6105                	addi	sp,sp,32
    80001980:	8082                	ret
    panic("wakeup1");
    80001982:	00007517          	auipc	a0,0x7
    80001986:	80650513          	addi	a0,a0,-2042 # 80008188 <digits+0x158>
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	bb8080e7          	jalr	-1096(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001992:	4c98                	lw	a4,24(s1)
    80001994:	4785                	li	a5,1
    80001996:	fef711e3          	bne	a4,a5,80001978 <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000199a:	4789                	li	a5,2
    8000199c:	cc9c                	sw	a5,24(s1)
}
    8000199e:	bfe9                	j	80001978 <wakeup1+0x1c>

00000000800019a0 <procinit>:
{
    800019a0:	7179                	addi	sp,sp,-48
    800019a2:	f406                	sd	ra,40(sp)
    800019a4:	f022                	sd	s0,32(sp)
    800019a6:	ec26                	sd	s1,24(sp)
    800019a8:	e84a                	sd	s2,16(sp)
    800019aa:	e44e                	sd	s3,8(sp)
    800019ac:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    800019ae:	00006597          	auipc	a1,0x6
    800019b2:	7e258593          	addi	a1,a1,2018 # 80008190 <digits+0x160>
    800019b6:	00010517          	auipc	a0,0x10
    800019ba:	f9a50513          	addi	a0,a0,-102 # 80011950 <pid_lock>
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	1b0080e7          	jalr	432(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	00010497          	auipc	s1,0x10
    800019ca:	3a248493          	addi	s1,s1,930 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019ce:	00006997          	auipc	s3,0x6
    800019d2:	7ca98993          	addi	s3,s3,1994 # 80008198 <digits+0x168>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d6:	00016917          	auipc	s2,0x16
    800019da:	f9290913          	addi	s2,s2,-110 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    800019de:	85ce                	mv	a1,s3
    800019e0:	8526                	mv	a0,s1
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	18c080e7          	jalr	396(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ea:	17048493          	addi	s1,s1,368
    800019ee:	ff2498e3          	bne	s1,s2,800019de <procinit+0x3e>
  kvminithart();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	5d4080e7          	jalr	1492(ra) # 80000fc6 <kvminithart>
}
    800019fa:	70a2                	ld	ra,40(sp)
    800019fc:	7402                	ld	s0,32(sp)
    800019fe:	64e2                	ld	s1,24(sp)
    80001a00:	6942                	ld	s2,16(sp)
    80001a02:	69a2                	ld	s3,8(sp)
    80001a04:	6145                	addi	sp,sp,48
    80001a06:	8082                	ret

0000000080001a08 <cpuid>:
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0e:	8512                	mv	a0,tp
}
    80001a10:	2501                	sext.w	a0,a0
    80001a12:	6422                	ld	s0,8(sp)
    80001a14:	0141                	addi	sp,sp,16
    80001a16:	8082                	ret

0000000080001a18 <mycpu>:
mycpu(void) {
    80001a18:	1141                	addi	sp,sp,-16
    80001a1a:	e422                	sd	s0,8(sp)
    80001a1c:	0800                	addi	s0,sp,16
    80001a1e:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a20:	2781                	sext.w	a5,a5
    80001a22:	079e                	slli	a5,a5,0x7
}
    80001a24:	00010517          	auipc	a0,0x10
    80001a28:	f4450513          	addi	a0,a0,-188 # 80011968 <cpus>
    80001a2c:	953e                	add	a0,a0,a5
    80001a2e:	6422                	ld	s0,8(sp)
    80001a30:	0141                	addi	sp,sp,16
    80001a32:	8082                	ret

0000000080001a34 <myproc>:
myproc(void) {
    80001a34:	1101                	addi	sp,sp,-32
    80001a36:	ec06                	sd	ra,24(sp)
    80001a38:	e822                	sd	s0,16(sp)
    80001a3a:	e426                	sd	s1,8(sp)
    80001a3c:	1000                	addi	s0,sp,32
  push_off();
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	174080e7          	jalr	372(ra) # 80000bb2 <push_off>
    80001a46:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a48:	2781                	sext.w	a5,a5
    80001a4a:	079e                	slli	a5,a5,0x7
    80001a4c:	00010717          	auipc	a4,0x10
    80001a50:	f0470713          	addi	a4,a4,-252 # 80011950 <pid_lock>
    80001a54:	97ba                	add	a5,a5,a4
    80001a56:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	1fa080e7          	jalr	506(ra) # 80000c52 <pop_off>
}
    80001a60:	8526                	mv	a0,s1
    80001a62:	60e2                	ld	ra,24(sp)
    80001a64:	6442                	ld	s0,16(sp)
    80001a66:	64a2                	ld	s1,8(sp)
    80001a68:	6105                	addi	sp,sp,32
    80001a6a:	8082                	ret

0000000080001a6c <forkret>:
{
    80001a6c:	1141                	addi	sp,sp,-16
    80001a6e:	e406                	sd	ra,8(sp)
    80001a70:	e022                	sd	s0,0(sp)
    80001a72:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a74:	00000097          	auipc	ra,0x0
    80001a78:	fc0080e7          	jalr	-64(ra) # 80001a34 <myproc>
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	236080e7          	jalr	566(ra) # 80000cb2 <release>
  if (first) {
    80001a84:	00007797          	auipc	a5,0x7
    80001a88:	dcc7a783          	lw	a5,-564(a5) # 80008850 <first.1>
    80001a8c:	eb89                	bnez	a5,80001a9e <forkret+0x32>
  usertrapret();
    80001a8e:	00001097          	auipc	ra,0x1
    80001a92:	dae080e7          	jalr	-594(ra) # 8000283c <usertrapret>
}
    80001a96:	60a2                	ld	ra,8(sp)
    80001a98:	6402                	ld	s0,0(sp)
    80001a9a:	0141                	addi	sp,sp,16
    80001a9c:	8082                	ret
    first = 0;
    80001a9e:	00007797          	auipc	a5,0x7
    80001aa2:	da07a923          	sw	zero,-590(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001aa6:	4505                	li	a0,1
    80001aa8:	00002097          	auipc	ra,0x2
    80001aac:	b32080e7          	jalr	-1230(ra) # 800035da <fsinit>
    80001ab0:	bff9                	j	80001a8e <forkret+0x22>

0000000080001ab2 <allocpid>:
allocpid() {
    80001ab2:	1101                	addi	sp,sp,-32
    80001ab4:	ec06                	sd	ra,24(sp)
    80001ab6:	e822                	sd	s0,16(sp)
    80001ab8:	e426                	sd	s1,8(sp)
    80001aba:	e04a                	sd	s2,0(sp)
    80001abc:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001abe:	00010917          	auipc	s2,0x10
    80001ac2:	e9290913          	addi	s2,s2,-366 # 80011950 <pid_lock>
    80001ac6:	854a                	mv	a0,s2
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	136080e7          	jalr	310(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001ad0:	00007797          	auipc	a5,0x7
    80001ad4:	d8478793          	addi	a5,a5,-636 # 80008854 <nextpid>
    80001ad8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ada:	0014871b          	addiw	a4,s1,1
    80001ade:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae0:	854a                	mv	a0,s2
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	1d0080e7          	jalr	464(ra) # 80000cb2 <release>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret

0000000080001af8 <kvm_free_kernelpgtbl>:
{
    80001af8:	7179                	addi	sp,sp,-48
    80001afa:	f406                	sd	ra,40(sp)
    80001afc:	f022                	sd	s0,32(sp)
    80001afe:	ec26                	sd	s1,24(sp)
    80001b00:	e84a                	sd	s2,16(sp)
    80001b02:	e44e                	sd	s3,8(sp)
    80001b04:	e052                	sd	s4,0(sp)
    80001b06:	1800                	addi	s0,sp,48
    80001b08:	8a2a                	mv	s4,a0
  for(int i = 0; i < 512; i++){
    80001b0a:	84aa                	mv	s1,a0
    80001b0c:	6905                	lui	s2,0x1
    80001b0e:	992a                	add	s2,s2,a0
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    80001b10:	4985                	li	s3,1
    80001b12:	a021                	j	80001b1a <kvm_free_kernelpgtbl+0x22>
  for(int i = 0; i < 512; i++){
    80001b14:	04a1                	addi	s1,s1,8
    80001b16:	03248063          	beq	s1,s2,80001b36 <kvm_free_kernelpgtbl+0x3e>
    pte_t pte = pagetable[i];
    80001b1a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    80001b1c:	00f57793          	andi	a5,a0,15
    80001b20:	ff379ae3          	bne	a5,s3,80001b14 <kvm_free_kernelpgtbl+0x1c>
    uint64 child = PTE2PA(pte);
    80001b24:	8129                	srli	a0,a0,0xa
      kvm_free_kernelpgtbl((pagetable_t)child);
    80001b26:	0532                	slli	a0,a0,0xc
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	fd0080e7          	jalr	-48(ra) # 80001af8 <kvm_free_kernelpgtbl>
      pagetable[i] = 0;
    80001b30:	0004b023          	sd	zero,0(s1)
    80001b34:	b7c5                	j	80001b14 <kvm_free_kernelpgtbl+0x1c>
  kfree((void*)pagetable); // 释放当前级别页表所占用空间
    80001b36:	8552                	mv	a0,s4
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	eda080e7          	jalr	-294(ra) # 80000a12 <kfree>
}
    80001b40:	70a2                	ld	ra,40(sp)
    80001b42:	7402                	ld	s0,32(sp)
    80001b44:	64e2                	ld	s1,24(sp)
    80001b46:	6942                	ld	s2,16(sp)
    80001b48:	69a2                	ld	s3,8(sp)
    80001b4a:	6a02                	ld	s4,0(sp)
    80001b4c:	6145                	addi	sp,sp,48
    80001b4e:	8082                	ret

0000000080001b50 <proc_pagetable>:
{
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	e04a                	sd	s2,0(sp)
    80001b5a:	1000                	addi	s0,sp,32
    80001b5c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	84c080e7          	jalr	-1972(ra) # 800013aa <uvmcreate>
    80001b66:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b68:	c121                	beqz	a0,80001ba8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b6a:	4729                	li	a4,10
    80001b6c:	00005697          	auipc	a3,0x5
    80001b70:	49468693          	addi	a3,a3,1172 # 80007000 <_trampoline>
    80001b74:	6605                	lui	a2,0x1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	5aa080e7          	jalr	1450(ra) # 80001128 <mappages>
    80001b86:	02054863          	bltz	a0,80001bb6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b8a:	4719                	li	a4,6
    80001b8c:	06093683          	ld	a3,96(s2) # 1060 <_entry-0x7fffefa0>
    80001b90:	6605                	lui	a2,0x1
    80001b92:	020005b7          	lui	a1,0x2000
    80001b96:	15fd                	addi	a1,a1,-1
    80001b98:	05b6                	slli	a1,a1,0xd
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	58c080e7          	jalr	1420(ra) # 80001128 <mappages>
    80001ba4:	02054163          	bltz	a0,80001bc6 <proc_pagetable+0x76>
}
    80001ba8:	8526                	mv	a0,s1
    80001baa:	60e2                	ld	ra,24(sp)
    80001bac:	6442                	ld	s0,16(sp)
    80001bae:	64a2                	ld	s1,8(sp)
    80001bb0:	6902                	ld	s2,0(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret
    uvmfree(pagetable, 0);
    80001bb6:	4581                	li	a1,0
    80001bb8:	8526                	mv	a0,s1
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	9ec080e7          	jalr	-1556(ra) # 800015a6 <uvmfree>
    return 0;
    80001bc2:	4481                	li	s1,0
    80001bc4:	b7d5                	j	80001ba8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc6:	4681                	li	a3,0
    80001bc8:	4605                	li	a2,1
    80001bca:	040005b7          	lui	a1,0x4000
    80001bce:	15fd                	addi	a1,a1,-1
    80001bd0:	05b2                	slli	a1,a1,0xc
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	730080e7          	jalr	1840(ra) # 80001304 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bdc:	4581                	li	a1,0
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	9c6080e7          	jalr	-1594(ra) # 800015a6 <uvmfree>
    return 0;
    80001be8:	4481                	li	s1,0
    80001bea:	bf7d                	j	80001ba8 <proc_pagetable+0x58>

0000000080001bec <proc_freepagetable>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	e04a                	sd	s2,0(sp)
    80001bf6:	1000                	addi	s0,sp,32
    80001bf8:	84aa                	mv	s1,a0
    80001bfa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfc:	4681                	li	a3,0
    80001bfe:	4605                	li	a2,1
    80001c00:	040005b7          	lui	a1,0x4000
    80001c04:	15fd                	addi	a1,a1,-1
    80001c06:	05b2                	slli	a1,a1,0xc
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	6fc080e7          	jalr	1788(ra) # 80001304 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c10:	4681                	li	a3,0
    80001c12:	4605                	li	a2,1
    80001c14:	020005b7          	lui	a1,0x2000
    80001c18:	15fd                	addi	a1,a1,-1
    80001c1a:	05b6                	slli	a1,a1,0xd
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	6e6080e7          	jalr	1766(ra) # 80001304 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c26:	85ca                	mv	a1,s2
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	97c080e7          	jalr	-1668(ra) # 800015a6 <uvmfree>
}
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret

0000000080001c3e <freeproc>:
{
    80001c3e:	1101                	addi	sp,sp,-32
    80001c40:	ec06                	sd	ra,24(sp)
    80001c42:	e822                	sd	s0,16(sp)
    80001c44:	e426                	sd	s1,8(sp)
    80001c46:	1000                	addi	s0,sp,32
    80001c48:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c4a:	7128                	ld	a0,96(a0)
    80001c4c:	c509                	beqz	a0,80001c56 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	dc4080e7          	jalr	-572(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001c56:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001c5a:	68a8                	ld	a0,80(s1)
    80001c5c:	c511                	beqz	a0,80001c68 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c5e:	64ac                	ld	a1,72(s1)
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f8c080e7          	jalr	-116(ra) # 80001bec <proc_freepagetable>
  p->pagetable = 0;
    80001c68:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c6c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c70:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c74:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c78:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c7c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c80:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c84:	0204aa23          	sw	zero,52(s1)
  void *kstack_pa = (void *)kvmpa(p->kernelpgtbl, p->kstack);
    80001c88:	60ac                	ld	a1,64(s1)
    80001c8a:	6ca8                	ld	a0,88(s1)
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	446080e7          	jalr	1094(ra) # 800010d2 <kvmpa>
  kfree(kstack_pa);
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	d7e080e7          	jalr	-642(ra) # 80000a12 <kfree>
  p->kstack = 0;
    80001c9c:	0404b023          	sd	zero,64(s1)
  kvm_free_kernelpgtbl(p->kernelpgtbl);
    80001ca0:	6ca8                	ld	a0,88(s1)
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	e56080e7          	jalr	-426(ra) # 80001af8 <kvm_free_kernelpgtbl>
  p->kernelpgtbl = 0;
    80001caa:	0404bc23          	sd	zero,88(s1)
  p->state = UNUSED;
    80001cae:	0004ac23          	sw	zero,24(s1)
}
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret

0000000080001cbc <allocproc>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	e04a                	sd	s2,0(sp)
    80001cc6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc8:	00010497          	auipc	s1,0x10
    80001ccc:	0a048493          	addi	s1,s1,160 # 80011d68 <proc>
    80001cd0:	00016917          	auipc	s2,0x16
    80001cd4:	c9890913          	addi	s2,s2,-872 # 80017968 <tickslock>
    acquire(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	f24080e7          	jalr	-220(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001ce2:	4c9c                	lw	a5,24(s1)
    80001ce4:	cf81                	beqz	a5,80001cfc <allocproc+0x40>
      release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	fca080e7          	jalr	-54(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf0:	17048493          	addi	s1,s1,368
    80001cf4:	ff2492e3          	bne	s1,s2,80001cd8 <allocproc+0x1c>
  return 0;
    80001cf8:	4481                	li	s1,0
    80001cfa:	a049                	j	80001d7c <allocproc+0xc0>
  p->pid = allocpid();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	db6080e7          	jalr	-586(ra) # 80001ab2 <allocpid>
    80001d04:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	e08080e7          	jalr	-504(ra) # 80000b0e <kalloc>
    80001d0e:	892a                	mv	s2,a0
    80001d10:	f0a8                	sd	a0,96(s1)
    80001d12:	cd25                	beqz	a0,80001d8a <allocproc+0xce>
  p->pagetable = proc_pagetable(p);
    80001d14:	8526                	mv	a0,s1
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	e3a080e7          	jalr	-454(ra) # 80001b50 <proc_pagetable>
    80001d1e:	892a                	mv	s2,a0
    80001d20:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d22:	c93d                	beqz	a0,80001d98 <allocproc+0xdc>
  p->kernelpgtbl = kvminit_newpgtbl();
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	576080e7          	jalr	1398(ra) # 8000129a <kvminit_newpgtbl>
    80001d2c:	eca8                	sd	a0,88(s1)
  char *pa = kalloc();
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	de0080e7          	jalr	-544(ra) # 80000b0e <kalloc>
    80001d36:	862a                	mv	a2,a0
  if(pa == 0)
    80001d38:	cd25                	beqz	a0,80001db0 <allocproc+0xf4>
  kvmmap(p->kernelpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d3a:	4719                	li	a4,6
    80001d3c:	6685                	lui	a3,0x1
    80001d3e:	04000937          	lui	s2,0x4000
    80001d42:	1975                	addi	s2,s2,-3
    80001d44:	00c91593          	slli	a1,s2,0xc
    80001d48:	6ca8                	ld	a0,88(s1)
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	46c080e7          	jalr	1132(ra) # 800011b6 <kvmmap>
  p->kstack = va; // 记录内核栈的逻辑地址，其实已经是固定的了，依然这样记录是为了避免需要修改其他部分 xv6 代码
    80001d52:	0932                	slli	s2,s2,0xc
    80001d54:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001d58:	07000613          	li	a2,112
    80001d5c:	4581                	li	a1,0
    80001d5e:	06848513          	addi	a0,s1,104
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f98080e7          	jalr	-104(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001d6a:	00000797          	auipc	a5,0x0
    80001d6e:	d0278793          	addi	a5,a5,-766 # 80001a6c <forkret>
    80001d72:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d74:	60bc                	ld	a5,64(s1)
    80001d76:	6705                	lui	a4,0x1
    80001d78:	97ba                	add	a5,a5,a4
    80001d7a:	f8bc                	sd	a5,112(s1)
}
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    release(&p->lock);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	f26080e7          	jalr	-218(ra) # 80000cb2 <release>
    return 0;
    80001d94:	84ca                	mv	s1,s2
    80001d96:	b7dd                	j	80001d7c <allocproc+0xc0>
    freeproc(p);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	ea4080e7          	jalr	-348(ra) # 80001c3e <freeproc>
    release(&p->lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	f0e080e7          	jalr	-242(ra) # 80000cb2 <release>
    return 0;
    80001dac:	84ca                	mv	s1,s2
    80001dae:	b7f9                	j	80001d7c <allocproc+0xc0>
    panic("kalloc");
    80001db0:	00006517          	auipc	a0,0x6
    80001db4:	3f050513          	addi	a0,a0,1008 # 800081a0 <digits+0x170>
    80001db8:	ffffe097          	auipc	ra,0xffffe
    80001dbc:	78a080e7          	jalr	1930(ra) # 80000542 <panic>

0000000080001dc0 <userinit>:
{
    80001dc0:	1101                	addi	sp,sp,-32
    80001dc2:	ec06                	sd	ra,24(sp)
    80001dc4:	e822                	sd	s0,16(sp)
    80001dc6:	e426                	sd	s1,8(sp)
    80001dc8:	e04a                	sd	s2,0(sp)
    80001dca:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	ef0080e7          	jalr	-272(ra) # 80001cbc <allocproc>
    80001dd4:	84aa                	mv	s1,a0
  initproc = p;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	24a7b123          	sd	a0,578(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dde:	03400613          	li	a2,52
    80001de2:	00007597          	auipc	a1,0x7
    80001de6:	a7e58593          	addi	a1,a1,-1410 # 80008860 <initcode>
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	5ec080e7          	jalr	1516(ra) # 800013d8 <uvminit>
  p->sz = PGSIZE;
    80001df4:	6905                	lui	s2,0x1
    80001df6:	0524b423          	sd	s2,72(s1)
  kvmcopymappings(p->pagetable, p->kernelpgtbl, 0, p->sz); // 同步程序内存映射到进程内核页表中
    80001dfa:	6685                	lui	a3,0x1
    80001dfc:	4601                	li	a2,0
    80001dfe:	6cac                	ld	a1,88(s1)
    80001e00:	68a8                	ld	a0,80(s1)
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	950080e7          	jalr	-1712(ra) # 80001752 <kvmcopymappings>
  p->trapframe->epc = 0;      // user program counter
    80001e0a:	70bc                	ld	a5,96(s1)
    80001e0c:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e10:	70bc                	ld	a5,96(s1)
    80001e12:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e16:	4641                	li	a2,16
    80001e18:	00006597          	auipc	a1,0x6
    80001e1c:	39058593          	addi	a1,a1,912 # 800081a8 <digits+0x178>
    80001e20:	16048513          	addi	a0,s1,352
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	028080e7          	jalr	40(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001e2c:	00006517          	auipc	a0,0x6
    80001e30:	38c50513          	addi	a0,a0,908 # 800081b8 <digits+0x188>
    80001e34:	00002097          	auipc	ra,0x2
    80001e38:	1ce080e7          	jalr	462(ra) # 80004002 <namei>
    80001e3c:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e40:	4789                	li	a5,2
    80001e42:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e44:	8526                	mv	a0,s1
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e6c080e7          	jalr	-404(ra) # 80000cb2 <release>
}
    80001e4e:	60e2                	ld	ra,24(sp)
    80001e50:	6442                	ld	s0,16(sp)
    80001e52:	64a2                	ld	s1,8(sp)
    80001e54:	6902                	ld	s2,0(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret

0000000080001e5a <fork>:
{
    80001e5a:	7139                	addi	sp,sp,-64
    80001e5c:	fc06                	sd	ra,56(sp)
    80001e5e:	f822                	sd	s0,48(sp)
    80001e60:	f426                	sd	s1,40(sp)
    80001e62:	f04a                	sd	s2,32(sp)
    80001e64:	ec4e                	sd	s3,24(sp)
    80001e66:	e852                	sd	s4,16(sp)
    80001e68:	e456                	sd	s5,8(sp)
    80001e6a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	bc8080e7          	jalr	-1080(ra) # 80001a34 <myproc>
    80001e74:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	e46080e7          	jalr	-442(ra) # 80001cbc <allocproc>
    80001e7e:	10050163          	beqz	a0,80001f80 <fork+0x126>
    80001e82:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001e84:	048ab603          	ld	a2,72(s5) # 1048 <_entry-0x7fffefb8>
    80001e88:	692c                	ld	a1,80(a0)
    80001e8a:	050ab503          	ld	a0,80(s5)
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	750080e7          	jalr	1872(ra) # 800015de <uvmcopy>
    80001e96:	06054763          	bltz	a0,80001f04 <fork+0xaa>
      kvmcopymappings(np->pagetable, np->kernelpgtbl, 0, p->sz) < 0){
    80001e9a:	048ab683          	ld	a3,72(s5)
    80001e9e:	4601                	li	a2,0
    80001ea0:	0589b583          	ld	a1,88(s3)
    80001ea4:	0509b503          	ld	a0,80(s3)
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	8aa080e7          	jalr	-1878(ra) # 80001752 <kvmcopymappings>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001eb0:	04054a63          	bltz	a0,80001f04 <fork+0xaa>
  np->sz = p->sz;
    80001eb4:	048ab783          	ld	a5,72(s5)
    80001eb8:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001ebc:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ec0:	060ab683          	ld	a3,96(s5)
    80001ec4:	87b6                	mv	a5,a3
    80001ec6:	0609b703          	ld	a4,96(s3)
    80001eca:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80001ece:	0007b803          	ld	a6,0(a5)
    80001ed2:	6788                	ld	a0,8(a5)
    80001ed4:	6b8c                	ld	a1,16(a5)
    80001ed6:	6f90                	ld	a2,24(a5)
    80001ed8:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001edc:	e708                	sd	a0,8(a4)
    80001ede:	eb0c                	sd	a1,16(a4)
    80001ee0:	ef10                	sd	a2,24(a4)
    80001ee2:	02078793          	addi	a5,a5,32
    80001ee6:	02070713          	addi	a4,a4,32
    80001eea:	fed792e3          	bne	a5,a3,80001ece <fork+0x74>
  np->trapframe->a0 = 0;
    80001eee:	0609b783          	ld	a5,96(s3)
    80001ef2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ef6:	0d8a8493          	addi	s1,s5,216
    80001efa:	0d898913          	addi	s2,s3,216
    80001efe:	158a8a13          	addi	s4,s5,344
    80001f02:	a00d                	j	80001f24 <fork+0xca>
    freeproc(np);
    80001f04:	854e                	mv	a0,s3
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	d38080e7          	jalr	-712(ra) # 80001c3e <freeproc>
    release(&np->lock);
    80001f0e:	854e                	mv	a0,s3
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	da2080e7          	jalr	-606(ra) # 80000cb2 <release>
    return -1;
    80001f18:	54fd                	li	s1,-1
    80001f1a:	a889                	j	80001f6c <fork+0x112>
  for(i = 0; i < NOFILE; i++)
    80001f1c:	04a1                	addi	s1,s1,8
    80001f1e:	0921                	addi	s2,s2,8
    80001f20:	01448b63          	beq	s1,s4,80001f36 <fork+0xdc>
    if(p->ofile[i])
    80001f24:	6088                	ld	a0,0(s1)
    80001f26:	d97d                	beqz	a0,80001f1c <fork+0xc2>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f28:	00002097          	auipc	ra,0x2
    80001f2c:	766080e7          	jalr	1894(ra) # 8000468e <filedup>
    80001f30:	00a93023          	sd	a0,0(s2) # 1000 <_entry-0x7ffff000>
    80001f34:	b7e5                	j	80001f1c <fork+0xc2>
  np->cwd = idup(p->cwd);
    80001f36:	158ab503          	ld	a0,344(s5)
    80001f3a:	00002097          	auipc	ra,0x2
    80001f3e:	8da080e7          	jalr	-1830(ra) # 80003814 <idup>
    80001f42:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f46:	4641                	li	a2,16
    80001f48:	160a8593          	addi	a1,s5,352
    80001f4c:	16098513          	addi	a0,s3,352
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	efc080e7          	jalr	-260(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001f58:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f5c:	4789                	li	a5,2
    80001f5e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f62:	854e                	mv	a0,s3
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	d4e080e7          	jalr	-690(ra) # 80000cb2 <release>
}
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	70e2                	ld	ra,56(sp)
    80001f70:	7442                	ld	s0,48(sp)
    80001f72:	74a2                	ld	s1,40(sp)
    80001f74:	7902                	ld	s2,32(sp)
    80001f76:	69e2                	ld	s3,24(sp)
    80001f78:	6a42                	ld	s4,16(sp)
    80001f7a:	6aa2                	ld	s5,8(sp)
    80001f7c:	6121                	addi	sp,sp,64
    80001f7e:	8082                	ret
    return -1;
    80001f80:	54fd                	li	s1,-1
    80001f82:	b7ed                	j	80001f6c <fork+0x112>

0000000080001f84 <reparent>:
{
    80001f84:	7179                	addi	sp,sp,-48
    80001f86:	f406                	sd	ra,40(sp)
    80001f88:	f022                	sd	s0,32(sp)
    80001f8a:	ec26                	sd	s1,24(sp)
    80001f8c:	e84a                	sd	s2,16(sp)
    80001f8e:	e44e                	sd	s3,8(sp)
    80001f90:	e052                	sd	s4,0(sp)
    80001f92:	1800                	addi	s0,sp,48
    80001f94:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f96:	00010497          	auipc	s1,0x10
    80001f9a:	dd248493          	addi	s1,s1,-558 # 80011d68 <proc>
      pp->parent = initproc;
    80001f9e:	00007a17          	auipc	s4,0x7
    80001fa2:	07aa0a13          	addi	s4,s4,122 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fa6:	00016997          	auipc	s3,0x16
    80001faa:	9c298993          	addi	s3,s3,-1598 # 80017968 <tickslock>
    80001fae:	a029                	j	80001fb8 <reparent+0x34>
    80001fb0:	17048493          	addi	s1,s1,368
    80001fb4:	03348363          	beq	s1,s3,80001fda <reparent+0x56>
    if(pp->parent == p){
    80001fb8:	709c                	ld	a5,32(s1)
    80001fba:	ff279be3          	bne	a5,s2,80001fb0 <reparent+0x2c>
      acquire(&pp->lock);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	c3e080e7          	jalr	-962(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80001fc8:	000a3783          	ld	a5,0(s4)
    80001fcc:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	ce2080e7          	jalr	-798(ra) # 80000cb2 <release>
    80001fd8:	bfe1                	j	80001fb0 <reparent+0x2c>
}
    80001fda:	70a2                	ld	ra,40(sp)
    80001fdc:	7402                	ld	s0,32(sp)
    80001fde:	64e2                	ld	s1,24(sp)
    80001fe0:	6942                	ld	s2,16(sp)
    80001fe2:	69a2                	ld	s3,8(sp)
    80001fe4:	6a02                	ld	s4,0(sp)
    80001fe6:	6145                	addi	sp,sp,48
    80001fe8:	8082                	ret

0000000080001fea <scheduler>:
{
    80001fea:	715d                	addi	sp,sp,-80
    80001fec:	e486                	sd	ra,72(sp)
    80001fee:	e0a2                	sd	s0,64(sp)
    80001ff0:	fc26                	sd	s1,56(sp)
    80001ff2:	f84a                	sd	s2,48(sp)
    80001ff4:	f44e                	sd	s3,40(sp)
    80001ff6:	f052                	sd	s4,32(sp)
    80001ff8:	ec56                	sd	s5,24(sp)
    80001ffa:	e85a                	sd	s6,16(sp)
    80001ffc:	e45e                	sd	s7,8(sp)
    80001ffe:	e062                	sd	s8,0(sp)
    80002000:	0880                	addi	s0,sp,80
    80002002:	8792                	mv	a5,tp
  int id = r_tp();
    80002004:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002006:	00779b13          	slli	s6,a5,0x7
    8000200a:	00010717          	auipc	a4,0x10
    8000200e:	94670713          	addi	a4,a4,-1722 # 80011950 <pid_lock>
    80002012:	975a                	add	a4,a4,s6
    80002014:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002018:	00010717          	auipc	a4,0x10
    8000201c:	95870713          	addi	a4,a4,-1704 # 80011970 <cpus+0x8>
    80002020:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	00010a17          	auipc	s4,0x10
    80002028:	92ca0a13          	addi	s4,s4,-1748 # 80011950 <pid_lock>
    8000202c:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernelpgtbl));
    8000202e:	5bfd                	li	s7,-1
    80002030:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002032:	00016997          	auipc	s3,0x16
    80002036:	93698993          	addi	s3,s3,-1738 # 80017968 <tickslock>
    8000203a:	a0bd                	j	800020a8 <scheduler+0xbe>
      release(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c74080e7          	jalr	-908(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002046:	17048493          	addi	s1,s1,368
    8000204a:	05348563          	beq	s1,s3,80002094 <scheduler+0xaa>
      acquire(&p->lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	bae080e7          	jalr	-1106(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    80002058:	4c9c                	lw	a5,24(s1)
    8000205a:	ff2791e3          	bne	a5,s2,8000203c <scheduler+0x52>
        p->state = RUNNING;
    8000205e:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002062:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernelpgtbl));
    80002066:	6cbc                	ld	a5,88(s1)
    80002068:	83b1                	srli	a5,a5,0xc
    8000206a:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    8000206e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80002072:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80002076:	06848593          	addi	a1,s1,104
    8000207a:	855a                	mv	a0,s6
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	716080e7          	jalr	1814(ra) # 80002792 <swtch>
        kvminithart();
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	f42080e7          	jalr	-190(ra) # 80000fc6 <kvminithart>
        c->proc = 0;
    8000208c:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002090:	4c05                	li	s8,1
    80002092:	b76d                	j	8000203c <scheduler+0x52>
    if(found == 0) {
    80002094:	000c1a63          	bnez	s8,800020a8 <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002098:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020a0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020a4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b0:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020b4:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b6:	00010497          	auipc	s1,0x10
    800020ba:	cb248493          	addi	s1,s1,-846 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800020be:	4909                	li	s2,2
        p->state = RUNNING;
    800020c0:	4a8d                	li	s5,3
    800020c2:	b771                	j	8000204e <scheduler+0x64>

00000000800020c4 <sched>:
{
    800020c4:	7179                	addi	sp,sp,-48
    800020c6:	f406                	sd	ra,40(sp)
    800020c8:	f022                	sd	s0,32(sp)
    800020ca:	ec26                	sd	s1,24(sp)
    800020cc:	e84a                	sd	s2,16(sp)
    800020ce:	e44e                	sd	s3,8(sp)
    800020d0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	962080e7          	jalr	-1694(ra) # 80001a34 <myproc>
    800020da:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	aa8080e7          	jalr	-1368(ra) # 80000b84 <holding>
    800020e4:	c93d                	beqz	a0,8000215a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	00010717          	auipc	a4,0x10
    800020f0:	86470713          	addi	a4,a4,-1948 # 80011950 <pid_lock>
    800020f4:	97ba                	add	a5,a5,a4
    800020f6:	0907a703          	lw	a4,144(a5)
    800020fa:	4785                	li	a5,1
    800020fc:	06f71763          	bne	a4,a5,8000216a <sched+0xa6>
  if(p->state == RUNNING)
    80002100:	4c98                	lw	a4,24(s1)
    80002102:	478d                	li	a5,3
    80002104:	06f70b63          	beq	a4,a5,8000217a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002108:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000210c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000210e:	efb5                	bnez	a5,8000218a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002110:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002112:	00010917          	auipc	s2,0x10
    80002116:	83e90913          	addi	s2,s2,-1986 # 80011950 <pid_lock>
    8000211a:	2781                	sext.w	a5,a5
    8000211c:	079e                	slli	a5,a5,0x7
    8000211e:	97ca                	add	a5,a5,s2
    80002120:	0947a983          	lw	s3,148(a5)
    80002124:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002126:	2781                	sext.w	a5,a5
    80002128:	079e                	slli	a5,a5,0x7
    8000212a:	00010597          	auipc	a1,0x10
    8000212e:	84658593          	addi	a1,a1,-1978 # 80011970 <cpus+0x8>
    80002132:	95be                	add	a1,a1,a5
    80002134:	06848513          	addi	a0,s1,104
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	65a080e7          	jalr	1626(ra) # 80002792 <swtch>
    80002140:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002142:	2781                	sext.w	a5,a5
    80002144:	079e                	slli	a5,a5,0x7
    80002146:	97ca                	add	a5,a5,s2
    80002148:	0937aa23          	sw	s3,148(a5)
}
    8000214c:	70a2                	ld	ra,40(sp)
    8000214e:	7402                	ld	s0,32(sp)
    80002150:	64e2                	ld	s1,24(sp)
    80002152:	6942                	ld	s2,16(sp)
    80002154:	69a2                	ld	s3,8(sp)
    80002156:	6145                	addi	sp,sp,48
    80002158:	8082                	ret
    panic("sched p->lock");
    8000215a:	00006517          	auipc	a0,0x6
    8000215e:	06650513          	addi	a0,a0,102 # 800081c0 <digits+0x190>
    80002162:	ffffe097          	auipc	ra,0xffffe
    80002166:	3e0080e7          	jalr	992(ra) # 80000542 <panic>
    panic("sched locks");
    8000216a:	00006517          	auipc	a0,0x6
    8000216e:	06650513          	addi	a0,a0,102 # 800081d0 <digits+0x1a0>
    80002172:	ffffe097          	auipc	ra,0xffffe
    80002176:	3d0080e7          	jalr	976(ra) # 80000542 <panic>
    panic("sched running");
    8000217a:	00006517          	auipc	a0,0x6
    8000217e:	06650513          	addi	a0,a0,102 # 800081e0 <digits+0x1b0>
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>
    panic("sched interruptible");
    8000218a:	00006517          	auipc	a0,0x6
    8000218e:	06650513          	addi	a0,a0,102 # 800081f0 <digits+0x1c0>
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	3b0080e7          	jalr	944(ra) # 80000542 <panic>

000000008000219a <exit>:
{
    8000219a:	7179                	addi	sp,sp,-48
    8000219c:	f406                	sd	ra,40(sp)
    8000219e:	f022                	sd	s0,32(sp)
    800021a0:	ec26                	sd	s1,24(sp)
    800021a2:	e84a                	sd	s2,16(sp)
    800021a4:	e44e                	sd	s3,8(sp)
    800021a6:	e052                	sd	s4,0(sp)
    800021a8:	1800                	addi	s0,sp,48
    800021aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	888080e7          	jalr	-1912(ra) # 80001a34 <myproc>
    800021b4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021b6:	00007797          	auipc	a5,0x7
    800021ba:	e627b783          	ld	a5,-414(a5) # 80009018 <initproc>
    800021be:	0d850493          	addi	s1,a0,216
    800021c2:	15850913          	addi	s2,a0,344
    800021c6:	02a79363          	bne	a5,a0,800021ec <exit+0x52>
    panic("init exiting");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	03e50513          	addi	a0,a0,62 # 80008208 <digits+0x1d8>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	370080e7          	jalr	880(ra) # 80000542 <panic>
      fileclose(f);
    800021da:	00002097          	auipc	ra,0x2
    800021de:	506080e7          	jalr	1286(ra) # 800046e0 <fileclose>
      p->ofile[fd] = 0;
    800021e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021e6:	04a1                	addi	s1,s1,8
    800021e8:	01248563          	beq	s1,s2,800021f2 <exit+0x58>
    if(p->ofile[fd]){
    800021ec:	6088                	ld	a0,0(s1)
    800021ee:	f575                	bnez	a0,800021da <exit+0x40>
    800021f0:	bfdd                	j	800021e6 <exit+0x4c>
  begin_op();
    800021f2:	00002097          	auipc	ra,0x2
    800021f6:	01c080e7          	jalr	28(ra) # 8000420e <begin_op>
  iput(p->cwd);
    800021fa:	1589b503          	ld	a0,344(s3)
    800021fe:	00002097          	auipc	ra,0x2
    80002202:	80e080e7          	jalr	-2034(ra) # 80003a0c <iput>
  end_op();
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	088080e7          	jalr	136(ra) # 8000428e <end_op>
  p->cwd = 0;
    8000220e:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002212:	00007497          	auipc	s1,0x7
    80002216:	e0648493          	addi	s1,s1,-506 # 80009018 <initproc>
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9e2080e7          	jalr	-1566(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    80002224:	6088                	ld	a0,0(s1)
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	736080e7          	jalr	1846(ra) # 8000195c <wakeup1>
  release(&initproc->lock);
    8000222e:	6088                	ld	a0,0(s1)
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a82080e7          	jalr	-1406(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002238:	854e                	mv	a0,s3
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	9c4080e7          	jalr	-1596(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    80002242:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002246:	854e                	mv	a0,s3
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	9ac080e7          	jalr	-1620(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    8000225a:	854e                	mv	a0,s3
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	9a2080e7          	jalr	-1630(ra) # 80000bfe <acquire>
  reparent(p);
    80002264:	854e                	mv	a0,s3
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	d1e080e7          	jalr	-738(ra) # 80001f84 <reparent>
  wakeup1(original_parent);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	6ec080e7          	jalr	1772(ra) # 8000195c <wakeup1>
  p->xstate = status;
    80002278:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000227c:	4791                	li	a5,4
    8000227e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a2e080e7          	jalr	-1490(ra) # 80000cb2 <release>
  sched();
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	e38080e7          	jalr	-456(ra) # 800020c4 <sched>
  panic("zombie exit");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	f8450513          	addi	a0,a0,-124 # 80008218 <digits+0x1e8>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2a6080e7          	jalr	678(ra) # 80000542 <panic>

00000000800022a4 <yield>:
{
    800022a4:	1101                	addi	sp,sp,-32
    800022a6:	ec06                	sd	ra,24(sp)
    800022a8:	e822                	sd	s0,16(sp)
    800022aa:	e426                	sd	s1,8(sp)
    800022ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	786080e7          	jalr	1926(ra) # 80001a34 <myproc>
    800022b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	946080e7          	jalr	-1722(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    800022c0:	4789                	li	a5,2
    800022c2:	cc9c                	sw	a5,24(s1)
  sched();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	e00080e7          	jalr	-512(ra) # 800020c4 <sched>
  release(&p->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9e4080e7          	jalr	-1564(ra) # 80000cb2 <release>
}
    800022d6:	60e2                	ld	ra,24(sp)
    800022d8:	6442                	ld	s0,16(sp)
    800022da:	64a2                	ld	s1,8(sp)
    800022dc:	6105                	addi	sp,sp,32
    800022de:	8082                	ret

00000000800022e0 <sleep>:
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	1800                	addi	s0,sp,48
    800022ee:	89aa                	mv	s3,a0
    800022f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	742080e7          	jalr	1858(ra) # 80001a34 <myproc>
    800022fa:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022fc:	05250663          	beq	a0,s2,80002348 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	8fe080e7          	jalr	-1794(ra) # 80000bfe <acquire>
    release(lk);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	9a8080e7          	jalr	-1624(ra) # 80000cb2 <release>
  p->chan = chan;
    80002312:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002316:	4785                	li	a5,1
    80002318:	cc9c                	sw	a5,24(s1)
  sched();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	daa080e7          	jalr	-598(ra) # 800020c4 <sched>
  p->chan = 0;
    80002322:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	98a080e7          	jalr	-1654(ra) # 80000cb2 <release>
    acquire(lk);
    80002330:	854a                	mv	a0,s2
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8cc080e7          	jalr	-1844(ra) # 80000bfe <acquire>
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
  p->chan = chan;
    80002348:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000234c:	4785                	li	a5,1
    8000234e:	cd1c                	sw	a5,24(a0)
  sched();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	d74080e7          	jalr	-652(ra) # 800020c4 <sched>
  p->chan = 0;
    80002358:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000235c:	bff9                	j	8000233a <sleep+0x5a>

000000008000235e <wait>:
{
    8000235e:	715d                	addi	sp,sp,-80
    80002360:	e486                	sd	ra,72(sp)
    80002362:	e0a2                	sd	s0,64(sp)
    80002364:	fc26                	sd	s1,56(sp)
    80002366:	f84a                	sd	s2,48(sp)
    80002368:	f44e                	sd	s3,40(sp)
    8000236a:	f052                	sd	s4,32(sp)
    8000236c:	ec56                	sd	s5,24(sp)
    8000236e:	e85a                	sd	s6,16(sp)
    80002370:	e45e                	sd	s7,8(sp)
    80002372:	0880                	addi	s0,sp,80
    80002374:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	6be080e7          	jalr	1726(ra) # 80001a34 <myproc>
    8000237e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	87e080e7          	jalr	-1922(ra) # 80000bfe <acquire>
    havekids = 0;
    80002388:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000238a:	4a11                	li	s4,4
        havekids = 1;
    8000238c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000238e:	00015997          	auipc	s3,0x15
    80002392:	5da98993          	addi	s3,s3,1498 # 80017968 <tickslock>
    havekids = 0;
    80002396:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002398:	00010497          	auipc	s1,0x10
    8000239c:	9d048493          	addi	s1,s1,-1584 # 80011d68 <proc>
    800023a0:	a08d                	j	80002402 <wait+0xa4>
          pid = np->pid;
    800023a2:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023a6:	000b0e63          	beqz	s6,800023c2 <wait+0x64>
    800023aa:	4691                	li	a3,4
    800023ac:	03448613          	addi	a2,s1,52
    800023b0:	85da                	mv	a1,s6
    800023b2:	05093503          	ld	a0,80(s2)
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	310080e7          	jalr	784(ra) # 800016c6 <copyout>
    800023be:	02054263          	bltz	a0,800023e2 <wait+0x84>
          freeproc(np);
    800023c2:	8526                	mv	a0,s1
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	87a080e7          	jalr	-1926(ra) # 80001c3e <freeproc>
          release(&np->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8e4080e7          	jalr	-1820(ra) # 80000cb2 <release>
          release(&p->lock);
    800023d6:	854a                	mv	a0,s2
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8da080e7          	jalr	-1830(ra) # 80000cb2 <release>
          return pid;
    800023e0:	a8a9                	j	8000243a <wait+0xdc>
            release(&np->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8ce080e7          	jalr	-1842(ra) # 80000cb2 <release>
            release(&p->lock);
    800023ec:	854a                	mv	a0,s2
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8c4080e7          	jalr	-1852(ra) # 80000cb2 <release>
            return -1;
    800023f6:	59fd                	li	s3,-1
    800023f8:	a089                	j	8000243a <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800023fa:	17048493          	addi	s1,s1,368
    800023fe:	03348463          	beq	s1,s3,80002426 <wait+0xc8>
      if(np->parent == p){
    80002402:	709c                	ld	a5,32(s1)
    80002404:	ff279be3          	bne	a5,s2,800023fa <wait+0x9c>
        acquire(&np->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	7f4080e7          	jalr	2036(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    80002412:	4c9c                	lw	a5,24(s1)
    80002414:	f94787e3          	beq	a5,s4,800023a2 <wait+0x44>
        release(&np->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	898080e7          	jalr	-1896(ra) # 80000cb2 <release>
        havekids = 1;
    80002422:	8756                	mv	a4,s5
    80002424:	bfd9                	j	800023fa <wait+0x9c>
    if(!havekids || p->killed){
    80002426:	c701                	beqz	a4,8000242e <wait+0xd0>
    80002428:	03092783          	lw	a5,48(s2)
    8000242c:	c39d                	beqz	a5,80002452 <wait+0xf4>
      release(&p->lock);
    8000242e:	854a                	mv	a0,s2
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	882080e7          	jalr	-1918(ra) # 80000cb2 <release>
      return -1;
    80002438:	59fd                	li	s3,-1
}
    8000243a:	854e                	mv	a0,s3
    8000243c:	60a6                	ld	ra,72(sp)
    8000243e:	6406                	ld	s0,64(sp)
    80002440:	74e2                	ld	s1,56(sp)
    80002442:	7942                	ld	s2,48(sp)
    80002444:	79a2                	ld	s3,40(sp)
    80002446:	7a02                	ld	s4,32(sp)
    80002448:	6ae2                	ld	s5,24(sp)
    8000244a:	6b42                	ld	s6,16(sp)
    8000244c:	6ba2                	ld	s7,8(sp)
    8000244e:	6161                	addi	sp,sp,80
    80002450:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002452:	85ca                	mv	a1,s2
    80002454:	854a                	mv	a0,s2
    80002456:	00000097          	auipc	ra,0x0
    8000245a:	e8a080e7          	jalr	-374(ra) # 800022e0 <sleep>
    havekids = 0;
    8000245e:	bf25                	j	80002396 <wait+0x38>

0000000080002460 <wakeup>:
{
    80002460:	7139                	addi	sp,sp,-64
    80002462:	fc06                	sd	ra,56(sp)
    80002464:	f822                	sd	s0,48(sp)
    80002466:	f426                	sd	s1,40(sp)
    80002468:	f04a                	sd	s2,32(sp)
    8000246a:	ec4e                	sd	s3,24(sp)
    8000246c:	e852                	sd	s4,16(sp)
    8000246e:	e456                	sd	s5,8(sp)
    80002470:	0080                	addi	s0,sp,64
    80002472:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002474:	00010497          	auipc	s1,0x10
    80002478:	8f448493          	addi	s1,s1,-1804 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000247c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000247e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002480:	00015917          	auipc	s2,0x15
    80002484:	4e890913          	addi	s2,s2,1256 # 80017968 <tickslock>
    80002488:	a811                	j	8000249c <wakeup+0x3c>
    release(&p->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	826080e7          	jalr	-2010(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002494:	17048493          	addi	s1,s1,368
    80002498:	03248063          	beq	s1,s2,800024b8 <wakeup+0x58>
    acquire(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	760080e7          	jalr	1888(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024a6:	4c9c                	lw	a5,24(s1)
    800024a8:	ff3791e3          	bne	a5,s3,8000248a <wakeup+0x2a>
    800024ac:	749c                	ld	a5,40(s1)
    800024ae:	fd479ee3          	bne	a5,s4,8000248a <wakeup+0x2a>
      p->state = RUNNABLE;
    800024b2:	0154ac23          	sw	s5,24(s1)
    800024b6:	bfd1                	j	8000248a <wakeup+0x2a>
}
    800024b8:	70e2                	ld	ra,56(sp)
    800024ba:	7442                	ld	s0,48(sp)
    800024bc:	74a2                	ld	s1,40(sp)
    800024be:	7902                	ld	s2,32(sp)
    800024c0:	69e2                	ld	s3,24(sp)
    800024c2:	6a42                	ld	s4,16(sp)
    800024c4:	6aa2                	ld	s5,8(sp)
    800024c6:	6121                	addi	sp,sp,64
    800024c8:	8082                	ret

00000000800024ca <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024ca:	7179                	addi	sp,sp,-48
    800024cc:	f406                	sd	ra,40(sp)
    800024ce:	f022                	sd	s0,32(sp)
    800024d0:	ec26                	sd	s1,24(sp)
    800024d2:	e84a                	sd	s2,16(sp)
    800024d4:	e44e                	sd	s3,8(sp)
    800024d6:	1800                	addi	s0,sp,48
    800024d8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	00010497          	auipc	s1,0x10
    800024de:	88e48493          	addi	s1,s1,-1906 # 80011d68 <proc>
    800024e2:	00015997          	auipc	s3,0x15
    800024e6:	48698993          	addi	s3,s3,1158 # 80017968 <tickslock>
    acquire(&p->lock);
    800024ea:	8526                	mv	a0,s1
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	712080e7          	jalr	1810(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    800024f4:	5c9c                	lw	a5,56(s1)
    800024f6:	01278d63          	beq	a5,s2,80002510 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	7b6080e7          	jalr	1974(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002504:	17048493          	addi	s1,s1,368
    80002508:	ff3491e3          	bne	s1,s3,800024ea <kill+0x20>
  }
  return -1;
    8000250c:	557d                	li	a0,-1
    8000250e:	a821                	j	80002526 <kill+0x5c>
      p->killed = 1;
    80002510:	4785                	li	a5,1
    80002512:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002514:	4c98                	lw	a4,24(s1)
    80002516:	00f70f63          	beq	a4,a5,80002534 <kill+0x6a>
      release(&p->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	796080e7          	jalr	1942(ra) # 80000cb2 <release>
      return 0;
    80002524:	4501                	li	a0,0
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6145                	addi	sp,sp,48
    80002532:	8082                	ret
        p->state = RUNNABLE;
    80002534:	4789                	li	a5,2
    80002536:	cc9c                	sw	a5,24(s1)
    80002538:	b7cd                	j	8000251a <kill+0x50>

000000008000253a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000253a:	7179                	addi	sp,sp,-48
    8000253c:	f406                	sd	ra,40(sp)
    8000253e:	f022                	sd	s0,32(sp)
    80002540:	ec26                	sd	s1,24(sp)
    80002542:	e84a                	sd	s2,16(sp)
    80002544:	e44e                	sd	s3,8(sp)
    80002546:	e052                	sd	s4,0(sp)
    80002548:	1800                	addi	s0,sp,48
    8000254a:	84aa                	mv	s1,a0
    8000254c:	892e                	mv	s2,a1
    8000254e:	89b2                	mv	s3,a2
    80002550:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	4e2080e7          	jalr	1250(ra) # 80001a34 <myproc>
  if(user_dst){
    8000255a:	c08d                	beqz	s1,8000257c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000255c:	86d2                	mv	a3,s4
    8000255e:	864e                	mv	a2,s3
    80002560:	85ca                	mv	a1,s2
    80002562:	6928                	ld	a0,80(a0)
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	162080e7          	jalr	354(ra) # 800016c6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000256c:	70a2                	ld	ra,40(sp)
    8000256e:	7402                	ld	s0,32(sp)
    80002570:	64e2                	ld	s1,24(sp)
    80002572:	6942                	ld	s2,16(sp)
    80002574:	69a2                	ld	s3,8(sp)
    80002576:	6a02                	ld	s4,0(sp)
    80002578:	6145                	addi	sp,sp,48
    8000257a:	8082                	ret
    memmove((char *)dst, src, len);
    8000257c:	000a061b          	sext.w	a2,s4
    80002580:	85ce                	mv	a1,s3
    80002582:	854a                	mv	a0,s2
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	7d2080e7          	jalr	2002(ra) # 80000d56 <memmove>
    return 0;
    8000258c:	8526                	mv	a0,s1
    8000258e:	bff9                	j	8000256c <either_copyout+0x32>

0000000080002590 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002590:	7179                	addi	sp,sp,-48
    80002592:	f406                	sd	ra,40(sp)
    80002594:	f022                	sd	s0,32(sp)
    80002596:	ec26                	sd	s1,24(sp)
    80002598:	e84a                	sd	s2,16(sp)
    8000259a:	e44e                	sd	s3,8(sp)
    8000259c:	e052                	sd	s4,0(sp)
    8000259e:	1800                	addi	s0,sp,48
    800025a0:	892a                	mv	s2,a0
    800025a2:	84ae                	mv	s1,a1
    800025a4:	89b2                	mv	s3,a2
    800025a6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025a8:	fffff097          	auipc	ra,0xfffff
    800025ac:	48c080e7          	jalr	1164(ra) # 80001a34 <myproc>
  if(user_src){
    800025b0:	c08d                	beqz	s1,800025d2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025b2:	86d2                	mv	a3,s4
    800025b4:	864e                	mv	a2,s3
    800025b6:	85ca                	mv	a1,s2
    800025b8:	6928                	ld	a0,80(a0)
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	278080e7          	jalr	632(ra) # 80001832 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025c2:	70a2                	ld	ra,40(sp)
    800025c4:	7402                	ld	s0,32(sp)
    800025c6:	64e2                	ld	s1,24(sp)
    800025c8:	6942                	ld	s2,16(sp)
    800025ca:	69a2                	ld	s3,8(sp)
    800025cc:	6a02                	ld	s4,0(sp)
    800025ce:	6145                	addi	sp,sp,48
    800025d0:	8082                	ret
    memmove(dst, (char*)src, len);
    800025d2:	000a061b          	sext.w	a2,s4
    800025d6:	85ce                	mv	a1,s3
    800025d8:	854a                	mv	a0,s2
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	77c080e7          	jalr	1916(ra) # 80000d56 <memmove>
    return 0;
    800025e2:	8526                	mv	a0,s1
    800025e4:	bff9                	j	800025c2 <either_copyin+0x32>

00000000800025e6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025e6:	715d                	addi	sp,sp,-80
    800025e8:	e486                	sd	ra,72(sp)
    800025ea:	e0a2                	sd	s0,64(sp)
    800025ec:	fc26                	sd	s1,56(sp)
    800025ee:	f84a                	sd	s2,48(sp)
    800025f0:	f44e                	sd	s3,40(sp)
    800025f2:	f052                	sd	s4,32(sp)
    800025f4:	ec56                	sd	s5,24(sp)
    800025f6:	e85a                	sd	s6,16(sp)
    800025f8:	e45e                	sd	s7,8(sp)
    800025fa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025fc:	00006517          	auipc	a0,0x6
    80002600:	abc50513          	addi	a0,a0,-1348 # 800080b8 <digits+0x88>
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	f88080e7          	jalr	-120(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000260c:	00010497          	auipc	s1,0x10
    80002610:	8bc48493          	addi	s1,s1,-1860 # 80011ec8 <proc+0x160>
    80002614:	00015917          	auipc	s2,0x15
    80002618:	4b490913          	addi	s2,s2,1204 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000261e:	00006997          	auipc	s3,0x6
    80002622:	c0a98993          	addi	s3,s3,-1014 # 80008228 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002626:	00006a97          	auipc	s5,0x6
    8000262a:	c0aa8a93          	addi	s5,s5,-1014 # 80008230 <digits+0x200>
    printf("\n");
    8000262e:	00006a17          	auipc	s4,0x6
    80002632:	a8aa0a13          	addi	s4,s4,-1398 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002636:	00006b97          	auipc	s7,0x6
    8000263a:	c72b8b93          	addi	s7,s7,-910 # 800082a8 <states.0>
    8000263e:	a00d                	j	80002660 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002640:	ed86a583          	lw	a1,-296(a3)
    80002644:	8556                	mv	a0,s5
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	f46080e7          	jalr	-186(ra) # 8000058c <printf>
    printf("\n");
    8000264e:	8552                	mv	a0,s4
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	f3c080e7          	jalr	-196(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002658:	17048493          	addi	s1,s1,368
    8000265c:	03248163          	beq	s1,s2,8000267e <procdump+0x98>
    if(p->state == UNUSED)
    80002660:	86a6                	mv	a3,s1
    80002662:	eb84a783          	lw	a5,-328(s1)
    80002666:	dbed                	beqz	a5,80002658 <procdump+0x72>
      state = "???";
    80002668:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000266a:	fcfb6be3          	bltu	s6,a5,80002640 <procdump+0x5a>
    8000266e:	1782                	slli	a5,a5,0x20
    80002670:	9381                	srli	a5,a5,0x20
    80002672:	078e                	slli	a5,a5,0x3
    80002674:	97de                	add	a5,a5,s7
    80002676:	6390                	ld	a2,0(a5)
    80002678:	f661                	bnez	a2,80002640 <procdump+0x5a>
      state = "???";
    8000267a:	864e                	mv	a2,s3
    8000267c:	b7d1                	j	80002640 <procdump+0x5a>
  }
}
    8000267e:	60a6                	ld	ra,72(sp)
    80002680:	6406                	ld	s0,64(sp)
    80002682:	74e2                	ld	s1,56(sp)
    80002684:	7942                	ld	s2,48(sp)
    80002686:	79a2                	ld	s3,40(sp)
    80002688:	7a02                	ld	s4,32(sp)
    8000268a:	6ae2                	ld	s5,24(sp)
    8000268c:	6b42                	ld	s6,16(sp)
    8000268e:	6ba2                	ld	s7,8(sp)
    80002690:	6161                	addi	sp,sp,80
    80002692:	8082                	ret

0000000080002694 <uvmlazytouch>:

// touch a lazy-allocated page so it's mapped to an actual physical page.
void uvmlazytouch(uint64 va) {
    80002694:	7179                	addi	sp,sp,-48
    80002696:	f406                	sd	ra,40(sp)
    80002698:	f022                	sd	s0,32(sp)
    8000269a:	ec26                	sd	s1,24(sp)
    8000269c:	e84a                	sd	s2,16(sp)
    8000269e:	e44e                	sd	s3,8(sp)
    800026a0:	1800                	addi	s0,sp,48
    800026a2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	390080e7          	jalr	912(ra) # 80001a34 <myproc>
    800026ac:	89aa                	mv	s3,a0
  char *mem = kalloc();
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	460080e7          	jalr	1120(ra) # 80000b0e <kalloc>
  if(mem == 0) {
    800026b6:	cd0d                	beqz	a0,800026f0 <uvmlazytouch+0x5c>
    800026b8:	84aa                	mv	s1,a0
    // failed to allocate physical memory
    printf("lazy alloc: out of memory\n");
    p->killed = 1;
  } else {
    memset(mem, 0, PGSIZE);
    800026ba:	6605                	lui	a2,0x1
    800026bc:	4581                	li	a1,0
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	63c080e7          	jalr	1596(ra) # 80000cfa <memset>
    if((mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0)
    800026c6:	757d                	lui	a0,0xfffff
    800026c8:	00a97933          	and	s2,s2,a0
    800026cc:	4779                	li	a4,30
    800026ce:	86a6                	mv	a3,s1
    800026d0:	6605                	lui	a2,0x1
    800026d2:	85ca                	mv	a1,s2
    800026d4:	0509b503          	ld	a0,80(s3)
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	a50080e7          	jalr	-1456(ra) # 80001128 <mappages>
    800026e0:	e505                	bnez	a0,80002708 <uvmlazytouch+0x74>
      kfree(mem);
      p->killed = 1;
    }
  }
  // printf("lazy alloc: %p, p->sz: %p\n", PGROUNDDOWN(va), p->sz);
}
    800026e2:	70a2                	ld	ra,40(sp)
    800026e4:	7402                	ld	s0,32(sp)
    800026e6:	64e2                	ld	s1,24(sp)
    800026e8:	6942                	ld	s2,16(sp)
    800026ea:	69a2                	ld	s3,8(sp)
    800026ec:	6145                	addi	sp,sp,48
    800026ee:	8082                	ret
    printf("lazy alloc: out of memory\n");
    800026f0:	00006517          	auipc	a0,0x6
    800026f4:	b5050513          	addi	a0,a0,-1200 # 80008240 <digits+0x210>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	e94080e7          	jalr	-364(ra) # 8000058c <printf>
    p->killed = 1;
    80002700:	4785                	li	a5,1
    80002702:	02f9a823          	sw	a5,48(s3)
    80002706:	bff1                	j	800026e2 <uvmlazytouch+0x4e>
       && (mappages(p->kernelpgtbl, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0)){
    80002708:	4779                	li	a4,30
    8000270a:	86a6                	mv	a3,s1
    8000270c:	6605                	lui	a2,0x1
    8000270e:	85ca                	mv	a1,s2
    80002710:	0589b503          	ld	a0,88(s3)
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	a14080e7          	jalr	-1516(ra) # 80001128 <mappages>
    8000271c:	d179                	beqz	a0,800026e2 <uvmlazytouch+0x4e>
      printf("lazy alloc: failed to map page\n");
    8000271e:	00006517          	auipc	a0,0x6
    80002722:	b4250513          	addi	a0,a0,-1214 # 80008260 <digits+0x230>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	e66080e7          	jalr	-410(ra) # 8000058c <printf>
      kfree(mem);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	2e2080e7          	jalr	738(ra) # 80000a12 <kfree>
      p->killed = 1;
    80002738:	4785                	li	a5,1
    8000273a:	02f9a823          	sw	a5,48(s3)
}
    8000273e:	b755                	j	800026e2 <uvmlazytouch+0x4e>

0000000080002740 <uvmshouldtouch>:

// whether a page is previously lazy-allocated and needed to be touched before use.
int uvmshouldtouch(uint64 va) {
    80002740:	1101                	addi	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	1000                	addi	s0,sp,32
    8000274a:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	2e8080e7          	jalr	744(ra) # 80001a34 <myproc>
  
  return va < p->sz // within size of memory for the process
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80002754:	6538                	ld	a4,72(a0)
    80002756:	02e4f863          	bgeu	s1,a4,80002786 <uvmshouldtouch+0x46>
    8000275a:	87aa                	mv	a5,a0
  asm volatile("mv %0, sp" : "=r" (x) );
    8000275c:	868a                	mv	a3,sp
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    8000275e:	777d                	lui	a4,0xfffff
    80002760:	8f65                	and	a4,a4,s1
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80002762:	4501                	li	a0,0
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    80002764:	02d70263          	beq	a4,a3,80002788 <uvmshouldtouch+0x48>
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80002768:	4601                	li	a2,0
    8000276a:	85a6                	mv	a1,s1
    8000276c:	6ba8                	ld	a0,80(a5)
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	87c080e7          	jalr	-1924(ra) # 80000fea <walk>
    80002776:	87aa                	mv	a5,a0
    80002778:	4505                	li	a0,1
    8000277a:	c799                	beqz	a5,80002788 <uvmshouldtouch+0x48>
    8000277c:	6388                	ld	a0,0(a5)
    8000277e:	00154513          	xori	a0,a0,1
    80002782:	8905                	andi	a0,a0,1
    80002784:	a011                	j	80002788 <uvmshouldtouch+0x48>
    80002786:	4501                	li	a0,0
    80002788:	60e2                	ld	ra,24(sp)
    8000278a:	6442                	ld	s0,16(sp)
    8000278c:	64a2                	ld	s1,8(sp)
    8000278e:	6105                	addi	sp,sp,32
    80002790:	8082                	ret

0000000080002792 <swtch>:
    80002792:	00153023          	sd	ra,0(a0)
    80002796:	00253423          	sd	sp,8(a0)
    8000279a:	e900                	sd	s0,16(a0)
    8000279c:	ed04                	sd	s1,24(a0)
    8000279e:	03253023          	sd	s2,32(a0)
    800027a2:	03353423          	sd	s3,40(a0)
    800027a6:	03453823          	sd	s4,48(a0)
    800027aa:	03553c23          	sd	s5,56(a0)
    800027ae:	05653023          	sd	s6,64(a0)
    800027b2:	05753423          	sd	s7,72(a0)
    800027b6:	05853823          	sd	s8,80(a0)
    800027ba:	05953c23          	sd	s9,88(a0)
    800027be:	07a53023          	sd	s10,96(a0)
    800027c2:	07b53423          	sd	s11,104(a0)
    800027c6:	0005b083          	ld	ra,0(a1)
    800027ca:	0085b103          	ld	sp,8(a1)
    800027ce:	6980                	ld	s0,16(a1)
    800027d0:	6d84                	ld	s1,24(a1)
    800027d2:	0205b903          	ld	s2,32(a1)
    800027d6:	0285b983          	ld	s3,40(a1)
    800027da:	0305ba03          	ld	s4,48(a1)
    800027de:	0385ba83          	ld	s5,56(a1)
    800027e2:	0405bb03          	ld	s6,64(a1)
    800027e6:	0485bb83          	ld	s7,72(a1)
    800027ea:	0505bc03          	ld	s8,80(a1)
    800027ee:	0585bc83          	ld	s9,88(a1)
    800027f2:	0605bd03          	ld	s10,96(a1)
    800027f6:	0685bd83          	ld	s11,104(a1)
    800027fa:	8082                	ret

00000000800027fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027fc:	1141                	addi	sp,sp,-16
    800027fe:	e406                	sd	ra,8(sp)
    80002800:	e022                	sd	s0,0(sp)
    80002802:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002804:	00006597          	auipc	a1,0x6
    80002808:	acc58593          	addi	a1,a1,-1332 # 800082d0 <states.0+0x28>
    8000280c:	00015517          	auipc	a0,0x15
    80002810:	15c50513          	addi	a0,a0,348 # 80017968 <tickslock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	35a080e7          	jalr	858(ra) # 80000b6e <initlock>
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e422                	sd	s0,8(sp)
    80002828:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	57678793          	addi	a5,a5,1398 # 80005da0 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002836:	6422                	ld	s0,8(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000283c:	1141                	addi	sp,sp,-16
    8000283e:	e406                	sd	ra,8(sp)
    80002840:	e022                	sd	s0,0(sp)
    80002842:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	1f0080e7          	jalr	496(ra) # 80001a34 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002850:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002852:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002856:	00004617          	auipc	a2,0x4
    8000285a:	7aa60613          	addi	a2,a2,1962 # 80007000 <_trampoline>
    8000285e:	00004697          	auipc	a3,0x4
    80002862:	7a268693          	addi	a3,a3,1954 # 80007000 <_trampoline>
    80002866:	8e91                	sub	a3,a3,a2
    80002868:	040007b7          	lui	a5,0x4000
    8000286c:	17fd                	addi	a5,a5,-1
    8000286e:	07b2                	slli	a5,a5,0xc
    80002870:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002876:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002878:	180026f3          	csrr	a3,satp
    8000287c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000287e:	7138                	ld	a4,96(a0)
    80002880:	6134                	ld	a3,64(a0)
    80002882:	6585                	lui	a1,0x1
    80002884:	96ae                	add	a3,a3,a1
    80002886:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002888:	7138                	ld	a4,96(a0)
    8000288a:	00000697          	auipc	a3,0x0
    8000288e:	13868693          	addi	a3,a3,312 # 800029c2 <usertrap>
    80002892:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002894:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002896:	8692                	mv	a3,tp
    80002898:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000289e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028aa:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ac:	6f18                	ld	a4,24(a4)
    800028ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b2:	692c                	ld	a1,80(a0)
    800028b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028b6:	00004717          	auipc	a4,0x4
    800028ba:	7da70713          	addi	a4,a4,2010 # 80007090 <userret>
    800028be:	8f11                	sub	a4,a4,a2
    800028c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028c2:	577d                	li	a4,-1
    800028c4:	177e                	slli	a4,a4,0x3f
    800028c6:	8dd9                	or	a1,a1,a4
    800028c8:	02000537          	lui	a0,0x2000
    800028cc:	157d                	addi	a0,a0,-1
    800028ce:	0536                	slli	a0,a0,0xd
    800028d0:	9782                	jalr	a5
}
    800028d2:	60a2                	ld	ra,8(sp)
    800028d4:	6402                	ld	s0,0(sp)
    800028d6:	0141                	addi	sp,sp,16
    800028d8:	8082                	ret

00000000800028da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028da:	1101                	addi	sp,sp,-32
    800028dc:	ec06                	sd	ra,24(sp)
    800028de:	e822                	sd	s0,16(sp)
    800028e0:	e426                	sd	s1,8(sp)
    800028e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e4:	00015497          	auipc	s1,0x15
    800028e8:	08448493          	addi	s1,s1,132 # 80017968 <tickslock>
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	310080e7          	jalr	784(ra) # 80000bfe <acquire>
  ticks++;
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	72a50513          	addi	a0,a0,1834 # 80009020 <ticks>
    800028fe:	411c                	lw	a5,0(a0)
    80002900:	2785                	addiw	a5,a5,1
    80002902:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002904:	00000097          	auipc	ra,0x0
    80002908:	b5c080e7          	jalr	-1188(ra) # 80002460 <wakeup>
  release(&tickslock);
    8000290c:	8526                	mv	a0,s1
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	3a4080e7          	jalr	932(ra) # 80000cb2 <release>
}
    80002916:	60e2                	ld	ra,24(sp)
    80002918:	6442                	ld	s0,16(sp)
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	6105                	addi	sp,sp,32
    8000291e:	8082                	ret

0000000080002920 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000292a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000292e:	00074d63          	bltz	a4,80002948 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002932:	57fd                	li	a5,-1
    80002934:	17fe                	slli	a5,a5,0x3f
    80002936:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002938:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000293a:	06f70363          	beq	a4,a5,800029a0 <devintr+0x80>
  }
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6105                	addi	sp,sp,32
    80002946:	8082                	ret
     (scause & 0xff) == 9){
    80002948:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000294c:	46a5                	li	a3,9
    8000294e:	fed792e3          	bne	a5,a3,80002932 <devintr+0x12>
    int irq = plic_claim();
    80002952:	00003097          	auipc	ra,0x3
    80002956:	556080e7          	jalr	1366(ra) # 80005ea8 <plic_claim>
    8000295a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000295c:	47a9                	li	a5,10
    8000295e:	02f50763          	beq	a0,a5,8000298c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002962:	4785                	li	a5,1
    80002964:	02f50963          	beq	a0,a5,80002996 <devintr+0x76>
    return 1;
    80002968:	4505                	li	a0,1
    } else if(irq){
    8000296a:	d8f1                	beqz	s1,8000293e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000296c:	85a6                	mv	a1,s1
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	96a50513          	addi	a0,a0,-1686 # 800082d8 <states.0+0x30>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	c16080e7          	jalr	-1002(ra) # 8000058c <printf>
      plic_complete(irq);
    8000297e:	8526                	mv	a0,s1
    80002980:	00003097          	auipc	ra,0x3
    80002984:	54c080e7          	jalr	1356(ra) # 80005ecc <plic_complete>
    return 1;
    80002988:	4505                	li	a0,1
    8000298a:	bf55                	j	8000293e <devintr+0x1e>
      uartintr();
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	036080e7          	jalr	54(ra) # 800009c2 <uartintr>
    80002994:	b7ed                	j	8000297e <devintr+0x5e>
      virtio_disk_intr();
    80002996:	00004097          	auipc	ra,0x4
    8000299a:	9ba080e7          	jalr	-1606(ra) # 80006350 <virtio_disk_intr>
    8000299e:	b7c5                	j	8000297e <devintr+0x5e>
    if(cpuid() == 0){
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	068080e7          	jalr	104(ra) # 80001a08 <cpuid>
    800029a8:	c901                	beqz	a0,800029b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029b0:	14479073          	csrw	sip,a5
    return 2;
    800029b4:	4509                	li	a0,2
    800029b6:	b761                	j	8000293e <devintr+0x1e>
      clockintr();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	f22080e7          	jalr	-222(ra) # 800028da <clockintr>
    800029c0:	b7ed                	j	800029aa <devintr+0x8a>

00000000800029c2 <usertrap>:
{
    800029c2:	7179                	addi	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029d4:	1007f793          	andi	a5,a5,256
    800029d8:	e3b5                	bnez	a5,80002a3c <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029da:	00003797          	auipc	a5,0x3
    800029de:	3c678793          	addi	a5,a5,966 # 80005da0 <kernelvec>
    800029e2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	04e080e7          	jalr	78(ra) # 80001a34 <myproc>
    800029ee:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029f0:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	14102773          	csrr	a4,sepc
    800029f6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029fc:	47a1                	li	a5,8
    800029fe:	04f71d63          	bne	a4,a5,80002a58 <usertrap+0x96>
    if(p->killed)
    80002a02:	591c                	lw	a5,48(a0)
    80002a04:	e7a1                	bnez	a5,80002a4c <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002a06:	70b8                	ld	a4,96(s1)
    80002a08:	6f1c                	ld	a5,24(a4)
    80002a0a:	0791                	addi	a5,a5,4
    80002a0c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a16:	10079073          	csrw	sstatus,a5
    syscall();
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	312080e7          	jalr	786(ra) # 80002d2c <syscall>
  if(p->killed)
    80002a22:	589c                	lw	a5,48(s1)
    80002a24:	e3e9                	bnez	a5,80002ae6 <usertrap+0x124>
  usertrapret();
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	e16080e7          	jalr	-490(ra) # 8000283c <usertrapret>
}
    80002a2e:	70a2                	ld	ra,40(sp)
    80002a30:	7402                	ld	s0,32(sp)
    80002a32:	64e2                	ld	s1,24(sp)
    80002a34:	6942                	ld	s2,16(sp)
    80002a36:	69a2                	ld	s3,8(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	8bc50513          	addi	a0,a0,-1860 # 800082f8 <states.0+0x50>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	afe080e7          	jalr	-1282(ra) # 80000542 <panic>
      exit(-1);
    80002a4c:	557d                	li	a0,-1
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	74c080e7          	jalr	1868(ra) # 8000219a <exit>
    80002a56:	bf45                	j	80002a06 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	ec8080e7          	jalr	-312(ra) # 80002920 <devintr>
    80002a60:	892a                	mv	s2,a0
    80002a62:	ed3d                	bnez	a0,80002ae0 <usertrap+0x11e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a64:	143029f3          	csrr	s3,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a68:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){
    80002a6c:	47b5                	li	a5,13
    80002a6e:	04f70d63          	beq	a4,a5,80002ac8 <usertrap+0x106>
    80002a72:	14202773          	csrr	a4,scause
    80002a76:	47bd                	li	a5,15
    80002a78:	04f70863          	beq	a4,a5,80002ac8 <usertrap+0x106>
    80002a7c:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a80:	5c90                	lw	a2,56(s1)
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	89650513          	addi	a0,a0,-1898 # 80008318 <states.0+0x70>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b02080e7          	jalr	-1278(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a96:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8ae50513          	addi	a0,a0,-1874 # 80008348 <states.0+0xa0>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	aea080e7          	jalr	-1302(ra) # 8000058c <printf>
      p->killed = 1;
    80002aaa:	4785                	li	a5,1
    80002aac:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002aae:	557d                	li	a0,-1
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	6ea080e7          	jalr	1770(ra) # 8000219a <exit>
  if(which_dev == 2)
    80002ab8:	4789                	li	a5,2
    80002aba:	f6f916e3          	bne	s2,a5,80002a26 <usertrap+0x64>
    yield();
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	7e6080e7          	jalr	2022(ra) # 800022a4 <yield>
    80002ac6:	b785                	j	80002a26 <usertrap+0x64>
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){
    80002ac8:	854e                	mv	a0,s3
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	c76080e7          	jalr	-906(ra) # 80002740 <uvmshouldtouch>
    80002ad2:	d54d                	beqz	a0,80002a7c <usertrap+0xba>
      uvmlazytouch(va);
    80002ad4:	854e                	mv	a0,s3
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	bbe080e7          	jalr	-1090(ra) # 80002694 <uvmlazytouch>
    80002ade:	b791                	j	80002a22 <usertrap+0x60>
  if(p->killed)
    80002ae0:	589c                	lw	a5,48(s1)
    80002ae2:	dbf9                	beqz	a5,80002ab8 <usertrap+0xf6>
    80002ae4:	b7e9                	j	80002aae <usertrap+0xec>
    80002ae6:	4901                	li	s2,0
    80002ae8:	b7d9                	j	80002aae <usertrap+0xec>

0000000080002aea <kerneltrap>:
{
    80002aea:	7179                	addi	sp,sp,-48
    80002aec:	f406                	sd	ra,40(sp)
    80002aee:	f022                	sd	s0,32(sp)
    80002af0:	ec26                	sd	s1,24(sp)
    80002af2:	e84a                	sd	s2,16(sp)
    80002af4:	e44e                	sd	s3,8(sp)
    80002af6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b00:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b04:	1004f793          	andi	a5,s1,256
    80002b08:	cb85                	beqz	a5,80002b38 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b10:	ef85                	bnez	a5,80002b48 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	e0e080e7          	jalr	-498(ra) # 80002920 <devintr>
    80002b1a:	cd1d                	beqz	a0,80002b58 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1c:	4789                	li	a5,2
    80002b1e:	06f50a63          	beq	a0,a5,80002b92 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b22:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10049073          	csrw	sstatus,s1
}
    80002b2a:	70a2                	ld	ra,40(sp)
    80002b2c:	7402                	ld	s0,32(sp)
    80002b2e:	64e2                	ld	s1,24(sp)
    80002b30:	6942                	ld	s2,16(sp)
    80002b32:	69a2                	ld	s3,8(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	83050513          	addi	a0,a0,-2000 # 80008368 <states.0+0xc0>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a02080e7          	jalr	-1534(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	84850513          	addi	a0,a0,-1976 # 80008390 <states.0+0xe8>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9f2080e7          	jalr	-1550(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002b58:	85ce                	mv	a1,s3
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	85650513          	addi	a0,a0,-1962 # 800083b0 <states.0+0x108>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a2a080e7          	jalr	-1494(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	84e50513          	addi	a0,a0,-1970 # 800083c0 <states.0+0x118>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a12080e7          	jalr	-1518(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	85650513          	addi	a0,a0,-1962 # 800083d8 <states.0+0x130>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9b8080e7          	jalr	-1608(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	ea2080e7          	jalr	-350(ra) # 80001a34 <myproc>
    80002b9a:	d541                	beqz	a0,80002b22 <kerneltrap+0x38>
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	e98080e7          	jalr	-360(ra) # 80001a34 <myproc>
    80002ba4:	4d18                	lw	a4,24(a0)
    80002ba6:	478d                	li	a5,3
    80002ba8:	f6f71de3          	bne	a4,a5,80002b22 <kerneltrap+0x38>
    yield();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	6f8080e7          	jalr	1784(ra) # 800022a4 <yield>
    80002bb4:	b7bd                	j	80002b22 <kerneltrap+0x38>

0000000080002bb6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	e72080e7          	jalr	-398(ra) # 80001a34 <myproc>
  switch (n) {
    80002bca:	4795                	li	a5,5
    80002bcc:	0497e163          	bltu	a5,s1,80002c0e <argraw+0x58>
    80002bd0:	048a                	slli	s1,s1,0x2
    80002bd2:	00006717          	auipc	a4,0x6
    80002bd6:	83e70713          	addi	a4,a4,-1986 # 80008410 <states.0+0x168>
    80002bda:	94ba                	add	s1,s1,a4
    80002bdc:	409c                	lw	a5,0(s1)
    80002bde:	97ba                	add	a5,a5,a4
    80002be0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be2:	713c                	ld	a5,96(a0)
    80002be4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret
    return p->trapframe->a1;
    80002bf0:	713c                	ld	a5,96(a0)
    80002bf2:	7fa8                	ld	a0,120(a5)
    80002bf4:	bfcd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a2;
    80002bf6:	713c                	ld	a5,96(a0)
    80002bf8:	63c8                	ld	a0,128(a5)
    80002bfa:	b7f5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a3;
    80002bfc:	713c                	ld	a5,96(a0)
    80002bfe:	67c8                	ld	a0,136(a5)
    80002c00:	b7dd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a4;
    80002c02:	713c                	ld	a5,96(a0)
    80002c04:	6bc8                	ld	a0,144(a5)
    80002c06:	b7c5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a5;
    80002c08:	713c                	ld	a5,96(a0)
    80002c0a:	6fc8                	ld	a0,152(a5)
    80002c0c:	bfe9                	j	80002be6 <argraw+0x30>
  panic("argraw");
    80002c0e:	00005517          	auipc	a0,0x5
    80002c12:	7da50513          	addi	a0,a0,2010 # 800083e8 <states.0+0x140>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	92c080e7          	jalr	-1748(ra) # 80000542 <panic>

0000000080002c1e <fetchaddr>:
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	e04a                	sd	s2,0(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84aa                	mv	s1,a0
    80002c2c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	e06080e7          	jalr	-506(ra) # 80001a34 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c36:	653c                	ld	a5,72(a0)
    80002c38:	02f4f863          	bgeu	s1,a5,80002c68 <fetchaddr+0x4a>
    80002c3c:	00848713          	addi	a4,s1,8
    80002c40:	02e7e663          	bltu	a5,a4,80002c6c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c44:	46a1                	li	a3,8
    80002c46:	8626                	mv	a2,s1
    80002c48:	85ca                	mv	a1,s2
    80002c4a:	6928                	ld	a0,80(a0)
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	be6080e7          	jalr	-1050(ra) # 80001832 <copyin>
    80002c54:	00a03533          	snez	a0,a0
    80002c58:	40a00533          	neg	a0,a0
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6902                	ld	s2,0(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    return -1;
    80002c68:	557d                	li	a0,-1
    80002c6a:	bfcd                	j	80002c5c <fetchaddr+0x3e>
    80002c6c:	557d                	li	a0,-1
    80002c6e:	b7fd                	j	80002c5c <fetchaddr+0x3e>

0000000080002c70 <fetchstr>:
{
    80002c70:	7179                	addi	sp,sp,-48
    80002c72:	f406                	sd	ra,40(sp)
    80002c74:	f022                	sd	s0,32(sp)
    80002c76:	ec26                	sd	s1,24(sp)
    80002c78:	e84a                	sd	s2,16(sp)
    80002c7a:	e44e                	sd	s3,8(sp)
    80002c7c:	1800                	addi	s0,sp,48
    80002c7e:	892a                	mv	s2,a0
    80002c80:	84ae                	mv	s1,a1
    80002c82:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	db0080e7          	jalr	-592(ra) # 80001a34 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c8c:	86ce                	mv	a3,s3
    80002c8e:	864a                	mv	a2,s2
    80002c90:	85a6                	mv	a1,s1
    80002c92:	6928                	ld	a0,80(a0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	bb6080e7          	jalr	-1098(ra) # 8000184a <copyinstr>
  if(err < 0)
    80002c9c:	00054763          	bltz	a0,80002caa <fetchstr+0x3a>
  return strlen(buf);
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	1dc080e7          	jalr	476(ra) # 80000e7e <strlen>
}
    80002caa:	70a2                	ld	ra,40(sp)
    80002cac:	7402                	ld	s0,32(sp)
    80002cae:	64e2                	ld	s1,24(sp)
    80002cb0:	6942                	ld	s2,16(sp)
    80002cb2:	69a2                	ld	s3,8(sp)
    80002cb4:	6145                	addi	sp,sp,48
    80002cb6:	8082                	ret

0000000080002cb8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ef2080e7          	jalr	-270(ra) # 80002bb6 <argraw>
    80002ccc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cce:	4501                	li	a0,0
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	64a2                	ld	s1,8(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	ed0080e7          	jalr	-304(ra) # 80002bb6 <argraw>
    80002cee:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cf0:	4501                	li	a0,0
    80002cf2:	60e2                	ld	ra,24(sp)
    80002cf4:	6442                	ld	s0,16(sp)
    80002cf6:	64a2                	ld	s1,8(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	e04a                	sd	s2,0(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84ae                	mv	s1,a1
    80002d0a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	eaa080e7          	jalr	-342(ra) # 80002bb6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d14:	864a                	mv	a2,s2
    80002d16:	85a6                	mv	a1,s1
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	f58080e7          	jalr	-168(ra) # 80002c70 <fetchstr>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6902                	ld	s2,0(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	cfc080e7          	jalr	-772(ra) # 80001a34 <myproc>
    80002d40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d42:	06053903          	ld	s2,96(a0)
    80002d46:	0a893783          	ld	a5,168(s2)
    80002d4a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d4e:	37fd                	addiw	a5,a5,-1
    80002d50:	4751                	li	a4,20
    80002d52:	00f76f63          	bltu	a4,a5,80002d70 <syscall+0x44>
    80002d56:	00369713          	slli	a4,a3,0x3
    80002d5a:	00005797          	auipc	a5,0x5
    80002d5e:	6ce78793          	addi	a5,a5,1742 # 80008428 <syscalls>
    80002d62:	97ba                	add	a5,a5,a4
    80002d64:	639c                	ld	a5,0(a5)
    80002d66:	c789                	beqz	a5,80002d70 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d68:	9782                	jalr	a5
    80002d6a:	06a93823          	sd	a0,112(s2)
    80002d6e:	a839                	j	80002d8c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d70:	16048613          	addi	a2,s1,352
    80002d74:	5c8c                	lw	a1,56(s1)
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	67a50513          	addi	a0,a0,1658 # 800083f0 <states.0+0x148>
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	80e080e7          	jalr	-2034(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d86:	70bc                	ld	a5,96(s1)
    80002d88:	577d                	li	a4,-1
    80002d8a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6902                	ld	s2,0(sp)
    80002d94:	6105                	addi	sp,sp,32
    80002d96:	8082                	ret

0000000080002d98 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002da0:	fec40593          	addi	a1,s0,-20
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	f12080e7          	jalr	-238(ra) # 80002cb8 <argint>
    return -1;
    80002dae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db0:	00054963          	bltz	a0,80002dc2 <sys_exit+0x2a>
  exit(n);
    80002db4:	fec42503          	lw	a0,-20(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	3e2080e7          	jalr	994(ra) # 8000219a <exit>
  return 0;  // not reached
    80002dc0:	4781                	li	a5,0
}
    80002dc2:	853e                	mv	a0,a5
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	c60080e7          	jalr	-928(ra) # 80001a34 <myproc>
}
    80002ddc:	5d08                	lw	a0,56(a0)
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <sys_fork>:

uint64
sys_fork(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return fork();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	06c080e7          	jalr	108(ra) # 80001e5a <fork>
}
    80002df6:	60a2                	ld	ra,8(sp)
    80002df8:	6402                	ld	s0,0(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <sys_wait>:

uint64
sys_wait(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e06:	fe840593          	addi	a1,s0,-24
    80002e0a:	4501                	li	a0,0
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	ece080e7          	jalr	-306(ra) # 80002cda <argaddr>
    80002e14:	87aa                	mv	a5,a0
    return -1;
    80002e16:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e18:	0007c863          	bltz	a5,80002e28 <sys_wait+0x2a>
  return wait(p);
    80002e1c:	fe843503          	ld	a0,-24(s0)
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	53e080e7          	jalr	1342(ra) # 8000235e <wait>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e30:	7179                	addi	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	e84a                	sd	s2,16(sp)
    80002e3a:	1800                	addi	s0,sp,48
  int addr;
  int n;
  struct proc* p = myproc();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	bf8080e7          	jalr	-1032(ra) # 80001a34 <myproc>
    80002e44:	84aa                	mv	s1,a0
  if(argint(0, &n) < 0)
    80002e46:	fdc40593          	addi	a1,s0,-36
    80002e4a:	4501                	li	a0,0
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	e6c080e7          	jalr	-404(ra) # 80002cb8 <argint>
    80002e54:	04054563          	bltz	a0,80002e9e <sys_sbrk+0x6e>
    return -1;
  addr = p->sz;
    80002e58:	64ac                	ld	a1,72(s1)
    80002e5a:	0005891b          	sext.w	s2,a1
  if(n < 0){
    80002e5e:	fdc42603          	lw	a2,-36(s0)
    80002e62:	00064e63          	bltz	a2,80002e7e <sys_sbrk+0x4e>
    uvmalloc(p->kernelpgtbl, p->sz, p->sz+n);
  }
  /*if(growproc(n) < 0)
    return -1;*/

  p->sz += n; //懒分配
    80002e66:	fdc42703          	lw	a4,-36(s0)
    80002e6a:	64bc                	ld	a5,72(s1)
    80002e6c:	97ba                	add	a5,a5,a4
    80002e6e:	e4bc                	sd	a5,72(s1)
  return addr;
    80002e70:	854a                	mv	a0,s2
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    uvmalloc(p->pagetable, p->sz, p->sz+n);
    80002e7e:	962e                	add	a2,a2,a1
    80002e80:	68a8                	ld	a0,80(s1)
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	610080e7          	jalr	1552(ra) # 80001492 <uvmalloc>
    uvmalloc(p->kernelpgtbl, p->sz, p->sz+n);
    80002e8a:	64ac                	ld	a1,72(s1)
    80002e8c:	fdc42603          	lw	a2,-36(s0)
    80002e90:	962e                	add	a2,a2,a1
    80002e92:	6ca8                	ld	a0,88(s1)
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	5fe080e7          	jalr	1534(ra) # 80001492 <uvmalloc>
    80002e9c:	b7e9                	j	80002e66 <sys_sbrk+0x36>
    return -1;
    80002e9e:	557d                	li	a0,-1
    80002ea0:	bfc9                	j	80002e72 <sys_sbrk+0x42>

0000000080002ea2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea2:	7139                	addi	sp,sp,-64
    80002ea4:	fc06                	sd	ra,56(sp)
    80002ea6:	f822                	sd	s0,48(sp)
    80002ea8:	f426                	sd	s1,40(sp)
    80002eaa:	f04a                	sd	s2,32(sp)
    80002eac:	ec4e                	sd	s3,24(sp)
    80002eae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eb0:	fcc40593          	addi	a1,s0,-52
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	e02080e7          	jalr	-510(ra) # 80002cb8 <argint>
    return -1;
    80002ebe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec0:	06054563          	bltz	a0,80002f2a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ec4:	00015517          	auipc	a0,0x15
    80002ec8:	aa450513          	addi	a0,a0,-1372 # 80017968 <tickslock>
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	d32080e7          	jalr	-718(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002ed4:	00006917          	auipc	s2,0x6
    80002ed8:	14c92903          	lw	s2,332(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002edc:	fcc42783          	lw	a5,-52(s0)
    80002ee0:	cf85                	beqz	a5,80002f18 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ee2:	00015997          	auipc	s3,0x15
    80002ee6:	a8698993          	addi	s3,s3,-1402 # 80017968 <tickslock>
    80002eea:	00006497          	auipc	s1,0x6
    80002eee:	13648493          	addi	s1,s1,310 # 80009020 <ticks>
    if(myproc()->killed){
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	b42080e7          	jalr	-1214(ra) # 80001a34 <myproc>
    80002efa:	591c                	lw	a5,48(a0)
    80002efc:	ef9d                	bnez	a5,80002f3a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002efe:	85ce                	mv	a1,s3
    80002f00:	8526                	mv	a0,s1
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	3de080e7          	jalr	990(ra) # 800022e0 <sleep>
  while(ticks - ticks0 < n){
    80002f0a:	409c                	lw	a5,0(s1)
    80002f0c:	412787bb          	subw	a5,a5,s2
    80002f10:	fcc42703          	lw	a4,-52(s0)
    80002f14:	fce7efe3          	bltu	a5,a4,80002ef2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f18:	00015517          	auipc	a0,0x15
    80002f1c:	a5050513          	addi	a0,a0,-1456 # 80017968 <tickslock>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	d92080e7          	jalr	-622(ra) # 80000cb2 <release>
  return 0;
    80002f28:	4781                	li	a5,0
}
    80002f2a:	853e                	mv	a0,a5
    80002f2c:	70e2                	ld	ra,56(sp)
    80002f2e:	7442                	ld	s0,48(sp)
    80002f30:	74a2                	ld	s1,40(sp)
    80002f32:	7902                	ld	s2,32(sp)
    80002f34:	69e2                	ld	s3,24(sp)
    80002f36:	6121                	addi	sp,sp,64
    80002f38:	8082                	ret
      release(&tickslock);
    80002f3a:	00015517          	auipc	a0,0x15
    80002f3e:	a2e50513          	addi	a0,a0,-1490 # 80017968 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	d70080e7          	jalr	-656(ra) # 80000cb2 <release>
      return -1;
    80002f4a:	57fd                	li	a5,-1
    80002f4c:	bff9                	j	80002f2a <sys_sleep+0x88>

0000000080002f4e <sys_kill>:

uint64
sys_kill(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f56:	fec40593          	addi	a1,s0,-20
    80002f5a:	4501                	li	a0,0
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	d5c080e7          	jalr	-676(ra) # 80002cb8 <argint>
    80002f64:	87aa                	mv	a5,a0
    return -1;
    80002f66:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f68:	0007c863          	bltz	a5,80002f78 <sys_kill+0x2a>
  return kill(pid);
    80002f6c:	fec42503          	lw	a0,-20(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	55a080e7          	jalr	1370(ra) # 800024ca <kill>
}
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f8a:	00015517          	auipc	a0,0x15
    80002f8e:	9de50513          	addi	a0,a0,-1570 # 80017968 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	c6c080e7          	jalr	-916(ra) # 80000bfe <acquire>
  xticks = ticks;
    80002f9a:	00006497          	auipc	s1,0x6
    80002f9e:	0864a483          	lw	s1,134(s1) # 80009020 <ticks>
  release(&tickslock);
    80002fa2:	00015517          	auipc	a0,0x15
    80002fa6:	9c650513          	addi	a0,a0,-1594 # 80017968 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	d08080e7          	jalr	-760(ra) # 80000cb2 <release>
  return xticks;
}
    80002fb2:	02049513          	slli	a0,s1,0x20
    80002fb6:	9101                	srli	a0,a0,0x20
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fc2:	7179                	addi	sp,sp,-48
    80002fc4:	f406                	sd	ra,40(sp)
    80002fc6:	f022                	sd	s0,32(sp)
    80002fc8:	ec26                	sd	s1,24(sp)
    80002fca:	e84a                	sd	s2,16(sp)
    80002fcc:	e44e                	sd	s3,8(sp)
    80002fce:	e052                	sd	s4,0(sp)
    80002fd0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fd2:	00005597          	auipc	a1,0x5
    80002fd6:	50658593          	addi	a1,a1,1286 # 800084d8 <syscalls+0xb0>
    80002fda:	00015517          	auipc	a0,0x15
    80002fde:	9a650513          	addi	a0,a0,-1626 # 80017980 <bcache>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	b8c080e7          	jalr	-1140(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fea:	0001d797          	auipc	a5,0x1d
    80002fee:	99678793          	addi	a5,a5,-1642 # 8001f980 <bcache+0x8000>
    80002ff2:	0001d717          	auipc	a4,0x1d
    80002ff6:	bf670713          	addi	a4,a4,-1034 # 8001fbe8 <bcache+0x8268>
    80002ffa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ffe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003002:	00015497          	auipc	s1,0x15
    80003006:	99648493          	addi	s1,s1,-1642 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    8000300a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000300c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000300e:	00005a17          	auipc	s4,0x5
    80003012:	4d2a0a13          	addi	s4,s4,1234 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003016:	2b893783          	ld	a5,696(s2)
    8000301a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000301c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003020:	85d2                	mv	a1,s4
    80003022:	01048513          	addi	a0,s1,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	4ac080e7          	jalr	1196(ra) # 800044d2 <initsleeplock>
    bcache.head.next->prev = b;
    8000302e:	2b893783          	ld	a5,696(s2)
    80003032:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003034:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003038:	45848493          	addi	s1,s1,1112
    8000303c:	fd349de3          	bne	s1,s3,80003016 <binit+0x54>
  }
}
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	69a2                	ld	s3,8(sp)
    8000304a:	6a02                	ld	s4,0(sp)
    8000304c:	6145                	addi	sp,sp,48
    8000304e:	8082                	ret

0000000080003050 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003050:	7179                	addi	sp,sp,-48
    80003052:	f406                	sd	ra,40(sp)
    80003054:	f022                	sd	s0,32(sp)
    80003056:	ec26                	sd	s1,24(sp)
    80003058:	e84a                	sd	s2,16(sp)
    8000305a:	e44e                	sd	s3,8(sp)
    8000305c:	1800                	addi	s0,sp,48
    8000305e:	892a                	mv	s2,a0
    80003060:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003062:	00015517          	auipc	a0,0x15
    80003066:	91e50513          	addi	a0,a0,-1762 # 80017980 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	b94080e7          	jalr	-1132(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003072:	0001d497          	auipc	s1,0x1d
    80003076:	bc64b483          	ld	s1,-1082(s1) # 8001fc38 <bcache+0x82b8>
    8000307a:	0001d797          	auipc	a5,0x1d
    8000307e:	b6e78793          	addi	a5,a5,-1170 # 8001fbe8 <bcache+0x8268>
    80003082:	02f48f63          	beq	s1,a5,800030c0 <bread+0x70>
    80003086:	873e                	mv	a4,a5
    80003088:	a021                	j	80003090 <bread+0x40>
    8000308a:	68a4                	ld	s1,80(s1)
    8000308c:	02e48a63          	beq	s1,a4,800030c0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003090:	449c                	lw	a5,8(s1)
    80003092:	ff279ce3          	bne	a5,s2,8000308a <bread+0x3a>
    80003096:	44dc                	lw	a5,12(s1)
    80003098:	ff3799e3          	bne	a5,s3,8000308a <bread+0x3a>
      b->refcnt++;
    8000309c:	40bc                	lw	a5,64(s1)
    8000309e:	2785                	addiw	a5,a5,1
    800030a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	8de50513          	addi	a0,a0,-1826 # 80017980 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	c08080e7          	jalr	-1016(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    800030b2:	01048513          	addi	a0,s1,16
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	456080e7          	jalr	1110(ra) # 8000450c <acquiresleep>
      return b;
    800030be:	a8b9                	j	8000311c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c0:	0001d497          	auipc	s1,0x1d
    800030c4:	b704b483          	ld	s1,-1168(s1) # 8001fc30 <bcache+0x82b0>
    800030c8:	0001d797          	auipc	a5,0x1d
    800030cc:	b2078793          	addi	a5,a5,-1248 # 8001fbe8 <bcache+0x8268>
    800030d0:	00f48863          	beq	s1,a5,800030e0 <bread+0x90>
    800030d4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	cf81                	beqz	a5,800030f0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030da:	64a4                	ld	s1,72(s1)
    800030dc:	fee49de3          	bne	s1,a4,800030d6 <bread+0x86>
  panic("bget: no buffers");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	40850513          	addi	a0,a0,1032 # 800084e8 <syscalls+0xc0>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	45a080e7          	jalr	1114(ra) # 80000542 <panic>
      b->dev = dev;
    800030f0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030f4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030fc:	4785                	li	a5,1
    800030fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003100:	00015517          	auipc	a0,0x15
    80003104:	88050513          	addi	a0,a0,-1920 # 80017980 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	baa080e7          	jalr	-1110(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80003110:	01048513          	addi	a0,s1,16
    80003114:	00001097          	auipc	ra,0x1
    80003118:	3f8080e7          	jalr	1016(ra) # 8000450c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000311c:	409c                	lw	a5,0(s1)
    8000311e:	cb89                	beqz	a5,80003130 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003120:	8526                	mv	a0,s1
    80003122:	70a2                	ld	ra,40(sp)
    80003124:	7402                	ld	s0,32(sp)
    80003126:	64e2                	ld	s1,24(sp)
    80003128:	6942                	ld	s2,16(sp)
    8000312a:	69a2                	ld	s3,8(sp)
    8000312c:	6145                	addi	sp,sp,48
    8000312e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003130:	4581                	li	a1,0
    80003132:	8526                	mv	a0,s1
    80003134:	00003097          	auipc	ra,0x3
    80003138:	f88080e7          	jalr	-120(ra) # 800060bc <virtio_disk_rw>
    b->valid = 1;
    8000313c:	4785                	li	a5,1
    8000313e:	c09c                	sw	a5,0(s1)
  return b;
    80003140:	b7c5                	j	80003120 <bread+0xd0>

0000000080003142 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314e:	0541                	addi	a0,a0,16
    80003150:	00001097          	auipc	ra,0x1
    80003154:	456080e7          	jalr	1110(ra) # 800045a6 <holdingsleep>
    80003158:	cd01                	beqz	a0,80003170 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000315a:	4585                	li	a1,1
    8000315c:	8526                	mv	a0,s1
    8000315e:	00003097          	auipc	ra,0x3
    80003162:	f5e080e7          	jalr	-162(ra) # 800060bc <virtio_disk_rw>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret
    panic("bwrite");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	39050513          	addi	a0,a0,912 # 80008500 <syscalls+0xd8>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3ca080e7          	jalr	970(ra) # 80000542 <panic>

0000000080003180 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	e04a                	sd	s2,0(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000318e:	01050913          	addi	s2,a0,16
    80003192:	854a                	mv	a0,s2
    80003194:	00001097          	auipc	ra,0x1
    80003198:	412080e7          	jalr	1042(ra) # 800045a6 <holdingsleep>
    8000319c:	c92d                	beqz	a0,8000320e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	3c2080e7          	jalr	962(ra) # 80004562 <releasesleep>

  acquire(&bcache.lock);
    800031a8:	00014517          	auipc	a0,0x14
    800031ac:	7d850513          	addi	a0,a0,2008 # 80017980 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	a4e080e7          	jalr	-1458(ra) # 80000bfe <acquire>
  b->refcnt--;
    800031b8:	40bc                	lw	a5,64(s1)
    800031ba:	37fd                	addiw	a5,a5,-1
    800031bc:	0007871b          	sext.w	a4,a5
    800031c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031c2:	eb05                	bnez	a4,800031f2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c4:	68bc                	ld	a5,80(s1)
    800031c6:	64b8                	ld	a4,72(s1)
    800031c8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031ca:	64bc                	ld	a5,72(s1)
    800031cc:	68b8                	ld	a4,80(s1)
    800031ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031d0:	0001c797          	auipc	a5,0x1c
    800031d4:	7b078793          	addi	a5,a5,1968 # 8001f980 <bcache+0x8000>
    800031d8:	2b87b703          	ld	a4,696(a5)
    800031dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031de:	0001d717          	auipc	a4,0x1d
    800031e2:	a0a70713          	addi	a4,a4,-1526 # 8001fbe8 <bcache+0x8268>
    800031e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e8:	2b87b703          	ld	a4,696(a5)
    800031ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	78e50513          	addi	a0,a0,1934 # 80017980 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	ab8080e7          	jalr	-1352(ra) # 80000cb2 <release>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6902                	ld	s2,0(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret
    panic("brelse");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	2fa50513          	addi	a0,a0,762 # 80008508 <syscalls+0xe0>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	32c080e7          	jalr	812(ra) # 80000542 <panic>

000000008000321e <bpin>:

void
bpin(struct buf *b) {
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	1000                	addi	s0,sp,32
    80003228:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322a:	00014517          	auipc	a0,0x14
    8000322e:	75650513          	addi	a0,a0,1878 # 80017980 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	9cc080e7          	jalr	-1588(ra) # 80000bfe <acquire>
  b->refcnt++;
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	2785                	addiw	a5,a5,1
    8000323e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003240:	00014517          	auipc	a0,0x14
    80003244:	74050513          	addi	a0,a0,1856 # 80017980 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret

000000008000325a <bunpin>:

void
bunpin(struct buf *b) {
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	71a50513          	addi	a0,a0,1818 # 80017980 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	990080e7          	jalr	-1648(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003276:	40bc                	lw	a5,64(s1)
    80003278:	37fd                	addiw	a5,a5,-1
    8000327a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	70450513          	addi	a0,a0,1796 # 80017980 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a2e080e7          	jalr	-1490(ra) # 80000cb2 <release>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	e426                	sd	s1,8(sp)
    8000329e:	e04a                	sd	s2,0(sp)
    800032a0:	1000                	addi	s0,sp,32
    800032a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a4:	00d5d59b          	srliw	a1,a1,0xd
    800032a8:	0001d797          	auipc	a5,0x1d
    800032ac:	db47a783          	lw	a5,-588(a5) # 8002005c <sb+0x1c>
    800032b0:	9dbd                	addw	a1,a1,a5
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	d9e080e7          	jalr	-610(ra) # 80003050 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ba:	0074f713          	andi	a4,s1,7
    800032be:	4785                	li	a5,1
    800032c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c4:	14ce                	slli	s1,s1,0x33
    800032c6:	90d9                	srli	s1,s1,0x36
    800032c8:	00950733          	add	a4,a0,s1
    800032cc:	05874703          	lbu	a4,88(a4)
    800032d0:	00e7f6b3          	and	a3,a5,a4
    800032d4:	c69d                	beqz	a3,80003302 <bfree+0x6c>
    800032d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d8:	94aa                	add	s1,s1,a0
    800032da:	fff7c793          	not	a5,a5
    800032de:	8ff9                	and	a5,a5,a4
    800032e0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	100080e7          	jalr	256(ra) # 800043e4 <log_write>
  brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	e92080e7          	jalr	-366(ra) # 80003180 <brelse>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6902                	ld	s2,0(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret
    panic("freeing free block");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	20e50513          	addi	a0,a0,526 # 80008510 <syscalls+0xe8>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	238080e7          	jalr	568(ra) # 80000542 <panic>

0000000080003312 <balloc>:
{
    80003312:	711d                	addi	sp,sp,-96
    80003314:	ec86                	sd	ra,88(sp)
    80003316:	e8a2                	sd	s0,80(sp)
    80003318:	e4a6                	sd	s1,72(sp)
    8000331a:	e0ca                	sd	s2,64(sp)
    8000331c:	fc4e                	sd	s3,56(sp)
    8000331e:	f852                	sd	s4,48(sp)
    80003320:	f456                	sd	s5,40(sp)
    80003322:	f05a                	sd	s6,32(sp)
    80003324:	ec5e                	sd	s7,24(sp)
    80003326:	e862                	sd	s8,16(sp)
    80003328:	e466                	sd	s9,8(sp)
    8000332a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000332c:	0001d797          	auipc	a5,0x1d
    80003330:	d187a783          	lw	a5,-744(a5) # 80020044 <sb+0x4>
    80003334:	cbd1                	beqz	a5,800033c8 <balloc+0xb6>
    80003336:	8baa                	mv	s7,a0
    80003338:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000333a:	0001db17          	auipc	s6,0x1d
    8000333e:	d06b0b13          	addi	s6,s6,-762 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003344:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003348:	6c89                	lui	s9,0x2
    8000334a:	a831                	j	80003366 <balloc+0x54>
    brelse(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e32080e7          	jalr	-462(ra) # 80003180 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003356:	015c87bb          	addw	a5,s9,s5
    8000335a:	00078a9b          	sext.w	s5,a5
    8000335e:	004b2703          	lw	a4,4(s6)
    80003362:	06eaf363          	bgeu	s5,a4,800033c8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003366:	41fad79b          	sraiw	a5,s5,0x1f
    8000336a:	0137d79b          	srliw	a5,a5,0x13
    8000336e:	015787bb          	addw	a5,a5,s5
    80003372:	40d7d79b          	sraiw	a5,a5,0xd
    80003376:	01cb2583          	lw	a1,28(s6)
    8000337a:	9dbd                	addw	a1,a1,a5
    8000337c:	855e                	mv	a0,s7
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	cd2080e7          	jalr	-814(ra) # 80003050 <bread>
    80003386:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003388:	004b2503          	lw	a0,4(s6)
    8000338c:	000a849b          	sext.w	s1,s5
    80003390:	8662                	mv	a2,s8
    80003392:	faa4fde3          	bgeu	s1,a0,8000334c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003396:	41f6579b          	sraiw	a5,a2,0x1f
    8000339a:	01d7d69b          	srliw	a3,a5,0x1d
    8000339e:	00c6873b          	addw	a4,a3,a2
    800033a2:	00777793          	andi	a5,a4,7
    800033a6:	9f95                	subw	a5,a5,a3
    800033a8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ac:	4037571b          	sraiw	a4,a4,0x3
    800033b0:	00e906b3          	add	a3,s2,a4
    800033b4:	0586c683          	lbu	a3,88(a3)
    800033b8:	00d7f5b3          	and	a1,a5,a3
    800033bc:	cd91                	beqz	a1,800033d8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033be:	2605                	addiw	a2,a2,1
    800033c0:	2485                	addiw	s1,s1,1
    800033c2:	fd4618e3          	bne	a2,s4,80003392 <balloc+0x80>
    800033c6:	b759                	j	8000334c <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c8:	00005517          	auipc	a0,0x5
    800033cc:	16050513          	addi	a0,a0,352 # 80008528 <syscalls+0x100>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	172080e7          	jalr	370(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d8:	974a                	add	a4,a4,s2
    800033da:	8fd5                	or	a5,a5,a3
    800033dc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	002080e7          	jalr	2(ra) # 800043e4 <log_write>
        brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	d94080e7          	jalr	-620(ra) # 80003180 <brelse>
  bp = bread(dev, bno);
    800033f4:	85a6                	mv	a1,s1
    800033f6:	855e                	mv	a0,s7
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	c58080e7          	jalr	-936(ra) # 80003050 <bread>
    80003400:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003402:	40000613          	li	a2,1024
    80003406:	4581                	li	a1,0
    80003408:	05850513          	addi	a0,a0,88
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	8ee080e7          	jalr	-1810(ra) # 80000cfa <memset>
  log_write(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	fce080e7          	jalr	-50(ra) # 800043e4 <log_write>
  brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	d60080e7          	jalr	-672(ra) # 80003180 <brelse>
}
    80003428:	8526                	mv	a0,s1
    8000342a:	60e6                	ld	ra,88(sp)
    8000342c:	6446                	ld	s0,80(sp)
    8000342e:	64a6                	ld	s1,72(sp)
    80003430:	6906                	ld	s2,64(sp)
    80003432:	79e2                	ld	s3,56(sp)
    80003434:	7a42                	ld	s4,48(sp)
    80003436:	7aa2                	ld	s5,40(sp)
    80003438:	7b02                	ld	s6,32(sp)
    8000343a:	6be2                	ld	s7,24(sp)
    8000343c:	6c42                	ld	s8,16(sp)
    8000343e:	6ca2                	ld	s9,8(sp)
    80003440:	6125                	addi	sp,sp,96
    80003442:	8082                	ret

0000000080003444 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
    80003454:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003456:	47ad                	li	a5,11
    80003458:	04b7fe63          	bgeu	a5,a1,800034b4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000345c:	ff45849b          	addiw	s1,a1,-12
    80003460:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003464:	0ff00793          	li	a5,255
    80003468:	0ae7e363          	bltu	a5,a4,8000350e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000346c:	08052583          	lw	a1,128(a0)
    80003470:	c5ad                	beqz	a1,800034da <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003472:	00092503          	lw	a0,0(s2)
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	bda080e7          	jalr	-1062(ra) # 80003050 <bread>
    8000347e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003480:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003484:	02049593          	slli	a1,s1,0x20
    80003488:	9181                	srli	a1,a1,0x20
    8000348a:	058a                	slli	a1,a1,0x2
    8000348c:	00b784b3          	add	s1,a5,a1
    80003490:	0004a983          	lw	s3,0(s1)
    80003494:	04098d63          	beqz	s3,800034ee <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003498:	8552                	mv	a0,s4
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	ce6080e7          	jalr	-794(ra) # 80003180 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034a2:	854e                	mv	a0,s3
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6a02                	ld	s4,0(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b4:	02059493          	slli	s1,a1,0x20
    800034b8:	9081                	srli	s1,s1,0x20
    800034ba:	048a                	slli	s1,s1,0x2
    800034bc:	94aa                	add	s1,s1,a0
    800034be:	0504a983          	lw	s3,80(s1)
    800034c2:	fe0990e3          	bnez	s3,800034a2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034c6:	4108                	lw	a0,0(a0)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	e4a080e7          	jalr	-438(ra) # 80003312 <balloc>
    800034d0:	0005099b          	sext.w	s3,a0
    800034d4:	0534a823          	sw	s3,80(s1)
    800034d8:	b7e9                	j	800034a2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034da:	4108                	lw	a0,0(a0)
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	e36080e7          	jalr	-458(ra) # 80003312 <balloc>
    800034e4:	0005059b          	sext.w	a1,a0
    800034e8:	08b92023          	sw	a1,128(s2)
    800034ec:	b759                	j	80003472 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034ee:	00092503          	lw	a0,0(s2)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e20080e7          	jalr	-480(ra) # 80003312 <balloc>
    800034fa:	0005099b          	sext.w	s3,a0
    800034fe:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003502:	8552                	mv	a0,s4
    80003504:	00001097          	auipc	ra,0x1
    80003508:	ee0080e7          	jalr	-288(ra) # 800043e4 <log_write>
    8000350c:	b771                	j	80003498 <bmap+0x54>
  panic("bmap: out of range");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	03250513          	addi	a0,a0,50 # 80008540 <syscalls+0x118>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	02c080e7          	jalr	44(ra) # 80000542 <panic>

000000008000351e <iget>:
{
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	e052                	sd	s4,0(sp)
    8000352c:	1800                	addi	s0,sp,48
    8000352e:	89aa                	mv	s3,a0
    80003530:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003532:	0001d517          	auipc	a0,0x1d
    80003536:	b2e50513          	addi	a0,a0,-1234 # 80020060 <icache>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	6c4080e7          	jalr	1732(ra) # 80000bfe <acquire>
  empty = 0;
    80003542:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003544:	0001d497          	auipc	s1,0x1d
    80003548:	b3448493          	addi	s1,s1,-1228 # 80020078 <icache+0x18>
    8000354c:	0001e697          	auipc	a3,0x1e
    80003550:	5bc68693          	addi	a3,a3,1468 # 80021b08 <log>
    80003554:	a039                	j	80003562 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003556:	02090b63          	beqz	s2,8000358c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000355a:	08848493          	addi	s1,s1,136
    8000355e:	02d48a63          	beq	s1,a3,80003592 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003562:	449c                	lw	a5,8(s1)
    80003564:	fef059e3          	blez	a5,80003556 <iget+0x38>
    80003568:	4098                	lw	a4,0(s1)
    8000356a:	ff3716e3          	bne	a4,s3,80003556 <iget+0x38>
    8000356e:	40d8                	lw	a4,4(s1)
    80003570:	ff4713e3          	bne	a4,s4,80003556 <iget+0x38>
      ip->ref++;
    80003574:	2785                	addiw	a5,a5,1
    80003576:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003578:	0001d517          	auipc	a0,0x1d
    8000357c:	ae850513          	addi	a0,a0,-1304 # 80020060 <icache>
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	732080e7          	jalr	1842(ra) # 80000cb2 <release>
      return ip;
    80003588:	8926                	mv	s2,s1
    8000358a:	a03d                	j	800035b8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358c:	f7f9                	bnez	a5,8000355a <iget+0x3c>
    8000358e:	8926                	mv	s2,s1
    80003590:	b7e9                	j	8000355a <iget+0x3c>
  if(empty == 0)
    80003592:	02090c63          	beqz	s2,800035ca <iget+0xac>
  ip->dev = dev;
    80003596:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000359a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359e:	4785                	li	a5,1
    800035a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035a8:	0001d517          	auipc	a0,0x1d
    800035ac:	ab850513          	addi	a0,a0,-1352 # 80020060 <icache>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	702080e7          	jalr	1794(ra) # 80000cb2 <release>
}
    800035b8:	854a                	mv	a0,s2
    800035ba:	70a2                	ld	ra,40(sp)
    800035bc:	7402                	ld	s0,32(sp)
    800035be:	64e2                	ld	s1,24(sp)
    800035c0:	6942                	ld	s2,16(sp)
    800035c2:	69a2                	ld	s3,8(sp)
    800035c4:	6a02                	ld	s4,0(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret
    panic("iget: no inodes");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	f8e50513          	addi	a0,a0,-114 # 80008558 <syscalls+0x130>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f70080e7          	jalr	-144(ra) # 80000542 <panic>

00000000800035da <fsinit>:
fsinit(int dev) {
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	1800                	addi	s0,sp,48
    800035e8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ea:	4585                	li	a1,1
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	a64080e7          	jalr	-1436(ra) # 80003050 <bread>
    800035f4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f6:	0001d997          	auipc	s3,0x1d
    800035fa:	a4a98993          	addi	s3,s3,-1462 # 80020040 <sb>
    800035fe:	02000613          	li	a2,32
    80003602:	05850593          	addi	a1,a0,88
    80003606:	854e                	mv	a0,s3
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	74e080e7          	jalr	1870(ra) # 80000d56 <memmove>
  brelse(bp);
    80003610:	8526                	mv	a0,s1
    80003612:	00000097          	auipc	ra,0x0
    80003616:	b6e080e7          	jalr	-1170(ra) # 80003180 <brelse>
  if(sb.magic != FSMAGIC)
    8000361a:	0009a703          	lw	a4,0(s3)
    8000361e:	102037b7          	lui	a5,0x10203
    80003622:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003626:	02f71263          	bne	a4,a5,8000364a <fsinit+0x70>
  initlog(dev, &sb);
    8000362a:	0001d597          	auipc	a1,0x1d
    8000362e:	a1658593          	addi	a1,a1,-1514 # 80020040 <sb>
    80003632:	854a                	mv	a0,s2
    80003634:	00001097          	auipc	ra,0x1
    80003638:	b38080e7          	jalr	-1224(ra) # 8000416c <initlog>
}
    8000363c:	70a2                	ld	ra,40(sp)
    8000363e:	7402                	ld	s0,32(sp)
    80003640:	64e2                	ld	s1,24(sp)
    80003642:	6942                	ld	s2,16(sp)
    80003644:	69a2                	ld	s3,8(sp)
    80003646:	6145                	addi	sp,sp,48
    80003648:	8082                	ret
    panic("invalid file system");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	f1e50513          	addi	a0,a0,-226 # 80008568 <syscalls+0x140>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	ef0080e7          	jalr	-272(ra) # 80000542 <panic>

000000008000365a <iinit>:
{
    8000365a:	7179                	addi	sp,sp,-48
    8000365c:	f406                	sd	ra,40(sp)
    8000365e:	f022                	sd	s0,32(sp)
    80003660:	ec26                	sd	s1,24(sp)
    80003662:	e84a                	sd	s2,16(sp)
    80003664:	e44e                	sd	s3,8(sp)
    80003666:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003668:	00005597          	auipc	a1,0x5
    8000366c:	f1858593          	addi	a1,a1,-232 # 80008580 <syscalls+0x158>
    80003670:	0001d517          	auipc	a0,0x1d
    80003674:	9f050513          	addi	a0,a0,-1552 # 80020060 <icache>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	4f6080e7          	jalr	1270(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003680:	0001d497          	auipc	s1,0x1d
    80003684:	a0848493          	addi	s1,s1,-1528 # 80020088 <icache+0x28>
    80003688:	0001e997          	auipc	s3,0x1e
    8000368c:	49098993          	addi	s3,s3,1168 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003690:	00005917          	auipc	s2,0x5
    80003694:	ef890913          	addi	s2,s2,-264 # 80008588 <syscalls+0x160>
    80003698:	85ca                	mv	a1,s2
    8000369a:	8526                	mv	a0,s1
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	e36080e7          	jalr	-458(ra) # 800044d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a4:	08848493          	addi	s1,s1,136
    800036a8:	ff3498e3          	bne	s1,s3,80003698 <iinit+0x3e>
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret

00000000800036ba <ialloc>:
{
    800036ba:	715d                	addi	sp,sp,-80
    800036bc:	e486                	sd	ra,72(sp)
    800036be:	e0a2                	sd	s0,64(sp)
    800036c0:	fc26                	sd	s1,56(sp)
    800036c2:	f84a                	sd	s2,48(sp)
    800036c4:	f44e                	sd	s3,40(sp)
    800036c6:	f052                	sd	s4,32(sp)
    800036c8:	ec56                	sd	s5,24(sp)
    800036ca:	e85a                	sd	s6,16(sp)
    800036cc:	e45e                	sd	s7,8(sp)
    800036ce:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d0:	0001d717          	auipc	a4,0x1d
    800036d4:	97c72703          	lw	a4,-1668(a4) # 8002004c <sb+0xc>
    800036d8:	4785                	li	a5,1
    800036da:	04e7fa63          	bgeu	a5,a4,8000372e <ialloc+0x74>
    800036de:	8aaa                	mv	s5,a0
    800036e0:	8bae                	mv	s7,a1
    800036e2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e4:	0001da17          	auipc	s4,0x1d
    800036e8:	95ca0a13          	addi	s4,s4,-1700 # 80020040 <sb>
    800036ec:	00048b1b          	sext.w	s6,s1
    800036f0:	0044d793          	srli	a5,s1,0x4
    800036f4:	018a2583          	lw	a1,24(s4)
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	8556                	mv	a0,s5
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	954080e7          	jalr	-1708(ra) # 80003050 <bread>
    80003704:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003706:	05850993          	addi	s3,a0,88
    8000370a:	00f4f793          	andi	a5,s1,15
    8000370e:	079a                	slli	a5,a5,0x6
    80003710:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003712:	00099783          	lh	a5,0(s3)
    80003716:	c785                	beqz	a5,8000373e <ialloc+0x84>
    brelse(bp);
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	a68080e7          	jalr	-1432(ra) # 80003180 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003720:	0485                	addi	s1,s1,1
    80003722:	00ca2703          	lw	a4,12(s4)
    80003726:	0004879b          	sext.w	a5,s1
    8000372a:	fce7e1e3          	bltu	a5,a4,800036ec <ialloc+0x32>
  panic("ialloc: no inodes");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	e6250513          	addi	a0,a0,-414 # 80008590 <syscalls+0x168>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e0c080e7          	jalr	-500(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    8000373e:	04000613          	li	a2,64
    80003742:	4581                	li	a1,0
    80003744:	854e                	mv	a0,s3
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	5b4080e7          	jalr	1460(ra) # 80000cfa <memset>
      dip->type = type;
    8000374e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	c90080e7          	jalr	-880(ra) # 800043e4 <log_write>
      brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	a22080e7          	jalr	-1502(ra) # 80003180 <brelse>
      return iget(dev, inum);
    80003766:	85da                	mv	a1,s6
    80003768:	8556                	mv	a0,s5
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	db4080e7          	jalr	-588(ra) # 8000351e <iget>
}
    80003772:	60a6                	ld	ra,72(sp)
    80003774:	6406                	ld	s0,64(sp)
    80003776:	74e2                	ld	s1,56(sp)
    80003778:	7942                	ld	s2,48(sp)
    8000377a:	79a2                	ld	s3,40(sp)
    8000377c:	7a02                	ld	s4,32(sp)
    8000377e:	6ae2                	ld	s5,24(sp)
    80003780:	6b42                	ld	s6,16(sp)
    80003782:	6ba2                	ld	s7,8(sp)
    80003784:	6161                	addi	sp,sp,80
    80003786:	8082                	ret

0000000080003788 <iupdate>:
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	e04a                	sd	s2,0(sp)
    80003792:	1000                	addi	s0,sp,32
    80003794:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003796:	415c                	lw	a5,4(a0)
    80003798:	0047d79b          	srliw	a5,a5,0x4
    8000379c:	0001d597          	auipc	a1,0x1d
    800037a0:	8bc5a583          	lw	a1,-1860(a1) # 80020058 <sb+0x18>
    800037a4:	9dbd                	addw	a1,a1,a5
    800037a6:	4108                	lw	a0,0(a0)
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	8a8080e7          	jalr	-1880(ra) # 80003050 <bread>
    800037b0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b2:	05850793          	addi	a5,a0,88
    800037b6:	40c8                	lw	a0,4(s1)
    800037b8:	893d                	andi	a0,a0,15
    800037ba:	051a                	slli	a0,a0,0x6
    800037bc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037be:	04449703          	lh	a4,68(s1)
    800037c2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c6:	04649703          	lh	a4,70(s1)
    800037ca:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ce:	04849703          	lh	a4,72(s1)
    800037d2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d6:	04a49703          	lh	a4,74(s1)
    800037da:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037de:	44f8                	lw	a4,76(s1)
    800037e0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e2:	03400613          	li	a2,52
    800037e6:	05048593          	addi	a1,s1,80
    800037ea:	0531                	addi	a0,a0,12
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	56a080e7          	jalr	1386(ra) # 80000d56 <memmove>
  log_write(bp);
    800037f4:	854a                	mv	a0,s2
    800037f6:	00001097          	auipc	ra,0x1
    800037fa:	bee080e7          	jalr	-1042(ra) # 800043e4 <log_write>
  brelse(bp);
    800037fe:	854a                	mv	a0,s2
    80003800:	00000097          	auipc	ra,0x0
    80003804:	980080e7          	jalr	-1664(ra) # 80003180 <brelse>
}
    80003808:	60e2                	ld	ra,24(sp)
    8000380a:	6442                	ld	s0,16(sp)
    8000380c:	64a2                	ld	s1,8(sp)
    8000380e:	6902                	ld	s2,0(sp)
    80003810:	6105                	addi	sp,sp,32
    80003812:	8082                	ret

0000000080003814 <idup>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	1000                	addi	s0,sp,32
    8000381e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003820:	0001d517          	auipc	a0,0x1d
    80003824:	84050513          	addi	a0,a0,-1984 # 80020060 <icache>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	3d6080e7          	jalr	982(ra) # 80000bfe <acquire>
  ip->ref++;
    80003830:	449c                	lw	a5,8(s1)
    80003832:	2785                	addiw	a5,a5,1
    80003834:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003836:	0001d517          	auipc	a0,0x1d
    8000383a:	82a50513          	addi	a0,a0,-2006 # 80020060 <icache>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	474080e7          	jalr	1140(ra) # 80000cb2 <release>
}
    80003846:	8526                	mv	a0,s1
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret

0000000080003852 <ilock>:
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	e04a                	sd	s2,0(sp)
    8000385c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000385e:	c115                	beqz	a0,80003882 <ilock+0x30>
    80003860:	84aa                	mv	s1,a0
    80003862:	451c                	lw	a5,8(a0)
    80003864:	00f05f63          	blez	a5,80003882 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003868:	0541                	addi	a0,a0,16
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	ca2080e7          	jalr	-862(ra) # 8000450c <acquiresleep>
  if(ip->valid == 0){
    80003872:	40bc                	lw	a5,64(s1)
    80003874:	cf99                	beqz	a5,80003892 <ilock+0x40>
}
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	64a2                	ld	s1,8(sp)
    8000387c:	6902                	ld	s2,0(sp)
    8000387e:	6105                	addi	sp,sp,32
    80003880:	8082                	ret
    panic("ilock");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	d2650513          	addi	a0,a0,-730 # 800085a8 <syscalls+0x180>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb8080e7          	jalr	-840(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003892:	40dc                	lw	a5,4(s1)
    80003894:	0047d79b          	srliw	a5,a5,0x4
    80003898:	0001c597          	auipc	a1,0x1c
    8000389c:	7c05a583          	lw	a1,1984(a1) # 80020058 <sb+0x18>
    800038a0:	9dbd                	addw	a1,a1,a5
    800038a2:	4088                	lw	a0,0(s1)
    800038a4:	fffff097          	auipc	ra,0xfffff
    800038a8:	7ac080e7          	jalr	1964(ra) # 80003050 <bread>
    800038ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ae:	05850593          	addi	a1,a0,88
    800038b2:	40dc                	lw	a5,4(s1)
    800038b4:	8bbd                	andi	a5,a5,15
    800038b6:	079a                	slli	a5,a5,0x6
    800038b8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ba:	00059783          	lh	a5,0(a1)
    800038be:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c2:	00259783          	lh	a5,2(a1)
    800038c6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038ca:	00459783          	lh	a5,4(a1)
    800038ce:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d2:	00659783          	lh	a5,6(a1)
    800038d6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038da:	459c                	lw	a5,8(a1)
    800038dc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038de:	03400613          	li	a2,52
    800038e2:	05b1                	addi	a1,a1,12
    800038e4:	05048513          	addi	a0,s1,80
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	46e080e7          	jalr	1134(ra) # 80000d56 <memmove>
    brelse(bp);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	88e080e7          	jalr	-1906(ra) # 80003180 <brelse>
    ip->valid = 1;
    800038fa:	4785                	li	a5,1
    800038fc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038fe:	04449783          	lh	a5,68(s1)
    80003902:	fbb5                	bnez	a5,80003876 <ilock+0x24>
      panic("ilock: no type");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	cac50513          	addi	a0,a0,-852 # 800085b0 <syscalls+0x188>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c36080e7          	jalr	-970(ra) # 80000542 <panic>

0000000080003914 <iunlock>:
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	e426                	sd	s1,8(sp)
    8000391c:	e04a                	sd	s2,0(sp)
    8000391e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003920:	c905                	beqz	a0,80003950 <iunlock+0x3c>
    80003922:	84aa                	mv	s1,a0
    80003924:	01050913          	addi	s2,a0,16
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	c7c080e7          	jalr	-900(ra) # 800045a6 <holdingsleep>
    80003932:	cd19                	beqz	a0,80003950 <iunlock+0x3c>
    80003934:	449c                	lw	a5,8(s1)
    80003936:	00f05d63          	blez	a5,80003950 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000393a:	854a                	mv	a0,s2
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	c26080e7          	jalr	-986(ra) # 80004562 <releasesleep>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6902                	ld	s2,0(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret
    panic("iunlock");
    80003950:	00005517          	auipc	a0,0x5
    80003954:	c7050513          	addi	a0,a0,-912 # 800085c0 <syscalls+0x198>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	bea080e7          	jalr	-1046(ra) # 80000542 <panic>

0000000080003960 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003960:	7179                	addi	sp,sp,-48
    80003962:	f406                	sd	ra,40(sp)
    80003964:	f022                	sd	s0,32(sp)
    80003966:	ec26                	sd	s1,24(sp)
    80003968:	e84a                	sd	s2,16(sp)
    8000396a:	e44e                	sd	s3,8(sp)
    8000396c:	e052                	sd	s4,0(sp)
    8000396e:	1800                	addi	s0,sp,48
    80003970:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003972:	05050493          	addi	s1,a0,80
    80003976:	08050913          	addi	s2,a0,128
    8000397a:	a021                	j	80003982 <itrunc+0x22>
    8000397c:	0491                	addi	s1,s1,4
    8000397e:	01248d63          	beq	s1,s2,80003998 <itrunc+0x38>
    if(ip->addrs[i]){
    80003982:	408c                	lw	a1,0(s1)
    80003984:	dde5                	beqz	a1,8000397c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003986:	0009a503          	lw	a0,0(s3)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	90c080e7          	jalr	-1780(ra) # 80003296 <bfree>
      ip->addrs[i] = 0;
    80003992:	0004a023          	sw	zero,0(s1)
    80003996:	b7dd                	j	8000397c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003998:	0809a583          	lw	a1,128(s3)
    8000399c:	e185                	bnez	a1,800039bc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000399e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a2:	854e                	mv	a0,s3
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	de4080e7          	jalr	-540(ra) # 80003788 <iupdate>
}
    800039ac:	70a2                	ld	ra,40(sp)
    800039ae:	7402                	ld	s0,32(sp)
    800039b0:	64e2                	ld	s1,24(sp)
    800039b2:	6942                	ld	s2,16(sp)
    800039b4:	69a2                	ld	s3,8(sp)
    800039b6:	6a02                	ld	s4,0(sp)
    800039b8:	6145                	addi	sp,sp,48
    800039ba:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039bc:	0009a503          	lw	a0,0(s3)
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	690080e7          	jalr	1680(ra) # 80003050 <bread>
    800039c8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039ca:	05850493          	addi	s1,a0,88
    800039ce:	45850913          	addi	s2,a0,1112
    800039d2:	a021                	j	800039da <itrunc+0x7a>
    800039d4:	0491                	addi	s1,s1,4
    800039d6:	01248b63          	beq	s1,s2,800039ec <itrunc+0x8c>
      if(a[j])
    800039da:	408c                	lw	a1,0(s1)
    800039dc:	dde5                	beqz	a1,800039d4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039de:	0009a503          	lw	a0,0(s3)
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	8b4080e7          	jalr	-1868(ra) # 80003296 <bfree>
    800039ea:	b7ed                	j	800039d4 <itrunc+0x74>
    brelse(bp);
    800039ec:	8552                	mv	a0,s4
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	792080e7          	jalr	1938(ra) # 80003180 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f6:	0809a583          	lw	a1,128(s3)
    800039fa:	0009a503          	lw	a0,0(s3)
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	898080e7          	jalr	-1896(ra) # 80003296 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a06:	0809a023          	sw	zero,128(s3)
    80003a0a:	bf51                	j	8000399e <itrunc+0x3e>

0000000080003a0c <iput>:
{
    80003a0c:	1101                	addi	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	e426                	sd	s1,8(sp)
    80003a14:	e04a                	sd	s2,0(sp)
    80003a16:	1000                	addi	s0,sp,32
    80003a18:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a1a:	0001c517          	auipc	a0,0x1c
    80003a1e:	64650513          	addi	a0,a0,1606 # 80020060 <icache>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	1dc080e7          	jalr	476(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2a:	4498                	lw	a4,8(s1)
    80003a2c:	4785                	li	a5,1
    80003a2e:	02f70363          	beq	a4,a5,80003a54 <iput+0x48>
  ip->ref--;
    80003a32:	449c                	lw	a5,8(s1)
    80003a34:	37fd                	addiw	a5,a5,-1
    80003a36:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a38:	0001c517          	auipc	a0,0x1c
    80003a3c:	62850513          	addi	a0,a0,1576 # 80020060 <icache>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	272080e7          	jalr	626(ra) # 80000cb2 <release>
}
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6902                	ld	s2,0(sp)
    80003a50:	6105                	addi	sp,sp,32
    80003a52:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a54:	40bc                	lw	a5,64(s1)
    80003a56:	dff1                	beqz	a5,80003a32 <iput+0x26>
    80003a58:	04a49783          	lh	a5,74(s1)
    80003a5c:	fbf9                	bnez	a5,80003a32 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a5e:	01048913          	addi	s2,s1,16
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	aa8080e7          	jalr	-1368(ra) # 8000450c <acquiresleep>
    release(&icache.lock);
    80003a6c:	0001c517          	auipc	a0,0x1c
    80003a70:	5f450513          	addi	a0,a0,1524 # 80020060 <icache>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	23e080e7          	jalr	574(ra) # 80000cb2 <release>
    itrunc(ip);
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	ee2080e7          	jalr	-286(ra) # 80003960 <itrunc>
    ip->type = 0;
    80003a86:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a8a:	8526                	mv	a0,s1
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	cfc080e7          	jalr	-772(ra) # 80003788 <iupdate>
    ip->valid = 0;
    80003a94:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	ac8080e7          	jalr	-1336(ra) # 80004562 <releasesleep>
    acquire(&icache.lock);
    80003aa2:	0001c517          	auipc	a0,0x1c
    80003aa6:	5be50513          	addi	a0,a0,1470 # 80020060 <icache>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	154080e7          	jalr	340(ra) # 80000bfe <acquire>
    80003ab2:	b741                	j	80003a32 <iput+0x26>

0000000080003ab4 <iunlockput>:
{
    80003ab4:	1101                	addi	sp,sp,-32
    80003ab6:	ec06                	sd	ra,24(sp)
    80003ab8:	e822                	sd	s0,16(sp)
    80003aba:	e426                	sd	s1,8(sp)
    80003abc:	1000                	addi	s0,sp,32
    80003abe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	e54080e7          	jalr	-428(ra) # 80003914 <iunlock>
  iput(ip);
    80003ac8:	8526                	mv	a0,s1
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	f42080e7          	jalr	-190(ra) # 80003a0c <iput>
}
    80003ad2:	60e2                	ld	ra,24(sp)
    80003ad4:	6442                	ld	s0,16(sp)
    80003ad6:	64a2                	ld	s1,8(sp)
    80003ad8:	6105                	addi	sp,sp,32
    80003ada:	8082                	ret

0000000080003adc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003adc:	1141                	addi	sp,sp,-16
    80003ade:	e422                	sd	s0,8(sp)
    80003ae0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae2:	411c                	lw	a5,0(a0)
    80003ae4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae6:	415c                	lw	a5,4(a0)
    80003ae8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aea:	04451783          	lh	a5,68(a0)
    80003aee:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af2:	04a51783          	lh	a5,74(a0)
    80003af6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003afa:	04c56783          	lwu	a5,76(a0)
    80003afe:	e99c                	sd	a5,16(a1)
}
    80003b00:	6422                	ld	s0,8(sp)
    80003b02:	0141                	addi	sp,sp,16
    80003b04:	8082                	ret

0000000080003b06 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b06:	457c                	lw	a5,76(a0)
    80003b08:	0ed7e863          	bltu	a5,a3,80003bf8 <readi+0xf2>
{
    80003b0c:	7159                	addi	sp,sp,-112
    80003b0e:	f486                	sd	ra,104(sp)
    80003b10:	f0a2                	sd	s0,96(sp)
    80003b12:	eca6                	sd	s1,88(sp)
    80003b14:	e8ca                	sd	s2,80(sp)
    80003b16:	e4ce                	sd	s3,72(sp)
    80003b18:	e0d2                	sd	s4,64(sp)
    80003b1a:	fc56                	sd	s5,56(sp)
    80003b1c:	f85a                	sd	s6,48(sp)
    80003b1e:	f45e                	sd	s7,40(sp)
    80003b20:	f062                	sd	s8,32(sp)
    80003b22:	ec66                	sd	s9,24(sp)
    80003b24:	e86a                	sd	s10,16(sp)
    80003b26:	e46e                	sd	s11,8(sp)
    80003b28:	1880                	addi	s0,sp,112
    80003b2a:	8baa                	mv	s7,a0
    80003b2c:	8c2e                	mv	s8,a1
    80003b2e:	8ab2                	mv	s5,a2
    80003b30:	84b6                	mv	s1,a3
    80003b32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b34:	9f35                	addw	a4,a4,a3
    return 0;
    80003b36:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b38:	08d76f63          	bltu	a4,a3,80003bd6 <readi+0xd0>
  if(off + n > ip->size)
    80003b3c:	00e7f463          	bgeu	a5,a4,80003b44 <readi+0x3e>
    n = ip->size - off;
    80003b40:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b44:	0a0b0863          	beqz	s6,80003bf4 <readi+0xee>
    80003b48:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b4e:	5cfd                	li	s9,-1
    80003b50:	a82d                	j	80003b8a <readi+0x84>
    80003b52:	020a1d93          	slli	s11,s4,0x20
    80003b56:	020ddd93          	srli	s11,s11,0x20
    80003b5a:	05890793          	addi	a5,s2,88
    80003b5e:	86ee                	mv	a3,s11
    80003b60:	963e                	add	a2,a2,a5
    80003b62:	85d6                	mv	a1,s5
    80003b64:	8562                	mv	a0,s8
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	9d4080e7          	jalr	-1580(ra) # 8000253a <either_copyout>
    80003b6e:	05950d63          	beq	a0,s9,80003bc8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	60c080e7          	jalr	1548(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7c:	013a09bb          	addw	s3,s4,s3
    80003b80:	009a04bb          	addw	s1,s4,s1
    80003b84:	9aee                	add	s5,s5,s11
    80003b86:	0569f663          	bgeu	s3,s6,80003bd2 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8a:	000ba903          	lw	s2,0(s7)
    80003b8e:	00a4d59b          	srliw	a1,s1,0xa
    80003b92:	855e                	mv	a0,s7
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	8b0080e7          	jalr	-1872(ra) # 80003444 <bmap>
    80003b9c:	0005059b          	sext.w	a1,a0
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	4ae080e7          	jalr	1198(ra) # 80003050 <bread>
    80003baa:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bac:	3ff4f613          	andi	a2,s1,1023
    80003bb0:	40cd07bb          	subw	a5,s10,a2
    80003bb4:	413b073b          	subw	a4,s6,s3
    80003bb8:	8a3e                	mv	s4,a5
    80003bba:	2781                	sext.w	a5,a5
    80003bbc:	0007069b          	sext.w	a3,a4
    80003bc0:	f8f6f9e3          	bgeu	a3,a5,80003b52 <readi+0x4c>
    80003bc4:	8a3a                	mv	s4,a4
    80003bc6:	b771                	j	80003b52 <readi+0x4c>
      brelse(bp);
    80003bc8:	854a                	mv	a0,s2
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	5b6080e7          	jalr	1462(ra) # 80003180 <brelse>
  }
  return tot;
    80003bd2:	0009851b          	sext.w	a0,s3
}
    80003bd6:	70a6                	ld	ra,104(sp)
    80003bd8:	7406                	ld	s0,96(sp)
    80003bda:	64e6                	ld	s1,88(sp)
    80003bdc:	6946                	ld	s2,80(sp)
    80003bde:	69a6                	ld	s3,72(sp)
    80003be0:	6a06                	ld	s4,64(sp)
    80003be2:	7ae2                	ld	s5,56(sp)
    80003be4:	7b42                	ld	s6,48(sp)
    80003be6:	7ba2                	ld	s7,40(sp)
    80003be8:	7c02                	ld	s8,32(sp)
    80003bea:	6ce2                	ld	s9,24(sp)
    80003bec:	6d42                	ld	s10,16(sp)
    80003bee:	6da2                	ld	s11,8(sp)
    80003bf0:	6165                	addi	sp,sp,112
    80003bf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf4:	89da                	mv	s3,s6
    80003bf6:	bff1                	j	80003bd2 <readi+0xcc>
    return 0;
    80003bf8:	4501                	li	a0,0
}
    80003bfa:	8082                	ret

0000000080003bfc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bfc:	457c                	lw	a5,76(a0)
    80003bfe:	10d7e663          	bltu	a5,a3,80003d0a <writei+0x10e>
{
    80003c02:	7159                	addi	sp,sp,-112
    80003c04:	f486                	sd	ra,104(sp)
    80003c06:	f0a2                	sd	s0,96(sp)
    80003c08:	eca6                	sd	s1,88(sp)
    80003c0a:	e8ca                	sd	s2,80(sp)
    80003c0c:	e4ce                	sd	s3,72(sp)
    80003c0e:	e0d2                	sd	s4,64(sp)
    80003c10:	fc56                	sd	s5,56(sp)
    80003c12:	f85a                	sd	s6,48(sp)
    80003c14:	f45e                	sd	s7,40(sp)
    80003c16:	f062                	sd	s8,32(sp)
    80003c18:	ec66                	sd	s9,24(sp)
    80003c1a:	e86a                	sd	s10,16(sp)
    80003c1c:	e46e                	sd	s11,8(sp)
    80003c1e:	1880                	addi	s0,sp,112
    80003c20:	8baa                	mv	s7,a0
    80003c22:	8c2e                	mv	s8,a1
    80003c24:	8ab2                	mv	s5,a2
    80003c26:	8936                	mv	s2,a3
    80003c28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c2a:	00e687bb          	addw	a5,a3,a4
    80003c2e:	0ed7e063          	bltu	a5,a3,80003d0e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c32:	00043737          	lui	a4,0x43
    80003c36:	0cf76e63          	bltu	a4,a5,80003d12 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3a:	0a0b0763          	beqz	s6,80003ce8 <writei+0xec>
    80003c3e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c40:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c44:	5cfd                	li	s9,-1
    80003c46:	a091                	j	80003c8a <writei+0x8e>
    80003c48:	02099d93          	slli	s11,s3,0x20
    80003c4c:	020ddd93          	srli	s11,s11,0x20
    80003c50:	05848793          	addi	a5,s1,88
    80003c54:	86ee                	mv	a3,s11
    80003c56:	8656                	mv	a2,s5
    80003c58:	85e2                	mv	a1,s8
    80003c5a:	953e                	add	a0,a0,a5
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	934080e7          	jalr	-1740(ra) # 80002590 <either_copyin>
    80003c64:	07950263          	beq	a0,s9,80003cc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c68:	8526                	mv	a0,s1
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	77a080e7          	jalr	1914(ra) # 800043e4 <log_write>
    brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	50c080e7          	jalr	1292(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7c:	01498a3b          	addw	s4,s3,s4
    80003c80:	0129893b          	addw	s2,s3,s2
    80003c84:	9aee                	add	s5,s5,s11
    80003c86:	056a7663          	bgeu	s4,s6,80003cd2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c8a:	000ba483          	lw	s1,0(s7)
    80003c8e:	00a9559b          	srliw	a1,s2,0xa
    80003c92:	855e                	mv	a0,s7
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	7b0080e7          	jalr	1968(ra) # 80003444 <bmap>
    80003c9c:	0005059b          	sext.w	a1,a0
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	3ae080e7          	jalr	942(ra) # 80003050 <bread>
    80003caa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cac:	3ff97513          	andi	a0,s2,1023
    80003cb0:	40ad07bb          	subw	a5,s10,a0
    80003cb4:	414b073b          	subw	a4,s6,s4
    80003cb8:	89be                	mv	s3,a5
    80003cba:	2781                	sext.w	a5,a5
    80003cbc:	0007069b          	sext.w	a3,a4
    80003cc0:	f8f6f4e3          	bgeu	a3,a5,80003c48 <writei+0x4c>
    80003cc4:	89ba                	mv	s3,a4
    80003cc6:	b749                	j	80003c48 <writei+0x4c>
      brelse(bp);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	4b6080e7          	jalr	1206(ra) # 80003180 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003cd2:	04cba783          	lw	a5,76(s7)
    80003cd6:	0127f463          	bgeu	a5,s2,80003cde <writei+0xe2>
      ip->size = off;
    80003cda:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cde:	855e                	mv	a0,s7
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	aa8080e7          	jalr	-1368(ra) # 80003788 <iupdate>
  }

  return n;
    80003ce8:	000b051b          	sext.w	a0,s6
}
    80003cec:	70a6                	ld	ra,104(sp)
    80003cee:	7406                	ld	s0,96(sp)
    80003cf0:	64e6                	ld	s1,88(sp)
    80003cf2:	6946                	ld	s2,80(sp)
    80003cf4:	69a6                	ld	s3,72(sp)
    80003cf6:	6a06                	ld	s4,64(sp)
    80003cf8:	7ae2                	ld	s5,56(sp)
    80003cfa:	7b42                	ld	s6,48(sp)
    80003cfc:	7ba2                	ld	s7,40(sp)
    80003cfe:	7c02                	ld	s8,32(sp)
    80003d00:	6ce2                	ld	s9,24(sp)
    80003d02:	6d42                	ld	s10,16(sp)
    80003d04:	6da2                	ld	s11,8(sp)
    80003d06:	6165                	addi	sp,sp,112
    80003d08:	8082                	ret
    return -1;
    80003d0a:	557d                	li	a0,-1
}
    80003d0c:	8082                	ret
    return -1;
    80003d0e:	557d                	li	a0,-1
    80003d10:	bff1                	j	80003cec <writei+0xf0>
    return -1;
    80003d12:	557d                	li	a0,-1
    80003d14:	bfe1                	j	80003cec <writei+0xf0>

0000000080003d16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d16:	1141                	addi	sp,sp,-16
    80003d18:	e406                	sd	ra,8(sp)
    80003d1a:	e022                	sd	s0,0(sp)
    80003d1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d1e:	4639                	li	a2,14
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	0b2080e7          	jalr	178(ra) # 80000dd2 <strncmp>
}
    80003d28:	60a2                	ld	ra,8(sp)
    80003d2a:	6402                	ld	s0,0(sp)
    80003d2c:	0141                	addi	sp,sp,16
    80003d2e:	8082                	ret

0000000080003d30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d30:	7139                	addi	sp,sp,-64
    80003d32:	fc06                	sd	ra,56(sp)
    80003d34:	f822                	sd	s0,48(sp)
    80003d36:	f426                	sd	s1,40(sp)
    80003d38:	f04a                	sd	s2,32(sp)
    80003d3a:	ec4e                	sd	s3,24(sp)
    80003d3c:	e852                	sd	s4,16(sp)
    80003d3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d40:	04451703          	lh	a4,68(a0)
    80003d44:	4785                	li	a5,1
    80003d46:	00f71a63          	bne	a4,a5,80003d5a <dirlookup+0x2a>
    80003d4a:	892a                	mv	s2,a0
    80003d4c:	89ae                	mv	s3,a1
    80003d4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d50:	457c                	lw	a5,76(a0)
    80003d52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d56:	e79d                	bnez	a5,80003d84 <dirlookup+0x54>
    80003d58:	a8a5                	j	80003dd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d5a:	00005517          	auipc	a0,0x5
    80003d5e:	86e50513          	addi	a0,a0,-1938 # 800085c8 <syscalls+0x1a0>
    80003d62:	ffffc097          	auipc	ra,0xffffc
    80003d66:	7e0080e7          	jalr	2016(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003d6a:	00005517          	auipc	a0,0x5
    80003d6e:	87650513          	addi	a0,a0,-1930 # 800085e0 <syscalls+0x1b8>
    80003d72:	ffffc097          	auipc	ra,0xffffc
    80003d76:	7d0080e7          	jalr	2000(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7a:	24c1                	addiw	s1,s1,16
    80003d7c:	04c92783          	lw	a5,76(s2)
    80003d80:	04f4f763          	bgeu	s1,a5,80003dce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d84:	4741                	li	a4,16
    80003d86:	86a6                	mv	a3,s1
    80003d88:	fc040613          	addi	a2,s0,-64
    80003d8c:	4581                	li	a1,0
    80003d8e:	854a                	mv	a0,s2
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	d76080e7          	jalr	-650(ra) # 80003b06 <readi>
    80003d98:	47c1                	li	a5,16
    80003d9a:	fcf518e3          	bne	a0,a5,80003d6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003d9e:	fc045783          	lhu	a5,-64(s0)
    80003da2:	dfe1                	beqz	a5,80003d7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da4:	fc240593          	addi	a1,s0,-62
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	f6c080e7          	jalr	-148(ra) # 80003d16 <namecmp>
    80003db2:	f561                	bnez	a0,80003d7a <dirlookup+0x4a>
      if(poff)
    80003db4:	000a0463          	beqz	s4,80003dbc <dirlookup+0x8c>
        *poff = off;
    80003db8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dbc:	fc045583          	lhu	a1,-64(s0)
    80003dc0:	00092503          	lw	a0,0(s2)
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	75a080e7          	jalr	1882(ra) # 8000351e <iget>
    80003dcc:	a011                	j	80003dd0 <dirlookup+0xa0>
  return 0;
    80003dce:	4501                	li	a0,0
}
    80003dd0:	70e2                	ld	ra,56(sp)
    80003dd2:	7442                	ld	s0,48(sp)
    80003dd4:	74a2                	ld	s1,40(sp)
    80003dd6:	7902                	ld	s2,32(sp)
    80003dd8:	69e2                	ld	s3,24(sp)
    80003dda:	6a42                	ld	s4,16(sp)
    80003ddc:	6121                	addi	sp,sp,64
    80003dde:	8082                	ret

0000000080003de0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de0:	711d                	addi	sp,sp,-96
    80003de2:	ec86                	sd	ra,88(sp)
    80003de4:	e8a2                	sd	s0,80(sp)
    80003de6:	e4a6                	sd	s1,72(sp)
    80003de8:	e0ca                	sd	s2,64(sp)
    80003dea:	fc4e                	sd	s3,56(sp)
    80003dec:	f852                	sd	s4,48(sp)
    80003dee:	f456                	sd	s5,40(sp)
    80003df0:	f05a                	sd	s6,32(sp)
    80003df2:	ec5e                	sd	s7,24(sp)
    80003df4:	e862                	sd	s8,16(sp)
    80003df6:	e466                	sd	s9,8(sp)
    80003df8:	1080                	addi	s0,sp,96
    80003dfa:	84aa                	mv	s1,a0
    80003dfc:	8aae                	mv	s5,a1
    80003dfe:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e00:	00054703          	lbu	a4,0(a0)
    80003e04:	02f00793          	li	a5,47
    80003e08:	02f70363          	beq	a4,a5,80003e2e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e0c:	ffffe097          	auipc	ra,0xffffe
    80003e10:	c28080e7          	jalr	-984(ra) # 80001a34 <myproc>
    80003e14:	15853503          	ld	a0,344(a0)
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	9fc080e7          	jalr	-1540(ra) # 80003814 <idup>
    80003e20:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e22:	02f00913          	li	s2,47
  len = path - s;
    80003e26:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e28:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e2a:	4b85                	li	s7,1
    80003e2c:	a865                	j	80003ee4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e2e:	4585                	li	a1,1
    80003e30:	4505                	li	a0,1
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	6ec080e7          	jalr	1772(ra) # 8000351e <iget>
    80003e3a:	89aa                	mv	s3,a0
    80003e3c:	b7dd                	j	80003e22 <namex+0x42>
      iunlockput(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	c74080e7          	jalr	-908(ra) # 80003ab4 <iunlockput>
      return 0;
    80003e48:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	60e6                	ld	ra,88(sp)
    80003e4e:	6446                	ld	s0,80(sp)
    80003e50:	64a6                	ld	s1,72(sp)
    80003e52:	6906                	ld	s2,64(sp)
    80003e54:	79e2                	ld	s3,56(sp)
    80003e56:	7a42                	ld	s4,48(sp)
    80003e58:	7aa2                	ld	s5,40(sp)
    80003e5a:	7b02                	ld	s6,32(sp)
    80003e5c:	6be2                	ld	s7,24(sp)
    80003e5e:	6c42                	ld	s8,16(sp)
    80003e60:	6ca2                	ld	s9,8(sp)
    80003e62:	6125                	addi	sp,sp,96
    80003e64:	8082                	ret
      iunlock(ip);
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	aac080e7          	jalr	-1364(ra) # 80003914 <iunlock>
      return ip;
    80003e70:	bfe9                	j	80003e4a <namex+0x6a>
      iunlockput(ip);
    80003e72:	854e                	mv	a0,s3
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	c40080e7          	jalr	-960(ra) # 80003ab4 <iunlockput>
      return 0;
    80003e7c:	89e6                	mv	s3,s9
    80003e7e:	b7f1                	j	80003e4a <namex+0x6a>
  len = path - s;
    80003e80:	40b48633          	sub	a2,s1,a1
    80003e84:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e88:	099c5463          	bge	s8,s9,80003f10 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e8c:	4639                	li	a2,14
    80003e8e:	8552                	mv	a0,s4
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	ec6080e7          	jalr	-314(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	01279763          	bne	a5,s2,80003eaa <namex+0xca>
    path++;
    80003ea0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	ff278de3          	beq	a5,s2,80003ea0 <namex+0xc0>
    ilock(ip);
    80003eaa:	854e                	mv	a0,s3
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	9a6080e7          	jalr	-1626(ra) # 80003852 <ilock>
    if(ip->type != T_DIR){
    80003eb4:	04499783          	lh	a5,68(s3)
    80003eb8:	f97793e3          	bne	a5,s7,80003e3e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ebc:	000a8563          	beqz	s5,80003ec6 <namex+0xe6>
    80003ec0:	0004c783          	lbu	a5,0(s1)
    80003ec4:	d3cd                	beqz	a5,80003e66 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ec6:	865a                	mv	a2,s6
    80003ec8:	85d2                	mv	a1,s4
    80003eca:	854e                	mv	a0,s3
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	e64080e7          	jalr	-412(ra) # 80003d30 <dirlookup>
    80003ed4:	8caa                	mv	s9,a0
    80003ed6:	dd51                	beqz	a0,80003e72 <namex+0x92>
    iunlockput(ip);
    80003ed8:	854e                	mv	a0,s3
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	bda080e7          	jalr	-1062(ra) # 80003ab4 <iunlockput>
    ip = next;
    80003ee2:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ee4:	0004c783          	lbu	a5,0(s1)
    80003ee8:	05279763          	bne	a5,s2,80003f36 <namex+0x156>
    path++;
    80003eec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eee:	0004c783          	lbu	a5,0(s1)
    80003ef2:	ff278de3          	beq	a5,s2,80003eec <namex+0x10c>
  if(*path == 0)
    80003ef6:	c79d                	beqz	a5,80003f24 <namex+0x144>
    path++;
    80003ef8:	85a6                	mv	a1,s1
  len = path - s;
    80003efa:	8cda                	mv	s9,s6
    80003efc:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003efe:	01278963          	beq	a5,s2,80003f10 <namex+0x130>
    80003f02:	dfbd                	beqz	a5,80003e80 <namex+0xa0>
    path++;
    80003f04:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f06:	0004c783          	lbu	a5,0(s1)
    80003f0a:	ff279ce3          	bne	a5,s2,80003f02 <namex+0x122>
    80003f0e:	bf8d                	j	80003e80 <namex+0xa0>
    memmove(name, s, len);
    80003f10:	2601                	sext.w	a2,a2
    80003f12:	8552                	mv	a0,s4
    80003f14:	ffffd097          	auipc	ra,0xffffd
    80003f18:	e42080e7          	jalr	-446(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003f1c:	9cd2                	add	s9,s9,s4
    80003f1e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f22:	bf9d                	j	80003e98 <namex+0xb8>
  if(nameiparent){
    80003f24:	f20a83e3          	beqz	s5,80003e4a <namex+0x6a>
    iput(ip);
    80003f28:	854e                	mv	a0,s3
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	ae2080e7          	jalr	-1310(ra) # 80003a0c <iput>
    return 0;
    80003f32:	4981                	li	s3,0
    80003f34:	bf19                	j	80003e4a <namex+0x6a>
  if(*path == 0)
    80003f36:	d7fd                	beqz	a5,80003f24 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f38:	0004c783          	lbu	a5,0(s1)
    80003f3c:	85a6                	mv	a1,s1
    80003f3e:	b7d1                	j	80003f02 <namex+0x122>

0000000080003f40 <dirlink>:
{
    80003f40:	7139                	addi	sp,sp,-64
    80003f42:	fc06                	sd	ra,56(sp)
    80003f44:	f822                	sd	s0,48(sp)
    80003f46:	f426                	sd	s1,40(sp)
    80003f48:	f04a                	sd	s2,32(sp)
    80003f4a:	ec4e                	sd	s3,24(sp)
    80003f4c:	e852                	sd	s4,16(sp)
    80003f4e:	0080                	addi	s0,sp,64
    80003f50:	892a                	mv	s2,a0
    80003f52:	8a2e                	mv	s4,a1
    80003f54:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f56:	4601                	li	a2,0
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	dd8080e7          	jalr	-552(ra) # 80003d30 <dirlookup>
    80003f60:	e93d                	bnez	a0,80003fd6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f62:	04c92483          	lw	s1,76(s2)
    80003f66:	c49d                	beqz	s1,80003f94 <dirlink+0x54>
    80003f68:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f6a:	4741                	li	a4,16
    80003f6c:	86a6                	mv	a3,s1
    80003f6e:	fc040613          	addi	a2,s0,-64
    80003f72:	4581                	li	a1,0
    80003f74:	854a                	mv	a0,s2
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	b90080e7          	jalr	-1136(ra) # 80003b06 <readi>
    80003f7e:	47c1                	li	a5,16
    80003f80:	06f51163          	bne	a0,a5,80003fe2 <dirlink+0xa2>
    if(de.inum == 0)
    80003f84:	fc045783          	lhu	a5,-64(s0)
    80003f88:	c791                	beqz	a5,80003f94 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f8a:	24c1                	addiw	s1,s1,16
    80003f8c:	04c92783          	lw	a5,76(s2)
    80003f90:	fcf4ede3          	bltu	s1,a5,80003f6a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f94:	4639                	li	a2,14
    80003f96:	85d2                	mv	a1,s4
    80003f98:	fc240513          	addi	a0,s0,-62
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	e72080e7          	jalr	-398(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80003fa4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa8:	4741                	li	a4,16
    80003faa:	86a6                	mv	a3,s1
    80003fac:	fc040613          	addi	a2,s0,-64
    80003fb0:	4581                	li	a1,0
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	c48080e7          	jalr	-952(ra) # 80003bfc <writei>
    80003fbc:	872a                	mv	a4,a0
    80003fbe:	47c1                	li	a5,16
  return 0;
    80003fc0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc2:	02f71863          	bne	a4,a5,80003ff2 <dirlink+0xb2>
}
    80003fc6:	70e2                	ld	ra,56(sp)
    80003fc8:	7442                	ld	s0,48(sp)
    80003fca:	74a2                	ld	s1,40(sp)
    80003fcc:	7902                	ld	s2,32(sp)
    80003fce:	69e2                	ld	s3,24(sp)
    80003fd0:	6a42                	ld	s4,16(sp)
    80003fd2:	6121                	addi	sp,sp,64
    80003fd4:	8082                	ret
    iput(ip);
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	a36080e7          	jalr	-1482(ra) # 80003a0c <iput>
    return -1;
    80003fde:	557d                	li	a0,-1
    80003fe0:	b7dd                	j	80003fc6 <dirlink+0x86>
      panic("dirlink read");
    80003fe2:	00004517          	auipc	a0,0x4
    80003fe6:	60e50513          	addi	a0,a0,1550 # 800085f0 <syscalls+0x1c8>
    80003fea:	ffffc097          	auipc	ra,0xffffc
    80003fee:	558080e7          	jalr	1368(ra) # 80000542 <panic>
    panic("dirlink");
    80003ff2:	00004517          	auipc	a0,0x4
    80003ff6:	71650513          	addi	a0,a0,1814 # 80008708 <syscalls+0x2e0>
    80003ffa:	ffffc097          	auipc	ra,0xffffc
    80003ffe:	548080e7          	jalr	1352(ra) # 80000542 <panic>

0000000080004002 <namei>:

struct inode*
namei(char *path)
{
    80004002:	1101                	addi	sp,sp,-32
    80004004:	ec06                	sd	ra,24(sp)
    80004006:	e822                	sd	s0,16(sp)
    80004008:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000400a:	fe040613          	addi	a2,s0,-32
    8000400e:	4581                	li	a1,0
    80004010:	00000097          	auipc	ra,0x0
    80004014:	dd0080e7          	jalr	-560(ra) # 80003de0 <namex>
}
    80004018:	60e2                	ld	ra,24(sp)
    8000401a:	6442                	ld	s0,16(sp)
    8000401c:	6105                	addi	sp,sp,32
    8000401e:	8082                	ret

0000000080004020 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004020:	1141                	addi	sp,sp,-16
    80004022:	e406                	sd	ra,8(sp)
    80004024:	e022                	sd	s0,0(sp)
    80004026:	0800                	addi	s0,sp,16
    80004028:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000402a:	4585                	li	a1,1
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	db4080e7          	jalr	-588(ra) # 80003de0 <namex>
}
    80004034:	60a2                	ld	ra,8(sp)
    80004036:	6402                	ld	s0,0(sp)
    80004038:	0141                	addi	sp,sp,16
    8000403a:	8082                	ret

000000008000403c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000403c:	1101                	addi	sp,sp,-32
    8000403e:	ec06                	sd	ra,24(sp)
    80004040:	e822                	sd	s0,16(sp)
    80004042:	e426                	sd	s1,8(sp)
    80004044:	e04a                	sd	s2,0(sp)
    80004046:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004048:	0001e917          	auipc	s2,0x1e
    8000404c:	ac090913          	addi	s2,s2,-1344 # 80021b08 <log>
    80004050:	01892583          	lw	a1,24(s2)
    80004054:	02892503          	lw	a0,40(s2)
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	ff8080e7          	jalr	-8(ra) # 80003050 <bread>
    80004060:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004062:	02c92683          	lw	a3,44(s2)
    80004066:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004068:	02d05763          	blez	a3,80004096 <write_head+0x5a>
    8000406c:	0001e797          	auipc	a5,0x1e
    80004070:	acc78793          	addi	a5,a5,-1332 # 80021b38 <log+0x30>
    80004074:	05c50713          	addi	a4,a0,92
    80004078:	36fd                	addiw	a3,a3,-1
    8000407a:	1682                	slli	a3,a3,0x20
    8000407c:	9281                	srli	a3,a3,0x20
    8000407e:	068a                	slli	a3,a3,0x2
    80004080:	0001e617          	auipc	a2,0x1e
    80004084:	abc60613          	addi	a2,a2,-1348 # 80021b3c <log+0x34>
    80004088:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000408a:	4390                	lw	a2,0(a5)
    8000408c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000408e:	0791                	addi	a5,a5,4
    80004090:	0711                	addi	a4,a4,4
    80004092:	fed79ce3          	bne	a5,a3,8000408a <write_head+0x4e>
  }
  bwrite(buf);
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	0aa080e7          	jalr	170(ra) # 80003142 <bwrite>
  brelse(buf);
    800040a0:	8526                	mv	a0,s1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	0de080e7          	jalr	222(ra) # 80003180 <brelse>
}
    800040aa:	60e2                	ld	ra,24(sp)
    800040ac:	6442                	ld	s0,16(sp)
    800040ae:	64a2                	ld	s1,8(sp)
    800040b0:	6902                	ld	s2,0(sp)
    800040b2:	6105                	addi	sp,sp,32
    800040b4:	8082                	ret

00000000800040b6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b6:	0001e797          	auipc	a5,0x1e
    800040ba:	a7e7a783          	lw	a5,-1410(a5) # 80021b34 <log+0x2c>
    800040be:	0af05663          	blez	a5,8000416a <install_trans+0xb4>
{
    800040c2:	7139                	addi	sp,sp,-64
    800040c4:	fc06                	sd	ra,56(sp)
    800040c6:	f822                	sd	s0,48(sp)
    800040c8:	f426                	sd	s1,40(sp)
    800040ca:	f04a                	sd	s2,32(sp)
    800040cc:	ec4e                	sd	s3,24(sp)
    800040ce:	e852                	sd	s4,16(sp)
    800040d0:	e456                	sd	s5,8(sp)
    800040d2:	0080                	addi	s0,sp,64
    800040d4:	0001ea97          	auipc	s5,0x1e
    800040d8:	a64a8a93          	addi	s5,s5,-1436 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040dc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040de:	0001e997          	auipc	s3,0x1e
    800040e2:	a2a98993          	addi	s3,s3,-1494 # 80021b08 <log>
    800040e6:	0189a583          	lw	a1,24(s3)
    800040ea:	014585bb          	addw	a1,a1,s4
    800040ee:	2585                	addiw	a1,a1,1
    800040f0:	0289a503          	lw	a0,40(s3)
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	f5c080e7          	jalr	-164(ra) # 80003050 <bread>
    800040fc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040fe:	000aa583          	lw	a1,0(s5)
    80004102:	0289a503          	lw	a0,40(s3)
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	f4a080e7          	jalr	-182(ra) # 80003050 <bread>
    8000410e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004110:	40000613          	li	a2,1024
    80004114:	05890593          	addi	a1,s2,88
    80004118:	05850513          	addi	a0,a0,88
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	c3a080e7          	jalr	-966(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	01c080e7          	jalr	28(ra) # 80003142 <bwrite>
    bunpin(dbuf);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	12a080e7          	jalr	298(ra) # 8000325a <bunpin>
    brelse(lbuf);
    80004138:	854a                	mv	a0,s2
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	046080e7          	jalr	70(ra) # 80003180 <brelse>
    brelse(dbuf);
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	03c080e7          	jalr	60(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000414c:	2a05                	addiw	s4,s4,1
    8000414e:	0a91                	addi	s5,s5,4
    80004150:	02c9a783          	lw	a5,44(s3)
    80004154:	f8fa49e3          	blt	s4,a5,800040e6 <install_trans+0x30>
}
    80004158:	70e2                	ld	ra,56(sp)
    8000415a:	7442                	ld	s0,48(sp)
    8000415c:	74a2                	ld	s1,40(sp)
    8000415e:	7902                	ld	s2,32(sp)
    80004160:	69e2                	ld	s3,24(sp)
    80004162:	6a42                	ld	s4,16(sp)
    80004164:	6aa2                	ld	s5,8(sp)
    80004166:	6121                	addi	sp,sp,64
    80004168:	8082                	ret
    8000416a:	8082                	ret

000000008000416c <initlog>:
{
    8000416c:	7179                	addi	sp,sp,-48
    8000416e:	f406                	sd	ra,40(sp)
    80004170:	f022                	sd	s0,32(sp)
    80004172:	ec26                	sd	s1,24(sp)
    80004174:	e84a                	sd	s2,16(sp)
    80004176:	e44e                	sd	s3,8(sp)
    80004178:	1800                	addi	s0,sp,48
    8000417a:	892a                	mv	s2,a0
    8000417c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000417e:	0001e497          	auipc	s1,0x1e
    80004182:	98a48493          	addi	s1,s1,-1654 # 80021b08 <log>
    80004186:	00004597          	auipc	a1,0x4
    8000418a:	47a58593          	addi	a1,a1,1146 # 80008600 <syscalls+0x1d8>
    8000418e:	8526                	mv	a0,s1
    80004190:	ffffd097          	auipc	ra,0xffffd
    80004194:	9de080e7          	jalr	-1570(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    80004198:	0149a583          	lw	a1,20(s3)
    8000419c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000419e:	0109a783          	lw	a5,16(s3)
    800041a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041a8:	854a                	mv	a0,s2
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	ea6080e7          	jalr	-346(ra) # 80003050 <bread>
  log.lh.n = lh->n;
    800041b2:	4d34                	lw	a3,88(a0)
    800041b4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041b6:	02d05563          	blez	a3,800041e0 <initlog+0x74>
    800041ba:	05c50793          	addi	a5,a0,92
    800041be:	0001e717          	auipc	a4,0x1e
    800041c2:	97a70713          	addi	a4,a4,-1670 # 80021b38 <log+0x30>
    800041c6:	36fd                	addiw	a3,a3,-1
    800041c8:	1682                	slli	a3,a3,0x20
    800041ca:	9281                	srli	a3,a3,0x20
    800041cc:	068a                	slli	a3,a3,0x2
    800041ce:	06050613          	addi	a2,a0,96
    800041d2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041d4:	4390                	lw	a2,0(a5)
    800041d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	0791                	addi	a5,a5,4
    800041da:	0711                	addi	a4,a4,4
    800041dc:	fed79ce3          	bne	a5,a3,800041d4 <initlog+0x68>
  brelse(buf);
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	fa0080e7          	jalr	-96(ra) # 80003180 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	ece080e7          	jalr	-306(ra) # 800040b6 <install_trans>
  log.lh.n = 0;
    800041f0:	0001e797          	auipc	a5,0x1e
    800041f4:	9407a223          	sw	zero,-1724(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	e44080e7          	jalr	-444(ra) # 8000403c <write_head>
}
    80004200:	70a2                	ld	ra,40(sp)
    80004202:	7402                	ld	s0,32(sp)
    80004204:	64e2                	ld	s1,24(sp)
    80004206:	6942                	ld	s2,16(sp)
    80004208:	69a2                	ld	s3,8(sp)
    8000420a:	6145                	addi	sp,sp,48
    8000420c:	8082                	ret

000000008000420e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000420e:	1101                	addi	sp,sp,-32
    80004210:	ec06                	sd	ra,24(sp)
    80004212:	e822                	sd	s0,16(sp)
    80004214:	e426                	sd	s1,8(sp)
    80004216:	e04a                	sd	s2,0(sp)
    80004218:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000421a:	0001e517          	auipc	a0,0x1e
    8000421e:	8ee50513          	addi	a0,a0,-1810 # 80021b08 <log>
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	9dc080e7          	jalr	-1572(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    8000422a:	0001e497          	auipc	s1,0x1e
    8000422e:	8de48493          	addi	s1,s1,-1826 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004232:	4979                	li	s2,30
    80004234:	a039                	j	80004242 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004236:	85a6                	mv	a1,s1
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	0a6080e7          	jalr	166(ra) # 800022e0 <sleep>
    if(log.committing){
    80004242:	50dc                	lw	a5,36(s1)
    80004244:	fbed                	bnez	a5,80004236 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004246:	509c                	lw	a5,32(s1)
    80004248:	0017871b          	addiw	a4,a5,1
    8000424c:	0007069b          	sext.w	a3,a4
    80004250:	0027179b          	slliw	a5,a4,0x2
    80004254:	9fb9                	addw	a5,a5,a4
    80004256:	0017979b          	slliw	a5,a5,0x1
    8000425a:	54d8                	lw	a4,44(s1)
    8000425c:	9fb9                	addw	a5,a5,a4
    8000425e:	00f95963          	bge	s2,a5,80004270 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004262:	85a6                	mv	a1,s1
    80004264:	8526                	mv	a0,s1
    80004266:	ffffe097          	auipc	ra,0xffffe
    8000426a:	07a080e7          	jalr	122(ra) # 800022e0 <sleep>
    8000426e:	bfd1                	j	80004242 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004270:	0001e517          	auipc	a0,0x1e
    80004274:	89850513          	addi	a0,a0,-1896 # 80021b08 <log>
    80004278:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	a38080e7          	jalr	-1480(ra) # 80000cb2 <release>
      break;
    }
  }
}
    80004282:	60e2                	ld	ra,24(sp)
    80004284:	6442                	ld	s0,16(sp)
    80004286:	64a2                	ld	s1,8(sp)
    80004288:	6902                	ld	s2,0(sp)
    8000428a:	6105                	addi	sp,sp,32
    8000428c:	8082                	ret

000000008000428e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000428e:	7139                	addi	sp,sp,-64
    80004290:	fc06                	sd	ra,56(sp)
    80004292:	f822                	sd	s0,48(sp)
    80004294:	f426                	sd	s1,40(sp)
    80004296:	f04a                	sd	s2,32(sp)
    80004298:	ec4e                	sd	s3,24(sp)
    8000429a:	e852                	sd	s4,16(sp)
    8000429c:	e456                	sd	s5,8(sp)
    8000429e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a0:	0001e497          	auipc	s1,0x1e
    800042a4:	86848493          	addi	s1,s1,-1944 # 80021b08 <log>
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	954080e7          	jalr	-1708(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    800042b2:	509c                	lw	a5,32(s1)
    800042b4:	37fd                	addiw	a5,a5,-1
    800042b6:	0007891b          	sext.w	s2,a5
    800042ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042bc:	50dc                	lw	a5,36(s1)
    800042be:	e7b9                	bnez	a5,8000430c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c0:	04091e63          	bnez	s2,8000431c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042c4:	0001e497          	auipc	s1,0x1e
    800042c8:	84448493          	addi	s1,s1,-1980 # 80021b08 <log>
    800042cc:	4785                	li	a5,1
    800042ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	9e0080e7          	jalr	-1568(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042da:	54dc                	lw	a5,44(s1)
    800042dc:	06f04763          	bgtz	a5,8000434a <end_op+0xbc>
    acquire(&log.lock);
    800042e0:	0001e497          	auipc	s1,0x1e
    800042e4:	82848493          	addi	s1,s1,-2008 # 80021b08 <log>
    800042e8:	8526                	mv	a0,s1
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	914080e7          	jalr	-1772(ra) # 80000bfe <acquire>
    log.committing = 0;
    800042f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffe097          	auipc	ra,0xffffe
    800042fc:	168080e7          	jalr	360(ra) # 80002460 <wakeup>
    release(&log.lock);
    80004300:	8526                	mv	a0,s1
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	9b0080e7          	jalr	-1616(ra) # 80000cb2 <release>
}
    8000430a:	a03d                	j	80004338 <end_op+0xaa>
    panic("log.committing");
    8000430c:	00004517          	auipc	a0,0x4
    80004310:	2fc50513          	addi	a0,a0,764 # 80008608 <syscalls+0x1e0>
    80004314:	ffffc097          	auipc	ra,0xffffc
    80004318:	22e080e7          	jalr	558(ra) # 80000542 <panic>
    wakeup(&log);
    8000431c:	0001d497          	auipc	s1,0x1d
    80004320:	7ec48493          	addi	s1,s1,2028 # 80021b08 <log>
    80004324:	8526                	mv	a0,s1
    80004326:	ffffe097          	auipc	ra,0xffffe
    8000432a:	13a080e7          	jalr	314(ra) # 80002460 <wakeup>
  release(&log.lock);
    8000432e:	8526                	mv	a0,s1
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	982080e7          	jalr	-1662(ra) # 80000cb2 <release>
}
    80004338:	70e2                	ld	ra,56(sp)
    8000433a:	7442                	ld	s0,48(sp)
    8000433c:	74a2                	ld	s1,40(sp)
    8000433e:	7902                	ld	s2,32(sp)
    80004340:	69e2                	ld	s3,24(sp)
    80004342:	6a42                	ld	s4,16(sp)
    80004344:	6aa2                	ld	s5,8(sp)
    80004346:	6121                	addi	sp,sp,64
    80004348:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434a:	0001da97          	auipc	s5,0x1d
    8000434e:	7eea8a93          	addi	s5,s5,2030 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004352:	0001da17          	auipc	s4,0x1d
    80004356:	7b6a0a13          	addi	s4,s4,1974 # 80021b08 <log>
    8000435a:	018a2583          	lw	a1,24(s4)
    8000435e:	012585bb          	addw	a1,a1,s2
    80004362:	2585                	addiw	a1,a1,1
    80004364:	028a2503          	lw	a0,40(s4)
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	ce8080e7          	jalr	-792(ra) # 80003050 <bread>
    80004370:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004372:	000aa583          	lw	a1,0(s5)
    80004376:	028a2503          	lw	a0,40(s4)
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	cd6080e7          	jalr	-810(ra) # 80003050 <bread>
    80004382:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004384:	40000613          	li	a2,1024
    80004388:	05850593          	addi	a1,a0,88
    8000438c:	05848513          	addi	a0,s1,88
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	9c6080e7          	jalr	-1594(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    80004398:	8526                	mv	a0,s1
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	da8080e7          	jalr	-600(ra) # 80003142 <bwrite>
    brelse(from);
    800043a2:	854e                	mv	a0,s3
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	ddc080e7          	jalr	-548(ra) # 80003180 <brelse>
    brelse(to);
    800043ac:	8526                	mv	a0,s1
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	dd2080e7          	jalr	-558(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b6:	2905                	addiw	s2,s2,1
    800043b8:	0a91                	addi	s5,s5,4
    800043ba:	02ca2783          	lw	a5,44(s4)
    800043be:	f8f94ee3          	blt	s2,a5,8000435a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	c7a080e7          	jalr	-902(ra) # 8000403c <write_head>
    install_trans(); // Now install writes to home locations
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	cec080e7          	jalr	-788(ra) # 800040b6 <install_trans>
    log.lh.n = 0;
    800043d2:	0001d797          	auipc	a5,0x1d
    800043d6:	7607a123          	sw	zero,1890(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043da:	00000097          	auipc	ra,0x0
    800043de:	c62080e7          	jalr	-926(ra) # 8000403c <write_head>
    800043e2:	bdfd                	j	800042e0 <end_op+0x52>

00000000800043e4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043e4:	1101                	addi	sp,sp,-32
    800043e6:	ec06                	sd	ra,24(sp)
    800043e8:	e822                	sd	s0,16(sp)
    800043ea:	e426                	sd	s1,8(sp)
    800043ec:	e04a                	sd	s2,0(sp)
    800043ee:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043f0:	0001d717          	auipc	a4,0x1d
    800043f4:	74472703          	lw	a4,1860(a4) # 80021b34 <log+0x2c>
    800043f8:	47f5                	li	a5,29
    800043fa:	08e7c063          	blt	a5,a4,8000447a <log_write+0x96>
    800043fe:	84aa                	mv	s1,a0
    80004400:	0001d797          	auipc	a5,0x1d
    80004404:	7247a783          	lw	a5,1828(a5) # 80021b24 <log+0x1c>
    80004408:	37fd                	addiw	a5,a5,-1
    8000440a:	06f75863          	bge	a4,a5,8000447a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000440e:	0001d797          	auipc	a5,0x1d
    80004412:	71a7a783          	lw	a5,1818(a5) # 80021b28 <log+0x20>
    80004416:	06f05a63          	blez	a5,8000448a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000441a:	0001d917          	auipc	s2,0x1d
    8000441e:	6ee90913          	addi	s2,s2,1774 # 80021b08 <log>
    80004422:	854a                	mv	a0,s2
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7da080e7          	jalr	2010(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000442c:	02c92603          	lw	a2,44(s2)
    80004430:	06c05563          	blez	a2,8000449a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004434:	44cc                	lw	a1,12(s1)
    80004436:	0001d717          	auipc	a4,0x1d
    8000443a:	70270713          	addi	a4,a4,1794 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000443e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004440:	4314                	lw	a3,0(a4)
    80004442:	04b68d63          	beq	a3,a1,8000449c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004446:	2785                	addiw	a5,a5,1
    80004448:	0711                	addi	a4,a4,4
    8000444a:	fec79be3          	bne	a5,a2,80004440 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000444e:	0621                	addi	a2,a2,8
    80004450:	060a                	slli	a2,a2,0x2
    80004452:	0001d797          	auipc	a5,0x1d
    80004456:	6b678793          	addi	a5,a5,1718 # 80021b08 <log>
    8000445a:	963e                	add	a2,a2,a5
    8000445c:	44dc                	lw	a5,12(s1)
    8000445e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004460:	8526                	mv	a0,s1
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	dbc080e7          	jalr	-580(ra) # 8000321e <bpin>
    log.lh.n++;
    8000446a:	0001d717          	auipc	a4,0x1d
    8000446e:	69e70713          	addi	a4,a4,1694 # 80021b08 <log>
    80004472:	575c                	lw	a5,44(a4)
    80004474:	2785                	addiw	a5,a5,1
    80004476:	d75c                	sw	a5,44(a4)
    80004478:	a83d                	j	800044b6 <log_write+0xd2>
    panic("too big a transaction");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	19e50513          	addi	a0,a0,414 # 80008618 <syscalls+0x1f0>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0c0080e7          	jalr	192(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    8000448a:	00004517          	auipc	a0,0x4
    8000448e:	1a650513          	addi	a0,a0,422 # 80008630 <syscalls+0x208>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	0b0080e7          	jalr	176(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000449a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000449c:	00878713          	addi	a4,a5,8
    800044a0:	00271693          	slli	a3,a4,0x2
    800044a4:	0001d717          	auipc	a4,0x1d
    800044a8:	66470713          	addi	a4,a4,1636 # 80021b08 <log>
    800044ac:	9736                	add	a4,a4,a3
    800044ae:	44d4                	lw	a3,12(s1)
    800044b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b2:	faf607e3          	beq	a2,a5,80004460 <log_write+0x7c>
  }
  release(&log.lock);
    800044b6:	0001d517          	auipc	a0,0x1d
    800044ba:	65250513          	addi	a0,a0,1618 # 80021b08 <log>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7f4080e7          	jalr	2036(ra) # 80000cb2 <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
    800044e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e2:	00004597          	auipc	a1,0x4
    800044e6:	16e58593          	addi	a1,a1,366 # 80008650 <syscalls+0x228>
    800044ea:	0521                	addi	a0,a0,8
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	682080e7          	jalr	1666(ra) # 80000b6e <initlock>
  lk->name = name;
    800044f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fc:	0204a423          	sw	zero,40(s1)
}
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6902                	ld	s2,0(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret

000000008000450c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	e04a                	sd	s2,0(sp)
    80004516:	1000                	addi	s0,sp,32
    80004518:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451a:	00850913          	addi	s2,a0,8
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6de080e7          	jalr	1758(ra) # 80000bfe <acquire>
  while (lk->locked) {
    80004528:	409c                	lw	a5,0(s1)
    8000452a:	cb89                	beqz	a5,8000453c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000452c:	85ca                	mv	a1,s2
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	db0080e7          	jalr	-592(ra) # 800022e0 <sleep>
  while (lk->locked) {
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	fbed                	bnez	a5,8000452c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000453c:	4785                	li	a5,1
    8000453e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	4f4080e7          	jalr	1268(ra) # 80001a34 <myproc>
    80004548:	5d1c                	lw	a5,56(a0)
    8000454a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	764080e7          	jalr	1892(ra) # 80000cb2 <release>
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004570:	00850913          	addi	s2,a0,8
    80004574:	854a                	mv	a0,s2
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	688080e7          	jalr	1672(ra) # 80000bfe <acquire>
  lk->locked = 0;
    8000457e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004582:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004586:	8526                	mv	a0,s1
    80004588:	ffffe097          	auipc	ra,0xffffe
    8000458c:	ed8080e7          	jalr	-296(ra) # 80002460 <wakeup>
  release(&lk->lk);
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	720080e7          	jalr	1824(ra) # 80000cb2 <release>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a6:	7179                	addi	sp,sp,-48
    800045a8:	f406                	sd	ra,40(sp)
    800045aa:	f022                	sd	s0,32(sp)
    800045ac:	ec26                	sd	s1,24(sp)
    800045ae:	e84a                	sd	s2,16(sp)
    800045b0:	e44e                	sd	s3,8(sp)
    800045b2:	1800                	addi	s0,sp,48
    800045b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b6:	00850913          	addi	s2,a0,8
    800045ba:	854a                	mv	a0,s2
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	642080e7          	jalr	1602(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	ef99                	bnez	a5,800045e4 <holdingsleep+0x3e>
    800045c8:	4481                	li	s1,0
  release(&lk->lk);
    800045ca:	854a                	mv	a0,s2
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6e6080e7          	jalr	1766(ra) # 80000cb2 <release>
  return r;
}
    800045d4:	8526                	mv	a0,s1
    800045d6:	70a2                	ld	ra,40(sp)
    800045d8:	7402                	ld	s0,32(sp)
    800045da:	64e2                	ld	s1,24(sp)
    800045dc:	6942                	ld	s2,16(sp)
    800045de:	69a2                	ld	s3,8(sp)
    800045e0:	6145                	addi	sp,sp,48
    800045e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e4:	0284a983          	lw	s3,40(s1)
    800045e8:	ffffd097          	auipc	ra,0xffffd
    800045ec:	44c080e7          	jalr	1100(ra) # 80001a34 <myproc>
    800045f0:	5d04                	lw	s1,56(a0)
    800045f2:	413484b3          	sub	s1,s1,s3
    800045f6:	0014b493          	seqz	s1,s1
    800045fa:	bfc1                	j	800045ca <holdingsleep+0x24>

00000000800045fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045fc:	1141                	addi	sp,sp,-16
    800045fe:	e406                	sd	ra,8(sp)
    80004600:	e022                	sd	s0,0(sp)
    80004602:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004604:	00004597          	auipc	a1,0x4
    80004608:	05c58593          	addi	a1,a1,92 # 80008660 <syscalls+0x238>
    8000460c:	0001d517          	auipc	a0,0x1d
    80004610:	64450513          	addi	a0,a0,1604 # 80021c50 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	55a080e7          	jalr	1370(ra) # 80000b6e <initlock>
}
    8000461c:	60a2                	ld	ra,8(sp)
    8000461e:	6402                	ld	s0,0(sp)
    80004620:	0141                	addi	sp,sp,16
    80004622:	8082                	ret

0000000080004624 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004624:	1101                	addi	sp,sp,-32
    80004626:	ec06                	sd	ra,24(sp)
    80004628:	e822                	sd	s0,16(sp)
    8000462a:	e426                	sd	s1,8(sp)
    8000462c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	62250513          	addi	a0,a0,1570 # 80021c50 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5c8080e7          	jalr	1480(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463e:	0001d497          	auipc	s1,0x1d
    80004642:	62a48493          	addi	s1,s1,1578 # 80021c68 <ftable+0x18>
    80004646:	0001e717          	auipc	a4,0x1e
    8000464a:	5c270713          	addi	a4,a4,1474 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	cf99                	beqz	a5,8000466e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004652:	02848493          	addi	s1,s1,40
    80004656:	fee49ce3          	bne	s1,a4,8000464e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000465a:	0001d517          	auipc	a0,0x1d
    8000465e:	5f650513          	addi	a0,a0,1526 # 80021c50 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	650080e7          	jalr	1616(ra) # 80000cb2 <release>
  return 0;
    8000466a:	4481                	li	s1,0
    8000466c:	a819                	j	80004682 <filealloc+0x5e>
      f->ref = 1;
    8000466e:	4785                	li	a5,1
    80004670:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	5de50513          	addi	a0,a0,1502 # 80021c50 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	638080e7          	jalr	1592(ra) # 80000cb2 <release>
}
    80004682:	8526                	mv	a0,s1
    80004684:	60e2                	ld	ra,24(sp)
    80004686:	6442                	ld	s0,16(sp)
    80004688:	64a2                	ld	s1,8(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	1000                	addi	s0,sp,32
    80004698:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000469a:	0001d517          	auipc	a0,0x1d
    8000469e:	5b650513          	addi	a0,a0,1462 # 80021c50 <ftable>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	55c080e7          	jalr	1372(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    800046aa:	40dc                	lw	a5,4(s1)
    800046ac:	02f05263          	blez	a5,800046d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b0:	2785                	addiw	a5,a5,1
    800046b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b4:	0001d517          	auipc	a0,0x1d
    800046b8:	59c50513          	addi	a0,a0,1436 # 80021c50 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5f6080e7          	jalr	1526(ra) # 80000cb2 <release>
  return f;
}
    800046c4:	8526                	mv	a0,s1
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret
    panic("filedup");
    800046d0:	00004517          	auipc	a0,0x4
    800046d4:	f9850513          	addi	a0,a0,-104 # 80008668 <syscalls+0x240>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	e6a080e7          	jalr	-406(ra) # 80000542 <panic>

00000000800046e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e0:	7139                	addi	sp,sp,-64
    800046e2:	fc06                	sd	ra,56(sp)
    800046e4:	f822                	sd	s0,48(sp)
    800046e6:	f426                	sd	s1,40(sp)
    800046e8:	f04a                	sd	s2,32(sp)
    800046ea:	ec4e                	sd	s3,24(sp)
    800046ec:	e852                	sd	s4,16(sp)
    800046ee:	e456                	sd	s5,8(sp)
    800046f0:	0080                	addi	s0,sp,64
    800046f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f4:	0001d517          	auipc	a0,0x1d
    800046f8:	55c50513          	addi	a0,a0,1372 # 80021c50 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	502080e7          	jalr	1282(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004704:	40dc                	lw	a5,4(s1)
    80004706:	06f05163          	blez	a5,80004768 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000470a:	37fd                	addiw	a5,a5,-1
    8000470c:	0007871b          	sext.w	a4,a5
    80004710:	c0dc                	sw	a5,4(s1)
    80004712:	06e04363          	bgtz	a4,80004778 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004716:	0004a903          	lw	s2,0(s1)
    8000471a:	0094ca83          	lbu	s5,9(s1)
    8000471e:	0104ba03          	ld	s4,16(s1)
    80004722:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004726:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000472a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472e:	0001d517          	auipc	a0,0x1d
    80004732:	52250513          	addi	a0,a0,1314 # 80021c50 <ftable>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	57c080e7          	jalr	1404(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    8000473e:	4785                	li	a5,1
    80004740:	04f90d63          	beq	s2,a5,8000479a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004744:	3979                	addiw	s2,s2,-2
    80004746:	4785                	li	a5,1
    80004748:	0527e063          	bltu	a5,s2,80004788 <fileclose+0xa8>
    begin_op();
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	ac2080e7          	jalr	-1342(ra) # 8000420e <begin_op>
    iput(ff.ip);
    80004754:	854e                	mv	a0,s3
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	2b6080e7          	jalr	694(ra) # 80003a0c <iput>
    end_op();
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	b30080e7          	jalr	-1232(ra) # 8000428e <end_op>
    80004766:	a00d                	j	80004788 <fileclose+0xa8>
    panic("fileclose");
    80004768:	00004517          	auipc	a0,0x4
    8000476c:	f0850513          	addi	a0,a0,-248 # 80008670 <syscalls+0x248>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	dd2080e7          	jalr	-558(ra) # 80000542 <panic>
    release(&ftable.lock);
    80004778:	0001d517          	auipc	a0,0x1d
    8000477c:	4d850513          	addi	a0,a0,1240 # 80021c50 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	532080e7          	jalr	1330(ra) # 80000cb2 <release>
  }
}
    80004788:	70e2                	ld	ra,56(sp)
    8000478a:	7442                	ld	s0,48(sp)
    8000478c:	74a2                	ld	s1,40(sp)
    8000478e:	7902                	ld	s2,32(sp)
    80004790:	69e2                	ld	s3,24(sp)
    80004792:	6a42                	ld	s4,16(sp)
    80004794:	6aa2                	ld	s5,8(sp)
    80004796:	6121                	addi	sp,sp,64
    80004798:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000479a:	85d6                	mv	a1,s5
    8000479c:	8552                	mv	a0,s4
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	372080e7          	jalr	882(ra) # 80004b10 <pipeclose>
    800047a6:	b7cd                	j	80004788 <fileclose+0xa8>

00000000800047a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a8:	715d                	addi	sp,sp,-80
    800047aa:	e486                	sd	ra,72(sp)
    800047ac:	e0a2                	sd	s0,64(sp)
    800047ae:	fc26                	sd	s1,56(sp)
    800047b0:	f84a                	sd	s2,48(sp)
    800047b2:	f44e                	sd	s3,40(sp)
    800047b4:	0880                	addi	s0,sp,80
    800047b6:	84aa                	mv	s1,a0
    800047b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ba:	ffffd097          	auipc	ra,0xffffd
    800047be:	27a080e7          	jalr	634(ra) # 80001a34 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c2:	409c                	lw	a5,0(s1)
    800047c4:	37f9                	addiw	a5,a5,-2
    800047c6:	4705                	li	a4,1
    800047c8:	04f76763          	bltu	a4,a5,80004816 <filestat+0x6e>
    800047cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	082080e7          	jalr	130(ra) # 80003852 <ilock>
    stati(f->ip, &st);
    800047d8:	fb840593          	addi	a1,s0,-72
    800047dc:	6c88                	ld	a0,24(s1)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	2fe080e7          	jalr	766(ra) # 80003adc <stati>
    iunlock(f->ip);
    800047e6:	6c88                	ld	a0,24(s1)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	12c080e7          	jalr	300(ra) # 80003914 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f0:	46e1                	li	a3,24
    800047f2:	fb840613          	addi	a2,s0,-72
    800047f6:	85ce                	mv	a1,s3
    800047f8:	05093503          	ld	a0,80(s2)
    800047fc:	ffffd097          	auipc	ra,0xffffd
    80004800:	eca080e7          	jalr	-310(ra) # 800016c6 <copyout>
    80004804:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004808:	60a6                	ld	ra,72(sp)
    8000480a:	6406                	ld	s0,64(sp)
    8000480c:	74e2                	ld	s1,56(sp)
    8000480e:	7942                	ld	s2,48(sp)
    80004810:	79a2                	ld	s3,40(sp)
    80004812:	6161                	addi	sp,sp,80
    80004814:	8082                	ret
  return -1;
    80004816:	557d                	li	a0,-1
    80004818:	bfc5                	j	80004808 <filestat+0x60>

000000008000481a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000481a:	7179                	addi	sp,sp,-48
    8000481c:	f406                	sd	ra,40(sp)
    8000481e:	f022                	sd	s0,32(sp)
    80004820:	ec26                	sd	s1,24(sp)
    80004822:	e84a                	sd	s2,16(sp)
    80004824:	e44e                	sd	s3,8(sp)
    80004826:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004828:	00854783          	lbu	a5,8(a0)
    8000482c:	c3d5                	beqz	a5,800048d0 <fileread+0xb6>
    8000482e:	84aa                	mv	s1,a0
    80004830:	89ae                	mv	s3,a1
    80004832:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004834:	411c                	lw	a5,0(a0)
    80004836:	4705                	li	a4,1
    80004838:	04e78963          	beq	a5,a4,8000488a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000483c:	470d                	li	a4,3
    8000483e:	04e78d63          	beq	a5,a4,80004898 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004842:	4709                	li	a4,2
    80004844:	06e79e63          	bne	a5,a4,800048c0 <fileread+0xa6>
    ilock(f->ip);
    80004848:	6d08                	ld	a0,24(a0)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	008080e7          	jalr	8(ra) # 80003852 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004852:	874a                	mv	a4,s2
    80004854:	5094                	lw	a3,32(s1)
    80004856:	864e                	mv	a2,s3
    80004858:	4585                	li	a1,1
    8000485a:	6c88                	ld	a0,24(s1)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	2aa080e7          	jalr	682(ra) # 80003b06 <readi>
    80004864:	892a                	mv	s2,a0
    80004866:	00a05563          	blez	a0,80004870 <fileread+0x56>
      f->off += r;
    8000486a:	509c                	lw	a5,32(s1)
    8000486c:	9fa9                	addw	a5,a5,a0
    8000486e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	0a2080e7          	jalr	162(ra) # 80003914 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000487a:	854a                	mv	a0,s2
    8000487c:	70a2                	ld	ra,40(sp)
    8000487e:	7402                	ld	s0,32(sp)
    80004880:	64e2                	ld	s1,24(sp)
    80004882:	6942                	ld	s2,16(sp)
    80004884:	69a2                	ld	s3,8(sp)
    80004886:	6145                	addi	sp,sp,48
    80004888:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000488a:	6908                	ld	a0,16(a0)
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	3f4080e7          	jalr	1012(ra) # 80004c80 <piperead>
    80004894:	892a                	mv	s2,a0
    80004896:	b7d5                	j	8000487a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004898:	02451783          	lh	a5,36(a0)
    8000489c:	03079693          	slli	a3,a5,0x30
    800048a0:	92c1                	srli	a3,a3,0x30
    800048a2:	4725                	li	a4,9
    800048a4:	02d76863          	bltu	a4,a3,800048d4 <fileread+0xba>
    800048a8:	0792                	slli	a5,a5,0x4
    800048aa:	0001d717          	auipc	a4,0x1d
    800048ae:	30670713          	addi	a4,a4,774 # 80021bb0 <devsw>
    800048b2:	97ba                	add	a5,a5,a4
    800048b4:	639c                	ld	a5,0(a5)
    800048b6:	c38d                	beqz	a5,800048d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048b8:	4505                	li	a0,1
    800048ba:	9782                	jalr	a5
    800048bc:	892a                	mv	s2,a0
    800048be:	bf75                	j	8000487a <fileread+0x60>
    panic("fileread");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	dc050513          	addi	a0,a0,-576 # 80008680 <syscalls+0x258>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c7a080e7          	jalr	-902(ra) # 80000542 <panic>
    return -1;
    800048d0:	597d                	li	s2,-1
    800048d2:	b765                	j	8000487a <fileread+0x60>
      return -1;
    800048d4:	597d                	li	s2,-1
    800048d6:	b755                	j	8000487a <fileread+0x60>
    800048d8:	597d                	li	s2,-1
    800048da:	b745                	j	8000487a <fileread+0x60>

00000000800048dc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048dc:	00954783          	lbu	a5,9(a0)
    800048e0:	14078563          	beqz	a5,80004a2a <filewrite+0x14e>
{
    800048e4:	715d                	addi	sp,sp,-80
    800048e6:	e486                	sd	ra,72(sp)
    800048e8:	e0a2                	sd	s0,64(sp)
    800048ea:	fc26                	sd	s1,56(sp)
    800048ec:	f84a                	sd	s2,48(sp)
    800048ee:	f44e                	sd	s3,40(sp)
    800048f0:	f052                	sd	s4,32(sp)
    800048f2:	ec56                	sd	s5,24(sp)
    800048f4:	e85a                	sd	s6,16(sp)
    800048f6:	e45e                	sd	s7,8(sp)
    800048f8:	e062                	sd	s8,0(sp)
    800048fa:	0880                	addi	s0,sp,80
    800048fc:	892a                	mv	s2,a0
    800048fe:	8aae                	mv	s5,a1
    80004900:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004902:	411c                	lw	a5,0(a0)
    80004904:	4705                	li	a4,1
    80004906:	02e78263          	beq	a5,a4,8000492a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490a:	470d                	li	a4,3
    8000490c:	02e78563          	beq	a5,a4,80004936 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004910:	4709                	li	a4,2
    80004912:	10e79463          	bne	a5,a4,80004a1a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004916:	0ec05e63          	blez	a2,80004a12 <filewrite+0x136>
    int i = 0;
    8000491a:	4981                	li	s3,0
    8000491c:	6b05                	lui	s6,0x1
    8000491e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004922:	6b85                	lui	s7,0x1
    80004924:	c00b8b9b          	addiw	s7,s7,-1024
    80004928:	a851                	j	800049bc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000492a:	6908                	ld	a0,16(a0)
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	254080e7          	jalr	596(ra) # 80004b80 <pipewrite>
    80004934:	a85d                	j	800049ea <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004936:	02451783          	lh	a5,36(a0)
    8000493a:	03079693          	slli	a3,a5,0x30
    8000493e:	92c1                	srli	a3,a3,0x30
    80004940:	4725                	li	a4,9
    80004942:	0ed76663          	bltu	a4,a3,80004a2e <filewrite+0x152>
    80004946:	0792                	slli	a5,a5,0x4
    80004948:	0001d717          	auipc	a4,0x1d
    8000494c:	26870713          	addi	a4,a4,616 # 80021bb0 <devsw>
    80004950:	97ba                	add	a5,a5,a4
    80004952:	679c                	ld	a5,8(a5)
    80004954:	cff9                	beqz	a5,80004a32 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004956:	4505                	li	a0,1
    80004958:	9782                	jalr	a5
    8000495a:	a841                	j	800049ea <filewrite+0x10e>
    8000495c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004960:	00000097          	auipc	ra,0x0
    80004964:	8ae080e7          	jalr	-1874(ra) # 8000420e <begin_op>
      ilock(f->ip);
    80004968:	01893503          	ld	a0,24(s2)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	ee6080e7          	jalr	-282(ra) # 80003852 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004974:	8762                	mv	a4,s8
    80004976:	02092683          	lw	a3,32(s2)
    8000497a:	01598633          	add	a2,s3,s5
    8000497e:	4585                	li	a1,1
    80004980:	01893503          	ld	a0,24(s2)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	278080e7          	jalr	632(ra) # 80003bfc <writei>
    8000498c:	84aa                	mv	s1,a0
    8000498e:	02a05f63          	blez	a0,800049cc <filewrite+0xf0>
        f->off += r;
    80004992:	02092783          	lw	a5,32(s2)
    80004996:	9fa9                	addw	a5,a5,a0
    80004998:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000499c:	01893503          	ld	a0,24(s2)
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	f74080e7          	jalr	-140(ra) # 80003914 <iunlock>
      end_op();
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	8e6080e7          	jalr	-1818(ra) # 8000428e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049b0:	049c1963          	bne	s8,s1,80004a02 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049b4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049b8:	0349d663          	bge	s3,s4,800049e4 <filewrite+0x108>
      int n1 = n - i;
    800049bc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049c0:	84be                	mv	s1,a5
    800049c2:	2781                	sext.w	a5,a5
    800049c4:	f8fb5ce3          	bge	s6,a5,8000495c <filewrite+0x80>
    800049c8:	84de                	mv	s1,s7
    800049ca:	bf49                	j	8000495c <filewrite+0x80>
      iunlock(f->ip);
    800049cc:	01893503          	ld	a0,24(s2)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	f44080e7          	jalr	-188(ra) # 80003914 <iunlock>
      end_op();
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	8b6080e7          	jalr	-1866(ra) # 8000428e <end_op>
      if(r < 0)
    800049e0:	fc04d8e3          	bgez	s1,800049b0 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049e4:	8552                	mv	a0,s4
    800049e6:	033a1863          	bne	s4,s3,80004a16 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ea:	60a6                	ld	ra,72(sp)
    800049ec:	6406                	ld	s0,64(sp)
    800049ee:	74e2                	ld	s1,56(sp)
    800049f0:	7942                	ld	s2,48(sp)
    800049f2:	79a2                	ld	s3,40(sp)
    800049f4:	7a02                	ld	s4,32(sp)
    800049f6:	6ae2                	ld	s5,24(sp)
    800049f8:	6b42                	ld	s6,16(sp)
    800049fa:	6ba2                	ld	s7,8(sp)
    800049fc:	6c02                	ld	s8,0(sp)
    800049fe:	6161                	addi	sp,sp,80
    80004a00:	8082                	ret
        panic("short filewrite");
    80004a02:	00004517          	auipc	a0,0x4
    80004a06:	c8e50513          	addi	a0,a0,-882 # 80008690 <syscalls+0x268>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	b38080e7          	jalr	-1224(ra) # 80000542 <panic>
    int i = 0;
    80004a12:	4981                	li	s3,0
    80004a14:	bfc1                	j	800049e4 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a16:	557d                	li	a0,-1
    80004a18:	bfc9                	j	800049ea <filewrite+0x10e>
    panic("filewrite");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	c8650513          	addi	a0,a0,-890 # 800086a0 <syscalls+0x278>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b20080e7          	jalr	-1248(ra) # 80000542 <panic>
    return -1;
    80004a2a:	557d                	li	a0,-1
}
    80004a2c:	8082                	ret
      return -1;
    80004a2e:	557d                	li	a0,-1
    80004a30:	bf6d                	j	800049ea <filewrite+0x10e>
    80004a32:	557d                	li	a0,-1
    80004a34:	bf5d                	j	800049ea <filewrite+0x10e>

0000000080004a36 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a36:	7179                	addi	sp,sp,-48
    80004a38:	f406                	sd	ra,40(sp)
    80004a3a:	f022                	sd	s0,32(sp)
    80004a3c:	ec26                	sd	s1,24(sp)
    80004a3e:	e84a                	sd	s2,16(sp)
    80004a40:	e44e                	sd	s3,8(sp)
    80004a42:	e052                	sd	s4,0(sp)
    80004a44:	1800                	addi	s0,sp,48
    80004a46:	84aa                	mv	s1,a0
    80004a48:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a4a:	0005b023          	sd	zero,0(a1)
    80004a4e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	bd2080e7          	jalr	-1070(ra) # 80004624 <filealloc>
    80004a5a:	e088                	sd	a0,0(s1)
    80004a5c:	c551                	beqz	a0,80004ae8 <pipealloc+0xb2>
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	bc6080e7          	jalr	-1082(ra) # 80004624 <filealloc>
    80004a66:	00aa3023          	sd	a0,0(s4)
    80004a6a:	c92d                	beqz	a0,80004adc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	0a2080e7          	jalr	162(ra) # 80000b0e <kalloc>
    80004a74:	892a                	mv	s2,a0
    80004a76:	c125                	beqz	a0,80004ad6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a78:	4985                	li	s3,1
    80004a7a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a7e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a82:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a86:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a8a:	00004597          	auipc	a1,0x4
    80004a8e:	c2658593          	addi	a1,a1,-986 # 800086b0 <syscalls+0x288>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	0dc080e7          	jalr	220(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004a9a:	609c                	ld	a5,0(s1)
    80004a9c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aa0:	609c                	ld	a5,0(s1)
    80004aa2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aa6:	609c                	ld	a5,0(s1)
    80004aa8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aac:	609c                	ld	a5,0(s1)
    80004aae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ab2:	000a3783          	ld	a5,0(s4)
    80004ab6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aba:	000a3783          	ld	a5,0(s4)
    80004abe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ac2:	000a3783          	ld	a5,0(s4)
    80004ac6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aca:	000a3783          	ld	a5,0(s4)
    80004ace:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ad2:	4501                	li	a0,0
    80004ad4:	a025                	j	80004afc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ad6:	6088                	ld	a0,0(s1)
    80004ad8:	e501                	bnez	a0,80004ae0 <pipealloc+0xaa>
    80004ada:	a039                	j	80004ae8 <pipealloc+0xb2>
    80004adc:	6088                	ld	a0,0(s1)
    80004ade:	c51d                	beqz	a0,80004b0c <pipealloc+0xd6>
    fileclose(*f0);
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	c00080e7          	jalr	-1024(ra) # 800046e0 <fileclose>
  if(*f1)
    80004ae8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aec:	557d                	li	a0,-1
  if(*f1)
    80004aee:	c799                	beqz	a5,80004afc <pipealloc+0xc6>
    fileclose(*f1);
    80004af0:	853e                	mv	a0,a5
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	bee080e7          	jalr	-1042(ra) # 800046e0 <fileclose>
  return -1;
    80004afa:	557d                	li	a0,-1
}
    80004afc:	70a2                	ld	ra,40(sp)
    80004afe:	7402                	ld	s0,32(sp)
    80004b00:	64e2                	ld	s1,24(sp)
    80004b02:	6942                	ld	s2,16(sp)
    80004b04:	69a2                	ld	s3,8(sp)
    80004b06:	6a02                	ld	s4,0(sp)
    80004b08:	6145                	addi	sp,sp,48
    80004b0a:	8082                	ret
  return -1;
    80004b0c:	557d                	li	a0,-1
    80004b0e:	b7fd                	j	80004afc <pipealloc+0xc6>

0000000080004b10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b10:	1101                	addi	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	e04a                	sd	s2,0(sp)
    80004b1a:	1000                	addi	s0,sp,32
    80004b1c:	84aa                	mv	s1,a0
    80004b1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	0de080e7          	jalr	222(ra) # 80000bfe <acquire>
  if(writable){
    80004b28:	02090d63          	beqz	s2,80004b62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b30:	21848513          	addi	a0,s1,536
    80004b34:	ffffe097          	auipc	ra,0xffffe
    80004b38:	92c080e7          	jalr	-1748(ra) # 80002460 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b3c:	2204b783          	ld	a5,544(s1)
    80004b40:	eb95                	bnez	a5,80004b74 <pipeclose+0x64>
    release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	16e080e7          	jalr	366(ra) # 80000cb2 <release>
    kfree((char*)pi);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	ec4080e7          	jalr	-316(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004b56:	60e2                	ld	ra,24(sp)
    80004b58:	6442                	ld	s0,16(sp)
    80004b5a:	64a2                	ld	s1,8(sp)
    80004b5c:	6902                	ld	s2,0(sp)
    80004b5e:	6105                	addi	sp,sp,32
    80004b60:	8082                	ret
    pi->readopen = 0;
    80004b62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b66:	21c48513          	addi	a0,s1,540
    80004b6a:	ffffe097          	auipc	ra,0xffffe
    80004b6e:	8f6080e7          	jalr	-1802(ra) # 80002460 <wakeup>
    80004b72:	b7e9                	j	80004b3c <pipeclose+0x2c>
    release(&pi->lock);
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	13c080e7          	jalr	316(ra) # 80000cb2 <release>
}
    80004b7e:	bfe1                	j	80004b56 <pipeclose+0x46>

0000000080004b80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b80:	711d                	addi	sp,sp,-96
    80004b82:	ec86                	sd	ra,88(sp)
    80004b84:	e8a2                	sd	s0,80(sp)
    80004b86:	e4a6                	sd	s1,72(sp)
    80004b88:	e0ca                	sd	s2,64(sp)
    80004b8a:	fc4e                	sd	s3,56(sp)
    80004b8c:	f852                	sd	s4,48(sp)
    80004b8e:	f456                	sd	s5,40(sp)
    80004b90:	f05a                	sd	s6,32(sp)
    80004b92:	ec5e                	sd	s7,24(sp)
    80004b94:	e862                	sd	s8,16(sp)
    80004b96:	1080                	addi	s0,sp,96
    80004b98:	84aa                	mv	s1,a0
    80004b9a:	8b2e                	mv	s6,a1
    80004b9c:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	e96080e7          	jalr	-362(ra) # 80001a34 <myproc>
    80004ba6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	054080e7          	jalr	84(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004bb2:	09505763          	blez	s5,80004c40 <pipewrite+0xc0>
    80004bb6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004bb8:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bbc:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc0:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bc2:	2184a783          	lw	a5,536(s1)
    80004bc6:	21c4a703          	lw	a4,540(s1)
    80004bca:	2007879b          	addiw	a5,a5,512
    80004bce:	02f71b63          	bne	a4,a5,80004c04 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004bd2:	2204a783          	lw	a5,544(s1)
    80004bd6:	c3d1                	beqz	a5,80004c5a <pipewrite+0xda>
    80004bd8:	03092783          	lw	a5,48(s2)
    80004bdc:	efbd                	bnez	a5,80004c5a <pipewrite+0xda>
      wakeup(&pi->nread);
    80004bde:	8552                	mv	a0,s4
    80004be0:	ffffe097          	auipc	ra,0xffffe
    80004be4:	880080e7          	jalr	-1920(ra) # 80002460 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004be8:	85a6                	mv	a1,s1
    80004bea:	854e                	mv	a0,s3
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	6f4080e7          	jalr	1780(ra) # 800022e0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bf4:	2184a783          	lw	a5,536(s1)
    80004bf8:	21c4a703          	lw	a4,540(s1)
    80004bfc:	2007879b          	addiw	a5,a5,512
    80004c00:	fcf709e3          	beq	a4,a5,80004bd2 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c04:	4685                	li	a3,1
    80004c06:	865a                	mv	a2,s6
    80004c08:	faf40593          	addi	a1,s0,-81
    80004c0c:	05093503          	ld	a0,80(s2)
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	c22080e7          	jalr	-990(ra) # 80001832 <copyin>
    80004c18:	03850563          	beq	a0,s8,80004c42 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c1c:	21c4a783          	lw	a5,540(s1)
    80004c20:	0017871b          	addiw	a4,a5,1
    80004c24:	20e4ae23          	sw	a4,540(s1)
    80004c28:	1ff7f793          	andi	a5,a5,511
    80004c2c:	97a6                	add	a5,a5,s1
    80004c2e:	faf44703          	lbu	a4,-81(s0)
    80004c32:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c36:	2b85                	addiw	s7,s7,1
    80004c38:	0b05                	addi	s6,s6,1
    80004c3a:	f97a94e3          	bne	s5,s7,80004bc2 <pipewrite+0x42>
    80004c3e:	a011                	j	80004c42 <pipewrite+0xc2>
    80004c40:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004c42:	21848513          	addi	a0,s1,536
    80004c46:	ffffe097          	auipc	ra,0xffffe
    80004c4a:	81a080e7          	jalr	-2022(ra) # 80002460 <wakeup>
  release(&pi->lock);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	062080e7          	jalr	98(ra) # 80000cb2 <release>
  return i;
    80004c58:	a039                	j	80004c66 <pipewrite+0xe6>
        release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	056080e7          	jalr	86(ra) # 80000cb2 <release>
        return -1;
    80004c64:	5bfd                	li	s7,-1
}
    80004c66:	855e                	mv	a0,s7
    80004c68:	60e6                	ld	ra,88(sp)
    80004c6a:	6446                	ld	s0,80(sp)
    80004c6c:	64a6                	ld	s1,72(sp)
    80004c6e:	6906                	ld	s2,64(sp)
    80004c70:	79e2                	ld	s3,56(sp)
    80004c72:	7a42                	ld	s4,48(sp)
    80004c74:	7aa2                	ld	s5,40(sp)
    80004c76:	7b02                	ld	s6,32(sp)
    80004c78:	6be2                	ld	s7,24(sp)
    80004c7a:	6c42                	ld	s8,16(sp)
    80004c7c:	6125                	addi	sp,sp,96
    80004c7e:	8082                	ret

0000000080004c80 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c80:	715d                	addi	sp,sp,-80
    80004c82:	e486                	sd	ra,72(sp)
    80004c84:	e0a2                	sd	s0,64(sp)
    80004c86:	fc26                	sd	s1,56(sp)
    80004c88:	f84a                	sd	s2,48(sp)
    80004c8a:	f44e                	sd	s3,40(sp)
    80004c8c:	f052                	sd	s4,32(sp)
    80004c8e:	ec56                	sd	s5,24(sp)
    80004c90:	e85a                	sd	s6,16(sp)
    80004c92:	0880                	addi	s0,sp,80
    80004c94:	84aa                	mv	s1,a0
    80004c96:	892e                	mv	s2,a1
    80004c98:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	d9a080e7          	jalr	-614(ra) # 80001a34 <myproc>
    80004ca2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	f58080e7          	jalr	-168(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cae:	2184a703          	lw	a4,536(s1)
    80004cb2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cba:	02f71463          	bne	a4,a5,80004ce2 <piperead+0x62>
    80004cbe:	2244a783          	lw	a5,548(s1)
    80004cc2:	c385                	beqz	a5,80004ce2 <piperead+0x62>
    if(pr->killed){
    80004cc4:	030a2783          	lw	a5,48(s4)
    80004cc8:	ebc1                	bnez	a5,80004d58 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cca:	85a6                	mv	a1,s1
    80004ccc:	854e                	mv	a0,s3
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	612080e7          	jalr	1554(ra) # 800022e0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd6:	2184a703          	lw	a4,536(s1)
    80004cda:	21c4a783          	lw	a5,540(s1)
    80004cde:	fef700e3          	beq	a4,a5,80004cbe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce6:	05505363          	blez	s5,80004d2c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004cea:	2184a783          	lw	a5,536(s1)
    80004cee:	21c4a703          	lw	a4,540(s1)
    80004cf2:	02f70d63          	beq	a4,a5,80004d2c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cf6:	0017871b          	addiw	a4,a5,1
    80004cfa:	20e4ac23          	sw	a4,536(s1)
    80004cfe:	1ff7f793          	andi	a5,a5,511
    80004d02:	97a6                	add	a5,a5,s1
    80004d04:	0187c783          	lbu	a5,24(a5)
    80004d08:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d0c:	4685                	li	a3,1
    80004d0e:	fbf40613          	addi	a2,s0,-65
    80004d12:	85ca                	mv	a1,s2
    80004d14:	050a3503          	ld	a0,80(s4)
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	9ae080e7          	jalr	-1618(ra) # 800016c6 <copyout>
    80004d20:	01650663          	beq	a0,s6,80004d2c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d24:	2985                	addiw	s3,s3,1
    80004d26:	0905                	addi	s2,s2,1
    80004d28:	fd3a91e3          	bne	s5,s3,80004cea <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d2c:	21c48513          	addi	a0,s1,540
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	730080e7          	jalr	1840(ra) # 80002460 <wakeup>
  release(&pi->lock);
    80004d38:	8526                	mv	a0,s1
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	f78080e7          	jalr	-136(ra) # 80000cb2 <release>
  return i;
}
    80004d42:	854e                	mv	a0,s3
    80004d44:	60a6                	ld	ra,72(sp)
    80004d46:	6406                	ld	s0,64(sp)
    80004d48:	74e2                	ld	s1,56(sp)
    80004d4a:	7942                	ld	s2,48(sp)
    80004d4c:	79a2                	ld	s3,40(sp)
    80004d4e:	7a02                	ld	s4,32(sp)
    80004d50:	6ae2                	ld	s5,24(sp)
    80004d52:	6b42                	ld	s6,16(sp)
    80004d54:	6161                	addi	sp,sp,80
    80004d56:	8082                	ret
      release(&pi->lock);
    80004d58:	8526                	mv	a0,s1
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	f58080e7          	jalr	-168(ra) # 80000cb2 <release>
      return -1;
    80004d62:	59fd                	li	s3,-1
    80004d64:	bff9                	j	80004d42 <piperead+0xc2>

0000000080004d66 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d66:	dd010113          	addi	sp,sp,-560
    80004d6a:	22113423          	sd	ra,552(sp)
    80004d6e:	22813023          	sd	s0,544(sp)
    80004d72:	20913c23          	sd	s1,536(sp)
    80004d76:	21213823          	sd	s2,528(sp)
    80004d7a:	21313423          	sd	s3,520(sp)
    80004d7e:	21413023          	sd	s4,512(sp)
    80004d82:	ffd6                	sd	s5,504(sp)
    80004d84:	fbda                	sd	s6,496(sp)
    80004d86:	f7de                	sd	s7,488(sp)
    80004d88:	f3e2                	sd	s8,480(sp)
    80004d8a:	efe6                	sd	s9,472(sp)
    80004d8c:	ebea                	sd	s10,464(sp)
    80004d8e:	e7ee                	sd	s11,456(sp)
    80004d90:	1c00                	addi	s0,sp,560
    80004d92:	892a                	mv	s2,a0
    80004d94:	dea43423          	sd	a0,-536(s0)
    80004d98:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	c98080e7          	jalr	-872(ra) # 80001a34 <myproc>
    80004da4:	84aa                	mv	s1,a0

  begin_op();
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	468080e7          	jalr	1128(ra) # 8000420e <begin_op>

  if((ip = namei(path)) == 0){
    80004dae:	854a                	mv	a0,s2
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	252080e7          	jalr	594(ra) # 80004002 <namei>
    80004db8:	cd2d                	beqz	a0,80004e32 <exec+0xcc>
    80004dba:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	a96080e7          	jalr	-1386(ra) # 80003852 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dc4:	04000713          	li	a4,64
    80004dc8:	4681                	li	a3,0
    80004dca:	e4840613          	addi	a2,s0,-440
    80004dce:	4581                	li	a1,0
    80004dd0:	8552                	mv	a0,s4
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	d34080e7          	jalr	-716(ra) # 80003b06 <readi>
    80004dda:	04000793          	li	a5,64
    80004dde:	00f51a63          	bne	a0,a5,80004df2 <exec+0x8c>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004de2:	e4842703          	lw	a4,-440(s0)
    80004de6:	464c47b7          	lui	a5,0x464c4
    80004dea:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dee:	04f70863          	beq	a4,a5,80004e3e <exec+0xd8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004df2:	8552                	mv	a0,s4
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	cc0080e7          	jalr	-832(ra) # 80003ab4 <iunlockput>
    end_op();
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	492080e7          	jalr	1170(ra) # 8000428e <end_op>
  }
  return -1;
    80004e04:	557d                	li	a0,-1
}
    80004e06:	22813083          	ld	ra,552(sp)
    80004e0a:	22013403          	ld	s0,544(sp)
    80004e0e:	21813483          	ld	s1,536(sp)
    80004e12:	21013903          	ld	s2,528(sp)
    80004e16:	20813983          	ld	s3,520(sp)
    80004e1a:	20013a03          	ld	s4,512(sp)
    80004e1e:	7afe                	ld	s5,504(sp)
    80004e20:	7b5e                	ld	s6,496(sp)
    80004e22:	7bbe                	ld	s7,488(sp)
    80004e24:	7c1e                	ld	s8,480(sp)
    80004e26:	6cfe                	ld	s9,472(sp)
    80004e28:	6d5e                	ld	s10,464(sp)
    80004e2a:	6dbe                	ld	s11,456(sp)
    80004e2c:	23010113          	addi	sp,sp,560
    80004e30:	8082                	ret
    end_op();
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	45c080e7          	jalr	1116(ra) # 8000428e <end_op>
    return -1;
    80004e3a:	557d                	li	a0,-1
    80004e3c:	b7e9                	j	80004e06 <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	d10080e7          	jalr	-752(ra) # 80001b50 <proc_pagetable>
    80004e48:	8b2a                	mv	s6,a0
    80004e4a:	d545                	beqz	a0,80004df2 <exec+0x8c>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e4c:	e6842783          	lw	a5,-408(s0)
    80004e50:	e8045703          	lhu	a4,-384(s0)
    80004e54:	cb35                	beqz	a4,80004ec8 <exec+0x162>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e56:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e58:	e0043423          	sd	zero,-504(s0)
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e5c:	0c000737          	lui	a4,0xc000
    80004e60:	1779                	addi	a4,a4,-2
    80004e62:	dee43023          	sd	a4,-544(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e66:	6a85                	lui	s5,0x1
    80004e68:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80004e6c:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e70:	6d85                	lui	s11,0x1
    80004e72:	aca5                	j	800050ea <exec+0x384>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e74:	00004517          	auipc	a0,0x4
    80004e78:	84450513          	addi	a0,a0,-1980 # 800086b8 <syscalls+0x290>
    80004e7c:	ffffb097          	auipc	ra,0xffffb
    80004e80:	6c6080e7          	jalr	1734(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e84:	874a                	mv	a4,s2
    80004e86:	009c86bb          	addw	a3,s9,s1
    80004e8a:	4581                	li	a1,0
    80004e8c:	8552                	mv	a0,s4
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	c78080e7          	jalr	-904(ra) # 80003b06 <readi>
    80004e96:	2501                	sext.w	a0,a0
    80004e98:	1ea91963          	bne	s2,a0,8000508a <exec+0x324>
  for(i = 0; i < sz; i += PGSIZE){
    80004e9c:	009d84bb          	addw	s1,s11,s1
    80004ea0:	013d09bb          	addw	s3,s10,s3
    80004ea4:	2374f363          	bgeu	s1,s7,800050ca <exec+0x364>
    pa = walkaddr(pagetable, va + i);
    80004ea8:	02049593          	slli	a1,s1,0x20
    80004eac:	9181                	srli	a1,a1,0x20
    80004eae:	95e2                	add	a1,a1,s8
    80004eb0:	855a                	mv	a0,s6
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	1de080e7          	jalr	478(ra) # 80001090 <walkaddr>
    80004eba:	862a                	mv	a2,a0
    if(pa == 0)
    80004ebc:	dd45                	beqz	a0,80004e74 <exec+0x10e>
      n = PGSIZE;
    80004ebe:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80004ec0:	fd59f2e3          	bgeu	s3,s5,80004e84 <exec+0x11e>
      n = sz - i;
    80004ec4:	894e                	mv	s2,s3
    80004ec6:	bf7d                	j	80004e84 <exec+0x11e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ec8:	4481                	li	s1,0
  iunlockput(ip);
    80004eca:	8552                	mv	a0,s4
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	be8080e7          	jalr	-1048(ra) # 80003ab4 <iunlockput>
  end_op();
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	3ba080e7          	jalr	954(ra) # 8000428e <end_op>
  p = myproc();
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	b58080e7          	jalr	-1192(ra) # 80001a34 <myproc>
    80004ee4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ee6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eea:	6785                	lui	a5,0x1
    80004eec:	17fd                	addi	a5,a5,-1
    80004eee:	94be                	add	s1,s1,a5
    80004ef0:	77fd                	lui	a5,0xfffff
    80004ef2:	8fe5                	and	a5,a5,s1
    80004ef4:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ef8:	6609                	lui	a2,0x2
    80004efa:	963e                	add	a2,a2,a5
    80004efc:	85be                	mv	a1,a5
    80004efe:	855a                	mv	a0,s6
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	592080e7          	jalr	1426(ra) # 80001492 <uvmalloc>
    80004f08:	8baa                	mv	s7,a0
  ip = 0;
    80004f0a:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f0c:	16050f63          	beqz	a0,8000508a <exec+0x324>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f10:	75f9                	lui	a1,0xffffe
    80004f12:	95aa                	add	a1,a1,a0
    80004f14:	855a                	mv	a0,s6
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	77e080e7          	jalr	1918(ra) # 80001694 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f1e:	7c7d                	lui	s8,0xfffff
    80004f20:	9c5e                	add	s8,s8,s7
  for(argc = 0; argv[argc]; argc++) {
    80004f22:	df043783          	ld	a5,-528(s0)
    80004f26:	6388                	ld	a0,0(a5)
    80004f28:	c925                	beqz	a0,80004f98 <exec+0x232>
    80004f2a:	e8840993          	addi	s3,s0,-376
    80004f2e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f32:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80004f34:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	f48080e7          	jalr	-184(ra) # 80000e7e <strlen>
    80004f3e:	0015079b          	addiw	a5,a0,1
    80004f42:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f46:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f4a:	17896463          	bltu	s2,s8,800050b2 <exec+0x34c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f4e:	df043d83          	ld	s11,-528(s0)
    80004f52:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f56:	8552                	mv	a0,s4
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	f26080e7          	jalr	-218(ra) # 80000e7e <strlen>
    80004f60:	0015069b          	addiw	a3,a0,1
    80004f64:	8652                	mv	a2,s4
    80004f66:	85ca                	mv	a1,s2
    80004f68:	855a                	mv	a0,s6
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	75c080e7          	jalr	1884(ra) # 800016c6 <copyout>
    80004f72:	14054463          	bltz	a0,800050ba <exec+0x354>
    ustack[argc] = sp;
    80004f76:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f7a:	0485                	addi	s1,s1,1
    80004f7c:	008d8793          	addi	a5,s11,8
    80004f80:	def43823          	sd	a5,-528(s0)
    80004f84:	008db503          	ld	a0,8(s11)
    80004f88:	c911                	beqz	a0,80004f9c <exec+0x236>
    if(argc >= MAXARG)
    80004f8a:	09a1                	addi	s3,s3,8
    80004f8c:	fb3c95e3          	bne	s9,s3,80004f36 <exec+0x1d0>
  sz = sz1;
    80004f90:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80004f94:	4a01                	li	s4,0
    80004f96:	a8d5                	j	8000508a <exec+0x324>
  sp = sz;
    80004f98:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80004f9a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9c:	00349793          	slli	a5,s1,0x3
    80004fa0:	f9040713          	addi	a4,s0,-112
    80004fa4:	97ba                	add	a5,a5,a4
    80004fa6:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ed8>
  sp -= (argc+1) * sizeof(uint64);
    80004faa:	00148693          	addi	a3,s1,1
    80004fae:	068e                	slli	a3,a3,0x3
    80004fb0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fb8:	01897663          	bgeu	s2,s8,80004fc4 <exec+0x25e>
  sz = sz1;
    80004fbc:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    80004fc0:	4a01                	li	s4,0
    80004fc2:	a0e1                	j	8000508a <exec+0x324>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc4:	e8840613          	addi	a2,s0,-376
    80004fc8:	85ca                	mv	a1,s2
    80004fca:	855a                	mv	a0,s6
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	6fa080e7          	jalr	1786(ra) # 800016c6 <copyout>
    80004fd4:	0e054763          	bltz	a0,800050c2 <exec+0x35c>
  p->trapframe->a1 = sp;
    80004fd8:	060ab783          	ld	a5,96(s5)
    80004fdc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe0:	de843783          	ld	a5,-536(s0)
    80004fe4:	0007c703          	lbu	a4,0(a5)
    80004fe8:	cf11                	beqz	a4,80005004 <exec+0x29e>
    80004fea:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fec:	02f00693          	li	a3,47
    80004ff0:	a039                	j	80004ffe <exec+0x298>
      last = s+1;
    80004ff2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ff6:	0785                	addi	a5,a5,1
    80004ff8:	fff7c703          	lbu	a4,-1(a5)
    80004ffc:	c701                	beqz	a4,80005004 <exec+0x29e>
    if(*s == '/')
    80004ffe:	fed71ce3          	bne	a4,a3,80004ff6 <exec+0x290>
    80005002:	bfc5                	j	80004ff2 <exec+0x28c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005004:	4641                	li	a2,16
    80005006:	de843583          	ld	a1,-536(s0)
    8000500a:	160a8513          	addi	a0,s5,352
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	e3e080e7          	jalr	-450(ra) # 80000e4c <safestrcpy>
  uvmunmap(p->kernelpgtbl, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    80005016:	6605                	lui	a2,0x1
    80005018:	167d                	addi	a2,a2,-1
    8000501a:	966a                	add	a2,a2,s10
    8000501c:	4681                	li	a3,0
    8000501e:	8231                	srli	a2,a2,0xc
    80005020:	4581                	li	a1,0
    80005022:	058ab503          	ld	a0,88(s5)
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	2de080e7          	jalr	734(ra) # 80001304 <uvmunmap>
  kvmcopymappings(pagetable, p->kernelpgtbl, 0, sz);
    8000502e:	86de                	mv	a3,s7
    80005030:	4601                	li	a2,0
    80005032:	058ab583          	ld	a1,88(s5)
    80005036:	855a                	mv	a0,s6
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	71a080e7          	jalr	1818(ra) # 80001752 <kvmcopymappings>
  oldpagetable = p->pagetable;
    80005040:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005044:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005048:	057ab423          	sd	s7,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000504c:	060ab783          	ld	a5,96(s5)
    80005050:	e6043703          	ld	a4,-416(s0)
    80005054:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005056:	060ab783          	ld	a5,96(s5)
    8000505a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000505e:	85ea                	mv	a1,s10
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	b8c080e7          	jalr	-1140(ra) # 80001bec <proc_freepagetable>
  if(p->pid == 1) vmprint(p->pagetable);// 按照实验要求，在 exec 返回之前打印一下页表。
    80005068:	038aa703          	lw	a4,56(s5)
    8000506c:	4785                	li	a5,1
    8000506e:	00f70563          	beq	a4,a5,80005078 <exec+0x312>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005072:	0004851b          	sext.w	a0,s1
    80005076:	bb41                	j	80004e06 <exec+0xa0>
  if(p->pid == 1) vmprint(p->pagetable);// 按照实验要求，在 exec 返回之前打印一下页表。
    80005078:	050ab503          	ld	a0,80(s5)
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	8ac080e7          	jalr	-1876(ra) # 80001928 <vmprint>
    80005084:	b7fd                	j	80005072 <exec+0x30c>
    80005086:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000508a:	df843583          	ld	a1,-520(s0)
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	b5c080e7          	jalr	-1188(ra) # 80001bec <proc_freepagetable>
  if(ip){
    80005098:	d40a1de3          	bnez	s4,80004df2 <exec+0x8c>
  return -1;
    8000509c:	557d                	li	a0,-1
    8000509e:	b3a5                	j	80004e06 <exec+0xa0>
    800050a0:	de943c23          	sd	s1,-520(s0)
    800050a4:	b7dd                	j	8000508a <exec+0x324>
    800050a6:	de943c23          	sd	s1,-520(s0)
    800050aa:	b7c5                	j	8000508a <exec+0x324>
    800050ac:	de943c23          	sd	s1,-520(s0)
    800050b0:	bfe9                	j	8000508a <exec+0x324>
  sz = sz1;
    800050b2:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    800050b6:	4a01                	li	s4,0
    800050b8:	bfc9                	j	8000508a <exec+0x324>
  sz = sz1;
    800050ba:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    800050be:	4a01                	li	s4,0
    800050c0:	b7e9                	j	8000508a <exec+0x324>
  sz = sz1;
    800050c2:	df743c23          	sd	s7,-520(s0)
  ip = 0;
    800050c6:	4a01                	li	s4,0
    800050c8:	b7c9                	j	8000508a <exec+0x324>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ca:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ce:	e0843783          	ld	a5,-504(s0)
    800050d2:	0017869b          	addiw	a3,a5,1
    800050d6:	e0d43423          	sd	a3,-504(s0)
    800050da:	e0043783          	ld	a5,-512(s0)
    800050de:	0387879b          	addiw	a5,a5,56
    800050e2:	e8045703          	lhu	a4,-384(s0)
    800050e6:	dee6d2e3          	bge	a3,a4,80004eca <exec+0x164>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ea:	2781                	sext.w	a5,a5
    800050ec:	e0f43023          	sd	a5,-512(s0)
    800050f0:	03800713          	li	a4,56
    800050f4:	86be                	mv	a3,a5
    800050f6:	e1040613          	addi	a2,s0,-496
    800050fa:	4581                	li	a1,0
    800050fc:	8552                	mv	a0,s4
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	a08080e7          	jalr	-1528(ra) # 80003b06 <readi>
    80005106:	03800793          	li	a5,56
    8000510a:	f6f51ee3          	bne	a0,a5,80005086 <exec+0x320>
    if(ph.type != ELF_PROG_LOAD)
    8000510e:	e1042783          	lw	a5,-496(s0)
    80005112:	4705                	li	a4,1
    80005114:	fae79de3          	bne	a5,a4,800050ce <exec+0x368>
    if(ph.memsz < ph.filesz)
    80005118:	e3843603          	ld	a2,-456(s0)
    8000511c:	e3043783          	ld	a5,-464(s0)
    80005120:	f8f660e3          	bltu	a2,a5,800050a0 <exec+0x33a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005124:	e2043783          	ld	a5,-480(s0)
    80005128:	963e                	add	a2,a2,a5
    8000512a:	f6f66ee3          	bltu	a2,a5,800050a6 <exec+0x340>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512e:	85a6                	mv	a1,s1
    80005130:	855a                	mv	a0,s6
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	360080e7          	jalr	864(ra) # 80001492 <uvmalloc>
    8000513a:	dea43c23          	sd	a0,-520(s0)
    8000513e:	fff50793          	addi	a5,a0,-1
    80005142:	de043703          	ld	a4,-544(s0)
    80005146:	f6f763e3          	bltu	a4,a5,800050ac <exec+0x346>
    if(ph.vaddr % PGSIZE != 0)
    8000514a:	e2043c03          	ld	s8,-480(s0)
    8000514e:	dd843783          	ld	a5,-552(s0)
    80005152:	00fc77b3          	and	a5,s8,a5
    80005156:	fb95                	bnez	a5,8000508a <exec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005158:	e1842c83          	lw	s9,-488(s0)
    8000515c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005160:	f60b85e3          	beqz	s7,800050ca <exec+0x364>
    80005164:	89de                	mv	s3,s7
    80005166:	4481                	li	s1,0
    80005168:	7d7d                	lui	s10,0xfffff
    8000516a:	bb3d                	j	80004ea8 <exec+0x142>

000000008000516c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000516c:	7179                	addi	sp,sp,-48
    8000516e:	f406                	sd	ra,40(sp)
    80005170:	f022                	sd	s0,32(sp)
    80005172:	ec26                	sd	s1,24(sp)
    80005174:	e84a                	sd	s2,16(sp)
    80005176:	1800                	addi	s0,sp,48
    80005178:	892e                	mv	s2,a1
    8000517a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000517c:	fdc40593          	addi	a1,s0,-36
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	b38080e7          	jalr	-1224(ra) # 80002cb8 <argint>
    80005188:	04054063          	bltz	a0,800051c8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000518c:	fdc42703          	lw	a4,-36(s0)
    80005190:	47bd                	li	a5,15
    80005192:	02e7ed63          	bltu	a5,a4,800051cc <argfd+0x60>
    80005196:	ffffd097          	auipc	ra,0xffffd
    8000519a:	89e080e7          	jalr	-1890(ra) # 80001a34 <myproc>
    8000519e:	fdc42703          	lw	a4,-36(s0)
    800051a2:	01a70793          	addi	a5,a4,26 # c00001a <_entry-0x73ffffe6>
    800051a6:	078e                	slli	a5,a5,0x3
    800051a8:	953e                	add	a0,a0,a5
    800051aa:	651c                	ld	a5,8(a0)
    800051ac:	c395                	beqz	a5,800051d0 <argfd+0x64>
    return -1;
  if(pfd)
    800051ae:	00090463          	beqz	s2,800051b6 <argfd+0x4a>
    *pfd = fd;
    800051b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b6:	4501                	li	a0,0
  if(pf)
    800051b8:	c091                	beqz	s1,800051bc <argfd+0x50>
    *pf = f;
    800051ba:	e09c                	sd	a5,0(s1)
}
    800051bc:	70a2                	ld	ra,40(sp)
    800051be:	7402                	ld	s0,32(sp)
    800051c0:	64e2                	ld	s1,24(sp)
    800051c2:	6942                	ld	s2,16(sp)
    800051c4:	6145                	addi	sp,sp,48
    800051c6:	8082                	ret
    return -1;
    800051c8:	557d                	li	a0,-1
    800051ca:	bfcd                	j	800051bc <argfd+0x50>
    return -1;
    800051cc:	557d                	li	a0,-1
    800051ce:	b7fd                	j	800051bc <argfd+0x50>
    800051d0:	557d                	li	a0,-1
    800051d2:	b7ed                	j	800051bc <argfd+0x50>

00000000800051d4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051d4:	1101                	addi	sp,sp,-32
    800051d6:	ec06                	sd	ra,24(sp)
    800051d8:	e822                	sd	s0,16(sp)
    800051da:	e426                	sd	s1,8(sp)
    800051dc:	1000                	addi	s0,sp,32
    800051de:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	854080e7          	jalr	-1964(ra) # 80001a34 <myproc>
    800051e8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051ea:	0d850793          	addi	a5,a0,216
    800051ee:	4501                	li	a0,0
    800051f0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051f2:	6398                	ld	a4,0(a5)
    800051f4:	cb19                	beqz	a4,8000520a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051f6:	2505                	addiw	a0,a0,1
    800051f8:	07a1                	addi	a5,a5,8
    800051fa:	fed51ce3          	bne	a0,a3,800051f2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051fe:	557d                	li	a0,-1
}
    80005200:	60e2                	ld	ra,24(sp)
    80005202:	6442                	ld	s0,16(sp)
    80005204:	64a2                	ld	s1,8(sp)
    80005206:	6105                	addi	sp,sp,32
    80005208:	8082                	ret
      p->ofile[fd] = f;
    8000520a:	01a50793          	addi	a5,a0,26
    8000520e:	078e                	slli	a5,a5,0x3
    80005210:	963e                	add	a2,a2,a5
    80005212:	e604                	sd	s1,8(a2)
      return fd;
    80005214:	b7f5                	j	80005200 <fdalloc+0x2c>

0000000080005216 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005216:	715d                	addi	sp,sp,-80
    80005218:	e486                	sd	ra,72(sp)
    8000521a:	e0a2                	sd	s0,64(sp)
    8000521c:	fc26                	sd	s1,56(sp)
    8000521e:	f84a                	sd	s2,48(sp)
    80005220:	f44e                	sd	s3,40(sp)
    80005222:	f052                	sd	s4,32(sp)
    80005224:	ec56                	sd	s5,24(sp)
    80005226:	0880                	addi	s0,sp,80
    80005228:	89ae                	mv	s3,a1
    8000522a:	8ab2                	mv	s5,a2
    8000522c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000522e:	fb040593          	addi	a1,s0,-80
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	dee080e7          	jalr	-530(ra) # 80004020 <nameiparent>
    8000523a:	892a                	mv	s2,a0
    8000523c:	12050e63          	beqz	a0,80005378 <create+0x162>
    return 0;

  ilock(dp);
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	612080e7          	jalr	1554(ra) # 80003852 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005248:	4601                	li	a2,0
    8000524a:	fb040593          	addi	a1,s0,-80
    8000524e:	854a                	mv	a0,s2
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	ae0080e7          	jalr	-1312(ra) # 80003d30 <dirlookup>
    80005258:	84aa                	mv	s1,a0
    8000525a:	c921                	beqz	a0,800052aa <create+0x94>
    iunlockput(dp);
    8000525c:	854a                	mv	a0,s2
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	856080e7          	jalr	-1962(ra) # 80003ab4 <iunlockput>
    ilock(ip);
    80005266:	8526                	mv	a0,s1
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	5ea080e7          	jalr	1514(ra) # 80003852 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005270:	2981                	sext.w	s3,s3
    80005272:	4789                	li	a5,2
    80005274:	02f99463          	bne	s3,a5,8000529c <create+0x86>
    80005278:	0444d783          	lhu	a5,68(s1)
    8000527c:	37f9                	addiw	a5,a5,-2
    8000527e:	17c2                	slli	a5,a5,0x30
    80005280:	93c1                	srli	a5,a5,0x30
    80005282:	4705                	li	a4,1
    80005284:	00f76c63          	bltu	a4,a5,8000529c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005288:	8526                	mv	a0,s1
    8000528a:	60a6                	ld	ra,72(sp)
    8000528c:	6406                	ld	s0,64(sp)
    8000528e:	74e2                	ld	s1,56(sp)
    80005290:	7942                	ld	s2,48(sp)
    80005292:	79a2                	ld	s3,40(sp)
    80005294:	7a02                	ld	s4,32(sp)
    80005296:	6ae2                	ld	s5,24(sp)
    80005298:	6161                	addi	sp,sp,80
    8000529a:	8082                	ret
    iunlockput(ip);
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	816080e7          	jalr	-2026(ra) # 80003ab4 <iunlockput>
    return 0;
    800052a6:	4481                	li	s1,0
    800052a8:	b7c5                	j	80005288 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052aa:	85ce                	mv	a1,s3
    800052ac:	00092503          	lw	a0,0(s2)
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	40a080e7          	jalr	1034(ra) # 800036ba <ialloc>
    800052b8:	84aa                	mv	s1,a0
    800052ba:	c521                	beqz	a0,80005302 <create+0xec>
  ilock(ip);
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	596080e7          	jalr	1430(ra) # 80003852 <ilock>
  ip->major = major;
    800052c4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052c8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052cc:	4a05                	li	s4,1
    800052ce:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	4b4080e7          	jalr	1204(ra) # 80003788 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052dc:	2981                	sext.w	s3,s3
    800052de:	03498a63          	beq	s3,s4,80005312 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e2:	40d0                	lw	a2,4(s1)
    800052e4:	fb040593          	addi	a1,s0,-80
    800052e8:	854a                	mv	a0,s2
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	c56080e7          	jalr	-938(ra) # 80003f40 <dirlink>
    800052f2:	06054b63          	bltz	a0,80005368 <create+0x152>
  iunlockput(dp);
    800052f6:	854a                	mv	a0,s2
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	7bc080e7          	jalr	1980(ra) # 80003ab4 <iunlockput>
  return ip;
    80005300:	b761                	j	80005288 <create+0x72>
    panic("create: ialloc");
    80005302:	00003517          	auipc	a0,0x3
    80005306:	3d650513          	addi	a0,a0,982 # 800086d8 <syscalls+0x2b0>
    8000530a:	ffffb097          	auipc	ra,0xffffb
    8000530e:	238080e7          	jalr	568(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005312:	04a95783          	lhu	a5,74(s2)
    80005316:	2785                	addiw	a5,a5,1
    80005318:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000531c:	854a                	mv	a0,s2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	46a080e7          	jalr	1130(ra) # 80003788 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005326:	40d0                	lw	a2,4(s1)
    80005328:	00003597          	auipc	a1,0x3
    8000532c:	3c058593          	addi	a1,a1,960 # 800086e8 <syscalls+0x2c0>
    80005330:	8526                	mv	a0,s1
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	c0e080e7          	jalr	-1010(ra) # 80003f40 <dirlink>
    8000533a:	00054f63          	bltz	a0,80005358 <create+0x142>
    8000533e:	00492603          	lw	a2,4(s2)
    80005342:	00003597          	auipc	a1,0x3
    80005346:	e0e58593          	addi	a1,a1,-498 # 80008150 <digits+0x120>
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	bf4080e7          	jalr	-1036(ra) # 80003f40 <dirlink>
    80005354:	f80557e3          	bgez	a0,800052e2 <create+0xcc>
      panic("create dots");
    80005358:	00003517          	auipc	a0,0x3
    8000535c:	39850513          	addi	a0,a0,920 # 800086f0 <syscalls+0x2c8>
    80005360:	ffffb097          	auipc	ra,0xffffb
    80005364:	1e2080e7          	jalr	482(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005368:	00003517          	auipc	a0,0x3
    8000536c:	39850513          	addi	a0,a0,920 # 80008700 <syscalls+0x2d8>
    80005370:	ffffb097          	auipc	ra,0xffffb
    80005374:	1d2080e7          	jalr	466(ra) # 80000542 <panic>
    return 0;
    80005378:	84aa                	mv	s1,a0
    8000537a:	b739                	j	80005288 <create+0x72>

000000008000537c <sys_dup>:
{
    8000537c:	7179                	addi	sp,sp,-48
    8000537e:	f406                	sd	ra,40(sp)
    80005380:	f022                	sd	s0,32(sp)
    80005382:	ec26                	sd	s1,24(sp)
    80005384:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005386:	fd840613          	addi	a2,s0,-40
    8000538a:	4581                	li	a1,0
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	dde080e7          	jalr	-546(ra) # 8000516c <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005398:	02054363          	bltz	a0,800053be <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000539c:	fd843503          	ld	a0,-40(s0)
    800053a0:	00000097          	auipc	ra,0x0
    800053a4:	e34080e7          	jalr	-460(ra) # 800051d4 <fdalloc>
    800053a8:	84aa                	mv	s1,a0
    return -1;
    800053aa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ac:	00054963          	bltz	a0,800053be <sys_dup+0x42>
  filedup(f);
    800053b0:	fd843503          	ld	a0,-40(s0)
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	2da080e7          	jalr	730(ra) # 8000468e <filedup>
  return fd;
    800053bc:	87a6                	mv	a5,s1
}
    800053be:	853e                	mv	a0,a5
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	64e2                	ld	s1,24(sp)
    800053c6:	6145                	addi	sp,sp,48
    800053c8:	8082                	ret

00000000800053ca <sys_read>:
{
    800053ca:	7179                	addi	sp,sp,-48
    800053cc:	f406                	sd	ra,40(sp)
    800053ce:	f022                	sd	s0,32(sp)
    800053d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	fe840613          	addi	a2,s0,-24
    800053d6:	4581                	li	a1,0
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	d92080e7          	jalr	-622(ra) # 8000516c <argfd>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e4:	04054163          	bltz	a0,80005426 <sys_read+0x5c>
    800053e8:	fe440593          	addi	a1,s0,-28
    800053ec:	4509                	li	a0,2
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	8ca080e7          	jalr	-1846(ra) # 80002cb8 <argint>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f8:	02054763          	bltz	a0,80005426 <sys_read+0x5c>
    800053fc:	fd840593          	addi	a1,s0,-40
    80005400:	4505                	li	a0,1
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	8d8080e7          	jalr	-1832(ra) # 80002cda <argaddr>
    return -1;
    8000540a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540c:	00054d63          	bltz	a0,80005426 <sys_read+0x5c>
  return fileread(f, p, n);
    80005410:	fe442603          	lw	a2,-28(s0)
    80005414:	fd843583          	ld	a1,-40(s0)
    80005418:	fe843503          	ld	a0,-24(s0)
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	3fe080e7          	jalr	1022(ra) # 8000481a <fileread>
    80005424:	87aa                	mv	a5,a0
}
    80005426:	853e                	mv	a0,a5
    80005428:	70a2                	ld	ra,40(sp)
    8000542a:	7402                	ld	s0,32(sp)
    8000542c:	6145                	addi	sp,sp,48
    8000542e:	8082                	ret

0000000080005430 <sys_write>:
{
    80005430:	7179                	addi	sp,sp,-48
    80005432:	f406                	sd	ra,40(sp)
    80005434:	f022                	sd	s0,32(sp)
    80005436:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	fe840613          	addi	a2,s0,-24
    8000543c:	4581                	li	a1,0
    8000543e:	4501                	li	a0,0
    80005440:	00000097          	auipc	ra,0x0
    80005444:	d2c080e7          	jalr	-724(ra) # 8000516c <argfd>
    return -1;
    80005448:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544a:	04054163          	bltz	a0,8000548c <sys_write+0x5c>
    8000544e:	fe440593          	addi	a1,s0,-28
    80005452:	4509                	li	a0,2
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	864080e7          	jalr	-1948(ra) # 80002cb8 <argint>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545e:	02054763          	bltz	a0,8000548c <sys_write+0x5c>
    80005462:	fd840593          	addi	a1,s0,-40
    80005466:	4505                	li	a0,1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	872080e7          	jalr	-1934(ra) # 80002cda <argaddr>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005472:	00054d63          	bltz	a0,8000548c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005476:	fe442603          	lw	a2,-28(s0)
    8000547a:	fd843583          	ld	a1,-40(s0)
    8000547e:	fe843503          	ld	a0,-24(s0)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	45a080e7          	jalr	1114(ra) # 800048dc <filewrite>
    8000548a:	87aa                	mv	a5,a0
}
    8000548c:	853e                	mv	a0,a5
    8000548e:	70a2                	ld	ra,40(sp)
    80005490:	7402                	ld	s0,32(sp)
    80005492:	6145                	addi	sp,sp,48
    80005494:	8082                	ret

0000000080005496 <sys_close>:
{
    80005496:	1101                	addi	sp,sp,-32
    80005498:	ec06                	sd	ra,24(sp)
    8000549a:	e822                	sd	s0,16(sp)
    8000549c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000549e:	fe040613          	addi	a2,s0,-32
    800054a2:	fec40593          	addi	a1,s0,-20
    800054a6:	4501                	li	a0,0
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	cc4080e7          	jalr	-828(ra) # 8000516c <argfd>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054b2:	02054463          	bltz	a0,800054da <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	57e080e7          	jalr	1406(ra) # 80001a34 <myproc>
    800054be:	fec42783          	lw	a5,-20(s0)
    800054c2:	07e9                	addi	a5,a5,26
    800054c4:	078e                	slli	a5,a5,0x3
    800054c6:	97aa                	add	a5,a5,a0
    800054c8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800054cc:	fe043503          	ld	a0,-32(s0)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	210080e7          	jalr	528(ra) # 800046e0 <fileclose>
  return 0;
    800054d8:	4781                	li	a5,0
}
    800054da:	853e                	mv	a0,a5
    800054dc:	60e2                	ld	ra,24(sp)
    800054de:	6442                	ld	s0,16(sp)
    800054e0:	6105                	addi	sp,sp,32
    800054e2:	8082                	ret

00000000800054e4 <sys_fstat>:
{
    800054e4:	1101                	addi	sp,sp,-32
    800054e6:	ec06                	sd	ra,24(sp)
    800054e8:	e822                	sd	s0,16(sp)
    800054ea:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ec:	fe840613          	addi	a2,s0,-24
    800054f0:	4581                	li	a1,0
    800054f2:	4501                	li	a0,0
    800054f4:	00000097          	auipc	ra,0x0
    800054f8:	c78080e7          	jalr	-904(ra) # 8000516c <argfd>
    return -1;
    800054fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fe:	02054563          	bltz	a0,80005528 <sys_fstat+0x44>
    80005502:	fe040593          	addi	a1,s0,-32
    80005506:	4505                	li	a0,1
    80005508:	ffffd097          	auipc	ra,0xffffd
    8000550c:	7d2080e7          	jalr	2002(ra) # 80002cda <argaddr>
    return -1;
    80005510:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005512:	00054b63          	bltz	a0,80005528 <sys_fstat+0x44>
  return filestat(f, st);
    80005516:	fe043583          	ld	a1,-32(s0)
    8000551a:	fe843503          	ld	a0,-24(s0)
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	28a080e7          	jalr	650(ra) # 800047a8 <filestat>
    80005526:	87aa                	mv	a5,a0
}
    80005528:	853e                	mv	a0,a5
    8000552a:	60e2                	ld	ra,24(sp)
    8000552c:	6442                	ld	s0,16(sp)
    8000552e:	6105                	addi	sp,sp,32
    80005530:	8082                	ret

0000000080005532 <sys_link>:
{
    80005532:	7169                	addi	sp,sp,-304
    80005534:	f606                	sd	ra,296(sp)
    80005536:	f222                	sd	s0,288(sp)
    80005538:	ee26                	sd	s1,280(sp)
    8000553a:	ea4a                	sd	s2,272(sp)
    8000553c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553e:	08000613          	li	a2,128
    80005542:	ed040593          	addi	a1,s0,-304
    80005546:	4501                	li	a0,0
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	7b4080e7          	jalr	1972(ra) # 80002cfc <argstr>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005552:	10054e63          	bltz	a0,8000566e <sys_link+0x13c>
    80005556:	08000613          	li	a2,128
    8000555a:	f5040593          	addi	a1,s0,-176
    8000555e:	4505                	li	a0,1
    80005560:	ffffd097          	auipc	ra,0xffffd
    80005564:	79c080e7          	jalr	1948(ra) # 80002cfc <argstr>
    return -1;
    80005568:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000556a:	10054263          	bltz	a0,8000566e <sys_link+0x13c>
  begin_op();
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	ca0080e7          	jalr	-864(ra) # 8000420e <begin_op>
  if((ip = namei(old)) == 0){
    80005576:	ed040513          	addi	a0,s0,-304
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	a88080e7          	jalr	-1400(ra) # 80004002 <namei>
    80005582:	84aa                	mv	s1,a0
    80005584:	c551                	beqz	a0,80005610 <sys_link+0xde>
  ilock(ip);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	2cc080e7          	jalr	716(ra) # 80003852 <ilock>
  if(ip->type == T_DIR){
    8000558e:	04449703          	lh	a4,68(s1)
    80005592:	4785                	li	a5,1
    80005594:	08f70463          	beq	a4,a5,8000561c <sys_link+0xea>
  ip->nlink++;
    80005598:	04a4d783          	lhu	a5,74(s1)
    8000559c:	2785                	addiw	a5,a5,1
    8000559e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	1e4080e7          	jalr	484(ra) # 80003788 <iupdate>
  iunlock(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	366080e7          	jalr	870(ra) # 80003914 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055b6:	fd040593          	addi	a1,s0,-48
    800055ba:	f5040513          	addi	a0,s0,-176
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	a62080e7          	jalr	-1438(ra) # 80004020 <nameiparent>
    800055c6:	892a                	mv	s2,a0
    800055c8:	c935                	beqz	a0,8000563c <sys_link+0x10a>
  ilock(dp);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	288080e7          	jalr	648(ra) # 80003852 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055d2:	00092703          	lw	a4,0(s2)
    800055d6:	409c                	lw	a5,0(s1)
    800055d8:	04f71d63          	bne	a4,a5,80005632 <sys_link+0x100>
    800055dc:	40d0                	lw	a2,4(s1)
    800055de:	fd040593          	addi	a1,s0,-48
    800055e2:	854a                	mv	a0,s2
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	95c080e7          	jalr	-1700(ra) # 80003f40 <dirlink>
    800055ec:	04054363          	bltz	a0,80005632 <sys_link+0x100>
  iunlockput(dp);
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	4c2080e7          	jalr	1218(ra) # 80003ab4 <iunlockput>
  iput(ip);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	410080e7          	jalr	1040(ra) # 80003a0c <iput>
  end_op();
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	c8a080e7          	jalr	-886(ra) # 8000428e <end_op>
  return 0;
    8000560c:	4781                	li	a5,0
    8000560e:	a085                	j	8000566e <sys_link+0x13c>
    end_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	c7e080e7          	jalr	-898(ra) # 8000428e <end_op>
    return -1;
    80005618:	57fd                	li	a5,-1
    8000561a:	a891                	j	8000566e <sys_link+0x13c>
    iunlockput(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	496080e7          	jalr	1174(ra) # 80003ab4 <iunlockput>
    end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	c68080e7          	jalr	-920(ra) # 8000428e <end_op>
    return -1;
    8000562e:	57fd                	li	a5,-1
    80005630:	a83d                	j	8000566e <sys_link+0x13c>
    iunlockput(dp);
    80005632:	854a                	mv	a0,s2
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	480080e7          	jalr	1152(ra) # 80003ab4 <iunlockput>
  ilock(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	214080e7          	jalr	532(ra) # 80003852 <ilock>
  ip->nlink--;
    80005646:	04a4d783          	lhu	a5,74(s1)
    8000564a:	37fd                	addiw	a5,a5,-1
    8000564c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	136080e7          	jalr	310(ra) # 80003788 <iupdate>
  iunlockput(ip);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	458080e7          	jalr	1112(ra) # 80003ab4 <iunlockput>
  end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	c2a080e7          	jalr	-982(ra) # 8000428e <end_op>
  return -1;
    8000566c:	57fd                	li	a5,-1
}
    8000566e:	853e                	mv	a0,a5
    80005670:	70b2                	ld	ra,296(sp)
    80005672:	7412                	ld	s0,288(sp)
    80005674:	64f2                	ld	s1,280(sp)
    80005676:	6952                	ld	s2,272(sp)
    80005678:	6155                	addi	sp,sp,304
    8000567a:	8082                	ret

000000008000567c <sys_unlink>:
{
    8000567c:	7151                	addi	sp,sp,-240
    8000567e:	f586                	sd	ra,232(sp)
    80005680:	f1a2                	sd	s0,224(sp)
    80005682:	eda6                	sd	s1,216(sp)
    80005684:	e9ca                	sd	s2,208(sp)
    80005686:	e5ce                	sd	s3,200(sp)
    80005688:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000568a:	08000613          	li	a2,128
    8000568e:	f3040593          	addi	a1,s0,-208
    80005692:	4501                	li	a0,0
    80005694:	ffffd097          	auipc	ra,0xffffd
    80005698:	668080e7          	jalr	1640(ra) # 80002cfc <argstr>
    8000569c:	18054163          	bltz	a0,8000581e <sys_unlink+0x1a2>
  begin_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	b6e080e7          	jalr	-1170(ra) # 8000420e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a8:	fb040593          	addi	a1,s0,-80
    800056ac:	f3040513          	addi	a0,s0,-208
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	970080e7          	jalr	-1680(ra) # 80004020 <nameiparent>
    800056b8:	84aa                	mv	s1,a0
    800056ba:	c979                	beqz	a0,80005790 <sys_unlink+0x114>
  ilock(dp);
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	196080e7          	jalr	406(ra) # 80003852 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056c4:	00003597          	auipc	a1,0x3
    800056c8:	02458593          	addi	a1,a1,36 # 800086e8 <syscalls+0x2c0>
    800056cc:	fb040513          	addi	a0,s0,-80
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	646080e7          	jalr	1606(ra) # 80003d16 <namecmp>
    800056d8:	14050a63          	beqz	a0,8000582c <sys_unlink+0x1b0>
    800056dc:	00003597          	auipc	a1,0x3
    800056e0:	a7458593          	addi	a1,a1,-1420 # 80008150 <digits+0x120>
    800056e4:	fb040513          	addi	a0,s0,-80
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	62e080e7          	jalr	1582(ra) # 80003d16 <namecmp>
    800056f0:	12050e63          	beqz	a0,8000582c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056f4:	f2c40613          	addi	a2,s0,-212
    800056f8:	fb040593          	addi	a1,s0,-80
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	632080e7          	jalr	1586(ra) # 80003d30 <dirlookup>
    80005706:	892a                	mv	s2,a0
    80005708:	12050263          	beqz	a0,8000582c <sys_unlink+0x1b0>
  ilock(ip);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	146080e7          	jalr	326(ra) # 80003852 <ilock>
  if(ip->nlink < 1)
    80005714:	04a91783          	lh	a5,74(s2)
    80005718:	08f05263          	blez	a5,8000579c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000571c:	04491703          	lh	a4,68(s2)
    80005720:	4785                	li	a5,1
    80005722:	08f70563          	beq	a4,a5,800057ac <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005726:	4641                	li	a2,16
    80005728:	4581                	li	a1,0
    8000572a:	fc040513          	addi	a0,s0,-64
    8000572e:	ffffb097          	auipc	ra,0xffffb
    80005732:	5cc080e7          	jalr	1484(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005736:	4741                	li	a4,16
    80005738:	f2c42683          	lw	a3,-212(s0)
    8000573c:	fc040613          	addi	a2,s0,-64
    80005740:	4581                	li	a1,0
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	4b8080e7          	jalr	1208(ra) # 80003bfc <writei>
    8000574c:	47c1                	li	a5,16
    8000574e:	0af51563          	bne	a0,a5,800057f8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005752:	04491703          	lh	a4,68(s2)
    80005756:	4785                	li	a5,1
    80005758:	0af70863          	beq	a4,a5,80005808 <sys_unlink+0x18c>
  iunlockput(dp);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	356080e7          	jalr	854(ra) # 80003ab4 <iunlockput>
  ip->nlink--;
    80005766:	04a95783          	lhu	a5,74(s2)
    8000576a:	37fd                	addiw	a5,a5,-1
    8000576c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005770:	854a                	mv	a0,s2
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	016080e7          	jalr	22(ra) # 80003788 <iupdate>
  iunlockput(ip);
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	338080e7          	jalr	824(ra) # 80003ab4 <iunlockput>
  end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	b0a080e7          	jalr	-1270(ra) # 8000428e <end_op>
  return 0;
    8000578c:	4501                	li	a0,0
    8000578e:	a84d                	j	80005840 <sys_unlink+0x1c4>
    end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	afe080e7          	jalr	-1282(ra) # 8000428e <end_op>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	a05d                	j	80005840 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000579c:	00003517          	auipc	a0,0x3
    800057a0:	f7450513          	addi	a0,a0,-140 # 80008710 <syscalls+0x2e8>
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	d9e080e7          	jalr	-610(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ac:	04c92703          	lw	a4,76(s2)
    800057b0:	02000793          	li	a5,32
    800057b4:	f6e7f9e3          	bgeu	a5,a4,80005726 <sys_unlink+0xaa>
    800057b8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057bc:	4741                	li	a4,16
    800057be:	86ce                	mv	a3,s3
    800057c0:	f1840613          	addi	a2,s0,-232
    800057c4:	4581                	li	a1,0
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	33e080e7          	jalr	830(ra) # 80003b06 <readi>
    800057d0:	47c1                	li	a5,16
    800057d2:	00f51b63          	bne	a0,a5,800057e8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057d6:	f1845783          	lhu	a5,-232(s0)
    800057da:	e7a1                	bnez	a5,80005822 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057dc:	29c1                	addiw	s3,s3,16
    800057de:	04c92783          	lw	a5,76(s2)
    800057e2:	fcf9ede3          	bltu	s3,a5,800057bc <sys_unlink+0x140>
    800057e6:	b781                	j	80005726 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e8:	00003517          	auipc	a0,0x3
    800057ec:	f4050513          	addi	a0,a0,-192 # 80008728 <syscalls+0x300>
    800057f0:	ffffb097          	auipc	ra,0xffffb
    800057f4:	d52080e7          	jalr	-686(ra) # 80000542 <panic>
    panic("unlink: writei");
    800057f8:	00003517          	auipc	a0,0x3
    800057fc:	f4850513          	addi	a0,a0,-184 # 80008740 <syscalls+0x318>
    80005800:	ffffb097          	auipc	ra,0xffffb
    80005804:	d42080e7          	jalr	-702(ra) # 80000542 <panic>
    dp->nlink--;
    80005808:	04a4d783          	lhu	a5,74(s1)
    8000580c:	37fd                	addiw	a5,a5,-1
    8000580e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	f74080e7          	jalr	-140(ra) # 80003788 <iupdate>
    8000581c:	b781                	j	8000575c <sys_unlink+0xe0>
    return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	a005                	j	80005840 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	290080e7          	jalr	656(ra) # 80003ab4 <iunlockput>
  iunlockput(dp);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	286080e7          	jalr	646(ra) # 80003ab4 <iunlockput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	a58080e7          	jalr	-1448(ra) # 8000428e <end_op>
  return -1;
    8000583e:	557d                	li	a0,-1
}
    80005840:	70ae                	ld	ra,232(sp)
    80005842:	740e                	ld	s0,224(sp)
    80005844:	64ee                	ld	s1,216(sp)
    80005846:	694e                	ld	s2,208(sp)
    80005848:	69ae                	ld	s3,200(sp)
    8000584a:	616d                	addi	sp,sp,240
    8000584c:	8082                	ret

000000008000584e <sys_open>:

uint64
sys_open(void)
{
    8000584e:	7131                	addi	sp,sp,-192
    80005850:	fd06                	sd	ra,184(sp)
    80005852:	f922                	sd	s0,176(sp)
    80005854:	f526                	sd	s1,168(sp)
    80005856:	f14a                	sd	s2,160(sp)
    80005858:	ed4e                	sd	s3,152(sp)
    8000585a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585c:	08000613          	li	a2,128
    80005860:	f5040593          	addi	a1,s0,-176
    80005864:	4501                	li	a0,0
    80005866:	ffffd097          	auipc	ra,0xffffd
    8000586a:	496080e7          	jalr	1174(ra) # 80002cfc <argstr>
    return -1;
    8000586e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005870:	0c054163          	bltz	a0,80005932 <sys_open+0xe4>
    80005874:	f4c40593          	addi	a1,s0,-180
    80005878:	4505                	li	a0,1
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	43e080e7          	jalr	1086(ra) # 80002cb8 <argint>
    80005882:	0a054863          	bltz	a0,80005932 <sys_open+0xe4>

  begin_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	988080e7          	jalr	-1656(ra) # 8000420e <begin_op>

  if(omode & O_CREATE){
    8000588e:	f4c42783          	lw	a5,-180(s0)
    80005892:	2007f793          	andi	a5,a5,512
    80005896:	cbdd                	beqz	a5,8000594c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005898:	4681                	li	a3,0
    8000589a:	4601                	li	a2,0
    8000589c:	4589                	li	a1,2
    8000589e:	f5040513          	addi	a0,s0,-176
    800058a2:	00000097          	auipc	ra,0x0
    800058a6:	974080e7          	jalr	-1676(ra) # 80005216 <create>
    800058aa:	892a                	mv	s2,a0
    if(ip == 0){
    800058ac:	c959                	beqz	a0,80005942 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058ae:	04491703          	lh	a4,68(s2)
    800058b2:	478d                	li	a5,3
    800058b4:	00f71763          	bne	a4,a5,800058c2 <sys_open+0x74>
    800058b8:	04695703          	lhu	a4,70(s2)
    800058bc:	47a5                	li	a5,9
    800058be:	0ce7ec63          	bltu	a5,a4,80005996 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	d62080e7          	jalr	-670(ra) # 80004624 <filealloc>
    800058ca:	89aa                	mv	s3,a0
    800058cc:	10050263          	beqz	a0,800059d0 <sys_open+0x182>
    800058d0:	00000097          	auipc	ra,0x0
    800058d4:	904080e7          	jalr	-1788(ra) # 800051d4 <fdalloc>
    800058d8:	84aa                	mv	s1,a0
    800058da:	0e054663          	bltz	a0,800059c6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058de:	04491703          	lh	a4,68(s2)
    800058e2:	478d                	li	a5,3
    800058e4:	0cf70463          	beq	a4,a5,800059ac <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e8:	4789                	li	a5,2
    800058ea:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058ee:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058f2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058f6:	f4c42783          	lw	a5,-180(s0)
    800058fa:	0017c713          	xori	a4,a5,1
    800058fe:	8b05                	andi	a4,a4,1
    80005900:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005904:	0037f713          	andi	a4,a5,3
    80005908:	00e03733          	snez	a4,a4
    8000590c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005910:	4007f793          	andi	a5,a5,1024
    80005914:	c791                	beqz	a5,80005920 <sys_open+0xd2>
    80005916:	04491703          	lh	a4,68(s2)
    8000591a:	4789                	li	a5,2
    8000591c:	08f70f63          	beq	a4,a5,800059ba <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005920:	854a                	mv	a0,s2
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	ff2080e7          	jalr	-14(ra) # 80003914 <iunlock>
  end_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	964080e7          	jalr	-1692(ra) # 8000428e <end_op>

  return fd;
}
    80005932:	8526                	mv	a0,s1
    80005934:	70ea                	ld	ra,184(sp)
    80005936:	744a                	ld	s0,176(sp)
    80005938:	74aa                	ld	s1,168(sp)
    8000593a:	790a                	ld	s2,160(sp)
    8000593c:	69ea                	ld	s3,152(sp)
    8000593e:	6129                	addi	sp,sp,192
    80005940:	8082                	ret
      end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	94c080e7          	jalr	-1716(ra) # 8000428e <end_op>
      return -1;
    8000594a:	b7e5                	j	80005932 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000594c:	f5040513          	addi	a0,s0,-176
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	6b2080e7          	jalr	1714(ra) # 80004002 <namei>
    80005958:	892a                	mv	s2,a0
    8000595a:	c905                	beqz	a0,8000598a <sys_open+0x13c>
    ilock(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	ef6080e7          	jalr	-266(ra) # 80003852 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	4785                	li	a5,1
    8000596a:	f4f712e3          	bne	a4,a5,800058ae <sys_open+0x60>
    8000596e:	f4c42783          	lw	a5,-180(s0)
    80005972:	dba1                	beqz	a5,800058c2 <sys_open+0x74>
      iunlockput(ip);
    80005974:	854a                	mv	a0,s2
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	13e080e7          	jalr	318(ra) # 80003ab4 <iunlockput>
      end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	910080e7          	jalr	-1776(ra) # 8000428e <end_op>
      return -1;
    80005986:	54fd                	li	s1,-1
    80005988:	b76d                	j	80005932 <sys_open+0xe4>
      end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	904080e7          	jalr	-1788(ra) # 8000428e <end_op>
      return -1;
    80005992:	54fd                	li	s1,-1
    80005994:	bf79                	j	80005932 <sys_open+0xe4>
    iunlockput(ip);
    80005996:	854a                	mv	a0,s2
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	11c080e7          	jalr	284(ra) # 80003ab4 <iunlockput>
    end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8ee080e7          	jalr	-1810(ra) # 8000428e <end_op>
    return -1;
    800059a8:	54fd                	li	s1,-1
    800059aa:	b761                	j	80005932 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059ac:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059b0:	04691783          	lh	a5,70(s2)
    800059b4:	02f99223          	sh	a5,36(s3)
    800059b8:	bf2d                	j	800058f2 <sys_open+0xa4>
    itrunc(ip);
    800059ba:	854a                	mv	a0,s2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	fa4080e7          	jalr	-92(ra) # 80003960 <itrunc>
    800059c4:	bfb1                	j	80005920 <sys_open+0xd2>
      fileclose(f);
    800059c6:	854e                	mv	a0,s3
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	d18080e7          	jalr	-744(ra) # 800046e0 <fileclose>
    iunlockput(ip);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	0e2080e7          	jalr	226(ra) # 80003ab4 <iunlockput>
    end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	8b4080e7          	jalr	-1868(ra) # 8000428e <end_op>
    return -1;
    800059e2:	54fd                	li	s1,-1
    800059e4:	b7b9                	j	80005932 <sys_open+0xe4>

00000000800059e6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059e6:	7175                	addi	sp,sp,-144
    800059e8:	e506                	sd	ra,136(sp)
    800059ea:	e122                	sd	s0,128(sp)
    800059ec:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	820080e7          	jalr	-2016(ra) # 8000420e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059f6:	08000613          	li	a2,128
    800059fa:	f7040593          	addi	a1,s0,-144
    800059fe:	4501                	li	a0,0
    80005a00:	ffffd097          	auipc	ra,0xffffd
    80005a04:	2fc080e7          	jalr	764(ra) # 80002cfc <argstr>
    80005a08:	02054963          	bltz	a0,80005a3a <sys_mkdir+0x54>
    80005a0c:	4681                	li	a3,0
    80005a0e:	4601                	li	a2,0
    80005a10:	4585                	li	a1,1
    80005a12:	f7040513          	addi	a0,s0,-144
    80005a16:	00000097          	auipc	ra,0x0
    80005a1a:	800080e7          	jalr	-2048(ra) # 80005216 <create>
    80005a1e:	cd11                	beqz	a0,80005a3a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	094080e7          	jalr	148(ra) # 80003ab4 <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	866080e7          	jalr	-1946(ra) # 8000428e <end_op>
  return 0;
    80005a30:	4501                	li	a0,0
}
    80005a32:	60aa                	ld	ra,136(sp)
    80005a34:	640a                	ld	s0,128(sp)
    80005a36:	6149                	addi	sp,sp,144
    80005a38:	8082                	ret
    end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	854080e7          	jalr	-1964(ra) # 8000428e <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	b7fd                	j	80005a32 <sys_mkdir+0x4c>

0000000080005a46 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a46:	7135                	addi	sp,sp,-160
    80005a48:	ed06                	sd	ra,152(sp)
    80005a4a:	e922                	sd	s0,144(sp)
    80005a4c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	7c0080e7          	jalr	1984(ra) # 8000420e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a56:	08000613          	li	a2,128
    80005a5a:	f7040593          	addi	a1,s0,-144
    80005a5e:	4501                	li	a0,0
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	29c080e7          	jalr	668(ra) # 80002cfc <argstr>
    80005a68:	04054a63          	bltz	a0,80005abc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a6c:	f6c40593          	addi	a1,s0,-148
    80005a70:	4505                	li	a0,1
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	246080e7          	jalr	582(ra) # 80002cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7a:	04054163          	bltz	a0,80005abc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a7e:	f6840593          	addi	a1,s0,-152
    80005a82:	4509                	li	a0,2
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	234080e7          	jalr	564(ra) # 80002cb8 <argint>
     argint(1, &major) < 0 ||
    80005a8c:	02054863          	bltz	a0,80005abc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a90:	f6841683          	lh	a3,-152(s0)
    80005a94:	f6c41603          	lh	a2,-148(s0)
    80005a98:	458d                	li	a1,3
    80005a9a:	f7040513          	addi	a0,s0,-144
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	778080e7          	jalr	1912(ra) # 80005216 <create>
     argint(2, &minor) < 0 ||
    80005aa6:	c919                	beqz	a0,80005abc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	00c080e7          	jalr	12(ra) # 80003ab4 <iunlockput>
  end_op();
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	7de080e7          	jalr	2014(ra) # 8000428e <end_op>
  return 0;
    80005ab8:	4501                	li	a0,0
    80005aba:	a031                	j	80005ac6 <sys_mknod+0x80>
    end_op();
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	7d2080e7          	jalr	2002(ra) # 8000428e <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
}
    80005ac6:	60ea                	ld	ra,152(sp)
    80005ac8:	644a                	ld	s0,144(sp)
    80005aca:	610d                	addi	sp,sp,160
    80005acc:	8082                	ret

0000000080005ace <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ace:	7135                	addi	sp,sp,-160
    80005ad0:	ed06                	sd	ra,152(sp)
    80005ad2:	e922                	sd	s0,144(sp)
    80005ad4:	e526                	sd	s1,136(sp)
    80005ad6:	e14a                	sd	s2,128(sp)
    80005ad8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	f5a080e7          	jalr	-166(ra) # 80001a34 <myproc>
    80005ae2:	892a                	mv	s2,a0
  
  begin_op();
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	72a080e7          	jalr	1834(ra) # 8000420e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aec:	08000613          	li	a2,128
    80005af0:	f6040593          	addi	a1,s0,-160
    80005af4:	4501                	li	a0,0
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	206080e7          	jalr	518(ra) # 80002cfc <argstr>
    80005afe:	04054b63          	bltz	a0,80005b54 <sys_chdir+0x86>
    80005b02:	f6040513          	addi	a0,s0,-160
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	4fc080e7          	jalr	1276(ra) # 80004002 <namei>
    80005b0e:	84aa                	mv	s1,a0
    80005b10:	c131                	beqz	a0,80005b54 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	d40080e7          	jalr	-704(ra) # 80003852 <ilock>
  if(ip->type != T_DIR){
    80005b1a:	04449703          	lh	a4,68(s1)
    80005b1e:	4785                	li	a5,1
    80005b20:	04f71063          	bne	a4,a5,80005b60 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	dee080e7          	jalr	-530(ra) # 80003914 <iunlock>
  iput(p->cwd);
    80005b2e:	15893503          	ld	a0,344(s2)
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	eda080e7          	jalr	-294(ra) # 80003a0c <iput>
  end_op();
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	754080e7          	jalr	1876(ra) # 8000428e <end_op>
  p->cwd = ip;
    80005b42:	14993c23          	sd	s1,344(s2)
  return 0;
    80005b46:	4501                	li	a0,0
}
    80005b48:	60ea                	ld	ra,152(sp)
    80005b4a:	644a                	ld	s0,144(sp)
    80005b4c:	64aa                	ld	s1,136(sp)
    80005b4e:	690a                	ld	s2,128(sp)
    80005b50:	610d                	addi	sp,sp,160
    80005b52:	8082                	ret
    end_op();
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	73a080e7          	jalr	1850(ra) # 8000428e <end_op>
    return -1;
    80005b5c:	557d                	li	a0,-1
    80005b5e:	b7ed                	j	80005b48 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b60:	8526                	mv	a0,s1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	f52080e7          	jalr	-174(ra) # 80003ab4 <iunlockput>
    end_op();
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	724080e7          	jalr	1828(ra) # 8000428e <end_op>
    return -1;
    80005b72:	557d                	li	a0,-1
    80005b74:	bfd1                	j	80005b48 <sys_chdir+0x7a>

0000000080005b76 <sys_exec>:

uint64
sys_exec(void)
{
    80005b76:	7145                	addi	sp,sp,-464
    80005b78:	e786                	sd	ra,456(sp)
    80005b7a:	e3a2                	sd	s0,448(sp)
    80005b7c:	ff26                	sd	s1,440(sp)
    80005b7e:	fb4a                	sd	s2,432(sp)
    80005b80:	f74e                	sd	s3,424(sp)
    80005b82:	f352                	sd	s4,416(sp)
    80005b84:	ef56                	sd	s5,408(sp)
    80005b86:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b88:	08000613          	li	a2,128
    80005b8c:	f4040593          	addi	a1,s0,-192
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	16a080e7          	jalr	362(ra) # 80002cfc <argstr>
    return -1;
    80005b9a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b9c:	0c054a63          	bltz	a0,80005c70 <sys_exec+0xfa>
    80005ba0:	e3840593          	addi	a1,s0,-456
    80005ba4:	4505                	li	a0,1
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	134080e7          	jalr	308(ra) # 80002cda <argaddr>
    80005bae:	0c054163          	bltz	a0,80005c70 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bb2:	10000613          	li	a2,256
    80005bb6:	4581                	li	a1,0
    80005bb8:	e4040513          	addi	a0,s0,-448
    80005bbc:	ffffb097          	auipc	ra,0xffffb
    80005bc0:	13e080e7          	jalr	318(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc8:	89a6                	mv	s3,s1
    80005bca:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bcc:	02000a13          	li	s4,32
    80005bd0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd4:	00391793          	slli	a5,s2,0x3
    80005bd8:	e3040593          	addi	a1,s0,-464
    80005bdc:	e3843503          	ld	a0,-456(s0)
    80005be0:	953e                	add	a0,a0,a5
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	03c080e7          	jalr	60(ra) # 80002c1e <fetchaddr>
    80005bea:	02054a63          	bltz	a0,80005c1e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bee:	e3043783          	ld	a5,-464(s0)
    80005bf2:	c3b9                	beqz	a5,80005c38 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf4:	ffffb097          	auipc	ra,0xffffb
    80005bf8:	f1a080e7          	jalr	-230(ra) # 80000b0e <kalloc>
    80005bfc:	85aa                	mv	a1,a0
    80005bfe:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c02:	cd11                	beqz	a0,80005c1e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c04:	6605                	lui	a2,0x1
    80005c06:	e3043503          	ld	a0,-464(s0)
    80005c0a:	ffffd097          	auipc	ra,0xffffd
    80005c0e:	066080e7          	jalr	102(ra) # 80002c70 <fetchstr>
    80005c12:	00054663          	bltz	a0,80005c1e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c16:	0905                	addi	s2,s2,1
    80005c18:	09a1                	addi	s3,s3,8
    80005c1a:	fb491be3          	bne	s2,s4,80005bd0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1e:	10048913          	addi	s2,s1,256
    80005c22:	6088                	ld	a0,0(s1)
    80005c24:	c529                	beqz	a0,80005c6e <sys_exec+0xf8>
    kfree(argv[i]);
    80005c26:	ffffb097          	auipc	ra,0xffffb
    80005c2a:	dec080e7          	jalr	-532(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2e:	04a1                	addi	s1,s1,8
    80005c30:	ff2499e3          	bne	s1,s2,80005c22 <sys_exec+0xac>
  return -1;
    80005c34:	597d                	li	s2,-1
    80005c36:	a82d                	j	80005c70 <sys_exec+0xfa>
      argv[i] = 0;
    80005c38:	0a8e                	slli	s5,s5,0x3
    80005c3a:	fc040793          	addi	a5,s0,-64
    80005c3e:	9abe                	add	s5,s5,a5
    80005c40:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c44:	e4040593          	addi	a1,s0,-448
    80005c48:	f4040513          	addi	a0,s0,-192
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	11a080e7          	jalr	282(ra) # 80004d66 <exec>
    80005c54:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c56:	10048993          	addi	s3,s1,256
    80005c5a:	6088                	ld	a0,0(s1)
    80005c5c:	c911                	beqz	a0,80005c70 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c5e:	ffffb097          	auipc	ra,0xffffb
    80005c62:	db4080e7          	jalr	-588(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c66:	04a1                	addi	s1,s1,8
    80005c68:	ff3499e3          	bne	s1,s3,80005c5a <sys_exec+0xe4>
    80005c6c:	a011                	j	80005c70 <sys_exec+0xfa>
  return -1;
    80005c6e:	597d                	li	s2,-1
}
    80005c70:	854a                	mv	a0,s2
    80005c72:	60be                	ld	ra,456(sp)
    80005c74:	641e                	ld	s0,448(sp)
    80005c76:	74fa                	ld	s1,440(sp)
    80005c78:	795a                	ld	s2,432(sp)
    80005c7a:	79ba                	ld	s3,424(sp)
    80005c7c:	7a1a                	ld	s4,416(sp)
    80005c7e:	6afa                	ld	s5,408(sp)
    80005c80:	6179                	addi	sp,sp,464
    80005c82:	8082                	ret

0000000080005c84 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c84:	7139                	addi	sp,sp,-64
    80005c86:	fc06                	sd	ra,56(sp)
    80005c88:	f822                	sd	s0,48(sp)
    80005c8a:	f426                	sd	s1,40(sp)
    80005c8c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c8e:	ffffc097          	auipc	ra,0xffffc
    80005c92:	da6080e7          	jalr	-602(ra) # 80001a34 <myproc>
    80005c96:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c98:	fd840593          	addi	a1,s0,-40
    80005c9c:	4501                	li	a0,0
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	03c080e7          	jalr	60(ra) # 80002cda <argaddr>
    return -1;
    80005ca6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ca8:	0e054063          	bltz	a0,80005d88 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cac:	fc840593          	addi	a1,s0,-56
    80005cb0:	fd040513          	addi	a0,s0,-48
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	d82080e7          	jalr	-638(ra) # 80004a36 <pipealloc>
    return -1;
    80005cbc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cbe:	0c054563          	bltz	a0,80005d88 <sys_pipe+0x104>
  fd0 = -1;
    80005cc2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc6:	fd043503          	ld	a0,-48(s0)
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	50a080e7          	jalr	1290(ra) # 800051d4 <fdalloc>
    80005cd2:	fca42223          	sw	a0,-60(s0)
    80005cd6:	08054c63          	bltz	a0,80005d6e <sys_pipe+0xea>
    80005cda:	fc843503          	ld	a0,-56(s0)
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	4f6080e7          	jalr	1270(ra) # 800051d4 <fdalloc>
    80005ce6:	fca42023          	sw	a0,-64(s0)
    80005cea:	06054863          	bltz	a0,80005d5a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cee:	4691                	li	a3,4
    80005cf0:	fc440613          	addi	a2,s0,-60
    80005cf4:	fd843583          	ld	a1,-40(s0)
    80005cf8:	68a8                	ld	a0,80(s1)
    80005cfa:	ffffc097          	auipc	ra,0xffffc
    80005cfe:	9cc080e7          	jalr	-1588(ra) # 800016c6 <copyout>
    80005d02:	02054063          	bltz	a0,80005d22 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d06:	4691                	li	a3,4
    80005d08:	fc040613          	addi	a2,s0,-64
    80005d0c:	fd843583          	ld	a1,-40(s0)
    80005d10:	0591                	addi	a1,a1,4
    80005d12:	68a8                	ld	a0,80(s1)
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	9b2080e7          	jalr	-1614(ra) # 800016c6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d1c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1e:	06055563          	bgez	a0,80005d88 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d22:	fc442783          	lw	a5,-60(s0)
    80005d26:	07e9                	addi	a5,a5,26
    80005d28:	078e                	slli	a5,a5,0x3
    80005d2a:	97a6                	add	a5,a5,s1
    80005d2c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d30:	fc042503          	lw	a0,-64(s0)
    80005d34:	0569                	addi	a0,a0,26
    80005d36:	050e                	slli	a0,a0,0x3
    80005d38:	9526                	add	a0,a0,s1
    80005d3a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d3e:	fd043503          	ld	a0,-48(s0)
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	99e080e7          	jalr	-1634(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005d4a:	fc843503          	ld	a0,-56(s0)
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	992080e7          	jalr	-1646(ra) # 800046e0 <fileclose>
    return -1;
    80005d56:	57fd                	li	a5,-1
    80005d58:	a805                	j	80005d88 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d5a:	fc442783          	lw	a5,-60(s0)
    80005d5e:	0007c863          	bltz	a5,80005d6e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d62:	01a78513          	addi	a0,a5,26
    80005d66:	050e                	slli	a0,a0,0x3
    80005d68:	9526                	add	a0,a0,s1
    80005d6a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d6e:	fd043503          	ld	a0,-48(s0)
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	96e080e7          	jalr	-1682(ra) # 800046e0 <fileclose>
    fileclose(wf);
    80005d7a:	fc843503          	ld	a0,-56(s0)
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	962080e7          	jalr	-1694(ra) # 800046e0 <fileclose>
    return -1;
    80005d86:	57fd                	li	a5,-1
}
    80005d88:	853e                	mv	a0,a5
    80005d8a:	70e2                	ld	ra,56(sp)
    80005d8c:	7442                	ld	s0,48(sp)
    80005d8e:	74a2                	ld	s1,40(sp)
    80005d90:	6121                	addi	sp,sp,64
    80005d92:	8082                	ret
	...

0000000080005da0 <kernelvec>:
    80005da0:	7111                	addi	sp,sp,-256
    80005da2:	e006                	sd	ra,0(sp)
    80005da4:	e40a                	sd	sp,8(sp)
    80005da6:	e80e                	sd	gp,16(sp)
    80005da8:	ec12                	sd	tp,24(sp)
    80005daa:	f016                	sd	t0,32(sp)
    80005dac:	f41a                	sd	t1,40(sp)
    80005dae:	f81e                	sd	t2,48(sp)
    80005db0:	fc22                	sd	s0,56(sp)
    80005db2:	e0a6                	sd	s1,64(sp)
    80005db4:	e4aa                	sd	a0,72(sp)
    80005db6:	e8ae                	sd	a1,80(sp)
    80005db8:	ecb2                	sd	a2,88(sp)
    80005dba:	f0b6                	sd	a3,96(sp)
    80005dbc:	f4ba                	sd	a4,104(sp)
    80005dbe:	f8be                	sd	a5,112(sp)
    80005dc0:	fcc2                	sd	a6,120(sp)
    80005dc2:	e146                	sd	a7,128(sp)
    80005dc4:	e54a                	sd	s2,136(sp)
    80005dc6:	e94e                	sd	s3,144(sp)
    80005dc8:	ed52                	sd	s4,152(sp)
    80005dca:	f156                	sd	s5,160(sp)
    80005dcc:	f55a                	sd	s6,168(sp)
    80005dce:	f95e                	sd	s7,176(sp)
    80005dd0:	fd62                	sd	s8,184(sp)
    80005dd2:	e1e6                	sd	s9,192(sp)
    80005dd4:	e5ea                	sd	s10,200(sp)
    80005dd6:	e9ee                	sd	s11,208(sp)
    80005dd8:	edf2                	sd	t3,216(sp)
    80005dda:	f1f6                	sd	t4,224(sp)
    80005ddc:	f5fa                	sd	t5,232(sp)
    80005dde:	f9fe                	sd	t6,240(sp)
    80005de0:	d0bfc0ef          	jal	ra,80002aea <kerneltrap>
    80005de4:	6082                	ld	ra,0(sp)
    80005de6:	6122                	ld	sp,8(sp)
    80005de8:	61c2                	ld	gp,16(sp)
    80005dea:	7282                	ld	t0,32(sp)
    80005dec:	7322                	ld	t1,40(sp)
    80005dee:	73c2                	ld	t2,48(sp)
    80005df0:	7462                	ld	s0,56(sp)
    80005df2:	6486                	ld	s1,64(sp)
    80005df4:	6526                	ld	a0,72(sp)
    80005df6:	65c6                	ld	a1,80(sp)
    80005df8:	6666                	ld	a2,88(sp)
    80005dfa:	7686                	ld	a3,96(sp)
    80005dfc:	7726                	ld	a4,104(sp)
    80005dfe:	77c6                	ld	a5,112(sp)
    80005e00:	7866                	ld	a6,120(sp)
    80005e02:	688a                	ld	a7,128(sp)
    80005e04:	692a                	ld	s2,136(sp)
    80005e06:	69ca                	ld	s3,144(sp)
    80005e08:	6a6a                	ld	s4,152(sp)
    80005e0a:	7a8a                	ld	s5,160(sp)
    80005e0c:	7b2a                	ld	s6,168(sp)
    80005e0e:	7bca                	ld	s7,176(sp)
    80005e10:	7c6a                	ld	s8,184(sp)
    80005e12:	6c8e                	ld	s9,192(sp)
    80005e14:	6d2e                	ld	s10,200(sp)
    80005e16:	6dce                	ld	s11,208(sp)
    80005e18:	6e6e                	ld	t3,216(sp)
    80005e1a:	7e8e                	ld	t4,224(sp)
    80005e1c:	7f2e                	ld	t5,232(sp)
    80005e1e:	7fce                	ld	t6,240(sp)
    80005e20:	6111                	addi	sp,sp,256
    80005e22:	10200073          	sret
    80005e26:	00000013          	nop
    80005e2a:	00000013          	nop
    80005e2e:	0001                	nop

0000000080005e30 <timervec>:
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	e10c                	sd	a1,0(a0)
    80005e36:	e510                	sd	a2,8(a0)
    80005e38:	e914                	sd	a3,16(a0)
    80005e3a:	710c                	ld	a1,32(a0)
    80005e3c:	7510                	ld	a2,40(a0)
    80005e3e:	6194                	ld	a3,0(a1)
    80005e40:	96b2                	add	a3,a3,a2
    80005e42:	e194                	sd	a3,0(a1)
    80005e44:	4589                	li	a1,2
    80005e46:	14459073          	csrw	sip,a1
    80005e4a:	6914                	ld	a3,16(a0)
    80005e4c:	6510                	ld	a2,8(a0)
    80005e4e:	610c                	ld	a1,0(a0)
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	30200073          	mret
	...

0000000080005e5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e5a:	1141                	addi	sp,sp,-16
    80005e5c:	e422                	sd	s0,8(sp)
    80005e5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e60:	0c0007b7          	lui	a5,0xc000
    80005e64:	4705                	li	a4,1
    80005e66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e68:	c3d8                	sw	a4,4(a5)
}
    80005e6a:	6422                	ld	s0,8(sp)
    80005e6c:	0141                	addi	sp,sp,16
    80005e6e:	8082                	ret

0000000080005e70 <plicinithart>:

void
plicinithart(void)
{
    80005e70:	1141                	addi	sp,sp,-16
    80005e72:	e406                	sd	ra,8(sp)
    80005e74:	e022                	sd	s0,0(sp)
    80005e76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	b90080e7          	jalr	-1136(ra) # 80001a08 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e80:	0085171b          	slliw	a4,a0,0x8
    80005e84:	0c0027b7          	lui	a5,0xc002
    80005e88:	97ba                	add	a5,a5,a4
    80005e8a:	40200713          	li	a4,1026
    80005e8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e92:	00d5151b          	slliw	a0,a0,0xd
    80005e96:	0c2017b7          	lui	a5,0xc201
    80005e9a:	953e                	add	a0,a0,a5
    80005e9c:	00052023          	sw	zero,0(a0)
}
    80005ea0:	60a2                	ld	ra,8(sp)
    80005ea2:	6402                	ld	s0,0(sp)
    80005ea4:	0141                	addi	sp,sp,16
    80005ea6:	8082                	ret

0000000080005ea8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ea8:	1141                	addi	sp,sp,-16
    80005eaa:	e406                	sd	ra,8(sp)
    80005eac:	e022                	sd	s0,0(sp)
    80005eae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005eb0:	ffffc097          	auipc	ra,0xffffc
    80005eb4:	b58080e7          	jalr	-1192(ra) # 80001a08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005eb8:	00d5179b          	slliw	a5,a0,0xd
    80005ebc:	0c201537          	lui	a0,0xc201
    80005ec0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ec2:	4148                	lw	a0,4(a0)
    80005ec4:	60a2                	ld	ra,8(sp)
    80005ec6:	6402                	ld	s0,0(sp)
    80005ec8:	0141                	addi	sp,sp,16
    80005eca:	8082                	ret

0000000080005ecc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ecc:	1101                	addi	sp,sp,-32
    80005ece:	ec06                	sd	ra,24(sp)
    80005ed0:	e822                	sd	s0,16(sp)
    80005ed2:	e426                	sd	s1,8(sp)
    80005ed4:	1000                	addi	s0,sp,32
    80005ed6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	b30080e7          	jalr	-1232(ra) # 80001a08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ee0:	00d5151b          	slliw	a0,a0,0xd
    80005ee4:	0c2017b7          	lui	a5,0xc201
    80005ee8:	97aa                	add	a5,a5,a0
    80005eea:	c3c4                	sw	s1,4(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret

0000000080005ef6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ef6:	1141                	addi	sp,sp,-16
    80005ef8:	e406                	sd	ra,8(sp)
    80005efa:	e022                	sd	s0,0(sp)
    80005efc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005efe:	479d                	li	a5,7
    80005f00:	04a7cc63          	blt	a5,a0,80005f58 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f04:	0001d797          	auipc	a5,0x1d
    80005f08:	0fc78793          	addi	a5,a5,252 # 80023000 <disk>
    80005f0c:	00a78733          	add	a4,a5,a0
    80005f10:	6789                	lui	a5,0x2
    80005f12:	97ba                	add	a5,a5,a4
    80005f14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f18:	eba1                	bnez	a5,80005f68 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f1a:	00451713          	slli	a4,a0,0x4
    80005f1e:	0001f797          	auipc	a5,0x1f
    80005f22:	0e27b783          	ld	a5,226(a5) # 80025000 <disk+0x2000>
    80005f26:	97ba                	add	a5,a5,a4
    80005f28:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f2c:	0001d797          	auipc	a5,0x1d
    80005f30:	0d478793          	addi	a5,a5,212 # 80023000 <disk>
    80005f34:	97aa                	add	a5,a5,a0
    80005f36:	6509                	lui	a0,0x2
    80005f38:	953e                	add	a0,a0,a5
    80005f3a:	4785                	li	a5,1
    80005f3c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f40:	0001f517          	auipc	a0,0x1f
    80005f44:	0d850513          	addi	a0,a0,216 # 80025018 <disk+0x2018>
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	518080e7          	jalr	1304(ra) # 80002460 <wakeup>
}
    80005f50:	60a2                	ld	ra,8(sp)
    80005f52:	6402                	ld	s0,0(sp)
    80005f54:	0141                	addi	sp,sp,16
    80005f56:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f58:	00002517          	auipc	a0,0x2
    80005f5c:	7f850513          	addi	a0,a0,2040 # 80008750 <syscalls+0x328>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5e2080e7          	jalr	1506(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005f68:	00003517          	auipc	a0,0x3
    80005f6c:	80050513          	addi	a0,a0,-2048 # 80008768 <syscalls+0x340>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5d2080e7          	jalr	1490(ra) # 80000542 <panic>

0000000080005f78 <virtio_disk_init>:
{
    80005f78:	1101                	addi	sp,sp,-32
    80005f7a:	ec06                	sd	ra,24(sp)
    80005f7c:	e822                	sd	s0,16(sp)
    80005f7e:	e426                	sd	s1,8(sp)
    80005f80:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f82:	00002597          	auipc	a1,0x2
    80005f86:	7fe58593          	addi	a1,a1,2046 # 80008780 <syscalls+0x358>
    80005f8a:	0001f517          	auipc	a0,0x1f
    80005f8e:	11e50513          	addi	a0,a0,286 # 800250a8 <disk+0x20a8>
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	bdc080e7          	jalr	-1060(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f9a:	100017b7          	lui	a5,0x10001
    80005f9e:	4398                	lw	a4,0(a5)
    80005fa0:	2701                	sext.w	a4,a4
    80005fa2:	747277b7          	lui	a5,0x74727
    80005fa6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005faa:	0ef71163          	bne	a4,a5,8000608c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fae:	100017b7          	lui	a5,0x10001
    80005fb2:	43dc                	lw	a5,4(a5)
    80005fb4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb6:	4705                	li	a4,1
    80005fb8:	0ce79a63          	bne	a5,a4,8000608c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fbc:	100017b7          	lui	a5,0x10001
    80005fc0:	479c                	lw	a5,8(a5)
    80005fc2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fc4:	4709                	li	a4,2
    80005fc6:	0ce79363          	bne	a5,a4,8000608c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fca:	100017b7          	lui	a5,0x10001
    80005fce:	47d8                	lw	a4,12(a5)
    80005fd0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fd2:	554d47b7          	lui	a5,0x554d4
    80005fd6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fda:	0af71963          	bne	a4,a5,8000608c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fde:	100017b7          	lui	a5,0x10001
    80005fe2:	4705                	li	a4,1
    80005fe4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe6:	470d                	li	a4,3
    80005fe8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fea:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fec:	c7ffe737          	lui	a4,0xc7ffe
    80005ff0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005ff4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ff6:	2701                	sext.w	a4,a4
    80005ff8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffa:	472d                	li	a4,11
    80005ffc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffe:	473d                	li	a4,15
    80006000:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006002:	6705                	lui	a4,0x1
    80006004:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006006:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000600a:	5bdc                	lw	a5,52(a5)
    8000600c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000600e:	c7d9                	beqz	a5,8000609c <virtio_disk_init+0x124>
  if(max < NUM)
    80006010:	471d                	li	a4,7
    80006012:	08f77d63          	bgeu	a4,a5,800060ac <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006016:	100014b7          	lui	s1,0x10001
    8000601a:	47a1                	li	a5,8
    8000601c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000601e:	6609                	lui	a2,0x2
    80006020:	4581                	li	a1,0
    80006022:	0001d517          	auipc	a0,0x1d
    80006026:	fde50513          	addi	a0,a0,-34 # 80023000 <disk>
    8000602a:	ffffb097          	auipc	ra,0xffffb
    8000602e:	cd0080e7          	jalr	-816(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006032:	0001d717          	auipc	a4,0x1d
    80006036:	fce70713          	addi	a4,a4,-50 # 80023000 <disk>
    8000603a:	00c75793          	srli	a5,a4,0xc
    8000603e:	2781                	sext.w	a5,a5
    80006040:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006042:	0001f797          	auipc	a5,0x1f
    80006046:	fbe78793          	addi	a5,a5,-66 # 80025000 <disk+0x2000>
    8000604a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000604c:	0001d717          	auipc	a4,0x1d
    80006050:	03470713          	addi	a4,a4,52 # 80023080 <disk+0x80>
    80006054:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006056:	0001e717          	auipc	a4,0x1e
    8000605a:	faa70713          	addi	a4,a4,-86 # 80024000 <disk+0x1000>
    8000605e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006060:	4705                	li	a4,1
    80006062:	00e78c23          	sb	a4,24(a5)
    80006066:	00e78ca3          	sb	a4,25(a5)
    8000606a:	00e78d23          	sb	a4,26(a5)
    8000606e:	00e78da3          	sb	a4,27(a5)
    80006072:	00e78e23          	sb	a4,28(a5)
    80006076:	00e78ea3          	sb	a4,29(a5)
    8000607a:	00e78f23          	sb	a4,30(a5)
    8000607e:	00e78fa3          	sb	a4,31(a5)
}
    80006082:	60e2                	ld	ra,24(sp)
    80006084:	6442                	ld	s0,16(sp)
    80006086:	64a2                	ld	s1,8(sp)
    80006088:	6105                	addi	sp,sp,32
    8000608a:	8082                	ret
    panic("could not find virtio disk");
    8000608c:	00002517          	auipc	a0,0x2
    80006090:	70450513          	addi	a0,a0,1796 # 80008790 <syscalls+0x368>
    80006094:	ffffa097          	auipc	ra,0xffffa
    80006098:	4ae080e7          	jalr	1198(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    8000609c:	00002517          	auipc	a0,0x2
    800060a0:	71450513          	addi	a0,a0,1812 # 800087b0 <syscalls+0x388>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	49e080e7          	jalr	1182(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    800060ac:	00002517          	auipc	a0,0x2
    800060b0:	72450513          	addi	a0,a0,1828 # 800087d0 <syscalls+0x3a8>
    800060b4:	ffffa097          	auipc	ra,0xffffa
    800060b8:	48e080e7          	jalr	1166(ra) # 80000542 <panic>

00000000800060bc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060bc:	7175                	addi	sp,sp,-144
    800060be:	e506                	sd	ra,136(sp)
    800060c0:	e122                	sd	s0,128(sp)
    800060c2:	fca6                	sd	s1,120(sp)
    800060c4:	f8ca                	sd	s2,112(sp)
    800060c6:	f4ce                	sd	s3,104(sp)
    800060c8:	f0d2                	sd	s4,96(sp)
    800060ca:	ecd6                	sd	s5,88(sp)
    800060cc:	e8da                	sd	s6,80(sp)
    800060ce:	e4de                	sd	s7,72(sp)
    800060d0:	e0e2                	sd	s8,64(sp)
    800060d2:	fc66                	sd	s9,56(sp)
    800060d4:	f86a                	sd	s10,48(sp)
    800060d6:	f46e                	sd	s11,40(sp)
    800060d8:	0900                	addi	s0,sp,144
    800060da:	8aaa                	mv	s5,a0
    800060dc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060de:	00c52c83          	lw	s9,12(a0)
    800060e2:	001c9c9b          	slliw	s9,s9,0x1
    800060e6:	1c82                	slli	s9,s9,0x20
    800060e8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060ec:	0001f517          	auipc	a0,0x1f
    800060f0:	fbc50513          	addi	a0,a0,-68 # 800250a8 <disk+0x20a8>
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	b0a080e7          	jalr	-1270(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    800060fc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060fe:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006100:	0001dc17          	auipc	s8,0x1d
    80006104:	f00c0c13          	addi	s8,s8,-256 # 80023000 <disk>
    80006108:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000610a:	4b0d                	li	s6,3
    8000610c:	a0ad                	j	80006176 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000610e:	00fc0733          	add	a4,s8,a5
    80006112:	975e                	add	a4,a4,s7
    80006114:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006118:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000611a:	0207c563          	bltz	a5,80006144 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000611e:	2905                	addiw	s2,s2,1
    80006120:	0611                	addi	a2,a2,4
    80006122:	19690d63          	beq	s2,s6,800062bc <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006126:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006128:	0001f717          	auipc	a4,0x1f
    8000612c:	ef070713          	addi	a4,a4,-272 # 80025018 <disk+0x2018>
    80006130:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006132:	00074683          	lbu	a3,0(a4)
    80006136:	fee1                	bnez	a3,8000610e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006138:	2785                	addiw	a5,a5,1
    8000613a:	0705                	addi	a4,a4,1
    8000613c:	fe979be3          	bne	a5,s1,80006132 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006140:	57fd                	li	a5,-1
    80006142:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006144:	01205d63          	blez	s2,8000615e <virtio_disk_rw+0xa2>
    80006148:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000614a:	000a2503          	lw	a0,0(s4)
    8000614e:	00000097          	auipc	ra,0x0
    80006152:	da8080e7          	jalr	-600(ra) # 80005ef6 <free_desc>
      for(int j = 0; j < i; j++)
    80006156:	2d85                	addiw	s11,s11,1
    80006158:	0a11                	addi	s4,s4,4
    8000615a:	ffb918e3          	bne	s2,s11,8000614a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000615e:	0001f597          	auipc	a1,0x1f
    80006162:	f4a58593          	addi	a1,a1,-182 # 800250a8 <disk+0x20a8>
    80006166:	0001f517          	auipc	a0,0x1f
    8000616a:	eb250513          	addi	a0,a0,-334 # 80025018 <disk+0x2018>
    8000616e:	ffffc097          	auipc	ra,0xffffc
    80006172:	172080e7          	jalr	370(ra) # 800022e0 <sleep>
  for(int i = 0; i < 3; i++){
    80006176:	f8040a13          	addi	s4,s0,-128
{
    8000617a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000617c:	894e                	mv	s2,s3
    8000617e:	b765                	j	80006126 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006180:	0001f717          	auipc	a4,0x1f
    80006184:	e8073703          	ld	a4,-384(a4) # 80025000 <disk+0x2000>
    80006188:	973e                	add	a4,a4,a5
    8000618a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000618e:	0001d517          	auipc	a0,0x1d
    80006192:	e7250513          	addi	a0,a0,-398 # 80023000 <disk>
    80006196:	0001f717          	auipc	a4,0x1f
    8000619a:	e6a70713          	addi	a4,a4,-406 # 80025000 <disk+0x2000>
    8000619e:	6314                	ld	a3,0(a4)
    800061a0:	96be                	add	a3,a3,a5
    800061a2:	00c6d603          	lhu	a2,12(a3)
    800061a6:	00166613          	ori	a2,a2,1
    800061aa:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ae:	f8842683          	lw	a3,-120(s0)
    800061b2:	6310                	ld	a2,0(a4)
    800061b4:	97b2                	add	a5,a5,a2
    800061b6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800061ba:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800061be:	0612                	slli	a2,a2,0x4
    800061c0:	962a                	add	a2,a2,a0
    800061c2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061c6:	00469793          	slli	a5,a3,0x4
    800061ca:	630c                	ld	a1,0(a4)
    800061cc:	95be                	add	a1,a1,a5
    800061ce:	6689                	lui	a3,0x2
    800061d0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800061d4:	96ca                	add	a3,a3,s2
    800061d6:	96aa                	add	a3,a3,a0
    800061d8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800061da:	6314                	ld	a3,0(a4)
    800061dc:	96be                	add	a3,a3,a5
    800061de:	4585                	li	a1,1
    800061e0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061e2:	6314                	ld	a3,0(a4)
    800061e4:	96be                	add	a3,a3,a5
    800061e6:	4509                	li	a0,2
    800061e8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061ec:	6314                	ld	a3,0(a4)
    800061ee:	97b6                	add	a5,a5,a3
    800061f0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061f4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061f8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061fc:	6714                	ld	a3,8(a4)
    800061fe:	0026d783          	lhu	a5,2(a3)
    80006202:	8b9d                	andi	a5,a5,7
    80006204:	0789                	addi	a5,a5,2
    80006206:	0786                	slli	a5,a5,0x1
    80006208:	97b6                	add	a5,a5,a3
    8000620a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000620e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006212:	6718                	ld	a4,8(a4)
    80006214:	00275783          	lhu	a5,2(a4)
    80006218:	2785                	addiw	a5,a5,1
    8000621a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006226:	004aa783          	lw	a5,4(s5)
    8000622a:	02b79163          	bne	a5,a1,8000624c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000622e:	0001f917          	auipc	s2,0x1f
    80006232:	e7a90913          	addi	s2,s2,-390 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006236:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006238:	85ca                	mv	a1,s2
    8000623a:	8556                	mv	a0,s5
    8000623c:	ffffc097          	auipc	ra,0xffffc
    80006240:	0a4080e7          	jalr	164(ra) # 800022e0 <sleep>
  while(b->disk == 1) {
    80006244:	004aa783          	lw	a5,4(s5)
    80006248:	fe9788e3          	beq	a5,s1,80006238 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000624c:	f8042483          	lw	s1,-128(s0)
    80006250:	20048793          	addi	a5,s1,512
    80006254:	00479713          	slli	a4,a5,0x4
    80006258:	0001d797          	auipc	a5,0x1d
    8000625c:	da878793          	addi	a5,a5,-600 # 80023000 <disk>
    80006260:	97ba                	add	a5,a5,a4
    80006262:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006266:	0001f917          	auipc	s2,0x1f
    8000626a:	d9a90913          	addi	s2,s2,-614 # 80025000 <disk+0x2000>
    8000626e:	a019                	j	80006274 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006270:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006274:	8526                	mv	a0,s1
    80006276:	00000097          	auipc	ra,0x0
    8000627a:	c80080e7          	jalr	-896(ra) # 80005ef6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000627e:	0492                	slli	s1,s1,0x4
    80006280:	00093783          	ld	a5,0(s2)
    80006284:	94be                	add	s1,s1,a5
    80006286:	00c4d783          	lhu	a5,12(s1)
    8000628a:	8b85                	andi	a5,a5,1
    8000628c:	f3f5                	bnez	a5,80006270 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000628e:	0001f517          	auipc	a0,0x1f
    80006292:	e1a50513          	addi	a0,a0,-486 # 800250a8 <disk+0x20a8>
    80006296:	ffffb097          	auipc	ra,0xffffb
    8000629a:	a1c080e7          	jalr	-1508(ra) # 80000cb2 <release>
}
    8000629e:	60aa                	ld	ra,136(sp)
    800062a0:	640a                	ld	s0,128(sp)
    800062a2:	74e6                	ld	s1,120(sp)
    800062a4:	7946                	ld	s2,112(sp)
    800062a6:	79a6                	ld	s3,104(sp)
    800062a8:	7a06                	ld	s4,96(sp)
    800062aa:	6ae6                	ld	s5,88(sp)
    800062ac:	6b46                	ld	s6,80(sp)
    800062ae:	6ba6                	ld	s7,72(sp)
    800062b0:	6c06                	ld	s8,64(sp)
    800062b2:	7ce2                	ld	s9,56(sp)
    800062b4:	7d42                	ld	s10,48(sp)
    800062b6:	7da2                	ld	s11,40(sp)
    800062b8:	6149                	addi	sp,sp,144
    800062ba:	8082                	ret
  if(write)
    800062bc:	01a037b3          	snez	a5,s10
    800062c0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800062c4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800062c8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa(myproc()->kernelpgtbl, (uint64) &buf0); // 调用 myproc()，获取进程内核页表
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	768080e7          	jalr	1896(ra) # 80001a34 <myproc>
    800062d4:	f8042483          	lw	s1,-128(s0)
    800062d8:	00449913          	slli	s2,s1,0x4
    800062dc:	0001f997          	auipc	s3,0x1f
    800062e0:	d2498993          	addi	s3,s3,-732 # 80025000 <disk+0x2000>
    800062e4:	0009ba03          	ld	s4,0(s3)
    800062e8:	9a4a                	add	s4,s4,s2
    800062ea:	f7040593          	addi	a1,s0,-144
    800062ee:	6d28                	ld	a0,88(a0)
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	de2080e7          	jalr	-542(ra) # 800010d2 <kvmpa>
    800062f8:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800062fc:	0009b783          	ld	a5,0(s3)
    80006300:	97ca                	add	a5,a5,s2
    80006302:	4741                	li	a4,16
    80006304:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006306:	0009b783          	ld	a5,0(s3)
    8000630a:	97ca                	add	a5,a5,s2
    8000630c:	4705                	li	a4,1
    8000630e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006312:	f8442783          	lw	a5,-124(s0)
    80006316:	0009b703          	ld	a4,0(s3)
    8000631a:	974a                	add	a4,a4,s2
    8000631c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006320:	0792                	slli	a5,a5,0x4
    80006322:	0009b703          	ld	a4,0(s3)
    80006326:	973e                	add	a4,a4,a5
    80006328:	058a8693          	addi	a3,s5,88
    8000632c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000632e:	0009b703          	ld	a4,0(s3)
    80006332:	973e                	add	a4,a4,a5
    80006334:	40000693          	li	a3,1024
    80006338:	c714                	sw	a3,8(a4)
  if(write)
    8000633a:	e40d13e3          	bnez	s10,80006180 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000633e:	0001f717          	auipc	a4,0x1f
    80006342:	cc273703          	ld	a4,-830(a4) # 80025000 <disk+0x2000>
    80006346:	973e                	add	a4,a4,a5
    80006348:	4689                	li	a3,2
    8000634a:	00d71623          	sh	a3,12(a4)
    8000634e:	b581                	j	8000618e <virtio_disk_rw+0xd2>

0000000080006350 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006350:	1101                	addi	sp,sp,-32
    80006352:	ec06                	sd	ra,24(sp)
    80006354:	e822                	sd	s0,16(sp)
    80006356:	e426                	sd	s1,8(sp)
    80006358:	e04a                	sd	s2,0(sp)
    8000635a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000635c:	0001f517          	auipc	a0,0x1f
    80006360:	d4c50513          	addi	a0,a0,-692 # 800250a8 <disk+0x20a8>
    80006364:	ffffb097          	auipc	ra,0xffffb
    80006368:	89a080e7          	jalr	-1894(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000636c:	0001f717          	auipc	a4,0x1f
    80006370:	c9470713          	addi	a4,a4,-876 # 80025000 <disk+0x2000>
    80006374:	02075783          	lhu	a5,32(a4)
    80006378:	6b18                	ld	a4,16(a4)
    8000637a:	00275683          	lhu	a3,2(a4)
    8000637e:	8ebd                	xor	a3,a3,a5
    80006380:	8a9d                	andi	a3,a3,7
    80006382:	cab9                	beqz	a3,800063d8 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006384:	0001d917          	auipc	s2,0x1d
    80006388:	c7c90913          	addi	s2,s2,-900 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000638c:	0001f497          	auipc	s1,0x1f
    80006390:	c7448493          	addi	s1,s1,-908 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006394:	078e                	slli	a5,a5,0x3
    80006396:	97ba                	add	a5,a5,a4
    80006398:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    8000639a:	20078713          	addi	a4,a5,512
    8000639e:	0712                	slli	a4,a4,0x4
    800063a0:	974a                	add	a4,a4,s2
    800063a2:	03074703          	lbu	a4,48(a4)
    800063a6:	ef21                	bnez	a4,800063fe <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063a8:	20078793          	addi	a5,a5,512
    800063ac:	0792                	slli	a5,a5,0x4
    800063ae:	97ca                	add	a5,a5,s2
    800063b0:	7798                	ld	a4,40(a5)
    800063b2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063b6:	7788                	ld	a0,40(a5)
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	0a8080e7          	jalr	168(ra) # 80002460 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063c0:	0204d783          	lhu	a5,32(s1)
    800063c4:	2785                	addiw	a5,a5,1
    800063c6:	8b9d                	andi	a5,a5,7
    800063c8:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063cc:	6898                	ld	a4,16(s1)
    800063ce:	00275683          	lhu	a3,2(a4)
    800063d2:	8a9d                	andi	a3,a3,7
    800063d4:	fcf690e3          	bne	a3,a5,80006394 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063d8:	10001737          	lui	a4,0x10001
    800063dc:	533c                	lw	a5,96(a4)
    800063de:	8b8d                	andi	a5,a5,3
    800063e0:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063e2:	0001f517          	auipc	a0,0x1f
    800063e6:	cc650513          	addi	a0,a0,-826 # 800250a8 <disk+0x20a8>
    800063ea:	ffffb097          	auipc	ra,0xffffb
    800063ee:	8c8080e7          	jalr	-1848(ra) # 80000cb2 <release>
}
    800063f2:	60e2                	ld	ra,24(sp)
    800063f4:	6442                	ld	s0,16(sp)
    800063f6:	64a2                	ld	s1,8(sp)
    800063f8:	6902                	ld	s2,0(sp)
    800063fa:	6105                	addi	sp,sp,32
    800063fc:	8082                	ret
      panic("virtio_disk_intr status");
    800063fe:	00002517          	auipc	a0,0x2
    80006402:	3f250513          	addi	a0,a0,1010 # 800087f0 <syscalls+0x3c8>
    80006406:	ffffa097          	auipc	ra,0xffffa
    8000640a:	13c080e7          	jalr	316(ra) # 80000542 <panic>

000000008000640e <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000640e:	7179                	addi	sp,sp,-48
    80006410:	f406                	sd	ra,40(sp)
    80006412:	f022                	sd	s0,32(sp)
    80006414:	ec26                	sd	s1,24(sp)
    80006416:	e84a                	sd	s2,16(sp)
    80006418:	e44e                	sd	s3,8(sp)
    8000641a:	e052                	sd	s4,0(sp)
    8000641c:	1800                	addi	s0,sp,48
    8000641e:	892a                	mv	s2,a0
    80006420:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006422:	00003a17          	auipc	s4,0x3
    80006426:	c06a0a13          	addi	s4,s4,-1018 # 80009028 <stats>
    8000642a:	000a2683          	lw	a3,0(s4)
    8000642e:	00002617          	auipc	a2,0x2
    80006432:	3da60613          	addi	a2,a2,986 # 80008808 <syscalls+0x3e0>
    80006436:	00000097          	auipc	ra,0x0
    8000643a:	304080e7          	jalr	772(ra) # 8000673a <snprintf>
    8000643e:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006440:	004a2683          	lw	a3,4(s4)
    80006444:	00002617          	auipc	a2,0x2
    80006448:	3d460613          	addi	a2,a2,980 # 80008818 <syscalls+0x3f0>
    8000644c:	85ce                	mv	a1,s3
    8000644e:	954a                	add	a0,a0,s2
    80006450:	00000097          	auipc	ra,0x0
    80006454:	2ea080e7          	jalr	746(ra) # 8000673a <snprintf>
  return n;
}
    80006458:	9d25                	addw	a0,a0,s1
    8000645a:	70a2                	ld	ra,40(sp)
    8000645c:	7402                	ld	s0,32(sp)
    8000645e:	64e2                	ld	s1,24(sp)
    80006460:	6942                	ld	s2,16(sp)
    80006462:	69a2                	ld	s3,8(sp)
    80006464:	6a02                	ld	s4,0(sp)
    80006466:	6145                	addi	sp,sp,48
    80006468:	8082                	ret

000000008000646a <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000646a:	7179                	addi	sp,sp,-48
    8000646c:	f406                	sd	ra,40(sp)
    8000646e:	f022                	sd	s0,32(sp)
    80006470:	ec26                	sd	s1,24(sp)
    80006472:	e84a                	sd	s2,16(sp)
    80006474:	e44e                	sd	s3,8(sp)
    80006476:	e052                	sd	s4,0(sp)
    80006478:	1800                	addi	s0,sp,48
    8000647a:	8a2e                	mv	s4,a1
    8000647c:	84b2                	mv	s1,a2
    8000647e:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006480:	ffffb097          	auipc	ra,0xffffb
    80006484:	5b4080e7          	jalr	1460(ra) # 80001a34 <myproc>
    80006488:	89aa                	mv	s3,a0

  if(uvmshouldtouch(srcva))
    8000648a:	8526                	mv	a0,s1
    8000648c:	ffffc097          	auipc	ra,0xffffc
    80006490:	2b4080e7          	jalr	692(ra) # 80002740 <uvmshouldtouch>
    80006494:	e139                	bnez	a0,800064da <copyin_new+0x70>
    uvmlazytouch(srcva);

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006496:	0489b783          	ld	a5,72(s3)
    8000649a:	04f4f663          	bgeu	s1,a5,800064e6 <copyin_new+0x7c>
    8000649e:	01248733          	add	a4,s1,s2
    800064a2:	04f77463          	bgeu	a4,a5,800064ea <copyin_new+0x80>
    800064a6:	04976463          	bltu	a4,s1,800064ee <copyin_new+0x84>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800064aa:	0009061b          	sext.w	a2,s2
    800064ae:	85a6                	mv	a1,s1
    800064b0:	8552                	mv	a0,s4
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	8a4080e7          	jalr	-1884(ra) # 80000d56 <memmove>
  stats.ncopyin++;   // XXX lock
    800064ba:	00003717          	auipc	a4,0x3
    800064be:	b6e70713          	addi	a4,a4,-1170 # 80009028 <stats>
    800064c2:	431c                	lw	a5,0(a4)
    800064c4:	2785                	addiw	a5,a5,1
    800064c6:	c31c                	sw	a5,0(a4)
  return 0;
    800064c8:	4501                	li	a0,0
}
    800064ca:	70a2                	ld	ra,40(sp)
    800064cc:	7402                	ld	s0,32(sp)
    800064ce:	64e2                	ld	s1,24(sp)
    800064d0:	6942                	ld	s2,16(sp)
    800064d2:	69a2                	ld	s3,8(sp)
    800064d4:	6a02                	ld	s4,0(sp)
    800064d6:	6145                	addi	sp,sp,48
    800064d8:	8082                	ret
    uvmlazytouch(srcva);
    800064da:	8526                	mv	a0,s1
    800064dc:	ffffc097          	auipc	ra,0xffffc
    800064e0:	1b8080e7          	jalr	440(ra) # 80002694 <uvmlazytouch>
    800064e4:	bf4d                	j	80006496 <copyin_new+0x2c>
    return -1;
    800064e6:	557d                	li	a0,-1
    800064e8:	b7cd                	j	800064ca <copyin_new+0x60>
    800064ea:	557d                	li	a0,-1
    800064ec:	bff9                	j	800064ca <copyin_new+0x60>
    800064ee:	557d                	li	a0,-1
    800064f0:	bfe9                	j	800064ca <copyin_new+0x60>

00000000800064f2 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800064f2:	7179                	addi	sp,sp,-48
    800064f4:	f406                	sd	ra,40(sp)
    800064f6:	f022                	sd	s0,32(sp)
    800064f8:	ec26                	sd	s1,24(sp)
    800064fa:	e84a                	sd	s2,16(sp)
    800064fc:	e44e                	sd	s3,8(sp)
    800064fe:	e052                	sd	s4,0(sp)
    80006500:	1800                	addi	s0,sp,48
    80006502:	8a2e                	mv	s4,a1
    80006504:	84b2                	mv	s1,a2
    80006506:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006508:	ffffb097          	auipc	ra,0xffffb
    8000650c:	52c080e7          	jalr	1324(ra) # 80001a34 <myproc>
    80006510:	89aa                	mv	s3,a0
  char *s = (char *) srcva;
  
  if(uvmshouldtouch(srcva))
    80006512:	8526                	mv	a0,s1
    80006514:	ffffc097          	auipc	ra,0xffffc
    80006518:	22c080e7          	jalr	556(ra) # 80002740 <uvmshouldtouch>
    8000651c:	ed15                	bnez	a0,80006558 <copyinstr_new+0x66>
    uvmlazytouch(srcva);

  stats.ncopyinstr++;   // XXX lock
    8000651e:	00003717          	auipc	a4,0x3
    80006522:	b0a70713          	addi	a4,a4,-1270 # 80009028 <stats>
    80006526:	435c                	lw	a5,4(a4)
    80006528:	2785                	addiw	a5,a5,1
    8000652a:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000652c:	04090563          	beqz	s2,80006576 <copyinstr_new+0x84>
    80006530:	01248633          	add	a2,s1,s2
    80006534:	87a6                	mv	a5,s1
    80006536:	0489b703          	ld	a4,72(s3)
    8000653a:	02e7f563          	bgeu	a5,a4,80006564 <copyinstr_new+0x72>
    dst[i] = s[i];
    8000653e:	0007c683          	lbu	a3,0(a5)
    80006542:	40978733          	sub	a4,a5,s1
    80006546:	9752                	add	a4,a4,s4
    80006548:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000654c:	c69d                	beqz	a3,8000657a <copyinstr_new+0x88>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000654e:	0785                	addi	a5,a5,1
    80006550:	fec793e3          	bne	a5,a2,80006536 <copyinstr_new+0x44>
      return 0;
  }
  return -1;
    80006554:	557d                	li	a0,-1
    80006556:	a801                	j	80006566 <copyinstr_new+0x74>
    uvmlazytouch(srcva);
    80006558:	8526                	mv	a0,s1
    8000655a:	ffffc097          	auipc	ra,0xffffc
    8000655e:	13a080e7          	jalr	314(ra) # 80002694 <uvmlazytouch>
    80006562:	bf75                	j	8000651e <copyinstr_new+0x2c>
  return -1;
    80006564:	557d                	li	a0,-1
}
    80006566:	70a2                	ld	ra,40(sp)
    80006568:	7402                	ld	s0,32(sp)
    8000656a:	64e2                	ld	s1,24(sp)
    8000656c:	6942                	ld	s2,16(sp)
    8000656e:	69a2                	ld	s3,8(sp)
    80006570:	6a02                	ld	s4,0(sp)
    80006572:	6145                	addi	sp,sp,48
    80006574:	8082                	ret
  return -1;
    80006576:	557d                	li	a0,-1
    80006578:	b7fd                	j	80006566 <copyinstr_new+0x74>
      return 0;
    8000657a:	4501                	li	a0,0
    8000657c:	b7ed                	j	80006566 <copyinstr_new+0x74>

000000008000657e <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000657e:	1141                	addi	sp,sp,-16
    80006580:	e422                	sd	s0,8(sp)
    80006582:	0800                	addi	s0,sp,16
  return -1;
}
    80006584:	557d                	li	a0,-1
    80006586:	6422                	ld	s0,8(sp)
    80006588:	0141                	addi	sp,sp,16
    8000658a:	8082                	ret

000000008000658c <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    8000658c:	7179                	addi	sp,sp,-48
    8000658e:	f406                	sd	ra,40(sp)
    80006590:	f022                	sd	s0,32(sp)
    80006592:	ec26                	sd	s1,24(sp)
    80006594:	e84a                	sd	s2,16(sp)
    80006596:	e44e                	sd	s3,8(sp)
    80006598:	e052                	sd	s4,0(sp)
    8000659a:	1800                	addi	s0,sp,48
    8000659c:	892a                	mv	s2,a0
    8000659e:	89ae                	mv	s3,a1
    800065a0:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800065a2:	00020517          	auipc	a0,0x20
    800065a6:	a5e50513          	addi	a0,a0,-1442 # 80026000 <stats>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	654080e7          	jalr	1620(ra) # 80000bfe <acquire>

  if(stats.sz == 0) {
    800065b2:	00021797          	auipc	a5,0x21
    800065b6:	a667a783          	lw	a5,-1434(a5) # 80027018 <stats+0x1018>
    800065ba:	cbb5                	beqz	a5,8000662e <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800065bc:	00021797          	auipc	a5,0x21
    800065c0:	a4478793          	addi	a5,a5,-1468 # 80027000 <stats+0x1000>
    800065c4:	4fd8                	lw	a4,28(a5)
    800065c6:	4f9c                	lw	a5,24(a5)
    800065c8:	9f99                	subw	a5,a5,a4
    800065ca:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800065ce:	06d05e63          	blez	a3,8000664a <statsread+0xbe>
    if(m > n)
    800065d2:	8a3e                	mv	s4,a5
    800065d4:	00d4d363          	bge	s1,a3,800065da <statsread+0x4e>
    800065d8:	8a26                	mv	s4,s1
    800065da:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065de:	86a6                	mv	a3,s1
    800065e0:	00020617          	auipc	a2,0x20
    800065e4:	a3860613          	addi	a2,a2,-1480 # 80026018 <stats+0x18>
    800065e8:	963a                	add	a2,a2,a4
    800065ea:	85ce                	mv	a1,s3
    800065ec:	854a                	mv	a0,s2
    800065ee:	ffffc097          	auipc	ra,0xffffc
    800065f2:	f4c080e7          	jalr	-180(ra) # 8000253a <either_copyout>
    800065f6:	57fd                	li	a5,-1
    800065f8:	00f50a63          	beq	a0,a5,8000660c <statsread+0x80>
      stats.off += m;
    800065fc:	00021717          	auipc	a4,0x21
    80006600:	a0470713          	addi	a4,a4,-1532 # 80027000 <stats+0x1000>
    80006604:	4f5c                	lw	a5,28(a4)
    80006606:	014787bb          	addw	a5,a5,s4
    8000660a:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    8000660c:	00020517          	auipc	a0,0x20
    80006610:	9f450513          	addi	a0,a0,-1548 # 80026000 <stats>
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	69e080e7          	jalr	1694(ra) # 80000cb2 <release>
  return m;
}
    8000661c:	8526                	mv	a0,s1
    8000661e:	70a2                	ld	ra,40(sp)
    80006620:	7402                	ld	s0,32(sp)
    80006622:	64e2                	ld	s1,24(sp)
    80006624:	6942                	ld	s2,16(sp)
    80006626:	69a2                	ld	s3,8(sp)
    80006628:	6a02                	ld	s4,0(sp)
    8000662a:	6145                	addi	sp,sp,48
    8000662c:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    8000662e:	6585                	lui	a1,0x1
    80006630:	00020517          	auipc	a0,0x20
    80006634:	9e850513          	addi	a0,a0,-1560 # 80026018 <stats+0x18>
    80006638:	00000097          	auipc	ra,0x0
    8000663c:	dd6080e7          	jalr	-554(ra) # 8000640e <statscopyin>
    80006640:	00021797          	auipc	a5,0x21
    80006644:	9ca7ac23          	sw	a0,-1576(a5) # 80027018 <stats+0x1018>
    80006648:	bf95                	j	800065bc <statsread+0x30>
    stats.sz = 0;
    8000664a:	00021797          	auipc	a5,0x21
    8000664e:	9b678793          	addi	a5,a5,-1610 # 80027000 <stats+0x1000>
    80006652:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006656:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000665a:	54fd                	li	s1,-1
    8000665c:	bf45                	j	8000660c <statsread+0x80>

000000008000665e <statsinit>:

void
statsinit(void)
{
    8000665e:	1141                	addi	sp,sp,-16
    80006660:	e406                	sd	ra,8(sp)
    80006662:	e022                	sd	s0,0(sp)
    80006664:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006666:	00002597          	auipc	a1,0x2
    8000666a:	1c258593          	addi	a1,a1,450 # 80008828 <syscalls+0x400>
    8000666e:	00020517          	auipc	a0,0x20
    80006672:	99250513          	addi	a0,a0,-1646 # 80026000 <stats>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	4f8080e7          	jalr	1272(ra) # 80000b6e <initlock>

  devsw[STATS].read = statsread;
    8000667e:	0001b797          	auipc	a5,0x1b
    80006682:	53278793          	addi	a5,a5,1330 # 80021bb0 <devsw>
    80006686:	00000717          	auipc	a4,0x0
    8000668a:	f0670713          	addi	a4,a4,-250 # 8000658c <statsread>
    8000668e:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006690:	00000717          	auipc	a4,0x0
    80006694:	eee70713          	addi	a4,a4,-274 # 8000657e <statswrite>
    80006698:	f798                	sd	a4,40(a5)
}
    8000669a:	60a2                	ld	ra,8(sp)
    8000669c:	6402                	ld	s0,0(sp)
    8000669e:	0141                	addi	sp,sp,16
    800066a0:	8082                	ret

00000000800066a2 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800066a2:	1101                	addi	sp,sp,-32
    800066a4:	ec22                	sd	s0,24(sp)
    800066a6:	1000                	addi	s0,sp,32
    800066a8:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800066aa:	c299                	beqz	a3,800066b0 <sprintint+0xe>
    800066ac:	0805c163          	bltz	a1,8000672e <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800066b0:	2581                	sext.w	a1,a1
    800066b2:	4301                	li	t1,0

  i = 0;
    800066b4:	fe040713          	addi	a4,s0,-32
    800066b8:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800066ba:	2601                	sext.w	a2,a2
    800066bc:	00002697          	auipc	a3,0x2
    800066c0:	17468693          	addi	a3,a3,372 # 80008830 <digits>
    800066c4:	88aa                	mv	a7,a0
    800066c6:	2505                	addiw	a0,a0,1
    800066c8:	02c5f7bb          	remuw	a5,a1,a2
    800066cc:	1782                	slli	a5,a5,0x20
    800066ce:	9381                	srli	a5,a5,0x20
    800066d0:	97b6                	add	a5,a5,a3
    800066d2:	0007c783          	lbu	a5,0(a5)
    800066d6:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066da:	0005879b          	sext.w	a5,a1
    800066de:	02c5d5bb          	divuw	a1,a1,a2
    800066e2:	0705                	addi	a4,a4,1
    800066e4:	fec7f0e3          	bgeu	a5,a2,800066c4 <sprintint+0x22>

  if(sign)
    800066e8:	00030b63          	beqz	t1,800066fe <sprintint+0x5c>
    buf[i++] = '-';
    800066ec:	ff040793          	addi	a5,s0,-16
    800066f0:	97aa                	add	a5,a5,a0
    800066f2:	02d00713          	li	a4,45
    800066f6:	fee78823          	sb	a4,-16(a5)
    800066fa:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066fe:	02a05c63          	blez	a0,80006736 <sprintint+0x94>
    80006702:	fe040793          	addi	a5,s0,-32
    80006706:	00a78733          	add	a4,a5,a0
    8000670a:	87c2                	mv	a5,a6
    8000670c:	0805                	addi	a6,a6,1
    8000670e:	fff5061b          	addiw	a2,a0,-1
    80006712:	1602                	slli	a2,a2,0x20
    80006714:	9201                	srli	a2,a2,0x20
    80006716:	9642                	add	a2,a2,a6
  *s = c;
    80006718:	fff74683          	lbu	a3,-1(a4)
    8000671c:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006720:	177d                	addi	a4,a4,-1
    80006722:	0785                	addi	a5,a5,1
    80006724:	fec79ae3          	bne	a5,a2,80006718 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006728:	6462                	ld	s0,24(sp)
    8000672a:	6105                	addi	sp,sp,32
    8000672c:	8082                	ret
    x = -xx;
    8000672e:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006732:	4305                	li	t1,1
    x = -xx;
    80006734:	b741                	j	800066b4 <sprintint+0x12>
  while(--i >= 0)
    80006736:	4501                	li	a0,0
    80006738:	bfc5                	j	80006728 <sprintint+0x86>

000000008000673a <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000673a:	7135                	addi	sp,sp,-160
    8000673c:	f486                	sd	ra,104(sp)
    8000673e:	f0a2                	sd	s0,96(sp)
    80006740:	eca6                	sd	s1,88(sp)
    80006742:	e8ca                	sd	s2,80(sp)
    80006744:	e4ce                	sd	s3,72(sp)
    80006746:	e0d2                	sd	s4,64(sp)
    80006748:	fc56                	sd	s5,56(sp)
    8000674a:	f85a                	sd	s6,48(sp)
    8000674c:	f45e                	sd	s7,40(sp)
    8000674e:	f062                	sd	s8,32(sp)
    80006750:	ec66                	sd	s9,24(sp)
    80006752:	e86a                	sd	s10,16(sp)
    80006754:	1880                	addi	s0,sp,112
    80006756:	e414                	sd	a3,8(s0)
    80006758:	e818                	sd	a4,16(s0)
    8000675a:	ec1c                	sd	a5,24(s0)
    8000675c:	03043023          	sd	a6,32(s0)
    80006760:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006764:	c61d                	beqz	a2,80006792 <snprintf+0x58>
    80006766:	8baa                	mv	s7,a0
    80006768:	89ae                	mv	s3,a1
    8000676a:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000676c:	00840793          	addi	a5,s0,8
    80006770:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    80006774:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006776:	4901                	li	s2,0
    80006778:	02b05563          	blez	a1,800067a2 <snprintf+0x68>
    if(c != '%'){
    8000677c:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006780:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006784:	02800d13          	li	s10,40
    switch(c){
    80006788:	07800c93          	li	s9,120
    8000678c:	06400c13          	li	s8,100
    80006790:	a01d                	j	800067b6 <snprintf+0x7c>
    panic("null fmt");
    80006792:	00002517          	auipc	a0,0x2
    80006796:	88650513          	addi	a0,a0,-1914 # 80008018 <etext+0x18>
    8000679a:	ffffa097          	auipc	ra,0xffffa
    8000679e:	da8080e7          	jalr	-600(ra) # 80000542 <panic>
  int off = 0;
    800067a2:	4481                	li	s1,0
    800067a4:	a86d                	j	8000685e <snprintf+0x124>
  *s = c;
    800067a6:	009b8733          	add	a4,s7,s1
    800067aa:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800067ae:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067b0:	2905                	addiw	s2,s2,1
    800067b2:	0b34d663          	bge	s1,s3,8000685e <snprintf+0x124>
    800067b6:	012a07b3          	add	a5,s4,s2
    800067ba:	0007c783          	lbu	a5,0(a5)
    800067be:	0007871b          	sext.w	a4,a5
    800067c2:	cfd1                	beqz	a5,8000685e <snprintf+0x124>
    if(c != '%'){
    800067c4:	ff5711e3          	bne	a4,s5,800067a6 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800067c8:	2905                	addiw	s2,s2,1
    800067ca:	012a07b3          	add	a5,s4,s2
    800067ce:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800067d2:	c7d1                	beqz	a5,8000685e <snprintf+0x124>
    switch(c){
    800067d4:	05678c63          	beq	a5,s6,8000682c <snprintf+0xf2>
    800067d8:	02fb6763          	bltu	s6,a5,80006806 <snprintf+0xcc>
    800067dc:	0b578663          	beq	a5,s5,80006888 <snprintf+0x14e>
    800067e0:	0b879a63          	bne	a5,s8,80006894 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067e4:	f9843783          	ld	a5,-104(s0)
    800067e8:	00878713          	addi	a4,a5,8
    800067ec:	f8e43c23          	sd	a4,-104(s0)
    800067f0:	4685                	li	a3,1
    800067f2:	4629                	li	a2,10
    800067f4:	438c                	lw	a1,0(a5)
    800067f6:	009b8533          	add	a0,s7,s1
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	ea8080e7          	jalr	-344(ra) # 800066a2 <sprintint>
    80006802:	9ca9                	addw	s1,s1,a0
      break;
    80006804:	b775                	j	800067b0 <snprintf+0x76>
    switch(c){
    80006806:	09979763          	bne	a5,s9,80006894 <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    8000680a:	f9843783          	ld	a5,-104(s0)
    8000680e:	00878713          	addi	a4,a5,8
    80006812:	f8e43c23          	sd	a4,-104(s0)
    80006816:	4685                	li	a3,1
    80006818:	4641                	li	a2,16
    8000681a:	438c                	lw	a1,0(a5)
    8000681c:	009b8533          	add	a0,s7,s1
    80006820:	00000097          	auipc	ra,0x0
    80006824:	e82080e7          	jalr	-382(ra) # 800066a2 <sprintint>
    80006828:	9ca9                	addw	s1,s1,a0
      break;
    8000682a:	b759                	j	800067b0 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    8000682c:	f9843783          	ld	a5,-104(s0)
    80006830:	00878713          	addi	a4,a5,8
    80006834:	f8e43c23          	sd	a4,-104(s0)
    80006838:	639c                	ld	a5,0(a5)
    8000683a:	c3a9                	beqz	a5,8000687c <snprintf+0x142>
      for(; *s && off < sz; s++)
    8000683c:	0007c703          	lbu	a4,0(a5)
    80006840:	db25                	beqz	a4,800067b0 <snprintf+0x76>
    80006842:	0134de63          	bge	s1,s3,8000685e <snprintf+0x124>
    80006846:	009b86b3          	add	a3,s7,s1
  *s = c;
    8000684a:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    8000684e:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006850:	0785                	addi	a5,a5,1
    80006852:	0007c703          	lbu	a4,0(a5)
    80006856:	df29                	beqz	a4,800067b0 <snprintf+0x76>
    80006858:	0685                	addi	a3,a3,1
    8000685a:	fe9998e3          	bne	s3,s1,8000684a <snprintf+0x110>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    8000685e:	8526                	mv	a0,s1
    80006860:	70a6                	ld	ra,104(sp)
    80006862:	7406                	ld	s0,96(sp)
    80006864:	64e6                	ld	s1,88(sp)
    80006866:	6946                	ld	s2,80(sp)
    80006868:	69a6                	ld	s3,72(sp)
    8000686a:	6a06                	ld	s4,64(sp)
    8000686c:	7ae2                	ld	s5,56(sp)
    8000686e:	7b42                	ld	s6,48(sp)
    80006870:	7ba2                	ld	s7,40(sp)
    80006872:	7c02                	ld	s8,32(sp)
    80006874:	6ce2                	ld	s9,24(sp)
    80006876:	6d42                	ld	s10,16(sp)
    80006878:	610d                	addi	sp,sp,160
    8000687a:	8082                	ret
        s = "(null)";
    8000687c:	00001797          	auipc	a5,0x1
    80006880:	79478793          	addi	a5,a5,1940 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    80006884:	876a                	mv	a4,s10
    80006886:	bf75                	j	80006842 <snprintf+0x108>
  *s = c;
    80006888:	009b87b3          	add	a5,s7,s1
    8000688c:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    80006890:	2485                	addiw	s1,s1,1
      break;
    80006892:	bf39                	j	800067b0 <snprintf+0x76>
  *s = c;
    80006894:	009b8733          	add	a4,s7,s1
    80006898:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    8000689c:	0014871b          	addiw	a4,s1,1
  *s = c;
    800068a0:	975e                	add	a4,a4,s7
    800068a2:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068a6:	2489                	addiw	s1,s1,2
      break;
    800068a8:	b721                	j	800067b0 <snprintf+0x76>
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
