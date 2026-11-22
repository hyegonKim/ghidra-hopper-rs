// Native ARM64 differential fixtures; only volatile registers are modified.
.text
.macro vec full, imm
.globl _vec\full\()_\imm, _vec\full\()_\imm\()_op
_vec\full\()_\imm:
 ldp q0, q1, [x4]
 msr nzcv, x1
_vec\full\()_\imm\()_op:
 .inst (0x2f00e400 | (\full << 30) | ((\imm >> 5) << 16) | ((\imm & 31) << 5))
 stp q0, q1, [x0]
 mrs x4, nzcv
 str x4, [x3]
 mov x0, x2
 ret
.endm
.irp imm, 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255
 vec 0, \imm
 vec 1, \imm
.endr
.globl _pair_load_offset, _pair_load_offset_op
_pair_load_offset:
 msr nzcv, x2
_pair_load_offset_op:
 ldp q0, q1, [x0, #16]
 stp q0, q1, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _pair_load_pre, _pair_load_pre_op
_pair_load_pre:
 msr nzcv, x2
_pair_load_pre_op:
 ldp q0, q1, [x0, #-32]!
 stp q0, q1, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _pair_load_post, _pair_load_post_op
_pair_load_post:
 msr nzcv, x2
_pair_load_post_op:
 ldp q0, q1, [x0], #32
 stp q0, q1, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _pair_store_offset, _pair_store_offset_op
_pair_store_offset:
 ldp q0, q1, [x1]
 msr nzcv, x2
_pair_store_offset_op:
 stp q0, q1, [x0, #16]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _pair_store_pre, _pair_store_pre_op
_pair_store_pre:
 ldp q0, q1, [x1]
 msr nzcv, x2
_pair_store_pre_op:
 stp q0, q1, [x0, #-32]!
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _pair_store_post, _pair_store_post_op
_pair_store_post:
 ldp q0, q1, [x1]
 msr nzcv, x2
_pair_store_post_op:
 stp q0, q1, [x0], #32
 mrs x4, nzcv
 str x4, [x3]
 ret
.macro indexed kind, size, ext, scaled, op, dst, index, shift
.globl _idx_\kind\()_\size\()_\ext\()_\scaled, _idx_\kind\()_\size\()_\ext\()_\scaled\()_op
_idx_\kind\()_\size\()_\ext\()_\scaled:
 msr nzcv, x4
_idx_\kind\()_\size\()_\ext\()_\scaled\()_op:
 \op \dst, [x0, \index, \ext #\shift]
 mrs x4, nzcv
 str x4, [x3]
 ret
.endm
indexed load, 1, uxtw, 0, ldrb, w0, w1, 0
indexed load, 1, uxtw, 1, ldrb, w0, w1, 0
indexed load, 1, lsl, 0, ldrb, w0, x1, 0
indexed load, 1, lsl, 1, ldrb, w0, x1, 0
indexed load, 1, sxtw, 0, ldrb, w0, w1, 0
indexed load, 1, sxtw, 1, ldrb, w0, w1, 0
indexed load, 1, sxtx, 0, ldrb, w0, x1, 0
indexed load, 1, sxtx, 1, ldrb, w0, x1, 0
indexed load, 2, uxtw, 0, ldrh, w0, w1, 0
indexed load, 2, uxtw, 1, ldrh, w0, w1, 1
indexed load, 2, lsl, 0, ldrh, w0, x1, 0
indexed load, 2, lsl, 1, ldrh, w0, x1, 1
indexed load, 2, sxtw, 0, ldrh, w0, w1, 0
indexed load, 2, sxtw, 1, ldrh, w0, w1, 1
indexed load, 2, sxtx, 0, ldrh, w0, x1, 0
indexed load, 2, sxtx, 1, ldrh, w0, x1, 1
indexed load, 4, uxtw, 0, ldr, w0, w1, 0
indexed load, 4, uxtw, 1, ldr, w0, w1, 2
indexed load, 4, lsl, 0, ldr, w0, x1, 0
indexed load, 4, lsl, 1, ldr, w0, x1, 2
indexed load, 4, sxtw, 0, ldr, w0, w1, 0
indexed load, 4, sxtw, 1, ldr, w0, w1, 2
indexed load, 4, sxtx, 0, ldr, w0, x1, 0
indexed load, 4, sxtx, 1, ldr, w0, x1, 2
indexed load, 8, uxtw, 0, ldr, x0, w1, 0
indexed load, 8, uxtw, 1, ldr, x0, w1, 3
indexed load, 8, lsl, 0, ldr, x0, x1, 0
indexed load, 8, lsl, 1, ldr, x0, x1, 3
indexed load, 8, sxtw, 0, ldr, x0, w1, 0
indexed load, 8, sxtw, 1, ldr, x0, w1, 3
indexed load, 8, sxtx, 0, ldr, x0, x1, 0
indexed load, 8, sxtx, 1, ldr, x0, x1, 3
indexed load, 0, uxtw, 0, ldrsw, x0, w1, 0
indexed load, 0, uxtw, 1, ldrsw, x0, w1, 2
indexed load, 0, lsl, 0, ldrsw, x0, x1, 0
indexed load, 0, lsl, 1, ldrsw, x0, x1, 2
indexed load, 0, sxtw, 0, ldrsw, x0, w1, 0
indexed load, 0, sxtw, 1, ldrsw, x0, w1, 2
indexed load, 0, sxtx, 0, ldrsw, x0, x1, 0
indexed load, 0, sxtx, 1, ldrsw, x0, x1, 2
indexed store, 1, uxtw, 0, strb, w2, w1, 0
indexed store, 1, uxtw, 1, strb, w2, w1, 0
indexed store, 1, lsl, 0, strb, w2, x1, 0
indexed store, 1, lsl, 1, strb, w2, x1, 0
indexed store, 1, sxtw, 0, strb, w2, w1, 0
indexed store, 1, sxtw, 1, strb, w2, w1, 0
indexed store, 1, sxtx, 0, strb, w2, x1, 0
indexed store, 1, sxtx, 1, strb, w2, x1, 0
indexed store, 2, uxtw, 0, strh, w2, w1, 0
indexed store, 2, uxtw, 1, strh, w2, w1, 1
indexed store, 2, lsl, 0, strh, w2, x1, 0
indexed store, 2, lsl, 1, strh, w2, x1, 1
indexed store, 2, sxtw, 0, strh, w2, w1, 0
indexed store, 2, sxtw, 1, strh, w2, w1, 1
indexed store, 2, sxtx, 0, strh, w2, x1, 0
indexed store, 2, sxtx, 1, strh, w2, x1, 1
indexed store, 4, uxtw, 0, str, w2, w1, 0
indexed store, 4, uxtw, 1, str, w2, w1, 2
indexed store, 4, lsl, 0, str, w2, x1, 0
indexed store, 4, lsl, 1, str, w2, x1, 2
indexed store, 4, sxtw, 0, str, w2, w1, 0
indexed store, 4, sxtw, 1, str, w2, w1, 2
indexed store, 4, sxtx, 0, str, w2, x1, 0
indexed store, 4, sxtx, 1, str, w2, x1, 2
indexed store, 8, uxtw, 0, str, x2, w1, 0
indexed store, 8, uxtw, 1, str, x2, w1, 3
indexed store, 8, lsl, 0, str, x2, x1, 0
indexed store, 8, lsl, 1, str, x2, x1, 3
indexed store, 8, sxtw, 0, str, x2, w1, 0
indexed store, 8, sxtw, 1, str, x2, w1, 3
indexed store, 8, sxtx, 0, str, x2, x1, 0
indexed store, 8, sxtx, 1, str, x2, x1, 3
.globl _atomic32_plain, _atomic32_plain_op
_atomic32_plain:
 msr nzcv, x2
_atomic32_plain_op:
 ldadd w0, w0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic32_a, _atomic32_a_op
_atomic32_a:
 msr nzcv, x2
_atomic32_a_op:
 ldadda w0, w0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic32_l, _atomic32_l_op
_atomic32_l:
 msr nzcv, x2
_atomic32_l_op:
 ldaddl w0, w0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic32_al, _atomic32_al_op
_atomic32_al:
 msr nzcv, x2
_atomic32_al_op:
 ldaddal w0, w0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _loop32, _loop32_op, _loop32_end
_loop32:
 msr nzcv, x2
_loop32_op:
 mov w16, w0
1:
 ldaxr w0, [x1]
 add w17, w0, w16
 stlxr w15, w17, [x1]
 cbnz w15, 1b
_loop32_end:
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _fail32, _fail32_op, _fail32_end
_fail32:
 msr nzcv, x2
_fail32_op:
 mov w3, w0
 ldaxr w2, [x1]
 clrex
 stlxr w0, w3, [x1]
_fail32_end:
 ret
.globl _atomic64_plain, _atomic64_plain_op
_atomic64_plain:
 msr nzcv, x2
_atomic64_plain_op:
 ldadd x0, x0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic64_a, _atomic64_a_op
_atomic64_a:
 msr nzcv, x2
_atomic64_a_op:
 ldadda x0, x0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic64_l, _atomic64_l_op
_atomic64_l:
 msr nzcv, x2
_atomic64_l_op:
 ldaddl x0, x0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _atomic64_al, _atomic64_al_op
_atomic64_al:
 msr nzcv, x2
_atomic64_al_op:
 ldaddal x0, x0, [x1]
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _loop64, _loop64_op, _loop64_end
_loop64:
 msr nzcv, x2
_loop64_op:
 mov x16, x0
1:
 ldaxr x0, [x1]
 add x17, x0, x16
 stlxr w15, x17, [x1]
 cbnz w15, 1b
_loop64_end:
 mrs x4, nzcv
 str x4, [x3]
 ret
.globl _fail64, _fail64_op, _fail64_end
_fail64:
 msr nzcv, x2
_fail64_op:
 mov x3, x0
 ldaxr x2, [x1]
 clrex
 stlxr w0, x3, [x1]
_fail64_end:
 ret
