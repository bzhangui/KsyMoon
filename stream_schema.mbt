///|
fn boolean_option(
  field : Map[String, @yaml.Yaml],
  key : String,
  fallback : Bool,
  path : String,
) -> Bool raise SchemaError {
  match field.get(key) {
    None => fallback
    Some(@yaml.Boolean(value)) => value
    _ => invalid(path + "." + key, "expected a boolean")
  }
}

///|
fn byte_option(
  field : Map[String, @yaml.Yaml],
  key : String,
  path : String,
) -> Byte? raise SchemaError {
  match field.get(key) {
    None => None
    Some(@yaml.Integer(value)) if value >= 0L && value <= 255L =>
      Some(value.to_byte())
    _ => invalid(path + "." + key, "expected a byte (0..255)")
  }
}

///|
fn parse_byte_options(
  field : Map[String, @yaml.Yaml],
  earlier : Map[String, Field],
  path : String,
  strz : Bool,
  navigation~ : Bool = false,
) -> ByteOptions raise SchemaError {
  let length = match (field.get("size"), field.get("size-eos")) {
    (Some(value), None) =>
      Some(parse_length(value, earlier, path + ".size", navigation~))
    (None, Some(@yaml.Boolean(true))) => Some(Remaining)
    (None, None) | (None, Some(@yaml.Boolean(false))) => None
    _ =>
      invalid(
        path, "size and size-eos are mutually exclusive; size-eos must be boolean",
      )
  }
  let terminator = match byte_option(field, "terminator", path) {
    Some(value) => Some(value)
    None => if strz { Some(0) } else { None }
  }
  guard length is Some(_) || terminator is Some(_) else {
    invalid(path, "bytes and strings require size, size-eos or terminator")
  }
  let padding = byte_option(field, "pad-right", path)
  guard padding is None || length is Some(_) else {
    invalid(path + ".pad-right", "padding requires a sized field")
  }
  {
    length,
    terminator,
    implicit_terminator: strz && !field.contains("terminator"),
    padding,
    keep_terminator: boolean_option(field, "include", false, path),
    consume: boolean_option(field, "consume", true, path),
    eos_error: boolean_option(field, "eos-error", true, path),
  }
}

///|
fn kind_expression_type(
  kind : FieldKind,
  path : String,
) -> ExprType raise SchemaError {
  match kind {
    Unsigned(_, _) | Signed(_, _) => Integer
    Text(_, _) => Text
    _ =>
      invalid(
        path, "expression requires an integer of at most 32 bits or a string",
      )
  }
}

