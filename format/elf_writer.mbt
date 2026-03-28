///| ELF Writer for generating executable files

///|
/// Configuration for ELF output
pub struct ElfWriterConfig {
  entry_point : UInt
  is_64bit : Bool
  is_executable : Bool
} derive(Show)

///|
/// Create default ELF writer config for RISC-V 64-bit executable
pub fn default_elf_config(entry : UInt) -> ElfWriterConfig {
  { entry_point: entry, is_64bit: true, is_executable: true }
}

///|
/// Create ELF writer config for RISC-V 32-bit executable
pub fn elf32_config(entry : UInt) -> ElfWriterConfig {
  { entry_point: entry, is_64bit: false, is_executable: true }
}

///|
/// Create ELF writer config for RISC-V 64-bit executable
pub fn elf64_config(entry : UInt) -> ElfWriterConfig {
  { entry_point: entry, is_64bit: true, is_executable: true }
}

///|
/// Write a 16-bit value in little-endian
fn write_u16_le(value : UInt) -> FixedArray[Byte] {
  let arr = FixedArray::make(2, b'\x00')
  arr[0] = (value & 0xFFU).to_byte()
  arr[1] = ((value >> 8) & 0xFFU).to_byte()
  arr
}

///|
/// Write a 32-bit value in little-endian
fn write_u32_le(value : UInt) -> FixedArray[Byte] {
  let arr = FixedArray::make(4, b'\x00')
  arr[0] = (value & 0xFFU).to_byte()
  arr[1] = ((value >> 8) & 0xFFU).to_byte()
  arr[2] = ((value >> 16) & 0xFFU).to_byte()
  arr[3] = ((value >> 24) & 0xFFU).to_byte()
  arr
}

///|
/// Write a 64-bit value in little-endian
fn write_u64_le(value : UInt) -> FixedArray[Byte] {
  let arr = FixedArray::make(8, b'\x00')
  arr[0] = (value & 0xFFU).to_byte()
  arr[1] = ((value >> 8) & 0xFFU).to_byte()
  arr[2] = ((value >> 16) & 0xFFU).to_byte()
  arr[3] = ((value >> 24) & 0xFFU).to_byte()
  arr[4] = ((value >> 32) & 0xFFU).to_byte()
  arr[5] = ((value >> 40) & 0xFFU).to_byte()
  arr[6] = ((value >> 48) & 0xFFU).to_byte()
  arr[7] = ((value >> 56) & 0xFFU).to_byte()
  arr
}

///|
/// Create ELF32 header bytes
fn create_elf32_header(entry : UInt, shoff : UInt) -> FixedArray[Byte] {
  // ELF32 header is 52 bytes
  let header = FixedArray::make(52, b'\x00')

  // ELF magic
  header[0] = b'\x7f'
  header[1] = b'E'
  header[2] = b'L'
  header[3] = b'F'

  // ELF class (32-bit)
  header[4] = ELFCLASS32

  // Data encoding (little endian)
  header[5] = ELFDATA2LSB

  // ELF version
  header[6] = b'\x01'

  // OS/ABI (ELFOSABI_NONE = 0)
  header[7] = b'\x00'

  // e_type: ET_EXEC = 2
  header[16] = b'\x02'
  header[17] = b'\x00'

  // e_machine: EM_RISCV = 243
  header[18] = 0xF3U.to_byte()
  header[19] = b'\x00'

  // e_version: 1
  header[20] = b'\x01'
  header[21] = b'\x00'
  header[22] = b'\x00'
  header[23] = b'\x00'

  // e_entry: entry point
  let entry_bytes = write_u32_le(entry)
  header[24] = entry_bytes[0]
  header[25] = entry_bytes[1]
  header[26] = entry_bytes[2]
  header[27] = entry_bytes[3]

  // e_phoff: program header offset (52 bytes = header size)
  header[28] = b'\x34' // 52
  header[29] = b'\x00'
  header[30] = b'\x00'
  header[31] = b'\x00'

  // e_shoff: section header offset
  let shoff_bytes = write_u32_le(shoff)
  header[32] = shoff_bytes[0]
  header[33] = shoff_bytes[1]
  header[34] = shoff_bytes[2]
  header[35] = shoff_bytes[3]

  // e_flags: 0
  header[36] = b'\x00'
  header[37] = b'\x00'
  header[38] = b'\x00'
  header[39] = b'\x00'

  // e_ehsize: ELF header size = 52
  header[40] = b'\x34' // 52
  header[41] = b'\x00'

  // e_phentsize: program header entry size = 32
  header[42] = b'\x20' // 32
  header[43] = b'\x00'

  // e_phnum: number of program headers = 1
  header[44] = b'\x01'
  header[45] = b'\x00'

  // e_shentsize: section header entry size = 40
  header[46] = b'\x28' // 40
  header[47] = b'\x00'

  // e_shnum: number of section headers = 3 (null, .text, .shstrtab)
  header[48] = b'\x03'
  header[49] = b'\x00'

  // e_shstrndx: section header string table index = 2
  header[50] = b'\x02'
  header[51] = b'\x00'

  header
}

