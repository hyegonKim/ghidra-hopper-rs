// Real instructions are assembled independently of the Rust decoder.
.text
.macro long name, instruction:vararg
.globl _\name, _\name\()_op
_\name:
 msr nzcv, x3
_\name\()_op:
 \instruction
 mrs x5, nzcv
 stp x0, x1, [x4]
 stp x2, x5, [x4, #16]
 mov x6, sp
 str x6, [x4, #32]
 ret
.endm
.macro vector name, instruction:vararg
.globl _\name, _\name\()_op
_\name:
 ldp q0, q31, [x1]
 msr nzcv, x0
_\name\()_op:
 \instruction
 stp q0, q31, [x1]
 mrs x2, nzcv
 str x2, [x1, #32]
 mov x2, sp
 str x2, [x1, #40]
 ret
.endm
long long_0, smaddl x0, w0, w1, x2
long long_1, smaddl x1, w0, w1, x2
long long_2, smaddl x2, w0, w1, x2
long long_3, smaddl x0, w0, w0, x0
long long_4, smaddl x2, w1, w0, x2
long long_5, smull x0, w0, w1
long long_6, smull x1, w0, w1
long long_7, smaddl x2, wzr, w1, x2
long long_8, smaddl x2, w0, wzr, x2
long long_9, smaddl xzr, w0, w1, x2
long long_10, smull xzr, wzr, wzr
long long_11, smull x2, w2, w2
long long_12, smaddl x0, wzr, wzr, x2
.irp imm,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255
 vector vi_0_0_0_0_\imm, movi v0.2s, #\imm
 vector vi_0_0_0_31_\imm, movi v31.2s, #\imm
 vector vi_0_0_2_0_\imm, movi v0.2s, #\imm, lsl #8
 vector vi_0_0_2_31_\imm, movi v31.2s, #\imm, lsl #8
 vector vi_0_0_4_0_\imm, movi v0.2s, #\imm, lsl #16
 vector vi_0_0_4_31_\imm, movi v31.2s, #\imm, lsl #16
 vector vi_0_0_6_0_\imm, movi v0.2s, #\imm, lsl #24
 vector vi_0_0_6_31_\imm, movi v31.2s, #\imm, lsl #24
 vector vi_0_0_8_0_\imm, movi v0.4h, #\imm
 vector vi_0_0_8_31_\imm, movi v31.4h, #\imm
 vector vi_0_0_10_0_\imm, movi v0.4h, #\imm, lsl #8
 vector vi_0_0_10_31_\imm, movi v31.4h, #\imm, lsl #8
 vector vi_0_0_12_0_\imm, movi v0.2s, #\imm, msl #8
 vector vi_0_0_12_31_\imm, movi v31.2s, #\imm, msl #8
 vector vi_0_0_13_0_\imm, movi v0.2s, #\imm, msl #16
 vector vi_0_0_13_31_\imm, movi v31.2s, #\imm, msl #16
 vector vi_0_0_14_0_\imm, movi v0.8b, #\imm
 vector vi_0_0_14_31_\imm, movi v31.8b, #\imm
 vector vi_0_1_0_0_\imm, movi v0.4s, #\imm
 vector vi_0_1_0_31_\imm, movi v31.4s, #\imm
 vector vi_0_1_2_0_\imm, movi v0.4s, #\imm, lsl #8
 vector vi_0_1_2_31_\imm, movi v31.4s, #\imm, lsl #8
 vector vi_0_1_4_0_\imm, movi v0.4s, #\imm, lsl #16
 vector vi_0_1_4_31_\imm, movi v31.4s, #\imm, lsl #16
 vector vi_0_1_6_0_\imm, movi v0.4s, #\imm, lsl #24
 vector vi_0_1_6_31_\imm, movi v31.4s, #\imm, lsl #24
 vector vi_0_1_8_0_\imm, movi v0.8h, #\imm
 vector vi_0_1_8_31_\imm, movi v31.8h, #\imm
 vector vi_0_1_10_0_\imm, movi v0.8h, #\imm, lsl #8
 vector vi_0_1_10_31_\imm, movi v31.8h, #\imm, lsl #8
 vector vi_0_1_12_0_\imm, movi v0.4s, #\imm, msl #8
 vector vi_0_1_12_31_\imm, movi v31.4s, #\imm, msl #8
 vector vi_0_1_13_0_\imm, movi v0.4s, #\imm, msl #16
 vector vi_0_1_13_31_\imm, movi v31.4s, #\imm, msl #16
 vector vi_0_1_14_0_\imm, movi v0.16b, #\imm
 vector vi_0_1_14_31_\imm, movi v31.16b, #\imm
 vector vi_1_0_14_0_\imm, .inst (0x2f00e400 | (0 << 30) | ((\imm >> 5) << 16) | ((\imm & 31) << 5) | 0)
 vector vi_1_0_14_31_\imm, .inst (0x2f00e400 | (0 << 30) | ((\imm >> 5) << 16) | ((\imm & 31) << 5) | 31)
 vector vi_1_1_14_0_\imm, .inst (0x2f00e400 | (1 << 30) | ((\imm >> 5) << 16) | ((\imm & 31) << 5) | 0)
 vector vi_1_1_14_31_\imm, .inst (0x2f00e400 | (1 << 30) | ((\imm >> 5) << 16) | ((\imm & 31) << 5) | 31)
.endr
