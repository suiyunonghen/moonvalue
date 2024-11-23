test "moonvalue to_string" {
  let v : @moonvalue.MoonValue[String, Bytes] = @moonvalue.new_object({})
  v.set_key_string("name", "dxsoft")
  let child = @moonvalue.new_object({})
  child.set_key_string("name", "child1")
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
}
