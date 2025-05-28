///|
fnalias @respo_node.(
  static_style,
  respo_style,
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
  text_node
)

///|
fnalias @respo.code_fonts

///|
fn[T] comp_code_block(
  lines : Array[String],
  highlighter~ : (String, String) -> String = fn(x, _) -> String { x }
) -> @respo_node.RespoNode[T] {
  let lang = lines[0]
  let content = lines[1:].to_array().join("\n")
  return comp_snippet(
    content,
    class_name=style_code_block,
    highliter=highlighter,
    lang~,
  )
}

///|
fn[T] comp_snippet(
  content : String,
  class_name? : String,
  highliter? : (String, String) -> String,
  lang? : String
) -> @respo_node.RespoNode[T] {
  let highliter = highliter.or(fn(content, _) -> String { content })
  let highlighted = highliter(content, lang.or("text"))
  return div(class_list=[style_snippet, class_name.or("")], [
    pre(class_name=style_code_block, children=[code(inner_text=highlighted)]),
  ])
}

///|
let style_snippet : String = static_style([
  (
    "&",
    respo_style(
      font_family=code_fonts,
      border=(1, Solid, Hsl(0, 0, 90)),
      padding=8 |> Px,
      border_radius=4,
      line_height=20 |> Px,
      font_size=12,
    ),
  ),
])

///|
fn[T] comp_image(chunk : String) -> @respo_node.RespoNode[T] {
  let useful = chunk.substring(start=2, end=chunk.length() - 1)
  let xs = useful.split("](").map(@string.View::to_string).collect()
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
    h1(render_inline(line.substring(start=2)))
  } else if line.has_prefix("## ") {
    h2(render_inline(line.substring(start=3)))
  } else if line.has_prefix("### ") {
    h3(render_inline(line.substring(start=4)))
  } else if line.has_prefix("#### ") {
    h4(render_inline(line.substring(start=5)))
  } else if line.has_prefix("> ") {
    blockquote(
      class_name=style_blockquote,
      render_inline(line.substring(start=2)),
    )
  } else if line.has_prefix(" ") {
    let content = line.trim_start(" ").to_string()
    let space_size = line.length() - content.length()
    let spaces = line.substring(start=0, end=space_size).to_string()
    div(class_name=style_indent, [
      span(inner_text=spaces, class_name=style_indent, []),
      comp_line(content),
    ])
  } else if line.has_prefix("* ") || line.has_prefix("- ") {
    li(class_name=style_line_list, render_inline(line.substring(start=2)))
  } else if line.has_prefix("#!html ") {
    div(class_name="html-container", innerHTML=line.substring(start=7), [])
  } else {
    div(render_inline(line))
  }
}

///|
fn[T] comp_link(chunk : String) -> @respo_node.RespoNode[T] {
  let useful = chunk.substring(start=1, end=chunk.length() - 1)
  let xs = useful.split("](").map(@string.View::to_string).collect()
  if xs is [content, url] {
    span(class_name=style_default_link, [
      if content.has_prefix("`") && content.has_suffix("`") {
        a(class_name=style_default_link, href=url, target=Blank, children=[
          code(inner_text=content.substring(start=1, end=content.length() - 1)),
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
  class_name? : String
) -> @respo_node.RespoNode[T] {
  div(class_name=class_name.or(""), render_inline(text))
}

///|
pub fn[T] comp_md_block(
  text : String,
  class_name? : String,
  style? : @respo_node.RespoStyle,
  highlighter~ : (String, String) -> String = fn(x, _) -> String { x }
) -> @respo_node.RespoNode[T] {
  let blocks = split_block(text)
  return div(
    class_list=[class_name.or(""), "md-block"],
    style=style.or(respo_style()),
    blocks
    .iter()
    .map(fn(block) {
      match block {
        Text(lines) => comp_text_block(lines.to_array())
        Code(lines) => comp_code_block(lines.to_array(), highlighter~)
        Table(lines) => comp_table_block(lines.to_array())
        _ => div([block.to_string() |> text_node])
      }
    })
    .collect(),
  )
}

///|
fn[T] comp_table_block(
  lines : Array[Array[String]]
) -> @respo_node.RespoNode[T] {
  let header_line = lines[0]
  let mark_line = lines[1]
  let body_lines = if mark_line[0].has_prefix(":") ||
    mark_line[0].has_suffix("-") {
    lines[2:]
  } else {
    lines[1:]
  }
  let attrs = {}
  attrs.set("class-name", style_md_table)
  create_element("table", attrs~, event={}, style=respo_style(), [
    create_element("thead", attrs={}, event={}, style=respo_style(), [
      create_element(
        "tr",
        header_line
        .iter()
        .map(fn(x) {
          create_element(
            "th",
            attrs={},
            event={},
            style=respo_style(),
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
          .map(fn(x) { create_element("td", render_inline(x.to_string())) })
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
  let lines = split_line(text)
  for chunk in lines {
    match chunk {
      Code(content) =>
        els.push(code(class_name=style_inline_code, inner_text=content))
      Url(content) =>
        els.push(a(href=content, inner_text=content, target=Blank))
      Link(content) => els.push(comp_link(content))
      Image(content) => els.push(comp_image(content))
      Text(content) => els.push(span(inner_text=content, []))
      Emphasis(content) => els.push(b(render_inline(content)))
      Italic(content) => els.push(i(inner_text=content, []))
    }
  }
  els
}

///|
let style_blockquote : String = static_style([
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
      border=(0, Solid, Hsl(0, 0, 90)),
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
      border=(1, Solid, Hsl(0, 0, 86)),
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
let style_md_table : String = static_style([
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

///|
let style_paragraph : String = static_style([("&", respo_style())])
