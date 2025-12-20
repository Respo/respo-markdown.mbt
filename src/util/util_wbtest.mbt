///|
test "split_line: plain text" {
  let result = split_line("Hello World")
  inspect(result.length(), content="1")
  guard result[0] is Text(content) else { fail("expected Text") }
  inspect(content, content="Hello World")
}

///|
test "split_line: inline code" {
  let result = split_line("use `println` function")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="use ")
  guard result[1] is Code(c) else { fail("expected Code") }
  inspect(c, content="println")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content=" function")
}

///|
test "split_line: url http" {
  let result = split_line("visit http://example.com for more")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="visit ")
  guard result[1] is Url(u) else { fail("expected Url") }
  inspect(u, content="http://example.com")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content="for more")
}

///|
test "split_line: url https" {
  let result = split_line("check https://example.com/path here")
  inspect(result.length(), content="3")
  guard result[1] is Url(u) else { fail("expected Url") }
  inspect(u, content="https://example.com/path")
}

///|
test "split_line: markdown link" {
  let result = split_line("click [here](http://example.com) now")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="click ")
  guard result[1] is Link(link) else { fail("expected Link") }
  inspect(link, content="[here](http://example.com)")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content=" now")
}

///|
test "split_line: markdown image" {
  let result = split_line("see ![alt](http://img.png) below")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="see ")
  guard result[1] is Image(img) else { fail("expected Image") }
  inspect(img, content="![alt](http://img.png)")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content=" below")
}

///|
test "split_line: emphasis bold" {
  let result = split_line("this is **bold** text")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="this is ")
  guard result[1] is Emphasis(emp) else { fail("expected Emphasis") }
  inspect(emp, content="bold")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content=" text")
}

///|
test "split_line: italic" {
  let result = split_line("this is *italic* text")
  inspect(result.length(), content="3")
  guard result[0] is Text(t0) else { fail("expected Text") }
  inspect(t0, content="this is ")
  guard result[1] is Italic(it) else { fail("expected Italic") }
  inspect(it, content="italic")
  guard result[2] is Text(t1) else { fail("expected Text") }
  inspect(t1, content=" text")
}

///|
test "split_line: multiple inline codes" {
  let result = split_line("`a` and `b`")
  inspect(result.length(), content="3")
  guard result[0] is Code(c0) else { fail("expected Code") }
  inspect(c0, content="a")
  guard result[1] is Text(t) else { fail("expected Text") }
  inspect(t, content=" and ")
  guard result[2] is Code(c1) else { fail("expected Code") }
  inspect(c1, content="b")
}

///|
test "split_line: empty string" {
  let result = split_line("")
  inspect(result.length(), content="0")
}

///|
test "split_line: only code" {
  let result = split_line("`code`")
  inspect(result.length(), content="1")
  guard result[0] is Code(c) else { fail("expected Code") }
  inspect(c, content="code")
}

///|
test "is_table_line: valid table line" {
  inspect(is_table_line("| a | b |"), content="true")
  inspect(is_table_line("|col1|col2|col3|"), content="true")
  inspect(is_table_line("| --- | --- |"), content="true")
}

///|
test "is_table_line: invalid table line" {
  inspect(is_table_line("| a | b"), content="false")
  inspect(is_table_line("a | b |"), content="false")
  inspect(is_table_line("normal text"), content="false")
  inspect(is_table_line(""), content="false")
}

///|
test "split_table_content: basic" {
  let result = split_table_content("| a | b | c |")
  inspect(result.length(), content="3")
  inspect(result[0], content="a")
  inspect(result[1], content="b")
  inspect(result[2], content="c")
}

///|
test "split_table_content: with spaces" {
  let result = split_table_content("|  hello  |  world  |")
  inspect(result.length(), content="2")
  inspect(result[0], content="hello")
  inspect(result[1], content="world")
}

///|
test "split_block: simple text" {
  let result = split_block("Hello\nWorld")
  inspect(result.length(), content="1")
  guard result[0] is Text(lines) else { fail("expected Text block") }
  inspect(lines.length(), content="2")
}

///|
test "split_block: code block" {
  let result = split_block("```js\nconsole.log('hi')\n```")
  inspect(result.length(), content="1")
  guard result[0] is Code(lines) else { fail("expected Code block") }
  inspect(lines.length(), content="2")
  inspect(lines[0], content="js")
  inspect(lines[1], content="console.log('hi')")
}

///|
test "split_block: text and code" {
  let result = split_block("Some text\n\n```python\nprint('hi')\n```")
  inspect(result.length(), content="2")
  guard result[0] is Text(_) else { fail("expected Text block") }
  guard result[1] is Code(_) else { fail("expected Code block") }
}

///|
test "split_block: table" {
  let result = split_block("| a | b |\n| 1 | 2 |")
  inspect(result.length(), content="2")
}

///|
test "split_block: empty lines" {
  let result = split_block("\n\nHello\n\n")
  inspect(result.length(), content="1")
  guard result[0] is Text(lines) else { fail("expected Text block") }
  inspect(lines.length(), content="1")
}

///|
test "split_block: multiple paragraphs" {
  let result = split_block("Para 1\n\nPara 2")
  inspect(result.length(), content="2")
}

///|
test "LineChunk::is_empty" {
  inspect(LineChunk::Text("").is_empty(), content="true")
  inspect(LineChunk::Text("a").is_empty(), content="false")
  inspect(LineChunk::Code("").is_empty(), content="true")
  inspect(LineChunk::Code("x").is_empty(), content="false")
  inspect(LineChunk::Url("").is_empty(), content="true")
  inspect(LineChunk::Link("").is_empty(), content="true")
  inspect(LineChunk::Image("").is_empty(), content="true")
  inspect(LineChunk::Emphasis("").is_empty(), content="true")
  inspect(LineChunk::Italic("").is_empty(), content="true")
}

///|
test "split_line: link with code inside" {
  let result = split_line("see [`func`](http://example.com)")
  inspect(result.length(), content="2")
  guard result[0] is Text(t) else { fail("expected Text") }
  inspect(t, content="see ")
  guard result[1] is Link(link) else { fail("expected Link") }
  inspect(link, content="[`func`](http://example.com)")
}

///|
test "split_line: asterisk not italic" {
  let result = split_line("a * b = c")
  inspect(result.length(), content="1")
  guard result[0] is Text(t) else { fail("expected Text") }
  inspect(t, content="a * b = c")
}

///|
test "split_line: trailing asterisk" {
  let result = split_line("test*")
  inspect(result.length(), content="1")
  guard result[0] is Text(t) else { fail("expected Text") }
  inspect(t, content="test*")
}

///|
test "split_block: code block without language" {
  let result = split_block("```\ncode here\n```")
  inspect(result.length(), content="1")
  guard result[0] is Code(lines) else { fail("expected Code block") }
  inspect(lines[0], content="")
  inspect(lines[1], content="code here")
}

///|
test "split_line: exclamation not image" {
  let result = split_line("Hello! World")
  inspect(result.length(), content="1")
  guard result[0] is Text(t) else { fail("expected Text") }
  inspect(t, content="Hello! World")
}

///|
test "split_line: bracket not link" {
  let result = split_line("array[0] = 1")
  inspect(result.length(), content="1")
  guard result[0] is Text(t) else { fail("expected Text") }
  inspect(t, content="array[0] = 1")
}
