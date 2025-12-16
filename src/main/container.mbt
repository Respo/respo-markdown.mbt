///|
using @respo {type RespoStatesTree}

///|
using @markdown {comp_md_block, comp_md}

///|
using @respo_node {input, space, textarea, a, img}

///|
let ui_row_middle = @respo.ui_row_middle

///|
let ui_row = @respo.ui_row

///|
let ui_expand = @respo.ui_expand

///|
let ui_textarea = @respo.ui_textarea

///|
let ui_font_code = @respo.ui_font_code

///|
let ui_input = @respo.ui_input

///|
struct ContainerState {
  draft : String
  text : String
} derive(ToJson, @json.FromJson, Default)

///|
fn[Op : @respo_node.RespoAction] comp_container(
  states : RespoStatesTree,
) -> @respo_node.RespoNode[Op] {
  let ((state : ContainerState), cursor) = states.local_pair()
  div(
    class_name=ui_global,
    style=respo_style(
      width=96 |> Percent,
      margin="0 auto" |> Custom,
      padding=8 |> Px,
    ),
    [
      div(class_name=ui_row_middle, [
        img(
          src="https://cos-sh.tiye.me/cos-up/bb4c2755050318e864b56f59145d726e-SubstractRespo.png",
          width=40,
          alt="Respo",
        ),
        space(width=8),
        a(
          href="https://github.com/Respo/respo-markdown.calcit",
          inner_text="respo-markdown",
        ),
      ]),
      div([
        comp_md_block(
          "Respo Markdown component renders Markdown text to virtual DOM in Respo. Require the code with\n\n```cirru\n\{code_demo}\n```\n",
        ),
      ]),
      space(height=40),
      div([
        div([comp_md("This is an example for using `comp-md`:")]),
        div([
          input(
            class_name=ui_input,
            style=respo_style(width=100 |> Percent),
            value=state.text,
            placeholder="text inline",
            on_input=fn(e, dispatch) {
              if e is Input(value~, ..) {
                dispatch.set_state(cursor, { ..state, text: value })
              }
            },
          ),
          comp_md(state.text),
        ]),
      ]),
      space(height=40),
      div([
        div(class_name="example", [
          comp_md_block("Example For using `comp-md-block`:"),
        ]),
        div(class_name=ui_row, [
          div(class_name=ui_expand, [
            textarea(
              placeholder="multi-line content",
              value=state.draft,
              class_list=[ui_textarea, ui_font_code],
              style=respo_style(
                height=100 |> Percent,
                width=100 |> Percent,
                font_size=13,
              ),
              on_input=fn(e, dispatch) {
                if e is Input(value~, ..) {
                  dispatch.set_state(cursor, { ..state, draft: value })
                }
              },
            ),
          ]),
          div(class_name=ui_expand, style=respo_style(padding=8 |> Px), [
            comp_md_block(state.draft),
          ]),
        ]),
      ]),
      space(height=200),
    ],
  )
}