///|
fn parse_field_kind(
  field : Map[String, @yaml.Yaml],
  earlier : Map[String, Field],
  endian : Endian?,
  type_names : Array[String],
  path : String,
  navigation~ : Bool = false,
) -> FieldKind raise SchemaError {
  if field.get("contents") is Some(value) {
    for
      key in [
        "type", "size", "size-eos", "terminator", "pad-right", "encoding", "include",
        "consume", "eos-error",
      ] {
      guard !field.contains(key) else {
        invalid(path, "contents cannot be combined with " + key)
      }
    }
    return Contents(parse_contents(value, path + ".contents"))
  }
  let kind = match field.get("type") {
    None =>
      return ByteField(
        parse_byte_options(field, earlier, path, false, navigation~),
      )
    Some(@yaml.String("str")) | Some(@yaml.String("strz")) => {
      let encoding = as_string(
        get_required(field, "encoding", path),
        path + ".encoding",
      ).to_upper()
      guard ["UTF-8", "UTF8", "ASCII", "UTF-16LE", "UTF-16BE"].contains(
        encoding,
      ) else {
        invalid(
          path + ".encoding",
          "encoding is awaiting implementation: " + encoding,
        )
      }
      return Text(
        parse_byte_options(
          field,
          earlier,
          path,
          field.get("type") == Some(@yaml.String("strz")),
          navigation~,
        ),
        encoding,
      )
    }
    Some(@yaml.String(name)) =>
      parse_kind(name, endian, type_names, path + ".type")
    Some(value) => {
      let mapping = as_mapping(value, path + ".type")
      check_keys(mapping, ["switch-on", "cases"], path + ".type")
      let selector = parse_expression(
        get_required(mapping, "switch-on", path + ".type"),
        path + ".type.switch-on",
      )
      let lookup = fn(name) raise SchemaError {
        match earlier.get(name) {
          Some(field) => field_expression_type(field, path + ".type.switch-on")
          None =>
            invalid(
              path + ".type.switch-on",
              "unknown or forward field '" + name + "'",
            )
        }
      }
      let cases = as_mapping(
        get_required(mapping, "cases", path + ".type"),
        path + ".type.cases",
      )
      let result = []
      let mut fallback = None
      for key, value in cases {
        let kind = parse_kind(
          as_string(value, path + ".type.cases." + key),
          endian,
          type_names,
          path + ".type.cases." + key,
        )
        if key == "_" {
          fallback = Some(kind)
        } else {
          let tag = parse_expression(
            @yaml.String(key),
            path + ".type.cases." + key,
          )
          guard tag is Integer(_) ||
            tag is Text(_) ||
            tag is Boolean(_) ||
            tag is Unary("-", Integer(_)) else {
            invalid(
              path + ".type.cases." + key,
              "case must be a constant integer, string or boolean",
            )
          }
          if !navigation {
            require_expression_type(
              tag,
              expression_type(selector, lookup, path),
              lookup,
              path,
            )
          }
          result.push((tag, kind))
        }
      }
      // Stable public variant numbering across hash-map iteration orders.
      result.sort_by(fn(a, b) {
        expression_code(a.0, fn(n) { n }, "").compare(
          expression_code(b.0, fn(n) { n }, ""),
        )
      })
      let suffix = path
        .replace_all(old=".", new="_")
        .replace_all(old="[", new="_")
        .replace_all(old="]", new="")
      Switch(suffix, selector, result, fallback)
    }
  }
  let has_options = [
      "size", "size-eos", "terminator", "pad-right", "include", "consume", "eos-error",
    ]
    .iter()
    .any(fn(key) { field.contains(key) })
  guard !field.contains("encoding") else {
    invalid(path + ".encoding", "encoding requires a string type")
  }
  if has_options {
    guard kind is Nested(_) || kind is Switch(_, _, _, _) else {
      invalid(path, "byte bounds/options require a user or switch type")
    }
    Bounded(kind, parse_byte_options(field, earlier, path, false, navigation~))
  } else {
    kind
  }
}

///|
fn kind_references(kind : FieldKind) -> Array[String] {
  match kind {
    Nested(name) => [name]
    Bounded(inner, _) => kind_references(inner)
    Switch(_, _, cases, fallback) => {
      let names = []
      for (_, kind) in cases {
        names.append(kind_references(kind))
      }
      if fallback is Some(kind) {
        names.append(kind_references(kind))
      }
      names
    }
    _ => []
  }
}

///|
fn flatten_types(
  mapping : Map[String, @yaml.Yaml],
  prefix : String,
  inherited : Map[String, String],
  definitions : Map[String, @yaml.Yaml],
) -> Map[String, @yaml.Yaml] raise SchemaError {
  let types = match mapping.get("types") {
    Some(value) => as_mapping(value, "types")
    None => Map([])
  }
  let visible = inherited.copy()
  for name, _ in types {
    check_identifier(name, "types." + name)
    visible[name] = prefix + name
  }
  for name, value in types {
    let full = prefix + name
    guard !definitions.contains(full) else {
      invalid("types." + full, "flattened type name collision")
    }
    definitions[full] = @yaml.Map(
      flatten_types(
        as_mapping(value, "types." + full),
        full + "_",
        visible,
        definitions,
      ),
    )
  }
  let result = mapping.copy()
  ignore(result.remove("types"))
  if result.get("seq") is Some(@yaml.Array(fields)) {
    result["seq"] = @yaml.Array(
      fields.map(fn(value) raise SchemaError {
        rewrite_field_type(value, visible)
      }),
    )
  }
  if result.get("instances") is Some(@yaml.Map(instances)) {
    let rewritten = Map([])
    for name, value in instances {
      rewritten[name] = rewrite_field_type(value, visible)
    }
    result["instances"] = @yaml.Map(rewritten)
  }
  if prefix == "" {
    result["types"] = @yaml.Map(definitions)
  }
  result
}