///|
/// Create ELF64 header bytes
fn create_elf64_header(entry : UInt, shoff : UInt) -> FixedArray[Byte] {
  let header = FixedArray::make(64, b'\x00')

  header[0] = b'\x7f'
  header[1] = b'E'
  header[2] = b'L'
  header[3] = b'F'
  header[4] = ELFCLASS64
  header[5] = ELFDATA2LSB
  header[6] = b'\x01'
  header[7] = b'\x00'

  header[16] = b'\x02'
  header[17] = b'\x00'
  header[18] = 0xF3U.to_byte()
  header[19] = b'\x00'
  header[20] = b'\x01'
  header[21] = b'\x00'
  header[22] = b'\x00'
  header[23] = b'\x00'

  let entry_bytes = write_u64_le(entry)
  for i = 0; i < entry_bytes.length(); i = i + 1 {
    header[24 + i] = entry_bytes[i]
  }

  let phoff_bytes = write_u64_le(64U)
  for i = 0; i < phoff_bytes.length(); i = i + 1 {
    header[32 + i] = phoff_bytes[i]
  }

  let shoff_bytes = write_u64_le(shoff)
  for i = 0; i < shoff_bytes.length(); i = i + 1 {
    header[40 + i] = shoff_bytes[i]
  }

  header[52] = b'\x40'
  header[53] = b'\x00'
  header[54] = b'\x38'
  header[55] = b'\x00'
  header[56] = b'\x01'
  header[57] = b'\x00'
  header[58] = b'\x40'
  header[59] = b'\x00'
  header[60] = b'\x03'
  header[61] = b'\x00'
  header[62] = b'\x02'
  header[63] = b'\x00'

  header
}

///|
/// Create ELF32 program header bytes (for LOAD segment)
fn create_elf32_program_header(
  vaddr : UInt,
  filesz : UInt,
  memsz : UInt,
) -> FixedArray[Byte] {
  // Program header is 32 bytes
  let phdr = FixedArray::make(32, b'\x00')

  // p_type: PT_LOAD = 1
  phdr[0] = b'\x01'
  phdr[1] = b'\x00'
  phdr[2] = b'\x00'
  phdr[3] = b'\x00'

  // p_offset: 0 (load from start of file)
  phdr[4] = b'\x00'
  phdr[5] = b'\x00'
  phdr[6] = b'\x00'
  phdr[7] = b'\x00'

  // p_vaddr: virtual address
  let vaddr_bytes = write_u32_le(vaddr)
  phdr[8] = vaddr_bytes[0]
  phdr[9] = vaddr_bytes[1]
  phdr[10] = vaddr_bytes[2]
  phdr[11] = vaddr_bytes[3]

  // p_paddr: physical address (same as vaddr)
  phdr[12] = vaddr_bytes[0]
  phdr[13] = vaddr_bytes[1]
  phdr[14] = vaddr_bytes[2]
  phdr[15] = vaddr_bytes[3]

  // p_filesz: file size
  let filesz_bytes = write_u32_le(filesz)
  phdr[16] = filesz_bytes[0]
  phdr[17] = filesz_bytes[1]
  phdr[18] = filesz_bytes[2]
  phdr[19] = filesz_bytes[3]

  // p_memsz: memory size
  let memsz_bytes = write_u32_le(memsz)
  phdr[20] = memsz_bytes[0]
  phdr[21] = memsz_bytes[1]
  phdr[22] = memsz_bytes[2]
  phdr[23] = memsz_bytes[3]

  // p_flags: PF_R | PF_X = 5
  phdr[24] = b'\x05'
  phdr[25] = b'\x00'
  phdr[26] = b'\x00'
  phdr[27] = b'\x00'

  // p_align: alignment = 4KB
  phdr[28] = b'\x00'
  phdr[29] = b'\x10'
  phdr[30] = b'\x00'
  phdr[31] = b'\x00'

  phdr
}

