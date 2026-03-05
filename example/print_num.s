# Print number 42 using write syscall
# RV32 Linux syscall: write(64) fd=a0, buf=a1, count=a2

_start:
    # Store the number "42" as string in stack
    addi sp, sp, -16
    
    # Convert 42 to string "42\n"
    li t0, 42           # Number to print
    li t1, 10           # Divisor
    li t2, 0            # Digit count
    
    # Get digits (reversed)
    addi t3, sp, 14     # Buffer end
    sb zero, 0(t3)      # Null terminator
    
convert_loop:
    remu t4, t0, t1     # t4 = t0 % 10 (digit)
    divu t0, t0, t1     # t0 = t0 / 10
    addi t4, t4, 48     # Convert to ASCII
    addi t3, t3, -1
    sb t4, 0(t3)        # Store digit
    addi t2, t2, 1      # Count++
    bnez t0, convert_loop
    
    # Calculate string length and address
    mv a1, t3           # buf = string start
    mv a2, t2           # count = length
    
    # syscall write(1, buf, count)
    li a0, 1            # fd = stdout
    li a7, 64           # syscall number for write
    ecall
    
    # syscall exit(0)
    li a0, 0            # exit code
    li a7, 93           # syscall number for exit
    ecall
