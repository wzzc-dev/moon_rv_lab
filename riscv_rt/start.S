# RISC-V startup code
.section .text
.global _start
.type _start, @function

_start:
    # Set up stack pointer (use high memory)
    lui sp, 0x80000     # sp = 0x80000000
    
    # Call main
    call main
    
    # Exit with return value from main
    li a7, 93        # SYS_exit
    ecall

    # Should not reach here
    j .

.size _start, . - _start
