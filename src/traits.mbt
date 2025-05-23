///| utf16 string interface
pub(open) trait IString {
  charCodeAt(Self, Int) -> Int //utf16编码格式的
  length(Self) -> Int
  to_string(Self) -> String = _
  to_utf8(Self) -> Array[Byte]!ConvertError = _
}

///|
pub impl Show for &IString with output(self, l : &Logger) -> Unit {
  l.write_string(IString::to_string(self))
}

///|
pub impl Show for &IString with to_string(self) -> String {
  IString::to_string(self)
}

///|
impl IString with to_utf8(self) -> Array[Byte]!ConvertError {
  let result = Array::new()
  let len = self.length()
  for i in 0..<len {
    let code = self.charCodeAt(i)
    if code <= UTF8_END1 {
      result.push(code.to_byte())
    } else if code >= UTF8_START2 && code <= UTF8_END2 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      result.push(((code >> 6) | 0xC0).to_byte())
      result.push(((code & 0x3f) | 0x80).to_byte())
    } else if code >= UTF8_START3 && code <= UTF8_END3 {
      //0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      result.push(((code >> 12) | 0xE0).to_byte())
      result.push((((code >> 6) & 0x3F) | 0x80).to_byte())
      result.push(((code & 0x3f) | 0x80).to_byte())
    } else {
      raise ConvertError("无效的Utf16编码")
    }
  }
  result
}

///|
pub impl Eq for &IString with op_equal(self, other : &IString) -> Bool {
  self.to_string() == other.to_string()
}

///|
pub impl Hash for &IString with hash_combine(self, hash : Hasher) -> Unit {
  hash.combine_string(self.to_string())
}

///|
impl IString with to_string(self) -> String {
  let l = self.length()
  if l == 0 {
    ""
  } else {
    let strArr : Array[Char] = Array::make(
      l,
      Char::from_int(self.charCodeAt(0)),
    )
    for i in 1..<l {
      strArr[i] = Char::from_int(self.charCodeAt(i))
    }
    String::from_array(strArr)
  }
}

///|
pub impl IString for String with charCodeAt(self, idx : Int) -> Int {
  self[idx].to_int()
}

///|
pub impl IString for String with length(self) -> Int {
  self.length()
}

///|
pub impl IString for String with to_string(self) -> String {
  self
}

///|
type LittleEndian

///|
pub fn LittleEndian::uint16(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    1 => bytes[0].to_uint()
    0 => 0
    _ => bytes[0].to_uint() | (bytes[1].to_uint() << 8)
  }
}

///|
pub fn LittleEndian::uint16Bytes(v : UInt) -> FixedArray[Byte] {
  let result = FixedArray::make(2, b'\x00')
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result
}

///|
pub fn LittleEndian::uint32(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    1 => bytes[0].to_uint()
    0 => 0
    2 => bytes[0].to_uint() | (bytes[1].to_uint() << 8)
    3 =>
      bytes[0].to_uint() |
      (bytes[1].to_uint() << 8) |
      (bytes[2].to_uint() << 16)
    _ =>
      bytes[0].to_uint() |
      (bytes[1].to_uint() << 8) |
      (bytes[2].to_uint() << 16) |
      (bytes[3].to_uint() << 24)
  }
}

///|
pub fn LittleEndian::uint32Bytes(v : UInt) -> FixedArray[Byte] {
  let result = FixedArray::make(4, b'\x00')
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result[2] = (v >> 16).to_byte()
  result[3] = (v >> 24).to_byte()
  result
}

///|
pub fn LittleEndian::uint64(bytes : ArrayView[Byte]) -> UInt64 {
  match bytes.length() {
    0 => 0
    1 => bytes[0].to_uint64()
    2 => bytes[0].to_uint64() | (bytes[1].to_uint64() << 8)
    3 =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16)
    4 =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16) |
      (bytes[3].to_uint64() << 24)
    5 =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16) |
      (bytes[3].to_uint64() << 24) |
      (bytes[4].to_uint64() << 32)
    6 =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16) |
      (bytes[3].to_uint64() << 24) |
      (bytes[4].to_uint64() << 32) |
      (bytes[5].to_uint64() << 40)
    7 =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16) |
      (bytes[3].to_uint64() << 24) |
      (bytes[4].to_uint64() << 32) |
      (bytes[5].to_uint64() << 40) |
      (bytes[6].to_uint64() << 48)
    _ =>
      bytes[0].to_uint64() |
      (bytes[1].to_uint64() << 8) |
      (bytes[2].to_uint64() << 16) |
      (bytes[3].to_uint64() << 24) |
      (bytes[4].to_uint64() << 32) |
      (bytes[5].to_uint64() << 40) |
      (bytes[6].to_uint64() << 48) |
      (bytes[7].to_uint64() << 56)
  }
}

