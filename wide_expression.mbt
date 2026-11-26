///|
fn mixed_integer_comparison(op : String, a : ExprType, b : ExprType) -> Bool {
  (a, b) is ((Integer, WideInteger) | (WideInteger, Integer)) &&
  op is ("==" | "!=" | "<" | "<=" | ">" | ">=")
}

///|
fn context_mixed_integer_comparison(
  scope : ContextScope,
  op : String,
  left : Expr,
  right : Expr,
) -> Bool raise SchemaError {
  mixed_integer_comparison(
    op,
    context_expression_type(scope, left),
    context_expression_type(scope, right),
  )
}

///|
fn context_mixed_integer_code(
  scope : ContextScope,
  op : String,
  left : Expr,
  right : Expr,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  let a = context_expression_code(scope, left, root, path, owner_reader~)
  let b = context_expression_code(scope, right, root, path, owner_reader~)
  let left_is_signed = context_expression_type(scope, left) == Integer
  let (signed, lhs, rhs) = if left_is_signed {
    ("a", "a.reinterpret_as_uint64()", "b")
  } else {
    ("b", "a", "b.reinterpret_as_uint64()")
  }
  let negative = op == "!=" ||
    (if left_is_signed {
      op == "<" || op == "<="
    } else {
      op == ">" || op == ">="
    })
  "({ let a = \{a}; let b = \{b}; if \{signed} < 0L { \{negative} } else { \{lhs} \{op} \{rhs} } })"
}
