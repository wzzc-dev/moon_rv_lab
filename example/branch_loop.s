# Branch and loop sample

_start:
    addi a0, x0, 0
    addi a1, x0, 4

loop:
    addi a0, a0, 3
    addi a1, a1, -1
    bne  a1, x0, loop
    ebreak
