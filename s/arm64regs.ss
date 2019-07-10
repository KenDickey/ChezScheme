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

;;; PC-relative
;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; opImmLo10000----ImmHi------Rdddd
;;   0 = ADR
;;   1 = ADRP


;;; ADD/SUB Immediate
;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; sOS100010s----Imm12---RnnnnRdddd
;;  0 = 32 bit
;;  1 = 64 bit
;;   0 = ADD
;;   1 = SUB
;;    0 = Don't set Condition Codes
;;    1 = Set CCs
;;           s = Logical Shift Left (LSL) 0=>0, 1=>12
;;; Alias: MOV to/from SP when shift=0, imm12=0, Rd|Rn = #b11111


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

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210

;;;  3         2         1         0
;;; 10987654321098765432109876543210
;;; 1op100101sh-----imm16------xRdxx
;;; op: 00 MOVN; 10 MOVZ; 11 MOVK
;;; sh: is LSL 0..3 => left shift by 0, 16, 32 or 48