///|
pub fn LittleEndian::uint64Bytes(v : UInt64) -> FixedArray[Byte] {
  let result = FixedArray::make(8, b'\x00')
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result[2] = (v >> 16).to_byte()
  result[3] = (v >> 24).to_byte()
  result[4] = (v >> 32).to_byte()
  result[5] = (v >> 40).to_byte()
  result[6] = (v >> 48).to_byte()
  result[7] = (v >> 56).to_byte()
  result
}

///|
type BigEndian

///|
pub fn BigEndian::uint16(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    1 => bytes[0].to_uint() << 8
    0 => 0
    _ => bytes[1].to_uint() | (bytes[0].to_uint() << 8)
  }
}

///|
pub fn BigEndian::uint16Bytes(v : UInt) -> FixedArray[Byte] {
  let result = FixedArray::make(2, b'\x00')
  result[0] = (v >> 8).to_byte()
  result[1] = v.to_byte()
  result
}

///|
pub fn BigEndian::uint32(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    0 => 0
    1 => bytes[0].to_uint() << 24
    2 => (bytes[1].to_uint() << 16) | (bytes[0].to_uint() << 24)
    3 =>
      (bytes[2].to_uint() << 8) |
      (bytes[1].to_uint() << 16) |
      (bytes[0].to_uint() << 24)
    _ =>
      bytes[3].to_uint() |
      (bytes[2].to_uint() << 8) |
      (bytes[1].to_uint() << 16) |
      (bytes[0].to_uint() << 24)
  }
}

///|
pub fn BigEndian::uint32Bytes(v : UInt) -> FixedArray[Byte] {
  let result = FixedArray::make(4, b'\x00')
  result[0] = (v >> 24).to_byte()
  result[1] = (v >> 16).to_byte()
  result[2] = (v >> 8).to_byte()
  result[3] = v.to_byte()
  result
}

///|
pub fn BigEndian::uint64(bytes : ArrayView[Byte]) -> UInt64 {
  match bytes.length() {
    0 => 0
    1 => bytes[0].to_uint64() << 56
    2 => (bytes[1].to_uint64() << 48) | (bytes[0].to_uint64() << 56)
    3 =>
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
    4 =>
      (bytes[3].to_uint64() << 32) |
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
    5 =>
      (bytes[4].to_uint64() << 24) |
      (bytes[3].to_uint64() << 32) |
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
    6 =>
      (bytes[5].to_uint64() << 16) |
      (bytes[4].to_uint64() << 24) |
      (bytes[3].to_uint64() << 32) |
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
    7 =>
      (bytes[6].to_uint64() << 8) |
      (bytes[5].to_uint64() << 16) |
      (bytes[4].to_uint64() << 24) |
      (bytes[3].to_uint64() << 32) |
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
    _ =>
      bytes[7].to_uint64() |
      (bytes[6].to_uint64() << 8) |
      (bytes[5].to_uint64() << 16) |
      (bytes[4].to_uint64() << 24) |
      (bytes[3].to_uint64() << 32) |
      (bytes[2].to_uint64() << 40) |
      (bytes[1].to_uint64() << 48) |
      (bytes[0].to_uint64() << 56)
  }
}

///|
pub fn BigEndian::uint64Bytes(v : UInt64) -> FixedArray[Byte] {
  let result = FixedArray::make(8, b'\x00')
  result[0] = (v >> 56).to_byte()
  result[1] = (v >> 48).to_byte()
  result[2] = (v >> 40).to_byte()
  result[3] = (v >> 32).to_byte()
  result[4] = (v >> 24).to_byte()
  result[5] = (v >> 16).to_byte()
  result[6] = (v >> 8).to_byte()
  result[7] = v.to_byte()
  result
}

