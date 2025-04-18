///|
priv enum MsgPackFormatCode {
  FmtCodeNil //0xc0
  FmtCodeUnUsed //0xc1
  FmtCodeFalse //0xc2
  FmtCodeTrue //0xc3
  FmtCodeBin8(len~ : UInt) //0xc4
  FmtCodeBin16(len~ : UInt) //0xc5
  FmtCodeBin32(len~ : UInt) //0xc6
  FmtCodeExt8(len~ : UInt, extType~ : Int) //0xc7
  FmtCodeExt16(len~ : UInt, extType~ : Int) //0xc8
  FmtCodeExt32(len~ : UInt, extType~ : Int) //0xc9
  FmtCodeFloat //0xca
  FmtCodeDouble //0xcb
  FmtCodeUInt8(value~ : Int) //0xcc
  FmtCodeUInt16(value~ : Int) //0xcd
  FmtCodeUInt32(value~ : Int) //0xce
  FmtCodeUInt64(value~ : UInt64) //0xcf
  FmtCodeInt8(value~ : Int) //0xd0
  FmtCodeInt16(value~ : Int) //0xd1
  FmtCodeInt32(value~ : Int) //0xd2
  FmtCodeInt64(value~ : Int64) //0xd3
  FmtCodeFixExt1(extType~ : Int) //0xd4
  FmtCodeFixExt2(extType~ : Int) //0xd5
  FmtCodeFixExt4(extType~ : Int) //0xd6
  FmtCodeFixExt8(extType~ : Int) //0xd7
  FmtCodeFixExt16(extType~ : Int) //0xd8
  FmtCodeStr8(len~ : UInt) //0xd9
  FmtCodeStr16(len~ : UInt) //0xda
  FmtCodeStr32(len~ : UInt) //0xdb
  FmtCodeArray16(len~ : UInt) //0xdc
  FmtCodeArray32(len~ : UInt) //0xdd
  FmtCodeMap16(len~ : UInt) //0xde
  FmtCodeMap32(len~ : UInt) //0xdf  
  FmtCodeFixInt(value~ : Int) //0x00-0x7f
  FmtCodeFixMap(len~ : UInt) //0x80-0x8f
  FmtCodeFixArray(len~ : UInt) //0x90-0x9f
  FmtCodeFixStr(len~ : UInt) //0xa0-0xbf  
  FmtCodeNegFixInt(value~ : Int) //0xe0-0xff  小负数
} derive(Show)

///| msgpack parser
struct MsgPackParser[T, B] {
  _packData : B
  shareBinary : Bool
  stringReader : (B, Int, Int) -> T!ConvertError
  binReader : (B, Int, Int) -> B
  mut _offset : Int
}

///|
fn MsgPackParser::new[T : IString + Hash + Eq, B : IBinReader](
  shareBinary : Bool,
  binary : B,
  utf8Reader : (B, Int, Int) -> T!ConvertError,
  binReader : (B, Int, Int) -> B
) -> MsgPackParser[T, B] {
  {
    _packData: binary,
    shareBinary,
    _offset: 0,
    stringReader: utf8Reader,
    binReader,
  }
}

