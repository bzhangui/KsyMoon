///|
fn walk_kinds(kind : FieldKind) -> Array[FieldKind] {
  let result = [kind]
  match kind {
    Bounded(inner, _) | Enumerated(inner, _) => result.append(walk_kinds(inner))
    Switch(_, _, cases, fallback) => {
      for (_, child) in cases {
        result.append(walk_kinds(child))
      }
      if fallback is Some(child) {
        result.append(walk_kinds(child))
      }
    }
    _ => ()
  }
  result
}

///|
fn record_reference(
  record : RecordDef,
  name : String,
  instance : Bool,
) -> String {
  let prefix = if instance { "self." } else { "v_" }
  let field = record.fields.iter().find_first(fn(f) { f.name == name })
  let suffix = if field is Some({ kind: Text(_, _) | BitInteger(1, _), .. }) {
    ""
  } else {
    ".to_int64()"
  }
  prefix + name + suffix
}

///|
fn byte_read_code(
  options : ByteOptions,
  path : String,
  instance : Bool,
  unit~ : Int32 = 1,
  big_endian~ : Bool = false,
  evaluate~ : ((Expr) -> String)? = None,
) -> String {
  let length = match options.length {
    Some(length) => length_code(length, in_instance=instance, evaluate~)
    None => "-1L"
  }
  let raw = if options.terminator is None && options.padding is None {
    "reader.take(\{length}, \{path})"
  } else {
    let term = match options.terminator {
      Some(b) => b.to_int().to_string()
      None => "-1"
    }
    let pad = match
      (if options.padding == options.terminator {
        None
      } else {
        options.padding
      }) {
      Some(b) => b.to_int().to_string()
      None => "-1"
    }
    "reader.read_bytes(\{length}, \{options.length is None}, \{term}, \{pad}, \{options.keep_terminator}, \{options.consume}, \{options.eos_error}, \{unit}, \{big_endian}, \{path})"
  }
  match options.processor {
    Some(processor) => processor_code(processor, raw, path, evaluate)
    None => raw
  }
}

///|
fn emit_switch_types(
  output : StringBuilder,
  records : Array[RecordDef],
  root_type : String,
) -> Unit {
  for record in records {
    let fields = record.fields.copy()
    for instance in record.instances {
      if instance.kind is Parsed(field, _) {
        fields.push(field)
      }
    }
    for field in fields {
      for kind in walk_kinds(field.kind) {
        if kind is Switch(name, _, cases, fallback) {
          output.write_string("///|\npub enum \{root_type}_switch_\{name} {\n")
          for index, (_, kind) in cases {
            output.write_string(
              "  Case\{index}(\{field_type(kind, root_type)})\n",
            )
          }
          if fallback is Some(kind) {
            output.write_string("  Default(\{field_type(kind, root_type)})\n")
          } else {
            output.write_string(
              if field.kind is Bounded(_, _) {
                "  Raw(BytesView)\n"
              } else {
                "  Unknown\n"
              },
            )
          }
          output.write_string("}\n\n")
        }
      }
    }
  }
}

///|
fn switch_read_code(
  kind : FieldKind,
  id : String,
  path : String,
  reference : (String) -> String,
  bounded : Bool,
  instance : Bool,
  selector_override~ : String? = None,
  evaluate~ : ((Expr) -> String)? = None,
  parent_context~ : String? = None,
  bits~ : Bool = false,
) -> String {
  guard kind is Switch(name, selector, cases, fallback) else {
    abort("expected switch")
  }
  let type_name = pascal_case(id) + "_switch_" + name
  let result = StringBuilder()
  // Selection uses the parent stream/fields, while case reads use the child stream.
  let selector_code = selector_override.unwrap_or(
    match evaluate {
      Some(evaluate) => evaluate(selector)
      None => expression_code(selector, reference, path, bit_stream=bits)
    },
  )
  result.write_string(
    if cases.is_empty() {
      "{ "
    } else {
      "{ let selector = \{selector_code}; "
    },
  )
  for index, (tag, child) in cases {
    let tag = match evaluate {
      Some(resolve) => resolve(tag)
      None => expression_code(tag, reference, path, bit_stream=bits)
    }
    result.write_string(
      "if selector == \{tag} { \{type_name}::Case\{index}(\{read_code(child, id, path, in_instance=instance, reference~, evaluate~, parent_context~, bits~)}) } else ",
    )
  }
  if fallback is Some(child) {
    result.write_string(
      "{ \{type_name}::Default(\{read_code(child, id, path, in_instance=instance, reference~, evaluate~, parent_context~, bits~)}) }",
    )
  } else if bounded {
    result.write_string(
      "{ \{type_name}::Raw(reader.take((reader.input.length() - reader.offset).to_int64(), \{path})) }",
    )
  } else {
    result.write_string("{ \{type_name}::Unknown }")
  }
  result.write_string(" }")
  result.to_string()
}

