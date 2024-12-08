# messagepack moonvalue
Bson serializer MessagePack serializer implementation for Moonbitlang
# Design concept
VT_String stores string types. As moonbit may generate multiple backends, the string could be either Jstring or moonbit string, so it is designed as a generic type here 
The type starting with VT_Share*** represents shared memory data. When parsing, it does not perform a copy operation, but directly records the binary block area and binary. VT_ShareString will only be parsed when it is actually needed. Therefore, when using shared mode, it is important to ensure that the shared memory area is valid and not overwritten by writing, otherwise it will result in inconsistent data
# write moonvalue
You can create objects or array types using functions such as _@moonvalue.new_object_ , _new_array_, etc. Set map key value pairs using _set_key_*** _  related functions, and IntMap key value pairs  using set_intkey_***  
Set_index_*** Set array value 
```
let v : @moonvalue.MoonValue[String, Bytes] = @moonvalue.new_object({})
v.set_key_string("name", "dxsoft")
let child = @moonvalue.new_object({})
child.set_key_string("name", "huzimo")
let cc = child.add_key_object("children", StrMap)
cc.set_key_int("age", 234)
v["children"] = child
println(child.to_string())
println(child.parent().unwrap().to_string())
let c = v.add_key_object("name", StrMap)
c.set_key_int("year", 123)
let m = c["year"].unwrap().add_key_object("month", StrMap)
m.set_key_string("y", "gg")
println(v.to_string())
println(c["year"].unwrap().parent().unwrap().to_string())
```
# read moonvalue
A function similar to xxx_by_key reads data from the map type  
eg.
> string_by_key read string from map    
> bool_by_key read bool from map   
> value_by_key return MoonValue from map    

A function similar to xxx_by_index reads data from an array  
eg.
> string_by_index read string from array  
> bool_by_index read bool from array  
> value_by_index return MoonValue from array  

as_xxx retrieves the value from Moonvalue 
eg.
> as_bool  
> as_double   

```
assert_eq!(result.string_by_key("name",""),"不得闲")
assert_eq!(result.bool_by_key("men",false),true)
assert_eq!(result.value_by_key("array").unwrap().int_by_index(1,0),345)
println(result.to_string())
```

# decode msgpack
You can use the _MsgPackParser::new_ function to parse the binary data of a msgpack. The parameter shareBinary indicates whether to share binary content. If enabled, VT-ShareString will be used,
VT_ShareBin, VT_ShareExt, and other shared binary data contents are parsed when needed (ensuring the security and lifecycle of the shared binary data). The parameter binary represents the binary data to be decoded, the parameter utf8Reader is used to customize the user to read the utf8 string function, and the parameter binReader is used to read the decoded binary function   

_MsgPackParser::newparser_with_str_array_ will create a **MgPackParser[String,Array[Byte]]**, which will parse **MoonValue [String,Array[Byte]]**, using Moonbit string for strings and Array[Byte] for binary   

_MsgPackParser::newparser_with_str_bytes_ will create a **MgPackParser[String,Bytes]**, which will parse **MoonValue [String,Bytes]**, using Moonbit string for strings and Bytes for binary   

```
let b : Array[Byte] = [
  134, 164, 110, 97, 109, 101, 169, 228, 184, 141, 229, 190, 151, 233, 151, 178,
  163, 97, 103, 101, 40, 163, 109, 101, 110, 195, 163, 110, 111, 119, 203, 64,
  230, 69, 246, 246, 72, 195, 95, 167, 99, 117, 114, 116, 105, 109, 101, 215, 255,
  69, 36, 64, 76, 103, 60, 86, 173, 165, 97, 114, 114, 97, 121, 146, 34, 205, 1,
  89,
]
let parser : MsgPackParser[String, Array[Byte]] = MsgPackParser::newparser_with_str_array(true, b)
match parser.parser?() {
  Ok(result) => println(result.to_string())
  _ => println("error")
}
```

# encode msgpack
you can use MsgpackEncoder
```
let w: Array[Byte] = Array::new()
let encoder = MsgpackEncoder::new(w)
encoder.encode(result)
println(w)
```