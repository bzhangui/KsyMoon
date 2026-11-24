///|
fn scalar_validation(kind : FieldKind, value : @yaml.Yaml) -> Bool {
  (kind is Unsigned(_, _) || kind is Signed(_, _)) && integer_validation(value)
}

///|
fn integer_validation(value : @yaml.Yaml) -> Bool {
  match value {
    @yaml.Integer(_) => true
    @yaml.Map(keys) =>
      keys.keys().all(fn(key) { ["eq", "min", "max"].contains(key) }) &&
      keys.values().all(fn(entry) { entry is @yaml.Integer(_) })
    _ => false
  }
}

///|
fn raw_predicate_validation(
  field : Map[String, @yaml.Yaml],
  value : @yaml.Yaml,
) -> Bool {
  if field.contains("repeat") || !integer_validation(value) {
    return true
  }
  guard field.get("type") is Some(@yaml.String(name)) else { return true }
  let numeric = [
    "u1", "u2", "u2le", "u2be", "u4", "u4le", "u4be", "s1", "s2", "s2le", "s2be",
    "s4", "s4le", "s4be",
  ]
  !numeric.contains(name)
}

///|
fn validation_expression(
  value : @yaml.Yaml,
  path : String,
) -> Expr raise SchemaError {
  let actual = Expr::Reference("_")
  let compare = fn(op, expected) raise SchemaError {
    Expr::Binary(op, actual, parse_expression(expected, path))
  }
  match value {
    @yaml.Map(options) => {
      check_keys(options, ["eq", "min", "max", "any-of", "expr"], path)
      if options.get("expr") is Some(expr) && options.length() == 1 {
        return parse_expression(expr, path)
      }
      if options.get("eq") is Some(expr) && options.length() == 1 {
        return compare("==", expr)
      }
      if options.get("any-of") is Some(@yaml.Array(choices)) &&
        options.length() == 1 {
        guard !choices.is_empty() else {
          invalid(path, "any-of cannot be empty")
        }
        let mut predicate = compare("==", choices[0])
        for choice in choices[1:] {
          predicate = Binary("or", predicate, compare("==", choice))
        }
        return predicate
      }
      match (options.get("min"), options.get("max")) {
        (Some(minimum), Some(maximum)) if options.length() == 2 =>
          Binary("and", compare(">=", minimum), compare("<=", maximum))
        (Some(minimum), None) if options.length() == 1 => compare(">=", minimum)
        (None, Some(maximum)) if options.length() == 1 => compare("<=", maximum)
        _ =>
          invalid(path, "expected a single validation rule or a min/max range")
      }
    }
    _ => compare("==", value)
  }
}

///|
fn plain_predicate(field : Field) -> Bool {
  guard field.predicate is Some(expr) else { return false }
  guard field.kind
    is (Unsigned(_, _)
    | Signed(_, _)
    | Signed64(_)
    | BitInteger(_, _)
    | ByteField(_)
    | Text(_, _)
    | Contents(_)
    | Float32(_)
    | Float64(_)) else {
    return false
  }
  predicate_is_comparison(expr)
}

///|
fn predicate_is_comparison(expr : Expr) -> Bool {
  match expr {
    Binary("and" | "or", a, b) =>
      predicate_is_comparison(a) && predicate_is_comparison(b)
    Binary("==" | "!=" | "<" | "<=" | ">" | ">=", a, b) =>
      predicate_operand(a) && predicate_operand(b)
    Unary("not", value) => predicate_is_comparison(value)
    Boolean(_) => true
    _ => false
  }
}

///|
fn predicate_operand(expr : Expr) -> Bool {
  expr
  is (Reference("_")
  | Integer(_)
  | RealLiteral(_)
  | ByteLiteral(_)
  | Text(_)
  | Boolean(_)
  | Unary("-", Integer(_)))
}

///|
fn predicate_code(
  field : Field,
  expr : Expr,
  path : String,
  evaluate : ((Expr) -> String)?,
) -> String {
  if plain_predicate(field) {
    plain_predicate_code(field.kind, expr, path)
  } else {
    evaluate.unwrap()(expr)
  }
}

///|
fn plain_predicate_code(kind : FieldKind, expr : Expr, path : String) -> String {
  let actual = match kind {
    Unsigned(_, _) | Signed(_, _) | BitInteger(_, _) if !(kind
      is BitInteger(1, _)) => "item.to_int64()"
    Float32(_) => "item.to_double()"
    _ => "item"
  }
  let emit = fn(value) { expression_code(value, fn(_) { actual }, path) }
  match expr {
    Binary(op, a, b) if op == "and" || op == "or" => {
      let joined = if op == "and" { "&&" } else { "||" }
      "(\{plain_predicate_code(kind, a, path)} \{joined} \{plain_predicate_code(kind, b, path)})"
    }
    Binary(op, a, b) => {
      let real = kind is (Float32(_) | Float64(_)) ||
        a is RealLiteral(_) ||
        b is RealLiteral(_)
      let operand = fn(value : Expr) {
        match value {
          Integer(n) | Unary("-", Integer(n)) => {
            let n = if value is Unary(_, _) { -n } else { n }
            if real {
              "(\{n}L).to_double()"
            } else {
              "\{n}L"
            }
          }
          Reference("_") if real && !(kind is Float32(_) || kind is Float64(_)) =>
            "(\{actual}).to_double()"
          _ => emit(value)
        }
      }
      if ["<", "<=", ">", ">="].contains(op) &&
        kind is (Text(_, _) | ByteField(_) | Contents(_)) {
        lexical_code(
          if kind is Text(_, _) {
            Text
          } else {
            Bytes
          },
          op,
          operand(a),
          operand(b),
        )
      } else {
        "(\{operand(a)} \{op} \{operand(b)})"
      }
    }
    Unary("not", value) => "(!\{plain_predicate_code(kind, value, path)})"
    _ => emit(expr)
  }
}

///|
fn plain_byte_until(expr : Expr) -> Bool {
  predicate_is_comparison(expr) &&
  expression_any(expr, fn(value) { value is ByteLiteral(_) })
}
