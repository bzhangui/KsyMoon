///|
priv enum Expr {
  Integer(Int64)
  Boolean(Bool)
  Reference(String)
  StreamPosition
  StreamSize
  Unary(String, Expr)
  Binary(String, Expr, Expr)
  Choose(Expr, Expr, Expr)
}

///|
priv enum ExprType {
  Integer
  Boolean
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
    let token = StringBuilder()
    if is_ascii_digit(ch) || is_ascii_lower(ch) || ch == '_' {
      while i < chars.length() &&
            (
              is_ascii_digit(chars[i]) ||
              is_ascii_lower(chars[i]) ||
              (chars[i] >= 'A' && chars[i] <= 'Z') ||
              chars[i] == '_'
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
    "-" if self.peek() == "9223372036854775808" => {
      self.index += 1
      Integer(-9223372036854775808L)
    }
    "-" | "+" | "~" => Unary(token, self.parse(10))
    "not" => Unary(token, self.parse(3))
    "true" => Boolean(true)
    "false" => Boolean(false)
    "_io" => {
      guard self.peek() == "." else {
        invalid(self.path, "expected _io.pos or _io.size")
      }
      self.index += 1
      let attribute = self.peek()
      self.index += 1
      match attribute {
        "pos" => StreamPosition
        "size" => StreamSize
        _ => invalid(self.path, "expected _io.pos or _io.size")
      }
    }
    number if number[0] >= '0' && number[0] <= '9' =>
      Integer(
        @string.parse_int64(number[:]) catch {
          _ => invalid(self.path, "invalid or out-of-range integer constant")
        },
      )
    name if name[0] >= 'a' && name[0] <= 'z' => {
      check_identifier(name, self.path)
      Reference(name)
    }
    _ => invalid(self.path, "unexpected expression token '\{token}'")
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
fn parse_expression(
  value : @yaml.Yaml,
  path : String,
) -> Expr raise SchemaError {
  match value {
    @yaml.Integer(value) => Integer(value)
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
    Unary(_, value) => check_expression_depth(value, depth + 1, path)
    Binary(_, left, right) => {
      check_expression_depth(left, depth + 1, path)
      check_expression_depth(right, depth + 1, path)
    }
    Choose(condition, yes, no) => {
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
) -> ExprType raise SchemaError {
  match expression {
    Integer(_) | StreamPosition | StreamSize => Integer
    Boolean(_) => Boolean
    Reference(name) => lookup(name)
    Unary(op, value) => {
      let expected = if op == "not" { ExprType::Boolean } else { Integer }
      require_expression_type(value, expected, lookup, path)
      expected
    }
    Binary(op, left, right) => {
      let left_type = expression_type(left, lookup, path)
      let right_type = expression_type(right, lookup, path)
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
      require_expression_type(condition, Boolean, lookup, path)
      let result = expression_type(yes, lookup, path)
      require_expression_type(no, result, lookup, path)
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
) -> Unit raise SchemaError {
  guard expression_type(value, lookup, path) == expected else {
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
  match field.kind {
    Unsigned(_, _) | Signed(_, _) => Integer
    _ =>
      invalid(
        path, "expression currently requires an integer of at most 32 bits",
      )
  }
}

///|
fn expression_code(
  expression : Expr,
  reference : (String) -> String,
  path : String,
) -> String {
  match expression {
    Integer(n) => "\{n}L"
    Boolean(value) => if value { "true" } else { "false" }
    Reference(name) => reference(name)
    StreamPosition => "reader.offset.to_int64()"
    StreamSize => "reader.input.length().to_int64()"
    Unary("not", value) => "(!\{expression_code(value, reference, path)})"
    Unary("+", value) => expression_code(value, reference, path)
    Unary("~", value) => "(\{expression_code(value, reference, path)}.lnot())"
    Unary(_, value) =>
      "reader.arithmetic(\"-\", 0L, \{expression_code(value, reference, path)}, \{path})"
    Binary(op, left, right) => {
      let a = expression_code(left, reference, path)
      let b = expression_code(right, reference, path)
      match op {
        "+" | "-" | "*" | "/" | "%" | "<<" | ">>" =>
          "reader.arithmetic(\"\{op}\", \{a}, \{b}, \{path})"
        "and" => "(\{a} && \{b})"
        "or" => "(\{a} || \{b})"
        _ => "(\{a} \{op} \{b})"
      }
    }
    Choose(condition, yes, no) =>
      "(if \{expression_code(condition, reference, path)} { \{expression_code(yes, reference, path)} } else { \{expression_code(no, reference, path)} })"
  }
}

///|
fn expression_arithmetic(expression : Expr) -> Bool {
  match expression {
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
    StreamSize => true
    Unary(_, value) => expression_stream_size(value)
    Binary(_, a, b) => expression_stream_size(a) || expression_stream_size(b)
    Choose(c, a, b) =>
      expression_stream_size(c) ||
      expression_stream_size(a) ||
      expression_stream_size(b)
    _ => false
  }
}
