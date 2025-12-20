///|
/// Re-export from util subpackage for internal use
pub type Block = @md_util.Block

///|
pub type LineChunk = @md_util.LineChunk

///|
fn split_block(text : String) -> Array[@md_util.Block] {
  @md_util.split_block(text)
}

///|
fn split_line(line : String) -> Array[@md_util.LineChunk] {
  @md_util.split_line(line)
}

///|
fn is_separator_line(cells : Array[String]) -> Bool {
  @md_util.is_separator_line(cells)
}
