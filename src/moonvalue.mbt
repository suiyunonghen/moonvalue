///| moonvalue
///

///| data of moonvalue
pub(all) enum ValueData[T, B] {
  VT_Null
  VT_True
  VT_False
  VT_Int(value~ : Int64)
  VT_Double(value~ : Double)
  VT_DateTime(value~ : @datetime.DateTime)
  VT_Float(value~ : Float)
  VT_String(value~ : T)
  VT_ShareString(value~ : StringView[T, B])
  VT_Bin(value~ : B)
  VT_ShareBin(value~ : BinaryView[B])
  VT_Ext(value~ : B, extType~ : Int)
  VT_ShareExt(value~ : BinaryView[B], extType~ : Int)
  VT_Obj(value~ : Map[T, MoonValue[T, B]])
  VT_Array(value~ : Array[MoonValue[T, B]])
  VT_IntKeyObj(value~ : Map[Int64, MoonValue[T, B]])
}

///|
struct MoonValue[T, B] {
  mut parent : MoonValue[T, B]?
  mut data : ValueData[T, B]
}

///|
pub fn MoonValue::new_object[T : IString + Hash + Eq, B : IBinReader](
  data : Map[T, MoonValue[T, B]]
) -> MoonValue[T, B] {
  { parent: None, data: VT_Obj(value=data) }
}

///|
pub fn MoonValue::new_array[T : IString + Hash + Eq, B : IBinReader](
  arr : Array[MoonValue[T, B]]
) -> MoonValue[T, B] {
  { parent: None, data: VT_Array(value=arr) }
}

///|
pub fn value[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> ValueData[T, B] {
  self.data
}

///|
pub fn parent[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> MoonValue[T, B]? {
  self.parent
}

///|
pub fn as_double[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : Double = 0
) -> Double {
  match self.data {
    VT_Int(value=v) => v.to_double()
    VT_Double(value=v) => v
    VT_Float(value=v) => v.to_double()
    VT_True => 1
    VT_False => 0
    VT_String(value=v) =>
      match @strconv.parse_double?(IString::to_string(v)) {
        Ok(result) => result
        _ => default
      }
    VT_ShareString(value~) =>
      match @strconv.parse_double?(value.string()) {
        Ok(result) => result
        _ => default
      }
    _ => default
  }
}

///|
pub fn as_datetime[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : @datetime.DateTime = 0
) -> @datetime.DateTime {
  match self.data {
    VT_DateTime(value~) => value
    // VT_Int(value=v) => v.to_double()
    // VT_Double(value=v) => v
    // VT_Float(value=v) => v.to_double()
    // VT_True => 1
    // VT_False => 0
    // VT_String(value=v) =>
    //   match @strconv.parse_double?(IString::to_string(v)) {
    //     Ok(result) => result
    //     _ => default
    //   }
    // VT_ShareString(value~)=>
    //   match @strconv.parse_double?(value.string()) {
    //     Ok(result) => result
    //     _ => default
    //   }  
    _ => default
  }
}

///|
pub fn value_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T
) -> MoonValue[T, B]? {
  match self.data {
    VT_Obj(value=map) => map[key]
    VT_IntKeyObj(value=map) =>
      match @strconv.parse_int64?(key.to_string()) {
        Ok(intKey) => map[intKey]
        _ => None
      }
    VT_Array(value=arr) =>
      match @strconv.parse_int?(key.to_string()) {
        Ok(index) =>
          if index >= 0 && index < arr.length() {
            Some(arr[index])
          } else {
            None
          }
        _ => None
      }
    _ => None
  }
}

///|
pub fn value_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int
) -> MoonValue[T, B]? {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        Some(arr[index])
      } else {
        None
      }
    VT_IntKeyObj(value=map) => map[index.to_int64()]
    _ => None
  }
}

///|
pub fn string_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : T
) -> T {
  match self.value_by_key(key) {
    Some(result) =>
      match result.data {
        VT_String(value=str) => str
        VT_ShareString(value=str) =>
          match str.value?() {
            Ok(str) => str
            _ => default
          }
        _ => default
      }
    _ => default
  }
}

