///| ELF parser implementation

///| Parses ELF32 and ELF64 binary files

///|
/// ELF Header for 32-bit
pub struct Elf32Header {
  e_ident : FixedArray[Byte] // 16 bytes
  e_type : UInt
  e_machine : UInt
  e_version : UInt
  e_entry : UInt
  e_phoff : UInt
  e_shoff : UInt
  e_flags : UInt
  e_ehsize : UInt
  e_phentsize : UInt
  e_phnum : UInt
  e_shentsize : UInt
  e_shnum : UInt
  e_shstrndx : UInt
} derive(Show)

///|
/// ELF Header for 64-bit
pub struct Elf64Header {
  e_ident : FixedArray[Byte] // 16 bytes
  e_type : UInt
  e_machine : UInt
  e_version : UInt
  e_entry : UInt
  e_phoff : UInt
  e_shoff : UInt
  e_flags : UInt
  e_ehsize : UInt
  e_phentsize : UInt
  e_phnum : UInt
  e_shentsize : UInt
  e_shnum : UInt
  e_shstrndx : UInt
} derive(Show)

///|
/// Section Header for 32-bit
pub struct Elf32SectionHeader {
  sh_name : UInt
  sh_type : UInt
  sh_flags : UInt
  sh_addr : UInt
  sh_offset : UInt
  sh_size : UInt
  sh_link : UInt
  sh_info : UInt
  sh_addralign : UInt
  sh_entsize : UInt
} derive(Show)

///|
/// Section Header for 64-bit
pub struct Elf64SectionHeader {
  sh_name : UInt
  sh_type : UInt
  sh_flags : UInt
  sh_addr : UInt
  sh_offset : UInt
  sh_size : UInt
  sh_link : UInt
  sh_info : UInt
  sh_addralign : UInt
  sh_entsize : UInt
} derive(Show)

///|
/// Program Header for 32-bit
pub struct Elf32ProgramHeader {
  p_type : UInt
  p_offset : UInt
  p_vaddr : UInt
  p_paddr : UInt
  p_filesz : UInt
  p_memsz : UInt
  p_flags : UInt
  p_align : UInt
} derive(Show)

///|
/// Program Header for 64-bit
pub struct Elf64ProgramHeader {
  p_type : UInt
  p_flags : UInt
  p_offset : UInt
  p_vaddr : UInt
  p_paddr : UInt
  p_filesz : UInt
  p_memsz : UInt
  p_align : UInt
} derive(Show)

///|
/// ELF File class (32 or 64 bit)
pub enum ElfClass {
  Elf32
  Elf64
  Unknown
} derive(Show, Eq)

///|
/// Parsed ELF file
pub struct ElfFile {
  is_64bit : Bool
  header32 : Elf32Header?
  header64 : Elf64Header?
  sections32 : Array[Elf32SectionHeader]
  sections64 : Array[Elf64SectionHeader]
  programs32 : Array[Elf32ProgramHeader]
  programs64 : Array[Elf64ProgramHeader]
  raw_data : FixedArray[Byte]
} derive(Show)

///|
/// Read a 32-bit little-endian value from bytes
fn read_u32_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  if offset + 3 >= bytes.length() {
    0U
  } else {
    bytes[offset].to_uint() |
    (bytes[offset + 1].to_uint() << 8) |
    (bytes[offset + 2].to_uint() << 16) |
    (bytes[offset + 3].to_uint() << 24)
  }
}

///|
/// Read a 64-bit little-endian value from bytes (returns lower 32 bits)
fn read_u64_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  if offset + 7 >= bytes.length() {
    0U
  } else {
    bytes[offset].to_uint() |
    (bytes[offset + 1].to_uint() << 8) |
    (bytes[offset + 2].to_uint() << 16) |
    (bytes[offset + 3].to_uint() << 24) |
    (bytes[offset + 4].to_uint() << 32) |
    (bytes[offset + 5].to_uint() << 40) |
    (bytes[offset + 6].to_uint() << 48) |
    (bytes[offset + 7].to_uint() << 56)
  }
}

///|
/// Read a 16-bit little-endian value from bytes
fn read_u16_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  if offset + 1 >= bytes.length() {
    0U
  } else {
    bytes[offset].to_uint() | (bytes[offset + 1].to_uint() << 8)
  }
}

