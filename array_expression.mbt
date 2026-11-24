///|
fn expression_result_type(
  kind : ExprType,
  field : String,
) -> String raise SchemaError {
  match kind {
    Integer => "Int64"
    WideInteger => "UInt64"
    Real => "Double"
    Text => "String"
    Bytes => "BytesView"
    Boolean => "Bool"
    _ => invalid(field, "unsupported array element type")
  }
}

///|
fn emit_sequence_extremes(
  output : StringBuilder,
  root : String,
  flags : Array[String],
) -> Unit {
  let clauses = StringBuilder()
  for
    (flag, variant) in [
      ("", "Number"),
      ("wide", "Wide"),
      ("real", "RealValue"),
      ("text", "StringValue"),
      ("binary", "Binary"),
    ] {
    if flag == "" || flags.contains(flag) {
      let less = if flag == "text" || flag == "binary" {
        lexical_code(if flag == "text" { Text } else { Bytes }, "<", "a", "b")
      } else {
        "a < b"
      }
      let greater = if flag == "text" || flag == "binary" {
        lexical_code(if flag == "text" { Text } else { Bytes }, ">", "a", "b")
      } else {
        "a > b"
      }
      clauses.write_string(
        "      (\{variant}(a), \{variant}(b)) => if minimum { \{less} } else { \{greater} }\n",
      )
    }
  }
  output.write_string(
    "///|\nfn \{root}Value::extreme(_ : \{root}Value, items : Array[\{root}Value], minimum : Bool) -> \{root}Value {\n  guard items.get(0) is Some(first) else { return Absent }\n  let mut best = first\n  for i in 1..<items.length() {\n    let candidate = items[i]\n    let replace_best = match (candidate, best) {\n\{clauses.to_string()}      _ => false\n    }\n    if replace_best { best = candidate }\n  }\n  best\n}\n",
  )
}

///|
fn lexical_binary(
  scope : ContextScope,
  op : String,
  left : Expr,
) -> Bool raise SchemaError {
  ["<", "<=", ">", ">="].contains(op) &&
  context_expression_type(scope, left) is (Text | Bytes)
}

///|
fn lexical_code(
  kind : ExprType,
  op : String,
  left : String,
  right : String,
) -> String {
  if kind == Text {
    "((\{left})[:].lexical_compare((\{right})[:]) \{op} 0)"
  } else {
    "((\{left}).lexical_compare(\{right}) \{op} 0)"
  }
}

///|
fn context_lexical_code(
  scope : ContextScope,
  op : String,
  left : Expr,
  right : Expr,
  root : String,
  path : String,
  reader : String,
) -> String raise SchemaError {
  lexical_code(
    context_expression_type(scope, left),
    op,
    context_expression_code(scope, left, root, path, owner_reader=reader),
    context_expression_code(scope, right, root, path, owner_reader=reader),
  )
}
