.text
// Each opcode has a native CPU oracle; SP destinations are observed then restored.
.macro integer name, word
.globl _\name, _\name\()_op
_\name:
 mov x9, sp
 msr nzcv, x2
_\name\()_op:
 .inst \word
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.endm
integer logic_32_and_0_0, 0xa010000
integer logic_32_and_0_1, 0xa010400
integer logic_32_and_0_31, 0xa017c00
integer logic_32_and_1_0, 0xa410000
integer logic_32_and_1_1, 0xa410400
integer logic_32_and_1_31, 0xa417c00
integer logic_32_and_2_0, 0xa810000
integer logic_32_and_2_1, 0xa810400
integer logic_32_and_2_31, 0xa817c00
integer logic_32_and_3_0, 0xac10000
integer logic_32_and_3_1, 0xac10400
integer logic_32_and_3_31, 0xac17c00
integer logic_32_bic_0_0, 0xa210000
integer logic_32_bic_0_1, 0xa210400
integer logic_32_bic_0_31, 0xa217c00
integer logic_32_bic_1_0, 0xa610000
integer logic_32_bic_1_1, 0xa610400
integer logic_32_bic_1_31, 0xa617c00
integer logic_32_bic_2_0, 0xaa10000
integer logic_32_bic_2_1, 0xaa10400
integer logic_32_bic_2_31, 0xaa17c00
integer logic_32_bic_3_0, 0xae10000
integer logic_32_bic_3_1, 0xae10400
integer logic_32_bic_3_31, 0xae17c00
integer logic_32_orn_0_0, 0x2a210000
integer logic_32_orn_0_1, 0x2a210400
integer logic_32_orn_0_31, 0x2a217c00
integer logic_32_orn_1_0, 0x2a610000
integer logic_32_orn_1_1, 0x2a610400
integer logic_32_orn_1_31, 0x2a617c00
integer logic_32_orn_2_0, 0x2aa10000
integer logic_32_orn_2_1, 0x2aa10400
integer logic_32_orn_2_31, 0x2aa17c00
integer logic_32_orn_3_0, 0x2ae10000
integer logic_32_orn_3_1, 0x2ae10400
integer logic_32_orn_3_31, 0x2ae17c00
integer logic_32_eor_0_0, 0x4a010000
integer logic_32_eor_0_1, 0x4a010400
integer logic_32_eor_0_31, 0x4a017c00
integer logic_32_eor_1_0, 0x4a410000
integer logic_32_eor_1_1, 0x4a410400
integer logic_32_eor_1_31, 0x4a417c00
integer logic_32_eor_2_0, 0x4a810000
integer logic_32_eor_2_1, 0x4a810400
integer logic_32_eor_2_31, 0x4a817c00
integer logic_32_eor_3_0, 0x4ac10000
integer logic_32_eor_3_1, 0x4ac10400
integer logic_32_eor_3_31, 0x4ac17c00
integer logic_32_eon_0_0, 0x4a210000
integer logic_32_eon_0_1, 0x4a210400
integer logic_32_eon_0_31, 0x4a217c00
integer logic_32_eon_1_0, 0x4a610000
integer logic_32_eon_1_1, 0x4a610400
integer logic_32_eon_1_31, 0x4a617c00
integer logic_32_eon_2_0, 0x4aa10000
integer logic_32_eon_2_1, 0x4aa10400
integer logic_32_eon_2_31, 0x4aa17c00
integer logic_32_eon_3_0, 0x4ae10000
integer logic_32_eon_3_1, 0x4ae10400
integer logic_32_eon_3_31, 0x4ae17c00
integer logic_32_ands_0_0, 0x6a010000
integer logic_32_ands_0_1, 0x6a010400
integer logic_32_ands_0_31, 0x6a017c00
integer logic_32_ands_1_0, 0x6a410000
integer logic_32_ands_1_1, 0x6a410400
integer logic_32_ands_1_31, 0x6a417c00
integer logic_32_ands_2_0, 0x6a810000
integer logic_32_ands_2_1, 0x6a810400
integer logic_32_ands_2_31, 0x6a817c00
integer logic_32_ands_3_0, 0x6ac10000
integer logic_32_ands_3_1, 0x6ac10400
integer logic_32_ands_3_31, 0x6ac17c00
integer logic_32_bics_0_0, 0x6a210000
integer logic_32_bics_0_1, 0x6a210400
integer logic_32_bics_0_31, 0x6a217c00
integer logic_32_bics_1_0, 0x6a610000
integer logic_32_bics_1_1, 0x6a610400
integer logic_32_bics_1_31, 0x6a617c00
integer logic_32_bics_2_0, 0x6aa10000
integer logic_32_bics_2_1, 0x6aa10400
integer logic_32_bics_2_31, 0x6aa17c00
integer logic_32_bics_3_0, 0x6ae10000
integer logic_32_bics_3_1, 0x6ae10400
integer logic_32_bics_3_31, 0x6ae17c00
integer select_32_1_0, 0x1a810400
integer select_32_1_1, 0x1a811400
integer select_32_1_2, 0x1a812400
integer select_32_1_3, 0x1a813400
integer select_32_1_4, 0x1a814400
integer select_32_1_5, 0x1a815400
integer select_32_1_6, 0x1a816400
integer select_32_1_7, 0x1a817400
integer select_32_1_8, 0x1a818400
integer select_32_1_9, 0x1a819400
integer select_32_1_10, 0x1a81a400
integer select_32_1_11, 0x1a81b400
integer select_32_1_12, 0x1a81c400
integer select_32_1_13, 0x1a81d400
integer select_32_1_14, 0x1a81e400
integer select_32_1_15, 0x1a81f400
integer select_32_2_0, 0x5a810000
integer select_32_2_1, 0x5a811000
integer select_32_2_2, 0x5a812000
integer select_32_2_3, 0x5a813000
integer select_32_2_4, 0x5a814000
integer select_32_2_5, 0x5a815000
integer select_32_2_6, 0x5a816000
integer select_32_2_7, 0x5a817000
integer select_32_2_8, 0x5a818000
integer select_32_2_9, 0x5a819000
integer select_32_2_10, 0x5a81a000
integer select_32_2_11, 0x5a81b000
integer select_32_2_12, 0x5a81c000
integer select_32_2_13, 0x5a81d000
integer select_32_2_14, 0x5a81e000
integer select_32_2_15, 0x5a81f000
integer select_32_3_0, 0x5a810400
integer select_32_3_1, 0x5a811400
integer select_32_3_2, 0x5a812400
integer select_32_3_3, 0x5a813400
integer select_32_3_4, 0x5a814400
integer select_32_3_5, 0x5a815400
integer select_32_3_6, 0x5a816400
integer select_32_3_7, 0x5a817400
integer select_32_3_8, 0x5a818400
integer select_32_3_9, 0x5a819400
integer select_32_3_10, 0x5a81a400
integer select_32_3_11, 0x5a81b400
integer select_32_3_12, 0x5a81c400
integer select_32_3_13, 0x5a81d400
integer select_32_3_14, 0x5a81e400
integer select_32_3_15, 0x5a81f400
integer extend_32_0_0_0, 0xb210000
integer extend_32_0_0_1, 0x2b210000
integer extend_32_0_0_2, 0x4b210000
integer extend_32_0_0_3, 0x6b210000
integer extend_32_0_1_0, 0xb210400
integer extend_32_0_1_1, 0x2b210400
integer extend_32_0_1_2, 0x4b210400
integer extend_32_0_1_3, 0x6b210400
integer extend_32_0_2_0, 0xb210800
integer extend_32_0_2_1, 0x2b210800
integer extend_32_0_2_2, 0x4b210800
integer extend_32_0_2_3, 0x6b210800
integer extend_32_0_3_0, 0xb210c00
integer extend_32_0_3_1, 0x2b210c00
integer extend_32_0_3_2, 0x4b210c00
integer extend_32_0_3_3, 0x6b210c00
integer extend_32_0_4_0, 0xb211000
integer extend_32_0_4_1, 0x2b211000
integer extend_32_0_4_2, 0x4b211000
integer extend_32_0_4_3, 0x6b211000
integer extend_32_1_0_0, 0xb212000
integer extend_32_1_0_1, 0x2b212000
integer extend_32_1_0_2, 0x4b212000
integer extend_32_1_0_3, 0x6b212000
integer extend_32_1_1_0, 0xb212400
integer extend_32_1_1_1, 0x2b212400
integer extend_32_1_1_2, 0x4b212400
integer extend_32_1_1_3, 0x6b212400
integer extend_32_1_2_0, 0xb212800
integer extend_32_1_2_1, 0x2b212800
integer extend_32_1_2_2, 0x4b212800
integer extend_32_1_2_3, 0x6b212800
integer extend_32_1_3_0, 0xb212c00
integer extend_32_1_3_1, 0x2b212c00
integer extend_32_1_3_2, 0x4b212c00
integer extend_32_1_3_3, 0x6b212c00
integer extend_32_1_4_0, 0xb213000
integer extend_32_1_4_1, 0x2b213000
integer extend_32_1_4_2, 0x4b213000
integer extend_32_1_4_3, 0x6b213000
integer extend_32_2_0_0, 0xb214000
integer extend_32_2_0_1, 0x2b214000
integer extend_32_2_0_2, 0x4b214000
integer extend_32_2_0_3, 0x6b214000
integer extend_32_2_1_0, 0xb214400
integer extend_32_2_1_1, 0x2b214400
integer extend_32_2_1_2, 0x4b214400
integer extend_32_2_1_3, 0x6b214400
integer extend_32_2_2_0, 0xb214800
integer extend_32_2_2_1, 0x2b214800
integer extend_32_2_2_2, 0x4b214800
integer extend_32_2_2_3, 0x6b214800
integer extend_32_2_3_0, 0xb214c00
integer extend_32_2_3_1, 0x2b214c00
integer extend_32_2_3_2, 0x4b214c00
integer extend_32_2_3_3, 0x6b214c00
integer extend_32_2_4_0, 0xb215000
integer extend_32_2_4_1, 0x2b215000
integer extend_32_2_4_2, 0x4b215000
integer extend_32_2_4_3, 0x6b215000
integer extend_32_3_0_0, 0xb216000
integer extend_32_3_0_1, 0x2b216000
integer extend_32_3_0_2, 0x4b216000
integer extend_32_3_0_3, 0x6b216000
integer extend_32_3_1_0, 0xb216400
integer extend_32_3_1_1, 0x2b216400
integer extend_32_3_1_2, 0x4b216400
integer extend_32_3_1_3, 0x6b216400
integer extend_32_3_2_0, 0xb216800
integer extend_32_3_2_1, 0x2b216800
integer extend_32_3_2_2, 0x4b216800
integer extend_32_3_2_3, 0x6b216800
integer extend_32_3_3_0, 0xb216c00
integer extend_32_3_3_1, 0x2b216c00
integer extend_32_3_3_2, 0x4b216c00
integer extend_32_3_3_3, 0x6b216c00
integer extend_32_3_4_0, 0xb217000
integer extend_32_3_4_1, 0x2b217000
integer extend_32_3_4_2, 0x4b217000
integer extend_32_3_4_3, 0x6b217000
integer extend_32_4_0_0, 0xb218000
integer extend_32_4_0_1, 0x2b218000
integer extend_32_4_0_2, 0x4b218000
integer extend_32_4_0_3, 0x6b218000
integer extend_32_4_1_0, 0xb218400
integer extend_32_4_1_1, 0x2b218400
integer extend_32_4_1_2, 0x4b218400
integer extend_32_4_1_3, 0x6b218400
integer extend_32_4_2_0, 0xb218800
integer extend_32_4_2_1, 0x2b218800
integer extend_32_4_2_2, 0x4b218800
integer extend_32_4_2_3, 0x6b218800
integer extend_32_4_3_0, 0xb218c00
integer extend_32_4_3_1, 0x2b218c00
integer extend_32_4_3_2, 0x4b218c00
integer extend_32_4_3_3, 0x6b218c00
integer extend_32_4_4_0, 0xb219000
integer extend_32_4_4_1, 0x2b219000
integer extend_32_4_4_2, 0x4b219000
integer extend_32_4_4_3, 0x6b219000
integer extend_32_5_0_0, 0xb21a000
integer extend_32_5_0_1, 0x2b21a000
integer extend_32_5_0_2, 0x4b21a000
integer extend_32_5_0_3, 0x6b21a000
integer extend_32_5_1_0, 0xb21a400
integer extend_32_5_1_1, 0x2b21a400
integer extend_32_5_1_2, 0x4b21a400
integer extend_32_5_1_3, 0x6b21a400
integer extend_32_5_2_0, 0xb21a800
integer extend_32_5_2_1, 0x2b21a800
integer extend_32_5_2_2, 0x4b21a800
integer extend_32_5_2_3, 0x6b21a800
integer extend_32_5_3_0, 0xb21ac00
integer extend_32_5_3_1, 0x2b21ac00
integer extend_32_5_3_2, 0x4b21ac00
integer extend_32_5_3_3, 0x6b21ac00
integer extend_32_5_4_0, 0xb21b000
integer extend_32_5_4_1, 0x2b21b000
integer extend_32_5_4_2, 0x4b21b000
integer extend_32_5_4_3, 0x6b21b000
integer extend_32_6_0_0, 0xb21c000
integer extend_32_6_0_1, 0x2b21c000
integer extend_32_6_0_2, 0x4b21c000
integer extend_32_6_0_3, 0x6b21c000
integer extend_32_6_1_0, 0xb21c400
integer extend_32_6_1_1, 0x2b21c400
integer extend_32_6_1_2, 0x4b21c400
integer extend_32_6_1_3, 0x6b21c400
integer extend_32_6_2_0, 0xb21c800
integer extend_32_6_2_1, 0x2b21c800
integer extend_32_6_2_2, 0x4b21c800
integer extend_32_6_2_3, 0x6b21c800
integer extend_32_6_3_0, 0xb21cc00
integer extend_32_6_3_1, 0x2b21cc00
integer extend_32_6_3_2, 0x4b21cc00
integer extend_32_6_3_3, 0x6b21cc00
integer extend_32_6_4_0, 0xb21d000
integer extend_32_6_4_1, 0x2b21d000
integer extend_32_6_4_2, 0x4b21d000
integer extend_32_6_4_3, 0x6b21d000
integer extend_32_7_0_0, 0xb21e000
integer extend_32_7_0_1, 0x2b21e000
integer extend_32_7_0_2, 0x4b21e000
integer extend_32_7_0_3, 0x6b21e000
integer extend_32_7_1_0, 0xb21e400
integer extend_32_7_1_1, 0x2b21e400
integer extend_32_7_1_2, 0x4b21e400
integer extend_32_7_1_3, 0x6b21e400
integer extend_32_7_2_0, 0xb21e800
integer extend_32_7_2_1, 0x2b21e800
integer extend_32_7_2_2, 0x4b21e800
integer extend_32_7_2_3, 0x6b21e800
integer extend_32_7_3_0, 0xb21ec00
integer extend_32_7_3_1, 0x2b21ec00
integer extend_32_7_3_2, 0x4b21ec00
integer extend_32_7_3_3, 0x6b21ec00
integer extend_32_7_4_0, 0xb21f000
integer extend_32_7_4_1, 0x2b21f000
integer extend_32_7_4_2, 0x4b21f000
integer extend_32_7_4_3, 0x6b21f000
integer sub_32_0_0, 0x4b010000
integer sub_32_0_1, 0x4b010400
integer sub_32_0_31, 0x4b017c00
integer sub_32_1_0, 0x4b410000
integer sub_32_1_1, 0x4b410400
integer sub_32_1_31, 0x4b417c00
integer sub_32_2_0, 0x4b810000
integer sub_32_2_1, 0x4b810400
integer sub_32_2_31, 0x4b817c00
integer multiply_32_0_4, 0x1b011000
integer multiply_32_0_31, 0x1b017c00
integer multiply_32_1_4, 0x1b019000
integer multiply_32_1_31, 0x1b01fc00
integer edge_32_zr_lhs, 0xa0103e0
integer edge_32_zr_rhs, 0xa1f0000
integer edge_32_zr_dest_flags, 0x6a01001f
integer edge_32_select_zr, 0x1a9f07e0
integer edge_32_sub_zr, 0x4b0103e0
integer edge_32_ext_sp_lhs, 0xb2143e0
integer edge_32_ext_sp_dest, 0xb21401f
integer logic_64_and_0_0, 0x8a010000
integer logic_64_and_0_1, 0x8a010400
integer logic_64_and_0_63, 0x8a01fc00
integer logic_64_and_1_0, 0x8a410000
integer logic_64_and_1_1, 0x8a410400
integer logic_64_and_1_63, 0x8a41fc00
integer logic_64_and_2_0, 0x8a810000
integer logic_64_and_2_1, 0x8a810400
integer logic_64_and_2_63, 0x8a81fc00
integer logic_64_and_3_0, 0x8ac10000
integer logic_64_and_3_1, 0x8ac10400
integer logic_64_and_3_63, 0x8ac1fc00
integer logic_64_bic_0_0, 0x8a210000
integer logic_64_bic_0_1, 0x8a210400
integer logic_64_bic_0_63, 0x8a21fc00
integer logic_64_bic_1_0, 0x8a610000
integer logic_64_bic_1_1, 0x8a610400
integer logic_64_bic_1_63, 0x8a61fc00
integer logic_64_bic_2_0, 0x8aa10000
integer logic_64_bic_2_1, 0x8aa10400
integer logic_64_bic_2_63, 0x8aa1fc00
integer logic_64_bic_3_0, 0x8ae10000
integer logic_64_bic_3_1, 0x8ae10400
integer logic_64_bic_3_63, 0x8ae1fc00
integer logic_64_orn_0_0, 0xaa210000
integer logic_64_orn_0_1, 0xaa210400
integer logic_64_orn_0_63, 0xaa21fc00
integer logic_64_orn_1_0, 0xaa610000
integer logic_64_orn_1_1, 0xaa610400
integer logic_64_orn_1_63, 0xaa61fc00
integer logic_64_orn_2_0, 0xaaa10000
integer logic_64_orn_2_1, 0xaaa10400
integer logic_64_orn_2_63, 0xaaa1fc00
integer logic_64_orn_3_0, 0xaae10000
integer logic_64_orn_3_1, 0xaae10400
integer logic_64_orn_3_63, 0xaae1fc00
integer logic_64_eor_0_0, 0xca010000
integer logic_64_eor_0_1, 0xca010400
integer logic_64_eor_0_63, 0xca01fc00
integer logic_64_eor_1_0, 0xca410000
integer logic_64_eor_1_1, 0xca410400
integer logic_64_eor_1_63, 0xca41fc00
integer logic_64_eor_2_0, 0xca810000
integer logic_64_eor_2_1, 0xca810400
integer logic_64_eor_2_63, 0xca81fc00
integer logic_64_eor_3_0, 0xcac10000
integer logic_64_eor_3_1, 0xcac10400
integer logic_64_eor_3_63, 0xcac1fc00
integer logic_64_eon_0_0, 0xca210000
integer logic_64_eon_0_1, 0xca210400
integer logic_64_eon_0_63, 0xca21fc00
integer logic_64_eon_1_0, 0xca610000
integer logic_64_eon_1_1, 0xca610400
integer logic_64_eon_1_63, 0xca61fc00
integer logic_64_eon_2_0, 0xcaa10000
integer logic_64_eon_2_1, 0xcaa10400
integer logic_64_eon_2_63, 0xcaa1fc00
integer logic_64_eon_3_0, 0xcae10000
integer logic_64_eon_3_1, 0xcae10400
integer logic_64_eon_3_63, 0xcae1fc00
integer logic_64_ands_0_0, 0xea010000
integer logic_64_ands_0_1, 0xea010400
integer logic_64_ands_0_63, 0xea01fc00
integer logic_64_ands_1_0, 0xea410000
integer logic_64_ands_1_1, 0xea410400
integer logic_64_ands_1_63, 0xea41fc00
integer logic_64_ands_2_0, 0xea810000
integer logic_64_ands_2_1, 0xea810400
integer logic_64_ands_2_63, 0xea81fc00
integer logic_64_ands_3_0, 0xeac10000
integer logic_64_ands_3_1, 0xeac10400
integer logic_64_ands_3_63, 0xeac1fc00
integer logic_64_bics_0_0, 0xea210000
integer logic_64_bics_0_1, 0xea210400
integer logic_64_bics_0_63, 0xea21fc00
integer logic_64_bics_1_0, 0xea610000
integer logic_64_bics_1_1, 0xea610400
integer logic_64_bics_1_63, 0xea61fc00
integer logic_64_bics_2_0, 0xeaa10000
integer logic_64_bics_2_1, 0xeaa10400
integer logic_64_bics_2_63, 0xeaa1fc00
integer logic_64_bics_3_0, 0xeae10000
integer logic_64_bics_3_1, 0xeae10400
integer logic_64_bics_3_63, 0xeae1fc00
integer select_64_1_0, 0x9a810400
integer select_64_1_1, 0x9a811400
integer select_64_1_2, 0x9a812400
integer select_64_1_3, 0x9a813400
integer select_64_1_4, 0x9a814400
integer select_64_1_5, 0x9a815400
integer select_64_1_6, 0x9a816400
integer select_64_1_7, 0x9a817400
integer select_64_1_8, 0x9a818400
integer select_64_1_9, 0x9a819400
integer select_64_1_10, 0x9a81a400
integer select_64_1_11, 0x9a81b400
integer select_64_1_12, 0x9a81c400
integer select_64_1_13, 0x9a81d400
integer select_64_1_14, 0x9a81e400
integer select_64_1_15, 0x9a81f400
integer select_64_2_0, 0xda810000
integer select_64_2_1, 0xda811000
integer select_64_2_2, 0xda812000
integer select_64_2_3, 0xda813000
integer select_64_2_4, 0xda814000
integer select_64_2_5, 0xda815000
integer select_64_2_6, 0xda816000
integer select_64_2_7, 0xda817000
integer select_64_2_8, 0xda818000
integer select_64_2_9, 0xda819000
integer select_64_2_10, 0xda81a000
integer select_64_2_11, 0xda81b000
integer select_64_2_12, 0xda81c000
integer select_64_2_13, 0xda81d000
integer select_64_2_14, 0xda81e000
integer select_64_2_15, 0xda81f000
integer select_64_3_0, 0xda810400
integer select_64_3_1, 0xda811400
integer select_64_3_2, 0xda812400
integer select_64_3_3, 0xda813400
integer select_64_3_4, 0xda814400
integer select_64_3_5, 0xda815400
integer select_64_3_6, 0xda816400
integer select_64_3_7, 0xda817400
integer select_64_3_8, 0xda818400
integer select_64_3_9, 0xda819400
integer select_64_3_10, 0xda81a400
integer select_64_3_11, 0xda81b400
integer select_64_3_12, 0xda81c400
integer select_64_3_13, 0xda81d400
integer select_64_3_14, 0xda81e400
integer select_64_3_15, 0xda81f400
integer extend_64_0_0_0, 0x8b210000
integer extend_64_0_0_1, 0xab210000
integer extend_64_0_0_2, 0xcb210000
integer extend_64_0_0_3, 0xeb210000
integer extend_64_0_1_0, 0x8b210400
integer extend_64_0_1_1, 0xab210400
integer extend_64_0_1_2, 0xcb210400
integer extend_64_0_1_3, 0xeb210400
integer extend_64_0_2_0, 0x8b210800
integer extend_64_0_2_1, 0xab210800
integer extend_64_0_2_2, 0xcb210800
integer extend_64_0_2_3, 0xeb210800
integer extend_64_0_3_0, 0x8b210c00
integer extend_64_0_3_1, 0xab210c00
integer extend_64_0_3_2, 0xcb210c00
integer extend_64_0_3_3, 0xeb210c00
integer extend_64_0_4_0, 0x8b211000
integer extend_64_0_4_1, 0xab211000
integer extend_64_0_4_2, 0xcb211000
integer extend_64_0_4_3, 0xeb211000
integer extend_64_1_0_0, 0x8b212000
integer extend_64_1_0_1, 0xab212000
integer extend_64_1_0_2, 0xcb212000
integer extend_64_1_0_3, 0xeb212000
integer extend_64_1_1_0, 0x8b212400
integer extend_64_1_1_1, 0xab212400
integer extend_64_1_1_2, 0xcb212400
integer extend_64_1_1_3, 0xeb212400
integer extend_64_1_2_0, 0x8b212800
integer extend_64_1_2_1, 0xab212800
integer extend_64_1_2_2, 0xcb212800
integer extend_64_1_2_3, 0xeb212800
integer extend_64_1_3_0, 0x8b212c00
integer extend_64_1_3_1, 0xab212c00
integer extend_64_1_3_2, 0xcb212c00
integer extend_64_1_3_3, 0xeb212c00
integer extend_64_1_4_0, 0x8b213000
integer extend_64_1_4_1, 0xab213000
integer extend_64_1_4_2, 0xcb213000
integer extend_64_1_4_3, 0xeb213000
integer extend_64_2_0_0, 0x8b214000
integer extend_64_2_0_1, 0xab214000
integer extend_64_2_0_2, 0xcb214000
integer extend_64_2_0_3, 0xeb214000
integer extend_64_2_1_0, 0x8b214400
integer extend_64_2_1_1, 0xab214400
integer extend_64_2_1_2, 0xcb214400
integer extend_64_2_1_3, 0xeb214400
integer extend_64_2_2_0, 0x8b214800
integer extend_64_2_2_1, 0xab214800
integer extend_64_2_2_2, 0xcb214800
integer extend_64_2_2_3, 0xeb214800
integer extend_64_2_3_0, 0x8b214c00
integer extend_64_2_3_1, 0xab214c00
integer extend_64_2_3_2, 0xcb214c00
integer extend_64_2_3_3, 0xeb214c00
integer extend_64_2_4_0, 0x8b215000
integer extend_64_2_4_1, 0xab215000
integer extend_64_2_4_2, 0xcb215000
integer extend_64_2_4_3, 0xeb215000
integer extend_64_3_0_0, 0x8b216000
integer extend_64_3_0_1, 0xab216000
integer extend_64_3_0_2, 0xcb216000
integer extend_64_3_0_3, 0xeb216000
integer extend_64_3_1_0, 0x8b216400
integer extend_64_3_1_1, 0xab216400
integer extend_64_3_1_2, 0xcb216400
integer extend_64_3_1_3, 0xeb216400
integer extend_64_3_2_0, 0x8b216800
integer extend_64_3_2_1, 0xab216800
integer extend_64_3_2_2, 0xcb216800
integer extend_64_3_2_3, 0xeb216800
integer extend_64_3_3_0, 0x8b216c00
integer extend_64_3_3_1, 0xab216c00
integer extend_64_3_3_2, 0xcb216c00
integer extend_64_3_3_3, 0xeb216c00
integer extend_64_3_4_0, 0x8b217000
integer extend_64_3_4_1, 0xab217000
integer extend_64_3_4_2, 0xcb217000
integer extend_64_3_4_3, 0xeb217000
integer extend_64_4_0_0, 0x8b218000
integer extend_64_4_0_1, 0xab218000
integer extend_64_4_0_2, 0xcb218000
integer extend_64_4_0_3, 0xeb218000
integer extend_64_4_1_0, 0x8b218400
integer extend_64_4_1_1, 0xab218400
integer extend_64_4_1_2, 0xcb218400
integer extend_64_4_1_3, 0xeb218400
integer extend_64_4_2_0, 0x8b218800
integer extend_64_4_2_1, 0xab218800
integer extend_64_4_2_2, 0xcb218800
integer extend_64_4_2_3, 0xeb218800
integer extend_64_4_3_0, 0x8b218c00
integer extend_64_4_3_1, 0xab218c00
integer extend_64_4_3_2, 0xcb218c00
integer extend_64_4_3_3, 0xeb218c00
integer extend_64_4_4_0, 0x8b219000
integer extend_64_4_4_1, 0xab219000
integer extend_64_4_4_2, 0xcb219000
integer extend_64_4_4_3, 0xeb219000
integer extend_64_5_0_0, 0x8b21a000
integer extend_64_5_0_1, 0xab21a000
integer extend_64_5_0_2, 0xcb21a000
integer extend_64_5_0_3, 0xeb21a000
integer extend_64_5_1_0, 0x8b21a400
integer extend_64_5_1_1, 0xab21a400
integer extend_64_5_1_2, 0xcb21a400
integer extend_64_5_1_3, 0xeb21a400
integer extend_64_5_2_0, 0x8b21a800
integer extend_64_5_2_1, 0xab21a800
integer extend_64_5_2_2, 0xcb21a800
integer extend_64_5_2_3, 0xeb21a800
integer extend_64_5_3_0, 0x8b21ac00
integer extend_64_5_3_1, 0xab21ac00
integer extend_64_5_3_2, 0xcb21ac00
integer extend_64_5_3_3, 0xeb21ac00
integer extend_64_5_4_0, 0x8b21b000
integer extend_64_5_4_1, 0xab21b000
integer extend_64_5_4_2, 0xcb21b000
integer extend_64_5_4_3, 0xeb21b000
integer extend_64_6_0_0, 0x8b21c000
integer extend_64_6_0_1, 0xab21c000
integer extend_64_6_0_2, 0xcb21c000
integer extend_64_6_0_3, 0xeb21c000
integer extend_64_6_1_0, 0x8b21c400
integer extend_64_6_1_1, 0xab21c400
integer extend_64_6_1_2, 0xcb21c400
integer extend_64_6_1_3, 0xeb21c400
integer extend_64_6_2_0, 0x8b21c800
integer extend_64_6_2_1, 0xab21c800
integer extend_64_6_2_2, 0xcb21c800
integer extend_64_6_2_3, 0xeb21c800
integer extend_64_6_3_0, 0x8b21cc00
integer extend_64_6_3_1, 0xab21cc00
integer extend_64_6_3_2, 0xcb21cc00
integer extend_64_6_3_3, 0xeb21cc00
integer extend_64_6_4_0, 0x8b21d000
integer extend_64_6_4_1, 0xab21d000
integer extend_64_6_4_2, 0xcb21d000
integer extend_64_6_4_3, 0xeb21d000
integer extend_64_7_0_0, 0x8b21e000
integer extend_64_7_0_1, 0xab21e000
integer extend_64_7_0_2, 0xcb21e000
integer extend_64_7_0_3, 0xeb21e000
integer extend_64_7_1_0, 0x8b21e400
integer extend_64_7_1_1, 0xab21e400
integer extend_64_7_1_2, 0xcb21e400
integer extend_64_7_1_3, 0xeb21e400
integer extend_64_7_2_0, 0x8b21e800
integer extend_64_7_2_1, 0xab21e800
integer extend_64_7_2_2, 0xcb21e800
integer extend_64_7_2_3, 0xeb21e800
integer extend_64_7_3_0, 0x8b21ec00
integer extend_64_7_3_1, 0xab21ec00
integer extend_64_7_3_2, 0xcb21ec00
integer extend_64_7_3_3, 0xeb21ec00
integer extend_64_7_4_0, 0x8b21f000
integer extend_64_7_4_1, 0xab21f000
integer extend_64_7_4_2, 0xcb21f000
integer extend_64_7_4_3, 0xeb21f000
integer sub_64_0_0, 0xcb010000
integer sub_64_0_1, 0xcb010400
integer sub_64_0_63, 0xcb01fc00
integer sub_64_1_0, 0xcb410000
integer sub_64_1_1, 0xcb410400
integer sub_64_1_63, 0xcb41fc00
integer sub_64_2_0, 0xcb810000
integer sub_64_2_1, 0xcb810400
integer sub_64_2_63, 0xcb81fc00
integer multiply_64_0_4, 0x9b011000
integer multiply_64_0_31, 0x9b017c00
integer multiply_64_1_4, 0x9b019000
integer multiply_64_1_31, 0x9b01fc00
integer edge_64_zr_lhs, 0x8a0103e0
integer edge_64_zr_rhs, 0x8a1f0000
integer edge_64_zr_dest_flags, 0xea01001f
integer edge_64_select_zr, 0x9a9f07e0
integer edge_64_sub_zr, 0xcb0103e0
integer edge_64_ext_sp_lhs, 0x8b2143e0
integer edge_64_ext_sp_dest, 0x8b21401f
.globl _imm_32_and_one, _imm_32_and_one_op
_imm_32_and_one:
 mov x9, sp
 msr nzcv, x2