///|
fn detectionFmtCode[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> MsgPackFormatCode {
  let formatCode = self._packData.read_byte(self._offset)
  self._offset += 1
  match formatCode {
    0xc0 => FmtCodeNil
    0xc1 => FmtCodeUnUsed
    0xc2 => FmtCodeFalse
    0xc3 => FmtCodeTrue
    0xc4 => FmtCodeBin8(len=self.parse_u8().reinterpret_as_uint())
    0xc5 => FmtCodeBin16(len=self.parse_u16().reinterpret_as_uint())
    0xc6 => FmtCodeBin32(len=self.parse_u32())
    0xc7 =>
      FmtCodeExt8(
        len=self.parse_u8().reinterpret_as_uint(),
        extType=self.parse_i8(),
      )
    0xc8 =>
      FmtCodeExt16(
        len=self.parse_u16().reinterpret_as_uint(),
        extType=self.parse_i8(),
      )
    0xc9 => FmtCodeExt32(len=self.parse_u32(), extType=self.parse_i8())
    0xca => FmtCodeFloat
    0xcb => FmtCodeDouble
    0xcc => FmtCodeUInt8(value=self.parse_u8())
    0xcd => FmtCodeUInt16(value=self.parse_u16())
    0xce => FmtCodeUInt32(value=self.parse_u32().reinterpret_as_int())
    0xcf => FmtCodeUInt64(value=self.parse_u64())
    0xd0 => FmtCodeInt8(value=self.parse_i8())
    0xd1 => FmtCodeInt16(value=self.parse_i16())
    0xd2 => FmtCodeInt32(value=self.parse_u32().reinterpret_as_int())
    0xd3 => FmtCodeInt64(value=self.parse_u64().reinterpret_as_int64())
    0xd4 => FmtCodeFixExt1(extType=self.parse_i8())
    0xd5 => FmtCodeFixExt2(extType=self.parse_i8())
    0xd6 => FmtCodeFixExt4(extType=self.parse_i8())
    0xd7 => FmtCodeFixExt8(extType=self.parse_i8())
    0xd8 => FmtCodeFixExt16(extType=self.parse_i8())
    0xd9 => FmtCodeStr8(len=self.parse_u8().reinterpret_as_uint())
    0xda => FmtCodeStr16(len=self.parse_u16().reinterpret_as_uint())
    0xdb => FmtCodeStr32(len=self.parse_u32())
    0xdc => FmtCodeArray16(len=self.parse_u16().reinterpret_as_uint())
    0xdd => FmtCodeArray32(len=self.parse_u32())
    0xde => FmtCodeMap16(len=self.parse_u16().reinterpret_as_uint())
    0xdf => FmtCodeMap32(len=self.parse_u32())
    _ =>
      if formatCode >= 0x00 && formatCode <= 0x7f {
        FmtCodeFixInt(value=formatCode.to_int())
      } else if formatCode >= 0x80 && formatCode <= 0x8f {
        FmtCodeFixMap(len=formatCode.to_uint() & 0x0f)
      } else if formatCode >= 0x90 && formatCode <= 0x9f {
        FmtCodeFixArray(len=formatCode.to_uint() & 0x0f)
      } else if formatCode >= 0xa0 && formatCode <= 0xbf {
        FmtCodeFixStr(len=formatCode.to_uint() & 0x1f)
      } else if formatCode >= 0xe0 && formatCode <= 0xff {
        FmtCodeNegFixInt(value=formatCode.to_int() - 256)
      } else {
        FmtCodeUnUsed
      }
  }
}

///|
fn parse_u8[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Int {
  let result = self._packData.read_byte(self._offset).to_int()
  self._offset += 1
  result
}

///|
fn parse_i8[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Int {
  let mut result = self._packData.read_byte(self._offset).to_int()
  if result > 127 {
    result -= 256
  }
  self._offset += 1
  result
}

///|
fn parse_u16[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Int {
  let result = self._packData.read_int16(self._offset, false)
  self._offset += 2
  result
}

///|
fn parse_i16[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Int {
  let mut result = self._packData.read_int16(self._offset, false)
  if result > 32767 {
    result -= 65536
  }
  self._offset += 2
  result
}

///|
fn parse_u32[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> UInt {
  let result = self._packData
    .read_int32(self._offset, false)
    .reinterpret_as_uint()
  self._offset += 4
  result
}

///|
fn parse_u64[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> UInt64 {
  let result = self._packData
    .read_int64(self._offset, false)
    .reinterpret_as_uint64()
  self._offset += 8
  result
}

///|
fn parse_float[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Float {
  let result = self._packData.read_float(self._offset)
  self._offset += 4
  result
}

///|
fn parse_double[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Double {
  let result = self._packData.read_double(self._offset)
  self._offset += 8
  result
}

///| parse msgpack
pub fn MsgPackParser::parse[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> MoonValue[T, B]!MsgPackParserError {
  self.parse_value!(self.detectionFmtCode(), None, KeyInfo::NoKey_or_Array)
}

///|
priv enum KeyInfo[T] {
  NoKey_or_Array
  Str(T)
  IntKey(Int64)
}

///| msgpack parse error
pub(all) type! MsgPackParserError {
  InvalidateMsgPackMapType(String)
  ErrorUtf8String(String)
  ErrorExtError(String)
  ErrorKey(String)
  ErrorIntKey(String)
}

///|
fn parse_key[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> T!MsgPackParserError {
  let code = self.detectionFmtCode()
  match code {
    FmtCodeFixStr(len=strLen)
    | FmtCodeStr8(len=strLen)
    | FmtCodeStr16(len=strLen)
    | FmtCodeStr32(len=strLen) => {
      let strLen = strLen.reinterpret_as_int()
      match (self.stringReader)?(self._packData, self._offset, strLen) {
        Err(ConvertError(str)) => raise ErrorUtf8String(str)
        Ok(value) => {
          self._offset += strLen
          value
        }
      }
    }
    _ => raise ErrorKey("invalidate map key code")
  }
}

///|
fn parse_intKey[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B]
) -> Int64!MsgPackParserError {
  let code = self.detectionFmtCode()
  match code {
    FmtCodeUInt8(value=vInt)
    | FmtCodeUInt32(value=vInt)
    | FmtCodeUInt16(value=vInt) => vInt.to_int64()
    FmtCodeInt8(value=vInt)
    | FmtCodeFixInt(value=vInt)
    | FmtCodeNegFixInt(value=vInt)
    | FmtCodeInt32(value=vInt)
    | FmtCodeInt16(value=vInt) => vInt.to_int64()
    FmtCodeUInt64(value=vInt) => vInt.reinterpret_as_int64()
    FmtCodeInt64(value=vInt) => vInt
    _ => raise ErrorIntKey("invalidate int map key code")
  }
}

///|
fn MsgPackParser::parse_value[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B],
  fmtCode : MsgPackFormatCode,
  parent : MoonValue[T, B]?,
  key : KeyInfo[T]
) -> MoonValue[T, B]!MsgPackParserError {
  match fmtCode {
    FmtCodeFixMap(len=mapLen)
    | FmtCodeMap16(len=mapLen)
    | FmtCodeMap32(len=mapLen) => {
      //先探测一下key是int还是string，然后知道用intmap      
      let code = self._packData.read_byte(self._offset)
      let result = if (code >= 0xd9 && code <= 0xdb) ||
        (code >= 0xa0 && code <= 0xbf) {
        let strMap = match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.add_key_object(keyStr, StrMap)
              IntKey(intKey) => p.add_intkey_object(intKey, StrMap)
              NoKey_or_Array => p.add_arr_object(StrMap)
            }
          _ => {
            let v = { parent, data: VT_Obj(value={}) }
            v
          }
        }
        for i in 0..<mapLen.reinterpret_as_int() {
          let key = self.parse_key!()
          let _ = self.parse_value!(
            self.detectionFmtCode(),
            Some(strMap),
            Str(key),
          )

        }
        strMap
      } else if (code >= 0xcc && code <= 0xd3) ||
        code <= 0x7f ||
        (code >= 0xe0 && code <= 0xff) {
        let intMap = match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.add_key_object(keyStr, IntMap)
              IntKey(intKey) => p.add_intkey_object(intKey, IntMap)
              _ => p.add_arr_object(IntMap)
            }
          _ => {
            let v = { parent, data: VT_IntKeyObj(value={}) }
            v
          }
        }
        for i in 0..<mapLen.reinterpret_as_int() {
          let key = self.parse_intKey!()
          let _ = self.parse_value!(
            self.detectionFmtCode(),
            Some(intMap),
            IntKey(key),
          )

        }
        intMap
      } else {
        //无效的内容
        raise InvalidateMsgPackMapType(
          "The key of the map can only be integers and strings",
        )
      }
      return result
    }
    FmtCodeFixArray(len=arrLen)
    | FmtCodeArray16(len=arrLen)
    | FmtCodeArray32(len=arrLen) => {
      let result = match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.add_key_object(strKey, Array)
            IntKey(intKey) => p.add_intkey_object(intKey, Array)
            _ => p.add_arr_object(Array)
          }
        None => { parent, data: VT_Array(value=[]) }
      }
      loop 0 {
        i => {
          if i.reinterpret_as_uint() == arrLen {
            break
          }
          let _ = self.parse_value!(
            self.detectionFmtCode(),
            Some(result),
            NoKey_or_Array,
          )
          continue i + 1
        }
      }
      return result
    }
    FmtCodeFixStr(len=strLen)
    | FmtCodeStr8(len=strLen)
    | FmtCodeStr16(len=strLen)
    | FmtCodeStr32(len=strLen) => {
      let strLen = strLen.reinterpret_as_int()
      if self.shareBinary {
        let view : StringView[T, B] = StringView::newStringView(
          self._packData,
          self._offset,
          strLen,
          self.stringReader,
        )
        self._offset += strLen
        match parent {
          Some(p) => {
            match key {
              Str(keystr) => p.set_key_share_string(keystr, view)
              IntKey(intKey) => p.set_intkey_share_string(intKey, view)
              _ => p.set_index_share_string(-1, view)
            }
            return { parent, data: VT_ShareString(value=view) }
          }
          _ => return { parent, data: VT_ShareString(value=view) }
        }
      } else {
        match (self.stringReader)?(self._packData, self._offset, strLen) {
          Err(ConvertError(str)) => raise ErrorUtf8String(str)
          Ok(val) => {
            self._offset += strLen
            match parent {
              Some(p) => {
                match key {
                  Str(keystr) => p.set_key_string(keystr, val)
                  IntKey(intKey) => p.set_intkey_string(intKey, val)
                  _ => p.set_index_string(-1, val)
                }
                return { parent, data: VT_String(value=val) }
              }
              _ => return { parent, data: VT_String(value=val) }
            }
          }
        }
      }
    }
    FmtCodeFalse => {
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_bool(strKey, false)
            IntKey(intKey) => p.set_intkey_bool(intKey, false)
            _ => p.set_index_bool(-1, false)
          }
        _ => ()
      }
      { parent, data: VT_False }
    }
    FmtCodeTrue => {
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_bool(strKey, true)
            IntKey(intKey) => p.set_intkey_bool(intKey, true)
            _ => p.set_index_bool(-1, true)
          }
        _ => ()
      }
      { parent, data: VT_True }
    }
    FmtCodeFloat => {
      let float = self.parse_float()
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_float(strKey, float)
            IntKey(intKey) => p.set_intkey_float(intKey, float)
            _ => p.set_index_float(-1, float)
          }
        _ => ()
      }
      { parent, data: VT_Float(value=float) }
    }
    FmtCodeDouble => {
      let double = self.parse_double()
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_double(strKey, double)
            IntKey(intKey) => p.set_intkey_double(intKey, double)
            _ => p.set_index_double(-1, double)
          }
        _ => ()
      }
      { parent, data: VT_Double(value=double) }
    }
    FmtCodeNil | FmtCodeUnUsed => { parent, data: VT_Null }
    FmtCodeBin8(len=binLen)
    | FmtCodeBin16(len=binLen)
    | FmtCodeBin32(len=binLen) => {
      let binLen = binLen.reinterpret_as_int()
      if self.shareBinary {
        let view : BinaryView[B] = BinaryView::newBinaryView(
          self._packData,
          self._offset,
          binLen,
        )
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.set_key_share_bin(keyStr, view)
              IntKey(intKey) => p.set_intkey_share_bin(intKey, view)
              _ => p.set_index_share_bin(-1, view)
            }
          None => ()
        }
        return { parent, data: VT_ShareBin(value=view) }
      } else {
        let bin = (self.binReader)(self._packData, self._offset, binLen)
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.set_key_bin(keyStr, bin)
              IntKey(intKey) => p.set_intkey_bin(intKey, bin)
              _ => p.set_index_bin(-1, bin)
            }
          None => ()
        }
        return { parent, data: VT_Bin(value=bin) }
      }
    }
    FmtCodeExt8(len=extLen, extType=exType) => {
      if extLen == 0 {
        raise ErrorExtError("ExtLen Error")
      }
      if exType == -1 {
        //96位日期时间 linux时间戳
        let nsec = self.parse_u32() //纳秒
        let sec = self.parse_u64()
        let ms = (sec * 1000 + (nsec / 1000000).to_uint64()).reinterpret_as_int64()
        let date = @datetime.DateTime::from_unix_mseconds(ms)
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.set_key_datetime(keyStr, date)
              IntKey(intKey) => p.set_intkey_datetime(intKey, date)
              _ => p.set_index_datetime(-1, date)
            }
          _ => ()
        }
        return { parent, data: VT_DateTime(value=date) }
      }
      self.parse_ext(parent, key, exType, extLen.reinterpret_as_int())
    }
    FmtCodeExt16(len=extLen, extType=exType)
    | FmtCodeExt32(len=extLen, extType=exType) => {
      if extLen == 0 {
        raise ErrorExtError("ExtLen Error")
      }
      self.parse_ext(parent, key, exType, extLen.reinterpret_as_int())
    }
    FmtCodeUInt8(value=vInt)
    | FmtCodeUInt32(value=vInt)
    | FmtCodeUInt16(value=vInt) => {
      let vInt = vInt.to_int64()
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_int64(strKey, vInt)
            IntKey(intKey) => p.set_intkey_int64(intKey, vInt)
            _ => p.set_index_int64(-1, vInt)
          }
        _ => ()
      }
      { parent, data: VT_Int(value=vInt) }
    }
    FmtCodeInt8(value=vInt)
    | FmtCodeFixInt(value=vInt)
    | FmtCodeNegFixInt(value=vInt)
    | FmtCodeInt32(value=vInt)
    | FmtCodeInt16(value=vInt) => {
      let vInt = vInt.to_int64()
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_int64(strKey, vInt)
            IntKey(intKey) => p.set_intkey_int64(intKey, vInt)
            _ => p.set_index_int64(-1, vInt)
          }
        _ => ()
      }
      { parent, data: VT_Int(value=vInt) }
    }
    FmtCodeUInt64(value=vInt) => {
      let vInt = vInt.reinterpret_as_int64()
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_int64(strKey, vInt)
            IntKey(intKey) => p.set_intkey_int64(intKey, vInt)
            _ => p.set_index_int64(-1, vInt)
          }
        _ => ()
      }
      { parent, data: VT_Int(value=vInt) }
    }
    FmtCodeInt64(value=vInt) => {
      match parent {
        Some(p) =>
          match key {
            Str(strKey) => p.set_key_int64(strKey, vInt)
            IntKey(intKey) => p.set_intkey_int64(intKey, vInt)
            _ => p.set_index_int64(-1, vInt)
          }
        _ => ()
      }
      { parent, data: VT_Int(value=vInt) }
    }
    FmtCodeFixExt1(extType=extype) => self.parse_ext(parent, key, extype, 1)
    FmtCodeFixExt2(extType=extype) => self.parse_ext(parent, key, extype, 2)
    FmtCodeFixExt4(extType=extype) => {
      if extype == -1 {
        //32位时间,就是Unix 1970-1-1经过的秒数
        let sec = self.parse_u32()
        let date = @datetime.DateTime::from_unix_mseconds(sec.to_int64() * 1000)
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.set_key_datetime(keyStr, date)
              IntKey(intKey) => p.set_intkey_datetime(intKey, date)
              _ => p.set_index_datetime(-1, date)
            }
          _ => ()
        }
        return { parent, data: VT_DateTime(value=date) }
      }
      self.parse_ext(parent, key, extype, 4)
    }
    FmtCodeFixExt8(extType=extype) => {
      if extype == -1 {
        //64位时间        
        let mut sec = self.parse_u64()
        let nsec = sec >> 34 //纳秒
        sec = sec & 0x00000003ffffffff //秒
        let ms = (sec * 1000 + nsec / 1000000).reinterpret_as_int64()
        let date = @datetime.DateTime::from_unix_mseconds(ms)
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.set_key_datetime(keyStr, date)
              IntKey(intKey) => p.set_intkey_datetime(intKey, date)
              _ => p.set_index_datetime(-1, date)
            }
          _ => ()
        }
        return { parent, data: VT_DateTime(value=date) }
      }
      self.parse_ext(parent, key, extype, 8)
    }
    FmtCodeFixExt16(extType=extype) => self.parse_ext(parent, key, extype, 16)
  }
}

