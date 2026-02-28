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
/// Returns 0 if offset is out of bounds
fn read_u32_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  // Boundary check: need 4 bytes starting at offset
  if offset < 0 || offset + 3 >= bytes.length() {
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
/// Returns 0 if offset is out of bounds
fn read_u64_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  // Boundary check: need 8 bytes starting at offset
  if offset < 0 || offset + 7 >= bytes.length() {
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
/// Returns 0 if offset is out of bounds
fn read_u16_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  // Boundary check: need 2 bytes starting at offset
  if offset < 0 || offset + 1 >= bytes.length() {
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
  // Minimum ELF header size is 52 bytes (ELF32) or 64 bytes (ELF64)
  if bytes.length() < 52 {
    return None
  }

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
/// First tries Section Headers, then falls back to Program Headers
pub fn ElfFile::get_code_sections(
  self : ElfFile,
) -> Array[(UInt, FixedArray[Byte])] {
  let result : Array[(UInt, FixedArray[Byte])] = []

  // First try Section Headers (more accurate)
  if self.is_64bit {
    for shdr in self.sections64 {
      // Check if this section has executable flag
      if (shdr.sh_flags & SHF_EXECINSTR) != 0U && shdr.sh_size > 0U {
        let offset = shdr.sh_offset.reinterpret_as_int()
        let size = shdr.sh_size.reinterpret_as_int()
        if offset + size <= self.raw_data.length() {
          let code : FixedArray[Byte] = FixedArray::make(size, b'\x00')
          for i = 0; i < size; i = i + 1 {
            code[i] = self.raw_data[offset + i]
          }
          result.push((shdr.sh_addr, code))
        }
      }
    }
  } else {
    for shdr in self.sections32 {
      // Check if this section has executable flag
      if (shdr.sh_flags & SHF_EXECINSTR) != 0U && shdr.sh_size > 0U {
        let offset = shdr.sh_offset.reinterpret_as_int()
        let size = shdr.sh_size.reinterpret_as_int()
        if offset + size <= self.raw_data.length() {
          let code : FixedArray[Byte] = FixedArray::make(size, b'\x00')
          for i = 0; i < size; i = i + 1 {
            code[i] = self.raw_data[offset + i]
          }
          result.push((shdr.sh_addr, code))
        }
      }
    }
  }

  // If no sections found with executable flag, fall back to Program Headers
  // This handles ELF files without section headers (e.g., stripped binaries)
  if result.length() == 0 {
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

///|
/// Symbol table entry for 32-bit ELF
pub struct Elf32Symbol {
  st_name : UInt // Symbol name (string table index)
  st_value : UInt // Symbol value
  st_size : UInt // Symbol size
  st_info : Byte // Symbol type and binding
  st_other : Byte // Symbol visibility
  st_shndx : UInt // Section index
} derive(Show)

///|
/// Symbol table entry for 64-bit ELF
pub struct Elf64Symbol {
  st_name : UInt // Symbol name (string table index)
  st_info : Byte // Symbol type and binding
  st_other : Byte // Symbol visibility
  st_shndx : UInt // Section index
  st_value : UInt // Symbol value
  st_size : UInt // Symbol size
} derive(Show)

///|
/// Symbol type enumeration
pub enum SymbolType {
  NoType
  Object
  Func
  Section
  File
  Unknown
} derive(Show, Eq)

///|
/// Symbol binding enumeration
pub enum SymbolBinding {
  Local
  Global
  Weak
  Unknown
} derive(Show, Eq)

///|
/// Parsed symbol information
pub struct Symbol {
  name : String
  value : UInt
  size : UInt
  sym_type : SymbolType
  binding : SymbolBinding
  section_index : UInt
} derive(Show)

///|
/// Get symbol type from st_info
pub fn Symbol::type_from_info(info : Byte) -> SymbolType {
  let typ = (info.to_uint() & 0xFU).reinterpret_as_int()
  match typ {
    0 => SymbolType::NoType
    1 => SymbolType::Object
    2 => SymbolType::Func
    3 => SymbolType::Section
    4 => SymbolType::File
    _ => SymbolType::Unknown
  }
}

///|
/// Get symbol binding from st_info
pub fn Symbol::binding_from_info(info : Byte) -> SymbolBinding {
  let bind = ((info.to_uint() >> 4) & 0xFU).reinterpret_as_int()
  match bind {
    0 => SymbolBinding::Local
    1 => SymbolBinding::Global
    2 => SymbolBinding::Weak
    _ => SymbolBinding::Unknown
  }
}

///|
/// Parse a 32-bit symbol table entry
fn parse_elf32_symbol(bytes : FixedArray[Byte], offset : Int) -> Elf32Symbol {
  Elf32Symbol::{
    st_name: read_u32_le(bytes, offset),
    st_value: read_u32_le(bytes, offset + 4),
    st_size: read_u32_le(bytes, offset + 8),
    st_info: bytes[offset + 12],
    st_other: bytes[offset + 13],
    st_shndx: read_u16_le(bytes, offset + 14),
  }
}

///|
/// Parse a 64-bit symbol table entry
fn parse_elf64_symbol(bytes : FixedArray[Byte], offset : Int) -> Elf64Symbol {
  Elf64Symbol::{
    st_name: read_u32_le(bytes, offset),
    st_info: bytes[offset + 4],
    st_other: bytes[offset + 5],
    st_shndx: read_u16_le(bytes, offset + 6),
    st_value: read_u64_le(bytes, offset + 8),
    st_size: read_u64_le(bytes, offset + 16),
  }
}

///|
/// Read a null-terminated string from bytes
fn read_string(bytes : FixedArray[Byte], offset : Int) -> String {
  let result : Array[Char] = []
  let mut i = offset
  while i < bytes.length() && bytes[i] != b'\x00' {
    result.push(bytes[i].to_int().unsafe_to_char())
    i = i + 1
  }
  let mut s = ""
  for c in result {
    s = s + c.to_string()
  }
  s
}

///|
/// Find section by type
fn find_section_by_type(
  sections32 : Array[Elf32SectionHeader],
  sections64 : Array[Elf64SectionHeader],
  is_64bit : Bool,
  sh_type : UInt,
) -> Int {
  if is_64bit {
    for i = 0; i < sections64.length(); i = i + 1 {
      if sections64[i].sh_type == sh_type {
        return i
      }
    }
  } else {
    for i = 0; i < sections32.length(); i = i + 1 {
      if sections32[i].sh_type == sh_type {
        return i
      }
    }
  }
  -1
}

///|
/// Get string table section index
fn get_strtab_section_index(elf : ElfFile) -> Int {
  if elf.is_64bit {
    match elf.header64 {
      Some(h) => h.e_shstrndx.reinterpret_as_int()
      None => -1
    }
  } else {
    match elf.header32 {
      Some(h) => h.e_shstrndx.reinterpret_as_int()
      None => -1
    }
  }
}

///|
/// Parse symbol table and return array of symbols
pub fn ElfFile::get_symbols(self : ElfFile) -> Array[Symbol] {
  let result : Array[Symbol] = []

  // Find .symtab section
  let symtab_idx = find_section_by_type(
    self.sections32,
    self.sections64,
    self.is_64bit,
    SHT_SYMTAB,
  )
  if symtab_idx < 0 {
    // Try .dynsym
    let dynsym_idx = find_section_by_type(
      self.sections32,
      self.sections64,
      self.is_64bit,
      SHT_DYNSYM,
    )
    if dynsym_idx < 0 {
      return result
    }
    return self.parse_symbols_from_section(dynsym_idx)
  }

  self.parse_symbols_from_section(symtab_idx)
}

///|
/// Parse symbols from a specific section index
fn ElfFile::parse_symbols_from_section(
  self : ElfFile,
  symtab_idx : Int,
) -> Array[Symbol] {
  let result : Array[Symbol] = []

  // Get symbol table section info
  let symtab_info = if self.is_64bit {
    if symtab_idx >= self.sections64.length() {
      return result
    }
    let sh = self.sections64[symtab_idx]
    Some((sh.sh_offset, sh.sh_size, sh.sh_entsize, sh.sh_link))
  } else {
    if symtab_idx >= self.sections32.length() {
      return result
    }
    let sh = self.sections32[symtab_idx]
    Some((sh.sh_offset, sh.sh_size, sh.sh_entsize, sh.sh_link))
  }

  match symtab_info {
    Some((sym_offset, sym_size, sym_entsize, strtab_idx)) => {
      // Get string table section info
      let strtab_info = if self.is_64bit {
        if strtab_idx.reinterpret_as_int() >= self.sections64.length() {
          None
        } else {
          let sh = self.sections64[strtab_idx.reinterpret_as_int()]
          Some((sh.sh_offset, sh.sh_size))
        }
      } else if strtab_idx.reinterpret_as_int() >= self.sections32.length() {
        None
      } else {
        let sh = self.sections32[strtab_idx.reinterpret_as_int()]
        Some((sh.sh_offset, sh.sh_size))
      }

      match strtab_info {
        Some((str_offset, _)) => {
          // Parse symbols
          let entsize = sym_entsize.reinterpret_as_int()
          let offset = sym_offset.reinterpret_as_int()
          let size = sym_size.reinterpret_as_int()
          let num_symbols = size / entsize

          for i = 0; i < num_symbols; i = i + 1 {
            let sym_offset = offset + i * entsize
            if self.is_64bit {
              let sym = parse_elf64_symbol(self.raw_data, sym_offset)
              let name = read_string(
                self.raw_data,
                str_offset.reinterpret_as_int() +
                sym.st_name.reinterpret_as_int(),
              )
              result.push(Symbol::{
                name,
                value: sym.st_value,
                size: sym.st_size,
                sym_type: Symbol::type_from_info(sym.st_info),
                binding: Symbol::binding_from_info(sym.st_info),
                section_index: sym.st_shndx,
              })
            } else {
              let sym = parse_elf32_symbol(self.raw_data, sym_offset)
              let name = read_string(
                self.raw_data,
                str_offset.reinterpret_as_int() +
                sym.st_name.reinterpret_as_int(),
              )
              result.push(Symbol::{
                name,
                value: sym.st_value,
                size: sym.st_size,
                sym_type: Symbol::type_from_info(sym.st_info),
                binding: Symbol::binding_from_info(sym.st_info),
                section_index: sym.st_shndx,
              })
            }
          }
        }
        None => ignore(())
      }
    }
    None => ignore(())
  }

  result
}

///|
/// Get function symbols only
pub fn ElfFile::get_function_symbols(self : ElfFile) -> Array[Symbol] {
  let all_symbols = self.get_symbols()
  let funcs : Array[Symbol] = []
  for sym in all_symbols {
    if sym.sym_type == SymbolType::Func && sym.size > 0U {
      funcs.push(sym)
    }
  }
  funcs
}

///|
/// Find symbol by address
pub fn ElfFile::find_symbol_by_addr(self : ElfFile, addr : UInt) -> Symbol? {
  let symbols = self.get_symbols()
  for sym in symbols {
    if sym.value <= addr && addr < sym.value + sym.size {
      return Some(sym)
    }
  }
  None
}

///|
/// Get section name by index
pub fn ElfFile::get_section_name(self : ElfFile, section_idx : Int) -> String {
  let shstrndx = get_strtab_section_index(self)
  if shstrndx < 0 {
    return ""
  }

  let str_offset = if self.is_64bit {
    if section_idx >= self.sections64.length() {
      return ""
    }
    let sh = self.sections64[section_idx]
    let strtab = self.sections64[shstrndx]
    strtab.sh_offset.reinterpret_as_int() + sh.sh_name.reinterpret_as_int()
  } else {
    if section_idx >= self.sections32.length() {
      return ""
    }
    let sh = self.sections32[section_idx]
    let strtab = self.sections32[shstrndx]
    strtab.sh_offset.reinterpret_as_int() + sh.sh_name.reinterpret_as_int()
  }

  if str_offset >= self.raw_data.length() {
    return ""
  }
  read_string(self.raw_data, str_offset)
}

///|
/// Find section by name
pub fn ElfFile::find_section_by_name(self : ElfFile, name : String) -> Int {
  let num_sections = if self.is_64bit {
    self.sections64.length()
  } else {
    self.sections32.length()
  }

  for i = 0; i < num_sections; i = i + 1 {
    let section_name = self.get_section_name(i)
    if section_name == name {
      return i
    }
  }
  -1
}

///|
/// Get .rodata section (read-only data)
pub fn ElfFile::get_rodata_section(self : ElfFile) -> FixedArray[Byte]? {
  let idx = self.find_section_by_name(".rodata")
  if idx < 0 {
    return None
  }

  match self.get_section(idx) {
    Some((_addr, offset, size)) => {
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
    None => None
  }
}

///|
/// Extract string literals from .rodata section
/// Returns a map of virtual address to string content
pub fn ElfFile::extract_strings(self : ElfFile) -> Map[UInt, String] {
  let result : Map[UInt, String] = {}

  // Find .rodata section
  let idx = self.find_section_by_name(".rodata")
  if idx < 0 {
    return result
  }

  match self.get_section(idx) {
    Some((vaddr, offset, size)) => {
      let off = offset.reinterpret_as_int()
      let sz = size.reinterpret_as_int()
      if off + sz > self.raw_data.length() || sz <= 0 {
        return result
      }

      // Scan for null-terminated strings
      let mut i = 0
      while i < sz {
        // Skip non-printable characters
        while i < sz {
          let c = self.raw_data[off + i].to_int()
          if c >= 32 && c < 127 { // Printable ASCII
            break
          }
          i = i + 1
        }

        if i >= sz {
          break
        }

        // Start of potential string
        let _start = i
        let str_addr = vaddr + i.reinterpret_as_uint()

        // Collect printable characters
        let chars : Array[Char] = []
        while i < sz {
          let c = self.raw_data[off + i].to_int()
          if c == 0 { // Null terminator
            break
          }
          if c >= 32 && c < 127 {
            chars.push(c.unsafe_to_char())
          } else {
            // Non-printable in middle, discard this string
            chars.clear()
            break
          }
          i = i + 1
        }

        // Save if valid string (at least 2 chars)
        if chars.length() >= 2 {
          let mut s = ""
          for c in chars {
            s = s + c.to_string()
          }
          result[str_addr] = s
        }

        i = i + 1 // Skip null terminator
      }
    }
    None => ()
  }

  result
}

///|
/// Relocation entry for 32-bit ELF (REL format - no addend)
pub struct Elf32Rel {
  r_offset : UInt // Address where to apply relocation
  r_info : UInt // Symbol index and relocation type
} derive(Show)

///|
/// Relocation entry for 32-bit ELF (RELA format - with addend)
pub struct Elf32Rela {
  r_offset : UInt // Address where to apply relocation
  r_info : UInt // Symbol index and relocation type
  r_addend : Int // Addend
} derive(Show)

///|
/// Relocation entry for 64-bit ELF (REL format - no addend)
pub struct Elf64Rel {
  r_offset : UInt // Address where to apply relocation
  r_info : UInt // Symbol index and relocation type
} derive(Show)

///|
/// Relocation entry for 64-bit ELF (RELA format - with addend)
pub struct Elf64Rela {
  r_offset : UInt // Address where to apply relocation
  r_info : UInt // Symbol index and relocation type
  r_addend : Int // Addend
} derive(Show)

///|
/// Parsed relocation information
pub struct Relocation {
  offset : UInt // Address where to apply relocation
  sym_index : UInt // Symbol table index
  rel_type : UInt // Relocation type (R_RISCV_*)
  addend : Int // Addend (0 for REL, actual value for RELA)
  sym_name : String // Symbol name (resolved after parsing)
  section_name : String // Section name where relocation applies
} derive(Show)

///|
/// Extract symbol index from r_info (32-bit)
pub fn get_symbol_index_32(info : UInt) -> UInt {
  info >> 8
}

///|
/// Extract relocation type from r_info (32-bit)
pub fn get_reloc_type_32(info : UInt) -> UInt {
  info & 0xFFU
}

///|
/// Extract symbol index from r_info (64-bit)
pub fn get_symbol_index_64(info : UInt) -> UInt {
  info >> 32
}

///|
/// Extract relocation type from r_info (64-bit)
pub fn get_reloc_type_64(info : UInt) -> UInt {
  info & 0xFFFFFFFFU
}

///|
/// Parse a 32-bit REL entry
fn parse_elf32_rel(bytes : FixedArray[Byte], offset : Int) -> Elf32Rel {
  Elf32Rel::{
    r_offset: read_u32_le(bytes, offset),
    r_info: read_u32_le(bytes, offset + 4),
  }
}

///|
/// Parse a 32-bit RELA entry
fn parse_elf32_rela(bytes : FixedArray[Byte], offset : Int) -> Elf32Rela {
  Elf32Rela::{
    r_offset: read_u32_le(bytes, offset),
    r_info: read_u32_le(bytes, offset + 4),
    r_addend: read_u32_le(bytes, offset + 8).reinterpret_as_int(),
  }
}

///|
/// Parse a 64-bit REL entry
fn parse_elf64_rel(bytes : FixedArray[Byte], offset : Int) -> Elf64Rel {
  Elf64Rel::{
    r_offset: read_u64_le(bytes, offset),
    r_info: read_u64_le(bytes, offset + 8),
  }
}

///|
/// Parse a 64-bit RELA entry
fn parse_elf64_rela(bytes : FixedArray[Byte], offset : Int) -> Elf64Rela {
  Elf64Rela::{
    r_offset: read_u64_le(bytes, offset),
    r_info: read_u64_le(bytes, offset + 8),
    r_addend: read_u64_le(bytes, offset + 16).reinterpret_as_int(),
  }
}

///|
/// Get relocation type name for RISC-V
pub fn get_riscv_reloc_name(rel_type : UInt) -> String {
  match rel_type {
    0U => "R_RISCV_NONE"
    1U => "R_RISCV_32"
    2U => "R_RISCV_64"
    3U => "R_RISCV_RELATIVE"
    4U => "R_RISCV_COPY"
    5U => "R_RISCV_JUMP_SLOT"
    6U => "R_RISCV_TLS_DTPMOD32"
    7U => "R_RISCV_TLS_DTPMOD64"
    8U => "R_RISCV_TLS_DTPREL32"
    9U => "R_RISCV_TLS_DTPREL64"
    10U => "R_RISCV_TLS_TPREL32"
    11U => "R_RISCV_TLS_TPREL64"
    16U => "R_RISCV_BRANCH"
    17U => "R_RISCV_JAL"
    18U => "R_RISCV_CALL"
    19U => "R_RISCV_CALL_PLT"
    20U => "R_RISCV_GOT_HI20"
    21U => "R_RISCV_TLS_GOT_HI20"
    22U => "R_RISCV_TLS_GD_HI20"
    23U => "R_RISCV_PCREL_HI20"
    24U => "R_RISCV_PCREL_LO12_I"
    25U => "R_RISCV_PCREL_LO12_S"
    26U => "R_RISCV_HI20"
    27U => "R_RISCV_LO12_I"
    28U => "R_RISCV_LO12_S"
    29U => "R_RISCV_LO12_PCREL_I"
    30U => "R_RISCV_LO12_PCREL_S"
    43U => "R_RISCV_ALIGN"
    44U => "R_RISCV_RVC_BRANCH"
    45U => "R_RISCV_RVC_JUMP"
    48U => "R_RISCV_SUB6"
    49U => "R_RISCV_SUB8"
    50U => "R_RISCV_SUB16"
    51U => "R_RISCV_SUB32"
    52U => "R_RISCV_SUB64"
    53U => "R_RISCV_ADD16"
    54U => "R_RISCV_ADD32"
    55U => "R_RISCV_ADD64"
    _ => "R_RISCV_UNKNOWN(" + rel_type.to_string() + ")"
  }
}

///|
/// Get relocations from a section by index
fn ElfFile::get_relocations_from_section(
  self : ElfFile,
  section_idx : Int,
  symbols : Array[Symbol],
) -> Array[Relocation] {
  let relocs : Array[Relocation] = []

  if self.is_64bit {
    match self.sections64[section_idx] {
      section => {
        let sh_type = section.sh_type
        let offset = section.sh_offset.reinterpret_as_int()
        let size = section.sh_size.reinterpret_as_int()
        let entsize = section.sh_entsize.reinterpret_as_int()
        let sec_name = self.get_section_name(section_idx)

        // Check if it's REL or RELA section
        if sh_type == SHT_REL && entsize == 16 {
          // 64-bit REL entries
          let mut pos = 0
          while pos + 16 <= size {
            let rel = parse_elf64_rel(self.raw_data, offset + pos)
            let sym_idx = get_symbol_index_64(rel.r_info)
            let rel_type = get_reloc_type_64(rel.r_info)

            // Get symbol name
            let sym_name = if sym_idx.reinterpret_as_int() < symbols.length() {
              symbols[sym_idx.reinterpret_as_int()].name
            } else {
              ""
            }

            relocs.push(Relocation::{
              offset: rel.r_offset,
              sym_index: sym_idx,
              rel_type,
              addend: 0,
              sym_name,
              section_name: sec_name,
            })
            pos = pos + 16
          }
        } else if sh_type == SHT_RELA && entsize == 24 {
          // 64-bit RELA entries
          let mut pos = 0
          while pos + 24 <= size {
            let rela = parse_elf64_rela(self.raw_data, offset + pos)
            let sym_idx = get_symbol_index_64(rela.r_info)
            let rel_type = get_reloc_type_64(rela.r_info)

            // Get symbol name
            let sym_name = if sym_idx.reinterpret_as_int() < symbols.length() {
              symbols[sym_idx.reinterpret_as_int()].name
            } else {
              ""
            }

            relocs.push(Relocation::{
              offset: rela.r_offset,
              sym_index: sym_idx,
              rel_type,
              addend: rela.r_addend,
              sym_name,
              section_name: sec_name,
            })
            pos = pos + 24
          }
        }
      }
    }
  } else {
    match self.sections32[section_idx] {
      section => {
        let sh_type = section.sh_type
        let offset = section.sh_offset.reinterpret_as_int()
        let size = section.sh_size.reinterpret_as_int()
        let entsize = section.sh_entsize.reinterpret_as_int()
        let sec_name = self.get_section_name(section_idx)

        // Check if it's REL or RELA section
        if sh_type == SHT_REL && entsize == 8 {
          // 32-bit REL entries
          let mut pos = 0
          while pos + 8 <= size {
            let rel = parse_elf32_rel(self.raw_data, offset + pos)
            let sym_idx = get_symbol_index_32(rel.r_info)
            let rel_type = get_reloc_type_32(rel.r_info)

            // Get symbol name
            let sym_name = if sym_idx.reinterpret_as_int() < symbols.length() {
              symbols[sym_idx.reinterpret_as_int()].name
            } else {
              ""
            }

            relocs.push(Relocation::{
              offset: rel.r_offset,
              sym_index: sym_idx,
              rel_type,
              addend: 0,
              sym_name,
              section_name: sec_name,
            })
            pos = pos + 8
          }
        } else if sh_type == SHT_RELA && entsize == 12 {
          // 32-bit RELA entries
          let mut pos = 0
          while pos + 12 <= size {
            let rela = parse_elf32_rela(self.raw_data, offset + pos)
            let sym_idx = get_symbol_index_32(rela.r_info)
            let rel_type = get_reloc_type_32(rela.r_info)

            // Get symbol name
            let sym_name = if sym_idx.reinterpret_as_int() < symbols.length() {
              symbols[sym_idx.reinterpret_as_int()].name
            } else {
              ""
            }

            relocs.push(Relocation::{
              offset: rela.r_offset,
              sym_index: sym_idx,
              rel_type,
              addend: rela.r_addend,
              sym_name,
              section_name: sec_name,
            })
            pos = pos + 12
          }
        }
      }
    }
  }

  relocs
}

///|
/// Get all relocations from the ELF file
pub fn ElfFile::get_relocations(self : ElfFile) -> Array[Relocation] {
  let all_relocs : Array[Relocation] = []
  let symbols = self.get_symbols()

  let section_count = self.section_count()
  for i = 0; i < section_count; i = i + 1 {
    let relocs = self.get_relocations_from_section(i, symbols)
    for r in relocs {
      all_relocs.push(r)
    }
  }

  all_relocs
}

///|
/// Get relocations for a specific section
pub fn ElfFile::get_relocations_for_section(
  self : ElfFile,
  section_name : String,
) -> Array[Relocation] {
  let result : Array[Relocation] = []
  let all_relocs = self.get_relocations()

  for r in all_relocs {
    if r.section_name == section_name {
      result.push(r)
    }
  }

  result
}

///|
/// Find relocation at a specific address
pub fn ElfFile::find_relocation_at(self : ElfFile, addr : UInt) -> Relocation? {
  let all_relocs = self.get_relocations()

  for r in all_relocs {
    if r.offset == addr {
      return Some(r)
    }
  }

  None
}

///|
/// Apply relocations to get resolved addresses
/// Returns a map from relocation offset to resolved symbol address
pub fn ElfFile::apply_relocations(self : ElfFile) -> Map[UInt, UInt] {
  let result : Map[UInt, UInt] = {}
  let symbols = self.get_symbols()

  for reloc in self.get_relocations() {
    // For most RISC-V relocations, the resolved address is symbol value + addend
    let sym_idx = reloc.sym_index.reinterpret_as_int()
    if sym_idx < symbols.length() {
      let sym = symbols[sym_idx]
      let resolved = sym.value + reloc.addend.reinterpret_as_uint()
      result[reloc.offset] = resolved
    }
  }

  result
}

///|
/// Format relocation information
pub fn format_relocation(reloc : Relocation) -> String {
  let type_name = get_riscv_reloc_name(reloc.rel_type)
  let offset_hex = format_hex_uint(reloc.offset)

  if reloc.sym_name.length() > 0 {
    let addend_str = if reloc.addend != 0 {
      if reloc.addend > 0 {
        " + " + reloc.addend.to_string()
      } else {
        " - " + (-reloc.addend).to_string()
      }
    } else {
      ""
    }
    offset_hex + ": " + type_name + " -> " + reloc.sym_name + addend_str
  } else {
    offset_hex + ": " + type_name
  }
}

///|
/// Format hex uint with 0x prefix
fn format_hex_uint(val : UInt) -> String {
  // Convert UInt to hex string manually
  let mut result = ""
  let mut v = val
  let hex_chars = "0123456789abcdef"

  if v == 0U {
    return "0x0"
  }

  let digits : Array[Char] = []
  while v > 0U {
    let digit = (v & 0xFU).reinterpret_as_int()
    digits.push(hex_chars[digit].unsafe_to_char())
    v = v >> 4
  }

  // Reverse digits
  result = "0x"
  for i = digits.length() - 1; i >= 0; i = i - 1 {
    result = result + digits[i].to_string()
  }

  result
}
