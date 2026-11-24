///|
priv struct EnumDef {
  labels : Array[(Int64, String)]
}

///|
fn parse_enum(value : @yaml.Yaml, path : String) -> EnumDef raise SchemaError {
  let labels = []
  let values : Map[Int64, Bool] = Map([])
  let names : Map[String, Bool] = Map([])
  for key, raw in as_mapping(value, path) {
    let number = @string.parse_int64(key[:]) catch {
      _ =>
        invalid(path + "." + key, "enum code must fit a signed 64-bit integer")
    }
    let label = match raw {
      @yaml.Map(meta) => {
        check_keys(meta, ["id", "doc", "doc-ref"], path + "." + key)
        as_string(get_required(meta, "id", path + "." + key), path + "." + key)
      }
      _ => as_string(raw, path + "." + key)
    }
    check_identifier(label, path + "." + key)
    guard !values.contains(number) && !names.contains(label) else {
      invalid(path + "." + key, "duplicate enum code or label")
    }
    values[number] = true
    names[label] = true
    labels.push((number, label))
  }
  guard !labels.is_empty() else {
    invalid(path, "enum requires at least one label")
  }
  labels.sort_by(fn(a, b) { a.0.compare(b.0) })
  { labels, }
}

///|
fn case_sort_key(tag : Expr) -> String {
  match tag {
    EnumLiteral(name, label) => name + "::" + label
    _ => expression_code(tag, fn(n) { n }, "")
  }
}

///|
fn context_enum(
  scope : ContextScope,
  name : String,
) -> EnumDef raise SchemaError {
  guard scope.graph.enums.get(name) is Some(definition) else {
    let label = if name.has_prefix("@") { name[1:].to_owned() } else { name }
    invalid(scope.path, "unknown enum '" + label + "'")
  }
  definition
}

///|
fn context_enum_label(
  scope : ContextScope,
  name : String,
  label : String,
) -> (String, Int64) raise SchemaError {
  let names = scope.graph.enum_scopes[scope.owner]
  let full = scoped_enum_name(name, scope.graph.type_scopes[scope.owner], names)
  let definition = context_enum(scope, full)
  guard definition.labels.iter().find_first(fn(item) { item.1 == label })
    is Some((value, _)) else {
    invalid(scope.path, "unknown enum label '" + name + "::" + label + "'")
  }
  (full, value)
}

///|
fn scoped_enum_name(
  name : String,
  types : Map[String, String],
  enums : Map[String, String],
) -> String {
  if enums.get(name) is Some(full) {
    return full
  }
  if name.rev_split_once("::") is Some((owner, enum_name)) {
    let first = owner
      .split_once("::")
      .map(fn(parts) { parts.0 })
      .unwrap_or(owner)
    if types.contains(first.to_owned()) {
      return scoped_type_name(owner.to_owned(), types) +
        "__" +
        enum_name.to_owned()
    }
  }
  "@" + name
}

///|
fn generated_enum_type(root : String, name : String) -> String {
  root + "_enum_" + name
}

///|
fn generated_enum_label(name : String) -> String {
  let label = pascal_case(name)
  if label == "UnknownCode" {
    "Known_" + label
  } else {
    label
  }
}

///|
fn emit_enums(
  output : StringBuilder,
  root : String,
  enums : Map[String, EnumDef],
) -> Unit {
  let names = enums.keys().collect()
  names.sort()
  for name in names {
    let kind = generated_enum_type(root, name)
    let raw = enums[name].labels
    let labels = raw.map(fn(item) {
      let (code, name) = item
      let label = generated_enum_label(name)
      let collides = raw
        .iter()
        .any(fn(other) {
          other.1 != name && generated_enum_label(other.1) == label
        })
      (code, if collides { label + "_" + name } else { label })
    })
    output.write_string("///|\npub(all) enum \{kind} {\n")
    for (_, label) in labels {
      output.write_string("  \{label}\n")
    }
    output.write_string(
      "  UnknownCode(Int64)\n} derive(Eq)\n\n///|\npub extend \{kind} with Eq::{not_equal, equal}\n\n",
    )
    output.write_string(
      "///|\npub fn \{kind}::from_code(code : Int64) -> \{kind} {\n  match code {\n",
    )
    for (code, label) in labels {
      output.write_string("    \{code}L => \{kind}::\{label}\n")
    }
    output.write_string("    _ => \{kind}::UnknownCode(code)\n  }\n}\n\n")
    output.write_string(
      "///|\npub fn \{kind}::to_i(self : \{kind}) -> Int64 {\n  match self {\n",
    )
    for (code, label) in labels {
      output.write_string("    \{label} => \{code}L\n")
    }
    output.write_string("    UnknownCode(code) => code\n  }\n}\n\n")
  }
}
