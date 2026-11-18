///|
priv enum InstanceKind {
  Value(Expr)
  Parsed(Field, Expr?)
}

///|
priv struct Instance {
  name : String
  kind : InstanceKind
  condition : Expr?
}

///|
fn parse_condition(
  value : @yaml.Yaml?,
  lookup : (String) -> ExprType raise SchemaError,
  path : String,
) -> Expr? raise SchemaError {
  match value {
    None => None
    Some(value) => {
      let expression = parse_expression(value, path)
      require_expression_type(expression, Boolean, lookup, path)
      Some(expression)
    }
  }
}

///|
fn parse_instances(
  value : @yaml.Yaml?,
  fields : Array[Field],
  endian : Endian?,
  type_names : Array[String],
  path : String,
) -> Array[Instance] raise SchemaError {
  let mapping = match value {
    None => return []
    Some(value) => as_mapping(value, path)
  }
  guard mapping.length() <= 64 else {
    invalid(path, "at most 64 instances per type")
  }
  let earlier : Map[String, Field] = Map([])
  for field in fields {
    earlier[field.name] = field
  }
  let instances = []
  for name, value in mapping {
    let path = path + "." + name
    check_identifier(name, path)
    guard !is_moonbit_keyword(name) && !earlier.contains(name) else {
      invalid(path, "instance name conflicts with a field or MoonBit keyword")
    }
    let properties = as_mapping(value, path)
    check_keys(
      properties,
      [
        "value", "pos", "if", "type", "size", "contents", "valid", "repeat", "repeat-expr",
        "doc", "doc-ref",
      ],
      path,
    )
    let condition = match properties.get("if") {
      None => None
      Some(value) => Some(parse_expression(value, path + ".if"))
    }
    let kind = match properties.get("value") {
      Some(value) => {
        check_keys(properties, ["value", "if", "doc", "doc-ref"], path)
        Value(parse_expression(value, path + ".value"))
      }
      None => {
        let position = match properties.get("pos") {
          Some(value) => Some(parse_expression(value, path + ".pos"))
          None => None
        }
        let read_properties = properties.copy()
        ignore(read_properties.remove("pos"))
        ignore(read_properties.remove("if"))
        read_properties["id"] = @yaml.String(name)
        let field = parse_field(
          @yaml.Map(read_properties),
          earlier,
          endian,
          type_names,
          path,
        )
        Parsed(field, position)
      }
    }
    instances.push({ name, kind, condition, })
  }
  instances
}

///|
fn record_expression_type(
  record : RecordDef,
  name : String,
  active : Array[String],
  path : String,
) -> ExprType raise SchemaError {
  for field in record.fields {
    if field.name == name {
      return field_expression_type(field, path)
    }
  }
  let instance = record.instances
    .iter()
    .find_first(fn(instance) { instance.name == name })
  guard instance is Some(instance) else {
    invalid(path, "unknown field or instance '\{name}'")
  }
  guard instance.condition is None else {
    invalid(path, "expression references a conditional instance")
  }
  guard !active.contains(name) else {
    invalid(path, "cyclic instance dependency at '\{name}'")
  }
  let active = [..active, name]
  match instance.kind {
    Value(expression) =>
      expression_type(
        expression,
        fn(name) raise SchemaError {
          record_expression_type(record, name, active, path)
        },
        path,
      )
    Parsed(field, _) => field_expression_type(field, path)
  }
}

///|
fn check_instances(record : RecordDef, path : String) -> Unit raise SchemaError {
  for instance in record.instances {
    let path = path + "." + instance.name
    let lookup = fn(name) raise SchemaError {
      record_expression_type(record, name, [instance.name], path)
    }
    if instance.condition is Some(condition) {
      require_expression_type(condition, Boolean, lookup, path + ".if")
    }
    match instance.kind {
      Value(expression) =>
        ignore(expression_type(expression, lookup, path + ".value"))
      Parsed(_, position) =>
        if position is Some(position) {
          require_expression_type(position, Integer, lookup, path + ".pos")
        }
    }
  }
}