///|
fn rewrite_field_type(
  value : @yaml.Yaml,
  visible : Map[String, String],
) -> @yaml.Yaml raise SchemaError {
  let field = as_mapping(value, "field").copy()
  match field.get("type") {
    Some(@yaml.String(name)) =>
      if visible.get(name) is Some(full) {
        field["type"] = @yaml.String(full)
      }
    Some(@yaml.Map(mapping)) => {
      let mapping = mapping.copy()
      if mapping.get("cases") is Some(@yaml.Map(cases)) {
        let cases = cases.copy()
        for tag, kind in cases {
          if kind is @yaml.String(name) && visible.get(name) is Some(full) {
            cases[tag] = @yaml.String(full)
          }
        }
        mapping["cases"] = @yaml.Map(cases)
      }
      field["type"] = @yaml.Map(mapping)
    }
    _ => ()
  }
  @yaml.Map(field)
}

///|
fn inherit_encoding(
  mapping : Map[String, @yaml.Yaml],
  encoding : @yaml.Yaml?,
) -> Map[String, @yaml.Yaml] raise SchemaError {
  let result = mapping.copy()
  let apply = fn(value) raise SchemaError {
    let field = as_mapping(value, "field").copy()
    if !field.contains("encoding") &&
      encoding is Some(encoding) &&
      (
        field.get("type") == Some(@yaml.String("str")) ||
        field.get("type") == Some(@yaml.String("strz"))
      ) {
      field["encoding"] = encoding
    }
    @yaml.Map(field)
  }
  if result.get("seq") is Some(@yaml.Array(fields)) {
    result["seq"] = @yaml.Array(fields.map(apply))
  }
  for section in ["types", "instances"] {
    if result.get(section) is Some(@yaml.Map(entries)) {
      let rewritten = Map([])
      for name, value in entries {
        rewritten[name] = if section == "types" {
          @yaml.Map(
            inherit_encoding(as_mapping(value, "types." + name), encoding),
          )
        } else {
          apply(value)
        }
      }
      result[section] = @yaml.Map(rewritten)
    }
  }
  result
}

///|
fn check_repeat_members(
  record : RecordDef,
  definitions : Map[String, RecordDef],
) -> Unit raise SchemaError {
  let fields = record.fields.copy()
  for instance in record.instances {
    if instance.kind is Parsed(field, _) {
      fields.push(field)
    }
  }
  for field in fields {
    if field.count is Some(Until(expression)) {
      let mut kind = field.kind
      while kind is Bounded(inner, _) {
        kind = inner
      }
      ignore(
        expression_type(
          expression,
          fn(name) raise SchemaError {
            if name.has_prefix("_.") {
              guard kind is Nested(type_name) else {
                invalid(field.name, "element member requires a user type")
              }
              let member_name = name[2:].to_owned()
              let member_field = definitions[type_name].fields
                .iter()
                .find_first(fn(f) { f.name == member_name })
              guard member_field is Some(member_field) else {
                invalid(
                  field.name,
                  "unknown element member '" + member_name + "'",
                )
              }
              field_expression_type(member_field, field.name)
            } else if name == "_" {
              kind_expression_type(kind, field.name)
            } else if name == "_index" {
              Integer
            } else {
              record_expression_type(record, name, [], field.name)
            }
          },
          field.name,
        ),
      )
    }
  }
}
