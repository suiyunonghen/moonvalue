///|
/// https://bsonspec.org/spec.html
/// 
// priv enum BsonFormatCode {
//   BsonEof //0x00
//   BsonDouble //0x01 64-bit binary floating point
//   BsonString //0x02 UTF-8 string
//   BsonEmbeddedDoc //0x03 Embedded document
//   BsonArray //0x04
//   BsonBinary //0x05 Binary data
//   BsonUndefined //0x06 Undefined (value) — Deprecated
//   BsonObjectID //0x07 ObjectId (byte*12)
//   BsonBoolean //0x08 unsigned_byte(0)false unsigned_byte(1) true
//   BsonDateTime //0x09 UTC datetime
//   BsonNull //0x0A
//   BsonRegex //0x0B
//   BsonDbPointer //0x0C DBPointer — Deprecated (byte*12)
//   BsonJavaScript //0x0D JavaScript code w/ scope — Deprecated
//   BsonSymbol //0x0E Symbol. — Deprecated
//   BsonCodeWithScope //0x0F JavaScript code with scope — Deprecated
//   BsonInt32 //0x10
//   BsonTimestamp //0x11 Timestamp
//   BsonInt64 //0x12 
//   BsonDecimal128 //0x13 128-bit decimal floating point
//   BsonMaxKey //0x7f Max key
//   BsonMinKey //0xff Min key
// }

///| 
/// msgpack parse error
pub(all) type! BsonParserError {
  BsonEof
  InvalidateBsonDoc(String)
  InvalidateBsonDataType(String)
  InvalidateBsonKey(String)
  InvalidateStringValue(String)
  InvalidateBsonBin(String)
} derive(Show)

///| 
/// Bson parser
struct BsonParser[T, B] {
  _bsonData : B
  shareBinary : Bool
  stringReader : (B, Int, Int) -> T!ConvertError
  binReader : (B, Int, Int) -> B
  mut _offset : Int
}

///|
fn BsonParser::new[T : IString + Hash + Eq, B : IBinReader](
  shareBinary : Bool,
  binary : B,
  utf8Reader : (B, Int, Int) -> T!ConvertError,
  binReader : (B, Int, Int) -> B
) -> BsonParser[T, B] {
  {
    _bsonData: binary,
    shareBinary,
    _offset: 0,
    stringReader: utf8Reader,
    binReader,
  }
}

///|
pub fn parse[T : IString + Hash + Eq, B : IBinReader](
  self : BsonParser[T, B]
) -> MoonValue[T, B]!BsonParserError {
  self.parse_bson_doc!(None, NoKey_or_Array)
}

///|
fn parse_bson_doc[T : IString + Hash + Eq, B : IBinReader](
  self : BsonParser[T, B],
  parent : MoonValue[T, B]?,
  key : KeyInfo[T]
) -> MoonValue[T, B]!BsonParserError {
  let blen = self._bsonData.length()
  let remain_size = blen - self._offset
  if remain_size < 4 {
    raise InvalidateBsonDoc("doc data size out of range")
  }
  let bson_doc_size = self._bsonData.read_int32(self._offset, true)
  self._offset += 4
  if bson_doc_size > remain_size {
    raise InvalidateBsonDoc("doc data size out of range")
  }
  let strMap = match parent {
    Some(p) =>
      match key {
        Str(keyStr) => p.add_key_object(keyStr, StrMap)
        IntKey(intKey) => p.add_intkey_object(intKey, StrMap)
        NoKey_or_Array => p.add_arr_object(StrMap)
      }
    _ => { parent, data: VT_Obj(value={}) }
  }
  while self._offset < blen {
    let (bson_type, key) = self.parse_key_type!(blen, false)
    match bson_type {
      0x03 =>
        //doc
        match self.parse_bson_doc?(Some(strMap), Str(key.unwrap())) {
          Err(e) => raise e
          _ => ()
        }
      0x04 =>
        //array
        match self.parse_bson_array?(Some(strMap), Str(key.unwrap())) {
          Err(e) => raise e
          _ => ()
        }
      0x00 =>
        //eof      
        break
      _ =>
        match self.parse_value?(bson_type, blen, strMap, Some(key.unwrap())) {
          Err(e) => raise e
          _ => ()
        }
    }
  }
  return strMap
}

