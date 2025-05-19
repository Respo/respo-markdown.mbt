///|
let code_demo : String =
  #| @markdown.comp_md("this is a `demo`")
  #|
  #| @markdown.comp_md("this is a `demo`", class_name=class_name)
  #|
  #| @markdown.comp_md_block("### this is a `demo`\n\nthis is second line\n\n```\nprintln(demo)```")
  #|
  #| @markdown.comp_md_block(content, class_name=class_name, style=style, highlighter=highlighter)
