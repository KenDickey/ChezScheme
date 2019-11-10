;;; "arm63opcodes.ss"

;;; Copyright 2019 Kenneth A Dickey
;;; 
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the License.
;;; You may obtain a copy of the License at
;;; 
;;; http://www.apache.org/licenses/LICENSE-2.0
;;; 
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions and
;;; limitations under the License.


;;; This is a documentation file. No executable code lives here.
;;; It is of interest to understand the layout of AArch64 opcodes
;;; at the bit level.  We hope it can be safely ignored.

;;; AArch64/ARMv8 Instruction Set Encoding from chapter C4 of:
;;; _ARM Architecture Reference Manual ARMv8, for ARMv8-A architecture profile_
;;; https://developer.arm.com/docs/ddi0487/latest/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile

;;; Note: ARM Limited holds copyright on the design of the opcodes.
;;;       The copyright above is just for the text of this file.


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

;;
;;; INTEGER OPERATIONS

;;; Integer Data Processing, Immediate
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
;;; xLo10000------ImmHi--------Rdest
;;  0 = ADR   CurrentPC + (Sign-extend ImmHi:ImmLo)
;;  1 = ADRP  (CurrentPC + (Sign-extend (ImmHi:ImmLo << 12)) & ~#fff)
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


;;; Logical Shifted Register
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; sop01010shNRmmmm-Imm6-Rsrc-Rdest
;;  0 = 32 bit
;;  1 = 64 bit
;;          00 - LSL
;;          01 - LSR
;;          10 - ASR
;;          11 - ROR
;;   00       0 - AND
;;   00       1 - BIC
;;   01       0 - ORR
;;   01       1 - ORN
;;   10       0 - EOR
;;   10       1 - EON
;;   11       0 - ANDS
;;   11       1 - BICS
;; -Imm6- is shift amount
;;; Move Register is alias of shifted ORR w XZR
;;; sop01010shNRmmmmmImm6-Rsrc-Rdest
;;  10101010000Rmmmmm0000011111Rdest - Move (Register)


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


;;; Conditional Compare
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; sOS11010010imm5-Cond10Rnnnn0NZCV  (Immediate)
;;; sOS11010010RmmmmCond00Rnnnn0NZCV  (Register)
;;  0 - 32 bit
;;  1 - 64 bit
;;   01 - CCMN
;;   11 - CCMP
;; Compare Rn with Rm/Imm5 and set CCs


;;; Conditional Select
;; ; 3         2         1         0
;; ;1098765432109765432109876543210
;;; sO011010100RmmmmCondOpRnnnnRdest
;;  0 - 32 bit
;;  1 - 64 bit
;;   0                  00 - CSEL
;;   0                  01 - CINC/CSINC  ;; Alias CSET  when Rn & Rm are both ZR
;;   1                  00 - CINV/CSINV  ;; Alias CSETM when Rn & Rm are both ZR
;;   1                  01 - CNEG/CSNEG
;; If Cond(ition) in CC holds,
;;   RDest gets Rn else Rm; as-is/incremented/inverted/negated


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
;; MRS X0, CNTVCT_EL0 -- Get Timer value     [count]


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
;;        011  PRE-Indexed
;;  00   0   0 - STP               32 bit
;;  00   0   1 - LDP               32 bit
;;  00   1   0 - STP (SIMD/FP)     32 bit
;;  00   1   1 - LTP (SIMD/FP)     32 bit
;;  01   0   1 - LDPSW
;;  01   1   0 - STP (SIMD/FP)     64 bit
;;  01   1   1 - LTP (SIMD/FP)     64 bit
;;  10   0   0 - STP               64 bit
;;  10   0   1 - LTP               64 bit
;;  10   1   0 - STP (SIMD/FP)    128 bit
;;  10   1   1 - LTP (SIMD/FP)    128 bit


;;; PC Relative Address to Register [ADR/ADRPaged]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 0im10000immed-high---------Rdest	ADR  (+/- 1MB)
;; PC + (signed) immed-hi:im to Rdest ;; NB: relative to THIS instruction
;;; 1im10000immed-high---------Rdest	ADRP (+/- 4GB)
;; (PC + ((signed) immed-hi:im << 12)) & ~#xfff to Rdest [4K Page selection (think BIBOP)]



;;; Integer Data Processing (Register) -- Extend
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; skk01011001RmmmmOptLsfRnnnnRdest (Extended Register)
;;                     Lsf (Left Shift 0..3)
;;                  000 - UXTB 
;;                  001 - UXTH
;;                  010 - UXTW
;;                  011 - UXTX (LSL if Rn is ZR)
;;                  100 - SXTB
;;                  101 - SXTH
;;                  110 - SXTW
;;                  111 - SXTX
;;; skk01011sh0Rmmmm-Imm6-RnnnnRdest (Shifted Register)
;;; skkk11010000Rmmmm00000RnnnnRdest (with Carry)
;;  0 - 32 bit
;;  1 - 64 bit
;;   00         ADD  
;;   01         ADDS 
;;   10         SUB  
;;   11         SUBS 


;;; Invert Carry Flag  CFINV
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 11010101000000000100000000011111


;;; Integer Data Processing (1 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s101101011000000opcodeRnnnnRdest
;;  0 - 32 bit
;;  1 - 64 bit
;;                  000000 - RBIT  Reverse BIT Order
;;                  000001 - REV16 Reverse Bytes in Register HalfWords
;;                  000010 - REV32 Reverse Bytes in Register Words
;;                  000011 - REV   Reverse Bytes in Register [Alias: REV64 when 64 bit]
;;                  000100 - CLZ   Count Leading Zeros
;;                  000101 - CLS   Count Leading Sign Bits


;;;Integer Data Processing (2 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s0011010110RmmmmOpcodeRnnnnRdest
;;  0 - 32 bit
;;  1 - 64 bit
;; Divide returns quotient, rounded toward zero;
;;  remainder is (numerator - (quotient * denominator)), using MSUB
;; No indication of overflow if divide by zero (Rd <- 0)
;;  or if (most-negative-integer / -1) exceeds range (Rd <- most-neg-int)
;;                  000010 - UDIV  UnSigned Divide
;;                  000011 - SDIV  Signed Divide
;; Variable shifts: Rm holds shift amount
;;                  001000 - LSLV
;;                  001001 - LSRV
;;                  001010 - ASRV
;;                  001011 - RORV
;;  0               010000 - CRC32B
;;  0               010001 - CRC32H
;;  0               010010 - CRC32W
;;  0               010100 - CRC32CB
;;  0               010101 - CRC32CH
;;  0               010110 - CRC32CW
;;  1               010011 - CRC32X
;;  1               010111 - CRC32CX


;;;Integer Data Processing (3 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s0011011opcRmmmmORaaaaRnnnnRdest
;;  0       000     0 - MADD   32 bit  Wd = (Wm * Wn) + Wa
;;  0       000     1 - MSUB   32 bit  Wd = (Wm * Wn) - Ws
;;  1       000     0 - MADD   64 bit  Xd = (Xm * Xn) + Xa
;;  1       000     1 - MSUB   64 bit  Xd = (Xm * Xn) - Xs
;;  1       001     0 - SMADDL Xd = (Wm * Wn) + Xa
;;  1       001     1 - SMSUBL Xd = (Wm * Wn) - Xa
;;  1       010     0 - SMULH  Signed Multiply High (Xm * Xn) -> result bits 127:64 -> Xd
;;  1       101     0 - UMADDL
;;  1       101     1 - UMSUBL
;;  1       110     0 - UMULH  UnSigned Multiply High

;;
;;; FLOATING POINT et al.. OPERATIONS


;;; Floating-Point <--> Fixed-Point
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s0011110pt0mdOpcScale-RnnnnRdest
;;  0 - 32 bit^
;;  1 - 64 bit
;;          00 00010 - SCVTF 
;;          00 00011 - UCVTF 
;;          00 11000 - FCVTZS
;;          00 11001 - FCVTZU
;;          01 00010 - SCVTF
;;          01 00011 - UCVTF
;;          01 11000 - FCVTZS
;;          01 11001 - FCVTZU
;;          11 00010 - SCVTF
;;          11 00011 - UCVTF
;;          11 11000 - FCVTZS
;;          11 11001 - FCVTZU


;;; Floating-Point <--> Integer
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; s0011110pt1mdOpc000000RnnnnRdest
;;  0 - 32 bit^
;;  1 - 64 bit
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;             00000 - FCVTNS
;;             00001 - FCVTNU
;;             00010 - SCVTF
;;             00011 - UCVTF
;;             00100 - FCVTAS
;;             00101 - FCVTAU
;;             00110 - FMOV
;;             00111 - FMOV
;;             01000 - FCVTPS
;;             01001 - FCVTPU
;;             10000 - FCVTMS
;;             10001 - FCVTMU
;;             11000 - FCVTZS
;;             11001 - FCVTZU


;;; Floating-Point Data Processing (1 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011110pt1Opcode10000RnnnnRdest
;;            ^      ^
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;             000000 - FMOV
;;             000001 - FABS
;;             000010 - FNEG
;;             000011 - FSQRT
;;             000100 - FCVT
;;             000101 - FCVT
;;             001000 - FRINTN
;;             001001 - FRINTP
;;             001010 - FRINTM
;;             001011 - FRINTZ
;;             001100 - FRINTA
;;             001110 - FRINTX
;;             001111 - FRINTI


;;; Floating-Point Compare
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011110pt1Rmmmm001000RnnnnOpcod
;;            ^      ^
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;                             00000 - FCMP
;;                             01000 - FCMP
;;                             10000 - FCMPE
;;                             11000 - FCMPE


;;; Floating-Point Immediate: FMOV
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011110pt1imm8----100imm5-Rdest
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision


;;; Floating-Point Conditional Compare
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011110pt1RmmmmCond01RnnnnoNZCV
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;                             0 - FCCMP
;;                             1 - FCCMPE
;; Sets CC flags
;; Note: Can generate floating point exceptions


;;; Floating-Point Data Processing (2 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 000111110pt1RmmmOpcd10RnnnnRdest
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;                  0000 - FMUL
;;                  0001 - FDIV
;;                  0010 - FADD
;;                  0011 - FSUB
;;                  0100 - FMAX
;;                  0101 - FMIN
;;                  0110 - FMAXNM
;;                  0111 - FMINNM
;;                  1000 - FNMUL
;; Rdest = If Rn > Rm then Rn else Rm


;;; Floating-Point Conditional Select [FCSEL]
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011110pt1RmmmmCond11RnnnnRdest
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;; Rdest = If Cond, then Rn else Rm
;; Note: Can generate floating point exceptions


;;; Floating-Point Data Processing (3 source)
;; ; 3         2         1         0
;; ;10987654321098765432109876543210
;;; 00011111ptXRmmmmoRaaaaRnnnnRdest
;;          00=Single Precision
;;          01=Double Precision
;;          11=Half   Precision
;;            0     0 - FMADD   Fdest = (Fm * Fn) + Fa
;;            0     1 - FMSUB   Fdest = (Fm * Fn) - Fa
;;            1     0 - FNMADD  Fdest = negate(Fm * Fn) + Fa
;;            1     1 - FNMSUB  Fdest = negate(Fm * Fn) - Fa
;; Note: Can generate floating point exceptions

;;
;;; SIMD

Bit 53 is tattered and worn down by a peripatetic existence
since being transformed by an evil wizard until such time as

Oh. What? Sorry. Not enought sleep lately.  My mind wanders after
reading large amounts of technical descriptive text.

Hope to get back to this later..

;;; @@@FIXME: FUTURE@@@
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