///|
/// Check if bytes represent a valid ELF file
pub fn is_elf(bytes : FixedArray[Byte]) -> Bool {
  if bytes.length() < 16 {
    false
  } else {
    // Check ELF magic: 0x7F, 'E', 'L', 'F'
    bytes[0] == b'\x7f' &&
    bytes[1] == b'E' &&
    bytes[2] == b'L' &&
    bytes[3] == b'F'
  }
}

///|
/// Get ELF class (32 or 64 bit)
pub fn get_elf_class(bytes : FixedArray[Byte]) -> ElfClass {
  if bytes.length() < 5 {
    ElfClass::Unknown
  } else {
    match bytes[4] {
      b'\x01' => ElfClass::Elf32
      b'\x02' => ElfClass::Elf64
      _ => ElfClass::Unknown
    }
  }
}

///|
/// Parse ELF32 header
fn parse_elf32_header(bytes : FixedArray[Byte]) -> Elf32Header {
  let ident = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    ident[i] = bytes[i]
  }

  Elf32Header::{
    e_ident: ident,
    e_type: read_u16_le(bytes, 16),
    e_machine: read_u16_le(bytes, 18),
    e_version: read_u32_le(bytes, 20),
    e_entry: read_u32_le(bytes, 24),
    e_phoff: read_u32_le(bytes, 28),
    e_shoff: read_u32_le(bytes, 32),
    e_flags: read_u32_le(bytes, 36),
    e_ehsize: read_u16_le(bytes, 40),
    e_phentsize: read_u16_le(bytes, 42),
    e_phnum: read_u16_le(bytes, 44),
    e_shentsize: read_u16_le(bytes, 46),
    e_shnum: read_u16_le(bytes, 48),
    e_shstrndx: read_u16_le(bytes, 50),
  }
}

///|
/// Parse ELF64 header
fn parse_elf64_header(bytes : FixedArray[Byte]) -> Elf64Header {
  let ident = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    ident[i] = bytes[i]
  }

  Elf64Header::{
    e_ident: ident,
    e_type: read_u16_le(bytes, 16),
    e_machine: read_u16_le(bytes, 18),
    e_version: read_u32_le(bytes, 20),
    e_entry: read_u64_le(bytes, 24),
    e_phoff: read_u64_le(bytes, 32),
    e_shoff: read_u64_le(bytes, 40),
    e_flags: read_u32_le(bytes, 48),
    e_ehsize: read_u16_le(bytes, 52),
    e_phentsize: read_u16_le(bytes, 54),
    e_phnum: read_u16_le(bytes, 56),
    e_shentsize: read_u16_le(bytes, 58),
    e_shnum: read_u16_le(bytes, 60),
    e_shstrndx: read_u16_le(bytes, 62),
  }
}

///|
/// Parse ELF32 section header at given offset
fn parse_elf32_section_header(
  bytes : FixedArray[Byte],
  offset : Int,
) -> Elf32SectionHeader {
  Elf32SectionHeader::{
    sh_name: read_u32_le(bytes, offset),
    sh_type: read_u32_le(bytes, offset + 4),
    sh_flags: read_u32_le(bytes, offset + 8),
    sh_addr: read_u32_le(bytes, offset + 12),
    sh_offset: read_u32_le(bytes, offset + 16),
    sh_size: read_u32_le(bytes, offset + 20),
    sh_link: read_u32_le(bytes, offset + 24),
    sh_info: read_u32_le(bytes, offset + 28),
    sh_addralign: read_u32_le(bytes, offset + 32),
    sh_entsize: read_u32_le(bytes, offset + 36),
  }
}

///|
/// Parse ELF64 section header at given offset
fn parse_elf64_section_header(
  bytes : FixedArray[Byte],
  offset : Int,
) -> Elf64SectionHeader {
  Elf64SectionHeader::{
    sh_name: read_u32_le(bytes, offset),
    sh_type: read_u32_le(bytes, offset + 4),
    sh_flags: read_u64_le(bytes, offset + 8),
    sh_addr: read_u64_le(bytes, offset + 16),
    sh_offset: read_u64_le(bytes, offset + 24),
    sh_size: read_u64_le(bytes, offset + 32),
    sh_link: read_u32_le(bytes, offset + 40),
    sh_info: read_u32_le(bytes, offset + 44),
    sh_addralign: read_u64_le(bytes, offset + 48),
    sh_entsize: read_u64_le(bytes, offset + 56),
  }
}

