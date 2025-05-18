// defn get0 (xs)
//   if (nil? xs) nil $ .-0 xs
// defn get1 (xs)
//   if (nil? xs) nil $ .-1 xs

// def peek-emphasis $ new js/RegExp "\"^(.+)\\*\\*"

///|
let peek_emphasis : JsRegex = JsRegex::js_regex_create("^(.*)\\*\\*", "")

// def peek-image $ new js/RegExp "\"^\\!\\[[^\\]]*\\]\\([^\\)]+\\)" "\"g"

///|
let peek_image : JsRegex = JsRegex::js_regex_create(
  "^\\!\\[[^\\]]*\\]\\([^\\)]+\\)", "g",
)

// def peek-italic $ new js/RegExp "\"^([^*/]+)\\*"

///|
let peek_itali : JsRegex = JsRegex::js_regex_create("^([^*/]+)\\*", "")

// def peek-link $ new js/RegExp "\"^\\[[^\\]]+\\]\\([^\\)]+\\)"

///|
let peek_link : JsRegex = JsRegex::js_regex_create(
  "^\\[[^\\]]+\\]\\([^\\)]+\\)", "",
)

// defn split-block (text)
//   split-block-iter (split-lines text) ([]) ([]) :empty

///|
enum Block {
  Empty
  Text(@immut/array.T[String])
  Code(@immut/array.T[String])
  Table(@immut/array.T[Array[String]])
} derive(Show, Eq)

///|
fn split_block(text : String) -> Array[Block] {
  split_block_iter(
    text.split("\n").map(fn(x) -> String { x.to_string() }).to_array(),
    [],
    Empty,
  )
}

// defn split-block-iter (lines acc buffer mode)
//   if (empty? lines)
//     if (empty? buffer) acc $ conj acc (:: mode buffer)
//     let
//         cursor $ first lines
//         left $ rest lines
//       case-default mode
//         raise $ str "|Strange splitting mode: " mode
//         :empty $ cond
//             = cursor |
//             recur left acc ([]) :empty
//           (starts-with? cursor "|```")
//             recur left acc
//               [] $ &str:slice cursor 3
//               , :code
//           (table-line? cursor)
//             recur left
//               conj acc $ :: :text buffer
//               [] $ split-table-content cursor
//               , :table
//           true $ recur left acc ([] cursor) :text
//         :text $ cond
//             = cursor |
//             recur left
//               conj acc $ :: :text buffer
//               []
//               , :empty
//           (starts-with? cursor "|```")
//             recur left
//               conj acc $ :: :text buffer
//               [] $ &str:slice cursor 3
//               , :code
//           (table-line? cursor)
//             recur left
//               conj acc $ :: :text buffer
//               [] $ split-table-content cursor
//               , :table
//           true $ recur left acc (conj buffer cursor) :text
//         :code $ if (starts-with? cursor "|```")
//           recur left
//             conj acc $ :: :code buffer
//             []
//             , :empty
//           recur left acc (conj buffer cursor) :code
//         :table $ if (table-line? cursor)
//           recur left acc
//             conj buffer $ split-table-content cursor
//             , :table
//           recur left
//             conj acc $ :: :table buffer
//             []
//             , :empty

///|
fn split_block_iter(
  lines : Array[String],
  acc : Array[Block],
  buffer : Block
) -> Array[Block] {
  if lines.is_empty() {
    if buffer is Empty {
      acc.push(Block::Empty)
    } else {
      acc.push(buffer)
    }
    return acc
  }
  let cursor = lines[0]
  let left = lines[1:].to_array()
  match buffer {
    Block::Empty =>
      if cursor == "" {
        split_block_iter(left, acc, Block::Empty)
      } else if cursor.has_prefix("|```") {
        split_block_iter(
          left,
          acc,
          Block::Code(
            @immut/array.from_array([cursor.substring(start=3).to_string()]),
          ),
        )
      } else if is_table_line(cursor) {
        split_block_iter(
          left,
          acc,
          Block::Table(@immut/array.from_array([split_table_content(cursor)])),
        )
      } else {
        split_block_iter(
          left,
          acc,
          Block::Text(@immut/array.from_array([cursor])),
        )
      }
    Block::Text(buffer) =>
      if cursor == "" {
        split_block_iter(left, acc, Block::Empty)
      } else if cursor.has_prefix("|```") {
        split_block_iter(left, acc, Block::Code(buffer))
      } else if is_table_line(cursor) {
        split_block_iter(
          left,
          acc,
          Block::Table(@immut/array.from_array([split_table_content(cursor)])),
        )
      } else {
        split_block_iter(left, acc, Block::Text(buffer.push(cursor)))
      }
    Block::Code(buffer) =>
      if cursor.has_prefix("|```") {
        split_block_iter(left, acc, Block::Empty)
      } else {
        split_block_iter(left, acc, Block::Code(buffer.push(cursor)))
      }
    Block::Table(buffer) =>
      if is_table_line(cursor) {
        split_block_iter(
          left,
          acc,
          Block::Table(buffer.push(split_table_content(cursor))),
        )
      } else {
        split_block_iter(left, acc, Block::Empty)
      }
  }
}

