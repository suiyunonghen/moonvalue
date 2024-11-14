test "moonvalue to_string"{
  let v=@moonvalue.newObject({})  
  v.setKeyString("name","dxsoft")
  let child = @moonvalue.newObject({})
  child.setKeyString("name","huzimo")
  let cc = child.addKeyObject("children")
  cc.setKeyInt("age",234)  
  v["children"] = child  
  println(child.to_string())
  println(child.parent().unwrap().to_string())
  let c = v.addKeyObject("name")
  c.setKeyInt("year",123)
  let m = c["year"].unwrap().addKeyObject("month")
  m.setKeyString("y","gg")
  println(v.to_string())
  println(c["year"].unwrap().parent().unwrap().to_string())
}