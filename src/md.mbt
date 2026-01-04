///|
using @respo_node {
  static_style,
  blockquote,
  create_element,
  div,
  img,
  span,
  a,
  code,
  i,
  b,
  h1,
  h2,
  h3,
  h4,
  pre,
  li,
}

///|
using @css {respo_style}

///|
let code_fonts = @respo.code_fonts

///|
fn[T] comp_code_block(
  lines : Array[String],
  indent? : Int = 0,
  highlighter? : (String, String) -> String = fn(x, _) -> String { x },
) -> @respo_node.RespoNode[T] {
  let lang = lines[0]
  let content = lines[1:].to_array().join("\n")
  return comp_snippet(
    content,
    class_name=style_code_block,
    highliter=highlighter,
    indent~,
    lang~,
  )
}

///|
fn[T] comp_snippet(
  content : String,
  class_name? : String,
  highliter? : (String, String) -> String,
  indent? : Int = 0,
  lang? : String,
) -> @respo_node.RespoNode[T] {
  let highliter = highliter.unwrap_or(fn(content, _) -> String { content })
  let highlighted = highliter(content, lang.unwrap_or("text"))
  return div(
    class_list=[style_snippet, class_name.unwrap_or("")],
    style=respo_style(margin_left=Px(Float::from_int(indent) * 8.0)),
    [pre(class_name=style_code_block, children=[code(inner_text=highlighted)])],
  )
}

///|
let style_snippet : String = static_style([
  (
    "&",
    respo_style(
      font_family=code_fonts,
      border=CssBorder(1, Solid, Hsl(0, 0, 90)),
      padding=8 |> Px,
      border_radius=4,
      line_height=20 |> Px,
      font_size=12,
    ),
  ),
])

///|
fn[T] comp_image(chunk : String) -> @respo_node.RespoNode[T] {
  let useful = chunk.unsafe_substring(start=2, end=chunk.length() - 1)
  let xs = useful.split("](").map(StringView::to_string).collect()
  if xs is [content, url, ..] {
    img(class_name=style_image, src=url, alt=content)
  } else {
    return div(class_name=style_image, [
      span(inner_text="Image not found", class_name=style_image, []),
    ])
  }
}

///|
fn[T] comp_line(line : String) -> @respo_node.RespoNode[T] {
  if line.has_prefix("# ") {
    h1(render_inline(line.unsafe_substring(start=2, end=line.length())))
  } else if line.has_prefix("## ") {
    h2(render_inline(line.unsafe_substring(start=3, end=line.length())))
  } else if line.has_prefix("### ") {
    h3(render_inline(line.unsafe_substring(start=4, end=line.length())))
  } else if line.has_prefix("#### ") {
    h4(render_inline(line.unsafe_substring(start=5, end=line.length())))
  } else if line == "---" || line == "***" || line == "___" {
    let attrs = {}
    attrs.set("class", style_hr)
    create_element("hr", attrs~, event={}, style=respo_style(), [])
  } else if line.has_prefix("> ") {
    blockquote(
      class_name=style_blockquote,
      render_inline(line.unsafe_substring(start=2, end=line.length())),
    )
  } else if line.has_prefix(" ") {
    let content = line.trim_start(chars=" ").to_string()
    let space_size = line.length() - content.length()
    let spaces = line.unsafe_substring(start=0, end=space_size)
    div([
      span(inner_text=spaces, class_name=style_indent, []),
      comp_line(content),
    ])
  } else if line.has_prefix("* ") || line.has_prefix("- ") {
    li(
      class_name=style_line_list,
      render_inline(line.unsafe_substring(start=2, end=line.length())),
    )
  } else if line.has_prefix("#!html ") {
    div(
      class_name="html-container",
      innerHTML=line.unsafe_substring(start=7, end=line.length()),
      [],
    )
  } else {
    div(render_inline(line))
  }
}

///|
fn[T] comp_link(chunk : String) -> @respo_node.RespoNode[T] {
  let useful = chunk.unsafe_substring(start=1, end=chunk.length() - 1)
  let xs = useful.split("](").map(StringView::to_string).collect()
  if xs is [content, url] {
    span(class_name=style_default_link, [
      if content.has_prefix("`") && content.has_suffix("`") {
        a(class_name=style_default_link, href=url, target=Blank, children=[
          code(
            inner_text=content.unsafe_substring(
              start=1,
              end=content.length() - 1,
            ),
          ),
        ])
      } else {
        a(
          class_name=style_default_link,
          href=url,
          target=Blank,
          inner_text="🌐 \{content}",
        )
      },
    ])
  } else {
    @dom_ffi.log("Error in comp-link: " + chunk)
    span(class_name=style_default_link, inner_text="\{xs}", [])
  }
}

///|
pub fn[T] comp_md(
  text : String,
  class_name? : String,
) -> @respo_node.RespoNode[T] {
  div(class_name=class_name.unwrap_or(""), render_inline(text))
}

