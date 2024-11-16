pub(all) enum ValueData {
  VT_Null
  VT_True
  VT_False
  VT_Int(value~ : Int64)
  VT_Double(value~ : Double)
  VT_Float(value~ : Float)
  VT_String(value~ : IString)
  VT_Bin(value~ : IBinary)
  VT_Obj(value~ : Map[IString, MoonValue])
  VT_Array(value~ : Array[MoonValue])
  VT_IntKeyObj(value~ : Map[Int64, MoonValue])
}

struct MoonValue {
  mut parent : MoonValue?
  mut data : ValueData
}

pub fn MoonValue::newObject(data : Map[IString, MoonValue]) -> MoonValue {
  { parent: None, data: VT_Obj(value=data) }
}

pub fn MoonValue::newArray(arr : Array[MoonValue]) -> MoonValue {
  { parent: None, data: VT_Array(value=arr) }
}

pub fn value(self : MoonValue) -> ValueData {
  self.data
}

pub fn parent(self : MoonValue) -> MoonValue? {
  self.parent
}

pub fn asDouble(self : MoonValue, default~ : Double = 0) -> Double {
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
    _ => default
  }
}

pub fn asInt(self : MoonValue, default~ : Int = 0) -> Int {
  match self.data {
    VT_Int(value=v) => v.to_int()
    VT_Double(value=v) => v.to_int()
    VT_Float(value=v) => v.to_double().to_int()
    VT_True => 1
    VT_False => 0
    VT_String(value=v) =>
      match @strconv.parse_int?(IString::to_string(v)) {
        Ok(result) => result
        _ => default
      }
    _ => default
  }
}

pub fn asBool(self : MoonValue, default~ : Bool) -> Bool {
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
    _ => default
  }
}

pub fn op_set(self : MoonValue, key : IString, val : MoonValue) -> Unit {
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

pub fn op_get(self : MoonValue, key : IString) -> MoonValue? {
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

pub fn setKeyInt(self : MoonValue, key : IString, v : Int) -> Unit {
  self.setKeyInt64(key, v.to_int64())
}

pub fn setKeyString(self : MoonValue, key : IString, v : IString) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      value[key] = { parent: Some(self), data: VT_String(value=v) }
    _ => ()
  }
}

pub fn setKeyInt64(self : MoonValue, key : IString, v : Int64) -> Unit {
  match self.data {
    VT_Obj(value~) => value[key] = { parent: Some(self), data: VT_Int(value=v) }
    _ => ()
  }
}

pub fn addKeyObject(self : MoonValue, key : IString) -> MoonValue {
  match self.data {
    VT_Obj(value=map) =>
      match map[key] {
        Some(mvalue) => {
          match mvalue.data {
            VT_Obj(_) => ()
            _ => {
              let result = {}
              mvalue.data = VT_Obj(value=result)
            }
          }
          return mvalue
        }
        _ => {
          let result = { parent: Some(self), data: VT_Obj(value={}) }
          map[key] = result
          return result
        }
      }
    VT_IntKeyObj(value=map) =>
      match @strconv.parse_int64?(key.to_string()) {
        Ok(intKey) =>
          match map[intKey] {
            Some(mvalue) => {
              match mvalue.data {
                VT_Obj(_) => ()
                _ => {
                  let result = {}
                  mvalue.data = VT_Obj(value=result)
                }
              }
              return mvalue
            }
            None => {
              let result = { parent: Some(self), data: VT_Obj(value={}) }
              map[intKey] = result
              return result
            }
          }
        _ => ()
      }
    VT_Array(value=arr) =>
      match @strconv.parse_int?(key.to_string()) {
        Ok(index) => if index < arr.length() { return arr[index] }
        _ => ()
      }
    _ => ()
  }
  //改变类型
  let map : Map[IString, MoonValue] = {}
  let result = { parent: Some(self), data: VT_Obj(value={}) }
  map[key] = result
  self.data = VT_Obj(value=map)
  result
}

pub fn convert2KV(self : MoonValue) -> Unit {
  self.data = VT_Obj(value={})
}

pub fn convert2IntKV(self : MoonValue) -> Unit {
  self.data = VT_IntKeyObj(value={})
}

pub fn convert2Bool(self : MoonValue, value : Bool) -> Unit {
  if value {
    self.data = VT_True
  } else {
    self.data = VT_False
  }
}

pub fn convert2Int(self : MoonValue, value : Int64) -> Unit {
  self.data = VT_Int(value~)
}

pub fn convert2Null(self : MoonValue) -> Unit {
  self.data = VT_Null
}

pub fn convert2Double(self : MoonValue, value : Double) -> Unit {
  self.data = VT_Double(value~)
}

pub fn convert2Float(self : MoonValue, value : Float) -> Unit {
  self.data = VT_Float(value~)
}

pub fn convert2Array(self : MoonValue) -> Unit {
  self.data = VT_Array(value=[])
}

pub fn convert2Bin(self : MoonValue) -> Unit {
  //self.data = VT_Bin(ArrayView)
}

fn level(self : MoonValue) -> Int {
  loop self.parent, 0 {
    Some(parent), result => continue parent.parent, 1 + result
    _, result => break result
  }
}

pub fn to_string(self : MoonValue) -> String {
  match self.data {
    VT_Null => "null"
    VT_True => "true"
    VT_False => "false"
    VT_Int(value=v) => v.to_string()
    VT_Double(value=v) => v.to_string()
    VT_Float(value=v) => v.to_string()
    VT_String(value=v) => v.to_string()
    VT_Bin(value=v) => v.to_string()
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
        builder.write_string("\n\{childSpace}\{k}:")
        match v.data {
          VT_String(value=str) => builder.write_string(" \"\{str}\"")
          _ => builder.write_string("\{v}")
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
        builder.write_string("\{v},")
      }
      builder.write_char(']')
      builder.to_string()
    }
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
          VT_String(value=str) => builder.write_string(" \"\{str}\"")
          _ => builder.write_string("\{v}")
        }
      }
      builder.write_string("\n\{space}}")
      builder.to_string()
    }
  }
}
