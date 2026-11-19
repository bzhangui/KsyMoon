///|
fn read_effects(records : Array[RecordDef]) -> Map[String, Bool] {
  let effects : Map[String, Bool] = Map([])
  for record in records {
    effects[record.name] = false
  }
  // The validated local type graph is acyclic. Propagate effects from leaves.
  for _ in 0..<records.length() {
    for record in records {
      effects[record.name] = record.fields
        .iter()
        .any(fn(field) { field_raises(field, effects) })
    }
  }
  effects
}

///|
fn field_raises(field : Field, effects : Map[String, Bool]) -> Bool {
  field.count is Some(_) ||
  field.validation is Some(_) ||
  (field.condition is Some(condition) && expression_arithmetic(condition)) ||
  kind_raises(field.kind, effects)
}

///|
fn kind_raises(kind : FieldKind, effects : Map[String, Bool]) -> Bool {
  match kind {
    Nested(name) => effects[name]
    Switch(_, selector, cases, fallback) =>
      (!cases.is_empty() && expression_arithmetic(selector)) ||
      cases.iter().any(fn(item) { kind_raises(item.1, effects) }) ||
      (fallback is Some(child) && kind_raises(child, effects))
    _ => true
  }
}
