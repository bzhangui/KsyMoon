///|
fn emit_stream_reader(
  output : StringBuilder,
  root_type : String,
  bounded : Bool,
  byte_options : Bool,
  strings : Bool,
  repeated : Bool,
  bits : Bool,
  single_byte_encoding : Bool,
  extended_encodings : Array[String],
) -> Unit {
  if bounded {
    let budget = if repeated { ", budget: self.budget" } else { "" }
    let self_arg = if repeated { "self" } else { "_self" }
    output.write_string(
      "///|\nfn \{root_type}Reader::substream(\{self_arg} : \{root_type}Reader, bytes : BytesView) -> \{root_type}Reader {\n  { input: bytes.to_owned(), offset: 0\{budget}\{bit_state(bits)} }\n}\n\n",
    )
  }
  if byte_options {
    let block =
      #|///|
      #|fn __ROOT__Reader::read_bytes(self : __ROOT__Reader, length : Int64, terminated : Bool, terminator : Int, padding : Int, keep_terminator : Bool, consume : Bool, eos_error : Bool, unit : Int, big_endian : Bool, field : String) -> BytesView raise __ROOT__ParseError {
      #|  let bytes = if terminated {
      #|    let start = self.offset
      #|    let mut end = start
      #|    while end + unit <= self.input.length() {
      #|      let matches = if unit == 1 { self.input[end].to_int() == terminator } else if big_endian { self.input[end] == 0 && self.input[end + 1].to_int() == terminator } else { self.input[end].to_int() == terminator && self.input[end + 1] == 0 }
      #|      if matches { break }
      #|      end += unit
      #|    }
      #|    if end + unit > self.input.length() {
      #|      end = self.input.length()
      #|      self.offset = end
      #|      guard !eos_error else { raise __ROOT__MissingTerminator(field~, offset=end) }
      #|      self.input[start:end]
      #|    } else {
      #|      self.offset = end + (if consume { unit } else { 0 })
      #|      self.input[start:end + (if keep_terminator { unit } else { 0 })]
      #|    }
      #|  } else { self.take(length, field) }
      #|  let mut end = bytes.length()
      #|  if padding >= 0 { while end > 0 && bytes[end - 1].to_int() == padding { end -= 1 } }
      #|  // A sized field is consumed completely even when a terminator occurs early.
      #|  if !terminated && terminator >= 0 {
      #|    let mut i = 0
      #|    while i + unit <= end {
      #|      let matches = if unit == 1 { bytes[i].to_int() == terminator } else if big_endian { bytes[i] == 0 && bytes[i + 1].to_int() == terminator } else { bytes[i].to_int() == terminator && bytes[i + 1] == 0 }
      #|      if matches { end = i + (if keep_terminator { unit } else { 0 }); break }
      #|      i += unit
      #|    }
      #|  }
      #|  bytes[:end]
      #|}
      #|
    let block = if bits {
      block.replace_all(
        old="  let bytes = if terminated",
        new="  self.bits_left = 0\n  let bytes = if terminated",
      )
    } else {
      block
    }
    write_reader_block(output, block, root_type)
  }
  if strings {
    let block =
      #|///|
      #|fn __ROOT__Reader::decode_text(_self : __ROOT__Reader, bytes : BytesView, encoding : String, field : String, start : Int) -> String raise __ROOT__ParseError {
      #|  let output = StringBuilder()
      #|  let mut i = 0
      #|  while i < bytes.length() {
      #|    let first = bytes[i].to_int()
      #|    let mut code = first
      #|    let mut width = 1
      #|    if encoding == "UTF-16LE" || encoding == "UTF-16BE" {
      #|      guard i + 1 < bytes.length() else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|      code = if encoding == "UTF-16LE" { first | (bytes[i + 1].to_int() << 8) } else { (first << 8) | bytes[i + 1].to_int() }
      #|      width = 2
      #|      if code >= 0xD800 && code <= 0xDBFF {
      #|        guard i + 3 < bytes.length() else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|        let low = if encoding == "UTF-16LE" { bytes[i + 2].to_int() | (bytes[i + 3].to_int() << 8) } else { (bytes[i + 2].to_int() << 8) | bytes[i + 3].to_int() }
      #|        guard low >= 0xDC00 && low <= 0xDFFF else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|        code = 0x10000 + ((code - 0xD800) << 10) + low - 0xDC00
      #|        width = 4
      #|      } else {
      #|        guard code < 0xDC00 || code > 0xDFFF else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|      }
      #|    } else if first >= 128 {
      #|      guard encoding != "ASCII" else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|      width = if first >= 0xC2 && first <= 0xDF { 2 } else if first >= 0xE0 && first <= 0xEF { 3 } else if first >= 0xF0 && first <= 0xF4 { 4 } else { 0 }
      #|      guard width > 0 && i + width <= bytes.length() else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|      code = first & (if width == 2 { 0x1F } else if width == 3 { 0x0F } else { 7 })
      #|      for j in 1..<width {
      #|        let next = bytes[i + j].to_int()
      #|        guard next >= 0x80 && next <= 0xBF else { raise __ROOT__InvalidEncoding(field~, offset=start + i + j, encoding~) }
      #|        code = (code << 6) | (next & 0x3F)
      #|      }
      #|      let minimum = if width == 2 { 128 } else if width == 3 { 2048 } else { 65536 }
      #|      guard code >= minimum && code <= 0x10FFFF && (code < 0xD800 || code > 0xDFFF) else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }
      #|    }
      #|    output.write_char(code.to_char().unwrap())
      #|    i += width
      #|  }
      #|  output.to_string()
      #|}
      #|
    let block = if single_byte_encoding {
      block.replace_all(
        old="    } else if first >= 128 {",
        new="    } else if encoding == \"ISO-8859-1\" { () } else if encoding == \"WINDOWS-1252\" {\n      if first >= 0x80 && first < 0xA0 {\n        let table : FixedArray[Int] = [0x20AC, -1, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, -1, 0x017D, -1, -1, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, -1, 0x017E, 0x0178]\n        code = table[first - 0x80]\n        guard code >= 0 else { raise __ROOT__InvalidEncoding(field~, offset=start + i, encoding~) }\n      }\n    } else if first >= 128 {",
      )
    } else {
      block
    }
    let block = if extended_encodings.is_empty() {
      block
    } else {
      extend_text_reader(output, root_type, block, extended_encodings)
    }
    write_reader_block(output, block, root_type)
  }
}