///|
fn parse_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MsgPackParser[T, B],
  parent : MoonValue[T, B]?,
  key : KeyInfo[T],
  extType : Int,
  binLen : Int
) -> MoonValue[T, B] {
  if self.shareBinary {
    let bin = BinaryView::newBinaryView(self._packData, self._offset, binLen)
    match parent {
      Some(p) =>
        match key {
          Str(keyStr) => p.set_key_share_ext(keyStr, bin, extType)
          IntKey(intKey) => p.set_intkey_share_ext(intKey, bin, extType)
          _ => p.set_index_share_ext(-1, bin, extType)
        }
      None => ()
    }
    return { parent, data: VT_ShareExt(value=bin, extType~) }
  } else {
    let bin = (self.binReader)(self._packData, self._offset, binLen)
    match parent {
      Some(p) =>
        match key {
          Str(keyStr) => p.set_key_ext(keyStr, bin, extType)
          IntKey(intKey) => p.set_intkey_ext(intKey, bin, extType)
          _ => p.set_index_ext(-1, bin, extType)
        }
      None => ()
    }
    return { parent, data: VT_Ext(value=bin, extType~) }
  }
}

///|
fn read_utf8string(
  bin : Array[Byte],
  offset : Int,
  l : Int
) -> String!ConvertError {
  let strArr : Array[Char] = Array::new()
  let mut idx = offset
  let l = offset + l
  while idx < l {
    let code = bin[idx].to_int()
    if (code & 0x80) == 0 {
      strArr.push(Char::from_int(code))
      idx = idx + 1
    } else if (code & 0xE0) == 0xC0 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      let code2 = bin[idx + 1].to_int()
      strArr.push(Char::from_int(((code & 0x1F) << 6) | (code2 & 0x3F)))
      idx = idx + 2
    } else if (code & 0xF0) == 0xE0 {
      //是3个字节的格式  0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      let code2 = bin[idx + 1].to_int()
      let code3 = bin[idx + 2].to_int()
      strArr.push(
        Char::from_int(
          ((code & 0x0F) << 12) | ((code2 & 0x3F) << 6) | (code3 & 0x3F),
        ),
      )
      idx = idx + 3
    } else {
      raise ConvertError("无效的Utf8编码")
    }
  }
  String::from_array(strArr)
}