///|
pub fn[T] comp_md_block(
  text : String,
  class_name? : String,
  style? : @css.RespoStyle,
  highlighter? : (String, String) -> String = fn(x, _) -> String { x },
) -> @respo_node.RespoNode[T] {
  let blocks = split_block(text)
  return div(
    class_list=[class_name.unwrap_or(""), "md-block"],
    style=style.unwrap_or(respo_style()),
    blocks
    .iter()
    .map(fn(block) {
      match block {
        @md_util.Text(lines) => comp_text_block(lines.to_array())
        @md_util.Code(indent, lines) =>
          comp_code_block(lines.to_array(), indent~, highlighter~)
        @md_util.Table(lines) => comp_table_block(lines.to_array())
        @md_util.Empty => div([])
      }
    })
    .collect(),
  )
}

///|
fn[T] comp_table_block(
  lines : Array[Array[String]],
) -> @respo_node.RespoNode[T] {
  let header_line = lines[0]
  // Check if second line is a separator line (e.g., | --- | :--- |)
  let body_lines = if lines.length() > 1 && @md_util.is_separator_line(lines[1]) {
    lines[2:]
  } else {
    lines[1:]
  }
  let table_style = respo_style(margin="16px 0" |> Custom)
    .add("empty-cells", "show")
    .add("border-collapse", "collapse")
    .add("width", "100%")
  let thead_style = respo_style(background_color=Hsl(220, 10, 97)).add(
    "font-weight", "600",
  )
  let th_style = respo_style(
    border=CssBorder(1, Solid, Hsl(220, 10, 90)),
    padding="10px 14px" |> Custom,
    text_align=Left,
    background_color=Hsl(220, 10, 97),
  ).add("border-bottom-width", "1px")
  let td_style = respo_style(
      padding="8px 14px" |> Custom,
      text_align=Left,
      vertical_align=Top,
    )
    .add("border-left", "1px solid hsl(220, 10%, 90%)")
    .add("border-right", "1px solid hsl(220, 10%, 90%)")
    .add("border-bottom", "1px solid hsl(220, 10%, 90%)")
  create_element("table", style=table_style, [
    create_element("thead", style=thead_style, [
      create_element(
        "tr",
        header_line
        .iter()
        .map(fn(x) {
          create_element(
            "th",
            attrs={},
            event={},
            style=th_style,
            render_inline(x.to_string()),
          )
        })
        .collect(),
      ),
    ]),
    create_element(
      "tbody",
      attrs={},
      event={},
      style=respo_style(),
      body_lines
      .iter()
      .map(fn(line) {
        create_element(
          "tr",
          line
          .iter()
          .map(fn(x) {
            create_element("td", style=td_style, render_inline(x.to_string()))
          })
          .collect(),
        )
      })
      .collect(),
    ),
  ])
}

///|
fn[T] comp_text_block(lines : Array[String]) -> @respo_node.RespoNode[T] {
  return div(
    class_name=style_paragraph,
    lines.iter().map(fn(line) { comp_line(line) }).collect(),
  )
}

///|
fn[T] render_inline(text : String) -> Array[@respo_node.RespoNode[T]] {
  let els = []
  println("render inline: " + text)
  let lines = split_line(text)
  for chunk in lines {
    match chunk {
      @md_util.Code(content) => {
        println("inline code: " + content)
        els.push(code(class_name=style_inline_code, inner_text=content))
      }
      @md_util.Url(content) =>
        els.push(a(href=content, inner_text=content, target=Blank))
      @md_util.Link(content) => els.push(comp_link(content))
      @md_util.Image(content) => els.push(comp_image(content))
      @md_util.Text(content) => els.push(span(inner_text=content, []))
      @md_util.Emphasis(content) => els.push(b(render_inline(content)))
      @md_util.Italic(content) => els.push(i(inner_text=content, []))
    }
  }
  els
}

///|
let style_blockquote : String = static_style([
  (
    "&",
    respo_style(
      border=CssBorder(0, Solid, Hsl(0, 0, 90)),
      margin_left=0 |> Px,
      padding_left=12 |> Px,
      color=Hsl(0, 0, 50),
    ).add("border-width", "0 0 0 6px"),
  ),
])

///|
let style_code_block : String = static_style([
  ("&", respo_style(max_width=60 |> Vw)),
])

///|
let style_default_link : String = static_style([
  ("&", respo_style(opacity=0.9, transition_duration=200 |> Ms)),
  ("&:hover", respo_style(opacity=1, transform=1 |> Scale)),
])

///|
let style_image : String = static_style([
  (
    "&",
    respo_style(
      max_width=480 |> Px,
      max_height=320 |> Px,
      border=CssBorder(0, Solid, Hsl(0, 0, 90)),
      border_radius=8,
    ),
  ),
])

///|
let style_indent : String = static_style([
  ("&", respo_style(white_space="pre", float="left")),
])

///|
let style_inline_code : String = static_style([
  (
    "&",
    respo_style(
      border=CssBorder(1, Solid, Hsl(0, 0, 86)),
      border_radius=4,
      font_size=12,
      padding="2px 4px" |> Custom,
      margin="2px 4px" |> Custom,
    ),
  ),
])

///|
let style_line_list : String = static_style([
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

///|
let style_hr : String = static_style([
  (
    "&",
    respo_style(
      border=CssBorder(0, Solid, Hsl(220, 6, 94)),
      margin="24px 40px" |> Custom,
    )
    .add("border-top-width", "1px")
    .add("height", "0"),
  ),
])

///|
let style_paragraph : String = static_style([("&", respo_style())])
