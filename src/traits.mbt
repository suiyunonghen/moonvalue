pub(open) trait IUtf16StringBuilder {
  append(Self, Char) -> Unit
  end_string(Self) -> IString
}

pub impl IUtf16StringBuilder for Array[Char] with append(self, char : Char) -> Unit {
  self.push(char)
}

pub impl IUtf16StringBuilder for Array[Char] with end_string(self) -> IString {
  String::from_array(self)
}

pub(open) trait IString {
  charCodeAt(Self, Int) -> Int //utf16编码格式的
  length(Self) -> Int
  to_string(Self) -> String
}

pub impl Eq for IString with op_equal(self, other : IString) -> Bool {
  self.to_string() == other.to_string()
}

pub impl Hash for IString with hash_combine(self, hash : Hasher) -> Unit {
  hash.combine_string(self.to_string())
}

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

pub impl IString for String with charCodeAt(self, idx : Int) -> Int {
  self[idx].to_int()
}

pub impl IString for String with length(self) -> Int { self.length() }

pub impl IString for String with to_string(self) -> String { self }

type LittleEndian

pub fn LittleEndian::uint16(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    1 => bytes[0].to_uint()
    0 => 0
    _ => bytes[0].to_uint() | (bytes[1].to_uint() << 8)
  }
}

pub fn LittleEndian::uint16Bytes(v : UInt) -> Bytes {
  let result = Bytes::make(2, 0)
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result
}

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

pub fn LittleEndian::uint32Bytes(v : UInt) -> Bytes {
  let result = Bytes::make(4, 0)
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result[2] = (v >> 16).to_byte()
  result[3] = (v >> 24).to_byte()
  result
}

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

