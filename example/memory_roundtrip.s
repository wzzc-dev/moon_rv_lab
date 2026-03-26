# Stack memory roundtrip sample

_start:
    addi sp, sp, -16
    li   t0, 7
    sw   t0, 0(sp)
    lw   a0, 0(sp)
    addi a1, a0, 5
    ebreak
