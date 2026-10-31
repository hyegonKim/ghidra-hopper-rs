.text
.p2align 2
.globl _sel32_eq
_sel32_eq:
    msr nzcv, x2
    csel w0, w0, w1, eq
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_ne
_sel32_ne:
    msr nzcv, x2
    csel w0, w0, w1, ne
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_cs
_sel32_cs:
    msr nzcv, x2
    csel w0, w0, w1, cs
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_cc
_sel32_cc:
    msr nzcv, x2
    csel w0, w0, w1, cc
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_mi
_sel32_mi:
    msr nzcv, x2
    csel w0, w0, w1, mi
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_pl
_sel32_pl:
    msr nzcv, x2
    csel w0, w0, w1, pl
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_vs
_sel32_vs:
    msr nzcv, x2
    csel w0, w0, w1, vs
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_vc
_sel32_vc:
    msr nzcv, x2
    csel w0, w0, w1, vc
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_hi
_sel32_hi:
    msr nzcv, x2
    csel w0, w0, w1, hi
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_ls
_sel32_ls:
    msr nzcv, x2
    csel w0, w0, w1, ls
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_ge
_sel32_ge:
    msr nzcv, x2
    csel w0, w0, w1, ge
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_lt
_sel32_lt:
    msr nzcv, x2
    csel w0, w0, w1, lt
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_gt
_sel32_gt:
    msr nzcv, x2
    csel w0, w0, w1, gt
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_le
_sel32_le:
    msr nzcv, x2
    csel w0, w0, w1, le
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_al
_sel32_al:
    msr nzcv, x2
    csel w0, w0, w1, al
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel32_nv
_sel32_nv:
    msr nzcv, x2
    csel w0, w0, w1, nv
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_eq
_sel64_eq:
    msr nzcv, x2
    csel x0, x0, x1, eq
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_ne
_sel64_ne:
    msr nzcv, x2
    csel x0, x0, x1, ne
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_cs
_sel64_cs:
    msr nzcv, x2
    csel x0, x0, x1, cs
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_cc
_sel64_cc:
    msr nzcv, x2
    csel x0, x0, x1, cc
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_mi
_sel64_mi:
    msr nzcv, x2
    csel x0, x0, x1, mi
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_pl
_sel64_pl:
    msr nzcv, x2
    csel x0, x0, x1, pl
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_vs
_sel64_vs:
    msr nzcv, x2
    csel x0, x0, x1, vs
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_vc
_sel64_vc:
    msr nzcv, x2
    csel x0, x0, x1, vc
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_hi
_sel64_hi:
    msr nzcv, x2
    csel x0, x0, x1, hi
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_ls
_sel64_ls:
    msr nzcv, x2
    csel x0, x0, x1, ls
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_ge
_sel64_ge:
    msr nzcv, x2
    csel x0, x0, x1, ge
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_lt
_sel64_lt:
    msr nzcv, x2
    csel x0, x0, x1, lt
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_gt
_sel64_gt:
    msr nzcv, x2
    csel x0, x0, x1, gt
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_le
_sel64_le:
    msr nzcv, x2
    csel x0, x0, x1, le
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_al
_sel64_al:
    msr nzcv, x2
    csel x0, x0, x1, al
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _sel64_nv
_sel64_nv:
    msr nzcv, x2
    csel x0, x0, x1, nv
    mrs x4, nzcv
    str x4, [x3]
    ret
.globl _movk32_0
_movk32_0:
    movk w0, #0x6c69, lsl #0
    ret
.globl _movn32_0
_movn32_0:
    movn w0, #0x6c69, lsl #0
    ret
.globl _movk32_16
_movk32_16:
    movk w0, #0x6c69, lsl #16
    ret
.globl _movn32_16
_movn32_16:
    movn w0, #0x6c69, lsl #16
    ret
.globl _movk64_0
_movk64_0:
    movk x0, #0x6c69, lsl #0
    ret
.globl _movn64_0
_movn64_0:
    movn x0, #0x6c69, lsl #0
    ret
.globl _movk64_16
_movk64_16:
    movk x0, #0x6c69, lsl #16
    ret
.globl _movn64_16
_movn64_16:
    movn x0, #0x6c69, lsl #16
    ret
.globl _movk64_32
_movk64_32:
    movk x0, #0x6c69, lsl #32
    ret
.globl _movn64_32
_movn64_32:
    movn x0, #0x6c69, lsl #32
    ret
.globl _movk64_48
_movk64_48:
    movk x0, #0x6c69, lsl #48
    ret
.globl _movn64_48
_movn64_48:
    movn x0, #0x6c69, lsl #48
    ret
.globl _signed_offset
_signed_offset:
    ldrsw x2, [x0, #4]
    str x0, [x1]
    mov x0, x2
    ret
.globl _signed_unscaled
_signed_unscaled:
    ldursw x2, [x0, #-4]
    str x0, [x1]
    mov x0, x2
    ret
.globl _signed_pre
_signed_pre:
    ldrsw x2, [x0, #4]!
    str x0, [x1]
    mov x0, x2
    ret
.globl _signed_post
_signed_post:
    ldrsw x2, [x0], #4
    str x0, [x1]
    mov x0, x2
    ret
.globl _signed_alias
_signed_alias:
    ldrsw x0, [x0, #4]
    ret
.globl _signed_discard
_signed_discard:
    ldrsw xzr, [x0, #4]
    mov x0, #42
    ret
.globl _acquire32
_acquire32:
    ldar w0, [x0]
    ret
.globl _acquire64
_acquire64:
    ldar x0, [x0]
    ret
.globl _acquire_sp
_acquire_sp:
    sub sp, sp, #16
    str x0, [sp]
    ldar x0, [sp]
    add sp, sp, #16
    ret
.globl _thread_read
_thread_read:
    mrs x0, TPIDR_EL0
    ret
.globl _thread_discard
_thread_discard:
    mrs xzr, TPIDR_EL0
    ret
