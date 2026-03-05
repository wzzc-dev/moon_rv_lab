# Print "42\n" using write syscall
# RV32 Linux syscall: write(64) fd=a0, buf=a1, count=a2

_start:
    # Store "42\n" on stack
    addi sp, sp, -8
    
    li t0, 52           # '4' = 0x34 = 52
    sb t0, 0(sp)
    li t0, 50           # '2' = 0x32 = 50  
    sb t0, 1(sp)
    li t0, 10           # '\n'
    sb t0, 2(sp)
    
    # syscall write(1, sp, 3)
    mv a1, sp           # buf
    li a0, 1            # fd = stdout
    li a2, 3            # count
    li a7, 64           # syscall: write
    ecall
    
    # syscall exit(0)
    li a0, 0
    li a7, 93           # syscall: exit
    ecall