///| binary reader
pub(open) trait IBinReader: Show {
  length(Self) -> Int
  read_byte(Self, Int) -> Byte
  read_bool(Self, Int) -> Bool = _
  read_int16(Self, Int, Bool) -> Int = _
  read_int32(Self, Int, Bool) -> Int = _
  read_int64(Self, Int, Bool) -> Int64 = _
  read_float(Self, Int) -> Float = _
  read_double(Self, Int) -> Double = _
}

///|
pub impl Show for &IBinReader with output(self, l : &Logger) -> Unit {
  l.write_string("blob[")
  let len = self.length()
  loop 0 {
    idx => {
      if idx == len {
        break
      }
      if idx == 0 {
        l.write_string("\{self.read_byte(idx)}")
      } else {
        l.write_string(",\{self.read_byte(idx)}")
      }
      continue idx + 1
    }
  }
  l.write_char(']')
}

///|
impl IBinReader with read_float(self, offset : Int) -> Float {
  self.read_int32(offset, false).reinterpret_as_float()
}

///|
impl IBinReader with read_double(self, offset : Int) -> Double {
  self.read_int64(offset, false).reinterpret_as_double()
}

///|
impl IBinReader with read_int16(self, offset : Int, littleEndian : Bool) -> Int {
  let bytes : Array[Byte] = [self.read_byte(offset), self.read_byte(offset + 1)]
  if littleEndian {
    LittleEndian::uint16(bytes[:]).reinterpret_as_int()
  } else {
    BigEndian::uint16(bytes[:]).reinterpret_as_int()
  }
}

///|
impl IBinReader with read_int32(self, offset : Int, littleEndian : Bool) -> Int {
  let bytes : Array[Byte] = [
    self.read_byte(offset),
    self.read_byte(offset + 1),
    self.read_byte(offset + 2),
    self.read_byte(offset + 3),
  ]
  if littleEndian {
    LittleEndian::uint32(bytes[:]).reinterpret_as_int()
  } else {
    BigEndian::uint32(bytes[:]).reinterpret_as_int()
  }
}

///|
impl IBinReader with read_int64(self, offset : Int, littleEndian : Bool) -> Int64 {
  let bytes : Array[Byte] = [
    self.read_byte(offset),
    self.read_byte(offset + 1),
    self.read_byte(offset + 2),
    self.read_byte(offset + 3),
    self.read_byte(offset + 4),
    self.read_byte(offset + 5),
    self.read_byte(offset + 6),
    self.read_byte(offset + 7),
  ]
  if littleEndian {
    LittleEndian::uint64(bytes[:]).reinterpret_as_int64()
  } else {
    BigEndian::uint64(bytes[:]).reinterpret_as_int64()
  }
}

///|
impl IBinReader with read_bool(self, offset : Int) -> Bool {
  self.read_byte(offset) == 1
}

///|
pub fn op_get(self : &IBinReader, offset : Int) -> Byte {
  let size = self.length()
  if offset >= size {
    panic()
  }
  self.read_byte(offset)
}

///| binary writer
pub(open) trait IBinWriter {
  write_byte(Self, Int, Byte) -> Unit
  write_bool(Self, Int, Bool) -> Unit = _
  write_bytes(Self, Int, FixedArray[Byte]) -> Unit = _
  write_int16(Self, Int, Int, Bool) -> Unit = _
  write_int32(Self, Int, Int, Bool) -> Unit = _
  write_int64(Self, Int, Int64, Bool) -> Unit = _
  write_double(Self, Int, Double) -> Unit = _
  write_float(Self, Int, Float) -> Unit = _
  append_byte(Self, Byte) -> Unit = _
  append_bool(Self, Bool) -> Unit = _
  append_int16(Self, Int, Bool) -> Unit = _
  append_int32(Self, Int, Bool) -> Unit = _
  append_int64(Self, Int64, Bool) -> Unit = _
  append_double(Self, Double) -> Unit = _
  append_float(Self, Float) -> Unit = _
  write_utf8(Self, &IString) -> Unit!ConvertError = _
}

