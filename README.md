## Markdown subset into Respo DOM

> also checks https://github.com/Respo/respo-markdown.calcit

```bash
moon add tiye/respo-markdown
```

```json
{
  "path": "tiye/respo-markdown",
  "alias": "markdown"
}
```

````moonbit
@markdown.comp_md("this is a `demo`")
@markdown.comp_md("this is a `demo`", class_name=class_name)
@markdown.comp_md_block("### this is a `demo`\n\nthis is second line\n\n```\nprintln(demo)```")
@markdown.comp_md_block(content, class_name=class_name, style=style, highlighter=highlighter)
````

## Supported Features

This is a **subset** of Markdown for simple rendering scenarios:

**Block elements:**

- Headings (`#`, `##`, `###`, `####`)
- Paragraphs (separated by blank lines)
- Blockquotes (`>`)
- Horizontal rules (`---`, `***`, `___`)
- Fenced code blocks (` ``` `) with language hint, supports indented code fences
- Tables (with `| col | col |` syntax, including separator line `| --- |`)

**Inline elements:**

- Inline code (`` `code` ``)
- Links (`[text](url)`)
- Images (`![alt](url)`)
- Bold/Emphasis (`**bold**`)
- Italic (`*italic*`)
- URLs (auto-detected `http://` or `https://`)

**Not supported:**

- Headings level 5+ (`#####`, `######`)
- Nested blockquotes
- Ordered/unordered lists (`-`, `*`, `1.`)
- HTML tags
- Nested formatting (e.g., bold inside italic)
- Reference-style links
- Footnotes
- Task lists

## License

Apache License 2.0
