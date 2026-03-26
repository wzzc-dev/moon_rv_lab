# brk/ioctl demo

_start:
    li a0, 0
    li a7, 214
    ecall

    addi s0, a0, 64
    mv a0, s0
    li a7, 214
    ecall

    li a0, 1
    li a1, 0
    li a2, 0
    li a7, 29
    ecall

    li a0, 0
    li a7, 93
    ecall