///|
fn binReader(bin : Array[Byte], offset : Int, binLen : Int) -> Array[Byte] {
  let result = Array::new()
  bin.blit_to(result, len=binLen, src_offset=offset)
  result
}

///|
pub fn MsgPackParser::newparser_with_str_array(
  shareBinary : Bool,
  binary : Array[Byte]
) -> MsgPackParser[String, Array[Byte]] {
  {
    _packData: binary,
    shareBinary,
    _offset: 0,
    stringReader: read_utf8string,
    binReader,
  }
}

///|
fn bytesReader(bin : Bytes, offset : Int, binLen : Int) -> Bytes {
  let fixArray = FixedArray::make(binLen, b'\x00')
  FixedArray::blit_from_bytes(fixArray, 0, bin, offset, binLen)
  Bytes::from_fixedarray(fixArray)
}

///|
fn read_utf8string_fromBytes(
  bin : Bytes,
  offset : Int,
  l : Int
) -> String!ConvertError {
  let strArr : Array[Char] = Array::new()
  let mut idx = offset
  let l = offset + l
  while idx < l {
    let code = bin[idx].to_int()
    if (code & 0x80) == 0 {
      strArr.push(Char::from_int(code))
      idx = idx + 1
    } else if (code & 0xE0) == 0xC0 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      let code2 = bin[idx + 1].to_int()
      strArr.push(Char::from_int(((code & 0x1F) << 6) | (code2 & 0x3F)))
      idx = idx + 2
    } else if (code & 0xF0) == 0xE0 {
      //是3个字节的格式  0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      let code2 = bin[idx + 1].to_int()
      let code3 = bin[idx + 2].to_int()
      strArr.push(
        Char::from_int(
          ((code & 0x0F) << 12) | ((code2 & 0x3F) << 6) | (code3 & 0x3F),
        ),
      )
      idx = idx + 3
    } else {
      raise ConvertError("无效的Utf8编码")
    }
  }
  String::from_array(strArr)
}

