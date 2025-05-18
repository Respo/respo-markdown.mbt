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
  Text(Array[String])
  Code(Array[String])
  Table(Array[String])
}

///|
fn split_block(text : String) -> Array[Block] {
  split_block_iter(split_lines(text), [], [], "empty")
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
  Unknown(String)
}

///|
fn split_line(line : String) -> Array[LineChunk] {
  split_line_iter([], line, "", Text)
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

// defn split-table-content (cursor)
//   -> cursor
//     .slice 1 $ dec (count cursor)
//     .split "\"|"
//     .map $ fn (x) (.trim x)

fn split_table_content(cursor : String) -> Array[String] {
  cursor.substring(start=1, end=cursor.len() - 1).split("|").map(|x| x.trim()).to_array()
}

// defn table-line? (cursor)
//   and (starts-with? cursor "\"|") (ends-with? cursor "\"|")

///|
fn is_table_line(cursor : String) -> Bool {
  cursor.has_prefix("|") && cursor.has_suffix("|")
}
