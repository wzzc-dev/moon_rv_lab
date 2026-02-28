///| ELF format definitions

///| Based on ELF Specification (https://refspecs.linuxfoundation.org/elf/elf.pdf)

///|
/// ELF identification indices
pub const EI_MAG0 : Int = 0 // 0x7F

///|
pub const EI_MAG1 : Int = 1 // 'E'

///|
pub const EI_MAG2 : Int = 2 // 'L'

///|
pub const EI_MAG3 : Int = 3 // 'F'

///|
pub const EI_CLASS : Int = 4 // 32/64 bit

///|
pub const EI_DATA : Int = 5 // Endianness

///|
pub const EI_VERSION : Int = 6 // ELF version

///|
pub const EI_OSABI : Int = 7 // OS/ABI

///|
pub const EI_NIDENT : Int = 16

///|
/// ELF class (32/64 bit)
pub const ELFCLASS32 : Byte = b'\x01'

///|
pub const ELFCLASS64 : Byte = b'\x02'

///|
/// ELF data encoding (endianness)
pub const ELFDATA2LSB : Byte = b'\x01' // Little endian

///|
pub const ELFDATA2MSB : Byte = b'\x02' // Big endian

///|
/// ELF machine types
pub const EM_RISCV : UInt = 243U

///|
/// ELF file types
pub const ET_EXEC : UInt = 2U

///|
pub const ET_DYN : UInt = 3U

///|
/// Section header types
pub const SHT_NULL : UInt = 0U

///|
pub const SHT_PROGBITS : UInt = 1U

///|
pub const SHT_SYMTAB : UInt = 2U

///|
pub const SHT_STRTAB : UInt = 3U

///|
pub const SHT_NOBITS : UInt = 8U

///|
pub const SHT_DYNSYM : UInt = 11U

///|
/// Section flags
pub const SHF_EXECINSTR : UInt = 0x4U

///|
/// Program header types
pub const PT_LOAD : UInt = 1U

///|
/// Program header flags
pub const PF_X : UInt = 0x1U

///|
pub const PF_R : UInt = 0x4U

///|
/// Symbol binding (upper 4 bits of st_info)
pub const STB_LOCAL : UInt = 0U

///|
pub const STB_GLOBAL : UInt = 1U

///|
pub const STB_WEAK : UInt = 2U

///|
/// Symbol type (lower 4 bits of st_info)
pub const STT_NOTYPE : UInt = 0U

///|
pub const STT_OBJECT : UInt = 1U

///|
pub const STT_FUNC : UInt = 2U

///|
pub const STT_SECTION : UInt = 3U

///|
pub const STT_FILE : UInt = 4U

///|
/// Special section indices
pub const SHN_UNDEF : UInt = 0U

///|
pub const SHN_ABS : UInt = 0xFFF1U

///|
/// Section header types - relocation
pub const SHT_REL : UInt = 9U

///|
pub const SHT_RELA : UInt = 4U

///|
/// RISC-V relocation types
/// Reference: https://github.com/riscv-non-isa/riscv-elf-psabi-doc
pub const R_RISCV_NONE : UInt = 0U

///|
pub const R_RISCV_32 : UInt = 1U

///|
pub const R_RISCV_64 : UInt = 2U

///|
pub const R_RISCV_RELATIVE : UInt = 3U

///|
pub const R_RISCV_COPY : UInt = 4U

///|
pub const R_RISCV_JUMP_SLOT : UInt = 5U

///|
pub const R_RISCV_TLS_DTPMOD32 : UInt = 6U

///|
pub const R_RISCV_TLS_DTPMOD64 : UInt = 7U

///|
pub const R_RISCV_TLS_DTPREL32 : UInt = 8U

///|
pub const R_RISCV_TLS_DTPREL64 : UInt = 9U

///|
pub const R_RISCV_TLS_TPREL32 : UInt = 10U

///|
pub const R_RISCV_TLS_TPREL64 : UInt = 11U

///|
pub const R_RISCV_BRANCH : UInt = 16U

///|
pub const R_RISCV_JAL : UInt = 17U

///|
pub const R_RISCV_CALL : UInt = 18U

///|
pub const R_RISCV_CALL_PLT : UInt = 19U

///|
pub const R_RISCV_GOT_HI20 : UInt = 20U

///|
pub const R_RISCV_TLS_GOT_HI20 : UInt = 21U

///|
pub const R_RISCV_TLS_GD_HI20 : UInt = 22U

///|
pub const R_RISCV_PCREL_HI20 : UInt = 23U

///|
pub const R_RISCV_PCREL_LO12_I : UInt = 24U

///|
pub const R_RISCV_PCREL_LO12_S : UInt = 25U

///|
pub const R_RISCV_HI20 : UInt = 26U

///|
pub const R_RISCV_LO12_I : UInt = 27U

///|
pub const R_RISCV_LO12_S : UInt = 28U

///|
pub const R_RISCV_LO12_PCREL_I : UInt = 29U

///|
pub const R_RISCV_LO12_PCREL_S : UInt = 30U

///|
pub const R_RISCV_ALIGN : UInt = 43U

///|
pub const R_RISCV_RVC_BRANCH : UInt = 44U

///|
pub const R_RISCV_RVC_JUMP : UInt = 45U

///|
pub const R_RISCV_SUB6 : UInt = 48U

///|
pub const R_RISCV_SUB8 : UInt = 49U

///|
pub const R_RISCV_SUB16 : UInt = 50U

///|
pub const R_RISCV_SUB32 : UInt = 51U

///|
pub const R_RISCV_SUB64 : UInt = 52U

///|
pub const R_RISCV_ADD16 : UInt = 53U

///|
pub const R_RISCV_ADD32 : UInt = 54U

///|
pub const R_RISCV_ADD64 : UInt = 55U
