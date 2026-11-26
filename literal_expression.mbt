///|
fn formatted_quote(chars : Array[Char], position : Int32) -> Bool {
  chars.get(position) is Some('f') && chars.get(position + 1) is Some('"')
}

///|
fn quoted_end(
  chars : Array[Char],
  start : Int32,
  path : String,
  depth : Int32,
) -> Int32 raise SchemaError {
  guard depth <= 64 else { invalid(path, "expression nesting exceeds 64") }
  let formatted = formatted_quote(chars, start)
  let quote_index = if formatted { start + 1 } else { start }
  let quote = chars[quote_index]
  let mut position = quote_index + 1
  while position < chars.length() {
    let ch = chars[position]
    if ch == quote {
      return position + 1
    }
    if quote == '"' && ch == '\\' {
      position += 2
    } else if formatted && ch == '{' {
      position = interpolation_end(chars, position + 1, path, depth + 1) + 1
    } else {
      position += 1
    }
  }
  invalid(path, "unterminated string literal")
}

///|
fn interpolation_end(
  chars : Array[Char],
  start : Int32,
  path : String,
  depth : Int32,
) -> Int32 raise SchemaError {
  let mut position = start
  while position < chars.length() {
    match chars[position] {
      '}' => return position
      '\'' | '"' => position = quoted_end(chars, position, path, depth)
      'f' if formatted_quote(chars, position) =>
        position = quoted_end(chars, position, path, depth)
      _ => position += 1
    }
  }
  invalid(path, "unterminated string interpolation")
}

///|
fn parse_formatted_string(
  token : String,
  path : String,
  depth : Int32,
) -> Expr raise SchemaError {
  let chars = token.to_array()
  let end = chars.length() - 1
  let components = []
  let mut segment = 2
  let mut position = segment
  while position < end {
    match chars[position] {
      '\\' => position += 2
      '{' => {
        if segment < position {
          components.push(
            Expr::Text(decode_string_chars(chars[segment:position], path)),
          )
        }
        let close = interpolation_end(chars, position + 1, path, depth + 1)
        let value = parse_expression_source(
          String::from_array(chars[position + 1:close]),
          path,
          depth=depth + 1,
        )
        components.push(Member(value, "@interpolate"))
        position = close + 1
        segment = position
      }
      _ => position += 1
    }
  }
  if segment < end {
    components.push(Text(decode_string_chars(chars[segment:end], path)))
  }
  guard components.get(0) is Some(first) else { return Text("") }
  let mut result = first
  for index in 1..<components.length() {
    result = Binary("+", result, components[index])
  }
  result
}

///|
fn hex_escape_digit(ch : Char, path : String) -> Int32 raise SchemaError {
  if is_ascii_digit(ch) {
    ch.to_int() - '0'.to_int()
  } else if ch >= 'a' && ch <= 'f' {
    ch.to_int() - 'a'.to_int() + 10
  } else if ch >= 'A' && ch <= 'F' {
    ch.to_int() - 'A'.to_int() + 10
  } else {
    invalid(path, "invalid Unicode escape")
  }
}

///|
fn string_escape(
  chars : ArrayView[Char],
  start : Int32,
  path : String,
) -> (Int32, Int32) raise SchemaError {
  guard chars.get(start) is Some(ch) else {
    invalid(path, "incomplete string escape")
  }
  if ch >= '0' && ch <= '7' {
    let mut value = 0
    let mut position = start
    while position < chars.length() &&
          chars[position] >= '0' &&
          chars[position] <= '7' {
      let digit = chars[position].to_int() - '0'.to_int()
      guard value <= (2147483647 - digit) / 8 else {
        invalid(path, "octal escape is out of range")
      }
      value = value * 8 + digit
      position += 1
    }
    return (value & 0xffff, position)
  }
  if ch == 'u' {
    let end = start + 5
    guard end <= chars.length() else {
      invalid(path, "Unicode escape requires four hexadecimal digits")
    }
    let mut value = 0
    for index in (start + 1)..<end {
      value = value * 16 + hex_escape_digit(chars[index], path)
    }
    return (value, end)
  }
  let value = match ch {
    'a' => 7
    'b' => 8
    't' => 9
    'n' => 10
    'v' => 11
    'f' => 12
    'r' => 13
    'e' => 27
    '\\' | '\'' | '"' => ch.to_int()
    _ => invalid(path, "unsupported string escape")
  }
  (value, start + 1)
}

///|
fn decode_string_chars(
  chars : ArrayView[Char],
  path : String,
) -> String raise SchemaError {
  let output = StringBuilder()
  let mut position = 0
  while position < chars.length() {
    let ch = chars[position]
    if ch != '\\' {
      output.write_char(ch)
      position += 1
      continue
    }
    let (first, next) = string_escape(chars, position + 1, path)
    let (code, next) = if first >= 0xd800 && first <= 0xdbff {
      guard chars.get(next) is Some('\\') else {
        invalid(path, "unpaired Unicode surrogate")
      }
      let (second, tail) = string_escape(chars, next + 1, path)
      guard second >= 0xdc00 && second <= 0xdfff else {
        invalid(path, "unpaired Unicode surrogate")
      }
      (0x10000 + (first - 0xd800) * 0x400 + second - 0xdc00, tail)
    } else {
      (first, next)
    }
    guard code.to_char() is Some(decoded) else {
      invalid(path, "unpaired Unicode surrogate")
    }
    output.write_char(decoded)
    position = next
  }
  output.to_string()
}

///|
fn context_byte_cast_value(
  scope : ContextScope,
  base : Expr,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  let kind = context_expression_type(scope, base)
  let source = context_value_code(scope, base, root, path, owner_reader)
  if kind == Bytes {
    return source
  }
  let (variant, range) = if kind == Sequence(WideInteger) {
    ("Wide", "value <= 255UL")
  } else {
    ("Number", "value >= 0L && value <= 255L")
  }
  let error = context_error(
    root,
    path,
    reader=owner_reader,
    message="byte cast requires values in 0..255",
  )
  "(match \{source} { \{root}Value::Items(items) => { let bytes = items.map(fn(item) raise \{root}ParseError { match item { \{root}Value::\{variant}(value) if \{range} => value.to_int().to_byte(); _ => { \{error} } } }); \{root}Value::Binary(Bytes::from_array(bytes[:])[:]) }; _ => { \{error} } })"
}