///|
/// Parse ELF32 program header at given offset
fn parse_elf32_program_header(
  bytes : FixedArray[Byte],
  offset : Int,
) -> Elf32ProgramHeader {
  Elf32ProgramHeader::{
    p_type: read_u32_le(bytes, offset),
    p_offset: read_u32_le(bytes, offset + 4),
    p_vaddr: read_u32_le(bytes, offset + 8),
    p_paddr: read_u32_le(bytes, offset + 12),
    p_filesz: read_u32_le(bytes, offset + 16),
    p_memsz: read_u32_le(bytes, offset + 20),
    p_flags: read_u32_le(bytes, offset + 24),
    p_align: read_u32_le(bytes, offset + 28),
  }
}

///|
/// Parse ELF64 program header at given offset
fn parse_elf64_program_header(
  bytes : FixedArray[Byte],
  offset : Int,
) -> Elf64ProgramHeader {
  Elf64ProgramHeader::{
    p_type: read_u32_le(bytes, offset),
    p_flags: read_u32_le(bytes, offset + 4),
    p_offset: read_u64_le(bytes, offset + 8),
    p_vaddr: read_u64_le(bytes, offset + 16),
    p_paddr: read_u64_le(bytes, offset + 24),
    p_filesz: read_u64_le(bytes, offset + 32),
    p_memsz: read_u64_le(bytes, offset + 40),
    p_align: read_u64_le(bytes, offset + 48),
  }
}

///|
/// Parse ELF file from bytes
pub fn parse_elf(bytes : FixedArray[Byte]) -> ElfFile? {
  if !is_elf(bytes) {
    None
  } else {
    let elf_class = get_elf_class(bytes)
    match elf_class {
      ElfClass::Elf32 => {
        let header = parse_elf32_header(bytes)
        // Parse section headers
        let sections : Array[Elf32SectionHeader] = []
        let shoff = header.e_shoff.reinterpret_as_int()
        let shentsize = header.e_shentsize.reinterpret_as_int()
        let shnum = header.e_shnum.reinterpret_as_int()
        for i = 0; i < shnum; i = i + 1 {
          let offset = shoff + i * shentsize
          if offset + 40 <= bytes.length() {
            sections.push(parse_elf32_section_header(bytes, offset))
          }
        }
        // Parse program headers
        let programs : Array[Elf32ProgramHeader] = []
        let phoff = header.e_phoff.reinterpret_as_int()
        let phentsize = header.e_phentsize.reinterpret_as_int()
        let phnum = header.e_phnum.reinterpret_as_int()
        for i = 0; i < phnum; i = i + 1 {
          let offset = phoff + i * phentsize
          if offset + 32 <= bytes.length() {
            programs.push(parse_elf32_program_header(bytes, offset))
          }
        }
        Some(ElfFile::{
          is_64bit: false,
          header32: Some(header),
          header64: None,
          sections32: sections,
          sections64: [],
          programs32: programs,
          programs64: [],
          raw_data: bytes,
        })
      }
      ElfClass::Elf64 => {
        let header = parse_elf64_header(bytes)
        // Parse section headers
        let sections : Array[Elf64SectionHeader] = []
        let shoff = header.e_shoff.reinterpret_as_int()
        let shentsize = header.e_shentsize.reinterpret_as_int()
        let shnum = header.e_shnum.reinterpret_as_int()
        for i = 0; i < shnum; i = i + 1 {
          let offset = shoff + i * shentsize
          if offset + 64 <= bytes.length() {
            sections.push(parse_elf64_section_header(bytes, offset))
          }
        }
        // Parse program headers
        let programs : Array[Elf64ProgramHeader] = []
        let phoff = header.e_phoff.reinterpret_as_int()
        let phentsize = header.e_phentsize.reinterpret_as_int()
        let phnum = header.e_phnum.reinterpret_as_int()
        for i = 0; i < phnum; i = i + 1 {
          let offset = phoff + i * phentsize
          if offset + 56 <= bytes.length() {
            programs.push(parse_elf64_program_header(bytes, offset))
          }
        }
        Some(ElfFile::{
          is_64bit: true,
          header32: None,
          header64: Some(header),
          sections32: [],
          sections64: sections,
          programs32: [],
          programs64: programs,
          raw_data: bytes,
        })
      }
      ElfClass::Unknown => None
    }
  }
}

