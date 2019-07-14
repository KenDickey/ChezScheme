;;; "arm63regs.ss"

;;; This is a documentation file. No executable code lives here.
;;; It is of interest to understand the layout of AArch64 opcodes
;;; at the bit level.  We hope it can be safely ignored.

;;; AArch64/ARMv8 Instruction Set Encoding from chapter C4 of:
;;; _ARM Architecture Reference Manual ARMv8, for ARMv8-A architecture profile_
;;; https://developer.arm.com/docs/ddi0487/latest/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile

;;; Note: Not all opcodes included => not all opcodes encoded here.

;;; Condition Codes [Negative Zero Carry oVerflow = NZCV]
;; #b0000 - Equal       (EQ)  Z=1
;;   0001 - Not Equal   (NE)  Z=0
;;   0010 - Carry Set   (CS) [=Higher or Same     (HS)] C=1
;;   0011 - Carry Clear (CC) [=Unsigned less than (LO)] C=0
;;   0100 - Minus/Negative     (MI)         N=1
;;   0101 - Plus or Zero       (PL)         N=0
;;   0110 - Signed oVerflow    (VS) signed  V=1
;;   0111 - No signed oVerflow (VC) signed  V=0
;;   1000 - Greater Than       (HI)         C=1 && Z=0
;;   1001 - Less or Same/Equal (LS)         C=0 && Z=1
;;   1010 - Greater or Equal   (GE) signed  N=V
;;   1011 - Less Than          (LT) signed  N!=V
;;   1100 - Greater Than       (GT) signed  Z=0 && N!=V
;;   1101 - Less Than or Equal (LE) signed  Z=1 && N!=V
;;   1110 - ALWAYS (default)   (AL)         NZCV ignored
;;   1111 - !!Never==>ALWAYS!! (NV) **NB: Wacky Conditional**

;;; Opcode Bits [28..25]  x => specified elsewhere
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;     100x - Data Processing -- Immediate
;;     101x - Branches, Exception, System
;;     x1x0 - Loads & Stores
;;     x101 - Data Processing -- Register
;;     x111 - Data Processing -- SIMD/Floating Point

;;; Data Processing, Immediate
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;     100
;;        00x -- PC-relative
;;        010 -- Add/Sub Immediate
;;        011 -- Add/Sub Immedite+Tag
;;        100 -- Logical Immediate
;;        101 -- Move Wide Immediate
;;        110 -- Bitfield
;;        111 -- Extract


;;; PC-relative ADdress to Register
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; opImmLo10000----ImmHi------Rdest
;;   0 = ADR   CurrentPC + (Sign-extend ImmHi:ImmLo)
;;   1 = ADRP  CurrentPC + (Sign-extend (ImmHi:ImmLo << 12))
;; ADRP => 4K Page -- independent of Virtual Memory granularity


;;; ADD/SUB Immediate
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; sOS100010s----Imm12---RnnnnRdest
;;  0 = 32 bit
;;  1 = 64 bit
;;   0 = ADD
;;   1 = SUB
;;    0 = Don't set Condition Codes
;;    1 = Set CCs
;;           s = Logical Shift Left (LSL) 0=>0, 1=>12
;; Alias: MOV to/from SP when shift=0, imm12=0, Rd|Rn = #b11111


;;; Move Wide Immediate [MOV*]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 1op100101sh-----imm16------Rdest
;;   00 MOVN -- MOVe-Not -- like MOVZ but invert imm16
;;   10 MOVZ -- MOVe & Zero other bits
;;   11 MOVK -- MOVe & Keep other bits
;;           00 -- imm16 LSL 0
;;           01 -- imm16 LSL 16
;;           10 -- imm16 LSL 32
;;           11 -- imm16 LSL 48