pub fn LittleEndian::uint64Bytes(v : UInt64) -> Bytes {
  let result = Bytes::make(8, 0)
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

type BigEndian

pub fn BigEndian::uint16(bytes : ArrayView[Byte]) -> UInt {
  match bytes.length() {
    1 => bytes[0].to_uint() << 8
    0 => 0
    _ => bytes[1].to_uint() | (bytes[0].to_uint() << 8)
  }
}

pub fn BigEndian::uint16Bytes(v : UInt) -> Bytes {
  let result = Bytes::make(2, 0)
  result[0] = (v >> 8).to_byte()
  result[1] = v.to_byte()
  result
}

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

pub fn BigEndian::uint32Bytes(v : UInt) -> Bytes {
  let result = Bytes::make(4, 0)
  result[0] = (v >> 24).to_byte()
  result[1] = (v >> 16).to_byte()
  result[2] = (v >> 8).to_byte()
  result[3] = v.to_byte()
  result
}

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

pub fn BigEndian::uint64Bytes(v : UInt64) -> Bytes {
  let result = Bytes::make(8, 0)
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

pub(open) trait IBinary: Show {
  length(Self) -> Int
  write_byte(Self, Int, Byte) -> Unit
  read_byte(Self, Int) -> Byte
  write_bool(Self, Int, Bool) -> Unit
  read_bool(Self, Int) -> Bool
  write_bytes(Self, Int, Bytes) -> Unit
  write_int16(Self, Int, Int, Bool) -> Unit
  write_int32(Self, Int, Int, Bool) -> Unit
  write_int64(Self, Int, Int64, Bool) -> Unit
  read_int16(Self, Int, Bool) -> Int
  read_int32(Self, Int, Bool) -> Int
  read_int64(Self, Int, Bool) -> Int64
  read_float(Self, Int) -> Float
  read_double(Self, Int) -> Double
  //create_utf16_str(Self) -> IUtf16StringBuilder
  //read_utf8(Self, Int, Int) -> IString!ConvertError
  //read_utf8string(Self, Int, Int) -> String!ConvertError
}

pub(open) trait ICopy: IBinary {
  copy_from(Self, Int, Self, Int, Int) -> Unit
  blit(Self, Int, Self, Int, Int) -> Unit
}

impl ICopy with copy_from(
  self,
  offset : Int,
  src : Self,
  srcFrom : Int,
  cpyLen : Int
) -> Unit {
  let mut leftLen = src.length() - srcFrom
  if leftLen == 0 {
    return
  }
  if leftLen > cpyLen {
    leftLen = cpyLen
  }
  for i = 0; i < leftLen; i = i + 1 {
    self.write_byte(offset + i, src.read_byte(srcFrom + i))
  }
}

impl ICopy with blit(
  self,
  offset : Int,
  src : Self,
  srcFrom : Int,
  cpyLen : Int
) -> Unit {
  self.copy_from(offset, src, srcFrom, cpyLen)
}

pub fn op_get(self : IBinary, offset : Int) -> Byte {
  let size = self.length()
  if offset >= size {
    panic()
  }
  self.read_byte(offset)
}

pub fn op_set(self : IBinary, offset : Int, v : Byte) -> Unit {
  let size = self.length()
  if offset >= size {
    panic()
  }
  self.write_byte(offset, v)
}

impl IBinary with read_float(self, offset : Int) -> Float {
  self.read_int32(offset, false).reinterpret_as_float()
}

impl IBinary with read_double(self, offset : Int) -> Double {
  self.read_int64(offset, false).reinterpret_as_double()
}

impl IBinary with write_bytes(self, offset : Int, b : Bytes) -> Unit {
  let mut idx = offset
  for v in b {
    self.write_byte(idx, v)
    idx = idx + 1
  }
}

impl IBinary with write_int16(
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

impl IBinary with write_int32(
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
  println(bytes)
  self.write_bytes(offset, bytes)
}

impl IBinary with write_int64(
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

impl IBinary with read_int16(self, offset : Int, littleEndian : Bool) -> Int {
  let bytes : Array[Byte] = [self.read_byte(offset), self.read_byte(offset + 1)]
  if littleEndian {
    LittleEndian::uint16(bytes[:]).reinterpret_as_int()
  } else {
    BigEndian::uint16(bytes[:]).reinterpret_as_int()
  }
}

impl IBinary with read_int32(self, offset : Int, littleEndian : Bool) -> Int {
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

impl IBinary with read_int64(self, offset : Int, littleEndian : Bool) -> Int64 {
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

impl IBinary with read_bool(self, offset : Int) -> Bool {
  self.read_byte(offset) == 1
}

impl IBinary with write_bool(self, offset : Int, value : Bool) -> Unit {
  if value {
    self.write_byte(offset, 1)
  } else {
    self.write_byte(offset, 0)
  }
}

// pub impl IBinary for Bytes with create_utf16_str(self) -> IUtf16StringBuilder {
//   let result : Array[Char] = Array::new()
//   result
// }

pub impl IBinary for Bytes with length(self) -> Int { self.length() }

pub impl IBinary for Bytes with write_byte(self, offset : Int, value : Byte) -> Unit {
  self[offset] = value
}

pub impl IBinary for Bytes with read_byte(self, offset : Int) -> Byte {
  self[offset]
}

pub impl ICopy for Bytes with blit(
  self,
  offset : Int,
  src : Bytes,
  srcFrom : Int,
  cpyLen : Int
) -> Unit {
  self.blit(offset, src, srcFrom, cpyLen)
}

pub impl ICopy for Bytes with copy_from(
  self,
  offset : Int,
  src : Bytes,
  srcFrom : Int,
  cpyLen : Int
) -> Unit {
  self.blit(offset, src, srcFrom, cpyLen)
}

struct BinaryView[B] {
  _source : B
  from : Int
  len : Int
} derive(Show)

pub fn newBinaryView[B : IBinary](
  src : B,
  from : Int,
  len : Int
) -> BinaryView[B] {
  { _source: src, from, len }
}

pub impl IBinary for BinaryView[IBinary] with length(self) -> Int { self.len }

pub impl IBinary for BinaryView[IBinary] with write_byte(
  self,
  offset : Int,
  v : Byte
) -> Unit {
  self._source.write_byte(self.from + offset, v)
}

pub impl IBinary for BinaryView[IBinary] with read_byte(self, offset : Int) -> Byte {
  self._source.read_byte(offset + self.from)
}

pub impl IBinary for BinaryView[IBinary] with write_bool(
  self,
  offset : Int,
  v : Bool
) -> Unit {
  self._source.write_bool(self.from + offset, v)
}

pub impl IBinary for BinaryView[IBinary] with read_bool(self, offset : Int) -> Bool {
  self._source.read_bool(self.from + offset)
}

pub impl IBinary for BinaryView[IBinary] with write_bytes(
  self,
  offset : Int,
  v : Bytes
) -> Unit {
  self._source.write_bytes(self.from + offset, v)
}

pub impl IBinary for BinaryView[IBinary] with write_int16(
  self,
  offset : Int,
  value : Int,
  littleEndian : Bool
) -> Unit {
  self._source.write_int16(self.from + offset, value, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with write_int32(
  self,
  offset : Int,
  value : Int,
  littleEndian : Bool
) -> Unit {
  self._source.write_int32(self.from + offset, value, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with write_int64(
  self,
  offset : Int,
  value : Int64,
  littleEndian : Bool
) -> Unit {
  self._source.write_int64(self.from + offset, value, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with read_int16(
  self,
  offset : Int,
  littleEndian : Bool
) -> Int {
  self._source.read_int16(self.from + offset, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with read_int32(
  self,
  offset : Int,
  littleEndian : Bool
) -> Int {
  self._source.read_int32(self.from + offset, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with read_int64(
  self,
  offset : Int,
  littleEndian : Bool
) -> Int64 {
  self._source.read_int64(self.from + offset, littleEndian)
}

pub impl IBinary for BinaryView[IBinary] with read_float(self, offset : Int) -> Float {
  self._source.read_float(self.from + offset)
}

pub impl IBinary for BinaryView[IBinary] with read_double(self, offset : Int) -> Double {
  self._source.read_double(self.from + offset)
}

struct StringView[T, B] {
  _source : B
  from : Int
  len : Int
  stringReader : (B, Int, Int) -> T!ConvertError
  mut _str : T?
}

pub fn StringView::newStringView[T : IString + Hash + Eq, B : IBinary](
  source : B,
  from : Int,
  len : Int,
  stringReader : (B, Int, Int) -> T!ConvertError
) -> StringView[T, B] {
  { _source: source, from, len, _str: None, stringReader }
}

pub fn value[T : IString + Hash + Eq, B : IBinary](
  self : StringView[T, B]
) -> T!ConvertError {
  match self._str {
    Some(v) => v
    _ => (self.stringReader)!(self._source, self.from, self.len)
  }
}

pub fn string[T : IString + Hash + Eq, B : IBinary](
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

pub impl IBinary for Array[Byte] with length(self) -> Int { self.length() }

pub impl IBinary for Array[Byte] with write_byte(
  self,
  offset : Int,
  byte : Byte
) -> Unit {
  self[offset] = byte
}

pub impl IBinary for Array[Byte] with read_byte(self, offset : Int) -> Byte {
  self[offset]
}