_imm_32_and_one_op:
 and w0, w0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_and_pattern, _imm_32_and_pattern_op
_imm_32_and_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_32_and_pattern_op:
 and w0, w0, #0xff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_and_sign, _imm_32_and_sign_op
_imm_32_and_sign:
 mov x9, sp
 msr nzcv, x2
_imm_32_and_sign_op:
 and w0, w0, #0x80000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_eor_one, _imm_32_eor_one_op
_imm_32_eor_one:
 mov x9, sp
 msr nzcv, x2
_imm_32_eor_one_op:
 eor w0, w0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_eor_pattern, _imm_32_eor_pattern_op
_imm_32_eor_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_32_eor_pattern_op:
 eor w0, w0, #0xff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_eor_sign, _imm_32_eor_sign_op
_imm_32_eor_sign:
 mov x9, sp
 msr nzcv, x2
_imm_32_eor_sign_op:
 eor w0, w0, #0x80000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_ands_one, _imm_32_ands_one_op
_imm_32_ands_one:
 mov x9, sp
 msr nzcv, x2
_imm_32_ands_one_op:
 ands w0, w0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_ands_pattern, _imm_32_ands_pattern_op
_imm_32_ands_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_32_ands_pattern_op:
 ands w0, w0, #0xff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_32_ands_sign, _imm_32_ands_sign_op
