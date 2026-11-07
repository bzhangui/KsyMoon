///|
fn emit_reader(
  output : StringBuilder,
  root_type : String,
  has_numeric_fields~ : Bool,
  has_uint64~ : Bool,
  has_repeated_fields~ : Bool,
  has_contents~ : Bool,
  has_validation~ : Bool,
) -> Unit {
  let validation_error = if has_validation {
    "  __ROOT__InvalidValue(field~ : String, offset~ : Int, value~ : Int64, minimum~ : Int64, maximum~ : Int64)\n"
  } else {
    ""
  }
  let contents_error = if has_contents {
    "  __ROOT__ContentsMismatch(field~ : String, offset~ : Int, expected~ : Byte, actual~ : Byte)\n"
  } else {
    ""
  }
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
    #|__REPEAT_ERROR____CONTENTS_ERROR____VALIDATION_ERROR__}
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
    .replace_all(old="__CONTENTS_ERROR__", new=contents_error[:])
    .replace_all(old="__VALIDATION_ERROR__", new=validation_error[:])
    .replace_all(old="__REPEAT_STATE__", new=repeat_state[:])
  write_reader_block(output, header, root_type)
  if has_numeric_fields {
    write_reader_block(
      output,
      numeric_reader("read_bits", "UInt", "0U", "to_uint"),
      root_type,
    )
  }
  if has_uint64 {
    write_reader_block(
      output,
      numeric_reader("read_uint64_bits", "UInt64", "0UL", "to_uint64"),
      root_type,
    )
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
  if has_contents {
    let contents =
      #|///|
      #|fn __ROOT__Reader::read_contents(
      #|  self : __ROOT__Reader,
      #|  expected : Bytes,
      #|  field : String,
      #|) -> BytesView raise __ROOT__ParseError {
      #|  let start = self.offset
      #|  let actual = self.take(expected.length().to_int64(), field)
      #|  for i in 0..<expected.length() {
      #|    guard actual[i] == expected[i] else {
      #|      raise __ROOT__ContentsMismatch(field~, offset=start + i, expected=expected[i], actual=actual[i])
      #|    }
      #|  }
      #|  actual
      #|}
      #|
    write_reader_block(output, contents, root_type)
  }
  if has_validation {
    let validation =
      #|///|
      #|fn __ROOT__Reader::check_scalar(
      #|  self : __ROOT__Reader,
      #|  value : Int64,
      #|  width : Int,
      #|  minimum : Int64,
      #|  maximum : Int64,
      #|  field : String,
      #|) -> Unit raise __ROOT__ParseError {
      #|  guard value >= minimum && value <= maximum else {
      #|    raise __ROOT__InvalidValue(field~, offset=self.offset - width, value~, minimum~, maximum~)
      #|  }
      #|}
      #|
    write_reader_block(output, validation, root_type)
  }
}

///|
fn numeric_reader(
  name : String,
  type_name : String,
  zero : String,
  convert : String,
) -> String {
  let block =
    #|///|
    #|fn __ROOT__Reader::__NAME__(
    #|  self : __ROOT__Reader,
    #|  width : Int,
    #|  little_endian : Bool,
    #|  field : String,
    #|) -> __TYPE__ raise __ROOT__ParseError {
    #|  let bytes = self.take(width.to_int64(), field)
    #|  let mut value = __ZERO__
    #|  for i in 0..<width {
    #|    let index = if little_endian { width - 1 - i } else { i }
    #|    value = (value << 8) | bytes[index].__CONVERT__()
    #|  }
    #|  value
    #|}
    #|
  block
  .replace_all(old="__NAME__", new=name[:])
  .replace_all(old="__TYPE__", new=type_name[:])
  .replace_all(old="__ZERO__", new=zero[:])
  .replace_all(old="__CONVERT__", new=convert[:])
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
