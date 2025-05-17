///|
fnalias @respo_node.(declare_static_style, respo_style, blockquote, div)

///|
let a : InspectError = 1

///|
struct MarkdownBlockOptions {
  class_name : String?
  style : String?
  highlighter : ((String, String) -> String)?
}

// defcomp comp-code-block (lines options)
//   let
//       lang $ first lines
//       content $ join-str (rest lines) &newline
//       highlight-fn $ either (:highlight options)
//         fn (x & l) x
//     if (= lang "\"cirru")
//       memof1-call comp-cirru-snippet content $ {} (:class-name style-code-block)
//       memof1-call comp-snippet content $ {} (:class-name style-code-block) (:highlighter highlight-fn) (:lang lang)

///|
fn comp_code_block(
  lines : Array[String],
  options : MarkdownBlockOptions
) -> @respo_node.RespoNode {
  let lang = lines[0]
  let content = lines[1:].to_array().join("\n")
  let highlight_fn = options.highlighter.or(fn(x, _) -> String { x })
  if lang == "cirru" {
    return comp_cirru_snippet(content, class_name=style_code_block)
  }
  return comp_snippet(
    content,
    class_name=style_code_block,
    highliter=highlight_fn,
    lang~,
  )
}

// defn comp-image (chunk)
//   let
//       useful $ &str:slice chunk 2
//         - (count chunk) 1
//     let[] (content url) (split useful "|](")
//       img $ {} (:src url) (:class-name style-image) (:alt content)

// defcomp comp-line (line)
//   cond
//       starts-with? line "|# "
//       h1 ({}) & $ render-inline (&str:slice line 2)
//     (starts-with? line "|## ")
//       h2 ({}) & $ render-inline (&str:slice line 3)
//     (starts-with? line "|### ")
//       h3 ({}) & $ render-inline (&str:slice line 4)
//     (starts-with? line "|#### ")
//       h4 ({}) & $ render-inline (&str:slice line 5)
//     (starts-with? line "|> ")
//       blockquote
//         {} $ :class-name style-blockquote
//         , & $ render-inline (&str:slice line 2)
//     (starts-with? line "\" ")
//       let
//           content $ .!trimLeft line
//           space-size $ &- (count line) (count content)
//           spaces $ .!slice line 0 space-size
//         div ({})
//           <> (str spaces spaces) style-indent
//           comp-line $ .!trimLeft line
//     (or (starts-with? line "|* ") (starts-with? line "|- "))
//       li
//         {} $ :class-name style-line-list
//         , & $ render-inline (&str:slice line 2)
//     (starts-with? line "|#!html ")
//       div $ {} (:class-name "\"html-container")
//         :innerHTML $ .trim (&str:slice line 7)
//     true $ div ({}) & (render-inline line)

// defn comp-link (chunk)
//   let
//       useful $ &str:slice chunk 1
//         - (count chunk) 1
//     let[] (content url) (split useful "|](")
//       span ({})
//         if
//           and (starts-with? content "|`") (ends-with? content "|`")
//           a
//             {}
//               :class-name $ str-spaced css/link style-default-link
//               :href url
//               :target |_blank
//             code $ {}
//               :inner-text $ &str:slice content 1
//                 dec $ count content
//           a $ {}
//             :class-name $ str-spaced css/link style-default-link
//             :href url
//             :inner-text $ str-spaced "\"🌐" content
//             :target |_blank

// defcomp comp-md (text ? options)
//   div
//     {} $ :class-name (get options :class-name)
//     , & $ memof1-call render-inline text

///|
fn comp_md[T](text : String, class_name? : String) -> @respo_node.RespoNode[T] {
  div(class_name=class_name.or(""), [render_inline(text)])
}

// defcomp comp-md-block (text ? options)
//   let
//       blocks $ split-block text
//       class-name $ :class-name options
//     div
//       {}
//         :class-name $ if (nil? class-name) |md-block (str-spaced |md-block class-name)
//         :style $ :style options
//       , & $ -> blocks
//         map $ fn (block)
//           tag-match block
//               :text lines
//               comp-text-block lines
//             (:code lines) (comp-code-block lines options)
//             (:table lines) (comp-table-block lines)

// defn comp-table-block (lines)
//   let
//       header-line $ first lines
//       body-lines $ let
//           p0 $ get (get lines 1) 0
//         if
//           and (some? p0)
//             or (.starts-with? p0 "\":-") (.starts-with? p0 "\"--")
//           .slice lines 2
//           .slice lines 1
//     create-element :table
//       {} $ :class-name style-md-table
//       create-element :thead ({})
//         create-element :tr ({}) & $ -> header-line
//           map $ fn (x)
//             create-element :th ({}) & $ render-inline x
//       create-element :tbody ({}) & $ -> body-lines
//         map $ fn (line)
//           create-element :tr ({}) & $ -> line
//             map $ fn (x)
//               create-element :td ({}) & $ render-inline x

// defcomp comp-text-block (lines)
//   div
//     {} $ :class-name (str-spaced |md-p style-paragraph)
//     , & $ -> lines
//       map $ fn (line) (memof1-call comp-line line)