///|
fn parse_bson_array[T : IString + Hash + Eq, B : IBinReader](
  self : BsonParser[T, B],
  parent : MoonValue[T, B]?,
  key : KeyInfo[T]
) -> MoonValue[T, B]!BsonParserError {
  let blen = self._bsonData.length()
  let remain_size = blen - self._offset
  if remain_size < 4 {
    raise InvalidateBsonDoc("doc data size out of range")
  }
  let bson_doc_size = self._bsonData.read_int32(self._offset, true)
  self._offset += 4
  if bson_doc_size > remain_size {
    raise InvalidateBsonDoc("doc data size out of range")
  }
  let array = match parent {
    Some(p) =>
      match key {
        Str(keyStr) => p.add_key_object(keyStr, Array)
        IntKey(intKey) => p.add_intkey_object(intKey, Array)
        NoKey_or_Array => p.add_arr_object(Array)
      }
    _ => { parent, data: VT_Array(value=[]) }
  }
  while self._offset < blen {
    let (bson_type, _) = self.parse_key_type!(blen, true)
    match bson_type {
      0x03 =>
        //doc                
        match self.parse_bson_doc?(Some(array), NoKey_or_Array) {
          Err(e) => raise e
          _ => ()
        }
      0x04 =>
        match self.parse_bson_array?(Some(array), NoKey_or_Array) {
          Err(e) => raise e
          _ => ()
        }
      0x00 =>
        //eof      
        break
      _ =>
        match self.parse_value?(bson_type, blen, array, None) {
          Err(e) => raise e
          _ => ()
        }
    }
  }
  return array
}

///|
fn parse_key_type[T : IString + Hash + Eq, B : IBinReader](
  self : BsonParser[T, B],
  blen : Int,
  is_arr_ele : Bool
) -> (Byte, T?)!BsonParserError {
  let bson_type = self._bsonData.read_byte(self._offset)
  self._offset += 1
  if bson_type == 0 {
    return (0, None)
  }
  //读取字段,cstring,ansic,utf8
  let key_offset = for i in self._offset..<blen {
    if self._bsonData.read_byte(i) == 0 {
      break i
    }
  } else {
    raise BsonParserError::InvalidateBsonKey("key must endwith 0")
  }
  if is_arr_ele {
    self._offset = key_offset + 1
    return (bson_type, None)
  }
  match
    (self.stringReader)?(
      self._bsonData,
      self._offset,
      key_offset - self._offset,
    ) {
    Ok(key) => {
      self._offset = key_offset + 1
      return (bson_type, Some(key))
    }
    _ => raise BsonParserError::InvalidateBsonKey("key must utf8")
  }
}

