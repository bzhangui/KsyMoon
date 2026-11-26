///|
fn context_to_integer(
  scope : ContextScope,
  value : Expr,
  radix : Expr?,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  let code = context_expression_code(scope, value, root, path, owner_reader~)
  match context_expression_type(scope, value) {
    Boolean => "(\{code}).to_int64()"
    Real => {
      let error = context_error(
        root,
        path,
        reader=owner_reader,
        message="real value is outside the Int64 range",
      )
      "({ let real = \{code}; guard real >= -9223372036854775808.0 && real < 9223372036854775808.0 else { \{error} }; real.to_int64() })"
    }
    Text => {
      let base = match radix {
        Some(base) =>
          context_expression_code(scope, base, root, path, owner_reader~)
        None => "10L"
      }
      scope.graph.needs_text_integer = true
      "\{owner_reader}.parse_text_integer(\{code}, \{base}, \{path})"
    }
    _ =>
      invalid(
        scope.path,
        "integer conversion requires a string, boolean or real",
      )
  }
}

///|
fn emit_text_integer(output : StringBuilder, root : String) -> Unit {
  let block =
    #|///|
    #|fn __ROOT__Reader::parse_text_integer(self : __ROOT__Reader, text : String, radix : Int64, field : String) -> Int64 raise __ROOT__ParseError {
    #|  let error = __ROOT__ContextError(field~, offset=self.offset, message="invalid integer text")
    #|  guard radix == 0L || (radix >= 2L && radix <= 36L) else { raise error }
    #|  let chars = text.trim().to_array()
    #|  let negative = chars.get(0) == Some('-')
    #|  let sign = if chars.get(0) is Some('+' | '-') { 1 } else { 0 }
    #|  let prefix_base = if chars.get(sign) == Some('0') {
    #|    match chars.get(sign + 1) {
    #|      Some('b' | 'B') => 2L
    #|      Some('o' | 'O') => 8L
    #|      Some('x' | 'X') => 16L
    #|      _ => 0L
    #|    }
    #|  } else { 0L }
    #|  let prefixed = prefix_base != 0L && (radix == 0L || radix == prefix_base)
    #|  let base = if prefixed { prefix_base } else if radix == 0L { 10L } else { radix }
    #|  let start = if prefixed { sign + 2 } else { sign }
    #|  let limit = if negative { 9223372036854775808UL } else { 9223372036854775807UL }
    #|  let base = base.reinterpret_as_uint64()
    #|  let mut number = 0UL
    #|  let mut previous_digit = prefixed
    #|  guard start < chars.length() else { raise error }
    #|  for i in start..<chars.length() {
    #|    let ch = chars[i]
    #|    if ch == '_' {
    #|      guard previous_digit else { raise error }
    #|      previous_digit = false
    #|      continue
    #|    }
    #|    let digit = match ch {
    #|      '0'..<='9' => ch.to_int() - '0'.to_int()
    #|      'a'..<='z' => ch.to_int() - 'a'.to_int() + 10
    #|      'A'..<='Z' => ch.to_int() - 'A'.to_int() + 10
    #|      _ => raise error
    #|    }
    #|    let digit = digit.to_uint64()
    #|    guard digit < base && number <= (limit - digit) / base else { raise error }
    #|    number = number * base + digit
    #|    previous_digit = true
    #|  }
    #|  guard previous_digit && !(radix == 0L && !prefixed && chars[sign] == '0' && number != 0UL) else { raise error }
    #|  (if negative { 0UL - number } else { number }).reinterpret_as_int64()
    #|}
    #|
  write_reader_block(output, block, root)
}