///|
pub fn MsgPackParser::newparser_with_str_bytes(
  shareBinary : Bool,
  binary : Bytes
) -> MsgPackParser[String, Bytes] {
  {
    _packData: binary,
    shareBinary,
    _offset: 0,
    stringReader: read_utf8string_fromBytes,
    binReader: bytesReader,
  }
}

///|
struct MsgpackEncoder[B] {
  writer : B
}

///|
pub fn MsgpackEncoder::new[B : IBinBlit](writer : B) -> MsgpackEncoder[B] {
  { writer, }
}

///|
fn encode_int[B : IBinBlit](self : MsgpackEncoder[B], v : Int64) -> Unit {
  if v >= 0 {
    if v < 128 {
      self.writer.append_byte(v.to_byte())
    } else if v <= 255 {
      self.writer.append_byte(0xcc)
      self.writer.append_byte(v.to_byte())
    } else if v <= 65535 {
      self.writer.append_byte(0xcd)
      self.writer.append_byte((v >> 8).to_byte())
      self.writer.append_byte(v.to_byte())
    } else if v <= 4294967295 {
      //(1<<32) - 1)
      self.writer.append_byte(0xce)
      self.writer.append_byte((v >> 24).to_byte())
      self.writer.append_byte((v >> 16).to_byte())
      self.writer.append_byte((v >> 8).to_byte())
      self.writer.append_byte(v.to_byte())
    } else {
      self.writer.append_byte(0xcf)
      self.writer.append_byte((v >> 56).to_byte())
      self.writer.append_byte((v >> 48).to_byte())
      self.writer.append_byte((v >> 40).to_byte())
      self.writer.append_byte((v >> 32).to_byte())
      self.writer.append_byte((v >> 24).to_byte())
      self.writer.append_byte((v >> 16).to_byte())
      self.writer.append_byte((v >> 8).to_byte())
      self.writer.append_byte(v.to_byte())
    }
    return
  }
  if v >= -32 {
    self.writer.append_byte(v.to_byte())
  } else if v >= -128 {
    self.writer.append_byte(0xd0)
    self.writer.append_byte(v.to_byte())
  } else if v >= -32768 {
    self.writer.append_byte(0xd1)
    self.writer.append_byte((v >> 8).to_byte())
    self.writer.append_byte(v.to_byte())
  } else if v >= -2147483648 {
    self.writer.append_byte(0xd2)
    self.writer.append_byte((v >> 24).to_byte())
    self.writer.append_byte((v >> 16).to_byte())
    self.writer.append_byte((v >> 8).to_byte())
    self.writer.append_byte(v.to_byte())
  } else {
    self.writer.append_byte(0xd3)
    self.writer.append_byte((v >> 56).to_byte())
    self.writer.append_byte((v >> 48).to_byte())
    self.writer.append_byte((v >> 40).to_byte())
    self.writer.append_byte((v >> 32).to_byte())
    self.writer.append_byte((v >> 24).to_byte())
    self.writer.append_byte((v >> 16).to_byte())
    self.writer.append_byte((v >> 8).to_byte())
    self.writer.append_byte(v.to_byte())
  }
}