///|
fn parse_value[T : IString + Hash + Eq, B : IBinReader](
  self : BsonParser[T, B],
  bson_type : Byte,
  data_size : Int,
  parent : MoonValue[T, B],
  key : T?
) -> Unit!BsonParserError {
  match bson_type {
    0x01 => {
      //double
      let d = self._bsonData
        .read_int64(self._offset, true)
        .reinterpret_as_double()
      match key {
        Some(k) => parent.set_key_double(k, d)
        _ => parent.set_index_double(-1, d)
      }
      self._offset += 8
    }
    0x02 => {
      let strlen = self._bsonData.read_int32(self._offset, true)
      self._offset += 4
      if self.shareBinary {
        match key {
          Some(k) =>
            parent.set_key_share_string(
              k,
              StringView::newStringView(
                self._bsonData,
                self._offset,
                strlen,
                self.stringReader,
              ),
            )
          _ =>
            parent.set_index_share_string(
              -1,
              StringView::newStringView(
                self._bsonData,
                self._offset,
                strlen,
                self.stringReader,
              ),
            )
        }
        self._offset += strlen
      } else {
        match (self.stringReader)?(self._bsonData, self._offset, strlen) {
          Ok(str) => {
            self._offset += strlen
            match key {
              Some(k) => parent.set_key_string(k, str)
              _ => parent.set_index_string(-1, str)
            }
          }
          _ =>
            raise BsonParserError::InvalidateStringValue(
              "invalidate utf8 string",
            )
        }
      }
    }
    0x05 => {
      //binary
      let mut binlen = self._bsonData.read_int32(self._offset, true)
      self._offset += 4
      //子类型
      let sub_type = self._bsonData.read_byte(self._offset)
      self._offset += 1
      match sub_type {
        0 => {
          //	Generic binary subtype
          if binlen + self._offset > data_size {
            raise InvalidateBsonBin("binary length out of range")
          }
          if self.shareBinary {
            match key {
              Some(k) =>
                parent.set_key_share_bin(
                  k,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                )
              _ =>
                parent.set_index_share_bin(
                  -1,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                )
            }
          } else {
            let bin = (self.binReader)(self._bsonData, self._offset, binlen)
            match key {
              Some(k) => parent.set_key_bin(k, bin)
              _ => parent.set_index_bin(-1, bin)
            }
          }
          self._offset += binlen
        }
        2 => {
          //Binary (Old)
          let nextOffs = self._offset + binlen
          binlen = self._bsonData.read_int32(self._offset, true)
          self._offset += 4
          if binlen + self._offset > data_size {
            raise InvalidateBsonBin("binary length out of range")
          }
          if self.shareBinary {
            match key {
              Some(k) =>
                parent.set_key_share_bin(
                  k,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                )
              _ =>
                parent.set_index_share_bin(
                  -1,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                )
            }
          } else {
            let bin = (self.binReader)(self._bsonData, self._offset, binlen)
            match key {
              Some(k) => parent.set_key_bin(k, bin)
              _ => parent.set_index_bin(-1, bin)
            }
          }
          self._offset = nextOffs
        }
        _ => {
          //统一用扩展类型来表示
          if binlen + self._offset > data_size {
            raise InvalidateBsonBin("binary length out of range")
          }
          if self.shareBinary {
            match key {
              Some(k) =>
                parent.set_key_share_ext(
                  k,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                  sub_type.to_int(),
                )
              _ =>
                parent.set_index_share_ext(
                  -1,
                  BinaryView::newBinaryView(
                    self._bsonData,
                    self._offset,
                    binlen,
                  ),
                  sub_type.to_int(),
                )
            }
          } else {
            let bin = (self.binReader)(self._bsonData, self._offset, binlen)
            match key {
              Some(k) => parent.set_key_ext(k, bin, sub_type.to_int())
              _ => parent.set_index_ext(-1, bin, sub_type.to_int())
            }
          }
          self._offset += binlen
        }
        // 1=>{
        //     //Function
        //     ()
        // }
        // 3=>{
        //     //UUID (Old)
        //     ()
        // }
        // 4=>{
        //     //	UUID
        //     ()
        // }
        // 5=>{
        //     //MD5
        //     ()
        // }
        // 6=>{
        //     //	Encrypted BSON value
        //     ()
        // }
        // 7=>{
        //     //Compressed BSON column
        //     ()
        // }
        // 8=>{
        //     //	Sensitive
        //     ()
        // }
        // 9=>{
        //     //	Vector
        //     ()
        // }
        // 128..<255=>{
        //     //	unsigned_byte(128)—unsigned_byte(255)	User defined
        //     ()
        // }            
      }
    }
    0x07 => {
      //ObjectID ,12字节
      if self.shareBinary {
        match key {
          Some(k) =>
            parent.set_key_share_ext(
              k,
              BinaryView::newBinaryView(self._bsonData, self._offset, 12),
              263,
            ) //256+7)
          _ =>
            parent.set_index_share_ext(
              -1,
              BinaryView::newBinaryView(self._bsonData, self._offset, 12),
              263,
            )
        }
      } else {
        let bin = (self.binReader)(self._bsonData, self._offset, 12)
        match key {
          Some(k) => parent.set_key_ext(k, bin, 263)
          _ => parent.set_index_ext(-1, bin, 263)
        }
      }
      self._offset += 12
    }
    0x08 => {
      match key {
        Some(k) =>
          parent.set_key_bool(k, self._bsonData.read_byte(self._offset) == 1)
        _ =>
          parent.set_index_bool(-1, self._bsonData.read_byte(self._offset) == 1)
      }
      self._offset += 1
    }
    0x09 => {
      //DateTime Unix 纪元(1970 年 1 月 1 日)以来的毫秒数
      let date = @datetime.DateTime::from_unix_mseconds(
        self._bsonData.read_int64(self._offset, true),
      )
      self._offset += 8
      match key {
        Some(k) => parent.set_key_datetime(k, date)
        _ => parent.set_index_datetime(-1, date)
      }
    }
    0x0A =>
      //null
      match parent.data {
        VT_Array(value=arr) => arr.push({ parent: Some(parent), data: VT_Null })
        _ => ()
      }
    0x0B =>
      //Regex
      ()
    0x0C =>
      //dbPoint
      ()
    0x0D =>
      //javascript
      ()
    0x0E =>
      //symbol
      ()
    0x0F =>
      //CodeWithScope
      ()
    0x10 => {
      //int32            
      match key {
        Some(k) =>
          parent.set_key_int64(
            k,
            self._bsonData.read_int32(self._offset, true).to_int64(),
          )
        _ =>
          parent.set_index_int64(
            -1,
            self._bsonData.read_int32(self._offset, true).to_int64(),
          )
      }
      self._offset += 4
    }
    0x11 => {
      //Timestamp 64 位值 MongoDB的Timestamp类型实际上是一个64位的值，其中高位32位是时间戳（以秒为单位，自Unix纪元（1970年1月1日）以来的秒数），
      //低位32位是一个递增的序数，用于在同一秒内对操作进行排序。这种类型主要用于MongoDB的复制和集群环境中，以确保操作的顺序性和一致性
      //这里直接使用扩展类型来
      if self.shareBinary {
        match key {
          Some(k) =>
            parent.set_key_share_ext(
              k,
              BinaryView::newBinaryView(self._bsonData, self._offset, 8),
              273,
            ) //256+17)
          _ =>
            parent.set_index_share_ext(
              -1,
              BinaryView::newBinaryView(self._bsonData, self._offset, 8),
              273,
            )
        }
      } else {
        let bin = (self.binReader)(self._bsonData, self._offset, 8)
        match key {
          Some(k) => parent.set_key_ext(k, bin, 273)
          _ => parent.set_index_ext(-1, bin, 273)
        }
      }
      self._offset += 8
    }
    0x12 => {
      //int64
      match key {
        Some(k) =>
          parent.set_key_int64(k, self._bsonData.read_int64(self._offset, true))
        _ =>
          parent.set_index_int64(
            -1,
            self._bsonData.read_int64(self._offset, true),
          )
      }
      self._offset += 8
    }
    0xff =>
      //minKey
      ()
    0x7F =>
      //maxKey
      ()
    _ => ()
  }
}