// defn split-line (line)
//   split-line-iter ([]) line | :text

///|
enum LineChunk {
  Text(String)
  Code(String)
  Url(String)
  Link(String)
  Image(String)
  Emphasis(String)
  Italic(String)
} derive(Show, Eq)

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

// defn split-line-iter (acc line buffer mode)
//   if (= | line)
//     if (= | buffer) acc $ conj acc (:: mode buffer)
//     let
//         cursor $ first line
//         left $ &str:slice line 1
//       case-default mode
//         raise $ str "|Unknown mode:" mode
//         :text $ case-default cursor
//           recur acc left (str buffer cursor) :text
//           "|`" $ recur
//             if (some? buffer)
//               conj acc $ :: :text buffer
//               , acc
//             , left | :code
//           |h $ if
//             or
//               = |http:// $ &str:slice line 0 7
//               = |https:// $ &str:slice line 0 8
//             let
//                 pieces $ split line "| "
//               recur
//                 conj
//                   if (= | buffer) acc $ conj acc (:: :text buffer)
//                   :: :url $ first pieces
//                 str "| " $ join-str (rest pieces) "| "
//                 , | :text
//             recur acc left (str buffer |h) :text
//           |[ $ let
//               guess $ get0 (.!match line peek-link)
//             if (some? guess)
//               recur
//                 conj
//                   if (= | buffer) acc $ conj acc (:: :text buffer)
//                   :: :link guess
//                 .!replace line guess |
//                 , | :text
//               recur acc left (str buffer |[) :text
//           |! $ let
//               guess $ get0 (.!match line peek-image)
//             if (some? guess)
//               recur
//                 conj
//                   if (= | buffer) acc $ conj acc (:: :text buffer)
//                   :: :image guess
//                 .replace line guess |
//                 , | :text
//               recur acc left (str buffer |!) :text
//           |* $ if (= left "\"")
//             recur acc left (str buffer |*) :text
//             let
//                 next-left $ &str:slice left 1
//               if
//                 = "\"*" $ first left
//                 let
//                     matched $ .!match next-left peek-emphasis
//                   if (some? matched)
//                     let
//                         emphasis $ get1 matched
//                         rest-line $ &str:slice next-left
//                           + 2 $ count emphasis
//                       recur
//                         conj acc (:: :text buffer) (:: :emphasis emphasis)
//                         , rest-line | :text
//                     recur acc left (str buffer |*) :text
//                 let
//                     matched $ .!match left peek-italic
//                   if (some? matched)
//                     let
//                         italic $ get1 matched
//                         rest-line $ &str:slice next-left (count italic)
//                       recur
//                         conj acc (:: :text buffer) (:: :italic italic)
//                         , rest-line | :text
//                     recur acc left (str buffer |*) :text
//         :code $ if (= cursor "|`")
//           recur
//             conj acc $ :: :code buffer
//             , left | :text
//           recur acc left (str buffer cursor) :code

///|
fn split_line_iter(
  acc : Array[LineChunk],
  line : String,
  mode : LineChunk
) -> Array[LineChunk] {
  if line == "" {
    if mode.is_empty() {
      return acc
    } else {
      acc.push(mode)
      return acc
    }
  }
  let cursor = line[0]
  let left = line.substring(start=1).to_string()
  // println("cursor: \{cursor} .. mode: \{mode} .. line: \{line}")
  match mode {
    Text(buffer) =>
      match cursor {
        '`' => split_line_iter(acc, left, Code(buffer + cursor.to_string()))
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
            split_line_iter(acc, line.replace(old=guess, new="|"), Text(""))
          } else {
            split_line_iter(acc, left, Text(buffer + cursor.to_string()))
          }
        '*' =>
          if left == "\"" {
            split_line_iter(acc, left, Text(buffer + "*"))
          } else {
            let next_left = left.substring(start=1)
            if left.has_prefix("*") {
              if match_string_pattern(next_left, peek_emphasis) is Some(matched) {
                let emphasis = matched.selects[0]
                let rest_line = left.substring(start=emphasis.length() + 2)
                acc.push(Emphasis(emphasis))
                split_line_iter(acc, rest_line, Text(""))
              } else {
                split_line_iter(acc, left, Text(buffer + "*"))
              }
            } else if match_string_pattern(left, peek_itali) is Some(matched) {
              let italic = matched.selects[0]
              let rest_line = left.substring(start=italic.length())
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

// defn split-table-content (cursor)
//   -> cursor
//     .slice 1 $ dec (count cursor)
//     .split "\"|"
//     .map $ fn (x) (.trim x)

///|
fn split_table_content(cursor : String) -> Array[String] {
  cursor
  .substring(start=1, end=cursor.length() - 1)
  .split("|")
  .map(fn(x) { x.trim(" ").to_string() })
  .to_array()
}

// defn table-line? (cursor)
//   and (starts-with? cursor "\"|") (ends-with? cursor "\"|")

///|
fn is_table_line(cursor : String) -> Bool {
  cursor.has_prefix("|") && cursor.has_suffix("|")
}