///|
pub fn str_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : String
) -> String {
  match self.value_by_key(key) {
    Some(result) =>
      match result.data {
        VT_String(value=str) => str.to_string()
        VT_ShareString(value=str) =>
          match str.value?() {
            Ok(str) => str.to_string()
            _ => default
          }
        VT_Int(value=v) => v.to_string()
        VT_Double(value=v) => v.to_string()
        VT_Float(value=v) => v.to_string()
        VT_True => "true"
        VT_False => "false"
        VT_DateTime(value=v) => Show::to_string(v)
        _ => default
      }
    _ => default
  }
}

///|
pub fn str_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : String
) -> String {
  match self.value_by_index(index) {
    Some(value) =>
      match value.data {
        VT_String(value=v) => v.to_string()
        VT_ShareString(value=v) =>
          match v.value?() {
            Ok(str) => str.to_string()
            _ => default
          }
        VT_Int(value=v) => v.to_string()
        VT_Double(value=v) => v.to_string()
        VT_Float(value=v) => v.to_string()
        VT_True => "true"
        VT_False => "false"
        VT_DateTime(value=v) => Show::to_string(v)
        _ => default
      }
    _ => default
  }
}

///|
pub fn string_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : T
) -> T {
  match self.value_by_index(index) {
    Some(result) =>
      match result.data {
        VT_String(value=str) => str
        VT_ShareString(value=str) =>
          match str.value?() {
            Ok(str) => str
            _ => default
          }
        _ => default
      }
    _ => default
  }
}

///|
pub fn int_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : Int64
) -> Int64 {
  match self.value_by_key(key) {
    Some(result) => result.as_int()
    _ => default
  }
}

///|
pub fn bool_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : Bool
) -> Bool {
  match self.value_by_key(key) {
    Some(result) => result.as_bool(default~)
    _ => default
  }
}

///|
pub fn double_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : Double
) -> Double {
  match self.value_by_key(key) {
    Some(result) => result.as_double(default~)
    _ => default
  }
}

///|
pub fn datetime_by_key[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  default : @datetime.DateTime
) -> @datetime.DateTime {
  match self.value_by_key(key) {
    Some(result) => result.as_datetime(default~)
    _ => default
  }
}

///|
pub fn int_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : Int64
) -> Int64 {
  match self.value_by_index(index) {
    Some(result) => result.as_int()
    _ => default
  }
}

///|
pub fn bool_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : Bool
) -> Bool {
  match self.value_by_index(index) {
    Some(result) => result.as_bool(default~)
    _ => default
  }
}

///|
pub fn double_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : Double
) -> Double {
  match self.value_by_index(index) {
    Some(result) => result.as_double(default~)
    _ => default
  }
}

///|
pub fn datetime_by_index[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  default : @datetime.DateTime
) -> @datetime.DateTime {
  match self.value_by_index(index) {
    Some(result) => result.as_datetime(default~)
    _ => default
  }
}

///|
pub fn as_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : T
) -> T {
  match self.data {
    VT_String(value=v) => v
    VT_ShareString(value=v) =>
      match v.value?() {
        Ok(str) => str
        _ => default
      }
    _ => default
  }
}

///|
pub fn as_str[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : String
) -> String {
  match self.data {
    VT_String(value=v) => v.to_string()
    VT_ShareString(value=v) =>
      match v.value?() {
        Ok(str) => str.to_string()
        _ => default
      }
    VT_Int(value=v) => v.to_string()
    VT_Double(value=v) => v.to_string()
    VT_Float(value=v) => v.to_string()
    VT_True => "true"
    VT_False => "false"
    VT_DateTime(value=v) => Show::to_string(v)
    _ => default
  }
}

///|
pub fn as_int[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : Int64 = 0
) -> Int64 {
  match self.data {
    VT_Int(value=v) => v
    VT_Double(value=v) => v.to_int64()
    VT_Float(value=v) => v.to_double().to_int64()
    VT_True => 1
    VT_False => 0
    VT_String(value=v) =>
      match @strconv.parse_int64?(IString::to_string(v)) {
        Ok(result) => result
        _ => default
      }
    VT_ShareString(value=v) =>
      match @strconv.parse_int64?(v.string()) {
        Ok(result) => result
        _ => default
      }
    _ => default
  }
}

