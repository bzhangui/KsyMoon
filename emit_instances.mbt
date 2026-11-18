///|
fn field_result_type(field : Field, root_type : String) -> String {
  let element = field_type(field.kind, root_type)
  let result = if field.count is Some(_) {
    "Array[\{element}]"
  } else {
    element
  }
  if field.condition is Some(_) {
    "Option[\{result}]"
  } else {
    result
  }
}

///|
fn instance_result_type(
  record : RecordDef,
  instance : Instance,
  root_type : String,
) -> String raise SchemaError {
  let result = match instance.kind {
    Parsed(field, _) => field_result_type(field, root_type)
    Value(expression) => {
      let kind = expression_type(
        expression,
        fn(name) raise SchemaError {
          record_expression_type(record, name, [instance.name], instance.name)
        },
        instance.name,
      )
      match kind {
        Integer => "Int64"
        Boolean => "Bool"
        Text => "String"
      }
    }
  }
  if instance.condition is Some(_) {
    "Option[\{result}]"
  } else {
    result
  }
}

///|
fn instance_reference(record : RecordDef, name : String) -> String {
  for field in record.fields {
    if field.name == name {
      return record_reference(record, name, true)
    }
  }
  let instance = record.instances
    .iter()
    .find_first(fn(instance) { instance.name == name })
    .unwrap()
  match instance.kind {
    Value(_) => "self.\{name}()"
    Parsed({ kind: Text(_, _), .. }, _) => "self.\{name}()"
    Parsed(_, _) => "self.\{name}().to_int64()"
  }
}

///|
fn emit_instances(
  output : StringBuilder,
  record : RecordDef,
  id : String,
  root_type : String,
  has_repeated_fields : Bool,
) -> Unit raise SchemaError {
  let type_name = if record.name == id {
    root_type + "Record"
  } else {
    nested_type(root_type, record.name)
  }
  for instance in record.instances {
    let name = instance.name
    let result_type = instance_result_type(record, instance, root_type)
    output.write_string(
      "///|\npub fn \{type_name}::\{name}(self : \{type_name}) -> \{result_type} raise \{root_type}ParseError {\n",
    )
    output.write_string(
      "  if self._ksy_cache_\{name} is Some(value) { return value }\n",
    )
    output.write_string(
      "  let reader = self._ksy_reader\n  let field = self._ksy_path + \".\{name}\"\n",
    )
    output.write_string(
      "  guard !self._ksy_busy_\{name} else { raise \{root_type}InstanceCycle(field~, offset=reader.offset) }\n",
    )
    output.write_string(
      "  self._ksy_busy_\{name} = true\n  defer { self._ksy_busy_\{name} = false }\n",
    )
    if instance.kind is Parsed(_, Some(_)) {
      output.write_string(
        "  let saved = reader.offset\n  defer { reader.offset = saved }\n",
      )
    }
    if has_repeated_fields && instance.kind is Parsed(_, _) {
      output.write_string(
        "  let saved_repeats = reader.budget[0]\n  errdefer { reader.budget[0] = saved_repeats }\n",
      )
    }
    output.write_string("  let value = {\n")
    let reference = fn(name) { instance_reference(record, name) }
    if instance.condition is Some(condition) {
      output.write_string(
        "    if \{expression_code(condition, reference, "field")} {\n",
      )
    }
    match instance.kind {
      Value(expression) =>
        output.write_string(
          "    let result = \{expression_code(expression, reference, "field")}\n",
        )
      Parsed(field, position) => {
        if position is Some(position) {
          output.write_string(
            "    reader.seek(\{expression_code(position, reference, "field")}, field)\n",
          )
        }
        emit_field_read(output, field, "result", id, "field", reference, true)
      }
    }
    output.write_string(
      if instance.condition is Some(_) {
        "    Some(result)\n    } else { None }\n"
      } else {
        "    result\n"
      },
    )
    output.write_string("  }\n")
    output.write_string(
      "  self._ksy_cache_\{name} = Some(value)\n  value\n}\n\n",
    )
  }
}
