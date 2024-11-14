pub(open) trait IString{
  charCodeAt(Self,Int)->Int  //utf16编码格式的
  length(Self)->Int
  to_string(Self)->String  
}

pub impl Eq for IString with op_equal(self,other: IString)->Bool{
  self.to_string()==other.to_string()
}

pub impl Hash for IString with hash_combine(self, hash: Hasher) -> Unit{
  hash.combine_string(self.to_string())
}

impl IString with to_string(self)->String{
  let l = self.length()
  if l == 0{
    ""
  }else{    
    let strArr: Array[Char]  = Array::make(l,Char::from_int(self.charCodeAt(0)))
    for i in 1..<l {
      strArr[i] = Char::from_int(self.charCodeAt(i))
    }
    String::from_array(strArr)
  }
}

pub impl IString for String with charCodeAt(self,idx: Int)->Int{
  self[idx].to_int()
}

pub impl IString for String with length(self)->Int{
  self.length()
}

pub impl IString for String with to_string(self)->String{
  self
}

type LittleEndian
pub fn LittleEndian::uint16(bytes: ArrayView[Byte])->UInt{  
  match bytes.length(){
    1=>bytes[0].to_uint()
    0=>0
    _=>bytes[0].to_uint() | (bytes[1].to_uint() << 8)
  }
}

pub fn LittleEndian::uint16Bytes(v: UInt)->Bytes{
  let result = Bytes::make(2,0)  
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result
}

pub fn LittleEndian::uint32(bytes: ArrayView[Byte])->UInt{
  match bytes.length(){
    1=>bytes[0].to_uint()
    0=>0
    2=>bytes[0].to_uint() | (bytes[1].to_uint() << 8)
    3=>bytes[0].to_uint() | (bytes[1].to_uint() << 8) | (bytes[2].to_uint() << 16)
    _=>bytes[0].to_uint() | (bytes[1].to_uint() << 8) | (bytes[2].to_uint() << 16) | (bytes[3].to_uint() << 24)
  }
}

pub fn LittleEndian::uint32Bytes(v: UInt)->Bytes{
  let result = Bytes::make(4,0)
  result[0] = v.to_byte()
  result[1] = (v >> 8).to_byte()
  result[2] = (v >> 16).to_byte()
  result[3] = (v >> 24).to_byte()
  result
}

pub fn LittleEndian::uint64(bytes: ArrayView[Byte])->UInt64{
  match bytes.length(){
    0=>0
    1=>bytes[0].to_uint64()    
    2=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8)
    3=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16)
    4=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16) | (bytes[3].to_uint64() << 24)
    5=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16) | (bytes[3].to_uint64() << 24) |
       (bytes[4].to_uint64() << 32)
    6=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16) | (bytes[3].to_uint64() << 24) |
       (bytes[4].to_uint64() << 32) | (bytes[5].to_uint64() << 40)
    7=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16) | (bytes[3].to_uint64() << 24) |
       (bytes[4].to_uint64() << 32) | (bytes[5].to_uint64() << 40)| (bytes[6].to_uint64() << 48)
    _=>bytes[0].to_uint64() | (bytes[1].to_uint64() << 8) | (bytes[2].to_uint64() << 16) | (bytes[3].to_uint64() << 24) |
       (bytes[4].to_uint64() << 32) | (bytes[5].to_uint64() << 40)| (bytes[6].to_uint64() << 48)| (bytes[7].to_uint64() << 56)
  }
}

