///|
fn emit_reader(
  output : StringBuilder,
  root_type : String,
  has_bounded~ : Bool,
  has_byte_options~ : Bool,
  has_strings~ : Bool,
  single_byte_encoding~ : Bool = false,
  has_open_repeats~ : Bool,
  has_numeric_fields~ : Bool,
  has_uint64~ : Bool,
  has_repeated_fields~ : Bool,
  has_contents~ : Bool,
  has_validation~ : Bool,
  has_predicates~ : Bool = false,
  has_instances~ : Bool,
  has_positions~ : Bool,
  has_arithmetic~ : Bool,
  has_read_fields~ : Bool,
  has_input~ : Bool,
  has_context~ : Bool = false,
  has_bits~ : Bool = false,
  has_narrow_bits~ : Bool = false,
  has_wide_bits~ : Bool = false,
  has_process~ : Bool = false,
) -> Unit {
  let validation_error = if has_validation {
    "  __ROOT__InvalidValue(field~ : String, offset~ : Int, value~ : Int64, minimum~ : Int64, maximum~ : Int64)\n"
  } else {
    ""
  }
  let validation_error = validation_error +
    (if has_predicates {
      "  __ROOT__ValidationMismatch(field~ : String, offset~ : Int)\n"
    } else {
      ""
    })
  let bit_error = if has_bits {
    "  __ROOT__BitOrder(field~ : String, offset~ : Int)\n"
  } else {
    ""
  }
  let contents_error = if has_contents {
    "  __ROOT__ContentsMismatch(field~ : String, offset~ : Int, expected~ : Byte, actual~ : Byte)\n"
  } else {
    ""
  }
  let repeat_error = if has_repeated_fields {
    "  __ROOT__RepeatLimit(field~ : String, offset~ : Int, count~ : Int64)\n" +
    (if has_open_repeats {
      "  __ROOT__NoProgress(field~ : String, offset~ : Int)\n"
    } else {
      ""
    })
  } else {
    ""
  }
  let instance_error = if has_instances {
    "  __ROOT__InstanceCycle(field~ : String, offset~ : Int)\n"
  } else {
    ""
  }
  let position_error = if has_positions {
    "  __ROOT__InvalidPosition(field~ : String, offset~ : Int, position~ : Int64)\n"
  } else {
    ""
  }
  let arithmetic_error = if has_arithmetic {
    "  __ROOT__ExpressionError(field~ : String, offset~ : Int, operation~ : String)\n"
  } else {
    ""
  }
  let repeat_state = if has_repeated_fields {
    "  budget : Array[Int]\n"
  } else {
    ""
  }
  let header =
    #|///|
    #|pub suberror __ROOT__ParseError {
    #|  __ROOT__Truncated(field~ : String, offset~ : Int, needed~ : Int64, remaining~ : Int)
    #|  __ROOT__InvalidLength(field~ : String, offset~ : Int, length~ : Int64)
    #|__REPEAT_ERROR____CONTENTS_ERROR____VALIDATION_ERROR____INSTANCE_ERROR____POSITION_ERROR____ARITHMETIC_ERROR__}
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
  let header = header.replace_all(
    old="__ARITHMETIC_ERROR__",
    new=((if has_context || has_process {
        "  __ROOT__ContextError(field~ : String, offset~ : Int, message~ : String)\n"
      } else {
        ""
      }) +
      arithmetic_error +
      bit_error +
      (if has_byte_options {
        "  __ROOT__MissingTerminator(field~ : String, offset~ : Int)\n"
      } else {
        ""
      }) +
      (if has_strings {
        "  __ROOT__InvalidEncoding(field~ : String, offset~ : Int, encoding~ : String)\n"
      } else {
        ""
      }))[:],
  )
  let header = if has_read_fields {
    header
  } else {
    header.split_once("///|\nfn __ROOT__Reader::take(").unwrap().0.to_owned()
  }
  let header = if has_read_fields {
    header
  } else {
    header
    .replace_all(
      old="  __ROOT__Truncated(field~ : String, offset~ : Int, needed~ : Int64, remaining~ : Int)\n",
      new=if has_bits {
        "  __ROOT__Truncated(field~ : String, offset~ : Int, needed~ : Int64, remaining~ : Int)\n"
      } else {
        ""
      },
    )
    .replace_all(
      old="  __ROOT__InvalidLength(field~ : String, offset~ : Int, length~ : Int64)\n",
      new=if has_repeated_fields {
        "  __ROOT__InvalidLength(field~ : String, offset~ : Int, length~ : Int64)\n"
      } else {
        ""
      },
    )
    .replace_all(
      old="  mut offset : Int",
      new=if has_positions || has_bits {
        "  mut offset : Int"
      } else {
        "  offset : Int"
      },
    )
  }
  let header = if has_input {
    header
  } else {
    header.replace_all(old="  input : Bytes\n", new="")
  }
  let header = header
    .replace_all(old="__REPEAT_ERROR__", new=repeat_error[:])
    .replace_all(old="__CONTENTS_ERROR__", new=contents_error[:])
    .replace_all(old="__VALIDATION_ERROR__", new=validation_error[:])
    .replace_all(old="__INSTANCE_ERROR__", new=instance_error[:])
    .replace_all(old="__POSITION_ERROR__", new=position_error[:])
    .replace_all(old="__ARITHMETIC_ERROR__", new=arithmetic_error[:])
    .replace_all(
      old="__REPEAT_STATE__",
      new=(repeat_state +
        (if has_bits {
          "  mut bits_left : Int\n  mut bit_little : Bool\n"
        } else {
          ""
        }))[:],
    )
  let header = if has_bits {
    header.replace_all(
      old="  guard length >= 0L else",
      new="  self.bits_left = 0\n  guard length >= 0L else",
    )
  } else {
    header
  }
  write_reader_block(output, header, root_type)
  if has_bits {
    if has_narrow_bits {
      emit_bit_reader(output, root_type, wide=false)
    }
    if has_wide_bits {
      emit_bit_reader(output, root_type, wide=true)
    }
  }
  emit_stream_reader(
    output, root_type, has_bounded, has_byte_options, has_strings, has_repeated_fields,
    has_bits, single_byte_encoding,
  )
  if has_positions {
    let seek =
      #|///|
      #|fn __ROOT__Reader::seek(self : __ROOT__Reader, position : Int64, field : String) -> Unit raise __ROOT__ParseError {
      #|  guard position >= 0L && position <= self.input.length().to_int64() else {
      #|    raise __ROOT__InvalidPosition(field~, offset=self.offset, position~)
      #|  }
      #|  self.offset = position.to_int()
      #|}
      #|
    let seek = if has_bits {
      seek.replace_all(
        old="  self.offset = position.to_int()",
        new="  self.bits_left = 0\n  self.offset = position.to_int()",
      )
    } else {
      seek
    }
    write_reader_block(output, seek, root_type)
  }
  if has_arithmetic {
    emit_arithmetic(output, root_type)
  }
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
      #|  guard count <= self.budget[0].to_int64() else {
      #|    raise __ROOT__RepeatLimit(field~, offset=self.offset, count~)
      #|  }
      #|  let count = count.to_int()
      #|  self.budget[0] -= count
      #|  count
      #|}
      #|
    let repeat = if has_context {
      repeat.replace_all(
        old="  self.budget[0] -= count",
        new="  self.budget[0] -= count\n  self.budget[self.budget[1]] += count",
      )
    } else {
      repeat
    }
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
