///|
priv enum ByteProcessor {
  Xor(Expr, Bool)
  XorLiteral(Bytes)
  Rotate(Expr, Bool)
  Zlib
}

///|
fn parse_processor(
  raw : @yaml.Yaml,
  earlier : Map[String, Field],
  path : String,
) -> ByteProcessor raise SchemaError {
  let text = as_string(raw, path).trim().to_owned()
  if text == "zlib" {
    return Zlib
  }
  guard text.split_once("(") is Some((name, argument)) && text.has_suffix(")") else {
    invalid(path, "expected xor(key), rol(count), ror(count) or zlib")
  }
  let argument = argument[:argument.length() - 1].to_owned().trim().to_owned()
  match name.trim().to_owned() {
    "xor" if argument.has_prefix("[") => {
      guard load_ksy_yaml(argument) is [@yaml.Array(items)] else {
        invalid(path, "expected a byte-array XOR key")
      }
      let key = items.map(fn(item) raise SchemaError {
        match item {
          @yaml.Integer(byte) if byte >= 0L && byte <= 255L => byte.to_byte()
          _ => invalid(path, "expected an XOR byte (0..255)")
        }
      })
      XorLiteral(Bytes::from_array(key[:]))
    }
    "xor" => {
      let value = parse_expression(@yaml.String(argument), path)
      let mask = value is Reference(name) &&
        earlier.get(name) is Some({ kind: ByteField(_) | Contents(_), .. })
      Xor(value, mask)
    }
    "rol" | "ror" as direction =>
      Rotate(parse_expression(@yaml.String(argument), path), direction == "ror")
    _ => invalid(path, "unsupported processor '" + name.to_owned() + "'")
  }
}

///|
fn processor_name(processor : ByteProcessor) -> String {
  match processor {
    Xor(_, false) => "process_xor_byte"
    Xor(_, true) | XorLiteral(_) => "process_xor_mask"
    Rotate(_, _) => "process_rotate"
    Zlib => "process_zlib"
  }
}

///|
fn processor_code(
  processor : ByteProcessor,
  raw : String,
  path : String,
  evaluate : ((Expr) -> String)?,
) -> String {
  let argument = fn(value) {
    if context_has_reference(value) || expression_arithmetic(value) {
      evaluate.unwrap()(value)
    } else {
      expression_code(value, fn(name) { name }, path)
    }
  }
  let args = match processor {
    Xor(key, _) => ", " + argument(key)
    XorLiteral(key) => {
      let bytes = key.to_array().map(fn(byte) { byte.to_int().to_string() })
      ", Bytes::from_array([" + bytes.join(", ") + "])[:]"
    }
    Rotate(count, right) => ", " + argument(count) + ", " + right.to_string()
    Zlib => ""
  }
  "{ let process_offset = reader.offset; let process_input = \{raw}; reader.\{processor_name(processor)}(process_input\{args}, \{path}, process_offset) }"
}

///|
fn kind_processor(kind : FieldKind) -> ByteProcessor? {
  match kind {
    ByteField(options) | Text(options, _) | Bounded(_, options) =>
      options.processor
    _ => None
  }
}

///|
fn emit_processors(
  output : StringBuilder,
  root : String,
  flags : Array[String],
) -> Unit {
  for name in flags {
    let source = match name {
      "process_xor_byte" =>
        (
          #|///|
          #|fn __ROOT__Reader::process_xor_byte(_ : __ROOT__Reader, data : BytesView, key : Int64, field : String, offset : Int) -> BytesView raise __ROOT__ParseError {
          #|  guard key >= 0L && key <= 255L else { raise __ROOT__ContextError(field~, offset~, message="XOR key is outside 0..255") }
          #|  let key = key.to_byte()
          #|  Bytes::makei(data.length(), fn(i) { data[i] ^ key })[:]
          #|}
          #|
        )
      "process_xor_mask" =>
        (
          #|///|
          #|fn __ROOT__Reader::process_xor_mask(_ : __ROOT__Reader, data : BytesView, key : BytesView, _field : String, _offset : Int) -> BytesView {
          #|  if key.is_empty() { return b""[:] }
          #|  Bytes::makei(data.length(), fn(i) { data[i] ^ key[i % key.length()] })[:]
          #|}
          #|
        )
      "process_rotate" =>
        (
          #|///|
          #|fn __ROOT__Reader::process_rotate(_ : __ROOT__Reader, data : BytesView, count : Int64, right : Bool, field : String, offset : Int) -> BytesView raise __ROOT__ParseError {
          #|  guard count >= 0L && count <= 8L else { raise __ROOT__ContextError(field~, offset~, message="rotation count is outside 0..8") }
          #|  let left = if right { 8 - count.to_int() } else { count.to_int() }
          #|  Bytes::makei(data.length(), fn(i) {
          #|    let byte = data[i].to_int()
          #|    ((byte << left) | (byte >> (8 - left))).to_byte()
          #|  })[:]
          #|}
          #|
        )
      "process_zlib" =>
        (
          #|///|
          #|fn __ROOT__Reader::process_zlib(_ : __ROOT__Reader, data : BytesView, field : String, offset : Int) -> BytesView raise __ROOT__ParseError {
          #|  // Bound decompression before allocating the decoded stream.
          #|  let decoded = @ksy_zlib.decompress(data, max_output=16_777_216) catch {
          #|    @ksy_zlib.ZlibError(_, message) => raise __ROOT__ContextError(field~, offset~, message~)
          #|  }
          #|  decoded[:]
          #|}
          #|
        )
      _ => continue
    }
    write_reader_block(output, source, root)
  }
}
