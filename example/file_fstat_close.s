# File fstat demo

_start:
    addi sp, sp, -192
    addi s0, sp, 0
    addi s1, sp, 32

    li t0, 101
    sb t0, 0(s0)
    li t0, 120
    sb t0, 1(s0)
    li t0, 97
    sb t0, 2(s0)
    li t0, 109
    sb t0, 3(s0)
    li t0, 112
    sb t0, 4(s0)
    li t0, 108
    sb t0, 5(s0)
    li t0, 101
    sb t0, 6(s0)
    li t0, 47
    sb t0, 7(s0)
    li t0, 105
    sb t0, 8(s0)
    li t0, 111
    sb t0, 9(s0)
    li t0, 46
    sb t0, 10(s0)
    li t0, 116
    sb t0, 11(s0)
    li t0, 120
    sb t0, 12(s0)
    li t0, 116
    sb t0, 13(s0)
    sb x0, 14(s0)

    li a0, 0
    mv a1, s0
    li a2, 0
    li a3, 0
    li a7, 56
    ecall

    mv s2, a0
    mv a0, s2
    mv a1, s1
    li a2, 0
    li a7, 80
    ecall

    mv a0, s2
    li a7, 57
    ecall

    li a0, 0
    li a7, 93
    ecall
