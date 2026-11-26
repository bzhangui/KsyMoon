///|
priv enum Expr {
  Integer(Int64)
  WideLiteral(UInt64)
  RealLiteral(Double)
  Text(String)
  ByteLiteral(Bytes)
  ArrayLiteral(Array[Expr])
  Boolean(Bool)
  Reference(String)
  Member(Expr, String)
  Index(Expr, Expr)
  Cast(Expr, String)
  Decode(Expr, String)
  Substring(Expr, Expr, Expr)
  EnumLiteral(String, String)
  ToEnum(Expr, String)
  TypeSize(String, Bool)
  StreamPosition
  StreamSize
  StreamEof
  Unary(String, Expr)
  Binary(String, Expr, Expr)
  Choose(Expr, Expr, Expr)
} derive(Eq)

///|
priv enum ExprType {
  Integer
  Boolean
  Text
  Stream
  Object(Array[String])
  Sequence(ExprType)
  Bytes
  WideInteger
  Enum(String)
  Real
} derive(Eq)

///|
priv struct ExprParser {
  tokens : Array[String]
  path : String
  mut index : Int32
  mut depth : Int32
}

///|
fn expression_tokens(
  source : String,
  path : String,
) -> Array[String] raise SchemaError {
  let chars = source.to_array()
  guard chars.length() <= 4096 else {
    invalid(path, "expression exceeds 4096 characters")
  }
  let tokens = []
  let mut i = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
      i += 1
      continue
    }
    if ch == '\'' || ch == '"' {
      let quote = ch
      let token = StringBuilder()
      token.write_char(quote)
      i += 1
      let mut closed = false
      while i < chars.length() {
        let current = chars[i]
        token.write_char(current)
        i += 1
        if current == '\\' && i < chars.length() {
          token.write_char(chars[i])
          i += 1
        } else if current == quote {
          closed = true
          break
        }
      }
      guard closed else { invalid(path, "unterminated string literal") }
      tokens.push(token.to_string())
      continue
    }
    let token = StringBuilder()
    if is_ascii_digit(ch) || is_ascii_lower(ch) || ch == '_' {
      let start = i
      let decimal = is_ascii_digit(ch) &&
        !(ch == '0' &&
        i + 1 < chars.length() &&
        ['x', 'X', 'b', 'B', 'o', 'O'].contains(chars[i + 1]))
      while i < chars.length() &&
            (
              is_ascii_digit(chars[i]) ||
              is_ascii_lower(chars[i]) ||
              (chars[i] >= 'A' && chars[i] <= 'Z') ||
              chars[i] == '_' ||
              (
                decimal &&
                chars[i] == '.' &&
                i + 1 < chars.length() &&
                is_ascii_digit(chars[i + 1])
              ) ||
              (
                decimal &&
                i > start &&
                (chars[i] == '+' || chars[i] == '-') &&
                (chars[i - 1] == 'e' || chars[i - 1] == 'E')
              )
            ) {
        token.write_char(chars[i])
        i += 1
      }
    } else {
      token.write_char(ch)
      i += 1
      if i < chars.length() &&
        (
          (
            (ch == '=' || ch == '!' || ch == '<' || ch == '>') &&
            chars[i] == '='
          ) ||
          (ch == ':' && chars[i] == ':') ||
          (ch == '<' && chars[i] == '<') ||
          (ch == '>' && chars[i] == '>')
        ) {
        token.write_char(chars[i])
        i += 1
      }
    }
    tokens.push(token.to_string())
  }
  tokens
}

///|
fn ExprParser::peek(self : ExprParser) -> String {
  self.tokens.get(self.index).unwrap_or("")
}

///|
fn expression_precedence(op : String) -> Int32 {
  match op {
    "or" => 1
    "and" => 2
    "==" | "!=" | "<" | "<=" | ">" | ">=" => 3
    "|" => 4
    "^" => 5
    "&" => 6
    "<<" | ">>" => 7
    "+" | "-" => 8
    "*" | "/" | "%" => 9
    _ => 0
  }
}