///|
/// Create ELF64 program header bytes (for LOAD segment)
fn create_elf64_program_header(
  offset : UInt,
  vaddr : UInt,
  filesz : UInt,
  memsz : UInt,
) -> FixedArray[Byte] {
  let phdr = FixedArray::make(56, b'\x00')

  let type_bytes = write_u32_le(PT_LOAD)
  for i = 0; i < type_bytes.length(); i = i + 1 {
    phdr[i] = type_bytes[i]
  }

  let flags_bytes = write_u32_le(PF_X | 0x4U)
  for i = 0; i < flags_bytes.length(); i = i + 1 {
    phdr[4 + i] = flags_bytes[i]
  }

  let offset_bytes = write_u64_le(offset)
  let vaddr_bytes = write_u64_le(vaddr)
  let filesz_bytes = write_u64_le(filesz)
  let memsz_bytes = write_u64_le(memsz)
  let align_bytes = write_u64_le(0x1000U)

  for i = 0; i < offset_bytes.length(); i = i + 1 {
    phdr[8 + i] = offset_bytes[i]
    phdr[16 + i] = vaddr_bytes[i]
    phdr[24 + i] = vaddr_bytes[i]
    phdr[32 + i] = filesz_bytes[i]
    phdr[40 + i] = memsz_bytes[i]
    phdr[48 + i] = align_bytes[i]
  }

  phdr
}

///|
/// Create ELF32 section header bytes
fn create_elf32_section_header(
  sh_name : UInt,
  sh_type : UInt,
  sh_flags : UInt,
  sh_addr : UInt,
  sh_offset : UInt,
  sh_size : UInt,
  sh_link : UInt,
  sh_info : UInt,
  sh_addralign : UInt,
  sh_entsize : UInt,
) -> FixedArray[Byte] {
  let shdr = FixedArray::make(40, b'\x00')

  // sh_name
  let name_bytes = write_u32_le(sh_name)
  shdr[0] = name_bytes[0]
  shdr[1] = name_bytes[1]
  shdr[2] = name_bytes[2]
  shdr[3] = name_bytes[3]

  // sh_type
  let type_bytes = write_u32_le(sh_type)
  shdr[4] = type_bytes[0]
  shdr[5] = type_bytes[1]
  shdr[6] = type_bytes[2]
  shdr[7] = type_bytes[3]

  // sh_flags
  let flags_bytes = write_u32_le(sh_flags)
  shdr[8] = flags_bytes[0]
  shdr[9] = flags_bytes[1]
  shdr[10] = flags_bytes[2]
  shdr[11] = flags_bytes[3]

  // sh_addr
  let addr_bytes = write_u32_le(sh_addr)
  shdr[12] = addr_bytes[0]
  shdr[13] = addr_bytes[1]
  shdr[14] = addr_bytes[2]
  shdr[15] = addr_bytes[3]

  // sh_offset
  let offset_bytes = write_u32_le(sh_offset)
  shdr[16] = offset_bytes[0]
  shdr[17] = offset_bytes[1]
  shdr[18] = offset_bytes[2]
  shdr[19] = offset_bytes[3]

  // sh_size
  let size_bytes = write_u32_le(sh_size)
  shdr[20] = size_bytes[0]
  shdr[21] = size_bytes[1]
  shdr[22] = size_bytes[2]
  shdr[23] = size_bytes[3]

  // sh_link
  let link_bytes = write_u32_le(sh_link)
  shdr[24] = link_bytes[0]
  shdr[25] = link_bytes[1]
  shdr[26] = link_bytes[2]
  shdr[27] = link_bytes[3]

  // sh_info
  let info_bytes = write_u32_le(sh_info)
  shdr[28] = info_bytes[0]
  shdr[29] = info_bytes[1]
  shdr[30] = info_bytes[2]
  shdr[31] = info_bytes[3]

  // sh_addralign
  let align_bytes = write_u32_le(sh_addralign)
  shdr[32] = align_bytes[0]
  shdr[33] = align_bytes[1]
  shdr[34] = align_bytes[2]
  shdr[35] = align_bytes[3]

  // sh_entsize
  let entsize_bytes = write_u32_le(sh_entsize)
  shdr[36] = entsize_bytes[0]
  shdr[37] = entsize_bytes[1]
  shdr[38] = entsize_bytes[2]
  shdr[39] = entsize_bytes[3]

  shdr
}