pub fn LittleEndian::uint64Bytes(v: UInt64)->Bytes{
  let result = Bytes::make(8,0)
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
pub fn BigEndian::uint16(bytes: ArrayView[Byte])->UInt{  
  match bytes.length(){
    1=>bytes[0].to_uint() << 8
    0=>0
    _=>bytes[1].to_uint() | (bytes[0].to_uint() << 8)
  }
}

pub fn BigEndian::uint16Bytes(v: UInt)->Bytes{
  let result = Bytes::make(2,0)  
  result[0] = (v >> 8).to_byte()
  result[1] = v.to_byte()  
  result
}

pub fn BigEndian::uint32(bytes: ArrayView[Byte])->UInt{
  match bytes.length(){
    0=>0
    1=>bytes[0].to_uint() << 24
    2=>(bytes[1].to_uint() << 16) | (bytes[0].to_uint() << 24)
    3=>(bytes[2].to_uint() << 8) | (bytes[1].to_uint() << 16) | (bytes[0].to_uint() << 24)
    _=>bytes[3].to_uint() | (bytes[2].to_uint() << 8) | (bytes[1].to_uint() << 16) | (bytes[0].to_uint() << 24)
  }
}

pub fn BigEndian::uint32Bytes(v: UInt)->Bytes{
  let result = Bytes::make(4,0)
  result[0] = (v >> 24).to_byte()
  result[1] = (v >> 16).to_byte()
  result[2] = (v >> 8).to_byte()
  result[3] = v.to_byte()    
  result
}

pub fn BigEndian::uint64(bytes: ArrayView[Byte])->UInt64{
  match bytes.length(){
    0=>0
    1=>bytes[0].to_uint64() << 56
    2=>(bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
    3=>(bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
    4=>(bytes[3].to_uint64() << 32) | (bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
    5=>(bytes[4].to_uint64() << 24) | (bytes[3].to_uint64() << 32) | (bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| 
       (bytes[0].to_uint64() << 56)
    6=>(bytes[5].to_uint64() << 16) | (bytes[4].to_uint64() << 24) | (bytes[3].to_uint64() << 32) | 
       (bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
    7=>(bytes[6].to_uint64() << 8) | (bytes[5].to_uint64() << 16) | (bytes[4].to_uint64() << 24) | (bytes[3].to_uint64() << 32) | 
       (bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
    _=>bytes[7].to_uint64() | (bytes[6].to_uint64() << 8) | (bytes[5].to_uint64() << 16) | (bytes[4].to_uint64() << 24) |
       (bytes[3].to_uint64() << 32) | (bytes[2].to_uint64() << 40)| (bytes[1].to_uint64() << 48)| (bytes[0].to_uint64() << 56)
  }
}

pub fn BigEndian::uint64Bytes(v: UInt64)->Bytes{
  let result = Bytes::make(8,0)
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

pub(open) trait IBinary: Show{
  length(Self)->Int  
  writeByte(Self,Int,Byte)->Unit
  readByte(Self,Int)->Byte

  writeBool(Self,Int,Bool)->Unit
  readBool(Self,Int)->Bool
  writeBytes(Self,Int,Bytes)->Unit
  writeInt16(Self,Int,Int,Bool)->Unit
  writeInt32(Self,Int,Int,Bool)->Unit
  writeInt64(Self,Int,Int64,Bool)->Unit
  readInt16(Self,Int,Bool)->Int
  readInt32(Self,Int,Bool)->Int
  readInt64(Self,Int,Bool)->Int64
  copyFrom(Self,Int,IBinary,Int,Int)->Unit
  blit(Self,Int,Bytes,Int,Int)->Unit
}

impl IBinary with blit(self,offset: Int,src: Bytes,srcFrom: Int,cpyLen:Int)->Unit{
  self.copyFrom(offset,src,srcFrom,cpyLen)  
}

pub fn op_get(self: IBinary,offset: Int)->Byte{
  let size = self.length()
  if offset >= size{
    panic()
  }
  self.readByte(offset)  
}

pub fn op_set(self: IBinary,offset: Int,v: Byte)->Unit{
  let size = self.length()
  if offset >= size{
    panic()
  }
  self.writeByte(offset,v)
}

impl IBinary with writeBytes(self,offset: Int,b: Bytes)->Unit{
  let mut idx = offset  
  for v in b{
    self.writeByte(idx,v)
    idx = idx+1
  }
}

impl IBinary with writeInt16(self,offset: Int,value: Int,littleEndian: Bool)->Unit{
  let bytes={
    if littleEndian{
      LittleEndian::uint16Bytes(value.reinterpret_as_uint())      
    }else{
      BigEndian::uint16Bytes(value.reinterpret_as_uint())
    }
  }  
  self.writeBytes(offset,bytes)
}

impl IBinary with writeInt32(self,offset: Int,value: Int,littleEndian: Bool)->Unit{
  let bytes={
    if littleEndian{
      LittleEndian::uint32Bytes(value.reinterpret_as_uint())      
    }else{
      BigEndian::uint32Bytes(value.reinterpret_as_uint())
    }
  }  
  self.writeBytes(offset,bytes)
}

impl IBinary with writeInt64(self,offset: Int,value: Int64,littleEndian: Bool)->Unit{
  let bytes={
    if littleEndian{
      LittleEndian::uint64Bytes(value.reinterpret_as_uint64())      
    }else{
      BigEndian::uint64Bytes(value.reinterpret_as_uint64())
    }
  }  
  self.writeBytes(offset,bytes)
}

impl IBinary with readInt16(self,offset: Int,littleEndian: Bool)->Int{    
  let bytes: Array[Byte] = [self.readByte(offset),self.readByte(offset+1)]  
  if littleEndian{
    LittleEndian::uint16(bytes[:]).reinterpret_as_int()
  }else{
    BigEndian::uint16(bytes[:]).reinterpret_as_int()
  }
}

impl IBinary with readInt32(self,offset: Int,littleEndian: Bool)->Int{  
  let bytes: Array[Byte] = [self.readByte(offset),self.readByte(offset+1),self.readByte(offset+2),self.readByte(offset+3)]
  if littleEndian{
    LittleEndian::uint32(bytes[:]).reinterpret_as_int()
  }else{
    BigEndian::uint32(bytes[:]).reinterpret_as_int()
  }
}

impl IBinary with readInt64(self,offset: Int,littleEndian: Bool)->Int64{  
  let bytes: Array[Byte] = [self.readByte(offset),self.readByte(offset+1),self.readByte(offset+2),self.readByte(offset+3),
                            self.readByte(offset+4),self.readByte(offset+5),self.readByte(offset+6),self.readByte(offset+7)]
  if littleEndian{
    LittleEndian::uint64(bytes[:]).reinterpret_as_int64()
  }else{
    BigEndian::uint64(bytes[:]).reinterpret_as_int64()
  }
}

impl IBinary with readBool(self,offset: Int)->Bool{
  self.readByte(offset) == 1
}

impl IBinary with writeBool(self,offset: Int,value: Bool)->Unit{
  if value{
    self.writeByte(offset,1)
  }else{
    self.writeByte(offset,0)
  }
}

impl IBinary with copyFrom(self,offset: Int,src: IBinary,srcFrom: Int,cpyLen:Int)->Unit{
  let mut leftLen = src.length() - srcFrom
  if leftLen == 0{
    return
  }
  if leftLen > cpyLen{
    leftLen = cpyLen
  }  
  for i = 0;i<leftLen;i=i+1{
    self.writeByte(offset+i, src.readByte(srcFrom+i))
  }
}

pub impl IBinary for Bytes with length(self)->Int{
  self.length()
}


pub impl IBinary for Bytes with writeByte(self,offset: Int, value: Byte)->Unit{
  self[offset] = value
}

pub impl IBinary for Bytes with readByte(self,offset: Int)->Byte{
  self[offset]
}

pub impl IBinary for Bytes with blit(self,offset: Int,src: Bytes,srcFrom: Int,cpyLen:Int)->Unit{
  self.blit(offset,src,srcFrom,cpyLen)
}

pub impl IBinary for @wasmMemManager.Memory with length(self)->Int{
  self.length
}
  
pub impl IBinary for @wasmMemManager.Memory with writeByte(self,offset: Int, value: Byte)->Unit{
  self.writeByte_unsafe(offset,value.to_int())
}
  
pub impl IBinary for @wasmMemManager.Memory with readByte(self,offset: Int)->Byte{
  self.readByte_unsafe(offset)
}