///|
fn ExprParser::parse(
  self : ExprParser,
  minimum : Int32,
) -> Expr raise SchemaError {
  self.depth += 1
  guard self.depth <= 64 else {
    invalid(self.path, "expression nesting exceeds 64")
  }
  let token = self.peek()
  self.index += 1
  let mut left = match token {
    "" => invalid(self.path, "expected an expression")
    "(" => {
      let value = self.parse(1)
      guard self.peek() == ")" else { invalid(self.path, "expected ')'") }
      self.index += 1
      value
    }
    "[" => {
      let items = []
      if self.peek() != "]" {
        while true {
          items.push(self.parse(1))
          if self.peek() != "," {
            break
          }
          self.index += 1
        }
      }
      guard self.peek() == "]" else { invalid(self.path, "expected ']'") }
      self.index += 1
      if items
        .iter()
        .all(fn(item) { item is Integer(value) && value >= 0L && value <= 255L }) {
        ByteLiteral(
          Bytes::makei(items.length(), fn(index) {
            match items[index] {
              Integer(value) => value.to_byte()
              _ => abort("invalid byte literal")
            }
          }),
        )
      } else {
        ArrayLiteral(items)
      }
    }
    "-" if self.peek() == "9223372036854775808" => {
      self.index += 1
      Integer(-9223372036854775808L)
    }
    "-" | "+" | "~" => Unary(token, self.parse(10))
    "not" => Unary(token, self.parse(3))
    "true" => Boolean(true)
    "false" => Boolean(false)
    "sizeof" | "bitsizeof" if self.peek() == "<" => {
      self.index += 1
      let parts = []
      while true {
        let name = self.peek()
        check_identifier(name, self.path)
        self.index += 1
        parts.push(name)
        if self.peek() != "::" {
          break
        }
        self.index += 1
      }
      guard self.peek() == ">" else {
        invalid(self.path, "expected '>' after size type")
      }
      self.index += 1
      TypeSize(parts.join("::"), token == "bitsizeof")
    }
    "_io" =>
      if self.peek() != "." {
        Reference("_io")
      } else {
        self.index += 1
        let attribute = self.peek()
        self.index += 1
        match attribute {
          "pos" => StreamPosition
          "size" => StreamSize
          "eof" => StreamEof
          _ => invalid(self.path, "expected _io.pos or _io.size")
        }
      }
    "_root" | "_parent" | "_sizeof" | "_bitsizeof" => Reference(token)
    number if number[0] >= '0' && number[0] <= '9' =>
      parse_number_literal(number, self.path)
    quoted if quoted[0] == '\'' || quoted[0] == '"' =>
      Text(parse_quoted(quoted, self.path))
    "_" | "_index" => Reference(token)
    name if name[0] >= 'a' && name[0] <= 'z' => {
      check_identifier(name, self.path)
      if self.peek() == "::" {
        let parts = [name]
        while self.peek() == "::" {
          self.index += 1
          let part = self.peek()
          check_identifier(part, self.path)
          self.index += 1
          parts.push(part)
        }
        let label = parts.pop().unwrap()
        EnumLiteral(parts.join("::"), label)
      } else {
        Reference(name)
      }
    }
    _ => invalid(self.path, "unexpected expression token '\{token}'")
  }
  while self.peek() == "." || self.peek() == "[" {
    let operation = self.peek()
    self.index += 1
    if operation == "." {
      let attribute = self.peek()
      self.index += 1
      if attribute == "substring" && self.peek() == "(" {
        self.index += 1
        let start = self.parse(1)
        guard self.peek() == "," else {
          invalid(self.path, "substring requires two indices")
        }
        self.index += 1
        let end = self.parse(1)
        guard self.peek() == ")" else {
          invalid(self.path, "expected ')' after substring indices")
        }
        self.index += 1
        left = Substring(left, start, end)
      } else if attribute == "to_s" && self.peek() == "(" {
        self.index += 1
        let encoding = self.peek()
        guard encoding.has_prefix("'") || encoding.has_prefix("\"") else {
          invalid(self.path, "byte decoding requires a literal encoding")
        }
        self.index += 1
        guard self.peek() == ")" else {
          invalid(self.path, "expected ')' after encoding")
        }
        self.index += 1
        left = Decode(left, parse_quoted(encoding, self.path).to_upper())
      } else if attribute == "as" && self.peek() == "<" {
        self.index += 1
        let parts = []
        while true {
          let name = self.peek()
          check_identifier(name, self.path)
          self.index += 1
          parts.push(name)
          if self.peek() != "::" {
            break
          }
          self.index += 1
        }
        let is_array = self.peek() == "["
        if is_array {
          self.index += 1
          guard self.peek() == "]" else {
            invalid(self.path, "expected ']' after array cast target")
          }
          self.index += 1
        }
        guard self.peek() == ">" else {
          invalid(self.path, "expected '>' after cast target")
        }
        self.index += 1
        let suffix = if is_array { "[]" } else { "" }
        left = Cast(left, parts.join("::") + suffix)
      } else {
        if attribute != "_io" &&
          attribute != "_root" &&
          attribute != "_parent" &&
          attribute != "_sizeof" &&
          attribute != "_bitsizeof" {
          check_identifier(attribute, self.path)
        }
        left = if left is Reference("_") && attribute != "length" {
          Reference("_." + attribute)
        } else {
          Member(left, attribute)
        }
      }
    } else {
      let index = self.parse(1)
      guard self.peek() == "]" else {
        invalid(self.path, "expected ']' in array access")
      }
      self.index += 1
      left = Index(left, index)
    }
  }
  while expression_precedence(self.peek()) >= minimum {
    let op = self.peek()
    let precedence = expression_precedence(op)
    self.index += 1
    let right = self.parse(precedence + 1)
    left = Binary(op, left, right)
  }
  if minimum == 1 && self.peek() == "?" {
    self.index += 1
    let yes = self.parse(1)
    guard self.peek() == ":" else {
      invalid(self.path, "expected ':' in conditional expression")
    }
    self.index += 1
    left = Choose(left, yes, self.parse(1))
  }
  self.depth -= 1
  left
}

