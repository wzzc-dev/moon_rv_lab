# Function call sample

_start:
    addi a0, x0, 5
    jal  ra, double_value
    addi a1, a0, 3
    ebreak

double_value:
    add  a0, a0, a0
    jalr x0, 0(ra)