///|
pub fn BsonParser::newparser_with_str_array(
  shareBinary : Bool,
  binary : Array[Byte]
) -> BsonParser[String, Array[Byte]] {
  {
    _bsonData: binary,
    shareBinary,
    _offset: 0,
    stringReader: read_utf8string,
    binReader,
  }
}

///|
pub fn BsonParser::newparser_with_str_bytes(
  shareBinary : Bool,
  binary : Bytes
) -> BsonParser[String, Bytes] {
  {
    _bsonData: binary,
    shareBinary,
    _offset: 0,
    stringReader: read_utf8string_fromBytes,
    binReader: bytesReader,
  }
}

///|
test "parse_bson" {
  // let arr : Array[Byte] = [
  //   139, 0, 0, 0, 16, 49, 0, 255, 255, 255, 255, 1, 100, 111, 117, 98, 108, 101,
  //   230, 181, 174, 231, 130, 185, 230, 149, 176, 0, 46, 144, 160, 248, 49, 182, 64,
  //   64, 16, 78, 111, 0, 1, 0, 0, 0, 2, 229, 167, 147, 229, 144, 141, 0, 10, 0, 0,
  //   0, 228, 184, 141, 229, 190, 151, 233, 151, 178, 0, 3, 105, 110, 102, 111, 0,
  //   66, 0, 0, 0, 16, 97, 103, 101, 0, 38, 0, 0, 0, 8, 105, 115, 109, 101, 110, 0,
  //   1, 2, 103, 105, 116, 104, 117, 98, 0, 32, 0, 0, 0, 104, 116, 116, 112, 115, 58,
  //   47, 47, 103, 105, 116, 104, 117, 98, 46, 99, 111, 109, 47, 115, 117, 105, 121,
  //   117, 110, 111, 110, 103, 104, 101, 110, 0, 0, 0,
  // ]
  let arr : Array[Byte] = [
    98, 1, 0, 0, 16, 49, 0, 255, 255, 255, 255, 1, 100, 111, 117, 98, 108, 101, 230,
    181, 174, 231, 130, 185, 230, 149, 176, 0, 46, 144, 160, 248, 49, 182, 64, 64,
    16, 78, 111, 0, 1, 0, 0, 0, 2, 229, 167, 147, 229, 144, 141, 0, 10, 0, 0, 0,
    228, 184, 141, 229, 190, 151, 233, 151, 178, 0, 3, 105, 110, 102, 111, 0, 66,
    0, 0, 0, 16, 97, 103, 101, 0, 38, 0, 0, 0, 8, 105, 115, 109, 101, 110, 0, 1,
    2, 103, 105, 116, 104, 117, 98, 0, 32, 0, 0, 0, 104, 116, 116, 112, 115, 58,
    47, 47, 103, 105, 116, 104, 117, 98, 46, 99, 111, 109, 47, 115, 117, 105, 121,
    117, 110, 111, 110, 103, 104, 101, 110, 0, 0, 4, 115, 116, 117, 100, 101, 110,
    116, 115, 0, 205, 0, 0, 0, 3, 48, 0, 99, 0, 0, 0, 2, 110, 97, 109, 101, 0, 11,
    0, 0, 0, 228, 184, 141, 229, 190, 151, 233, 151, 178, 49, 0, 16, 97, 103, 101,
    0, 38, 0, 0, 0, 8, 105, 115, 119, 111, 109, 101, 110, 0, 0, 2, 103, 105, 116,
    104, 117, 98, 0, 42, 0, 0, 0, 104, 116, 116, 112, 115, 58, 47, 47, 103, 105,
    116, 104, 117, 98, 46, 99, 111, 109, 47, 115, 117, 105, 121, 117, 110, 111, 110,
    103, 104, 101, 110, 47, 109, 111, 111, 110, 118, 97, 108, 117, 101, 0, 0, 10,
    49, 0, 3, 50, 0, 92, 0, 0, 0, 2, 110, 97, 109, 101, 0, 5, 0, 0, 0, 103, 105,
    114, 108, 0, 16, 97, 103, 101, 0, 39, 0, 0, 0, 8, 105, 115, 119, 111, 109, 101,
    110, 0, 1, 2, 103, 105, 116, 104, 117, 98, 0, 41, 0, 0, 0, 104, 116, 116, 112,
    115, 58, 47, 47, 103, 105, 116, 104, 117, 98, 46, 99, 111, 109, 47, 115, 117,
    105, 121, 117, 110, 111, 110, 103, 104, 101, 110, 47, 100, 97, 116, 101, 116,
    105, 109, 101, 0, 0, 0, 0,
  ]
  let parser : BsonParser[String, Array[Byte]] = BsonParser::newparser_with_str_array(
    false, arr,
  )
  match parser.parse?() {
    Ok(v) => {
      inspect!(v["students"].unwrap()["1"].unwrap().to_string(), content="null")
      println(v.to_string())
    }
    Err(e) => println(e)
  }
}
