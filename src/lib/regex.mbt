///|
extern type JsRegex

///| extract basic information from a regex match result
struct MatchResult {
  matched : String
  start : UInt
  selects : Array[String]
}

///|
extern "js" fn JsRegex::js_regex_create(
  pattern : String,
  flags : String
) -> JsRegex =
  #| (pattern, flags) => new RegExp(pattern, flags)

///|
extern "js" fn JsRegex::match_str(regex : JsRegex, input : String) -> JsValue =
  #| (regex, input) => regex.match(input)

///|
extern type JsValue

///|
extern "js" fn JsValue::is_null(obj : JsValue) -> Bool =
  #| (obj) => obj === null

///|
extern "js" fn JsValue::get_length(obj : JsValue) -> UInt =
  #| (obj) => obj.length

///|
extern "js" fn JsValue::get_prop(obj : JsValue, p : String) -> JsValue =
  #| (obj, p) => obj[p]

///|
extern "js" fn JsValue::reinterpret_as_string(obj : JsValue) -> String =
  #| (obj) => obj

///|
extern "js" fn JsValue::reinterpret_as_int(obj : JsValue) -> Int =
  #| (obj) => obj

///|
extern "js" fn JsValue::get_index(obj : JsValue, index : UInt) -> JsValue =
  #| (obj, index) => obj[index]

///|
fn match_string_pattern(input : String, reg : JsRegex) -> MatchResult? {
  let ret = JsRegex::match_str(reg, input)
  if JsValue::is_null(ret) {
    None
  } else {
    let matched = JsValue::get_index(ret, 0)
    let start = JsValue::get_prop(matched, "index")
    let selects : Array[String] = Array::new()
    let len = JsValue::get_length(ret).reinterpret_as_int() - 1
    for i = 0; i < len; i = i + 1 {
      let item = JsValue::get_index(ret, i.reinterpret_as_uint())
      selects.push(item.reinterpret_as_string())
    }
    Some(MatchResult::{
      matched: matched.reinterpret_as_string(),
      start: start.reinterpret_as_int().reinterpret_as_uint(),
      selects,
    })
  }
}