///|
impl IBinWriter with write_utf8(self, str : &IString) -> Unit!ConvertError {
  let len = str.length()
  for i in 0..<len {
    let code = str.charCodeAt(i)
    if code <= UTF8_END1 {
      self.append_byte(code.to_byte())
    } else if code >= UTF8_START2 && code <= UTF8_END2 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      self.append_byte(((code >> 6) | 0xC0).to_byte())
      self.append_byte(((code & 0x3f) | 0x80).to_byte())
    } else if code >= UTF8_START3 && code <= UTF8_END3 {
      //0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      self.append_byte(((code >> 12) | 0xE0).to_byte())
      self.append_byte((((code >> 6) & 0x3F) | 0x80).to_byte())
      self.append_byte(((code & 0x3f) | 0x80).to_byte())
    } else {
      raise ConvertError("无效的Utf16编码")
    }
  }
}

///|
impl IBinWriter with append_byte(self, b : Byte) -> Unit {
  self.write_byte(-1, b)
}

///|
impl IBinWriter with append_bool(self, b : Bool) -> Unit {
  if b {
    self.write_byte(-1, 1)
  } else {
    self.write_byte(-1, 0)
  }
}

///|
impl IBinWriter with write_bool(self, offset : Int, value : Bool) -> Unit {
  if value {
    self.write_byte(offset, 1)
  } else {
    self.write_byte(offset, 0)
  }
}

///|
impl IBinWriter with write_bytes(self, offset : Int, b : FixedArray[Byte]) -> Unit {
  if offset < 0 {
    for v in b {
      self.write_byte(-1, v)
    }
  } else {
    let mut idx = offset
    for v in b {
      self.write_byte(idx, v)
      idx = idx + 1
    }
  }
}

///|
impl IBinWriter with write_int16(
  self,
  offset : Int,
  value : Int,
  littleEndian : Bool
) -> Unit {
  let bytes = if littleEndian {
    LittleEndian::uint16Bytes(value.reinterpret_as_uint())
  } else {
    BigEndian::uint16Bytes(value.reinterpret_as_uint())
  }
  self.write_bytes(offset, bytes)
}

///|
impl IBinWriter with append_int16(self, value : Int, littleEndian : Bool) -> Unit {
  self.write_int16(-1, value, littleEndian)
}

///|
impl IBinWriter with append_int32(self, value : Int, littleEndian : Bool) -> Unit {
  self.write_int32(-1, value, littleEndian)
}

///|
impl IBinWriter with append_int64(self, value : Int64, littleEndian : Bool) -> Unit {
  self.write_int64(-1, value, littleEndian)
}

///|
impl IBinWriter with append_double(self, value : Double) -> Unit {
  self.write_double(-1, value)
}

///|
impl IBinWriter with append_float(self, value : Float) -> Unit {
  self.write_float(-1, value)
}

///|
impl IBinWriter with write_int32(
  self,
  offset : Int,
  value : Int,
  littleEndian : Bool
) -> Unit {
  let bytes = if littleEndian {
    LittleEndian::uint32Bytes(value.reinterpret_as_uint())
  } else {
    BigEndian::uint32Bytes(value.reinterpret_as_uint())
  }
  self.write_bytes(offset, bytes)
}

///|
impl IBinWriter with write_int64(
  self,
  offset : Int,
  value : Int64,
  littleEndian : Bool
) -> Unit {
  let bytes = if littleEndian {
    LittleEndian::uint64Bytes(value.reinterpret_as_uint64())
  } else {
    BigEndian::uint64Bytes(value.reinterpret_as_uint64())
  }
  self.write_bytes(offset, bytes)
}

///|
impl IBinWriter with write_double(self, offset : Int, v : Double) -> Unit {
  self.write_int64(offset, v.reinterpret_as_int64(), false)
}

///|
impl IBinWriter with write_float(self, offset : Int, v : Float) -> Unit {
  self.write_int32(offset, v.reinterpret_as_int(), false)
}

///|
pub impl IBinReader for Bytes with length(self) -> Int {
  self.length()
}

///|
pub impl IBinReader for Bytes with read_byte(self, offset : Int) -> Byte {
  self[offset]
}

///|
pub impl IBinWriter for FixedArray[Byte] with write_byte(
  self,
  offset : Int,
  value : Byte
) -> Unit {
  self[offset] = value
}

///| share memory binary
struct BinaryView[B] {
  _source : B
  from : Int
  len : Int
} derive(Show)

///|
pub fn BinaryView::newBinaryView[B : IBinReader](
  src : B,
  from : Int,
  len : Int
) -> BinaryView[B] {
  { _source: src, from, len }
}