// defn render-inline (text)
//   -> (split-line text)
//     map $ fn (chunk)
//       tag-match chunk
//           :code content
//           code $ {} (:class-name style-inline-code) (:inner-text content)
//         (:url content)
//           a $ {} (:href content) (:inner-text content) (:target |_blank)
//         (:link content) (comp-link content)
//         (:image content) (comp-image content)
//         (:text content) (<> content nil)
//         (:emphasis content)
//           create-element :b ({}) & $ render-inline content
//         (:italic content)
//           create-element :i $ {} (:inner-text content)
//         _ $ <> (str |Unknown: chunk) nil

// defstyle style-blockquote $ {}
//   "\"&" $ {}
//     :border-left $ str "\"6px solid " (hsl 0 0 90)
//     :margin-left 0
//     :padding-left 12
//     :color $ hsl 0 0 50

///|
let style_blockquote : String = declare_static_style([
  (
    "&",
    respo_style(
      border=(0, Solid, Hsl(0, 0, 90)),
      margin_left=0 |> Px,
      padding_left=12 |> Px,
      color=Hsl(0, 0, 50),
    ).add("border-width", "0 0 0 6px"),
  ),
])

// defstyle style-code-block $ {}
//   "\"&" $ {} (:max-width "\"60vw")

///|
let style_code_block : String = declare_static_style([
  ("&", respo_style(max_width=60 |> Vw)),
])

// defstyle style-default-link $ {}
//   "\"&" $ {} (:opacity 0.9) (:transition-duration "\"200ms")
//   "\"&:hover" $ {} (:opacity 1) (:transform "\"scale(1)")

///|
let style_default_link : String = declare_static_style([
  ("&", respo_style(opacity=0.9, transition_duration=200 |> Ms)),
  ("&:hover", respo_style(opacity=1, transform=1 |> Scale)),
])

// defstyle style-image $ {}
//   "\"&" $ {} (:max-width 480) (:max-height 320)
//     :border $ str "\"1px solid " (hsl 0 0 90)
//     :border-radius "\"8px"

///|
let style_image : String = declare_static_style([
  (
    "&",
    respo_style(
      max_width=480 |> Px,
      max_height=320 |> Px,
      border=(0, Solid, Hsl(0, 0, 90)),
      border_radius=8,
    ),
  ),
])

// defstyle style-indent $ {}
//   "\"&" $ {} (:white-space :pre) (:float :left)

///|
let style_indent : String = declare_static_style([
  ("&", respo_style(white_space="pre", float="left")),
])

// defstyle style-inline-code $ {}
//   "\"&" $ {}
//     :border $ str "\"1px solid " (hsl 0 0 086)
//     :border-radius "\"4px"
//     :font-size 12
//     :padding "\"2px 4px"
//     :margin "\"2px 4px"

///|
let style_inline_code : String = declare_static_style([
  (
    "&",
    respo_style(
      border=(0, Solid, Hsl(0, 0, 86)),
      border_radius=4,
      font_size=12,
      padding="2px 4px" |> Custom,
      margin="2px 4px" |> Custom,
    ),
  ),
])

// defstyle style-line-list $ {}
//   "\"&" $ {} (:margin-left 12)
//   "\"&::marker" $ {}
//     :color $ hsl 0 0 80
//     :font-family ui/font-code
//     :white-space :pre
//     :content "\"'● '"
//     :transition-duration "\"300ms"
//   "\"&:hover::marker" $ {}
//     :color $ hsl 0 0 50
//     :content "\"'● '"

///|
let style_line_list : String = declare_static_style([
  ("&", respo_style(margin_left=12 |> Px)),
  (
    "&::marker",
    respo_style(
      color=Hsl(0, 0, 80),
      font_family="ui/font-code",
      white_space="pre",
      content="'● '",
      transition_duration=300 |> Ms,
    ),
  ),
  ("&:hover::marker", respo_style(color=Hsl(0, 0, 50), content="'● '")),
])

// defstyle style-md-table $ {}
//   "\"&" $ {}
//     :border $ str "\"1px solid " (hsl 0 0 90)
//     :empty-cells :show
//     :border-collapse :collapse
//   "\"& thead" $ {}
//     :background-color $ hsl 0 0 96
//   "\"& tr" $ {}
//     :border-top $ str "\"1px solid " (hsl 0 0 94)
//   "\"& td, & th" $ {}
//     :border-left $ str "\"1px solid " (hsl 0 0 94)
//     :padding "\"0.5em 1em"
//     :line-height "\"1.5em"
//     :text-align :left
//     :vertical-align :middle

///|
let style_md_table : String = declare_static_style([
  (
    "&",
    respo_style(border=(1, Solid, Hsl(0, 0, 90)))
    .add("empty-cells", "show")
    .add("border-collapse", "collapse"),
  ),
  ("& thead", respo_style(background_color=Hsl(0, 0, 96))),
  (
    "& tr",
    respo_style(
      border=(0, Solid, Hsl(0, 0, 94)),
      border_width="1px 0 0 0" |> Custom,
    ),
  ),
  (
    "& td, & th",
    respo_style(
      border=(0, Solid, Hsl(0, 0, 94)),
      border_width="0 0 0 1px" |> Custom,
      padding="0.5em 1em" |> Custom,
      line_height=1.5 |> Em,
      text_align=Left,
      vertical_align=Middle,
    ),
  ),
])

// defstyle style-paragraph $ {}
//   "\"&" $ {}

///|
let style_paragraph : String = declare_static_style([("&", respo_style())])
