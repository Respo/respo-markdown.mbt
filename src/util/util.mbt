///|
#external
priv type JsRegex

///|
/// extract basic information from a regex match result
priv struct MatchResult {
  matched : String
  // start : UInt
  selects : Array[String]
} derive(Show)

///|
extern "js" fn JsRegex::js_regex_create(
  pattern : String,
  flags : String,
) -> JsRegex =
  #| (pattern, flags) => new RegExp(pattern, flags)

///|
extern "js" fn JsRegex::match_str(regex : JsRegex, input : String) -> JsValue =
  #| (regex, input) => {
  #|   let ret = input.match(regex);
  #|   console.log("match result: ", ret);
  #|   return ret;
  #| }

///|
#external
priv type JsValue

///|
extern "js" fn JsValue::is_null(obj : JsValue) -> Bool =
  #| (obj) => obj === null

///|
extern "js" fn JsValue::get_length(obj : JsValue) -> UInt =
  #| (obj) => obj.length

///|
extern "js" fn JsValue::reinterpret_as_string(obj : JsValue) -> String =
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
    // let start = JsValue::get_prop(matched, "index")
    let selects : Array[String] = Array::new()
    let len = JsValue::get_length(ret).reinterpret_as_int()
    for i = 0; i < len; i = i + 1 {
      if i == 0 {
        continue
      }
      let item = JsValue::get_index(ret, i.reinterpret_as_uint())
      selects.push(item.reinterpret_as_string())
    }
    Some(MatchResult::{
      matched: matched.reinterpret_as_string(),
      // start: start.reinterpret_as_int().reinterpret_as_uint(),
      selects,
    })
  }
}

///|
let peek_emphasis : JsRegex = JsRegex::js_regex_create("^([^\\*]*)\\*\\*", "")

// def peek-image $ new js/RegExp "\"^\\!\\[[^\\]]*\\]\\([^\\)]+\\)" "\"g"

///|
let peek_image : JsRegex = JsRegex::js_regex_create(
  "^\\!\\[[^\\]]*\\]\\([^\\)]+\\)", "g",
)

///|
let peek_italic : JsRegex = JsRegex::js_regex_create("^([^*/]+)\\*", "")

///|
let peek_link : JsRegex = JsRegex::js_regex_create(
  "^\\[[^\\]]+\\]\\([^\\)]+\\)", "",
)

///| Check if line contains a code fence (```) with optional leading whitespace

///|
/// Returns Some((indent, lang)) if found, None otherwise
fn parse_code_fence(line : String) -> (Int, String)? {
  let trimmed = line.trim_start(chars=" ").to_string()
  if trimmed.has_prefix("```") {
    let indent = line.length() - trimmed.length()
    let lang = trimmed.unsafe_substring(start=3, end=trimmed.length())
    Some((indent, lang))
  } else {
    None
  }
}

///|
/// Remove leading spaces from a line up to the specified indent level
fn remove_indent(line : String, indent : Int) -> String {
  let mut count = 0
  let mut start_idx = 0
  for i = 0; i < line.length() && count < indent; i = i + 1 {
    if line.get_char(i) == Some(' ') {
      count = count + 1
      start_idx = i + 1
    } else {
      break
    }
  }
  line.unsafe_substring(start=start_idx, end=line.length())
}

///|
pub enum Block {
  Empty
  Text(@immut/array.T[String])
  Code(Int, @immut/array.T[String]) // (indent, lines)
  Table(@immut/array.T[Array[String]])
}

///|
pub fn split_block(text : String) -> Array[Block] {
  split_block_iter(
    text.split("\n").map(fn(x) -> String { x.to_string() }).to_array(),
    [],
    Empty,
    0, // code_indent: track the indentation level of code block
  )
}

///|
fn split_block_iter(
  lines : Array[String],
  acc : Array[Block],
  buffer : Block,
  code_indent : Int,
) -> Array[Block] {
  if lines.is_empty() {
    if buffer is Empty {
      //
    } else {
      acc.push(buffer)
    }
    return acc
  }
  let cursor = lines[0]
  let left = lines[1:].to_array()
  match buffer {
    Empty =>
      if cursor == "" {
        split_block_iter(left, acc, Empty, 0)
      } else if parse_code_fence(cursor) is Some((indent, lang)) {
        split_block_iter(
          left,
          acc,
          Code(indent, @immut/array.from_array([lang])),
          indent,
        )
      } else if is_table_line(cursor) {
        if cursor != "" {
          acc.push(Text(@immut/array.from_array([cursor])))
        }
        split_block_iter(
          left,
          acc,
          Table(@immut/array.from_array([split_table_content(cursor)])),
          0,
        )
      } else {
        split_block_iter(left, acc, Text(@immut/array.from_array([cursor])), 0)
      }
    Text(buffer) =>
      if cursor == "" {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(left, acc, Empty, 0)
      } else if parse_code_fence(cursor) is Some((indent, lang)) {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(
          left,
          acc,
          Code(indent, @immut/array.from_array([lang])),
          indent,
        )
      } else if is_table_line(cursor) {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(
          left,
          acc,
          Table(@immut/array.from_array([split_table_content(cursor)])),
          0,
        )
      } else {
        split_block_iter(left, acc, Text(buffer.push(cursor)), 0)
      }
    Code(block_indent, buffer) =>
      // Check for closing fence with same or less indentation
      if parse_code_fence(cursor) is Some((indent, _)) && indent <= code_indent {
        acc.push(Code(block_indent, buffer))
        split_block_iter(left, acc, Empty, 0)
      } else {
        // Remove the code block's indentation from content lines
        let content = remove_indent(cursor, code_indent)
        split_block_iter(
          left,
          acc,
          Code(block_indent, buffer.push(content)),
          code_indent,
        )
      }
    Table(buffer) =>
      if is_table_line(cursor) {
        split_block_iter(
          left,
          acc,
          Table(buffer.push(split_table_content(cursor))),
          0,
        )
      } else {
        acc.push(Table(buffer))
        split_block_iter(left, acc, Empty, 0)
      }
  }
}

