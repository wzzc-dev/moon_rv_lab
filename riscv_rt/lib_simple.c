// Simple runtime library using direct Linux syscalls
// No libc dependency

#include <stdint.h>

// RISC-V Linux syscall numbers
#define SYS_write 64
#define SYS_read 63
#define SYS_exit 93
#define SYS_brk 214

// Inline syscall helper for RISC-V
static inline long syscall1(long num, long arg0) {
    register long a7 __asm__("a7") = num;
    register long a0 __asm__("a0") = arg0;
    __asm__ volatile ("ecall" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}

static inline long syscall3(long num, long arg0, long arg1, long arg2) {
    register long a7 __asm__("a7") = num;
    register long a0 __asm__("a0") = arg0;
    register long a1 __asm__("a1") = arg1;
    register long a2 __asm__("a2") = arg2;
    __asm__ volatile ("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2) : "memory");
    return a0;
}

// Simple integer print
void minimbt_print_int(int value) {
    char buffer[16];
    int i = 15;
    int neg = 0;
    
    if (value < 0) {
        neg = 1;
        value = -value;
    }
    
    if (value == 0) {
        buffer[i--] = '0';
    } else {
        while (value > 0) {
            buffer[i--] = '0' + (value % 10);
            value /= 10;
        }
    }
    
    if (neg) {
        buffer[i--] = '-';
    }
    
    syscall3(SYS_write, 1, (long)(buffer + i + 1), 15 - i);
}

// Print newline
void minimbt_print_endline(void) {
    char c = '\n';
    syscall3(SYS_write, 1, (long)&c, 1);
}

// Print a single character
void minimbt_print_char(char c) {
    syscall3(SYS_write, 1, (long)&c, 1);
}

// Read integer (simple implementation)
int minimbt_read_int(void) {
    char buffer[16];
    int len = syscall3(SYS_read, 0, (long)buffer, 15);
    if (len <= 0) return 0;
    buffer[len] = 0;
    
    int value = 0;
    int neg = 0;
    int i = 0;
    
    if (buffer[0] == '-') {
        neg = 1;
        i = 1;
    }
    
    while (i < len && buffer[i] >= '0' && buffer[i] <= '9') {
        value = value * 10 + (buffer[i] - '0');
        i++;
    }
    
    return neg ? -value : value;
}

// Read character
char minimbt_read_char(void) {
    char c = 0;
    syscall3(SYS_read, 0, (long)&c, 1);
    return c;
}

// Simple heap allocator
static char *heap_ptr = 0;

void* minimbt_alloc(int size) {
    if (heap_ptr == 0) {
        heap_ptr = (char*)syscall1(SYS_brk, 0);
    }
    char *result = heap_ptr;
    heap_ptr += size;
    // Align to 8 bytes
    heap_ptr = (char*)(((long)heap_ptr + 7) & ~7);
    syscall1(SYS_brk, (long)heap_ptr);
    return result;
}

void minimbt_free(void* ptr) {
    // Simple allocator doesn't free
}
