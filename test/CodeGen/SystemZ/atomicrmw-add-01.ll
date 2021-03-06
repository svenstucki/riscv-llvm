; Test 8-bit atomic additions.
;
; RUN: llc < %s -mtriple=s390x-linux-gnu | FileCheck %s -check-prefix=CHECK
; RUN: llc < %s -mtriple=s390x-linux-gnu | FileCheck %s -check-prefix=CHECK-SHIFT1
; RUN: llc < %s -mtriple=s390x-linux-gnu | FileCheck %s -check-prefix=CHECK-SHIFT2

; Check addition of a variable.
; - CHECK is for the main loop.
; - CHECK-SHIFT1 makes sure that the negated shift count used by the second
;   RLL is set up correctly.  The negation is independent of the NILL and L
;   tested in CHECK.
; - CHECK-SHIFT2 makes sure that %b is shifted into the high part of the word
;   before being used.  This shift is independent of the other loop prologue
;   instructions.
define i8 @f1(i8 *%src, i8 %b) {
; CHECK: f1:
; CHECK: sllg [[SHIFT:%r[1-9]+]], %r2, 3
; CHECK: nill %r2, 65532
; CHECK: l [[OLD:%r[0-9]+]], 0(%r2)
; CHECK: [[LABEL:\.[^:]*]]:
; CHECK: rll [[ROT:%r[0-9]+]], [[OLD]], 0([[SHIFT]])
; CHECK: ar [[ROT]], %r3
; CHECK: rll [[NEW:%r[0-9]+]], [[ROT]], 0({{%r[1-9]+}})
; CHECK: cs [[OLD]], [[NEW]], 0(%r2)
; CHECK: j{{g?}}lh [[LABEL]]
; CHECK: rll %r2, [[OLD]], 8([[SHIFT]])
; CHECK: br %r14
;
; CHECK-SHIFT1: f1:
; CHECK-SHIFT1: sllg [[SHIFT:%r[1-9]+]], %r2, 3
; CHECK-SHIFT1: lcr [[NEGSHIFT:%r[1-9]+]], [[SHIFT]]
; CHECK-SHIFT1: rll
; CHECK-SHIFT1: rll {{%r[0-9]+}}, {{%r[0-9]+}}, 0([[NEGSHIFT]])
; CHECK-SHIFT1: rll
; CHECK-SHIFT1: br %r14
;
; CHECK-SHIFT2: f1:
; CHECK-SHIFT2: sll %r3, 24
; CHECK-SHIFT2: rll
; CHECK-SHIFT2: ar {{%r[0-9]+}}, %r3
; CHECK-SHIFT2: rll
; CHECK-SHIFT2: rll
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 %b seq_cst
  ret i8 %res
}

; Check the minimum signed value.  We add 0x80000000 to the rotated word.
define i8 @f2(i8 *%src) {
; CHECK: f2:
; CHECK: sllg [[SHIFT:%r[1-9]+]], %r2, 3
; CHECK: nill %r2, 65532
; CHECK: l [[OLD:%r[0-9]+]], 0(%r2)
; CHECK: [[LABEL:\.[^:]*]]:
; CHECK: rll [[ROT:%r[0-9]+]], [[OLD]], 0([[SHIFT]])
; CHECK: afi [[ROT]], -2147483648
; CHECK: rll [[NEW:%r[0-9]+]], [[ROT]], 0([[NEGSHIFT:%r[1-9]+]])
; CHECK: cs [[OLD]], [[NEW]], 0(%r2)
; CHECK: j{{g?}}lh [[LABEL]]
; CHECK: rll %r2, [[OLD]], 8([[SHIFT]])
; CHECK: br %r14
;
; CHECK-SHIFT1: f2:
; CHECK-SHIFT1: sllg [[SHIFT:%r[1-9]+]], %r2, 3
; CHECK-SHIFT1: lcr [[NEGSHIFT:%r[1-9]+]], [[SHIFT]]
; CHECK-SHIFT1: rll
; CHECK-SHIFT1: rll {{%r[0-9]+}}, {{%r[0-9]+}}, 0([[NEGSHIFT]])
; CHECK-SHIFT1: rll
; CHECK-SHIFT1: br %r14
;
; CHECK-SHIFT2: f2:
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 -128 seq_cst
  ret i8 %res
}

; Check addition of -1.  We add 0xff000000 to the rotated word.
define i8 @f3(i8 *%src) {
; CHECK: f3:
; CHECK: afi [[ROT]], -16777216
; CHECK: br %r14
;
; CHECK-SHIFT1: f3:
; CHECK-SHIFT1: br %r14
; CHECK-SHIFT2: f3:
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 -1 seq_cst
  ret i8 %res
}

; Check addition of 1.  We add 0x01000000 to the rotated word.
define i8 @f4(i8 *%src) {
; CHECK: f4:
; CHECK: afi [[ROT]], 16777216
; CHECK: br %r14
;
; CHECK-SHIFT1: f4:
; CHECK-SHIFT1: br %r14
; CHECK-SHIFT2: f4:
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 1 seq_cst
  ret i8 %res
}

; Check the maximum signed value.  We add 0x7f000000 to the rotated word.
define i8 @f5(i8 *%src) {
; CHECK: f5:
; CHECK: afi [[ROT]], 2130706432
; CHECK: br %r14
;
; CHECK-SHIFT1: f5:
; CHECK-SHIFT1: br %r14
; CHECK-SHIFT2: f5:
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 127 seq_cst
  ret i8 %res
}

; Check addition of a large unsigned value.  We add 0xfe000000 to the
; rotated word, expressed as a negative AFI operand.
define i8 @f6(i8 *%src) {
; CHECK: f6:
; CHECK: afi [[ROT]], -33554432
; CHECK: br %r14
;
; CHECK-SHIFT1: f6:
; CHECK-SHIFT1: br %r14
; CHECK-SHIFT2: f6:
; CHECK-SHIFT2: br %r14
  %res = atomicrmw add i8 *%src, i8 254 seq_cst
  ret i8 %res
}
