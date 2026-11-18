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
      if kind == Integer {
        "Int64"
      } else {
        "Bool"
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
      return "self.\{name}.to_int64()"
    }
  }
  let instance = record.instances
    .iter()
    .find_first(fn(instance) { instance.name == name })
    .unwrap()
  match instance.kind {
    Value(_) => "self.\{name}()"
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
        "  let saved_repeats = reader.repeats_left\n  errdefer { reader.repeats_left = saved_repeats }\n",
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
        match field.count {
          None => {
            output.write_string(
              "    let result = \{read_code(field.kind, id, "field", in_instance=true)}\n",
            )
            if field.validation is Some(check) {
              output.write_string(
                "    reader.check_scalar(result.to_int64(), \{check.width.to_int()}, \{check.minimum}L, \{check.maximum}L, field)\n",
              )
            }
          }
          Some(count) => {
            output.write_string(
              "    let count = reader.reserve_repeats(\{length_code(count, in_instance=true)}, field)\n",
            )
            output.write_string(
              "    let result = []\n    for index in 0..<count {\n",
            )
            output.write_string(
              "      let item_path = field + \"[\" + index.to_string() + \"]\"\n",
            )
            output.write_string(
              "      result.push(\{read_code(field.kind, id, "item_path", in_instance=true)})\n    }\n",
            )
          }
        }
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