///|
pub enum LineChunk {
  Text(String)
  Code(String)
  Url(String)
  Link(String)
  Image(String)
  Emphasis(String)
  Italic(String)
}

///|
pub fn LineChunk::is_empty(self : LineChunk) -> Bool {
  match self {
    Text("") => true
    Code("") => true
    Url("") => true
    Link("") => true
    Image("") => true
    Emphasis("") => true
    Italic("") => true
    _ => false
  }
}

///|
pub fn split_line(line : String) -> Array[LineChunk] {
  split_line_iter([], line, Text(""))
}

///|
fn split_line_iter(
  acc : Array[LineChunk],
  line : String,
  mode : LineChunk,
) -> Array[LineChunk] {
  if line == "" {
    if mode.is_empty() {
      return acc
    } else {
      acc.push(mode)
      return acc
    }
  }
  let cursor = line.get_char(0).unwrap()
  let left = line.unsafe_substring(start=1, end=line.length())
  // println("cursor: \{cursor} .. mode: \{mode} .. line: \{line}")
  match mode {
    Text(buffer) =>
      match cursor {
        '`' => {
          if not(buffer.is_empty()) {
            acc.push(mode)
          }
          split_line_iter(acc, left, Code(""))
        }
        'h' =>
          if line.has_prefix("http://") || line.has_prefix("https://") {
            let pieces = line
              .split(" ")
              .map(fn(x) -> String { x.to_string() })
              .to_array()
            if not(mode.is_empty()) {
              acc.push(mode)
            }
            acc.push(Url(pieces[0].to_string()))
            split_line_iter(acc, pieces[1:].to_array().join(" "), Text(""))
          } else {
            split_line_iter(acc, left, Text(buffer + cursor.to_string()))
          }
        '[' =>
          if match_string_pattern(line, peek_link) is Some(guess) {
            let guess = guess.matched
            if not(mode.is_empty()) {
              acc.push(mode)
            }
            acc.push(Link(guess.to_string()))
            split_line_iter(acc, line.replace(old=guess, new=""), Text(""))
          } else {
            split_line_iter(acc, left, Text(buffer + cursor.to_string()))
          }
        '!' =>
          if match_string_pattern(line, peek_image) is Some(guess) {
            let guess = guess.matched
            if not(mode.is_empty()) {
              acc.push(mode)
            }
            acc.push(Image(guess.to_string()))
            split_line_iter(acc, line.replace(old=guess, new=""), Text(""))
          } else {
            split_line_iter(acc, left, Text(buffer + cursor.to_string()))
          }
        '*' =>
          if left == "" {
            split_line_iter(acc, left, Text(buffer + "*"))
          } else {
            let next_left = left.unsafe_substring(start=1, end=left.length())
            if left.has_prefix("*") {
              if match_string_pattern(next_left, peek_emphasis) is Some(matched) {
                println("emphasis: \{matched}")
                let emphasis = matched.selects[0]
                let rest_line = next_left.unsafe_substring(
                  start=emphasis.length() + 2,
                  end=next_left.length(),
                )
                acc.push(mode)
                acc.push(Emphasis(emphasis))
                split_line_iter(acc, rest_line, Text(""))
              } else {
                split_line_iter(acc, left, Text(buffer + "*"))
              }
            } else if match_string_pattern(left, peek_italic) is Some(matched) {
              let italic = matched.selects[0]
              let rest_line = next_left.unsafe_substring(
                start=italic.length(),
                end=next_left.length(),
              )
              acc.push(mode)
              acc.push(Italic(italic))
              split_line_iter(acc, rest_line, Text(""))
            } else {
              split_line_iter(acc, left, Text(buffer + "*"))
            }
          }
        _ => split_line_iter(acc, left, Text(buffer + cursor.to_string()))
      }
    Code(buffer) =>
      if cursor == '`' {
        acc.push(Code(buffer))
        split_line_iter(acc, left, Text(""))
      } else {
        split_line_iter(acc, left, Code(buffer + cursor.to_string()))
      }
    _ => panic() // unknown
  }
}

///|
pub fn split_table_content(cursor : String) -> Array[String] {
  cursor
  .unsafe_substring(start=1, end=cursor.length() - 1)
  .split("|")
  .map(fn(x) { x.trim(chars=" ").to_string() })
  .to_array()
}

///|
pub fn is_table_line(cursor : String) -> Bool {
  cursor.has_prefix("|") && cursor.has_suffix("|")
}
