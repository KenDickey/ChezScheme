;;; AArch64/ARMv8 Instruction Set Encoding from chapter C4 of:
;;; _ARM Architecture Reference Manual ARMv8, for ARMv8-A architecture profile_
;;; https://developer.arm.com/docs/ddi0487/latest/arm-architecture-reference-manual-armv8-for-armv8-a-architecture-profile

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

;;; Opcode Bits [28..25]
;; 100x - Data Processing -- Immediate
;; 101x - Branches, Exception, System
;; x1x0 - Loads & Stores
;; x101 - Data Processing -- Register
;; x111 - Data Processing -- SIMD/Floating Point

;;; Data Processing, Immediate
;; Bits [28 #b100]
;;                [25..23]
;;                  00x -- PC-relative
;;                  010 -- Add/Sub Immediate
;;                  011 -- Add/Sub Immedite+Tag
;;                  100 -- Logical Immediate
;;                  101 -- Move Wide Immediate
;;                  110 -- Bitfield
;;                  111 -- Extract

;;; PC-relative ADdress to Register
;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; opImmLo10000----ImmHi------Rdest
;;   0 = ADR   CurrentPC + (Sign-extend ImmHi:ImmLo)
;;   1 = ADRP  CurrentPC + (Sign-extend (ImmHi:ImmLo << 12))
;; ADRP => 4K Page -- independent of Virtual Memory granularity


;;; ADD/SUB Immediate
;;;  3         2         1         0
;;; 10987654321098765432109876543210
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
;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; 1op100101sh-----imm16------Rdest
;;   00 MOVN -- MOVe-Not -- like MOVZ but invert imm16
;;   10 MOVZ -- MOVe & Zero other bits
;;   11 MOVK -- MOVe & Keep other bits
;;           00 -- imm16 LSL 0
;;           01 -- imm16 LSL 16
;;           10 -- imm16 LSL 32
;;           11 -- imm16 LSL 48


;;; Bitfield Move Immediate [*BFM]
;;;  3         2         1         0
;;; 10987654321098765432109876543210
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
;But in memory shows as (bytes reversed!):
;	ARM64 HEX - E1130333
; e.g. objdump -d foo.o -> shows in HEX order

;; Note other Bitfield ops:
;;	CLZ   - Count Leading Zeros
;;	RBIT  - Reverse all BITs in a register
;;	REV   - REVerse the order of bytes in a register
;;	REV16 - REVerse the byte order in each Halfword
;;	REV32 - REVerse the byte order in each Word
;; All but REV32 can operate on Word [Wn] or Double [Xn] registers, except REV32 (Xn only)


;;; Extract Immediate
;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; s00100111N0Rmmmm-Imm6-RnnnnRdest
;;  0        0 = 32 bit
;;  1        1 = 64 bit

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210