///|
fn parse_number_literal(
  number : String,
  path : String,
) -> Expr raise SchemaError {
  let lowercase = number.to_lower()
  let base_prefix = lowercase.has_prefix("0x") ||
    lowercase.has_prefix("0b") ||
    lowercase.has_prefix("0o")
  if !base_prefix && (number.contains(".") || lowercase.contains("e")) {
    let value = @string.parse_double(number[:]) catch {
      _ => invalid(path, "invalid real constant")
    }
    guard !value.is_inf() && !value.is_nan() else {
      invalid(path, "real constant is out of range")
    }
    RealLiteral(value)
  } else {
    try @string.parse_int64(number[:]) catch {
      _ => {
        let digits = if number.has_prefix("+") { number[1:] } else { number[:] }
        let value = @string.parse_uint64(digits) catch {
          _ => invalid(path, "invalid or out-of-range integer constant")
        }
        WideLiteral(value)
      }
    } noraise {
      value => Integer(value)
    }
  }
}

///|
fn parse_expression(
  value : @yaml.Yaml,
  path : String,
) -> Expr raise SchemaError {
  match value {
    @yaml.Integer(value) => Integer(value)
    @yaml.Real(value, repr~) => {
      // The YAML decoder keeps the spelling when a scalar exceeds Int64.
      let digits = if repr.has_prefix("+") || repr.has_prefix("-") {
        repr[1:]
      } else {
        repr[:]
      }
      if !digits.is_empty() && digits.iter().all(is_ascii_digit) {
        parse_number_literal(repr, path)
      } else {
        RealLiteral(value)
      }
    }
    @yaml.Array(_) => ByteLiteral(parse_contents(value, path))
    @yaml.Boolean(value) => Boolean(value)
    @yaml.String(source) => {
      let parser : ExprParser = {
        tokens: expression_tokens(source, path),
        path,
        index: 0,
        depth: 0,
      }
      let expression = parser.parse(1)
      guard parser.index == parser.tokens.length() else {
        invalid(path, "unexpected expression token '\{parser.peek()}'")
      }
      check_expression_depth(expression, 0, path)
      expression
    }
    _ => invalid(path, "expected an integer, boolean or expression string")
  }
}

///|
fn check_expression_depth(
  expression : Expr,
  depth : Int32,
  path : String,
) -> Unit raise SchemaError {
  guard depth <= 64 else { invalid(path, "expression nesting exceeds 64") }
  match expression {
    Member(value, _) | Cast(value, _) | Decode(value, _) | ToEnum(value, _) =>
      check_expression_depth(value, depth + 1, path)
    Index(value, index) => {
      check_expression_depth(value, depth + 1, path)
      check_expression_depth(index, depth + 1, path)
    }
    Unary(_, value) => check_expression_depth(value, depth + 1, path)
    Binary(_, left, right) => {
      check_expression_depth(left, depth + 1, path)
      check_expression_depth(right, depth + 1, path)
    }
    Choose(condition, yes, no) | Substring(condition, yes, no) => {
      check_expression_depth(condition, depth + 1, path)
      check_expression_depth(yes, depth + 1, path)
      check_expression_depth(no, depth + 1, path)
    }
    _ => ()
  }
}