///|
pub fn as_bool[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  default~ : Bool
) -> Bool {
  match self.data {
    VT_Null => default
    VT_True => true
    VT_False => false
    VT_Int(value~) => value != 0
    VT_Double(value~) => value != 0
    VT_Float(value~) => value != 0
    VT_String(value~) =>
      match @strconv.parse_bool?(IString::to_string(value)) {
        Ok(b) => b
        _ => default
      }
    VT_ShareString(value~) =>
      match @strconv.parse_bool?(value.string()) {
        Ok(b) => b
        _ => default
      }
    _ => default
  }
}

///|
pub fn op_set[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  val : MoonValue[T, B]
) -> Unit {
  match val.parent {
    Some(_) => return
    _ => ()
  }
  match self.data {
    VT_Obj(value~) => {
      val.parent = Some(self)
      value[key] = val
    }
    VT_Array(value~) =>
      match @strconv.parse_int?(key.to_string()) {
        Ok(idx) => {
          val.parent = Some(self)
          value[idx] = val
        }
        _ => ()
      }
    VT_IntKeyObj(value~) =>
      match @strconv.parse_int64?(key.to_string()) {
        Ok(idx) => value[idx] = val
        _ => ()
      }
    _ => ()
  }
}

///|
pub fn MoonValue::op_get[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T
) -> MoonValue[T, B]? {
  match self.data {
    VT_Obj(value~) => value[key]
    VT_Array(value~) =>
      match @strconv.parse_int?(key.to_string()) {
        Ok(idx) => Some(value[idx])
        _ => None
      }
    VT_IntKeyObj(value~) =>
      match @strconv.parse_int64?(key.to_string()) {
        Ok(idx) => value[idx]
        _ => None
      }
    _ => None
  }
}

///|
pub fn set_key_int[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : Int
) -> Unit {
  self.set_key_int64(key, v.to_int64())
}

///|
pub fn set_key_bool[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  bool : Bool
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vbool) =>
          if bool {
            vbool.data = VT_True
          } else {
            vbool.data = VT_False
          }
        None =>
          value[key] = {
            parent: Some(self),
            data: if bool {
              VT_True
            } else {
              VT_False
            },
          }
      }
    _ => ()
  }
}

