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
}

priv struct MsgPackParser {
  _packData : IBinary
  shareBinary : Bool
  mut _offset : Int
}

fn detectionFmtCode(self : MsgPackParser) -> MsgPackFormatCode {
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

fn parse_map(self : MsgPackParser, parent : MoonValue, mapLen : UInt) -> Unit {

}

fn parse_u8(self : MsgPackParser) -> Int {
  let result = self._packData.read_byte(self._offset).to_int()
  self._offset += 1
  result
}

fn parse_i8(self : MsgPackParser) -> Int {
  let mut result = self._packData.read_byte(self._offset).to_int()
  if result > 127 {
    result -= 256
  }
  self._offset += 1
  result
}

fn parse_u16(self : MsgPackParser) -> Int {
  let result = self._packData.read_int16(self._offset, false)
  self._offset += 2
  result
}

fn parse_i16(self : MsgPackParser) -> Int {
  let mut result = self._packData.read_int16(self._offset, false)
  if result > 32767 {
    result -= 65536
  }
  self._offset += 2
  result
}

fn parse_u32(self : MsgPackParser) -> UInt {
  let result = self._packData
    .read_int32(self._offset, false)
    .reinterpret_as_uint()
  self._offset += 4
  result
}

fn parse_u64(self : MsgPackParser) -> UInt64 {
  let result = self._packData
    .read_int64(self._offset, false)
    .reinterpret_as_uint64()
  self._offset += 8
  result
}

fn parse_float(self : MsgPackParser) -> Float {
  let result = self._packData.read_float(self._offset)
  self._offset += 4
  result
}

fn parse_double(self : MsgPackParser) -> Double {
  let result = self._packData.read_double(self._offset)
  self._offset += 8
  result
}

fn parser(self : MsgPackParser) -> MoonValue!MsgPackParserError {
  self.parse_value!(self.detectionFmtCode(), None, KeyInfo::None)
}

enum KeyInfo {
  None
  Array
  Str(IString)
  IntKey(Int64)
}

pub(all) type! MsgPackParserError {
  InvalidateMsgPackMapType(String)
  ErrorUtf8String(String)
  ErrorExtError(String)
}

fn parse_value(
  self : MsgPackParser,
  fmtCode : MsgPackFormatCode,
  parent : MoonValue?,
  key : KeyInfo
) -> MoonValue!MsgPackParserError {
  match fmtCode {
    FmtCodeFixMap(len=mapLen)
    | FmtCodeMap16(len=mapLen) | FmtCodeMap32(len=mapLen) => {
      //先探测一下key是int还是string，然后知道用intmap
      let code = self._packData.read_byte(self._offset)
      let result = if (code >= 0xd9 && code <= 0xdb) ||
        (code >= 0xa0 && code <= 0xbf) {
        match parent {
          Some(p) =>
            match key {
              Str(keyStr) => p.add_key_object(keyStr, StrMap)
              IntKey(intKey) => p.add_intkey_object(intKey, StrMap)
              _ => p.add_arr_object(StrMap)
            }
          _ => {
            let v = { parent, data: VT_Obj(value={}) }
            v
          }
        }
      } else if (code >= 0xcc && code <= 0xd3) ||
        code <= 0x7f ||
        (code >= 0xe0 && code <= 0xff) {
        match parent {
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
      } else {
        //无效的内容
        raise InvalidateMsgPackMapType(
          "The key of the map can only be integers and strings",
        )
      }
      self.parse_map(result, mapLen)
      return result
    }
    FmtCodeFixArray(len=arrLen)
    | FmtCodeArray16(len=arrLen) | FmtCodeArray32(len=arrLen) => {
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
            Array,
          )
          continue i + 1
        }
      }
      return result
    }
    FmtCodeFixStr(len=strLen)
    | FmtCodeStr8(len=strLen)
    | FmtCodeStr16(len=strLen) | FmtCodeStr32(len=strLen) => {
      let strLen = strLen.reinterpret_as_int()
      let strData : IString = if self.shareBinary {
        let strView : IString = StringView::newStringView(
          self._packData,
          self._offset,
          strLen,
        )
        self._offset += strLen
        strView
      } else {
        match self._packData.read_utf8?(self._offset, strLen) {
          Err(ConvertError(str)) => raise ErrorUtf8String(str)
          Ok(value) => value
        }
      }
      match parent {
        Some(p) => {
          match key {
            Str(keystr) => p.set_key_string(keystr, strData)
            IntKey(intKey) => p.set_intkey_string(intKey, strData)
            _ => p.set_index_string(-1, strData)
          }
          { parent, data: VT_String(value=strData) }
        }
        _ => { parent, data: VT_String(value=strData) }
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
    | FmtCodeBin16(len=binLen) | FmtCodeBin32(len=binLen) => {
      let binLen = binLen.reinterpret_as_int()
      let bytes = if self.shareBinary {
        let bv : IBinary = newBinaryView(self._packData, self._offset, binLen)
        self._offset += binLen
        bv
      } else {
        let bytes : IBinary = Bytes::make(binLen, 0)
        ICopy::copy_from(bytes, 0, self._packData, self._offset, binLen)
        self._offset += binLen
        bytes
      }
      match parent {
        Some(p) =>
          match key {
            Str(keyStr) => p.set_key_bin(keyStr, bytes)
            IntKey(intKey) => p.set_intkey_bin(intKey, bytes)
            _ => p.set_index_bin(-1, bytes)
          }
        None => ()
      }
      { parent, data: VT_Bin(value=bytes) }
    }
    FmtCodeExt8(len=extLen, extType=exType) => {
      if extLen == 0 {
        raise ErrorExtError("ExtLen Error")
      }
      if exType == -1 {
        //96位日期时间 linux时间戳
        let nsec = self.parse_u32() //纳秒
        let sec = self.parse_u64()
        //秒
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
    | FmtCodeUInt32(value=vInt) | FmtCodeUInt16(value=vInt) => {
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
    | FmtCodeInt32(value=vInt) | FmtCodeInt16(value=vInt) => {
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

      }
      self.parse_ext(parent, key, extype, 4)
    }
    FmtCodeFixExt8(extType=extype) => {
      if extype == -1 {
        //64位时间
        let mut sec = self.parse_u64()
        let nsec = sec >> 34 //纳秒
        sec = sec & 0x00000003ffffffff //秒        
      }
      self.parse_ext(parent, key, extype, 8)
    }
    FmtCodeFixExt16(extType=extype) => self.parse_ext(parent, key, extype, 16)
  }
}

fn parse_ext(
  self : MsgPackParser,
  parent : MoonValue?,
  key : KeyInfo,
  extType : Int,
  binLen : Int
) -> MoonValue {
  let bytes = if self.shareBinary {
    let bv : IBinary = newBinaryView(self._packData, self._offset, binLen)
    self._offset += binLen
    bv
  } else {
    let bytes : IBinary = Bytes::make(binLen, 0)
    ICopy::copy_from(bytes, 0, self._packData, self._offset, binLen)
    self._offset += binLen
    bytes
  }
  match parent {
    Some(p) =>
      match key {
        Str(keyStr) => p.set_key_ext(keyStr, bytes, extType)
        IntKey(intKey) => p.set_intkey_ext(intKey, bytes, extType)
        _ => p.set_index_ext(-1, bytes, extType)
      }
    None => ()
  }
  { parent, data: VT_Ext(value=bytes, extType~) }
}
