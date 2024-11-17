pub(all) enum ValueData {
  VT_Null
  VT_True
  VT_False
  VT_Int(value~ : Int64)
  VT_Double(value~ : Double)
  VT_Float(value~ : Float)
  VT_String(value~ : IString)
  VT_Bin(value~ : IBinary)
  VT_Ext(value~ : IBinary, extType~ : Int)
  VT_Obj(value~ : Map[IString, MoonValue])
  VT_Array(value~ : Array[MoonValue])
  VT_IntKeyObj(value~ : Map[Int64, MoonValue])
}

struct MoonValue {
  mut parent : MoonValue?
  mut data : ValueData
}

pub fn MoonValue::new_object(data : Map[IString, MoonValue]) -> MoonValue {
  { parent: None, data: VT_Obj(value=data) }
}

pub fn MoonValue::new_array(arr : Array[MoonValue]) -> MoonValue {
  { parent: None, data: VT_Array(value=arr) }
}

pub fn value(self : MoonValue) -> ValueData {
  self.data
}

pub fn parent(self : MoonValue) -> MoonValue? {
  self.parent
}

pub fn as_double(self : MoonValue, default~ : Double = 0) -> Double {
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

pub fn as_int(self : MoonValue, default~ : Int = 0) -> Int {
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

pub fn as_bool(self : MoonValue, default~ : Bool) -> Bool {
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

pub fn set_key_int(self : MoonValue, key : IString, v : Int) -> Unit {
  self.set_key_int64(key, v.to_int64())
}

pub fn set_key_bool(self : MoonValue, key : IString, bool : Bool) -> Unit {
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

pub fn set_key_float(self : MoonValue, key : IString, v : Float) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Float(value=v)
        None => value[key] = { parent: Some(self), data: VT_Float(value=v) }
      }
    _ => ()
  }
}

pub fn set_key_double(self : MoonValue, key : IString, v : Double) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Double(value=v)
        None => value[key] = { parent: Some(self), data: VT_Double(value=v) }
      }
    _ => ()
  }
}

pub fn set_key_bin(self : MoonValue, key : IString, v : IBinary) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Bin(value=v)
        None => value[key] = { parent: Some(self), data: VT_Bin(value=v) }
      }
    _ => ()
  }
}

pub fn set_key_ext(
  self : MoonValue,
  key : IString,
  v : IBinary,
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

pub fn set_intkey_ext(
  self : MoonValue,
  key : Int64,
  v : IBinary,
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

pub fn set_index_ext(
  self : MoonValue,
  index : Int,
  v : IBinary,
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

pub fn set_intkey_float(self : MoonValue, key : Int64, v : Float) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Float(value=v)
        None => value[key] = { parent: Some(self), data: VT_Float(value=v) }
      }
    _ => ()
  }
}

pub fn set_intkey_bin(self : MoonValue, key : Int64, v : IBinary) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Bin(value=v)
        None => value[key] = { parent: Some(self), data: VT_Bin(value=v) }
      }
    _ => ()
  }
}

pub fn set_intkey_double(self : MoonValue, key : Int64, v : Double) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Double(value=v)
        None => value[key] = { parent: Some(self), data: VT_Double(value=v) }
      }
    _ => ()
  }
}

pub fn set_key_string(self : MoonValue, key : IString, v : IString) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_String(value=v)
        None => value[key] = { parent: Some(self), data: VT_String(value=v) }
      }
    _ => ()
  }
}

pub fn set_intkey_string(self : MoonValue, key : Int64, v : IString) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_String(value=v)
        None => value[key] = { parent: Some(self), data: VT_String(value=v) }
      }
    _ => ()
  }
}

pub fn set_intkey_bool(self : MoonValue, key : Int64, v : Bool) -> Unit {
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

pub fn set_intkey_int64(self : MoonValue, key : Int64, v : Int64) -> Unit {
  match self.data {
    VT_IntKeyObj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Int(value=v)
        None => value[key] = { parent: Some(self), data: VT_Int(value=v) }
      }
    _ => ()
  }
}

pub fn set_key_int64(self : MoonValue, key : IString, v : Int64) -> Unit {
  match self.data {
    VT_Obj(value~) =>
      match value[key] {
        Some(vdata) => vdata.data = VT_Int(value=v)
        None => value[key] = { parent: Some(self), data: VT_Int(value=v) }
      }
    _ => ()
  }
}

pub(all) enum CompValueType {
  StrMap
  IntMap
  Array
}

pub fn add_key_object(
  self : MoonValue,
  key : IString,
  valueType : CompValueType
) -> MoonValue {
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
  let map : Map[IString, MoonValue] = {}
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

pub fn add_intkey_object(
  self : MoonValue,
  key : Int64,
  valueType : CompValueType
) -> MoonValue {
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
    VT_Obj(value=map) => {
      let key = key.to_string()
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
    }
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
  let map : Map[Int64, MoonValue] = {}
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

pub fn add_arr_object(self : MoonValue, valueType : CompValueType) -> MoonValue {
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
  }
  let arr : Array[MoonValue] = []
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

pub fn set_index_string(self : MoonValue, index : Int, v : IString) -> Unit {
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

pub fn set_index_bin(self : MoonValue, index : Int, v : IBinary) -> Unit {
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

pub fn set_index_float(self : MoonValue, index : Int, v : Float) -> Unit {
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

pub fn set_index_double(self : MoonValue, index : Int, v : Double) -> Unit {
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

pub fn set_index_bool(self : MoonValue, index : Int, v : Bool) -> Unit {
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

pub fn set_index_int64(self : MoonValue, index : Int, v : Int64) -> Unit {
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
