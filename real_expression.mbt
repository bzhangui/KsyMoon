///|
fn context_real_binary(
  scope : ContextScope,
  left : Expr,
  right : Expr,
) -> Bool raise SchemaError {
  let a = context_expression_type(scope, left)
  let b = context_expression_type(scope, right)
  if a != Real && b != Real {
    return false
  }
  guard (a == Real || a == Integer) && (b == Real || b == Integer) else {
    invalid(scope.path, "real operands require a real or integer")
  }
  true
}

///|
fn context_real_code(
  scope : ContextScope,
  operator : String,
  left : Expr,
  right : Expr,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  let convert = fn(expr) raise SchemaError {
    let code = context_expression_code(scope, expr, root, path, owner_reader~)
    if context_expression_type(scope, expr) == Integer {
      "(\{code}).to_double()"
    } else {
      code
    }
  }
  let a = convert(left)
  let b = convert(right)
  if operator == "/" {
    let error = context_error(
      root,
      path,
      reader=owner_reader,
      message="division by zero",
    )
    "({ let numerator = \{a}; let denominator = \{b}; guard denominator != 0.0 else { \{error} }; numerator / denominator })"
  } else {
    "(\{a} \{operator} \{b})"
  }
}

///|
fn context_uses_integer_arithmetic(
  scope : ContextScope,
  expr : Expr,
) -> Bool raise SchemaError {
  match expr {
    Binary(op, left, right) => {
      let arithmetic = ["+", "-", "*", "/", "%", "<<", ">>"].contains(op)
      (arithmetic && !context_real_binary(scope, left, right)) ||
      context_uses_integer_arithmetic(scope, left) ||
      context_uses_integer_arithmetic(scope, right)
    }
    Unary(op, child) =>
      (op == "-" && context_expression_type(scope, child) != Real) ||
      context_uses_integer_arithmetic(scope, child)
    Index(base, index) =>
      context_uses_integer_arithmetic(scope, base) ||
      context_uses_integer_arithmetic(scope, index)
    Member(child, _) | Cast(child, _) | Decode(child, _) | ToEnum(child, _) =>
      context_uses_integer_arithmetic(scope, child)
    Choose(cond, yes, no) =>
      context_uses_integer_arithmetic(scope, cond) ||
      context_uses_integer_arithmetic(scope, yes) ||
      context_uses_integer_arithmetic(scope, no)
    _ => false
  }
}

///|
fn context_integer_helpers(graph : ContextGraph) -> Bool raise SchemaError {
  for owner, record in graph.records {
    let fields = record.fields.copy()
    let scope = context_scope(graph, owner, owner)
    let expressions = []
    for instance in record.instances {
      if instance.io is Some(value) {
        expressions.push(value)
      }
      if instance.condition is Some(value) {
        expressions.push(value)
      }
      match instance.kind {
        Value(value) => expressions.push(value)
        Parsed(field, position) => {
          fields.push(field)
          if position is Some(value) {
            expressions.push(value)
          }
        }
      }
    }
    if graph.byte_orders.get(owner) is Some(ChooseOrder(selector, _, _)) {
      expressions.push(selector)
    }
    for value in expressions {
      if context_uses_integer_arithmetic(scope, value) {
        return true
      }
    }
    for field in fields {
      let scope = context_scope(
        graph,
        owner,
        owner + "." + field.name,
        item=Some(field.kind),
        index_allowed=field.count is Some(_),
      )
      let values = context_kind_expressions(field.kind)
      if field.condition is Some(value) {
        values.push(value)
      }
      match field.count {
        Some(Times(Calculated(value))) | Some(Until(value)) =>
          values.push(value)
        _ => ()
      }
      for value in values {
        if context_uses_integer_arithmetic(scope, value) {
          return true
        }
      }
    }
  }
  false
}
