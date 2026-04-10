# Rich demo for workbench / trace / CFG
# Covers stack frames, loops, calls, branches and memory writes.

_start:
    addi sp, sp, -48
    sw   ra, 44(sp)
    sw   s0, 40(sp)
    sw   s1, 36(sp)
    sw   s2, 32(sp)
    sw   s3, 28(sp)

    li   a0, 6
    jal  ra, 104
    mv   s0, a0

    li   a0, 5
    li   a1, 3
    jal  ra, 152
    mv   s1, a0

    add  s2, s0, s1
    sw   s0, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    lw   a0, 8(sp)

    li   t0, 40
    blt  a0, t0, 12
    li   s3, 1
    jal  x0, 8

below_threshold:
    li   s3, -1

finalize:
    mv   a1, s0
    mv   a2, s1
    mv   a3, s3
    lw   ra, 44(sp)
    lw   s0, 40(sp)
    lw   s1, 36(sp)
    lw   s2, 32(sp)
    lw   s3, 28(sp)
    addi sp, sp, 48
    ebreak

sum_to_n:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    mv   s0, a0
    li   s1, 0

sum_loop:
    beq  s0, x0, 16
    add  s1, s1, s0
    addi s0, s0, -1
    jal  x0, -12

sum_done:
    mv   a0, s1
    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    addi sp, sp, 16
    ret

mix_pair:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    mv   s0, a0
    mv   s1, a1

    add  t0, s0, s1
    slli t1, s1, 1
    add  t0, t0, t1
    andi t2, t0, 1
    beq  t2, x0, 12
    addi t0, t0, 5
    jal  x0, 8

mix_even:
    addi t0, t0, 2

mix_done:
    mv   a0, t0
    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    addi sp, sp, 16
    ret