///|
fn expression_type(
  expression : Expr,
  lookup : (String) -> ExprType raise SchemaError,
  path : String,
  navigation~ : ((Expr) -> ExprType raise SchemaError)? = None,
) -> ExprType raise SchemaError {
  match expression {
    Integer(_) | StreamPosition | StreamSize => Integer
    WideLiteral(_) => WideInteger
    RealLiteral(_) => Real
    Boolean(_) | StreamEof => Boolean
    Text(_) => Text
    ByteLiteral(_) => Bytes
    Reference(name) => lookup(name)
    Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | Decode(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _)
    | TypeSize(_, _)
    | Substring(_, _, _)
    | ArrayLiteral(_) =>
      match navigation {
        Some(resolve) => resolve(expression)
        None => invalid(path, "object navigation awaits implementation")
      }
    Unary(op, value) => {
      let expected = if op == "not" { ExprType::Boolean } else { Integer }
      require_expression_type(value, expected, lookup, path, navigation~)
      expected
    }
    Binary(op, left, right) => {
      let left_type = expression_type(left, lookup, path, navigation~)
      let right_type = expression_type(right, lookup, path, navigation~)
      guard left_type == right_type else {
        invalid(path, "expression operands have different types")
      }
      match op {
        "and" | "or" => {
          guard left_type == Boolean else {
            invalid(path, "logical operands must be boolean")
          }
          Boolean
        }
        "==" | "!=" => Boolean
        _ => {
          guard left_type == Integer else {
            invalid(path, "operator requires integer operands")
          }
          if op == "<" || op == "<=" || op == ">" || op == ">=" {
            Boolean
          } else {
            Integer
          }
        }
      }
    }
    Choose(condition, yes, no) => {
      require_expression_type(condition, Boolean, lookup, path, navigation~)
      let result = expression_type(yes, lookup, path, navigation~)
      require_expression_type(no, result, lookup, path, navigation~)
      result
    }
  }
}

///|
fn require_expression_type(
  value : Expr,
  expected : ExprType,
  lookup : (String) -> ExprType raise SchemaError,
  path : String,
  navigation~ : ((Expr) -> ExprType raise SchemaError)? = None,
) -> Unit raise SchemaError {
  guard expression_type(value, lookup, path, navigation~) == expected else {
    invalid(
      path,
      if expected == Boolean {
        "expected a boolean expression"
      } else {
        "expected an integer expression"
      },
    )
  }
}

///|
fn field_expression_type(
  field : Field,
  path : String,
) -> ExprType raise SchemaError {
  guard field.count is None && field.condition is None else {
    invalid(path, "expression requires a nonoptional scalar field")
  }
  kind_expression_type(field.kind, path)
}

///|
fn expression_code(
  expression : Expr,
  reference : (String) -> String,
  path : String,
  navigation~ : ((Expr) -> String)? = None,
  lowered~ : ((Expr) -> String?)? = None,
  stream_reader~ : String = "reader",
  bit_stream~ : Bool = false,
) -> String {
  if lowered is Some(lower) && lower(expression) is Some(code) {
    return code
  }
  let child = fn(value) {
    expression_code(
      value,
      reference,
      path,
      navigation~,
      lowered~,
      stream_reader~,
      bit_stream~,
    )
  }
  match expression {
    Integer(n) => "\{n}L"
    WideLiteral(n) => "\{n}UL"
    RealLiteral(value) => {
      let code = value.to_string()
      if code.contains(".") || code.contains("e") {
        code
      } else {
        code + ".0"
      }
    }
    Text(value) => value.escape()
    ByteLiteral(bytes) => byte_literal_code(bytes)
    Boolean(value) => if value { "true" } else { "false" }
    Reference(name) => reference(name)
    Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | Decode(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _)
    | TypeSize(_, _)
    | Substring(_, _, _)
    | ArrayLiteral(_) => navigation.unwrap()(expression)
    StreamPosition => "\{stream_reader}.offset.to_int64()"
    StreamSize => "\{stream_reader}.input.length().to_int64()"
    StreamEof =>
      if bit_stream {
        "(\{stream_reader}.bits_left == 0 && \{stream_reader}.offset == \{stream_reader}.input.length())"
      } else {
        "(\{stream_reader}.offset.to_int64() == \{stream_reader}.input.length().to_int64())"
      }
    Unary("not", value) => "(!\{child(value)})"
    Unary("+", value) => child(value)
    Unary("~", value) => "(\{child(value)}.lnot())"
    Unary(_, value) =>
      "\{stream_reader}.arithmetic(\"-\", 0L, \{child(value)}, \{path})"
    Binary(op, left, right) => {
      let a = child(left)
      let b = child(right)
      match op {
        "+" | "-" | "*" | "/" | "%" | "<<" | ">>" =>
          "\{stream_reader}.arithmetic(\"\{op}\", \{a}, \{b}, \{path})"
        "and" => "(\{a} && \{b})"
        "or" => "(\{a} || \{b})"
        _ => "(\{a} \{op} \{b})"
      }
    }
    Choose(condition, yes, no) =>
      "(if \{child(condition)} { \{child(yes)} } else { \{child(no)} })"
  }
}

