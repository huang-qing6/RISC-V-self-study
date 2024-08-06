
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
    80000060:	d6478793          	addi	a5,a5,-668 # 80005dc0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e5478793          	addi	a5,a5,-428 # 80000efa <main>
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
    80000110:	b44080e7          	jalr	-1212(ra) # 80000c50 <acquire>
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
    8000012a:	3be080e7          	jalr	958(ra) # 800024e4 <either_copyin>
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
    80000152:	bb6080e7          	jalr	-1098(ra) # 80000d04 <release>

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
    800001a0:	ab4080e7          	jalr	-1356(ra) # 80000c50 <acquire>
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
    800001ce:	852080e7          	jalr	-1966(ra) # 80001a1c <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	05a080e7          	jalr	90(ra) # 80002234 <sleep>
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
    8000021a:	278080e7          	jalr	632(ra) # 8000248e <either_copyout>
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
    80000236:	ad2080e7          	jalr	-1326(ra) # 80000d04 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	abc080e7          	jalr	-1348(ra) # 80000d04 <release>
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
    800002dc:	978080e7          	jalr	-1672(ra) # 80000c50 <acquire>

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
    800002fa:	244080e7          	jalr	580(ra) # 8000253a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9fe080e7          	jalr	-1538(ra) # 80000d04 <release>
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
    8000044e:	f6a080e7          	jalr	-150(ra) # 800023b4 <wakeup>
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
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	754080e7          	jalr	1876(ra) # 80000bc0 <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	53478793          	addi	a5,a5,1332 # 800219b0 <devsw>
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
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
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
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
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
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	64c080e7          	jalr	1612(ra) # 80000c50 <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
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
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
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
    80000766:	5a2080e7          	jalr	1442(ra) # 80000d04 <release>
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
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	438080e7          	jalr	1080(ra) # 80000bc0 <initlock>
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
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	3e2080e7          	jalr	994(ra) # 80000bc0 <initlock>
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
    800007fe:	40a080e7          	jalr	1034(ra) # 80000c04 <push_off>

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
    8000082c:	47c080e7          	jalr	1148(ra) # 80000ca4 <pop_off>
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
    800008a6:	b12080e7          	jalr	-1262(ra) # 800023b4 <wakeup>
    
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
    800008ea:	36a080e7          	jalr	874(ra) # 80000c50 <acquire>
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
    80000940:	8f8080e7          	jalr	-1800(ra) # 80002234 <sleep>
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
    80000986:	382080e7          	jalr	898(ra) # 80000d04 <release>
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
    800009f2:	262080e7          	jalr	610(ra) # 80000c50 <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	304080e7          	jalr	772(ra) # 80000d04 <release>
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
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
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
    80000a42:	30e080e7          	jalr	782(ra) # 80000d4c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	200080e7          	jalr	512(ra) # 80000c50 <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	2a0080e7          	jalr	672(ra) # 80000d04 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
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
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	0d6080e7          	jalr	214(ra) # 80000bc0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
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
    80000b26:	12e080e7          	jalr	302(ra) # 80000c50 <acquire>
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
    80000b3e:	1ca080e7          	jalr	458(ra) # 80000d04 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	204080e7          	jalr	516(ra) # 80000d4c <memset>
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
    80000b68:	1a0080e7          	jalr	416(ra) # 80000d04 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <freebytes>:


//add new
void 
freebytes(uint64 *dst){
    80000b6e:	1101                	addi	sp,sp,-32
    80000b70:	ec06                	sd	ra,24(sp)
    80000b72:	e822                	sd	s0,16(sp)
    80000b74:	e426                	sd	s1,8(sp)
    80000b76:	e04a                	sd	s2,0(sp)
    80000b78:	1000                	addi	s0,sp,32
    80000b7a:	892a                	mv	s2,a0
  *dst = 0;
    80000b7c:	00053023          	sd	zero,0(a0)
  struct run *p = kmem.freelist; //bian li
    80000b80:	00011517          	auipc	a0,0x11
    80000b84:	db050513          	addi	a0,a0,-592 # 80011930 <kmem>
    80000b88:	6d04                	ld	s1,24(a0)

  acquire(&kmem.lock);
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	0c6080e7          	jalr	198(ra) # 80000c50 <acquire>
  while(p){
    80000b92:	c889                	beqz	s1,80000ba4 <freebytes+0x36>
    *dst += PGSIZE;
    80000b94:	6705                	lui	a4,0x1
    80000b96:	00093783          	ld	a5,0(s2)
    80000b9a:	97ba                	add	a5,a5,a4
    80000b9c:	00f93023          	sd	a5,0(s2)
    p = p->next;
    80000ba0:	6084                	ld	s1,0(s1)
  while(p){
    80000ba2:	f8f5                	bnez	s1,80000b96 <freebytes+0x28>
  }
  release(&kmem.lock);
    80000ba4:	00011517          	auipc	a0,0x11
    80000ba8:	d8c50513          	addi	a0,a0,-628 # 80011930 <kmem>
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	158080e7          	jalr	344(ra) # 80000d04 <release>
}
    80000bb4:	60e2                	ld	ra,24(sp)
    80000bb6:	6442                	ld	s0,16(sp)
    80000bb8:	64a2                	ld	s1,8(sp)
    80000bba:	6902                	ld	s2,0(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret

0000000080000bc0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bc0:	1141                	addi	sp,sp,-16
    80000bc2:	e422                	sd	s0,8(sp)
    80000bc4:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bc6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bcc:	00053823          	sd	zero,16(a0)
}
    80000bd0:	6422                	ld	s0,8(sp)
    80000bd2:	0141                	addi	sp,sp,16
    80000bd4:	8082                	ret

0000000080000bd6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bd6:	411c                	lw	a5,0(a0)
    80000bd8:	e399                	bnez	a5,80000bde <holding+0x8>
    80000bda:	4501                	li	a0,0
  return r;
}
    80000bdc:	8082                	ret
{
    80000bde:	1101                	addi	sp,sp,-32
    80000be0:	ec06                	sd	ra,24(sp)
    80000be2:	e822                	sd	s0,16(sp)
    80000be4:	e426                	sd	s1,8(sp)
    80000be6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be8:	6904                	ld	s1,16(a0)
    80000bea:	00001097          	auipc	ra,0x1
    80000bee:	e16080e7          	jalr	-490(ra) # 80001a00 <mycpu>
    80000bf2:	40a48533          	sub	a0,s1,a0
    80000bf6:	00153513          	seqz	a0,a0
}
    80000bfa:	60e2                	ld	ra,24(sp)
    80000bfc:	6442                	ld	s0,16(sp)
    80000bfe:	64a2                	ld	s1,8(sp)
    80000c00:	6105                	addi	sp,sp,32
    80000c02:	8082                	ret

0000000080000c04 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c04:	1101                	addi	sp,sp,-32
    80000c06:	ec06                	sd	ra,24(sp)
    80000c08:	e822                	sd	s0,16(sp)
    80000c0a:	e426                	sd	s1,8(sp)
    80000c0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c0e:	100024f3          	csrr	s1,sstatus
    80000c12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c18:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c1c:	00001097          	auipc	ra,0x1
    80000c20:	de4080e7          	jalr	-540(ra) # 80001a00 <mycpu>
    80000c24:	5d3c                	lw	a5,120(a0)
    80000c26:	cf89                	beqz	a5,80000c40 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	dd8080e7          	jalr	-552(ra) # 80001a00 <mycpu>
    80000c30:	5d3c                	lw	a5,120(a0)
    80000c32:	2785                	addiw	a5,a5,1
    80000c34:	dd3c                	sw	a5,120(a0)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	addi	sp,sp,32
    80000c3e:	8082                	ret
    mycpu()->intena = old;
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	dc0080e7          	jalr	-576(ra) # 80001a00 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c48:	8085                	srli	s1,s1,0x1
    80000c4a:	8885                	andi	s1,s1,1
    80000c4c:	dd64                	sw	s1,124(a0)
    80000c4e:	bfe9                	j	80000c28 <push_off+0x24>

0000000080000c50 <acquire>:
{
    80000c50:	1101                	addi	sp,sp,-32
    80000c52:	ec06                	sd	ra,24(sp)
    80000c54:	e822                	sd	s0,16(sp)
    80000c56:	e426                	sd	s1,8(sp)
    80000c58:	1000                	addi	s0,sp,32
    80000c5a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	fa8080e7          	jalr	-88(ra) # 80000c04 <push_off>
  if(holding(lk))
    80000c64:	8526                	mv	a0,s1
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	f70080e7          	jalr	-144(ra) # 80000bd6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6e:	4705                	li	a4,1
  if(holding(lk))
    80000c70:	e115                	bnez	a0,80000c94 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c72:	87ba                	mv	a5,a4
    80000c74:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c78:	2781                	sext.w	a5,a5
    80000c7a:	ffe5                	bnez	a5,80000c72 <acquire+0x22>
  __sync_synchronize();
    80000c7c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c80:	00001097          	auipc	ra,0x1
    80000c84:	d80080e7          	jalr	-640(ra) # 80001a00 <mycpu>
    80000c88:	e888                	sd	a0,16(s1)
}
    80000c8a:	60e2                	ld	ra,24(sp)
    80000c8c:	6442                	ld	s0,16(sp)
    80000c8e:	64a2                	ld	s1,8(sp)
    80000c90:	6105                	addi	sp,sp,32
    80000c92:	8082                	ret
    panic("acquire");
    80000c94:	00007517          	auipc	a0,0x7
    80000c98:	3dc50513          	addi	a0,a0,988 # 80008070 <digits+0x30>
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	8a6080e7          	jalr	-1882(ra) # 80000542 <panic>

0000000080000ca4 <pop_off>:

void
pop_off(void)
{
    80000ca4:	1141                	addi	sp,sp,-16
    80000ca6:	e406                	sd	ra,8(sp)
    80000ca8:	e022                	sd	s0,0(sp)
    80000caa:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cac:	00001097          	auipc	ra,0x1
    80000cb0:	d54080e7          	jalr	-684(ra) # 80001a00 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cba:	e78d                	bnez	a5,80000ce4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cbc:	5d3c                	lw	a5,120(a0)
    80000cbe:	02f05b63          	blez	a5,80000cf4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cc2:	37fd                	addiw	a5,a5,-1
    80000cc4:	0007871b          	sext.w	a4,a5
    80000cc8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cca:	eb09                	bnez	a4,80000cdc <pop_off+0x38>
    80000ccc:	5d7c                	lw	a5,124(a0)
    80000cce:	c799                	beqz	a5,80000cdc <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cd4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cdc:	60a2                	ld	ra,8(sp)
    80000cde:	6402                	ld	s0,0(sp)
    80000ce0:	0141                	addi	sp,sp,16
    80000ce2:	8082                	ret
    panic("pop_off - interruptible");
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	39450513          	addi	a0,a0,916 # 80008078 <digits+0x38>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	856080e7          	jalr	-1962(ra) # 80000542 <panic>
    panic("pop_off");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	39c50513          	addi	a0,a0,924 # 80008090 <digits+0x50>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	846080e7          	jalr	-1978(ra) # 80000542 <panic>

0000000080000d04 <release>:
{
    80000d04:	1101                	addi	sp,sp,-32
    80000d06:	ec06                	sd	ra,24(sp)
    80000d08:	e822                	sd	s0,16(sp)
    80000d0a:	e426                	sd	s1,8(sp)
    80000d0c:	1000                	addi	s0,sp,32
    80000d0e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	ec6080e7          	jalr	-314(ra) # 80000bd6 <holding>
    80000d18:	c115                	beqz	a0,80000d3c <release+0x38>
  lk->cpu = 0;
    80000d1a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d1e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d22:	0f50000f          	fence	iorw,ow
    80000d26:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	f7a080e7          	jalr	-134(ra) # 80000ca4 <pop_off>
}
    80000d32:	60e2                	ld	ra,24(sp)
    80000d34:	6442                	ld	s0,16(sp)
    80000d36:	64a2                	ld	s1,8(sp)
    80000d38:	6105                	addi	sp,sp,32
    80000d3a:	8082                	ret
    panic("release");
    80000d3c:	00007517          	auipc	a0,0x7
    80000d40:	35c50513          	addi	a0,a0,860 # 80008098 <digits+0x58>
    80000d44:	fffff097          	auipc	ra,0xfffff
    80000d48:	7fe080e7          	jalr	2046(ra) # 80000542 <panic>

0000000080000d4c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d4c:	1141                	addi	sp,sp,-16
    80000d4e:	e422                	sd	s0,8(sp)
    80000d50:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d52:	ca19                	beqz	a2,80000d68 <memset+0x1c>
    80000d54:	87aa                	mv	a5,a0
    80000d56:	1602                	slli	a2,a2,0x20
    80000d58:	9201                	srli	a2,a2,0x20
    80000d5a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d5e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	fee79de3          	bne	a5,a4,80000d5e <memset+0x12>
  }
  return dst;
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d74:	ca05                	beqz	a2,80000da4 <memcmp+0x36>
    80000d76:	fff6069b          	addiw	a3,a2,-1
    80000d7a:	1682                	slli	a3,a3,0x20
    80000d7c:	9281                	srli	a3,a3,0x20
    80000d7e:	0685                	addi	a3,a3,1
    80000d80:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d82:	00054783          	lbu	a5,0(a0)
    80000d86:	0005c703          	lbu	a4,0(a1)
    80000d8a:	00e79863          	bne	a5,a4,80000d9a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d8e:	0505                	addi	a0,a0,1
    80000d90:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d92:	fed518e3          	bne	a0,a3,80000d82 <memcmp+0x14>
  }

  return 0;
    80000d96:	4501                	li	a0,0
    80000d98:	a019                	j	80000d9e <memcmp+0x30>
      return *s1 - *s2;
    80000d9a:	40e7853b          	subw	a0,a5,a4
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret
  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	bfe5                	j	80000d9e <memcmp+0x30>

0000000080000da8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da8:	1141                	addi	sp,sp,-16
    80000daa:	e422                	sd	s0,8(sp)
    80000dac:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dae:	02a5e563          	bltu	a1,a0,80000dd8 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000db2:	fff6069b          	addiw	a3,a2,-1
    80000db6:	ce11                	beqz	a2,80000dd2 <memmove+0x2a>
    80000db8:	1682                	slli	a3,a3,0x20
    80000dba:	9281                	srli	a3,a3,0x20
    80000dbc:	0685                	addi	a3,a3,1
    80000dbe:	96ae                	add	a3,a3,a1
    80000dc0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dc2:	0585                	addi	a1,a1,1
    80000dc4:	0785                	addi	a5,a5,1
    80000dc6:	fff5c703          	lbu	a4,-1(a1)
    80000dca:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dce:	fed59ae3          	bne	a1,a3,80000dc2 <memmove+0x1a>

  return dst;
}
    80000dd2:	6422                	ld	s0,8(sp)
    80000dd4:	0141                	addi	sp,sp,16
    80000dd6:	8082                	ret
  if(s < d && s + n > d){
    80000dd8:	02061713          	slli	a4,a2,0x20
    80000ddc:	9301                	srli	a4,a4,0x20
    80000dde:	00e587b3          	add	a5,a1,a4
    80000de2:	fcf578e3          	bgeu	a0,a5,80000db2 <memmove+0xa>
    d += n;
    80000de6:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000de8:	fff6069b          	addiw	a3,a2,-1
    80000dec:	d27d                	beqz	a2,80000dd2 <memmove+0x2a>
    80000dee:	02069613          	slli	a2,a3,0x20
    80000df2:	9201                	srli	a2,a2,0x20
    80000df4:	fff64613          	not	a2,a2
    80000df8:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dfa:	17fd                	addi	a5,a5,-1
    80000dfc:	177d                	addi	a4,a4,-1
    80000dfe:	0007c683          	lbu	a3,0(a5)
    80000e02:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e06:	fef61ae3          	bne	a2,a5,80000dfa <memmove+0x52>
    80000e0a:	b7e1                	j	80000dd2 <memmove+0x2a>

0000000080000e0c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e406                	sd	ra,8(sp)
    80000e10:	e022                	sd	s0,0(sp)
    80000e12:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e14:	00000097          	auipc	ra,0x0
    80000e18:	f94080e7          	jalr	-108(ra) # 80000da8 <memmove>
}
    80000e1c:	60a2                	ld	ra,8(sp)
    80000e1e:	6402                	ld	s0,0(sp)
    80000e20:	0141                	addi	sp,sp,16
    80000e22:	8082                	ret

0000000080000e24 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e2a:	ce11                	beqz	a2,80000e46 <strncmp+0x22>
    80000e2c:	00054783          	lbu	a5,0(a0)
    80000e30:	cf89                	beqz	a5,80000e4a <strncmp+0x26>
    80000e32:	0005c703          	lbu	a4,0(a1)
    80000e36:	00f71a63          	bne	a4,a5,80000e4a <strncmp+0x26>
    n--, p++, q++;
    80000e3a:	367d                	addiw	a2,a2,-1
    80000e3c:	0505                	addi	a0,a0,1
    80000e3e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e40:	f675                	bnez	a2,80000e2c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e42:	4501                	li	a0,0
    80000e44:	a809                	j	80000e56 <strncmp+0x32>
    80000e46:	4501                	li	a0,0
    80000e48:	a039                	j	80000e56 <strncmp+0x32>
  if(n == 0)
    80000e4a:	ca09                	beqz	a2,80000e5c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e4c:	00054503          	lbu	a0,0(a0)
    80000e50:	0005c783          	lbu	a5,0(a1)
    80000e54:	9d1d                	subw	a0,a0,a5
}
    80000e56:	6422                	ld	s0,8(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret
    return 0;
    80000e5c:	4501                	li	a0,0
    80000e5e:	bfe5                	j	80000e56 <strncmp+0x32>

0000000080000e60 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e60:	1141                	addi	sp,sp,-16
    80000e62:	e422                	sd	s0,8(sp)
    80000e64:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e66:	872a                	mv	a4,a0
    80000e68:	8832                	mv	a6,a2
    80000e6a:	367d                	addiw	a2,a2,-1
    80000e6c:	01005963          	blez	a6,80000e7e <strncpy+0x1e>
    80000e70:	0705                	addi	a4,a4,1
    80000e72:	0005c783          	lbu	a5,0(a1)
    80000e76:	fef70fa3          	sb	a5,-1(a4)
    80000e7a:	0585                	addi	a1,a1,1
    80000e7c:	f7f5                	bnez	a5,80000e68 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e7e:	86ba                	mv	a3,a4
    80000e80:	00c05c63          	blez	a2,80000e98 <strncpy+0x38>
    *s++ = 0;
    80000e84:	0685                	addi	a3,a3,1
    80000e86:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e8a:	fff6c793          	not	a5,a3
    80000e8e:	9fb9                	addw	a5,a5,a4
    80000e90:	010787bb          	addw	a5,a5,a6
    80000e94:	fef048e3          	bgtz	a5,80000e84 <strncpy+0x24>
  return os;
}
    80000e98:	6422                	ld	s0,8(sp)
    80000e9a:	0141                	addi	sp,sp,16
    80000e9c:	8082                	ret

0000000080000e9e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e9e:	1141                	addi	sp,sp,-16
    80000ea0:	e422                	sd	s0,8(sp)
    80000ea2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ea4:	02c05363          	blez	a2,80000eca <safestrcpy+0x2c>
    80000ea8:	fff6069b          	addiw	a3,a2,-1
    80000eac:	1682                	slli	a3,a3,0x20
    80000eae:	9281                	srli	a3,a3,0x20
    80000eb0:	96ae                	add	a3,a3,a1
    80000eb2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eb4:	00d58963          	beq	a1,a3,80000ec6 <safestrcpy+0x28>
    80000eb8:	0585                	addi	a1,a1,1
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff5c703          	lbu	a4,-1(a1)
    80000ec0:	fee78fa3          	sb	a4,-1(a5)
    80000ec4:	fb65                	bnez	a4,80000eb4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ec6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eca:	6422                	ld	s0,8(sp)
    80000ecc:	0141                	addi	sp,sp,16
    80000ece:	8082                	ret

0000000080000ed0 <strlen>:

int
strlen(const char *s)
{
    80000ed0:	1141                	addi	sp,sp,-16
    80000ed2:	e422                	sd	s0,8(sp)
    80000ed4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ed6:	00054783          	lbu	a5,0(a0)
    80000eda:	cf91                	beqz	a5,80000ef6 <strlen+0x26>
    80000edc:	0505                	addi	a0,a0,1
    80000ede:	87aa                	mv	a5,a0
    80000ee0:	4685                	li	a3,1
    80000ee2:	9e89                	subw	a3,a3,a0
    80000ee4:	00f6853b          	addw	a0,a3,a5
    80000ee8:	0785                	addi	a5,a5,1
    80000eea:	fff7c703          	lbu	a4,-1(a5)
    80000eee:	fb7d                	bnez	a4,80000ee4 <strlen+0x14>
    ;
  return n;
}
    80000ef0:	6422                	ld	s0,8(sp)
    80000ef2:	0141                	addi	sp,sp,16
    80000ef4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ef6:	4501                	li	a0,0
    80000ef8:	bfe5                	j	80000ef0 <strlen+0x20>

0000000080000efa <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000efa:	1141                	addi	sp,sp,-16
    80000efc:	e406                	sd	ra,8(sp)
    80000efe:	e022                	sd	s0,0(sp)
    80000f00:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f02:	00001097          	auipc	ra,0x1
    80000f06:	aee080e7          	jalr	-1298(ra) # 800019f0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f0a:	00008717          	auipc	a4,0x8
    80000f0e:	10270713          	addi	a4,a4,258 # 8000900c <started>
  if(cpuid() == 0){
    80000f12:	c139                	beqz	a0,80000f58 <main+0x5e>
    while(started == 0)
    80000f14:	431c                	lw	a5,0(a4)
    80000f16:	2781                	sext.w	a5,a5
    80000f18:	dff5                	beqz	a5,80000f14 <main+0x1a>
      ;
    __sync_synchronize();
    80000f1a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f1e:	00001097          	auipc	ra,0x1
    80000f22:	ad2080e7          	jalr	-1326(ra) # 800019f0 <cpuid>
    80000f26:	85aa                	mv	a1,a0
    80000f28:	00007517          	auipc	a0,0x7
    80000f2c:	19050513          	addi	a0,a0,400 # 800080b8 <digits+0x78>
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	65c080e7          	jalr	1628(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	0d8080e7          	jalr	216(ra) # 80001010 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f40:	00001097          	auipc	ra,0x1
    80000f44:	770080e7          	jalr	1904(ra) # 800026b0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	eb8080e7          	jalr	-328(ra) # 80005e00 <plicinithart>
  }

  scheduler();        
    80000f50:	00001097          	auipc	ra,0x1
    80000f54:	008080e7          	jalr	8(ra) # 80001f58 <scheduler>
    consoleinit();
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	4fc080e7          	jalr	1276(ra) # 80000454 <consoleinit>
    printfinit();
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	80c080e7          	jalr	-2036(ra) # 8000076c <printfinit>
    printf("\n");
    80000f68:	00007517          	auipc	a0,0x7
    80000f6c:	16050513          	addi	a0,a0,352 # 800080c8 <digits+0x88>
    80000f70:	fffff097          	auipc	ra,0xfffff
    80000f74:	61c080e7          	jalr	1564(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f78:	00007517          	auipc	a0,0x7
    80000f7c:	12850513          	addi	a0,a0,296 # 800080a0 <digits+0x60>
    80000f80:	fffff097          	auipc	ra,0xfffff
    80000f84:	60c080e7          	jalr	1548(ra) # 8000058c <printf>
    printf("\n");
    80000f88:	00007517          	auipc	a0,0x7
    80000f8c:	14050513          	addi	a0,a0,320 # 800080c8 <digits+0x88>
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	5fc080e7          	jalr	1532(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f98:	00000097          	auipc	ra,0x0
    80000f9c:	b3a080e7          	jalr	-1222(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000fa0:	00000097          	auipc	ra,0x0
    80000fa4:	2a0080e7          	jalr	672(ra) # 80001240 <kvminit>
    kvminithart();   // turn on paging
    80000fa8:	00000097          	auipc	ra,0x0
    80000fac:	068080e7          	jalr	104(ra) # 80001010 <kvminithart>
    procinit();      // process table
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	970080e7          	jalr	-1680(ra) # 80001920 <procinit>
    trapinit();      // trap vectors
    80000fb8:	00001097          	auipc	ra,0x1
    80000fbc:	6d0080e7          	jalr	1744(ra) # 80002688 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fc0:	00001097          	auipc	ra,0x1
    80000fc4:	6f0080e7          	jalr	1776(ra) # 800026b0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	e22080e7          	jalr	-478(ra) # 80005dea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fd0:	00005097          	auipc	ra,0x5
    80000fd4:	e30080e7          	jalr	-464(ra) # 80005e00 <plicinithart>
    binit();         // buffer cache
    80000fd8:	00002097          	auipc	ra,0x2
    80000fdc:	fd6080e7          	jalr	-42(ra) # 80002fae <binit>
    iinit();         // inode cache
    80000fe0:	00002097          	auipc	ra,0x2
    80000fe4:	666080e7          	jalr	1638(ra) # 80003646 <iinit>
    fileinit();      // file table
    80000fe8:	00003097          	auipc	ra,0x3
    80000fec:	600080e7          	jalr	1536(ra) # 800045e8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	f18080e7          	jalr	-232(ra) # 80005f08 <virtio_disk_init>
    userinit();      // first user process
    80000ff8:	00001097          	auipc	ra,0x1
    80000ffc:	cee080e7          	jalr	-786(ra) # 80001ce6 <userinit>
    __sync_synchronize();
    80001000:	0ff0000f          	fence
    started = 1;
    80001004:	4785                	li	a5,1
    80001006:	00008717          	auipc	a4,0x8
    8000100a:	00f72323          	sw	a5,6(a4) # 8000900c <started>
    8000100e:	b789                	j	80000f50 <main+0x56>

0000000080001010 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001010:	1141                	addi	sp,sp,-16
    80001012:	e422                	sd	s0,8(sp)
    80001014:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001016:	00008797          	auipc	a5,0x8
    8000101a:	ffa7b783          	ld	a5,-6(a5) # 80009010 <kernel_pagetable>
    8000101e:	83b1                	srli	a5,a5,0xc
    80001020:	577d                	li	a4,-1
    80001022:	177e                	slli	a4,a4,0x3f
    80001024:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001026:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000102a:	12000073          	sfence.vma
  sfence_vma();
}
    8000102e:	6422                	ld	s0,8(sp)
    80001030:	0141                	addi	sp,sp,16
    80001032:	8082                	ret

0000000080001034 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001034:	7139                	addi	sp,sp,-64
    80001036:	fc06                	sd	ra,56(sp)
    80001038:	f822                	sd	s0,48(sp)
    8000103a:	f426                	sd	s1,40(sp)
    8000103c:	f04a                	sd	s2,32(sp)
    8000103e:	ec4e                	sd	s3,24(sp)
    80001040:	e852                	sd	s4,16(sp)
    80001042:	e456                	sd	s5,8(sp)
    80001044:	e05a                	sd	s6,0(sp)
    80001046:	0080                	addi	s0,sp,64
    80001048:	84aa                	mv	s1,a0
    8000104a:	89ae                	mv	s3,a1
    8000104c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000104e:	57fd                	li	a5,-1
    80001050:	83e9                	srli	a5,a5,0x1a
    80001052:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001054:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001056:	04b7f263          	bgeu	a5,a1,8000109a <walk+0x66>
    panic("walk");
    8000105a:	00007517          	auipc	a0,0x7
    8000105e:	07650513          	addi	a0,a0,118 # 800080d0 <digits+0x90>
    80001062:	fffff097          	auipc	ra,0xfffff
    80001066:	4e0080e7          	jalr	1248(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000106a:	060a8663          	beqz	s5,800010d6 <walk+0xa2>
    8000106e:	00000097          	auipc	ra,0x0
    80001072:	aa0080e7          	jalr	-1376(ra) # 80000b0e <kalloc>
    80001076:	84aa                	mv	s1,a0
    80001078:	c529                	beqz	a0,800010c2 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000107a:	6605                	lui	a2,0x1
    8000107c:	4581                	li	a1,0
    8000107e:	00000097          	auipc	ra,0x0
    80001082:	cce080e7          	jalr	-818(ra) # 80000d4c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001086:	00c4d793          	srli	a5,s1,0xc
    8000108a:	07aa                	slli	a5,a5,0xa
    8000108c:	0017e793          	ori	a5,a5,1
    80001090:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001094:	3a5d                	addiw	s4,s4,-9
    80001096:	036a0063          	beq	s4,s6,800010b6 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000109a:	0149d933          	srl	s2,s3,s4
    8000109e:	1ff97913          	andi	s2,s2,511
    800010a2:	090e                	slli	s2,s2,0x3
    800010a4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a6:	00093483          	ld	s1,0(s2)
    800010aa:	0014f793          	andi	a5,s1,1
    800010ae:	dfd5                	beqz	a5,8000106a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010b0:	80a9                	srli	s1,s1,0xa
    800010b2:	04b2                	slli	s1,s1,0xc
    800010b4:	b7c5                	j	80001094 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b6:	00c9d513          	srli	a0,s3,0xc
    800010ba:	1ff57513          	andi	a0,a0,511
    800010be:	050e                	slli	a0,a0,0x3
    800010c0:	9526                	add	a0,a0,s1
}
    800010c2:	70e2                	ld	ra,56(sp)
    800010c4:	7442                	ld	s0,48(sp)
    800010c6:	74a2                	ld	s1,40(sp)
    800010c8:	7902                	ld	s2,32(sp)
    800010ca:	69e2                	ld	s3,24(sp)
    800010cc:	6a42                	ld	s4,16(sp)
    800010ce:	6aa2                	ld	s5,8(sp)
    800010d0:	6b02                	ld	s6,0(sp)
    800010d2:	6121                	addi	sp,sp,64
    800010d4:	8082                	ret
        return 0;
    800010d6:	4501                	li	a0,0
    800010d8:	b7ed                	j	800010c2 <walk+0x8e>

00000000800010da <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010da:	57fd                	li	a5,-1
    800010dc:	83e9                	srli	a5,a5,0x1a
    800010de:	00b7f463          	bgeu	a5,a1,800010e6 <walkaddr+0xc>
    return 0;
    800010e2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010e4:	8082                	ret
{
    800010e6:	1141                	addi	sp,sp,-16
    800010e8:	e406                	sd	ra,8(sp)
    800010ea:	e022                	sd	s0,0(sp)
    800010ec:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ee:	4601                	li	a2,0
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	f44080e7          	jalr	-188(ra) # 80001034 <walk>
  if(pte == 0)
    800010f8:	c105                	beqz	a0,80001118 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010fa:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010fc:	0117f693          	andi	a3,a5,17
    80001100:	4745                	li	a4,17
    return 0;
    80001102:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001104:	00e68663          	beq	a3,a4,80001110 <walkaddr+0x36>
}
    80001108:	60a2                	ld	ra,8(sp)
    8000110a:	6402                	ld	s0,0(sp)
    8000110c:	0141                	addi	sp,sp,16
    8000110e:	8082                	ret
  pa = PTE2PA(*pte);
    80001110:	00a7d513          	srli	a0,a5,0xa
    80001114:	0532                	slli	a0,a0,0xc
  return pa;
    80001116:	bfcd                	j	80001108 <walkaddr+0x2e>
    return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7fd                	j	80001108 <walkaddr+0x2e>

000000008000111c <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000111c:	1101                	addi	sp,sp,-32
    8000111e:	ec06                	sd	ra,24(sp)
    80001120:	e822                	sd	s0,16(sp)
    80001122:	e426                	sd	s1,8(sp)
    80001124:	1000                	addi	s0,sp,32
    80001126:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001128:	1552                	slli	a0,a0,0x34
    8000112a:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000112e:	4601                	li	a2,0
    80001130:	00008517          	auipc	a0,0x8
    80001134:	ee053503          	ld	a0,-288(a0) # 80009010 <kernel_pagetable>
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	efc080e7          	jalr	-260(ra) # 80001034 <walk>
  if(pte == 0)
    80001140:	cd09                	beqz	a0,8000115a <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001142:	6108                	ld	a0,0(a0)
    80001144:	00157793          	andi	a5,a0,1
    80001148:	c38d                	beqz	a5,8000116a <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000114a:	8129                	srli	a0,a0,0xa
    8000114c:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000114e:	9526                	add	a0,a0,s1
    80001150:	60e2                	ld	ra,24(sp)
    80001152:	6442                	ld	s0,16(sp)
    80001154:	64a2                	ld	s1,8(sp)
    80001156:	6105                	addi	sp,sp,32
    80001158:	8082                	ret
    panic("kvmpa");
    8000115a:	00007517          	auipc	a0,0x7
    8000115e:	f7e50513          	addi	a0,a0,-130 # 800080d8 <digits+0x98>
    80001162:	fffff097          	auipc	ra,0xfffff
    80001166:	3e0080e7          	jalr	992(ra) # 80000542 <panic>
    panic("kvmpa");
    8000116a:	00007517          	auipc	a0,0x7
    8000116e:	f6e50513          	addi	a0,a0,-146 # 800080d8 <digits+0x98>
    80001172:	fffff097          	auipc	ra,0xfffff
    80001176:	3d0080e7          	jalr	976(ra) # 80000542 <panic>

000000008000117a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000117a:	715d                	addi	sp,sp,-80
    8000117c:	e486                	sd	ra,72(sp)
    8000117e:	e0a2                	sd	s0,64(sp)
    80001180:	fc26                	sd	s1,56(sp)
    80001182:	f84a                	sd	s2,48(sp)
    80001184:	f44e                	sd	s3,40(sp)
    80001186:	f052                	sd	s4,32(sp)
    80001188:	ec56                	sd	s5,24(sp)
    8000118a:	e85a                	sd	s6,16(sp)
    8000118c:	e45e                	sd	s7,8(sp)
    8000118e:	0880                	addi	s0,sp,80
    80001190:	8aaa                	mv	s5,a0
    80001192:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001194:	777d                	lui	a4,0xfffff
    80001196:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000119a:	167d                	addi	a2,a2,-1
    8000119c:	00b609b3          	add	s3,a2,a1
    800011a0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011a4:	893e                	mv	s2,a5
    800011a6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011aa:	6b85                	lui	s7,0x1
    800011ac:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b0:	4605                	li	a2,1
    800011b2:	85ca                	mv	a1,s2
    800011b4:	8556                	mv	a0,s5
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	e7e080e7          	jalr	-386(ra) # 80001034 <walk>
    800011be:	c51d                	beqz	a0,800011ec <mappages+0x72>
    if(*pte & PTE_V)
    800011c0:	611c                	ld	a5,0(a0)
    800011c2:	8b85                	andi	a5,a5,1
    800011c4:	ef81                	bnez	a5,800011dc <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011c6:	80b1                	srli	s1,s1,0xc
    800011c8:	04aa                	slli	s1,s1,0xa
    800011ca:	0164e4b3          	or	s1,s1,s6
    800011ce:	0014e493          	ori	s1,s1,1
    800011d2:	e104                	sd	s1,0(a0)
    if(a == last)
    800011d4:	03390863          	beq	s2,s3,80001204 <mappages+0x8a>
    a += PGSIZE;
    800011d8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011da:	bfc9                	j	800011ac <mappages+0x32>
      panic("remap");
    800011dc:	00007517          	auipc	a0,0x7
    800011e0:	f0450513          	addi	a0,a0,-252 # 800080e0 <digits+0xa0>
    800011e4:	fffff097          	auipc	ra,0xfffff
    800011e8:	35e080e7          	jalr	862(ra) # 80000542 <panic>
      return -1;
    800011ec:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ee:	60a6                	ld	ra,72(sp)
    800011f0:	6406                	ld	s0,64(sp)
    800011f2:	74e2                	ld	s1,56(sp)
    800011f4:	7942                	ld	s2,48(sp)
    800011f6:	79a2                	ld	s3,40(sp)
    800011f8:	7a02                	ld	s4,32(sp)
    800011fa:	6ae2                	ld	s5,24(sp)
    800011fc:	6b42                	ld	s6,16(sp)
    800011fe:	6ba2                	ld	s7,8(sp)
    80001200:	6161                	addi	sp,sp,80
    80001202:	8082                	ret
  return 0;
    80001204:	4501                	li	a0,0
    80001206:	b7e5                	j	800011ee <mappages+0x74>

0000000080001208 <kvmmap>:
{
    80001208:	1141                	addi	sp,sp,-16
    8000120a:	e406                	sd	ra,8(sp)
    8000120c:	e022                	sd	s0,0(sp)
    8000120e:	0800                	addi	s0,sp,16
    80001210:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001212:	86ae                	mv	a3,a1
    80001214:	85aa                	mv	a1,a0
    80001216:	00008517          	auipc	a0,0x8
    8000121a:	dfa53503          	ld	a0,-518(a0) # 80009010 <kernel_pagetable>
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f5c080e7          	jalr	-164(ra) # 8000117a <mappages>
    80001226:	e509                	bnez	a0,80001230 <kvmmap+0x28>
}
    80001228:	60a2                	ld	ra,8(sp)
    8000122a:	6402                	ld	s0,0(sp)
    8000122c:	0141                	addi	sp,sp,16
    8000122e:	8082                	ret
    panic("kvmmap");
    80001230:	00007517          	auipc	a0,0x7
    80001234:	eb850513          	addi	a0,a0,-328 # 800080e8 <digits+0xa8>
    80001238:	fffff097          	auipc	ra,0xfffff
    8000123c:	30a080e7          	jalr	778(ra) # 80000542 <panic>

0000000080001240 <kvminit>:
{
    80001240:	1101                	addi	sp,sp,-32
    80001242:	ec06                	sd	ra,24(sp)
    80001244:	e822                	sd	s0,16(sp)
    80001246:	e426                	sd	s1,8(sp)
    80001248:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	8c4080e7          	jalr	-1852(ra) # 80000b0e <kalloc>
    80001252:	00008797          	auipc	a5,0x8
    80001256:	daa7bf23          	sd	a0,-578(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000125a:	6605                	lui	a2,0x1
    8000125c:	4581                	li	a1,0
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	aee080e7          	jalr	-1298(ra) # 80000d4c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	6605                	lui	a2,0x1
    8000126a:	100005b7          	lui	a1,0x10000
    8000126e:	10000537          	lui	a0,0x10000
    80001272:	00000097          	auipc	ra,0x0
    80001276:	f96080e7          	jalr	-106(ra) # 80001208 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000127a:	4699                	li	a3,6
    8000127c:	6605                	lui	a2,0x1
    8000127e:	100015b7          	lui	a1,0x10001
    80001282:	10001537          	lui	a0,0x10001
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f82080e7          	jalr	-126(ra) # 80001208 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000128e:	4699                	li	a3,6
    80001290:	6641                	lui	a2,0x10
    80001292:	020005b7          	lui	a1,0x2000
    80001296:	02000537          	lui	a0,0x2000
    8000129a:	00000097          	auipc	ra,0x0
    8000129e:	f6e080e7          	jalr	-146(ra) # 80001208 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012a2:	4699                	li	a3,6
    800012a4:	00400637          	lui	a2,0x400
    800012a8:	0c0005b7          	lui	a1,0xc000
    800012ac:	0c000537          	lui	a0,0xc000
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f58080e7          	jalr	-168(ra) # 80001208 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012b8:	00007497          	auipc	s1,0x7
    800012bc:	d4848493          	addi	s1,s1,-696 # 80008000 <etext>
    800012c0:	46a9                	li	a3,10
    800012c2:	80007617          	auipc	a2,0x80007
    800012c6:	d3e60613          	addi	a2,a2,-706 # 8000 <_entry-0x7fff8000>
    800012ca:	4585                	li	a1,1
    800012cc:	05fe                	slli	a1,a1,0x1f
    800012ce:	852e                	mv	a0,a1
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f38080e7          	jalr	-200(ra) # 80001208 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012d8:	4699                	li	a3,6
    800012da:	4645                	li	a2,17
    800012dc:	066e                	slli	a2,a2,0x1b
    800012de:	8e05                	sub	a2,a2,s1
    800012e0:	85a6                	mv	a1,s1
    800012e2:	8526                	mv	a0,s1
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f24080e7          	jalr	-220(ra) # 80001208 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012ec:	46a9                	li	a3,10
    800012ee:	6605                	lui	a2,0x1
    800012f0:	00006597          	auipc	a1,0x6
    800012f4:	d1058593          	addi	a1,a1,-752 # 80007000 <_trampoline>
    800012f8:	04000537          	lui	a0,0x4000
    800012fc:	157d                	addi	a0,a0,-1
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	00000097          	auipc	ra,0x0
    80001304:	f08080e7          	jalr	-248(ra) # 80001208 <kvmmap>
}
    80001308:	60e2                	ld	ra,24(sp)
    8000130a:	6442                	ld	s0,16(sp)
    8000130c:	64a2                	ld	s1,8(sp)
    8000130e:	6105                	addi	sp,sp,32
    80001310:	8082                	ret

0000000080001312 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001312:	715d                	addi	sp,sp,-80
    80001314:	e486                	sd	ra,72(sp)
    80001316:	e0a2                	sd	s0,64(sp)
    80001318:	fc26                	sd	s1,56(sp)
    8000131a:	f84a                	sd	s2,48(sp)
    8000131c:	f44e                	sd	s3,40(sp)
    8000131e:	f052                	sd	s4,32(sp)
    80001320:	ec56                	sd	s5,24(sp)
    80001322:	e85a                	sd	s6,16(sp)
    80001324:	e45e                	sd	s7,8(sp)
    80001326:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001328:	03459793          	slli	a5,a1,0x34
    8000132c:	e795                	bnez	a5,80001358 <uvmunmap+0x46>
    8000132e:	8a2a                	mv	s4,a0
    80001330:	892e                	mv	s2,a1
    80001332:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001334:	0632                	slli	a2,a2,0xc
    80001336:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133c:	6b05                	lui	s6,0x1
    8000133e:	0735e263          	bltu	a1,s3,800013a2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001342:	60a6                	ld	ra,72(sp)
    80001344:	6406                	ld	s0,64(sp)
    80001346:	74e2                	ld	s1,56(sp)
    80001348:	7942                	ld	s2,48(sp)
    8000134a:	79a2                	ld	s3,40(sp)
    8000134c:	7a02                	ld	s4,32(sp)
    8000134e:	6ae2                	ld	s5,24(sp)
    80001350:	6b42                	ld	s6,16(sp)
    80001352:	6ba2                	ld	s7,8(sp)
    80001354:	6161                	addi	sp,sp,80
    80001356:	8082                	ret
    panic("uvmunmap: not aligned");
    80001358:	00007517          	auipc	a0,0x7
    8000135c:	d9850513          	addi	a0,a0,-616 # 800080f0 <digits+0xb0>
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	1e2080e7          	jalr	482(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001368:	00007517          	auipc	a0,0x7
    8000136c:	da050513          	addi	a0,a0,-608 # 80008108 <digits+0xc8>
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	1d2080e7          	jalr	466(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	da050513          	addi	a0,a0,-608 # 80008118 <digits+0xd8>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	1c2080e7          	jalr	450(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	da850513          	addi	a0,a0,-600 # 80008130 <digits+0xf0>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1b2080e7          	jalr	434(ra) # 80000542 <panic>
    *pte = 0;
    80001398:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139c:	995a                	add	s2,s2,s6
    8000139e:	fb3972e3          	bgeu	s2,s3,80001342 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013a2:	4601                	li	a2,0
    800013a4:	85ca                	mv	a1,s2
    800013a6:	8552                	mv	a0,s4
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	c8c080e7          	jalr	-884(ra) # 80001034 <walk>
    800013b0:	84aa                	mv	s1,a0
    800013b2:	d95d                	beqz	a0,80001368 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013b4:	6108                	ld	a0,0(a0)
    800013b6:	00157793          	andi	a5,a0,1
    800013ba:	dfdd                	beqz	a5,80001378 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013bc:	3ff57793          	andi	a5,a0,1023
    800013c0:	fd7784e3          	beq	a5,s7,80001388 <uvmunmap+0x76>
    if(do_free){
    800013c4:	fc0a8ae3          	beqz	s5,80001398 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013c8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ca:	0532                	slli	a0,a0,0xc
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	646080e7          	jalr	1606(ra) # 80000a12 <kfree>
    800013d4:	b7d1                	j	80001398 <uvmunmap+0x86>

00000000800013d6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013d6:	1101                	addi	sp,sp,-32
    800013d8:	ec06                	sd	ra,24(sp)
    800013da:	e822                	sd	s0,16(sp)
    800013dc:	e426                	sd	s1,8(sp)
    800013de:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	72e080e7          	jalr	1838(ra) # 80000b0e <kalloc>
    800013e8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ea:	c519                	beqz	a0,800013f8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013ec:	6605                	lui	a2,0x1
    800013ee:	4581                	li	a1,0
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	95c080e7          	jalr	-1700(ra) # 80000d4c <memset>
  return pagetable;
}
    800013f8:	8526                	mv	a0,s1
    800013fa:	60e2                	ld	ra,24(sp)
    800013fc:	6442                	ld	s0,16(sp)
    800013fe:	64a2                	ld	s1,8(sp)
    80001400:	6105                	addi	sp,sp,32
    80001402:	8082                	ret

0000000080001404 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001404:	7179                	addi	sp,sp,-48
    80001406:	f406                	sd	ra,40(sp)
    80001408:	f022                	sd	s0,32(sp)
    8000140a:	ec26                	sd	s1,24(sp)
    8000140c:	e84a                	sd	s2,16(sp)
    8000140e:	e44e                	sd	s3,8(sp)
    80001410:	e052                	sd	s4,0(sp)
    80001412:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001414:	6785                	lui	a5,0x1
    80001416:	04f67863          	bgeu	a2,a5,80001466 <uvminit+0x62>
    8000141a:	8a2a                	mv	s4,a0
    8000141c:	89ae                	mv	s3,a1
    8000141e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	6ee080e7          	jalr	1774(ra) # 80000b0e <kalloc>
    80001428:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000142a:	6605                	lui	a2,0x1
    8000142c:	4581                	li	a1,0
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	91e080e7          	jalr	-1762(ra) # 80000d4c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001436:	4779                	li	a4,30
    80001438:	86ca                	mv	a3,s2
    8000143a:	6605                	lui	a2,0x1
    8000143c:	4581                	li	a1,0
    8000143e:	8552                	mv	a0,s4
    80001440:	00000097          	auipc	ra,0x0
    80001444:	d3a080e7          	jalr	-710(ra) # 8000117a <mappages>
  memmove(mem, src, sz);
    80001448:	8626                	mv	a2,s1
    8000144a:	85ce                	mv	a1,s3
    8000144c:	854a                	mv	a0,s2
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	95a080e7          	jalr	-1702(ra) # 80000da8 <memmove>
}
    80001456:	70a2                	ld	ra,40(sp)
    80001458:	7402                	ld	s0,32(sp)
    8000145a:	64e2                	ld	s1,24(sp)
    8000145c:	6942                	ld	s2,16(sp)
    8000145e:	69a2                	ld	s3,8(sp)
    80001460:	6a02                	ld	s4,0(sp)
    80001462:	6145                	addi	sp,sp,48
    80001464:	8082                	ret
    panic("inituvm: more than a page");
    80001466:	00007517          	auipc	a0,0x7
    8000146a:	ce250513          	addi	a0,a0,-798 # 80008148 <digits+0x108>
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	0d4080e7          	jalr	212(ra) # 80000542 <panic>

0000000080001476 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001476:	1101                	addi	sp,sp,-32
    80001478:	ec06                	sd	ra,24(sp)
    8000147a:	e822                	sd	s0,16(sp)
    8000147c:	e426                	sd	s1,8(sp)
    8000147e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001480:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001482:	00b67d63          	bgeu	a2,a1,8000149c <uvmdealloc+0x26>
    80001486:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001488:	6785                	lui	a5,0x1
    8000148a:	17fd                	addi	a5,a5,-1
    8000148c:	00f60733          	add	a4,a2,a5
    80001490:	767d                	lui	a2,0xfffff
    80001492:	8f71                	and	a4,a4,a2
    80001494:	97ae                	add	a5,a5,a1
    80001496:	8ff1                	and	a5,a5,a2
    80001498:	00f76863          	bltu	a4,a5,800014a8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000149c:	8526                	mv	a0,s1
    8000149e:	60e2                	ld	ra,24(sp)
    800014a0:	6442                	ld	s0,16(sp)
    800014a2:	64a2                	ld	s1,8(sp)
    800014a4:	6105                	addi	sp,sp,32
    800014a6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014a8:	8f99                	sub	a5,a5,a4
    800014aa:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ac:	4685                	li	a3,1
    800014ae:	0007861b          	sext.w	a2,a5
    800014b2:	85ba                	mv	a1,a4
    800014b4:	00000097          	auipc	ra,0x0
    800014b8:	e5e080e7          	jalr	-418(ra) # 80001312 <uvmunmap>
    800014bc:	b7c5                	j	8000149c <uvmdealloc+0x26>

00000000800014be <uvmalloc>:
  if(newsz < oldsz)
    800014be:	0ab66163          	bltu	a2,a1,80001560 <uvmalloc+0xa2>
{
    800014c2:	7139                	addi	sp,sp,-64
    800014c4:	fc06                	sd	ra,56(sp)
    800014c6:	f822                	sd	s0,48(sp)
    800014c8:	f426                	sd	s1,40(sp)
    800014ca:	f04a                	sd	s2,32(sp)
    800014cc:	ec4e                	sd	s3,24(sp)
    800014ce:	e852                	sd	s4,16(sp)
    800014d0:	e456                	sd	s5,8(sp)
    800014d2:	0080                	addi	s0,sp,64
    800014d4:	8aaa                	mv	s5,a0
    800014d6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014d8:	6985                	lui	s3,0x1
    800014da:	19fd                	addi	s3,s3,-1
    800014dc:	95ce                	add	a1,a1,s3
    800014de:	79fd                	lui	s3,0xfffff
    800014e0:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e4:	08c9f063          	bgeu	s3,a2,80001564 <uvmalloc+0xa6>
    800014e8:	894e                	mv	s2,s3
    mem = kalloc();
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	624080e7          	jalr	1572(ra) # 80000b0e <kalloc>
    800014f2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014f4:	c51d                	beqz	a0,80001522 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014f6:	6605                	lui	a2,0x1
    800014f8:	4581                	li	a1,0
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	852080e7          	jalr	-1966(ra) # 80000d4c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001502:	4779                	li	a4,30
    80001504:	86a6                	mv	a3,s1
    80001506:	6605                	lui	a2,0x1
    80001508:	85ca                	mv	a1,s2
    8000150a:	8556                	mv	a0,s5
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	c6e080e7          	jalr	-914(ra) # 8000117a <mappages>
    80001514:	e905                	bnez	a0,80001544 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001516:	6785                	lui	a5,0x1
    80001518:	993e                	add	s2,s2,a5
    8000151a:	fd4968e3          	bltu	s2,s4,800014ea <uvmalloc+0x2c>
  return newsz;
    8000151e:	8552                	mv	a0,s4
    80001520:	a809                	j	80001532 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001522:	864e                	mv	a2,s3
    80001524:	85ca                	mv	a1,s2
    80001526:	8556                	mv	a0,s5
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f4e080e7          	jalr	-178(ra) # 80001476 <uvmdealloc>
      return 0;
    80001530:	4501                	li	a0,0
}
    80001532:	70e2                	ld	ra,56(sp)
    80001534:	7442                	ld	s0,48(sp)
    80001536:	74a2                	ld	s1,40(sp)
    80001538:	7902                	ld	s2,32(sp)
    8000153a:	69e2                	ld	s3,24(sp)
    8000153c:	6a42                	ld	s4,16(sp)
    8000153e:	6aa2                	ld	s5,8(sp)
    80001540:	6121                	addi	sp,sp,64
    80001542:	8082                	ret
      kfree(mem);
    80001544:	8526                	mv	a0,s1
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	4cc080e7          	jalr	1228(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000154e:	864e                	mv	a2,s3
    80001550:	85ca                	mv	a1,s2
    80001552:	8556                	mv	a0,s5
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f22080e7          	jalr	-222(ra) # 80001476 <uvmdealloc>
      return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfd1                	j	80001532 <uvmalloc+0x74>
    return oldsz;
    80001560:	852e                	mv	a0,a1
}
    80001562:	8082                	ret
  return newsz;
    80001564:	8532                	mv	a0,a2
    80001566:	b7f1                	j	80001532 <uvmalloc+0x74>

0000000080001568 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001568:	7179                	addi	sp,sp,-48
    8000156a:	f406                	sd	ra,40(sp)
    8000156c:	f022                	sd	s0,32(sp)
    8000156e:	ec26                	sd	s1,24(sp)
    80001570:	e84a                	sd	s2,16(sp)
    80001572:	e44e                	sd	s3,8(sp)
    80001574:	e052                	sd	s4,0(sp)
    80001576:	1800                	addi	s0,sp,48
    80001578:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000157a:	84aa                	mv	s1,a0
    8000157c:	6905                	lui	s2,0x1
    8000157e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001580:	4985                	li	s3,1
    80001582:	a821                	j	8000159a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001584:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001586:	0532                	slli	a0,a0,0xc
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	fe0080e7          	jalr	-32(ra) # 80001568 <freewalk>
      pagetable[i] = 0;
    80001590:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001594:	04a1                	addi	s1,s1,8
    80001596:	03248163          	beq	s1,s2,800015b8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000159a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000159c:	00f57793          	andi	a5,a0,15
    800015a0:	ff3782e3          	beq	a5,s3,80001584 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015a4:	8905                	andi	a0,a0,1
    800015a6:	d57d                	beqz	a0,80001594 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015a8:	00007517          	auipc	a0,0x7
    800015ac:	bc050513          	addi	a0,a0,-1088 # 80008168 <digits+0x128>
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	f92080e7          	jalr	-110(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800015b8:	8552                	mv	a0,s4
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	458080e7          	jalr	1112(ra) # 80000a12 <kfree>
}
    800015c2:	70a2                	ld	ra,40(sp)
    800015c4:	7402                	ld	s0,32(sp)
    800015c6:	64e2                	ld	s1,24(sp)
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	69a2                	ld	s3,8(sp)
    800015cc:	6a02                	ld	s4,0(sp)
    800015ce:	6145                	addi	sp,sp,48
    800015d0:	8082                	ret

00000000800015d2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015d2:	1101                	addi	sp,sp,-32
    800015d4:	ec06                	sd	ra,24(sp)
    800015d6:	e822                	sd	s0,16(sp)
    800015d8:	e426                	sd	s1,8(sp)
    800015da:	1000                	addi	s0,sp,32
    800015dc:	84aa                	mv	s1,a0
  if(sz > 0)
    800015de:	e999                	bnez	a1,800015f4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015e0:	8526                	mv	a0,s1
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	f86080e7          	jalr	-122(ra) # 80001568 <freewalk>
}
    800015ea:	60e2                	ld	ra,24(sp)
    800015ec:	6442                	ld	s0,16(sp)
    800015ee:	64a2                	ld	s1,8(sp)
    800015f0:	6105                	addi	sp,sp,32
    800015f2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015f4:	6605                	lui	a2,0x1
    800015f6:	167d                	addi	a2,a2,-1
    800015f8:	962e                	add	a2,a2,a1
    800015fa:	4685                	li	a3,1
    800015fc:	8231                	srli	a2,a2,0xc
    800015fe:	4581                	li	a1,0
    80001600:	00000097          	auipc	ra,0x0
    80001604:	d12080e7          	jalr	-750(ra) # 80001312 <uvmunmap>
    80001608:	bfe1                	j	800015e0 <uvmfree+0xe>

000000008000160a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000160a:	c679                	beqz	a2,800016d8 <uvmcopy+0xce>
{
    8000160c:	715d                	addi	sp,sp,-80
    8000160e:	e486                	sd	ra,72(sp)
    80001610:	e0a2                	sd	s0,64(sp)
    80001612:	fc26                	sd	s1,56(sp)
    80001614:	f84a                	sd	s2,48(sp)
    80001616:	f44e                	sd	s3,40(sp)
    80001618:	f052                	sd	s4,32(sp)
    8000161a:	ec56                	sd	s5,24(sp)
    8000161c:	e85a                	sd	s6,16(sp)
    8000161e:	e45e                	sd	s7,8(sp)
    80001620:	0880                	addi	s0,sp,80
    80001622:	8b2a                	mv	s6,a0
    80001624:	8aae                	mv	s5,a1
    80001626:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001628:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000162a:	4601                	li	a2,0
    8000162c:	85ce                	mv	a1,s3
    8000162e:	855a                	mv	a0,s6
    80001630:	00000097          	auipc	ra,0x0
    80001634:	a04080e7          	jalr	-1532(ra) # 80001034 <walk>
    80001638:	c531                	beqz	a0,80001684 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000163a:	6118                	ld	a4,0(a0)
    8000163c:	00177793          	andi	a5,a4,1
    80001640:	cbb1                	beqz	a5,80001694 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001642:	00a75593          	srli	a1,a4,0xa
    80001646:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000164a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	4c0080e7          	jalr	1216(ra) # 80000b0e <kalloc>
    80001656:	892a                	mv	s2,a0
    80001658:	c939                	beqz	a0,800016ae <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000165a:	6605                	lui	a2,0x1
    8000165c:	85de                	mv	a1,s7
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	74a080e7          	jalr	1866(ra) # 80000da8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001666:	8726                	mv	a4,s1
    80001668:	86ca                	mv	a3,s2
    8000166a:	6605                	lui	a2,0x1
    8000166c:	85ce                	mv	a1,s3
    8000166e:	8556                	mv	a0,s5
    80001670:	00000097          	auipc	ra,0x0
    80001674:	b0a080e7          	jalr	-1270(ra) # 8000117a <mappages>
    80001678:	e515                	bnez	a0,800016a4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000167a:	6785                	lui	a5,0x1
    8000167c:	99be                	add	s3,s3,a5
    8000167e:	fb49e6e3          	bltu	s3,s4,8000162a <uvmcopy+0x20>
    80001682:	a081                	j	800016c2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001684:	00007517          	auipc	a0,0x7
    80001688:	af450513          	addi	a0,a0,-1292 # 80008178 <digits+0x138>
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	eb6080e7          	jalr	-330(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b0450513          	addi	a0,a0,-1276 # 80008198 <digits+0x158>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	ea6080e7          	jalr	-346(ra) # 80000542 <panic>
      kfree(mem);
    800016a4:	854a                	mv	a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	36c080e7          	jalr	876(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ae:	4685                	li	a3,1
    800016b0:	00c9d613          	srli	a2,s3,0xc
    800016b4:	4581                	li	a1,0
    800016b6:	8556                	mv	a0,s5
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	c5a080e7          	jalr	-934(ra) # 80001312 <uvmunmap>
  return -1;
    800016c0:	557d                	li	a0,-1
}
    800016c2:	60a6                	ld	ra,72(sp)
    800016c4:	6406                	ld	s0,64(sp)
    800016c6:	74e2                	ld	s1,56(sp)
    800016c8:	7942                	ld	s2,48(sp)
    800016ca:	79a2                	ld	s3,40(sp)
    800016cc:	7a02                	ld	s4,32(sp)
    800016ce:	6ae2                	ld	s5,24(sp)
    800016d0:	6b42                	ld	s6,16(sp)
    800016d2:	6ba2                	ld	s7,8(sp)
    800016d4:	6161                	addi	sp,sp,80
    800016d6:	8082                	ret
  return 0;
    800016d8:	4501                	li	a0,0
}
    800016da:	8082                	ret

00000000800016dc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016dc:	1141                	addi	sp,sp,-16
    800016de:	e406                	sd	ra,8(sp)
    800016e0:	e022                	sd	s0,0(sp)
    800016e2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016e4:	4601                	li	a2,0
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	94e080e7          	jalr	-1714(ra) # 80001034 <walk>
  if(pte == 0)
    800016ee:	c901                	beqz	a0,800016fe <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016f0:	611c                	ld	a5,0(a0)
    800016f2:	9bbd                	andi	a5,a5,-17
    800016f4:	e11c                	sd	a5,0(a0)
}
    800016f6:	60a2                	ld	ra,8(sp)
    800016f8:	6402                	ld	s0,0(sp)
    800016fa:	0141                	addi	sp,sp,16
    800016fc:	8082                	ret
    panic("uvmclear");
    800016fe:	00007517          	auipc	a0,0x7
    80001702:	aba50513          	addi	a0,a0,-1350 # 800081b8 <digits+0x178>
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	e3c080e7          	jalr	-452(ra) # 80000542 <panic>

000000008000170e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170e:	c6bd                	beqz	a3,8000177c <copyout+0x6e>
{
    80001710:	715d                	addi	sp,sp,-80
    80001712:	e486                	sd	ra,72(sp)
    80001714:	e0a2                	sd	s0,64(sp)
    80001716:	fc26                	sd	s1,56(sp)
    80001718:	f84a                	sd	s2,48(sp)
    8000171a:	f44e                	sd	s3,40(sp)
    8000171c:	f052                	sd	s4,32(sp)
    8000171e:	ec56                	sd	s5,24(sp)
    80001720:	e85a                	sd	s6,16(sp)
    80001722:	e45e                	sd	s7,8(sp)
    80001724:	e062                	sd	s8,0(sp)
    80001726:	0880                	addi	s0,sp,80
    80001728:	8b2a                	mv	s6,a0
    8000172a:	8c2e                	mv	s8,a1
    8000172c:	8a32                	mv	s4,a2
    8000172e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001730:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001732:	6a85                	lui	s5,0x1
    80001734:	a015                	j	80001758 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001736:	9562                	add	a0,a0,s8
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	85d2                	mv	a1,s4
    8000173e:	41250533          	sub	a0,a0,s2
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	666080e7          	jalr	1638(ra) # 80000da8 <memmove>

    len -= n;
    8000174a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000174e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001750:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001754:	02098263          	beqz	s3,80001778 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001758:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175c:	85ca                	mv	a1,s2
    8000175e:	855a                	mv	a0,s6
    80001760:	00000097          	auipc	ra,0x0
    80001764:	97a080e7          	jalr	-1670(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    80001768:	cd01                	beqz	a0,80001780 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000176a:	418904b3          	sub	s1,s2,s8
    8000176e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001770:	fc99f3e3          	bgeu	s3,s1,80001736 <copyout+0x28>
    80001774:	84ce                	mv	s1,s3
    80001776:	b7c1                	j	80001736 <copyout+0x28>
  }
  return 0;
    80001778:	4501                	li	a0,0
    8000177a:	a021                	j	80001782 <copyout+0x74>
    8000177c:	4501                	li	a0,0
}
    8000177e:	8082                	ret
      return -1;
    80001780:	557d                	li	a0,-1
}
    80001782:	60a6                	ld	ra,72(sp)
    80001784:	6406                	ld	s0,64(sp)
    80001786:	74e2                	ld	s1,56(sp)
    80001788:	7942                	ld	s2,48(sp)
    8000178a:	79a2                	ld	s3,40(sp)
    8000178c:	7a02                	ld	s4,32(sp)
    8000178e:	6ae2                	ld	s5,24(sp)
    80001790:	6b42                	ld	s6,16(sp)
    80001792:	6ba2                	ld	s7,8(sp)
    80001794:	6c02                	ld	s8,0(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret

000000008000179a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000179a:	caa5                	beqz	a3,8000180a <copyin+0x70>
{
    8000179c:	715d                	addi	sp,sp,-80
    8000179e:	e486                	sd	ra,72(sp)
    800017a0:	e0a2                	sd	s0,64(sp)
    800017a2:	fc26                	sd	s1,56(sp)
    800017a4:	f84a                	sd	s2,48(sp)
    800017a6:	f44e                	sd	s3,40(sp)
    800017a8:	f052                	sd	s4,32(sp)
    800017aa:	ec56                	sd	s5,24(sp)
    800017ac:	e85a                	sd	s6,16(sp)
    800017ae:	e45e                	sd	s7,8(sp)
    800017b0:	e062                	sd	s8,0(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8b2a                	mv	s6,a0
    800017b6:	8a2e                	mv	s4,a1
    800017b8:	8c32                	mv	s8,a2
    800017ba:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6a85                	lui	s5,0x1
    800017c0:	a01d                	j	800017e6 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017c2:	018505b3          	add	a1,a0,s8
    800017c6:	0004861b          	sext.w	a2,s1
    800017ca:	412585b3          	sub	a1,a1,s2
    800017ce:	8552                	mv	a0,s4
    800017d0:	fffff097          	auipc	ra,0xfffff
    800017d4:	5d8080e7          	jalr	1496(ra) # 80000da8 <memmove>

    len -= n;
    800017d8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017dc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017de:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017e2:	02098263          	beqz	s3,80001806 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017e6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017ea:	85ca                	mv	a1,s2
    800017ec:	855a                	mv	a0,s6
    800017ee:	00000097          	auipc	ra,0x0
    800017f2:	8ec080e7          	jalr	-1812(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    800017f6:	cd01                	beqz	a0,8000180e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017f8:	418904b3          	sub	s1,s2,s8
    800017fc:	94d6                	add	s1,s1,s5
    if(n > len)
    800017fe:	fc99f2e3          	bgeu	s3,s1,800017c2 <copyin+0x28>
    80001802:	84ce                	mv	s1,s3
    80001804:	bf7d                	j	800017c2 <copyin+0x28>
  }
  return 0;
    80001806:	4501                	li	a0,0
    80001808:	a021                	j	80001810 <copyin+0x76>
    8000180a:	4501                	li	a0,0
}
    8000180c:	8082                	ret
      return -1;
    8000180e:	557d                	li	a0,-1
}
    80001810:	60a6                	ld	ra,72(sp)
    80001812:	6406                	ld	s0,64(sp)
    80001814:	74e2                	ld	s1,56(sp)
    80001816:	7942                	ld	s2,48(sp)
    80001818:	79a2                	ld	s3,40(sp)
    8000181a:	7a02                	ld	s4,32(sp)
    8000181c:	6ae2                	ld	s5,24(sp)
    8000181e:	6b42                	ld	s6,16(sp)
    80001820:	6ba2                	ld	s7,8(sp)
    80001822:	6c02                	ld	s8,0(sp)
    80001824:	6161                	addi	sp,sp,80
    80001826:	8082                	ret

0000000080001828 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001828:	c6c5                	beqz	a3,800018d0 <copyinstr+0xa8>
{
    8000182a:	715d                	addi	sp,sp,-80
    8000182c:	e486                	sd	ra,72(sp)
    8000182e:	e0a2                	sd	s0,64(sp)
    80001830:	fc26                	sd	s1,56(sp)
    80001832:	f84a                	sd	s2,48(sp)
    80001834:	f44e                	sd	s3,40(sp)
    80001836:	f052                	sd	s4,32(sp)
    80001838:	ec56                	sd	s5,24(sp)
    8000183a:	e85a                	sd	s6,16(sp)
    8000183c:	e45e                	sd	s7,8(sp)
    8000183e:	0880                	addi	s0,sp,80
    80001840:	8a2a                	mv	s4,a0
    80001842:	8b2e                	mv	s6,a1
    80001844:	8bb2                	mv	s7,a2
    80001846:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001848:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000184a:	6985                	lui	s3,0x1
    8000184c:	a035                	j	80001878 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000184e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001852:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001854:	0017b793          	seqz	a5,a5
    80001858:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000185c:	60a6                	ld	ra,72(sp)
    8000185e:	6406                	ld	s0,64(sp)
    80001860:	74e2                	ld	s1,56(sp)
    80001862:	7942                	ld	s2,48(sp)
    80001864:	79a2                	ld	s3,40(sp)
    80001866:	7a02                	ld	s4,32(sp)
    80001868:	6ae2                	ld	s5,24(sp)
    8000186a:	6b42                	ld	s6,16(sp)
    8000186c:	6ba2                	ld	s7,8(sp)
    8000186e:	6161                	addi	sp,sp,80
    80001870:	8082                	ret
    srcva = va0 + PGSIZE;
    80001872:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001876:	c8a9                	beqz	s1,800018c8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001878:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000187c:	85ca                	mv	a1,s2
    8000187e:	8552                	mv	a0,s4
    80001880:	00000097          	auipc	ra,0x0
    80001884:	85a080e7          	jalr	-1958(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    80001888:	c131                	beqz	a0,800018cc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000188a:	41790833          	sub	a6,s2,s7
    8000188e:	984e                	add	a6,a6,s3
    if(n > max)
    80001890:	0104f363          	bgeu	s1,a6,80001896 <copyinstr+0x6e>
    80001894:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001896:	955e                	add	a0,a0,s7
    80001898:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000189c:	fc080be3          	beqz	a6,80001872 <copyinstr+0x4a>
    800018a0:	985a                	add	a6,a6,s6
    800018a2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018a4:	41650633          	sub	a2,a0,s6
    800018a8:	14fd                	addi	s1,s1,-1
    800018aa:	9b26                	add	s6,s6,s1
    800018ac:	00f60733          	add	a4,a2,a5
    800018b0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018b4:	df49                	beqz	a4,8000184e <copyinstr+0x26>
        *dst = *p;
    800018b6:	00e78023          	sb	a4,0(a5)
      --max;
    800018ba:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018be:	0785                	addi	a5,a5,1
    while(n > 0){
    800018c0:	ff0796e3          	bne	a5,a6,800018ac <copyinstr+0x84>
      dst++;
    800018c4:	8b42                	mv	s6,a6
    800018c6:	b775                	j	80001872 <copyinstr+0x4a>
    800018c8:	4781                	li	a5,0
    800018ca:	b769                	j	80001854 <copyinstr+0x2c>
      return -1;
    800018cc:	557d                	li	a0,-1
    800018ce:	b779                	j	8000185c <copyinstr+0x34>
  int got_null = 0;
    800018d0:	4781                	li	a5,0
  if(got_null){
    800018d2:	0017b793          	seqz	a5,a5
    800018d6:	40f00533          	neg	a0,a5
}
    800018da:	8082                	ret

00000000800018dc <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018dc:	1101                	addi	sp,sp,-32
    800018de:	ec06                	sd	ra,24(sp)
    800018e0:	e822                	sd	s0,16(sp)
    800018e2:	e426                	sd	s1,8(sp)
    800018e4:	1000                	addi	s0,sp,32
    800018e6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	2ee080e7          	jalr	750(ra) # 80000bd6 <holding>
    800018f0:	c909                	beqz	a0,80001902 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018f2:	749c                	ld	a5,40(s1)
    800018f4:	00978f63          	beq	a5,s1,80001912 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018f8:	60e2                	ld	ra,24(sp)
    800018fa:	6442                	ld	s0,16(sp)
    800018fc:	64a2                	ld	s1,8(sp)
    800018fe:	6105                	addi	sp,sp,32
    80001900:	8082                	ret
    panic("wakeup1");
    80001902:	00007517          	auipc	a0,0x7
    80001906:	8c650513          	addi	a0,a0,-1850 # 800081c8 <digits+0x188>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	c38080e7          	jalr	-968(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001912:	4cd8                	lw	a4,28(s1)
    80001914:	4785                	li	a5,1
    80001916:	fef711e3          	bne	a4,a5,800018f8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000191a:	4789                	li	a5,2
    8000191c:	ccdc                	sw	a5,28(s1)
}
    8000191e:	bfe9                	j	800018f8 <wakeup1+0x1c>

0000000080001920 <procinit>:
{
    80001920:	715d                	addi	sp,sp,-80
    80001922:	e486                	sd	ra,72(sp)
    80001924:	e0a2                	sd	s0,64(sp)
    80001926:	fc26                	sd	s1,56(sp)
    80001928:	f84a                	sd	s2,48(sp)
    8000192a:	f44e                	sd	s3,40(sp)
    8000192c:	f052                	sd	s4,32(sp)
    8000192e:	ec56                	sd	s5,24(sp)
    80001930:	e85a                	sd	s6,16(sp)
    80001932:	e45e                	sd	s7,8(sp)
    80001934:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001936:	00007597          	auipc	a1,0x7
    8000193a:	89a58593          	addi	a1,a1,-1894 # 800081d0 <digits+0x190>
    8000193e:	00010517          	auipc	a0,0x10
    80001942:	01250513          	addi	a0,a0,18 # 80011950 <pid_lock>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	27a080e7          	jalr	634(ra) # 80000bc0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00010917          	auipc	s2,0x10
    80001952:	41a90913          	addi	s2,s2,1050 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001956:	00007b97          	auipc	s7,0x7
    8000195a:	882b8b93          	addi	s7,s7,-1918 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000195e:	8b4a                	mv	s6,s2
    80001960:	00006a97          	auipc	s5,0x6
    80001964:	6a0a8a93          	addi	s5,s5,1696 # 80008000 <etext>
    80001968:	040009b7          	lui	s3,0x4000
    8000196c:	19fd                	addi	s3,s3,-1
    8000196e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	00016a17          	auipc	s4,0x16
    80001974:	df8a0a13          	addi	s4,s4,-520 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001978:	85de                	mv	a1,s7
    8000197a:	854a                	mv	a0,s2
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	244080e7          	jalr	580(ra) # 80000bc0 <initlock>
      char *pa = kalloc();
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	18a080e7          	jalr	394(ra) # 80000b0e <kalloc>
    8000198c:	85aa                	mv	a1,a0
      if(pa == 0)
    8000198e:	c929                	beqz	a0,800019e0 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001990:	416904b3          	sub	s1,s2,s6
    80001994:	848d                	srai	s1,s1,0x3
    80001996:	000ab783          	ld	a5,0(s5)
    8000199a:	02f484b3          	mul	s1,s1,a5
    8000199e:	2485                	addiw	s1,s1,1
    800019a0:	00d4949b          	slliw	s1,s1,0xd
    800019a4:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019a8:	4699                	li	a3,6
    800019aa:	6605                	lui	a2,0x1
    800019ac:	8526                	mv	a0,s1
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	85a080e7          	jalr	-1958(ra) # 80001208 <kvmmap>
      p->kstack = va;
    800019b6:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	16890913          	addi	s2,s2,360
    800019be:	fb491de3          	bne	s2,s4,80001978 <procinit+0x58>
  kvminithart();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	64e080e7          	jalr	1614(ra) # 80001010 <kvminithart>
}
    800019ca:	60a6                	ld	ra,72(sp)
    800019cc:	6406                	ld	s0,64(sp)
    800019ce:	74e2                	ld	s1,56(sp)
    800019d0:	7942                	ld	s2,48(sp)
    800019d2:	79a2                	ld	s3,40(sp)
    800019d4:	7a02                	ld	s4,32(sp)
    800019d6:	6ae2                	ld	s5,24(sp)
    800019d8:	6b42                	ld	s6,16(sp)
    800019da:	6ba2                	ld	s7,8(sp)
    800019dc:	6161                	addi	sp,sp,80
    800019de:	8082                	ret
        panic("kalloc");
    800019e0:	00007517          	auipc	a0,0x7
    800019e4:	80050513          	addi	a0,a0,-2048 # 800081e0 <digits+0x1a0>
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	b5a080e7          	jalr	-1190(ra) # 80000542 <panic>

00000000800019f0 <cpuid>:
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e422                	sd	s0,8(sp)
    800019f4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f6:	8512                	mv	a0,tp
}
    800019f8:	2501                	sext.w	a0,a0
    800019fa:	6422                	ld	s0,8(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret

0000000080001a00 <mycpu>:
mycpu(void) {
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e422                	sd	s0,8(sp)
    80001a04:	0800                	addi	s0,sp,16
    80001a06:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a08:	2781                	sext.w	a5,a5
    80001a0a:	079e                	slli	a5,a5,0x7
}
    80001a0c:	00010517          	auipc	a0,0x10
    80001a10:	f5c50513          	addi	a0,a0,-164 # 80011968 <cpus>
    80001a14:	953e                	add	a0,a0,a5
    80001a16:	6422                	ld	s0,8(sp)
    80001a18:	0141                	addi	sp,sp,16
    80001a1a:	8082                	ret

0000000080001a1c <myproc>:
myproc(void) {
    80001a1c:	1101                	addi	sp,sp,-32
    80001a1e:	ec06                	sd	ra,24(sp)
    80001a20:	e822                	sd	s0,16(sp)
    80001a22:	e426                	sd	s1,8(sp)
    80001a24:	1000                	addi	s0,sp,32
  push_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	1de080e7          	jalr	478(ra) # 80000c04 <push_off>
    80001a2e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a30:	2781                	sext.w	a5,a5
    80001a32:	079e                	slli	a5,a5,0x7
    80001a34:	00010717          	auipc	a4,0x10
    80001a38:	f1c70713          	addi	a4,a4,-228 # 80011950 <pid_lock>
    80001a3c:	97ba                	add	a5,a5,a4
    80001a3e:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	264080e7          	jalr	612(ra) # 80000ca4 <pop_off>
}
    80001a48:	8526                	mv	a0,s1
    80001a4a:	60e2                	ld	ra,24(sp)
    80001a4c:	6442                	ld	s0,16(sp)
    80001a4e:	64a2                	ld	s1,8(sp)
    80001a50:	6105                	addi	sp,sp,32
    80001a52:	8082                	ret

0000000080001a54 <forkret>:
{
    80001a54:	1141                	addi	sp,sp,-16
    80001a56:	e406                	sd	ra,8(sp)
    80001a58:	e022                	sd	s0,0(sp)
    80001a5a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a5c:	00000097          	auipc	ra,0x0
    80001a60:	fc0080e7          	jalr	-64(ra) # 80001a1c <myproc>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	2a0080e7          	jalr	672(ra) # 80000d04 <release>
  if (first) {
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	fc47a783          	lw	a5,-60(a5) # 80008a30 <first.1>
    80001a74:	eb89                	bnez	a5,80001a86 <forkret+0x32>
  usertrapret();
    80001a76:	00001097          	auipc	ra,0x1
    80001a7a:	c52080e7          	jalr	-942(ra) # 800026c8 <usertrapret>
}
    80001a7e:	60a2                	ld	ra,8(sp)
    80001a80:	6402                	ld	s0,0(sp)
    80001a82:	0141                	addi	sp,sp,16
    80001a84:	8082                	ret
    first = 0;
    80001a86:	00007797          	auipc	a5,0x7
    80001a8a:	fa07a523          	sw	zero,-86(a5) # 80008a30 <first.1>
    fsinit(ROOTDEV);
    80001a8e:	4505                	li	a0,1
    80001a90:	00002097          	auipc	ra,0x2
    80001a94:	b36080e7          	jalr	-1226(ra) # 800035c6 <fsinit>
    80001a98:	bff9                	j	80001a76 <forkret+0x22>

0000000080001a9a <allocpid>:
allocpid() {
    80001a9a:	1101                	addi	sp,sp,-32
    80001a9c:	ec06                	sd	ra,24(sp)
    80001a9e:	e822                	sd	s0,16(sp)
    80001aa0:	e426                	sd	s1,8(sp)
    80001aa2:	e04a                	sd	s2,0(sp)
    80001aa4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aa6:	00010917          	auipc	s2,0x10
    80001aaa:	eaa90913          	addi	s2,s2,-342 # 80011950 <pid_lock>
    80001aae:	854a                	mv	a0,s2
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	1a0080e7          	jalr	416(ra) # 80000c50 <acquire>
  pid = nextpid;
    80001ab8:	00007797          	auipc	a5,0x7
    80001abc:	f7c78793          	addi	a5,a5,-132 # 80008a34 <nextpid>
    80001ac0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ac2:	0014871b          	addiw	a4,s1,1
    80001ac6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ac8:	854a                	mv	a0,s2
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	23a080e7          	jalr	570(ra) # 80000d04 <release>
}
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	60e2                	ld	ra,24(sp)
    80001ad6:	6442                	ld	s0,16(sp)
    80001ad8:	64a2                	ld	s1,8(sp)
    80001ada:	6902                	ld	s2,0(sp)
    80001adc:	6105                	addi	sp,sp,32
    80001ade:	8082                	ret

0000000080001ae0 <proc_pagetable>:
{
    80001ae0:	1101                	addi	sp,sp,-32
    80001ae2:	ec06                	sd	ra,24(sp)
    80001ae4:	e822                	sd	s0,16(sp)
    80001ae6:	e426                	sd	s1,8(sp)
    80001ae8:	e04a                	sd	s2,0(sp)
    80001aea:	1000                	addi	s0,sp,32
    80001aec:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	8e8080e7          	jalr	-1816(ra) # 800013d6 <uvmcreate>
    80001af6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001af8:	c121                	beqz	a0,80001b38 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001afa:	4729                	li	a4,10
    80001afc:	00005697          	auipc	a3,0x5
    80001b00:	50468693          	addi	a3,a3,1284 # 80007000 <_trampoline>
    80001b04:	6605                	lui	a2,0x1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	66c080e7          	jalr	1644(ra) # 8000117a <mappages>
    80001b16:	02054863          	bltz	a0,80001b46 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b1a:	4719                	li	a4,6
    80001b1c:	05893683          	ld	a3,88(s2)
    80001b20:	6605                	lui	a2,0x1
    80001b22:	020005b7          	lui	a1,0x2000
    80001b26:	15fd                	addi	a1,a1,-1
    80001b28:	05b6                	slli	a1,a1,0xd
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	64e080e7          	jalr	1614(ra) # 8000117a <mappages>
    80001b34:	02054163          	bltz	a0,80001b56 <proc_pagetable+0x76>
}
    80001b38:	8526                	mv	a0,s1
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6902                	ld	s2,0(sp)
    80001b42:	6105                	addi	sp,sp,32
    80001b44:	8082                	ret
    uvmfree(pagetable, 0);
    80001b46:	4581                	li	a1,0
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	a88080e7          	jalr	-1400(ra) # 800015d2 <uvmfree>
    return 0;
    80001b52:	4481                	li	s1,0
    80001b54:	b7d5                	j	80001b38 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b56:	4681                	li	a3,0
    80001b58:	4605                	li	a2,1
    80001b5a:	040005b7          	lui	a1,0x4000
    80001b5e:	15fd                	addi	a1,a1,-1
    80001b60:	05b2                	slli	a1,a1,0xc
    80001b62:	8526                	mv	a0,s1
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	7ae080e7          	jalr	1966(ra) # 80001312 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b6c:	4581                	li	a1,0
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	a62080e7          	jalr	-1438(ra) # 800015d2 <uvmfree>
    return 0;
    80001b78:	4481                	li	s1,0
    80001b7a:	bf7d                	j	80001b38 <proc_pagetable+0x58>

0000000080001b7c <proc_freepagetable>:
{
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	e04a                	sd	s2,0(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	84aa                	mv	s1,a0
    80001b8a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b8c:	4681                	li	a3,0
    80001b8e:	4605                	li	a2,1
    80001b90:	040005b7          	lui	a1,0x4000
    80001b94:	15fd                	addi	a1,a1,-1
    80001b96:	05b2                	slli	a1,a1,0xc
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	77a080e7          	jalr	1914(ra) # 80001312 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba0:	4681                	li	a3,0
    80001ba2:	4605                	li	a2,1
    80001ba4:	020005b7          	lui	a1,0x2000
    80001ba8:	15fd                	addi	a1,a1,-1
    80001baa:	05b6                	slli	a1,a1,0xd
    80001bac:	8526                	mv	a0,s1
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	764080e7          	jalr	1892(ra) # 80001312 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bb6:	85ca                	mv	a1,s2
    80001bb8:	8526                	mv	a0,s1
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	a18080e7          	jalr	-1512(ra) # 800015d2 <uvmfree>
}
    80001bc2:	60e2                	ld	ra,24(sp)
    80001bc4:	6442                	ld	s0,16(sp)
    80001bc6:	64a2                	ld	s1,8(sp)
    80001bc8:	6902                	ld	s2,0(sp)
    80001bca:	6105                	addi	sp,sp,32
    80001bcc:	8082                	ret

0000000080001bce <freeproc>:
{
    80001bce:	1101                	addi	sp,sp,-32
    80001bd0:	ec06                	sd	ra,24(sp)
    80001bd2:	e822                	sd	s0,16(sp)
    80001bd4:	e426                	sd	s1,8(sp)
    80001bd6:	1000                	addi	s0,sp,32
    80001bd8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bda:	6d28                	ld	a0,88(a0)
    80001bdc:	c509                	beqz	a0,80001be6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	e34080e7          	jalr	-460(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001be6:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bea:	68a8                	ld	a0,80(s1)
    80001bec:	c511                	beqz	a0,80001bf8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bee:	64ac                	ld	a1,72(s1)
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	f8c080e7          	jalr	-116(ra) # 80001b7c <proc_freepagetable>
  p->pagetable = 0;
    80001bf8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bfc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c00:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c04:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c08:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c0c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c10:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c14:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c18:	0004ae23          	sw	zero,28(s1)
}
    80001c1c:	60e2                	ld	ra,24(sp)
    80001c1e:	6442                	ld	s0,16(sp)
    80001c20:	64a2                	ld	s1,8(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <allocproc>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	00010497          	auipc	s1,0x10
    80001c36:	13648493          	addi	s1,s1,310 # 80011d68 <proc>
    80001c3a:	00016917          	auipc	s2,0x16
    80001c3e:	b2e90913          	addi	s2,s2,-1234 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	00c080e7          	jalr	12(ra) # 80000c50 <acquire>
    if(p->state == UNUSED) {
    80001c4c:	4cdc                	lw	a5,28(s1)
    80001c4e:	cf81                	beqz	a5,80001c66 <allocproc+0x40>
      release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	0b2080e7          	jalr	178(ra) # 80000d04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5a:	16848493          	addi	s1,s1,360
    80001c5e:	ff2492e3          	bne	s1,s2,80001c42 <allocproc+0x1c>
  return 0;
    80001c62:	4481                	li	s1,0
    80001c64:	a0b9                	j	80001cb2 <allocproc+0x8c>
  p->pid = allocpid();
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e34080e7          	jalr	-460(ra) # 80001a9a <allocpid>
    80001c6e:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	e9e080e7          	jalr	-354(ra) # 80000b0e <kalloc>
    80001c78:	892a                	mv	s2,a0
    80001c7a:	eca8                	sd	a0,88(s1)
    80001c7c:	c131                	beqz	a0,80001cc0 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	e60080e7          	jalr	-416(ra) # 80001ae0 <proc_pagetable>
    80001c88:	892a                	mv	s2,a0
    80001c8a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c8c:	c129                	beqz	a0,80001cce <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c8e:	07000613          	li	a2,112
    80001c92:	4581                	li	a1,0
    80001c94:	06048513          	addi	a0,s1,96
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	0b4080e7          	jalr	180(ra) # 80000d4c <memset>
  p->context.ra = (uint64)forkret;
    80001ca0:	00000797          	auipc	a5,0x0
    80001ca4:	db478793          	addi	a5,a5,-588 # 80001a54 <forkret>
    80001ca8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001caa:	60bc                	ld	a5,64(s1)
    80001cac:	6705                	lui	a4,0x1
    80001cae:	97ba                	add	a5,a5,a4
    80001cb0:	f4bc                	sd	a5,104(s1)
}
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	60e2                	ld	ra,24(sp)
    80001cb6:	6442                	ld	s0,16(sp)
    80001cb8:	64a2                	ld	s1,8(sp)
    80001cba:	6902                	ld	s2,0(sp)
    80001cbc:	6105                	addi	sp,sp,32
    80001cbe:	8082                	ret
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	042080e7          	jalr	66(ra) # 80000d04 <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	b7dd                	j	80001cb2 <allocproc+0x8c>
    freeproc(p);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	efe080e7          	jalr	-258(ra) # 80001bce <freeproc>
    release(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	02a080e7          	jalr	42(ra) # 80000d04 <release>
    return 0;
    80001ce2:	84ca                	mv	s1,s2
    80001ce4:	b7f9                	j	80001cb2 <allocproc+0x8c>

0000000080001ce6 <userinit>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	f36080e7          	jalr	-202(ra) # 80001c26 <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00007797          	auipc	a5,0x7
    80001cfe:	30a7bf23          	sd	a0,798(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00007597          	auipc	a1,0x7
    80001d0a:	d3a58593          	addi	a1,a1,-710 # 80008a40 <initcode>
    80001d0e:	6928                	ld	a0,80(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	6f4080e7          	jalr	1780(ra) # 80001404 <uvminit>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	4c058593          	addi	a1,a1,1216 # 800081e8 <digits+0x1a8>
    80001d30:	15848513          	addi	a0,s1,344
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	16a080e7          	jalr	362(ra) # 80000e9e <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00006517          	auipc	a0,0x6
    80001d40:	4bc50513          	addi	a0,a0,1212 # 800081f8 <digits+0x1b8>
    80001d44:	00002097          	auipc	ra,0x2
    80001d48:	2aa080e7          	jalr	682(ra) # 80003fee <namei>
    80001d4c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d50:	4789                	li	a5,2
    80001d52:	ccdc                	sw	a5,28(s1)
  release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	fae080e7          	jalr	-82(ra) # 80000d04 <release>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <growproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	ca6080e7          	jalr	-858(ra) # 80001a1c <myproc>
    80001d7e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d80:	652c                	ld	a1,72(a0)
    80001d82:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d86:	00904f63          	bgtz	s1,80001da4 <growproc+0x3c>
  } else if(n < 0){
    80001d8a:	0204cc63          	bltz	s1,80001dc2 <growproc+0x5a>
  p->sz = sz;
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d96:	4501                	li	a0,0
}
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	6928                	ld	a0,80(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	70e080e7          	jalr	1806(ra) # 800014be <uvmalloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	fa69                	bnez	a2,80001d8e <growproc+0x26>
      return -1;
    80001dbe:	557d                	li	a0,-1
    80001dc0:	bfe1                	j	80001d98 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	6928                	ld	a0,80(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	6a8080e7          	jalr	1704(ra) # 80001476 <uvmdealloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	bf55                	j	80001d8e <growproc+0x26>

0000000080001ddc <fork>:
{
    80001ddc:	7139                	addi	sp,sp,-64
    80001dde:	fc06                	sd	ra,56(sp)
    80001de0:	f822                	sd	s0,48(sp)
    80001de2:	f426                	sd	s1,40(sp)
    80001de4:	f04a                	sd	s2,32(sp)
    80001de6:	ec4e                	sd	s3,24(sp)
    80001de8:	e852                	sd	s4,16(sp)
    80001dea:	e456                	sd	s5,8(sp)
    80001dec:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	c2e080e7          	jalr	-978(ra) # 80001a1c <myproc>
    80001df6:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	e2e080e7          	jalr	-466(ra) # 80001c26 <allocproc>
    80001e00:	c57d                	beqz	a0,80001eee <fork+0x112>
    80001e02:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e04:	048ab603          	ld	a2,72(s5)
    80001e08:	692c                	ld	a1,80(a0)
    80001e0a:	050ab503          	ld	a0,80(s5)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	7fc080e7          	jalr	2044(ra) # 8000160a <uvmcopy>
    80001e16:	04054a63          	bltz	a0,80001e6a <fork+0x8e>
  np->sz = p->sz;
    80001e1a:	048ab783          	ld	a5,72(s5)
    80001e1e:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e22:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e26:	058ab683          	ld	a3,88(s5)
    80001e2a:	87b6                	mv	a5,a3
    80001e2c:	058a3703          	ld	a4,88(s4)
    80001e30:	12068693          	addi	a3,a3,288
    80001e34:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e38:	6788                	ld	a0,8(a5)
    80001e3a:	6b8c                	ld	a1,16(a5)
    80001e3c:	6f90                	ld	a2,24(a5)
    80001e3e:	01073023          	sd	a6,0(a4)
    80001e42:	e708                	sd	a0,8(a4)
    80001e44:	eb0c                	sd	a1,16(a4)
    80001e46:	ef10                	sd	a2,24(a4)
    80001e48:	02078793          	addi	a5,a5,32
    80001e4c:	02070713          	addi	a4,a4,32
    80001e50:	fed792e3          	bne	a5,a3,80001e34 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e54:	058a3783          	ld	a5,88(s4)
    80001e58:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e5c:	0d0a8493          	addi	s1,s5,208
    80001e60:	0d0a0913          	addi	s2,s4,208
    80001e64:	150a8993          	addi	s3,s5,336
    80001e68:	a00d                	j	80001e8a <fork+0xae>
    freeproc(np);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	d62080e7          	jalr	-670(ra) # 80001bce <freeproc>
    release(&np->lock);
    80001e74:	8552                	mv	a0,s4
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e8e080e7          	jalr	-370(ra) # 80000d04 <release>
    return -1;
    80001e7e:	54fd                	li	s1,-1
    80001e80:	a8a9                	j	80001eda <fork+0xfe>
  for(i = 0; i < NOFILE; i++)
    80001e82:	04a1                	addi	s1,s1,8
    80001e84:	0921                	addi	s2,s2,8
    80001e86:	01348b63          	beq	s1,s3,80001e9c <fork+0xc0>
    if(p->ofile[i])
    80001e8a:	6088                	ld	a0,0(s1)
    80001e8c:	d97d                	beqz	a0,80001e82 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e8e:	00002097          	auipc	ra,0x2
    80001e92:	7ec080e7          	jalr	2028(ra) # 8000467a <filedup>
    80001e96:	00a93023          	sd	a0,0(s2)
    80001e9a:	b7e5                	j	80001e82 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e9c:	150ab503          	ld	a0,336(s5)
    80001ea0:	00002097          	auipc	ra,0x2
    80001ea4:	960080e7          	jalr	-1696(ra) # 80003800 <idup>
    80001ea8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eac:	4641                	li	a2,16
    80001eae:	158a8593          	addi	a1,s5,344
    80001eb2:	158a0513          	addi	a0,s4,344
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	fe8080e7          	jalr	-24(ra) # 80000e9e <safestrcpy>
  np->trace_mask = p->trace_mask;
    80001ebe:	018aa783          	lw	a5,24(s5)
    80001ec2:	00fa2c23          	sw	a5,24(s4)
  pid = np->pid;
    80001ec6:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001eca:	4789                	li	a5,2
    80001ecc:	00fa2e23          	sw	a5,28(s4)
  release(&np->lock);
    80001ed0:	8552                	mv	a0,s4
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	e32080e7          	jalr	-462(ra) # 80000d04 <release>
}
    80001eda:	8526                	mv	a0,s1
    80001edc:	70e2                	ld	ra,56(sp)
    80001ede:	7442                	ld	s0,48(sp)
    80001ee0:	74a2                	ld	s1,40(sp)
    80001ee2:	7902                	ld	s2,32(sp)
    80001ee4:	69e2                	ld	s3,24(sp)
    80001ee6:	6a42                	ld	s4,16(sp)
    80001ee8:	6aa2                	ld	s5,8(sp)
    80001eea:	6121                	addi	sp,sp,64
    80001eec:	8082                	ret
    return -1;
    80001eee:	54fd                	li	s1,-1
    80001ef0:	b7ed                	j	80001eda <fork+0xfe>

0000000080001ef2 <reparent>:
{
    80001ef2:	7179                	addi	sp,sp,-48
    80001ef4:	f406                	sd	ra,40(sp)
    80001ef6:	f022                	sd	s0,32(sp)
    80001ef8:	ec26                	sd	s1,24(sp)
    80001efa:	e84a                	sd	s2,16(sp)
    80001efc:	e44e                	sd	s3,8(sp)
    80001efe:	e052                	sd	s4,0(sp)
    80001f00:	1800                	addi	s0,sp,48
    80001f02:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f04:	00010497          	auipc	s1,0x10
    80001f08:	e6448493          	addi	s1,s1,-412 # 80011d68 <proc>
      pp->parent = initproc;
    80001f0c:	00007a17          	auipc	s4,0x7
    80001f10:	10ca0a13          	addi	s4,s4,268 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f14:	00016997          	auipc	s3,0x16
    80001f18:	85498993          	addi	s3,s3,-1964 # 80017768 <tickslock>
    80001f1c:	a029                	j	80001f26 <reparent+0x34>
    80001f1e:	16848493          	addi	s1,s1,360
    80001f22:	03348363          	beq	s1,s3,80001f48 <reparent+0x56>
    if(pp->parent == p){
    80001f26:	709c                	ld	a5,32(s1)
    80001f28:	ff279be3          	bne	a5,s2,80001f1e <reparent+0x2c>
      acquire(&pp->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d22080e7          	jalr	-734(ra) # 80000c50 <acquire>
      pp->parent = initproc;
    80001f36:	000a3783          	ld	a5,0(s4)
    80001f3a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	dc6080e7          	jalr	-570(ra) # 80000d04 <release>
    80001f46:	bfe1                	j	80001f1e <reparent+0x2c>
}
    80001f48:	70a2                	ld	ra,40(sp)
    80001f4a:	7402                	ld	s0,32(sp)
    80001f4c:	64e2                	ld	s1,24(sp)
    80001f4e:	6942                	ld	s2,16(sp)
    80001f50:	69a2                	ld	s3,8(sp)
    80001f52:	6a02                	ld	s4,0(sp)
    80001f54:	6145                	addi	sp,sp,48
    80001f56:	8082                	ret

0000000080001f58 <scheduler>:
{
    80001f58:	715d                	addi	sp,sp,-80
    80001f5a:	e486                	sd	ra,72(sp)
    80001f5c:	e0a2                	sd	s0,64(sp)
    80001f5e:	fc26                	sd	s1,56(sp)
    80001f60:	f84a                	sd	s2,48(sp)
    80001f62:	f44e                	sd	s3,40(sp)
    80001f64:	f052                	sd	s4,32(sp)
    80001f66:	ec56                	sd	s5,24(sp)
    80001f68:	e85a                	sd	s6,16(sp)
    80001f6a:	e45e                	sd	s7,8(sp)
    80001f6c:	e062                	sd	s8,0(sp)
    80001f6e:	0880                	addi	s0,sp,80
    80001f70:	8792                	mv	a5,tp
  int id = r_tp();
    80001f72:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f74:	00779b13          	slli	s6,a5,0x7
    80001f78:	00010717          	auipc	a4,0x10
    80001f7c:	9d870713          	addi	a4,a4,-1576 # 80011950 <pid_lock>
    80001f80:	975a                	add	a4,a4,s6
    80001f82:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f86:	00010717          	auipc	a4,0x10
    80001f8a:	9ea70713          	addi	a4,a4,-1558 # 80011970 <cpus+0x8>
    80001f8e:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f90:	4c0d                	li	s8,3
        c->proc = p;
    80001f92:	079e                	slli	a5,a5,0x7
    80001f94:	00010a17          	auipc	s4,0x10
    80001f98:	9bca0a13          	addi	s4,s4,-1604 # 80011950 <pid_lock>
    80001f9c:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f9e:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa0:	00015997          	auipc	s3,0x15
    80001fa4:	7c898993          	addi	s3,s3,1992 # 80017768 <tickslock>
    80001fa8:	a899                	j	80001ffe <scheduler+0xa6>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d58080e7          	jalr	-680(ra) # 80000d04 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	16848493          	addi	s1,s1,360
    80001fb8:	03348963          	beq	s1,s3,80001fea <scheduler+0x92>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c92080e7          	jalr	-878(ra) # 80000c50 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4cdc                	lw	a5,28(s1)
    80001fc8:	ff2791e3          	bne	a5,s2,80001faa <scheduler+0x52>
        p->state = RUNNING;
    80001fcc:	0184ae23          	sw	s8,28(s1)
        c->proc = p;
    80001fd0:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	855a                	mv	a0,s6
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	644080e7          	jalr	1604(ra) # 8000261e <swtch>
        c->proc = 0;
    80001fe2:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fe6:	8ade                	mv	s5,s7
    80001fe8:	b7c9                	j	80001faa <scheduler+0x52>
    if(found == 0) {
    80001fea:	000a9a63          	bnez	s5,80001ffe <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff6:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001ffa:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002002:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002006:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000200a:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200c:	00010497          	auipc	s1,0x10
    80002010:	d5c48493          	addi	s1,s1,-676 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002014:	4909                	li	s2,2
    80002016:	b75d                	j	80001fbc <scheduler+0x64>

0000000080002018 <sched>:
{
    80002018:	7179                	addi	sp,sp,-48
    8000201a:	f406                	sd	ra,40(sp)
    8000201c:	f022                	sd	s0,32(sp)
    8000201e:	ec26                	sd	s1,24(sp)
    80002020:	e84a                	sd	s2,16(sp)
    80002022:	e44e                	sd	s3,8(sp)
    80002024:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	9f6080e7          	jalr	-1546(ra) # 80001a1c <myproc>
    8000202e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	ba6080e7          	jalr	-1114(ra) # 80000bd6 <holding>
    80002038:	c93d                	beqz	a0,800020ae <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	00010717          	auipc	a4,0x10
    80002044:	91070713          	addi	a4,a4,-1776 # 80011950 <pid_lock>
    80002048:	97ba                	add	a5,a5,a4
    8000204a:	0907a703          	lw	a4,144(a5)
    8000204e:	4785                	li	a5,1
    80002050:	06f71763          	bne	a4,a5,800020be <sched+0xa6>
  if(p->state == RUNNING)
    80002054:	4cd8                	lw	a4,28(s1)
    80002056:	478d                	li	a5,3
    80002058:	06f70b63          	beq	a4,a5,800020ce <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000205c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002060:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002062:	efb5                	bnez	a5,800020de <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002064:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002066:	00010917          	auipc	s2,0x10
    8000206a:	8ea90913          	addi	s2,s2,-1814 # 80011950 <pid_lock>
    8000206e:	2781                	sext.w	a5,a5
    80002070:	079e                	slli	a5,a5,0x7
    80002072:	97ca                	add	a5,a5,s2
    80002074:	0947a983          	lw	s3,148(a5)
    80002078:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	00010597          	auipc	a1,0x10
    80002082:	8f258593          	addi	a1,a1,-1806 # 80011970 <cpus+0x8>
    80002086:	95be                	add	a1,a1,a5
    80002088:	06048513          	addi	a0,s1,96
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	592080e7          	jalr	1426(ra) # 8000261e <swtch>
    80002094:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002096:	2781                	sext.w	a5,a5
    80002098:	079e                	slli	a5,a5,0x7
    8000209a:	97ca                	add	a5,a5,s2
    8000209c:	0937aa23          	sw	s3,148(a5)
}
    800020a0:	70a2                	ld	ra,40(sp)
    800020a2:	7402                	ld	s0,32(sp)
    800020a4:	64e2                	ld	s1,24(sp)
    800020a6:	6942                	ld	s2,16(sp)
    800020a8:	69a2                	ld	s3,8(sp)
    800020aa:	6145                	addi	sp,sp,48
    800020ac:	8082                	ret
    panic("sched p->lock");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	15250513          	addi	a0,a0,338 # 80008200 <digits+0x1c0>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48c080e7          	jalr	1164(ra) # 80000542 <panic>
    panic("sched locks");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	15250513          	addi	a0,a0,338 # 80008210 <digits+0x1d0>
    800020c6:	ffffe097          	auipc	ra,0xffffe
    800020ca:	47c080e7          	jalr	1148(ra) # 80000542 <panic>
    panic("sched running");
    800020ce:	00006517          	auipc	a0,0x6
    800020d2:	15250513          	addi	a0,a0,338 # 80008220 <digits+0x1e0>
    800020d6:	ffffe097          	auipc	ra,0xffffe
    800020da:	46c080e7          	jalr	1132(ra) # 80000542 <panic>
    panic("sched interruptible");
    800020de:	00006517          	auipc	a0,0x6
    800020e2:	15250513          	addi	a0,a0,338 # 80008230 <digits+0x1f0>
    800020e6:	ffffe097          	auipc	ra,0xffffe
    800020ea:	45c080e7          	jalr	1116(ra) # 80000542 <panic>

00000000800020ee <exit>:
{
    800020ee:	7179                	addi	sp,sp,-48
    800020f0:	f406                	sd	ra,40(sp)
    800020f2:	f022                	sd	s0,32(sp)
    800020f4:	ec26                	sd	s1,24(sp)
    800020f6:	e84a                	sd	s2,16(sp)
    800020f8:	e44e                	sd	s3,8(sp)
    800020fa:	e052                	sd	s4,0(sp)
    800020fc:	1800                	addi	s0,sp,48
    800020fe:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	91c080e7          	jalr	-1764(ra) # 80001a1c <myproc>
    80002108:	89aa                	mv	s3,a0
  if(p == initproc)
    8000210a:	00007797          	auipc	a5,0x7
    8000210e:	f0e7b783          	ld	a5,-242(a5) # 80009018 <initproc>
    80002112:	0d050493          	addi	s1,a0,208
    80002116:	15050913          	addi	s2,a0,336
    8000211a:	02a79363          	bne	a5,a0,80002140 <exit+0x52>
    panic("init exiting");
    8000211e:	00006517          	auipc	a0,0x6
    80002122:	12a50513          	addi	a0,a0,298 # 80008248 <digits+0x208>
    80002126:	ffffe097          	auipc	ra,0xffffe
    8000212a:	41c080e7          	jalr	1052(ra) # 80000542 <panic>
      fileclose(f);
    8000212e:	00002097          	auipc	ra,0x2
    80002132:	59e080e7          	jalr	1438(ra) # 800046cc <fileclose>
      p->ofile[fd] = 0;
    80002136:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000213a:	04a1                	addi	s1,s1,8
    8000213c:	01248563          	beq	s1,s2,80002146 <exit+0x58>
    if(p->ofile[fd]){
    80002140:	6088                	ld	a0,0(s1)
    80002142:	f575                	bnez	a0,8000212e <exit+0x40>
    80002144:	bfdd                	j	8000213a <exit+0x4c>
  begin_op();
    80002146:	00002097          	auipc	ra,0x2
    8000214a:	0b4080e7          	jalr	180(ra) # 800041fa <begin_op>
  iput(p->cwd);
    8000214e:	1509b503          	ld	a0,336(s3)
    80002152:	00002097          	auipc	ra,0x2
    80002156:	8a6080e7          	jalr	-1882(ra) # 800039f8 <iput>
  end_op();
    8000215a:	00002097          	auipc	ra,0x2
    8000215e:	120080e7          	jalr	288(ra) # 8000427a <end_op>
  p->cwd = 0;
    80002162:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002166:	00007497          	auipc	s1,0x7
    8000216a:	eb248493          	addi	s1,s1,-334 # 80009018 <initproc>
    8000216e:	6088                	ld	a0,0(s1)
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	ae0080e7          	jalr	-1312(ra) # 80000c50 <acquire>
  wakeup1(initproc);
    80002178:	6088                	ld	a0,0(s1)
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	762080e7          	jalr	1890(ra) # 800018dc <wakeup1>
  release(&initproc->lock);
    80002182:	6088                	ld	a0,0(s1)
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b80080e7          	jalr	-1152(ra) # 80000d04 <release>
  acquire(&p->lock);
    8000218c:	854e                	mv	a0,s3
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	ac2080e7          	jalr	-1342(ra) # 80000c50 <acquire>
  struct proc *original_parent = p->parent;
    80002196:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000219a:	854e                	mv	a0,s3
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	b68080e7          	jalr	-1176(ra) # 80000d04 <release>
  acquire(&original_parent->lock);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	aaa080e7          	jalr	-1366(ra) # 80000c50 <acquire>
  acquire(&p->lock);
    800021ae:	854e                	mv	a0,s3
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	aa0080e7          	jalr	-1376(ra) # 80000c50 <acquire>
  reparent(p);
    800021b8:	854e                	mv	a0,s3
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	d38080e7          	jalr	-712(ra) # 80001ef2 <reparent>
  wakeup1(original_parent);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	718080e7          	jalr	1816(ra) # 800018dc <wakeup1>
  p->xstate = status;
    800021cc:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021d0:	4791                	li	a5,4
    800021d2:	00f9ae23          	sw	a5,28(s3)
  release(&original_parent->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	b2c080e7          	jalr	-1236(ra) # 80000d04 <release>
  sched();
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	e38080e7          	jalr	-456(ra) # 80002018 <sched>
  panic("zombie exit");
    800021e8:	00006517          	auipc	a0,0x6
    800021ec:	07050513          	addi	a0,a0,112 # 80008258 <digits+0x218>
    800021f0:	ffffe097          	auipc	ra,0xffffe
    800021f4:	352080e7          	jalr	850(ra) # 80000542 <panic>

00000000800021f8 <yield>:
{
    800021f8:	1101                	addi	sp,sp,-32
    800021fa:	ec06                	sd	ra,24(sp)
    800021fc:	e822                	sd	s0,16(sp)
    800021fe:	e426                	sd	s1,8(sp)
    80002200:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	81a080e7          	jalr	-2022(ra) # 80001a1c <myproc>
    8000220a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a44080e7          	jalr	-1468(ra) # 80000c50 <acquire>
  p->state = RUNNABLE;
    80002214:	4789                	li	a5,2
    80002216:	ccdc                	sw	a5,28(s1)
  sched();
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	e00080e7          	jalr	-512(ra) # 80002018 <sched>
  release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	ae2080e7          	jalr	-1310(ra) # 80000d04 <release>
}
    8000222a:	60e2                	ld	ra,24(sp)
    8000222c:	6442                	ld	s0,16(sp)
    8000222e:	64a2                	ld	s1,8(sp)
    80002230:	6105                	addi	sp,sp,32
    80002232:	8082                	ret

0000000080002234 <sleep>:
{
    80002234:	7179                	addi	sp,sp,-48
    80002236:	f406                	sd	ra,40(sp)
    80002238:	f022                	sd	s0,32(sp)
    8000223a:	ec26                	sd	s1,24(sp)
    8000223c:	e84a                	sd	s2,16(sp)
    8000223e:	e44e                	sd	s3,8(sp)
    80002240:	1800                	addi	s0,sp,48
    80002242:	89aa                	mv	s3,a0
    80002244:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	7d6080e7          	jalr	2006(ra) # 80001a1c <myproc>
    8000224e:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002250:	05250663          	beq	a0,s2,8000229c <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	9fc080e7          	jalr	-1540(ra) # 80000c50 <acquire>
    release(lk);
    8000225c:	854a                	mv	a0,s2
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	aa6080e7          	jalr	-1370(ra) # 80000d04 <release>
  p->chan = chan;
    80002266:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000226a:	4785                	li	a5,1
    8000226c:	ccdc                	sw	a5,28(s1)
  sched();
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	daa080e7          	jalr	-598(ra) # 80002018 <sched>
  p->chan = 0;
    80002276:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	a88080e7          	jalr	-1400(ra) # 80000d04 <release>
    acquire(lk);
    80002284:	854a                	mv	a0,s2
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	9ca080e7          	jalr	-1590(ra) # 80000c50 <acquire>
}
    8000228e:	70a2                	ld	ra,40(sp)
    80002290:	7402                	ld	s0,32(sp)
    80002292:	64e2                	ld	s1,24(sp)
    80002294:	6942                	ld	s2,16(sp)
    80002296:	69a2                	ld	s3,8(sp)
    80002298:	6145                	addi	sp,sp,48
    8000229a:	8082                	ret
  p->chan = chan;
    8000229c:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022a0:	4785                	li	a5,1
    800022a2:	cd5c                	sw	a5,28(a0)
  sched();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	d74080e7          	jalr	-652(ra) # 80002018 <sched>
  p->chan = 0;
    800022ac:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022b0:	bff9                	j	8000228e <sleep+0x5a>

00000000800022b2 <wait>:
{
    800022b2:	715d                	addi	sp,sp,-80
    800022b4:	e486                	sd	ra,72(sp)
    800022b6:	e0a2                	sd	s0,64(sp)
    800022b8:	fc26                	sd	s1,56(sp)
    800022ba:	f84a                	sd	s2,48(sp)
    800022bc:	f44e                	sd	s3,40(sp)
    800022be:	f052                	sd	s4,32(sp)
    800022c0:	ec56                	sd	s5,24(sp)
    800022c2:	e85a                	sd	s6,16(sp)
    800022c4:	e45e                	sd	s7,8(sp)
    800022c6:	0880                	addi	s0,sp,80
    800022c8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	752080e7          	jalr	1874(ra) # 80001a1c <myproc>
    800022d2:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	97c080e7          	jalr	-1668(ra) # 80000c50 <acquire>
    havekids = 0;
    800022dc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022de:	4a11                	li	s4,4
        havekids = 1;
    800022e0:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022e2:	00015997          	auipc	s3,0x15
    800022e6:	48698993          	addi	s3,s3,1158 # 80017768 <tickslock>
    havekids = 0;
    800022ea:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022ec:	00010497          	auipc	s1,0x10
    800022f0:	a7c48493          	addi	s1,s1,-1412 # 80011d68 <proc>
    800022f4:	a08d                	j	80002356 <wait+0xa4>
          pid = np->pid;
    800022f6:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022fa:	000b0e63          	beqz	s6,80002316 <wait+0x64>
    800022fe:	4691                	li	a3,4
    80002300:	03448613          	addi	a2,s1,52
    80002304:	85da                	mv	a1,s6
    80002306:	05093503          	ld	a0,80(s2)
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	404080e7          	jalr	1028(ra) # 8000170e <copyout>
    80002312:	02054263          	bltz	a0,80002336 <wait+0x84>
          freeproc(np);
    80002316:	8526                	mv	a0,s1
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	8b6080e7          	jalr	-1866(ra) # 80001bce <freeproc>
          release(&np->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	9e2080e7          	jalr	-1566(ra) # 80000d04 <release>
          release(&p->lock);
    8000232a:	854a                	mv	a0,s2
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	9d8080e7          	jalr	-1576(ra) # 80000d04 <release>
          return pid;
    80002334:	a8a9                	j	8000238e <wait+0xdc>
            release(&np->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	9cc080e7          	jalr	-1588(ra) # 80000d04 <release>
            release(&p->lock);
    80002340:	854a                	mv	a0,s2
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	9c2080e7          	jalr	-1598(ra) # 80000d04 <release>
            return -1;
    8000234a:	59fd                	li	s3,-1
    8000234c:	a089                	j	8000238e <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000234e:	16848493          	addi	s1,s1,360
    80002352:	03348463          	beq	s1,s3,8000237a <wait+0xc8>
      if(np->parent == p){
    80002356:	709c                	ld	a5,32(s1)
    80002358:	ff279be3          	bne	a5,s2,8000234e <wait+0x9c>
        acquire(&np->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	8f2080e7          	jalr	-1806(ra) # 80000c50 <acquire>
        if(np->state == ZOMBIE){
    80002366:	4cdc                	lw	a5,28(s1)
    80002368:	f94787e3          	beq	a5,s4,800022f6 <wait+0x44>
        release(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	996080e7          	jalr	-1642(ra) # 80000d04 <release>
        havekids = 1;
    80002376:	8756                	mv	a4,s5
    80002378:	bfd9                	j	8000234e <wait+0x9c>
    if(!havekids || p->killed){
    8000237a:	c701                	beqz	a4,80002382 <wait+0xd0>
    8000237c:	03092783          	lw	a5,48(s2)
    80002380:	c39d                	beqz	a5,800023a6 <wait+0xf4>
      release(&p->lock);
    80002382:	854a                	mv	a0,s2
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	980080e7          	jalr	-1664(ra) # 80000d04 <release>
      return -1;
    8000238c:	59fd                	li	s3,-1
}
    8000238e:	854e                	mv	a0,s3
    80002390:	60a6                	ld	ra,72(sp)
    80002392:	6406                	ld	s0,64(sp)
    80002394:	74e2                	ld	s1,56(sp)
    80002396:	7942                	ld	s2,48(sp)
    80002398:	79a2                	ld	s3,40(sp)
    8000239a:	7a02                	ld	s4,32(sp)
    8000239c:	6ae2                	ld	s5,24(sp)
    8000239e:	6b42                	ld	s6,16(sp)
    800023a0:	6ba2                	ld	s7,8(sp)
    800023a2:	6161                	addi	sp,sp,80
    800023a4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023a6:	85ca                	mv	a1,s2
    800023a8:	854a                	mv	a0,s2
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	e8a080e7          	jalr	-374(ra) # 80002234 <sleep>
    havekids = 0;
    800023b2:	bf25                	j	800022ea <wait+0x38>

00000000800023b4 <wakeup>:
{
    800023b4:	7139                	addi	sp,sp,-64
    800023b6:	fc06                	sd	ra,56(sp)
    800023b8:	f822                	sd	s0,48(sp)
    800023ba:	f426                	sd	s1,40(sp)
    800023bc:	f04a                	sd	s2,32(sp)
    800023be:	ec4e                	sd	s3,24(sp)
    800023c0:	e852                	sd	s4,16(sp)
    800023c2:	e456                	sd	s5,8(sp)
    800023c4:	0080                	addi	s0,sp,64
    800023c6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c8:	00010497          	auipc	s1,0x10
    800023cc:	9a048493          	addi	s1,s1,-1632 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023d0:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023d2:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d4:	00015917          	auipc	s2,0x15
    800023d8:	39490913          	addi	s2,s2,916 # 80017768 <tickslock>
    800023dc:	a811                	j	800023f0 <wakeup+0x3c>
    release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	924080e7          	jalr	-1756(ra) # 80000d04 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03248063          	beq	s1,s2,8000240c <wakeup+0x58>
    acquire(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	85e080e7          	jalr	-1954(ra) # 80000c50 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023fa:	4cdc                	lw	a5,28(s1)
    800023fc:	ff3791e3          	bne	a5,s3,800023de <wakeup+0x2a>
    80002400:	749c                	ld	a5,40(s1)
    80002402:	fd479ee3          	bne	a5,s4,800023de <wakeup+0x2a>
      p->state = RUNNABLE;
    80002406:	0154ae23          	sw	s5,28(s1)
    8000240a:	bfd1                	j	800023de <wakeup+0x2a>
}
    8000240c:	70e2                	ld	ra,56(sp)
    8000240e:	7442                	ld	s0,48(sp)
    80002410:	74a2                	ld	s1,40(sp)
    80002412:	7902                	ld	s2,32(sp)
    80002414:	69e2                	ld	s3,24(sp)
    80002416:	6a42                	ld	s4,16(sp)
    80002418:	6aa2                	ld	s5,8(sp)
    8000241a:	6121                	addi	sp,sp,64
    8000241c:	8082                	ret

000000008000241e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000241e:	7179                	addi	sp,sp,-48
    80002420:	f406                	sd	ra,40(sp)
    80002422:	f022                	sd	s0,32(sp)
    80002424:	ec26                	sd	s1,24(sp)
    80002426:	e84a                	sd	s2,16(sp)
    80002428:	e44e                	sd	s3,8(sp)
    8000242a:	1800                	addi	s0,sp,48
    8000242c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000242e:	00010497          	auipc	s1,0x10
    80002432:	93a48493          	addi	s1,s1,-1734 # 80011d68 <proc>
    80002436:	00015997          	auipc	s3,0x15
    8000243a:	33298993          	addi	s3,s3,818 # 80017768 <tickslock>
    acquire(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	810080e7          	jalr	-2032(ra) # 80000c50 <acquire>
    if(p->pid == pid){
    80002448:	5c9c                	lw	a5,56(s1)
    8000244a:	01278d63          	beq	a5,s2,80002464 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	8b4080e7          	jalr	-1868(ra) # 80000d04 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002458:	16848493          	addi	s1,s1,360
    8000245c:	ff3491e3          	bne	s1,s3,8000243e <kill+0x20>
  }
  return -1;
    80002460:	557d                	li	a0,-1
    80002462:	a821                	j	8000247a <kill+0x5c>
      p->killed = 1;
    80002464:	4785                	li	a5,1
    80002466:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002468:	4cd8                	lw	a4,28(s1)
    8000246a:	00f70f63          	beq	a4,a5,80002488 <kill+0x6a>
      release(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	894080e7          	jalr	-1900(ra) # 80000d04 <release>
      return 0;
    80002478:	4501                	li	a0,0
}
    8000247a:	70a2                	ld	ra,40(sp)
    8000247c:	7402                	ld	s0,32(sp)
    8000247e:	64e2                	ld	s1,24(sp)
    80002480:	6942                	ld	s2,16(sp)
    80002482:	69a2                	ld	s3,8(sp)
    80002484:	6145                	addi	sp,sp,48
    80002486:	8082                	ret
        p->state = RUNNABLE;
    80002488:	4789                	li	a5,2
    8000248a:	ccdc                	sw	a5,28(s1)
    8000248c:	b7cd                	j	8000246e <kill+0x50>

000000008000248e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000248e:	7179                	addi	sp,sp,-48
    80002490:	f406                	sd	ra,40(sp)
    80002492:	f022                	sd	s0,32(sp)
    80002494:	ec26                	sd	s1,24(sp)
    80002496:	e84a                	sd	s2,16(sp)
    80002498:	e44e                	sd	s3,8(sp)
    8000249a:	e052                	sd	s4,0(sp)
    8000249c:	1800                	addi	s0,sp,48
    8000249e:	84aa                	mv	s1,a0
    800024a0:	892e                	mv	s2,a1
    800024a2:	89b2                	mv	s3,a2
    800024a4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	576080e7          	jalr	1398(ra) # 80001a1c <myproc>
  if(user_dst){
    800024ae:	c08d                	beqz	s1,800024d0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024b0:	86d2                	mv	a3,s4
    800024b2:	864e                	mv	a2,s3
    800024b4:	85ca                	mv	a1,s2
    800024b6:	6928                	ld	a0,80(a0)
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	256080e7          	jalr	598(ra) # 8000170e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c0:	70a2                	ld	ra,40(sp)
    800024c2:	7402                	ld	s0,32(sp)
    800024c4:	64e2                	ld	s1,24(sp)
    800024c6:	6942                	ld	s2,16(sp)
    800024c8:	69a2                	ld	s3,8(sp)
    800024ca:	6a02                	ld	s4,0(sp)
    800024cc:	6145                	addi	sp,sp,48
    800024ce:	8082                	ret
    memmove((char *)dst, src, len);
    800024d0:	000a061b          	sext.w	a2,s4
    800024d4:	85ce                	mv	a1,s3
    800024d6:	854a                	mv	a0,s2
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	8d0080e7          	jalr	-1840(ra) # 80000da8 <memmove>
    return 0;
    800024e0:	8526                	mv	a0,s1
    800024e2:	bff9                	j	800024c0 <either_copyout+0x32>

00000000800024e4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e4:	7179                	addi	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	e052                	sd	s4,0(sp)
    800024f2:	1800                	addi	s0,sp,48
    800024f4:	892a                	mv	s2,a0
    800024f6:	84ae                	mv	s1,a1
    800024f8:	89b2                	mv	s3,a2
    800024fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	520080e7          	jalr	1312(ra) # 80001a1c <myproc>
  if(user_src){
    80002504:	c08d                	beqz	s1,80002526 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002506:	86d2                	mv	a3,s4
    80002508:	864e                	mv	a2,s3
    8000250a:	85ca                	mv	a1,s2
    8000250c:	6928                	ld	a0,80(a0)
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	28c080e7          	jalr	652(ra) # 8000179a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002516:	70a2                	ld	ra,40(sp)
    80002518:	7402                	ld	s0,32(sp)
    8000251a:	64e2                	ld	s1,24(sp)
    8000251c:	6942                	ld	s2,16(sp)
    8000251e:	69a2                	ld	s3,8(sp)
    80002520:	6a02                	ld	s4,0(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret
    memmove(dst, (char*)src, len);
    80002526:	000a061b          	sext.w	a2,s4
    8000252a:	85ce                	mv	a1,s3
    8000252c:	854a                	mv	a0,s2
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	87a080e7          	jalr	-1926(ra) # 80000da8 <memmove>
    return 0;
    80002536:	8526                	mv	a0,s1
    80002538:	bff9                	j	80002516 <either_copyin+0x32>

000000008000253a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000253a:	715d                	addi	sp,sp,-80
    8000253c:	e486                	sd	ra,72(sp)
    8000253e:	e0a2                	sd	s0,64(sp)
    80002540:	fc26                	sd	s1,56(sp)
    80002542:	f84a                	sd	s2,48(sp)
    80002544:	f44e                	sd	s3,40(sp)
    80002546:	f052                	sd	s4,32(sp)
    80002548:	ec56                	sd	s5,24(sp)
    8000254a:	e85a                	sd	s6,16(sp)
    8000254c:	e45e                	sd	s7,8(sp)
    8000254e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002550:	00006517          	auipc	a0,0x6
    80002554:	b7850513          	addi	a0,a0,-1160 # 800080c8 <digits+0x88>
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	034080e7          	jalr	52(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002560:	00010497          	auipc	s1,0x10
    80002564:	96048493          	addi	s1,s1,-1696 # 80011ec0 <proc+0x158>
    80002568:	00015917          	auipc	s2,0x15
    8000256c:	35890913          	addi	s2,s2,856 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002570:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002572:	00006997          	auipc	s3,0x6
    80002576:	cf698993          	addi	s3,s3,-778 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000257a:	00006a97          	auipc	s5,0x6
    8000257e:	cf6a8a93          	addi	s5,s5,-778 # 80008270 <digits+0x230>
    printf("\n");
    80002582:	00006a17          	auipc	s4,0x6
    80002586:	b46a0a13          	addi	s4,s4,-1210 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258a:	00006b97          	auipc	s7,0x6
    8000258e:	d1eb8b93          	addi	s7,s7,-738 # 800082a8 <states.0>
    80002592:	a00d                	j	800025b4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002594:	ee06a583          	lw	a1,-288(a3)
    80002598:	8556                	mv	a0,s5
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	ff2080e7          	jalr	-14(ra) # 8000058c <printf>
    printf("\n");
    800025a2:	8552                	mv	a0,s4
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	fe8080e7          	jalr	-24(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ac:	16848493          	addi	s1,s1,360
    800025b0:	03248163          	beq	s1,s2,800025d2 <procdump+0x98>
    if(p->state == UNUSED)
    800025b4:	86a6                	mv	a3,s1
    800025b6:	ec44a783          	lw	a5,-316(s1)
    800025ba:	dbed                	beqz	a5,800025ac <procdump+0x72>
      state = "???";
    800025bc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025be:	fcfb6be3          	bltu	s6,a5,80002594 <procdump+0x5a>
    800025c2:	1782                	slli	a5,a5,0x20
    800025c4:	9381                	srli	a5,a5,0x20
    800025c6:	078e                	slli	a5,a5,0x3
    800025c8:	97de                	add	a5,a5,s7
    800025ca:	6390                	ld	a2,0(a5)
    800025cc:	f661                	bnez	a2,80002594 <procdump+0x5a>
      state = "???";
    800025ce:	864e                	mv	a2,s3
    800025d0:	b7d1                	j	80002594 <procdump+0x5a>
  }
}
    800025d2:	60a6                	ld	ra,72(sp)
    800025d4:	6406                	ld	s0,64(sp)
    800025d6:	74e2                	ld	s1,56(sp)
    800025d8:	7942                	ld	s2,48(sp)
    800025da:	79a2                	ld	s3,40(sp)
    800025dc:	7a02                	ld	s4,32(sp)
    800025de:	6ae2                	ld	s5,24(sp)
    800025e0:	6b42                	ld	s6,16(sp)
    800025e2:	6ba2                	ld	s7,8(sp)
    800025e4:	6161                	addi	sp,sp,80
    800025e6:	8082                	ret

00000000800025e8 <procnum>:

void 
procnum(uint64 *dst){
    800025e8:	1141                	addi	sp,sp,-16
    800025ea:	e422                	sd	s0,8(sp)
    800025ec:	0800                	addi	s0,sp,16
  *dst = 0;
    800025ee:	00053023          	sd	zero,0(a0)
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	0000f797          	auipc	a5,0xf
    800025f6:	77678793          	addi	a5,a5,1910 # 80011d68 <proc>
    800025fa:	00015697          	auipc	a3,0x15
    800025fe:	16e68693          	addi	a3,a3,366 # 80017768 <tickslock>
    80002602:	a029                	j	8000260c <procnum+0x24>
    80002604:	16878793          	addi	a5,a5,360
    80002608:	00d78863          	beq	a5,a3,80002618 <procnum+0x30>
    if(p -> state != UNUSED)(*dst)++;
    8000260c:	4fd8                	lw	a4,28(a5)
    8000260e:	db7d                	beqz	a4,80002604 <procnum+0x1c>
    80002610:	6118                	ld	a4,0(a0)
    80002612:	0705                	addi	a4,a4,1
    80002614:	e118                	sd	a4,0(a0)
    80002616:	b7fd                	j	80002604 <procnum+0x1c>
  }
}
    80002618:	6422                	ld	s0,8(sp)
    8000261a:	0141                	addi	sp,sp,16
    8000261c:	8082                	ret

000000008000261e <swtch>:
    8000261e:	00153023          	sd	ra,0(a0)
    80002622:	00253423          	sd	sp,8(a0)
    80002626:	e900                	sd	s0,16(a0)
    80002628:	ed04                	sd	s1,24(a0)
    8000262a:	03253023          	sd	s2,32(a0)
    8000262e:	03353423          	sd	s3,40(a0)
    80002632:	03453823          	sd	s4,48(a0)
    80002636:	03553c23          	sd	s5,56(a0)
    8000263a:	05653023          	sd	s6,64(a0)
    8000263e:	05753423          	sd	s7,72(a0)
    80002642:	05853823          	sd	s8,80(a0)
    80002646:	05953c23          	sd	s9,88(a0)
    8000264a:	07a53023          	sd	s10,96(a0)
    8000264e:	07b53423          	sd	s11,104(a0)
    80002652:	0005b083          	ld	ra,0(a1)
    80002656:	0085b103          	ld	sp,8(a1)
    8000265a:	6980                	ld	s0,16(a1)
    8000265c:	6d84                	ld	s1,24(a1)
    8000265e:	0205b903          	ld	s2,32(a1)
    80002662:	0285b983          	ld	s3,40(a1)
    80002666:	0305ba03          	ld	s4,48(a1)
    8000266a:	0385ba83          	ld	s5,56(a1)
    8000266e:	0405bb03          	ld	s6,64(a1)
    80002672:	0485bb83          	ld	s7,72(a1)
    80002676:	0505bc03          	ld	s8,80(a1)
    8000267a:	0585bc83          	ld	s9,88(a1)
    8000267e:	0605bd03          	ld	s10,96(a1)
    80002682:	0685bd83          	ld	s11,104(a1)
    80002686:	8082                	ret

0000000080002688 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002688:	1141                	addi	sp,sp,-16
    8000268a:	e406                	sd	ra,8(sp)
    8000268c:	e022                	sd	s0,0(sp)
    8000268e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002690:	00006597          	auipc	a1,0x6
    80002694:	c4058593          	addi	a1,a1,-960 # 800082d0 <states.0+0x28>
    80002698:	00015517          	auipc	a0,0x15
    8000269c:	0d050513          	addi	a0,a0,208 # 80017768 <tickslock>
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	520080e7          	jalr	1312(ra) # 80000bc0 <initlock>
}
    800026a8:	60a2                	ld	ra,8(sp)
    800026aa:	6402                	ld	s0,0(sp)
    800026ac:	0141                	addi	sp,sp,16
    800026ae:	8082                	ret

00000000800026b0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b0:	1141                	addi	sp,sp,-16
    800026b2:	e422                	sd	s0,8(sp)
    800026b4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b6:	00003797          	auipc	a5,0x3
    800026ba:	67a78793          	addi	a5,a5,1658 # 80005d30 <kernelvec>
    800026be:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c2:	6422                	ld	s0,8(sp)
    800026c4:	0141                	addi	sp,sp,16
    800026c6:	8082                	ret

00000000800026c8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	34c080e7          	jalr	844(ra) # 80001a1c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026dc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026de:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026e2:	00005617          	auipc	a2,0x5
    800026e6:	91e60613          	addi	a2,a2,-1762 # 80007000 <_trampoline>
    800026ea:	00005697          	auipc	a3,0x5
    800026ee:	91668693          	addi	a3,a3,-1770 # 80007000 <_trampoline>
    800026f2:	8e91                	sub	a3,a3,a2
    800026f4:	040007b7          	lui	a5,0x4000
    800026f8:	17fd                	addi	a5,a5,-1
    800026fa:	07b2                	slli	a5,a5,0xc
    800026fc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fe:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002702:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002704:	180026f3          	csrr	a3,satp
    80002708:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000270a:	6d38                	ld	a4,88(a0)
    8000270c:	6134                	ld	a3,64(a0)
    8000270e:	6585                	lui	a1,0x1
    80002710:	96ae                	add	a3,a3,a1
    80002712:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002714:	6d38                	ld	a4,88(a0)
    80002716:	00000697          	auipc	a3,0x0
    8000271a:	13868693          	addi	a3,a3,312 # 8000284e <usertrap>
    8000271e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002720:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002722:	8692                	mv	a3,tp
    80002724:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002726:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000272a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002732:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002738:	6f18                	ld	a4,24(a4)
    8000273a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273e:	692c                	ld	a1,80(a0)
    80002740:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002742:	00005717          	auipc	a4,0x5
    80002746:	94e70713          	addi	a4,a4,-1714 # 80007090 <userret>
    8000274a:	8f11                	sub	a4,a4,a2
    8000274c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000274e:	577d                	li	a4,-1
    80002750:	177e                	slli	a4,a4,0x3f
    80002752:	8dd9                	or	a1,a1,a4
    80002754:	02000537          	lui	a0,0x2000
    80002758:	157d                	addi	a0,a0,-1
    8000275a:	0536                	slli	a0,a0,0xd
    8000275c:	9782                	jalr	a5
}
    8000275e:	60a2                	ld	ra,8(sp)
    80002760:	6402                	ld	s0,0(sp)
    80002762:	0141                	addi	sp,sp,16
    80002764:	8082                	ret

0000000080002766 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002766:	1101                	addi	sp,sp,-32
    80002768:	ec06                	sd	ra,24(sp)
    8000276a:	e822                	sd	s0,16(sp)
    8000276c:	e426                	sd	s1,8(sp)
    8000276e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002770:	00015497          	auipc	s1,0x15
    80002774:	ff848493          	addi	s1,s1,-8 # 80017768 <tickslock>
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	4d6080e7          	jalr	1238(ra) # 80000c50 <acquire>
  ticks++;
    80002782:	00007517          	auipc	a0,0x7
    80002786:	89e50513          	addi	a0,a0,-1890 # 80009020 <ticks>
    8000278a:	411c                	lw	a5,0(a0)
    8000278c:	2785                	addiw	a5,a5,1
    8000278e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002790:	00000097          	auipc	ra,0x0
    80002794:	c24080e7          	jalr	-988(ra) # 800023b4 <wakeup>
  release(&tickslock);
    80002798:	8526                	mv	a0,s1
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	56a080e7          	jalr	1386(ra) # 80000d04 <release>
}
    800027a2:	60e2                	ld	ra,24(sp)
    800027a4:	6442                	ld	s0,16(sp)
    800027a6:	64a2                	ld	s1,8(sp)
    800027a8:	6105                	addi	sp,sp,32
    800027aa:	8082                	ret

00000000800027ac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ac:	1101                	addi	sp,sp,-32
    800027ae:	ec06                	sd	ra,24(sp)
    800027b0:	e822                	sd	s0,16(sp)
    800027b2:	e426                	sd	s1,8(sp)
    800027b4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ba:	00074d63          	bltz	a4,800027d4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027be:	57fd                	li	a5,-1
    800027c0:	17fe                	slli	a5,a5,0x3f
    800027c2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c6:	06f70363          	beq	a4,a5,8000282c <devintr+0x80>
  }
}
    800027ca:	60e2                	ld	ra,24(sp)
    800027cc:	6442                	ld	s0,16(sp)
    800027ce:	64a2                	ld	s1,8(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret
     (scause & 0xff) == 9){
    800027d4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027d8:	46a5                	li	a3,9
    800027da:	fed792e3          	bne	a5,a3,800027be <devintr+0x12>
    int irq = plic_claim();
    800027de:	00003097          	auipc	ra,0x3
    800027e2:	65a080e7          	jalr	1626(ra) # 80005e38 <plic_claim>
    800027e6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e8:	47a9                	li	a5,10
    800027ea:	02f50763          	beq	a0,a5,80002818 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ee:	4785                	li	a5,1
    800027f0:	02f50963          	beq	a0,a5,80002822 <devintr+0x76>
    return 1;
    800027f4:	4505                	li	a0,1
    } else if(irq){
    800027f6:	d8f1                	beqz	s1,800027ca <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f8:	85a6                	mv	a1,s1
    800027fa:	00006517          	auipc	a0,0x6
    800027fe:	ade50513          	addi	a0,a0,-1314 # 800082d8 <states.0+0x30>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	d8a080e7          	jalr	-630(ra) # 8000058c <printf>
      plic_complete(irq);
    8000280a:	8526                	mv	a0,s1
    8000280c:	00003097          	auipc	ra,0x3
    80002810:	650080e7          	jalr	1616(ra) # 80005e5c <plic_complete>
    return 1;
    80002814:	4505                	li	a0,1
    80002816:	bf55                	j	800027ca <devintr+0x1e>
      uartintr();
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	1aa080e7          	jalr	426(ra) # 800009c2 <uartintr>
    80002820:	b7ed                	j	8000280a <devintr+0x5e>
      virtio_disk_intr();
    80002822:	00004097          	auipc	ra,0x4
    80002826:	ab4080e7          	jalr	-1356(ra) # 800062d6 <virtio_disk_intr>
    8000282a:	b7c5                	j	8000280a <devintr+0x5e>
    if(cpuid() == 0){
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	1c4080e7          	jalr	452(ra) # 800019f0 <cpuid>
    80002834:	c901                	beqz	a0,80002844 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002836:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000283a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000283c:	14479073          	csrw	sip,a5
    return 2;
    80002840:	4509                	li	a0,2
    80002842:	b761                	j	800027ca <devintr+0x1e>
      clockintr();
    80002844:	00000097          	auipc	ra,0x0
    80002848:	f22080e7          	jalr	-222(ra) # 80002766 <clockintr>
    8000284c:	b7ed                	j	80002836 <devintr+0x8a>

000000008000284e <usertrap>:
{
    8000284e:	1101                	addi	sp,sp,-32
    80002850:	ec06                	sd	ra,24(sp)
    80002852:	e822                	sd	s0,16(sp)
    80002854:	e426                	sd	s1,8(sp)
    80002856:	e04a                	sd	s2,0(sp)
    80002858:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285e:	1007f793          	andi	a5,a5,256
    80002862:	e3ad                	bnez	a5,800028c4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002864:	00003797          	auipc	a5,0x3
    80002868:	4cc78793          	addi	a5,a5,1228 # 80005d30 <kernelvec>
    8000286c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	1ac080e7          	jalr	428(ra) # 80001a1c <myproc>
    80002878:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000287a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287c:	14102773          	csrr	a4,sepc
    80002880:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002882:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002886:	47a1                	li	a5,8
    80002888:	04f71c63          	bne	a4,a5,800028e0 <usertrap+0x92>
    if(p->killed)
    8000288c:	591c                	lw	a5,48(a0)
    8000288e:	e3b9                	bnez	a5,800028d4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002890:	6cb8                	ld	a4,88(s1)
    80002892:	6f1c                	ld	a5,24(a4)
    80002894:	0791                	addi	a5,a5,4
    80002896:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002898:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000289c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a0:	10079073          	csrw	sstatus,a5
    syscall();
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	3d4080e7          	jalr	980(ra) # 80002c78 <syscall>
  if(p->killed)
    800028ac:	589c                	lw	a5,48(s1)
    800028ae:	ebc1                	bnez	a5,8000293e <usertrap+0xf0>
  usertrapret();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	e18080e7          	jalr	-488(ra) # 800026c8 <usertrapret>
}
    800028b8:	60e2                	ld	ra,24(sp)
    800028ba:	6442                	ld	s0,16(sp)
    800028bc:	64a2                	ld	s1,8(sp)
    800028be:	6902                	ld	s2,0(sp)
    800028c0:	6105                	addi	sp,sp,32
    800028c2:	8082                	ret
    panic("usertrap: not from user mode");
    800028c4:	00006517          	auipc	a0,0x6
    800028c8:	a3450513          	addi	a0,a0,-1484 # 800082f8 <states.0+0x50>
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	c76080e7          	jalr	-906(ra) # 80000542 <panic>
      exit(-1);
    800028d4:	557d                	li	a0,-1
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	818080e7          	jalr	-2024(ra) # 800020ee <exit>
    800028de:	bf4d                	j	80002890 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	ecc080e7          	jalr	-308(ra) # 800027ac <devintr>
    800028e8:	892a                	mv	s2,a0
    800028ea:	c501                	beqz	a0,800028f2 <usertrap+0xa4>
  if(p->killed)
    800028ec:	589c                	lw	a5,48(s1)
    800028ee:	c3a1                	beqz	a5,8000292e <usertrap+0xe0>
    800028f0:	a815                	j	80002924 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028f6:	5c90                	lw	a2,56(s1)
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a2050513          	addi	a0,a0,-1504 # 80008318 <states.0+0x70>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c8c080e7          	jalr	-884(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002908:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000290c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a3850513          	addi	a0,a0,-1480 # 80008348 <states.0+0xa0>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c74080e7          	jalr	-908(ra) # 8000058c <printf>
    p->killed = 1;
    80002920:	4785                	li	a5,1
    80002922:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002924:	557d                	li	a0,-1
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	7c8080e7          	jalr	1992(ra) # 800020ee <exit>
  if(which_dev == 2)
    8000292e:	4789                	li	a5,2
    80002930:	f8f910e3          	bne	s2,a5,800028b0 <usertrap+0x62>
    yield();
    80002934:	00000097          	auipc	ra,0x0
    80002938:	8c4080e7          	jalr	-1852(ra) # 800021f8 <yield>
    8000293c:	bf95                	j	800028b0 <usertrap+0x62>
  int which_dev = 0;
    8000293e:	4901                	li	s2,0
    80002940:	b7d5                	j	80002924 <usertrap+0xd6>

0000000080002942 <kerneltrap>:
{
    80002942:	7179                	addi	sp,sp,-48
    80002944:	f406                	sd	ra,40(sp)
    80002946:	f022                	sd	s0,32(sp)
    80002948:	ec26                	sd	s1,24(sp)
    8000294a:	e84a                	sd	s2,16(sp)
    8000294c:	e44e                	sd	s3,8(sp)
    8000294e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002958:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000295c:	1004f793          	andi	a5,s1,256
    80002960:	cb85                	beqz	a5,80002990 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002962:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002966:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002968:	ef85                	bnez	a5,800029a0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	e42080e7          	jalr	-446(ra) # 800027ac <devintr>
    80002972:	cd1d                	beqz	a0,800029b0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002974:	4789                	li	a5,2
    80002976:	06f50a63          	beq	a0,a5,800029ea <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297e:	10049073          	csrw	sstatus,s1
}
    80002982:	70a2                	ld	ra,40(sp)
    80002984:	7402                	ld	s0,32(sp)
    80002986:	64e2                	ld	s1,24(sp)
    80002988:	6942                	ld	s2,16(sp)
    8000298a:	69a2                	ld	s3,8(sp)
    8000298c:	6145                	addi	sp,sp,48
    8000298e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002990:	00006517          	auipc	a0,0x6
    80002994:	9d850513          	addi	a0,a0,-1576 # 80008368 <states.0+0xc0>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	baa080e7          	jalr	-1110(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	9f050513          	addi	a0,a0,-1552 # 80008390 <states.0+0xe8>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	b9a080e7          	jalr	-1126(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    800029b0:	85ce                	mv	a1,s3
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	9fe50513          	addi	a0,a0,-1538 # 800083b0 <states.0+0x108>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bd2080e7          	jalr	-1070(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9f650513          	addi	a0,a0,-1546 # 800083c0 <states.0+0x118>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bba080e7          	jalr	-1094(ra) # 8000058c <printf>
    panic("kerneltrap");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	9fe50513          	addi	a0,a0,-1538 # 800083d8 <states.0+0x130>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	b60080e7          	jalr	-1184(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	032080e7          	jalr	50(ra) # 80001a1c <myproc>
    800029f2:	d541                	beqz	a0,8000297a <kerneltrap+0x38>
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	028080e7          	jalr	40(ra) # 80001a1c <myproc>
    800029fc:	4d58                	lw	a4,28(a0)
    800029fe:	478d                	li	a5,3
    80002a00:	f6f71de3          	bne	a4,a5,8000297a <kerneltrap+0x38>
    yield();
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	7f4080e7          	jalr	2036(ra) # 800021f8 <yield>
    80002a0c:	b7bd                	j	8000297a <kerneltrap+0x38>

0000000080002a0e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a0e:	1101                	addi	sp,sp,-32
    80002a10:	ec06                	sd	ra,24(sp)
    80002a12:	e822                	sd	s0,16(sp)
    80002a14:	e426                	sd	s1,8(sp)
    80002a16:	1000                	addi	s0,sp,32
    80002a18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	002080e7          	jalr	2(ra) # 80001a1c <myproc>
  switch (n) {
    80002a22:	4795                	li	a5,5
    80002a24:	0497e163          	bltu	a5,s1,80002a66 <argraw+0x58>
    80002a28:	048a                	slli	s1,s1,0x2
    80002a2a:	00006717          	auipc	a4,0x6
    80002a2e:	ade70713          	addi	a4,a4,-1314 # 80008508 <states.0+0x260>
    80002a32:	94ba                	add	s1,s1,a4
    80002a34:	409c                	lw	a5,0(s1)
    80002a36:	97ba                	add	a5,a5,a4
    80002a38:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a3a:	6d3c                	ld	a5,88(a0)
    80002a3c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a3e:	60e2                	ld	ra,24(sp)
    80002a40:	6442                	ld	s0,16(sp)
    80002a42:	64a2                	ld	s1,8(sp)
    80002a44:	6105                	addi	sp,sp,32
    80002a46:	8082                	ret
    return p->trapframe->a1;
    80002a48:	6d3c                	ld	a5,88(a0)
    80002a4a:	7fa8                	ld	a0,120(a5)
    80002a4c:	bfcd                	j	80002a3e <argraw+0x30>
    return p->trapframe->a2;
    80002a4e:	6d3c                	ld	a5,88(a0)
    80002a50:	63c8                	ld	a0,128(a5)
    80002a52:	b7f5                	j	80002a3e <argraw+0x30>
    return p->trapframe->a3;
    80002a54:	6d3c                	ld	a5,88(a0)
    80002a56:	67c8                	ld	a0,136(a5)
    80002a58:	b7dd                	j	80002a3e <argraw+0x30>
    return p->trapframe->a4;
    80002a5a:	6d3c                	ld	a5,88(a0)
    80002a5c:	6bc8                	ld	a0,144(a5)
    80002a5e:	b7c5                	j	80002a3e <argraw+0x30>
    return p->trapframe->a5;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	6fc8                	ld	a0,152(a5)
    80002a64:	bfe9                	j	80002a3e <argraw+0x30>
  panic("argraw");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	98250513          	addi	a0,a0,-1662 # 800083e8 <states.0+0x140>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	ad4080e7          	jalr	-1324(ra) # 80000542 <panic>

0000000080002a76 <fetchaddr>:
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	e04a                	sd	s2,0(sp)
    80002a80:	1000                	addi	s0,sp,32
    80002a82:	84aa                	mv	s1,a0
    80002a84:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f96080e7          	jalr	-106(ra) # 80001a1c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a8e:	653c                	ld	a5,72(a0)
    80002a90:	02f4f863          	bgeu	s1,a5,80002ac0 <fetchaddr+0x4a>
    80002a94:	00848713          	addi	a4,s1,8
    80002a98:	02e7e663          	bltu	a5,a4,80002ac4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a9c:	46a1                	li	a3,8
    80002a9e:	8626                	mv	a2,s1
    80002aa0:	85ca                	mv	a1,s2
    80002aa2:	6928                	ld	a0,80(a0)
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	cf6080e7          	jalr	-778(ra) # 8000179a <copyin>
    80002aac:	00a03533          	snez	a0,a0
    80002ab0:	40a00533          	neg	a0,a0
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6902                	ld	s2,0(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret
    return -1;
    80002ac0:	557d                	li	a0,-1
    80002ac2:	bfcd                	j	80002ab4 <fetchaddr+0x3e>
    80002ac4:	557d                	li	a0,-1
    80002ac6:	b7fd                	j	80002ab4 <fetchaddr+0x3e>

0000000080002ac8 <fetchstr>:
{
    80002ac8:	7179                	addi	sp,sp,-48
    80002aca:	f406                	sd	ra,40(sp)
    80002acc:	f022                	sd	s0,32(sp)
    80002ace:	ec26                	sd	s1,24(sp)
    80002ad0:	e84a                	sd	s2,16(sp)
    80002ad2:	e44e                	sd	s3,8(sp)
    80002ad4:	1800                	addi	s0,sp,48
    80002ad6:	892a                	mv	s2,a0
    80002ad8:	84ae                	mv	s1,a1
    80002ada:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	f40080e7          	jalr	-192(ra) # 80001a1c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ae4:	86ce                	mv	a3,s3
    80002ae6:	864a                	mv	a2,s2
    80002ae8:	85a6                	mv	a1,s1
    80002aea:	6928                	ld	a0,80(a0)
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	d3c080e7          	jalr	-708(ra) # 80001828 <copyinstr>
  if(err < 0)
    80002af4:	00054763          	bltz	a0,80002b02 <fetchstr+0x3a>
  return strlen(buf);
    80002af8:	8526                	mv	a0,s1
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	3d6080e7          	jalr	982(ra) # 80000ed0 <strlen>
}
    80002b02:	70a2                	ld	ra,40(sp)
    80002b04:	7402                	ld	s0,32(sp)
    80002b06:	64e2                	ld	s1,24(sp)
    80002b08:	6942                	ld	s2,16(sp)
    80002b0a:	69a2                	ld	s3,8(sp)
    80002b0c:	6145                	addi	sp,sp,48
    80002b0e:	8082                	ret

0000000080002b10 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	e426                	sd	s1,8(sp)
    80002b18:	1000                	addi	s0,sp,32
    80002b1a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	ef2080e7          	jalr	-270(ra) # 80002a0e <argraw>
    80002b24:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b26:	4501                	li	a0,0
    80002b28:	60e2                	ld	ra,24(sp)
    80002b2a:	6442                	ld	s0,16(sp)
    80002b2c:	64a2                	ld	s1,8(sp)
    80002b2e:	6105                	addi	sp,sp,32
    80002b30:	8082                	ret

0000000080002b32 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
    80002b3c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b3e:	00000097          	auipc	ra,0x0
    80002b42:	ed0080e7          	jalr	-304(ra) # 80002a0e <argraw>
    80002b46:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b48:	4501                	li	a0,0
    80002b4a:	60e2                	ld	ra,24(sp)
    80002b4c:	6442                	ld	s0,16(sp)
    80002b4e:	64a2                	ld	s1,8(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b54:	7179                	addi	sp,sp,-48
    80002b56:	f406                	sd	ra,40(sp)
    80002b58:	f022                	sd	s0,32(sp)
    80002b5a:	ec26                	sd	s1,24(sp)
    80002b5c:	e84a                	sd	s2,16(sp)
    80002b5e:	1800                	addi	s0,sp,48
    80002b60:	84ae                	mv	s1,a1
    80002b62:	8932                	mv	s2,a2
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    80002b64:	fd840593          	addi	a1,s0,-40
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	fca080e7          	jalr	-54(ra) # 80002b32 <argaddr>
    80002b70:	02054063          	bltz	a0,80002b90 <argstr+0x3c>
    return -1;
  return fetchstr(addr, buf, max);
    80002b74:	864a                	mv	a2,s2
    80002b76:	85a6                	mv	a1,s1
    80002b78:	fd843503          	ld	a0,-40(s0)
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	f4c080e7          	jalr	-180(ra) # 80002ac8 <fetchstr>
}
    80002b84:	70a2                	ld	ra,40(sp)
    80002b86:	7402                	ld	s0,32(sp)
    80002b88:	64e2                	ld	s1,24(sp)
    80002b8a:	6942                	ld	s2,16(sp)
    80002b8c:	6145                	addi	sp,sp,48
    80002b8e:	8082                	ret
    return -1;
    80002b90:	557d                	li	a0,-1
    80002b92:	bfcd                	j	80002b84 <argstr+0x30>

0000000080002b94 <check_arg>:
[SYS_close]   000003,
[SYS_trace]   000000,
[SYS_sysinfo] 000002,
};

void check_arg(int num){
    80002b94:	7115                	addi	sp,sp,-224
    80002b96:	ed86                	sd	ra,216(sp)
    80002b98:	e9a2                	sd	s0,208(sp)
    80002b9a:	e5a6                	sd	s1,200(sp)
    80002b9c:	e1ca                	sd	s2,192(sp)
    80002b9e:	fd4e                	sd	s3,184(sp)
    80002ba0:	f952                	sd	s4,176(sp)
    80002ba2:	f556                	sd	s5,168(sp)
    80002ba4:	f15a                	sd	s6,160(sp)
    80002ba6:	ed5e                	sd	s7,152(sp)
    80002ba8:	1180                	addi	s0,sp,224
  int arg_sum = syscalls_argv[num];
    80002baa:	00251793          	slli	a5,a0,0x2
    80002bae:	00006517          	auipc	a0,0x6
    80002bb2:	97250513          	addi	a0,a0,-1678 # 80008520 <syscalls_argv>
    80002bb6:	953e                	add	a0,a0,a5
    80002bb8:	4104                	lw	s1,0(a0)

  if(arg_sum == 0){
    80002bba:	cc91                	beqz	s1,80002bd6 <check_arg+0x42>
    80002bbc:	4901                	li	s2,0
  uint64 addr;
  //struct file *f;
  char path[MAXPATH];

  while(arg_sum != 0){
    int tmp = arg_sum%10;
    80002bbe:	49a9                	li	s3,10
    arg_sum /= 10;
    switch (tmp)
    80002bc0:	4a89                	li	s5,2
      argint(idx, &p);
      printf("arg%d: %d ", idx, p);
      break;
    case 2:
      argaddr(idx, &addr);
      printf("arg%d: %d ", idx, addr);
    80002bc2:	00006b17          	auipc	s6,0x6
    80002bc6:	83eb0b13          	addi	s6,s6,-1986 # 80008400 <states.0+0x158>
    switch (tmp)
    80002bca:	4a11                	li	s4,4
      /*argfd(idx, 0, &f);
      printf("arg%d: %d ", idx, f->ref);*/
      break;
    case 4:
      argstr(idx, path, MAXPATH);
      printf("arg%d: %s ", idx, path);
    80002bcc:	00006b97          	auipc	s7,0x6
    80002bd0:	844b8b93          	addi	s7,s7,-1980 # 80008410 <states.0+0x168>
    80002bd4:	a0a9                	j	80002c1e <check_arg+0x8a>
    printf("no args!");
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	81a50513          	addi	a0,a0,-2022 # 800083f0 <states.0+0x148>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ae080e7          	jalr	-1618(ra) # 8000058c <printf>
    }
    idx++;
  }

  return;
}
    80002be6:	60ee                	ld	ra,216(sp)
    80002be8:	644e                	ld	s0,208(sp)
    80002bea:	64ae                	ld	s1,200(sp)
    80002bec:	690e                	ld	s2,192(sp)
    80002bee:	79ea                	ld	s3,184(sp)
    80002bf0:	7a4a                	ld	s4,176(sp)
    80002bf2:	7aaa                	ld	s5,168(sp)
    80002bf4:	7b0a                	ld	s6,160(sp)
    80002bf6:	6bea                	ld	s7,152(sp)
    80002bf8:	612d                	addi	sp,sp,224
    80002bfa:	8082                	ret
      argaddr(idx, &addr);
    80002bfc:	fa040593          	addi	a1,s0,-96
    80002c00:	854a                	mv	a0,s2
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	f30080e7          	jalr	-208(ra) # 80002b32 <argaddr>
      printf("arg%d: %d ", idx, addr);
    80002c0a:	fa043603          	ld	a2,-96(s0)
    80002c0e:	85ca                	mv	a1,s2
    80002c10:	855a                	mv	a0,s6
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	97a080e7          	jalr	-1670(ra) # 8000058c <printf>
    idx++;
    80002c1a:	2905                	addiw	s2,s2,1
  while(arg_sum != 0){
    80002c1c:	d4e9                	beqz	s1,80002be6 <check_arg+0x52>
    int tmp = arg_sum%10;
    80002c1e:	0334e7bb          	remw	a5,s1,s3
    arg_sum /= 10;
    80002c22:	0334c4bb          	divw	s1,s1,s3
    switch (tmp)
    80002c26:	fd578be3          	beq	a5,s5,80002bfc <check_arg+0x68>
    80002c2a:	03478563          	beq	a5,s4,80002c54 <check_arg+0xc0>
    80002c2e:	4705                	li	a4,1
    80002c30:	fee795e3          	bne	a5,a4,80002c1a <check_arg+0x86>
      argint(idx, &p);
    80002c34:	fac40593          	addi	a1,s0,-84
    80002c38:	854a                	mv	a0,s2
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	ed6080e7          	jalr	-298(ra) # 80002b10 <argint>
      printf("arg%d: %d ", idx, p);
    80002c42:	fac42603          	lw	a2,-84(s0)
    80002c46:	85ca                	mv	a1,s2
    80002c48:	855a                	mv	a0,s6
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	942080e7          	jalr	-1726(ra) # 8000058c <printf>
      break;
    80002c52:	b7e1                	j	80002c1a <check_arg+0x86>
      argstr(idx, path, MAXPATH);
    80002c54:	08000613          	li	a2,128
    80002c58:	f2040593          	addi	a1,s0,-224
    80002c5c:	854a                	mv	a0,s2
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	ef6080e7          	jalr	-266(ra) # 80002b54 <argstr>
      printf("arg%d: %s ", idx, path);
    80002c66:	f2040613          	addi	a2,s0,-224
    80002c6a:	85ca                	mv	a1,s2
    80002c6c:	855e                	mv	a0,s7
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	91e080e7          	jalr	-1762(ra) # 8000058c <printf>
      break;      
    80002c76:	b755                	j	80002c1a <check_arg+0x86>

0000000080002c78 <syscall>:

void
syscall(void)
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	d96080e7          	jalr	-618(ra) # 80001a1c <myproc>
    80002c8e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c90:	6d38                	ld	a4,88(a0)
    80002c92:	775c                	ld	a5,168(a4)
    80002c94:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c98:	37fd                	addiw	a5,a5,-1
    80002c9a:	46d9                	li	a3,22
    80002c9c:	06f6e563          	bltu	a3,a5,80002d06 <syscall+0x8e>
    80002ca0:	00391693          	slli	a3,s2,0x3
    80002ca4:	00006797          	auipc	a5,0x6
    80002ca8:	87c78793          	addi	a5,a5,-1924 # 80008520 <syscalls_argv>
    80002cac:	97b6                	add	a5,a5,a3
    80002cae:	0607b983          	ld	s3,96(a5)
    80002cb2:	04098a63          	beqz	s3,80002d06 <syscall+0x8e>
    

    // 根据追踪的函数调用触发
    if((1 << num) & p->trace_mask){
    80002cb6:	4d1c                	lw	a5,24(a0)
    80002cb8:	4127d7bb          	sraw	a5,a5,s2
    80002cbc:	8b85                	andi	a5,a5,1
    80002cbe:	e789                	bnez	a5,80002cc8 <syscall+0x50>
      printf("%d: syscall %s -> %d，",p->pid, syscalls_name[num], p->trapframe->a0);
      check_arg(num);
      printf("\n");
    }

    p->trapframe->a0 = syscalls[num](); 
    80002cc0:	6ca4                	ld	s1,88(s1)
    80002cc2:	9982                	jalr	s3
    80002cc4:	f8a8                	sd	a0,112(s1)
    80002cc6:	a8b9                	j	80002d24 <syscall+0xac>
      printf("%d: syscall %s -> %d，",p->pid, syscalls_name[num], p->trapframe->a0);
    80002cc8:	00006797          	auipc	a5,0x6
    80002ccc:	85878793          	addi	a5,a5,-1960 # 80008520 <syscalls_argv>
    80002cd0:	97b6                	add	a5,a5,a3
    80002cd2:	7b34                	ld	a3,112(a4)
    80002cd4:	1207b603          	ld	a2,288(a5)
    80002cd8:	5d0c                	lw	a1,56(a0)
    80002cda:	00005517          	auipc	a0,0x5
    80002cde:	74650513          	addi	a0,a0,1862 # 80008420 <states.0+0x178>
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	8aa080e7          	jalr	-1878(ra) # 8000058c <printf>
      check_arg(num);
    80002cea:	854a                	mv	a0,s2
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	ea8080e7          	jalr	-344(ra) # 80002b94 <check_arg>
      printf("\n");
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	3d450513          	addi	a0,a0,980 # 800080c8 <digits+0x88>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	890080e7          	jalr	-1904(ra) # 8000058c <printf>
    80002d04:	bf75                	j	80002cc0 <syscall+0x48>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d06:	86ca                	mv	a3,s2
    80002d08:	15848613          	addi	a2,s1,344
    80002d0c:	5c8c                	lw	a1,56(s1)
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	72a50513          	addi	a0,a0,1834 # 80008438 <states.0+0x190>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	876080e7          	jalr	-1930(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d1e:	6cbc                	ld	a5,88(s1)
    80002d20:	577d                	li	a4,-1
    80002d22:	fbb8                	sd	a4,112(a5)
  }
}
    80002d24:	70a2                	ld	ra,40(sp)
    80002d26:	7402                	ld	s0,32(sp)
    80002d28:	64e2                	ld	s1,24(sp)
    80002d2a:	6942                	ld	s2,16(sp)
    80002d2c:	69a2                	ld	s3,8(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret

0000000080002d32 <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d3a:	fec40593          	addi	a1,s0,-20
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	dd0080e7          	jalr	-560(ra) # 80002b10 <argint>
    return -1;
    80002d48:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d4a:	00054963          	bltz	a0,80002d5c <sys_exit+0x2a>
  exit(n);
    80002d4e:	fec42503          	lw	a0,-20(s0)
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	39c080e7          	jalr	924(ra) # 800020ee <exit>
  return 0;  // not reached
    80002d5a:	4781                	li	a5,0
}
    80002d5c:	853e                	mv	a0,a5
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret

0000000080002d66 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d66:	1141                	addi	sp,sp,-16
    80002d68:	e406                	sd	ra,8(sp)
    80002d6a:	e022                	sd	s0,0(sp)
    80002d6c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	cae080e7          	jalr	-850(ra) # 80001a1c <myproc>
}
    80002d76:	5d08                	lw	a0,56(a0)
    80002d78:	60a2                	ld	ra,8(sp)
    80002d7a:	6402                	ld	s0,0(sp)
    80002d7c:	0141                	addi	sp,sp,16
    80002d7e:	8082                	ret

0000000080002d80 <sys_fork>:

uint64
sys_fork(void)
{
    80002d80:	1141                	addi	sp,sp,-16
    80002d82:	e406                	sd	ra,8(sp)
    80002d84:	e022                	sd	s0,0(sp)
    80002d86:	0800                	addi	s0,sp,16
  return fork();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	054080e7          	jalr	84(ra) # 80001ddc <fork>
}
    80002d90:	60a2                	ld	ra,8(sp)
    80002d92:	6402                	ld	s0,0(sp)
    80002d94:	0141                	addi	sp,sp,16
    80002d96:	8082                	ret

0000000080002d98 <sys_wait>:

uint64
sys_wait(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002da0:	fe840593          	addi	a1,s0,-24
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	d8c080e7          	jalr	-628(ra) # 80002b32 <argaddr>
    80002dae:	87aa                	mv	a5,a0
    return -1;
    80002db0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002db2:	0007c863          	bltz	a5,80002dc2 <sys_wait+0x2a>
  return wait(p);
    80002db6:	fe843503          	ld	a0,-24(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	4f8080e7          	jalr	1272(ra) # 800022b2 <wait>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dd4:	fdc40593          	addi	a1,s0,-36
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	d36080e7          	jalr	-714(ra) # 80002b10 <argint>
    return -1;
    80002de2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002de4:	00054f63          	bltz	a0,80002e02 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	c34080e7          	jalr	-972(ra) # 80001a1c <myproc>
    80002df0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002df2:	fdc42503          	lw	a0,-36(s0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	f72080e7          	jalr	-142(ra) # 80001d68 <growproc>
    80002dfe:	00054863          	bltz	a0,80002e0e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e02:	8526                	mv	a0,s1
    80002e04:	70a2                	ld	ra,40(sp)
    80002e06:	7402                	ld	s0,32(sp)
    80002e08:	64e2                	ld	s1,24(sp)
    80002e0a:	6145                	addi	sp,sp,48
    80002e0c:	8082                	ret
    return -1;
    80002e0e:	54fd                	li	s1,-1
    80002e10:	bfcd                	j	80002e02 <sys_sbrk+0x38>

0000000080002e12 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e12:	7139                	addi	sp,sp,-64
    80002e14:	fc06                	sd	ra,56(sp)
    80002e16:	f822                	sd	s0,48(sp)
    80002e18:	f426                	sd	s1,40(sp)
    80002e1a:	f04a                	sd	s2,32(sp)
    80002e1c:	ec4e                	sd	s3,24(sp)
    80002e1e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e20:	fcc40593          	addi	a1,s0,-52
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	cea080e7          	jalr	-790(ra) # 80002b10 <argint>
    return -1;
    80002e2e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e30:	06054563          	bltz	a0,80002e9a <sys_sleep+0x88>
  acquire(&tickslock);
    80002e34:	00015517          	auipc	a0,0x15
    80002e38:	93450513          	addi	a0,a0,-1740 # 80017768 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	e14080e7          	jalr	-492(ra) # 80000c50 <acquire>
  ticks0 = ticks;
    80002e44:	00006917          	auipc	s2,0x6
    80002e48:	1dc92903          	lw	s2,476(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e4c:	fcc42783          	lw	a5,-52(s0)
    80002e50:	cf85                	beqz	a5,80002e88 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e52:	00015997          	auipc	s3,0x15
    80002e56:	91698993          	addi	s3,s3,-1770 # 80017768 <tickslock>
    80002e5a:	00006497          	auipc	s1,0x6
    80002e5e:	1c648493          	addi	s1,s1,454 # 80009020 <ticks>
    if(myproc()->killed){
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	bba080e7          	jalr	-1094(ra) # 80001a1c <myproc>
    80002e6a:	591c                	lw	a5,48(a0)
    80002e6c:	ef9d                	bnez	a5,80002eaa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e6e:	85ce                	mv	a1,s3
    80002e70:	8526                	mv	a0,s1
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	3c2080e7          	jalr	962(ra) # 80002234 <sleep>
  while(ticks - ticks0 < n){
    80002e7a:	409c                	lw	a5,0(s1)
    80002e7c:	412787bb          	subw	a5,a5,s2
    80002e80:	fcc42703          	lw	a4,-52(s0)
    80002e84:	fce7efe3          	bltu	a5,a4,80002e62 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e88:	00015517          	auipc	a0,0x15
    80002e8c:	8e050513          	addi	a0,a0,-1824 # 80017768 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	e74080e7          	jalr	-396(ra) # 80000d04 <release>
  return 0;
    80002e98:	4781                	li	a5,0
}
    80002e9a:	853e                	mv	a0,a5
    80002e9c:	70e2                	ld	ra,56(sp)
    80002e9e:	7442                	ld	s0,48(sp)
    80002ea0:	74a2                	ld	s1,40(sp)
    80002ea2:	7902                	ld	s2,32(sp)
    80002ea4:	69e2                	ld	s3,24(sp)
    80002ea6:	6121                	addi	sp,sp,64
    80002ea8:	8082                	ret
      release(&tickslock);
    80002eaa:	00015517          	auipc	a0,0x15
    80002eae:	8be50513          	addi	a0,a0,-1858 # 80017768 <tickslock>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	e52080e7          	jalr	-430(ra) # 80000d04 <release>
      return -1;
    80002eba:	57fd                	li	a5,-1
    80002ebc:	bff9                	j	80002e9a <sys_sleep+0x88>

0000000080002ebe <sys_kill>:

uint64
sys_kill(void)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ec6:	fec40593          	addi	a1,s0,-20
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	c44080e7          	jalr	-956(ra) # 80002b10 <argint>
    80002ed4:	87aa                	mv	a5,a0
    return -1;
    80002ed6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ed8:	0007c863          	bltz	a5,80002ee8 <sys_kill+0x2a>
  return kill(pid);
    80002edc:	fec42503          	lw	a0,-20(s0)
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	53e080e7          	jalr	1342(ra) # 8000241e <kill>
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	e426                	sd	s1,8(sp)
    80002ef8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002efa:	00015517          	auipc	a0,0x15
    80002efe:	86e50513          	addi	a0,a0,-1938 # 80017768 <tickslock>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	d4e080e7          	jalr	-690(ra) # 80000c50 <acquire>
  xticks = ticks;
    80002f0a:	00006497          	auipc	s1,0x6
    80002f0e:	1164a483          	lw	s1,278(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f12:	00015517          	auipc	a0,0x15
    80002f16:	85650513          	addi	a0,a0,-1962 # 80017768 <tickslock>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	dea080e7          	jalr	-534(ra) # 80000d04 <release>
  return xticks;
}
    80002f22:	02049513          	slli	a0,s1,0x20
    80002f26:	9101                	srli	a0,a0,0x20
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6105                	addi	sp,sp,32
    80002f30:	8082                	ret

0000000080002f32 <sys_trace>:

//trace sys
uint64
sys_trace(void){
    80002f32:	1141                	addi	sp,sp,-16
    80002f34:	e406                	sd	ra,8(sp)
    80002f36:	e022                	sd	s0,0(sp)
    80002f38:	0800                	addi	s0,sp,16
  //gain sys used arg
  argint(0, &(myproc()->trace_mask));
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	ae2080e7          	jalr	-1310(ra) # 80001a1c <myproc>
    80002f42:	01850593          	addi	a1,a0,24
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	bc8080e7          	jalr	-1080(ra) # 80002b10 <argint>
  return 0;
}
    80002f50:	4501                	li	a0,0
    80002f52:	60a2                	ld	ra,8(sp)
    80002f54:	6402                	ld	s0,0(sp)
    80002f56:	0141                	addi	sp,sp,16
    80002f58:	8082                	ret

0000000080002f5a <sys_sysinfo>:

uint64
sys_sysinfo(void){
    80002f5a:	7179                	addi	sp,sp,-48
    80002f5c:	f406                	sd	ra,40(sp)
    80002f5e:	f022                	sd	s0,32(sp)
    80002f60:	1800                	addi	s0,sp,48
  struct sysinfo info;
  freebytes(&info.freemem);
    80002f62:	fe040513          	addi	a0,s0,-32
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	c08080e7          	jalr	-1016(ra) # 80000b6e <freebytes>
  procnum(&info.nproc);
    80002f6e:	fe840513          	addi	a0,s0,-24
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	676080e7          	jalr	1654(ra) # 800025e8 <procnum>

  uint64 dstaddr;
  argaddr(0, &dstaddr);
    80002f7a:	fd840593          	addi	a1,s0,-40
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	bb2080e7          	jalr	-1102(ra) # 80002b32 <argaddr>

  if(copyout(myproc()->pagetable, dstaddr, (char *)&info, sizeof info) < 0)
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	a94080e7          	jalr	-1388(ra) # 80001a1c <myproc>
    80002f90:	46c1                	li	a3,16
    80002f92:	fe040613          	addi	a2,s0,-32
    80002f96:	fd843583          	ld	a1,-40(s0)
    80002f9a:	6928                	ld	a0,80(a0)
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	772080e7          	jalr	1906(ra) # 8000170e <copyout>
    return -1;

  return 0;
}
    80002fa4:	957d                	srai	a0,a0,0x3f
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	6145                	addi	sp,sp,48
    80002fac:	8082                	ret

0000000080002fae <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fae:	7179                	addi	sp,sp,-48
    80002fb0:	f406                	sd	ra,40(sp)
    80002fb2:	f022                	sd	s0,32(sp)
    80002fb4:	ec26                	sd	s1,24(sp)
    80002fb6:	e84a                	sd	s2,16(sp)
    80002fb8:	e44e                	sd	s3,8(sp)
    80002fba:	e052                	sd	s4,0(sp)
    80002fbc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fbe:	00005597          	auipc	a1,0x5
    80002fc2:	74258593          	addi	a1,a1,1858 # 80008700 <syscalls_name+0xc0>
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	7ba50513          	addi	a0,a0,1978 # 80017780 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	bf2080e7          	jalr	-1038(ra) # 80000bc0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fd6:	0001c797          	auipc	a5,0x1c
    80002fda:	7aa78793          	addi	a5,a5,1962 # 8001f780 <bcache+0x8000>
    80002fde:	0001d717          	auipc	a4,0x1d
    80002fe2:	a0a70713          	addi	a4,a4,-1526 # 8001f9e8 <bcache+0x8268>
    80002fe6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fea:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fee:	00014497          	auipc	s1,0x14
    80002ff2:	7aa48493          	addi	s1,s1,1962 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ff6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ff8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ffa:	00005a17          	auipc	s4,0x5
    80002ffe:	70ea0a13          	addi	s4,s4,1806 # 80008708 <syscalls_name+0xc8>
    b->next = bcache.head.next;
    80003002:	2b893783          	ld	a5,696(s2)
    80003006:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003008:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000300c:	85d2                	mv	a1,s4
    8000300e:	01048513          	addi	a0,s1,16
    80003012:	00001097          	auipc	ra,0x1
    80003016:	4ac080e7          	jalr	1196(ra) # 800044be <initsleeplock>
    bcache.head.next->prev = b;
    8000301a:	2b893783          	ld	a5,696(s2)
    8000301e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003020:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003024:	45848493          	addi	s1,s1,1112
    80003028:	fd349de3          	bne	s1,s3,80003002 <binit+0x54>
  }
}
    8000302c:	70a2                	ld	ra,40(sp)
    8000302e:	7402                	ld	s0,32(sp)
    80003030:	64e2                	ld	s1,24(sp)
    80003032:	6942                	ld	s2,16(sp)
    80003034:	69a2                	ld	s3,8(sp)
    80003036:	6a02                	ld	s4,0(sp)
    80003038:	6145                	addi	sp,sp,48
    8000303a:	8082                	ret

000000008000303c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000303c:	7179                	addi	sp,sp,-48
    8000303e:	f406                	sd	ra,40(sp)
    80003040:	f022                	sd	s0,32(sp)
    80003042:	ec26                	sd	s1,24(sp)
    80003044:	e84a                	sd	s2,16(sp)
    80003046:	e44e                	sd	s3,8(sp)
    80003048:	1800                	addi	s0,sp,48
    8000304a:	892a                	mv	s2,a0
    8000304c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000304e:	00014517          	auipc	a0,0x14
    80003052:	73250513          	addi	a0,a0,1842 # 80017780 <bcache>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	bfa080e7          	jalr	-1030(ra) # 80000c50 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000305e:	0001d497          	auipc	s1,0x1d
    80003062:	9da4b483          	ld	s1,-1574(s1) # 8001fa38 <bcache+0x82b8>
    80003066:	0001d797          	auipc	a5,0x1d
    8000306a:	98278793          	addi	a5,a5,-1662 # 8001f9e8 <bcache+0x8268>
    8000306e:	02f48f63          	beq	s1,a5,800030ac <bread+0x70>
    80003072:	873e                	mv	a4,a5
    80003074:	a021                	j	8000307c <bread+0x40>
    80003076:	68a4                	ld	s1,80(s1)
    80003078:	02e48a63          	beq	s1,a4,800030ac <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000307c:	449c                	lw	a5,8(s1)
    8000307e:	ff279ce3          	bne	a5,s2,80003076 <bread+0x3a>
    80003082:	44dc                	lw	a5,12(s1)
    80003084:	ff3799e3          	bne	a5,s3,80003076 <bread+0x3a>
      b->refcnt++;
    80003088:	40bc                	lw	a5,64(s1)
    8000308a:	2785                	addiw	a5,a5,1
    8000308c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	6f250513          	addi	a0,a0,1778 # 80017780 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	c6e080e7          	jalr	-914(ra) # 80000d04 <release>
      acquiresleep(&b->lock);
    8000309e:	01048513          	addi	a0,s1,16
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	456080e7          	jalr	1110(ra) # 800044f8 <acquiresleep>
      return b;
    800030aa:	a8b9                	j	80003108 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ac:	0001d497          	auipc	s1,0x1d
    800030b0:	9844b483          	ld	s1,-1660(s1) # 8001fa30 <bcache+0x82b0>
    800030b4:	0001d797          	auipc	a5,0x1d
    800030b8:	93478793          	addi	a5,a5,-1740 # 8001f9e8 <bcache+0x8268>
    800030bc:	00f48863          	beq	s1,a5,800030cc <bread+0x90>
    800030c0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030c2:	40bc                	lw	a5,64(s1)
    800030c4:	cf81                	beqz	a5,800030dc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c6:	64a4                	ld	s1,72(s1)
    800030c8:	fee49de3          	bne	s1,a4,800030c2 <bread+0x86>
  panic("bget: no buffers");
    800030cc:	00005517          	auipc	a0,0x5
    800030d0:	64450513          	addi	a0,a0,1604 # 80008710 <syscalls_name+0xd0>
    800030d4:	ffffd097          	auipc	ra,0xffffd
    800030d8:	46e080e7          	jalr	1134(ra) # 80000542 <panic>
      b->dev = dev;
    800030dc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030e0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030e4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030e8:	4785                	li	a5,1
    800030ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	69450513          	addi	a0,a0,1684 # 80017780 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	c10080e7          	jalr	-1008(ra) # 80000d04 <release>
      acquiresleep(&b->lock);
    800030fc:	01048513          	addi	a0,s1,16
    80003100:	00001097          	auipc	ra,0x1
    80003104:	3f8080e7          	jalr	1016(ra) # 800044f8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003108:	409c                	lw	a5,0(s1)
    8000310a:	cb89                	beqz	a5,8000311c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000310c:	8526                	mv	a0,s1
    8000310e:	70a2                	ld	ra,40(sp)
    80003110:	7402                	ld	s0,32(sp)
    80003112:	64e2                	ld	s1,24(sp)
    80003114:	6942                	ld	s2,16(sp)
    80003116:	69a2                	ld	s3,8(sp)
    80003118:	6145                	addi	sp,sp,48
    8000311a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000311c:	4581                	li	a1,0
    8000311e:	8526                	mv	a0,s1
    80003120:	00003097          	auipc	ra,0x3
    80003124:	f2c080e7          	jalr	-212(ra) # 8000604c <virtio_disk_rw>
    b->valid = 1;
    80003128:	4785                	li	a5,1
    8000312a:	c09c                	sw	a5,0(s1)
  return b;
    8000312c:	b7c5                	j	8000310c <bread+0xd0>

000000008000312e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000312e:	1101                	addi	sp,sp,-32
    80003130:	ec06                	sd	ra,24(sp)
    80003132:	e822                	sd	s0,16(sp)
    80003134:	e426                	sd	s1,8(sp)
    80003136:	1000                	addi	s0,sp,32
    80003138:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000313a:	0541                	addi	a0,a0,16
    8000313c:	00001097          	auipc	ra,0x1
    80003140:	456080e7          	jalr	1110(ra) # 80004592 <holdingsleep>
    80003144:	cd01                	beqz	a0,8000315c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003146:	4585                	li	a1,1
    80003148:	8526                	mv	a0,s1
    8000314a:	00003097          	auipc	ra,0x3
    8000314e:	f02080e7          	jalr	-254(ra) # 8000604c <virtio_disk_rw>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret
    panic("bwrite");
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	5cc50513          	addi	a0,a0,1484 # 80008728 <syscalls_name+0xe8>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	3de080e7          	jalr	990(ra) # 80000542 <panic>

000000008000316c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000316c:	1101                	addi	sp,sp,-32
    8000316e:	ec06                	sd	ra,24(sp)
    80003170:	e822                	sd	s0,16(sp)
    80003172:	e426                	sd	s1,8(sp)
    80003174:	e04a                	sd	s2,0(sp)
    80003176:	1000                	addi	s0,sp,32
    80003178:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000317a:	01050913          	addi	s2,a0,16
    8000317e:	854a                	mv	a0,s2
    80003180:	00001097          	auipc	ra,0x1
    80003184:	412080e7          	jalr	1042(ra) # 80004592 <holdingsleep>
    80003188:	c92d                	beqz	a0,800031fa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000318a:	854a                	mv	a0,s2
    8000318c:	00001097          	auipc	ra,0x1
    80003190:	3c2080e7          	jalr	962(ra) # 8000454e <releasesleep>

  acquire(&bcache.lock);
    80003194:	00014517          	auipc	a0,0x14
    80003198:	5ec50513          	addi	a0,a0,1516 # 80017780 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	ab4080e7          	jalr	-1356(ra) # 80000c50 <acquire>
  b->refcnt--;
    800031a4:	40bc                	lw	a5,64(s1)
    800031a6:	37fd                	addiw	a5,a5,-1
    800031a8:	0007871b          	sext.w	a4,a5
    800031ac:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031ae:	eb05                	bnez	a4,800031de <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031b0:	68bc                	ld	a5,80(s1)
    800031b2:	64b8                	ld	a4,72(s1)
    800031b4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031b6:	64bc                	ld	a5,72(s1)
    800031b8:	68b8                	ld	a4,80(s1)
    800031ba:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031bc:	0001c797          	auipc	a5,0x1c
    800031c0:	5c478793          	addi	a5,a5,1476 # 8001f780 <bcache+0x8000>
    800031c4:	2b87b703          	ld	a4,696(a5)
    800031c8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ca:	0001d717          	auipc	a4,0x1d
    800031ce:	81e70713          	addi	a4,a4,-2018 # 8001f9e8 <bcache+0x8268>
    800031d2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031d4:	2b87b703          	ld	a4,696(a5)
    800031d8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031da:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	5a250513          	addi	a0,a0,1442 # 80017780 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	b1e080e7          	jalr	-1250(ra) # 80000d04 <release>
}
    800031ee:	60e2                	ld	ra,24(sp)
    800031f0:	6442                	ld	s0,16(sp)
    800031f2:	64a2                	ld	s1,8(sp)
    800031f4:	6902                	ld	s2,0(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret
    panic("brelse");
    800031fa:	00005517          	auipc	a0,0x5
    800031fe:	53650513          	addi	a0,a0,1334 # 80008730 <syscalls_name+0xf0>
    80003202:	ffffd097          	auipc	ra,0xffffd
    80003206:	340080e7          	jalr	832(ra) # 80000542 <panic>

000000008000320a <bpin>:

void
bpin(struct buf *b) {
    8000320a:	1101                	addi	sp,sp,-32
    8000320c:	ec06                	sd	ra,24(sp)
    8000320e:	e822                	sd	s0,16(sp)
    80003210:	e426                	sd	s1,8(sp)
    80003212:	1000                	addi	s0,sp,32
    80003214:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003216:	00014517          	auipc	a0,0x14
    8000321a:	56a50513          	addi	a0,a0,1386 # 80017780 <bcache>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	a32080e7          	jalr	-1486(ra) # 80000c50 <acquire>
  b->refcnt++;
    80003226:	40bc                	lw	a5,64(s1)
    80003228:	2785                	addiw	a5,a5,1
    8000322a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000322c:	00014517          	auipc	a0,0x14
    80003230:	55450513          	addi	a0,a0,1364 # 80017780 <bcache>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	ad0080e7          	jalr	-1328(ra) # 80000d04 <release>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret

0000000080003246 <bunpin>:

void
bunpin(struct buf *b) {
    80003246:	1101                	addi	sp,sp,-32
    80003248:	ec06                	sd	ra,24(sp)
    8000324a:	e822                	sd	s0,16(sp)
    8000324c:	e426                	sd	s1,8(sp)
    8000324e:	1000                	addi	s0,sp,32
    80003250:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003252:	00014517          	auipc	a0,0x14
    80003256:	52e50513          	addi	a0,a0,1326 # 80017780 <bcache>
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	9f6080e7          	jalr	-1546(ra) # 80000c50 <acquire>
  b->refcnt--;
    80003262:	40bc                	lw	a5,64(s1)
    80003264:	37fd                	addiw	a5,a5,-1
    80003266:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003268:	00014517          	auipc	a0,0x14
    8000326c:	51850513          	addi	a0,a0,1304 # 80017780 <bcache>
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	a94080e7          	jalr	-1388(ra) # 80000d04 <release>
}
    80003278:	60e2                	ld	ra,24(sp)
    8000327a:	6442                	ld	s0,16(sp)
    8000327c:	64a2                	ld	s1,8(sp)
    8000327e:	6105                	addi	sp,sp,32
    80003280:	8082                	ret

0000000080003282 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	e426                	sd	s1,8(sp)
    8000328a:	e04a                	sd	s2,0(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003290:	00d5d59b          	srliw	a1,a1,0xd
    80003294:	0001d797          	auipc	a5,0x1d
    80003298:	bc87a783          	lw	a5,-1080(a5) # 8001fe5c <sb+0x1c>
    8000329c:	9dbd                	addw	a1,a1,a5
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	d9e080e7          	jalr	-610(ra) # 8000303c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032a6:	0074f713          	andi	a4,s1,7
    800032aa:	4785                	li	a5,1
    800032ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032b0:	14ce                	slli	s1,s1,0x33
    800032b2:	90d9                	srli	s1,s1,0x36
    800032b4:	00950733          	add	a4,a0,s1
    800032b8:	05874703          	lbu	a4,88(a4)
    800032bc:	00e7f6b3          	and	a3,a5,a4
    800032c0:	c69d                	beqz	a3,800032ee <bfree+0x6c>
    800032c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032c4:	94aa                	add	s1,s1,a0
    800032c6:	fff7c793          	not	a5,a5
    800032ca:	8ff9                	and	a5,a5,a4
    800032cc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	100080e7          	jalr	256(ra) # 800043d0 <log_write>
  brelse(bp);
    800032d8:	854a                	mv	a0,s2
    800032da:	00000097          	auipc	ra,0x0
    800032de:	e92080e7          	jalr	-366(ra) # 8000316c <brelse>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	64a2                	ld	s1,8(sp)
    800032e8:	6902                	ld	s2,0(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret
    panic("freeing free block");
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	44a50513          	addi	a0,a0,1098 # 80008738 <syscalls_name+0xf8>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	24c080e7          	jalr	588(ra) # 80000542 <panic>

00000000800032fe <balloc>:
{
    800032fe:	711d                	addi	sp,sp,-96
    80003300:	ec86                	sd	ra,88(sp)
    80003302:	e8a2                	sd	s0,80(sp)
    80003304:	e4a6                	sd	s1,72(sp)
    80003306:	e0ca                	sd	s2,64(sp)
    80003308:	fc4e                	sd	s3,56(sp)
    8000330a:	f852                	sd	s4,48(sp)
    8000330c:	f456                	sd	s5,40(sp)
    8000330e:	f05a                	sd	s6,32(sp)
    80003310:	ec5e                	sd	s7,24(sp)
    80003312:	e862                	sd	s8,16(sp)
    80003314:	e466                	sd	s9,8(sp)
    80003316:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003318:	0001d797          	auipc	a5,0x1d
    8000331c:	b2c7a783          	lw	a5,-1236(a5) # 8001fe44 <sb+0x4>
    80003320:	cbd1                	beqz	a5,800033b4 <balloc+0xb6>
    80003322:	8baa                	mv	s7,a0
    80003324:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003326:	0001db17          	auipc	s6,0x1d
    8000332a:	b1ab0b13          	addi	s6,s6,-1254 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003330:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003332:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003334:	6c89                	lui	s9,0x2
    80003336:	a831                	j	80003352 <balloc+0x54>
    brelse(bp);
    80003338:	854a                	mv	a0,s2
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e32080e7          	jalr	-462(ra) # 8000316c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003342:	015c87bb          	addw	a5,s9,s5
    80003346:	00078a9b          	sext.w	s5,a5
    8000334a:	004b2703          	lw	a4,4(s6)
    8000334e:	06eaf363          	bgeu	s5,a4,800033b4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003352:	41fad79b          	sraiw	a5,s5,0x1f
    80003356:	0137d79b          	srliw	a5,a5,0x13
    8000335a:	015787bb          	addw	a5,a5,s5
    8000335e:	40d7d79b          	sraiw	a5,a5,0xd
    80003362:	01cb2583          	lw	a1,28(s6)
    80003366:	9dbd                	addw	a1,a1,a5
    80003368:	855e                	mv	a0,s7
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	cd2080e7          	jalr	-814(ra) # 8000303c <bread>
    80003372:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003374:	004b2503          	lw	a0,4(s6)
    80003378:	000a849b          	sext.w	s1,s5
    8000337c:	8662                	mv	a2,s8
    8000337e:	faa4fde3          	bgeu	s1,a0,80003338 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003382:	41f6579b          	sraiw	a5,a2,0x1f
    80003386:	01d7d69b          	srliw	a3,a5,0x1d
    8000338a:	00c6873b          	addw	a4,a3,a2
    8000338e:	00777793          	andi	a5,a4,7
    80003392:	9f95                	subw	a5,a5,a3
    80003394:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003398:	4037571b          	sraiw	a4,a4,0x3
    8000339c:	00e906b3          	add	a3,s2,a4
    800033a0:	0586c683          	lbu	a3,88(a3)
    800033a4:	00d7f5b3          	and	a1,a5,a3
    800033a8:	cd91                	beqz	a1,800033c4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033aa:	2605                	addiw	a2,a2,1
    800033ac:	2485                	addiw	s1,s1,1
    800033ae:	fd4618e3          	bne	a2,s4,8000337e <balloc+0x80>
    800033b2:	b759                	j	80003338 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033b4:	00005517          	auipc	a0,0x5
    800033b8:	39c50513          	addi	a0,a0,924 # 80008750 <syscalls_name+0x110>
    800033bc:	ffffd097          	auipc	ra,0xffffd
    800033c0:	186080e7          	jalr	390(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c4:	974a                	add	a4,a4,s2
    800033c6:	8fd5                	or	a5,a5,a3
    800033c8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033cc:	854a                	mv	a0,s2
    800033ce:	00001097          	auipc	ra,0x1
    800033d2:	002080e7          	jalr	2(ra) # 800043d0 <log_write>
        brelse(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	d94080e7          	jalr	-620(ra) # 8000316c <brelse>
  bp = bread(dev, bno);
    800033e0:	85a6                	mv	a1,s1
    800033e2:	855e                	mv	a0,s7
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	c58080e7          	jalr	-936(ra) # 8000303c <bread>
    800033ec:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033ee:	40000613          	li	a2,1024
    800033f2:	4581                	li	a1,0
    800033f4:	05850513          	addi	a0,a0,88
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	954080e7          	jalr	-1708(ra) # 80000d4c <memset>
  log_write(bp);
    80003400:	854a                	mv	a0,s2
    80003402:	00001097          	auipc	ra,0x1
    80003406:	fce080e7          	jalr	-50(ra) # 800043d0 <log_write>
  brelse(bp);
    8000340a:	854a                	mv	a0,s2
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	d60080e7          	jalr	-672(ra) # 8000316c <brelse>
}
    80003414:	8526                	mv	a0,s1
    80003416:	60e6                	ld	ra,88(sp)
    80003418:	6446                	ld	s0,80(sp)
    8000341a:	64a6                	ld	s1,72(sp)
    8000341c:	6906                	ld	s2,64(sp)
    8000341e:	79e2                	ld	s3,56(sp)
    80003420:	7a42                	ld	s4,48(sp)
    80003422:	7aa2                	ld	s5,40(sp)
    80003424:	7b02                	ld	s6,32(sp)
    80003426:	6be2                	ld	s7,24(sp)
    80003428:	6c42                	ld	s8,16(sp)
    8000342a:	6ca2                	ld	s9,8(sp)
    8000342c:	6125                	addi	sp,sp,96
    8000342e:	8082                	ret

0000000080003430 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003430:	7179                	addi	sp,sp,-48
    80003432:	f406                	sd	ra,40(sp)
    80003434:	f022                	sd	s0,32(sp)
    80003436:	ec26                	sd	s1,24(sp)
    80003438:	e84a                	sd	s2,16(sp)
    8000343a:	e44e                	sd	s3,8(sp)
    8000343c:	e052                	sd	s4,0(sp)
    8000343e:	1800                	addi	s0,sp,48
    80003440:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003442:	47ad                	li	a5,11
    80003444:	04b7fe63          	bgeu	a5,a1,800034a0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003448:	ff45849b          	addiw	s1,a1,-12
    8000344c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003450:	0ff00793          	li	a5,255
    80003454:	0ae7e363          	bltu	a5,a4,800034fa <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003458:	08052583          	lw	a1,128(a0)
    8000345c:	c5ad                	beqz	a1,800034c6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000345e:	00092503          	lw	a0,0(s2)
    80003462:	00000097          	auipc	ra,0x0
    80003466:	bda080e7          	jalr	-1062(ra) # 8000303c <bread>
    8000346a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000346c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003470:	02049593          	slli	a1,s1,0x20
    80003474:	9181                	srli	a1,a1,0x20
    80003476:	058a                	slli	a1,a1,0x2
    80003478:	00b784b3          	add	s1,a5,a1
    8000347c:	0004a983          	lw	s3,0(s1)
    80003480:	04098d63          	beqz	s3,800034da <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003484:	8552                	mv	a0,s4
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	ce6080e7          	jalr	-794(ra) # 8000316c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000348e:	854e                	mv	a0,s3
    80003490:	70a2                	ld	ra,40(sp)
    80003492:	7402                	ld	s0,32(sp)
    80003494:	64e2                	ld	s1,24(sp)
    80003496:	6942                	ld	s2,16(sp)
    80003498:	69a2                	ld	s3,8(sp)
    8000349a:	6a02                	ld	s4,0(sp)
    8000349c:	6145                	addi	sp,sp,48
    8000349e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034a0:	02059493          	slli	s1,a1,0x20
    800034a4:	9081                	srli	s1,s1,0x20
    800034a6:	048a                	slli	s1,s1,0x2
    800034a8:	94aa                	add	s1,s1,a0
    800034aa:	0504a983          	lw	s3,80(s1)
    800034ae:	fe0990e3          	bnez	s3,8000348e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034b2:	4108                	lw	a0,0(a0)
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	e4a080e7          	jalr	-438(ra) # 800032fe <balloc>
    800034bc:	0005099b          	sext.w	s3,a0
    800034c0:	0534a823          	sw	s3,80(s1)
    800034c4:	b7e9                	j	8000348e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034c6:	4108                	lw	a0,0(a0)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	e36080e7          	jalr	-458(ra) # 800032fe <balloc>
    800034d0:	0005059b          	sext.w	a1,a0
    800034d4:	08b92023          	sw	a1,128(s2)
    800034d8:	b759                	j	8000345e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034da:	00092503          	lw	a0,0(s2)
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e20080e7          	jalr	-480(ra) # 800032fe <balloc>
    800034e6:	0005099b          	sext.w	s3,a0
    800034ea:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034ee:	8552                	mv	a0,s4
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	ee0080e7          	jalr	-288(ra) # 800043d0 <log_write>
    800034f8:	b771                	j	80003484 <bmap+0x54>
  panic("bmap: out of range");
    800034fa:	00005517          	auipc	a0,0x5
    800034fe:	26e50513          	addi	a0,a0,622 # 80008768 <syscalls_name+0x128>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	040080e7          	jalr	64(ra) # 80000542 <panic>

000000008000350a <iget>:
{
    8000350a:	7179                	addi	sp,sp,-48
    8000350c:	f406                	sd	ra,40(sp)
    8000350e:	f022                	sd	s0,32(sp)
    80003510:	ec26                	sd	s1,24(sp)
    80003512:	e84a                	sd	s2,16(sp)
    80003514:	e44e                	sd	s3,8(sp)
    80003516:	e052                	sd	s4,0(sp)
    80003518:	1800                	addi	s0,sp,48
    8000351a:	89aa                	mv	s3,a0
    8000351c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000351e:	0001d517          	auipc	a0,0x1d
    80003522:	94250513          	addi	a0,a0,-1726 # 8001fe60 <icache>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	72a080e7          	jalr	1834(ra) # 80000c50 <acquire>
  empty = 0;
    8000352e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003530:	0001d497          	auipc	s1,0x1d
    80003534:	94848493          	addi	s1,s1,-1720 # 8001fe78 <icache+0x18>
    80003538:	0001e697          	auipc	a3,0x1e
    8000353c:	3d068693          	addi	a3,a3,976 # 80021908 <log>
    80003540:	a039                	j	8000354e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003542:	02090b63          	beqz	s2,80003578 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003546:	08848493          	addi	s1,s1,136
    8000354a:	02d48a63          	beq	s1,a3,8000357e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000354e:	449c                	lw	a5,8(s1)
    80003550:	fef059e3          	blez	a5,80003542 <iget+0x38>
    80003554:	4098                	lw	a4,0(s1)
    80003556:	ff3716e3          	bne	a4,s3,80003542 <iget+0x38>
    8000355a:	40d8                	lw	a4,4(s1)
    8000355c:	ff4713e3          	bne	a4,s4,80003542 <iget+0x38>
      ip->ref++;
    80003560:	2785                	addiw	a5,a5,1
    80003562:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003564:	0001d517          	auipc	a0,0x1d
    80003568:	8fc50513          	addi	a0,a0,-1796 # 8001fe60 <icache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	798080e7          	jalr	1944(ra) # 80000d04 <release>
      return ip;
    80003574:	8926                	mv	s2,s1
    80003576:	a03d                	j	800035a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003578:	f7f9                	bnez	a5,80003546 <iget+0x3c>
    8000357a:	8926                	mv	s2,s1
    8000357c:	b7e9                	j	80003546 <iget+0x3c>
  if(empty == 0)
    8000357e:	02090c63          	beqz	s2,800035b6 <iget+0xac>
  ip->dev = dev;
    80003582:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003586:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000358a:	4785                	li	a5,1
    8000358c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003590:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003594:	0001d517          	auipc	a0,0x1d
    80003598:	8cc50513          	addi	a0,a0,-1844 # 8001fe60 <icache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	768080e7          	jalr	1896(ra) # 80000d04 <release>
}
    800035a4:	854a                	mv	a0,s2
    800035a6:	70a2                	ld	ra,40(sp)
    800035a8:	7402                	ld	s0,32(sp)
    800035aa:	64e2                	ld	s1,24(sp)
    800035ac:	6942                	ld	s2,16(sp)
    800035ae:	69a2                	ld	s3,8(sp)
    800035b0:	6a02                	ld	s4,0(sp)
    800035b2:	6145                	addi	sp,sp,48
    800035b4:	8082                	ret
    panic("iget: no inodes");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	1ca50513          	addi	a0,a0,458 # 80008780 <syscalls_name+0x140>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f84080e7          	jalr	-124(ra) # 80000542 <panic>

00000000800035c6 <fsinit>:
fsinit(int dev) {
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	1800                	addi	s0,sp,48
    800035d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035d6:	4585                	li	a1,1
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	a64080e7          	jalr	-1436(ra) # 8000303c <bread>
    800035e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035e2:	0001d997          	auipc	s3,0x1d
    800035e6:	85e98993          	addi	s3,s3,-1954 # 8001fe40 <sb>
    800035ea:	02000613          	li	a2,32
    800035ee:	05850593          	addi	a1,a0,88
    800035f2:	854e                	mv	a0,s3
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	7b4080e7          	jalr	1972(ra) # 80000da8 <memmove>
  brelse(bp);
    800035fc:	8526                	mv	a0,s1
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	b6e080e7          	jalr	-1170(ra) # 8000316c <brelse>
  if(sb.magic != FSMAGIC)
    80003606:	0009a703          	lw	a4,0(s3)
    8000360a:	102037b7          	lui	a5,0x10203
    8000360e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003612:	02f71263          	bne	a4,a5,80003636 <fsinit+0x70>
  initlog(dev, &sb);
    80003616:	0001d597          	auipc	a1,0x1d
    8000361a:	82a58593          	addi	a1,a1,-2006 # 8001fe40 <sb>
    8000361e:	854a                	mv	a0,s2
    80003620:	00001097          	auipc	ra,0x1
    80003624:	b38080e7          	jalr	-1224(ra) # 80004158 <initlog>
}
    80003628:	70a2                	ld	ra,40(sp)
    8000362a:	7402                	ld	s0,32(sp)
    8000362c:	64e2                	ld	s1,24(sp)
    8000362e:	6942                	ld	s2,16(sp)
    80003630:	69a2                	ld	s3,8(sp)
    80003632:	6145                	addi	sp,sp,48
    80003634:	8082                	ret
    panic("invalid file system");
    80003636:	00005517          	auipc	a0,0x5
    8000363a:	15a50513          	addi	a0,a0,346 # 80008790 <syscalls_name+0x150>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	f04080e7          	jalr	-252(ra) # 80000542 <panic>

0000000080003646 <iinit>:
{
    80003646:	7179                	addi	sp,sp,-48
    80003648:	f406                	sd	ra,40(sp)
    8000364a:	f022                	sd	s0,32(sp)
    8000364c:	ec26                	sd	s1,24(sp)
    8000364e:	e84a                	sd	s2,16(sp)
    80003650:	e44e                	sd	s3,8(sp)
    80003652:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003654:	00005597          	auipc	a1,0x5
    80003658:	15458593          	addi	a1,a1,340 # 800087a8 <syscalls_name+0x168>
    8000365c:	0001d517          	auipc	a0,0x1d
    80003660:	80450513          	addi	a0,a0,-2044 # 8001fe60 <icache>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	55c080e7          	jalr	1372(ra) # 80000bc0 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000366c:	0001d497          	auipc	s1,0x1d
    80003670:	81c48493          	addi	s1,s1,-2020 # 8001fe88 <icache+0x28>
    80003674:	0001e997          	auipc	s3,0x1e
    80003678:	2a498993          	addi	s3,s3,676 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000367c:	00005917          	auipc	s2,0x5
    80003680:	13490913          	addi	s2,s2,308 # 800087b0 <syscalls_name+0x170>
    80003684:	85ca                	mv	a1,s2
    80003686:	8526                	mv	a0,s1
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	e36080e7          	jalr	-458(ra) # 800044be <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003690:	08848493          	addi	s1,s1,136
    80003694:	ff3498e3          	bne	s1,s3,80003684 <iinit+0x3e>
}
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6145                	addi	sp,sp,48
    800036a4:	8082                	ret

00000000800036a6 <ialloc>:
{
    800036a6:	715d                	addi	sp,sp,-80
    800036a8:	e486                	sd	ra,72(sp)
    800036aa:	e0a2                	sd	s0,64(sp)
    800036ac:	fc26                	sd	s1,56(sp)
    800036ae:	f84a                	sd	s2,48(sp)
    800036b0:	f44e                	sd	s3,40(sp)
    800036b2:	f052                	sd	s4,32(sp)
    800036b4:	ec56                	sd	s5,24(sp)
    800036b6:	e85a                	sd	s6,16(sp)
    800036b8:	e45e                	sd	s7,8(sp)
    800036ba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036bc:	0001c717          	auipc	a4,0x1c
    800036c0:	79072703          	lw	a4,1936(a4) # 8001fe4c <sb+0xc>
    800036c4:	4785                	li	a5,1
    800036c6:	04e7fa63          	bgeu	a5,a4,8000371a <ialloc+0x74>
    800036ca:	8aaa                	mv	s5,a0
    800036cc:	8bae                	mv	s7,a1
    800036ce:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036d0:	0001ca17          	auipc	s4,0x1c
    800036d4:	770a0a13          	addi	s4,s4,1904 # 8001fe40 <sb>
    800036d8:	00048b1b          	sext.w	s6,s1
    800036dc:	0044d793          	srli	a5,s1,0x4
    800036e0:	018a2583          	lw	a1,24(s4)
    800036e4:	9dbd                	addw	a1,a1,a5
    800036e6:	8556                	mv	a0,s5
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	954080e7          	jalr	-1708(ra) # 8000303c <bread>
    800036f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036f2:	05850993          	addi	s3,a0,88
    800036f6:	00f4f793          	andi	a5,s1,15
    800036fa:	079a                	slli	a5,a5,0x6
    800036fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036fe:	00099783          	lh	a5,0(s3)
    80003702:	c785                	beqz	a5,8000372a <ialloc+0x84>
    brelse(bp);
    80003704:	00000097          	auipc	ra,0x0
    80003708:	a68080e7          	jalr	-1432(ra) # 8000316c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000370c:	0485                	addi	s1,s1,1
    8000370e:	00ca2703          	lw	a4,12(s4)
    80003712:	0004879b          	sext.w	a5,s1
    80003716:	fce7e1e3          	bltu	a5,a4,800036d8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000371a:	00005517          	auipc	a0,0x5
    8000371e:	09e50513          	addi	a0,a0,158 # 800087b8 <syscalls_name+0x178>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	e20080e7          	jalr	-480(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    8000372a:	04000613          	li	a2,64
    8000372e:	4581                	li	a1,0
    80003730:	854e                	mv	a0,s3
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	61a080e7          	jalr	1562(ra) # 80000d4c <memset>
      dip->type = type;
    8000373a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000373e:	854a                	mv	a0,s2
    80003740:	00001097          	auipc	ra,0x1
    80003744:	c90080e7          	jalr	-880(ra) # 800043d0 <log_write>
      brelse(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	a22080e7          	jalr	-1502(ra) # 8000316c <brelse>
      return iget(dev, inum);
    80003752:	85da                	mv	a1,s6
    80003754:	8556                	mv	a0,s5
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	db4080e7          	jalr	-588(ra) # 8000350a <iget>
}
    8000375e:	60a6                	ld	ra,72(sp)
    80003760:	6406                	ld	s0,64(sp)
    80003762:	74e2                	ld	s1,56(sp)
    80003764:	7942                	ld	s2,48(sp)
    80003766:	79a2                	ld	s3,40(sp)
    80003768:	7a02                	ld	s4,32(sp)
    8000376a:	6ae2                	ld	s5,24(sp)
    8000376c:	6b42                	ld	s6,16(sp)
    8000376e:	6ba2                	ld	s7,8(sp)
    80003770:	6161                	addi	sp,sp,80
    80003772:	8082                	ret

0000000080003774 <iupdate>:
{
    80003774:	1101                	addi	sp,sp,-32
    80003776:	ec06                	sd	ra,24(sp)
    80003778:	e822                	sd	s0,16(sp)
    8000377a:	e426                	sd	s1,8(sp)
    8000377c:	e04a                	sd	s2,0(sp)
    8000377e:	1000                	addi	s0,sp,32
    80003780:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003782:	415c                	lw	a5,4(a0)
    80003784:	0047d79b          	srliw	a5,a5,0x4
    80003788:	0001c597          	auipc	a1,0x1c
    8000378c:	6d05a583          	lw	a1,1744(a1) # 8001fe58 <sb+0x18>
    80003790:	9dbd                	addw	a1,a1,a5
    80003792:	4108                	lw	a0,0(a0)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	8a8080e7          	jalr	-1880(ra) # 8000303c <bread>
    8000379c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000379e:	05850793          	addi	a5,a0,88
    800037a2:	40c8                	lw	a0,4(s1)
    800037a4:	893d                	andi	a0,a0,15
    800037a6:	051a                	slli	a0,a0,0x6
    800037a8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037aa:	04449703          	lh	a4,68(s1)
    800037ae:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037b2:	04649703          	lh	a4,70(s1)
    800037b6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ba:	04849703          	lh	a4,72(s1)
    800037be:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037c2:	04a49703          	lh	a4,74(s1)
    800037c6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037ca:	44f8                	lw	a4,76(s1)
    800037cc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037ce:	03400613          	li	a2,52
    800037d2:	05048593          	addi	a1,s1,80
    800037d6:	0531                	addi	a0,a0,12
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	5d0080e7          	jalr	1488(ra) # 80000da8 <memmove>
  log_write(bp);
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	bee080e7          	jalr	-1042(ra) # 800043d0 <log_write>
  brelse(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	980080e7          	jalr	-1664(ra) # 8000316c <brelse>
}
    800037f4:	60e2                	ld	ra,24(sp)
    800037f6:	6442                	ld	s0,16(sp)
    800037f8:	64a2                	ld	s1,8(sp)
    800037fa:	6902                	ld	s2,0(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret

0000000080003800 <idup>:
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	1000                	addi	s0,sp,32
    8000380a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000380c:	0001c517          	auipc	a0,0x1c
    80003810:	65450513          	addi	a0,a0,1620 # 8001fe60 <icache>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	43c080e7          	jalr	1084(ra) # 80000c50 <acquire>
  ip->ref++;
    8000381c:	449c                	lw	a5,8(s1)
    8000381e:	2785                	addiw	a5,a5,1
    80003820:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003822:	0001c517          	auipc	a0,0x1c
    80003826:	63e50513          	addi	a0,a0,1598 # 8001fe60 <icache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	4da080e7          	jalr	1242(ra) # 80000d04 <release>
}
    80003832:	8526                	mv	a0,s1
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret

000000008000383e <ilock>:
{
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	e426                	sd	s1,8(sp)
    80003846:	e04a                	sd	s2,0(sp)
    80003848:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000384a:	c115                	beqz	a0,8000386e <ilock+0x30>
    8000384c:	84aa                	mv	s1,a0
    8000384e:	451c                	lw	a5,8(a0)
    80003850:	00f05f63          	blez	a5,8000386e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003854:	0541                	addi	a0,a0,16
    80003856:	00001097          	auipc	ra,0x1
    8000385a:	ca2080e7          	jalr	-862(ra) # 800044f8 <acquiresleep>
  if(ip->valid == 0){
    8000385e:	40bc                	lw	a5,64(s1)
    80003860:	cf99                	beqz	a5,8000387e <ilock+0x40>
}
    80003862:	60e2                	ld	ra,24(sp)
    80003864:	6442                	ld	s0,16(sp)
    80003866:	64a2                	ld	s1,8(sp)
    80003868:	6902                	ld	s2,0(sp)
    8000386a:	6105                	addi	sp,sp,32
    8000386c:	8082                	ret
    panic("ilock");
    8000386e:	00005517          	auipc	a0,0x5
    80003872:	f6250513          	addi	a0,a0,-158 # 800087d0 <syscalls_name+0x190>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	ccc080e7          	jalr	-820(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000387e:	40dc                	lw	a5,4(s1)
    80003880:	0047d79b          	srliw	a5,a5,0x4
    80003884:	0001c597          	auipc	a1,0x1c
    80003888:	5d45a583          	lw	a1,1492(a1) # 8001fe58 <sb+0x18>
    8000388c:	9dbd                	addw	a1,a1,a5
    8000388e:	4088                	lw	a0,0(s1)
    80003890:	fffff097          	auipc	ra,0xfffff
    80003894:	7ac080e7          	jalr	1964(ra) # 8000303c <bread>
    80003898:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389a:	05850593          	addi	a1,a0,88
    8000389e:	40dc                	lw	a5,4(s1)
    800038a0:	8bbd                	andi	a5,a5,15
    800038a2:	079a                	slli	a5,a5,0x6
    800038a4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038a6:	00059783          	lh	a5,0(a1)
    800038aa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038ae:	00259783          	lh	a5,2(a1)
    800038b2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038b6:	00459783          	lh	a5,4(a1)
    800038ba:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038be:	00659783          	lh	a5,6(a1)
    800038c2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038c6:	459c                	lw	a5,8(a1)
    800038c8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038ca:	03400613          	li	a2,52
    800038ce:	05b1                	addi	a1,a1,12
    800038d0:	05048513          	addi	a0,s1,80
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	4d4080e7          	jalr	1236(ra) # 80000da8 <memmove>
    brelse(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	88e080e7          	jalr	-1906(ra) # 8000316c <brelse>
    ip->valid = 1;
    800038e6:	4785                	li	a5,1
    800038e8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ea:	04449783          	lh	a5,68(s1)
    800038ee:	fbb5                	bnez	a5,80003862 <ilock+0x24>
      panic("ilock: no type");
    800038f0:	00005517          	auipc	a0,0x5
    800038f4:	ee850513          	addi	a0,a0,-280 # 800087d8 <syscalls_name+0x198>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	c4a080e7          	jalr	-950(ra) # 80000542 <panic>

0000000080003900 <iunlock>:
{
    80003900:	1101                	addi	sp,sp,-32
    80003902:	ec06                	sd	ra,24(sp)
    80003904:	e822                	sd	s0,16(sp)
    80003906:	e426                	sd	s1,8(sp)
    80003908:	e04a                	sd	s2,0(sp)
    8000390a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000390c:	c905                	beqz	a0,8000393c <iunlock+0x3c>
    8000390e:	84aa                	mv	s1,a0
    80003910:	01050913          	addi	s2,a0,16
    80003914:	854a                	mv	a0,s2
    80003916:	00001097          	auipc	ra,0x1
    8000391a:	c7c080e7          	jalr	-900(ra) # 80004592 <holdingsleep>
    8000391e:	cd19                	beqz	a0,8000393c <iunlock+0x3c>
    80003920:	449c                	lw	a5,8(s1)
    80003922:	00f05d63          	blez	a5,8000393c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003926:	854a                	mv	a0,s2
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	c26080e7          	jalr	-986(ra) # 8000454e <releasesleep>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret
    panic("iunlock");
    8000393c:	00005517          	auipc	a0,0x5
    80003940:	eac50513          	addi	a0,a0,-340 # 800087e8 <syscalls_name+0x1a8>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	bfe080e7          	jalr	-1026(ra) # 80000542 <panic>

000000008000394c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000394c:	7179                	addi	sp,sp,-48
    8000394e:	f406                	sd	ra,40(sp)
    80003950:	f022                	sd	s0,32(sp)
    80003952:	ec26                	sd	s1,24(sp)
    80003954:	e84a                	sd	s2,16(sp)
    80003956:	e44e                	sd	s3,8(sp)
    80003958:	e052                	sd	s4,0(sp)
    8000395a:	1800                	addi	s0,sp,48
    8000395c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000395e:	05050493          	addi	s1,a0,80
    80003962:	08050913          	addi	s2,a0,128
    80003966:	a021                	j	8000396e <itrunc+0x22>
    80003968:	0491                	addi	s1,s1,4
    8000396a:	01248d63          	beq	s1,s2,80003984 <itrunc+0x38>
    if(ip->addrs[i]){
    8000396e:	408c                	lw	a1,0(s1)
    80003970:	dde5                	beqz	a1,80003968 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003972:	0009a503          	lw	a0,0(s3)
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	90c080e7          	jalr	-1780(ra) # 80003282 <bfree>
      ip->addrs[i] = 0;
    8000397e:	0004a023          	sw	zero,0(s1)
    80003982:	b7dd                	j	80003968 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003984:	0809a583          	lw	a1,128(s3)
    80003988:	e185                	bnez	a1,800039a8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000398a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000398e:	854e                	mv	a0,s3
    80003990:	00000097          	auipc	ra,0x0
    80003994:	de4080e7          	jalr	-540(ra) # 80003774 <iupdate>
}
    80003998:	70a2                	ld	ra,40(sp)
    8000399a:	7402                	ld	s0,32(sp)
    8000399c:	64e2                	ld	s1,24(sp)
    8000399e:	6942                	ld	s2,16(sp)
    800039a0:	69a2                	ld	s3,8(sp)
    800039a2:	6a02                	ld	s4,0(sp)
    800039a4:	6145                	addi	sp,sp,48
    800039a6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039a8:	0009a503          	lw	a0,0(s3)
    800039ac:	fffff097          	auipc	ra,0xfffff
    800039b0:	690080e7          	jalr	1680(ra) # 8000303c <bread>
    800039b4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039b6:	05850493          	addi	s1,a0,88
    800039ba:	45850913          	addi	s2,a0,1112
    800039be:	a021                	j	800039c6 <itrunc+0x7a>
    800039c0:	0491                	addi	s1,s1,4
    800039c2:	01248b63          	beq	s1,s2,800039d8 <itrunc+0x8c>
      if(a[j])
    800039c6:	408c                	lw	a1,0(s1)
    800039c8:	dde5                	beqz	a1,800039c0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039ca:	0009a503          	lw	a0,0(s3)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	8b4080e7          	jalr	-1868(ra) # 80003282 <bfree>
    800039d6:	b7ed                	j	800039c0 <itrunc+0x74>
    brelse(bp);
    800039d8:	8552                	mv	a0,s4
    800039da:	fffff097          	auipc	ra,0xfffff
    800039de:	792080e7          	jalr	1938(ra) # 8000316c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039e2:	0809a583          	lw	a1,128(s3)
    800039e6:	0009a503          	lw	a0,0(s3)
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	898080e7          	jalr	-1896(ra) # 80003282 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039f2:	0809a023          	sw	zero,128(s3)
    800039f6:	bf51                	j	8000398a <itrunc+0x3e>

00000000800039f8 <iput>:
{
    800039f8:	1101                	addi	sp,sp,-32
    800039fa:	ec06                	sd	ra,24(sp)
    800039fc:	e822                	sd	s0,16(sp)
    800039fe:	e426                	sd	s1,8(sp)
    80003a00:	e04a                	sd	s2,0(sp)
    80003a02:	1000                	addi	s0,sp,32
    80003a04:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a06:	0001c517          	auipc	a0,0x1c
    80003a0a:	45a50513          	addi	a0,a0,1114 # 8001fe60 <icache>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	242080e7          	jalr	578(ra) # 80000c50 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a16:	4498                	lw	a4,8(s1)
    80003a18:	4785                	li	a5,1
    80003a1a:	02f70363          	beq	a4,a5,80003a40 <iput+0x48>
  ip->ref--;
    80003a1e:	449c                	lw	a5,8(s1)
    80003a20:	37fd                	addiw	a5,a5,-1
    80003a22:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a24:	0001c517          	auipc	a0,0x1c
    80003a28:	43c50513          	addi	a0,a0,1084 # 8001fe60 <icache>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	2d8080e7          	jalr	728(ra) # 80000d04 <release>
}
    80003a34:	60e2                	ld	ra,24(sp)
    80003a36:	6442                	ld	s0,16(sp)
    80003a38:	64a2                	ld	s1,8(sp)
    80003a3a:	6902                	ld	s2,0(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a40:	40bc                	lw	a5,64(s1)
    80003a42:	dff1                	beqz	a5,80003a1e <iput+0x26>
    80003a44:	04a49783          	lh	a5,74(s1)
    80003a48:	fbf9                	bnez	a5,80003a1e <iput+0x26>
    acquiresleep(&ip->lock);
    80003a4a:	01048913          	addi	s2,s1,16
    80003a4e:	854a                	mv	a0,s2
    80003a50:	00001097          	auipc	ra,0x1
    80003a54:	aa8080e7          	jalr	-1368(ra) # 800044f8 <acquiresleep>
    release(&icache.lock);
    80003a58:	0001c517          	auipc	a0,0x1c
    80003a5c:	40850513          	addi	a0,a0,1032 # 8001fe60 <icache>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	2a4080e7          	jalr	676(ra) # 80000d04 <release>
    itrunc(ip);
    80003a68:	8526                	mv	a0,s1
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	ee2080e7          	jalr	-286(ra) # 8000394c <itrunc>
    ip->type = 0;
    80003a72:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a76:	8526                	mv	a0,s1
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	cfc080e7          	jalr	-772(ra) # 80003774 <iupdate>
    ip->valid = 0;
    80003a80:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a84:	854a                	mv	a0,s2
    80003a86:	00001097          	auipc	ra,0x1
    80003a8a:	ac8080e7          	jalr	-1336(ra) # 8000454e <releasesleep>
    acquire(&icache.lock);
    80003a8e:	0001c517          	auipc	a0,0x1c
    80003a92:	3d250513          	addi	a0,a0,978 # 8001fe60 <icache>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	1ba080e7          	jalr	442(ra) # 80000c50 <acquire>
    80003a9e:	b741                	j	80003a1e <iput+0x26>

0000000080003aa0 <iunlockput>:
{
    80003aa0:	1101                	addi	sp,sp,-32
    80003aa2:	ec06                	sd	ra,24(sp)
    80003aa4:	e822                	sd	s0,16(sp)
    80003aa6:	e426                	sd	s1,8(sp)
    80003aa8:	1000                	addi	s0,sp,32
    80003aaa:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	e54080e7          	jalr	-428(ra) # 80003900 <iunlock>
  iput(ip);
    80003ab4:	8526                	mv	a0,s1
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	f42080e7          	jalr	-190(ra) # 800039f8 <iput>
}
    80003abe:	60e2                	ld	ra,24(sp)
    80003ac0:	6442                	ld	s0,16(sp)
    80003ac2:	64a2                	ld	s1,8(sp)
    80003ac4:	6105                	addi	sp,sp,32
    80003ac6:	8082                	ret

0000000080003ac8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ac8:	1141                	addi	sp,sp,-16
    80003aca:	e422                	sd	s0,8(sp)
    80003acc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ace:	411c                	lw	a5,0(a0)
    80003ad0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ad2:	415c                	lw	a5,4(a0)
    80003ad4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ad6:	04451783          	lh	a5,68(a0)
    80003ada:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ade:	04a51783          	lh	a5,74(a0)
    80003ae2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ae6:	04c56783          	lwu	a5,76(a0)
    80003aea:	e99c                	sd	a5,16(a1)
}
    80003aec:	6422                	ld	s0,8(sp)
    80003aee:	0141                	addi	sp,sp,16
    80003af0:	8082                	ret

0000000080003af2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af2:	457c                	lw	a5,76(a0)
    80003af4:	0ed7e863          	bltu	a5,a3,80003be4 <readi+0xf2>
{
    80003af8:	7159                	addi	sp,sp,-112
    80003afa:	f486                	sd	ra,104(sp)
    80003afc:	f0a2                	sd	s0,96(sp)
    80003afe:	eca6                	sd	s1,88(sp)
    80003b00:	e8ca                	sd	s2,80(sp)
    80003b02:	e4ce                	sd	s3,72(sp)
    80003b04:	e0d2                	sd	s4,64(sp)
    80003b06:	fc56                	sd	s5,56(sp)
    80003b08:	f85a                	sd	s6,48(sp)
    80003b0a:	f45e                	sd	s7,40(sp)
    80003b0c:	f062                	sd	s8,32(sp)
    80003b0e:	ec66                	sd	s9,24(sp)
    80003b10:	e86a                	sd	s10,16(sp)
    80003b12:	e46e                	sd	s11,8(sp)
    80003b14:	1880                	addi	s0,sp,112
    80003b16:	8baa                	mv	s7,a0
    80003b18:	8c2e                	mv	s8,a1
    80003b1a:	8ab2                	mv	s5,a2
    80003b1c:	84b6                	mv	s1,a3
    80003b1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b20:	9f35                	addw	a4,a4,a3
    return 0;
    80003b22:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b24:	08d76f63          	bltu	a4,a3,80003bc2 <readi+0xd0>
  if(off + n > ip->size)
    80003b28:	00e7f463          	bgeu	a5,a4,80003b30 <readi+0x3e>
    n = ip->size - off;
    80003b2c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b30:	0a0b0863          	beqz	s6,80003be0 <readi+0xee>
    80003b34:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b36:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b3a:	5cfd                	li	s9,-1
    80003b3c:	a82d                	j	80003b76 <readi+0x84>
    80003b3e:	020a1d93          	slli	s11,s4,0x20
    80003b42:	020ddd93          	srli	s11,s11,0x20
    80003b46:	05890793          	addi	a5,s2,88
    80003b4a:	86ee                	mv	a3,s11
    80003b4c:	963e                	add	a2,a2,a5
    80003b4e:	85d6                	mv	a1,s5
    80003b50:	8562                	mv	a0,s8
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	93c080e7          	jalr	-1732(ra) # 8000248e <either_copyout>
    80003b5a:	05950d63          	beq	a0,s9,80003bb4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	60c080e7          	jalr	1548(ra) # 8000316c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b68:	013a09bb          	addw	s3,s4,s3
    80003b6c:	009a04bb          	addw	s1,s4,s1
    80003b70:	9aee                	add	s5,s5,s11
    80003b72:	0569f663          	bgeu	s3,s6,80003bbe <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b76:	000ba903          	lw	s2,0(s7)
    80003b7a:	00a4d59b          	srliw	a1,s1,0xa
    80003b7e:	855e                	mv	a0,s7
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	8b0080e7          	jalr	-1872(ra) # 80003430 <bmap>
    80003b88:	0005059b          	sext.w	a1,a0
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	4ae080e7          	jalr	1198(ra) # 8000303c <bread>
    80003b96:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	3ff4f613          	andi	a2,s1,1023
    80003b9c:	40cd07bb          	subw	a5,s10,a2
    80003ba0:	413b073b          	subw	a4,s6,s3
    80003ba4:	8a3e                	mv	s4,a5
    80003ba6:	2781                	sext.w	a5,a5
    80003ba8:	0007069b          	sext.w	a3,a4
    80003bac:	f8f6f9e3          	bgeu	a3,a5,80003b3e <readi+0x4c>
    80003bb0:	8a3a                	mv	s4,a4
    80003bb2:	b771                	j	80003b3e <readi+0x4c>
      brelse(bp);
    80003bb4:	854a                	mv	a0,s2
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	5b6080e7          	jalr	1462(ra) # 8000316c <brelse>
  }
  return tot;
    80003bbe:	0009851b          	sext.w	a0,s3
}
    80003bc2:	70a6                	ld	ra,104(sp)
    80003bc4:	7406                	ld	s0,96(sp)
    80003bc6:	64e6                	ld	s1,88(sp)
    80003bc8:	6946                	ld	s2,80(sp)
    80003bca:	69a6                	ld	s3,72(sp)
    80003bcc:	6a06                	ld	s4,64(sp)
    80003bce:	7ae2                	ld	s5,56(sp)
    80003bd0:	7b42                	ld	s6,48(sp)
    80003bd2:	7ba2                	ld	s7,40(sp)
    80003bd4:	7c02                	ld	s8,32(sp)
    80003bd6:	6ce2                	ld	s9,24(sp)
    80003bd8:	6d42                	ld	s10,16(sp)
    80003bda:	6da2                	ld	s11,8(sp)
    80003bdc:	6165                	addi	sp,sp,112
    80003bde:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be0:	89da                	mv	s3,s6
    80003be2:	bff1                	j	80003bbe <readi+0xcc>
    return 0;
    80003be4:	4501                	li	a0,0
}
    80003be6:	8082                	ret

0000000080003be8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be8:	457c                	lw	a5,76(a0)
    80003bea:	10d7e663          	bltu	a5,a3,80003cf6 <writei+0x10e>
{
    80003bee:	7159                	addi	sp,sp,-112
    80003bf0:	f486                	sd	ra,104(sp)
    80003bf2:	f0a2                	sd	s0,96(sp)
    80003bf4:	eca6                	sd	s1,88(sp)
    80003bf6:	e8ca                	sd	s2,80(sp)
    80003bf8:	e4ce                	sd	s3,72(sp)
    80003bfa:	e0d2                	sd	s4,64(sp)
    80003bfc:	fc56                	sd	s5,56(sp)
    80003bfe:	f85a                	sd	s6,48(sp)
    80003c00:	f45e                	sd	s7,40(sp)
    80003c02:	f062                	sd	s8,32(sp)
    80003c04:	ec66                	sd	s9,24(sp)
    80003c06:	e86a                	sd	s10,16(sp)
    80003c08:	e46e                	sd	s11,8(sp)
    80003c0a:	1880                	addi	s0,sp,112
    80003c0c:	8baa                	mv	s7,a0
    80003c0e:	8c2e                	mv	s8,a1
    80003c10:	8ab2                	mv	s5,a2
    80003c12:	8936                	mv	s2,a3
    80003c14:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c16:	00e687bb          	addw	a5,a3,a4
    80003c1a:	0ed7e063          	bltu	a5,a3,80003cfa <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c1e:	00043737          	lui	a4,0x43
    80003c22:	0cf76e63          	bltu	a4,a5,80003cfe <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c26:	0a0b0763          	beqz	s6,80003cd4 <writei+0xec>
    80003c2a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c30:	5cfd                	li	s9,-1
    80003c32:	a091                	j	80003c76 <writei+0x8e>
    80003c34:	02099d93          	slli	s11,s3,0x20
    80003c38:	020ddd93          	srli	s11,s11,0x20
    80003c3c:	05848793          	addi	a5,s1,88
    80003c40:	86ee                	mv	a3,s11
    80003c42:	8656                	mv	a2,s5
    80003c44:	85e2                	mv	a1,s8
    80003c46:	953e                	add	a0,a0,a5
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	89c080e7          	jalr	-1892(ra) # 800024e4 <either_copyin>
    80003c50:	07950263          	beq	a0,s9,80003cb4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c54:	8526                	mv	a0,s1
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	77a080e7          	jalr	1914(ra) # 800043d0 <log_write>
    brelse(bp);
    80003c5e:	8526                	mv	a0,s1
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	50c080e7          	jalr	1292(ra) # 8000316c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c68:	01498a3b          	addw	s4,s3,s4
    80003c6c:	0129893b          	addw	s2,s3,s2
    80003c70:	9aee                	add	s5,s5,s11
    80003c72:	056a7663          	bgeu	s4,s6,80003cbe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c76:	000ba483          	lw	s1,0(s7)
    80003c7a:	00a9559b          	srliw	a1,s2,0xa
    80003c7e:	855e                	mv	a0,s7
    80003c80:	fffff097          	auipc	ra,0xfffff
    80003c84:	7b0080e7          	jalr	1968(ra) # 80003430 <bmap>
    80003c88:	0005059b          	sext.w	a1,a0
    80003c8c:	8526                	mv	a0,s1
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	3ae080e7          	jalr	942(ra) # 8000303c <bread>
    80003c96:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c98:	3ff97513          	andi	a0,s2,1023
    80003c9c:	40ad07bb          	subw	a5,s10,a0
    80003ca0:	414b073b          	subw	a4,s6,s4
    80003ca4:	89be                	mv	s3,a5
    80003ca6:	2781                	sext.w	a5,a5
    80003ca8:	0007069b          	sext.w	a3,a4
    80003cac:	f8f6f4e3          	bgeu	a3,a5,80003c34 <writei+0x4c>
    80003cb0:	89ba                	mv	s3,a4
    80003cb2:	b749                	j	80003c34 <writei+0x4c>
      brelse(bp);
    80003cb4:	8526                	mv	a0,s1
    80003cb6:	fffff097          	auipc	ra,0xfffff
    80003cba:	4b6080e7          	jalr	1206(ra) # 8000316c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003cbe:	04cba783          	lw	a5,76(s7)
    80003cc2:	0127f463          	bgeu	a5,s2,80003cca <writei+0xe2>
      ip->size = off;
    80003cc6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cca:	855e                	mv	a0,s7
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	aa8080e7          	jalr	-1368(ra) # 80003774 <iupdate>
  }

  return n;
    80003cd4:	000b051b          	sext.w	a0,s6
}
    80003cd8:	70a6                	ld	ra,104(sp)
    80003cda:	7406                	ld	s0,96(sp)
    80003cdc:	64e6                	ld	s1,88(sp)
    80003cde:	6946                	ld	s2,80(sp)
    80003ce0:	69a6                	ld	s3,72(sp)
    80003ce2:	6a06                	ld	s4,64(sp)
    80003ce4:	7ae2                	ld	s5,56(sp)
    80003ce6:	7b42                	ld	s6,48(sp)
    80003ce8:	7ba2                	ld	s7,40(sp)
    80003cea:	7c02                	ld	s8,32(sp)
    80003cec:	6ce2                	ld	s9,24(sp)
    80003cee:	6d42                	ld	s10,16(sp)
    80003cf0:	6da2                	ld	s11,8(sp)
    80003cf2:	6165                	addi	sp,sp,112
    80003cf4:	8082                	ret
    return -1;
    80003cf6:	557d                	li	a0,-1
}
    80003cf8:	8082                	ret
    return -1;
    80003cfa:	557d                	li	a0,-1
    80003cfc:	bff1                	j	80003cd8 <writei+0xf0>
    return -1;
    80003cfe:	557d                	li	a0,-1
    80003d00:	bfe1                	j	80003cd8 <writei+0xf0>

0000000080003d02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d02:	1141                	addi	sp,sp,-16
    80003d04:	e406                	sd	ra,8(sp)
    80003d06:	e022                	sd	s0,0(sp)
    80003d08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d0a:	4639                	li	a2,14
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	118080e7          	jalr	280(ra) # 80000e24 <strncmp>
}
    80003d14:	60a2                	ld	ra,8(sp)
    80003d16:	6402                	ld	s0,0(sp)
    80003d18:	0141                	addi	sp,sp,16
    80003d1a:	8082                	ret

0000000080003d1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d1c:	7139                	addi	sp,sp,-64
    80003d1e:	fc06                	sd	ra,56(sp)
    80003d20:	f822                	sd	s0,48(sp)
    80003d22:	f426                	sd	s1,40(sp)
    80003d24:	f04a                	sd	s2,32(sp)
    80003d26:	ec4e                	sd	s3,24(sp)
    80003d28:	e852                	sd	s4,16(sp)
    80003d2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d2c:	04451703          	lh	a4,68(a0)
    80003d30:	4785                	li	a5,1
    80003d32:	00f71a63          	bne	a4,a5,80003d46 <dirlookup+0x2a>
    80003d36:	892a                	mv	s2,a0
    80003d38:	89ae                	mv	s3,a1
    80003d3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3c:	457c                	lw	a5,76(a0)
    80003d3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d42:	e79d                	bnez	a5,80003d70 <dirlookup+0x54>
    80003d44:	a8a5                	j	80003dbc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d46:	00005517          	auipc	a0,0x5
    80003d4a:	aaa50513          	addi	a0,a0,-1366 # 800087f0 <syscalls_name+0x1b0>
    80003d4e:	ffffc097          	auipc	ra,0xffffc
    80003d52:	7f4080e7          	jalr	2036(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	ab250513          	addi	a0,a0,-1358 # 80008808 <syscalls_name+0x1c8>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7e4080e7          	jalr	2020(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d66:	24c1                	addiw	s1,s1,16
    80003d68:	04c92783          	lw	a5,76(s2)
    80003d6c:	04f4f763          	bgeu	s1,a5,80003dba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d70:	4741                	li	a4,16
    80003d72:	86a6                	mv	a3,s1
    80003d74:	fc040613          	addi	a2,s0,-64
    80003d78:	4581                	li	a1,0
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	d76080e7          	jalr	-650(ra) # 80003af2 <readi>
    80003d84:	47c1                	li	a5,16
    80003d86:	fcf518e3          	bne	a0,a5,80003d56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d8a:	fc045783          	lhu	a5,-64(s0)
    80003d8e:	dfe1                	beqz	a5,80003d66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d90:	fc240593          	addi	a1,s0,-62
    80003d94:	854e                	mv	a0,s3
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	f6c080e7          	jalr	-148(ra) # 80003d02 <namecmp>
    80003d9e:	f561                	bnez	a0,80003d66 <dirlookup+0x4a>
      if(poff)
    80003da0:	000a0463          	beqz	s4,80003da8 <dirlookup+0x8c>
        *poff = off;
    80003da4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003da8:	fc045583          	lhu	a1,-64(s0)
    80003dac:	00092503          	lw	a0,0(s2)
    80003db0:	fffff097          	auipc	ra,0xfffff
    80003db4:	75a080e7          	jalr	1882(ra) # 8000350a <iget>
    80003db8:	a011                	j	80003dbc <dirlookup+0xa0>
  return 0;
    80003dba:	4501                	li	a0,0
}
    80003dbc:	70e2                	ld	ra,56(sp)
    80003dbe:	7442                	ld	s0,48(sp)
    80003dc0:	74a2                	ld	s1,40(sp)
    80003dc2:	7902                	ld	s2,32(sp)
    80003dc4:	69e2                	ld	s3,24(sp)
    80003dc6:	6a42                	ld	s4,16(sp)
    80003dc8:	6121                	addi	sp,sp,64
    80003dca:	8082                	ret

0000000080003dcc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dcc:	711d                	addi	sp,sp,-96
    80003dce:	ec86                	sd	ra,88(sp)
    80003dd0:	e8a2                	sd	s0,80(sp)
    80003dd2:	e4a6                	sd	s1,72(sp)
    80003dd4:	e0ca                	sd	s2,64(sp)
    80003dd6:	fc4e                	sd	s3,56(sp)
    80003dd8:	f852                	sd	s4,48(sp)
    80003dda:	f456                	sd	s5,40(sp)
    80003ddc:	f05a                	sd	s6,32(sp)
    80003dde:	ec5e                	sd	s7,24(sp)
    80003de0:	e862                	sd	s8,16(sp)
    80003de2:	e466                	sd	s9,8(sp)
    80003de4:	1080                	addi	s0,sp,96
    80003de6:	84aa                	mv	s1,a0
    80003de8:	8aae                	mv	s5,a1
    80003dea:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dec:	00054703          	lbu	a4,0(a0)
    80003df0:	02f00793          	li	a5,47
    80003df4:	02f70363          	beq	a4,a5,80003e1a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003df8:	ffffe097          	auipc	ra,0xffffe
    80003dfc:	c24080e7          	jalr	-988(ra) # 80001a1c <myproc>
    80003e00:	15053503          	ld	a0,336(a0)
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	9fc080e7          	jalr	-1540(ra) # 80003800 <idup>
    80003e0c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e0e:	02f00913          	li	s2,47
  len = path - s;
    80003e12:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e14:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e16:	4b85                	li	s7,1
    80003e18:	a865                	j	80003ed0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e1a:	4585                	li	a1,1
    80003e1c:	4505                	li	a0,1
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	6ec080e7          	jalr	1772(ra) # 8000350a <iget>
    80003e26:	89aa                	mv	s3,a0
    80003e28:	b7dd                	j	80003e0e <namex+0x42>
      iunlockput(ip);
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	c74080e7          	jalr	-908(ra) # 80003aa0 <iunlockput>
      return 0;
    80003e34:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e36:	854e                	mv	a0,s3
    80003e38:	60e6                	ld	ra,88(sp)
    80003e3a:	6446                	ld	s0,80(sp)
    80003e3c:	64a6                	ld	s1,72(sp)
    80003e3e:	6906                	ld	s2,64(sp)
    80003e40:	79e2                	ld	s3,56(sp)
    80003e42:	7a42                	ld	s4,48(sp)
    80003e44:	7aa2                	ld	s5,40(sp)
    80003e46:	7b02                	ld	s6,32(sp)
    80003e48:	6be2                	ld	s7,24(sp)
    80003e4a:	6c42                	ld	s8,16(sp)
    80003e4c:	6ca2                	ld	s9,8(sp)
    80003e4e:	6125                	addi	sp,sp,96
    80003e50:	8082                	ret
      iunlock(ip);
    80003e52:	854e                	mv	a0,s3
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	aac080e7          	jalr	-1364(ra) # 80003900 <iunlock>
      return ip;
    80003e5c:	bfe9                	j	80003e36 <namex+0x6a>
      iunlockput(ip);
    80003e5e:	854e                	mv	a0,s3
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	c40080e7          	jalr	-960(ra) # 80003aa0 <iunlockput>
      return 0;
    80003e68:	89e6                	mv	s3,s9
    80003e6a:	b7f1                	j	80003e36 <namex+0x6a>
  len = path - s;
    80003e6c:	40b48633          	sub	a2,s1,a1
    80003e70:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e74:	099c5463          	bge	s8,s9,80003efc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e78:	4639                	li	a2,14
    80003e7a:	8552                	mv	a0,s4
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	f2c080e7          	jalr	-212(ra) # 80000da8 <memmove>
  while(*path == '/')
    80003e84:	0004c783          	lbu	a5,0(s1)
    80003e88:	01279763          	bne	a5,s2,80003e96 <namex+0xca>
    path++;
    80003e8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8e:	0004c783          	lbu	a5,0(s1)
    80003e92:	ff278de3          	beq	a5,s2,80003e8c <namex+0xc0>
    ilock(ip);
    80003e96:	854e                	mv	a0,s3
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	9a6080e7          	jalr	-1626(ra) # 8000383e <ilock>
    if(ip->type != T_DIR){
    80003ea0:	04499783          	lh	a5,68(s3)
    80003ea4:	f97793e3          	bne	a5,s7,80003e2a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ea8:	000a8563          	beqz	s5,80003eb2 <namex+0xe6>
    80003eac:	0004c783          	lbu	a5,0(s1)
    80003eb0:	d3cd                	beqz	a5,80003e52 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eb2:	865a                	mv	a2,s6
    80003eb4:	85d2                	mv	a1,s4
    80003eb6:	854e                	mv	a0,s3
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	e64080e7          	jalr	-412(ra) # 80003d1c <dirlookup>
    80003ec0:	8caa                	mv	s9,a0
    80003ec2:	dd51                	beqz	a0,80003e5e <namex+0x92>
    iunlockput(ip);
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	bda080e7          	jalr	-1062(ra) # 80003aa0 <iunlockput>
    ip = next;
    80003ece:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	05279763          	bne	a5,s2,80003f22 <namex+0x156>
    path++;
    80003ed8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eda:	0004c783          	lbu	a5,0(s1)
    80003ede:	ff278de3          	beq	a5,s2,80003ed8 <namex+0x10c>
  if(*path == 0)
    80003ee2:	c79d                	beqz	a5,80003f10 <namex+0x144>
    path++;
    80003ee4:	85a6                	mv	a1,s1
  len = path - s;
    80003ee6:	8cda                	mv	s9,s6
    80003ee8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003eea:	01278963          	beq	a5,s2,80003efc <namex+0x130>
    80003eee:	dfbd                	beqz	a5,80003e6c <namex+0xa0>
    path++;
    80003ef0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	ff279ce3          	bne	a5,s2,80003eee <namex+0x122>
    80003efa:	bf8d                	j	80003e6c <namex+0xa0>
    memmove(name, s, len);
    80003efc:	2601                	sext.w	a2,a2
    80003efe:	8552                	mv	a0,s4
    80003f00:	ffffd097          	auipc	ra,0xffffd
    80003f04:	ea8080e7          	jalr	-344(ra) # 80000da8 <memmove>
    name[len] = 0;
    80003f08:	9cd2                	add	s9,s9,s4
    80003f0a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f0e:	bf9d                	j	80003e84 <namex+0xb8>
  if(nameiparent){
    80003f10:	f20a83e3          	beqz	s5,80003e36 <namex+0x6a>
    iput(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	ae2080e7          	jalr	-1310(ra) # 800039f8 <iput>
    return 0;
    80003f1e:	4981                	li	s3,0
    80003f20:	bf19                	j	80003e36 <namex+0x6a>
  if(*path == 0)
    80003f22:	d7fd                	beqz	a5,80003f10 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f24:	0004c783          	lbu	a5,0(s1)
    80003f28:	85a6                	mv	a1,s1
    80003f2a:	b7d1                	j	80003eee <namex+0x122>

0000000080003f2c <dirlink>:
{
    80003f2c:	7139                	addi	sp,sp,-64
    80003f2e:	fc06                	sd	ra,56(sp)
    80003f30:	f822                	sd	s0,48(sp)
    80003f32:	f426                	sd	s1,40(sp)
    80003f34:	f04a                	sd	s2,32(sp)
    80003f36:	ec4e                	sd	s3,24(sp)
    80003f38:	e852                	sd	s4,16(sp)
    80003f3a:	0080                	addi	s0,sp,64
    80003f3c:	892a                	mv	s2,a0
    80003f3e:	8a2e                	mv	s4,a1
    80003f40:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f42:	4601                	li	a2,0
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	dd8080e7          	jalr	-552(ra) # 80003d1c <dirlookup>
    80003f4c:	e93d                	bnez	a0,80003fc2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4e:	04c92483          	lw	s1,76(s2)
    80003f52:	c49d                	beqz	s1,80003f80 <dirlink+0x54>
    80003f54:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f56:	4741                	li	a4,16
    80003f58:	86a6                	mv	a3,s1
    80003f5a:	fc040613          	addi	a2,s0,-64
    80003f5e:	4581                	li	a1,0
    80003f60:	854a                	mv	a0,s2
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	b90080e7          	jalr	-1136(ra) # 80003af2 <readi>
    80003f6a:	47c1                	li	a5,16
    80003f6c:	06f51163          	bne	a0,a5,80003fce <dirlink+0xa2>
    if(de.inum == 0)
    80003f70:	fc045783          	lhu	a5,-64(s0)
    80003f74:	c791                	beqz	a5,80003f80 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f76:	24c1                	addiw	s1,s1,16
    80003f78:	04c92783          	lw	a5,76(s2)
    80003f7c:	fcf4ede3          	bltu	s1,a5,80003f56 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f80:	4639                	li	a2,14
    80003f82:	85d2                	mv	a1,s4
    80003f84:	fc240513          	addi	a0,s0,-62
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	ed8080e7          	jalr	-296(ra) # 80000e60 <strncpy>
  de.inum = inum;
    80003f90:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f94:	4741                	li	a4,16
    80003f96:	86a6                	mv	a3,s1
    80003f98:	fc040613          	addi	a2,s0,-64
    80003f9c:	4581                	li	a1,0
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	c48080e7          	jalr	-952(ra) # 80003be8 <writei>
    80003fa8:	872a                	mv	a4,a0
    80003faa:	47c1                	li	a5,16
  return 0;
    80003fac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fae:	02f71863          	bne	a4,a5,80003fde <dirlink+0xb2>
}
    80003fb2:	70e2                	ld	ra,56(sp)
    80003fb4:	7442                	ld	s0,48(sp)
    80003fb6:	74a2                	ld	s1,40(sp)
    80003fb8:	7902                	ld	s2,32(sp)
    80003fba:	69e2                	ld	s3,24(sp)
    80003fbc:	6a42                	ld	s4,16(sp)
    80003fbe:	6121                	addi	sp,sp,64
    80003fc0:	8082                	ret
    iput(ip);
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	a36080e7          	jalr	-1482(ra) # 800039f8 <iput>
    return -1;
    80003fca:	557d                	li	a0,-1
    80003fcc:	b7dd                	j	80003fb2 <dirlink+0x86>
      panic("dirlink read");
    80003fce:	00005517          	auipc	a0,0x5
    80003fd2:	84a50513          	addi	a0,a0,-1974 # 80008818 <syscalls_name+0x1d8>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	56c080e7          	jalr	1388(ra) # 80000542 <panic>
    panic("dirlink");
    80003fde:	00005517          	auipc	a0,0x5
    80003fe2:	95250513          	addi	a0,a0,-1710 # 80008930 <syscalls_name+0x2f0>
    80003fe6:	ffffc097          	auipc	ra,0xffffc
    80003fea:	55c080e7          	jalr	1372(ra) # 80000542 <panic>

0000000080003fee <namei>:

struct inode*
namei(char *path)
{
    80003fee:	1101                	addi	sp,sp,-32
    80003ff0:	ec06                	sd	ra,24(sp)
    80003ff2:	e822                	sd	s0,16(sp)
    80003ff4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ff6:	fe040613          	addi	a2,s0,-32
    80003ffa:	4581                	li	a1,0
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	dd0080e7          	jalr	-560(ra) # 80003dcc <namex>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	6105                	addi	sp,sp,32
    8000400a:	8082                	ret

000000008000400c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000400c:	1141                	addi	sp,sp,-16
    8000400e:	e406                	sd	ra,8(sp)
    80004010:	e022                	sd	s0,0(sp)
    80004012:	0800                	addi	s0,sp,16
    80004014:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004016:	4585                	li	a1,1
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	db4080e7          	jalr	-588(ra) # 80003dcc <namex>
}
    80004020:	60a2                	ld	ra,8(sp)
    80004022:	6402                	ld	s0,0(sp)
    80004024:	0141                	addi	sp,sp,16
    80004026:	8082                	ret

0000000080004028 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	e04a                	sd	s2,0(sp)
    80004032:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004034:	0001e917          	auipc	s2,0x1e
    80004038:	8d490913          	addi	s2,s2,-1836 # 80021908 <log>
    8000403c:	01892583          	lw	a1,24(s2)
    80004040:	02892503          	lw	a0,40(s2)
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	ff8080e7          	jalr	-8(ra) # 8000303c <bread>
    8000404c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000404e:	02c92683          	lw	a3,44(s2)
    80004052:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004054:	02d05763          	blez	a3,80004082 <write_head+0x5a>
    80004058:	0001e797          	auipc	a5,0x1e
    8000405c:	8e078793          	addi	a5,a5,-1824 # 80021938 <log+0x30>
    80004060:	05c50713          	addi	a4,a0,92
    80004064:	36fd                	addiw	a3,a3,-1
    80004066:	1682                	slli	a3,a3,0x20
    80004068:	9281                	srli	a3,a3,0x20
    8000406a:	068a                	slli	a3,a3,0x2
    8000406c:	0001e617          	auipc	a2,0x1e
    80004070:	8d060613          	addi	a2,a2,-1840 # 8002193c <log+0x34>
    80004074:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004076:	4390                	lw	a2,0(a5)
    80004078:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	0791                	addi	a5,a5,4
    8000407c:	0711                	addi	a4,a4,4
    8000407e:	fed79ce3          	bne	a5,a3,80004076 <write_head+0x4e>
  }
  bwrite(buf);
    80004082:	8526                	mv	a0,s1
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	0aa080e7          	jalr	170(ra) # 8000312e <bwrite>
  brelse(buf);
    8000408c:	8526                	mv	a0,s1
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	0de080e7          	jalr	222(ra) # 8000316c <brelse>
}
    80004096:	60e2                	ld	ra,24(sp)
    80004098:	6442                	ld	s0,16(sp)
    8000409a:	64a2                	ld	s1,8(sp)
    8000409c:	6902                	ld	s2,0(sp)
    8000409e:	6105                	addi	sp,sp,32
    800040a0:	8082                	ret

00000000800040a2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a2:	0001e797          	auipc	a5,0x1e
    800040a6:	8927a783          	lw	a5,-1902(a5) # 80021934 <log+0x2c>
    800040aa:	0af05663          	blez	a5,80004156 <install_trans+0xb4>
{
    800040ae:	7139                	addi	sp,sp,-64
    800040b0:	fc06                	sd	ra,56(sp)
    800040b2:	f822                	sd	s0,48(sp)
    800040b4:	f426                	sd	s1,40(sp)
    800040b6:	f04a                	sd	s2,32(sp)
    800040b8:	ec4e                	sd	s3,24(sp)
    800040ba:	e852                	sd	s4,16(sp)
    800040bc:	e456                	sd	s5,8(sp)
    800040be:	0080                	addi	s0,sp,64
    800040c0:	0001ea97          	auipc	s5,0x1e
    800040c4:	878a8a93          	addi	s5,s5,-1928 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ca:	0001e997          	auipc	s3,0x1e
    800040ce:	83e98993          	addi	s3,s3,-1986 # 80021908 <log>
    800040d2:	0189a583          	lw	a1,24(s3)
    800040d6:	014585bb          	addw	a1,a1,s4
    800040da:	2585                	addiw	a1,a1,1
    800040dc:	0289a503          	lw	a0,40(s3)
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	f5c080e7          	jalr	-164(ra) # 8000303c <bread>
    800040e8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040ea:	000aa583          	lw	a1,0(s5)
    800040ee:	0289a503          	lw	a0,40(s3)
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	f4a080e7          	jalr	-182(ra) # 8000303c <bread>
    800040fa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040fc:	40000613          	li	a2,1024
    80004100:	05890593          	addi	a1,s2,88
    80004104:	05850513          	addi	a0,a0,88
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	ca0080e7          	jalr	-864(ra) # 80000da8 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004110:	8526                	mv	a0,s1
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	01c080e7          	jalr	28(ra) # 8000312e <bwrite>
    bunpin(dbuf);
    8000411a:	8526                	mv	a0,s1
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	12a080e7          	jalr	298(ra) # 80003246 <bunpin>
    brelse(lbuf);
    80004124:	854a                	mv	a0,s2
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	046080e7          	jalr	70(ra) # 8000316c <brelse>
    brelse(dbuf);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	03c080e7          	jalr	60(ra) # 8000316c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004138:	2a05                	addiw	s4,s4,1
    8000413a:	0a91                	addi	s5,s5,4
    8000413c:	02c9a783          	lw	a5,44(s3)
    80004140:	f8fa49e3          	blt	s4,a5,800040d2 <install_trans+0x30>
}
    80004144:	70e2                	ld	ra,56(sp)
    80004146:	7442                	ld	s0,48(sp)
    80004148:	74a2                	ld	s1,40(sp)
    8000414a:	7902                	ld	s2,32(sp)
    8000414c:	69e2                	ld	s3,24(sp)
    8000414e:	6a42                	ld	s4,16(sp)
    80004150:	6aa2                	ld	s5,8(sp)
    80004152:	6121                	addi	sp,sp,64
    80004154:	8082                	ret
    80004156:	8082                	ret

0000000080004158 <initlog>:
{
    80004158:	7179                	addi	sp,sp,-48
    8000415a:	f406                	sd	ra,40(sp)
    8000415c:	f022                	sd	s0,32(sp)
    8000415e:	ec26                	sd	s1,24(sp)
    80004160:	e84a                	sd	s2,16(sp)
    80004162:	e44e                	sd	s3,8(sp)
    80004164:	1800                	addi	s0,sp,48
    80004166:	892a                	mv	s2,a0
    80004168:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000416a:	0001d497          	auipc	s1,0x1d
    8000416e:	79e48493          	addi	s1,s1,1950 # 80021908 <log>
    80004172:	00004597          	auipc	a1,0x4
    80004176:	6b658593          	addi	a1,a1,1718 # 80008828 <syscalls_name+0x1e8>
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	a44080e7          	jalr	-1468(ra) # 80000bc0 <initlock>
  log.start = sb->logstart;
    80004184:	0149a583          	lw	a1,20(s3)
    80004188:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000418a:	0109a783          	lw	a5,16(s3)
    8000418e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004190:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004194:	854a                	mv	a0,s2
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	ea6080e7          	jalr	-346(ra) # 8000303c <bread>
  log.lh.n = lh->n;
    8000419e:	4d34                	lw	a3,88(a0)
    800041a0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041a2:	02d05563          	blez	a3,800041cc <initlog+0x74>
    800041a6:	05c50793          	addi	a5,a0,92
    800041aa:	0001d717          	auipc	a4,0x1d
    800041ae:	78e70713          	addi	a4,a4,1934 # 80021938 <log+0x30>
    800041b2:	36fd                	addiw	a3,a3,-1
    800041b4:	1682                	slli	a3,a3,0x20
    800041b6:	9281                	srli	a3,a3,0x20
    800041b8:	068a                	slli	a3,a3,0x2
    800041ba:	06050613          	addi	a2,a0,96
    800041be:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041c0:	4390                	lw	a2,0(a5)
    800041c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c4:	0791                	addi	a5,a5,4
    800041c6:	0711                	addi	a4,a4,4
    800041c8:	fed79ce3          	bne	a5,a3,800041c0 <initlog+0x68>
  brelse(buf);
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	fa0080e7          	jalr	-96(ra) # 8000316c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	ece080e7          	jalr	-306(ra) # 800040a2 <install_trans>
  log.lh.n = 0;
    800041dc:	0001d797          	auipc	a5,0x1d
    800041e0:	7407ac23          	sw	zero,1880(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	e44080e7          	jalr	-444(ra) # 80004028 <write_head>
}
    800041ec:	70a2                	ld	ra,40(sp)
    800041ee:	7402                	ld	s0,32(sp)
    800041f0:	64e2                	ld	s1,24(sp)
    800041f2:	6942                	ld	s2,16(sp)
    800041f4:	69a2                	ld	s3,8(sp)
    800041f6:	6145                	addi	sp,sp,48
    800041f8:	8082                	ret

00000000800041fa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041fa:	1101                	addi	sp,sp,-32
    800041fc:	ec06                	sd	ra,24(sp)
    800041fe:	e822                	sd	s0,16(sp)
    80004200:	e426                	sd	s1,8(sp)
    80004202:	e04a                	sd	s2,0(sp)
    80004204:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004206:	0001d517          	auipc	a0,0x1d
    8000420a:	70250513          	addi	a0,a0,1794 # 80021908 <log>
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a42080e7          	jalr	-1470(ra) # 80000c50 <acquire>
  while(1){
    if(log.committing){
    80004216:	0001d497          	auipc	s1,0x1d
    8000421a:	6f248493          	addi	s1,s1,1778 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421e:	4979                	li	s2,30
    80004220:	a039                	j	8000422e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004222:	85a6                	mv	a1,s1
    80004224:	8526                	mv	a0,s1
    80004226:	ffffe097          	auipc	ra,0xffffe
    8000422a:	00e080e7          	jalr	14(ra) # 80002234 <sleep>
    if(log.committing){
    8000422e:	50dc                	lw	a5,36(s1)
    80004230:	fbed                	bnez	a5,80004222 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004232:	509c                	lw	a5,32(s1)
    80004234:	0017871b          	addiw	a4,a5,1
    80004238:	0007069b          	sext.w	a3,a4
    8000423c:	0027179b          	slliw	a5,a4,0x2
    80004240:	9fb9                	addw	a5,a5,a4
    80004242:	0017979b          	slliw	a5,a5,0x1
    80004246:	54d8                	lw	a4,44(s1)
    80004248:	9fb9                	addw	a5,a5,a4
    8000424a:	00f95963          	bge	s2,a5,8000425c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000424e:	85a6                	mv	a1,s1
    80004250:	8526                	mv	a0,s1
    80004252:	ffffe097          	auipc	ra,0xffffe
    80004256:	fe2080e7          	jalr	-30(ra) # 80002234 <sleep>
    8000425a:	bfd1                	j	8000422e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000425c:	0001d517          	auipc	a0,0x1d
    80004260:	6ac50513          	addi	a0,a0,1708 # 80021908 <log>
    80004264:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a9e080e7          	jalr	-1378(ra) # 80000d04 <release>
      break;
    }
  }
}
    8000426e:	60e2                	ld	ra,24(sp)
    80004270:	6442                	ld	s0,16(sp)
    80004272:	64a2                	ld	s1,8(sp)
    80004274:	6902                	ld	s2,0(sp)
    80004276:	6105                	addi	sp,sp,32
    80004278:	8082                	ret

000000008000427a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000427a:	7139                	addi	sp,sp,-64
    8000427c:	fc06                	sd	ra,56(sp)
    8000427e:	f822                	sd	s0,48(sp)
    80004280:	f426                	sd	s1,40(sp)
    80004282:	f04a                	sd	s2,32(sp)
    80004284:	ec4e                	sd	s3,24(sp)
    80004286:	e852                	sd	s4,16(sp)
    80004288:	e456                	sd	s5,8(sp)
    8000428a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000428c:	0001d497          	auipc	s1,0x1d
    80004290:	67c48493          	addi	s1,s1,1660 # 80021908 <log>
    80004294:	8526                	mv	a0,s1
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	9ba080e7          	jalr	-1606(ra) # 80000c50 <acquire>
  log.outstanding -= 1;
    8000429e:	509c                	lw	a5,32(s1)
    800042a0:	37fd                	addiw	a5,a5,-1
    800042a2:	0007891b          	sext.w	s2,a5
    800042a6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042a8:	50dc                	lw	a5,36(s1)
    800042aa:	e7b9                	bnez	a5,800042f8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042ac:	04091e63          	bnez	s2,80004308 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042b0:	0001d497          	auipc	s1,0x1d
    800042b4:	65848493          	addi	s1,s1,1624 # 80021908 <log>
    800042b8:	4785                	li	a5,1
    800042ba:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042bc:	8526                	mv	a0,s1
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	a46080e7          	jalr	-1466(ra) # 80000d04 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042c6:	54dc                	lw	a5,44(s1)
    800042c8:	06f04763          	bgtz	a5,80004336 <end_op+0xbc>
    acquire(&log.lock);
    800042cc:	0001d497          	auipc	s1,0x1d
    800042d0:	63c48493          	addi	s1,s1,1596 # 80021908 <log>
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	97a080e7          	jalr	-1670(ra) # 80000c50 <acquire>
    log.committing = 0;
    800042de:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042e2:	8526                	mv	a0,s1
    800042e4:	ffffe097          	auipc	ra,0xffffe
    800042e8:	0d0080e7          	jalr	208(ra) # 800023b4 <wakeup>
    release(&log.lock);
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	a16080e7          	jalr	-1514(ra) # 80000d04 <release>
}
    800042f6:	a03d                	j	80004324 <end_op+0xaa>
    panic("log.committing");
    800042f8:	00004517          	auipc	a0,0x4
    800042fc:	53850513          	addi	a0,a0,1336 # 80008830 <syscalls_name+0x1f0>
    80004300:	ffffc097          	auipc	ra,0xffffc
    80004304:	242080e7          	jalr	578(ra) # 80000542 <panic>
    wakeup(&log);
    80004308:	0001d497          	auipc	s1,0x1d
    8000430c:	60048493          	addi	s1,s1,1536 # 80021908 <log>
    80004310:	8526                	mv	a0,s1
    80004312:	ffffe097          	auipc	ra,0xffffe
    80004316:	0a2080e7          	jalr	162(ra) # 800023b4 <wakeup>
  release(&log.lock);
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	9e8080e7          	jalr	-1560(ra) # 80000d04 <release>
}
    80004324:	70e2                	ld	ra,56(sp)
    80004326:	7442                	ld	s0,48(sp)
    80004328:	74a2                	ld	s1,40(sp)
    8000432a:	7902                	ld	s2,32(sp)
    8000432c:	69e2                	ld	s3,24(sp)
    8000432e:	6a42                	ld	s4,16(sp)
    80004330:	6aa2                	ld	s5,8(sp)
    80004332:	6121                	addi	sp,sp,64
    80004334:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004336:	0001da97          	auipc	s5,0x1d
    8000433a:	602a8a93          	addi	s5,s5,1538 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000433e:	0001da17          	auipc	s4,0x1d
    80004342:	5caa0a13          	addi	s4,s4,1482 # 80021908 <log>
    80004346:	018a2583          	lw	a1,24(s4)
    8000434a:	012585bb          	addw	a1,a1,s2
    8000434e:	2585                	addiw	a1,a1,1
    80004350:	028a2503          	lw	a0,40(s4)
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	ce8080e7          	jalr	-792(ra) # 8000303c <bread>
    8000435c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000435e:	000aa583          	lw	a1,0(s5)
    80004362:	028a2503          	lw	a0,40(s4)
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	cd6080e7          	jalr	-810(ra) # 8000303c <bread>
    8000436e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004370:	40000613          	li	a2,1024
    80004374:	05850593          	addi	a1,a0,88
    80004378:	05848513          	addi	a0,s1,88
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	a2c080e7          	jalr	-1492(ra) # 80000da8 <memmove>
    bwrite(to);  // write the log
    80004384:	8526                	mv	a0,s1
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	da8080e7          	jalr	-600(ra) # 8000312e <bwrite>
    brelse(from);
    8000438e:	854e                	mv	a0,s3
    80004390:	fffff097          	auipc	ra,0xfffff
    80004394:	ddc080e7          	jalr	-548(ra) # 8000316c <brelse>
    brelse(to);
    80004398:	8526                	mv	a0,s1
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	dd2080e7          	jalr	-558(ra) # 8000316c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a2:	2905                	addiw	s2,s2,1
    800043a4:	0a91                	addi	s5,s5,4
    800043a6:	02ca2783          	lw	a5,44(s4)
    800043aa:	f8f94ee3          	blt	s2,a5,80004346 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	c7a080e7          	jalr	-902(ra) # 80004028 <write_head>
    install_trans(); // Now install writes to home locations
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	cec080e7          	jalr	-788(ra) # 800040a2 <install_trans>
    log.lh.n = 0;
    800043be:	0001d797          	auipc	a5,0x1d
    800043c2:	5607ab23          	sw	zero,1398(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	c62080e7          	jalr	-926(ra) # 80004028 <write_head>
    800043ce:	bdfd                	j	800042cc <end_op+0x52>

00000000800043d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043dc:	0001d717          	auipc	a4,0x1d
    800043e0:	55872703          	lw	a4,1368(a4) # 80021934 <log+0x2c>
    800043e4:	47f5                	li	a5,29
    800043e6:	08e7c063          	blt	a5,a4,80004466 <log_write+0x96>
    800043ea:	84aa                	mv	s1,a0
    800043ec:	0001d797          	auipc	a5,0x1d
    800043f0:	5387a783          	lw	a5,1336(a5) # 80021924 <log+0x1c>
    800043f4:	37fd                	addiw	a5,a5,-1
    800043f6:	06f75863          	bge	a4,a5,80004466 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043fa:	0001d797          	auipc	a5,0x1d
    800043fe:	52e7a783          	lw	a5,1326(a5) # 80021928 <log+0x20>
    80004402:	06f05a63          	blez	a5,80004476 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004406:	0001d917          	auipc	s2,0x1d
    8000440a:	50290913          	addi	s2,s2,1282 # 80021908 <log>
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	840080e7          	jalr	-1984(ra) # 80000c50 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004418:	02c92603          	lw	a2,44(s2)
    8000441c:	06c05563          	blez	a2,80004486 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004420:	44cc                	lw	a1,12(s1)
    80004422:	0001d717          	auipc	a4,0x1d
    80004426:	51670713          	addi	a4,a4,1302 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000442c:	4314                	lw	a3,0(a4)
    8000442e:	04b68d63          	beq	a3,a1,80004488 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004432:	2785                	addiw	a5,a5,1
    80004434:	0711                	addi	a4,a4,4
    80004436:	fec79be3          	bne	a5,a2,8000442c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000443a:	0621                	addi	a2,a2,8
    8000443c:	060a                	slli	a2,a2,0x2
    8000443e:	0001d797          	auipc	a5,0x1d
    80004442:	4ca78793          	addi	a5,a5,1226 # 80021908 <log>
    80004446:	963e                	add	a2,a2,a5
    80004448:	44dc                	lw	a5,12(s1)
    8000444a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000444c:	8526                	mv	a0,s1
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	dbc080e7          	jalr	-580(ra) # 8000320a <bpin>
    log.lh.n++;
    80004456:	0001d717          	auipc	a4,0x1d
    8000445a:	4b270713          	addi	a4,a4,1202 # 80021908 <log>
    8000445e:	575c                	lw	a5,44(a4)
    80004460:	2785                	addiw	a5,a5,1
    80004462:	d75c                	sw	a5,44(a4)
    80004464:	a83d                	j	800044a2 <log_write+0xd2>
    panic("too big a transaction");
    80004466:	00004517          	auipc	a0,0x4
    8000446a:	3da50513          	addi	a0,a0,986 # 80008840 <syscalls_name+0x200>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	0d4080e7          	jalr	212(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004476:	00004517          	auipc	a0,0x4
    8000447a:	3e250513          	addi	a0,a0,994 # 80008858 <syscalls_name+0x218>
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	0c4080e7          	jalr	196(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004486:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004488:	00878713          	addi	a4,a5,8
    8000448c:	00271693          	slli	a3,a4,0x2
    80004490:	0001d717          	auipc	a4,0x1d
    80004494:	47870713          	addi	a4,a4,1144 # 80021908 <log>
    80004498:	9736                	add	a4,a4,a3
    8000449a:	44d4                	lw	a3,12(s1)
    8000449c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000449e:	faf607e3          	beq	a2,a5,8000444c <log_write+0x7c>
  }
  release(&log.lock);
    800044a2:	0001d517          	auipc	a0,0x1d
    800044a6:	46650513          	addi	a0,a0,1126 # 80021908 <log>
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	85a080e7          	jalr	-1958(ra) # 80000d04 <release>
}
    800044b2:	60e2                	ld	ra,24(sp)
    800044b4:	6442                	ld	s0,16(sp)
    800044b6:	64a2                	ld	s1,8(sp)
    800044b8:	6902                	ld	s2,0(sp)
    800044ba:	6105                	addi	sp,sp,32
    800044bc:	8082                	ret

00000000800044be <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
    800044cc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ce:	00004597          	auipc	a1,0x4
    800044d2:	3aa58593          	addi	a1,a1,938 # 80008878 <syscalls_name+0x238>
    800044d6:	0521                	addi	a0,a0,8
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	6e8080e7          	jalr	1768(ra) # 80000bc0 <initlock>
  lk->name = name;
    800044e0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e8:	0204a423          	sw	zero,40(s1)
}
    800044ec:	60e2                	ld	ra,24(sp)
    800044ee:	6442                	ld	s0,16(sp)
    800044f0:	64a2                	ld	s1,8(sp)
    800044f2:	6902                	ld	s2,0(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044f8:	1101                	addi	sp,sp,-32
    800044fa:	ec06                	sd	ra,24(sp)
    800044fc:	e822                	sd	s0,16(sp)
    800044fe:	e426                	sd	s1,8(sp)
    80004500:	e04a                	sd	s2,0(sp)
    80004502:	1000                	addi	s0,sp,32
    80004504:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004506:	00850913          	addi	s2,a0,8
    8000450a:	854a                	mv	a0,s2
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	744080e7          	jalr	1860(ra) # 80000c50 <acquire>
  while (lk->locked) {
    80004514:	409c                	lw	a5,0(s1)
    80004516:	cb89                	beqz	a5,80004528 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004518:	85ca                	mv	a1,s2
    8000451a:	8526                	mv	a0,s1
    8000451c:	ffffe097          	auipc	ra,0xffffe
    80004520:	d18080e7          	jalr	-744(ra) # 80002234 <sleep>
  while (lk->locked) {
    80004524:	409c                	lw	a5,0(s1)
    80004526:	fbed                	bnez	a5,80004518 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004528:	4785                	li	a5,1
    8000452a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000452c:	ffffd097          	auipc	ra,0xffffd
    80004530:	4f0080e7          	jalr	1264(ra) # 80001a1c <myproc>
    80004534:	5d1c                	lw	a5,56(a0)
    80004536:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	7ca080e7          	jalr	1994(ra) # 80000d04 <release>
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	e04a                	sd	s2,0(sp)
    80004558:	1000                	addi	s0,sp,32
    8000455a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000455c:	00850913          	addi	s2,a0,8
    80004560:	854a                	mv	a0,s2
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	6ee080e7          	jalr	1774(ra) # 80000c50 <acquire>
  lk->locked = 0;
    8000456a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000456e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	e40080e7          	jalr	-448(ra) # 800023b4 <wakeup>
  release(&lk->lk);
    8000457c:	854a                	mv	a0,s2
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	786080e7          	jalr	1926(ra) # 80000d04 <release>
}
    80004586:	60e2                	ld	ra,24(sp)
    80004588:	6442                	ld	s0,16(sp)
    8000458a:	64a2                	ld	s1,8(sp)
    8000458c:	6902                	ld	s2,0(sp)
    8000458e:	6105                	addi	sp,sp,32
    80004590:	8082                	ret

0000000080004592 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004592:	7179                	addi	sp,sp,-48
    80004594:	f406                	sd	ra,40(sp)
    80004596:	f022                	sd	s0,32(sp)
    80004598:	ec26                	sd	s1,24(sp)
    8000459a:	e84a                	sd	s2,16(sp)
    8000459c:	e44e                	sd	s3,8(sp)
    8000459e:	1800                	addi	s0,sp,48
    800045a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045a2:	00850913          	addi	s2,a0,8
    800045a6:	854a                	mv	a0,s2
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	6a8080e7          	jalr	1704(ra) # 80000c50 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b0:	409c                	lw	a5,0(s1)
    800045b2:	ef99                	bnez	a5,800045d0 <holdingsleep+0x3e>
    800045b4:	4481                	li	s1,0
  release(&lk->lk);
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	74c080e7          	jalr	1868(ra) # 80000d04 <release>
  return r;
}
    800045c0:	8526                	mv	a0,s1
    800045c2:	70a2                	ld	ra,40(sp)
    800045c4:	7402                	ld	s0,32(sp)
    800045c6:	64e2                	ld	s1,24(sp)
    800045c8:	6942                	ld	s2,16(sp)
    800045ca:	69a2                	ld	s3,8(sp)
    800045cc:	6145                	addi	sp,sp,48
    800045ce:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d0:	0284a983          	lw	s3,40(s1)
    800045d4:	ffffd097          	auipc	ra,0xffffd
    800045d8:	448080e7          	jalr	1096(ra) # 80001a1c <myproc>
    800045dc:	5d04                	lw	s1,56(a0)
    800045de:	413484b3          	sub	s1,s1,s3
    800045e2:	0014b493          	seqz	s1,s1
    800045e6:	bfc1                	j	800045b6 <holdingsleep+0x24>

00000000800045e8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045e8:	1141                	addi	sp,sp,-16
    800045ea:	e406                	sd	ra,8(sp)
    800045ec:	e022                	sd	s0,0(sp)
    800045ee:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045f0:	00004597          	auipc	a1,0x4
    800045f4:	29858593          	addi	a1,a1,664 # 80008888 <syscalls_name+0x248>
    800045f8:	0001d517          	auipc	a0,0x1d
    800045fc:	45850513          	addi	a0,a0,1112 # 80021a50 <ftable>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5c0080e7          	jalr	1472(ra) # 80000bc0 <initlock>
}
    80004608:	60a2                	ld	ra,8(sp)
    8000460a:	6402                	ld	s0,0(sp)
    8000460c:	0141                	addi	sp,sp,16
    8000460e:	8082                	ret

0000000080004610 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	43650513          	addi	a0,a0,1078 # 80021a50 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	62e080e7          	jalr	1582(ra) # 80000c50 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000462a:	0001d497          	auipc	s1,0x1d
    8000462e:	43e48493          	addi	s1,s1,1086 # 80021a68 <ftable+0x18>
    80004632:	0001e717          	auipc	a4,0x1e
    80004636:	3d670713          	addi	a4,a4,982 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    8000463a:	40dc                	lw	a5,4(s1)
    8000463c:	cf99                	beqz	a5,8000465a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463e:	02848493          	addi	s1,s1,40
    80004642:	fee49ce3          	bne	s1,a4,8000463a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004646:	0001d517          	auipc	a0,0x1d
    8000464a:	40a50513          	addi	a0,a0,1034 # 80021a50 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	6b6080e7          	jalr	1718(ra) # 80000d04 <release>
  return 0;
    80004656:	4481                	li	s1,0
    80004658:	a819                	j	8000466e <filealloc+0x5e>
      f->ref = 1;
    8000465a:	4785                	li	a5,1
    8000465c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	3f250513          	addi	a0,a0,1010 # 80021a50 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	69e080e7          	jalr	1694(ra) # 80000d04 <release>
}
    8000466e:	8526                	mv	a0,s1
    80004670:	60e2                	ld	ra,24(sp)
    80004672:	6442                	ld	s0,16(sp)
    80004674:	64a2                	ld	s1,8(sp)
    80004676:	6105                	addi	sp,sp,32
    80004678:	8082                	ret

000000008000467a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	1000                	addi	s0,sp,32
    80004684:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004686:	0001d517          	auipc	a0,0x1d
    8000468a:	3ca50513          	addi	a0,a0,970 # 80021a50 <ftable>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	5c2080e7          	jalr	1474(ra) # 80000c50 <acquire>
  if(f->ref < 1)
    80004696:	40dc                	lw	a5,4(s1)
    80004698:	02f05263          	blez	a5,800046bc <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000469c:	2785                	addiw	a5,a5,1
    8000469e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	3b050513          	addi	a0,a0,944 # 80021a50 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	65c080e7          	jalr	1628(ra) # 80000d04 <release>
  return f;
}
    800046b0:	8526                	mv	a0,s1
    800046b2:	60e2                	ld	ra,24(sp)
    800046b4:	6442                	ld	s0,16(sp)
    800046b6:	64a2                	ld	s1,8(sp)
    800046b8:	6105                	addi	sp,sp,32
    800046ba:	8082                	ret
    panic("filedup");
    800046bc:	00004517          	auipc	a0,0x4
    800046c0:	1d450513          	addi	a0,a0,468 # 80008890 <syscalls_name+0x250>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	e7e080e7          	jalr	-386(ra) # 80000542 <panic>

00000000800046cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046cc:	7139                	addi	sp,sp,-64
    800046ce:	fc06                	sd	ra,56(sp)
    800046d0:	f822                	sd	s0,48(sp)
    800046d2:	f426                	sd	s1,40(sp)
    800046d4:	f04a                	sd	s2,32(sp)
    800046d6:	ec4e                	sd	s3,24(sp)
    800046d8:	e852                	sd	s4,16(sp)
    800046da:	e456                	sd	s5,8(sp)
    800046dc:	0080                	addi	s0,sp,64
    800046de:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046e0:	0001d517          	auipc	a0,0x1d
    800046e4:	37050513          	addi	a0,a0,880 # 80021a50 <ftable>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	568080e7          	jalr	1384(ra) # 80000c50 <acquire>
  if(f->ref < 1)
    800046f0:	40dc                	lw	a5,4(s1)
    800046f2:	06f05163          	blez	a5,80004754 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046f6:	37fd                	addiw	a5,a5,-1
    800046f8:	0007871b          	sext.w	a4,a5
    800046fc:	c0dc                	sw	a5,4(s1)
    800046fe:	06e04363          	bgtz	a4,80004764 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004702:	0004a903          	lw	s2,0(s1)
    80004706:	0094ca83          	lbu	s5,9(s1)
    8000470a:	0104ba03          	ld	s4,16(s1)
    8000470e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004712:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004716:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000471a:	0001d517          	auipc	a0,0x1d
    8000471e:	33650513          	addi	a0,a0,822 # 80021a50 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	5e2080e7          	jalr	1506(ra) # 80000d04 <release>

  if(ff.type == FD_PIPE){
    8000472a:	4785                	li	a5,1
    8000472c:	04f90d63          	beq	s2,a5,80004786 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004730:	3979                	addiw	s2,s2,-2
    80004732:	4785                	li	a5,1
    80004734:	0527e063          	bltu	a5,s2,80004774 <fileclose+0xa8>
    begin_op();
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	ac2080e7          	jalr	-1342(ra) # 800041fa <begin_op>
    iput(ff.ip);
    80004740:	854e                	mv	a0,s3
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	2b6080e7          	jalr	694(ra) # 800039f8 <iput>
    end_op();
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	b30080e7          	jalr	-1232(ra) # 8000427a <end_op>
    80004752:	a00d                	j	80004774 <fileclose+0xa8>
    panic("fileclose");
    80004754:	00004517          	auipc	a0,0x4
    80004758:	14450513          	addi	a0,a0,324 # 80008898 <syscalls_name+0x258>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	de6080e7          	jalr	-538(ra) # 80000542 <panic>
    release(&ftable.lock);
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	2ec50513          	addi	a0,a0,748 # 80021a50 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	598080e7          	jalr	1432(ra) # 80000d04 <release>
  }
}
    80004774:	70e2                	ld	ra,56(sp)
    80004776:	7442                	ld	s0,48(sp)
    80004778:	74a2                	ld	s1,40(sp)
    8000477a:	7902                	ld	s2,32(sp)
    8000477c:	69e2                	ld	s3,24(sp)
    8000477e:	6a42                	ld	s4,16(sp)
    80004780:	6aa2                	ld	s5,8(sp)
    80004782:	6121                	addi	sp,sp,64
    80004784:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004786:	85d6                	mv	a1,s5
    80004788:	8552                	mv	a0,s4
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	372080e7          	jalr	882(ra) # 80004afc <pipeclose>
    80004792:	b7cd                	j	80004774 <fileclose+0xa8>

0000000080004794 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004794:	715d                	addi	sp,sp,-80
    80004796:	e486                	sd	ra,72(sp)
    80004798:	e0a2                	sd	s0,64(sp)
    8000479a:	fc26                	sd	s1,56(sp)
    8000479c:	f84a                	sd	s2,48(sp)
    8000479e:	f44e                	sd	s3,40(sp)
    800047a0:	0880                	addi	s0,sp,80
    800047a2:	84aa                	mv	s1,a0
    800047a4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047a6:	ffffd097          	auipc	ra,0xffffd
    800047aa:	276080e7          	jalr	630(ra) # 80001a1c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047ae:	409c                	lw	a5,0(s1)
    800047b0:	37f9                	addiw	a5,a5,-2
    800047b2:	4705                	li	a4,1
    800047b4:	04f76763          	bltu	a4,a5,80004802 <filestat+0x6e>
    800047b8:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	082080e7          	jalr	130(ra) # 8000383e <ilock>
    stati(f->ip, &st);
    800047c4:	fb840593          	addi	a1,s0,-72
    800047c8:	6c88                	ld	a0,24(s1)
    800047ca:	fffff097          	auipc	ra,0xfffff
    800047ce:	2fe080e7          	jalr	766(ra) # 80003ac8 <stati>
    iunlock(f->ip);
    800047d2:	6c88                	ld	a0,24(s1)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	12c080e7          	jalr	300(ra) # 80003900 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047dc:	46e1                	li	a3,24
    800047de:	fb840613          	addi	a2,s0,-72
    800047e2:	85ce                	mv	a1,s3
    800047e4:	05093503          	ld	a0,80(s2)
    800047e8:	ffffd097          	auipc	ra,0xffffd
    800047ec:	f26080e7          	jalr	-218(ra) # 8000170e <copyout>
    800047f0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047f4:	60a6                	ld	ra,72(sp)
    800047f6:	6406                	ld	s0,64(sp)
    800047f8:	74e2                	ld	s1,56(sp)
    800047fa:	7942                	ld	s2,48(sp)
    800047fc:	79a2                	ld	s3,40(sp)
    800047fe:	6161                	addi	sp,sp,80
    80004800:	8082                	ret
  return -1;
    80004802:	557d                	li	a0,-1
    80004804:	bfc5                	j	800047f4 <filestat+0x60>

0000000080004806 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004806:	7179                	addi	sp,sp,-48
    80004808:	f406                	sd	ra,40(sp)
    8000480a:	f022                	sd	s0,32(sp)
    8000480c:	ec26                	sd	s1,24(sp)
    8000480e:	e84a                	sd	s2,16(sp)
    80004810:	e44e                	sd	s3,8(sp)
    80004812:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004814:	00854783          	lbu	a5,8(a0)
    80004818:	c3d5                	beqz	a5,800048bc <fileread+0xb6>
    8000481a:	84aa                	mv	s1,a0
    8000481c:	89ae                	mv	s3,a1
    8000481e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004820:	411c                	lw	a5,0(a0)
    80004822:	4705                	li	a4,1
    80004824:	04e78963          	beq	a5,a4,80004876 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004828:	470d                	li	a4,3
    8000482a:	04e78d63          	beq	a5,a4,80004884 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000482e:	4709                	li	a4,2
    80004830:	06e79e63          	bne	a5,a4,800048ac <fileread+0xa6>
    ilock(f->ip);
    80004834:	6d08                	ld	a0,24(a0)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	008080e7          	jalr	8(ra) # 8000383e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000483e:	874a                	mv	a4,s2
    80004840:	5094                	lw	a3,32(s1)
    80004842:	864e                	mv	a2,s3
    80004844:	4585                	li	a1,1
    80004846:	6c88                	ld	a0,24(s1)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	2aa080e7          	jalr	682(ra) # 80003af2 <readi>
    80004850:	892a                	mv	s2,a0
    80004852:	00a05563          	blez	a0,8000485c <fileread+0x56>
      f->off += r;
    80004856:	509c                	lw	a5,32(s1)
    80004858:	9fa9                	addw	a5,a5,a0
    8000485a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000485c:	6c88                	ld	a0,24(s1)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	0a2080e7          	jalr	162(ra) # 80003900 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004866:	854a                	mv	a0,s2
    80004868:	70a2                	ld	ra,40(sp)
    8000486a:	7402                	ld	s0,32(sp)
    8000486c:	64e2                	ld	s1,24(sp)
    8000486e:	6942                	ld	s2,16(sp)
    80004870:	69a2                	ld	s3,8(sp)
    80004872:	6145                	addi	sp,sp,48
    80004874:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004876:	6908                	ld	a0,16(a0)
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	3f4080e7          	jalr	1012(ra) # 80004c6c <piperead>
    80004880:	892a                	mv	s2,a0
    80004882:	b7d5                	j	80004866 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004884:	02451783          	lh	a5,36(a0)
    80004888:	03079693          	slli	a3,a5,0x30
    8000488c:	92c1                	srli	a3,a3,0x30
    8000488e:	4725                	li	a4,9
    80004890:	02d76863          	bltu	a4,a3,800048c0 <fileread+0xba>
    80004894:	0792                	slli	a5,a5,0x4
    80004896:	0001d717          	auipc	a4,0x1d
    8000489a:	11a70713          	addi	a4,a4,282 # 800219b0 <devsw>
    8000489e:	97ba                	add	a5,a5,a4
    800048a0:	639c                	ld	a5,0(a5)
    800048a2:	c38d                	beqz	a5,800048c4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048a4:	4505                	li	a0,1
    800048a6:	9782                	jalr	a5
    800048a8:	892a                	mv	s2,a0
    800048aa:	bf75                	j	80004866 <fileread+0x60>
    panic("fileread");
    800048ac:	00004517          	auipc	a0,0x4
    800048b0:	ffc50513          	addi	a0,a0,-4 # 800088a8 <syscalls_name+0x268>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	c8e080e7          	jalr	-882(ra) # 80000542 <panic>
    return -1;
    800048bc:	597d                	li	s2,-1
    800048be:	b765                	j	80004866 <fileread+0x60>
      return -1;
    800048c0:	597d                	li	s2,-1
    800048c2:	b755                	j	80004866 <fileread+0x60>
    800048c4:	597d                	li	s2,-1
    800048c6:	b745                	j	80004866 <fileread+0x60>

00000000800048c8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048c8:	00954783          	lbu	a5,9(a0)
    800048cc:	14078563          	beqz	a5,80004a16 <filewrite+0x14e>
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	f052                	sd	s4,32(sp)
    800048de:	ec56                	sd	s5,24(sp)
    800048e0:	e85a                	sd	s6,16(sp)
    800048e2:	e45e                	sd	s7,8(sp)
    800048e4:	e062                	sd	s8,0(sp)
    800048e6:	0880                	addi	s0,sp,80
    800048e8:	892a                	mv	s2,a0
    800048ea:	8aae                	mv	s5,a1
    800048ec:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ee:	411c                	lw	a5,0(a0)
    800048f0:	4705                	li	a4,1
    800048f2:	02e78263          	beq	a5,a4,80004916 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048f6:	470d                	li	a4,3
    800048f8:	02e78563          	beq	a5,a4,80004922 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048fc:	4709                	li	a4,2
    800048fe:	10e79463          	bne	a5,a4,80004a06 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004902:	0ec05e63          	blez	a2,800049fe <filewrite+0x136>
    int i = 0;
    80004906:	4981                	li	s3,0
    80004908:	6b05                	lui	s6,0x1
    8000490a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000490e:	6b85                	lui	s7,0x1
    80004910:	c00b8b9b          	addiw	s7,s7,-1024
    80004914:	a851                	j	800049a8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004916:	6908                	ld	a0,16(a0)
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	254080e7          	jalr	596(ra) # 80004b6c <pipewrite>
    80004920:	a85d                	j	800049d6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004922:	02451783          	lh	a5,36(a0)
    80004926:	03079693          	slli	a3,a5,0x30
    8000492a:	92c1                	srli	a3,a3,0x30
    8000492c:	4725                	li	a4,9
    8000492e:	0ed76663          	bltu	a4,a3,80004a1a <filewrite+0x152>
    80004932:	0792                	slli	a5,a5,0x4
    80004934:	0001d717          	auipc	a4,0x1d
    80004938:	07c70713          	addi	a4,a4,124 # 800219b0 <devsw>
    8000493c:	97ba                	add	a5,a5,a4
    8000493e:	679c                	ld	a5,8(a5)
    80004940:	cff9                	beqz	a5,80004a1e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004942:	4505                	li	a0,1
    80004944:	9782                	jalr	a5
    80004946:	a841                	j	800049d6 <filewrite+0x10e>
    80004948:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	8ae080e7          	jalr	-1874(ra) # 800041fa <begin_op>
      ilock(f->ip);
    80004954:	01893503          	ld	a0,24(s2)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	ee6080e7          	jalr	-282(ra) # 8000383e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004960:	8762                	mv	a4,s8
    80004962:	02092683          	lw	a3,32(s2)
    80004966:	01598633          	add	a2,s3,s5
    8000496a:	4585                	li	a1,1
    8000496c:	01893503          	ld	a0,24(s2)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	278080e7          	jalr	632(ra) # 80003be8 <writei>
    80004978:	84aa                	mv	s1,a0
    8000497a:	02a05f63          	blez	a0,800049b8 <filewrite+0xf0>
        f->off += r;
    8000497e:	02092783          	lw	a5,32(s2)
    80004982:	9fa9                	addw	a5,a5,a0
    80004984:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004988:	01893503          	ld	a0,24(s2)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	f74080e7          	jalr	-140(ra) # 80003900 <iunlock>
      end_op();
    80004994:	00000097          	auipc	ra,0x0
    80004998:	8e6080e7          	jalr	-1818(ra) # 8000427a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000499c:	049c1963          	bne	s8,s1,800049ee <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049a0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049a4:	0349d663          	bge	s3,s4,800049d0 <filewrite+0x108>
      int n1 = n - i;
    800049a8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049ac:	84be                	mv	s1,a5
    800049ae:	2781                	sext.w	a5,a5
    800049b0:	f8fb5ce3          	bge	s6,a5,80004948 <filewrite+0x80>
    800049b4:	84de                	mv	s1,s7
    800049b6:	bf49                	j	80004948 <filewrite+0x80>
      iunlock(f->ip);
    800049b8:	01893503          	ld	a0,24(s2)
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	f44080e7          	jalr	-188(ra) # 80003900 <iunlock>
      end_op();
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	8b6080e7          	jalr	-1866(ra) # 8000427a <end_op>
      if(r < 0)
    800049cc:	fc04d8e3          	bgez	s1,8000499c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049d0:	8552                	mv	a0,s4
    800049d2:	033a1863          	bne	s4,s3,80004a02 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049d6:	60a6                	ld	ra,72(sp)
    800049d8:	6406                	ld	s0,64(sp)
    800049da:	74e2                	ld	s1,56(sp)
    800049dc:	7942                	ld	s2,48(sp)
    800049de:	79a2                	ld	s3,40(sp)
    800049e0:	7a02                	ld	s4,32(sp)
    800049e2:	6ae2                	ld	s5,24(sp)
    800049e4:	6b42                	ld	s6,16(sp)
    800049e6:	6ba2                	ld	s7,8(sp)
    800049e8:	6c02                	ld	s8,0(sp)
    800049ea:	6161                	addi	sp,sp,80
    800049ec:	8082                	ret
        panic("short filewrite");
    800049ee:	00004517          	auipc	a0,0x4
    800049f2:	eca50513          	addi	a0,a0,-310 # 800088b8 <syscalls_name+0x278>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	b4c080e7          	jalr	-1204(ra) # 80000542 <panic>
    int i = 0;
    800049fe:	4981                	li	s3,0
    80004a00:	bfc1                	j	800049d0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a02:	557d                	li	a0,-1
    80004a04:	bfc9                	j	800049d6 <filewrite+0x10e>
    panic("filewrite");
    80004a06:	00004517          	auipc	a0,0x4
    80004a0a:	ec250513          	addi	a0,a0,-318 # 800088c8 <syscalls_name+0x288>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	b34080e7          	jalr	-1228(ra) # 80000542 <panic>
    return -1;
    80004a16:	557d                	li	a0,-1
}
    80004a18:	8082                	ret
      return -1;
    80004a1a:	557d                	li	a0,-1
    80004a1c:	bf6d                	j	800049d6 <filewrite+0x10e>
    80004a1e:	557d                	li	a0,-1
    80004a20:	bf5d                	j	800049d6 <filewrite+0x10e>

0000000080004a22 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a22:	7179                	addi	sp,sp,-48
    80004a24:	f406                	sd	ra,40(sp)
    80004a26:	f022                	sd	s0,32(sp)
    80004a28:	ec26                	sd	s1,24(sp)
    80004a2a:	e84a                	sd	s2,16(sp)
    80004a2c:	e44e                	sd	s3,8(sp)
    80004a2e:	e052                	sd	s4,0(sp)
    80004a30:	1800                	addi	s0,sp,48
    80004a32:	84aa                	mv	s1,a0
    80004a34:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a36:	0005b023          	sd	zero,0(a1)
    80004a3a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	bd2080e7          	jalr	-1070(ra) # 80004610 <filealloc>
    80004a46:	e088                	sd	a0,0(s1)
    80004a48:	c551                	beqz	a0,80004ad4 <pipealloc+0xb2>
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	bc6080e7          	jalr	-1082(ra) # 80004610 <filealloc>
    80004a52:	00aa3023          	sd	a0,0(s4)
    80004a56:	c92d                	beqz	a0,80004ac8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	0b6080e7          	jalr	182(ra) # 80000b0e <kalloc>
    80004a60:	892a                	mv	s2,a0
    80004a62:	c125                	beqz	a0,80004ac2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a64:	4985                	li	s3,1
    80004a66:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a6a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a6e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a72:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a76:	00004597          	auipc	a1,0x4
    80004a7a:	9fa58593          	addi	a1,a1,-1542 # 80008470 <states.0+0x1c8>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	142080e7          	jalr	322(ra) # 80000bc0 <initlock>
  (*f0)->type = FD_PIPE;
    80004a86:	609c                	ld	a5,0(s1)
    80004a88:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a8c:	609c                	ld	a5,0(s1)
    80004a8e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a92:	609c                	ld	a5,0(s1)
    80004a94:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a98:	609c                	ld	a5,0(s1)
    80004a9a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a9e:	000a3783          	ld	a5,0(s4)
    80004aa2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aa6:	000a3783          	ld	a5,0(s4)
    80004aaa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aae:	000a3783          	ld	a5,0(s4)
    80004ab2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ab6:	000a3783          	ld	a5,0(s4)
    80004aba:	0127b823          	sd	s2,16(a5)
  return 0;
    80004abe:	4501                	li	a0,0
    80004ac0:	a025                	j	80004ae8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ac2:	6088                	ld	a0,0(s1)
    80004ac4:	e501                	bnez	a0,80004acc <pipealloc+0xaa>
    80004ac6:	a039                	j	80004ad4 <pipealloc+0xb2>
    80004ac8:	6088                	ld	a0,0(s1)
    80004aca:	c51d                	beqz	a0,80004af8 <pipealloc+0xd6>
    fileclose(*f0);
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	c00080e7          	jalr	-1024(ra) # 800046cc <fileclose>
  if(*f1)
    80004ad4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ad8:	557d                	li	a0,-1
  if(*f1)
    80004ada:	c799                	beqz	a5,80004ae8 <pipealloc+0xc6>
    fileclose(*f1);
    80004adc:	853e                	mv	a0,a5
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	bee080e7          	jalr	-1042(ra) # 800046cc <fileclose>
  return -1;
    80004ae6:	557d                	li	a0,-1
}
    80004ae8:	70a2                	ld	ra,40(sp)
    80004aea:	7402                	ld	s0,32(sp)
    80004aec:	64e2                	ld	s1,24(sp)
    80004aee:	6942                	ld	s2,16(sp)
    80004af0:	69a2                	ld	s3,8(sp)
    80004af2:	6a02                	ld	s4,0(sp)
    80004af4:	6145                	addi	sp,sp,48
    80004af6:	8082                	ret
  return -1;
    80004af8:	557d                	li	a0,-1
    80004afa:	b7fd                	j	80004ae8 <pipealloc+0xc6>

0000000080004afc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	e04a                	sd	s2,0(sp)
    80004b06:	1000                	addi	s0,sp,32
    80004b08:	84aa                	mv	s1,a0
    80004b0a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	144080e7          	jalr	324(ra) # 80000c50 <acquire>
  if(writable){
    80004b14:	02090d63          	beqz	s2,80004b4e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b18:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b1c:	21848513          	addi	a0,s1,536
    80004b20:	ffffe097          	auipc	ra,0xffffe
    80004b24:	894080e7          	jalr	-1900(ra) # 800023b4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b28:	2204b783          	ld	a5,544(s1)
    80004b2c:	eb95                	bnez	a5,80004b60 <pipeclose+0x64>
    release(&pi->lock);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	1d4080e7          	jalr	468(ra) # 80000d04 <release>
    kfree((char*)pi);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	ed8080e7          	jalr	-296(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004b42:	60e2                	ld	ra,24(sp)
    80004b44:	6442                	ld	s0,16(sp)
    80004b46:	64a2                	ld	s1,8(sp)
    80004b48:	6902                	ld	s2,0(sp)
    80004b4a:	6105                	addi	sp,sp,32
    80004b4c:	8082                	ret
    pi->readopen = 0;
    80004b4e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b52:	21c48513          	addi	a0,s1,540
    80004b56:	ffffe097          	auipc	ra,0xffffe
    80004b5a:	85e080e7          	jalr	-1954(ra) # 800023b4 <wakeup>
    80004b5e:	b7e9                	j	80004b28 <pipeclose+0x2c>
    release(&pi->lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	1a2080e7          	jalr	418(ra) # 80000d04 <release>
}
    80004b6a:	bfe1                	j	80004b42 <pipeclose+0x46>

0000000080004b6c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b6c:	711d                	addi	sp,sp,-96
    80004b6e:	ec86                	sd	ra,88(sp)
    80004b70:	e8a2                	sd	s0,80(sp)
    80004b72:	e4a6                	sd	s1,72(sp)
    80004b74:	e0ca                	sd	s2,64(sp)
    80004b76:	fc4e                	sd	s3,56(sp)
    80004b78:	f852                	sd	s4,48(sp)
    80004b7a:	f456                	sd	s5,40(sp)
    80004b7c:	f05a                	sd	s6,32(sp)
    80004b7e:	ec5e                	sd	s7,24(sp)
    80004b80:	e862                	sd	s8,16(sp)
    80004b82:	1080                	addi	s0,sp,96
    80004b84:	84aa                	mv	s1,a0
    80004b86:	8b2e                	mv	s6,a1
    80004b88:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	e92080e7          	jalr	-366(ra) # 80001a1c <myproc>
    80004b92:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b94:	8526                	mv	a0,s1
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	0ba080e7          	jalr	186(ra) # 80000c50 <acquire>
  for(i = 0; i < n; i++){
    80004b9e:	09505763          	blez	s5,80004c2c <pipewrite+0xc0>
    80004ba2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ba4:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ba8:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bac:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bae:	2184a783          	lw	a5,536(s1)
    80004bb2:	21c4a703          	lw	a4,540(s1)
    80004bb6:	2007879b          	addiw	a5,a5,512
    80004bba:	02f71b63          	bne	a4,a5,80004bf0 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004bbe:	2204a783          	lw	a5,544(s1)
    80004bc2:	c3d1                	beqz	a5,80004c46 <pipewrite+0xda>
    80004bc4:	03092783          	lw	a5,48(s2)
    80004bc8:	efbd                	bnez	a5,80004c46 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004bca:	8552                	mv	a0,s4
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	7e8080e7          	jalr	2024(ra) # 800023b4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd4:	85a6                	mv	a1,s1
    80004bd6:	854e                	mv	a0,s3
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	65c080e7          	jalr	1628(ra) # 80002234 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004be0:	2184a783          	lw	a5,536(s1)
    80004be4:	21c4a703          	lw	a4,540(s1)
    80004be8:	2007879b          	addiw	a5,a5,512
    80004bec:	fcf709e3          	beq	a4,a5,80004bbe <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf0:	4685                	li	a3,1
    80004bf2:	865a                	mv	a2,s6
    80004bf4:	faf40593          	addi	a1,s0,-81
    80004bf8:	05093503          	ld	a0,80(s2)
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	b9e080e7          	jalr	-1122(ra) # 8000179a <copyin>
    80004c04:	03850563          	beq	a0,s8,80004c2e <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c08:	21c4a783          	lw	a5,540(s1)
    80004c0c:	0017871b          	addiw	a4,a5,1
    80004c10:	20e4ae23          	sw	a4,540(s1)
    80004c14:	1ff7f793          	andi	a5,a5,511
    80004c18:	97a6                	add	a5,a5,s1
    80004c1a:	faf44703          	lbu	a4,-81(s0)
    80004c1e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c22:	2b85                	addiw	s7,s7,1
    80004c24:	0b05                	addi	s6,s6,1
    80004c26:	f97a94e3          	bne	s5,s7,80004bae <pipewrite+0x42>
    80004c2a:	a011                	j	80004c2e <pipewrite+0xc2>
    80004c2c:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004c2e:	21848513          	addi	a0,s1,536
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	782080e7          	jalr	1922(ra) # 800023b4 <wakeup>
  release(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	0c8080e7          	jalr	200(ra) # 80000d04 <release>
  return i;
    80004c44:	a039                	j	80004c52 <pipewrite+0xe6>
        release(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	0bc080e7          	jalr	188(ra) # 80000d04 <release>
        return -1;
    80004c50:	5bfd                	li	s7,-1
}
    80004c52:	855e                	mv	a0,s7
    80004c54:	60e6                	ld	ra,88(sp)
    80004c56:	6446                	ld	s0,80(sp)
    80004c58:	64a6                	ld	s1,72(sp)
    80004c5a:	6906                	ld	s2,64(sp)
    80004c5c:	79e2                	ld	s3,56(sp)
    80004c5e:	7a42                	ld	s4,48(sp)
    80004c60:	7aa2                	ld	s5,40(sp)
    80004c62:	7b02                	ld	s6,32(sp)
    80004c64:	6be2                	ld	s7,24(sp)
    80004c66:	6c42                	ld	s8,16(sp)
    80004c68:	6125                	addi	sp,sp,96
    80004c6a:	8082                	ret

0000000080004c6c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c6c:	715d                	addi	sp,sp,-80
    80004c6e:	e486                	sd	ra,72(sp)
    80004c70:	e0a2                	sd	s0,64(sp)
    80004c72:	fc26                	sd	s1,56(sp)
    80004c74:	f84a                	sd	s2,48(sp)
    80004c76:	f44e                	sd	s3,40(sp)
    80004c78:	f052                	sd	s4,32(sp)
    80004c7a:	ec56                	sd	s5,24(sp)
    80004c7c:	e85a                	sd	s6,16(sp)
    80004c7e:	0880                	addi	s0,sp,80
    80004c80:	84aa                	mv	s1,a0
    80004c82:	892e                	mv	s2,a1
    80004c84:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	d96080e7          	jalr	-618(ra) # 80001a1c <myproc>
    80004c8e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c90:	8526                	mv	a0,s1
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	fbe080e7          	jalr	-66(ra) # 80000c50 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c9a:	2184a703          	lw	a4,536(s1)
    80004c9e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca6:	02f71463          	bne	a4,a5,80004cce <piperead+0x62>
    80004caa:	2244a783          	lw	a5,548(s1)
    80004cae:	c385                	beqz	a5,80004cce <piperead+0x62>
    if(pr->killed){
    80004cb0:	030a2783          	lw	a5,48(s4)
    80004cb4:	ebc1                	bnez	a5,80004d44 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb6:	85a6                	mv	a1,s1
    80004cb8:	854e                	mv	a0,s3
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	57a080e7          	jalr	1402(ra) # 80002234 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc2:	2184a703          	lw	a4,536(s1)
    80004cc6:	21c4a783          	lw	a5,540(s1)
    80004cca:	fef700e3          	beq	a4,a5,80004caa <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cd2:	05505363          	blez	s5,80004d18 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004cd6:	2184a783          	lw	a5,536(s1)
    80004cda:	21c4a703          	lw	a4,540(s1)
    80004cde:	02f70d63          	beq	a4,a5,80004d18 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ce2:	0017871b          	addiw	a4,a5,1
    80004ce6:	20e4ac23          	sw	a4,536(s1)
    80004cea:	1ff7f793          	andi	a5,a5,511
    80004cee:	97a6                	add	a5,a5,s1
    80004cf0:	0187c783          	lbu	a5,24(a5)
    80004cf4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf8:	4685                	li	a3,1
    80004cfa:	fbf40613          	addi	a2,s0,-65
    80004cfe:	85ca                	mv	a1,s2
    80004d00:	050a3503          	ld	a0,80(s4)
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	a0a080e7          	jalr	-1526(ra) # 8000170e <copyout>
    80004d0c:	01650663          	beq	a0,s6,80004d18 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d10:	2985                	addiw	s3,s3,1
    80004d12:	0905                	addi	s2,s2,1
    80004d14:	fd3a91e3          	bne	s5,s3,80004cd6 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d18:	21c48513          	addi	a0,s1,540
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	698080e7          	jalr	1688(ra) # 800023b4 <wakeup>
  release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	fde080e7          	jalr	-34(ra) # 80000d04 <release>
  return i;
}
    80004d2e:	854e                	mv	a0,s3
    80004d30:	60a6                	ld	ra,72(sp)
    80004d32:	6406                	ld	s0,64(sp)
    80004d34:	74e2                	ld	s1,56(sp)
    80004d36:	7942                	ld	s2,48(sp)
    80004d38:	79a2                	ld	s3,40(sp)
    80004d3a:	7a02                	ld	s4,32(sp)
    80004d3c:	6ae2                	ld	s5,24(sp)
    80004d3e:	6b42                	ld	s6,16(sp)
    80004d40:	6161                	addi	sp,sp,80
    80004d42:	8082                	ret
      release(&pi->lock);
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	fbe080e7          	jalr	-66(ra) # 80000d04 <release>
      return -1;
    80004d4e:	59fd                	li	s3,-1
    80004d50:	bff9                	j	80004d2e <piperead+0xc2>

0000000080004d52 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d52:	de010113          	addi	sp,sp,-544
    80004d56:	20113c23          	sd	ra,536(sp)
    80004d5a:	20813823          	sd	s0,528(sp)
    80004d5e:	20913423          	sd	s1,520(sp)
    80004d62:	21213023          	sd	s2,512(sp)
    80004d66:	ffce                	sd	s3,504(sp)
    80004d68:	fbd2                	sd	s4,496(sp)
    80004d6a:	f7d6                	sd	s5,488(sp)
    80004d6c:	f3da                	sd	s6,480(sp)
    80004d6e:	efde                	sd	s7,472(sp)
    80004d70:	ebe2                	sd	s8,464(sp)
    80004d72:	e7e6                	sd	s9,456(sp)
    80004d74:	e3ea                	sd	s10,448(sp)
    80004d76:	ff6e                	sd	s11,440(sp)
    80004d78:	1400                	addi	s0,sp,544
    80004d7a:	892a                	mv	s2,a0
    80004d7c:	dea43423          	sd	a0,-536(s0)
    80004d80:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	c98080e7          	jalr	-872(ra) # 80001a1c <myproc>
    80004d8c:	84aa                	mv	s1,a0

  begin_op();
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	46c080e7          	jalr	1132(ra) # 800041fa <begin_op>

  if((ip = namei(path)) == 0){
    80004d96:	854a                	mv	a0,s2
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	256080e7          	jalr	598(ra) # 80003fee <namei>
    80004da0:	c93d                	beqz	a0,80004e16 <exec+0xc4>
    80004da2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	a9a080e7          	jalr	-1382(ra) # 8000383e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dac:	04000713          	li	a4,64
    80004db0:	4681                	li	a3,0
    80004db2:	e4840613          	addi	a2,s0,-440
    80004db6:	4581                	li	a1,0
    80004db8:	8556                	mv	a0,s5
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	d38080e7          	jalr	-712(ra) # 80003af2 <readi>
    80004dc2:	04000793          	li	a5,64
    80004dc6:	00f51a63          	bne	a0,a5,80004dda <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dca:	e4842703          	lw	a4,-440(s0)
    80004dce:	464c47b7          	lui	a5,0x464c4
    80004dd2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dd6:	04f70663          	beq	a4,a5,80004e22 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dda:	8556                	mv	a0,s5
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	cc4080e7          	jalr	-828(ra) # 80003aa0 <iunlockput>
    end_op();
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	496080e7          	jalr	1174(ra) # 8000427a <end_op>
  }
  return -1;
    80004dec:	557d                	li	a0,-1
}
    80004dee:	21813083          	ld	ra,536(sp)
    80004df2:	21013403          	ld	s0,528(sp)
    80004df6:	20813483          	ld	s1,520(sp)
    80004dfa:	20013903          	ld	s2,512(sp)
    80004dfe:	79fe                	ld	s3,504(sp)
    80004e00:	7a5e                	ld	s4,496(sp)
    80004e02:	7abe                	ld	s5,488(sp)
    80004e04:	7b1e                	ld	s6,480(sp)
    80004e06:	6bfe                	ld	s7,472(sp)
    80004e08:	6c5e                	ld	s8,464(sp)
    80004e0a:	6cbe                	ld	s9,456(sp)
    80004e0c:	6d1e                	ld	s10,448(sp)
    80004e0e:	7dfa                	ld	s11,440(sp)
    80004e10:	22010113          	addi	sp,sp,544
    80004e14:	8082                	ret
    end_op();
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	464080e7          	jalr	1124(ra) # 8000427a <end_op>
    return -1;
    80004e1e:	557d                	li	a0,-1
    80004e20:	b7f9                	j	80004dee <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	cbc080e7          	jalr	-836(ra) # 80001ae0 <proc_pagetable>
    80004e2c:	8b2a                	mv	s6,a0
    80004e2e:	d555                	beqz	a0,80004dda <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e30:	e6842783          	lw	a5,-408(s0)
    80004e34:	e8045703          	lhu	a4,-384(s0)
    80004e38:	c735                	beqz	a4,80004ea4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e3a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e3c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e40:	6a05                	lui	s4,0x1
    80004e42:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e46:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e4a:	6d85                	lui	s11,0x1
    80004e4c:	7d7d                	lui	s10,0xfffff
    80004e4e:	ac1d                	j	80005084 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e50:	00004517          	auipc	a0,0x4
    80004e54:	a8850513          	addi	a0,a0,-1400 # 800088d8 <syscalls_name+0x298>
    80004e58:	ffffb097          	auipc	ra,0xffffb
    80004e5c:	6ea080e7          	jalr	1770(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e60:	874a                	mv	a4,s2
    80004e62:	009c86bb          	addw	a3,s9,s1
    80004e66:	4581                	li	a1,0
    80004e68:	8556                	mv	a0,s5
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	c88080e7          	jalr	-888(ra) # 80003af2 <readi>
    80004e72:	2501                	sext.w	a0,a0
    80004e74:	1aa91863          	bne	s2,a0,80005024 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e78:	009d84bb          	addw	s1,s11,s1
    80004e7c:	013d09bb          	addw	s3,s10,s3
    80004e80:	1f74f263          	bgeu	s1,s7,80005064 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e84:	02049593          	slli	a1,s1,0x20
    80004e88:	9181                	srli	a1,a1,0x20
    80004e8a:	95e2                	add	a1,a1,s8
    80004e8c:	855a                	mv	a0,s6
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	24c080e7          	jalr	588(ra) # 800010da <walkaddr>
    80004e96:	862a                	mv	a2,a0
    if(pa == 0)
    80004e98:	dd45                	beqz	a0,80004e50 <exec+0xfe>
      n = PGSIZE;
    80004e9a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e9c:	fd49f2e3          	bgeu	s3,s4,80004e60 <exec+0x10e>
      n = sz - i;
    80004ea0:	894e                	mv	s2,s3
    80004ea2:	bf7d                	j	80004e60 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ea4:	4481                	li	s1,0
  iunlockput(ip);
    80004ea6:	8556                	mv	a0,s5
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	bf8080e7          	jalr	-1032(ra) # 80003aa0 <iunlockput>
  end_op();
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	3ca080e7          	jalr	970(ra) # 8000427a <end_op>
  p = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	b64080e7          	jalr	-1180(ra) # 80001a1c <myproc>
    80004ec0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ec2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ec6:	6785                	lui	a5,0x1
    80004ec8:	17fd                	addi	a5,a5,-1
    80004eca:	94be                	add	s1,s1,a5
    80004ecc:	77fd                	lui	a5,0xfffff
    80004ece:	8fe5                	and	a5,a5,s1
    80004ed0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ed4:	6609                	lui	a2,0x2
    80004ed6:	963e                	add	a2,a2,a5
    80004ed8:	85be                	mv	a1,a5
    80004eda:	855a                	mv	a0,s6
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	5e2080e7          	jalr	1506(ra) # 800014be <uvmalloc>
    80004ee4:	8c2a                	mv	s8,a0
  ip = 0;
    80004ee6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ee8:	12050e63          	beqz	a0,80005024 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eec:	75f9                	lui	a1,0xffffe
    80004eee:	95aa                	add	a1,a1,a0
    80004ef0:	855a                	mv	a0,s6
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	7ea080e7          	jalr	2026(ra) # 800016dc <uvmclear>
  stackbase = sp - PGSIZE;
    80004efa:	7afd                	lui	s5,0xfffff
    80004efc:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004efe:	df043783          	ld	a5,-528(s0)
    80004f02:	6388                	ld	a0,0(a5)
    80004f04:	c925                	beqz	a0,80004f74 <exec+0x222>
    80004f06:	e8840993          	addi	s3,s0,-376
    80004f0a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f0e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f10:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	fbe080e7          	jalr	-66(ra) # 80000ed0 <strlen>
    80004f1a:	0015079b          	addiw	a5,a0,1
    80004f1e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f22:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f26:	13596363          	bltu	s2,s5,8000504c <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f2a:	df043d83          	ld	s11,-528(s0)
    80004f2e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f32:	8552                	mv	a0,s4
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	f9c080e7          	jalr	-100(ra) # 80000ed0 <strlen>
    80004f3c:	0015069b          	addiw	a3,a0,1
    80004f40:	8652                	mv	a2,s4
    80004f42:	85ca                	mv	a1,s2
    80004f44:	855a                	mv	a0,s6
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	7c8080e7          	jalr	1992(ra) # 8000170e <copyout>
    80004f4e:	10054363          	bltz	a0,80005054 <exec+0x302>
    ustack[argc] = sp;
    80004f52:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f56:	0485                	addi	s1,s1,1
    80004f58:	008d8793          	addi	a5,s11,8
    80004f5c:	def43823          	sd	a5,-528(s0)
    80004f60:	008db503          	ld	a0,8(s11)
    80004f64:	c911                	beqz	a0,80004f78 <exec+0x226>
    if(argc >= MAXARG)
    80004f66:	09a1                	addi	s3,s3,8
    80004f68:	fb3c95e3          	bne	s9,s3,80004f12 <exec+0x1c0>
  sz = sz1;
    80004f6c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f70:	4a81                	li	s5,0
    80004f72:	a84d                	j	80005024 <exec+0x2d2>
  sp = sz;
    80004f74:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f76:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f78:	00349793          	slli	a5,s1,0x3
    80004f7c:	f9040713          	addi	a4,s0,-112
    80004f80:	97ba                	add	a5,a5,a4
    80004f82:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f86:	00148693          	addi	a3,s1,1
    80004f8a:	068e                	slli	a3,a3,0x3
    80004f8c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f90:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f94:	01597663          	bgeu	s2,s5,80004fa0 <exec+0x24e>
  sz = sz1;
    80004f98:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9c:	4a81                	li	s5,0
    80004f9e:	a059                	j	80005024 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fa0:	e8840613          	addi	a2,s0,-376
    80004fa4:	85ca                	mv	a1,s2
    80004fa6:	855a                	mv	a0,s6
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	766080e7          	jalr	1894(ra) # 8000170e <copyout>
    80004fb0:	0a054663          	bltz	a0,8000505c <exec+0x30a>
  p->trapframe->a1 = sp;
    80004fb4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004fb8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fbc:	de843783          	ld	a5,-536(s0)
    80004fc0:	0007c703          	lbu	a4,0(a5)
    80004fc4:	cf11                	beqz	a4,80004fe0 <exec+0x28e>
    80004fc6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fc8:	02f00693          	li	a3,47
    80004fcc:	a039                	j	80004fda <exec+0x288>
      last = s+1;
    80004fce:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fd2:	0785                	addi	a5,a5,1
    80004fd4:	fff7c703          	lbu	a4,-1(a5)
    80004fd8:	c701                	beqz	a4,80004fe0 <exec+0x28e>
    if(*s == '/')
    80004fda:	fed71ce3          	bne	a4,a3,80004fd2 <exec+0x280>
    80004fde:	bfc5                	j	80004fce <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fe0:	4641                	li	a2,16
    80004fe2:	de843583          	ld	a1,-536(s0)
    80004fe6:	158b8513          	addi	a0,s7,344
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	eb4080e7          	jalr	-332(ra) # 80000e9e <safestrcpy>
  oldpagetable = p->pagetable;
    80004ff2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ff6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ffa:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ffe:	058bb783          	ld	a5,88(s7)
    80005002:	e6043703          	ld	a4,-416(s0)
    80005006:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005008:	058bb783          	ld	a5,88(s7)
    8000500c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005010:	85ea                	mv	a1,s10
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	b6a080e7          	jalr	-1174(ra) # 80001b7c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000501a:	0004851b          	sext.w	a0,s1
    8000501e:	bbc1                	j	80004dee <exec+0x9c>
    80005020:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005024:	df843583          	ld	a1,-520(s0)
    80005028:	855a                	mv	a0,s6
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	b52080e7          	jalr	-1198(ra) # 80001b7c <proc_freepagetable>
  if(ip){
    80005032:	da0a94e3          	bnez	s5,80004dda <exec+0x88>
  return -1;
    80005036:	557d                	li	a0,-1
    80005038:	bb5d                	j	80004dee <exec+0x9c>
    8000503a:	de943c23          	sd	s1,-520(s0)
    8000503e:	b7dd                	j	80005024 <exec+0x2d2>
    80005040:	de943c23          	sd	s1,-520(s0)
    80005044:	b7c5                	j	80005024 <exec+0x2d2>
    80005046:	de943c23          	sd	s1,-520(s0)
    8000504a:	bfe9                	j	80005024 <exec+0x2d2>
  sz = sz1;
    8000504c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005050:	4a81                	li	s5,0
    80005052:	bfc9                	j	80005024 <exec+0x2d2>
  sz = sz1;
    80005054:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005058:	4a81                	li	s5,0
    8000505a:	b7e9                	j	80005024 <exec+0x2d2>
  sz = sz1;
    8000505c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005060:	4a81                	li	s5,0
    80005062:	b7c9                	j	80005024 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005064:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005068:	e0843783          	ld	a5,-504(s0)
    8000506c:	0017869b          	addiw	a3,a5,1
    80005070:	e0d43423          	sd	a3,-504(s0)
    80005074:	e0043783          	ld	a5,-512(s0)
    80005078:	0387879b          	addiw	a5,a5,56
    8000507c:	e8045703          	lhu	a4,-384(s0)
    80005080:	e2e6d3e3          	bge	a3,a4,80004ea6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005084:	2781                	sext.w	a5,a5
    80005086:	e0f43023          	sd	a5,-512(s0)
    8000508a:	03800713          	li	a4,56
    8000508e:	86be                	mv	a3,a5
    80005090:	e1040613          	addi	a2,s0,-496
    80005094:	4581                	li	a1,0
    80005096:	8556                	mv	a0,s5
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	a5a080e7          	jalr	-1446(ra) # 80003af2 <readi>
    800050a0:	03800793          	li	a5,56
    800050a4:	f6f51ee3          	bne	a0,a5,80005020 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800050a8:	e1042783          	lw	a5,-496(s0)
    800050ac:	4705                	li	a4,1
    800050ae:	fae79de3          	bne	a5,a4,80005068 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800050b2:	e3843603          	ld	a2,-456(s0)
    800050b6:	e3043783          	ld	a5,-464(s0)
    800050ba:	f8f660e3          	bltu	a2,a5,8000503a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050be:	e2043783          	ld	a5,-480(s0)
    800050c2:	963e                	add	a2,a2,a5
    800050c4:	f6f66ee3          	bltu	a2,a5,80005040 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c8:	85a6                	mv	a1,s1
    800050ca:	855a                	mv	a0,s6
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	3f2080e7          	jalr	1010(ra) # 800014be <uvmalloc>
    800050d4:	dea43c23          	sd	a0,-520(s0)
    800050d8:	d53d                	beqz	a0,80005046 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800050da:	e2043c03          	ld	s8,-480(s0)
    800050de:	de043783          	ld	a5,-544(s0)
    800050e2:	00fc77b3          	and	a5,s8,a5
    800050e6:	ff9d                	bnez	a5,80005024 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050e8:	e1842c83          	lw	s9,-488(s0)
    800050ec:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050f0:	f60b8ae3          	beqz	s7,80005064 <exec+0x312>
    800050f4:	89de                	mv	s3,s7
    800050f6:	4481                	li	s1,0
    800050f8:	b371                	j	80004e84 <exec+0x132>

00000000800050fa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050fa:	7179                	addi	sp,sp,-48
    800050fc:	f406                	sd	ra,40(sp)
    800050fe:	f022                	sd	s0,32(sp)
    80005100:	ec26                	sd	s1,24(sp)
    80005102:	e84a                	sd	s2,16(sp)
    80005104:	1800                	addi	s0,sp,48
    80005106:	892e                	mv	s2,a1
    80005108:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000510a:	fdc40593          	addi	a1,s0,-36
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	a02080e7          	jalr	-1534(ra) # 80002b10 <argint>
    80005116:	04054063          	bltz	a0,80005156 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000511a:	fdc42703          	lw	a4,-36(s0)
    8000511e:	47bd                	li	a5,15
    80005120:	02e7ed63          	bltu	a5,a4,8000515a <argfd+0x60>
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	8f8080e7          	jalr	-1800(ra) # 80001a1c <myproc>
    8000512c:	fdc42703          	lw	a4,-36(s0)
    80005130:	01a70793          	addi	a5,a4,26
    80005134:	078e                	slli	a5,a5,0x3
    80005136:	953e                	add	a0,a0,a5
    80005138:	611c                	ld	a5,0(a0)
    8000513a:	c395                	beqz	a5,8000515e <argfd+0x64>
    return -1;
  if(pfd)
    8000513c:	00090463          	beqz	s2,80005144 <argfd+0x4a>
    *pfd = fd;
    80005140:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005144:	4501                	li	a0,0
  if(pf)
    80005146:	c091                	beqz	s1,8000514a <argfd+0x50>
    *pf = f;
    80005148:	e09c                	sd	a5,0(s1)
}
    8000514a:	70a2                	ld	ra,40(sp)
    8000514c:	7402                	ld	s0,32(sp)
    8000514e:	64e2                	ld	s1,24(sp)
    80005150:	6942                	ld	s2,16(sp)
    80005152:	6145                	addi	sp,sp,48
    80005154:	8082                	ret
    return -1;
    80005156:	557d                	li	a0,-1
    80005158:	bfcd                	j	8000514a <argfd+0x50>
    return -1;
    8000515a:	557d                	li	a0,-1
    8000515c:	b7fd                	j	8000514a <argfd+0x50>
    8000515e:	557d                	li	a0,-1
    80005160:	b7ed                	j	8000514a <argfd+0x50>

0000000080005162 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005162:	1101                	addi	sp,sp,-32
    80005164:	ec06                	sd	ra,24(sp)
    80005166:	e822                	sd	s0,16(sp)
    80005168:	e426                	sd	s1,8(sp)
    8000516a:	1000                	addi	s0,sp,32
    8000516c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	8ae080e7          	jalr	-1874(ra) # 80001a1c <myproc>
    80005176:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005178:	0d050793          	addi	a5,a0,208
    8000517c:	4501                	li	a0,0
    8000517e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005180:	6398                	ld	a4,0(a5)
    80005182:	cb19                	beqz	a4,80005198 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005184:	2505                	addiw	a0,a0,1
    80005186:	07a1                	addi	a5,a5,8
    80005188:	fed51ce3          	bne	a0,a3,80005180 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000518c:	557d                	li	a0,-1
}
    8000518e:	60e2                	ld	ra,24(sp)
    80005190:	6442                	ld	s0,16(sp)
    80005192:	64a2                	ld	s1,8(sp)
    80005194:	6105                	addi	sp,sp,32
    80005196:	8082                	ret
      p->ofile[fd] = f;
    80005198:	01a50793          	addi	a5,a0,26
    8000519c:	078e                	slli	a5,a5,0x3
    8000519e:	963e                	add	a2,a2,a5
    800051a0:	e204                	sd	s1,0(a2)
      return fd;
    800051a2:	b7f5                	j	8000518e <fdalloc+0x2c>

00000000800051a4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051a4:	715d                	addi	sp,sp,-80
    800051a6:	e486                	sd	ra,72(sp)
    800051a8:	e0a2                	sd	s0,64(sp)
    800051aa:	fc26                	sd	s1,56(sp)
    800051ac:	f84a                	sd	s2,48(sp)
    800051ae:	f44e                	sd	s3,40(sp)
    800051b0:	f052                	sd	s4,32(sp)
    800051b2:	ec56                	sd	s5,24(sp)
    800051b4:	0880                	addi	s0,sp,80
    800051b6:	89ae                	mv	s3,a1
    800051b8:	8ab2                	mv	s5,a2
    800051ba:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051bc:	fb040593          	addi	a1,s0,-80
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	e4c080e7          	jalr	-436(ra) # 8000400c <nameiparent>
    800051c8:	892a                	mv	s2,a0
    800051ca:	12050e63          	beqz	a0,80005306 <create+0x162>
    return 0;

  ilock(dp);
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	670080e7          	jalr	1648(ra) # 8000383e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051d6:	4601                	li	a2,0
    800051d8:	fb040593          	addi	a1,s0,-80
    800051dc:	854a                	mv	a0,s2
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	b3e080e7          	jalr	-1218(ra) # 80003d1c <dirlookup>
    800051e6:	84aa                	mv	s1,a0
    800051e8:	c921                	beqz	a0,80005238 <create+0x94>
    iunlockput(dp);
    800051ea:	854a                	mv	a0,s2
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	8b4080e7          	jalr	-1868(ra) # 80003aa0 <iunlockput>
    ilock(ip);
    800051f4:	8526                	mv	a0,s1
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	648080e7          	jalr	1608(ra) # 8000383e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051fe:	2981                	sext.w	s3,s3
    80005200:	4789                	li	a5,2
    80005202:	02f99463          	bne	s3,a5,8000522a <create+0x86>
    80005206:	0444d783          	lhu	a5,68(s1)
    8000520a:	37f9                	addiw	a5,a5,-2
    8000520c:	17c2                	slli	a5,a5,0x30
    8000520e:	93c1                	srli	a5,a5,0x30
    80005210:	4705                	li	a4,1
    80005212:	00f76c63          	bltu	a4,a5,8000522a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005216:	8526                	mv	a0,s1
    80005218:	60a6                	ld	ra,72(sp)
    8000521a:	6406                	ld	s0,64(sp)
    8000521c:	74e2                	ld	s1,56(sp)
    8000521e:	7942                	ld	s2,48(sp)
    80005220:	79a2                	ld	s3,40(sp)
    80005222:	7a02                	ld	s4,32(sp)
    80005224:	6ae2                	ld	s5,24(sp)
    80005226:	6161                	addi	sp,sp,80
    80005228:	8082                	ret
    iunlockput(ip);
    8000522a:	8526                	mv	a0,s1
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	874080e7          	jalr	-1932(ra) # 80003aa0 <iunlockput>
    return 0;
    80005234:	4481                	li	s1,0
    80005236:	b7c5                	j	80005216 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005238:	85ce                	mv	a1,s3
    8000523a:	00092503          	lw	a0,0(s2)
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	468080e7          	jalr	1128(ra) # 800036a6 <ialloc>
    80005246:	84aa                	mv	s1,a0
    80005248:	c521                	beqz	a0,80005290 <create+0xec>
  ilock(ip);
    8000524a:	ffffe097          	auipc	ra,0xffffe
    8000524e:	5f4080e7          	jalr	1524(ra) # 8000383e <ilock>
  ip->major = major;
    80005252:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005256:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000525a:	4a05                	li	s4,1
    8000525c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005260:	8526                	mv	a0,s1
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	512080e7          	jalr	1298(ra) # 80003774 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000526a:	2981                	sext.w	s3,s3
    8000526c:	03498a63          	beq	s3,s4,800052a0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005270:	40d0                	lw	a2,4(s1)
    80005272:	fb040593          	addi	a1,s0,-80
    80005276:	854a                	mv	a0,s2
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	cb4080e7          	jalr	-844(ra) # 80003f2c <dirlink>
    80005280:	06054b63          	bltz	a0,800052f6 <create+0x152>
  iunlockput(dp);
    80005284:	854a                	mv	a0,s2
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	81a080e7          	jalr	-2022(ra) # 80003aa0 <iunlockput>
  return ip;
    8000528e:	b761                	j	80005216 <create+0x72>
    panic("create: ialloc");
    80005290:	00003517          	auipc	a0,0x3
    80005294:	66850513          	addi	a0,a0,1640 # 800088f8 <syscalls_name+0x2b8>
    80005298:	ffffb097          	auipc	ra,0xffffb
    8000529c:	2aa080e7          	jalr	682(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    800052a0:	04a95783          	lhu	a5,74(s2)
    800052a4:	2785                	addiw	a5,a5,1
    800052a6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052aa:	854a                	mv	a0,s2
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	4c8080e7          	jalr	1224(ra) # 80003774 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052b4:	40d0                	lw	a2,4(s1)
    800052b6:	00003597          	auipc	a1,0x3
    800052ba:	65258593          	addi	a1,a1,1618 # 80008908 <syscalls_name+0x2c8>
    800052be:	8526                	mv	a0,s1
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	c6c080e7          	jalr	-916(ra) # 80003f2c <dirlink>
    800052c8:	00054f63          	bltz	a0,800052e6 <create+0x142>
    800052cc:	00492603          	lw	a2,4(s2)
    800052d0:	00003597          	auipc	a1,0x3
    800052d4:	64058593          	addi	a1,a1,1600 # 80008910 <syscalls_name+0x2d0>
    800052d8:	8526                	mv	a0,s1
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	c52080e7          	jalr	-942(ra) # 80003f2c <dirlink>
    800052e2:	f80557e3          	bgez	a0,80005270 <create+0xcc>
      panic("create dots");
    800052e6:	00003517          	auipc	a0,0x3
    800052ea:	63250513          	addi	a0,a0,1586 # 80008918 <syscalls_name+0x2d8>
    800052ee:	ffffb097          	auipc	ra,0xffffb
    800052f2:	254080e7          	jalr	596(ra) # 80000542 <panic>
    panic("create: dirlink");
    800052f6:	00003517          	auipc	a0,0x3
    800052fa:	63250513          	addi	a0,a0,1586 # 80008928 <syscalls_name+0x2e8>
    800052fe:	ffffb097          	auipc	ra,0xffffb
    80005302:	244080e7          	jalr	580(ra) # 80000542 <panic>
    return 0;
    80005306:	84aa                	mv	s1,a0
    80005308:	b739                	j	80005216 <create+0x72>

000000008000530a <sys_dup>:
{
    8000530a:	7179                	addi	sp,sp,-48
    8000530c:	f406                	sd	ra,40(sp)
    8000530e:	f022                	sd	s0,32(sp)
    80005310:	ec26                	sd	s1,24(sp)
    80005312:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005314:	fd840613          	addi	a2,s0,-40
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	dde080e7          	jalr	-546(ra) # 800050fa <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005326:	02054363          	bltz	a0,8000534c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000532a:	fd843503          	ld	a0,-40(s0)
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	e34080e7          	jalr	-460(ra) # 80005162 <fdalloc>
    80005336:	84aa                	mv	s1,a0
    return -1;
    80005338:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000533a:	00054963          	bltz	a0,8000534c <sys_dup+0x42>
  filedup(f);
    8000533e:	fd843503          	ld	a0,-40(s0)
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	338080e7          	jalr	824(ra) # 8000467a <filedup>
  return fd;
    8000534a:	87a6                	mv	a5,s1
}
    8000534c:	853e                	mv	a0,a5
    8000534e:	70a2                	ld	ra,40(sp)
    80005350:	7402                	ld	s0,32(sp)
    80005352:	64e2                	ld	s1,24(sp)
    80005354:	6145                	addi	sp,sp,48
    80005356:	8082                	ret

0000000080005358 <sys_read>:
{
    80005358:	7179                	addi	sp,sp,-48
    8000535a:	f406                	sd	ra,40(sp)
    8000535c:	f022                	sd	s0,32(sp)
    8000535e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	fe840613          	addi	a2,s0,-24
    80005364:	4581                	li	a1,0
    80005366:	4501                	li	a0,0
    80005368:	00000097          	auipc	ra,0x0
    8000536c:	d92080e7          	jalr	-622(ra) # 800050fa <argfd>
    return -1;
    80005370:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005372:	04054163          	bltz	a0,800053b4 <sys_read+0x5c>
    80005376:	fe440593          	addi	a1,s0,-28
    8000537a:	4509                	li	a0,2
    8000537c:	ffffd097          	auipc	ra,0xffffd
    80005380:	794080e7          	jalr	1940(ra) # 80002b10 <argint>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	02054763          	bltz	a0,800053b4 <sys_read+0x5c>
    8000538a:	fd840593          	addi	a1,s0,-40
    8000538e:	4505                	li	a0,1
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	7a2080e7          	jalr	1954(ra) # 80002b32 <argaddr>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	00054d63          	bltz	a0,800053b4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000539e:	fe442603          	lw	a2,-28(s0)
    800053a2:	fd843583          	ld	a1,-40(s0)
    800053a6:	fe843503          	ld	a0,-24(s0)
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	45c080e7          	jalr	1116(ra) # 80004806 <fileread>
    800053b2:	87aa                	mv	a5,a0
}
    800053b4:	853e                	mv	a0,a5
    800053b6:	70a2                	ld	ra,40(sp)
    800053b8:	7402                	ld	s0,32(sp)
    800053ba:	6145                	addi	sp,sp,48
    800053bc:	8082                	ret

00000000800053be <sys_write>:
{
    800053be:	7179                	addi	sp,sp,-48
    800053c0:	f406                	sd	ra,40(sp)
    800053c2:	f022                	sd	s0,32(sp)
    800053c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c6:	fe840613          	addi	a2,s0,-24
    800053ca:	4581                	li	a1,0
    800053cc:	4501                	li	a0,0
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	d2c080e7          	jalr	-724(ra) # 800050fa <argfd>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d8:	04054163          	bltz	a0,8000541a <sys_write+0x5c>
    800053dc:	fe440593          	addi	a1,s0,-28
    800053e0:	4509                	li	a0,2
    800053e2:	ffffd097          	auipc	ra,0xffffd
    800053e6:	72e080e7          	jalr	1838(ra) # 80002b10 <argint>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	02054763          	bltz	a0,8000541a <sys_write+0x5c>
    800053f0:	fd840593          	addi	a1,s0,-40
    800053f4:	4505                	li	a0,1
    800053f6:	ffffd097          	auipc	ra,0xffffd
    800053fa:	73c080e7          	jalr	1852(ra) # 80002b32 <argaddr>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005400:	00054d63          	bltz	a0,8000541a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005404:	fe442603          	lw	a2,-28(s0)
    80005408:	fd843583          	ld	a1,-40(s0)
    8000540c:	fe843503          	ld	a0,-24(s0)
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	4b8080e7          	jalr	1208(ra) # 800048c8 <filewrite>
    80005418:	87aa                	mv	a5,a0
}
    8000541a:	853e                	mv	a0,a5
    8000541c:	70a2                	ld	ra,40(sp)
    8000541e:	7402                	ld	s0,32(sp)
    80005420:	6145                	addi	sp,sp,48
    80005422:	8082                	ret

0000000080005424 <sys_close>:
{
    80005424:	1101                	addi	sp,sp,-32
    80005426:	ec06                	sd	ra,24(sp)
    80005428:	e822                	sd	s0,16(sp)
    8000542a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000542c:	fe040613          	addi	a2,s0,-32
    80005430:	fec40593          	addi	a1,s0,-20
    80005434:	4501                	li	a0,0
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	cc4080e7          	jalr	-828(ra) # 800050fa <argfd>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005440:	02054463          	bltz	a0,80005468 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	5d8080e7          	jalr	1496(ra) # 80001a1c <myproc>
    8000544c:	fec42783          	lw	a5,-20(s0)
    80005450:	07e9                	addi	a5,a5,26
    80005452:	078e                	slli	a5,a5,0x3
    80005454:	97aa                	add	a5,a5,a0
    80005456:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000545a:	fe043503          	ld	a0,-32(s0)
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	26e080e7          	jalr	622(ra) # 800046cc <fileclose>
  return 0;
    80005466:	4781                	li	a5,0
}
    80005468:	853e                	mv	a0,a5
    8000546a:	60e2                	ld	ra,24(sp)
    8000546c:	6442                	ld	s0,16(sp)
    8000546e:	6105                	addi	sp,sp,32
    80005470:	8082                	ret

0000000080005472 <sys_fstat>:
{
    80005472:	1101                	addi	sp,sp,-32
    80005474:	ec06                	sd	ra,24(sp)
    80005476:	e822                	sd	s0,16(sp)
    80005478:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	c78080e7          	jalr	-904(ra) # 800050fa <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000548c:	02054563          	bltz	a0,800054b6 <sys_fstat+0x44>
    80005490:	fe040593          	addi	a1,s0,-32
    80005494:	4505                	li	a0,1
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	69c080e7          	jalr	1692(ra) # 80002b32 <argaddr>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a0:	00054b63          	bltz	a0,800054b6 <sys_fstat+0x44>
  return filestat(f, st);
    800054a4:	fe043583          	ld	a1,-32(s0)
    800054a8:	fe843503          	ld	a0,-24(s0)
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	2e8080e7          	jalr	744(ra) # 80004794 <filestat>
    800054b4:	87aa                	mv	a5,a0
}
    800054b6:	853e                	mv	a0,a5
    800054b8:	60e2                	ld	ra,24(sp)
    800054ba:	6442                	ld	s0,16(sp)
    800054bc:	6105                	addi	sp,sp,32
    800054be:	8082                	ret

00000000800054c0 <sys_link>:
{
    800054c0:	7169                	addi	sp,sp,-304
    800054c2:	f606                	sd	ra,296(sp)
    800054c4:	f222                	sd	s0,288(sp)
    800054c6:	ee26                	sd	s1,280(sp)
    800054c8:	ea4a                	sd	s2,272(sp)
    800054ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054cc:	08000613          	li	a2,128
    800054d0:	ed040593          	addi	a1,s0,-304
    800054d4:	4501                	li	a0,0
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	67e080e7          	jalr	1662(ra) # 80002b54 <argstr>
    return -1;
    800054de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e0:	10054e63          	bltz	a0,800055fc <sys_link+0x13c>
    800054e4:	08000613          	li	a2,128
    800054e8:	f5040593          	addi	a1,s0,-176
    800054ec:	4505                	li	a0,1
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	666080e7          	jalr	1638(ra) # 80002b54 <argstr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f8:	10054263          	bltz	a0,800055fc <sys_link+0x13c>
  begin_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	cfe080e7          	jalr	-770(ra) # 800041fa <begin_op>
  if((ip = namei(old)) == 0){
    80005504:	ed040513          	addi	a0,s0,-304
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	ae6080e7          	jalr	-1306(ra) # 80003fee <namei>
    80005510:	84aa                	mv	s1,a0
    80005512:	c551                	beqz	a0,8000559e <sys_link+0xde>
  ilock(ip);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	32a080e7          	jalr	810(ra) # 8000383e <ilock>
  if(ip->type == T_DIR){
    8000551c:	04449703          	lh	a4,68(s1)
    80005520:	4785                	li	a5,1
    80005522:	08f70463          	beq	a4,a5,800055aa <sys_link+0xea>
  ip->nlink++;
    80005526:	04a4d783          	lhu	a5,74(s1)
    8000552a:	2785                	addiw	a5,a5,1
    8000552c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	242080e7          	jalr	578(ra) # 80003774 <iupdate>
  iunlock(ip);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	3c4080e7          	jalr	964(ra) # 80003900 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005544:	fd040593          	addi	a1,s0,-48
    80005548:	f5040513          	addi	a0,s0,-176
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	ac0080e7          	jalr	-1344(ra) # 8000400c <nameiparent>
    80005554:	892a                	mv	s2,a0
    80005556:	c935                	beqz	a0,800055ca <sys_link+0x10a>
  ilock(dp);
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	2e6080e7          	jalr	742(ra) # 8000383e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005560:	00092703          	lw	a4,0(s2)
    80005564:	409c                	lw	a5,0(s1)
    80005566:	04f71d63          	bne	a4,a5,800055c0 <sys_link+0x100>
    8000556a:	40d0                	lw	a2,4(s1)
    8000556c:	fd040593          	addi	a1,s0,-48
    80005570:	854a                	mv	a0,s2
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	9ba080e7          	jalr	-1606(ra) # 80003f2c <dirlink>
    8000557a:	04054363          	bltz	a0,800055c0 <sys_link+0x100>
  iunlockput(dp);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	520080e7          	jalr	1312(ra) # 80003aa0 <iunlockput>
  iput(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	46e080e7          	jalr	1134(ra) # 800039f8 <iput>
  end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	ce8080e7          	jalr	-792(ra) # 8000427a <end_op>
  return 0;
    8000559a:	4781                	li	a5,0
    8000559c:	a085                	j	800055fc <sys_link+0x13c>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	cdc080e7          	jalr	-804(ra) # 8000427a <end_op>
    return -1;
    800055a6:	57fd                	li	a5,-1
    800055a8:	a891                	j	800055fc <sys_link+0x13c>
    iunlockput(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	4f4080e7          	jalr	1268(ra) # 80003aa0 <iunlockput>
    end_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	cc6080e7          	jalr	-826(ra) # 8000427a <end_op>
    return -1;
    800055bc:	57fd                	li	a5,-1
    800055be:	a83d                	j	800055fc <sys_link+0x13c>
    iunlockput(dp);
    800055c0:	854a                	mv	a0,s2
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	4de080e7          	jalr	1246(ra) # 80003aa0 <iunlockput>
  ilock(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	272080e7          	jalr	626(ra) # 8000383e <ilock>
  ip->nlink--;
    800055d4:	04a4d783          	lhu	a5,74(s1)
    800055d8:	37fd                	addiw	a5,a5,-1
    800055da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	194080e7          	jalr	404(ra) # 80003774 <iupdate>
  iunlockput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	4b6080e7          	jalr	1206(ra) # 80003aa0 <iunlockput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	c88080e7          	jalr	-888(ra) # 8000427a <end_op>
  return -1;
    800055fa:	57fd                	li	a5,-1
}
    800055fc:	853e                	mv	a0,a5
    800055fe:	70b2                	ld	ra,296(sp)
    80005600:	7412                	ld	s0,288(sp)
    80005602:	64f2                	ld	s1,280(sp)
    80005604:	6952                	ld	s2,272(sp)
    80005606:	6155                	addi	sp,sp,304
    80005608:	8082                	ret

000000008000560a <sys_unlink>:
{
    8000560a:	7151                	addi	sp,sp,-240
    8000560c:	f586                	sd	ra,232(sp)
    8000560e:	f1a2                	sd	s0,224(sp)
    80005610:	eda6                	sd	s1,216(sp)
    80005612:	e9ca                	sd	s2,208(sp)
    80005614:	e5ce                	sd	s3,200(sp)
    80005616:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005618:	08000613          	li	a2,128
    8000561c:	f3040593          	addi	a1,s0,-208
    80005620:	4501                	li	a0,0
    80005622:	ffffd097          	auipc	ra,0xffffd
    80005626:	532080e7          	jalr	1330(ra) # 80002b54 <argstr>
    8000562a:	18054163          	bltz	a0,800057ac <sys_unlink+0x1a2>
  begin_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	bcc080e7          	jalr	-1076(ra) # 800041fa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005636:	fb040593          	addi	a1,s0,-80
    8000563a:	f3040513          	addi	a0,s0,-208
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	9ce080e7          	jalr	-1586(ra) # 8000400c <nameiparent>
    80005646:	84aa                	mv	s1,a0
    80005648:	c979                	beqz	a0,8000571e <sys_unlink+0x114>
  ilock(dp);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	1f4080e7          	jalr	500(ra) # 8000383e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005652:	00003597          	auipc	a1,0x3
    80005656:	2b658593          	addi	a1,a1,694 # 80008908 <syscalls_name+0x2c8>
    8000565a:	fb040513          	addi	a0,s0,-80
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	6a4080e7          	jalr	1700(ra) # 80003d02 <namecmp>
    80005666:	14050a63          	beqz	a0,800057ba <sys_unlink+0x1b0>
    8000566a:	00003597          	auipc	a1,0x3
    8000566e:	2a658593          	addi	a1,a1,678 # 80008910 <syscalls_name+0x2d0>
    80005672:	fb040513          	addi	a0,s0,-80
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	68c080e7          	jalr	1676(ra) # 80003d02 <namecmp>
    8000567e:	12050e63          	beqz	a0,800057ba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005682:	f2c40613          	addi	a2,s0,-212
    80005686:	fb040593          	addi	a1,s0,-80
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	690080e7          	jalr	1680(ra) # 80003d1c <dirlookup>
    80005694:	892a                	mv	s2,a0
    80005696:	12050263          	beqz	a0,800057ba <sys_unlink+0x1b0>
  ilock(ip);
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	1a4080e7          	jalr	420(ra) # 8000383e <ilock>
  if(ip->nlink < 1)
    800056a2:	04a91783          	lh	a5,74(s2)
    800056a6:	08f05263          	blez	a5,8000572a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056aa:	04491703          	lh	a4,68(s2)
    800056ae:	4785                	li	a5,1
    800056b0:	08f70563          	beq	a4,a5,8000573a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056b4:	4641                	li	a2,16
    800056b6:	4581                	li	a1,0
    800056b8:	fc040513          	addi	a0,s0,-64
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	690080e7          	jalr	1680(ra) # 80000d4c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c4:	4741                	li	a4,16
    800056c6:	f2c42683          	lw	a3,-212(s0)
    800056ca:	fc040613          	addi	a2,s0,-64
    800056ce:	4581                	li	a1,0
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	516080e7          	jalr	1302(ra) # 80003be8 <writei>
    800056da:	47c1                	li	a5,16
    800056dc:	0af51563          	bne	a0,a5,80005786 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056e0:	04491703          	lh	a4,68(s2)
    800056e4:	4785                	li	a5,1
    800056e6:	0af70863          	beq	a4,a5,80005796 <sys_unlink+0x18c>
  iunlockput(dp);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	3b4080e7          	jalr	948(ra) # 80003aa0 <iunlockput>
  ip->nlink--;
    800056f4:	04a95783          	lhu	a5,74(s2)
    800056f8:	37fd                	addiw	a5,a5,-1
    800056fa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	074080e7          	jalr	116(ra) # 80003774 <iupdate>
  iunlockput(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	396080e7          	jalr	918(ra) # 80003aa0 <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	b68080e7          	jalr	-1176(ra) # 8000427a <end_op>
  return 0;
    8000571a:	4501                	li	a0,0
    8000571c:	a84d                	j	800057ce <sys_unlink+0x1c4>
    end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	b5c080e7          	jalr	-1188(ra) # 8000427a <end_op>
    return -1;
    80005726:	557d                	li	a0,-1
    80005728:	a05d                	j	800057ce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	20e50513          	addi	a0,a0,526 # 80008938 <syscalls_name+0x2f8>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	e10080e7          	jalr	-496(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000573a:	04c92703          	lw	a4,76(s2)
    8000573e:	02000793          	li	a5,32
    80005742:	f6e7f9e3          	bgeu	a5,a4,800056b4 <sys_unlink+0xaa>
    80005746:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000574a:	4741                	li	a4,16
    8000574c:	86ce                	mv	a3,s3
    8000574e:	f1840613          	addi	a2,s0,-232
    80005752:	4581                	li	a1,0
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	39c080e7          	jalr	924(ra) # 80003af2 <readi>
    8000575e:	47c1                	li	a5,16
    80005760:	00f51b63          	bne	a0,a5,80005776 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005764:	f1845783          	lhu	a5,-232(s0)
    80005768:	e7a1                	bnez	a5,800057b0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000576a:	29c1                	addiw	s3,s3,16
    8000576c:	04c92783          	lw	a5,76(s2)
    80005770:	fcf9ede3          	bltu	s3,a5,8000574a <sys_unlink+0x140>
    80005774:	b781                	j	800056b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005776:	00003517          	auipc	a0,0x3
    8000577a:	1da50513          	addi	a0,a0,474 # 80008950 <syscalls_name+0x310>
    8000577e:	ffffb097          	auipc	ra,0xffffb
    80005782:	dc4080e7          	jalr	-572(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005786:	00003517          	auipc	a0,0x3
    8000578a:	1e250513          	addi	a0,a0,482 # 80008968 <syscalls_name+0x328>
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	db4080e7          	jalr	-588(ra) # 80000542 <panic>
    dp->nlink--;
    80005796:	04a4d783          	lhu	a5,74(s1)
    8000579a:	37fd                	addiw	a5,a5,-1
    8000579c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	fd2080e7          	jalr	-46(ra) # 80003774 <iupdate>
    800057aa:	b781                	j	800056ea <sys_unlink+0xe0>
    return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	a005                	j	800057ce <sys_unlink+0x1c4>
    iunlockput(ip);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	2ee080e7          	jalr	750(ra) # 80003aa0 <iunlockput>
  iunlockput(dp);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	2e4080e7          	jalr	740(ra) # 80003aa0 <iunlockput>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	ab6080e7          	jalr	-1354(ra) # 8000427a <end_op>
  return -1;
    800057cc:	557d                	li	a0,-1
}
    800057ce:	70ae                	ld	ra,232(sp)
    800057d0:	740e                	ld	s0,224(sp)
    800057d2:	64ee                	ld	s1,216(sp)
    800057d4:	694e                	ld	s2,208(sp)
    800057d6:	69ae                	ld	s3,200(sp)
    800057d8:	616d                	addi	sp,sp,240
    800057da:	8082                	ret

00000000800057dc <sys_open>:

uint64
sys_open(void)
{
    800057dc:	7131                	addi	sp,sp,-192
    800057de:	fd06                	sd	ra,184(sp)
    800057e0:	f922                	sd	s0,176(sp)
    800057e2:	f526                	sd	s1,168(sp)
    800057e4:	f14a                	sd	s2,160(sp)
    800057e6:	ed4e                	sd	s3,152(sp)
    800057e8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ea:	08000613          	li	a2,128
    800057ee:	f5040593          	addi	a1,s0,-176
    800057f2:	4501                	li	a0,0
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	360080e7          	jalr	864(ra) # 80002b54 <argstr>
    return -1;
    800057fc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057fe:	0c054163          	bltz	a0,800058c0 <sys_open+0xe4>
    80005802:	f4c40593          	addi	a1,s0,-180
    80005806:	4505                	li	a0,1
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	308080e7          	jalr	776(ra) # 80002b10 <argint>
    80005810:	0a054863          	bltz	a0,800058c0 <sys_open+0xe4>

  begin_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	9e6080e7          	jalr	-1562(ra) # 800041fa <begin_op>

  if(omode & O_CREATE){
    8000581c:	f4c42783          	lw	a5,-180(s0)
    80005820:	2007f793          	andi	a5,a5,512
    80005824:	cbdd                	beqz	a5,800058da <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005826:	4681                	li	a3,0
    80005828:	4601                	li	a2,0
    8000582a:	4589                	li	a1,2
    8000582c:	f5040513          	addi	a0,s0,-176
    80005830:	00000097          	auipc	ra,0x0
    80005834:	974080e7          	jalr	-1676(ra) # 800051a4 <create>
    80005838:	892a                	mv	s2,a0
    if(ip == 0){
    8000583a:	c959                	beqz	a0,800058d0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000583c:	04491703          	lh	a4,68(s2)
    80005840:	478d                	li	a5,3
    80005842:	00f71763          	bne	a4,a5,80005850 <sys_open+0x74>
    80005846:	04695703          	lhu	a4,70(s2)
    8000584a:	47a5                	li	a5,9
    8000584c:	0ce7ec63          	bltu	a5,a4,80005924 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	dc0080e7          	jalr	-576(ra) # 80004610 <filealloc>
    80005858:	89aa                	mv	s3,a0
    8000585a:	10050263          	beqz	a0,8000595e <sys_open+0x182>
    8000585e:	00000097          	auipc	ra,0x0
    80005862:	904080e7          	jalr	-1788(ra) # 80005162 <fdalloc>
    80005866:	84aa                	mv	s1,a0
    80005868:	0e054663          	bltz	a0,80005954 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000586c:	04491703          	lh	a4,68(s2)
    80005870:	478d                	li	a5,3
    80005872:	0cf70463          	beq	a4,a5,8000593a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005876:	4789                	li	a5,2
    80005878:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000587c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005880:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005884:	f4c42783          	lw	a5,-180(s0)
    80005888:	0017c713          	xori	a4,a5,1
    8000588c:	8b05                	andi	a4,a4,1
    8000588e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005892:	0037f713          	andi	a4,a5,3
    80005896:	00e03733          	snez	a4,a4
    8000589a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000589e:	4007f793          	andi	a5,a5,1024
    800058a2:	c791                	beqz	a5,800058ae <sys_open+0xd2>
    800058a4:	04491703          	lh	a4,68(s2)
    800058a8:	4789                	li	a5,2
    800058aa:	08f70f63          	beq	a4,a5,80005948 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	050080e7          	jalr	80(ra) # 80003900 <iunlock>
  end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	9c2080e7          	jalr	-1598(ra) # 8000427a <end_op>

  return fd;
}
    800058c0:	8526                	mv	a0,s1
    800058c2:	70ea                	ld	ra,184(sp)
    800058c4:	744a                	ld	s0,176(sp)
    800058c6:	74aa                	ld	s1,168(sp)
    800058c8:	790a                	ld	s2,160(sp)
    800058ca:	69ea                	ld	s3,152(sp)
    800058cc:	6129                	addi	sp,sp,192
    800058ce:	8082                	ret
      end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	9aa080e7          	jalr	-1622(ra) # 8000427a <end_op>
      return -1;
    800058d8:	b7e5                	j	800058c0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058da:	f5040513          	addi	a0,s0,-176
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	710080e7          	jalr	1808(ra) # 80003fee <namei>
    800058e6:	892a                	mv	s2,a0
    800058e8:	c905                	beqz	a0,80005918 <sys_open+0x13c>
    ilock(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	f54080e7          	jalr	-172(ra) # 8000383e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058f2:	04491703          	lh	a4,68(s2)
    800058f6:	4785                	li	a5,1
    800058f8:	f4f712e3          	bne	a4,a5,8000583c <sys_open+0x60>
    800058fc:	f4c42783          	lw	a5,-180(s0)
    80005900:	dba1                	beqz	a5,80005850 <sys_open+0x74>
      iunlockput(ip);
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	19c080e7          	jalr	412(ra) # 80003aa0 <iunlockput>
      end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	96e080e7          	jalr	-1682(ra) # 8000427a <end_op>
      return -1;
    80005914:	54fd                	li	s1,-1
    80005916:	b76d                	j	800058c0 <sys_open+0xe4>
      end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	962080e7          	jalr	-1694(ra) # 8000427a <end_op>
      return -1;
    80005920:	54fd                	li	s1,-1
    80005922:	bf79                	j	800058c0 <sys_open+0xe4>
    iunlockput(ip);
    80005924:	854a                	mv	a0,s2
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	17a080e7          	jalr	378(ra) # 80003aa0 <iunlockput>
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	94c080e7          	jalr	-1716(ra) # 8000427a <end_op>
    return -1;
    80005936:	54fd                	li	s1,-1
    80005938:	b761                	j	800058c0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000593a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000593e:	04691783          	lh	a5,70(s2)
    80005942:	02f99223          	sh	a5,36(s3)
    80005946:	bf2d                	j	80005880 <sys_open+0xa4>
    itrunc(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	002080e7          	jalr	2(ra) # 8000394c <itrunc>
    80005952:	bfb1                	j	800058ae <sys_open+0xd2>
      fileclose(f);
    80005954:	854e                	mv	a0,s3
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	d76080e7          	jalr	-650(ra) # 800046cc <fileclose>
    iunlockput(ip);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	140080e7          	jalr	320(ra) # 80003aa0 <iunlockput>
    end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	912080e7          	jalr	-1774(ra) # 8000427a <end_op>
    return -1;
    80005970:	54fd                	li	s1,-1
    80005972:	b7b9                	j	800058c0 <sys_open+0xe4>

0000000080005974 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005974:	7175                	addi	sp,sp,-144
    80005976:	e506                	sd	ra,136(sp)
    80005978:	e122                	sd	s0,128(sp)
    8000597a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	87e080e7          	jalr	-1922(ra) # 800041fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005984:	08000613          	li	a2,128
    80005988:	f7040593          	addi	a1,s0,-144
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	1c6080e7          	jalr	454(ra) # 80002b54 <argstr>
    80005996:	02054963          	bltz	a0,800059c8 <sys_mkdir+0x54>
    8000599a:	4681                	li	a3,0
    8000599c:	4601                	li	a2,0
    8000599e:	4585                	li	a1,1
    800059a0:	f7040513          	addi	a0,s0,-144
    800059a4:	00000097          	auipc	ra,0x0
    800059a8:	800080e7          	jalr	-2048(ra) # 800051a4 <create>
    800059ac:	cd11                	beqz	a0,800059c8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	0f2080e7          	jalr	242(ra) # 80003aa0 <iunlockput>
  end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	8c4080e7          	jalr	-1852(ra) # 8000427a <end_op>
  return 0;
    800059be:	4501                	li	a0,0
}
    800059c0:	60aa                	ld	ra,136(sp)
    800059c2:	640a                	ld	s0,128(sp)
    800059c4:	6149                	addi	sp,sp,144
    800059c6:	8082                	ret
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	8b2080e7          	jalr	-1870(ra) # 8000427a <end_op>
    return -1;
    800059d0:	557d                	li	a0,-1
    800059d2:	b7fd                	j	800059c0 <sys_mkdir+0x4c>

00000000800059d4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059d4:	7135                	addi	sp,sp,-160
    800059d6:	ed06                	sd	ra,152(sp)
    800059d8:	e922                	sd	s0,144(sp)
    800059da:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	81e080e7          	jalr	-2018(ra) # 800041fa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	166080e7          	jalr	358(ra) # 80002b54 <argstr>
    800059f6:	04054a63          	bltz	a0,80005a4a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059fa:	f6c40593          	addi	a1,s0,-148
    800059fe:	4505                	li	a0,1
    80005a00:	ffffd097          	auipc	ra,0xffffd
    80005a04:	110080e7          	jalr	272(ra) # 80002b10 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a08:	04054163          	bltz	a0,80005a4a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a0c:	f6840593          	addi	a1,s0,-152
    80005a10:	4509                	li	a0,2
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	0fe080e7          	jalr	254(ra) # 80002b10 <argint>
     argint(1, &major) < 0 ||
    80005a1a:	02054863          	bltz	a0,80005a4a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a1e:	f6841683          	lh	a3,-152(s0)
    80005a22:	f6c41603          	lh	a2,-148(s0)
    80005a26:	458d                	li	a1,3
    80005a28:	f7040513          	addi	a0,s0,-144
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	778080e7          	jalr	1912(ra) # 800051a4 <create>
     argint(2, &minor) < 0 ||
    80005a34:	c919                	beqz	a0,80005a4a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	06a080e7          	jalr	106(ra) # 80003aa0 <iunlockput>
  end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	83c080e7          	jalr	-1988(ra) # 8000427a <end_op>
  return 0;
    80005a46:	4501                	li	a0,0
    80005a48:	a031                	j	80005a54 <sys_mknod+0x80>
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	830080e7          	jalr	-2000(ra) # 8000427a <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
}
    80005a54:	60ea                	ld	ra,152(sp)
    80005a56:	644a                	ld	s0,144(sp)
    80005a58:	610d                	addi	sp,sp,160
    80005a5a:	8082                	ret

0000000080005a5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a5c:	7135                	addi	sp,sp,-160
    80005a5e:	ed06                	sd	ra,152(sp)
    80005a60:	e922                	sd	s0,144(sp)
    80005a62:	e526                	sd	s1,136(sp)
    80005a64:	e14a                	sd	s2,128(sp)
    80005a66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	fb4080e7          	jalr	-76(ra) # 80001a1c <myproc>
    80005a70:	892a                	mv	s2,a0
  
  begin_op();
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	788080e7          	jalr	1928(ra) # 800041fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a7a:	08000613          	li	a2,128
    80005a7e:	f6040593          	addi	a1,s0,-160
    80005a82:	4501                	li	a0,0
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	0d0080e7          	jalr	208(ra) # 80002b54 <argstr>
    80005a8c:	04054b63          	bltz	a0,80005ae2 <sys_chdir+0x86>
    80005a90:	f6040513          	addi	a0,s0,-160
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	55a080e7          	jalr	1370(ra) # 80003fee <namei>
    80005a9c:	84aa                	mv	s1,a0
    80005a9e:	c131                	beqz	a0,80005ae2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	d9e080e7          	jalr	-610(ra) # 8000383e <ilock>
  if(ip->type != T_DIR){
    80005aa8:	04449703          	lh	a4,68(s1)
    80005aac:	4785                	li	a5,1
    80005aae:	04f71063          	bne	a4,a5,80005aee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	e4c080e7          	jalr	-436(ra) # 80003900 <iunlock>
  iput(p->cwd);
    80005abc:	15093503          	ld	a0,336(s2)
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	f38080e7          	jalr	-200(ra) # 800039f8 <iput>
  end_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	7b2080e7          	jalr	1970(ra) # 8000427a <end_op>
  p->cwd = ip;
    80005ad0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ad4:	4501                	li	a0,0
}
    80005ad6:	60ea                	ld	ra,152(sp)
    80005ad8:	644a                	ld	s0,144(sp)
    80005ada:	64aa                	ld	s1,136(sp)
    80005adc:	690a                	ld	s2,128(sp)
    80005ade:	610d                	addi	sp,sp,160
    80005ae0:	8082                	ret
    end_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	798080e7          	jalr	1944(ra) # 8000427a <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
    80005aec:	b7ed                	j	80005ad6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005aee:	8526                	mv	a0,s1
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	fb0080e7          	jalr	-80(ra) # 80003aa0 <iunlockput>
    end_op();
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	782080e7          	jalr	1922(ra) # 8000427a <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	bfd1                	j	80005ad6 <sys_chdir+0x7a>

0000000080005b04 <sys_exec>:

uint64
sys_exec(void)
{
    80005b04:	7145                	addi	sp,sp,-464
    80005b06:	e786                	sd	ra,456(sp)
    80005b08:	e3a2                	sd	s0,448(sp)
    80005b0a:	ff26                	sd	s1,440(sp)
    80005b0c:	fb4a                	sd	s2,432(sp)
    80005b0e:	f74e                	sd	s3,424(sp)
    80005b10:	f352                	sd	s4,416(sp)
    80005b12:	ef56                	sd	s5,408(sp)
    80005b14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b16:	08000613          	li	a2,128
    80005b1a:	f4040593          	addi	a1,s0,-192
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	034080e7          	jalr	52(ra) # 80002b54 <argstr>
    return -1;
    80005b28:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b2a:	0c054a63          	bltz	a0,80005bfe <sys_exec+0xfa>
    80005b2e:	e3840593          	addi	a1,s0,-456
    80005b32:	4505                	li	a0,1
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	ffe080e7          	jalr	-2(ra) # 80002b32 <argaddr>
    80005b3c:	0c054163          	bltz	a0,80005bfe <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b40:	10000613          	li	a2,256
    80005b44:	4581                	li	a1,0
    80005b46:	e4040513          	addi	a0,s0,-448
    80005b4a:	ffffb097          	auipc	ra,0xffffb
    80005b4e:	202080e7          	jalr	514(ra) # 80000d4c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b56:	89a6                	mv	s3,s1
    80005b58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b5a:	02000a13          	li	s4,32
    80005b5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b62:	00391793          	slli	a5,s2,0x3
    80005b66:	e3040593          	addi	a1,s0,-464
    80005b6a:	e3843503          	ld	a0,-456(s0)
    80005b6e:	953e                	add	a0,a0,a5
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	f06080e7          	jalr	-250(ra) # 80002a76 <fetchaddr>
    80005b78:	02054a63          	bltz	a0,80005bac <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b7c:	e3043783          	ld	a5,-464(s0)
    80005b80:	c3b9                	beqz	a5,80005bc6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b82:	ffffb097          	auipc	ra,0xffffb
    80005b86:	f8c080e7          	jalr	-116(ra) # 80000b0e <kalloc>
    80005b8a:	85aa                	mv	a1,a0
    80005b8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b90:	cd11                	beqz	a0,80005bac <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b92:	6605                	lui	a2,0x1
    80005b94:	e3043503          	ld	a0,-464(s0)
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	f30080e7          	jalr	-208(ra) # 80002ac8 <fetchstr>
    80005ba0:	00054663          	bltz	a0,80005bac <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ba4:	0905                	addi	s2,s2,1
    80005ba6:	09a1                	addi	s3,s3,8
    80005ba8:	fb491be3          	bne	s2,s4,80005b5e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bac:	10048913          	addi	s2,s1,256
    80005bb0:	6088                	ld	a0,0(s1)
    80005bb2:	c529                	beqz	a0,80005bfc <sys_exec+0xf8>
    kfree(argv[i]);
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	e5e080e7          	jalr	-418(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbc:	04a1                	addi	s1,s1,8
    80005bbe:	ff2499e3          	bne	s1,s2,80005bb0 <sys_exec+0xac>
  return -1;
    80005bc2:	597d                	li	s2,-1
    80005bc4:	a82d                	j	80005bfe <sys_exec+0xfa>
      argv[i] = 0;
    80005bc6:	0a8e                	slli	s5,s5,0x3
    80005bc8:	fc040793          	addi	a5,s0,-64
    80005bcc:	9abe                	add	s5,s5,a5
    80005bce:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005bd2:	e4040593          	addi	a1,s0,-448
    80005bd6:	f4040513          	addi	a0,s0,-192
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	178080e7          	jalr	376(ra) # 80004d52 <exec>
    80005be2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be4:	10048993          	addi	s3,s1,256
    80005be8:	6088                	ld	a0,0(s1)
    80005bea:	c911                	beqz	a0,80005bfe <sys_exec+0xfa>
    kfree(argv[i]);
    80005bec:	ffffb097          	auipc	ra,0xffffb
    80005bf0:	e26080e7          	jalr	-474(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf4:	04a1                	addi	s1,s1,8
    80005bf6:	ff3499e3          	bne	s1,s3,80005be8 <sys_exec+0xe4>
    80005bfa:	a011                	j	80005bfe <sys_exec+0xfa>
  return -1;
    80005bfc:	597d                	li	s2,-1
}
    80005bfe:	854a                	mv	a0,s2
    80005c00:	60be                	ld	ra,456(sp)
    80005c02:	641e                	ld	s0,448(sp)
    80005c04:	74fa                	ld	s1,440(sp)
    80005c06:	795a                	ld	s2,432(sp)
    80005c08:	79ba                	ld	s3,424(sp)
    80005c0a:	7a1a                	ld	s4,416(sp)
    80005c0c:	6afa                	ld	s5,408(sp)
    80005c0e:	6179                	addi	sp,sp,464
    80005c10:	8082                	ret

0000000080005c12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c12:	7139                	addi	sp,sp,-64
    80005c14:	fc06                	sd	ra,56(sp)
    80005c16:	f822                	sd	s0,48(sp)
    80005c18:	f426                	sd	s1,40(sp)
    80005c1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c1c:	ffffc097          	auipc	ra,0xffffc
    80005c20:	e00080e7          	jalr	-512(ra) # 80001a1c <myproc>
    80005c24:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c26:	fd840593          	addi	a1,s0,-40
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	f06080e7          	jalr	-250(ra) # 80002b32 <argaddr>
    return -1;
    80005c34:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c36:	0e054063          	bltz	a0,80005d16 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c3a:	fc840593          	addi	a1,s0,-56
    80005c3e:	fd040513          	addi	a0,s0,-48
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	de0080e7          	jalr	-544(ra) # 80004a22 <pipealloc>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c4c:	0c054563          	bltz	a0,80005d16 <sys_pipe+0x104>
  fd0 = -1;
    80005c50:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c54:	fd043503          	ld	a0,-48(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	50a080e7          	jalr	1290(ra) # 80005162 <fdalloc>
    80005c60:	fca42223          	sw	a0,-60(s0)
    80005c64:	08054c63          	bltz	a0,80005cfc <sys_pipe+0xea>
    80005c68:	fc843503          	ld	a0,-56(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	4f6080e7          	jalr	1270(ra) # 80005162 <fdalloc>
    80005c74:	fca42023          	sw	a0,-64(s0)
    80005c78:	06054863          	bltz	a0,80005ce8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c7c:	4691                	li	a3,4
    80005c7e:	fc440613          	addi	a2,s0,-60
    80005c82:	fd843583          	ld	a1,-40(s0)
    80005c86:	68a8                	ld	a0,80(s1)
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	a86080e7          	jalr	-1402(ra) # 8000170e <copyout>
    80005c90:	02054063          	bltz	a0,80005cb0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c94:	4691                	li	a3,4
    80005c96:	fc040613          	addi	a2,s0,-64
    80005c9a:	fd843583          	ld	a1,-40(s0)
    80005c9e:	0591                	addi	a1,a1,4
    80005ca0:	68a8                	ld	a0,80(s1)
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	a6c080e7          	jalr	-1428(ra) # 8000170e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005caa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cac:	06055563          	bgez	a0,80005d16 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cb0:	fc442783          	lw	a5,-60(s0)
    80005cb4:	07e9                	addi	a5,a5,26
    80005cb6:	078e                	slli	a5,a5,0x3
    80005cb8:	97a6                	add	a5,a5,s1
    80005cba:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cbe:	fc042503          	lw	a0,-64(s0)
    80005cc2:	0569                	addi	a0,a0,26
    80005cc4:	050e                	slli	a0,a0,0x3
    80005cc6:	9526                	add	a0,a0,s1
    80005cc8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ccc:	fd043503          	ld	a0,-48(s0)
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	9fc080e7          	jalr	-1540(ra) # 800046cc <fileclose>
    fileclose(wf);
    80005cd8:	fc843503          	ld	a0,-56(s0)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	9f0080e7          	jalr	-1552(ra) # 800046cc <fileclose>
    return -1;
    80005ce4:	57fd                	li	a5,-1
    80005ce6:	a805                	j	80005d16 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ce8:	fc442783          	lw	a5,-60(s0)
    80005cec:	0007c863          	bltz	a5,80005cfc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cf0:	01a78513          	addi	a0,a5,26
    80005cf4:	050e                	slli	a0,a0,0x3
    80005cf6:	9526                	add	a0,a0,s1
    80005cf8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cfc:	fd043503          	ld	a0,-48(s0)
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	9cc080e7          	jalr	-1588(ra) # 800046cc <fileclose>
    fileclose(wf);
    80005d08:	fc843503          	ld	a0,-56(s0)
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	9c0080e7          	jalr	-1600(ra) # 800046cc <fileclose>
    return -1;
    80005d14:	57fd                	li	a5,-1
}
    80005d16:	853e                	mv	a0,a5
    80005d18:	70e2                	ld	ra,56(sp)
    80005d1a:	7442                	ld	s0,48(sp)
    80005d1c:	74a2                	ld	s1,40(sp)
    80005d1e:	6121                	addi	sp,sp,64
    80005d20:	8082                	ret
	...

0000000080005d30 <kernelvec>:
    80005d30:	7111                	addi	sp,sp,-256
    80005d32:	e006                	sd	ra,0(sp)
    80005d34:	e40a                	sd	sp,8(sp)
    80005d36:	e80e                	sd	gp,16(sp)
    80005d38:	ec12                	sd	tp,24(sp)
    80005d3a:	f016                	sd	t0,32(sp)
    80005d3c:	f41a                	sd	t1,40(sp)
    80005d3e:	f81e                	sd	t2,48(sp)
    80005d40:	fc22                	sd	s0,56(sp)
    80005d42:	e0a6                	sd	s1,64(sp)
    80005d44:	e4aa                	sd	a0,72(sp)
    80005d46:	e8ae                	sd	a1,80(sp)
    80005d48:	ecb2                	sd	a2,88(sp)
    80005d4a:	f0b6                	sd	a3,96(sp)
    80005d4c:	f4ba                	sd	a4,104(sp)
    80005d4e:	f8be                	sd	a5,112(sp)
    80005d50:	fcc2                	sd	a6,120(sp)
    80005d52:	e146                	sd	a7,128(sp)
    80005d54:	e54a                	sd	s2,136(sp)
    80005d56:	e94e                	sd	s3,144(sp)
    80005d58:	ed52                	sd	s4,152(sp)
    80005d5a:	f156                	sd	s5,160(sp)
    80005d5c:	f55a                	sd	s6,168(sp)
    80005d5e:	f95e                	sd	s7,176(sp)
    80005d60:	fd62                	sd	s8,184(sp)
    80005d62:	e1e6                	sd	s9,192(sp)
    80005d64:	e5ea                	sd	s10,200(sp)
    80005d66:	e9ee                	sd	s11,208(sp)
    80005d68:	edf2                	sd	t3,216(sp)
    80005d6a:	f1f6                	sd	t4,224(sp)
    80005d6c:	f5fa                	sd	t5,232(sp)
    80005d6e:	f9fe                	sd	t6,240(sp)
    80005d70:	bd3fc0ef          	jal	ra,80002942 <kerneltrap>
    80005d74:	6082                	ld	ra,0(sp)
    80005d76:	6122                	ld	sp,8(sp)
    80005d78:	61c2                	ld	gp,16(sp)
    80005d7a:	7282                	ld	t0,32(sp)
    80005d7c:	7322                	ld	t1,40(sp)
    80005d7e:	73c2                	ld	t2,48(sp)
    80005d80:	7462                	ld	s0,56(sp)
    80005d82:	6486                	ld	s1,64(sp)
    80005d84:	6526                	ld	a0,72(sp)
    80005d86:	65c6                	ld	a1,80(sp)
    80005d88:	6666                	ld	a2,88(sp)
    80005d8a:	7686                	ld	a3,96(sp)
    80005d8c:	7726                	ld	a4,104(sp)
    80005d8e:	77c6                	ld	a5,112(sp)
    80005d90:	7866                	ld	a6,120(sp)
    80005d92:	688a                	ld	a7,128(sp)
    80005d94:	692a                	ld	s2,136(sp)
    80005d96:	69ca                	ld	s3,144(sp)
    80005d98:	6a6a                	ld	s4,152(sp)
    80005d9a:	7a8a                	ld	s5,160(sp)
    80005d9c:	7b2a                	ld	s6,168(sp)
    80005d9e:	7bca                	ld	s7,176(sp)
    80005da0:	7c6a                	ld	s8,184(sp)
    80005da2:	6c8e                	ld	s9,192(sp)
    80005da4:	6d2e                	ld	s10,200(sp)
    80005da6:	6dce                	ld	s11,208(sp)
    80005da8:	6e6e                	ld	t3,216(sp)
    80005daa:	7e8e                	ld	t4,224(sp)
    80005dac:	7f2e                	ld	t5,232(sp)
    80005dae:	7fce                	ld	t6,240(sp)
    80005db0:	6111                	addi	sp,sp,256
    80005db2:	10200073          	sret
    80005db6:	00000013          	nop
    80005dba:	00000013          	nop
    80005dbe:	0001                	nop

0000000080005dc0 <timervec>:
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	e10c                	sd	a1,0(a0)
    80005dc6:	e510                	sd	a2,8(a0)
    80005dc8:	e914                	sd	a3,16(a0)
    80005dca:	710c                	ld	a1,32(a0)
    80005dcc:	7510                	ld	a2,40(a0)
    80005dce:	6194                	ld	a3,0(a1)
    80005dd0:	96b2                	add	a3,a3,a2
    80005dd2:	e194                	sd	a3,0(a1)
    80005dd4:	4589                	li	a1,2
    80005dd6:	14459073          	csrw	sip,a1
    80005dda:	6914                	ld	a3,16(a0)
    80005ddc:	6510                	ld	a2,8(a0)
    80005dde:	610c                	ld	a1,0(a0)
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	30200073          	mret
	...

0000000080005dea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dea:	1141                	addi	sp,sp,-16
    80005dec:	e422                	sd	s0,8(sp)
    80005dee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005df0:	0c0007b7          	lui	a5,0xc000
    80005df4:	4705                	li	a4,1
    80005df6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005df8:	c3d8                	sw	a4,4(a5)
}
    80005dfa:	6422                	ld	s0,8(sp)
    80005dfc:	0141                	addi	sp,sp,16
    80005dfe:	8082                	ret

0000000080005e00 <plicinithart>:

void
plicinithart(void)
{
    80005e00:	1141                	addi	sp,sp,-16
    80005e02:	e406                	sd	ra,8(sp)
    80005e04:	e022                	sd	s0,0(sp)
    80005e06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	be8080e7          	jalr	-1048(ra) # 800019f0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e10:	0085171b          	slliw	a4,a0,0x8
    80005e14:	0c0027b7          	lui	a5,0xc002
    80005e18:	97ba                	add	a5,a5,a4
    80005e1a:	40200713          	li	a4,1026
    80005e1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e22:	00d5151b          	slliw	a0,a0,0xd
    80005e26:	0c2017b7          	lui	a5,0xc201
    80005e2a:	953e                	add	a0,a0,a5
    80005e2c:	00052023          	sw	zero,0(a0)
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret

0000000080005e38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e38:	1141                	addi	sp,sp,-16
    80005e3a:	e406                	sd	ra,8(sp)
    80005e3c:	e022                	sd	s0,0(sp)
    80005e3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	bb0080e7          	jalr	-1104(ra) # 800019f0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e48:	00d5179b          	slliw	a5,a0,0xd
    80005e4c:	0c201537          	lui	a0,0xc201
    80005e50:	953e                	add	a0,a0,a5
  return irq;
}
    80005e52:	4148                	lw	a0,4(a0)
    80005e54:	60a2                	ld	ra,8(sp)
    80005e56:	6402                	ld	s0,0(sp)
    80005e58:	0141                	addi	sp,sp,16
    80005e5a:	8082                	ret

0000000080005e5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e5c:	1101                	addi	sp,sp,-32
    80005e5e:	ec06                	sd	ra,24(sp)
    80005e60:	e822                	sd	s0,16(sp)
    80005e62:	e426                	sd	s1,8(sp)
    80005e64:	1000                	addi	s0,sp,32
    80005e66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b88080e7          	jalr	-1144(ra) # 800019f0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e70:	00d5151b          	slliw	a0,a0,0xd
    80005e74:	0c2017b7          	lui	a5,0xc201
    80005e78:	97aa                	add	a5,a5,a0
    80005e7a:	c3c4                	sw	s1,4(a5)
}
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	64a2                	ld	s1,8(sp)
    80005e82:	6105                	addi	sp,sp,32
    80005e84:	8082                	ret

0000000080005e86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e86:	1141                	addi	sp,sp,-16
    80005e88:	e406                	sd	ra,8(sp)
    80005e8a:	e022                	sd	s0,0(sp)
    80005e8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e8e:	479d                	li	a5,7
    80005e90:	04a7cc63          	blt	a5,a0,80005ee8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e94:	0001d797          	auipc	a5,0x1d
    80005e98:	16c78793          	addi	a5,a5,364 # 80023000 <disk>
    80005e9c:	00a78733          	add	a4,a5,a0
    80005ea0:	6789                	lui	a5,0x2
    80005ea2:	97ba                	add	a5,a5,a4
    80005ea4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ea8:	eba1                	bnez	a5,80005ef8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005eaa:	00451713          	slli	a4,a0,0x4
    80005eae:	0001f797          	auipc	a5,0x1f
    80005eb2:	1527b783          	ld	a5,338(a5) # 80025000 <disk+0x2000>
    80005eb6:	97ba                	add	a5,a5,a4
    80005eb8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ebc:	0001d797          	auipc	a5,0x1d
    80005ec0:	14478793          	addi	a5,a5,324 # 80023000 <disk>
    80005ec4:	97aa                	add	a5,a5,a0
    80005ec6:	6509                	lui	a0,0x2
    80005ec8:	953e                	add	a0,a0,a5
    80005eca:	4785                	li	a5,1
    80005ecc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ed0:	0001f517          	auipc	a0,0x1f
    80005ed4:	14850513          	addi	a0,a0,328 # 80025018 <disk+0x2018>
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	4dc080e7          	jalr	1244(ra) # 800023b4 <wakeup>
}
    80005ee0:	60a2                	ld	ra,8(sp)
    80005ee2:	6402                	ld	s0,0(sp)
    80005ee4:	0141                	addi	sp,sp,16
    80005ee6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	a9050513          	addi	a0,a0,-1392 # 80008978 <syscalls_name+0x338>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	652080e7          	jalr	1618(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005ef8:	00003517          	auipc	a0,0x3
    80005efc:	a9850513          	addi	a0,a0,-1384 # 80008990 <syscalls_name+0x350>
    80005f00:	ffffa097          	auipc	ra,0xffffa
    80005f04:	642080e7          	jalr	1602(ra) # 80000542 <panic>

0000000080005f08 <virtio_disk_init>:
{
    80005f08:	1101                	addi	sp,sp,-32
    80005f0a:	ec06                	sd	ra,24(sp)
    80005f0c:	e822                	sd	s0,16(sp)
    80005f0e:	e426                	sd	s1,8(sp)
    80005f10:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f12:	00003597          	auipc	a1,0x3
    80005f16:	a9658593          	addi	a1,a1,-1386 # 800089a8 <syscalls_name+0x368>
    80005f1a:	0001f517          	auipc	a0,0x1f
    80005f1e:	18e50513          	addi	a0,a0,398 # 800250a8 <disk+0x20a8>
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	c9e080e7          	jalr	-866(ra) # 80000bc0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f2a:	100017b7          	lui	a5,0x10001
    80005f2e:	4398                	lw	a4,0(a5)
    80005f30:	2701                	sext.w	a4,a4
    80005f32:	747277b7          	lui	a5,0x74727
    80005f36:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f3a:	0ef71163          	bne	a4,a5,8000601c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	43dc                	lw	a5,4(a5)
    80005f44:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f46:	4705                	li	a4,1
    80005f48:	0ce79a63          	bne	a5,a4,8000601c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	479c                	lw	a5,8(a5)
    80005f52:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f54:	4709                	li	a4,2
    80005f56:	0ce79363          	bne	a5,a4,8000601c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f5a:	100017b7          	lui	a5,0x10001
    80005f5e:	47d8                	lw	a4,12(a5)
    80005f60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f62:	554d47b7          	lui	a5,0x554d4
    80005f66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f6a:	0af71963          	bne	a4,a5,8000601c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6e:	100017b7          	lui	a5,0x10001
    80005f72:	4705                	li	a4,1
    80005f74:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f76:	470d                	li	a4,3
    80005f78:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f7a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f7c:	c7ffe737          	lui	a4,0xc7ffe
    80005f80:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f84:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f86:	2701                	sext.w	a4,a4
    80005f88:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8a:	472d                	li	a4,11
    80005f8c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8e:	473d                	li	a4,15
    80005f90:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f92:	6705                	lui	a4,0x1
    80005f94:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f96:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f9a:	5bdc                	lw	a5,52(a5)
    80005f9c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f9e:	c7d9                	beqz	a5,8000602c <virtio_disk_init+0x124>
  if(max < NUM)
    80005fa0:	471d                	li	a4,7
    80005fa2:	08f77d63          	bgeu	a4,a5,8000603c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa6:	100014b7          	lui	s1,0x10001
    80005faa:	47a1                	li	a5,8
    80005fac:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fae:	6609                	lui	a2,0x2
    80005fb0:	4581                	li	a1,0
    80005fb2:	0001d517          	auipc	a0,0x1d
    80005fb6:	04e50513          	addi	a0,a0,78 # 80023000 <disk>
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	d92080e7          	jalr	-622(ra) # 80000d4c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fc2:	0001d717          	auipc	a4,0x1d
    80005fc6:	03e70713          	addi	a4,a4,62 # 80023000 <disk>
    80005fca:	00c75793          	srli	a5,a4,0xc
    80005fce:	2781                	sext.w	a5,a5
    80005fd0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005fd2:	0001f797          	auipc	a5,0x1f
    80005fd6:	02e78793          	addi	a5,a5,46 # 80025000 <disk+0x2000>
    80005fda:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005fdc:	0001d717          	auipc	a4,0x1d
    80005fe0:	0a470713          	addi	a4,a4,164 # 80023080 <disk+0x80>
    80005fe4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005fe6:	0001e717          	auipc	a4,0x1e
    80005fea:	01a70713          	addi	a4,a4,26 # 80024000 <disk+0x1000>
    80005fee:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ff0:	4705                	li	a4,1
    80005ff2:	00e78c23          	sb	a4,24(a5)
    80005ff6:	00e78ca3          	sb	a4,25(a5)
    80005ffa:	00e78d23          	sb	a4,26(a5)
    80005ffe:	00e78da3          	sb	a4,27(a5)
    80006002:	00e78e23          	sb	a4,28(a5)
    80006006:	00e78ea3          	sb	a4,29(a5)
    8000600a:	00e78f23          	sb	a4,30(a5)
    8000600e:	00e78fa3          	sb	a4,31(a5)
}
    80006012:	60e2                	ld	ra,24(sp)
    80006014:	6442                	ld	s0,16(sp)
    80006016:	64a2                	ld	s1,8(sp)
    80006018:	6105                	addi	sp,sp,32
    8000601a:	8082                	ret
    panic("could not find virtio disk");
    8000601c:	00003517          	auipc	a0,0x3
    80006020:	99c50513          	addi	a0,a0,-1636 # 800089b8 <syscalls_name+0x378>
    80006024:	ffffa097          	auipc	ra,0xffffa
    80006028:	51e080e7          	jalr	1310(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    8000602c:	00003517          	auipc	a0,0x3
    80006030:	9ac50513          	addi	a0,a0,-1620 # 800089d8 <syscalls_name+0x398>
    80006034:	ffffa097          	auipc	ra,0xffffa
    80006038:	50e080e7          	jalr	1294(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    8000603c:	00003517          	auipc	a0,0x3
    80006040:	9bc50513          	addi	a0,a0,-1604 # 800089f8 <syscalls_name+0x3b8>
    80006044:	ffffa097          	auipc	ra,0xffffa
    80006048:	4fe080e7          	jalr	1278(ra) # 80000542 <panic>

000000008000604c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000604c:	7175                	addi	sp,sp,-144
    8000604e:	e506                	sd	ra,136(sp)
    80006050:	e122                	sd	s0,128(sp)
    80006052:	fca6                	sd	s1,120(sp)
    80006054:	f8ca                	sd	s2,112(sp)
    80006056:	f4ce                	sd	s3,104(sp)
    80006058:	f0d2                	sd	s4,96(sp)
    8000605a:	ecd6                	sd	s5,88(sp)
    8000605c:	e8da                	sd	s6,80(sp)
    8000605e:	e4de                	sd	s7,72(sp)
    80006060:	e0e2                	sd	s8,64(sp)
    80006062:	fc66                	sd	s9,56(sp)
    80006064:	f86a                	sd	s10,48(sp)
    80006066:	f46e                	sd	s11,40(sp)
    80006068:	0900                	addi	s0,sp,144
    8000606a:	8aaa                	mv	s5,a0
    8000606c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000606e:	00c52c83          	lw	s9,12(a0)
    80006072:	001c9c9b          	slliw	s9,s9,0x1
    80006076:	1c82                	slli	s9,s9,0x20
    80006078:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000607c:	0001f517          	auipc	a0,0x1f
    80006080:	02c50513          	addi	a0,a0,44 # 800250a8 <disk+0x20a8>
    80006084:	ffffb097          	auipc	ra,0xffffb
    80006088:	bcc080e7          	jalr	-1076(ra) # 80000c50 <acquire>
  for(int i = 0; i < 3; i++){
    8000608c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000608e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006090:	0001dc17          	auipc	s8,0x1d
    80006094:	f70c0c13          	addi	s8,s8,-144 # 80023000 <disk>
    80006098:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000609a:	4b0d                	li	s6,3
    8000609c:	a0ad                	j	80006106 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000609e:	00fc0733          	add	a4,s8,a5
    800060a2:	975e                	add	a4,a4,s7
    800060a4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060a8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060aa:	0207c563          	bltz	a5,800060d4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060ae:	2905                	addiw	s2,s2,1
    800060b0:	0611                	addi	a2,a2,4
    800060b2:	19690d63          	beq	s2,s6,8000624c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800060b6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060b8:	0001f717          	auipc	a4,0x1f
    800060bc:	f6070713          	addi	a4,a4,-160 # 80025018 <disk+0x2018>
    800060c0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060c2:	00074683          	lbu	a3,0(a4)
    800060c6:	fee1                	bnez	a3,8000609e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060c8:	2785                	addiw	a5,a5,1
    800060ca:	0705                	addi	a4,a4,1
    800060cc:	fe979be3          	bne	a5,s1,800060c2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060d0:	57fd                	li	a5,-1
    800060d2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060d4:	01205d63          	blez	s2,800060ee <virtio_disk_rw+0xa2>
    800060d8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060da:	000a2503          	lw	a0,0(s4)
    800060de:	00000097          	auipc	ra,0x0
    800060e2:	da8080e7          	jalr	-600(ra) # 80005e86 <free_desc>
      for(int j = 0; j < i; j++)
    800060e6:	2d85                	addiw	s11,s11,1
    800060e8:	0a11                	addi	s4,s4,4
    800060ea:	ffb918e3          	bne	s2,s11,800060da <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060ee:	0001f597          	auipc	a1,0x1f
    800060f2:	fba58593          	addi	a1,a1,-70 # 800250a8 <disk+0x20a8>
    800060f6:	0001f517          	auipc	a0,0x1f
    800060fa:	f2250513          	addi	a0,a0,-222 # 80025018 <disk+0x2018>
    800060fe:	ffffc097          	auipc	ra,0xffffc
    80006102:	136080e7          	jalr	310(ra) # 80002234 <sleep>
  for(int i = 0; i < 3; i++){
    80006106:	f8040a13          	addi	s4,s0,-128
{
    8000610a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000610c:	894e                	mv	s2,s3
    8000610e:	b765                	j	800060b6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006110:	0001f717          	auipc	a4,0x1f
    80006114:	ef073703          	ld	a4,-272(a4) # 80025000 <disk+0x2000>
    80006118:	973e                	add	a4,a4,a5
    8000611a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000611e:	0001d517          	auipc	a0,0x1d
    80006122:	ee250513          	addi	a0,a0,-286 # 80023000 <disk>
    80006126:	0001f717          	auipc	a4,0x1f
    8000612a:	eda70713          	addi	a4,a4,-294 # 80025000 <disk+0x2000>
    8000612e:	6314                	ld	a3,0(a4)
    80006130:	96be                	add	a3,a3,a5
    80006132:	00c6d603          	lhu	a2,12(a3)
    80006136:	00166613          	ori	a2,a2,1
    8000613a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000613e:	f8842683          	lw	a3,-120(s0)
    80006142:	6310                	ld	a2,0(a4)
    80006144:	97b2                	add	a5,a5,a2
    80006146:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000614a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000614e:	0612                	slli	a2,a2,0x4
    80006150:	962a                	add	a2,a2,a0
    80006152:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006156:	00469793          	slli	a5,a3,0x4
    8000615a:	630c                	ld	a1,0(a4)
    8000615c:	95be                	add	a1,a1,a5
    8000615e:	6689                	lui	a3,0x2
    80006160:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006164:	96ca                	add	a3,a3,s2
    80006166:	96aa                	add	a3,a3,a0
    80006168:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000616a:	6314                	ld	a3,0(a4)
    8000616c:	96be                	add	a3,a3,a5
    8000616e:	4585                	li	a1,1
    80006170:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006172:	6314                	ld	a3,0(a4)
    80006174:	96be                	add	a3,a3,a5
    80006176:	4509                	li	a0,2
    80006178:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000617c:	6314                	ld	a3,0(a4)
    8000617e:	97b6                	add	a5,a5,a3
    80006180:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006184:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006188:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000618c:	6714                	ld	a3,8(a4)
    8000618e:	0026d783          	lhu	a5,2(a3)
    80006192:	8b9d                	andi	a5,a5,7
    80006194:	0789                	addi	a5,a5,2
    80006196:	0786                	slli	a5,a5,0x1
    80006198:	97b6                	add	a5,a5,a3
    8000619a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000619e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061a2:	6718                	ld	a4,8(a4)
    800061a4:	00275783          	lhu	a5,2(a4)
    800061a8:	2785                	addiw	a5,a5,1
    800061aa:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ae:	100017b7          	lui	a5,0x10001
    800061b2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061b6:	004aa783          	lw	a5,4(s5)
    800061ba:	02b79163          	bne	a5,a1,800061dc <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800061be:	0001f917          	auipc	s2,0x1f
    800061c2:	eea90913          	addi	s2,s2,-278 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061c8:	85ca                	mv	a1,s2
    800061ca:	8556                	mv	a0,s5
    800061cc:	ffffc097          	auipc	ra,0xffffc
    800061d0:	068080e7          	jalr	104(ra) # 80002234 <sleep>
  while(b->disk == 1) {
    800061d4:	004aa783          	lw	a5,4(s5)
    800061d8:	fe9788e3          	beq	a5,s1,800061c8 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061dc:	f8042483          	lw	s1,-128(s0)
    800061e0:	20048793          	addi	a5,s1,512
    800061e4:	00479713          	slli	a4,a5,0x4
    800061e8:	0001d797          	auipc	a5,0x1d
    800061ec:	e1878793          	addi	a5,a5,-488 # 80023000 <disk>
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061f6:	0001f917          	auipc	s2,0x1f
    800061fa:	e0a90913          	addi	s2,s2,-502 # 80025000 <disk+0x2000>
    800061fe:	a019                	j	80006204 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006200:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006204:	8526                	mv	a0,s1
    80006206:	00000097          	auipc	ra,0x0
    8000620a:	c80080e7          	jalr	-896(ra) # 80005e86 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000620e:	0492                	slli	s1,s1,0x4
    80006210:	00093783          	ld	a5,0(s2)
    80006214:	94be                	add	s1,s1,a5
    80006216:	00c4d783          	lhu	a5,12(s1)
    8000621a:	8b85                	andi	a5,a5,1
    8000621c:	f3f5                	bnez	a5,80006200 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000621e:	0001f517          	auipc	a0,0x1f
    80006222:	e8a50513          	addi	a0,a0,-374 # 800250a8 <disk+0x20a8>
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	ade080e7          	jalr	-1314(ra) # 80000d04 <release>
}
    8000622e:	60aa                	ld	ra,136(sp)
    80006230:	640a                	ld	s0,128(sp)
    80006232:	74e6                	ld	s1,120(sp)
    80006234:	7946                	ld	s2,112(sp)
    80006236:	79a6                	ld	s3,104(sp)
    80006238:	7a06                	ld	s4,96(sp)
    8000623a:	6ae6                	ld	s5,88(sp)
    8000623c:	6b46                	ld	s6,80(sp)
    8000623e:	6ba6                	ld	s7,72(sp)
    80006240:	6c06                	ld	s8,64(sp)
    80006242:	7ce2                	ld	s9,56(sp)
    80006244:	7d42                	ld	s10,48(sp)
    80006246:	7da2                	ld	s11,40(sp)
    80006248:	6149                	addi	sp,sp,144
    8000624a:	8082                	ret
  if(write)
    8000624c:	01a037b3          	snez	a5,s10
    80006250:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006254:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006258:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000625c:	f8042483          	lw	s1,-128(s0)
    80006260:	00449913          	slli	s2,s1,0x4
    80006264:	0001f997          	auipc	s3,0x1f
    80006268:	d9c98993          	addi	s3,s3,-612 # 80025000 <disk+0x2000>
    8000626c:	0009ba03          	ld	s4,0(s3)
    80006270:	9a4a                	add	s4,s4,s2
    80006272:	f7040513          	addi	a0,s0,-144
    80006276:	ffffb097          	auipc	ra,0xffffb
    8000627a:	ea6080e7          	jalr	-346(ra) # 8000111c <kvmpa>
    8000627e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006282:	0009b783          	ld	a5,0(s3)
    80006286:	97ca                	add	a5,a5,s2
    80006288:	4741                	li	a4,16
    8000628a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000628c:	0009b783          	ld	a5,0(s3)
    80006290:	97ca                	add	a5,a5,s2
    80006292:	4705                	li	a4,1
    80006294:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006298:	f8442783          	lw	a5,-124(s0)
    8000629c:	0009b703          	ld	a4,0(s3)
    800062a0:	974a                	add	a4,a4,s2
    800062a2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a6:	0792                	slli	a5,a5,0x4
    800062a8:	0009b703          	ld	a4,0(s3)
    800062ac:	973e                	add	a4,a4,a5
    800062ae:	058a8693          	addi	a3,s5,88
    800062b2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800062b4:	0009b703          	ld	a4,0(s3)
    800062b8:	973e                	add	a4,a4,a5
    800062ba:	40000693          	li	a3,1024
    800062be:	c714                	sw	a3,8(a4)
  if(write)
    800062c0:	e40d18e3          	bnez	s10,80006110 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062c4:	0001f717          	auipc	a4,0x1f
    800062c8:	d3c73703          	ld	a4,-708(a4) # 80025000 <disk+0x2000>
    800062cc:	973e                	add	a4,a4,a5
    800062ce:	4689                	li	a3,2
    800062d0:	00d71623          	sh	a3,12(a4)
    800062d4:	b5a9                	j	8000611e <virtio_disk_rw+0xd2>

00000000800062d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062d6:	1101                	addi	sp,sp,-32
    800062d8:	ec06                	sd	ra,24(sp)
    800062da:	e822                	sd	s0,16(sp)
    800062dc:	e426                	sd	s1,8(sp)
    800062de:	e04a                	sd	s2,0(sp)
    800062e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062e2:	0001f517          	auipc	a0,0x1f
    800062e6:	dc650513          	addi	a0,a0,-570 # 800250a8 <disk+0x20a8>
    800062ea:	ffffb097          	auipc	ra,0xffffb
    800062ee:	966080e7          	jalr	-1690(ra) # 80000c50 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062f2:	0001f717          	auipc	a4,0x1f
    800062f6:	d0e70713          	addi	a4,a4,-754 # 80025000 <disk+0x2000>
    800062fa:	02075783          	lhu	a5,32(a4)
    800062fe:	6b18                	ld	a4,16(a4)
    80006300:	00275683          	lhu	a3,2(a4)
    80006304:	8ebd                	xor	a3,a3,a5
    80006306:	8a9d                	andi	a3,a3,7
    80006308:	cab9                	beqz	a3,8000635e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000630a:	0001d917          	auipc	s2,0x1d
    8000630e:	cf690913          	addi	s2,s2,-778 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006312:	0001f497          	auipc	s1,0x1f
    80006316:	cee48493          	addi	s1,s1,-786 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000631a:	078e                	slli	a5,a5,0x3
    8000631c:	97ba                	add	a5,a5,a4
    8000631e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006320:	20078713          	addi	a4,a5,512
    80006324:	0712                	slli	a4,a4,0x4
    80006326:	974a                	add	a4,a4,s2
    80006328:	03074703          	lbu	a4,48(a4)
    8000632c:	ef21                	bnez	a4,80006384 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000632e:	20078793          	addi	a5,a5,512
    80006332:	0792                	slli	a5,a5,0x4
    80006334:	97ca                	add	a5,a5,s2
    80006336:	7798                	ld	a4,40(a5)
    80006338:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000633c:	7788                	ld	a0,40(a5)
    8000633e:	ffffc097          	auipc	ra,0xffffc
    80006342:	076080e7          	jalr	118(ra) # 800023b4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006346:	0204d783          	lhu	a5,32(s1)
    8000634a:	2785                	addiw	a5,a5,1
    8000634c:	8b9d                	andi	a5,a5,7
    8000634e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006352:	6898                	ld	a4,16(s1)
    80006354:	00275683          	lhu	a3,2(a4)
    80006358:	8a9d                	andi	a3,a3,7
    8000635a:	fcf690e3          	bne	a3,a5,8000631a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000635e:	10001737          	lui	a4,0x10001
    80006362:	533c                	lw	a5,96(a4)
    80006364:	8b8d                	andi	a5,a5,3
    80006366:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006368:	0001f517          	auipc	a0,0x1f
    8000636c:	d4050513          	addi	a0,a0,-704 # 800250a8 <disk+0x20a8>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	994080e7          	jalr	-1644(ra) # 80000d04 <release>
}
    80006378:	60e2                	ld	ra,24(sp)
    8000637a:	6442                	ld	s0,16(sp)
    8000637c:	64a2                	ld	s1,8(sp)
    8000637e:	6902                	ld	s2,0(sp)
    80006380:	6105                	addi	sp,sp,32
    80006382:	8082                	ret
      panic("virtio_disk_intr status");
    80006384:	00002517          	auipc	a0,0x2
    80006388:	69450513          	addi	a0,a0,1684 # 80008a18 <syscalls_name+0x3d8>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	1b6080e7          	jalr	438(ra) # 80000542 <panic>
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
