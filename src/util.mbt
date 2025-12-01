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

///|
priv enum Block {
  Empty
  Text(@immut/array.T[String])
  Code(@immut/array.T[String])
  Table(@immut/array.T[Array[String]])
}

///|
fn split_block(text : String) -> Array[Block] {
  split_block_iter(
    text.split("\n").map(fn(x) -> String { x.to_string() }).to_array(),
    [],
    Empty,
  )
}

///|
fn split_block_iter(
  lines : Array[String],
  acc : Array[Block],
  buffer : Block,
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
        split_block_iter(left, acc, Empty)
      } else if cursor.has_prefix("```") {
        split_block_iter(
          left,
          acc,
          Code(@immut/array.from_array([cursor.substring(start=3).to_string()])),
        )
      } else if is_table_line(cursor) {
        if cursor != "" {
          acc.push(Text(@immut/array.from_array([cursor])))
        }
        split_block_iter(
          left,
          acc,
          Table(@immut/array.from_array([split_table_content(cursor)])),
        )
      } else {
        split_block_iter(left, acc, Text(@immut/array.from_array([cursor])))
      }
    Text(buffer) =>
      if cursor == "" {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(left, acc, Empty)
      } else if cursor.has_prefix("```") {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(left, acc, Code(buffer))
      } else if is_table_line(cursor) {
        if not(buffer.is_empty()) {
          acc.push(Text(buffer))
        }
        split_block_iter(
          left,
          acc,
          Table(@immut/array.from_array([split_table_content(cursor)])),
        )
      } else {
        split_block_iter(left, acc, Text(buffer.push(cursor)))
      }
    Code(buffer) =>
      if cursor.has_prefix("```") {
        acc.push(Code(buffer))
        split_block_iter(left, acc, Empty)
      } else {
        split_block_iter(left, acc, Code(buffer.push(cursor)))
      }
    Table(buffer) =>
      if is_table_line(cursor) {
        split_block_iter(
          left,
          acc,
          Table(buffer.push(split_table_content(cursor))),
        )
      } else {
        acc.push(Table(buffer))
        split_block_iter(left, acc, Empty)
      }
  }
}

///|
priv enum LineChunk {
  Text(String)
  Code(String)
  Url(String)
  Link(String)
  Image(String)
  Emphasis(String)
  Italic(String)
}

///|
fn LineChunk::is_empty(self : LineChunk) -> Bool {
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
fn split_line(line : String) -> Array[LineChunk] {
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
  let left = line.substring(start=1).to_string()
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
            let next_left = left.substring(start=1)
            if left.has_prefix("*") {
              if match_string_pattern(next_left, peek_emphasis) is Some(matched) {
                println("emphasis: \{matched}")
                let emphasis = matched.selects[0]
                let rest_line = next_left.substring(start=emphasis.length() + 2)
                acc.push(mode)
                acc.push(Emphasis(emphasis))
                split_line_iter(acc, rest_line, Text(""))
              } else {
                split_line_iter(acc, left, Text(buffer + "*"))
              }
            } else if match_string_pattern(left, peek_italic) is Some(matched) {
              let italic = matched.selects[0]
              let rest_line = next_left.substring(start=italic.length())
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
fn split_table_content(cursor : String) -> Array[String] {
  cursor
  .substring(start=1, end=cursor.length() - 1)
  .split("|")
  .map(fn(x) { x.trim(chars=" ").to_string() })
  .to_array()
}

///|
fn is_table_line(cursor : String) -> Bool {
  cursor.has_prefix("|") && cursor.has_suffix("|")
}