///|
fn extend_text_reader(
  output : StringBuilder,
  root_type : String,
  block : String,
  encodings : Array[String],
) -> String {
  let branches = []
  if encodings.contains("SHIFT-JIS") || encodings.contains("IBM437") {
    output.write_string(cpython_codec_notice())
    output.write_string("\n\n")
  }
  if encodings.contains("SHIFT-JIS") {
    output.write_string(
      "///|\nlet ksy_shift_jis_\{root_type} : Array[Char] = \{shift_jis_mapping().escape()}.to_array()\n\n",
    )
    let branch =
      #|if encoding == "SHIFT-JIS" {
      #|      if first >= 0xA1 && first <= 0xDF {
      #|        code = 0xFF61 + first - 0xA1
      #|      } else if first >= 0x80 {
      #|        let error_offset = start + i
      #|        let valid_lead = (first >= 0x81 && first <= 0x9F) || (first >= 0xE0 && first <= 0xEF)
      #|        guard valid_lead && i + 1 < bytes.length() else {
      #|          raise __ROOT__InvalidEncoding(field~, offset=error_offset, encoding~)
      #|        }
      #|        let trail = bytes[i + 1].to_int()
      #|        guard trail >= 0x40 && trail <= 0xFC && trail != 0x7F else {
      #|          raise __ROOT__InvalidEncoding(field~, offset=error_offset, encoding~)
      #|        }
      #|        let row = if first <= 0x9F { first - 0x81 } else { first - 0xE0 + 31 }
      #|        let column = if trail <= 0x7E { trail - 0x40 } else { trail - 0x41 }
      #|        let character = ksy_shift_jis___ROOT__[row * 188 + column]
      #|        guard character != '\u{FFFD}' else {
      #|          raise __ROOT__InvalidEncoding(field~, offset=error_offset, encoding~)
      #|        }
      #|        code = character.to_int()
      #|        width = 2
      #|      }
      #|    }
    branches.push(branch)
  }
  if encodings.contains("IBM437") {
    output.write_string(
      "///|\nlet ksy_ibm437_\{root_type} : Array[Char] = \{ibm437_mapping().escape()}.to_array()\n\n",
    )
    let branch =
      #|if encoding == "IBM437" {
      #|      if first >= 0x80 {
      #|        code = ksy_ibm437___ROOT__[first - 0x80].to_int()
      #|      }
      #|    }
    branches.push(branch)
  }
  let block = if branches.is_empty() {
    block
  } else {
    let original = "    if encoding == \"UTF-16LE\" || encoding == \"UTF-16BE\" {"
    block.replace_all(
      old=original,
      new="    \{branches.join(" else ")} else \{original[4:].to_owned()}"[:],
    )
  }
  if encodings.contains("unknown") {
    let validation =
      #|  guard encoding is ("UTF-8" | "UTF8" | "ASCII" | "UTF-16LE" | "UTF-16BE" | "WINDOWS-1252" | "ISO-8859-1" | "SHIFT-JIS" | "IBM437") else {
      #|    raise __ROOT__InvalidEncoding(field~, offset=start, encoding~)
      #|  }
      #|  let output = StringBuilder()
    block.replace_all(old="  let output = StringBuilder()", new=validation[:])
  } else {
    block
  }
}
