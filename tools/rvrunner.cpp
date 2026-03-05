#include <libriscv/machine.hpp>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <iostream>
#include <cstring>
#include <unistd.h>

// Load raw binary file
std::vector<uint8_t> load_file(const char* filename) {
    std::ifstream file(filename, std::ios::binary | std::ios::ate);
    if (!file) {
        fprintf(stderr, "Error: Cannot open file %s\n", filename);
        exit(1);
    }
    size_t size = file.tellg();
    file.seekg(0, std::ios::beg);
    std::vector<uint8_t> buffer(size);
    if (!file.read(reinterpret_cast<char*>(buffer.data()), size)) {
        fprintf(stderr, "Error: Cannot read file %s\n", filename);
        exit(1);
    }
    return buffer;
}

// Check if file is ELF and determine if 32-bit or 64-bit
bool is_elf64(const std::vector<uint8_t>& data) {
    if (data.size() < 52) return false;
    if (data[0] != 0x7f || data[1] != 'E' || data[2] != 'L' || data[3] != 'F') {
        return false;
    }
    return data[4] == 2; // ELFCLASS64
}

// Setup Linux-like syscalls for RV64
void setup_linux_syscalls_64() {
    using Machine = riscv::Machine<riscv::RISCV64>;
    
    // write syscall (64)
    Machine::install_syscall_handler(64, [](Machine& machine) {
        auto [fd, buf, count] = machine.sysargs<uint64_t, uint64_t, uint64_t>();
        
        std::vector<uint8_t> data(count);
        machine.memory.memcpy_out(data.data(), buf, count);
        
        ssize_t written = 0;
        if (fd == 1 || fd == 2) { // stdout or stderr
            written = write(fd, data.data(), count);
        }
        machine.set_result(written);
    });
    
    // read syscall (63)
    Machine::install_syscall_handler(63, [](Machine& machine) {
        auto [fd, buf, count] = machine.sysargs<uint64_t, uint64_t, uint64_t>();
        
        std::vector<uint8_t> data(count);
        ssize_t bytes_read = read(fd, data.data(), count);
        
        if (bytes_read > 0) {
            machine.memory.memcpy(buf, data.data(), bytes_read);
        }
        machine.set_result(bytes_read);
    });
    
    // exit syscall (93)
    Machine::install_syscall_handler(93, [](Machine& machine) {
        auto [status] = machine.sysargs<int>();
        printf("\n---\nProgram exited with code %d\n", status);
        machine.stop();
    });
    
    // exit_group syscall (94)
    Machine::install_syscall_handler(94, [](Machine& machine) {
        auto [status] = machine.sysargs<int>();
        printf("\n---\nProgram exited with code %d\n", status);
        machine.stop();
    });
    
    // brk syscall (214)
    static uint64_t heap_end = 0;
    Machine::install_syscall_handler(214, [](Machine& machine) {
        auto [addr] = machine.sysargs<uint64_t>();
        if (heap_end == 0) {
            heap_end = machine.memory.heap_address();
        }
        if (addr == 0) {
            machine.set_result(heap_end);
        } else if (addr >= heap_end) {
            heap_end = addr;
            machine.set_result(heap_end);
        } else {
            machine.set_result(heap_end);
        }
    });
    
    // fstat syscall (80) - return success
    Machine::install_syscall_handler(80, [](Machine& machine) {
        machine.set_result(0);
    });
    
    // ioctl syscall (29) - return -ENOTTY
    Machine::install_syscall_handler(29, [](Machine& machine) {
        machine.set_result(-25); // -ENOTTY
    });
    
    // openat syscall (56) - minimal support
    Machine::install_syscall_handler(56, [](Machine& machine) {
        machine.set_result(-1);
    });
    
    // close syscall (57)
    Machine::install_syscall_handler(57, [](Machine& machine) {
        machine.set_result(0);
    });
    
    // lseek syscall (62)
    Machine::install_syscall_handler(62, [](Machine& machine) {
        machine.set_result(-1);
    });
}