_imm_32_ands_sign:
 mov x9, sp
 msr nzcv, x2
_imm_32_ands_sign_op:
 ands w0, w0, #0x80000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_and_one, _imm_64_and_one_op
_imm_64_and_one:
 mov x9, sp
 msr nzcv, x2
_imm_64_and_one_op:
 and x0, x0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_and_pattern, _imm_64_and_pattern_op
_imm_64_and_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_64_and_pattern_op:
 and x0, x0, #0xff00ff00ff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_and_sign, _imm_64_and_sign_op
_imm_64_and_sign:
 mov x9, sp
 msr nzcv, x2
_imm_64_and_sign_op:
 and x0, x0, #0x8000000000000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_eor_one, _imm_64_eor_one_op
_imm_64_eor_one:
 mov x9, sp
 msr nzcv, x2
_imm_64_eor_one_op:
 eor x0, x0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_eor_pattern, _imm_64_eor_pattern_op
_imm_64_eor_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_64_eor_pattern_op:
 eor x0, x0, #0xff00ff00ff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_eor_sign, _imm_64_eor_sign_op
_imm_64_eor_sign:
 mov x9, sp
 msr nzcv, x2
_imm_64_eor_sign_op:
 eor x0, x0, #0x8000000000000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_ands_one, _imm_64_ands_one_op
