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