///|
/// Get entry point address
pub fn ElfFile::entry_point(self : ElfFile) -> UInt {
  if self.is_64bit {
    match self.header64 {
      Some(h) => h.e_entry
      None => 0U
    }
  } else {
    match self.header32 {
      Some(h) => h.e_entry
      None => 0U
    }
  }
}

///|
/// Check if this is a RISC-V ELF
pub fn ElfFile::is_riscv(self : ElfFile) -> Bool {
  if self.is_64bit {
    match self.header64 {
      Some(h) => h.e_machine == EM_RISCV
      None => false
    }
  } else {
    match self.header32 {
      Some(h) => h.e_machine == EM_RISCV
      None => false
    }
  }
}

///|
/// Get code section data (executable sections)
pub fn ElfFile::get_code_sections(
  self : ElfFile,
) -> Array[(UInt, FixedArray[Byte])] {
  let result : Array[(UInt, FixedArray[Byte])] = []
  if self.is_64bit {
    for phdr in self.programs64 {
      // Check if this is a LOAD segment with execute permission
      if phdr.p_type == PT_LOAD && (phdr.p_flags & PF_X) != 0U {
        let offset = phdr.p_offset.reinterpret_as_int()
        let filesz = phdr.p_filesz.reinterpret_as_int()
        if offset + filesz <= self.raw_data.length() && filesz > 0 {
          let code : FixedArray[Byte] = FixedArray::make(filesz, b'\x00')
          for i = 0; i < filesz; i = i + 1 {
            code[i] = self.raw_data[offset + i]
          }
          result.push((phdr.p_vaddr, code))
        }
      }
    }
  } else {
    for phdr in self.programs32 {
      // Check if this is a LOAD segment with execute permission
      if phdr.p_type == PT_LOAD && (phdr.p_flags & PF_X) != 0U {
        let offset = phdr.p_offset.reinterpret_as_int()
        let filesz = phdr.p_filesz.reinterpret_as_int()
        if offset + filesz <= self.raw_data.length() && filesz > 0 {
          let code : FixedArray[Byte] = FixedArray::make(filesz, b'\x00')
          for i = 0; i < filesz; i = i + 1 {
            code[i] = self.raw_data[offset + i]
          }
          result.push((phdr.p_vaddr, code))
        }
      }
    }
  }
  result
}

///|
/// Get number of sections
pub fn ElfFile::section_count(self : ElfFile) -> Int {
  if self.is_64bit {
    self.sections64.length()
  } else {
    self.sections32.length()
  }
}

///|
/// Get number of program headers
pub fn ElfFile::program_count(self : ElfFile) -> Int {
  if self.is_64bit {
    self.programs64.length()
  } else {
    self.programs32.length()
  }
}

///|
/// Get section by index (returns virtual address, offset, size)
pub fn ElfFile::get_section(self : ElfFile, index : Int) -> (UInt, UInt, UInt)? {
  if self.is_64bit {
    if index >= 0 && index < self.sections64.length() {
      let sh = self.sections64[index]
      Some((sh.sh_addr, sh.sh_offset, sh.sh_size))
    } else {
      None
    }
  } else if index >= 0 && index < self.sections32.length() {
    let sh = self.sections32[index]
    Some((sh.sh_addr, sh.sh_offset, sh.sh_size))
  } else {
    None
  }
}

///|
/// Extract bytes from a given offset and size
pub fn ElfFile::extract_bytes(
  self : ElfFile,
  offset : UInt,
  size : UInt,
) -> FixedArray[Byte]? {
  let off = offset.reinterpret_as_int()
  let sz = size.reinterpret_as_int()
  if off + sz <= self.raw_data.length() && sz > 0 {
    let data : FixedArray[Byte] = FixedArray::make(sz, b'\x00')
    for i = 0; i < sz; i = i + 1 {
      data[i] = self.raw_data[off + i]
    }
    Some(data)
  } else {
    None
  }
}