///|
fn encode_string[T : IString + Hash + Eq, B : IBinBlit](
  self : MsgpackEncoder[B],
  str : T
) -> Unit {
  let bliter : B = IBinBlit::newBlit()
  bliter.write_utf8?(str).unwrap()
  let strLen = bliter.length()
  if strLen < 32 {
    self.writer.append_byte((0xa0 | strLen).to_byte())
  } else if strLen < 256 {
    self.writer.append_byte((0xd9).to_byte())
    self.writer.append_byte(strLen.to_byte())
  } else if strLen < 65536 {
    self.writer.append_byte(0xda)
    self.writer.append_byte((strLen >> 8).to_byte())
    self.writer.append_byte(strLen.to_byte())
  } else {
    self.writer.append_byte(0xdb)
    self.writer.append_byte((strLen >> 24).to_byte())
    self.writer.append_byte((strLen >> 16).to_byte())
    self.writer.append_byte((strLen >> 8).to_byte())
    self.writer.append_byte(strLen.to_byte())
  }
  self.writer.append_data(bliter)
  //self.writer.blit(-1,bliter,0,strLen)
  // for i in 0..<strLen{
  //   self.writer.append_byte(utf8Bytes[i])
  // }  
}

///|
fn encode_share_string[T : IString + Hash + Eq, B : IBinBlit](
  self : MsgpackEncoder[B],
  str : StringView[T, B]
) -> Unit {
  let strLen = str.len
  if strLen < 32 {
    self.writer.append_byte((0xa0 | strLen).to_byte())
  } else if strLen < 256 {
    self.writer.append_byte((0xd9).to_byte())
    self.writer.append_byte(strLen.to_byte())
  } else if strLen < 65536 {
    self.writer.append_byte(0xda)
    self.writer.append_byte((strLen >> 8).to_byte())
    self.writer.append_byte(strLen.to_byte())
  } else {
    self.writer.append_byte(0xdb)
    self.writer.append_byte((strLen >> 24).to_byte())
    self.writer.append_byte((strLen >> 16).to_byte())
    self.writer.append_byte((strLen >> 8).to_byte())
    self.writer.append_byte(strLen.to_byte())
  }
  self.writer.blit(-1, str._source, str.from, str.len)
  // for i in 0..<strLen{
  //   self.writer.append_byte(str._source.read_byte(i+str.from))
  // }  
}

