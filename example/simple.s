# Simple RISC-V assembly example for rvkit asm
# Basic instructions only

_start:
    addi a0, x0, 42
    addi a1, a0, 10
    add  a2, a0, a1
    sub  a3, a1, a0
    andi a4, a0, 0xFF
    ori  a5, a0, 0x100
    xori a6, a0, 0xFF
    slli a7, a0, 2
    srli s0, a0, 1
    lui  t0, 0x12345
    slti t1, a0, 100
    ebreak