// Setup Linux-like syscalls for RV32
void setup_linux_syscalls_32() {
    using Machine = riscv::Machine<riscv::RISCV32>;
    
    // write syscall (64)
    Machine::install_syscall_handler(64, [](Machine& machine) {
        auto [fd, buf, count] = machine.sysargs<uint32_t, uint32_t, uint32_t>();
        
        std::vector<uint8_t> data(count);
        machine.memory.memcpy_out(data.data(), buf, count);
        
        ssize_t written = 0;
        if (fd == 1 || fd == 2) { // stdout or stderr
            written = write(fd, data.data(), count);
        }
        machine.set_result(written);
    });
    
    // read syscall (63)
    Machine::install_syscall_handler(63, [](Machine& machine) {
        auto [fd, buf, count] = machine.sysargs<uint32_t, uint32_t, uint32_t>();
        
        std::vector<uint8_t> data(count);
        ssize_t bytes_read = read(fd, data.data(), count);
        
        if (bytes_read > 0) {
            machine.memory.memcpy(buf, data.data(), bytes_read);
        }
        machine.set_result(bytes_read);
    });
    
    // exit syscall (93)
    Machine::install_syscall_handler(93, [](Machine& machine) {
        auto [status] = machine.sysargs<int>();
        printf("\n---\nProgram exited with code %d\n", status);
        machine.stop();
    });
    
    // exit_group syscall (94)
    Machine::install_syscall_handler(94, [](Machine& machine) {
        auto [status] = machine.sysargs<int>();
        printf("\n---\nProgram exited with code %d\n", status);
        machine.stop();
    });
    
    // brk syscall (214)
    static uint32_t heap_end = 0;
    Machine::install_syscall_handler(214, [](Machine& machine) {
        auto [addr] = machine.sysargs<uint32_t>();
        if (heap_end == 0) {
            heap_end = machine.memory.heap_address();
        }
        if (addr == 0) {
            machine.set_result(heap_end);
        } else if (addr >= heap_end) {
            heap_end = addr;
            machine.set_result(heap_end);
        } else {
            machine.set_result(heap_end);
        }
    });
    
    // fstat syscall (80) - return success
    Machine::install_syscall_handler(80, [](Machine& machine) {
        machine.set_result(0);
    });
    
    // ioctl syscall (29) - return -ENOTTY
    Machine::install_syscall_handler(29, [](Machine& machine) {
        machine.set_result(-25); // -ENOTTY
    });
    
    // openat syscall (56) - minimal support
    Machine::install_syscall_handler(56, [](Machine& machine) {
        machine.set_result(-1);
    });
    
    // close syscall (57)
    Machine::install_syscall_handler(57, [](Machine& machine) {
        machine.set_result(0);
    });
    
    // lseek syscall (62)
    Machine::install_syscall_handler(62, [](Machine& machine) {
        machine.set_result(-1);
    });
}

