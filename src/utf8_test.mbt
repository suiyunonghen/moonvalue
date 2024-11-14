test "utf8"{
  let arr = @moonvalue.utf16_utf8?("不得闲测试").unwrap()
  println(arr)
  let str = @moonvalue.utf8_utf16?(arr[0:])
  println(str.unwrap())
  assert_eq!(str.unwrap(),"不得闲测试")
}