///|
pub fn set_key_float[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : Float
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Float(value=v)
        None => value[key] = { parent: Some(self), data: VT_Float(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_double[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : Double
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Double(value=v)
        None => value[key] = { parent: Some(self), data: VT_Double(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : B
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Bin(value=v)
        None => value[key] = { parent: Some(self), data: VT_Bin(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_share_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : BinaryView[B]
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareBin(value=v)
        None => value[key] = { parent: Some(self), data: VT_ShareBin(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_datetime[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : @datetime.DateTime
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_DateTime(value=v)
        None => value[key] = { parent: Some(self), data: VT_DateTime(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : B,
  extType : Int
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Ext(value=v, extType~)
        None =>
          value[key] = { parent: Some(self), data: VT_Ext(value=v, extType~) }
      }
    _ => ()
  }
}

///|
pub fn set_key_share_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : BinaryView[B],
  extType : Int
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareExt(value=v, extType~)
        None =>
          value[key] = {
            parent: Some(self),
            data: VT_ShareExt(value=v, extType~),
          }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : B,
  extType : Int
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Ext(value=v, extType~)
        None =>
          value[key] = { parent: Some(self), data: VT_Ext(value=v, extType~) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_share_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : BinaryView[B],
  extType : Int
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareExt(value=v, extType~)
        None =>
          value[key] = {
            parent: Some(self),
            data: VT_ShareExt(value=v, extType~),
          }
      }
    _ => ()
  }
}

///|
pub fn set_index_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : B,
  extType : Int
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_Ext(value=v, extType~)
      } else {
        arr.push({ parent: Some(self), data: VT_Ext(value=v, extType~) })
      }
    _ => ()
  }
}

///|
pub fn set_index_share_ext[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : BinaryView[B],
  extType : Int
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_ShareExt(value=v, extType~)
      } else {
        arr.push({ parent: Some(self), data: VT_ShareExt(value=v, extType~) })
      }
    _ => ()
  }
}

///|
pub fn set_intkey_float[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : Float
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Float(value=v)
        None => value[key] = { parent: Some(self), data: VT_Float(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : B
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Bin(value=v)
        None => value[key] = { parent: Some(self), data: VT_Bin(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_share_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : BinaryView[B]
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareBin(value=v)
        None => value[key] = { parent: Some(self), data: VT_ShareBin(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_datetime[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : @datetime.DateTime
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_DateTime(value=v)
        None => value[key] = { parent: Some(self), data: VT_DateTime(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_double[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : Double
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Double(value=v)
        None => value[key] = { parent: Some(self), data: VT_Double(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : T
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_String(value=v)
        None => value[key] = { parent: Some(self), data: VT_String(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_share_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : StringView[T, B]
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareString(value=v)
        None =>
          value[key] = { parent: Some(self), data: VT_ShareString(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : T
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_String(value=v)
        None => value[key] = { parent: Some(self), data: VT_String(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_share_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : StringView[T, B]
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_ShareString(value=v)
        None =>
          value[key] = { parent: Some(self), data: VT_ShareString(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_bool[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : Bool
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) =>
          if v {
            vdata.data = VT_True
          } else {
            vdata.data = VT_False
          }
        None =>
          value[key] = {
            parent: Some(self),
            data: if v {
              VT_True
            } else {
              VT_False
            },
          }
      }
    _ => ()
  }
}

///|
pub fn set_intkey_int64[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  v : Int64
) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Int(value=v)
        None => value[key] = { parent: Some(self), data: VT_Int(value=v) }
      }
    _ => ()
  }
}

///|
pub fn set_key_int64[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  v : Int64
) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Int(value=v)
        None => value[key] = { parent: Some(self), data: VT_Int(value=v) }
      }
    _ => ()
  }
}

///|
pub(all) enum CompValueType {
  StrMap
  IntMap
  Array
}

///|
pub fn add_key_object[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : T,
  valueType : CompValueType
) -> MoonValue[T, B] {
  match self.data {
    VT_Obj(value=map) =>
      match map[key] {
        Some(mvalue) => {
          match valueType {
            StrMap =>
              match mvalue.data {
                VT_Obj(_) => ()
                _ => mvalue.data = VT_Obj(value={})
              }
            IntMap =>
              match mvalue.data {
                VT_IntKeyObj(_) => ()
                _ => mvalue.data = VT_IntKeyObj(value={})
              }
            _ =>
              match mvalue.data {
                VT_Array(_) => ()
                _ => mvalue.data = VT_Array(value=[])
              }
          }
          return mvalue
        }
        _ => {
          let result = {
            parent: Some(self),
            data: match valueType {
              StrMap => VT_Obj(value={})
              IntMap => VT_IntKeyObj(value={})
              _ => VT_Array(value=[])
            },
          }
          map[key] = result
          return result
        }
      }
    VT_IntKeyObj(value=map) =>
      match @strconv.parse_int64?(key.to_string()) {
        Ok(intKey) =>
          match map[intKey] {
            Some(mvalue) => {
              match valueType {
                StrMap =>
                  match mvalue.data {
                    VT_Obj(_) => ()
                    _ => mvalue.data = VT_Obj(value={})
                  }
                IntMap =>
                  match mvalue.data {
                    VT_IntKeyObj(_) => ()
                    _ => mvalue.data = VT_IntKeyObj(value={})
                  }
                _ =>
                  match mvalue.data {
                    VT_Array(_) => ()
                    _ => mvalue.data = VT_Array(value=[])
                  }
              }
              return mvalue
            }
            None => {
              let result = {
                parent: Some(self),
                data: match valueType {
                  StrMap => VT_Obj(value={})
                  IntMap => VT_IntKeyObj(value={})
                  _ => VT_Array(value=[])
                },
              }
              map[intKey] = result
              return result
            }
          }
        _ => ()
      }
    VT_Array(value=arr) =>
      match @strconv.parse_int?(key.to_string()) {
        Ok(index) =>
          if index < arr.length() {
            return match valueType {
              StrMap =>
                match arr[index].data {
                  VT_Obj(_) => arr[index]
                  _ => {
                    let result = { parent: Some(self), data: VT_Obj(value={}) }
                    arr[index] = result
                    result
                  }
                }
              IntMap =>
                match arr[index].data {
                  VT_IntKeyObj(_) => arr[index]
                  _ => {
                    let result = {
                      parent: Some(self),
                      data: VT_IntKeyObj(value={}),
                    }
                    arr[index] = result
                    result
                  }
                }
              _ =>
                match arr[index].data {
                  VT_Array(_) => arr[index]
                  _ => {
                    let result = {
                      parent: Some(self),
                      data: VT_Array(value=[]),
                    }
                    arr[index] = result
                    result
                  }
                }
            }
          }
        _ => ()
      }
    _ => ()
  }
  //改变类型
  let map : Map[T, MoonValue[T, B]] = {}
  let result = {
    parent: Some(self),
    data: match valueType {
      StrMap => VT_Obj(value={})
      IntMap => VT_IntKeyObj(value={})
      _ => VT_Array(value=[])
    },
  }
  map[key] = result
  self.data = VT_Obj(value=map)
  result
}

///|
pub fn add_intkey_object[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  key : Int64,
  valueType : CompValueType
) -> MoonValue[T, B] {
  match self.data {
    VT_IntKeyObj(value=map) =>
      match map[key] {
        Some(mvalue) => {
          match valueType {
            StrMap =>
              match mvalue.data {
                VT_Obj(_) => ()
                _ => mvalue.data = VT_Obj(value={})
              }
            IntMap =>
              match mvalue.data {
                VT_IntKeyObj(_) => ()
                _ => mvalue.data = VT_IntKeyObj(value={})
              }
            Array =>
              match mvalue.data {
                VT_Array(_) => ()
                _ => mvalue.data = VT_Array(value=[])
              }
          }
          return mvalue
        }
        _ => {
          let result = {
            parent: Some(self),
            data: match valueType {
              StrMap => VT_Obj(value={})
              IntMap => VT_IntKeyObj(value={})
              Array => VT_Array(value=[])
            },
          }
          map[key] = result
          return result
        }
      }
    // VT_Obj(value=map) => {
    //   let key = key.to_string()
    //   match map[key] {
    //     Some(mvalue) => {
    //       match valueType {
    //         StrMap =>
    //           match mvalue.data {
    //             VT_Obj(_) => ()
    //             _ => mvalue.data = VT_Obj(value={})
    //           }
    //         IntMap =>
    //           match mvalue.data {
    //             VT_IntKeyObj(_) => ()
    //             _ => mvalue.data = VT_IntKeyObj(value={})
    //           }
    //         Array =>
    //           match mvalue.data {
    //             VT_Array(_) => ()
    //             _ => mvalue.data = VT_Array(value=[])
    //           }
    //       }
    //       return mvalue
    //     }
    //     _ => {
    //       let result = {
    //         parent: Some(self),
    //         data: match valueType {
    //           StrMap => VT_Obj(value={})
    //           IntMap => VT_IntKeyObj(value={})
    //           Array => VT_Array(value=[])
    //         },
    //       }
    //       map[key] = result
    //       return result
    //     }
    //   }
    // }
    VT_Array(value=arr) =>
      if key < arr.length().to_int64() {
        let index = key.to_int()
        return match valueType {
          StrMap =>
            match arr[index].data {
              VT_Obj(_) => arr[index]
              _ => {
                let result = { parent: Some(self), data: VT_Obj(value={}) }
                arr[index] = result
                result
              }
            }
          IntMap =>
            match arr[index].data {
              VT_IntKeyObj(_) => arr[index]
              _ => {
                let result = {
                  parent: Some(self),
                  data: VT_IntKeyObj(value={}),
                }
                arr[index] = result
                result
              }
            }
          Array =>
            match arr[index].data {
              VT_Array(_) => arr[index]
              _ => {
                let result = { parent: Some(self), data: VT_Array(value=[]) }
                arr[index] = result
                result
              }
            }
        }
      }
    _ => ()
  }
  //改变类型
  let map : Map[Int64, MoonValue[T, B]] = {}
  let result = {
    parent: Some(self),
    data: match valueType {
      StrMap => VT_Obj(value={})
      IntMap => VT_IntKeyObj(value={})
      Array => VT_Array(value=[])
    },
  }
  map[key] = result
  self.data = VT_IntKeyObj(value=map)
  result
}

///|
pub fn add_arr_object[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  valueType : CompValueType
) -> MoonValue[T, B] {
  match self.data {
    VT_Array(value=arr) =>
      match valueType {
        StrMap => {
          let result = { parent: Some(self), data: VT_Obj(value={}) }
          arr.push(result)
          return result
        }
        IntMap => {
          let result = { parent: Some(self), data: VT_IntKeyObj(value={}) }
          arr.push(result)
          return result
        }
        Array => {
          let result = { parent: Some(self), data: VT_Array(value=[]) }
          arr.push(result)
          return result
        }
      }
    _ => ()
  }
  let arr : Array[MoonValue[T, B]] = []
  let result = {
    parent: Some(self),
    data: match valueType {
      StrMap => VT_Obj(value={})
      IntMap => VT_IntKeyObj(value={})
      Array => VT_Array(value=[])
    },
  }
  arr.push(result)
  self.data = VT_Array(value=arr)
  result
}

///|
pub fn set_index_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : T
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_String(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_String(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_share_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : StringView[T, B]
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_ShareString(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_ShareString(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : B
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_Bin(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_Bin(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_share_bin[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : BinaryView[B]
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_ShareBin(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_ShareBin(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_datetime[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : @datetime.DateTime
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_DateTime(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_DateTime(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_float[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : Float
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_Float(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_Float(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_double[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : Double
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_Double(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_Double(value=v) })
      }
    _ => ()
  }
}

///|
pub fn set_index_bool[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : Bool
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        if v {
          arr[index].data = VT_True
        } else {
          arr[index].data = VT_False
        }
      } else if v {
        arr.push({ parent: Some(self), data: VT_True })
      } else {
        arr.push({ parent: Some(self), data: VT_False })
      }
    _ => ()
  }
}

///|
pub fn set_index_int64[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  index : Int,
  v : Int64
) -> Unit {
  match self.data {
    VT_Array(value=arr) =>
      if index >= 0 && index < arr.length() {
        arr[index].data = VT_Int(value=v)
      } else {
        arr.push({ parent: Some(self), data: VT_Int(value=v) })
      }
    _ => ()
  }
}

///|
pub fn convert2KV[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Unit {
  self.data = VT_Obj(value={})
}

///|
pub fn convert2IntKV[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Unit {
  self.data = VT_IntKeyObj(value={})
}

///|
pub fn set_bool[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : Bool
) -> Unit {
  if value {
    self.data = VT_True
  } else {
    self.data = VT_False
  }
}

///|
pub fn set_int[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : Int64
) -> Unit {
  self.data = VT_Int(value~)
}

///|
pub fn set_nil[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Unit {
  self.data = VT_Null
}

///|
pub fn set_double[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : Double
) -> Unit {
  self.data = VT_Double(value~)
}

///|
pub fn set_float[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : Float
) -> Unit {
  self.data = VT_Float(value~)
}

///|
pub fn set_datetime[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : @datetime.DateTime
) -> Unit {
  self.data = VT_DateTime(value~)
}

///|
pub fn set_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B],
  value : T
) -> Unit {
  self.data = VT_String(value~)
}

///|
pub fn convert2Array[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Unit {
  self.data = VT_Array(value=[])
}

///|
fn level[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Int {
  loop self.parent, 0 {
    Some(parent), result => continue parent.parent, 1 + result
    _, result => break result
  }
}

///|
pub fn to_string[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> String {
  match self.data {
    VT_Null => "null"
    VT_True => "true"
    VT_False => "false"
    VT_Int(value=v) => v.to_string()
    VT_Double(value=v) => v.to_string()
    VT_Float(value=v) => v.to_string()
    VT_String(value=v) => v.to_string()
    VT_Bin(value=v) => Show::to_string(v)
    VT_Ext(value=_, extType=_) => ""
    VT_DateTime(value=v) => Show::to_string(v)
    VT_Obj(value=obj) => {
      let builder : StringBuilder = StringBuilder::new()
      let mulSpace = self.level()
      let space = String::make(mulSpace * 2, ' ')
      let childSpace = String::make((mulSpace + 1) * 2, ' ')
      builder.write_char('{')
      let mut first = true
      for k, v in obj {
        if first {
          first = false
        } else {
          builder.write_char(',')
        }
        builder.write_string("\n\{childSpace}\{k.to_string()}:")
        match v.data {
          VT_String(value=str) =>
            builder.write_string(" \"\{str.to_string()}\"")
          _ => builder.write_string("\{v.to_string()}")
        }
      }
      builder.write_string("\n\{space}}")
      builder.to_string()
    }
    VT_Array(value=arr) => {
      let builder : StringBuilder = StringBuilder::new()
      builder.write_char('[')
      let mut first = true
      for v in arr {
        if first {
          first = false
        } else {
          builder.write_char(',')
        }
        builder.write_string("\{v.to_string()}")
      }
      builder.write_char(']')
      builder.to_string()
    }
    VT_ShareBin(value=_) => ""
    VT_ShareExt(value=_, extType=_) => ""
    VT_ShareString(value=view) => "\"\{view.string()}\""
    VT_IntKeyObj(value=intMap) => {
      let builder : StringBuilder = StringBuilder::new()
      let mulSpace = self.level()
      let space = String::make(mulSpace * 2, ' ')
      let childSpace = String::make((mulSpace + 1) * 2, ' ')
      builder.write_char('{')
      let mut first = true
      for k, v in intMap {
        if first {
          first = false
        } else {
          builder.write_char(',')
        }
        builder.write_string("\n\{childSpace}\{k}:")
        match v.data {
          VT_String(value=str) =>
            builder.write_string(" \"\{str.to_string()}\"")
          _ => builder.write_string("\{v.to_string()}")
        }
      }
      builder.write_string("\n\{space}}")
      builder.to_string()
    }
  }
}

///|
/// iterate all childs
pub fn iter[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Iter[MoonValue[T, B]] {
  Iter::new(fn(yieldfn) {
    match self.data {
      VT_Obj(value=map) => {
        for _, v in map {
          match yieldfn(v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      VT_IntKeyObj(value=map) => {
        for _, v in map {
          match yieldfn(v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      VT_Array(value=arr) => {
        for _, v in arr {
          match yieldfn(v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      _ => IterEnd
    }
  })
}

///|
/// only iterate on map[IString,moonvalue]
pub fn iter2[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Iter2[T, MoonValue[T, B]] {
  Iter2::new(fn(yieldfn) {
    match self.data {
      VT_Obj(value=map) => {
        for k, v in map {
          match yieldfn(k, v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      _ => IterEnd
    }
  })
}

///|
/// only iterate on arrays or intmap
pub fn iter_intmap_array[T : IString + Hash + Eq, B : IBinReader](
  self : MoonValue[T, B]
) -> Iter2[Int64, MoonValue[T, B]] {
  Iter2::new(fn(yieldfn) {
    match self.data {
      VT_IntKeyObj(value=map) => {
        for k, v in map {
          match yieldfn(k, v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      VT_Array(value=arr) => {
        for idx, v in arr {
          match yieldfn(idx.to_int64(), v) {
            IterEnd => return IterEnd
            _ => continue
          }
        }
        IterEnd
      }
      _ => IterEnd
    }
  })
}

///|
test "iter" {
  let v : MoonValue[String, Bytes] = MoonValue::new_object({})
  v.set_key_string("name", "dxsoft")
  let child = MoonValue::new_object({})
  child.set_key_string("name", "child1")
  let cc = child.add_key_object("children", StrMap)
  cc.set_key_int("age", 32)
  v["children"] = child
  for key, value in v {
    assert_eq!(key, "name")
    assert_eq!(value.to_string(), "dxsoft")
    break
  }
}