///|
fn encode_datetime[B : IBinBlit](
  self : MsgpackEncoder[B],
  d : @datetime.DateTime
) -> Unit {
  let msecs = d.unix_millseconds()
  let secs = msecs / 1000
  if (secs >> 34) == 0 {
    let msecs = ((msecs - secs * 1000) * 1000 * 1000) << 34
    let secs = secs | msecs
    if (secs & 0xffffffff00000000) == 0 {
      //32位日期格式      
      self.writer.append_byte(0xd6)
      self.writer.append_byte(0xff)
      self.writer.append_int32(secs.to_int(), false)
      return
    }
    //64位日期格式      
    self.writer.append_byte(0xd7)
    self.writer.append_byte(0xff)
    self.writer.append_int64(secs, false)
    return
  }
  //96位日期格式
  self.writer.append_byte(0xc7)
  self.writer.append_byte(12)
  self.writer.append_byte(0xff)
  let mirsecs = (msecs - secs * 1000) * 1000 * 1000 //microseconds
  self.writer.append_int32(mirsecs.to_int(), false)
  self.writer.append_int64(secs, false)
}

///|
fn encode_bin[B : IBinBlit](
  self : MsgpackEncoder[B],
  v : B,
  from : Int,
  len : Int
) -> Unit {
  if len < 256 {
    self.writer.append_byte(0xc4)
    self.writer.append_byte(len.to_byte())
  } else if len < 65536 {
    self.writer.append_byte(0xc5)
    self.writer.append_byte((len >> 8).to_byte())
    self.writer.append_byte(len.to_byte())
  } else {
    self.writer.append_byte(0xc6)
    self.writer.append_byte((len >> 24).to_byte())
    self.writer.append_byte((len >> 16).to_byte())
    self.writer.append_byte((len >> 8).to_byte())
    self.writer.append_byte(len.to_byte())
  }
  for i in from..<(from + len) {
    self.writer.append_byte(v.read_byte(i))
  }
}

///|
fn encode_ext[B : IBinBlit](
  self : MsgpackEncoder[B],
  v : B,
  from : Int,
  len : Int,
  extType : Int
) -> Unit {
  match len {
    1 => {
      self.writer.append_byte(0xd4)
      self.writer.append_byte(extType.to_byte())
    }
    2 => {
      self.writer.append_byte(0xd5)
      self.writer.append_byte(extType.to_byte())
    }
    4 => {
      self.writer.append_byte(0xd6)
      self.writer.append_byte(extType.to_byte())
    }
    8 => {
      self.writer.append_byte(0xd7)
      self.writer.append_byte(extType.to_byte())
    }
    16 => {
      self.writer.append_byte(0xd8)
      self.writer.append_byte(extType.to_byte())
    }
    _ =>
      if len < 256 {
        self.writer.append_byte(0xc7)
        self.writer.append_byte(len.to_byte())
        self.writer.append_byte(extType.to_byte())
      } else if len < 65536 {
        self.writer.append_byte(0xc8)
        self.writer.append_byte((len >> 8).to_byte())
        self.writer.append_byte(len.to_byte())
        self.writer.append_byte(extType.to_byte())
      } else {
        self.writer.append_byte(0xc9)
        self.writer.append_byte((len >> 24).to_byte())
        self.writer.append_byte((len >> 16).to_byte())
        self.writer.append_byte((len >> 8).to_byte())
        self.writer.append_byte(len.to_byte())
        self.writer.append_byte(extType.to_byte())
      }
  }
  for i in from..<(from + len) {
    self.writer.append_byte(v.read_byte(i))
  }
}