// Check if data is ELF format
bool is_elf(const std::vector<uint8_t>& data) {
    if (data.size() < 4) return false;
    return data[0] == 0x7f && data[1] == 'E' && data[2] == 'L' && data[3] == 'F';
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <binary> [entry_addr] [--64]\n", argv[0]);
        fprintf(stderr, "  binary: RISC-V ELF or raw binary file\n");
        fprintf(stderr, "  entry_addr: Entry point for raw binary (default: 0x10000)\n");
        fprintf(stderr, "  --64: Use 64-bit mode for raw binary (default: 32-bit)\n");
        return 1;
    }

    // Load binary
    auto binary = load_file(argv[1]);
    
    // Parse arguments
    uint64_t entry_addr = 0x10000;
    bool force_64bit = false;
    bool is_raw = !is_elf(binary);
    
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--64") == 0) {
            force_64bit = true;
        } else if (argv[i][0] != '-') {
            entry_addr = strtoull(argv[i], nullptr, 0);
        }
    }

    printf("Loaded %zu bytes from %s\n", binary.size(), argv[1]);

    using namespace riscv;

    bool is_64bit = is_elf64(binary) || (is_raw && force_64bit);
    printf("Architecture: %d-bit (%s)\n", is_64bit ? 64 : 32, is_raw ? "raw" : "ELF");

    if (is_64bit) {
        // Create a 64-bit machine
        if (is_raw) {
            Machine<RISCV64> machine;
            // Copy binary to memory at entry address
            machine.memory.memcpy(entry_addr, binary.data(), binary.size());
            // Initialize execute area
            machine.cpu.init_execute_area(binary.data(), entry_addr, binary.size());
            // Set entry point
            machine.cpu.jump(entry_addr);
            
            // Setup Linux-like syscalls
            setup_linux_syscalls_64();

            printf("Entry point: 0x%llx\n", (unsigned long long)machine.cpu.pc());
            printf("Running...\n");
            printf("---\n");

            try {
                machine.simulate(100'000'000ull);
            } catch (const std::exception& e) {
                fprintf(stderr, ">>> Runtime exception: %s\n", e.what());
            }

            printf("---\n");
            printf("Machine stopped.\n");
            printf("Instructions executed: %llu\n", (unsigned long long)machine.instruction_counter());
            
            // Print final register state
            printf("\nFinal registers:\n");
            for (int i = 0; i < 32; i++) {
                printf("  x%-2d: 0x%016llx\n", i, (unsigned long long)machine.cpu.reg(i));
            }
        } else {
            Machine<RISCV64> machine(binary);
            
            // Setup Linux-like syscalls
            setup_linux_syscalls_64();

            printf("Entry point: 0x%llx\n", (unsigned long long)machine.cpu.pc());
            printf("Running...\n");
            printf("---\n");

            try {
                machine.simulate(100'000'000ull);
            } catch (const std::exception& e) {
                fprintf(stderr, ">>> Runtime exception: %s\n", e.what());
            }

            printf("---\n");
            printf("Machine stopped.\n");
            printf("Instructions executed: %llu\n", (unsigned long long)machine.instruction_counter());
            
            // Print final register state
            printf("\nFinal registers:\n");
            for (int i = 0; i < 32; i++) {
                printf("  x%-2d: 0x%016llx\n", i, (unsigned long long)machine.cpu.reg(i));
            }
        }
    } else {
        // Create a 32-bit machine
        if (is_raw) {
            Machine<RISCV32> machine;
            // Copy binary to memory at entry address
            machine.memory.memcpy((uint32_t)entry_addr, binary.data(), binary.size());
            // Initialize execute area
            machine.cpu.init_execute_area(binary.data(), (uint32_t)entry_addr, binary.size());
            // Set entry point
            machine.cpu.jump((uint32_t)entry_addr);
            
            // Setup Linux-like syscalls
            setup_linux_syscalls_32();

            printf("Entry point: 0x%x\n", machine.cpu.pc());
            printf("Running...\n");
            printf("---\n");

            try {
                machine.simulate(100'000'000ull);
            } catch (const std::exception& e) {
                fprintf(stderr, ">>> Runtime exception: %s\n", e.what());
            }

            printf("---\n");
            printf("Machine stopped.\n");
            printf("Instructions executed: %llu\n", (unsigned long long)machine.instruction_counter());
            
            // Print final register state
            printf("\nFinal registers:\n");
            for (int i = 0; i < 32; i++) {
                printf("  x%-2d: 0x%08x\n", i, machine.cpu.reg(i));
            }
        } else {
            Machine<RISCV32> machine(binary);
            
            // Setup Linux-like syscalls
            setup_linux_syscalls_32();

            printf("Entry point: 0x%x\n", machine.cpu.pc());
            printf("Running...\n");
            printf("---\n");

            try {
                machine.simulate(100'000'000ull);
            } catch (const std::exception& e) {
                fprintf(stderr, ">>> Runtime exception: %s\n", e.what());
            }

            printf("---\n");
            printf("Machine stopped.\n");
            printf("Instructions executed: %llu\n", (unsigned long long)machine.instruction_counter());
            
            // Print final register state
            printf("\nFinal registers:\n");
            for (int i = 0; i < 32; i++) {
                printf("  x%-2d: 0x%08x\n", i, machine.cpu.reg(i));
            }
        }
    }

    return 0;
}
