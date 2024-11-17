//! UTF8跟UTF16之间转码
//UCS-2编码    UTF-8 字节流(二进制)
//0000 - 007F  0xxxxxxx
//0080 - 07FF 110xxxxx 10xxxxxx
//0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx

const UTF8_END1 = 0x007F

const UTF8_START2 = 0x0080

const UTF8_END2 = 0x07FF

const UTF8_START3 = 0x0800

const UTF8_END3 = 0xFFFF

pub(all) type! ConvertError String

pub fn utf16_utf8(str : String) -> Array[Byte]!ConvertError {
  let result = Array::new()
  for char in str {
    let code = char.to_int()
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

pub fn utf8_utf16(utf8Arr : ArrayView[Byte]) -> String!ConvertError {
  let strArr : Array[Char] = Array::new()
  let l = utf8Arr.length()
  let mut idx = 0
  while idx < l {
    let code = utf8Arr[idx].to_int()
    if (code & 0x80) == 0 {
      strArr.push(Char::from_int(code))
      idx = idx + 1
    } else if (code & 0xE0) == 0xC0 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      let code2 = utf8Arr[idx + 1].to_int()
      strArr.push(Char::from_int(((code & 0x1F) << 6) | (code2 & 0x3F)))
      idx = idx + 2
    } else if (code & 0xF0) == 0xE0 {
      //是3个字节的格式  0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      let code2 = utf8Arr[idx + 1].to_int()
      let code3 = utf8Arr[idx + 2].to_int()
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

impl IBinary with read_utf8(self,offset: Int,l: Int)->IString!ConvertError{
  let strArr : Array[Char] = Array::new()
  let mut idx = offset
  while idx < l {    
    let code = self.read_byte(idx).to_int()
    if (code & 0x80) == 0 {
      strArr.push(Char::from_int(code))
      idx = idx + 1
    } else if (code & 0xE0) == 0xC0 {
      //是2个字节的格式 0080 - 07FF 110xxxxx 10xxxxxx
      let code2 = self.read_byte(idx + 1).to_int()
      strArr.push(Char::from_int(((code & 0x1F) << 6) | (code2 & 0x3F)))
      idx = idx + 2
    } else if (code & 0xF0) == 0xE0 {
      //是3个字节的格式  0800 - FFFF 1110xxxx 10xxxxxx 10xxxxxx
      let code2 = self.read_byte(idx + 1).to_int()
      let code3 = self.read_byte(idx + 2).to_int()
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

test "utft8" {
  let arr = utf16_utf8?("不得闲测试").unwrap()
  println(arr)
  let str = utf8_utf16?(arr[0:])
  println(str.unwrap())
  assert_eq!(str.unwrap(), "不得闲测试")
}