///|
pub impl IBinReader for BinaryView[&IBinReader] with length(self) -> Int {
  self.len
}

///|
pub impl IBinReader for BinaryView[&IBinReader] with read_bool(
  self,
  offset : Int
) -> Bool {
  self._source.read_bool(self.from + offset)
}

///|
pub impl IBinReader for BinaryView[&IBinReader] with read_byte(
  self,
  offset : Int
) -> Byte {
  self._source.read_byte(offset + self.from)
}

///| share memory string
struct StringView[T, B] {
  _source : B
  from : Int
  len : Int
  stringReader : (B, Int, Int) -> T!ConvertError
  mut _str : T?
} derive(Show)

///|
pub fn StringView::newStringView[T : IString + Hash + Eq, B : IBinReader](
  source : B,
  from : Int,
  len : Int,
  stringReader : (B, Int, Int) -> T!ConvertError
) -> StringView[T, B] {
  { _source: source, from, len, _str: None, stringReader }
}

///|
pub fn StringView::value[T : IString + Hash + Eq, B : IBinReader](
  self : StringView[T, B]
) -> T!ConvertError {
  match self._str {
    Some(v) => v
    _ => (self.stringReader)!(self._source, self.from, self.len)
  }
}

///|
pub fn string[T : IString + Hash + Eq, B : IBinReader](
  self : StringView[T, B]
) -> String {
  match self._str {
    Some(v) => v.to_string()
    _ =>
      match (self.stringReader)?(self._source, self.from, self.len) {
        Ok(v) => v.to_string()
        _ => ""
      }
  }
}

///|
pub impl IString for StringView[String, Bytes] with charCodeAt(
  self,
  index : Int
) -> Int {
  match self._str {
    Some(v) => v[index].to_int()
    _ =>
      match (self.stringReader)?(self._source, self.from, self.len) {
        Ok(str) => {
          self._str = Some(str)
          str[index].to_int()
        }
        Err(ConvertError(_)) => -1
      }
  }
}

///|
pub impl IString for StringView[String, Bytes] with length(self) -> Int {
  match self._str {
    Some(v) => v.length()
    _ =>
      match (self.stringReader)?(self._source, self.from, self.len) {
        Ok(str) => {
          self._str = Some(str)
          str.length()
        }
        Err(ConvertError(_)) => -1
      }
  }
}

///|
pub impl IString for StringView[String, Bytes] with to_string(self) -> String {
  match self._str {
    Some(v) => v.to_string()
    _ =>
      match (self.stringReader)?(self._source, self.from, self.len) {
        Ok(str) => {
          self._str = Some(str)
          str.to_string()
        }
        Err(ConvertError(_)) => ""
      }
  }
}

///|
pub impl IBinReader for Array[Byte] with length(self) -> Int {
  self.length()
}

///|
pub impl IBinReader for Array[Byte] with read_byte(self, offset : Int) -> Byte {
  self[offset]
}

///|
pub impl IBinWriter for Array[Byte] with write_byte(
  self,
  offset : Int,
  byte : Byte
) -> Unit {
  if offset < 0 || offset > self.length() {
    self.push(byte)
  } else {
    self[offset] = byte
  }
}

///| binary blit
pub(open) trait IBinBlit: IBinWriter + IBinReader {
  newBlit() -> Self
  as_binwriter(Self) -> &IBinWriter
  as_binreader(Self) -> &IBinReader
  blit(Self, Int, Self, Int, Int) -> Unit
  append_data(Self, Self) -> Unit
}

///|
impl IBinBlit for Array[Byte] with newBlit() -> Array[Byte] {
  Array::new()
}

///|
impl IBinBlit for Array[Byte] with as_binwriter(self) -> &IBinWriter {
  self
}

///|
impl IBinBlit for Array[Byte] with as_binreader(self) -> &IBinReader {
  self
}

///|
impl IBinBlit for Array[Byte] with blit(
  self,
  offset : Int,
  other : Array[Byte],
  from : Int,
  len : Int
) {
  if offset < 0 {
    other.blit_to(self, len~, src_offset=from, dst_offset=self.length())
  } else {
    other.blit_to(self, len~, src_offset=from, dst_offset=offset)
  }
}

///|
impl IBinBlit for Array[Byte] with append_data(self, other : Array[Byte]) -> Unit {
  self.append(other)
}