///|
fn expression_arithmetic(expression : Expr) -> Bool {
  match expression {
    Member(value, _) | Cast(value, _) | Decode(value, _) | ToEnum(value, _) =>
      expression_arithmetic(value)
    Index(value, index) =>
      expression_arithmetic(value) || expression_arithmetic(index)
    Unary(op, value) => op == "-" || expression_arithmetic(value)
    Binary(op, a, b) =>
      ["+", "-", "*", "/", "%", "<<", ">>"].contains(op) ||
      expression_arithmetic(a) ||
      expression_arithmetic(b)
    Choose(c, a, b) =>
      expression_arithmetic(c) ||
      expression_arithmetic(a) ||
      expression_arithmetic(b)
    _ => false
  }
}

///|
fn expression_stream_size(expression : Expr) -> Bool {
  match expression {
    StreamSize | StreamEof => true
    Cast(value, _) | ToEnum(value, _) => expression_stream_size(value)
    Member(value, attribute) =>
      attribute == "size" || expression_stream_size(value)
    Index(value, index) =>
      expression_stream_size(value) || expression_stream_size(index)
    Unary(_, value) => expression_stream_size(value)
    Binary(_, a, b) => expression_stream_size(a) || expression_stream_size(b)
    Choose(c, a, b) =>
      expression_stream_size(c) ||
      expression_stream_size(a) ||
      expression_stream_size(b)
    _ => false
  }
}

///|
fn parse_quoted(source : String, path : String) -> String raise SchemaError {
  let chars = source.to_array()
  let output = StringBuilder()
  let mut i = 1
  while i < chars.length() - 1 {
    let ch = chars[i]
    if ch == '\\' {
      i += 1
      output.write_char(
        match chars[i] {
          'n' => '\n'
          'r' => '\r'
          't' => '\t'
          '\\' => '\\'
          '\'' => '\''
          '"' => '"'
          _ => invalid(path, "unsupported string escape")
        },
      )
    } else {
      output.write_char(ch)
    }
    i += 1
  }
  output.to_string()
}

///|
fn integer_cast(target : String) -> (Int32, Bool)? {
  match target {
    "u1" => Some((8, false))
    "u2" => Some((16, false))
    "u4" => Some((32, false))
    "u8" => Some((64, false))
    "s1" => Some((8, true))
    "s2" => Some((16, true))
    "s4" => Some((32, true))
    "s8" => Some((64, true))
    _ => None
  }
}

///|
fn expression_any(expr : Expr, predicate : (Expr) -> Bool) -> Bool {
  if predicate(expr) {
    return true
  }
  match expr {
    ArrayLiteral(items) =>
      items.iter().any(fn(item) { expression_any(item, predicate) })
    Member(base, _)
    | Cast(base, _)
    | Decode(base, _)
    | ToEnum(base, _)
    | Unary(_, base) => expression_any(base, predicate)
    Index(a, b) | Binary(_, a, b) =>
      expression_any(a, predicate) || expression_any(b, predicate)
    Choose(a, b, c) | Substring(a, b, c) =>
      expression_any(a, predicate) ||
      expression_any(b, predicate) ||
      expression_any(c, predicate)
    _ => false
  }
}

///|
fn context_contains_endpoint(expr : Expr) -> Bool {
  expression_any(expr, fn(value) { value is Member(_, "first" | "last") })
}

///|
fn context_contains_wide_value(expr : Expr) -> Bool {
  expression_any(expr, fn(value) { value is (Cast(_, "u8") | WideLiteral(_)) })
}
