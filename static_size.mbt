///|
fn constant_length(length : LengthExpr) -> Int64? {
  match length {
    Constant(value) | Calculated(Integer(value)) if value >= 0L => Some(value)
    _ => None
  }
}

///|
fn fixed_product(a : Int64, b : Int64) -> Int64? {
  if a == 0L || b <= 9223372036854775807L / a {
    Some(a * b)
  } else {
    None
  }
}

///|
fn fixed_kind_bits(
  graph : ContextGraph,
  kind : FieldKind,
  visiting : Array[String],
) -> Int64? {
  match kind {
    Unsigned(width, _) | Signed(width, _) => Some(width.to_int64() * 8L)
    Signed64(_) | Unsigned64(_) | Float64(_) => Some(64L)
    Float32(_) => Some(32L)
    BitInteger(width, _) | WideBitInteger(width, _) => Some(width.to_int64())
    Contents(bytes) => Some(bytes.length().to_int64() * 8L)
    ByteField(options) | Text(options, _) | Bounded(_, options) =>
      options.length
      .bind(constant_length)
      .bind(fn(value) { fixed_product(value, 8L) })
    Enumerated(inner, _) => fixed_kind_bits(graph, inner, visiting)
    Nested(name) | Application(name, _) =>
      fixed_record_bits(graph, name, visiting)
    Switch(_, _, cases, fallback) => {
      guard fallback is Some(branch) &&
        fixed_kind_bits(graph, branch, visiting) is Some(bits) else {
        return None
      }
      if cases
        .iter()
        .all(fn(entry) {
          fixed_kind_bits(graph, entry.1, visiting) == Some(bits)
        }) {
        Some(bits)
      } else {
        None
      }
    }
  }
}

///|
fn fixed_field_bits(
  graph : ContextGraph,
  field : Field,
  visiting : Array[String],
) -> Int64? {
  guard fixed_kind_bits(graph, field.kind, visiting) is Some(bits) else {
    return None
  }
  match field.count {
    None => Some(bits)
    Some(Times(count)) =>
      constant_length(count).bind(fn(value) { fixed_product(value, bits) })
    _ => None
  }
}

///|
fn fixed_record_bits(
  graph : ContextGraph,
  owner : String,
  visiting : Array[String],
) -> Int64? {
  guard !visiting.contains(owner) && graph.records.get(owner) is Some(record) else {
    return None
  }
  let path = [..visiting, owner]
  let mut total = 0L
  for field in record.fields {
    if field.condition is Some(Boolean(false)) {
      continue
    }
    guard field.condition is (None | Some(Boolean(true))) &&
      fixed_field_bits(graph, field, path) is Some(bits) else {
      return None
    }
    let raw_bits = match field.kind {
      Enumerated(inner, _) => inner is (BitInteger(_, _) | WideBitInteger(_, _))
      BitInteger(_, _) | WideBitInteger(_, _) => true
      _ => false
    }
    let align = if raw_bits { 0L } else { (8L - total % 8L) % 8L }
    guard total <= 9223372036854775807L - align &&
      total + align <= 9223372036854775807L - bits else {
      return None
    }
    total += align + bits
  }
  Some(total)
}

///|
fn fixed_value_bits(
  scope : ContextScope,
  target : Expr,
) -> Int64? raise SchemaError {
  let graph = scope.graph
  match target {
    Reference("_root" | "_parent") => ()
    Reference(name) =>
      if graph.records[scope.owner].fields
        .iter()
        .find_first(fn(field) { field.name == name })
        is Some(field) {
        return fixed_field_bits(graph, field, [])
      }
    Member(base, name) =>
      if context_expression_type(scope, base) is Object([owner]) &&
        graph.records.get(owner) is Some(record) &&
        record.fields.iter().find_first(fn(field) { field.name == name })
        is Some(field) {
        return fixed_field_bits(graph, field, [])
      }
    _ => ()
  }
  if context_expression_type(scope, target) is Object([owner]) {
    fixed_record_bits(graph, owner, [])
  } else {
    None
  }
}

///|
fn size_expression(
  scope : ContextScope,
  expression : Expr,
) -> Int64 raise SchemaError {
  let (bits, as_bits) = match expression {
    Reference(name) =>
      (fixed_record_bits(scope.graph, scope.owner, []), name == "_bitsizeof")
    Member(value, name) =>
      (fixed_value_bits(scope, value), name == "_bitsizeof")
    TypeSize(name, as_bits) => {
      let width = match name {
        "u1" | "s1" => Some(8L)
        "u2" | "u2be" | "u2le" | "s2" | "s2be" | "s2le" => Some(16L)
        "u4"
        | "u4be"
        | "u4le"
        | "s4"
        | "s4be"
        | "s4le"
        | "f4"
        | "f4le"
        | "f4be" => Some(32L)
        "u8"
        | "u8be"
        | "u8le"
        | "s8"
        | "s8be"
        | "s8le"
        | "f8"
        | "f8le"
        | "f8be" => Some(64L)
        _ =>
          if bit_width(name) is Some(width) && width >= 1 && width <= 64 {
            Some(width.to_int64())
          } else {
            fixed_record_bits(scope.graph, context_cast_target(scope, name), [])
          }
      }
      (width, as_bits)
    }
    _ => (None, false)
  }
  guard bits is Some(width) else {
    invalid(scope.path, "size is not fixed at schema compilation")
  }
  if as_bits {
    width
  } else {
    width / 8L + (if width % 8L == 0L { 0L } else { 1L })
  }
}