///|
pub fn encode[T : IString + Hash + Eq, B : IBinBlit](
  self : MsgpackEncoder[B],
  value : MoonValue[T, B]
) -> Unit {
  match value.data {
    VT_Null => self.writer.append_byte(0xc0)
    VT_True => self.writer.append_byte(0xc3)
    VT_False => self.writer.append_byte(0xc2)
    VT_Int(value~) => self.encode_int(value)
    VT_Float(value~) => {
      self.writer.append_byte(0xca)
      self.writer.append_float(value)
    }
    VT_Double(value~) => {
      self.writer.append_byte(0xcb)
      self.writer.append_double(value)
    }
    VT_DateTime(value~) => self.encode_datetime(value)
    VT_String(value~) => self.encode_string(value)
    VT_ShareString(value~) => self.encode_share_string(value)
    VT_Bin(value~) => self.encode_bin(value, 0, value.length())
    VT_ShareBin(value~) => self.encode_bin(value._source, value.from, value.len)
    VT_Ext(value~, extType~) =>
      self.encode_ext(value, 0, value.length(), extType)
    VT_ShareExt(value~, extType~) =>
      self.encode_ext(value._source, value.from, value.len, extType)
    VT_Array(value~) => {
      let arrlen = value.length()
      if arrlen < 16 {
        self.writer.append_byte((0x90 | arrlen).to_byte())
      } else {
        if arrlen < 65536 {
          self.writer.append_byte(0xdc)
        } else {
          self.writer.append_byte(0xdd)
          self.writer.append_byte((arrlen >> 24).to_byte())
          self.writer.append_byte((arrlen >> 16).to_byte())
        }
        self.writer.append_byte((arrlen >> 8).to_byte())
        self.writer.append_byte(arrlen.to_byte())
      }
      for i in 0..<arrlen {
        self.encode(value[i])
      }
    }
    VT_Obj(value~) => {
      let mapLen = value.size()
      if mapLen < 16 {
        self.writer.append_byte((0x80 | mapLen).to_byte())
      } else {
        if mapLen < 65536 {
          self.writer.append_byte(0xde)
        } else {
          self.writer.append_byte(0xdf)
          self.writer.append_byte((mapLen >> 24).to_byte())
          self.writer.append_byte((mapLen >> 16).to_byte())
        }
        self.writer.append_byte((mapLen >> 8).to_byte())
        self.writer.append_byte(mapLen.to_byte())
      }
      for k, v in value {
        self.encode_string(k)
        self.encode(v)
      }
    }
    VT_IntKeyObj(value~) => {
      let mapLen = value.size()
      if mapLen < 16 {
        self.writer.append_byte((0x80 | mapLen).to_byte())
      } else {
        if mapLen < 65536 {
          self.writer.append_byte(0xde)
        } else {
          self.writer.append_byte(0xdf)
          self.writer.append_byte((mapLen >> 24).to_byte())
          self.writer.append_byte((mapLen >> 16).to_byte())
        }
        self.writer.append_byte((mapLen >> 8).to_byte())
        self.writer.append_byte(mapLen.to_byte())
      }
      for k, v in value {
        self.encode_int(k)
        self.encode(v)
      }
    }
  }
}

///|
test "parse" {
  let b : Array[Byte] = [
    134, 164, 110, 97, 109, 101, 169, 228, 184, 141, 229, 190, 151, 233, 151, 178,
    163, 97, 103, 101, 40, 163, 109, 101, 110, 195, 163, 110, 111, 119, 203, 64,
    230, 69, 246, 246, 72, 195, 95, 167, 99, 117, 114, 116, 105, 109, 101, 215, 255,
    69, 36, 64, 76, 103, 60, 86, 173, 165, 97, 114, 114, 97, 121, 146, 34, 205, 1,
    89,
  ]
  let parser : MsgPackParser[String, Array[Byte]] = MsgPackParser::newparser_with_str_array(
    true, b,
  )
  match parser.parse?() {
    Ok(result) => {
      assert_eq!(result.string_by_key("name", ""), "不得闲")
      assert_eq!(result.bool_by_key("men", false), true)
      assert_eq!(result.value_by_key("array").unwrap().int_by_index(1, 0), 345)
      println(result.to_string())
      let w : Array[Byte] = Array::new()
      let encoder = MsgpackEncoder::new(w)
      encoder.encode(result)
      let parser : MsgPackParser[String, Array[Byte]] = MsgPackParser::newparser_with_str_array(
        true, w,
      )
      match parser.parse?() {
        Ok(t) => println(t.to_string())
        _ => println("error2")
      }
    }
    _ => println("error")
  }
}