///|
/// Create ELF64 section header bytes
fn create_elf64_section_header(
  sh_name : UInt,
  sh_type : UInt,
  sh_flags : UInt,
  sh_addr : UInt,
  sh_offset : UInt,
  sh_size : UInt,
  sh_link : UInt,
  sh_info : UInt,
  sh_addralign : UInt,
  sh_entsize : UInt,
) -> FixedArray[Byte] {
  let shdr = FixedArray::make(64, b'\x00')
  let name_bytes = write_u32_le(sh_name)
  let type_bytes = write_u32_le(sh_type)
  let flags_bytes = write_u64_le(sh_flags)
  let addr_bytes = write_u64_le(sh_addr)
  let offset_bytes = write_u64_le(sh_offset)
  let size_bytes = write_u64_le(sh_size)
  let link_bytes = write_u32_le(sh_link)
  let info_bytes = write_u32_le(sh_info)
  let align_bytes = write_u64_le(sh_addralign)
  let entsize_bytes = write_u64_le(sh_entsize)

  for i = 0; i < name_bytes.length(); i = i + 1 {
    shdr[i] = name_bytes[i]
    shdr[4 + i] = type_bytes[i]
    shdr[40 + i] = link_bytes[i]
    shdr[44 + i] = info_bytes[i]
  }

  for i = 0; i < flags_bytes.length(); i = i + 1 {
    shdr[8 + i] = flags_bytes[i]
    shdr[16 + i] = addr_bytes[i]
    shdr[24 + i] = offset_bytes[i]
    shdr[32 + i] = size_bytes[i]
    shdr[48 + i] = align_bytes[i]
    shdr[56 + i] = entsize_bytes[i]
  }

  shdr
}

///|
/// Section header string table content
/// Format: "\0.text\0.shstrtab\0"
fn create_shstrtab() -> FixedArray[Byte] {
  // "\0.text\0.shstrtab\0" = 1 + 5 + 1 + 9 + 1 = 17 bytes
  let strtab = FixedArray::make(17, b'\x00')
  // .text at offset 1
  strtab[1] = b'.'
  strtab[2] = b't'
  strtab[3] = b'e'
  strtab[4] = b'x'
  strtab[5] = b't'
  // .shstrtab at offset 7
  strtab[7] = b'.'
  strtab[8] = b's'
  strtab[9] = b'h'
  strtab[10] = b's'
  strtab[11] = b't'
  strtab[12] = b'r'
  strtab[13] = b't'
  strtab[14] = b'a'
  strtab[15] = b'b'
  strtab
}

///|
/// Write a minimal ELF32 executable with code
pub fn write_elf32_executable(
  code : FixedArray[Byte],
  entry : UInt,
  base_addr : UInt,
) -> FixedArray[Byte] {
  // Calculate sizes
  let elf_header_size = 52
  let phdr_size = 32
  let shdr_size = 40
  let num_shdrs = 3 // null, .text, .shstrtab
  let shstrtab = create_shstrtab()
  let shstrtab_size = shstrtab.length()

  // Calculate offsets
  let code_offset = elf_header_size + phdr_size // 84
  let total_code_size = code.length()
  let shstrtab_offset = code_offset + total_code_size
  let shdr_offset = shstrtab_offset + shstrtab_size

  // Total file size
  let total_size = shdr_offset + shdr_size * num_shdrs

  // Create output buffer
  let output = FixedArray::make(total_size, b'\x00')

  // Write ELF header
  let header = create_elf32_header(entry, shdr_offset.reinterpret_as_uint())
  for i = 0; i < header.length(); i = i + 1 {
    output[i] = header[i]
  }

  // Write program header
  let phdr = create_elf32_program_header(
    base_addr,
    total_code_size.reinterpret_as_uint(),
    total_code_size.reinterpret_as_uint(),
  )
  for i = 0; i < phdr.length(); i = i + 1 {
    output[elf_header_size + i] = phdr[i]
  }

  // Write code section
  for i = 0; i < code.length(); i = i + 1 {
    output[code_offset + i] = code[i]
  }

  // Write section header string table
  for i = 0; i < shstrtab.length(); i = i + 1 {
    output[shstrtab_offset + i] = shstrtab[i]
  }

  // Write section headers
  // Section 0: NULL section
  let null_shdr = create_elf32_section_header(
    0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U,
  )
  for i = 0; i < null_shdr.length(); i = i + 1 {
    output[shdr_offset + i] = null_shdr[i]
  }

  // Section 1: .text section
  let text_shdr = create_elf32_section_header(
    1U, // sh_name: offset in shstrtab
    SHT_PROGBITS,
    SHF_ALLOC | SHF_EXECINSTR,
    base_addr,
    code_offset.reinterpret_as_uint(),
    total_code_size.reinterpret_as_uint(),
    0U,
    0U,
    4U, // alignment
    0U,
  )
  for i = 0; i < text_shdr.length(); i = i + 1 {
    output[shdr_offset + shdr_size + i] = text_shdr[i]
  }

  // Section 2: .shstrtab section
  let shstrtab_shdr = create_elf32_section_header(
    7U, // sh_name: offset in shstrtab
    SHT_STRTAB,
    0U,
    0U,
    shstrtab_offset.reinterpret_as_uint(),
    shstrtab_size.reinterpret_as_uint(),
    0U,
    0U,
    1U,
    0U,
  )
  for i = 0; i < shstrtab_shdr.length(); i = i + 1 {
    output[shdr_offset + 2 * shdr_size + i] = shstrtab_shdr[i]
  }

  output
}