;;; Logical Immediate
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; sop1001000---Imm12----Rsrc-Rdest
;;  0 = 32 bit
;;  1 = 64 bit
;;   00 = AND
;;   01 = ORR  (Inclusive OR)
;;   10 = EOR  (Excusive OR)
;;   11 = ANDS (S => Set CCs) [Alias: TST (immediate) when Rdest is ZR=#b11111]


;;; Bitfield Move Immediate [*BFM]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; sop100110NImmR--ImmS--Rsrc-Rdest
;;  0        0 = 32 bit
;;  1        1 = 64 bit
;;   00 = SBFM Signed (=>sign extend; lower bits to Zero) [Also alias for ASR]
;;   01 =  BFM keep other bits  [Alias: BFInsert; BFClear when Rsrc is ZR=#b1111]]
;;   11 = UBFM Unsigned (upper & lower bits to Zero)
;; BFM can
;;   [A] can copy a span of bits from an offset in Rsrc to bit0 in Rdest.   [SourceOffset]
;;or [B] can copy a span of bits from bit0 of Rsrc into an offset in Rdest. [DestOffset]
;; if ImmS >= ImmR then copy (ImmS-ImmR+1) bits starting at SourceOffset ImmR in Rsrc to bit0 in Rdest. [A]
;; else copy (ImmS+1) bits from bit0 in Rsrc to DestOffset (RegSize-ImmR) in Rdest. [B]
;; [A] => immS = Span+R-1 ; immR = SourceOffset
;; [B] => immS = Span+1   ; immR = RegSize-DestOffset (RegSize is 64 or 32)

;NB: **Little Endian**
;"BFM  W1, WZR, #3, #4" Encodes as:
;	ARM64 GDB/LLDB - 330313E1
; But in memory shows as (bytes reversed!):
;	ARM64 HEX - E1130333
; e.g. objdump -d foo.o -> shows in HEX (byte reversed) order

;; Note other Bitfield ops:
;;	CLZ   - Count Leading Zeros
;;	RBIT  - Reverse all BITs in a register
;;	REV   - REVerse the order of bytes in a register
;;	REV16 - REVerse the byte order in each Halfword
;;	REV32 - REVerse the byte order in each Word
;; All but REV32 can operate on Word [Wn] or Double [Xn] registers, except REV32 (Xn only)


;;; Extract Immediate  [EXTR]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s00100111N0Rmmmm-Imm6-RnnnnRdest
;;  0        0 = 32 bit
;;  1        1 = 64 bit
;; Extract a register from a pair of registers
;;   Rn:Rm
;; Imm6 is least significant bit position to extract from
;; [Alias: ROR when Rn=Rm, then Imm6 is called 'shift']


;;; Conditional Branch Immediate [B.cond]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 01010100-----Imm19---------0Cond
;; Cond is one of the Condition Codes (encoded as above)
;; Immed19 is relative to the address of THIS instruction, in the range ±1MB.

;;; Note on Conditional Branch range
;;   B.cond:    +/-  1 MB
;;   CBZ, CBNZ: +/-  1 MB
;;   TBZ, TBNZ: +/- 32 KB
;;
;; Unconditional Branch [B, BL] is +/- 128MB
;; BR, BLR range is unconstrained


;;; No-Operation [NOP]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 11010101000000110010000000011111
;; ; Takes up space..


;;; System Register Move
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 1101010100L1OOp1CRn-CRm-Op2Rtttt
;;            0 - MSR Move to System   from Register
;;            1 - MRS Move to Register from System
;; E.g.
;; MRS X0, CNTFRQ_EL0 -- Get Timer Frequency [Hz]
;; MRS X0, CNTVCT_EL0 -- Get Timer value


;;; Unconditional Branch (Register) [BR]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 1101011opc-11111000000Rnnnn00000
;;         0000 - BR  Branch to address in Register
;;         0001 - BLR Branch w Link to Reg addr
;;         0010 - RET RETurn through Link Register

;;; Compare and Branch (Immediate)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s011010o-----Imm19---------Rtttt
;;  0 - 32 bit
;;  1 - 64 bit
;;         0 - CBZ  Compare and Branch if Zero
;;         1 - CBNZ Compare and Branch if Non-Zero
;; Range +/- 1 MB


;;; Test and Branch Zero (Immediate)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; x011011oBitPo---Immed14----Rtttt
;;         0 - TBZ   Branch if test bit is Zero
;;         1 - TBNZ  Branch if test bit is Not-Zero
;;          BitPos: 6 bits (x:BitPo) -> Bit # To Test (0..63)
;;  Immed14 -- relative branch
;;; Note: Does NOT set/change Condition Flags
;; Range: +/- 32 KB

;;; Unconditional Branch (Immediate)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; o00101---Immed26----------------
;;  0 - B
;;  1 - BL
;; Range is +/- 128 MB


;;; Unconditional Branch (Register)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 1101011Opc-Op2--Op3---RnnnnOp4--
;;         000011111000000     00000 - BR
;;         000111111000000     00000 - BLR
;;         001011111000000     00000 - RET
;;         0100111110000001111100000 - ERET ExceptionRET
;;         0101111110000001111100000 - DRPS DebugReturn


;;; Load Register (Literal)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; op011v00---Imm19-----------Rdest
;;  00   0 - LDR (literal)           32 bit (unsigned)
;;  00   1 - LDR (literal, SIMD/FP)  32 bit
;;  01   0 - LDR (literal)           64 bit
;;  01   1 - LDR (literal, SIMD/FP)  64 bit
;;  10   0 - LDRSW (literal) Signed Word (sign extend 32 bits)
;;  10   1 - LDR (literal, SIMD/FP) 128 bit

;; Note also: LDRB -- LoaD Regsiter Byte (next)


;;; Load/Store Register
;; ; 3    __   2        _1         0
;; ;10987654321098765432109876543210
;;; sz111vT1op0-Immed9--T2RnnnnRdest
;;        00            01  Immediate, Post-Indexed
;;        00            11  Immediate, PRE-Indexed
;;        00            00  Unscaled immediate offset
;;; sz111v00op1RmmmmXXXS10RnnnnRdest
;;        00            10  Register Offset
;;; sz111v01op--Immed12---RnnnnRdest
;;        01            xx  UnSigned Immediate Offset
;;  00   0  00 - STRB 
;;  00   0  01 - LDRB 
;;  00   0  10 - LDRSB             64 bit
;;  00   0  11 - LDRSB             32 bit
;;  00   1  00 - STR   (SIMD/FP)    8 bit 
;;  00   1  01 - LDR   (SIMD/FP)    8 bit 
;;  00   1  10 - STR   (SIMD/FP)  128 bit 
;;  00   1  11 - LDR   (SIMD/FP)  128 bit
;;  01   0  00 - STRH
;;  01   0  01 - LDRH
;;  01   0  10 - LDRSH             64 bit
;;  01   0  11 - LDRSH             32 bit
;;  01   1  00 - STR   (SIMD/FP)   16 bit 
;;  01   1  01 - LDR   (SIMD/FP)   16 bit 
;;  10   0  00 - STR               32 bit
;;  10   0  01 - LDR               32 bit
;;  10   0  10 - LDRSW  
;;  10   1  00 - STR   (SIMD/FP)   32 bit
;;  10   1  01 - LDR   (SIMD/FP)   32 bit
;;  11   0  00 - STR               64 bit
;;  11   0  01 - LDR               64 bit
;;  11   1  00 - STR   (SIMD/FP)   64 bit
;;  11   1  01 - LDR   (SIMD/FP)   64 bit


;;;  Load/Store Register Pair
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; op101VxxxL-Imm7--Rt2--RnnnnRt1--
;;        001  Post-Indexed
;;        010  Offset
;;        101  PRE-Indexed
;;  00   0   0 - STP               32 bit
;;  00   0   1 - LDP               32 bi
;;  00   1   0 - STP (SIMD/FP)     32 bit
;;  00   1   1 - LTP (SIMD/FP)     32 bit
;;  01   0   1 - LDPSW
;;  01   1   0 - STP (SIMD/FP)     64 bit
;;  01   1   1 - LTP (SIMD/FP)     64 bit
;;  10   0   0 - STP               64 bit
;;  10   0   1 - LTP               64 bit
;;  10   1   0 - STP (SIMD/FP)    128 bit
;;  10   1   1 - LTP (SIMD/FP)    128 bit

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210

;; ; 3         2         1         0
;; ;10987654321098765432109876543210