///|
fn emit_field_read(
  output : StringBuilder,
  field : Field,
  target : String,
  id : String,
  path : String,
  reference : (String) -> String,
  instance : Bool,
  evaluate~ : ((Expr) -> String)? = None,
  parent_context~ : String? = None,
  publish_items~ : (String, String)? = None,
  bits~ : Bool = false,
) -> Unit {
  match field.count {
    None => {
      output.write_string(
        "  let \{target} = \{read_code(field.kind, id, path, in_instance=instance, reference~, evaluate~, parent_context~, bits~)}\n",
      )
      if field.validation is Some(check) {
        output.write_string(
          "  reader.check_scalar(\{target}.to_int64(), \{check.width.to_int()}, \{check.minimum}L, \{check.maximum}L, \{path})\n",
        )
      }
    }
    Some(repeat) => {
      match repeat {
        Times(count) =>
          output.write_string(
            "  let count_\{target} = reader.reserve_repeats(\{length_code(count, in_instance=instance, evaluate~)}, \{path})\n",
          )
        _ => ()
      }
      output.write_string("  let \{target} = []\n")
      if publish_items is Some((before, _)) {
        output.write_string(before)
      }
      match repeat {
        Times(_) =>
          output.write_string("  for index in 0..<count_\{target} {\n")
        ToEnd => {
          let buffered = if bits &&
            field.kind is (BitInteger(_, _) | WideBitInteger(_, _)) {
            " || reader.bits_left > 0"
          } else {
            ""
          }
          output.write_string(
            "  while reader.offset < reader.input.length()\{buffered} {\n    let index = \{target}.length()\n",
          )
        }
        Until(_) =>
          output.write_string(
            "  while true {\n    let index = \{target}.length()\n",
          )
      }
      output.write_string(
        "    let item_path = \{path} + \"[\" + index.to_string() + \"]\"\n",
      )
      if repeat is ToEnd || repeat is Until(_) {
        output.write_string(
          "    ignore(reader.reserve_repeats(1L, item_path))\n",
        )
      }
      if repeat is ToEnd {
        output.write_string(
          if bits {
            "    let before = reader.offset.to_int64() * 8L - reader.bits_left.to_int64()\n"
          } else {
            "    let before = reader.offset\n"
          },
        )
      }
      output.write_string(
        "    let item = \{read_code(field.kind, id, "item_path", in_instance=instance, reference~, evaluate~, parent_context~, bits~)}\n    \{target}.push(item)\n",
      )
      if publish_items is Some((_, after)) {
        output.write_string(after)
      }
      if repeat is Until(expression) {
        let predicate = match evaluate {
          Some(evaluate) => evaluate(expression)
          None =>
            expression_code(
              expression,
              fn(name) {
                if name == "_" {
                  if field.kind is Text(_, _) || field.kind is BitInteger(1, _) {
                    "item"
                  } else {
                    "item.to_int64()"
                  }
                } else if name == "_index" {
                  "index.to_int64()"
                } else if name.has_prefix("_.") {
                  "item." + name[2:].to_owned() + ".to_int64()"
                } else {
                  reference(name)
                }
              },
              "item_path",
              bit_stream=bits,
            )
        }
        output.write_string("    if \{predicate} { break }\n")
      }
      if repeat is ToEnd {
        let position = if bits {
          "(reader.offset.to_int64() * 8L - reader.bits_left.to_int64())"
        } else {
          "reader.offset"
        }
        output.write_string(
          "    guard \{position} > before else { raise \{pascal_case(id)}NoProgress(field=item_path, offset=reader.offset) }\n",
        )
      }
      output.write_string("  }\n")
    }
  }
}