///|
/// Write a minimal ELF64 executable with code
pub fn write_elf64_executable(
  code : FixedArray[Byte],
  entry : UInt,
  base_addr : UInt,
) -> FixedArray[Byte] {
  let elf_header_size = 64
  let phdr_size = 56
  let shdr_size = 64
  let num_shdrs = 3
  let shstrtab = create_shstrtab()
  let shstrtab_size = shstrtab.length()

  let code_offset = elf_header_size + phdr_size
  let total_code_size = code.length()
  let shstrtab_offset = code_offset + total_code_size
  let shdr_offset = shstrtab_offset + shstrtab_size
  let total_size = shdr_offset + shdr_size * num_shdrs

  let output = FixedArray::make(total_size, b'\x00')

  let header = create_elf64_header(entry, shdr_offset.reinterpret_as_uint())
  for i = 0; i < header.length(); i = i + 1 {
    output[i] = header[i]
  }

  let phdr = create_elf64_program_header(
    code_offset.reinterpret_as_uint(),
    base_addr,
    total_code_size.reinterpret_as_uint(),
    total_code_size.reinterpret_as_uint(),
  )
  for i = 0; i < phdr.length(); i = i + 1 {
    output[elf_header_size + i] = phdr[i]
  }

  for i = 0; i < code.length(); i = i + 1 {
    output[code_offset + i] = code[i]
  }

  for i = 0; i < shstrtab.length(); i = i + 1 {
    output[shstrtab_offset + i] = shstrtab[i]
  }

  let null_shdr = create_elf64_section_header(
    0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U, 0U,
  )
  for i = 0; i < null_shdr.length(); i = i + 1 {
    output[shdr_offset + i] = null_shdr[i]
  }

  let text_shdr = create_elf64_section_header(
    1U,
    SHT_PROGBITS,
    SHF_ALLOC | SHF_EXECINSTR,
    base_addr,
    code_offset.reinterpret_as_uint(),
    total_code_size.reinterpret_as_uint(),
    0U,
    0U,
    4U,
    0U,
  )
  for i = 0; i < text_shdr.length(); i = i + 1 {
    output[shdr_offset + shdr_size + i] = text_shdr[i]
  }

  let shstrtab_shdr = create_elf64_section_header(
    7U,
    SHT_STRTAB,
    0U,
    0U,
    shstrtab_offset.reinterpret_as_uint(),
    shstrtab_size.reinterpret_as_uint(),
    0U,
    0U,
    1U,
    0U,
  )
  for i = 0; i < shstrtab_shdr.length(); i = i + 1 {
    output[shdr_offset + 2 * shdr_size + i] = shstrtab_shdr[i]
  }

  output
}

///|
pub fn assemble_to_elf32(
  code : FixedArray[Byte],
  entry : UInt,
) -> FixedArray[Byte] {
  write_elf32_executable(code, entry, 0x10000U)
}

///|
pub fn assemble_to_elf64(
  code : FixedArray[Byte],
  entry : UInt,
) -> FixedArray[Byte] {
  write_elf64_executable(code, entry, 0x10000U)
}

///|
/// Assemble code to ELF executable
pub fn assemble_to_elf(
  code : FixedArray[Byte],
  entry : UInt,
) -> FixedArray[Byte] {
  assemble_to_elf64(code, entry)
}
