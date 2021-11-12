
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ac013103          	ld	sp,-1344(sp) # 80008ac0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d9c78793          	addi	a5,a5,-612 # 80005e00 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3a4080e7          	jalr	932(ra) # 800024d0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	eda080e7          	jalr	-294(ra) # 800020ae <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	26a080e7          	jalr	618(ra) # 8000247a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	234080e7          	jalr	564(ra) # 80002526 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dfe080e7          	jalr	-514(ra) # 80002244 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8a078793          	addi	a5,a5,-1888 # 80021d18 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9a4080e7          	jalr	-1628(ra) # 80002244 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	782080e7          	jalr	1922(ra) # 800020ae <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	898080e7          	jalr	-1896(ra) # 8000276c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f64080e7          	jalr	-156(ra) # 80005e40 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	ffe080e7          	jalr	-2(ra) # 80001ee2 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7f8080e7          	jalr	2040(ra) # 80002744 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	818080e7          	jalr	-2024(ra) # 8000276c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	ece080e7          	jalr	-306(ra) # 80005e2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	edc080e7          	jalr	-292(ra) # 80005e40 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0b8080e7          	jalr	184(ra) # 80003024 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	748080e7          	jalr	1864(ra) # 800036bc <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	6f2080e7          	jalr	1778(ra) # 8000466e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	fde080e7          	jalr	-34(ra) # 80005f62 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d1c080e7          	jalr	-740(ra) # 80001ca8 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	262a0a13          	addi	s4,s4,610 # 80017ad0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	19048493          	addi	s1,s1,400
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	19698993          	addi	s3,s3,406 # 80017ad0 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	f4bc                	sd	a5,104(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	19048493          	addi	s1,s1,400
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first)
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	f007a783          	lw	a5,-256(a5) # 80008900 <first.1709>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d7a080e7          	jalr	-646(ra) # 80002784 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ee07a323          	sw	zero,-282(a5) # 80008900 <first.1709>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	c18080e7          	jalr	-1000(ra) # 8000363c <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	eb878793          	addi	a5,a5,-328 # 80008904 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	08093683          	ld	a3,128(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6e:	6148                	ld	a0,128(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0804b023          	sd	zero,128(s1)
  if (p->pagetable)
    80001b7e:	7ca8                	ld	a0,120(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	78ac                	ld	a1,112(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80001b90:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001b9c:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ae23          	sw	zero,28(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	f0290913          	addi	s2,s2,-254 # 80017ad0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001be0:	4cdc                	lw	a5,28(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bee:	19048493          	addi	s1,s1,400
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a88d                	j	80001c6a <allocproc+0xb0>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	ccdc                	sw	a5,28(s1)
  p->ctime = ticks; // stores time using global variable ticks
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	4287a783          	lw	a5,1064(a5) # 80009030 <ticks>
    80001c10:	d8dc                	sw	a5,52(s1)
  p->statprior = 60;
    80001c12:	03c00793          	li	a5,60
    80001c16:	dc9c                	sw	a5,56(s1)
  p->run_time = 0;
    80001c18:	0204ae23          	sw	zero,60(s1)
  p->start_time = 0;
    80001c1c:	0404a023          	sw	zero,64(s1)
  p->end_time = 0;
    80001c20:	0404a223          	sw	zero,68(s1)
  p->qval = 0;
    80001c24:	0604a023          	sw	zero,96(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	ecc080e7          	jalr	-308(ra) # 80000af4 <kalloc>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e0c8                	sd	a0,128(s1)
    80001c34:	c131                	beqz	a0,80001c78 <allocproc+0xbe>
  p->pagetable = proc_pagetable(p);
    80001c36:	8526                	mv	a0,s1
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	e3c080e7          	jalr	-452(ra) # 80001a74 <proc_pagetable>
    80001c40:	892a                	mv	s2,a0
    80001c42:	fca8                	sd	a0,120(s1)
  if (p->pagetable == 0)
    80001c44:	c531                	beqz	a0,80001c90 <allocproc+0xd6>
  memset(&p->context, 0, sizeof(p->context));
    80001c46:	07000613          	li	a2,112
    80001c4a:	4581                	li	a1,0
    80001c4c:	08848513          	addi	a0,s1,136
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	090080e7          	jalr	144(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c58:	00000797          	auipc	a5,0x0
    80001c5c:	d9078793          	addi	a5,a5,-624 # 800019e8 <forkret>
    80001c60:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c62:	74bc                	ld	a5,104(s1)
    80001c64:	6705                	lui	a4,0x1
    80001c66:	97ba                	add	a5,a5,a4
    80001c68:	e8dc                	sd	a5,144(s1)
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ee8080e7          	jalr	-280(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	bff1                	j	80001c6a <allocproc+0xb0>
    freeproc(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	ed0080e7          	jalr	-304(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
    return 0;
    80001ca4:	84ca                	mv	s1,s2
    80001ca6:	b7d1                	j	80001c6a <allocproc+0xb0>

0000000080001ca8 <userinit>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f08080e7          	jalr	-248(ra) # 80001bba <allocproc>
    80001cba:	84aa                	mv	s1,a0
  initproc = p;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	36a7b623          	sd	a0,876(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc4:	03400613          	li	a2,52
    80001cc8:	00007597          	auipc	a1,0x7
    80001ccc:	c4858593          	addi	a1,a1,-952 # 80008910 <initcode>
    80001cd0:	7d28                	ld	a0,120(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	696080e7          	jalr	1686(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cda:	6785                	lui	a5,0x1
    80001cdc:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cde:	60d8                	ld	a4,128(s1)
    80001ce0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce4:	60d8                	ld	a4,128(s1)
    80001ce6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	00006597          	auipc	a1,0x6
    80001cee:	51658593          	addi	a1,a1,1302 # 80008200 <digits+0x1c0>
    80001cf2:	18048513          	addi	a0,s1,384
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	13c080e7          	jalr	316(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	51250513          	addi	a0,a0,1298 # 80008210 <digits+0x1d0>
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	364080e7          	jalr	868(ra) # 8000406a <namei>
    80001d0e:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80001d12:	478d                	li	a5,3
    80001d14:	ccdc                	sw	a5,28(s1)
  release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <growproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	addi	s0,sp,32
    80001d36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	c78080e7          	jalr	-904(ra) # 800019b0 <myproc>
    80001d40:	892a                	mv	s2,a0
  sz = p->sz;
    80001d42:	792c                	ld	a1,112(a0)
    80001d44:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d48:	00904f63          	bgtz	s1,80001d66 <growproc+0x3c>
  else if (n < 0)
    80001d4c:	0204cc63          	bltz	s1,80001d84 <growproc+0x5a>
  p->sz = sz;
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	06c93823          	sd	a2,112(s2)
  return 0;
    80001d58:	4501                	li	a0,0
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d66:	9e25                	addw	a2,a2,s1
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	1582                	slli	a1,a1,0x20
    80001d6e:	9181                	srli	a1,a1,0x20
    80001d70:	7d28                	ld	a0,120(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	6b0080e7          	jalr	1712(ra) # 80001422 <uvmalloc>
    80001d7a:	0005061b          	sext.w	a2,a0
    80001d7e:	fa69                	bnez	a2,80001d50 <growproc+0x26>
      return -1;
    80001d80:	557d                	li	a0,-1
    80001d82:	bfe1                	j	80001d5a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d84:	9e25                	addw	a2,a2,s1
    80001d86:	1602                	slli	a2,a2,0x20
    80001d88:	9201                	srli	a2,a2,0x20
    80001d8a:	1582                	slli	a1,a1,0x20
    80001d8c:	9181                	srli	a1,a1,0x20
    80001d8e:	7d28                	ld	a0,120(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	64a080e7          	jalr	1610(ra) # 800013da <uvmdealloc>
    80001d98:	0005061b          	sext.w	a2,a0
    80001d9c:	bf55                	j	80001d50 <growproc+0x26>

0000000080001d9e <fork>:
{
    80001d9e:	7179                	addi	sp,sp,-48
    80001da0:	f406                	sd	ra,40(sp)
    80001da2:	f022                	sd	s0,32(sp)
    80001da4:	ec26                	sd	s1,24(sp)
    80001da6:	e84a                	sd	s2,16(sp)
    80001da8:	e44e                	sd	s3,8(sp)
    80001daa:	e052                	sd	s4,0(sp)
    80001dac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	c02080e7          	jalr	-1022(ra) # 800019b0 <myproc>
    80001db6:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	e02080e7          	jalr	-510(ra) # 80001bba <allocproc>
    80001dc0:	10050f63          	beqz	a0,80001ede <fork+0x140>
    80001dc4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dc6:	07093603          	ld	a2,112(s2)
    80001dca:	7d2c                	ld	a1,120(a0)
    80001dcc:	07893503          	ld	a0,120(s2)
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	79e080e7          	jalr	1950(ra) # 8000156e <uvmcopy>
    80001dd8:	04054a63          	bltz	a0,80001e2c <fork+0x8e>
  np->sz = p->sz;
    80001ddc:	07093783          	ld	a5,112(s2)
    80001de0:	06f9b823          	sd	a5,112(s3)
  np->tmask = p->tmask;
    80001de4:	01892783          	lw	a5,24(s2)
    80001de8:	00f9ac23          	sw	a5,24(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dec:	08093683          	ld	a3,128(s2)
    80001df0:	87b6                	mv	a5,a3
    80001df2:	0809b703          	ld	a4,128(s3)
    80001df6:	12068693          	addi	a3,a3,288
    80001dfa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfe:	6788                	ld	a0,8(a5)
    80001e00:	6b8c                	ld	a1,16(a5)
    80001e02:	6f90                	ld	a2,24(a5)
    80001e04:	01073023          	sd	a6,0(a4)
    80001e08:	e708                	sd	a0,8(a4)
    80001e0a:	eb0c                	sd	a1,16(a4)
    80001e0c:	ef10                	sd	a2,24(a4)
    80001e0e:	02078793          	addi	a5,a5,32
    80001e12:	02070713          	addi	a4,a4,32
    80001e16:	fed792e3          	bne	a5,a3,80001dfa <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e1a:	0809b783          	ld	a5,128(s3)
    80001e1e:	0607b823          	sd	zero,112(a5)
    80001e22:	0f800493          	li	s1,248
  for (i = 0; i < NOFILE; i++)
    80001e26:	17800a13          	li	s4,376
    80001e2a:	a03d                	j	80001e58 <fork+0xba>
    freeproc(np);
    80001e2c:	854e                	mv	a0,s3
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	d34080e7          	jalr	-716(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e36:	854e                	mv	a0,s3
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
    return -1;
    80001e40:	5a7d                	li	s4,-1
    80001e42:	a069                	j	80001ecc <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	8bc080e7          	jalr	-1860(ra) # 80004700 <filedup>
    80001e4c:	009987b3          	add	a5,s3,s1
    80001e50:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	01448763          	beq	s1,s4,80001e62 <fork+0xc4>
    if (p->ofile[i])
    80001e58:	009907b3          	add	a5,s2,s1
    80001e5c:	6388                	ld	a0,0(a5)
    80001e5e:	f17d                	bnez	a0,80001e44 <fork+0xa6>
    80001e60:	bfcd                	j	80001e52 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e62:	17893503          	ld	a0,376(s2)
    80001e66:	00002097          	auipc	ra,0x2
    80001e6a:	a10080e7          	jalr	-1520(ra) # 80003876 <idup>
    80001e6e:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e72:	4641                	li	a2,16
    80001e74:	18090593          	addi	a1,s2,384
    80001e78:	18098513          	addi	a0,s3,384
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	fb6080e7          	jalr	-74(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e84:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e92:	0000f497          	auipc	s1,0xf
    80001e96:	42648493          	addi	s1,s1,1062 # 800112b8 <wait_lock>
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea4:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ebc:	478d                	li	a5,3
    80001ebe:	00f9ae23          	sw	a5,28(s3)
  release(&np->lock);
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>
}
    80001ecc:	8552                	mv	a0,s4
    80001ece:	70a2                	ld	ra,40(sp)
    80001ed0:	7402                	ld	s0,32(sp)
    80001ed2:	64e2                	ld	s1,24(sp)
    80001ed4:	6942                	ld	s2,16(sp)
    80001ed6:	69a2                	ld	s3,8(sp)
    80001ed8:	6a02                	ld	s4,0(sp)
    80001eda:	6145                	addi	sp,sp,48
    80001edc:	8082                	ret
    return -1;
    80001ede:	5a7d                	li	s4,-1
    80001ee0:	b7f5                	j	80001ecc <fork+0x12e>

0000000080001ee2 <scheduler>:
{
    80001ee2:	7139                	addi	sp,sp,-64
    80001ee4:	fc06                	sd	ra,56(sp)
    80001ee6:	f822                	sd	s0,48(sp)
    80001ee8:	f426                	sd	s1,40(sp)
    80001eea:	f04a                	sd	s2,32(sp)
    80001eec:	ec4e                	sd	s3,24(sp)
    80001eee:	e852                	sd	s4,16(sp)
    80001ef0:	e456                	sd	s5,8(sp)
    80001ef2:	e05a                	sd	s6,0(sp)
    80001ef4:	0080                	addi	s0,sp,64
    80001ef6:	8492                	mv	s1,tp
  int id = r_tp();
    80001ef8:	2481                	sext.w	s1,s1
  c->proc = 0;
    80001efa:	00749a93          	slli	s5,s1,0x7
    80001efe:	0000f797          	auipc	a5,0xf
    80001f02:	3a278793          	addi	a5,a5,930 # 800112a0 <pid_lock>
    80001f06:	97d6                	add	a5,a5,s5
    80001f08:	0207b823          	sd	zero,48(a5)
  printf("RR started\n");
    80001f0c:	00006517          	auipc	a0,0x6
    80001f10:	30c50513          	addi	a0,a0,780 # 80008218 <digits+0x1d8>
    80001f14:	ffffe097          	auipc	ra,0xffffe
    80001f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
        swtch(&c->context, &p->context);
    80001f1c:	0000f797          	auipc	a5,0xf
    80001f20:	3bc78793          	addi	a5,a5,956 # 800112d8 <cpus+0x8>
    80001f24:	9abe                	add	s5,s5,a5
      if (p->state == RUNNABLE)
    80001f26:	498d                	li	s3,3
        p->state = RUNNING;
    80001f28:	4b11                	li	s6,4
        c->proc = p;
    80001f2a:	049e                	slli	s1,s1,0x7
    80001f2c:	0000fa17          	auipc	s4,0xf
    80001f30:	374a0a13          	addi	s4,s4,884 # 800112a0 <pid_lock>
    80001f34:	9a26                	add	s4,s4,s1
    for (p = proc; p < &proc[NPROC]; p++)
    80001f36:	00016917          	auipc	s2,0x16
    80001f3a:	b9a90913          	addi	s2,s2,-1126 # 80017ad0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f46:	10079073          	csrw	sstatus,a5
    80001f4a:	0000f497          	auipc	s1,0xf
    80001f4e:	78648493          	addi	s1,s1,1926 # 800116d0 <proc>
    80001f52:	a03d                	j	80001f80 <scheduler+0x9e>
        p->state = RUNNING;
    80001f54:	0164ae23          	sw	s6,28(s1)
        c->proc = p;
    80001f58:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5c:	08848593          	addi	a1,s1,136
    80001f60:	8556                	mv	a0,s5
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	778080e7          	jalr	1912(ra) # 800026da <swtch>
        c->proc = 0;
    80001f6a:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d28080e7          	jalr	-728(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f78:	19048493          	addi	s1,s1,400
    80001f7c:	fd2481e3          	beq	s1,s2,80001f3e <scheduler+0x5c>
      acquire(&p->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c62080e7          	jalr	-926(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    80001f8a:	4cdc                	lw	a5,28(s1)
    80001f8c:	ff3791e3          	bne	a5,s3,80001f6e <scheduler+0x8c>
    80001f90:	b7d1                	j	80001f54 <scheduler+0x72>

0000000080001f92 <sched>:
{
    80001f92:	7179                	addi	sp,sp,-48
    80001f94:	f406                	sd	ra,40(sp)
    80001f96:	f022                	sd	s0,32(sp)
    80001f98:	ec26                	sd	s1,24(sp)
    80001f9a:	e84a                	sd	s2,16(sp)
    80001f9c:	e44e                	sd	s3,8(sp)
    80001f9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	a10080e7          	jalr	-1520(ra) # 800019b0 <myproc>
    80001fa8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	bc0080e7          	jalr	-1088(ra) # 80000b6a <holding>
    80001fb2:	c93d                	beqz	a0,80002028 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	2e670713          	addi	a4,a4,742 # 800112a0 <pid_lock>
    80001fc2:	97ba                	add	a5,a5,a4
    80001fc4:	0a87a703          	lw	a4,168(a5)
    80001fc8:	4785                	li	a5,1
    80001fca:	06f71763          	bne	a4,a5,80002038 <sched+0xa6>
  if (p->state == RUNNING)
    80001fce:	4cd8                	lw	a4,28(s1)
    80001fd0:	4791                	li	a5,4
    80001fd2:	06f70b63          	beq	a4,a5,80002048 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fda:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fdc:	efb5                	bnez	a5,80002058 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fde:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe0:	0000f917          	auipc	s2,0xf
    80001fe4:	2c090913          	addi	s2,s2,704 # 800112a0 <pid_lock>
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	97ca                	add	a5,a5,s2
    80001fee:	0ac7a983          	lw	s3,172(a5)
    80001ff2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	0000f597          	auipc	a1,0xf
    80001ffc:	2e058593          	addi	a1,a1,736 # 800112d8 <cpus+0x8>
    80002000:	95be                	add	a1,a1,a5
    80002002:	08848513          	addi	a0,s1,136
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	6d4080e7          	jalr	1748(ra) # 800026da <swtch>
    8000200e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	97ca                	add	a5,a5,s2
    80002016:	0b37a623          	sw	s3,172(a5)
}
    8000201a:	70a2                	ld	ra,40(sp)
    8000201c:	7402                	ld	s0,32(sp)
    8000201e:	64e2                	ld	s1,24(sp)
    80002020:	6942                	ld	s2,16(sp)
    80002022:	69a2                	ld	s3,8(sp)
    80002024:	6145                	addi	sp,sp,48
    80002026:	8082                	ret
    panic("sched p->lock");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	20050513          	addi	a0,a0,512 # 80008228 <digits+0x1e8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
    panic("sched locks");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	20050513          	addi	a0,a0,512 # 80008238 <digits+0x1f8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    panic("sched running");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	20050513          	addi	a0,a0,512 # 80008248 <digits+0x208>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	20050513          	addi	a0,a0,512 # 80008258 <digits+0x218>
    80002060:	ffffe097          	auipc	ra,0xffffe
    80002064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>

0000000080002068 <yield>:
{
    80002068:	1101                	addi	sp,sp,-32
    8000206a:	ec06                	sd	ra,24(sp)
    8000206c:	e822                	sd	s0,16(sp)
    8000206e:	e426                	sd	s1,8(sp)
    80002070:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	93e080e7          	jalr	-1730(ra) # 800019b0 <myproc>
    8000207a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002084:	478d                	li	a5,3
    80002086:	ccdc                	sw	a5,28(s1)
  p->end_time = ticks;
    80002088:	00007797          	auipc	a5,0x7
    8000208c:	fa87a783          	lw	a5,-88(a5) # 80009030 <ticks>
    80002090:	c0fc                	sw	a5,68(s1)
  sched();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	f00080e7          	jalr	-256(ra) # 80001f92 <sched>
  release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
}
    800020a4:	60e2                	ld	ra,24(sp)
    800020a6:	6442                	ld	s0,16(sp)
    800020a8:	64a2                	ld	s1,8(sp)
    800020aa:	6105                	addi	sp,sp,32
    800020ac:	8082                	ret

00000000800020ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	1800                	addi	s0,sp,48
    800020bc:	89aa                	mv	s3,a0
    800020be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	8f0080e7          	jalr	-1808(ra) # 800019b0 <myproc>
    800020c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
  release(lk);
    800020d2:	854a                	mv	a0,s2
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e0:	4789                	li	a5,2
    800020e2:	ccdc                	sw	a5,28(s1)
  p->sleep_time = ticks;
    800020e4:	00007797          	auipc	a5,0x7
    800020e8:	f4c7a783          	lw	a5,-180(a5) # 80009030 <ticks>
    800020ec:	c4fc                	sw	a5,76(s1)
  sched();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	ea4080e7          	jalr	-348(ra) # 80001f92 <sched>

  // Tidy up.
  p->chan = 0;
    800020f6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	b9c080e7          	jalr	-1124(ra) # 80000c98 <release>
  acquire(lk);
    80002104:	854a                	mv	a0,s2
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	ade080e7          	jalr	-1314(ra) # 80000be4 <acquire>
}
    8000210e:	70a2                	ld	ra,40(sp)
    80002110:	7402                	ld	s0,32(sp)
    80002112:	64e2                	ld	s1,24(sp)
    80002114:	6942                	ld	s2,16(sp)
    80002116:	69a2                	ld	s3,8(sp)
    80002118:	6145                	addi	sp,sp,48
    8000211a:	8082                	ret

000000008000211c <wait>:
{
    8000211c:	715d                	addi	sp,sp,-80
    8000211e:	e486                	sd	ra,72(sp)
    80002120:	e0a2                	sd	s0,64(sp)
    80002122:	fc26                	sd	s1,56(sp)
    80002124:	f84a                	sd	s2,48(sp)
    80002126:	f44e                	sd	s3,40(sp)
    80002128:	f052                	sd	s4,32(sp)
    8000212a:	ec56                	sd	s5,24(sp)
    8000212c:	e85a                	sd	s6,16(sp)
    8000212e:	e45e                	sd	s7,8(sp)
    80002130:	e062                	sd	s8,0(sp)
    80002132:	0880                	addi	s0,sp,80
    80002134:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	87a080e7          	jalr	-1926(ra) # 800019b0 <myproc>
    8000213e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002140:	0000f517          	auipc	a0,0xf
    80002144:	17850513          	addi	a0,a0,376 # 800112b8 <wait_lock>
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	a9c080e7          	jalr	-1380(ra) # 80000be4 <acquire>
    havekids = 0;
    80002150:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002152:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002154:	00016997          	auipc	s3,0x16
    80002158:	97c98993          	addi	s3,s3,-1668 # 80017ad0 <tickslock>
        havekids = 1;
    8000215c:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000215e:	0000fc17          	auipc	s8,0xf
    80002162:	15ac0c13          	addi	s8,s8,346 # 800112b8 <wait_lock>
    havekids = 0;
    80002166:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002168:	0000f497          	auipc	s1,0xf
    8000216c:	56848493          	addi	s1,s1,1384 # 800116d0 <proc>
    80002170:	a0bd                	j	800021de <wait+0xc2>
          pid = np->pid;
    80002172:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002176:	000b0e63          	beqz	s6,80002192 <wait+0x76>
    8000217a:	4691                	li	a3,4
    8000217c:	02c48613          	addi	a2,s1,44
    80002180:	85da                	mv	a1,s6
    80002182:	07893503          	ld	a0,120(s2)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	4ec080e7          	jalr	1260(ra) # 80001672 <copyout>
    8000218e:	02054563          	bltz	a0,800021b8 <wait+0x9c>
          freeproc(np);
    80002192:	8526                	mv	a0,s1
    80002194:	00000097          	auipc	ra,0x0
    80002198:	9ce080e7          	jalr	-1586(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
          release(&wait_lock);
    800021a6:	0000f517          	auipc	a0,0xf
    800021aa:	11250513          	addi	a0,a0,274 # 800112b8 <wait_lock>
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
          return pid;
    800021b6:	a09d                	j	8000221c <wait+0x100>
            release(&np->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	ade080e7          	jalr	-1314(ra) # 80000c98 <release>
            release(&wait_lock);
    800021c2:	0000f517          	auipc	a0,0xf
    800021c6:	0f650513          	addi	a0,a0,246 # 800112b8 <wait_lock>
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
            return -1;
    800021d2:	59fd                	li	s3,-1
    800021d4:	a0a1                	j	8000221c <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021d6:	19048493          	addi	s1,s1,400
    800021da:	03348463          	beq	s1,s3,80002202 <wait+0xe6>
      if (np->parent == p)
    800021de:	6cbc                	ld	a5,88(s1)
    800021e0:	ff279be3          	bne	a5,s2,800021d6 <wait+0xba>
        acquire(&np->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	9fe080e7          	jalr	-1538(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800021ee:	4cdc                	lw	a5,28(s1)
    800021f0:	f94781e3          	beq	a5,s4,80002172 <wait+0x56>
        release(&np->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
        havekids = 1;
    800021fe:	8756                	mv	a4,s5
    80002200:	bfd9                	j	800021d6 <wait+0xba>
    if (!havekids || p->killed)
    80002202:	c701                	beqz	a4,8000220a <wait+0xee>
    80002204:	02892783          	lw	a5,40(s2)
    80002208:	c79d                	beqz	a5,80002236 <wait+0x11a>
      release(&wait_lock);
    8000220a:	0000f517          	auipc	a0,0xf
    8000220e:	0ae50513          	addi	a0,a0,174 # 800112b8 <wait_lock>
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
      return -1;
    8000221a:	59fd                	li	s3,-1
}
    8000221c:	854e                	mv	a0,s3
    8000221e:	60a6                	ld	ra,72(sp)
    80002220:	6406                	ld	s0,64(sp)
    80002222:	74e2                	ld	s1,56(sp)
    80002224:	7942                	ld	s2,48(sp)
    80002226:	79a2                	ld	s3,40(sp)
    80002228:	7a02                	ld	s4,32(sp)
    8000222a:	6ae2                	ld	s5,24(sp)
    8000222c:	6b42                	ld	s6,16(sp)
    8000222e:	6ba2                	ld	s7,8(sp)
    80002230:	6c02                	ld	s8,0(sp)
    80002232:	6161                	addi	sp,sp,80
    80002234:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002236:	85e2                	mv	a1,s8
    80002238:	854a                	mv	a0,s2
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	e74080e7          	jalr	-396(ra) # 800020ae <sleep>
    havekids = 0;
    80002242:	b715                	j	80002166 <wait+0x4a>

0000000080002244 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002244:	7139                	addi	sp,sp,-64
    80002246:	fc06                	sd	ra,56(sp)
    80002248:	f822                	sd	s0,48(sp)
    8000224a:	f426                	sd	s1,40(sp)
    8000224c:	f04a                	sd	s2,32(sp)
    8000224e:	ec4e                	sd	s3,24(sp)
    80002250:	e852                	sd	s4,16(sp)
    80002252:	e456                	sd	s5,8(sp)
    80002254:	e05a                	sd	s6,0(sp)
    80002256:	0080                	addi	s0,sp,64
    80002258:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000225a:	0000f497          	auipc	s1,0xf
    8000225e:	47648493          	addi	s1,s1,1142 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002262:	4989                	li	s3,2
      {
        p->end_time = ticks;
    80002264:	00007b17          	auipc	s6,0x7
    80002268:	dccb0b13          	addi	s6,s6,-564 # 80009030 <ticks>
        p->state = RUNNABLE;
    8000226c:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000226e:	00016917          	auipc	s2,0x16
    80002272:	86290913          	addi	s2,s2,-1950 # 80017ad0 <tickslock>
    80002276:	a005                	j	80002296 <wakeup+0x52>
        p->end_time = ticks;
    80002278:	000b2783          	lw	a5,0(s6)
    8000227c:	c0fc                	sw	a5,68(s1)
        p->state = RUNNABLE;
    8000227e:	0154ae23          	sw	s5,28(s1)
        p->wake_time = ticks;
    80002282:	c8bc                	sw	a5,80(s1)
      }
      release(&p->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	19048493          	addi	s1,s1,400
    80002292:	03248463          	beq	s1,s2,800022ba <wakeup+0x76>
    if (p != myproc())
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	71a080e7          	jalr	1818(ra) # 800019b0 <myproc>
    8000229e:	fea488e3          	beq	s1,a0,8000228e <wakeup+0x4a>
      acquire(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022ac:	4cdc                	lw	a5,28(s1)
    800022ae:	fd379be3          	bne	a5,s3,80002284 <wakeup+0x40>
    800022b2:	709c                	ld	a5,32(s1)
    800022b4:	fd4798e3          	bne	a5,s4,80002284 <wakeup+0x40>
    800022b8:	b7c1                	j	80002278 <wakeup+0x34>
    }
  }
}
    800022ba:	70e2                	ld	ra,56(sp)
    800022bc:	7442                	ld	s0,48(sp)
    800022be:	74a2                	ld	s1,40(sp)
    800022c0:	7902                	ld	s2,32(sp)
    800022c2:	69e2                	ld	s3,24(sp)
    800022c4:	6a42                	ld	s4,16(sp)
    800022c6:	6aa2                	ld	s5,8(sp)
    800022c8:	6b02                	ld	s6,0(sp)
    800022ca:	6121                	addi	sp,sp,64
    800022cc:	8082                	ret

00000000800022ce <reparent>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	e052                	sd	s4,0(sp)
    800022dc:	1800                	addi	s0,sp,48
    800022de:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022e0:	0000f497          	auipc	s1,0xf
    800022e4:	3f048493          	addi	s1,s1,1008 # 800116d0 <proc>
      pp->parent = initproc;
    800022e8:	00007a17          	auipc	s4,0x7
    800022ec:	d40a0a13          	addi	s4,s4,-704 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	7e098993          	addi	s3,s3,2016 # 80017ad0 <tickslock>
    800022f8:	a029                	j	80002302 <reparent+0x34>
    800022fa:	19048493          	addi	s1,s1,400
    800022fe:	01348d63          	beq	s1,s3,80002318 <reparent+0x4a>
    if (pp->parent == p)
    80002302:	6cbc                	ld	a5,88(s1)
    80002304:	ff279be3          	bne	a5,s2,800022fa <reparent+0x2c>
      pp->parent = initproc;
    80002308:	000a3503          	ld	a0,0(s4)
    8000230c:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	f36080e7          	jalr	-202(ra) # 80002244 <wakeup>
    80002316:	b7d5                	j	800022fa <reparent+0x2c>
}
    80002318:	70a2                	ld	ra,40(sp)
    8000231a:	7402                	ld	s0,32(sp)
    8000231c:	64e2                	ld	s1,24(sp)
    8000231e:	6942                	ld	s2,16(sp)
    80002320:	69a2                	ld	s3,8(sp)
    80002322:	6a02                	ld	s4,0(sp)
    80002324:	6145                	addi	sp,sp,48
    80002326:	8082                	ret

0000000080002328 <exit>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	e052                	sd	s4,0(sp)
    80002336:	1800                	addi	s0,sp,48
    80002338:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	676080e7          	jalr	1654(ra) # 800019b0 <myproc>
    80002342:	89aa                	mv	s3,a0
  if (p == initproc)
    80002344:	00007797          	auipc	a5,0x7
    80002348:	ce47b783          	ld	a5,-796(a5) # 80009028 <initproc>
    8000234c:	0f850493          	addi	s1,a0,248
    80002350:	17850913          	addi	s2,a0,376
    80002354:	02a79363          	bne	a5,a0,8000237a <exit+0x52>
    panic("init exiting");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f1850513          	addi	a0,a0,-232 # 80008270 <digits+0x230>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
      fileclose(f);
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	3ea080e7          	jalr	1002(ra) # 80004752 <fileclose>
      p->ofile[fd] = 0;
    80002370:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002374:	04a1                	addi	s1,s1,8
    80002376:	01248563          	beq	s1,s2,80002380 <exit+0x58>
    if (p->ofile[fd])
    8000237a:	6088                	ld	a0,0(s1)
    8000237c:	f575                	bnez	a0,80002368 <exit+0x40>
    8000237e:	bfdd                	j	80002374 <exit+0x4c>
  begin_op();
    80002380:	00002097          	auipc	ra,0x2
    80002384:	f06080e7          	jalr	-250(ra) # 80004286 <begin_op>
  iput(p->cwd);
    80002388:	1789b503          	ld	a0,376(s3)
    8000238c:	00001097          	auipc	ra,0x1
    80002390:	6e2080e7          	jalr	1762(ra) # 80003a6e <iput>
  end_op();
    80002394:	00002097          	auipc	ra,0x2
    80002398:	f72080e7          	jalr	-142(ra) # 80004306 <end_op>
  p->cwd = 0;
    8000239c:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	f1848493          	addi	s1,s1,-232 # 800112b8 <wait_lock>
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  reparent(p);
    800023b2:	854e                	mv	a0,s3
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	f1a080e7          	jalr	-230(ra) # 800022ce <reparent>
  wakeup(p->parent);
    800023bc:	0589b503          	ld	a0,88(s3)
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	e84080e7          	jalr	-380(ra) # 80002244 <wakeup>
  acquire(&p->lock);
    800023c8:	854e                	mv	a0,s3
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023d2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023d6:	4795                	li	a5,5
    800023d8:	00f9ae23          	sw	a5,28(s3)
  release(&wait_lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
  sched();
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	bac080e7          	jalr	-1108(ra) # 80001f92 <sched>
  panic("zombie exit");
    800023ee:	00006517          	auipc	a0,0x6
    800023f2:	e9250513          	addi	a0,a0,-366 # 80008280 <digits+0x240>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800023fe <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000240e:	0000f497          	auipc	s1,0xf
    80002412:	2c248493          	addi	s1,s1,706 # 800116d0 <proc>
    80002416:	00015997          	auipc	s3,0x15
    8000241a:	6ba98993          	addi	s3,s3,1722 # 80017ad0 <tickslock>
  {
    acquire(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002428:	589c                	lw	a5,48(s1)
    8000242a:	01278d63          	beq	a5,s2,80002444 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002438:	19048493          	addi	s1,s1,400
    8000243c:	ff3491e3          	bne	s1,s3,8000241e <kill+0x20>
  }
  return -1;
    80002440:	557d                	li	a0,-1
    80002442:	a015                	j	80002466 <kill+0x68>
      p->end_time = ticks;
    80002444:	00007797          	auipc	a5,0x7
    80002448:	bec7a783          	lw	a5,-1044(a5) # 80009030 <ticks>
    8000244c:	c0fc                	sw	a5,68(s1)
      p->killed = 1;
    8000244e:	4785                	li	a5,1
    80002450:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002452:	4cd8                	lw	a4,28(s1)
    80002454:	4789                	li	a5,2
    80002456:	00f70f63          	beq	a4,a5,80002474 <kill+0x76>
      release(&p->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
      return 0;
    80002464:	4501                	li	a0,0
}
    80002466:	70a2                	ld	ra,40(sp)
    80002468:	7402                	ld	s0,32(sp)
    8000246a:	64e2                	ld	s1,24(sp)
    8000246c:	6942                	ld	s2,16(sp)
    8000246e:	69a2                	ld	s3,8(sp)
    80002470:	6145                	addi	sp,sp,48
    80002472:	8082                	ret
        p->state = RUNNABLE;
    80002474:	478d                	li	a5,3
    80002476:	ccdc                	sw	a5,28(s1)
    80002478:	b7cd                	j	8000245a <kill+0x5c>

000000008000247a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247a:	7179                	addi	sp,sp,-48
    8000247c:	f406                	sd	ra,40(sp)
    8000247e:	f022                	sd	s0,32(sp)
    80002480:	ec26                	sd	s1,24(sp)
    80002482:	e84a                	sd	s2,16(sp)
    80002484:	e44e                	sd	s3,8(sp)
    80002486:	e052                	sd	s4,0(sp)
    80002488:	1800                	addi	s0,sp,48
    8000248a:	84aa                	mv	s1,a0
    8000248c:	892e                	mv	s2,a1
    8000248e:	89b2                	mv	s3,a2
    80002490:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	51e080e7          	jalr	1310(ra) # 800019b0 <myproc>
  if (user_dst)
    8000249a:	c08d                	beqz	s1,800024bc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000249c:	86d2                	mv	a3,s4
    8000249e:	864e                	mv	a2,s3
    800024a0:	85ca                	mv	a1,s2
    800024a2:	7d28                	ld	a0,120(a0)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	1ce080e7          	jalr	462(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6a02                	ld	s4,0(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    memmove((char *)dst, src, len);
    800024bc:	000a061b          	sext.w	a2,s4
    800024c0:	85ce                	mv	a1,s3
    800024c2:	854a                	mv	a0,s2
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	87c080e7          	jalr	-1924(ra) # 80000d40 <memmove>
    return 0;
    800024cc:	8526                	mv	a0,s1
    800024ce:	bff9                	j	800024ac <either_copyout+0x32>

00000000800024d0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	e052                	sd	s4,0(sp)
    800024de:	1800                	addi	s0,sp,48
    800024e0:	892a                	mv	s2,a0
    800024e2:	84ae                	mv	s1,a1
    800024e4:	89b2                	mv	s3,a2
    800024e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	4c8080e7          	jalr	1224(ra) # 800019b0 <myproc>
  if (user_src)
    800024f0:	c08d                	beqz	s1,80002512 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024f2:	86d2                	mv	a3,s4
    800024f4:	864e                	mv	a2,s3
    800024f6:	85ca                	mv	a1,s2
    800024f8:	7d28                	ld	a0,120(a0)
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	204080e7          	jalr	516(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6a02                	ld	s4,0(sp)
    8000250e:	6145                	addi	sp,sp,48
    80002510:	8082                	ret
    memmove(dst, (char *)src, len);
    80002512:	000a061b          	sext.w	a2,s4
    80002516:	85ce                	mv	a1,s3
    80002518:	854a                	mv	a0,s2
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	826080e7          	jalr	-2010(ra) # 80000d40 <memmove>
    return 0;
    80002522:	8526                	mv	a0,s1
    80002524:	bff9                	j	80002502 <either_copyin+0x32>

0000000080002526 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002526:	715d                	addi	sp,sp,-80
    80002528:	e486                	sd	ra,72(sp)
    8000252a:	e0a2                	sd	s0,64(sp)
    8000252c:	fc26                	sd	s1,56(sp)
    8000252e:	f84a                	sd	s2,48(sp)
    80002530:	f44e                	sd	s3,40(sp)
    80002532:	f052                	sd	s4,32(sp)
    80002534:	ec56                	sd	s5,24(sp)
    80002536:	e85a                	sd	s6,16(sp)
    80002538:	e45e                	sd	s7,8(sp)
    8000253a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000253c:	00006517          	auipc	a0,0x6
    80002540:	b8c50513          	addi	a0,a0,-1140 # 800080c8 <digits+0x88>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	044080e7          	jalr	68(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000254c:	0000f497          	auipc	s1,0xf
    80002550:	30448493          	addi	s1,s1,772 # 80011850 <proc+0x180>
    80002554:	00015917          	auipc	s2,0x15
    80002558:	6fc90913          	addi	s2,s2,1788 # 80017c50 <bcache+0x168>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000255e:	00006997          	auipc	s3,0x6
    80002562:	d3298993          	addi	s3,s3,-718 # 80008290 <digits+0x250>
#ifdef RR
    printf("%d %s %s", p->pid, state, p->name);
    80002566:	00006a97          	auipc	s5,0x6
    8000256a:	d32a8a93          	addi	s5,s5,-718 # 80008298 <digits+0x258>
#ifdef PBS
    int niceness = ((10 * (p->wake_time - p->sleep_time)) / ((p->wake_time - p->sleep_time) + p->run_time));
    int proc_dp = max(0, min(p->statprior - niceness + 5, 100)); // stores dp of the proc
    printf("%d %d %s %d %d %d", p->pid, proc_dp, state, p->total_runtime, ticks - p->ctime - p->total_runtime, p->notime);
#endif
    printf("\n");
    8000256e:	00006a17          	auipc	s4,0x6
    80002572:	b5aa0a13          	addi	s4,s4,-1190 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002576:	00006b97          	auipc	s7,0x6
    8000257a:	d5ab8b93          	addi	s7,s7,-678 # 800082d0 <states.1746>
    8000257e:	a00d                	j	800025a0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002580:	eb06a583          	lw	a1,-336(a3)
    80002584:	8556                	mv	a0,s5
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	002080e7          	jalr	2(ra) # 80000588 <printf>
    printf("\n");
    8000258e:	8552                	mv	a0,s4
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	ff8080e7          	jalr	-8(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002598:	19048493          	addi	s1,s1,400
    8000259c:	03248163          	beq	s1,s2,800025be <procdump+0x98>
    if (p->state == UNUSED)
    800025a0:	86a6                	mv	a3,s1
    800025a2:	e9c4a783          	lw	a5,-356(s1)
    800025a6:	dbed                	beqz	a5,80002598 <procdump+0x72>
      state = "???";
    800025a8:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	fcfb6be3          	bltu	s6,a5,80002580 <procdump+0x5a>
    800025ae:	1782                	slli	a5,a5,0x20
    800025b0:	9381                	srli	a5,a5,0x20
    800025b2:	078e                	slli	a5,a5,0x3
    800025b4:	97de                	add	a5,a5,s7
    800025b6:	6390                	ld	a2,0(a5)
    800025b8:	f661                	bnez	a2,80002580 <procdump+0x5a>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    800025bc:	b7d1                	j	80002580 <procdump+0x5a>
  }
}
    800025be:	60a6                	ld	ra,72(sp)
    800025c0:	6406                	ld	s0,64(sp)
    800025c2:	74e2                	ld	s1,56(sp)
    800025c4:	7942                	ld	s2,48(sp)
    800025c6:	79a2                	ld	s3,40(sp)
    800025c8:	7a02                	ld	s4,32(sp)
    800025ca:	6ae2                	ld	s5,24(sp)
    800025cc:	6b42                	ld	s6,16(sp)
    800025ce:	6ba2                	ld	s7,8(sp)
    800025d0:	6161                	addi	sp,sp,80
    800025d2:	8082                	ret

00000000800025d4 <trace>:
void trace(int tmask)
{
    800025d4:	1101                	addi	sp,sp,-32
    800025d6:	ec06                	sd	ra,24(sp)
    800025d8:	e822                	sd	s0,16(sp)
    800025da:	e426                	sd	s1,8(sp)
    800025dc:	1000                	addi	s0,sp,32
    800025de:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	3d0080e7          	jalr	976(ra) # 800019b0 <myproc>
  p->tmask = tmask;
    800025e8:	cd04                	sw	s1,24(a0)
}
    800025ea:	60e2                	ld	ra,24(sp)
    800025ec:	6442                	ld	s0,16(sp)
    800025ee:	64a2                	ld	s1,8(sp)
    800025f0:	6105                	addi	sp,sp,32
    800025f2:	8082                	ret

00000000800025f4 <set_priority>:

// void setpriority(int p){
//     StaticPrip = p;
// }

void set_priority(int prio , int pid, int* op){
    800025f4:	7139                	addi	sp,sp,-64
    800025f6:	fc06                	sd	ra,56(sp)
    800025f8:	f822                	sd	s0,48(sp)
    800025fa:	f426                	sd	s1,40(sp)
    800025fc:	f04a                	sd	s2,32(sp)
    800025fe:	ec4e                	sd	s3,24(sp)
    80002600:	e852                	sd	s4,16(sp)
    80002602:	e456                	sd	s5,8(sp)
    80002604:	0080                	addi	s0,sp,64
    80002606:	8aaa                	mv	s5,a0
    80002608:	892e                	mv	s2,a1
    8000260a:	8a32                	mv	s4,a2
    for (struct proc* p = proc; p < &proc[NPROC]; p++){
    8000260c:	0000f497          	auipc	s1,0xf
    80002610:	0c448493          	addi	s1,s1,196 # 800116d0 <proc>
    80002614:	00015997          	auipc	s3,0x15
    80002618:	4bc98993          	addi	s3,s3,1212 # 80017ad0 <tickslock>
    8000261c:	a809                	j	8000262e <set_priority+0x3a>
        acquire(&p->lock);
        *op = p->statprior;
        p->statprior = prio;
        release(&p->lock);
        if(*op < prio){
          yield();
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	a4a080e7          	jalr	-1462(ra) # 80002068 <yield>
    for (struct proc* p = proc; p < &proc[NPROC]; p++){
    80002626:	19048493          	addi	s1,s1,400
    8000262a:	03348963          	beq	s1,s3,8000265c <set_priority+0x68>
      if(p->pid == pid){
    8000262e:	589c                	lw	a5,48(s1)
    80002630:	ff279be3          	bne	a5,s2,80002626 <set_priority+0x32>
        acquire(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	5ae080e7          	jalr	1454(ra) # 80000be4 <acquire>
        *op = p->statprior;
    8000263e:	5c9c                	lw	a5,56(s1)
    80002640:	00fa2023          	sw	a5,0(s4)
        p->statprior = prio;
    80002644:	0354ac23          	sw	s5,56(s1)
        release(&p->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	64e080e7          	jalr	1614(ra) # 80000c98 <release>
        if(*op < prio){
    80002652:	000a2783          	lw	a5,0(s4)
    80002656:	fd57d8e3          	bge	a5,s5,80002626 <set_priority+0x32>
    8000265a:	b7d1                	j	8000261e <set_priority+0x2a>
        }
      }

    }
}
    8000265c:	70e2                	ld	ra,56(sp)
    8000265e:	7442                	ld	s0,48(sp)
    80002660:	74a2                	ld	s1,40(sp)
    80002662:	7902                	ld	s2,32(sp)
    80002664:	69e2                	ld	s3,24(sp)
    80002666:	6a42                	ld	s4,16(sp)
    80002668:	6aa2                	ld	s5,8(sp)
    8000266a:	6121                	addi	sp,sp,64
    8000266c:	8082                	ret

000000008000266e <updatetime>:

void updatetime(void)
{
    8000266e:	1141                	addi	sp,sp,-16
    80002670:	e422                	sd	s0,8(sp)
    80002672:	0800                	addi	s0,sp,16
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002674:	0000f797          	auipc	a5,0xf
    80002678:	05c78793          	addi	a5,a5,92 # 800116d0 <proc>
  {
    if (p->state == RUNNING)
    8000267c:	4611                	li	a2,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000267e:	00015697          	auipc	a3,0x15
    80002682:	45268693          	addi	a3,a3,1106 # 80017ad0 <tickslock>
    80002686:	a029                	j	80002690 <updatetime+0x22>
    80002688:	19078793          	addi	a5,a5,400
    8000268c:	00d78c63          	beq	a5,a3,800026a4 <updatetime+0x36>
    if (p->state == RUNNING)
    80002690:	4fd8                	lw	a4,28(a5)
    80002692:	fec71be3          	bne	a4,a2,80002688 <updatetime+0x1a>
    {
      p->run_time++;
    80002696:	5fd8                	lw	a4,60(a5)
    80002698:	2705                	addiw	a4,a4,1
    8000269a:	dfd8                	sw	a4,60(a5)
      p->total_runtime++;
    8000269c:	53f8                	lw	a4,100(a5)
    8000269e:	2705                	addiw	a4,a4,1
    800026a0:	d3f8                	sw	a4,100(a5)
    800026a2:	b7dd                	j	80002688 <updatetime+0x1a>
    }
  }
}
    800026a4:	6422                	ld	s0,8(sp)
    800026a6:	0141                	addi	sp,sp,16
    800026a8:	8082                	ret

00000000800026aa <max>:

int max(int a, int b)
{
    800026aa:	1141                	addi	sp,sp,-16
    800026ac:	e422                	sd	s0,8(sp)
    800026ae:	0800                	addi	s0,sp,16
  return a > b ? a : b;
    800026b0:	87ae                	mv	a5,a1
    800026b2:	00a5d363          	bge	a1,a0,800026b8 <max+0xe>
    800026b6:	87aa                	mv	a5,a0
}
    800026b8:	0007851b          	sext.w	a0,a5
    800026bc:	6422                	ld	s0,8(sp)
    800026be:	0141                	addi	sp,sp,16
    800026c0:	8082                	ret

00000000800026c2 <min>:
int min(int a, int b)
{
    800026c2:	1141                	addi	sp,sp,-16
    800026c4:	e422                	sd	s0,8(sp)
    800026c6:	0800                	addi	s0,sp,16
  return a < b ? a : b;
    800026c8:	87ae                	mv	a5,a1
    800026ca:	00b55363          	bge	a0,a1,800026d0 <min+0xe>
    800026ce:	87aa                	mv	a5,a0
}
    800026d0:	0007851b          	sext.w	a0,a5
    800026d4:	6422                	ld	s0,8(sp)
    800026d6:	0141                	addi	sp,sp,16
    800026d8:	8082                	ret

00000000800026da <swtch>:
    800026da:	00153023          	sd	ra,0(a0)
    800026de:	00253423          	sd	sp,8(a0)
    800026e2:	e900                	sd	s0,16(a0)
    800026e4:	ed04                	sd	s1,24(a0)
    800026e6:	03253023          	sd	s2,32(a0)
    800026ea:	03353423          	sd	s3,40(a0)
    800026ee:	03453823          	sd	s4,48(a0)
    800026f2:	03553c23          	sd	s5,56(a0)
    800026f6:	05653023          	sd	s6,64(a0)
    800026fa:	05753423          	sd	s7,72(a0)
    800026fe:	05853823          	sd	s8,80(a0)
    80002702:	05953c23          	sd	s9,88(a0)
    80002706:	07a53023          	sd	s10,96(a0)
    8000270a:	07b53423          	sd	s11,104(a0)
    8000270e:	0005b083          	ld	ra,0(a1)
    80002712:	0085b103          	ld	sp,8(a1)
    80002716:	6980                	ld	s0,16(a1)
    80002718:	6d84                	ld	s1,24(a1)
    8000271a:	0205b903          	ld	s2,32(a1)
    8000271e:	0285b983          	ld	s3,40(a1)
    80002722:	0305ba03          	ld	s4,48(a1)
    80002726:	0385ba83          	ld	s5,56(a1)
    8000272a:	0405bb03          	ld	s6,64(a1)
    8000272e:	0485bb83          	ld	s7,72(a1)
    80002732:	0505bc03          	ld	s8,80(a1)
    80002736:	0585bc83          	ld	s9,88(a1)
    8000273a:	0605bd03          	ld	s10,96(a1)
    8000273e:	0685bd83          	ld	s11,104(a1)
    80002742:	8082                	ret

0000000080002744 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002744:	1141                	addi	sp,sp,-16
    80002746:	e406                	sd	ra,8(sp)
    80002748:	e022                	sd	s0,0(sp)
    8000274a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000274c:	00006597          	auipc	a1,0x6
    80002750:	bb458593          	addi	a1,a1,-1100 # 80008300 <states.1746+0x30>
    80002754:	00015517          	auipc	a0,0x15
    80002758:	37c50513          	addi	a0,a0,892 # 80017ad0 <tickslock>
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	3f8080e7          	jalr	1016(ra) # 80000b54 <initlock>
}
    80002764:	60a2                	ld	ra,8(sp)
    80002766:	6402                	ld	s0,0(sp)
    80002768:	0141                	addi	sp,sp,16
    8000276a:	8082                	ret

000000008000276c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000276c:	1141                	addi	sp,sp,-16
    8000276e:	e422                	sd	s0,8(sp)
    80002770:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002772:	00003797          	auipc	a5,0x3
    80002776:	5fe78793          	addi	a5,a5,1534 # 80005d70 <kernelvec>
    8000277a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000277e:	6422                	ld	s0,8(sp)
    80002780:	0141                	addi	sp,sp,16
    80002782:	8082                	ret

0000000080002784 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002784:	1141                	addi	sp,sp,-16
    80002786:	e406                	sd	ra,8(sp)
    80002788:	e022                	sd	s0,0(sp)
    8000278a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	224080e7          	jalr	548(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002794:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002798:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000279e:	00005617          	auipc	a2,0x5
    800027a2:	86260613          	addi	a2,a2,-1950 # 80007000 <_trampoline>
    800027a6:	00005697          	auipc	a3,0x5
    800027aa:	85a68693          	addi	a3,a3,-1958 # 80007000 <_trampoline>
    800027ae:	8e91                	sub	a3,a3,a2
    800027b0:	040007b7          	lui	a5,0x4000
    800027b4:	17fd                	addi	a5,a5,-1
    800027b6:	07b2                	slli	a5,a5,0xc
    800027b8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ba:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027be:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c0:	180026f3          	csrr	a3,satp
    800027c4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027c6:	6158                	ld	a4,128(a0)
    800027c8:	7534                	ld	a3,104(a0)
    800027ca:	6585                	lui	a1,0x1
    800027cc:	96ae                	add	a3,a3,a1
    800027ce:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d0:	6158                	ld	a4,128(a0)
    800027d2:	00000697          	auipc	a3,0x0
    800027d6:	14068693          	addi	a3,a3,320 # 80002912 <usertrap>
    800027da:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027dc:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027de:	8692                	mv	a3,tp
    800027e0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027e6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ea:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ee:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f2:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027f4:	6f18                	ld	a4,24(a4)
    800027f6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027fa:	7d2c                	ld	a1,120(a0)
    800027fc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027fe:	00005717          	auipc	a4,0x5
    80002802:	89270713          	addi	a4,a4,-1902 # 80007090 <userret>
    80002806:	8f11                	sub	a4,a4,a2
    80002808:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000280a:	577d                	li	a4,-1
    8000280c:	177e                	slli	a4,a4,0x3f
    8000280e:	8dd9                	or	a1,a1,a4
    80002810:	02000537          	lui	a0,0x2000
    80002814:	157d                	addi	a0,a0,-1
    80002816:	0536                	slli	a0,a0,0xd
    80002818:	9782                	jalr	a5
}
    8000281a:	60a2                	ld	ra,8(sp)
    8000281c:	6402                	ld	s0,0(sp)
    8000281e:	0141                	addi	sp,sp,16
    80002820:	8082                	ret

0000000080002822 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002822:	1101                	addi	sp,sp,-32
    80002824:	ec06                	sd	ra,24(sp)
    80002826:	e822                	sd	s0,16(sp)
    80002828:	e426                	sd	s1,8(sp)
    8000282a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000282c:	00015497          	auipc	s1,0x15
    80002830:	2a448493          	addi	s1,s1,676 # 80017ad0 <tickslock>
    80002834:	8526                	mv	a0,s1
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	3ae080e7          	jalr	942(ra) # 80000be4 <acquire>
  ticks++;
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	7f250513          	addi	a0,a0,2034 # 80009030 <ticks>
    80002846:	411c                	lw	a5,0(a0)
    80002848:	2785                	addiw	a5,a5,1
    8000284a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	9f8080e7          	jalr	-1544(ra) # 80002244 <wakeup>
  release(&tickslock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	442080e7          	jalr	1090(ra) # 80000c98 <release>
  updatetime();
    8000285e:	00000097          	auipc	ra,0x0
    80002862:	e10080e7          	jalr	-496(ra) # 8000266e <updatetime>
}
    80002866:	60e2                	ld	ra,24(sp)
    80002868:	6442                	ld	s0,16(sp)
    8000286a:	64a2                	ld	s1,8(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret

0000000080002870 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002870:	1101                	addi	sp,sp,-32
    80002872:	ec06                	sd	ra,24(sp)
    80002874:	e822                	sd	s0,16(sp)
    80002876:	e426                	sd	s1,8(sp)
    80002878:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000287e:	00074d63          	bltz	a4,80002898 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002882:	57fd                	li	a5,-1
    80002884:	17fe                	slli	a5,a5,0x3f
    80002886:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002888:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000288a:	06f70363          	beq	a4,a5,800028f0 <devintr+0x80>
  }
}
    8000288e:	60e2                	ld	ra,24(sp)
    80002890:	6442                	ld	s0,16(sp)
    80002892:	64a2                	ld	s1,8(sp)
    80002894:	6105                	addi	sp,sp,32
    80002896:	8082                	ret
     (scause & 0xff) == 9){
    80002898:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000289c:	46a5                	li	a3,9
    8000289e:	fed792e3          	bne	a5,a3,80002882 <devintr+0x12>
    int irq = plic_claim();
    800028a2:	00003097          	auipc	ra,0x3
    800028a6:	5d6080e7          	jalr	1494(ra) # 80005e78 <plic_claim>
    800028aa:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ac:	47a9                	li	a5,10
    800028ae:	02f50763          	beq	a0,a5,800028dc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028b2:	4785                	li	a5,1
    800028b4:	02f50963          	beq	a0,a5,800028e6 <devintr+0x76>
    return 1;
    800028b8:	4505                	li	a0,1
    } else if(irq){
    800028ba:	d8f1                	beqz	s1,8000288e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028bc:	85a6                	mv	a1,s1
    800028be:	00006517          	auipc	a0,0x6
    800028c2:	a4a50513          	addi	a0,a0,-1462 # 80008308 <states.1746+0x38>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	cc2080e7          	jalr	-830(ra) # 80000588 <printf>
      plic_complete(irq);
    800028ce:	8526                	mv	a0,s1
    800028d0:	00003097          	auipc	ra,0x3
    800028d4:	5cc080e7          	jalr	1484(ra) # 80005e9c <plic_complete>
    return 1;
    800028d8:	4505                	li	a0,1
    800028da:	bf55                	j	8000288e <devintr+0x1e>
      uartintr();
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	0cc080e7          	jalr	204(ra) # 800009a8 <uartintr>
    800028e4:	b7ed                	j	800028ce <devintr+0x5e>
      virtio_disk_intr();
    800028e6:	00004097          	auipc	ra,0x4
    800028ea:	a96080e7          	jalr	-1386(ra) # 8000637c <virtio_disk_intr>
    800028ee:	b7c5                	j	800028ce <devintr+0x5e>
    if(cpuid() == 0){
    800028f0:	fffff097          	auipc	ra,0xfffff
    800028f4:	094080e7          	jalr	148(ra) # 80001984 <cpuid>
    800028f8:	c901                	beqz	a0,80002908 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028fa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002900:	14479073          	csrw	sip,a5
    return 2;
    80002904:	4509                	li	a0,2
    80002906:	b761                	j	8000288e <devintr+0x1e>
      clockintr();
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	f1a080e7          	jalr	-230(ra) # 80002822 <clockintr>
    80002910:	b7ed                	j	800028fa <devintr+0x8a>

0000000080002912 <usertrap>:
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	e04a                	sd	s2,0(sp)
    8000291c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002922:	1007f793          	andi	a5,a5,256
    80002926:	e3ad                	bnez	a5,80002988 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002928:	00003797          	auipc	a5,0x3
    8000292c:	44878793          	addi	a5,a5,1096 # 80005d70 <kernelvec>
    80002930:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	07c080e7          	jalr	124(ra) # 800019b0 <myproc>
    8000293c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000293e:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002940:	14102773          	csrr	a4,sepc
    80002944:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002946:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000294a:	47a1                	li	a5,8
    8000294c:	04f71c63          	bne	a4,a5,800029a4 <usertrap+0x92>
    if(p->killed)
    80002950:	551c                	lw	a5,40(a0)
    80002952:	e3b9                	bnez	a5,80002998 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002954:	60d8                	ld	a4,128(s1)
    80002956:	6f1c                	ld	a5,24(a4)
    80002958:	0791                	addi	a5,a5,4
    8000295a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002960:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002964:	10079073          	csrw	sstatus,a5
    syscall();
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	2e0080e7          	jalr	736(ra) # 80002c48 <syscall>
  if(p->killed)
    80002970:	549c                	lw	a5,40(s1)
    80002972:	ebc1                	bnez	a5,80002a02 <usertrap+0xf0>
  usertrapret();
    80002974:	00000097          	auipc	ra,0x0
    80002978:	e10080e7          	jalr	-496(ra) # 80002784 <usertrapret>
}
    8000297c:	60e2                	ld	ra,24(sp)
    8000297e:	6442                	ld	s0,16(sp)
    80002980:	64a2                	ld	s1,8(sp)
    80002982:	6902                	ld	s2,0(sp)
    80002984:	6105                	addi	sp,sp,32
    80002986:	8082                	ret
    panic("usertrap: not from user mode");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	9a050513          	addi	a0,a0,-1632 # 80008328 <states.1746+0x58>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>
      exit(-1);
    80002998:	557d                	li	a0,-1
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	98e080e7          	jalr	-1650(ra) # 80002328 <exit>
    800029a2:	bf4d                	j	80002954 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	ecc080e7          	jalr	-308(ra) # 80002870 <devintr>
    800029ac:	892a                	mv	s2,a0
    800029ae:	c501                	beqz	a0,800029b6 <usertrap+0xa4>
  if(p->killed)
    800029b0:	549c                	lw	a5,40(s1)
    800029b2:	c3a1                	beqz	a5,800029f2 <usertrap+0xe0>
    800029b4:	a815                	j	800029e8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ba:	5890                	lw	a2,48(s1)
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	98c50513          	addi	a0,a0,-1652 # 80008348 <states.1746+0x78>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc4080e7          	jalr	-1084(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029cc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9a450513          	addi	a0,a0,-1628 # 80008378 <states.1746+0xa8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bac080e7          	jalr	-1108(ra) # 80000588 <printf>
    p->killed = 1;
    800029e4:	4785                	li	a5,1
    800029e6:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029e8:	557d                	li	a0,-1
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	93e080e7          	jalr	-1730(ra) # 80002328 <exit>
    if(which_dev == 2)
    800029f2:	4789                	li	a5,2
    800029f4:	f8f910e3          	bne	s2,a5,80002974 <usertrap+0x62>
      yield();
    800029f8:	fffff097          	auipc	ra,0xfffff
    800029fc:	670080e7          	jalr	1648(ra) # 80002068 <yield>
    80002a00:	bf95                	j	80002974 <usertrap+0x62>
  int which_dev = 0;
    80002a02:	4901                	li	s2,0
    80002a04:	b7d5                	j	800029e8 <usertrap+0xd6>

0000000080002a06 <kerneltrap>:
{
    80002a06:	7179                	addi	sp,sp,-48
    80002a08:	f406                	sd	ra,40(sp)
    80002a0a:	f022                	sd	s0,32(sp)
    80002a0c:	ec26                	sd	s1,24(sp)
    80002a0e:	e84a                	sd	s2,16(sp)
    80002a10:	e44e                	sd	s3,8(sp)
    80002a12:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a20:	1004f793          	andi	a5,s1,256
    80002a24:	cb85                	beqz	a5,80002a54 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a2a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a2c:	ef85                	bnez	a5,80002a64 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	e42080e7          	jalr	-446(ra) # 80002870 <devintr>
    80002a36:	cd1d                	beqz	a0,80002a74 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a38:	4789                	li	a5,2
    80002a3a:	06f50a63          	beq	a0,a5,80002aae <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a3e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a42:	10049073          	csrw	sstatus,s1
}
    80002a46:	70a2                	ld	ra,40(sp)
    80002a48:	7402                	ld	s0,32(sp)
    80002a4a:	64e2                	ld	s1,24(sp)
    80002a4c:	6942                	ld	s2,16(sp)
    80002a4e:	69a2                	ld	s3,8(sp)
    80002a50:	6145                	addi	sp,sp,48
    80002a52:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	94450513          	addi	a0,a0,-1724 # 80008398 <states.1746+0xc8>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	95c50513          	addi	a0,a0,-1700 # 800083c0 <states.1746+0xf0>
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	ad2080e7          	jalr	-1326(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a74:	85ce                	mv	a1,s3
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	96a50513          	addi	a0,a0,-1686 # 800083e0 <states.1746+0x110>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b0a080e7          	jalr	-1270(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a86:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	96250513          	addi	a0,a0,-1694 # 800083f0 <states.1746+0x120>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	af2080e7          	jalr	-1294(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	96a50513          	addi	a0,a0,-1686 # 80008408 <states.1746+0x138>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	a98080e7          	jalr	-1384(ra) # 8000053e <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	f02080e7          	jalr	-254(ra) # 800019b0 <myproc>
    80002ab6:	d541                	beqz	a0,80002a3e <kerneltrap+0x38>
    80002ab8:	fffff097          	auipc	ra,0xfffff
    80002abc:	ef8080e7          	jalr	-264(ra) # 800019b0 <myproc>
    80002ac0:	4d58                	lw	a4,28(a0)
    80002ac2:	4791                	li	a5,4
    80002ac4:	f6f71de3          	bne	a4,a5,80002a3e <kerneltrap+0x38>
      yield();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	5a0080e7          	jalr	1440(ra) # 80002068 <yield>
    80002ad0:	b7bd                	j	80002a3e <kerneltrap+0x38>

0000000080002ad2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ad2:	1101                	addi	sp,sp,-32
    80002ad4:	ec06                	sd	ra,24(sp)
    80002ad6:	e822                	sd	s0,16(sp)
    80002ad8:	e426                	sd	s1,8(sp)
    80002ada:	1000                	addi	s0,sp,32
    80002adc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	ed2080e7          	jalr	-302(ra) # 800019b0 <myproc>
  switch (n)
    80002ae6:	4795                	li	a5,5
    80002ae8:	0497e163          	bltu	a5,s1,80002b2a <argraw+0x58>
    80002aec:	048a                	slli	s1,s1,0x2
    80002aee:	00006717          	auipc	a4,0x6
    80002af2:	a2270713          	addi	a4,a4,-1502 # 80008510 <states.1746+0x240>
    80002af6:	94ba                	add	s1,s1,a4
    80002af8:	409c                	lw	a5,0(s1)
    80002afa:	97ba                	add	a5,a5,a4
    80002afc:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002afe:	615c                	ld	a5,128(a0)
    80002b00:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6105                	addi	sp,sp,32
    80002b0a:	8082                	ret
    return p->trapframe->a1;
    80002b0c:	615c                	ld	a5,128(a0)
    80002b0e:	7fa8                	ld	a0,120(a5)
    80002b10:	bfcd                	j	80002b02 <argraw+0x30>
    return p->trapframe->a2;
    80002b12:	615c                	ld	a5,128(a0)
    80002b14:	63c8                	ld	a0,128(a5)
    80002b16:	b7f5                	j	80002b02 <argraw+0x30>
    return p->trapframe->a3;
    80002b18:	615c                	ld	a5,128(a0)
    80002b1a:	67c8                	ld	a0,136(a5)
    80002b1c:	b7dd                	j	80002b02 <argraw+0x30>
    return p->trapframe->a4;
    80002b1e:	615c                	ld	a5,128(a0)
    80002b20:	6bc8                	ld	a0,144(a5)
    80002b22:	b7c5                	j	80002b02 <argraw+0x30>
    return p->trapframe->a5;
    80002b24:	615c                	ld	a5,128(a0)
    80002b26:	6fc8                	ld	a0,152(a5)
    80002b28:	bfe9                	j	80002b02 <argraw+0x30>
  panic("argraw");
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	8ee50513          	addi	a0,a0,-1810 # 80008418 <states.1746+0x148>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a0c080e7          	jalr	-1524(ra) # 8000053e <panic>

0000000080002b3a <fetchaddr>:
{
    80002b3a:	1101                	addi	sp,sp,-32
    80002b3c:	ec06                	sd	ra,24(sp)
    80002b3e:	e822                	sd	s0,16(sp)
    80002b40:	e426                	sd	s1,8(sp)
    80002b42:	e04a                	sd	s2,0(sp)
    80002b44:	1000                	addi	s0,sp,32
    80002b46:	84aa                	mv	s1,a0
    80002b48:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	e66080e7          	jalr	-410(ra) # 800019b0 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002b52:	793c                	ld	a5,112(a0)
    80002b54:	02f4f863          	bgeu	s1,a5,80002b84 <fetchaddr+0x4a>
    80002b58:	00848713          	addi	a4,s1,8
    80002b5c:	02e7e663          	bltu	a5,a4,80002b88 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b60:	46a1                	li	a3,8
    80002b62:	8626                	mv	a2,s1
    80002b64:	85ca                	mv	a1,s2
    80002b66:	7d28                	ld	a0,120(a0)
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	b96080e7          	jalr	-1130(ra) # 800016fe <copyin>
    80002b70:	00a03533          	snez	a0,a0
    80002b74:	40a00533          	neg	a0,a0
}
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6902                	ld	s2,0(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
    return -1;
    80002b84:	557d                	li	a0,-1
    80002b86:	bfcd                	j	80002b78 <fetchaddr+0x3e>
    80002b88:	557d                	li	a0,-1
    80002b8a:	b7fd                	j	80002b78 <fetchaddr+0x3e>

0000000080002b8c <fetchstr>:
{
    80002b8c:	7179                	addi	sp,sp,-48
    80002b8e:	f406                	sd	ra,40(sp)
    80002b90:	f022                	sd	s0,32(sp)
    80002b92:	ec26                	sd	s1,24(sp)
    80002b94:	e84a                	sd	s2,16(sp)
    80002b96:	e44e                	sd	s3,8(sp)
    80002b98:	1800                	addi	s0,sp,48
    80002b9a:	892a                	mv	s2,a0
    80002b9c:	84ae                	mv	s1,a1
    80002b9e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	e10080e7          	jalr	-496(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ba8:	86ce                	mv	a3,s3
    80002baa:	864a                	mv	a2,s2
    80002bac:	85a6                	mv	a1,s1
    80002bae:	7d28                	ld	a0,120(a0)
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	bda080e7          	jalr	-1062(ra) # 8000178a <copyinstr>
  if (err < 0)
    80002bb8:	00054763          	bltz	a0,80002bc6 <fetchstr+0x3a>
  return strlen(buf);
    80002bbc:	8526                	mv	a0,s1
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	2a6080e7          	jalr	678(ra) # 80000e64 <strlen>
}
    80002bc6:	70a2                	ld	ra,40(sp)
    80002bc8:	7402                	ld	s0,32(sp)
    80002bca:	64e2                	ld	s1,24(sp)
    80002bcc:	6942                	ld	s2,16(sp)
    80002bce:	69a2                	ld	s3,8(sp)
    80002bd0:	6145                	addi	sp,sp,48
    80002bd2:	8082                	ret

0000000080002bd4 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	1000                	addi	s0,sp,32
    80002bde:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	ef2080e7          	jalr	-270(ra) # 80002ad2 <argraw>
    80002be8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bea:	4501                	li	a0,0
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	64a2                	ld	s1,8(sp)
    80002bf2:	6105                	addi	sp,sp,32
    80002bf4:	8082                	ret

0000000080002bf6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002bf6:	1101                	addi	sp,sp,-32
    80002bf8:	ec06                	sd	ra,24(sp)
    80002bfa:	e822                	sd	s0,16(sp)
    80002bfc:	e426                	sd	s1,8(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	ed0080e7          	jalr	-304(ra) # 80002ad2 <argraw>
    80002c0a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c0c:	4501                	li	a0,0
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	64a2                	ld	s1,8(sp)
    80002c14:	6105                	addi	sp,sp,32
    80002c16:	8082                	ret

0000000080002c18 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	e04a                	sd	s2,0(sp)
    80002c22:	1000                	addi	s0,sp,32
    80002c24:	84ae                	mv	s1,a1
    80002c26:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	eaa080e7          	jalr	-342(ra) # 80002ad2 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c30:	864a                	mv	a2,s2
    80002c32:	85a6                	mv	a1,s1
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	f58080e7          	jalr	-168(ra) # 80002b8c <fetchstr>
}
    80002c3c:	60e2                	ld	ra,24(sp)
    80002c3e:	6442                	ld	s0,16(sp)
    80002c40:	64a2                	ld	s1,8(sp)
    80002c42:	6902                	ld	s2,0(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret

0000000080002c48 <syscall>:
    [SYS_trace]
    { 1, "trace" },
};

void syscall(void)
{
    80002c48:	715d                	addi	sp,sp,-80
    80002c4a:	e486                	sd	ra,72(sp)
    80002c4c:	e0a2                	sd	s0,64(sp)
    80002c4e:	fc26                	sd	s1,56(sp)
    80002c50:	f84a                	sd	s2,48(sp)
    80002c52:	f44e                	sd	s3,40(sp)
    80002c54:	f052                	sd	s4,32(sp)
    80002c56:	ec56                	sd	s5,24(sp)
    80002c58:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    80002c5a:	fffff097          	auipc	ra,0xfffff
    80002c5e:	d56080e7          	jalr	-682(ra) # 800019b0 <myproc>
    80002c62:	84aa                	mv	s1,a0
  int tmask, ok;
  num = p->trapframe->a7;
    80002c64:	615c                	ld	a5,128(a0)
    80002c66:	77dc                	ld	a5,168(a5)
    80002c68:	00078a1b          	sext.w	s4,a5
  tmask = p->tmask;
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c6c:	37fd                	addiw	a5,a5,-1
    80002c6e:	4759                	li	a4,22
    80002c70:	10f76063          	bltu	a4,a5,80002d70 <syscall+0x128>
    80002c74:	003a1713          	slli	a4,s4,0x3
    80002c78:	00006797          	auipc	a5,0x6
    80002c7c:	8b078793          	addi	a5,a5,-1872 # 80008528 <syscalls>
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	0007b983          	ld	s3,0(a5)
    80002c86:	0e098563          	beqz	s3,80002d70 <syscall+0x128>
  tmask = p->tmask;
    80002c8a:	01852903          	lw	s2,24(a0)
  {
    argint(0, &ok);
    80002c8e:	fbc40593          	addi	a1,s0,-68
    80002c92:	4501                	li	a0,0
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	f40080e7          	jalr	-192(ra) # 80002bd4 <argint>
    p->trapframe->a0 = syscalls[num]();
    80002c9c:	0804ba83          	ld	s5,128(s1)
    80002ca0:	9982                	jalr	s3
    80002ca2:	06aab823          	sd	a0,112(s5)
    if (tmask & (1 << num))
    80002ca6:	4149593b          	sraw	s2,s2,s4
    80002caa:	00197913          	andi	s2,s2,1
    80002cae:	0e090063          	beqz	s2,80002d8e <syscall+0x146>
    {
      printf("\n%d: syscall %s (", p->pid, syscall_infos[num].name);
    80002cb2:	004a1793          	slli	a5,s4,0x4
    80002cb6:	00006997          	auipc	s3,0x6
    80002cba:	c9298993          	addi	s3,s3,-878 # 80008948 <syscall_infos>
    80002cbe:	99be                	add	s3,s3,a5
    80002cc0:	0089b603          	ld	a2,8(s3)
    80002cc4:	588c                	lw	a1,48(s1)
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	75a50513          	addi	a0,a0,1882 # 80008420 <states.1746+0x150>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8ba080e7          	jalr	-1862(ra) # 80000588 <printf>
      if(syscall_infos[num].argnum == 1)
    80002cd6:	0009a703          	lw	a4,0(s3)
    80002cda:	4785                	li	a5,1
    80002cdc:	06f70f63          	beq	a4,a5,80002d5a <syscall+0x112>
      {
        printf("%d ",ok);
      }
      else
      {
        printf("%d ",ok);
    80002ce0:	fbc42583          	lw	a1,-68(s0)
    80002ce4:	00005517          	auipc	a0,0x5
    80002ce8:	75450513          	addi	a0,a0,1876 # 80008438 <states.1746+0x168>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	89c080e7          	jalr	-1892(ra) # 80000588 <printf>
        for (int i = 1; i < syscall_infos[num].argnum; i++){ int n; argint(i,&n);printf("%d ",n);}
    80002cf4:	004a1713          	slli	a4,s4,0x4
    80002cf8:	00006797          	auipc	a5,0x6
    80002cfc:	c5078793          	addi	a5,a5,-944 # 80008948 <syscall_infos>
    80002d00:	97ba                	add	a5,a5,a4
    80002d02:	4398                	lw	a4,0(a5)
    80002d04:	4785                	li	a5,1
    80002d06:	02e7df63          	bge	a5,a4,80002d44 <syscall+0xfc>
    80002d0a:	00005997          	auipc	s3,0x5
    80002d0e:	72e98993          	addi	s3,s3,1838 # 80008438 <states.1746+0x168>
    80002d12:	0a12                	slli	s4,s4,0x4
    80002d14:	00006797          	auipc	a5,0x6
    80002d18:	c3478793          	addi	a5,a5,-972 # 80008948 <syscall_infos>
    80002d1c:	9a3e                	add	s4,s4,a5
    80002d1e:	fb840593          	addi	a1,s0,-72
    80002d22:	854a                	mv	a0,s2
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	eb0080e7          	jalr	-336(ra) # 80002bd4 <argint>
    80002d2c:	fb842583          	lw	a1,-72(s0)
    80002d30:	854e                	mv	a0,s3
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	856080e7          	jalr	-1962(ra) # 80000588 <printf>
    80002d3a:	2905                	addiw	s2,s2,1
    80002d3c:	000a2783          	lw	a5,0(s4)
    80002d40:	fcf94fe3          	blt	s2,a5,80002d1e <syscall+0xd6>
      }
      printf(") %d\n", p->trapframe->a0);
    80002d44:	60dc                	ld	a5,128(s1)
    80002d46:	7bac                	ld	a1,112(a5)
    80002d48:	00005517          	auipc	a0,0x5
    80002d4c:	6f850513          	addi	a0,a0,1784 # 80008440 <states.1746+0x170>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	838080e7          	jalr	-1992(ra) # 80000588 <printf>
    80002d58:	a81d                	j	80002d8e <syscall+0x146>
        printf("%d ",ok);
    80002d5a:	fbc42583          	lw	a1,-68(s0)
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	6da50513          	addi	a0,a0,1754 # 80008438 <states.1746+0x168>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	822080e7          	jalr	-2014(ra) # 80000588 <printf>
    80002d6e:	bfd9                	j	80002d44 <syscall+0xfc>
    }
  }
  else
  {
    printf("%d %s: invalid sys call %d\n",
    80002d70:	86d2                	mv	a3,s4
    80002d72:	18048613          	addi	a2,s1,384
    80002d76:	588c                	lw	a1,48(s1)
    80002d78:	00005517          	auipc	a0,0x5
    80002d7c:	6d050513          	addi	a0,a0,1744 # 80008448 <states.1746+0x178>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	808080e7          	jalr	-2040(ra) # 80000588 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d88:	60dc                	ld	a5,128(s1)
    80002d8a:	577d                	li	a4,-1
    80002d8c:	fbb8                	sd	a4,112(a5)
  }
}
    80002d8e:	60a6                	ld	ra,72(sp)
    80002d90:	6406                	ld	s0,64(sp)
    80002d92:	74e2                	ld	s1,56(sp)
    80002d94:	7942                	ld	s2,48(sp)
    80002d96:	79a2                	ld	s3,40(sp)
    80002d98:	7a02                	ld	s4,32(sp)
    80002d9a:	6ae2                	ld	s5,24(sp)
    80002d9c:	6161                	addi	sp,sp,80
    80002d9e:	8082                	ret

0000000080002da0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002da8:	fec40593          	addi	a1,s0,-20
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e26080e7          	jalr	-474(ra) # 80002bd4 <argint>
    return -1;
    80002db6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db8:	00054963          	bltz	a0,80002dca <sys_exit+0x2a>
  exit(n);
    80002dbc:	fec42503          	lw	a0,-20(s0)
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	568080e7          	jalr	1384(ra) # 80002328 <exit>
  return 0;  // not reached
    80002dc8:	4781                	li	a5,0
}
    80002dca:	853e                	mv	a0,a5
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dd4:	1141                	addi	sp,sp,-16
    80002dd6:	e406                	sd	ra,8(sp)
    80002dd8:	e022                	sd	s0,0(sp)
    80002dda:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	bd4080e7          	jalr	-1068(ra) # 800019b0 <myproc>
}
    80002de4:	5908                	lw	a0,48(a0)
    80002de6:	60a2                	ld	ra,8(sp)
    80002de8:	6402                	ld	s0,0(sp)
    80002dea:	0141                	addi	sp,sp,16
    80002dec:	8082                	ret

0000000080002dee <sys_fork>:

uint64
sys_fork(void)
{
    80002dee:	1141                	addi	sp,sp,-16
    80002df0:	e406                	sd	ra,8(sp)
    80002df2:	e022                	sd	s0,0(sp)
    80002df4:	0800                	addi	s0,sp,16
  return fork();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	fa8080e7          	jalr	-88(ra) # 80001d9e <fork>
}
    80002dfe:	60a2                	ld	ra,8(sp)
    80002e00:	6402                	ld	s0,0(sp)
    80002e02:	0141                	addi	sp,sp,16
    80002e04:	8082                	ret

0000000080002e06 <sys_wait>:

uint64
sys_wait(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e0e:	fe840593          	addi	a1,s0,-24
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	de2080e7          	jalr	-542(ra) # 80002bf6 <argaddr>
    80002e1c:	87aa                	mv	a5,a0
    return -1;
    80002e1e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e20:	0007c863          	bltz	a5,80002e30 <sys_wait+0x2a>
  return wait(p);
    80002e24:	fe843503          	ld	a0,-24(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	2f4080e7          	jalr	756(ra) # 8000211c <wait>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e38:	7179                	addi	sp,sp,-48
    80002e3a:	f406                	sd	ra,40(sp)
    80002e3c:	f022                	sd	s0,32(sp)
    80002e3e:	ec26                	sd	s1,24(sp)
    80002e40:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e42:	fdc40593          	addi	a1,s0,-36
    80002e46:	4501                	li	a0,0
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	d8c080e7          	jalr	-628(ra) # 80002bd4 <argint>
    80002e50:	87aa                	mv	a5,a0
    return -1;
    80002e52:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e54:	0207c063          	bltz	a5,80002e74 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	b58080e7          	jalr	-1192(ra) # 800019b0 <myproc>
    80002e60:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80002e62:	fdc42503          	lw	a0,-36(s0)
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	ec4080e7          	jalr	-316(ra) # 80001d2a <growproc>
    80002e6e:	00054863          	bltz	a0,80002e7e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e72:	8526                	mv	a0,s1
}
    80002e74:	70a2                	ld	ra,40(sp)
    80002e76:	7402                	ld	s0,32(sp)
    80002e78:	64e2                	ld	s1,24(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    return -1;
    80002e7e:	557d                	li	a0,-1
    80002e80:	bfd5                	j	80002e74 <sys_sbrk+0x3c>

0000000080002e82 <sys_trace>:

uint64
sys_trace(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e8a:	fec40593          	addi	a1,s0,-20
    80002e8e:	4501                	li	a0,0
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	d44080e7          	jalr	-700(ra) # 80002bd4 <argint>
  trace(n);
    80002e98:	fec42503          	lw	a0,-20(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	738080e7          	jalr	1848(ra) # 800025d4 <trace>
  return 0;
}
    80002ea4:	4501                	li	a0,0
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	6105                	addi	sp,sp,32
    80002eac:	8082                	ret

0000000080002eae <sys_set_priority>:

uint64
sys_set_priority(void){
    80002eae:	1101                	addi	sp,sp,-32
    80002eb0:	ec06                	sd	ra,24(sp)
    80002eb2:	e822                	sd	s0,16(sp)
    80002eb4:	1000                	addi	s0,sp,32
  int pid, prio, op = 0;
    80002eb6:	fe042223          	sw	zero,-28(s0)
  if(argint(0, &prio) < 0)
    80002eba:	fe840593          	addi	a1,s0,-24
    80002ebe:	4501                	li	a0,0
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	d14080e7          	jalr	-748(ra) # 80002bd4 <argint>
    return -1;
    80002ec8:	57fd                	li	a5,-1
  if(argint(0, &prio) < 0)
    80002eca:	02054863          	bltz	a0,80002efa <sys_set_priority+0x4c>
  if(argint(1, &pid) < 0)
    80002ece:	fec40593          	addi	a1,s0,-20
    80002ed2:	4505                	li	a0,1
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	d00080e7          	jalr	-768(ra) # 80002bd4 <argint>
    return -1;
    80002edc:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    80002ede:	00054e63          	bltz	a0,80002efa <sys_set_priority+0x4c>
  set_priority(prio,pid,&op);
    80002ee2:	fe440613          	addi	a2,s0,-28
    80002ee6:	fec42583          	lw	a1,-20(s0)
    80002eea:	fe842503          	lw	a0,-24(s0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	706080e7          	jalr	1798(ra) # 800025f4 <set_priority>
  return op;
    80002ef6:	fe442783          	lw	a5,-28(s0)
}
    80002efa:	853e                	mv	a0,a5
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f04:	7139                	addi	sp,sp,-64
    80002f06:	fc06                	sd	ra,56(sp)
    80002f08:	f822                	sd	s0,48(sp)
    80002f0a:	f426                	sd	s1,40(sp)
    80002f0c:	f04a                	sd	s2,32(sp)
    80002f0e:	ec4e                	sd	s3,24(sp)
    80002f10:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f12:	fcc40593          	addi	a1,s0,-52
    80002f16:	4501                	li	a0,0
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	cbc080e7          	jalr	-836(ra) # 80002bd4 <argint>
    return -1;
    80002f20:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f22:	06054563          	bltz	a0,80002f8c <sys_sleep+0x88>
  acquire(&tickslock);
    80002f26:	00015517          	auipc	a0,0x15
    80002f2a:	baa50513          	addi	a0,a0,-1110 # 80017ad0 <tickslock>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	cb6080e7          	jalr	-842(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f36:	00006917          	auipc	s2,0x6
    80002f3a:	0fa92903          	lw	s2,250(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f3e:	fcc42783          	lw	a5,-52(s0)
    80002f42:	cf85                	beqz	a5,80002f7a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f44:	00015997          	auipc	s3,0x15
    80002f48:	b8c98993          	addi	s3,s3,-1140 # 80017ad0 <tickslock>
    80002f4c:	00006497          	auipc	s1,0x6
    80002f50:	0e448493          	addi	s1,s1,228 # 80009030 <ticks>
    if(myproc()->killed){
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	a5c080e7          	jalr	-1444(ra) # 800019b0 <myproc>
    80002f5c:	551c                	lw	a5,40(a0)
    80002f5e:	ef9d                	bnez	a5,80002f9c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f60:	85ce                	mv	a1,s3
    80002f62:	8526                	mv	a0,s1
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	14a080e7          	jalr	330(ra) # 800020ae <sleep>
  while(ticks - ticks0 < n){
    80002f6c:	409c                	lw	a5,0(s1)
    80002f6e:	412787bb          	subw	a5,a5,s2
    80002f72:	fcc42703          	lw	a4,-52(s0)
    80002f76:	fce7efe3          	bltu	a5,a4,80002f54 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f7a:	00015517          	auipc	a0,0x15
    80002f7e:	b5650513          	addi	a0,a0,-1194 # 80017ad0 <tickslock>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	d16080e7          	jalr	-746(ra) # 80000c98 <release>
  return 0;
    80002f8a:	4781                	li	a5,0
}
    80002f8c:	853e                	mv	a0,a5
    80002f8e:	70e2                	ld	ra,56(sp)
    80002f90:	7442                	ld	s0,48(sp)
    80002f92:	74a2                	ld	s1,40(sp)
    80002f94:	7902                	ld	s2,32(sp)
    80002f96:	69e2                	ld	s3,24(sp)
    80002f98:	6121                	addi	sp,sp,64
    80002f9a:	8082                	ret
      release(&tickslock);
    80002f9c:	00015517          	auipc	a0,0x15
    80002fa0:	b3450513          	addi	a0,a0,-1228 # 80017ad0 <tickslock>
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	cf4080e7          	jalr	-780(ra) # 80000c98 <release>
      return -1;
    80002fac:	57fd                	li	a5,-1
    80002fae:	bff9                	j	80002f8c <sys_sleep+0x88>

0000000080002fb0 <sys_kill>:

uint64
sys_kill(void)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fb8:	fec40593          	addi	a1,s0,-20
    80002fbc:	4501                	li	a0,0
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	c16080e7          	jalr	-1002(ra) # 80002bd4 <argint>
    80002fc6:	87aa                	mv	a5,a0
    return -1;
    80002fc8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fca:	0007c863          	bltz	a5,80002fda <sys_kill+0x2a>
  return kill(pid);
    80002fce:	fec42503          	lw	a0,-20(s0)
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	42c080e7          	jalr	1068(ra) # 800023fe <kill>
}
    80002fda:	60e2                	ld	ra,24(sp)
    80002fdc:	6442                	ld	s0,16(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fec:	00015517          	auipc	a0,0x15
    80002ff0:	ae450513          	addi	a0,a0,-1308 # 80017ad0 <tickslock>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	bf0080e7          	jalr	-1040(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002ffc:	00006497          	auipc	s1,0x6
    80003000:	0344a483          	lw	s1,52(s1) # 80009030 <ticks>
  release(&tickslock);
    80003004:	00015517          	auipc	a0,0x15
    80003008:	acc50513          	addi	a0,a0,-1332 # 80017ad0 <tickslock>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	c8c080e7          	jalr	-884(ra) # 80000c98 <release>
  return xticks;
}
    80003014:	02049513          	slli	a0,s1,0x20
    80003018:	9101                	srli	a0,a0,0x20
    8000301a:	60e2                	ld	ra,24(sp)
    8000301c:	6442                	ld	s0,16(sp)
    8000301e:	64a2                	ld	s1,8(sp)
    80003020:	6105                	addi	sp,sp,32
    80003022:	8082                	ret

0000000080003024 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003024:	7179                	addi	sp,sp,-48
    80003026:	f406                	sd	ra,40(sp)
    80003028:	f022                	sd	s0,32(sp)
    8000302a:	ec26                	sd	s1,24(sp)
    8000302c:	e84a                	sd	s2,16(sp)
    8000302e:	e44e                	sd	s3,8(sp)
    80003030:	e052                	sd	s4,0(sp)
    80003032:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003034:	00005597          	auipc	a1,0x5
    80003038:	5b458593          	addi	a1,a1,1460 # 800085e8 <syscalls+0xc0>
    8000303c:	00015517          	auipc	a0,0x15
    80003040:	aac50513          	addi	a0,a0,-1364 # 80017ae8 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	b10080e7          	jalr	-1264(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000304c:	0001d797          	auipc	a5,0x1d
    80003050:	a9c78793          	addi	a5,a5,-1380 # 8001fae8 <bcache+0x8000>
    80003054:	0001d717          	auipc	a4,0x1d
    80003058:	cfc70713          	addi	a4,a4,-772 # 8001fd50 <bcache+0x8268>
    8000305c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003060:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003064:	00015497          	auipc	s1,0x15
    80003068:	a9c48493          	addi	s1,s1,-1380 # 80017b00 <bcache+0x18>
    b->next = bcache.head.next;
    8000306c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000306e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003070:	00005a17          	auipc	s4,0x5
    80003074:	580a0a13          	addi	s4,s4,1408 # 800085f0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003078:	2b893783          	ld	a5,696(s2)
    8000307c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000307e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003082:	85d2                	mv	a1,s4
    80003084:	01048513          	addi	a0,s1,16
    80003088:	00001097          	auipc	ra,0x1
    8000308c:	4bc080e7          	jalr	1212(ra) # 80004544 <initsleeplock>
    bcache.head.next->prev = b;
    80003090:	2b893783          	ld	a5,696(s2)
    80003094:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003096:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000309a:	45848493          	addi	s1,s1,1112
    8000309e:	fd349de3          	bne	s1,s3,80003078 <binit+0x54>
  }
}
    800030a2:	70a2                	ld	ra,40(sp)
    800030a4:	7402                	ld	s0,32(sp)
    800030a6:	64e2                	ld	s1,24(sp)
    800030a8:	6942                	ld	s2,16(sp)
    800030aa:	69a2                	ld	s3,8(sp)
    800030ac:	6a02                	ld	s4,0(sp)
    800030ae:	6145                	addi	sp,sp,48
    800030b0:	8082                	ret

00000000800030b2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030b2:	7179                	addi	sp,sp,-48
    800030b4:	f406                	sd	ra,40(sp)
    800030b6:	f022                	sd	s0,32(sp)
    800030b8:	ec26                	sd	s1,24(sp)
    800030ba:	e84a                	sd	s2,16(sp)
    800030bc:	e44e                	sd	s3,8(sp)
    800030be:	1800                	addi	s0,sp,48
    800030c0:	89aa                	mv	s3,a0
    800030c2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030c4:	00015517          	auipc	a0,0x15
    800030c8:	a2450513          	addi	a0,a0,-1500 # 80017ae8 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030d4:	0001d497          	auipc	s1,0x1d
    800030d8:	ccc4b483          	ld	s1,-820(s1) # 8001fda0 <bcache+0x82b8>
    800030dc:	0001d797          	auipc	a5,0x1d
    800030e0:	c7478793          	addi	a5,a5,-908 # 8001fd50 <bcache+0x8268>
    800030e4:	02f48f63          	beq	s1,a5,80003122 <bread+0x70>
    800030e8:	873e                	mv	a4,a5
    800030ea:	a021                	j	800030f2 <bread+0x40>
    800030ec:	68a4                	ld	s1,80(s1)
    800030ee:	02e48a63          	beq	s1,a4,80003122 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030f2:	449c                	lw	a5,8(s1)
    800030f4:	ff379ce3          	bne	a5,s3,800030ec <bread+0x3a>
    800030f8:	44dc                	lw	a5,12(s1)
    800030fa:	ff2799e3          	bne	a5,s2,800030ec <bread+0x3a>
      b->refcnt++;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	2785                	addiw	a5,a5,1
    80003102:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003104:	00015517          	auipc	a0,0x15
    80003108:	9e450513          	addi	a0,a0,-1564 # 80017ae8 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003114:	01048513          	addi	a0,s1,16
    80003118:	00001097          	auipc	ra,0x1
    8000311c:	466080e7          	jalr	1126(ra) # 8000457e <acquiresleep>
      return b;
    80003120:	a8b9                	j	8000317e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003122:	0001d497          	auipc	s1,0x1d
    80003126:	c764b483          	ld	s1,-906(s1) # 8001fd98 <bcache+0x82b0>
    8000312a:	0001d797          	auipc	a5,0x1d
    8000312e:	c2678793          	addi	a5,a5,-986 # 8001fd50 <bcache+0x8268>
    80003132:	00f48863          	beq	s1,a5,80003142 <bread+0x90>
    80003136:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003138:	40bc                	lw	a5,64(s1)
    8000313a:	cf81                	beqz	a5,80003152 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000313c:	64a4                	ld	s1,72(s1)
    8000313e:	fee49de3          	bne	s1,a4,80003138 <bread+0x86>
  panic("bget: no buffers");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	4b650513          	addi	a0,a0,1206 # 800085f8 <syscalls+0xd0>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>
      b->dev = dev;
    80003152:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003156:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000315a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000315e:	4785                	li	a5,1
    80003160:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003162:	00015517          	auipc	a0,0x15
    80003166:	98650513          	addi	a0,a0,-1658 # 80017ae8 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003172:	01048513          	addi	a0,s1,16
    80003176:	00001097          	auipc	ra,0x1
    8000317a:	408080e7          	jalr	1032(ra) # 8000457e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000317e:	409c                	lw	a5,0(s1)
    80003180:	cb89                	beqz	a5,80003192 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003182:	8526                	mv	a0,s1
    80003184:	70a2                	ld	ra,40(sp)
    80003186:	7402                	ld	s0,32(sp)
    80003188:	64e2                	ld	s1,24(sp)
    8000318a:	6942                	ld	s2,16(sp)
    8000318c:	69a2                	ld	s3,8(sp)
    8000318e:	6145                	addi	sp,sp,48
    80003190:	8082                	ret
    virtio_disk_rw(b, 0);
    80003192:	4581                	li	a1,0
    80003194:	8526                	mv	a0,s1
    80003196:	00003097          	auipc	ra,0x3
    8000319a:	f10080e7          	jalr	-240(ra) # 800060a6 <virtio_disk_rw>
    b->valid = 1;
    8000319e:	4785                	li	a5,1
    800031a0:	c09c                	sw	a5,0(s1)
  return b;
    800031a2:	b7c5                	j	80003182 <bread+0xd0>

00000000800031a4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	e426                	sd	s1,8(sp)
    800031ac:	1000                	addi	s0,sp,32
    800031ae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b0:	0541                	addi	a0,a0,16
    800031b2:	00001097          	auipc	ra,0x1
    800031b6:	466080e7          	jalr	1126(ra) # 80004618 <holdingsleep>
    800031ba:	cd01                	beqz	a0,800031d2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031bc:	4585                	li	a1,1
    800031be:	8526                	mv	a0,s1
    800031c0:	00003097          	auipc	ra,0x3
    800031c4:	ee6080e7          	jalr	-282(ra) # 800060a6 <virtio_disk_rw>
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6105                	addi	sp,sp,32
    800031d0:	8082                	ret
    panic("bwrite");
    800031d2:	00005517          	auipc	a0,0x5
    800031d6:	43e50513          	addi	a0,a0,1086 # 80008610 <syscalls+0xe8>
    800031da:	ffffd097          	auipc	ra,0xffffd
    800031de:	364080e7          	jalr	868(ra) # 8000053e <panic>

00000000800031e2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	e04a                	sd	s2,0(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f0:	01050913          	addi	s2,a0,16
    800031f4:	854a                	mv	a0,s2
    800031f6:	00001097          	auipc	ra,0x1
    800031fa:	422080e7          	jalr	1058(ra) # 80004618 <holdingsleep>
    800031fe:	c92d                	beqz	a0,80003270 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003200:	854a                	mv	a0,s2
    80003202:	00001097          	auipc	ra,0x1
    80003206:	3d2080e7          	jalr	978(ra) # 800045d4 <releasesleep>

  acquire(&bcache.lock);
    8000320a:	00015517          	auipc	a0,0x15
    8000320e:	8de50513          	addi	a0,a0,-1826 # 80017ae8 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	9d2080e7          	jalr	-1582(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000321a:	40bc                	lw	a5,64(s1)
    8000321c:	37fd                	addiw	a5,a5,-1
    8000321e:	0007871b          	sext.w	a4,a5
    80003222:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003224:	eb05                	bnez	a4,80003254 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003226:	68bc                	ld	a5,80(s1)
    80003228:	64b8                	ld	a4,72(s1)
    8000322a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000322c:	64bc                	ld	a5,72(s1)
    8000322e:	68b8                	ld	a4,80(s1)
    80003230:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003232:	0001d797          	auipc	a5,0x1d
    80003236:	8b678793          	addi	a5,a5,-1866 # 8001fae8 <bcache+0x8000>
    8000323a:	2b87b703          	ld	a4,696(a5)
    8000323e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003240:	0001d717          	auipc	a4,0x1d
    80003244:	b1070713          	addi	a4,a4,-1264 # 8001fd50 <bcache+0x8268>
    80003248:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000324a:	2b87b703          	ld	a4,696(a5)
    8000324e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003250:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003254:	00015517          	auipc	a0,0x15
    80003258:	89450513          	addi	a0,a0,-1900 # 80017ae8 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	a3c080e7          	jalr	-1476(ra) # 80000c98 <release>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6902                	ld	s2,0(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret
    panic("brelse");
    80003270:	00005517          	auipc	a0,0x5
    80003274:	3a850513          	addi	a0,a0,936 # 80008618 <syscalls+0xf0>
    80003278:	ffffd097          	auipc	ra,0xffffd
    8000327c:	2c6080e7          	jalr	710(ra) # 8000053e <panic>

0000000080003280 <bpin>:

void
bpin(struct buf *b) {
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	e426                	sd	s1,8(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000328c:	00015517          	auipc	a0,0x15
    80003290:	85c50513          	addi	a0,a0,-1956 # 80017ae8 <bcache>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000329c:	40bc                	lw	a5,64(s1)
    8000329e:	2785                	addiw	a5,a5,1
    800032a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032a2:	00015517          	auipc	a0,0x15
    800032a6:	84650513          	addi	a0,a0,-1978 # 80017ae8 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
}
    800032b2:	60e2                	ld	ra,24(sp)
    800032b4:	6442                	ld	s0,16(sp)
    800032b6:	64a2                	ld	s1,8(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <bunpin>:

void
bunpin(struct buf *b) {
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	1000                	addi	s0,sp,32
    800032c6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c8:	00015517          	auipc	a0,0x15
    800032cc:	82050513          	addi	a0,a0,-2016 # 80017ae8 <bcache>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	914080e7          	jalr	-1772(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032d8:	40bc                	lw	a5,64(s1)
    800032da:	37fd                	addiw	a5,a5,-1
    800032dc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032de:	00015517          	auipc	a0,0x15
    800032e2:	80a50513          	addi	a0,a0,-2038 # 80017ae8 <bcache>
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	9b2080e7          	jalr	-1614(ra) # 80000c98 <release>
}
    800032ee:	60e2                	ld	ra,24(sp)
    800032f0:	6442                	ld	s0,16(sp)
    800032f2:	64a2                	ld	s1,8(sp)
    800032f4:	6105                	addi	sp,sp,32
    800032f6:	8082                	ret

00000000800032f8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	e426                	sd	s1,8(sp)
    80003300:	e04a                	sd	s2,0(sp)
    80003302:	1000                	addi	s0,sp,32
    80003304:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003306:	00d5d59b          	srliw	a1,a1,0xd
    8000330a:	0001d797          	auipc	a5,0x1d
    8000330e:	eba7a783          	lw	a5,-326(a5) # 800201c4 <sb+0x1c>
    80003312:	9dbd                	addw	a1,a1,a5
    80003314:	00000097          	auipc	ra,0x0
    80003318:	d9e080e7          	jalr	-610(ra) # 800030b2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000331c:	0074f713          	andi	a4,s1,7
    80003320:	4785                	li	a5,1
    80003322:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003326:	14ce                	slli	s1,s1,0x33
    80003328:	90d9                	srli	s1,s1,0x36
    8000332a:	00950733          	add	a4,a0,s1
    8000332e:	05874703          	lbu	a4,88(a4)
    80003332:	00e7f6b3          	and	a3,a5,a4
    80003336:	c69d                	beqz	a3,80003364 <bfree+0x6c>
    80003338:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000333a:	94aa                	add	s1,s1,a0
    8000333c:	fff7c793          	not	a5,a5
    80003340:	8ff9                	and	a5,a5,a4
    80003342:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	118080e7          	jalr	280(ra) # 8000445e <log_write>
  brelse(bp);
    8000334e:	854a                	mv	a0,s2
    80003350:	00000097          	auipc	ra,0x0
    80003354:	e92080e7          	jalr	-366(ra) # 800031e2 <brelse>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	64a2                	ld	s1,8(sp)
    8000335e:	6902                	ld	s2,0(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret
    panic("freeing free block");
    80003364:	00005517          	auipc	a0,0x5
    80003368:	2bc50513          	addi	a0,a0,700 # 80008620 <syscalls+0xf8>
    8000336c:	ffffd097          	auipc	ra,0xffffd
    80003370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>

0000000080003374 <balloc>:
{
    80003374:	711d                	addi	sp,sp,-96
    80003376:	ec86                	sd	ra,88(sp)
    80003378:	e8a2                	sd	s0,80(sp)
    8000337a:	e4a6                	sd	s1,72(sp)
    8000337c:	e0ca                	sd	s2,64(sp)
    8000337e:	fc4e                	sd	s3,56(sp)
    80003380:	f852                	sd	s4,48(sp)
    80003382:	f456                	sd	s5,40(sp)
    80003384:	f05a                	sd	s6,32(sp)
    80003386:	ec5e                	sd	s7,24(sp)
    80003388:	e862                	sd	s8,16(sp)
    8000338a:	e466                	sd	s9,8(sp)
    8000338c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000338e:	0001d797          	auipc	a5,0x1d
    80003392:	e1e7a783          	lw	a5,-482(a5) # 800201ac <sb+0x4>
    80003396:	cbd1                	beqz	a5,8000342a <balloc+0xb6>
    80003398:	8baa                	mv	s7,a0
    8000339a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000339c:	0001db17          	auipc	s6,0x1d
    800033a0:	e0cb0b13          	addi	s6,s6,-500 # 800201a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033a6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033aa:	6c89                	lui	s9,0x2
    800033ac:	a831                	j	800033c8 <balloc+0x54>
    brelse(bp);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e32080e7          	jalr	-462(ra) # 800031e2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033b8:	015c87bb          	addw	a5,s9,s5
    800033bc:	00078a9b          	sext.w	s5,a5
    800033c0:	004b2703          	lw	a4,4(s6)
    800033c4:	06eaf363          	bgeu	s5,a4,8000342a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033c8:	41fad79b          	sraiw	a5,s5,0x1f
    800033cc:	0137d79b          	srliw	a5,a5,0x13
    800033d0:	015787bb          	addw	a5,a5,s5
    800033d4:	40d7d79b          	sraiw	a5,a5,0xd
    800033d8:	01cb2583          	lw	a1,28(s6)
    800033dc:	9dbd                	addw	a1,a1,a5
    800033de:	855e                	mv	a0,s7
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	cd2080e7          	jalr	-814(ra) # 800030b2 <bread>
    800033e8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ea:	004b2503          	lw	a0,4(s6)
    800033ee:	000a849b          	sext.w	s1,s5
    800033f2:	8662                	mv	a2,s8
    800033f4:	faa4fde3          	bgeu	s1,a0,800033ae <balloc+0x3a>
      m = 1 << (bi % 8);
    800033f8:	41f6579b          	sraiw	a5,a2,0x1f
    800033fc:	01d7d69b          	srliw	a3,a5,0x1d
    80003400:	00c6873b          	addw	a4,a3,a2
    80003404:	00777793          	andi	a5,a4,7
    80003408:	9f95                	subw	a5,a5,a3
    8000340a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000340e:	4037571b          	sraiw	a4,a4,0x3
    80003412:	00e906b3          	add	a3,s2,a4
    80003416:	0586c683          	lbu	a3,88(a3)
    8000341a:	00d7f5b3          	and	a1,a5,a3
    8000341e:	cd91                	beqz	a1,8000343a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003420:	2605                	addiw	a2,a2,1
    80003422:	2485                	addiw	s1,s1,1
    80003424:	fd4618e3          	bne	a2,s4,800033f4 <balloc+0x80>
    80003428:	b759                	j	800033ae <balloc+0x3a>
  panic("balloc: out of blocks");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	20e50513          	addi	a0,a0,526 # 80008638 <syscalls+0x110>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	10c080e7          	jalr	268(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000343a:	974a                	add	a4,a4,s2
    8000343c:	8fd5                	or	a5,a5,a3
    8000343e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003442:	854a                	mv	a0,s2
    80003444:	00001097          	auipc	ra,0x1
    80003448:	01a080e7          	jalr	26(ra) # 8000445e <log_write>
        brelse(bp);
    8000344c:	854a                	mv	a0,s2
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	d94080e7          	jalr	-620(ra) # 800031e2 <brelse>
  bp = bread(dev, bno);
    80003456:	85a6                	mv	a1,s1
    80003458:	855e                	mv	a0,s7
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	c58080e7          	jalr	-936(ra) # 800030b2 <bread>
    80003462:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003464:	40000613          	li	a2,1024
    80003468:	4581                	li	a1,0
    8000346a:	05850513          	addi	a0,a0,88
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	872080e7          	jalr	-1934(ra) # 80000ce0 <memset>
  log_write(bp);
    80003476:	854a                	mv	a0,s2
    80003478:	00001097          	auipc	ra,0x1
    8000347c:	fe6080e7          	jalr	-26(ra) # 8000445e <log_write>
  brelse(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	00000097          	auipc	ra,0x0
    80003486:	d60080e7          	jalr	-672(ra) # 800031e2 <brelse>
}
    8000348a:	8526                	mv	a0,s1
    8000348c:	60e6                	ld	ra,88(sp)
    8000348e:	6446                	ld	s0,80(sp)
    80003490:	64a6                	ld	s1,72(sp)
    80003492:	6906                	ld	s2,64(sp)
    80003494:	79e2                	ld	s3,56(sp)
    80003496:	7a42                	ld	s4,48(sp)
    80003498:	7aa2                	ld	s5,40(sp)
    8000349a:	7b02                	ld	s6,32(sp)
    8000349c:	6be2                	ld	s7,24(sp)
    8000349e:	6c42                	ld	s8,16(sp)
    800034a0:	6ca2                	ld	s9,8(sp)
    800034a2:	6125                	addi	sp,sp,96
    800034a4:	8082                	ret

00000000800034a6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034a6:	7179                	addi	sp,sp,-48
    800034a8:	f406                	sd	ra,40(sp)
    800034aa:	f022                	sd	s0,32(sp)
    800034ac:	ec26                	sd	s1,24(sp)
    800034ae:	e84a                	sd	s2,16(sp)
    800034b0:	e44e                	sd	s3,8(sp)
    800034b2:	e052                	sd	s4,0(sp)
    800034b4:	1800                	addi	s0,sp,48
    800034b6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034b8:	47ad                	li	a5,11
    800034ba:	04b7fe63          	bgeu	a5,a1,80003516 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034be:	ff45849b          	addiw	s1,a1,-12
    800034c2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034c6:	0ff00793          	li	a5,255
    800034ca:	0ae7e363          	bltu	a5,a4,80003570 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034ce:	08052583          	lw	a1,128(a0)
    800034d2:	c5ad                	beqz	a1,8000353c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034d4:	00092503          	lw	a0,0(s2)
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	bda080e7          	jalr	-1062(ra) # 800030b2 <bread>
    800034e0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034e2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034e6:	02049593          	slli	a1,s1,0x20
    800034ea:	9181                	srli	a1,a1,0x20
    800034ec:	058a                	slli	a1,a1,0x2
    800034ee:	00b784b3          	add	s1,a5,a1
    800034f2:	0004a983          	lw	s3,0(s1)
    800034f6:	04098d63          	beqz	s3,80003550 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034fa:	8552                	mv	a0,s4
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	ce6080e7          	jalr	-794(ra) # 800031e2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003504:	854e                	mv	a0,s3
    80003506:	70a2                	ld	ra,40(sp)
    80003508:	7402                	ld	s0,32(sp)
    8000350a:	64e2                	ld	s1,24(sp)
    8000350c:	6942                	ld	s2,16(sp)
    8000350e:	69a2                	ld	s3,8(sp)
    80003510:	6a02                	ld	s4,0(sp)
    80003512:	6145                	addi	sp,sp,48
    80003514:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003516:	02059493          	slli	s1,a1,0x20
    8000351a:	9081                	srli	s1,s1,0x20
    8000351c:	048a                	slli	s1,s1,0x2
    8000351e:	94aa                	add	s1,s1,a0
    80003520:	0504a983          	lw	s3,80(s1)
    80003524:	fe0990e3          	bnez	s3,80003504 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003528:	4108                	lw	a0,0(a0)
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	e4a080e7          	jalr	-438(ra) # 80003374 <balloc>
    80003532:	0005099b          	sext.w	s3,a0
    80003536:	0534a823          	sw	s3,80(s1)
    8000353a:	b7e9                	j	80003504 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000353c:	4108                	lw	a0,0(a0)
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	e36080e7          	jalr	-458(ra) # 80003374 <balloc>
    80003546:	0005059b          	sext.w	a1,a0
    8000354a:	08b92023          	sw	a1,128(s2)
    8000354e:	b759                	j	800034d4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003550:	00092503          	lw	a0,0(s2)
    80003554:	00000097          	auipc	ra,0x0
    80003558:	e20080e7          	jalr	-480(ra) # 80003374 <balloc>
    8000355c:	0005099b          	sext.w	s3,a0
    80003560:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003564:	8552                	mv	a0,s4
    80003566:	00001097          	auipc	ra,0x1
    8000356a:	ef8080e7          	jalr	-264(ra) # 8000445e <log_write>
    8000356e:	b771                	j	800034fa <bmap+0x54>
  panic("bmap: out of range");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	0e050513          	addi	a0,a0,224 # 80008650 <syscalls+0x128>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>

0000000080003580 <iget>:
{
    80003580:	7179                	addi	sp,sp,-48
    80003582:	f406                	sd	ra,40(sp)
    80003584:	f022                	sd	s0,32(sp)
    80003586:	ec26                	sd	s1,24(sp)
    80003588:	e84a                	sd	s2,16(sp)
    8000358a:	e44e                	sd	s3,8(sp)
    8000358c:	e052                	sd	s4,0(sp)
    8000358e:	1800                	addi	s0,sp,48
    80003590:	89aa                	mv	s3,a0
    80003592:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003594:	0001d517          	auipc	a0,0x1d
    80003598:	c3450513          	addi	a0,a0,-972 # 800201c8 <itable>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  empty = 0;
    800035a4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035a6:	0001d497          	auipc	s1,0x1d
    800035aa:	c3a48493          	addi	s1,s1,-966 # 800201e0 <itable+0x18>
    800035ae:	0001e697          	auipc	a3,0x1e
    800035b2:	6c268693          	addi	a3,a3,1730 # 80021c70 <log>
    800035b6:	a039                	j	800035c4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b8:	02090b63          	beqz	s2,800035ee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035bc:	08848493          	addi	s1,s1,136
    800035c0:	02d48a63          	beq	s1,a3,800035f4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035c4:	449c                	lw	a5,8(s1)
    800035c6:	fef059e3          	blez	a5,800035b8 <iget+0x38>
    800035ca:	4098                	lw	a4,0(s1)
    800035cc:	ff3716e3          	bne	a4,s3,800035b8 <iget+0x38>
    800035d0:	40d8                	lw	a4,4(s1)
    800035d2:	ff4713e3          	bne	a4,s4,800035b8 <iget+0x38>
      ip->ref++;
    800035d6:	2785                	addiw	a5,a5,1
    800035d8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035da:	0001d517          	auipc	a0,0x1d
    800035de:	bee50513          	addi	a0,a0,-1042 # 800201c8 <itable>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
      return ip;
    800035ea:	8926                	mv	s2,s1
    800035ec:	a03d                	j	8000361a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ee:	f7f9                	bnez	a5,800035bc <iget+0x3c>
    800035f0:	8926                	mv	s2,s1
    800035f2:	b7e9                	j	800035bc <iget+0x3c>
  if(empty == 0)
    800035f4:	02090c63          	beqz	s2,8000362c <iget+0xac>
  ip->dev = dev;
    800035f8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035fc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003600:	4785                	li	a5,1
    80003602:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003606:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000360a:	0001d517          	auipc	a0,0x1d
    8000360e:	bbe50513          	addi	a0,a0,-1090 # 800201c8 <itable>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
}
    8000361a:	854a                	mv	a0,s2
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6a02                	ld	s4,0(sp)
    80003628:	6145                	addi	sp,sp,48
    8000362a:	8082                	ret
    panic("iget: no inodes");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	03c50513          	addi	a0,a0,60 # 80008668 <syscalls+0x140>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f0a080e7          	jalr	-246(ra) # 8000053e <panic>

000000008000363c <fsinit>:
fsinit(int dev) {
    8000363c:	7179                	addi	sp,sp,-48
    8000363e:	f406                	sd	ra,40(sp)
    80003640:	f022                	sd	s0,32(sp)
    80003642:	ec26                	sd	s1,24(sp)
    80003644:	e84a                	sd	s2,16(sp)
    80003646:	e44e                	sd	s3,8(sp)
    80003648:	1800                	addi	s0,sp,48
    8000364a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000364c:	4585                	li	a1,1
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	a64080e7          	jalr	-1436(ra) # 800030b2 <bread>
    80003656:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003658:	0001d997          	auipc	s3,0x1d
    8000365c:	b5098993          	addi	s3,s3,-1200 # 800201a8 <sb>
    80003660:	02000613          	li	a2,32
    80003664:	05850593          	addi	a1,a0,88
    80003668:	854e                	mv	a0,s3
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	6d6080e7          	jalr	1750(ra) # 80000d40 <memmove>
  brelse(bp);
    80003672:	8526                	mv	a0,s1
    80003674:	00000097          	auipc	ra,0x0
    80003678:	b6e080e7          	jalr	-1170(ra) # 800031e2 <brelse>
  if(sb.magic != FSMAGIC)
    8000367c:	0009a703          	lw	a4,0(s3)
    80003680:	102037b7          	lui	a5,0x10203
    80003684:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003688:	02f71263          	bne	a4,a5,800036ac <fsinit+0x70>
  initlog(dev, &sb);
    8000368c:	0001d597          	auipc	a1,0x1d
    80003690:	b1c58593          	addi	a1,a1,-1252 # 800201a8 <sb>
    80003694:	854a                	mv	a0,s2
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	b4c080e7          	jalr	-1204(ra) # 800041e2 <initlog>
}
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6145                	addi	sp,sp,48
    800036aa:	8082                	ret
    panic("invalid file system");
    800036ac:	00005517          	auipc	a0,0x5
    800036b0:	fcc50513          	addi	a0,a0,-52 # 80008678 <syscalls+0x150>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>

00000000800036bc <iinit>:
{
    800036bc:	7179                	addi	sp,sp,-48
    800036be:	f406                	sd	ra,40(sp)
    800036c0:	f022                	sd	s0,32(sp)
    800036c2:	ec26                	sd	s1,24(sp)
    800036c4:	e84a                	sd	s2,16(sp)
    800036c6:	e44e                	sd	s3,8(sp)
    800036c8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036ca:	00005597          	auipc	a1,0x5
    800036ce:	fc658593          	addi	a1,a1,-58 # 80008690 <syscalls+0x168>
    800036d2:	0001d517          	auipc	a0,0x1d
    800036d6:	af650513          	addi	a0,a0,-1290 # 800201c8 <itable>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	47a080e7          	jalr	1146(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036e2:	0001d497          	auipc	s1,0x1d
    800036e6:	b0e48493          	addi	s1,s1,-1266 # 800201f0 <itable+0x28>
    800036ea:	0001e997          	auipc	s3,0x1e
    800036ee:	59698993          	addi	s3,s3,1430 # 80021c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036f2:	00005917          	auipc	s2,0x5
    800036f6:	fa690913          	addi	s2,s2,-90 # 80008698 <syscalls+0x170>
    800036fa:	85ca                	mv	a1,s2
    800036fc:	8526                	mv	a0,s1
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	e46080e7          	jalr	-442(ra) # 80004544 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003706:	08848493          	addi	s1,s1,136
    8000370a:	ff3498e3          	bne	s1,s3,800036fa <iinit+0x3e>
}
    8000370e:	70a2                	ld	ra,40(sp)
    80003710:	7402                	ld	s0,32(sp)
    80003712:	64e2                	ld	s1,24(sp)
    80003714:	6942                	ld	s2,16(sp)
    80003716:	69a2                	ld	s3,8(sp)
    80003718:	6145                	addi	sp,sp,48
    8000371a:	8082                	ret

000000008000371c <ialloc>:
{
    8000371c:	715d                	addi	sp,sp,-80
    8000371e:	e486                	sd	ra,72(sp)
    80003720:	e0a2                	sd	s0,64(sp)
    80003722:	fc26                	sd	s1,56(sp)
    80003724:	f84a                	sd	s2,48(sp)
    80003726:	f44e                	sd	s3,40(sp)
    80003728:	f052                	sd	s4,32(sp)
    8000372a:	ec56                	sd	s5,24(sp)
    8000372c:	e85a                	sd	s6,16(sp)
    8000372e:	e45e                	sd	s7,8(sp)
    80003730:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003732:	0001d717          	auipc	a4,0x1d
    80003736:	a8272703          	lw	a4,-1406(a4) # 800201b4 <sb+0xc>
    8000373a:	4785                	li	a5,1
    8000373c:	04e7fa63          	bgeu	a5,a4,80003790 <ialloc+0x74>
    80003740:	8aaa                	mv	s5,a0
    80003742:	8bae                	mv	s7,a1
    80003744:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003746:	0001da17          	auipc	s4,0x1d
    8000374a:	a62a0a13          	addi	s4,s4,-1438 # 800201a8 <sb>
    8000374e:	00048b1b          	sext.w	s6,s1
    80003752:	0044d593          	srli	a1,s1,0x4
    80003756:	018a2783          	lw	a5,24(s4)
    8000375a:	9dbd                	addw	a1,a1,a5
    8000375c:	8556                	mv	a0,s5
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	954080e7          	jalr	-1708(ra) # 800030b2 <bread>
    80003766:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003768:	05850993          	addi	s3,a0,88
    8000376c:	00f4f793          	andi	a5,s1,15
    80003770:	079a                	slli	a5,a5,0x6
    80003772:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003774:	00099783          	lh	a5,0(s3)
    80003778:	c785                	beqz	a5,800037a0 <ialloc+0x84>
    brelse(bp);
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	a68080e7          	jalr	-1432(ra) # 800031e2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003782:	0485                	addi	s1,s1,1
    80003784:	00ca2703          	lw	a4,12(s4)
    80003788:	0004879b          	sext.w	a5,s1
    8000378c:	fce7e1e3          	bltu	a5,a4,8000374e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003790:	00005517          	auipc	a0,0x5
    80003794:	f1050513          	addi	a0,a0,-240 # 800086a0 <syscalls+0x178>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037a0:	04000613          	li	a2,64
    800037a4:	4581                	li	a1,0
    800037a6:	854e                	mv	a0,s3
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	538080e7          	jalr	1336(ra) # 80000ce0 <memset>
      dip->type = type;
    800037b0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037b4:	854a                	mv	a0,s2
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	ca8080e7          	jalr	-856(ra) # 8000445e <log_write>
      brelse(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	a22080e7          	jalr	-1502(ra) # 800031e2 <brelse>
      return iget(dev, inum);
    800037c8:	85da                	mv	a1,s6
    800037ca:	8556                	mv	a0,s5
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	db4080e7          	jalr	-588(ra) # 80003580 <iget>
}
    800037d4:	60a6                	ld	ra,72(sp)
    800037d6:	6406                	ld	s0,64(sp)
    800037d8:	74e2                	ld	s1,56(sp)
    800037da:	7942                	ld	s2,48(sp)
    800037dc:	79a2                	ld	s3,40(sp)
    800037de:	7a02                	ld	s4,32(sp)
    800037e0:	6ae2                	ld	s5,24(sp)
    800037e2:	6b42                	ld	s6,16(sp)
    800037e4:	6ba2                	ld	s7,8(sp)
    800037e6:	6161                	addi	sp,sp,80
    800037e8:	8082                	ret

00000000800037ea <iupdate>:
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	e04a                	sd	s2,0(sp)
    800037f4:	1000                	addi	s0,sp,32
    800037f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f8:	415c                	lw	a5,4(a0)
    800037fa:	0047d79b          	srliw	a5,a5,0x4
    800037fe:	0001d597          	auipc	a1,0x1d
    80003802:	9c25a583          	lw	a1,-1598(a1) # 800201c0 <sb+0x18>
    80003806:	9dbd                	addw	a1,a1,a5
    80003808:	4108                	lw	a0,0(a0)
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	8a8080e7          	jalr	-1880(ra) # 800030b2 <bread>
    80003812:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003814:	05850793          	addi	a5,a0,88
    80003818:	40c8                	lw	a0,4(s1)
    8000381a:	893d                	andi	a0,a0,15
    8000381c:	051a                	slli	a0,a0,0x6
    8000381e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003820:	04449703          	lh	a4,68(s1)
    80003824:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003828:	04649703          	lh	a4,70(s1)
    8000382c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003830:	04849703          	lh	a4,72(s1)
    80003834:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003838:	04a49703          	lh	a4,74(s1)
    8000383c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003840:	44f8                	lw	a4,76(s1)
    80003842:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003844:	03400613          	li	a2,52
    80003848:	05048593          	addi	a1,s1,80
    8000384c:	0531                	addi	a0,a0,12
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	4f2080e7          	jalr	1266(ra) # 80000d40 <memmove>
  log_write(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	c06080e7          	jalr	-1018(ra) # 8000445e <log_write>
  brelse(bp);
    80003860:	854a                	mv	a0,s2
    80003862:	00000097          	auipc	ra,0x0
    80003866:	980080e7          	jalr	-1664(ra) # 800031e2 <brelse>
}
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	64a2                	ld	s1,8(sp)
    80003870:	6902                	ld	s2,0(sp)
    80003872:	6105                	addi	sp,sp,32
    80003874:	8082                	ret

0000000080003876 <idup>:
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	1000                	addi	s0,sp,32
    80003880:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003882:	0001d517          	auipc	a0,0x1d
    80003886:	94650513          	addi	a0,a0,-1722 # 800201c8 <itable>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	35a080e7          	jalr	858(ra) # 80000be4 <acquire>
  ip->ref++;
    80003892:	449c                	lw	a5,8(s1)
    80003894:	2785                	addiw	a5,a5,1
    80003896:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003898:	0001d517          	auipc	a0,0x1d
    8000389c:	93050513          	addi	a0,a0,-1744 # 800201c8 <itable>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	3f8080e7          	jalr	1016(ra) # 80000c98 <release>
}
    800038a8:	8526                	mv	a0,s1
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret

00000000800038b4 <ilock>:
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	e04a                	sd	s2,0(sp)
    800038be:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038c0:	c115                	beqz	a0,800038e4 <ilock+0x30>
    800038c2:	84aa                	mv	s1,a0
    800038c4:	451c                	lw	a5,8(a0)
    800038c6:	00f05f63          	blez	a5,800038e4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ca:	0541                	addi	a0,a0,16
    800038cc:	00001097          	auipc	ra,0x1
    800038d0:	cb2080e7          	jalr	-846(ra) # 8000457e <acquiresleep>
  if(ip->valid == 0){
    800038d4:	40bc                	lw	a5,64(s1)
    800038d6:	cf99                	beqz	a5,800038f4 <ilock+0x40>
}
    800038d8:	60e2                	ld	ra,24(sp)
    800038da:	6442                	ld	s0,16(sp)
    800038dc:	64a2                	ld	s1,8(sp)
    800038de:	6902                	ld	s2,0(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret
    panic("ilock");
    800038e4:	00005517          	auipc	a0,0x5
    800038e8:	dd450513          	addi	a0,a0,-556 # 800086b8 <syscalls+0x190>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f4:	40dc                	lw	a5,4(s1)
    800038f6:	0047d79b          	srliw	a5,a5,0x4
    800038fa:	0001d597          	auipc	a1,0x1d
    800038fe:	8c65a583          	lw	a1,-1850(a1) # 800201c0 <sb+0x18>
    80003902:	9dbd                	addw	a1,a1,a5
    80003904:	4088                	lw	a0,0(s1)
    80003906:	fffff097          	auipc	ra,0xfffff
    8000390a:	7ac080e7          	jalr	1964(ra) # 800030b2 <bread>
    8000390e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003910:	05850593          	addi	a1,a0,88
    80003914:	40dc                	lw	a5,4(s1)
    80003916:	8bbd                	andi	a5,a5,15
    80003918:	079a                	slli	a5,a5,0x6
    8000391a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000391c:	00059783          	lh	a5,0(a1)
    80003920:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003924:	00259783          	lh	a5,2(a1)
    80003928:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000392c:	00459783          	lh	a5,4(a1)
    80003930:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003934:	00659783          	lh	a5,6(a1)
    80003938:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000393c:	459c                	lw	a5,8(a1)
    8000393e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003940:	03400613          	li	a2,52
    80003944:	05b1                	addi	a1,a1,12
    80003946:	05048513          	addi	a0,s1,80
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	3f6080e7          	jalr	1014(ra) # 80000d40 <memmove>
    brelse(bp);
    80003952:	854a                	mv	a0,s2
    80003954:	00000097          	auipc	ra,0x0
    80003958:	88e080e7          	jalr	-1906(ra) # 800031e2 <brelse>
    ip->valid = 1;
    8000395c:	4785                	li	a5,1
    8000395e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003960:	04449783          	lh	a5,68(s1)
    80003964:	fbb5                	bnez	a5,800038d8 <ilock+0x24>
      panic("ilock: no type");
    80003966:	00005517          	auipc	a0,0x5
    8000396a:	d5a50513          	addi	a0,a0,-678 # 800086c0 <syscalls+0x198>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080003976 <iunlock>:
{
    80003976:	1101                	addi	sp,sp,-32
    80003978:	ec06                	sd	ra,24(sp)
    8000397a:	e822                	sd	s0,16(sp)
    8000397c:	e426                	sd	s1,8(sp)
    8000397e:	e04a                	sd	s2,0(sp)
    80003980:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003982:	c905                	beqz	a0,800039b2 <iunlock+0x3c>
    80003984:	84aa                	mv	s1,a0
    80003986:	01050913          	addi	s2,a0,16
    8000398a:	854a                	mv	a0,s2
    8000398c:	00001097          	auipc	ra,0x1
    80003990:	c8c080e7          	jalr	-884(ra) # 80004618 <holdingsleep>
    80003994:	cd19                	beqz	a0,800039b2 <iunlock+0x3c>
    80003996:	449c                	lw	a5,8(s1)
    80003998:	00f05d63          	blez	a5,800039b2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000399c:	854a                	mv	a0,s2
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	c36080e7          	jalr	-970(ra) # 800045d4 <releasesleep>
}
    800039a6:	60e2                	ld	ra,24(sp)
    800039a8:	6442                	ld	s0,16(sp)
    800039aa:	64a2                	ld	s1,8(sp)
    800039ac:	6902                	ld	s2,0(sp)
    800039ae:	6105                	addi	sp,sp,32
    800039b0:	8082                	ret
    panic("iunlock");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	d1e50513          	addi	a0,a0,-738 # 800086d0 <syscalls+0x1a8>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>

00000000800039c2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039c2:	7179                	addi	sp,sp,-48
    800039c4:	f406                	sd	ra,40(sp)
    800039c6:	f022                	sd	s0,32(sp)
    800039c8:	ec26                	sd	s1,24(sp)
    800039ca:	e84a                	sd	s2,16(sp)
    800039cc:	e44e                	sd	s3,8(sp)
    800039ce:	e052                	sd	s4,0(sp)
    800039d0:	1800                	addi	s0,sp,48
    800039d2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039d4:	05050493          	addi	s1,a0,80
    800039d8:	08050913          	addi	s2,a0,128
    800039dc:	a021                	j	800039e4 <itrunc+0x22>
    800039de:	0491                	addi	s1,s1,4
    800039e0:	01248d63          	beq	s1,s2,800039fa <itrunc+0x38>
    if(ip->addrs[i]){
    800039e4:	408c                	lw	a1,0(s1)
    800039e6:	dde5                	beqz	a1,800039de <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039e8:	0009a503          	lw	a0,0(s3)
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	90c080e7          	jalr	-1780(ra) # 800032f8 <bfree>
      ip->addrs[i] = 0;
    800039f4:	0004a023          	sw	zero,0(s1)
    800039f8:	b7dd                	j	800039de <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039fa:	0809a583          	lw	a1,128(s3)
    800039fe:	e185                	bnez	a1,80003a1e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a00:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a04:	854e                	mv	a0,s3
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	de4080e7          	jalr	-540(ra) # 800037ea <iupdate>
}
    80003a0e:	70a2                	ld	ra,40(sp)
    80003a10:	7402                	ld	s0,32(sp)
    80003a12:	64e2                	ld	s1,24(sp)
    80003a14:	6942                	ld	s2,16(sp)
    80003a16:	69a2                	ld	s3,8(sp)
    80003a18:	6a02                	ld	s4,0(sp)
    80003a1a:	6145                	addi	sp,sp,48
    80003a1c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a1e:	0009a503          	lw	a0,0(s3)
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	690080e7          	jalr	1680(ra) # 800030b2 <bread>
    80003a2a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a2c:	05850493          	addi	s1,a0,88
    80003a30:	45850913          	addi	s2,a0,1112
    80003a34:	a811                	j	80003a48 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a36:	0009a503          	lw	a0,0(s3)
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	8be080e7          	jalr	-1858(ra) # 800032f8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a42:	0491                	addi	s1,s1,4
    80003a44:	01248563          	beq	s1,s2,80003a4e <itrunc+0x8c>
      if(a[j])
    80003a48:	408c                	lw	a1,0(s1)
    80003a4a:	dde5                	beqz	a1,80003a42 <itrunc+0x80>
    80003a4c:	b7ed                	j	80003a36 <itrunc+0x74>
    brelse(bp);
    80003a4e:	8552                	mv	a0,s4
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	792080e7          	jalr	1938(ra) # 800031e2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a58:	0809a583          	lw	a1,128(s3)
    80003a5c:	0009a503          	lw	a0,0(s3)
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	898080e7          	jalr	-1896(ra) # 800032f8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a68:	0809a023          	sw	zero,128(s3)
    80003a6c:	bf51                	j	80003a00 <itrunc+0x3e>

0000000080003a6e <iput>:
{
    80003a6e:	1101                	addi	sp,sp,-32
    80003a70:	ec06                	sd	ra,24(sp)
    80003a72:	e822                	sd	s0,16(sp)
    80003a74:	e426                	sd	s1,8(sp)
    80003a76:	e04a                	sd	s2,0(sp)
    80003a78:	1000                	addi	s0,sp,32
    80003a7a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a7c:	0001c517          	auipc	a0,0x1c
    80003a80:	74c50513          	addi	a0,a0,1868 # 800201c8 <itable>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	160080e7          	jalr	352(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a8c:	4498                	lw	a4,8(s1)
    80003a8e:	4785                	li	a5,1
    80003a90:	02f70363          	beq	a4,a5,80003ab6 <iput+0x48>
  ip->ref--;
    80003a94:	449c                	lw	a5,8(s1)
    80003a96:	37fd                	addiw	a5,a5,-1
    80003a98:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a9a:	0001c517          	auipc	a0,0x1c
    80003a9e:	72e50513          	addi	a0,a0,1838 # 800201c8 <itable>
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	1f6080e7          	jalr	502(ra) # 80000c98 <release>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6902                	ld	s2,0(sp)
    80003ab2:	6105                	addi	sp,sp,32
    80003ab4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab6:	40bc                	lw	a5,64(s1)
    80003ab8:	dff1                	beqz	a5,80003a94 <iput+0x26>
    80003aba:	04a49783          	lh	a5,74(s1)
    80003abe:	fbf9                	bnez	a5,80003a94 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ac0:	01048913          	addi	s2,s1,16
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00001097          	auipc	ra,0x1
    80003aca:	ab8080e7          	jalr	-1352(ra) # 8000457e <acquiresleep>
    release(&itable.lock);
    80003ace:	0001c517          	auipc	a0,0x1c
    80003ad2:	6fa50513          	addi	a0,a0,1786 # 800201c8 <itable>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	1c2080e7          	jalr	450(ra) # 80000c98 <release>
    itrunc(ip);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	ee2080e7          	jalr	-286(ra) # 800039c2 <itrunc>
    ip->type = 0;
    80003ae8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	cfc080e7          	jalr	-772(ra) # 800037ea <iupdate>
    ip->valid = 0;
    80003af6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003afa:	854a                	mv	a0,s2
    80003afc:	00001097          	auipc	ra,0x1
    80003b00:	ad8080e7          	jalr	-1320(ra) # 800045d4 <releasesleep>
    acquire(&itable.lock);
    80003b04:	0001c517          	auipc	a0,0x1c
    80003b08:	6c450513          	addi	a0,a0,1732 # 800201c8 <itable>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	0d8080e7          	jalr	216(ra) # 80000be4 <acquire>
    80003b14:	b741                	j	80003a94 <iput+0x26>

0000000080003b16 <iunlockput>:
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	1000                	addi	s0,sp,32
    80003b20:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	e54080e7          	jalr	-428(ra) # 80003976 <iunlock>
  iput(ip);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	f42080e7          	jalr	-190(ra) # 80003a6e <iput>
}
    80003b34:	60e2                	ld	ra,24(sp)
    80003b36:	6442                	ld	s0,16(sp)
    80003b38:	64a2                	ld	s1,8(sp)
    80003b3a:	6105                	addi	sp,sp,32
    80003b3c:	8082                	ret

0000000080003b3e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b3e:	1141                	addi	sp,sp,-16
    80003b40:	e422                	sd	s0,8(sp)
    80003b42:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b44:	411c                	lw	a5,0(a0)
    80003b46:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b48:	415c                	lw	a5,4(a0)
    80003b4a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b4c:	04451783          	lh	a5,68(a0)
    80003b50:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b54:	04a51783          	lh	a5,74(a0)
    80003b58:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b5c:	04c56783          	lwu	a5,76(a0)
    80003b60:	e99c                	sd	a5,16(a1)
}
    80003b62:	6422                	ld	s0,8(sp)
    80003b64:	0141                	addi	sp,sp,16
    80003b66:	8082                	ret

0000000080003b68 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b68:	457c                	lw	a5,76(a0)
    80003b6a:	0ed7e963          	bltu	a5,a3,80003c5c <readi+0xf4>
{
    80003b6e:	7159                	addi	sp,sp,-112
    80003b70:	f486                	sd	ra,104(sp)
    80003b72:	f0a2                	sd	s0,96(sp)
    80003b74:	eca6                	sd	s1,88(sp)
    80003b76:	e8ca                	sd	s2,80(sp)
    80003b78:	e4ce                	sd	s3,72(sp)
    80003b7a:	e0d2                	sd	s4,64(sp)
    80003b7c:	fc56                	sd	s5,56(sp)
    80003b7e:	f85a                	sd	s6,48(sp)
    80003b80:	f45e                	sd	s7,40(sp)
    80003b82:	f062                	sd	s8,32(sp)
    80003b84:	ec66                	sd	s9,24(sp)
    80003b86:	e86a                	sd	s10,16(sp)
    80003b88:	e46e                	sd	s11,8(sp)
    80003b8a:	1880                	addi	s0,sp,112
    80003b8c:	8baa                	mv	s7,a0
    80003b8e:	8c2e                	mv	s8,a1
    80003b90:	8ab2                	mv	s5,a2
    80003b92:	84b6                	mv	s1,a3
    80003b94:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b96:	9f35                	addw	a4,a4,a3
    return 0;
    80003b98:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b9a:	0ad76063          	bltu	a4,a3,80003c3a <readi+0xd2>
  if(off + n > ip->size)
    80003b9e:	00e7f463          	bgeu	a5,a4,80003ba6 <readi+0x3e>
    n = ip->size - off;
    80003ba2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba6:	0a0b0963          	beqz	s6,80003c58 <readi+0xf0>
    80003baa:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bac:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bb0:	5cfd                	li	s9,-1
    80003bb2:	a82d                	j	80003bec <readi+0x84>
    80003bb4:	020a1d93          	slli	s11,s4,0x20
    80003bb8:	020ddd93          	srli	s11,s11,0x20
    80003bbc:	05890613          	addi	a2,s2,88
    80003bc0:	86ee                	mv	a3,s11
    80003bc2:	963a                	add	a2,a2,a4
    80003bc4:	85d6                	mv	a1,s5
    80003bc6:	8562                	mv	a0,s8
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	8b2080e7          	jalr	-1870(ra) # 8000247a <either_copyout>
    80003bd0:	05950d63          	beq	a0,s9,80003c2a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	60c080e7          	jalr	1548(ra) # 800031e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bde:	013a09bb          	addw	s3,s4,s3
    80003be2:	009a04bb          	addw	s1,s4,s1
    80003be6:	9aee                	add	s5,s5,s11
    80003be8:	0569f763          	bgeu	s3,s6,80003c36 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bec:	000ba903          	lw	s2,0(s7)
    80003bf0:	00a4d59b          	srliw	a1,s1,0xa
    80003bf4:	855e                	mv	a0,s7
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	8b0080e7          	jalr	-1872(ra) # 800034a6 <bmap>
    80003bfe:	0005059b          	sext.w	a1,a0
    80003c02:	854a                	mv	a0,s2
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	4ae080e7          	jalr	1198(ra) # 800030b2 <bread>
    80003c0c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0e:	3ff4f713          	andi	a4,s1,1023
    80003c12:	40ed07bb          	subw	a5,s10,a4
    80003c16:	413b06bb          	subw	a3,s6,s3
    80003c1a:	8a3e                	mv	s4,a5
    80003c1c:	2781                	sext.w	a5,a5
    80003c1e:	0006861b          	sext.w	a2,a3
    80003c22:	f8f679e3          	bgeu	a2,a5,80003bb4 <readi+0x4c>
    80003c26:	8a36                	mv	s4,a3
    80003c28:	b771                	j	80003bb4 <readi+0x4c>
      brelse(bp);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	fffff097          	auipc	ra,0xfffff
    80003c30:	5b6080e7          	jalr	1462(ra) # 800031e2 <brelse>
      tot = -1;
    80003c34:	59fd                	li	s3,-1
  }
  return tot;
    80003c36:	0009851b          	sext.w	a0,s3
}
    80003c3a:	70a6                	ld	ra,104(sp)
    80003c3c:	7406                	ld	s0,96(sp)
    80003c3e:	64e6                	ld	s1,88(sp)
    80003c40:	6946                	ld	s2,80(sp)
    80003c42:	69a6                	ld	s3,72(sp)
    80003c44:	6a06                	ld	s4,64(sp)
    80003c46:	7ae2                	ld	s5,56(sp)
    80003c48:	7b42                	ld	s6,48(sp)
    80003c4a:	7ba2                	ld	s7,40(sp)
    80003c4c:	7c02                	ld	s8,32(sp)
    80003c4e:	6ce2                	ld	s9,24(sp)
    80003c50:	6d42                	ld	s10,16(sp)
    80003c52:	6da2                	ld	s11,8(sp)
    80003c54:	6165                	addi	sp,sp,112
    80003c56:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c58:	89da                	mv	s3,s6
    80003c5a:	bff1                	j	80003c36 <readi+0xce>
    return 0;
    80003c5c:	4501                	li	a0,0
}
    80003c5e:	8082                	ret

0000000080003c60 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c60:	457c                	lw	a5,76(a0)
    80003c62:	10d7e863          	bltu	a5,a3,80003d72 <writei+0x112>
{
    80003c66:	7159                	addi	sp,sp,-112
    80003c68:	f486                	sd	ra,104(sp)
    80003c6a:	f0a2                	sd	s0,96(sp)
    80003c6c:	eca6                	sd	s1,88(sp)
    80003c6e:	e8ca                	sd	s2,80(sp)
    80003c70:	e4ce                	sd	s3,72(sp)
    80003c72:	e0d2                	sd	s4,64(sp)
    80003c74:	fc56                	sd	s5,56(sp)
    80003c76:	f85a                	sd	s6,48(sp)
    80003c78:	f45e                	sd	s7,40(sp)
    80003c7a:	f062                	sd	s8,32(sp)
    80003c7c:	ec66                	sd	s9,24(sp)
    80003c7e:	e86a                	sd	s10,16(sp)
    80003c80:	e46e                	sd	s11,8(sp)
    80003c82:	1880                	addi	s0,sp,112
    80003c84:	8b2a                	mv	s6,a0
    80003c86:	8c2e                	mv	s8,a1
    80003c88:	8ab2                	mv	s5,a2
    80003c8a:	8936                	mv	s2,a3
    80003c8c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c8e:	00e687bb          	addw	a5,a3,a4
    80003c92:	0ed7e263          	bltu	a5,a3,80003d76 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c96:	00043737          	lui	a4,0x43
    80003c9a:	0ef76063          	bltu	a4,a5,80003d7a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9e:	0c0b8863          	beqz	s7,80003d6e <writei+0x10e>
    80003ca2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ca8:	5cfd                	li	s9,-1
    80003caa:	a091                	j	80003cee <writei+0x8e>
    80003cac:	02099d93          	slli	s11,s3,0x20
    80003cb0:	020ddd93          	srli	s11,s11,0x20
    80003cb4:	05848513          	addi	a0,s1,88
    80003cb8:	86ee                	mv	a3,s11
    80003cba:	8656                	mv	a2,s5
    80003cbc:	85e2                	mv	a1,s8
    80003cbe:	953a                	add	a0,a0,a4
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	810080e7          	jalr	-2032(ra) # 800024d0 <either_copyin>
    80003cc8:	07950263          	beq	a0,s9,80003d2c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ccc:	8526                	mv	a0,s1
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	790080e7          	jalr	1936(ra) # 8000445e <log_write>
    brelse(bp);
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	50a080e7          	jalr	1290(ra) # 800031e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce0:	01498a3b          	addw	s4,s3,s4
    80003ce4:	0129893b          	addw	s2,s3,s2
    80003ce8:	9aee                	add	s5,s5,s11
    80003cea:	057a7663          	bgeu	s4,s7,80003d36 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cee:	000b2483          	lw	s1,0(s6)
    80003cf2:	00a9559b          	srliw	a1,s2,0xa
    80003cf6:	855a                	mv	a0,s6
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	7ae080e7          	jalr	1966(ra) # 800034a6 <bmap>
    80003d00:	0005059b          	sext.w	a1,a0
    80003d04:	8526                	mv	a0,s1
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	3ac080e7          	jalr	940(ra) # 800030b2 <bread>
    80003d0e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d10:	3ff97713          	andi	a4,s2,1023
    80003d14:	40ed07bb          	subw	a5,s10,a4
    80003d18:	414b86bb          	subw	a3,s7,s4
    80003d1c:	89be                	mv	s3,a5
    80003d1e:	2781                	sext.w	a5,a5
    80003d20:	0006861b          	sext.w	a2,a3
    80003d24:	f8f674e3          	bgeu	a2,a5,80003cac <writei+0x4c>
    80003d28:	89b6                	mv	s3,a3
    80003d2a:	b749                	j	80003cac <writei+0x4c>
      brelse(bp);
    80003d2c:	8526                	mv	a0,s1
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	4b4080e7          	jalr	1204(ra) # 800031e2 <brelse>
  }

  if(off > ip->size)
    80003d36:	04cb2783          	lw	a5,76(s6)
    80003d3a:	0127f463          	bgeu	a5,s2,80003d42 <writei+0xe2>
    ip->size = off;
    80003d3e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d42:	855a                	mv	a0,s6
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	aa6080e7          	jalr	-1370(ra) # 800037ea <iupdate>

  return tot;
    80003d4c:	000a051b          	sext.w	a0,s4
}
    80003d50:	70a6                	ld	ra,104(sp)
    80003d52:	7406                	ld	s0,96(sp)
    80003d54:	64e6                	ld	s1,88(sp)
    80003d56:	6946                	ld	s2,80(sp)
    80003d58:	69a6                	ld	s3,72(sp)
    80003d5a:	6a06                	ld	s4,64(sp)
    80003d5c:	7ae2                	ld	s5,56(sp)
    80003d5e:	7b42                	ld	s6,48(sp)
    80003d60:	7ba2                	ld	s7,40(sp)
    80003d62:	7c02                	ld	s8,32(sp)
    80003d64:	6ce2                	ld	s9,24(sp)
    80003d66:	6d42                	ld	s10,16(sp)
    80003d68:	6da2                	ld	s11,8(sp)
    80003d6a:	6165                	addi	sp,sp,112
    80003d6c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6e:	8a5e                	mv	s4,s7
    80003d70:	bfc9                	j	80003d42 <writei+0xe2>
    return -1;
    80003d72:	557d                	li	a0,-1
}
    80003d74:	8082                	ret
    return -1;
    80003d76:	557d                	li	a0,-1
    80003d78:	bfe1                	j	80003d50 <writei+0xf0>
    return -1;
    80003d7a:	557d                	li	a0,-1
    80003d7c:	bfd1                	j	80003d50 <writei+0xf0>

0000000080003d7e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d7e:	1141                	addi	sp,sp,-16
    80003d80:	e406                	sd	ra,8(sp)
    80003d82:	e022                	sd	s0,0(sp)
    80003d84:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d86:	4639                	li	a2,14
    80003d88:	ffffd097          	auipc	ra,0xffffd
    80003d8c:	030080e7          	jalr	48(ra) # 80000db8 <strncmp>
}
    80003d90:	60a2                	ld	ra,8(sp)
    80003d92:	6402                	ld	s0,0(sp)
    80003d94:	0141                	addi	sp,sp,16
    80003d96:	8082                	ret

0000000080003d98 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d98:	7139                	addi	sp,sp,-64
    80003d9a:	fc06                	sd	ra,56(sp)
    80003d9c:	f822                	sd	s0,48(sp)
    80003d9e:	f426                	sd	s1,40(sp)
    80003da0:	f04a                	sd	s2,32(sp)
    80003da2:	ec4e                	sd	s3,24(sp)
    80003da4:	e852                	sd	s4,16(sp)
    80003da6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003da8:	04451703          	lh	a4,68(a0)
    80003dac:	4785                	li	a5,1
    80003dae:	00f71a63          	bne	a4,a5,80003dc2 <dirlookup+0x2a>
    80003db2:	892a                	mv	s2,a0
    80003db4:	89ae                	mv	s3,a1
    80003db6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db8:	457c                	lw	a5,76(a0)
    80003dba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dbc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbe:	e79d                	bnez	a5,80003dec <dirlookup+0x54>
    80003dc0:	a8a5                	j	80003e38 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	91650513          	addi	a0,a0,-1770 # 800086d8 <syscalls+0x1b0>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dd2:	00005517          	auipc	a0,0x5
    80003dd6:	91e50513          	addi	a0,a0,-1762 # 800086f0 <syscalls+0x1c8>
    80003dda:	ffffc097          	auipc	ra,0xffffc
    80003dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de2:	24c1                	addiw	s1,s1,16
    80003de4:	04c92783          	lw	a5,76(s2)
    80003de8:	04f4f763          	bgeu	s1,a5,80003e36 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dec:	4741                	li	a4,16
    80003dee:	86a6                	mv	a3,s1
    80003df0:	fc040613          	addi	a2,s0,-64
    80003df4:	4581                	li	a1,0
    80003df6:	854a                	mv	a0,s2
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	d70080e7          	jalr	-656(ra) # 80003b68 <readi>
    80003e00:	47c1                	li	a5,16
    80003e02:	fcf518e3          	bne	a0,a5,80003dd2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e06:	fc045783          	lhu	a5,-64(s0)
    80003e0a:	dfe1                	beqz	a5,80003de2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e0c:	fc240593          	addi	a1,s0,-62
    80003e10:	854e                	mv	a0,s3
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	f6c080e7          	jalr	-148(ra) # 80003d7e <namecmp>
    80003e1a:	f561                	bnez	a0,80003de2 <dirlookup+0x4a>
      if(poff)
    80003e1c:	000a0463          	beqz	s4,80003e24 <dirlookup+0x8c>
        *poff = off;
    80003e20:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e24:	fc045583          	lhu	a1,-64(s0)
    80003e28:	00092503          	lw	a0,0(s2)
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	754080e7          	jalr	1876(ra) # 80003580 <iget>
    80003e34:	a011                	j	80003e38 <dirlookup+0xa0>
  return 0;
    80003e36:	4501                	li	a0,0
}
    80003e38:	70e2                	ld	ra,56(sp)
    80003e3a:	7442                	ld	s0,48(sp)
    80003e3c:	74a2                	ld	s1,40(sp)
    80003e3e:	7902                	ld	s2,32(sp)
    80003e40:	69e2                	ld	s3,24(sp)
    80003e42:	6a42                	ld	s4,16(sp)
    80003e44:	6121                	addi	sp,sp,64
    80003e46:	8082                	ret

0000000080003e48 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e48:	711d                	addi	sp,sp,-96
    80003e4a:	ec86                	sd	ra,88(sp)
    80003e4c:	e8a2                	sd	s0,80(sp)
    80003e4e:	e4a6                	sd	s1,72(sp)
    80003e50:	e0ca                	sd	s2,64(sp)
    80003e52:	fc4e                	sd	s3,56(sp)
    80003e54:	f852                	sd	s4,48(sp)
    80003e56:	f456                	sd	s5,40(sp)
    80003e58:	f05a                	sd	s6,32(sp)
    80003e5a:	ec5e                	sd	s7,24(sp)
    80003e5c:	e862                	sd	s8,16(sp)
    80003e5e:	e466                	sd	s9,8(sp)
    80003e60:	1080                	addi	s0,sp,96
    80003e62:	84aa                	mv	s1,a0
    80003e64:	8b2e                	mv	s6,a1
    80003e66:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e68:	00054703          	lbu	a4,0(a0)
    80003e6c:	02f00793          	li	a5,47
    80003e70:	02f70363          	beq	a4,a5,80003e96 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e74:	ffffe097          	auipc	ra,0xffffe
    80003e78:	b3c080e7          	jalr	-1220(ra) # 800019b0 <myproc>
    80003e7c:	17853503          	ld	a0,376(a0)
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	9f6080e7          	jalr	-1546(ra) # 80003876 <idup>
    80003e88:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e8a:	02f00913          	li	s2,47
  len = path - s;
    80003e8e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e90:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e92:	4c05                	li	s8,1
    80003e94:	a865                	j	80003f4c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e96:	4585                	li	a1,1
    80003e98:	4505                	li	a0,1
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	6e6080e7          	jalr	1766(ra) # 80003580 <iget>
    80003ea2:	89aa                	mv	s3,a0
    80003ea4:	b7dd                	j	80003e8a <namex+0x42>
      iunlockput(ip);
    80003ea6:	854e                	mv	a0,s3
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	c6e080e7          	jalr	-914(ra) # 80003b16 <iunlockput>
      return 0;
    80003eb0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	60e6                	ld	ra,88(sp)
    80003eb6:	6446                	ld	s0,80(sp)
    80003eb8:	64a6                	ld	s1,72(sp)
    80003eba:	6906                	ld	s2,64(sp)
    80003ebc:	79e2                	ld	s3,56(sp)
    80003ebe:	7a42                	ld	s4,48(sp)
    80003ec0:	7aa2                	ld	s5,40(sp)
    80003ec2:	7b02                	ld	s6,32(sp)
    80003ec4:	6be2                	ld	s7,24(sp)
    80003ec6:	6c42                	ld	s8,16(sp)
    80003ec8:	6ca2                	ld	s9,8(sp)
    80003eca:	6125                	addi	sp,sp,96
    80003ecc:	8082                	ret
      iunlock(ip);
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	aa6080e7          	jalr	-1370(ra) # 80003976 <iunlock>
      return ip;
    80003ed8:	bfe9                	j	80003eb2 <namex+0x6a>
      iunlockput(ip);
    80003eda:	854e                	mv	a0,s3
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	c3a080e7          	jalr	-966(ra) # 80003b16 <iunlockput>
      return 0;
    80003ee4:	89d2                	mv	s3,s4
    80003ee6:	b7f1                	j	80003eb2 <namex+0x6a>
  len = path - s;
    80003ee8:	40b48633          	sub	a2,s1,a1
    80003eec:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ef0:	094cd463          	bge	s9,s4,80003f78 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef4:	4639                	li	a2,14
    80003ef6:	8556                	mv	a0,s5
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e48080e7          	jalr	-440(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f00:	0004c783          	lbu	a5,0(s1)
    80003f04:	01279763          	bne	a5,s2,80003f12 <namex+0xca>
    path++;
    80003f08:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0a:	0004c783          	lbu	a5,0(s1)
    80003f0e:	ff278de3          	beq	a5,s2,80003f08 <namex+0xc0>
    ilock(ip);
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	9a0080e7          	jalr	-1632(ra) # 800038b4 <ilock>
    if(ip->type != T_DIR){
    80003f1c:	04499783          	lh	a5,68(s3)
    80003f20:	f98793e3          	bne	a5,s8,80003ea6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f24:	000b0563          	beqz	s6,80003f2e <namex+0xe6>
    80003f28:	0004c783          	lbu	a5,0(s1)
    80003f2c:	d3cd                	beqz	a5,80003ece <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f2e:	865e                	mv	a2,s7
    80003f30:	85d6                	mv	a1,s5
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	e64080e7          	jalr	-412(ra) # 80003d98 <dirlookup>
    80003f3c:	8a2a                	mv	s4,a0
    80003f3e:	dd51                	beqz	a0,80003eda <namex+0x92>
    iunlockput(ip);
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	bd4080e7          	jalr	-1068(ra) # 80003b16 <iunlockput>
    ip = next;
    80003f4a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f4c:	0004c783          	lbu	a5,0(s1)
    80003f50:	05279763          	bne	a5,s2,80003f9e <namex+0x156>
    path++;
    80003f54:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f56:	0004c783          	lbu	a5,0(s1)
    80003f5a:	ff278de3          	beq	a5,s2,80003f54 <namex+0x10c>
  if(*path == 0)
    80003f5e:	c79d                	beqz	a5,80003f8c <namex+0x144>
    path++;
    80003f60:	85a6                	mv	a1,s1
  len = path - s;
    80003f62:	8a5e                	mv	s4,s7
    80003f64:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f66:	01278963          	beq	a5,s2,80003f78 <namex+0x130>
    80003f6a:	dfbd                	beqz	a5,80003ee8 <namex+0xa0>
    path++;
    80003f6c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f6e:	0004c783          	lbu	a5,0(s1)
    80003f72:	ff279ce3          	bne	a5,s2,80003f6a <namex+0x122>
    80003f76:	bf8d                	j	80003ee8 <namex+0xa0>
    memmove(name, s, len);
    80003f78:	2601                	sext.w	a2,a2
    80003f7a:	8556                	mv	a0,s5
    80003f7c:	ffffd097          	auipc	ra,0xffffd
    80003f80:	dc4080e7          	jalr	-572(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f84:	9a56                	add	s4,s4,s5
    80003f86:	000a0023          	sb	zero,0(s4)
    80003f8a:	bf9d                	j	80003f00 <namex+0xb8>
  if(nameiparent){
    80003f8c:	f20b03e3          	beqz	s6,80003eb2 <namex+0x6a>
    iput(ip);
    80003f90:	854e                	mv	a0,s3
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	adc080e7          	jalr	-1316(ra) # 80003a6e <iput>
    return 0;
    80003f9a:	4981                	li	s3,0
    80003f9c:	bf19                	j	80003eb2 <namex+0x6a>
  if(*path == 0)
    80003f9e:	d7fd                	beqz	a5,80003f8c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	85a6                	mv	a1,s1
    80003fa6:	b7d1                	j	80003f6a <namex+0x122>

0000000080003fa8 <dirlink>:
{
    80003fa8:	7139                	addi	sp,sp,-64
    80003faa:	fc06                	sd	ra,56(sp)
    80003fac:	f822                	sd	s0,48(sp)
    80003fae:	f426                	sd	s1,40(sp)
    80003fb0:	f04a                	sd	s2,32(sp)
    80003fb2:	ec4e                	sd	s3,24(sp)
    80003fb4:	e852                	sd	s4,16(sp)
    80003fb6:	0080                	addi	s0,sp,64
    80003fb8:	892a                	mv	s2,a0
    80003fba:	8a2e                	mv	s4,a1
    80003fbc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fbe:	4601                	li	a2,0
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	dd8080e7          	jalr	-552(ra) # 80003d98 <dirlookup>
    80003fc8:	e93d                	bnez	a0,8000403e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fca:	04c92483          	lw	s1,76(s2)
    80003fce:	c49d                	beqz	s1,80003ffc <dirlink+0x54>
    80003fd0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd2:	4741                	li	a4,16
    80003fd4:	86a6                	mv	a3,s1
    80003fd6:	fc040613          	addi	a2,s0,-64
    80003fda:	4581                	li	a1,0
    80003fdc:	854a                	mv	a0,s2
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	b8a080e7          	jalr	-1142(ra) # 80003b68 <readi>
    80003fe6:	47c1                	li	a5,16
    80003fe8:	06f51163          	bne	a0,a5,8000404a <dirlink+0xa2>
    if(de.inum == 0)
    80003fec:	fc045783          	lhu	a5,-64(s0)
    80003ff0:	c791                	beqz	a5,80003ffc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	24c1                	addiw	s1,s1,16
    80003ff4:	04c92783          	lw	a5,76(s2)
    80003ff8:	fcf4ede3          	bltu	s1,a5,80003fd2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ffc:	4639                	li	a2,14
    80003ffe:	85d2                	mv	a1,s4
    80004000:	fc240513          	addi	a0,s0,-62
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	df0080e7          	jalr	-528(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000400c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004010:	4741                	li	a4,16
    80004012:	86a6                	mv	a3,s1
    80004014:	fc040613          	addi	a2,s0,-64
    80004018:	4581                	li	a1,0
    8000401a:	854a                	mv	a0,s2
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	c44080e7          	jalr	-956(ra) # 80003c60 <writei>
    80004024:	872a                	mv	a4,a0
    80004026:	47c1                	li	a5,16
  return 0;
    80004028:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402a:	02f71863          	bne	a4,a5,8000405a <dirlink+0xb2>
}
    8000402e:	70e2                	ld	ra,56(sp)
    80004030:	7442                	ld	s0,48(sp)
    80004032:	74a2                	ld	s1,40(sp)
    80004034:	7902                	ld	s2,32(sp)
    80004036:	69e2                	ld	s3,24(sp)
    80004038:	6a42                	ld	s4,16(sp)
    8000403a:	6121                	addi	sp,sp,64
    8000403c:	8082                	ret
    iput(ip);
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	a30080e7          	jalr	-1488(ra) # 80003a6e <iput>
    return -1;
    80004046:	557d                	li	a0,-1
    80004048:	b7dd                	j	8000402e <dirlink+0x86>
      panic("dirlink read");
    8000404a:	00004517          	auipc	a0,0x4
    8000404e:	6b650513          	addi	a0,a0,1718 # 80008700 <syscalls+0x1d8>
    80004052:	ffffc097          	auipc	ra,0xffffc
    80004056:	4ec080e7          	jalr	1260(ra) # 8000053e <panic>
    panic("dirlink");
    8000405a:	00004517          	auipc	a0,0x4
    8000405e:	7ae50513          	addi	a0,a0,1966 # 80008808 <syscalls+0x2e0>
    80004062:	ffffc097          	auipc	ra,0xffffc
    80004066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>

000000008000406a <namei>:

struct inode*
namei(char *path)
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004072:	fe040613          	addi	a2,s0,-32
    80004076:	4581                	li	a1,0
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	dd0080e7          	jalr	-560(ra) # 80003e48 <namex>
}
    80004080:	60e2                	ld	ra,24(sp)
    80004082:	6442                	ld	s0,16(sp)
    80004084:	6105                	addi	sp,sp,32
    80004086:	8082                	ret

0000000080004088 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004088:	1141                	addi	sp,sp,-16
    8000408a:	e406                	sd	ra,8(sp)
    8000408c:	e022                	sd	s0,0(sp)
    8000408e:	0800                	addi	s0,sp,16
    80004090:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004092:	4585                	li	a1,1
    80004094:	00000097          	auipc	ra,0x0
    80004098:	db4080e7          	jalr	-588(ra) # 80003e48 <namex>
}
    8000409c:	60a2                	ld	ra,8(sp)
    8000409e:	6402                	ld	s0,0(sp)
    800040a0:	0141                	addi	sp,sp,16
    800040a2:	8082                	ret

00000000800040a4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040a4:	1101                	addi	sp,sp,-32
    800040a6:	ec06                	sd	ra,24(sp)
    800040a8:	e822                	sd	s0,16(sp)
    800040aa:	e426                	sd	s1,8(sp)
    800040ac:	e04a                	sd	s2,0(sp)
    800040ae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040b0:	0001e917          	auipc	s2,0x1e
    800040b4:	bc090913          	addi	s2,s2,-1088 # 80021c70 <log>
    800040b8:	01892583          	lw	a1,24(s2)
    800040bc:	02892503          	lw	a0,40(s2)
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	ff2080e7          	jalr	-14(ra) # 800030b2 <bread>
    800040c8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ca:	02c92683          	lw	a3,44(s2)
    800040ce:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040d0:	02d05763          	blez	a3,800040fe <write_head+0x5a>
    800040d4:	0001e797          	auipc	a5,0x1e
    800040d8:	bcc78793          	addi	a5,a5,-1076 # 80021ca0 <log+0x30>
    800040dc:	05c50713          	addi	a4,a0,92
    800040e0:	36fd                	addiw	a3,a3,-1
    800040e2:	1682                	slli	a3,a3,0x20
    800040e4:	9281                	srli	a3,a3,0x20
    800040e6:	068a                	slli	a3,a3,0x2
    800040e8:	0001e617          	auipc	a2,0x1e
    800040ec:	bbc60613          	addi	a2,a2,-1092 # 80021ca4 <log+0x34>
    800040f0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040f2:	4390                	lw	a2,0(a5)
    800040f4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040f6:	0791                	addi	a5,a5,4
    800040f8:	0711                	addi	a4,a4,4
    800040fa:	fed79ce3          	bne	a5,a3,800040f2 <write_head+0x4e>
  }
  bwrite(buf);
    800040fe:	8526                	mv	a0,s1
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	0a4080e7          	jalr	164(ra) # 800031a4 <bwrite>
  brelse(buf);
    80004108:	8526                	mv	a0,s1
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	0d8080e7          	jalr	216(ra) # 800031e2 <brelse>
}
    80004112:	60e2                	ld	ra,24(sp)
    80004114:	6442                	ld	s0,16(sp)
    80004116:	64a2                	ld	s1,8(sp)
    80004118:	6902                	ld	s2,0(sp)
    8000411a:	6105                	addi	sp,sp,32
    8000411c:	8082                	ret

000000008000411e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411e:	0001e797          	auipc	a5,0x1e
    80004122:	b7e7a783          	lw	a5,-1154(a5) # 80021c9c <log+0x2c>
    80004126:	0af05d63          	blez	a5,800041e0 <install_trans+0xc2>
{
    8000412a:	7139                	addi	sp,sp,-64
    8000412c:	fc06                	sd	ra,56(sp)
    8000412e:	f822                	sd	s0,48(sp)
    80004130:	f426                	sd	s1,40(sp)
    80004132:	f04a                	sd	s2,32(sp)
    80004134:	ec4e                	sd	s3,24(sp)
    80004136:	e852                	sd	s4,16(sp)
    80004138:	e456                	sd	s5,8(sp)
    8000413a:	e05a                	sd	s6,0(sp)
    8000413c:	0080                	addi	s0,sp,64
    8000413e:	8b2a                	mv	s6,a0
    80004140:	0001ea97          	auipc	s5,0x1e
    80004144:	b60a8a93          	addi	s5,s5,-1184 # 80021ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004148:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000414a:	0001e997          	auipc	s3,0x1e
    8000414e:	b2698993          	addi	s3,s3,-1242 # 80021c70 <log>
    80004152:	a035                	j	8000417e <install_trans+0x60>
      bunpin(dbuf);
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	166080e7          	jalr	358(ra) # 800032bc <bunpin>
    brelse(lbuf);
    8000415e:	854a                	mv	a0,s2
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	082080e7          	jalr	130(ra) # 800031e2 <brelse>
    brelse(dbuf);
    80004168:	8526                	mv	a0,s1
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	078080e7          	jalr	120(ra) # 800031e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004172:	2a05                	addiw	s4,s4,1
    80004174:	0a91                	addi	s5,s5,4
    80004176:	02c9a783          	lw	a5,44(s3)
    8000417a:	04fa5963          	bge	s4,a5,800041cc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000417e:	0189a583          	lw	a1,24(s3)
    80004182:	014585bb          	addw	a1,a1,s4
    80004186:	2585                	addiw	a1,a1,1
    80004188:	0289a503          	lw	a0,40(s3)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	f26080e7          	jalr	-218(ra) # 800030b2 <bread>
    80004194:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004196:	000aa583          	lw	a1,0(s5)
    8000419a:	0289a503          	lw	a0,40(s3)
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	f14080e7          	jalr	-236(ra) # 800030b2 <bread>
    800041a6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041a8:	40000613          	li	a2,1024
    800041ac:	05890593          	addi	a1,s2,88
    800041b0:	05850513          	addi	a0,a0,88
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b8c080e7          	jalr	-1140(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041bc:	8526                	mv	a0,s1
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	fe6080e7          	jalr	-26(ra) # 800031a4 <bwrite>
    if(recovering == 0)
    800041c6:	f80b1ce3          	bnez	s6,8000415e <install_trans+0x40>
    800041ca:	b769                	j	80004154 <install_trans+0x36>
}
    800041cc:	70e2                	ld	ra,56(sp)
    800041ce:	7442                	ld	s0,48(sp)
    800041d0:	74a2                	ld	s1,40(sp)
    800041d2:	7902                	ld	s2,32(sp)
    800041d4:	69e2                	ld	s3,24(sp)
    800041d6:	6a42                	ld	s4,16(sp)
    800041d8:	6aa2                	ld	s5,8(sp)
    800041da:	6b02                	ld	s6,0(sp)
    800041dc:	6121                	addi	sp,sp,64
    800041de:	8082                	ret
    800041e0:	8082                	ret

00000000800041e2 <initlog>:
{
    800041e2:	7179                	addi	sp,sp,-48
    800041e4:	f406                	sd	ra,40(sp)
    800041e6:	f022                	sd	s0,32(sp)
    800041e8:	ec26                	sd	s1,24(sp)
    800041ea:	e84a                	sd	s2,16(sp)
    800041ec:	e44e                	sd	s3,8(sp)
    800041ee:	1800                	addi	s0,sp,48
    800041f0:	892a                	mv	s2,a0
    800041f2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041f4:	0001e497          	auipc	s1,0x1e
    800041f8:	a7c48493          	addi	s1,s1,-1412 # 80021c70 <log>
    800041fc:	00004597          	auipc	a1,0x4
    80004200:	51458593          	addi	a1,a1,1300 # 80008710 <syscalls+0x1e8>
    80004204:	8526                	mv	a0,s1
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	94e080e7          	jalr	-1714(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000420e:	0149a583          	lw	a1,20(s3)
    80004212:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004214:	0109a783          	lw	a5,16(s3)
    80004218:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000421a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000421e:	854a                	mv	a0,s2
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	e92080e7          	jalr	-366(ra) # 800030b2 <bread>
  log.lh.n = lh->n;
    80004228:	4d3c                	lw	a5,88(a0)
    8000422a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000422c:	02f05563          	blez	a5,80004256 <initlog+0x74>
    80004230:	05c50713          	addi	a4,a0,92
    80004234:	0001e697          	auipc	a3,0x1e
    80004238:	a6c68693          	addi	a3,a3,-1428 # 80021ca0 <log+0x30>
    8000423c:	37fd                	addiw	a5,a5,-1
    8000423e:	1782                	slli	a5,a5,0x20
    80004240:	9381                	srli	a5,a5,0x20
    80004242:	078a                	slli	a5,a5,0x2
    80004244:	06050613          	addi	a2,a0,96
    80004248:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000424a:	4310                	lw	a2,0(a4)
    8000424c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000424e:	0711                	addi	a4,a4,4
    80004250:	0691                	addi	a3,a3,4
    80004252:	fef71ce3          	bne	a4,a5,8000424a <initlog+0x68>
  brelse(buf);
    80004256:	fffff097          	auipc	ra,0xfffff
    8000425a:	f8c080e7          	jalr	-116(ra) # 800031e2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000425e:	4505                	li	a0,1
    80004260:	00000097          	auipc	ra,0x0
    80004264:	ebe080e7          	jalr	-322(ra) # 8000411e <install_trans>
  log.lh.n = 0;
    80004268:	0001e797          	auipc	a5,0x1e
    8000426c:	a207aa23          	sw	zero,-1484(a5) # 80021c9c <log+0x2c>
  write_head(); // clear the log
    80004270:	00000097          	auipc	ra,0x0
    80004274:	e34080e7          	jalr	-460(ra) # 800040a4 <write_head>
}
    80004278:	70a2                	ld	ra,40(sp)
    8000427a:	7402                	ld	s0,32(sp)
    8000427c:	64e2                	ld	s1,24(sp)
    8000427e:	6942                	ld	s2,16(sp)
    80004280:	69a2                	ld	s3,8(sp)
    80004282:	6145                	addi	sp,sp,48
    80004284:	8082                	ret

0000000080004286 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004286:	1101                	addi	sp,sp,-32
    80004288:	ec06                	sd	ra,24(sp)
    8000428a:	e822                	sd	s0,16(sp)
    8000428c:	e426                	sd	s1,8(sp)
    8000428e:	e04a                	sd	s2,0(sp)
    80004290:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004292:	0001e517          	auipc	a0,0x1e
    80004296:	9de50513          	addi	a0,a0,-1570 # 80021c70 <log>
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	94a080e7          	jalr	-1718(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042a2:	0001e497          	auipc	s1,0x1e
    800042a6:	9ce48493          	addi	s1,s1,-1586 # 80021c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042aa:	4979                	li	s2,30
    800042ac:	a039                	j	800042ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800042ae:	85a6                	mv	a1,s1
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffe097          	auipc	ra,0xffffe
    800042b6:	dfc080e7          	jalr	-516(ra) # 800020ae <sleep>
    if(log.committing){
    800042ba:	50dc                	lw	a5,36(s1)
    800042bc:	fbed                	bnez	a5,800042ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042be:	509c                	lw	a5,32(s1)
    800042c0:	0017871b          	addiw	a4,a5,1
    800042c4:	0007069b          	sext.w	a3,a4
    800042c8:	0027179b          	slliw	a5,a4,0x2
    800042cc:	9fb9                	addw	a5,a5,a4
    800042ce:	0017979b          	slliw	a5,a5,0x1
    800042d2:	54d8                	lw	a4,44(s1)
    800042d4:	9fb9                	addw	a5,a5,a4
    800042d6:	00f95963          	bge	s2,a5,800042e8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042da:	85a6                	mv	a1,s1
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffe097          	auipc	ra,0xffffe
    800042e2:	dd0080e7          	jalr	-560(ra) # 800020ae <sleep>
    800042e6:	bfd1                	j	800042ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042e8:	0001e517          	auipc	a0,0x1e
    800042ec:	98850513          	addi	a0,a0,-1656 # 80021c70 <log>
    800042f0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	9a6080e7          	jalr	-1626(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042fa:	60e2                	ld	ra,24(sp)
    800042fc:	6442                	ld	s0,16(sp)
    800042fe:	64a2                	ld	s1,8(sp)
    80004300:	6902                	ld	s2,0(sp)
    80004302:	6105                	addi	sp,sp,32
    80004304:	8082                	ret

0000000080004306 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004306:	7139                	addi	sp,sp,-64
    80004308:	fc06                	sd	ra,56(sp)
    8000430a:	f822                	sd	s0,48(sp)
    8000430c:	f426                	sd	s1,40(sp)
    8000430e:	f04a                	sd	s2,32(sp)
    80004310:	ec4e                	sd	s3,24(sp)
    80004312:	e852                	sd	s4,16(sp)
    80004314:	e456                	sd	s5,8(sp)
    80004316:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004318:	0001e497          	auipc	s1,0x1e
    8000431c:	95848493          	addi	s1,s1,-1704 # 80021c70 <log>
    80004320:	8526                	mv	a0,s1
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8c2080e7          	jalr	-1854(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000432a:	509c                	lw	a5,32(s1)
    8000432c:	37fd                	addiw	a5,a5,-1
    8000432e:	0007891b          	sext.w	s2,a5
    80004332:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004334:	50dc                	lw	a5,36(s1)
    80004336:	efb9                	bnez	a5,80004394 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004338:	06091663          	bnez	s2,800043a4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000433c:	0001e497          	auipc	s1,0x1e
    80004340:	93448493          	addi	s1,s1,-1740 # 80021c70 <log>
    80004344:	4785                	li	a5,1
    80004346:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004352:	54dc                	lw	a5,44(s1)
    80004354:	06f04763          	bgtz	a5,800043c2 <end_op+0xbc>
    acquire(&log.lock);
    80004358:	0001e497          	auipc	s1,0x1e
    8000435c:	91848493          	addi	s1,s1,-1768 # 80021c70 <log>
    80004360:	8526                	mv	a0,s1
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	882080e7          	jalr	-1918(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000436a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	ed4080e7          	jalr	-300(ra) # 80002244 <wakeup>
    release(&log.lock);
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	91e080e7          	jalr	-1762(ra) # 80000c98 <release>
}
    80004382:	70e2                	ld	ra,56(sp)
    80004384:	7442                	ld	s0,48(sp)
    80004386:	74a2                	ld	s1,40(sp)
    80004388:	7902                	ld	s2,32(sp)
    8000438a:	69e2                	ld	s3,24(sp)
    8000438c:	6a42                	ld	s4,16(sp)
    8000438e:	6aa2                	ld	s5,8(sp)
    80004390:	6121                	addi	sp,sp,64
    80004392:	8082                	ret
    panic("log.committing");
    80004394:	00004517          	auipc	a0,0x4
    80004398:	38450513          	addi	a0,a0,900 # 80008718 <syscalls+0x1f0>
    8000439c:	ffffc097          	auipc	ra,0xffffc
    800043a0:	1a2080e7          	jalr	418(ra) # 8000053e <panic>
    wakeup(&log);
    800043a4:	0001e497          	auipc	s1,0x1e
    800043a8:	8cc48493          	addi	s1,s1,-1844 # 80021c70 <log>
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffe097          	auipc	ra,0xffffe
    800043b2:	e96080e7          	jalr	-362(ra) # 80002244 <wakeup>
  release(&log.lock);
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
  if(do_commit){
    800043c0:	b7c9                	j	80004382 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c2:	0001ea97          	auipc	s5,0x1e
    800043c6:	8dea8a93          	addi	s5,s5,-1826 # 80021ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043ca:	0001ea17          	auipc	s4,0x1e
    800043ce:	8a6a0a13          	addi	s4,s4,-1882 # 80021c70 <log>
    800043d2:	018a2583          	lw	a1,24(s4)
    800043d6:	012585bb          	addw	a1,a1,s2
    800043da:	2585                	addiw	a1,a1,1
    800043dc:	028a2503          	lw	a0,40(s4)
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	cd2080e7          	jalr	-814(ra) # 800030b2 <bread>
    800043e8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ea:	000aa583          	lw	a1,0(s5)
    800043ee:	028a2503          	lw	a0,40(s4)
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	cc0080e7          	jalr	-832(ra) # 800030b2 <bread>
    800043fa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043fc:	40000613          	li	a2,1024
    80004400:	05850593          	addi	a1,a0,88
    80004404:	05848513          	addi	a0,s1,88
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	938080e7          	jalr	-1736(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004410:	8526                	mv	a0,s1
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	d92080e7          	jalr	-622(ra) # 800031a4 <bwrite>
    brelse(from);
    8000441a:	854e                	mv	a0,s3
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	dc6080e7          	jalr	-570(ra) # 800031e2 <brelse>
    brelse(to);
    80004424:	8526                	mv	a0,s1
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	dbc080e7          	jalr	-580(ra) # 800031e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442e:	2905                	addiw	s2,s2,1
    80004430:	0a91                	addi	s5,s5,4
    80004432:	02ca2783          	lw	a5,44(s4)
    80004436:	f8f94ee3          	blt	s2,a5,800043d2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	c6a080e7          	jalr	-918(ra) # 800040a4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004442:	4501                	li	a0,0
    80004444:	00000097          	auipc	ra,0x0
    80004448:	cda080e7          	jalr	-806(ra) # 8000411e <install_trans>
    log.lh.n = 0;
    8000444c:	0001e797          	auipc	a5,0x1e
    80004450:	8407a823          	sw	zero,-1968(a5) # 80021c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004454:	00000097          	auipc	ra,0x0
    80004458:	c50080e7          	jalr	-944(ra) # 800040a4 <write_head>
    8000445c:	bdf5                	j	80004358 <end_op+0x52>

000000008000445e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000446c:	0001e917          	auipc	s2,0x1e
    80004470:	80490913          	addi	s2,s2,-2044 # 80021c70 <log>
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	76e080e7          	jalr	1902(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000447e:	02c92603          	lw	a2,44(s2)
    80004482:	47f5                	li	a5,29
    80004484:	06c7c563          	blt	a5,a2,800044ee <log_write+0x90>
    80004488:	0001e797          	auipc	a5,0x1e
    8000448c:	8047a783          	lw	a5,-2044(a5) # 80021c8c <log+0x1c>
    80004490:	37fd                	addiw	a5,a5,-1
    80004492:	04f65e63          	bge	a2,a5,800044ee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004496:	0001d797          	auipc	a5,0x1d
    8000449a:	7fa7a783          	lw	a5,2042(a5) # 80021c90 <log+0x20>
    8000449e:	06f05063          	blez	a5,800044fe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044a2:	4781                	li	a5,0
    800044a4:	06c05563          	blez	a2,8000450e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044a8:	44cc                	lw	a1,12(s1)
    800044aa:	0001d717          	auipc	a4,0x1d
    800044ae:	7f670713          	addi	a4,a4,2038 # 80021ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044b2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b4:	4314                	lw	a3,0(a4)
    800044b6:	04b68c63          	beq	a3,a1,8000450e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ba:	2785                	addiw	a5,a5,1
    800044bc:	0711                	addi	a4,a4,4
    800044be:	fef61be3          	bne	a2,a5,800044b4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044c2:	0621                	addi	a2,a2,8
    800044c4:	060a                	slli	a2,a2,0x2
    800044c6:	0001d797          	auipc	a5,0x1d
    800044ca:	7aa78793          	addi	a5,a5,1962 # 80021c70 <log>
    800044ce:	963e                	add	a2,a2,a5
    800044d0:	44dc                	lw	a5,12(s1)
    800044d2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044d4:	8526                	mv	a0,s1
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	daa080e7          	jalr	-598(ra) # 80003280 <bpin>
    log.lh.n++;
    800044de:	0001d717          	auipc	a4,0x1d
    800044e2:	79270713          	addi	a4,a4,1938 # 80021c70 <log>
    800044e6:	575c                	lw	a5,44(a4)
    800044e8:	2785                	addiw	a5,a5,1
    800044ea:	d75c                	sw	a5,44(a4)
    800044ec:	a835                	j	80004528 <log_write+0xca>
    panic("too big a transaction");
    800044ee:	00004517          	auipc	a0,0x4
    800044f2:	23a50513          	addi	a0,a0,570 # 80008728 <syscalls+0x200>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	048080e7          	jalr	72(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044fe:	00004517          	auipc	a0,0x4
    80004502:	24250513          	addi	a0,a0,578 # 80008740 <syscalls+0x218>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	038080e7          	jalr	56(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000450e:	00878713          	addi	a4,a5,8
    80004512:	00271693          	slli	a3,a4,0x2
    80004516:	0001d717          	auipc	a4,0x1d
    8000451a:	75a70713          	addi	a4,a4,1882 # 80021c70 <log>
    8000451e:	9736                	add	a4,a4,a3
    80004520:	44d4                	lw	a3,12(s1)
    80004522:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004524:	faf608e3          	beq	a2,a5,800044d4 <log_write+0x76>
  }
  release(&log.lock);
    80004528:	0001d517          	auipc	a0,0x1d
    8000452c:	74850513          	addi	a0,a0,1864 # 80021c70 <log>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	768080e7          	jalr	1896(ra) # 80000c98 <release>
}
    80004538:	60e2                	ld	ra,24(sp)
    8000453a:	6442                	ld	s0,16(sp)
    8000453c:	64a2                	ld	s1,8(sp)
    8000453e:	6902                	ld	s2,0(sp)
    80004540:	6105                	addi	sp,sp,32
    80004542:	8082                	ret

0000000080004544 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004544:	1101                	addi	sp,sp,-32
    80004546:	ec06                	sd	ra,24(sp)
    80004548:	e822                	sd	s0,16(sp)
    8000454a:	e426                	sd	s1,8(sp)
    8000454c:	e04a                	sd	s2,0(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
    80004552:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004554:	00004597          	auipc	a1,0x4
    80004558:	20c58593          	addi	a1,a1,524 # 80008760 <syscalls+0x238>
    8000455c:	0521                	addi	a0,a0,8
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	5f6080e7          	jalr	1526(ra) # 80000b54 <initlock>
  lk->name = name;
    80004566:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000456a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000456e:	0204a423          	sw	zero,40(s1)
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000457e:	1101                	addi	sp,sp,-32
    80004580:	ec06                	sd	ra,24(sp)
    80004582:	e822                	sd	s0,16(sp)
    80004584:	e426                	sd	s1,8(sp)
    80004586:	e04a                	sd	s2,0(sp)
    80004588:	1000                	addi	s0,sp,32
    8000458a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000458c:	00850913          	addi	s2,a0,8
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	652080e7          	jalr	1618(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000459a:	409c                	lw	a5,0(s1)
    8000459c:	cb89                	beqz	a5,800045ae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000459e:	85ca                	mv	a1,s2
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	b0c080e7          	jalr	-1268(ra) # 800020ae <sleep>
  while (lk->locked) {
    800045aa:	409c                	lw	a5,0(s1)
    800045ac:	fbed                	bnez	a5,8000459e <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ae:	4785                	li	a5,1
    800045b0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045b2:	ffffd097          	auipc	ra,0xffffd
    800045b6:	3fe080e7          	jalr	1022(ra) # 800019b0 <myproc>
    800045ba:	591c                	lw	a5,48(a0)
    800045bc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6d8080e7          	jalr	1752(ra) # 80000c98 <release>
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	e04a                	sd	s2,0(sp)
    800045de:	1000                	addi	s0,sp,32
    800045e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e2:	00850913          	addi	s2,a0,8
    800045e6:	854a                	mv	a0,s2
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	c4a080e7          	jalr	-950(ra) # 80002244 <wakeup>
  release(&lk->lk);
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
}
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6902                	ld	s2,0(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret

0000000080004618 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004618:	7179                	addi	sp,sp,-48
    8000461a:	f406                	sd	ra,40(sp)
    8000461c:	f022                	sd	s0,32(sp)
    8000461e:	ec26                	sd	s1,24(sp)
    80004620:	e84a                	sd	s2,16(sp)
    80004622:	e44e                	sd	s3,8(sp)
    80004624:	1800                	addi	s0,sp,48
    80004626:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004628:	00850913          	addi	s2,a0,8
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004636:	409c                	lw	a5,0(s1)
    80004638:	ef99                	bnez	a5,80004656 <holdingsleep+0x3e>
    8000463a:	4481                	li	s1,0
  release(&lk->lk);
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	65a080e7          	jalr	1626(ra) # 80000c98 <release>
  return r;
}
    80004646:	8526                	mv	a0,s1
    80004648:	70a2                	ld	ra,40(sp)
    8000464a:	7402                	ld	s0,32(sp)
    8000464c:	64e2                	ld	s1,24(sp)
    8000464e:	6942                	ld	s2,16(sp)
    80004650:	69a2                	ld	s3,8(sp)
    80004652:	6145                	addi	sp,sp,48
    80004654:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004656:	0284a983          	lw	s3,40(s1)
    8000465a:	ffffd097          	auipc	ra,0xffffd
    8000465e:	356080e7          	jalr	854(ra) # 800019b0 <myproc>
    80004662:	5904                	lw	s1,48(a0)
    80004664:	413484b3          	sub	s1,s1,s3
    80004668:	0014b493          	seqz	s1,s1
    8000466c:	bfc1                	j	8000463c <holdingsleep+0x24>

000000008000466e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000466e:	1141                	addi	sp,sp,-16
    80004670:	e406                	sd	ra,8(sp)
    80004672:	e022                	sd	s0,0(sp)
    80004674:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004676:	00004597          	auipc	a1,0x4
    8000467a:	0fa58593          	addi	a1,a1,250 # 80008770 <syscalls+0x248>
    8000467e:	0001d517          	auipc	a0,0x1d
    80004682:	73a50513          	addi	a0,a0,1850 # 80021db8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	4ce080e7          	jalr	1230(ra) # 80000b54 <initlock>
}
    8000468e:	60a2                	ld	ra,8(sp)
    80004690:	6402                	ld	s0,0(sp)
    80004692:	0141                	addi	sp,sp,16
    80004694:	8082                	ret

0000000080004696 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	71850513          	addi	a0,a0,1816 # 80021db8 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	53c080e7          	jalr	1340(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b0:	0001d497          	auipc	s1,0x1d
    800046b4:	72048493          	addi	s1,s1,1824 # 80021dd0 <ftable+0x18>
    800046b8:	0001e717          	auipc	a4,0x1e
    800046bc:	6b870713          	addi	a4,a4,1720 # 80022d70 <ftable+0xfb8>
    if(f->ref == 0){
    800046c0:	40dc                	lw	a5,4(s1)
    800046c2:	cf99                	beqz	a5,800046e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c4:	02848493          	addi	s1,s1,40
    800046c8:	fee49ce3          	bne	s1,a4,800046c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	6ec50513          	addi	a0,a0,1772 # 80021db8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
  return 0;
    800046dc:	4481                	li	s1,0
    800046de:	a819                	j	800046f4 <filealloc+0x5e>
      f->ref = 1;
    800046e0:	4785                	li	a5,1
    800046e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046e4:	0001d517          	auipc	a0,0x1d
    800046e8:	6d450513          	addi	a0,a0,1748 # 80021db8 <ftable>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
}
    800046f4:	8526                	mv	a0,s1
    800046f6:	60e2                	ld	ra,24(sp)
    800046f8:	6442                	ld	s0,16(sp)
    800046fa:	64a2                	ld	s1,8(sp)
    800046fc:	6105                	addi	sp,sp,32
    800046fe:	8082                	ret

0000000080004700 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	1000                	addi	s0,sp,32
    8000470a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000470c:	0001d517          	auipc	a0,0x1d
    80004710:	6ac50513          	addi	a0,a0,1708 # 80021db8 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000471c:	40dc                	lw	a5,4(s1)
    8000471e:	02f05263          	blez	a5,80004742 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004722:	2785                	addiw	a5,a5,1
    80004724:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	69250513          	addi	a0,a0,1682 # 80021db8 <ftable>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	56a080e7          	jalr	1386(ra) # 80000c98 <release>
  return f;
}
    80004736:	8526                	mv	a0,s1
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6105                	addi	sp,sp,32
    80004740:	8082                	ret
    panic("filedup");
    80004742:	00004517          	auipc	a0,0x4
    80004746:	03650513          	addi	a0,a0,54 # 80008778 <syscalls+0x250>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	df4080e7          	jalr	-524(ra) # 8000053e <panic>

0000000080004752 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004752:	7139                	addi	sp,sp,-64
    80004754:	fc06                	sd	ra,56(sp)
    80004756:	f822                	sd	s0,48(sp)
    80004758:	f426                	sd	s1,40(sp)
    8000475a:	f04a                	sd	s2,32(sp)
    8000475c:	ec4e                	sd	s3,24(sp)
    8000475e:	e852                	sd	s4,16(sp)
    80004760:	e456                	sd	s5,8(sp)
    80004762:	0080                	addi	s0,sp,64
    80004764:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004766:	0001d517          	auipc	a0,0x1d
    8000476a:	65250513          	addi	a0,a0,1618 # 80021db8 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	476080e7          	jalr	1142(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	06f05163          	blez	a5,800047da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000477c:	37fd                	addiw	a5,a5,-1
    8000477e:	0007871b          	sext.w	a4,a5
    80004782:	c0dc                	sw	a5,4(s1)
    80004784:	06e04363          	bgtz	a4,800047ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004788:	0004a903          	lw	s2,0(s1)
    8000478c:	0094ca83          	lbu	s5,9(s1)
    80004790:	0104ba03          	ld	s4,16(s1)
    80004794:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004798:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000479c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047a0:	0001d517          	auipc	a0,0x1d
    800047a4:	61850513          	addi	a0,a0,1560 # 80021db8 <ftable>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4f0080e7          	jalr	1264(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047b0:	4785                	li	a5,1
    800047b2:	04f90d63          	beq	s2,a5,8000480c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047b6:	3979                	addiw	s2,s2,-2
    800047b8:	4785                	li	a5,1
    800047ba:	0527e063          	bltu	a5,s2,800047fa <fileclose+0xa8>
    begin_op();
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	ac8080e7          	jalr	-1336(ra) # 80004286 <begin_op>
    iput(ff.ip);
    800047c6:	854e                	mv	a0,s3
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	2a6080e7          	jalr	678(ra) # 80003a6e <iput>
    end_op();
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	b36080e7          	jalr	-1226(ra) # 80004306 <end_op>
    800047d8:	a00d                	j	800047fa <fileclose+0xa8>
    panic("fileclose");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	fa650513          	addi	a0,a0,-90 # 80008780 <syscalls+0x258>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047ea:	0001d517          	auipc	a0,0x1d
    800047ee:	5ce50513          	addi	a0,a0,1486 # 80021db8 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	4a6080e7          	jalr	1190(ra) # 80000c98 <release>
  }
}
    800047fa:	70e2                	ld	ra,56(sp)
    800047fc:	7442                	ld	s0,48(sp)
    800047fe:	74a2                	ld	s1,40(sp)
    80004800:	7902                	ld	s2,32(sp)
    80004802:	69e2                	ld	s3,24(sp)
    80004804:	6a42                	ld	s4,16(sp)
    80004806:	6aa2                	ld	s5,8(sp)
    80004808:	6121                	addi	sp,sp,64
    8000480a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000480c:	85d6                	mv	a1,s5
    8000480e:	8552                	mv	a0,s4
    80004810:	00000097          	auipc	ra,0x0
    80004814:	34c080e7          	jalr	844(ra) # 80004b5c <pipeclose>
    80004818:	b7cd                	j	800047fa <fileclose+0xa8>

000000008000481a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000481a:	715d                	addi	sp,sp,-80
    8000481c:	e486                	sd	ra,72(sp)
    8000481e:	e0a2                	sd	s0,64(sp)
    80004820:	fc26                	sd	s1,56(sp)
    80004822:	f84a                	sd	s2,48(sp)
    80004824:	f44e                	sd	s3,40(sp)
    80004826:	0880                	addi	s0,sp,80
    80004828:	84aa                	mv	s1,a0
    8000482a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000482c:	ffffd097          	auipc	ra,0xffffd
    80004830:	184080e7          	jalr	388(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004834:	409c                	lw	a5,0(s1)
    80004836:	37f9                	addiw	a5,a5,-2
    80004838:	4705                	li	a4,1
    8000483a:	04f76763          	bltu	a4,a5,80004888 <filestat+0x6e>
    8000483e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	072080e7          	jalr	114(ra) # 800038b4 <ilock>
    stati(f->ip, &st);
    8000484a:	fb840593          	addi	a1,s0,-72
    8000484e:	6c88                	ld	a0,24(s1)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	2ee080e7          	jalr	750(ra) # 80003b3e <stati>
    iunlock(f->ip);
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	11c080e7          	jalr	284(ra) # 80003976 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004862:	46e1                	li	a3,24
    80004864:	fb840613          	addi	a2,s0,-72
    80004868:	85ce                	mv	a1,s3
    8000486a:	07893503          	ld	a0,120(s2)
    8000486e:	ffffd097          	auipc	ra,0xffffd
    80004872:	e04080e7          	jalr	-508(ra) # 80001672 <copyout>
    80004876:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000487a:	60a6                	ld	ra,72(sp)
    8000487c:	6406                	ld	s0,64(sp)
    8000487e:	74e2                	ld	s1,56(sp)
    80004880:	7942                	ld	s2,48(sp)
    80004882:	79a2                	ld	s3,40(sp)
    80004884:	6161                	addi	sp,sp,80
    80004886:	8082                	ret
  return -1;
    80004888:	557d                	li	a0,-1
    8000488a:	bfc5                	j	8000487a <filestat+0x60>

000000008000488c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000488c:	7179                	addi	sp,sp,-48
    8000488e:	f406                	sd	ra,40(sp)
    80004890:	f022                	sd	s0,32(sp)
    80004892:	ec26                	sd	s1,24(sp)
    80004894:	e84a                	sd	s2,16(sp)
    80004896:	e44e                	sd	s3,8(sp)
    80004898:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000489a:	00854783          	lbu	a5,8(a0)
    8000489e:	c3d5                	beqz	a5,80004942 <fileread+0xb6>
    800048a0:	84aa                	mv	s1,a0
    800048a2:	89ae                	mv	s3,a1
    800048a4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048a6:	411c                	lw	a5,0(a0)
    800048a8:	4705                	li	a4,1
    800048aa:	04e78963          	beq	a5,a4,800048fc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ae:	470d                	li	a4,3
    800048b0:	04e78d63          	beq	a5,a4,8000490a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b4:	4709                	li	a4,2
    800048b6:	06e79e63          	bne	a5,a4,80004932 <fileread+0xa6>
    ilock(f->ip);
    800048ba:	6d08                	ld	a0,24(a0)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	ff8080e7          	jalr	-8(ra) # 800038b4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048c4:	874a                	mv	a4,s2
    800048c6:	5094                	lw	a3,32(s1)
    800048c8:	864e                	mv	a2,s3
    800048ca:	4585                	li	a1,1
    800048cc:	6c88                	ld	a0,24(s1)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	29a080e7          	jalr	666(ra) # 80003b68 <readi>
    800048d6:	892a                	mv	s2,a0
    800048d8:	00a05563          	blez	a0,800048e2 <fileread+0x56>
      f->off += r;
    800048dc:	509c                	lw	a5,32(s1)
    800048de:	9fa9                	addw	a5,a5,a0
    800048e0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048e2:	6c88                	ld	a0,24(s1)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	092080e7          	jalr	146(ra) # 80003976 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048ec:	854a                	mv	a0,s2
    800048ee:	70a2                	ld	ra,40(sp)
    800048f0:	7402                	ld	s0,32(sp)
    800048f2:	64e2                	ld	s1,24(sp)
    800048f4:	6942                	ld	s2,16(sp)
    800048f6:	69a2                	ld	s3,8(sp)
    800048f8:	6145                	addi	sp,sp,48
    800048fa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048fc:	6908                	ld	a0,16(a0)
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	3c8080e7          	jalr	968(ra) # 80004cc6 <piperead>
    80004906:	892a                	mv	s2,a0
    80004908:	b7d5                	j	800048ec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000490a:	02451783          	lh	a5,36(a0)
    8000490e:	03079693          	slli	a3,a5,0x30
    80004912:	92c1                	srli	a3,a3,0x30
    80004914:	4725                	li	a4,9
    80004916:	02d76863          	bltu	a4,a3,80004946 <fileread+0xba>
    8000491a:	0792                	slli	a5,a5,0x4
    8000491c:	0001d717          	auipc	a4,0x1d
    80004920:	3fc70713          	addi	a4,a4,1020 # 80021d18 <devsw>
    80004924:	97ba                	add	a5,a5,a4
    80004926:	639c                	ld	a5,0(a5)
    80004928:	c38d                	beqz	a5,8000494a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000492a:	4505                	li	a0,1
    8000492c:	9782                	jalr	a5
    8000492e:	892a                	mv	s2,a0
    80004930:	bf75                	j	800048ec <fileread+0x60>
    panic("fileread");
    80004932:	00004517          	auipc	a0,0x4
    80004936:	e5e50513          	addi	a0,a0,-418 # 80008790 <syscalls+0x268>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	c04080e7          	jalr	-1020(ra) # 8000053e <panic>
    return -1;
    80004942:	597d                	li	s2,-1
    80004944:	b765                	j	800048ec <fileread+0x60>
      return -1;
    80004946:	597d                	li	s2,-1
    80004948:	b755                	j	800048ec <fileread+0x60>
    8000494a:	597d                	li	s2,-1
    8000494c:	b745                	j	800048ec <fileread+0x60>

000000008000494e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000494e:	715d                	addi	sp,sp,-80
    80004950:	e486                	sd	ra,72(sp)
    80004952:	e0a2                	sd	s0,64(sp)
    80004954:	fc26                	sd	s1,56(sp)
    80004956:	f84a                	sd	s2,48(sp)
    80004958:	f44e                	sd	s3,40(sp)
    8000495a:	f052                	sd	s4,32(sp)
    8000495c:	ec56                	sd	s5,24(sp)
    8000495e:	e85a                	sd	s6,16(sp)
    80004960:	e45e                	sd	s7,8(sp)
    80004962:	e062                	sd	s8,0(sp)
    80004964:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004966:	00954783          	lbu	a5,9(a0)
    8000496a:	10078663          	beqz	a5,80004a76 <filewrite+0x128>
    8000496e:	892a                	mv	s2,a0
    80004970:	8aae                	mv	s5,a1
    80004972:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004974:	411c                	lw	a5,0(a0)
    80004976:	4705                	li	a4,1
    80004978:	02e78263          	beq	a5,a4,8000499c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497c:	470d                	li	a4,3
    8000497e:	02e78663          	beq	a5,a4,800049aa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004982:	4709                	li	a4,2
    80004984:	0ee79163          	bne	a5,a4,80004a66 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004988:	0ac05d63          	blez	a2,80004a42 <filewrite+0xf4>
    int i = 0;
    8000498c:	4981                	li	s3,0
    8000498e:	6b05                	lui	s6,0x1
    80004990:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004994:	6b85                	lui	s7,0x1
    80004996:	c00b8b9b          	addiw	s7,s7,-1024
    8000499a:	a861                	j	80004a32 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000499c:	6908                	ld	a0,16(a0)
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	22e080e7          	jalr	558(ra) # 80004bcc <pipewrite>
    800049a6:	8a2a                	mv	s4,a0
    800049a8:	a045                	j	80004a48 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049aa:	02451783          	lh	a5,36(a0)
    800049ae:	03079693          	slli	a3,a5,0x30
    800049b2:	92c1                	srli	a3,a3,0x30
    800049b4:	4725                	li	a4,9
    800049b6:	0cd76263          	bltu	a4,a3,80004a7a <filewrite+0x12c>
    800049ba:	0792                	slli	a5,a5,0x4
    800049bc:	0001d717          	auipc	a4,0x1d
    800049c0:	35c70713          	addi	a4,a4,860 # 80021d18 <devsw>
    800049c4:	97ba                	add	a5,a5,a4
    800049c6:	679c                	ld	a5,8(a5)
    800049c8:	cbdd                	beqz	a5,80004a7e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049ca:	4505                	li	a0,1
    800049cc:	9782                	jalr	a5
    800049ce:	8a2a                	mv	s4,a0
    800049d0:	a8a5                	j	80004a48 <filewrite+0xfa>
    800049d2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	8b0080e7          	jalr	-1872(ra) # 80004286 <begin_op>
      ilock(f->ip);
    800049de:	01893503          	ld	a0,24(s2)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	ed2080e7          	jalr	-302(ra) # 800038b4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ea:	8762                	mv	a4,s8
    800049ec:	02092683          	lw	a3,32(s2)
    800049f0:	01598633          	add	a2,s3,s5
    800049f4:	4585                	li	a1,1
    800049f6:	01893503          	ld	a0,24(s2)
    800049fa:	fffff097          	auipc	ra,0xfffff
    800049fe:	266080e7          	jalr	614(ra) # 80003c60 <writei>
    80004a02:	84aa                	mv	s1,a0
    80004a04:	00a05763          	blez	a0,80004a12 <filewrite+0xc4>
        f->off += r;
    80004a08:	02092783          	lw	a5,32(s2)
    80004a0c:	9fa9                	addw	a5,a5,a0
    80004a0e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a12:	01893503          	ld	a0,24(s2)
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	f60080e7          	jalr	-160(ra) # 80003976 <iunlock>
      end_op();
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	8e8080e7          	jalr	-1816(ra) # 80004306 <end_op>

      if(r != n1){
    80004a26:	009c1f63          	bne	s8,s1,80004a44 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a2a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a2e:	0149db63          	bge	s3,s4,80004a44 <filewrite+0xf6>
      int n1 = n - i;
    80004a32:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a36:	84be                	mv	s1,a5
    80004a38:	2781                	sext.w	a5,a5
    80004a3a:	f8fb5ce3          	bge	s6,a5,800049d2 <filewrite+0x84>
    80004a3e:	84de                	mv	s1,s7
    80004a40:	bf49                	j	800049d2 <filewrite+0x84>
    int i = 0;
    80004a42:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a44:	013a1f63          	bne	s4,s3,80004a62 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a48:	8552                	mv	a0,s4
    80004a4a:	60a6                	ld	ra,72(sp)
    80004a4c:	6406                	ld	s0,64(sp)
    80004a4e:	74e2                	ld	s1,56(sp)
    80004a50:	7942                	ld	s2,48(sp)
    80004a52:	79a2                	ld	s3,40(sp)
    80004a54:	7a02                	ld	s4,32(sp)
    80004a56:	6ae2                	ld	s5,24(sp)
    80004a58:	6b42                	ld	s6,16(sp)
    80004a5a:	6ba2                	ld	s7,8(sp)
    80004a5c:	6c02                	ld	s8,0(sp)
    80004a5e:	6161                	addi	sp,sp,80
    80004a60:	8082                	ret
    ret = (i == n ? n : -1);
    80004a62:	5a7d                	li	s4,-1
    80004a64:	b7d5                	j	80004a48 <filewrite+0xfa>
    panic("filewrite");
    80004a66:	00004517          	auipc	a0,0x4
    80004a6a:	d3a50513          	addi	a0,a0,-710 # 800087a0 <syscalls+0x278>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    return -1;
    80004a76:	5a7d                	li	s4,-1
    80004a78:	bfc1                	j	80004a48 <filewrite+0xfa>
      return -1;
    80004a7a:	5a7d                	li	s4,-1
    80004a7c:	b7f1                	j	80004a48 <filewrite+0xfa>
    80004a7e:	5a7d                	li	s4,-1
    80004a80:	b7e1                	j	80004a48 <filewrite+0xfa>

0000000080004a82 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a82:	7179                	addi	sp,sp,-48
    80004a84:	f406                	sd	ra,40(sp)
    80004a86:	f022                	sd	s0,32(sp)
    80004a88:	ec26                	sd	s1,24(sp)
    80004a8a:	e84a                	sd	s2,16(sp)
    80004a8c:	e44e                	sd	s3,8(sp)
    80004a8e:	e052                	sd	s4,0(sp)
    80004a90:	1800                	addi	s0,sp,48
    80004a92:	84aa                	mv	s1,a0
    80004a94:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a96:	0005b023          	sd	zero,0(a1)
    80004a9a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	bf8080e7          	jalr	-1032(ra) # 80004696 <filealloc>
    80004aa6:	e088                	sd	a0,0(s1)
    80004aa8:	c551                	beqz	a0,80004b34 <pipealloc+0xb2>
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	bec080e7          	jalr	-1044(ra) # 80004696 <filealloc>
    80004ab2:	00aa3023          	sd	a0,0(s4)
    80004ab6:	c92d                	beqz	a0,80004b28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	03c080e7          	jalr	60(ra) # 80000af4 <kalloc>
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	c125                	beqz	a0,80004b22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ac4:	4985                	li	s3,1
    80004ac6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ace:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ad6:	00004597          	auipc	a1,0x4
    80004ada:	9aa58593          	addi	a1,a1,-1622 # 80008480 <states.1746+0x1b0>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	076080e7          	jalr	118(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ae6:	609c                	ld	a5,0(s1)
    80004ae8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aec:	609c                	ld	a5,0(s1)
    80004aee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af2:	609c                	ld	a5,0(s1)
    80004af4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004af8:	609c                	ld	a5,0(s1)
    80004afa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004afe:	000a3783          	ld	a5,0(s4)
    80004b02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b06:	000a3783          	ld	a5,0(s4)
    80004b0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b0e:	000a3783          	ld	a5,0(s4)
    80004b12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b1e:	4501                	li	a0,0
    80004b20:	a025                	j	80004b48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b22:	6088                	ld	a0,0(s1)
    80004b24:	e501                	bnez	a0,80004b2c <pipealloc+0xaa>
    80004b26:	a039                	j	80004b34 <pipealloc+0xb2>
    80004b28:	6088                	ld	a0,0(s1)
    80004b2a:	c51d                	beqz	a0,80004b58 <pipealloc+0xd6>
    fileclose(*f0);
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	c26080e7          	jalr	-986(ra) # 80004752 <fileclose>
  if(*f1)
    80004b34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b38:	557d                	li	a0,-1
  if(*f1)
    80004b3a:	c799                	beqz	a5,80004b48 <pipealloc+0xc6>
    fileclose(*f1);
    80004b3c:	853e                	mv	a0,a5
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	c14080e7          	jalr	-1004(ra) # 80004752 <fileclose>
  return -1;
    80004b46:	557d                	li	a0,-1
}
    80004b48:	70a2                	ld	ra,40(sp)
    80004b4a:	7402                	ld	s0,32(sp)
    80004b4c:	64e2                	ld	s1,24(sp)
    80004b4e:	6942                	ld	s2,16(sp)
    80004b50:	69a2                	ld	s3,8(sp)
    80004b52:	6a02                	ld	s4,0(sp)
    80004b54:	6145                	addi	sp,sp,48
    80004b56:	8082                	ret
  return -1;
    80004b58:	557d                	li	a0,-1
    80004b5a:	b7fd                	j	80004b48 <pipealloc+0xc6>

0000000080004b5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	e04a                	sd	s2,0(sp)
    80004b66:	1000                	addi	s0,sp,32
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	078080e7          	jalr	120(ra) # 80000be4 <acquire>
  if(writable){
    80004b74:	02090d63          	beqz	s2,80004bae <pipeclose+0x52>
    pi->writeopen = 0;
    80004b78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b7c:	21848513          	addi	a0,s1,536
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	6c4080e7          	jalr	1732(ra) # 80002244 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b88:	2204b783          	ld	a5,544(s1)
    80004b8c:	eb95                	bnez	a5,80004bc0 <pipeclose+0x64>
    release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	108080e7          	jalr	264(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	e5e080e7          	jalr	-418(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ba2:	60e2                	ld	ra,24(sp)
    80004ba4:	6442                	ld	s0,16(sp)
    80004ba6:	64a2                	ld	s1,8(sp)
    80004ba8:	6902                	ld	s2,0(sp)
    80004baa:	6105                	addi	sp,sp,32
    80004bac:	8082                	ret
    pi->readopen = 0;
    80004bae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb2:	21c48513          	addi	a0,s1,540
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	68e080e7          	jalr	1678(ra) # 80002244 <wakeup>
    80004bbe:	b7e9                	j	80004b88 <pipeclose+0x2c>
    release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0d6080e7          	jalr	214(ra) # 80000c98 <release>
}
    80004bca:	bfe1                	j	80004ba2 <pipeclose+0x46>

0000000080004bcc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bcc:	7159                	addi	sp,sp,-112
    80004bce:	f486                	sd	ra,104(sp)
    80004bd0:	f0a2                	sd	s0,96(sp)
    80004bd2:	eca6                	sd	s1,88(sp)
    80004bd4:	e8ca                	sd	s2,80(sp)
    80004bd6:	e4ce                	sd	s3,72(sp)
    80004bd8:	e0d2                	sd	s4,64(sp)
    80004bda:	fc56                	sd	s5,56(sp)
    80004bdc:	f85a                	sd	s6,48(sp)
    80004bde:	f45e                	sd	s7,40(sp)
    80004be0:	f062                	sd	s8,32(sp)
    80004be2:	ec66                	sd	s9,24(sp)
    80004be4:	1880                	addi	s0,sp,112
    80004be6:	84aa                	mv	s1,a0
    80004be8:	8aae                	mv	s5,a1
    80004bea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	dc4080e7          	jalr	-572(ra) # 800019b0 <myproc>
    80004bf4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	fec080e7          	jalr	-20(ra) # 80000be4 <acquire>
  while(i < n){
    80004c00:	0d405163          	blez	s4,80004cc2 <pipewrite+0xf6>
    80004c04:	8ba6                	mv	s7,s1
  int i = 0;
    80004c06:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c08:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c0a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c0e:	21c48c13          	addi	s8,s1,540
    80004c12:	a08d                	j	80004c74 <pipewrite+0xa8>
      release(&pi->lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	082080e7          	jalr	130(ra) # 80000c98 <release>
      return -1;
    80004c1e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c20:	854a                	mv	a0,s2
    80004c22:	70a6                	ld	ra,104(sp)
    80004c24:	7406                	ld	s0,96(sp)
    80004c26:	64e6                	ld	s1,88(sp)
    80004c28:	6946                	ld	s2,80(sp)
    80004c2a:	69a6                	ld	s3,72(sp)
    80004c2c:	6a06                	ld	s4,64(sp)
    80004c2e:	7ae2                	ld	s5,56(sp)
    80004c30:	7b42                	ld	s6,48(sp)
    80004c32:	7ba2                	ld	s7,40(sp)
    80004c34:	7c02                	ld	s8,32(sp)
    80004c36:	6ce2                	ld	s9,24(sp)
    80004c38:	6165                	addi	sp,sp,112
    80004c3a:	8082                	ret
      wakeup(&pi->nread);
    80004c3c:	8566                	mv	a0,s9
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	606080e7          	jalr	1542(ra) # 80002244 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c46:	85de                	mv	a1,s7
    80004c48:	8562                	mv	a0,s8
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	464080e7          	jalr	1124(ra) # 800020ae <sleep>
    80004c52:	a839                	j	80004c70 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c54:	21c4a783          	lw	a5,540(s1)
    80004c58:	0017871b          	addiw	a4,a5,1
    80004c5c:	20e4ae23          	sw	a4,540(s1)
    80004c60:	1ff7f793          	andi	a5,a5,511
    80004c64:	97a6                	add	a5,a5,s1
    80004c66:	f9f44703          	lbu	a4,-97(s0)
    80004c6a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c6e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c70:	03495d63          	bge	s2,s4,80004caa <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c74:	2204a783          	lw	a5,544(s1)
    80004c78:	dfd1                	beqz	a5,80004c14 <pipewrite+0x48>
    80004c7a:	0289a783          	lw	a5,40(s3)
    80004c7e:	fbd9                	bnez	a5,80004c14 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c80:	2184a783          	lw	a5,536(s1)
    80004c84:	21c4a703          	lw	a4,540(s1)
    80004c88:	2007879b          	addiw	a5,a5,512
    80004c8c:	faf708e3          	beq	a4,a5,80004c3c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c90:	4685                	li	a3,1
    80004c92:	01590633          	add	a2,s2,s5
    80004c96:	f9f40593          	addi	a1,s0,-97
    80004c9a:	0789b503          	ld	a0,120(s3)
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	a60080e7          	jalr	-1440(ra) # 800016fe <copyin>
    80004ca6:	fb6517e3          	bne	a0,s6,80004c54 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004caa:	21848513          	addi	a0,s1,536
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	596080e7          	jalr	1430(ra) # 80002244 <wakeup>
  release(&pi->lock);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fe0080e7          	jalr	-32(ra) # 80000c98 <release>
  return i;
    80004cc0:	b785                	j	80004c20 <pipewrite+0x54>
  int i = 0;
    80004cc2:	4901                	li	s2,0
    80004cc4:	b7dd                	j	80004caa <pipewrite+0xde>

0000000080004cc6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cc6:	715d                	addi	sp,sp,-80
    80004cc8:	e486                	sd	ra,72(sp)
    80004cca:	e0a2                	sd	s0,64(sp)
    80004ccc:	fc26                	sd	s1,56(sp)
    80004cce:	f84a                	sd	s2,48(sp)
    80004cd0:	f44e                	sd	s3,40(sp)
    80004cd2:	f052                	sd	s4,32(sp)
    80004cd4:	ec56                	sd	s5,24(sp)
    80004cd6:	e85a                	sd	s6,16(sp)
    80004cd8:	0880                	addi	s0,sp,80
    80004cda:	84aa                	mv	s1,a0
    80004cdc:	892e                	mv	s2,a1
    80004cde:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce0:	ffffd097          	auipc	ra,0xffffd
    80004ce4:	cd0080e7          	jalr	-816(ra) # 800019b0 <myproc>
    80004ce8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cea:	8b26                	mv	s6,s1
    80004cec:	8526                	mv	a0,s1
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	ef6080e7          	jalr	-266(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf6:	2184a703          	lw	a4,536(s1)
    80004cfa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cfe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d02:	02f71463          	bne	a4,a5,80004d2a <piperead+0x64>
    80004d06:	2244a783          	lw	a5,548(s1)
    80004d0a:	c385                	beqz	a5,80004d2a <piperead+0x64>
    if(pr->killed){
    80004d0c:	028a2783          	lw	a5,40(s4)
    80004d10:	ebc1                	bnez	a5,80004da0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d12:	85da                	mv	a1,s6
    80004d14:	854e                	mv	a0,s3
    80004d16:	ffffd097          	auipc	ra,0xffffd
    80004d1a:	398080e7          	jalr	920(ra) # 800020ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1e:	2184a703          	lw	a4,536(s1)
    80004d22:	21c4a783          	lw	a5,540(s1)
    80004d26:	fef700e3          	beq	a4,a5,80004d06 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d2a:	09505263          	blez	s5,80004dae <piperead+0xe8>
    80004d2e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d30:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d32:	2184a783          	lw	a5,536(s1)
    80004d36:	21c4a703          	lw	a4,540(s1)
    80004d3a:	02f70d63          	beq	a4,a5,80004d74 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d3e:	0017871b          	addiw	a4,a5,1
    80004d42:	20e4ac23          	sw	a4,536(s1)
    80004d46:	1ff7f793          	andi	a5,a5,511
    80004d4a:	97a6                	add	a5,a5,s1
    80004d4c:	0187c783          	lbu	a5,24(a5)
    80004d50:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d54:	4685                	li	a3,1
    80004d56:	fbf40613          	addi	a2,s0,-65
    80004d5a:	85ca                	mv	a1,s2
    80004d5c:	078a3503          	ld	a0,120(s4)
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	912080e7          	jalr	-1774(ra) # 80001672 <copyout>
    80004d68:	01650663          	beq	a0,s6,80004d74 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d6c:	2985                	addiw	s3,s3,1
    80004d6e:	0905                	addi	s2,s2,1
    80004d70:	fd3a91e3          	bne	s5,s3,80004d32 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d74:	21c48513          	addi	a0,s1,540
    80004d78:	ffffd097          	auipc	ra,0xffffd
    80004d7c:	4cc080e7          	jalr	1228(ra) # 80002244 <wakeup>
  release(&pi->lock);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>
  return i;
}
    80004d8a:	854e                	mv	a0,s3
    80004d8c:	60a6                	ld	ra,72(sp)
    80004d8e:	6406                	ld	s0,64(sp)
    80004d90:	74e2                	ld	s1,56(sp)
    80004d92:	7942                	ld	s2,48(sp)
    80004d94:	79a2                	ld	s3,40(sp)
    80004d96:	7a02                	ld	s4,32(sp)
    80004d98:	6ae2                	ld	s5,24(sp)
    80004d9a:	6b42                	ld	s6,16(sp)
    80004d9c:	6161                	addi	sp,sp,80
    80004d9e:	8082                	ret
      release(&pi->lock);
    80004da0:	8526                	mv	a0,s1
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
      return -1;
    80004daa:	59fd                	li	s3,-1
    80004dac:	bff9                	j	80004d8a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dae:	4981                	li	s3,0
    80004db0:	b7d1                	j	80004d74 <piperead+0xae>

0000000080004db2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db2:	df010113          	addi	sp,sp,-528
    80004db6:	20113423          	sd	ra,520(sp)
    80004dba:	20813023          	sd	s0,512(sp)
    80004dbe:	ffa6                	sd	s1,504(sp)
    80004dc0:	fbca                	sd	s2,496(sp)
    80004dc2:	f7ce                	sd	s3,488(sp)
    80004dc4:	f3d2                	sd	s4,480(sp)
    80004dc6:	efd6                	sd	s5,472(sp)
    80004dc8:	ebda                	sd	s6,464(sp)
    80004dca:	e7de                	sd	s7,456(sp)
    80004dcc:	e3e2                	sd	s8,448(sp)
    80004dce:	ff66                	sd	s9,440(sp)
    80004dd0:	fb6a                	sd	s10,432(sp)
    80004dd2:	f76e                	sd	s11,424(sp)
    80004dd4:	0c00                	addi	s0,sp,528
    80004dd6:	84aa                	mv	s1,a0
    80004dd8:	dea43c23          	sd	a0,-520(s0)
    80004ddc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	bd0080e7          	jalr	-1072(ra) # 800019b0 <myproc>
    80004de8:	892a                	mv	s2,a0

  begin_op();
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	49c080e7          	jalr	1180(ra) # 80004286 <begin_op>

  if((ip = namei(path)) == 0){
    80004df2:	8526                	mv	a0,s1
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	276080e7          	jalr	630(ra) # 8000406a <namei>
    80004dfc:	c92d                	beqz	a0,80004e6e <exec+0xbc>
    80004dfe:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	ab4080e7          	jalr	-1356(ra) # 800038b4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e08:	04000713          	li	a4,64
    80004e0c:	4681                	li	a3,0
    80004e0e:	e5040613          	addi	a2,s0,-432
    80004e12:	4581                	li	a1,0
    80004e14:	8526                	mv	a0,s1
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	d52080e7          	jalr	-686(ra) # 80003b68 <readi>
    80004e1e:	04000793          	li	a5,64
    80004e22:	00f51a63          	bne	a0,a5,80004e36 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e26:	e5042703          	lw	a4,-432(s0)
    80004e2a:	464c47b7          	lui	a5,0x464c4
    80004e2e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e32:	04f70463          	beq	a4,a5,80004e7a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e36:	8526                	mv	a0,s1
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	cde080e7          	jalr	-802(ra) # 80003b16 <iunlockput>
    end_op();
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	4c6080e7          	jalr	1222(ra) # 80004306 <end_op>
  }
  return -1;
    80004e48:	557d                	li	a0,-1
}
    80004e4a:	20813083          	ld	ra,520(sp)
    80004e4e:	20013403          	ld	s0,512(sp)
    80004e52:	74fe                	ld	s1,504(sp)
    80004e54:	795e                	ld	s2,496(sp)
    80004e56:	79be                	ld	s3,488(sp)
    80004e58:	7a1e                	ld	s4,480(sp)
    80004e5a:	6afe                	ld	s5,472(sp)
    80004e5c:	6b5e                	ld	s6,464(sp)
    80004e5e:	6bbe                	ld	s7,456(sp)
    80004e60:	6c1e                	ld	s8,448(sp)
    80004e62:	7cfa                	ld	s9,440(sp)
    80004e64:	7d5a                	ld	s10,432(sp)
    80004e66:	7dba                	ld	s11,424(sp)
    80004e68:	21010113          	addi	sp,sp,528
    80004e6c:	8082                	ret
    end_op();
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	498080e7          	jalr	1176(ra) # 80004306 <end_op>
    return -1;
    80004e76:	557d                	li	a0,-1
    80004e78:	bfc9                	j	80004e4a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	bf8080e7          	jalr	-1032(ra) # 80001a74 <proc_pagetable>
    80004e84:	8baa                	mv	s7,a0
    80004e86:	d945                	beqz	a0,80004e36 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e88:	e7042983          	lw	s3,-400(s0)
    80004e8c:	e8845783          	lhu	a5,-376(s0)
    80004e90:	c7ad                	beqz	a5,80004efa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e92:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e94:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e96:	6c85                	lui	s9,0x1
    80004e98:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e9c:	def43823          	sd	a5,-528(s0)
    80004ea0:	a42d                	j	800050ca <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea2:	00004517          	auipc	a0,0x4
    80004ea6:	90e50513          	addi	a0,a0,-1778 # 800087b0 <syscalls+0x288>
    80004eaa:	ffffb097          	auipc	ra,0xffffb
    80004eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb2:	8756                	mv	a4,s5
    80004eb4:	012d86bb          	addw	a3,s11,s2
    80004eb8:	4581                	li	a1,0
    80004eba:	8526                	mv	a0,s1
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	cac080e7          	jalr	-852(ra) # 80003b68 <readi>
    80004ec4:	2501                	sext.w	a0,a0
    80004ec6:	1aaa9963          	bne	s5,a0,80005078 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004eca:	6785                	lui	a5,0x1
    80004ecc:	0127893b          	addw	s2,a5,s2
    80004ed0:	77fd                	lui	a5,0xfffff
    80004ed2:	01478a3b          	addw	s4,a5,s4
    80004ed6:	1f897163          	bgeu	s2,s8,800050b8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004eda:	02091593          	slli	a1,s2,0x20
    80004ede:	9181                	srli	a1,a1,0x20
    80004ee0:	95ea                	add	a1,a1,s10
    80004ee2:	855e                	mv	a0,s7
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	18a080e7          	jalr	394(ra) # 8000106e <walkaddr>
    80004eec:	862a                	mv	a2,a0
    if(pa == 0)
    80004eee:	d955                	beqz	a0,80004ea2 <exec+0xf0>
      n = PGSIZE;
    80004ef0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ef2:	fd9a70e3          	bgeu	s4,s9,80004eb2 <exec+0x100>
      n = sz - i;
    80004ef6:	8ad2                	mv	s5,s4
    80004ef8:	bf6d                	j	80004eb2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004efa:	4901                	li	s2,0
  iunlockput(ip);
    80004efc:	8526                	mv	a0,s1
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	c18080e7          	jalr	-1000(ra) # 80003b16 <iunlockput>
  end_op();
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	400080e7          	jalr	1024(ra) # 80004306 <end_op>
  p = myproc();
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	aa2080e7          	jalr	-1374(ra) # 800019b0 <myproc>
    80004f16:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f18:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80004f1c:	6785                	lui	a5,0x1
    80004f1e:	17fd                	addi	a5,a5,-1
    80004f20:	993e                	add	s2,s2,a5
    80004f22:	757d                	lui	a0,0xfffff
    80004f24:	00a977b3          	and	a5,s2,a0
    80004f28:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f2c:	6609                	lui	a2,0x2
    80004f2e:	963e                	add	a2,a2,a5
    80004f30:	85be                	mv	a1,a5
    80004f32:	855e                	mv	a0,s7
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	4ee080e7          	jalr	1262(ra) # 80001422 <uvmalloc>
    80004f3c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f3e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f40:	12050c63          	beqz	a0,80005078 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f44:	75f9                	lui	a1,0xffffe
    80004f46:	95aa                	add	a1,a1,a0
    80004f48:	855e                	mv	a0,s7
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	6f6080e7          	jalr	1782(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f52:	7c7d                	lui	s8,0xfffff
    80004f54:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f56:	e0043783          	ld	a5,-512(s0)
    80004f5a:	6388                	ld	a0,0(a5)
    80004f5c:	c535                	beqz	a0,80004fc8 <exec+0x216>
    80004f5e:	e9040993          	addi	s3,s0,-368
    80004f62:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f66:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	efc080e7          	jalr	-260(ra) # 80000e64 <strlen>
    80004f70:	2505                	addiw	a0,a0,1
    80004f72:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f76:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f7a:	13896363          	bltu	s2,s8,800050a0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f7e:	e0043d83          	ld	s11,-512(s0)
    80004f82:	000dba03          	ld	s4,0(s11)
    80004f86:	8552                	mv	a0,s4
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	edc080e7          	jalr	-292(ra) # 80000e64 <strlen>
    80004f90:	0015069b          	addiw	a3,a0,1
    80004f94:	8652                	mv	a2,s4
    80004f96:	85ca                	mv	a1,s2
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	6d8080e7          	jalr	1752(ra) # 80001672 <copyout>
    80004fa2:	10054363          	bltz	a0,800050a8 <exec+0x2f6>
    ustack[argc] = sp;
    80004fa6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004faa:	0485                	addi	s1,s1,1
    80004fac:	008d8793          	addi	a5,s11,8
    80004fb0:	e0f43023          	sd	a5,-512(s0)
    80004fb4:	008db503          	ld	a0,8(s11)
    80004fb8:	c911                	beqz	a0,80004fcc <exec+0x21a>
    if(argc >= MAXARG)
    80004fba:	09a1                	addi	s3,s3,8
    80004fbc:	fb3c96e3          	bne	s9,s3,80004f68 <exec+0x1b6>
  sz = sz1;
    80004fc0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc4:	4481                	li	s1,0
    80004fc6:	a84d                	j	80005078 <exec+0x2c6>
  sp = sz;
    80004fc8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fcc:	00349793          	slli	a5,s1,0x3
    80004fd0:	f9040713          	addi	a4,s0,-112
    80004fd4:	97ba                	add	a5,a5,a4
    80004fd6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fda:	00148693          	addi	a3,s1,1
    80004fde:	068e                	slli	a3,a3,0x3
    80004fe0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fe4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fe8:	01897663          	bgeu	s2,s8,80004ff4 <exec+0x242>
  sz = sz1;
    80004fec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff0:	4481                	li	s1,0
    80004ff2:	a059                	j	80005078 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ff4:	e9040613          	addi	a2,s0,-368
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	855e                	mv	a0,s7
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	676080e7          	jalr	1654(ra) # 80001672 <copyout>
    80005004:	0a054663          	bltz	a0,800050b0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005008:	080ab783          	ld	a5,128(s5)
    8000500c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005010:	df843783          	ld	a5,-520(s0)
    80005014:	0007c703          	lbu	a4,0(a5)
    80005018:	cf11                	beqz	a4,80005034 <exec+0x282>
    8000501a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000501c:	02f00693          	li	a3,47
    80005020:	a039                	j	8000502e <exec+0x27c>
      last = s+1;
    80005022:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005026:	0785                	addi	a5,a5,1
    80005028:	fff7c703          	lbu	a4,-1(a5)
    8000502c:	c701                	beqz	a4,80005034 <exec+0x282>
    if(*s == '/')
    8000502e:	fed71ce3          	bne	a4,a3,80005026 <exec+0x274>
    80005032:	bfc5                	j	80005022 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005034:	4641                	li	a2,16
    80005036:	df843583          	ld	a1,-520(s0)
    8000503a:	180a8513          	addi	a0,s5,384
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	df4080e7          	jalr	-524(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005046:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    8000504a:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    8000504e:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005052:	080ab783          	ld	a5,128(s5)
    80005056:	e6843703          	ld	a4,-408(s0)
    8000505a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000505c:	080ab783          	ld	a5,128(s5)
    80005060:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005064:	85ea                	mv	a1,s10
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	aaa080e7          	jalr	-1366(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000506e:	0004851b          	sext.w	a0,s1
    80005072:	bbe1                	j	80004e4a <exec+0x98>
    80005074:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005078:	e0843583          	ld	a1,-504(s0)
    8000507c:	855e                	mv	a0,s7
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	a92080e7          	jalr	-1390(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005086:	da0498e3          	bnez	s1,80004e36 <exec+0x84>
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	bb7d                	j	80004e4a <exec+0x98>
    8000508e:	e1243423          	sd	s2,-504(s0)
    80005092:	b7dd                	j	80005078 <exec+0x2c6>
    80005094:	e1243423          	sd	s2,-504(s0)
    80005098:	b7c5                	j	80005078 <exec+0x2c6>
    8000509a:	e1243423          	sd	s2,-504(s0)
    8000509e:	bfe9                	j	80005078 <exec+0x2c6>
  sz = sz1;
    800050a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a4:	4481                	li	s1,0
    800050a6:	bfc9                	j	80005078 <exec+0x2c6>
  sz = sz1;
    800050a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ac:	4481                	li	s1,0
    800050ae:	b7e9                	j	80005078 <exec+0x2c6>
  sz = sz1;
    800050b0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050b4:	4481                	li	s1,0
    800050b6:	b7c9                	j	80005078 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050b8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050bc:	2b05                	addiw	s6,s6,1
    800050be:	0389899b          	addiw	s3,s3,56
    800050c2:	e8845783          	lhu	a5,-376(s0)
    800050c6:	e2fb5be3          	bge	s6,a5,80004efc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ca:	2981                	sext.w	s3,s3
    800050cc:	03800713          	li	a4,56
    800050d0:	86ce                	mv	a3,s3
    800050d2:	e1840613          	addi	a2,s0,-488
    800050d6:	4581                	li	a1,0
    800050d8:	8526                	mv	a0,s1
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	a8e080e7          	jalr	-1394(ra) # 80003b68 <readi>
    800050e2:	03800793          	li	a5,56
    800050e6:	f8f517e3          	bne	a0,a5,80005074 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050ea:	e1842783          	lw	a5,-488(s0)
    800050ee:	4705                	li	a4,1
    800050f0:	fce796e3          	bne	a5,a4,800050bc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050f4:	e4043603          	ld	a2,-448(s0)
    800050f8:	e3843783          	ld	a5,-456(s0)
    800050fc:	f8f669e3          	bltu	a2,a5,8000508e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005100:	e2843783          	ld	a5,-472(s0)
    80005104:	963e                	add	a2,a2,a5
    80005106:	f8f667e3          	bltu	a2,a5,80005094 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000510a:	85ca                	mv	a1,s2
    8000510c:	855e                	mv	a0,s7
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	314080e7          	jalr	788(ra) # 80001422 <uvmalloc>
    80005116:	e0a43423          	sd	a0,-504(s0)
    8000511a:	d141                	beqz	a0,8000509a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000511c:	e2843d03          	ld	s10,-472(s0)
    80005120:	df043783          	ld	a5,-528(s0)
    80005124:	00fd77b3          	and	a5,s10,a5
    80005128:	fba1                	bnez	a5,80005078 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000512a:	e2042d83          	lw	s11,-480(s0)
    8000512e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005132:	f80c03e3          	beqz	s8,800050b8 <exec+0x306>
    80005136:	8a62                	mv	s4,s8
    80005138:	4901                	li	s2,0
    8000513a:	b345                	j	80004eda <exec+0x128>

000000008000513c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000513c:	7179                	addi	sp,sp,-48
    8000513e:	f406                	sd	ra,40(sp)
    80005140:	f022                	sd	s0,32(sp)
    80005142:	ec26                	sd	s1,24(sp)
    80005144:	e84a                	sd	s2,16(sp)
    80005146:	1800                	addi	s0,sp,48
    80005148:	892e                	mv	s2,a1
    8000514a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000514c:	fdc40593          	addi	a1,s0,-36
    80005150:	ffffe097          	auipc	ra,0xffffe
    80005154:	a84080e7          	jalr	-1404(ra) # 80002bd4 <argint>
    80005158:	04054063          	bltz	a0,80005198 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000515c:	fdc42703          	lw	a4,-36(s0)
    80005160:	47bd                	li	a5,15
    80005162:	02e7ed63          	bltu	a5,a4,8000519c <argfd+0x60>
    80005166:	ffffd097          	auipc	ra,0xffffd
    8000516a:	84a080e7          	jalr	-1974(ra) # 800019b0 <myproc>
    8000516e:	fdc42703          	lw	a4,-36(s0)
    80005172:	01e70793          	addi	a5,a4,30
    80005176:	078e                	slli	a5,a5,0x3
    80005178:	953e                	add	a0,a0,a5
    8000517a:	651c                	ld	a5,8(a0)
    8000517c:	c395                	beqz	a5,800051a0 <argfd+0x64>
    return -1;
  if(pfd)
    8000517e:	00090463          	beqz	s2,80005186 <argfd+0x4a>
    *pfd = fd;
    80005182:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005186:	4501                	li	a0,0
  if(pf)
    80005188:	c091                	beqz	s1,8000518c <argfd+0x50>
    *pf = f;
    8000518a:	e09c                	sd	a5,0(s1)
}
    8000518c:	70a2                	ld	ra,40(sp)
    8000518e:	7402                	ld	s0,32(sp)
    80005190:	64e2                	ld	s1,24(sp)
    80005192:	6942                	ld	s2,16(sp)
    80005194:	6145                	addi	sp,sp,48
    80005196:	8082                	ret
    return -1;
    80005198:	557d                	li	a0,-1
    8000519a:	bfcd                	j	8000518c <argfd+0x50>
    return -1;
    8000519c:	557d                	li	a0,-1
    8000519e:	b7fd                	j	8000518c <argfd+0x50>
    800051a0:	557d                	li	a0,-1
    800051a2:	b7ed                	j	8000518c <argfd+0x50>

00000000800051a4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051a4:	1101                	addi	sp,sp,-32
    800051a6:	ec06                	sd	ra,24(sp)
    800051a8:	e822                	sd	s0,16(sp)
    800051aa:	e426                	sd	s1,8(sp)
    800051ac:	1000                	addi	s0,sp,32
    800051ae:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	800080e7          	jalr	-2048(ra) # 800019b0 <myproc>
    800051b8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051ba:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    800051be:	4501                	li	a0,0
    800051c0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051c2:	6398                	ld	a4,0(a5)
    800051c4:	cb19                	beqz	a4,800051da <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051c6:	2505                	addiw	a0,a0,1
    800051c8:	07a1                	addi	a5,a5,8
    800051ca:	fed51ce3          	bne	a0,a3,800051c2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ce:	557d                	li	a0,-1
}
    800051d0:	60e2                	ld	ra,24(sp)
    800051d2:	6442                	ld	s0,16(sp)
    800051d4:	64a2                	ld	s1,8(sp)
    800051d6:	6105                	addi	sp,sp,32
    800051d8:	8082                	ret
      p->ofile[fd] = f;
    800051da:	01e50793          	addi	a5,a0,30
    800051de:	078e                	slli	a5,a5,0x3
    800051e0:	963e                	add	a2,a2,a5
    800051e2:	e604                	sd	s1,8(a2)
      return fd;
    800051e4:	b7f5                	j	800051d0 <fdalloc+0x2c>

00000000800051e6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051e6:	715d                	addi	sp,sp,-80
    800051e8:	e486                	sd	ra,72(sp)
    800051ea:	e0a2                	sd	s0,64(sp)
    800051ec:	fc26                	sd	s1,56(sp)
    800051ee:	f84a                	sd	s2,48(sp)
    800051f0:	f44e                	sd	s3,40(sp)
    800051f2:	f052                	sd	s4,32(sp)
    800051f4:	ec56                	sd	s5,24(sp)
    800051f6:	0880                	addi	s0,sp,80
    800051f8:	89ae                	mv	s3,a1
    800051fa:	8ab2                	mv	s5,a2
    800051fc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051fe:	fb040593          	addi	a1,s0,-80
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	e86080e7          	jalr	-378(ra) # 80004088 <nameiparent>
    8000520a:	892a                	mv	s2,a0
    8000520c:	12050f63          	beqz	a0,8000534a <create+0x164>
    return 0;

  ilock(dp);
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	6a4080e7          	jalr	1700(ra) # 800038b4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005218:	4601                	li	a2,0
    8000521a:	fb040593          	addi	a1,s0,-80
    8000521e:	854a                	mv	a0,s2
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	b78080e7          	jalr	-1160(ra) # 80003d98 <dirlookup>
    80005228:	84aa                	mv	s1,a0
    8000522a:	c921                	beqz	a0,8000527a <create+0x94>
    iunlockput(dp);
    8000522c:	854a                	mv	a0,s2
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	8e8080e7          	jalr	-1816(ra) # 80003b16 <iunlockput>
    ilock(ip);
    80005236:	8526                	mv	a0,s1
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	67c080e7          	jalr	1660(ra) # 800038b4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005240:	2981                	sext.w	s3,s3
    80005242:	4789                	li	a5,2
    80005244:	02f99463          	bne	s3,a5,8000526c <create+0x86>
    80005248:	0444d783          	lhu	a5,68(s1)
    8000524c:	37f9                	addiw	a5,a5,-2
    8000524e:	17c2                	slli	a5,a5,0x30
    80005250:	93c1                	srli	a5,a5,0x30
    80005252:	4705                	li	a4,1
    80005254:	00f76c63          	bltu	a4,a5,8000526c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005258:	8526                	mv	a0,s1
    8000525a:	60a6                	ld	ra,72(sp)
    8000525c:	6406                	ld	s0,64(sp)
    8000525e:	74e2                	ld	s1,56(sp)
    80005260:	7942                	ld	s2,48(sp)
    80005262:	79a2                	ld	s3,40(sp)
    80005264:	7a02                	ld	s4,32(sp)
    80005266:	6ae2                	ld	s5,24(sp)
    80005268:	6161                	addi	sp,sp,80
    8000526a:	8082                	ret
    iunlockput(ip);
    8000526c:	8526                	mv	a0,s1
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	8a8080e7          	jalr	-1880(ra) # 80003b16 <iunlockput>
    return 0;
    80005276:	4481                	li	s1,0
    80005278:	b7c5                	j	80005258 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000527a:	85ce                	mv	a1,s3
    8000527c:	00092503          	lw	a0,0(s2)
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	49c080e7          	jalr	1180(ra) # 8000371c <ialloc>
    80005288:	84aa                	mv	s1,a0
    8000528a:	c529                	beqz	a0,800052d4 <create+0xee>
  ilock(ip);
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	628080e7          	jalr	1576(ra) # 800038b4 <ilock>
  ip->major = major;
    80005294:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005298:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000529c:	4785                	li	a5,1
    8000529e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052a2:	8526                	mv	a0,s1
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	546080e7          	jalr	1350(ra) # 800037ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ac:	2981                	sext.w	s3,s3
    800052ae:	4785                	li	a5,1
    800052b0:	02f98a63          	beq	s3,a5,800052e4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052b4:	40d0                	lw	a2,4(s1)
    800052b6:	fb040593          	addi	a1,s0,-80
    800052ba:	854a                	mv	a0,s2
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	cec080e7          	jalr	-788(ra) # 80003fa8 <dirlink>
    800052c4:	06054b63          	bltz	a0,8000533a <create+0x154>
  iunlockput(dp);
    800052c8:	854a                	mv	a0,s2
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	84c080e7          	jalr	-1972(ra) # 80003b16 <iunlockput>
  return ip;
    800052d2:	b759                	j	80005258 <create+0x72>
    panic("create: ialloc");
    800052d4:	00003517          	auipc	a0,0x3
    800052d8:	4fc50513          	addi	a0,a0,1276 # 800087d0 <syscalls+0x2a8>
    800052dc:	ffffb097          	auipc	ra,0xffffb
    800052e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052e4:	04a95783          	lhu	a5,74(s2)
    800052e8:	2785                	addiw	a5,a5,1
    800052ea:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052ee:	854a                	mv	a0,s2
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	4fa080e7          	jalr	1274(ra) # 800037ea <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052f8:	40d0                	lw	a2,4(s1)
    800052fa:	00003597          	auipc	a1,0x3
    800052fe:	4e658593          	addi	a1,a1,1254 # 800087e0 <syscalls+0x2b8>
    80005302:	8526                	mv	a0,s1
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	ca4080e7          	jalr	-860(ra) # 80003fa8 <dirlink>
    8000530c:	00054f63          	bltz	a0,8000532a <create+0x144>
    80005310:	00492603          	lw	a2,4(s2)
    80005314:	00003597          	auipc	a1,0x3
    80005318:	4d458593          	addi	a1,a1,1236 # 800087e8 <syscalls+0x2c0>
    8000531c:	8526                	mv	a0,s1
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	c8a080e7          	jalr	-886(ra) # 80003fa8 <dirlink>
    80005326:	f80557e3          	bgez	a0,800052b4 <create+0xce>
      panic("create dots");
    8000532a:	00003517          	auipc	a0,0x3
    8000532e:	4c650513          	addi	a0,a0,1222 # 800087f0 <syscalls+0x2c8>
    80005332:	ffffb097          	auipc	ra,0xffffb
    80005336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000533a:	00003517          	auipc	a0,0x3
    8000533e:	4c650513          	addi	a0,a0,1222 # 80008800 <syscalls+0x2d8>
    80005342:	ffffb097          	auipc	ra,0xffffb
    80005346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>
    return 0;
    8000534a:	84aa                	mv	s1,a0
    8000534c:	b731                	j	80005258 <create+0x72>

000000008000534e <sys_dup>:
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	ec26                	sd	s1,24(sp)
    80005356:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005358:	fd840613          	addi	a2,s0,-40
    8000535c:	4581                	li	a1,0
    8000535e:	4501                	li	a0,0
    80005360:	00000097          	auipc	ra,0x0
    80005364:	ddc080e7          	jalr	-548(ra) # 8000513c <argfd>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000536a:	02054363          	bltz	a0,80005390 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000536e:	fd843503          	ld	a0,-40(s0)
    80005372:	00000097          	auipc	ra,0x0
    80005376:	e32080e7          	jalr	-462(ra) # 800051a4 <fdalloc>
    8000537a:	84aa                	mv	s1,a0
    return -1;
    8000537c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000537e:	00054963          	bltz	a0,80005390 <sys_dup+0x42>
  filedup(f);
    80005382:	fd843503          	ld	a0,-40(s0)
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	37a080e7          	jalr	890(ra) # 80004700 <filedup>
  return fd;
    8000538e:	87a6                	mv	a5,s1
}
    80005390:	853e                	mv	a0,a5
    80005392:	70a2                	ld	ra,40(sp)
    80005394:	7402                	ld	s0,32(sp)
    80005396:	64e2                	ld	s1,24(sp)
    80005398:	6145                	addi	sp,sp,48
    8000539a:	8082                	ret

000000008000539c <sys_read>:
{
    8000539c:	7179                	addi	sp,sp,-48
    8000539e:	f406                	sd	ra,40(sp)
    800053a0:	f022                	sd	s0,32(sp)
    800053a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a4:	fe840613          	addi	a2,s0,-24
    800053a8:	4581                	li	a1,0
    800053aa:	4501                	li	a0,0
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	d90080e7          	jalr	-624(ra) # 8000513c <argfd>
    return -1;
    800053b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b6:	04054163          	bltz	a0,800053f8 <sys_read+0x5c>
    800053ba:	fe440593          	addi	a1,s0,-28
    800053be:	4509                	li	a0,2
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	814080e7          	jalr	-2028(ra) # 80002bd4 <argint>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ca:	02054763          	bltz	a0,800053f8 <sys_read+0x5c>
    800053ce:	fd840593          	addi	a1,s0,-40
    800053d2:	4505                	li	a0,1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	822080e7          	jalr	-2014(ra) # 80002bf6 <argaddr>
    return -1;
    800053dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053de:	00054d63          	bltz	a0,800053f8 <sys_read+0x5c>
  return fileread(f, p, n);
    800053e2:	fe442603          	lw	a2,-28(s0)
    800053e6:	fd843583          	ld	a1,-40(s0)
    800053ea:	fe843503          	ld	a0,-24(s0)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	49e080e7          	jalr	1182(ra) # 8000488c <fileread>
    800053f6:	87aa                	mv	a5,a0
}
    800053f8:	853e                	mv	a0,a5
    800053fa:	70a2                	ld	ra,40(sp)
    800053fc:	7402                	ld	s0,32(sp)
    800053fe:	6145                	addi	sp,sp,48
    80005400:	8082                	ret

0000000080005402 <sys_write>:
{
    80005402:	7179                	addi	sp,sp,-48
    80005404:	f406                	sd	ra,40(sp)
    80005406:	f022                	sd	s0,32(sp)
    80005408:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540a:	fe840613          	addi	a2,s0,-24
    8000540e:	4581                	li	a1,0
    80005410:	4501                	li	a0,0
    80005412:	00000097          	auipc	ra,0x0
    80005416:	d2a080e7          	jalr	-726(ra) # 8000513c <argfd>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541c:	04054163          	bltz	a0,8000545e <sys_write+0x5c>
    80005420:	fe440593          	addi	a1,s0,-28
    80005424:	4509                	li	a0,2
    80005426:	ffffd097          	auipc	ra,0xffffd
    8000542a:	7ae080e7          	jalr	1966(ra) # 80002bd4 <argint>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005430:	02054763          	bltz	a0,8000545e <sys_write+0x5c>
    80005434:	fd840593          	addi	a1,s0,-40
    80005438:	4505                	li	a0,1
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	7bc080e7          	jalr	1980(ra) # 80002bf6 <argaddr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005444:	00054d63          	bltz	a0,8000545e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005448:	fe442603          	lw	a2,-28(s0)
    8000544c:	fd843583          	ld	a1,-40(s0)
    80005450:	fe843503          	ld	a0,-24(s0)
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	4fa080e7          	jalr	1274(ra) # 8000494e <filewrite>
    8000545c:	87aa                	mv	a5,a0
}
    8000545e:	853e                	mv	a0,a5
    80005460:	70a2                	ld	ra,40(sp)
    80005462:	7402                	ld	s0,32(sp)
    80005464:	6145                	addi	sp,sp,48
    80005466:	8082                	ret

0000000080005468 <sys_close>:
{
    80005468:	1101                	addi	sp,sp,-32
    8000546a:	ec06                	sd	ra,24(sp)
    8000546c:	e822                	sd	s0,16(sp)
    8000546e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005470:	fe040613          	addi	a2,s0,-32
    80005474:	fec40593          	addi	a1,s0,-20
    80005478:	4501                	li	a0,0
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	cc2080e7          	jalr	-830(ra) # 8000513c <argfd>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005484:	02054463          	bltz	a0,800054ac <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	528080e7          	jalr	1320(ra) # 800019b0 <myproc>
    80005490:	fec42783          	lw	a5,-20(s0)
    80005494:	07f9                	addi	a5,a5,30
    80005496:	078e                	slli	a5,a5,0x3
    80005498:	97aa                	add	a5,a5,a0
    8000549a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000549e:	fe043503          	ld	a0,-32(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	2b0080e7          	jalr	688(ra) # 80004752 <fileclose>
  return 0;
    800054aa:	4781                	li	a5,0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	60e2                	ld	ra,24(sp)
    800054b0:	6442                	ld	s0,16(sp)
    800054b2:	6105                	addi	sp,sp,32
    800054b4:	8082                	ret

00000000800054b6 <sys_fstat>:
{
    800054b6:	1101                	addi	sp,sp,-32
    800054b8:	ec06                	sd	ra,24(sp)
    800054ba:	e822                	sd	s0,16(sp)
    800054bc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054be:	fe840613          	addi	a2,s0,-24
    800054c2:	4581                	li	a1,0
    800054c4:	4501                	li	a0,0
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	c76080e7          	jalr	-906(ra) # 8000513c <argfd>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054d0:	02054563          	bltz	a0,800054fa <sys_fstat+0x44>
    800054d4:	fe040593          	addi	a1,s0,-32
    800054d8:	4505                	li	a0,1
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	71c080e7          	jalr	1820(ra) # 80002bf6 <argaddr>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e4:	00054b63          	bltz	a0,800054fa <sys_fstat+0x44>
  return filestat(f, st);
    800054e8:	fe043583          	ld	a1,-32(s0)
    800054ec:	fe843503          	ld	a0,-24(s0)
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	32a080e7          	jalr	810(ra) # 8000481a <filestat>
    800054f8:	87aa                	mv	a5,a0
}
    800054fa:	853e                	mv	a0,a5
    800054fc:	60e2                	ld	ra,24(sp)
    800054fe:	6442                	ld	s0,16(sp)
    80005500:	6105                	addi	sp,sp,32
    80005502:	8082                	ret

0000000080005504 <sys_link>:
{
    80005504:	7169                	addi	sp,sp,-304
    80005506:	f606                	sd	ra,296(sp)
    80005508:	f222                	sd	s0,288(sp)
    8000550a:	ee26                	sd	s1,280(sp)
    8000550c:	ea4a                	sd	s2,272(sp)
    8000550e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005510:	08000613          	li	a2,128
    80005514:	ed040593          	addi	a1,s0,-304
    80005518:	4501                	li	a0,0
    8000551a:	ffffd097          	auipc	ra,0xffffd
    8000551e:	6fe080e7          	jalr	1790(ra) # 80002c18 <argstr>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005524:	10054e63          	bltz	a0,80005640 <sys_link+0x13c>
    80005528:	08000613          	li	a2,128
    8000552c:	f5040593          	addi	a1,s0,-176
    80005530:	4505                	li	a0,1
    80005532:	ffffd097          	auipc	ra,0xffffd
    80005536:	6e6080e7          	jalr	1766(ra) # 80002c18 <argstr>
    return -1;
    8000553a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553c:	10054263          	bltz	a0,80005640 <sys_link+0x13c>
  begin_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	d46080e7          	jalr	-698(ra) # 80004286 <begin_op>
  if((ip = namei(old)) == 0){
    80005548:	ed040513          	addi	a0,s0,-304
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	b1e080e7          	jalr	-1250(ra) # 8000406a <namei>
    80005554:	84aa                	mv	s1,a0
    80005556:	c551                	beqz	a0,800055e2 <sys_link+0xde>
  ilock(ip);
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	35c080e7          	jalr	860(ra) # 800038b4 <ilock>
  if(ip->type == T_DIR){
    80005560:	04449703          	lh	a4,68(s1)
    80005564:	4785                	li	a5,1
    80005566:	08f70463          	beq	a4,a5,800055ee <sys_link+0xea>
  ip->nlink++;
    8000556a:	04a4d783          	lhu	a5,74(s1)
    8000556e:	2785                	addiw	a5,a5,1
    80005570:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	274080e7          	jalr	628(ra) # 800037ea <iupdate>
  iunlock(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	3f6080e7          	jalr	1014(ra) # 80003976 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005588:	fd040593          	addi	a1,s0,-48
    8000558c:	f5040513          	addi	a0,s0,-176
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	af8080e7          	jalr	-1288(ra) # 80004088 <nameiparent>
    80005598:	892a                	mv	s2,a0
    8000559a:	c935                	beqz	a0,8000560e <sys_link+0x10a>
  ilock(dp);
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	318080e7          	jalr	792(ra) # 800038b4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055a4:	00092703          	lw	a4,0(s2)
    800055a8:	409c                	lw	a5,0(s1)
    800055aa:	04f71d63          	bne	a4,a5,80005604 <sys_link+0x100>
    800055ae:	40d0                	lw	a2,4(s1)
    800055b0:	fd040593          	addi	a1,s0,-48
    800055b4:	854a                	mv	a0,s2
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	9f2080e7          	jalr	-1550(ra) # 80003fa8 <dirlink>
    800055be:	04054363          	bltz	a0,80005604 <sys_link+0x100>
  iunlockput(dp);
    800055c2:	854a                	mv	a0,s2
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	552080e7          	jalr	1362(ra) # 80003b16 <iunlockput>
  iput(ip);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	4a0080e7          	jalr	1184(ra) # 80003a6e <iput>
  end_op();
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	d30080e7          	jalr	-720(ra) # 80004306 <end_op>
  return 0;
    800055de:	4781                	li	a5,0
    800055e0:	a085                	j	80005640 <sys_link+0x13c>
    end_op();
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	d24080e7          	jalr	-732(ra) # 80004306 <end_op>
    return -1;
    800055ea:	57fd                	li	a5,-1
    800055ec:	a891                	j	80005640 <sys_link+0x13c>
    iunlockput(ip);
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	526080e7          	jalr	1318(ra) # 80003b16 <iunlockput>
    end_op();
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	d0e080e7          	jalr	-754(ra) # 80004306 <end_op>
    return -1;
    80005600:	57fd                	li	a5,-1
    80005602:	a83d                	j	80005640 <sys_link+0x13c>
    iunlockput(dp);
    80005604:	854a                	mv	a0,s2
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	510080e7          	jalr	1296(ra) # 80003b16 <iunlockput>
  ilock(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	2a4080e7          	jalr	676(ra) # 800038b4 <ilock>
  ip->nlink--;
    80005618:	04a4d783          	lhu	a5,74(s1)
    8000561c:	37fd                	addiw	a5,a5,-1
    8000561e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	1c6080e7          	jalr	454(ra) # 800037ea <iupdate>
  iunlockput(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	4e8080e7          	jalr	1256(ra) # 80003b16 <iunlockput>
  end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	cd0080e7          	jalr	-816(ra) # 80004306 <end_op>
  return -1;
    8000563e:	57fd                	li	a5,-1
}
    80005640:	853e                	mv	a0,a5
    80005642:	70b2                	ld	ra,296(sp)
    80005644:	7412                	ld	s0,288(sp)
    80005646:	64f2                	ld	s1,280(sp)
    80005648:	6952                	ld	s2,272(sp)
    8000564a:	6155                	addi	sp,sp,304
    8000564c:	8082                	ret

000000008000564e <sys_unlink>:
{
    8000564e:	7151                	addi	sp,sp,-240
    80005650:	f586                	sd	ra,232(sp)
    80005652:	f1a2                	sd	s0,224(sp)
    80005654:	eda6                	sd	s1,216(sp)
    80005656:	e9ca                	sd	s2,208(sp)
    80005658:	e5ce                	sd	s3,200(sp)
    8000565a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000565c:	08000613          	li	a2,128
    80005660:	f3040593          	addi	a1,s0,-208
    80005664:	4501                	li	a0,0
    80005666:	ffffd097          	auipc	ra,0xffffd
    8000566a:	5b2080e7          	jalr	1458(ra) # 80002c18 <argstr>
    8000566e:	18054163          	bltz	a0,800057f0 <sys_unlink+0x1a2>
  begin_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	c14080e7          	jalr	-1004(ra) # 80004286 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000567a:	fb040593          	addi	a1,s0,-80
    8000567e:	f3040513          	addi	a0,s0,-208
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	a06080e7          	jalr	-1530(ra) # 80004088 <nameiparent>
    8000568a:	84aa                	mv	s1,a0
    8000568c:	c979                	beqz	a0,80005762 <sys_unlink+0x114>
  ilock(dp);
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	226080e7          	jalr	550(ra) # 800038b4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005696:	00003597          	auipc	a1,0x3
    8000569a:	14a58593          	addi	a1,a1,330 # 800087e0 <syscalls+0x2b8>
    8000569e:	fb040513          	addi	a0,s0,-80
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	6dc080e7          	jalr	1756(ra) # 80003d7e <namecmp>
    800056aa:	14050a63          	beqz	a0,800057fe <sys_unlink+0x1b0>
    800056ae:	00003597          	auipc	a1,0x3
    800056b2:	13a58593          	addi	a1,a1,314 # 800087e8 <syscalls+0x2c0>
    800056b6:	fb040513          	addi	a0,s0,-80
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	6c4080e7          	jalr	1732(ra) # 80003d7e <namecmp>
    800056c2:	12050e63          	beqz	a0,800057fe <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056c6:	f2c40613          	addi	a2,s0,-212
    800056ca:	fb040593          	addi	a1,s0,-80
    800056ce:	8526                	mv	a0,s1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	6c8080e7          	jalr	1736(ra) # 80003d98 <dirlookup>
    800056d8:	892a                	mv	s2,a0
    800056da:	12050263          	beqz	a0,800057fe <sys_unlink+0x1b0>
  ilock(ip);
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	1d6080e7          	jalr	470(ra) # 800038b4 <ilock>
  if(ip->nlink < 1)
    800056e6:	04a91783          	lh	a5,74(s2)
    800056ea:	08f05263          	blez	a5,8000576e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056ee:	04491703          	lh	a4,68(s2)
    800056f2:	4785                	li	a5,1
    800056f4:	08f70563          	beq	a4,a5,8000577e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056f8:	4641                	li	a2,16
    800056fa:	4581                	li	a1,0
    800056fc:	fc040513          	addi	a0,s0,-64
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	5e0080e7          	jalr	1504(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005708:	4741                	li	a4,16
    8000570a:	f2c42683          	lw	a3,-212(s0)
    8000570e:	fc040613          	addi	a2,s0,-64
    80005712:	4581                	li	a1,0
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	54a080e7          	jalr	1354(ra) # 80003c60 <writei>
    8000571e:	47c1                	li	a5,16
    80005720:	0af51563          	bne	a0,a5,800057ca <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005724:	04491703          	lh	a4,68(s2)
    80005728:	4785                	li	a5,1
    8000572a:	0af70863          	beq	a4,a5,800057da <sys_unlink+0x18c>
  iunlockput(dp);
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	3e6080e7          	jalr	998(ra) # 80003b16 <iunlockput>
  ip->nlink--;
    80005738:	04a95783          	lhu	a5,74(s2)
    8000573c:	37fd                	addiw	a5,a5,-1
    8000573e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005742:	854a                	mv	a0,s2
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	0a6080e7          	jalr	166(ra) # 800037ea <iupdate>
  iunlockput(ip);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	3c8080e7          	jalr	968(ra) # 80003b16 <iunlockput>
  end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	bb0080e7          	jalr	-1104(ra) # 80004306 <end_op>
  return 0;
    8000575e:	4501                	li	a0,0
    80005760:	a84d                	j	80005812 <sys_unlink+0x1c4>
    end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	ba4080e7          	jalr	-1116(ra) # 80004306 <end_op>
    return -1;
    8000576a:	557d                	li	a0,-1
    8000576c:	a05d                	j	80005812 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000576e:	00003517          	auipc	a0,0x3
    80005772:	0a250513          	addi	a0,a0,162 # 80008810 <syscalls+0x2e8>
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000577e:	04c92703          	lw	a4,76(s2)
    80005782:	02000793          	li	a5,32
    80005786:	f6e7f9e3          	bgeu	a5,a4,800056f8 <sys_unlink+0xaa>
    8000578a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000578e:	4741                	li	a4,16
    80005790:	86ce                	mv	a3,s3
    80005792:	f1840613          	addi	a2,s0,-232
    80005796:	4581                	li	a1,0
    80005798:	854a                	mv	a0,s2
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	3ce080e7          	jalr	974(ra) # 80003b68 <readi>
    800057a2:	47c1                	li	a5,16
    800057a4:	00f51b63          	bne	a0,a5,800057ba <sys_unlink+0x16c>
    if(de.inum != 0)
    800057a8:	f1845783          	lhu	a5,-232(s0)
    800057ac:	e7a1                	bnez	a5,800057f4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ae:	29c1                	addiw	s3,s3,16
    800057b0:	04c92783          	lw	a5,76(s2)
    800057b4:	fcf9ede3          	bltu	s3,a5,8000578e <sys_unlink+0x140>
    800057b8:	b781                	j	800056f8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057ba:	00003517          	auipc	a0,0x3
    800057be:	06e50513          	addi	a0,a0,110 # 80008828 <syscalls+0x300>
    800057c2:	ffffb097          	auipc	ra,0xffffb
    800057c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057ca:	00003517          	auipc	a0,0x3
    800057ce:	07650513          	addi	a0,a0,118 # 80008840 <syscalls+0x318>
    800057d2:	ffffb097          	auipc	ra,0xffffb
    800057d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>
    dp->nlink--;
    800057da:	04a4d783          	lhu	a5,74(s1)
    800057de:	37fd                	addiw	a5,a5,-1
    800057e0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	004080e7          	jalr	4(ra) # 800037ea <iupdate>
    800057ee:	b781                	j	8000572e <sys_unlink+0xe0>
    return -1;
    800057f0:	557d                	li	a0,-1
    800057f2:	a005                	j	80005812 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	320080e7          	jalr	800(ra) # 80003b16 <iunlockput>
  iunlockput(dp);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	316080e7          	jalr	790(ra) # 80003b16 <iunlockput>
  end_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	afe080e7          	jalr	-1282(ra) # 80004306 <end_op>
  return -1;
    80005810:	557d                	li	a0,-1
}
    80005812:	70ae                	ld	ra,232(sp)
    80005814:	740e                	ld	s0,224(sp)
    80005816:	64ee                	ld	s1,216(sp)
    80005818:	694e                	ld	s2,208(sp)
    8000581a:	69ae                	ld	s3,200(sp)
    8000581c:	616d                	addi	sp,sp,240
    8000581e:	8082                	ret

0000000080005820 <sys_open>:

uint64
sys_open(void)
{
    80005820:	7131                	addi	sp,sp,-192
    80005822:	fd06                	sd	ra,184(sp)
    80005824:	f922                	sd	s0,176(sp)
    80005826:	f526                	sd	s1,168(sp)
    80005828:	f14a                	sd	s2,160(sp)
    8000582a:	ed4e                	sd	s3,152(sp)
    8000582c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000582e:	08000613          	li	a2,128
    80005832:	f5040593          	addi	a1,s0,-176
    80005836:	4501                	li	a0,0
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	3e0080e7          	jalr	992(ra) # 80002c18 <argstr>
    return -1;
    80005840:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005842:	0c054163          	bltz	a0,80005904 <sys_open+0xe4>
    80005846:	f4c40593          	addi	a1,s0,-180
    8000584a:	4505                	li	a0,1
    8000584c:	ffffd097          	auipc	ra,0xffffd
    80005850:	388080e7          	jalr	904(ra) # 80002bd4 <argint>
    80005854:	0a054863          	bltz	a0,80005904 <sys_open+0xe4>

  begin_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	a2e080e7          	jalr	-1490(ra) # 80004286 <begin_op>

  if(omode & O_CREATE){
    80005860:	f4c42783          	lw	a5,-180(s0)
    80005864:	2007f793          	andi	a5,a5,512
    80005868:	cbdd                	beqz	a5,8000591e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000586a:	4681                	li	a3,0
    8000586c:	4601                	li	a2,0
    8000586e:	4589                	li	a1,2
    80005870:	f5040513          	addi	a0,s0,-176
    80005874:	00000097          	auipc	ra,0x0
    80005878:	972080e7          	jalr	-1678(ra) # 800051e6 <create>
    8000587c:	892a                	mv	s2,a0
    if(ip == 0){
    8000587e:	c959                	beqz	a0,80005914 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005880:	04491703          	lh	a4,68(s2)
    80005884:	478d                	li	a5,3
    80005886:	00f71763          	bne	a4,a5,80005894 <sys_open+0x74>
    8000588a:	04695703          	lhu	a4,70(s2)
    8000588e:	47a5                	li	a5,9
    80005890:	0ce7ec63          	bltu	a5,a4,80005968 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	e02080e7          	jalr	-510(ra) # 80004696 <filealloc>
    8000589c:	89aa                	mv	s3,a0
    8000589e:	10050263          	beqz	a0,800059a2 <sys_open+0x182>
    800058a2:	00000097          	auipc	ra,0x0
    800058a6:	902080e7          	jalr	-1790(ra) # 800051a4 <fdalloc>
    800058aa:	84aa                	mv	s1,a0
    800058ac:	0e054663          	bltz	a0,80005998 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058b0:	04491703          	lh	a4,68(s2)
    800058b4:	478d                	li	a5,3
    800058b6:	0cf70463          	beq	a4,a5,8000597e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058ba:	4789                	li	a5,2
    800058bc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058c0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058c4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058c8:	f4c42783          	lw	a5,-180(s0)
    800058cc:	0017c713          	xori	a4,a5,1
    800058d0:	8b05                	andi	a4,a4,1
    800058d2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058d6:	0037f713          	andi	a4,a5,3
    800058da:	00e03733          	snez	a4,a4
    800058de:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058e2:	4007f793          	andi	a5,a5,1024
    800058e6:	c791                	beqz	a5,800058f2 <sys_open+0xd2>
    800058e8:	04491703          	lh	a4,68(s2)
    800058ec:	4789                	li	a5,2
    800058ee:	08f70f63          	beq	a4,a5,8000598c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058f2:	854a                	mv	a0,s2
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	082080e7          	jalr	130(ra) # 80003976 <iunlock>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	a0a080e7          	jalr	-1526(ra) # 80004306 <end_op>

  return fd;
}
    80005904:	8526                	mv	a0,s1
    80005906:	70ea                	ld	ra,184(sp)
    80005908:	744a                	ld	s0,176(sp)
    8000590a:	74aa                	ld	s1,168(sp)
    8000590c:	790a                	ld	s2,160(sp)
    8000590e:	69ea                	ld	s3,152(sp)
    80005910:	6129                	addi	sp,sp,192
    80005912:	8082                	ret
      end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	9f2080e7          	jalr	-1550(ra) # 80004306 <end_op>
      return -1;
    8000591c:	b7e5                	j	80005904 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000591e:	f5040513          	addi	a0,s0,-176
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	748080e7          	jalr	1864(ra) # 8000406a <namei>
    8000592a:	892a                	mv	s2,a0
    8000592c:	c905                	beqz	a0,8000595c <sys_open+0x13c>
    ilock(ip);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	f86080e7          	jalr	-122(ra) # 800038b4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005936:	04491703          	lh	a4,68(s2)
    8000593a:	4785                	li	a5,1
    8000593c:	f4f712e3          	bne	a4,a5,80005880 <sys_open+0x60>
    80005940:	f4c42783          	lw	a5,-180(s0)
    80005944:	dba1                	beqz	a5,80005894 <sys_open+0x74>
      iunlockput(ip);
    80005946:	854a                	mv	a0,s2
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	1ce080e7          	jalr	462(ra) # 80003b16 <iunlockput>
      end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	9b6080e7          	jalr	-1610(ra) # 80004306 <end_op>
      return -1;
    80005958:	54fd                	li	s1,-1
    8000595a:	b76d                	j	80005904 <sys_open+0xe4>
      end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	9aa080e7          	jalr	-1622(ra) # 80004306 <end_op>
      return -1;
    80005964:	54fd                	li	s1,-1
    80005966:	bf79                	j	80005904 <sys_open+0xe4>
    iunlockput(ip);
    80005968:	854a                	mv	a0,s2
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	1ac080e7          	jalr	428(ra) # 80003b16 <iunlockput>
    end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	994080e7          	jalr	-1644(ra) # 80004306 <end_op>
    return -1;
    8000597a:	54fd                	li	s1,-1
    8000597c:	b761                	j	80005904 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000597e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005982:	04691783          	lh	a5,70(s2)
    80005986:	02f99223          	sh	a5,36(s3)
    8000598a:	bf2d                	j	800058c4 <sys_open+0xa4>
    itrunc(ip);
    8000598c:	854a                	mv	a0,s2
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	034080e7          	jalr	52(ra) # 800039c2 <itrunc>
    80005996:	bfb1                	j	800058f2 <sys_open+0xd2>
      fileclose(f);
    80005998:	854e                	mv	a0,s3
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	db8080e7          	jalr	-584(ra) # 80004752 <fileclose>
    iunlockput(ip);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	172080e7          	jalr	370(ra) # 80003b16 <iunlockput>
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	95a080e7          	jalr	-1702(ra) # 80004306 <end_op>
    return -1;
    800059b4:	54fd                	li	s1,-1
    800059b6:	b7b9                	j	80005904 <sys_open+0xe4>

00000000800059b8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059b8:	7175                	addi	sp,sp,-144
    800059ba:	e506                	sd	ra,136(sp)
    800059bc:	e122                	sd	s0,128(sp)
    800059be:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	8c6080e7          	jalr	-1850(ra) # 80004286 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059c8:	08000613          	li	a2,128
    800059cc:	f7040593          	addi	a1,s0,-144
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	246080e7          	jalr	582(ra) # 80002c18 <argstr>
    800059da:	02054963          	bltz	a0,80005a0c <sys_mkdir+0x54>
    800059de:	4681                	li	a3,0
    800059e0:	4601                	li	a2,0
    800059e2:	4585                	li	a1,1
    800059e4:	f7040513          	addi	a0,s0,-144
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	7fe080e7          	jalr	2046(ra) # 800051e6 <create>
    800059f0:	cd11                	beqz	a0,80005a0c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	124080e7          	jalr	292(ra) # 80003b16 <iunlockput>
  end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	90c080e7          	jalr	-1780(ra) # 80004306 <end_op>
  return 0;
    80005a02:	4501                	li	a0,0
}
    80005a04:	60aa                	ld	ra,136(sp)
    80005a06:	640a                	ld	s0,128(sp)
    80005a08:	6149                	addi	sp,sp,144
    80005a0a:	8082                	ret
    end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	8fa080e7          	jalr	-1798(ra) # 80004306 <end_op>
    return -1;
    80005a14:	557d                	li	a0,-1
    80005a16:	b7fd                	j	80005a04 <sys_mkdir+0x4c>

0000000080005a18 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a18:	7135                	addi	sp,sp,-160
    80005a1a:	ed06                	sd	ra,152(sp)
    80005a1c:	e922                	sd	s0,144(sp)
    80005a1e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	866080e7          	jalr	-1946(ra) # 80004286 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a28:	08000613          	li	a2,128
    80005a2c:	f7040593          	addi	a1,s0,-144
    80005a30:	4501                	li	a0,0
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	1e6080e7          	jalr	486(ra) # 80002c18 <argstr>
    80005a3a:	04054a63          	bltz	a0,80005a8e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a3e:	f6c40593          	addi	a1,s0,-148
    80005a42:	4505                	li	a0,1
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	190080e7          	jalr	400(ra) # 80002bd4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a4c:	04054163          	bltz	a0,80005a8e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a50:	f6840593          	addi	a1,s0,-152
    80005a54:	4509                	li	a0,2
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	17e080e7          	jalr	382(ra) # 80002bd4 <argint>
     argint(1, &major) < 0 ||
    80005a5e:	02054863          	bltz	a0,80005a8e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a62:	f6841683          	lh	a3,-152(s0)
    80005a66:	f6c41603          	lh	a2,-148(s0)
    80005a6a:	458d                	li	a1,3
    80005a6c:	f7040513          	addi	a0,s0,-144
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	776080e7          	jalr	1910(ra) # 800051e6 <create>
     argint(2, &minor) < 0 ||
    80005a78:	c919                	beqz	a0,80005a8e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	09c080e7          	jalr	156(ra) # 80003b16 <iunlockput>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	884080e7          	jalr	-1916(ra) # 80004306 <end_op>
  return 0;
    80005a8a:	4501                	li	a0,0
    80005a8c:	a031                	j	80005a98 <sys_mknod+0x80>
    end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	878080e7          	jalr	-1928(ra) # 80004306 <end_op>
    return -1;
    80005a96:	557d                	li	a0,-1
}
    80005a98:	60ea                	ld	ra,152(sp)
    80005a9a:	644a                	ld	s0,144(sp)
    80005a9c:	610d                	addi	sp,sp,160
    80005a9e:	8082                	ret

0000000080005aa0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aa0:	7135                	addi	sp,sp,-160
    80005aa2:	ed06                	sd	ra,152(sp)
    80005aa4:	e922                	sd	s0,144(sp)
    80005aa6:	e526                	sd	s1,136(sp)
    80005aa8:	e14a                	sd	s2,128(sp)
    80005aaa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aac:	ffffc097          	auipc	ra,0xffffc
    80005ab0:	f04080e7          	jalr	-252(ra) # 800019b0 <myproc>
    80005ab4:	892a                	mv	s2,a0
  
  begin_op();
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	7d0080e7          	jalr	2000(ra) # 80004286 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005abe:	08000613          	li	a2,128
    80005ac2:	f6040593          	addi	a1,s0,-160
    80005ac6:	4501                	li	a0,0
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	150080e7          	jalr	336(ra) # 80002c18 <argstr>
    80005ad0:	04054b63          	bltz	a0,80005b26 <sys_chdir+0x86>
    80005ad4:	f6040513          	addi	a0,s0,-160
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	592080e7          	jalr	1426(ra) # 8000406a <namei>
    80005ae0:	84aa                	mv	s1,a0
    80005ae2:	c131                	beqz	a0,80005b26 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	dd0080e7          	jalr	-560(ra) # 800038b4 <ilock>
  if(ip->type != T_DIR){
    80005aec:	04449703          	lh	a4,68(s1)
    80005af0:	4785                	li	a5,1
    80005af2:	04f71063          	bne	a4,a5,80005b32 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	e7e080e7          	jalr	-386(ra) # 80003976 <iunlock>
  iput(p->cwd);
    80005b00:	17893503          	ld	a0,376(s2)
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	f6a080e7          	jalr	-150(ra) # 80003a6e <iput>
  end_op();
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	7fa080e7          	jalr	2042(ra) # 80004306 <end_op>
  p->cwd = ip;
    80005b14:	16993c23          	sd	s1,376(s2)
  return 0;
    80005b18:	4501                	li	a0,0
}
    80005b1a:	60ea                	ld	ra,152(sp)
    80005b1c:	644a                	ld	s0,144(sp)
    80005b1e:	64aa                	ld	s1,136(sp)
    80005b20:	690a                	ld	s2,128(sp)
    80005b22:	610d                	addi	sp,sp,160
    80005b24:	8082                	ret
    end_op();
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	7e0080e7          	jalr	2016(ra) # 80004306 <end_op>
    return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	b7ed                	j	80005b1a <sys_chdir+0x7a>
    iunlockput(ip);
    80005b32:	8526                	mv	a0,s1
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	fe2080e7          	jalr	-30(ra) # 80003b16 <iunlockput>
    end_op();
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	7ca080e7          	jalr	1994(ra) # 80004306 <end_op>
    return -1;
    80005b44:	557d                	li	a0,-1
    80005b46:	bfd1                	j	80005b1a <sys_chdir+0x7a>

0000000080005b48 <sys_exec>:

uint64
sys_exec(void)
{
    80005b48:	7145                	addi	sp,sp,-464
    80005b4a:	e786                	sd	ra,456(sp)
    80005b4c:	e3a2                	sd	s0,448(sp)
    80005b4e:	ff26                	sd	s1,440(sp)
    80005b50:	fb4a                	sd	s2,432(sp)
    80005b52:	f74e                	sd	s3,424(sp)
    80005b54:	f352                	sd	s4,416(sp)
    80005b56:	ef56                	sd	s5,408(sp)
    80005b58:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b5a:	08000613          	li	a2,128
    80005b5e:	f4040593          	addi	a1,s0,-192
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	0b4080e7          	jalr	180(ra) # 80002c18 <argstr>
    return -1;
    80005b6c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b6e:	0c054a63          	bltz	a0,80005c42 <sys_exec+0xfa>
    80005b72:	e3840593          	addi	a1,s0,-456
    80005b76:	4505                	li	a0,1
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	07e080e7          	jalr	126(ra) # 80002bf6 <argaddr>
    80005b80:	0c054163          	bltz	a0,80005c42 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b84:	10000613          	li	a2,256
    80005b88:	4581                	li	a1,0
    80005b8a:	e4040513          	addi	a0,s0,-448
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	152080e7          	jalr	338(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b96:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b9a:	89a6                	mv	s3,s1
    80005b9c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b9e:	02000a13          	li	s4,32
    80005ba2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ba6:	00391513          	slli	a0,s2,0x3
    80005baa:	e3040593          	addi	a1,s0,-464
    80005bae:	e3843783          	ld	a5,-456(s0)
    80005bb2:	953e                	add	a0,a0,a5
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	f86080e7          	jalr	-122(ra) # 80002b3a <fetchaddr>
    80005bbc:	02054a63          	bltz	a0,80005bf0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bc0:	e3043783          	ld	a5,-464(s0)
    80005bc4:	c3b9                	beqz	a5,80005c0a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bc6:	ffffb097          	auipc	ra,0xffffb
    80005bca:	f2e080e7          	jalr	-210(ra) # 80000af4 <kalloc>
    80005bce:	85aa                	mv	a1,a0
    80005bd0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bd4:	cd11                	beqz	a0,80005bf0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bd6:	6605                	lui	a2,0x1
    80005bd8:	e3043503          	ld	a0,-464(s0)
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	fb0080e7          	jalr	-80(ra) # 80002b8c <fetchstr>
    80005be4:	00054663          	bltz	a0,80005bf0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005be8:	0905                	addi	s2,s2,1
    80005bea:	09a1                	addi	s3,s3,8
    80005bec:	fb491be3          	bne	s2,s4,80005ba2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf0:	10048913          	addi	s2,s1,256
    80005bf4:	6088                	ld	a0,0(s1)
    80005bf6:	c529                	beqz	a0,80005c40 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bf8:	ffffb097          	auipc	ra,0xffffb
    80005bfc:	e00080e7          	jalr	-512(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c00:	04a1                	addi	s1,s1,8
    80005c02:	ff2499e3          	bne	s1,s2,80005bf4 <sys_exec+0xac>
  return -1;
    80005c06:	597d                	li	s2,-1
    80005c08:	a82d                	j	80005c42 <sys_exec+0xfa>
      argv[i] = 0;
    80005c0a:	0a8e                	slli	s5,s5,0x3
    80005c0c:	fc040793          	addi	a5,s0,-64
    80005c10:	9abe                	add	s5,s5,a5
    80005c12:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c16:	e4040593          	addi	a1,s0,-448
    80005c1a:	f4040513          	addi	a0,s0,-192
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	194080e7          	jalr	404(ra) # 80004db2 <exec>
    80005c26:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c28:	10048993          	addi	s3,s1,256
    80005c2c:	6088                	ld	a0,0(s1)
    80005c2e:	c911                	beqz	a0,80005c42 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	dc8080e7          	jalr	-568(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c38:	04a1                	addi	s1,s1,8
    80005c3a:	ff3499e3          	bne	s1,s3,80005c2c <sys_exec+0xe4>
    80005c3e:	a011                	j	80005c42 <sys_exec+0xfa>
  return -1;
    80005c40:	597d                	li	s2,-1
}
    80005c42:	854a                	mv	a0,s2
    80005c44:	60be                	ld	ra,456(sp)
    80005c46:	641e                	ld	s0,448(sp)
    80005c48:	74fa                	ld	s1,440(sp)
    80005c4a:	795a                	ld	s2,432(sp)
    80005c4c:	79ba                	ld	s3,424(sp)
    80005c4e:	7a1a                	ld	s4,416(sp)
    80005c50:	6afa                	ld	s5,408(sp)
    80005c52:	6179                	addi	sp,sp,464
    80005c54:	8082                	ret

0000000080005c56 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c56:	7139                	addi	sp,sp,-64
    80005c58:	fc06                	sd	ra,56(sp)
    80005c5a:	f822                	sd	s0,48(sp)
    80005c5c:	f426                	sd	s1,40(sp)
    80005c5e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c60:	ffffc097          	auipc	ra,0xffffc
    80005c64:	d50080e7          	jalr	-688(ra) # 800019b0 <myproc>
    80005c68:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c6a:	fd840593          	addi	a1,s0,-40
    80005c6e:	4501                	li	a0,0
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	f86080e7          	jalr	-122(ra) # 80002bf6 <argaddr>
    return -1;
    80005c78:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c7a:	0e054063          	bltz	a0,80005d5a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c7e:	fc840593          	addi	a1,s0,-56
    80005c82:	fd040513          	addi	a0,s0,-48
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	dfc080e7          	jalr	-516(ra) # 80004a82 <pipealloc>
    return -1;
    80005c8e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c90:	0c054563          	bltz	a0,80005d5a <sys_pipe+0x104>
  fd0 = -1;
    80005c94:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c98:	fd043503          	ld	a0,-48(s0)
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	508080e7          	jalr	1288(ra) # 800051a4 <fdalloc>
    80005ca4:	fca42223          	sw	a0,-60(s0)
    80005ca8:	08054c63          	bltz	a0,80005d40 <sys_pipe+0xea>
    80005cac:	fc843503          	ld	a0,-56(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	4f4080e7          	jalr	1268(ra) # 800051a4 <fdalloc>
    80005cb8:	fca42023          	sw	a0,-64(s0)
    80005cbc:	06054863          	bltz	a0,80005d2c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc0:	4691                	li	a3,4
    80005cc2:	fc440613          	addi	a2,s0,-60
    80005cc6:	fd843583          	ld	a1,-40(s0)
    80005cca:	7ca8                	ld	a0,120(s1)
    80005ccc:	ffffc097          	auipc	ra,0xffffc
    80005cd0:	9a6080e7          	jalr	-1626(ra) # 80001672 <copyout>
    80005cd4:	02054063          	bltz	a0,80005cf4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cd8:	4691                	li	a3,4
    80005cda:	fc040613          	addi	a2,s0,-64
    80005cde:	fd843583          	ld	a1,-40(s0)
    80005ce2:	0591                	addi	a1,a1,4
    80005ce4:	7ca8                	ld	a0,120(s1)
    80005ce6:	ffffc097          	auipc	ra,0xffffc
    80005cea:	98c080e7          	jalr	-1652(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cf0:	06055563          	bgez	a0,80005d5a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cf4:	fc442783          	lw	a5,-60(s0)
    80005cf8:	07f9                	addi	a5,a5,30
    80005cfa:	078e                	slli	a5,a5,0x3
    80005cfc:	97a6                	add	a5,a5,s1
    80005cfe:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d02:	fc042503          	lw	a0,-64(s0)
    80005d06:	0579                	addi	a0,a0,30
    80005d08:	050e                	slli	a0,a0,0x3
    80005d0a:	9526                	add	a0,a0,s1
    80005d0c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d10:	fd043503          	ld	a0,-48(s0)
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	a3e080e7          	jalr	-1474(ra) # 80004752 <fileclose>
    fileclose(wf);
    80005d1c:	fc843503          	ld	a0,-56(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	a32080e7          	jalr	-1486(ra) # 80004752 <fileclose>
    return -1;
    80005d28:	57fd                	li	a5,-1
    80005d2a:	a805                	j	80005d5a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d2c:	fc442783          	lw	a5,-60(s0)
    80005d30:	0007c863          	bltz	a5,80005d40 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d34:	01e78513          	addi	a0,a5,30
    80005d38:	050e                	slli	a0,a0,0x3
    80005d3a:	9526                	add	a0,a0,s1
    80005d3c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d40:	fd043503          	ld	a0,-48(s0)
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	a0e080e7          	jalr	-1522(ra) # 80004752 <fileclose>
    fileclose(wf);
    80005d4c:	fc843503          	ld	a0,-56(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	a02080e7          	jalr	-1534(ra) # 80004752 <fileclose>
    return -1;
    80005d58:	57fd                	li	a5,-1
}
    80005d5a:	853e                	mv	a0,a5
    80005d5c:	70e2                	ld	ra,56(sp)
    80005d5e:	7442                	ld	s0,48(sp)
    80005d60:	74a2                	ld	s1,40(sp)
    80005d62:	6121                	addi	sp,sp,64
    80005d64:	8082                	ret
	...

0000000080005d70 <kernelvec>:
    80005d70:	7111                	addi	sp,sp,-256
    80005d72:	e006                	sd	ra,0(sp)
    80005d74:	e40a                	sd	sp,8(sp)
    80005d76:	e80e                	sd	gp,16(sp)
    80005d78:	ec12                	sd	tp,24(sp)
    80005d7a:	f016                	sd	t0,32(sp)
    80005d7c:	f41a                	sd	t1,40(sp)
    80005d7e:	f81e                	sd	t2,48(sp)
    80005d80:	fc22                	sd	s0,56(sp)
    80005d82:	e0a6                	sd	s1,64(sp)
    80005d84:	e4aa                	sd	a0,72(sp)
    80005d86:	e8ae                	sd	a1,80(sp)
    80005d88:	ecb2                	sd	a2,88(sp)
    80005d8a:	f0b6                	sd	a3,96(sp)
    80005d8c:	f4ba                	sd	a4,104(sp)
    80005d8e:	f8be                	sd	a5,112(sp)
    80005d90:	fcc2                	sd	a6,120(sp)
    80005d92:	e146                	sd	a7,128(sp)
    80005d94:	e54a                	sd	s2,136(sp)
    80005d96:	e94e                	sd	s3,144(sp)
    80005d98:	ed52                	sd	s4,152(sp)
    80005d9a:	f156                	sd	s5,160(sp)
    80005d9c:	f55a                	sd	s6,168(sp)
    80005d9e:	f95e                	sd	s7,176(sp)
    80005da0:	fd62                	sd	s8,184(sp)
    80005da2:	e1e6                	sd	s9,192(sp)
    80005da4:	e5ea                	sd	s10,200(sp)
    80005da6:	e9ee                	sd	s11,208(sp)
    80005da8:	edf2                	sd	t3,216(sp)
    80005daa:	f1f6                	sd	t4,224(sp)
    80005dac:	f5fa                	sd	t5,232(sp)
    80005dae:	f9fe                	sd	t6,240(sp)
    80005db0:	c57fc0ef          	jal	ra,80002a06 <kerneltrap>
    80005db4:	6082                	ld	ra,0(sp)
    80005db6:	6122                	ld	sp,8(sp)
    80005db8:	61c2                	ld	gp,16(sp)
    80005dba:	7282                	ld	t0,32(sp)
    80005dbc:	7322                	ld	t1,40(sp)
    80005dbe:	73c2                	ld	t2,48(sp)
    80005dc0:	7462                	ld	s0,56(sp)
    80005dc2:	6486                	ld	s1,64(sp)
    80005dc4:	6526                	ld	a0,72(sp)
    80005dc6:	65c6                	ld	a1,80(sp)
    80005dc8:	6666                	ld	a2,88(sp)
    80005dca:	7686                	ld	a3,96(sp)
    80005dcc:	7726                	ld	a4,104(sp)
    80005dce:	77c6                	ld	a5,112(sp)
    80005dd0:	7866                	ld	a6,120(sp)
    80005dd2:	688a                	ld	a7,128(sp)
    80005dd4:	692a                	ld	s2,136(sp)
    80005dd6:	69ca                	ld	s3,144(sp)
    80005dd8:	6a6a                	ld	s4,152(sp)
    80005dda:	7a8a                	ld	s5,160(sp)
    80005ddc:	7b2a                	ld	s6,168(sp)
    80005dde:	7bca                	ld	s7,176(sp)
    80005de0:	7c6a                	ld	s8,184(sp)
    80005de2:	6c8e                	ld	s9,192(sp)
    80005de4:	6d2e                	ld	s10,200(sp)
    80005de6:	6dce                	ld	s11,208(sp)
    80005de8:	6e6e                	ld	t3,216(sp)
    80005dea:	7e8e                	ld	t4,224(sp)
    80005dec:	7f2e                	ld	t5,232(sp)
    80005dee:	7fce                	ld	t6,240(sp)
    80005df0:	6111                	addi	sp,sp,256
    80005df2:	10200073          	sret
    80005df6:	00000013          	nop
    80005dfa:	00000013          	nop
    80005dfe:	0001                	nop

0000000080005e00 <timervec>:
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	e10c                	sd	a1,0(a0)
    80005e06:	e510                	sd	a2,8(a0)
    80005e08:	e914                	sd	a3,16(a0)
    80005e0a:	6d0c                	ld	a1,24(a0)
    80005e0c:	7110                	ld	a2,32(a0)
    80005e0e:	6194                	ld	a3,0(a1)
    80005e10:	96b2                	add	a3,a3,a2
    80005e12:	e194                	sd	a3,0(a1)
    80005e14:	4589                	li	a1,2
    80005e16:	14459073          	csrw	sip,a1
    80005e1a:	6914                	ld	a3,16(a0)
    80005e1c:	6510                	ld	a2,8(a0)
    80005e1e:	610c                	ld	a1,0(a0)
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	30200073          	mret
	...

0000000080005e2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e2a:	1141                	addi	sp,sp,-16
    80005e2c:	e422                	sd	s0,8(sp)
    80005e2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e30:	0c0007b7          	lui	a5,0xc000
    80005e34:	4705                	li	a4,1
    80005e36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e38:	c3d8                	sw	a4,4(a5)
}
    80005e3a:	6422                	ld	s0,8(sp)
    80005e3c:	0141                	addi	sp,sp,16
    80005e3e:	8082                	ret

0000000080005e40 <plicinithart>:

void
plicinithart(void)
{
    80005e40:	1141                	addi	sp,sp,-16
    80005e42:	e406                	sd	ra,8(sp)
    80005e44:	e022                	sd	s0,0(sp)
    80005e46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	b3c080e7          	jalr	-1220(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e50:	0085171b          	slliw	a4,a0,0x8
    80005e54:	0c0027b7          	lui	a5,0xc002
    80005e58:	97ba                	add	a5,a5,a4
    80005e5a:	40200713          	li	a4,1026
    80005e5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e62:	00d5151b          	slliw	a0,a0,0xd
    80005e66:	0c2017b7          	lui	a5,0xc201
    80005e6a:	953e                	add	a0,a0,a5
    80005e6c:	00052023          	sw	zero,0(a0)
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret

0000000080005e78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e78:	1141                	addi	sp,sp,-16
    80005e7a:	e406                	sd	ra,8(sp)
    80005e7c:	e022                	sd	s0,0(sp)
    80005e7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e80:	ffffc097          	auipc	ra,0xffffc
    80005e84:	b04080e7          	jalr	-1276(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e88:	00d5179b          	slliw	a5,a0,0xd
    80005e8c:	0c201537          	lui	a0,0xc201
    80005e90:	953e                	add	a0,a0,a5
  return irq;
}
    80005e92:	4148                	lw	a0,4(a0)
    80005e94:	60a2                	ld	ra,8(sp)
    80005e96:	6402                	ld	s0,0(sp)
    80005e98:	0141                	addi	sp,sp,16
    80005e9a:	8082                	ret

0000000080005e9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e9c:	1101                	addi	sp,sp,-32
    80005e9e:	ec06                	sd	ra,24(sp)
    80005ea0:	e822                	sd	s0,16(sp)
    80005ea2:	e426                	sd	s1,8(sp)
    80005ea4:	1000                	addi	s0,sp,32
    80005ea6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	adc080e7          	jalr	-1316(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005eb0:	00d5151b          	slliw	a0,a0,0xd
    80005eb4:	0c2017b7          	lui	a5,0xc201
    80005eb8:	97aa                	add	a5,a5,a0
    80005eba:	c3c4                	sw	s1,4(a5)
}
    80005ebc:	60e2                	ld	ra,24(sp)
    80005ebe:	6442                	ld	s0,16(sp)
    80005ec0:	64a2                	ld	s1,8(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret

0000000080005ec6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ec6:	1141                	addi	sp,sp,-16
    80005ec8:	e406                	sd	ra,8(sp)
    80005eca:	e022                	sd	s0,0(sp)
    80005ecc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ece:	479d                	li	a5,7
    80005ed0:	06a7c963          	blt	a5,a0,80005f42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ed4:	0001d797          	auipc	a5,0x1d
    80005ed8:	12c78793          	addi	a5,a5,300 # 80023000 <disk>
    80005edc:	00a78733          	add	a4,a5,a0
    80005ee0:	6789                	lui	a5,0x2
    80005ee2:	97ba                	add	a5,a5,a4
    80005ee4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ee8:	e7ad                	bnez	a5,80005f52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eea:	00451793          	slli	a5,a0,0x4
    80005eee:	0001f717          	auipc	a4,0x1f
    80005ef2:	11270713          	addi	a4,a4,274 # 80025000 <disk+0x2000>
    80005ef6:	6314                	ld	a3,0(a4)
    80005ef8:	96be                	add	a3,a3,a5
    80005efa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005efe:	6314                	ld	a3,0(a4)
    80005f00:	96be                	add	a3,a3,a5
    80005f02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f06:	6314                	ld	a3,0(a4)
    80005f08:	96be                	add	a3,a3,a5
    80005f0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f0e:	6318                	ld	a4,0(a4)
    80005f10:	97ba                	add	a5,a5,a4
    80005f12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f16:	0001d797          	auipc	a5,0x1d
    80005f1a:	0ea78793          	addi	a5,a5,234 # 80023000 <disk>
    80005f1e:	97aa                	add	a5,a5,a0
    80005f20:	6509                	lui	a0,0x2
    80005f22:	953e                	add	a0,a0,a5
    80005f24:	4785                	li	a5,1
    80005f26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f2a:	0001f517          	auipc	a0,0x1f
    80005f2e:	0ee50513          	addi	a0,a0,238 # 80025018 <disk+0x2018>
    80005f32:	ffffc097          	auipc	ra,0xffffc
    80005f36:	312080e7          	jalr	786(ra) # 80002244 <wakeup>
}
    80005f3a:	60a2                	ld	ra,8(sp)
    80005f3c:	6402                	ld	s0,0(sp)
    80005f3e:	0141                	addi	sp,sp,16
    80005f40:	8082                	ret
    panic("free_desc 1");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	90e50513          	addi	a0,a0,-1778 # 80008850 <syscalls+0x328>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	90e50513          	addi	a0,a0,-1778 # 80008860 <syscalls+0x338>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>

0000000080005f62 <virtio_disk_init>:
{
    80005f62:	1101                	addi	sp,sp,-32
    80005f64:	ec06                	sd	ra,24(sp)
    80005f66:	e822                	sd	s0,16(sp)
    80005f68:	e426                	sd	s1,8(sp)
    80005f6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f6c:	00003597          	auipc	a1,0x3
    80005f70:	90458593          	addi	a1,a1,-1788 # 80008870 <syscalls+0x348>
    80005f74:	0001f517          	auipc	a0,0x1f
    80005f78:	1b450513          	addi	a0,a0,436 # 80025128 <disk+0x2128>
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	bd8080e7          	jalr	-1064(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f84:	100017b7          	lui	a5,0x10001
    80005f88:	4398                	lw	a4,0(a5)
    80005f8a:	2701                	sext.w	a4,a4
    80005f8c:	747277b7          	lui	a5,0x74727
    80005f90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f94:	0ef71163          	bne	a4,a5,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f98:	100017b7          	lui	a5,0x10001
    80005f9c:	43dc                	lw	a5,4(a5)
    80005f9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa0:	4705                	li	a4,1
    80005fa2:	0ce79a63          	bne	a5,a4,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fa6:	100017b7          	lui	a5,0x10001
    80005faa:	479c                	lw	a5,8(a5)
    80005fac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fae:	4709                	li	a4,2
    80005fb0:	0ce79363          	bne	a5,a4,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fb4:	100017b7          	lui	a5,0x10001
    80005fb8:	47d8                	lw	a4,12(a5)
    80005fba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fbc:	554d47b7          	lui	a5,0x554d4
    80005fc0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fc4:	0af71963          	bne	a4,a5,80006076 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc8:	100017b7          	lui	a5,0x10001
    80005fcc:	4705                	li	a4,1
    80005fce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd0:	470d                	li	a4,3
    80005fd2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fd4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fd6:	c7ffe737          	lui	a4,0xc7ffe
    80005fda:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fde:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe0:	2701                	sext.w	a4,a4
    80005fe2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe4:	472d                	li	a4,11
    80005fe6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	473d                	li	a4,15
    80005fea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fec:	6705                	lui	a4,0x1
    80005fee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ff4:	5bdc                	lw	a5,52(a5)
    80005ff6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ff8:	c7d9                	beqz	a5,80006086 <virtio_disk_init+0x124>
  if(max < NUM)
    80005ffa:	471d                	li	a4,7
    80005ffc:	08f77d63          	bgeu	a4,a5,80006096 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006000:	100014b7          	lui	s1,0x10001
    80006004:	47a1                	li	a5,8
    80006006:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006008:	6609                	lui	a2,0x2
    8000600a:	4581                	li	a1,0
    8000600c:	0001d517          	auipc	a0,0x1d
    80006010:	ff450513          	addi	a0,a0,-12 # 80023000 <disk>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	ccc080e7          	jalr	-820(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000601c:	0001d717          	auipc	a4,0x1d
    80006020:	fe470713          	addi	a4,a4,-28 # 80023000 <disk>
    80006024:	00c75793          	srli	a5,a4,0xc
    80006028:	2781                	sext.w	a5,a5
    8000602a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000602c:	0001f797          	auipc	a5,0x1f
    80006030:	fd478793          	addi	a5,a5,-44 # 80025000 <disk+0x2000>
    80006034:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006036:	0001d717          	auipc	a4,0x1d
    8000603a:	04a70713          	addi	a4,a4,74 # 80023080 <disk+0x80>
    8000603e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006040:	0001e717          	auipc	a4,0x1e
    80006044:	fc070713          	addi	a4,a4,-64 # 80024000 <disk+0x1000>
    80006048:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000604a:	4705                	li	a4,1
    8000604c:	00e78c23          	sb	a4,24(a5)
    80006050:	00e78ca3          	sb	a4,25(a5)
    80006054:	00e78d23          	sb	a4,26(a5)
    80006058:	00e78da3          	sb	a4,27(a5)
    8000605c:	00e78e23          	sb	a4,28(a5)
    80006060:	00e78ea3          	sb	a4,29(a5)
    80006064:	00e78f23          	sb	a4,30(a5)
    80006068:	00e78fa3          	sb	a4,31(a5)
}
    8000606c:	60e2                	ld	ra,24(sp)
    8000606e:	6442                	ld	s0,16(sp)
    80006070:	64a2                	ld	s1,8(sp)
    80006072:	6105                	addi	sp,sp,32
    80006074:	8082                	ret
    panic("could not find virtio disk");
    80006076:	00003517          	auipc	a0,0x3
    8000607a:	80a50513          	addi	a0,a0,-2038 # 80008880 <syscalls+0x358>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006086:	00003517          	auipc	a0,0x3
    8000608a:	81a50513          	addi	a0,a0,-2022 # 800088a0 <syscalls+0x378>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006096:	00003517          	auipc	a0,0x3
    8000609a:	82a50513          	addi	a0,a0,-2006 # 800088c0 <syscalls+0x398>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>

00000000800060a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060a6:	7159                	addi	sp,sp,-112
    800060a8:	f486                	sd	ra,104(sp)
    800060aa:	f0a2                	sd	s0,96(sp)
    800060ac:	eca6                	sd	s1,88(sp)
    800060ae:	e8ca                	sd	s2,80(sp)
    800060b0:	e4ce                	sd	s3,72(sp)
    800060b2:	e0d2                	sd	s4,64(sp)
    800060b4:	fc56                	sd	s5,56(sp)
    800060b6:	f85a                	sd	s6,48(sp)
    800060b8:	f45e                	sd	s7,40(sp)
    800060ba:	f062                	sd	s8,32(sp)
    800060bc:	ec66                	sd	s9,24(sp)
    800060be:	e86a                	sd	s10,16(sp)
    800060c0:	1880                	addi	s0,sp,112
    800060c2:	892a                	mv	s2,a0
    800060c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060c6:	00c52c83          	lw	s9,12(a0)
    800060ca:	001c9c9b          	slliw	s9,s9,0x1
    800060ce:	1c82                	slli	s9,s9,0x20
    800060d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060d4:	0001f517          	auipc	a0,0x1f
    800060d8:	05450513          	addi	a0,a0,84 # 80025128 <disk+0x2128>
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	b08080e7          	jalr	-1272(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060e8:	0001db97          	auipc	s7,0x1d
    800060ec:	f18b8b93          	addi	s7,s7,-232 # 80023000 <disk>
    800060f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060f4:	8a4e                	mv	s4,s3
    800060f6:	a051                	j	8000617a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060f8:	00fb86b3          	add	a3,s7,a5
    800060fc:	96da                	add	a3,a3,s6
    800060fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006102:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006104:	0207c563          	bltz	a5,8000612e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006108:	2485                	addiw	s1,s1,1
    8000610a:	0711                	addi	a4,a4,4
    8000610c:	25548063          	beq	s1,s5,8000634c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006110:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006112:	0001f697          	auipc	a3,0x1f
    80006116:	f0668693          	addi	a3,a3,-250 # 80025018 <disk+0x2018>
    8000611a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000611c:	0006c583          	lbu	a1,0(a3)
    80006120:	fde1                	bnez	a1,800060f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006122:	2785                	addiw	a5,a5,1
    80006124:	0685                	addi	a3,a3,1
    80006126:	ff879be3          	bne	a5,s8,8000611c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000612a:	57fd                	li	a5,-1
    8000612c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000612e:	02905a63          	blez	s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006132:	f9042503          	lw	a0,-112(s0)
    80006136:	00000097          	auipc	ra,0x0
    8000613a:	d90080e7          	jalr	-624(ra) # 80005ec6 <free_desc>
      for(int j = 0; j < i; j++)
    8000613e:	4785                	li	a5,1
    80006140:	0297d163          	bge	a5,s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006144:	f9442503          	lw	a0,-108(s0)
    80006148:	00000097          	auipc	ra,0x0
    8000614c:	d7e080e7          	jalr	-642(ra) # 80005ec6 <free_desc>
      for(int j = 0; j < i; j++)
    80006150:	4789                	li	a5,2
    80006152:	0097d863          	bge	a5,s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006156:	f9842503          	lw	a0,-104(s0)
    8000615a:	00000097          	auipc	ra,0x0
    8000615e:	d6c080e7          	jalr	-660(ra) # 80005ec6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006162:	0001f597          	auipc	a1,0x1f
    80006166:	fc658593          	addi	a1,a1,-58 # 80025128 <disk+0x2128>
    8000616a:	0001f517          	auipc	a0,0x1f
    8000616e:	eae50513          	addi	a0,a0,-338 # 80025018 <disk+0x2018>
    80006172:	ffffc097          	auipc	ra,0xffffc
    80006176:	f3c080e7          	jalr	-196(ra) # 800020ae <sleep>
  for(int i = 0; i < 3; i++){
    8000617a:	f9040713          	addi	a4,s0,-112
    8000617e:	84ce                	mv	s1,s3
    80006180:	bf41                	j	80006110 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006182:	20058713          	addi	a4,a1,512
    80006186:	00471693          	slli	a3,a4,0x4
    8000618a:	0001d717          	auipc	a4,0x1d
    8000618e:	e7670713          	addi	a4,a4,-394 # 80023000 <disk>
    80006192:	9736                	add	a4,a4,a3
    80006194:	4685                	li	a3,1
    80006196:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000619a:	20058713          	addi	a4,a1,512
    8000619e:	00471693          	slli	a3,a4,0x4
    800061a2:	0001d717          	auipc	a4,0x1d
    800061a6:	e5e70713          	addi	a4,a4,-418 # 80023000 <disk>
    800061aa:	9736                	add	a4,a4,a3
    800061ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061b4:	7679                	lui	a2,0xffffe
    800061b6:	963e                	add	a2,a2,a5
    800061b8:	0001f697          	auipc	a3,0x1f
    800061bc:	e4868693          	addi	a3,a3,-440 # 80025000 <disk+0x2000>
    800061c0:	6298                	ld	a4,0(a3)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061c6:	6298                	ld	a4,0(a3)
    800061c8:	9732                	add	a4,a4,a2
    800061ca:	4541                	li	a0,16
    800061cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ce:	6298                	ld	a4,0(a3)
    800061d0:	9732                	add	a4,a4,a2
    800061d2:	4505                	li	a0,1
    800061d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061d8:	f9442703          	lw	a4,-108(s0)
    800061dc:	6288                	ld	a0,0(a3)
    800061de:	962a                	add	a2,a2,a0
    800061e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061e4:	0712                	slli	a4,a4,0x4
    800061e6:	6290                	ld	a2,0(a3)
    800061e8:	963a                	add	a2,a2,a4
    800061ea:	05890513          	addi	a0,s2,88
    800061ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061f0:	6294                	ld	a3,0(a3)
    800061f2:	96ba                	add	a3,a3,a4
    800061f4:	40000613          	li	a2,1024
    800061f8:	c690                	sw	a2,8(a3)
  if(write)
    800061fa:	140d0063          	beqz	s10,8000633a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061fe:	0001f697          	auipc	a3,0x1f
    80006202:	e026b683          	ld	a3,-510(a3) # 80025000 <disk+0x2000>
    80006206:	96ba                	add	a3,a3,a4
    80006208:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620c:	0001d817          	auipc	a6,0x1d
    80006210:	df480813          	addi	a6,a6,-524 # 80023000 <disk>
    80006214:	0001f517          	auipc	a0,0x1f
    80006218:	dec50513          	addi	a0,a0,-532 # 80025000 <disk+0x2000>
    8000621c:	6114                	ld	a3,0(a0)
    8000621e:	96ba                	add	a3,a3,a4
    80006220:	00c6d603          	lhu	a2,12(a3)
    80006224:	00166613          	ori	a2,a2,1
    80006228:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000622c:	f9842683          	lw	a3,-104(s0)
    80006230:	6110                	ld	a2,0(a0)
    80006232:	9732                	add	a4,a4,a2
    80006234:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006238:	20058613          	addi	a2,a1,512
    8000623c:	0612                	slli	a2,a2,0x4
    8000623e:	9642                	add	a2,a2,a6
    80006240:	577d                	li	a4,-1
    80006242:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006246:	00469713          	slli	a4,a3,0x4
    8000624a:	6114                	ld	a3,0(a0)
    8000624c:	96ba                	add	a3,a3,a4
    8000624e:	03078793          	addi	a5,a5,48
    80006252:	97c2                	add	a5,a5,a6
    80006254:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006256:	611c                	ld	a5,0(a0)
    80006258:	97ba                	add	a5,a5,a4
    8000625a:	4685                	li	a3,1
    8000625c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000625e:	611c                	ld	a5,0(a0)
    80006260:	97ba                	add	a5,a5,a4
    80006262:	4809                	li	a6,2
    80006264:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006268:	611c                	ld	a5,0(a0)
    8000626a:	973e                	add	a4,a4,a5
    8000626c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006270:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006274:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006278:	6518                	ld	a4,8(a0)
    8000627a:	00275783          	lhu	a5,2(a4)
    8000627e:	8b9d                	andi	a5,a5,7
    80006280:	0786                	slli	a5,a5,0x1
    80006282:	97ba                	add	a5,a5,a4
    80006284:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006288:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000628c:	6518                	ld	a4,8(a0)
    8000628e:	00275783          	lhu	a5,2(a4)
    80006292:	2785                	addiw	a5,a5,1
    80006294:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006298:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000629c:	100017b7          	lui	a5,0x10001
    800062a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a4:	00492703          	lw	a4,4(s2)
    800062a8:	4785                	li	a5,1
    800062aa:	02f71163          	bne	a4,a5,800062cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ae:	0001f997          	auipc	s3,0x1f
    800062b2:	e7a98993          	addi	s3,s3,-390 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b8:	85ce                	mv	a1,s3
    800062ba:	854a                	mv	a0,s2
    800062bc:	ffffc097          	auipc	ra,0xffffc
    800062c0:	df2080e7          	jalr	-526(ra) # 800020ae <sleep>
  while(b->disk == 1) {
    800062c4:	00492783          	lw	a5,4(s2)
    800062c8:	fe9788e3          	beq	a5,s1,800062b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062cc:	f9042903          	lw	s2,-112(s0)
    800062d0:	20090793          	addi	a5,s2,512
    800062d4:	00479713          	slli	a4,a5,0x4
    800062d8:	0001d797          	auipc	a5,0x1d
    800062dc:	d2878793          	addi	a5,a5,-728 # 80023000 <disk>
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062e6:	0001f997          	auipc	s3,0x1f
    800062ea:	d1a98993          	addi	s3,s3,-742 # 80025000 <disk+0x2000>
    800062ee:	00491713          	slli	a4,s2,0x4
    800062f2:	0009b783          	ld	a5,0(s3)
    800062f6:	97ba                	add	a5,a5,a4
    800062f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062fc:	854a                	mv	a0,s2
    800062fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006302:	00000097          	auipc	ra,0x0
    80006306:	bc4080e7          	jalr	-1084(ra) # 80005ec6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000630a:	8885                	andi	s1,s1,1
    8000630c:	f0ed                	bnez	s1,800062ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000630e:	0001f517          	auipc	a0,0x1f
    80006312:	e1a50513          	addi	a0,a0,-486 # 80025128 <disk+0x2128>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
}
    8000631e:	70a6                	ld	ra,104(sp)
    80006320:	7406                	ld	s0,96(sp)
    80006322:	64e6                	ld	s1,88(sp)
    80006324:	6946                	ld	s2,80(sp)
    80006326:	69a6                	ld	s3,72(sp)
    80006328:	6a06                	ld	s4,64(sp)
    8000632a:	7ae2                	ld	s5,56(sp)
    8000632c:	7b42                	ld	s6,48(sp)
    8000632e:	7ba2                	ld	s7,40(sp)
    80006330:	7c02                	ld	s8,32(sp)
    80006332:	6ce2                	ld	s9,24(sp)
    80006334:	6d42                	ld	s10,16(sp)
    80006336:	6165                	addi	sp,sp,112
    80006338:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000633a:	0001f697          	auipc	a3,0x1f
    8000633e:	cc66b683          	ld	a3,-826(a3) # 80025000 <disk+0x2000>
    80006342:	96ba                	add	a3,a3,a4
    80006344:	4609                	li	a2,2
    80006346:	00c69623          	sh	a2,12(a3)
    8000634a:	b5c9                	j	8000620c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000634c:	f9042583          	lw	a1,-112(s0)
    80006350:	20058793          	addi	a5,a1,512
    80006354:	0792                	slli	a5,a5,0x4
    80006356:	0001d517          	auipc	a0,0x1d
    8000635a:	d5250513          	addi	a0,a0,-686 # 800230a8 <disk+0xa8>
    8000635e:	953e                	add	a0,a0,a5
  if(write)
    80006360:	e20d11e3          	bnez	s10,80006182 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006364:	20058713          	addi	a4,a1,512
    80006368:	00471693          	slli	a3,a4,0x4
    8000636c:	0001d717          	auipc	a4,0x1d
    80006370:	c9470713          	addi	a4,a4,-876 # 80023000 <disk>
    80006374:	9736                	add	a4,a4,a3
    80006376:	0a072423          	sw	zero,168(a4)
    8000637a:	b505                	j	8000619a <virtio_disk_rw+0xf4>

000000008000637c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000637c:	1101                	addi	sp,sp,-32
    8000637e:	ec06                	sd	ra,24(sp)
    80006380:	e822                	sd	s0,16(sp)
    80006382:	e426                	sd	s1,8(sp)
    80006384:	e04a                	sd	s2,0(sp)
    80006386:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006388:	0001f517          	auipc	a0,0x1f
    8000638c:	da050513          	addi	a0,a0,-608 # 80025128 <disk+0x2128>
    80006390:	ffffb097          	auipc	ra,0xffffb
    80006394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006398:	10001737          	lui	a4,0x10001
    8000639c:	533c                	lw	a5,96(a4)
    8000639e:	8b8d                	andi	a5,a5,3
    800063a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063a6:	0001f797          	auipc	a5,0x1f
    800063aa:	c5a78793          	addi	a5,a5,-934 # 80025000 <disk+0x2000>
    800063ae:	6b94                	ld	a3,16(a5)
    800063b0:	0207d703          	lhu	a4,32(a5)
    800063b4:	0026d783          	lhu	a5,2(a3)
    800063b8:	06f70163          	beq	a4,a5,8000641a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063bc:	0001d917          	auipc	s2,0x1d
    800063c0:	c4490913          	addi	s2,s2,-956 # 80023000 <disk>
    800063c4:	0001f497          	auipc	s1,0x1f
    800063c8:	c3c48493          	addi	s1,s1,-964 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063d0:	6898                	ld	a4,16(s1)
    800063d2:	0204d783          	lhu	a5,32(s1)
    800063d6:	8b9d                	andi	a5,a5,7
    800063d8:	078e                	slli	a5,a5,0x3
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063de:	20078713          	addi	a4,a5,512
    800063e2:	0712                	slli	a4,a4,0x4
    800063e4:	974a                	add	a4,a4,s2
    800063e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063ea:	e731                	bnez	a4,80006436 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063ec:	20078793          	addi	a5,a5,512
    800063f0:	0792                	slli	a5,a5,0x4
    800063f2:	97ca                	add	a5,a5,s2
    800063f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063fa:	ffffc097          	auipc	ra,0xffffc
    800063fe:	e4a080e7          	jalr	-438(ra) # 80002244 <wakeup>

    disk.used_idx += 1;
    80006402:	0204d783          	lhu	a5,32(s1)
    80006406:	2785                	addiw	a5,a5,1
    80006408:	17c2                	slli	a5,a5,0x30
    8000640a:	93c1                	srli	a5,a5,0x30
    8000640c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006410:	6898                	ld	a4,16(s1)
    80006412:	00275703          	lhu	a4,2(a4)
    80006416:	faf71be3          	bne	a4,a5,800063cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000641a:	0001f517          	auipc	a0,0x1f
    8000641e:	d0e50513          	addi	a0,a0,-754 # 80025128 <disk+0x2128>
    80006422:	ffffb097          	auipc	ra,0xffffb
    80006426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000642a:	60e2                	ld	ra,24(sp)
    8000642c:	6442                	ld	s0,16(sp)
    8000642e:	64a2                	ld	s1,8(sp)
    80006430:	6902                	ld	s2,0(sp)
    80006432:	6105                	addi	sp,sp,32
    80006434:	8082                	ret
      panic("virtio_disk_intr status");
    80006436:	00002517          	auipc	a0,0x2
    8000643a:	4aa50513          	addi	a0,a0,1194 # 800088e0 <syscalls+0x3b8>
    8000643e:	ffffa097          	auipc	ra,0xffffa
    80006442:	100080e7          	jalr	256(ra) # 8000053e <panic>
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
