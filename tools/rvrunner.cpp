#include <libriscv/machine.hpp>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <iostream>

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

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <binary> [entry_point]\n", argv[0]);
        fprintf(stderr, "  binary: Raw RISC-V binary file\n");
        fprintf(stderr, "  entry_point: Entry address in hex (default: 0x10000)\n");
        return 1;
    }

    // Load binary
    auto binary = load_file(argv[1]);
    uint32_t entry = 0x10000;
    if (argc > 2) {
        entry = strtoul(argv[2], nullptr, 0);
    }

    printf("Loaded %zu bytes from %s\n", binary.size(), argv[1]);
    printf("Entry point: 0x%x\n", entry);

    using namespace riscv;

    // Create a 32-bit machine with minimal setup
    Machine<RISCV32> machine;
    
    // Setup minimal syscalls (just ebreak/ebreak)
    machine.setup_minimal_syscalls();

    // Install ecall handler to catch ebreak
    Machine<RISCV32>::install_syscall_handler(0, // ecall
        [] (Machine<RISCV32>& machine) {
            // Check if this is ebreak (causes are stored in exception info)
            printf(">>> ecall/ebreak encountered, stopping\n");
            machine.stop();
        });

    // Load the binary at entry point
    const uint32_t dst = entry;
    machine.cpu.init_execute_area(binary.data(), dst, binary.size());
    
    // Set up stack
    const uint32_t stack_top = 0x80000000;
    machine.cpu.reg(2) = stack_top; // sp
    
    // Jump to entry
    machine.cpu.jump(dst);

    printf("Running...\n");
    printf("---\n");

    try {
        // Run for max 10M instructions
        machine.simulate(10'000'000ull);
    } catch (const std::exception& e) {
        fprintf(stderr, ">>> Runtime exception: %s\n", e.what());
    }

    printf("---\n");
    printf("Machine stopped.\n");
    printf("Instructions executed: %lu\n", machine.instruction_counter());
    
    // Print final register state
    printf("\nFinal registers:\n");
    for (int i = 0; i < 32; i++) {
        printf("  x%-2d (a%-2d): 0x%08x\n", i, i, machine.cpu.reg(i));
    }

    return 0;
}