_imm_64_ands_one:
 mov x9, sp
 msr nzcv, x2
_imm_64_ands_one_op:
 ands x0, x0, #1
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_ands_pattern, _imm_64_ands_pattern_op
_imm_64_ands_pattern:
 mov x9, sp
 msr nzcv, x2
_imm_64_ands_pattern_op:
 ands x0, x0, #0xff00ff00ff00ff00
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_64_ands_sign, _imm_64_ands_sign_op
_imm_64_ands_sign:
 mov x9, sp
 msr nzcv, x2
_imm_64_ands_sign_op:
 ands x0, x0, #0x8000000000000000
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_sp, _imm_sp_op
_imm_sp:
 mov x9, sp
 msr nzcv, x2
_imm_sp_op:
 and sp, x0, #0xff
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _imm_wsp, _imm_wsp_op
_imm_wsp:
 mov x9, sp
 msr nzcv, x2
_imm_wsp_op:
 eor wsp, w0, #0xff
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _tst_zr, _tst_zr_op
_tst_zr:
 mov x9, sp
 msr nzcv, x2
_tst_zr_op:
 ands xzr, x0, #0xff
 mov x10, sp
 mov sp, x9
 mrs x6, nzcv
 stp x6, x10, [x3]
 str x9, [x3, #16]
 ret
.globl _memory_0_1_0_unsigned_0_0, _memory_0_1_0_unsigned_0_0_op
_memory_0_1_0_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_unsigned_0_0_op:
 str b0, [x0, #2]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unsigned_0_31, _memory_0_1_0_unsigned_0_31_op
_memory_0_1_0_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_unsigned_0_31_op:
 str b31, [x0, #2]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unsigned_1_0, _memory_0_1_0_unsigned_1_0_op
_memory_0_1_0_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_unsigned_1_0_op:
 str b0, [sp, #2]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unsigned_1_31, _memory_0_1_0_unsigned_1_31_op
_memory_0_1_0_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_unsigned_1_31_op:
 str b31, [sp, #2]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unscaled_0_0, _memory_0_1_0_unscaled_0_0_op
_memory_0_1_0_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_unscaled_0_0_op:
 stur b0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unscaled_0_31, _memory_0_1_0_unscaled_0_31_op
_memory_0_1_0_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_unscaled_0_31_op:
 stur b31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unscaled_1_0, _memory_0_1_0_unscaled_1_0_op
_memory_0_1_0_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_unscaled_1_0_op:
 stur b0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_unscaled_1_31, _memory_0_1_0_unscaled_1_31_op
_memory_0_1_0_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_unscaled_1_31_op:
 stur b31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_pre_0_0, _memory_0_1_0_pre_0_0_op
_memory_0_1_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_pre_0_0_op:
 str b0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_pre_0_31, _memory_0_1_0_pre_0_31_op
_memory_0_1_0_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_pre_0_31_op:
 str b31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_pre_1_0, _memory_0_1_0_pre_1_0_op
_memory_0_1_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_pre_1_0_op:
 str b0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_pre_1_31, _memory_0_1_0_pre_1_31_op
_memory_0_1_0_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_pre_1_31_op:
 str b31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_post_0_0, _memory_0_1_0_post_0_0_op
_memory_0_1_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_post_0_0_op:
 str b0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_post_0_31, _memory_0_1_0_post_0_31_op
_memory_0_1_0_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_0_post_0_31_op:
 str b31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_post_1_0, _memory_0_1_0_post_1_0_op
_memory_0_1_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_post_1_0_op:
 str b0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_0_post_1_31, _memory_0_1_0_post_1_31_op
_memory_0_1_0_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_0_post_1_31_op:
 str b31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unsigned_0_0, _memory_0_1_1_unsigned_0_0_op
_memory_0_1_1_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_unsigned_0_0_op:
 ldr b0, [x0, #2]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unsigned_0_31, _memory_0_1_1_unsigned_0_31_op
_memory_0_1_1_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_unsigned_0_31_op:
 ldr b31, [x0, #2]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unsigned_1_0, _memory_0_1_1_unsigned_1_0_op
_memory_0_1_1_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_unsigned_1_0_op:
 ldr b0, [sp, #2]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unsigned_1_31, _memory_0_1_1_unsigned_1_31_op
_memory_0_1_1_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_unsigned_1_31_op:
 ldr b31, [sp, #2]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unscaled_0_0, _memory_0_1_1_unscaled_0_0_op
_memory_0_1_1_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_unscaled_0_0_op:
 ldur b0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unscaled_0_31, _memory_0_1_1_unscaled_0_31_op
_memory_0_1_1_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_unscaled_0_31_op:
 ldur b31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unscaled_1_0, _memory_0_1_1_unscaled_1_0_op
_memory_0_1_1_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_unscaled_1_0_op:
 ldur b0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_unscaled_1_31, _memory_0_1_1_unscaled_1_31_op
_memory_0_1_1_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_unscaled_1_31_op:
 ldur b31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_pre_0_0, _memory_0_1_1_pre_0_0_op
_memory_0_1_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_pre_0_0_op:
 ldr b0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_pre_0_31, _memory_0_1_1_pre_0_31_op
_memory_0_1_1_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_pre_0_31_op:
 ldr b31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_pre_1_0, _memory_0_1_1_pre_1_0_op
_memory_0_1_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_pre_1_0_op:
 ldr b0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_pre_1_31, _memory_0_1_1_pre_1_31_op
_memory_0_1_1_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_pre_1_31_op:
 ldr b31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_post_0_0, _memory_0_1_1_post_0_0_op
_memory_0_1_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_post_0_0_op:
 ldr b0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_post_0_31, _memory_0_1_1_post_0_31_op
_memory_0_1_1_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_1_1_post_0_31_op:
 ldr b31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_post_1_0, _memory_0_1_1_post_1_0_op
_memory_0_1_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_post_1_0_op:
 ldr b0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_1_1_post_1_31, _memory_0_1_1_post_1_31_op
_memory_0_1_1_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_1_1_post_1_31_op:
 ldr b31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unsigned_0_0, _memory_0_2_0_unsigned_0_0_op
_memory_0_2_0_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_unsigned_0_0_op:
 str h0, [x0, #4]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unsigned_0_31, _memory_0_2_0_unsigned_0_31_op
_memory_0_2_0_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_unsigned_0_31_op:
 str h31, [x0, #4]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unsigned_1_0, _memory_0_2_0_unsigned_1_0_op
_memory_0_2_0_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_unsigned_1_0_op:
 str h0, [sp, #4]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unsigned_1_31, _memory_0_2_0_unsigned_1_31_op
_memory_0_2_0_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_unsigned_1_31_op:
 str h31, [sp, #4]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unscaled_0_0, _memory_0_2_0_unscaled_0_0_op
_memory_0_2_0_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_unscaled_0_0_op:
 stur h0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unscaled_0_31, _memory_0_2_0_unscaled_0_31_op
_memory_0_2_0_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_unscaled_0_31_op:
 stur h31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unscaled_1_0, _memory_0_2_0_unscaled_1_0_op
_memory_0_2_0_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_unscaled_1_0_op:
 stur h0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_unscaled_1_31, _memory_0_2_0_unscaled_1_31_op
_memory_0_2_0_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_unscaled_1_31_op:
 stur h31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_pre_0_0, _memory_0_2_0_pre_0_0_op
_memory_0_2_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_pre_0_0_op:
 str h0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_pre_0_31, _memory_0_2_0_pre_0_31_op
_memory_0_2_0_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_pre_0_31_op:
 str h31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_pre_1_0, _memory_0_2_0_pre_1_0_op
_memory_0_2_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_pre_1_0_op:
 str h0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_pre_1_31, _memory_0_2_0_pre_1_31_op
_memory_0_2_0_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_pre_1_31_op:
 str h31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_post_0_0, _memory_0_2_0_post_0_0_op
_memory_0_2_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_post_0_0_op:
 str h0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_post_0_31, _memory_0_2_0_post_0_31_op
_memory_0_2_0_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_0_post_0_31_op:
 str h31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_post_1_0, _memory_0_2_0_post_1_0_op
_memory_0_2_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_post_1_0_op:
 str h0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_0_post_1_31, _memory_0_2_0_post_1_31_op
_memory_0_2_0_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_0_post_1_31_op:
 str h31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unsigned_0_0, _memory_0_2_1_unsigned_0_0_op
_memory_0_2_1_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_unsigned_0_0_op:
 ldr h0, [x0, #4]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unsigned_0_31, _memory_0_2_1_unsigned_0_31_op
_memory_0_2_1_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_unsigned_0_31_op:
 ldr h31, [x0, #4]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unsigned_1_0, _memory_0_2_1_unsigned_1_0_op
_memory_0_2_1_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_unsigned_1_0_op:
 ldr h0, [sp, #4]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unsigned_1_31, _memory_0_2_1_unsigned_1_31_op
_memory_0_2_1_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_unsigned_1_31_op:
 ldr h31, [sp, #4]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unscaled_0_0, _memory_0_2_1_unscaled_0_0_op
_memory_0_2_1_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_unscaled_0_0_op:
 ldur h0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unscaled_0_31, _memory_0_2_1_unscaled_0_31_op
_memory_0_2_1_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_unscaled_0_31_op:
 ldur h31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unscaled_1_0, _memory_0_2_1_unscaled_1_0_op
_memory_0_2_1_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_unscaled_1_0_op:
 ldur h0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_unscaled_1_31, _memory_0_2_1_unscaled_1_31_op
_memory_0_2_1_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_unscaled_1_31_op:
 ldur h31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_pre_0_0, _memory_0_2_1_pre_0_0_op
_memory_0_2_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_pre_0_0_op:
 ldr h0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_pre_0_31, _memory_0_2_1_pre_0_31_op
_memory_0_2_1_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_pre_0_31_op:
 ldr h31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_pre_1_0, _memory_0_2_1_pre_1_0_op
_memory_0_2_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_pre_1_0_op:
 ldr h0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_pre_1_31, _memory_0_2_1_pre_1_31_op
_memory_0_2_1_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_pre_1_31_op:
 ldr h31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_post_0_0, _memory_0_2_1_post_0_0_op
_memory_0_2_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_post_0_0_op:
 ldr h0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_post_0_31, _memory_0_2_1_post_0_31_op
_memory_0_2_1_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_2_1_post_0_31_op:
 ldr h31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_post_1_0, _memory_0_2_1_post_1_0_op
_memory_0_2_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_post_1_0_op:
 ldr h0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_2_1_post_1_31, _memory_0_2_1_post_1_31_op
_memory_0_2_1_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_2_1_post_1_31_op:
 ldr h31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unsigned_0_0, _memory_0_4_0_unsigned_0_0_op
_memory_0_4_0_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_unsigned_0_0_op:
 str s0, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unsigned_0_31, _memory_0_4_0_unsigned_0_31_op
_memory_0_4_0_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_unsigned_0_31_op:
 str s31, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unsigned_1_0, _memory_0_4_0_unsigned_1_0_op
_memory_0_4_0_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_unsigned_1_0_op:
 str s0, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unsigned_1_31, _memory_0_4_0_unsigned_1_31_op
_memory_0_4_0_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_unsigned_1_31_op:
 str s31, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unscaled_0_0, _memory_0_4_0_unscaled_0_0_op
_memory_0_4_0_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_unscaled_0_0_op:
 stur s0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unscaled_0_31, _memory_0_4_0_unscaled_0_31_op
_memory_0_4_0_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_unscaled_0_31_op:
 stur s31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unscaled_1_0, _memory_0_4_0_unscaled_1_0_op
_memory_0_4_0_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_unscaled_1_0_op:
 stur s0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_unscaled_1_31, _memory_0_4_0_unscaled_1_31_op
_memory_0_4_0_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_unscaled_1_31_op:
 stur s31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_pre_0_0, _memory_0_4_0_pre_0_0_op
_memory_0_4_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_pre_0_0_op:
 str s0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_pre_0_31, _memory_0_4_0_pre_0_31_op
_memory_0_4_0_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_pre_0_31_op:
 str s31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_pre_1_0, _memory_0_4_0_pre_1_0_op
_memory_0_4_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_pre_1_0_op:
 str s0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_pre_1_31, _memory_0_4_0_pre_1_31_op
_memory_0_4_0_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_pre_1_31_op:
 str s31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_post_0_0, _memory_0_4_0_post_0_0_op
_memory_0_4_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_post_0_0_op:
 str s0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_post_0_31, _memory_0_4_0_post_0_31_op
_memory_0_4_0_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_0_post_0_31_op:
 str s31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_post_1_0, _memory_0_4_0_post_1_0_op
_memory_0_4_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_post_1_0_op:
 str s0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_0_post_1_31, _memory_0_4_0_post_1_31_op
_memory_0_4_0_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_0_post_1_31_op:
 str s31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unsigned_0_0, _memory_0_4_1_unsigned_0_0_op
_memory_0_4_1_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_unsigned_0_0_op:
 ldr s0, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unsigned_0_31, _memory_0_4_1_unsigned_0_31_op
_memory_0_4_1_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_unsigned_0_31_op:
 ldr s31, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unsigned_1_0, _memory_0_4_1_unsigned_1_0_op
_memory_0_4_1_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_unsigned_1_0_op:
 ldr s0, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unsigned_1_31, _memory_0_4_1_unsigned_1_31_op
_memory_0_4_1_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_unsigned_1_31_op:
 ldr s31, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unscaled_0_0, _memory_0_4_1_unscaled_0_0_op
_memory_0_4_1_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_unscaled_0_0_op:
 ldur s0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unscaled_0_31, _memory_0_4_1_unscaled_0_31_op
_memory_0_4_1_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_unscaled_0_31_op:
 ldur s31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unscaled_1_0, _memory_0_4_1_unscaled_1_0_op
_memory_0_4_1_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_unscaled_1_0_op:
 ldur s0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_unscaled_1_31, _memory_0_4_1_unscaled_1_31_op
_memory_0_4_1_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_unscaled_1_31_op:
 ldur s31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_pre_0_0, _memory_0_4_1_pre_0_0_op
_memory_0_4_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_pre_0_0_op:
 ldr s0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_pre_0_31, _memory_0_4_1_pre_0_31_op
_memory_0_4_1_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_pre_0_31_op:
 ldr s31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_pre_1_0, _memory_0_4_1_pre_1_0_op
_memory_0_4_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_pre_1_0_op:
 ldr s0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_pre_1_31, _memory_0_4_1_pre_1_31_op
_memory_0_4_1_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_pre_1_31_op:
 ldr s31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_post_0_0, _memory_0_4_1_post_0_0_op
_memory_0_4_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_post_0_0_op:
 ldr s0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_post_0_31, _memory_0_4_1_post_0_31_op
_memory_0_4_1_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_4_1_post_0_31_op:
 ldr s31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_post_1_0, _memory_0_4_1_post_1_0_op
_memory_0_4_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_post_1_0_op:
 ldr s0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_4_1_post_1_31, _memory_0_4_1_post_1_31_op
_memory_0_4_1_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_4_1_post_1_31_op:
 ldr s31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unsigned_0_0, _memory_0_8_0_unsigned_0_0_op
_memory_0_8_0_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_unsigned_0_0_op:
 str d0, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unsigned_0_31, _memory_0_8_0_unsigned_0_31_op
_memory_0_8_0_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_unsigned_0_31_op:
 str d31, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unsigned_1_0, _memory_0_8_0_unsigned_1_0_op
_memory_0_8_0_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_unsigned_1_0_op:
 str d0, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unsigned_1_31, _memory_0_8_0_unsigned_1_31_op
_memory_0_8_0_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_unsigned_1_31_op:
 str d31, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unscaled_0_0, _memory_0_8_0_unscaled_0_0_op
_memory_0_8_0_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_unscaled_0_0_op:
 stur d0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unscaled_0_31, _memory_0_8_0_unscaled_0_31_op
_memory_0_8_0_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_unscaled_0_31_op:
 stur d31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unscaled_1_0, _memory_0_8_0_unscaled_1_0_op
_memory_0_8_0_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_unscaled_1_0_op:
 stur d0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_unscaled_1_31, _memory_0_8_0_unscaled_1_31_op
_memory_0_8_0_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_unscaled_1_31_op:
 stur d31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_pre_0_0, _memory_0_8_0_pre_0_0_op
_memory_0_8_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_pre_0_0_op:
 str d0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_pre_0_31, _memory_0_8_0_pre_0_31_op
_memory_0_8_0_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_pre_0_31_op:
 str d31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_pre_1_0, _memory_0_8_0_pre_1_0_op
_memory_0_8_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_pre_1_0_op:
 str d0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_pre_1_31, _memory_0_8_0_pre_1_31_op
_memory_0_8_0_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_pre_1_31_op:
 str d31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_post_0_0, _memory_0_8_0_post_0_0_op
_memory_0_8_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_post_0_0_op:
 str d0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_post_0_31, _memory_0_8_0_post_0_31_op
_memory_0_8_0_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_0_post_0_31_op:
 str d31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_post_1_0, _memory_0_8_0_post_1_0_op
_memory_0_8_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_post_1_0_op:
 str d0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_0_post_1_31, _memory_0_8_0_post_1_31_op
_memory_0_8_0_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_0_post_1_31_op:
 str d31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unsigned_0_0, _memory_0_8_1_unsigned_0_0_op
_memory_0_8_1_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_unsigned_0_0_op:
 ldr d0, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unsigned_0_31, _memory_0_8_1_unsigned_0_31_op
_memory_0_8_1_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_unsigned_0_31_op:
 ldr d31, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unsigned_1_0, _memory_0_8_1_unsigned_1_0_op
_memory_0_8_1_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_unsigned_1_0_op:
 ldr d0, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unsigned_1_31, _memory_0_8_1_unsigned_1_31_op
_memory_0_8_1_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_unsigned_1_31_op:
 ldr d31, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unscaled_0_0, _memory_0_8_1_unscaled_0_0_op
_memory_0_8_1_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_unscaled_0_0_op:
 ldur d0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unscaled_0_31, _memory_0_8_1_unscaled_0_31_op
_memory_0_8_1_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_unscaled_0_31_op:
 ldur d31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unscaled_1_0, _memory_0_8_1_unscaled_1_0_op
_memory_0_8_1_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_unscaled_1_0_op:
 ldur d0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_unscaled_1_31, _memory_0_8_1_unscaled_1_31_op
_memory_0_8_1_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_unscaled_1_31_op:
 ldur d31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_pre_0_0, _memory_0_8_1_pre_0_0_op
_memory_0_8_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_pre_0_0_op:
 ldr d0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_pre_0_31, _memory_0_8_1_pre_0_31_op
_memory_0_8_1_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_pre_0_31_op:
 ldr d31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_pre_1_0, _memory_0_8_1_pre_1_0_op
_memory_0_8_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_pre_1_0_op:
 ldr d0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_pre_1_31, _memory_0_8_1_pre_1_31_op
_memory_0_8_1_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_pre_1_31_op:
 ldr d31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_post_0_0, _memory_0_8_1_post_0_0_op
_memory_0_8_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_post_0_0_op:
 ldr d0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_post_0_31, _memory_0_8_1_post_0_31_op
_memory_0_8_1_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_8_1_post_0_31_op:
 ldr d31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_post_1_0, _memory_0_8_1_post_1_0_op
_memory_0_8_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_post_1_0_op:
 ldr d0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_8_1_post_1_31, _memory_0_8_1_post_1_31_op
_memory_0_8_1_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_8_1_post_1_31_op:
 ldr d31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unsigned_0_0, _memory_0_16_0_unsigned_0_0_op
_memory_0_16_0_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_unsigned_0_0_op:
 str q0, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unsigned_0_31, _memory_0_16_0_unsigned_0_31_op
_memory_0_16_0_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_unsigned_0_31_op:
 str q31, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unsigned_1_0, _memory_0_16_0_unsigned_1_0_op
_memory_0_16_0_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_unsigned_1_0_op:
 str q0, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unsigned_1_31, _memory_0_16_0_unsigned_1_31_op
_memory_0_16_0_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_unsigned_1_31_op:
 str q31, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unscaled_0_0, _memory_0_16_0_unscaled_0_0_op
_memory_0_16_0_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_unscaled_0_0_op:
 stur q0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unscaled_0_31, _memory_0_16_0_unscaled_0_31_op
_memory_0_16_0_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_unscaled_0_31_op:
 stur q31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unscaled_1_0, _memory_0_16_0_unscaled_1_0_op
_memory_0_16_0_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_unscaled_1_0_op:
 stur q0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_unscaled_1_31, _memory_0_16_0_unscaled_1_31_op
_memory_0_16_0_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_unscaled_1_31_op:
 stur q31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_pre_0_0, _memory_0_16_0_pre_0_0_op
_memory_0_16_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_pre_0_0_op:
 str q0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_pre_0_31, _memory_0_16_0_pre_0_31_op
_memory_0_16_0_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_pre_0_31_op:
 str q31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_pre_1_0, _memory_0_16_0_pre_1_0_op
_memory_0_16_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_pre_1_0_op:
 str q0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_pre_1_31, _memory_0_16_0_pre_1_31_op
_memory_0_16_0_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_pre_1_31_op:
 str q31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_post_0_0, _memory_0_16_0_post_0_0_op
_memory_0_16_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_post_0_0_op:
 str q0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_post_0_31, _memory_0_16_0_post_0_31_op
_memory_0_16_0_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_0_post_0_31_op:
 str q31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_post_1_0, _memory_0_16_0_post_1_0_op
_memory_0_16_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_post_1_0_op:
 str q0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_0_post_1_31, _memory_0_16_0_post_1_31_op
_memory_0_16_0_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_0_post_1_31_op:
 str q31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unsigned_0_0, _memory_0_16_1_unsigned_0_0_op
_memory_0_16_1_unsigned_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_unsigned_0_0_op:
 ldr q0, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unsigned_0_31, _memory_0_16_1_unsigned_0_31_op
_memory_0_16_1_unsigned_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_unsigned_0_31_op:
 ldr q31, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unsigned_1_0, _memory_0_16_1_unsigned_1_0_op
_memory_0_16_1_unsigned_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_unsigned_1_0_op:
 ldr q0, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unsigned_1_31, _memory_0_16_1_unsigned_1_31_op
_memory_0_16_1_unsigned_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_unsigned_1_31_op:
 ldr q31, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unscaled_0_0, _memory_0_16_1_unscaled_0_0_op
_memory_0_16_1_unscaled_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_unscaled_0_0_op:
 ldur q0, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unscaled_0_31, _memory_0_16_1_unscaled_0_31_op
_memory_0_16_1_unscaled_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_unscaled_0_31_op:
 ldur q31, [x0, #-7]
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unscaled_1_0, _memory_0_16_1_unscaled_1_0_op
_memory_0_16_1_unscaled_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_unscaled_1_0_op:
 ldur q0, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_unscaled_1_31, _memory_0_16_1_unscaled_1_31_op
_memory_0_16_1_unscaled_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_unscaled_1_31_op:
 ldur q31, [sp, #-7]
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_pre_0_0, _memory_0_16_1_pre_0_0_op
_memory_0_16_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_pre_0_0_op:
 ldr q0, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_pre_0_31, _memory_0_16_1_pre_0_31_op
_memory_0_16_1_pre_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_pre_0_31_op:
 ldr q31, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_pre_1_0, _memory_0_16_1_pre_1_0_op
_memory_0_16_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_pre_1_0_op:
 ldr q0, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_pre_1_31, _memory_0_16_1_pre_1_31_op
_memory_0_16_1_pre_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_pre_1_31_op:
 ldr q31, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_post_0_0, _memory_0_16_1_post_0_0_op
_memory_0_16_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_post_0_0_op:
 ldr q0, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_post_0_31, _memory_0_16_1_post_0_31_op
_memory_0_16_1_post_0_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_0_16_1_post_0_31_op:
 ldr q31, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_post_1_0, _memory_0_16_1_post_1_0_op
_memory_0_16_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_post_1_0_op:
 ldr q0, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_0_16_1_post_1_31, _memory_0_16_1_post_1_31_op
_memory_0_16_1_post_1_31:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_0_16_1_post_1_31_op:
 ldr q31, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q31, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_offset_0_0, _memory_1_4_0_offset_0_0_op
_memory_1_4_0_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_0_offset_0_0_op:
 stp s0, s1, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_offset_1_0, _memory_1_4_0_offset_1_0_op
_memory_1_4_0_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_0_offset_1_0_op:
 stp s0, s1, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_pre_0_0, _memory_1_4_0_pre_0_0_op
_memory_1_4_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_0_pre_0_0_op:
 stp s0, s1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_pre_1_0, _memory_1_4_0_pre_1_0_op
_memory_1_4_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_0_pre_1_0_op:
 stp s0, s1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_post_0_0, _memory_1_4_0_post_0_0_op
_memory_1_4_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_0_post_0_0_op:
 stp s0, s1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_0_post_1_0, _memory_1_4_0_post_1_0_op
_memory_1_4_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_0_post_1_0_op:
 stp s0, s1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_offset_0_0, _memory_1_4_1_offset_0_0_op
_memory_1_4_1_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_1_offset_0_0_op:
 ldp s0, s1, [x0, #8]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_offset_1_0, _memory_1_4_1_offset_1_0_op
_memory_1_4_1_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_1_offset_1_0_op:
 ldp s0, s1, [sp, #8]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_pre_0_0, _memory_1_4_1_pre_0_0_op
_memory_1_4_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_1_pre_0_0_op:
 ldp s0, s1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_pre_1_0, _memory_1_4_1_pre_1_0_op
_memory_1_4_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_1_pre_1_0_op:
 ldp s0, s1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_post_0_0, _memory_1_4_1_post_0_0_op
_memory_1_4_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_4_1_post_0_0_op:
 ldp s0, s1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_4_1_post_1_0, _memory_1_4_1_post_1_0_op
_memory_1_4_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_4_1_post_1_0_op:
 ldp s0, s1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_offset_0_0, _memory_1_8_0_offset_0_0_op
_memory_1_8_0_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_0_offset_0_0_op:
 stp d0, d1, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_offset_1_0, _memory_1_8_0_offset_1_0_op
_memory_1_8_0_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_0_offset_1_0_op:
 stp d0, d1, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_pre_0_0, _memory_1_8_0_pre_0_0_op
_memory_1_8_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_0_pre_0_0_op:
 stp d0, d1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_pre_1_0, _memory_1_8_0_pre_1_0_op
_memory_1_8_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_0_pre_1_0_op:
 stp d0, d1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_post_0_0, _memory_1_8_0_post_0_0_op
_memory_1_8_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_0_post_0_0_op:
 stp d0, d1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_0_post_1_0, _memory_1_8_0_post_1_0_op
_memory_1_8_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_0_post_1_0_op:
 stp d0, d1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_offset_0_0, _memory_1_8_1_offset_0_0_op
_memory_1_8_1_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_1_offset_0_0_op:
 ldp d0, d1, [x0, #16]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_offset_1_0, _memory_1_8_1_offset_1_0_op
_memory_1_8_1_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_1_offset_1_0_op:
 ldp d0, d1, [sp, #16]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_pre_0_0, _memory_1_8_1_pre_0_0_op
_memory_1_8_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_1_pre_0_0_op:
 ldp d0, d1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_pre_1_0, _memory_1_8_1_pre_1_0_op
_memory_1_8_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_1_pre_1_0_op:
 ldp d0, d1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_post_0_0, _memory_1_8_1_post_0_0_op
_memory_1_8_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_8_1_post_0_0_op:
 ldp d0, d1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_8_1_post_1_0, _memory_1_8_1_post_1_0_op
_memory_1_8_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_8_1_post_1_0_op:
 ldp d0, d1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_offset_0_0, _memory_1_16_0_offset_0_0_op
_memory_1_16_0_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_0_offset_0_0_op:
 stp q0, q1, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_offset_1_0, _memory_1_16_0_offset_1_0_op
_memory_1_16_0_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_0_offset_1_0_op:
 stp q0, q1, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_pre_0_0, _memory_1_16_0_pre_0_0_op
_memory_1_16_0_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_0_pre_0_0_op:
 stp q0, q1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_pre_1_0, _memory_1_16_0_pre_1_0_op
_memory_1_16_0_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_0_pre_1_0_op:
 stp q0, q1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_post_0_0, _memory_1_16_0_post_0_0_op
_memory_1_16_0_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_0_post_0_0_op:
 stp q0, q1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_0_post_1_0, _memory_1_16_0_post_1_0_op
_memory_1_16_0_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_0_post_1_0_op:
 stp q0, q1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_offset_0_0, _memory_1_16_1_offset_0_0_op
_memory_1_16_1_offset_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_1_offset_0_0_op:
 ldp q0, q1, [x0, #32]
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_offset_1_0, _memory_1_16_1_offset_1_0_op
_memory_1_16_1_offset_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_1_offset_1_0_op:
 ldp q0, q1, [sp, #32]
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_pre_0_0, _memory_1_16_1_pre_0_0_op
_memory_1_16_1_pre_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_1_pre_0_0_op:
 ldp q0, q1, [x0, #-16]!
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_pre_1_0, _memory_1_16_1_pre_1_0_op
_memory_1_16_1_pre_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_1_pre_1_0_op:
 ldp q0, q1, [sp, #-16]!
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_post_0_0, _memory_1_16_1_post_0_0_op
_memory_1_16_1_post_0_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
_memory_1_16_1_post_0_0_op:
 ldp q0, q1, [x0], #16
 mov x10, x0
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
.globl _memory_1_16_1_post_1_0, _memory_1_16_1_post_1_0_op
_memory_1_16_1_post_1_0:
 mov x9, sp
 ldp q0, q1, [x1]
 mov v31.16b, v0.16b
 msr nzcv, x2
 mov sp, x0
_memory_1_16_1_post_1_0_op:
 ldp q0, q1, [sp], #16
 mov x10, sp
 mov sp, x9
 stp q0, q1, [x1]
 mrs x6, nzcv
 stp x6, x10, [x3]
 ret
