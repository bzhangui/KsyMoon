///|
fn bit_width(name : String) -> Int32? {
  guard name.has_prefix("b") else { return None }
  let stop = if name.has_suffix("le") || name.has_suffix("be") {
    name.length() - 2
  } else {
    name.length()
  }
  if stop <= 1 {
    return None
  }
  let digits = name[1:stop].to_owned()
  guard digits.iter().all(fn(ch) { is_ascii_digit(ch) }) else { return None }
  Some(@string.parse_int(digits[:]) catch { _ => 0 })
}

///|
fn bit_state(bits : Bool) -> String {
  if bits {
    ", bits_left: 0, bit_little: false"
  } else {
    ""
  }
}

///|
fn save_position(indent : String, bits : Bool) -> String {
  let extra = if bits {
    "\{indent}let saved_bits = reader.bits_left\n\{indent}let saved_order = reader.bit_little\n"
  } else {
    ""
  }
  let restore = if bits {
    "; reader.bits_left = saved_bits; reader.bit_little = saved_order"
  } else {
    ""
  }
  "\{indent}let saved = reader.offset\n\{extra}\{indent}defer { reader.offset = saved\{restore} }\n"
}

///|
fn emit_bit_reader(output : StringBuilder, root : String) -> Unit {
  let block =
    #|///|
    #|fn __ROOT__Reader::read_bit_integer(self : __ROOT__Reader, width : Int, little : Bool, field : String) -> UInt raise __ROOT__ParseError {
    #|  guard self.bits_left == 0 || self.bit_little == little else {
    #|    raise __ROOT__BitOrder(field~, offset=self.offset - 1)
    #|  }
    #|  let needed = (width - self.bits_left + 7) / 8
    #|  let remaining = self.input.length() - self.offset
    #|  guard needed <= remaining else {
    #|    raise __ROOT__Truncated(field~, offset=self.offset, needed=needed.to_int64(), remaining~)
    #|  }
    #|  self.bit_little = little
    #|  let mut result = 0U
    #|  for i in 0..<width {
    #|    if self.bits_left == 0 {
    #|      self.offset += 1
    #|      self.bits_left = 8
    #|    }
    #|    self.bits_left -= 1
    #|    let shift = if little { 7 - self.bits_left } else { self.bits_left }
    #|    let bit = (self.input[self.offset - 1].to_int().reinterpret_as_uint() >> shift) & 1U
    #|    result = if little { result | (bit << i) } else { (result << 1) | bit }
    #|  }
    #|  result
    #|}
    #|
  write_reader_block(output, block, root)
}

///|
fn schema_has_bits(schema : Schema) -> Bool {
  [schema.root, ..schema.records]
  .iter()
  .any(fn(record) {
    record.fields
    .iter()
    .any(fn(field) {
      walk_kinds(field.kind).iter().any(fn(k) { k is BitInteger(_, _) })
    }) ||
    record.instances
    .iter()
    .any(fn(instance) {
      instance.kind is Parsed(field, _) &&
      walk_kinds(field.kind).iter().any(fn(k) { k is BitInteger(_, _) })
    })
  })
}
