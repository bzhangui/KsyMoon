///|
fn emit_reader(
  output : StringBuilder,
  root_type : String,
  has_numeric_fields : Bool,
  has_repeated_fields : Bool,
) -> Unit {
  let repeat_error = if has_repeated_fields {
    "  __ROOT__RepeatLimit(field~ : String, offset~ : Int, count~ : Int64)\n"
  } else {
    ""
  }
  let repeat_state = if has_repeated_fields {
    "  mut repeats_left : Int\n"
  } else {
    ""
  }
  let header =
    #|///|
    #|pub suberror __ROOT__ParseError {
    #|  __ROOT__Truncated(field~ : String, offset~ : Int, needed~ : Int64, remaining~ : Int)
    #|  __ROOT__InvalidLength(field~ : String, offset~ : Int, length~ : Int64)
    #|__REPEAT_ERROR__}
    #|
    #|///|
    #|priv struct __ROOT__Reader {
    #|  input : Bytes
    #|  mut offset : Int
    #|__REPEAT_STATE__}
    #|
    #|///|
    #|fn __ROOT__Reader::take(
    #|  self : __ROOT__Reader,
    #|  length : Int64,
    #|  field : String,
    #|) -> BytesView raise __ROOT__ParseError {
    #|  guard length >= 0L else {
    #|    raise __ROOT__InvalidLength(field~, offset=self.offset, length~)
    #|  }
    #|  let remaining = self.input.length() - self.offset
    #|  guard length <= remaining.to_int64() else {
    #|    raise __ROOT__Truncated(field~, offset=self.offset, needed=length, remaining~)
    #|  }
    #|  let start = self.offset
    #|  self.offset = start + length.to_int()
    #|  self.input[start:self.offset]
    #|}
    #|
  let header = header
    .replace_all(old="__REPEAT_ERROR__", new=repeat_error[:])
    .replace_all(old="__REPEAT_STATE__", new=repeat_state[:])
  write_reader_block(output, header, root_type)
  if has_numeric_fields {
    let numbers =
      #|///|
      #|fn __ROOT__Reader::read_bits(
      #|  self : __ROOT__Reader,
      #|  width : Int,
      #|  little_endian : Bool,
      #|  field : String,
      #|) -> UInt raise __ROOT__ParseError {
      #|  let bytes = self.take(width.to_int64(), field)
      #|  let mut value = 0U
      #|  for i in 0..<width {
      #|    let index = if little_endian { width - 1 - i } else { i }
      #|    value = (value << 8) | bytes[index].to_uint()
      #|  }
      #|  value
      #|}
      #|
    write_reader_block(output, numbers, root_type)
  }
  if has_repeated_fields {
    let repeat =
      #|///|
      #|fn __ROOT__Reader::reserve_repeats(
      #|  self : __ROOT__Reader,
      #|  count : Int64,
      #|  field : String,
      #|) -> Int raise __ROOT__ParseError {
      #|  guard count >= 0L else {
      #|    raise __ROOT__InvalidLength(field~, offset=self.offset, length=count)
      #|  }
      #|  guard count <= self.repeats_left.to_int64() else {
      #|    raise __ROOT__RepeatLimit(field~, offset=self.offset, count~)
      #|  }
      #|  let count = count.to_int()
      #|  self.repeats_left -= count
      #|  count
      #|}
      #|
    write_reader_block(output, repeat, root_type)
  }
}

///|
fn write_reader_block(
  output : StringBuilder,
  block : String,
  root_type : String,
) -> Unit {
  output.write_string(block.replace_all(old="__ROOT__", new=root_type[:]))
  output.write_char('\n')
}
