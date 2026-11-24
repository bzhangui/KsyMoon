///|
fn supported_encoding(encoding : String) -> Bool {
  [
    "UTF-8", "UTF8", "ASCII", "UTF-16LE", "UTF-16BE", "WINDOWS-1252", "ISO-8859-1",
  ].contains(encoding)
}

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
    processor: field
    .get("process")
    .map(fn(value) raise SchemaError {
      parse_processor(value, earlier, path + ".process")
    }),
  }
}

///|
fn kind_expression_type(
  kind : FieldKind,
  path : String,
) -> ExprType raise SchemaError {
  match kind {
    BitInteger(1, _) => Boolean
    Unsigned(_, _) | Signed(_, _) | Signed64(_) | BitInteger(_, _) => Integer
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
        "consume", "eos-error", "process",
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
      guard supported_encoding(encoding) else {
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
        let case_path = path + ".type.cases." + key
        let kind = match value {
          @yaml.String("strz") => {
            let case = Map([("type", value)])
            if field.get("encoding") is Some(encoding) {
              case["encoding"] = encoding
            }
            parse_field_kind(
              case,
              earlier,
              endian,
              type_names,
              case_path,
              navigation~,
            )
          }
          _ =>
            parse_kind(
              as_string(value, case_path),
              endian,
              type_names,
              case_path,
            )
        }
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
            tag is EnumLiteral(_, _) ||
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
      result.sort_by(fn(a, b) { case_sort_key(a.0).compare(case_sort_key(b.0)) })
      let suffix = path
        .replace_all(old=".", new="_")
        .replace_all(old="[", new="_")
        .replace_all(old="]", new="")
      Switch(suffix, selector, result, fallback)
    }
  }
  let has_options = [
      "size", "size-eos", "terminator", "pad-right", "include", "consume", "eos-error",
      "process",
    ]
    .iter()
    .any(fn(key) { field.contains(key) })
  guard !field.contains("encoding") ||
    walk_kinds(kind).iter().any(fn(kind) { kind is Text(_, _) }) else {
    invalid(path + ".encoding", "encoding requires a string type")
  }
  if has_options {
    guard kind is Nested(_) ||
      kind is Application(_, _) ||
      kind is Switch(_, _, _, _) else {
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
    Nested(name) | Application(name, _) => [name]
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
  type_scopes : Map[String, Map[String, String]],
  inherited_enums : Map[String, String],
  enum_scopes : Map[String, Map[String, String]],
  enums : Map[String, EnumDef],
  imports_visibility : Map[String, Map[String, String]],
  module_roots : Map[String, String],
  module_owner~ : String = "@root",
) -> Map[String, @yaml.Yaml] raise SchemaError {
  let types = match mapping.get("types") {
    Some(value) => as_mapping(value, "types")
    None => Map([])
  }
  let owner = if prefix == "" {
    "@root"
  } else {
    prefix[:prefix.length() - 1].to_owned()
  }
  if module_owner != "@root" {
    module_roots[owner] = module_owner
  }
  let visible = match imports_visibility.get(owner) {
    Some(aliases) => aliases.copy()
    None => inherited.copy()
  }
  for name, _ in types {
    check_identifier(name, "types." + name)
    if owner != "@root" || !imports_visibility.contains(name) {
      visible[name] = prefix + name
    }
  }
  type_scopes[owner] = visible
  let visible_enums = if owner != "@root" && imports_visibility.contains(owner) {
    Map([])
  } else {
    inherited_enums.copy()
  }
  if mapping.get("enums") is Some(raw_enums) {
    for enum_name, raw_values in as_mapping(raw_enums, owner + ".enums") {
      let path = owner + ".enums." + enum_name
      check_identifier(enum_name, path)
      let name = if owner == "@root" {
        enum_name
      } else {
        owner + "__" + enum_name
      }
      visible_enums[enum_name] = name
      enums[name] = parse_enum(raw_values, path)
    }
  }
  enum_scopes[owner] = visible_enums
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
        type_scopes,
        visible_enums,
        enum_scopes,
        enums,
        imports_visibility,
        module_roots,
        module_owner=if owner == "@root" && imports_visibility.contains(name) {
          full
        } else {
          module_owner
        },
      ),
    )
  }
  let result = mapping.copy()
  ignore(result.remove("types"))
  if result.get("seq") is Some(@yaml.Array(fields)) {
    result["seq"] = @yaml.Array(
      fields.map(fn(value) raise SchemaError {
        rewrite_field_type(value, visible, visible_enums, imports_visibility)
      }),
    )
  }
  if result.get("instances") is Some(@yaml.Map(instances)) {
    let rewritten = Map([])
    for name, value in instances {
      rewritten[name] = rewrite_field_type(
        value, visible, visible_enums, imports_visibility,
      )
    }
    result["instances"] = @yaml.Map(rewritten)
  }
  if prefix == "" {
    result["types"] = @yaml.Map(definitions)
  }
  result
}

///|
fn scoped_type_name(name : String, visible : Map[String, String]) -> String {
  if name.split_once("(") is Some((base, arguments)) {
    return scoped_type_name(base.trim().to_owned(), visible) +
      "(" +
      arguments.to_owned()
  }
  if visible.get(name) is Some(full) {
    full
  } else if name.split_once("::") is Some((prefix, suffix)) &&
    visible.get(prefix.to_owned()) is Some(full) {
    full + "_" + suffix.replace_all(old="::", new="_").to_owned()
  } else {
    name
  }
}

///|
fn scoped_field_type(
  name : String,
  visible : Map[String, String],
  imports_visibility : Map[String, Map[String, String]],
) -> String raise SchemaError {
  let base = match name.split_once("(") {
    Some((base, _)) => base.trim().to_owned()
    None => name
  }
  let first = match base.split_once("::") {
    Some((qualifier, _)) => qualifier.to_owned()
    None => base
  }
  if imports_visibility.contains(first) && !visible.contains(first) {
    invalid("type", "module '" + first + "' must be imported by this document")
  }
  scoped_type_name(name, visible)
}

///|
fn rewrite_field_type(
  value : @yaml.Yaml,
  visible : Map[String, String],
  visible_enums : Map[String, String],
  imports_visibility : Map[String, Map[String, String]],
) -> @yaml.Yaml raise SchemaError {
  let field = as_mapping(value, "field").copy()
  if field.get("enum") is Some(@yaml.String(name)) {
    field["enum"] = @yaml.String(scoped_enum_name(name, visible, visible_enums))
  }
  match field.get("type") {
    Some(@yaml.String(name)) =>
      field["type"] = @yaml.String(
        scoped_field_type(name, visible, imports_visibility),
      )
    Some(@yaml.Map(mapping)) => {
      let mapping = mapping.copy()
      if mapping.get("cases") is Some(@yaml.Map(cases)) {
        let cases = cases.copy()
        for tag, kind in cases {
          if kind is @yaml.String(name) {
            cases[tag] = @yaml.String(
              scoped_field_type(name, visible, imports_visibility),
            )
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
fn schema_endian(
  value : @yaml.Yaml?,
  path : String,
) -> Endian? raise SchemaError {
  match value {
    None => None
    Some(@yaml.String("le")) => Some(Little)
    Some(@yaml.String("be")) => Some(Big)
    _ => invalid(path, "expected 'le' or 'be'")
  }
}

///|
fn inherit_read_defaults(
  mapping : Map[String, @yaml.Yaml],
  inherited : Map[String, @yaml.Yaml],
  imports_visibility : Map[String, Map[String, String]],
  byte_orders : Map[String, ByteOrder],
  owner~ : String = "@root",
  order_owner~ : String? = None,
  root~ : Bool = true,
) -> Map[String, @yaml.Yaml] raise SchemaError {
  let defaults = inherited.copy()
  let mut order_owner = order_owner
  let path = owner + ".meta.endian"
  if mapping.get("meta") is Some(value) {
    let meta = as_mapping(value, "type.meta")
    if !root {
      check_keys(meta, ["endian", "encoding", "bit-endian"], "type.meta")
    }
    if meta.get("endian") is Some(raw) {
      if raw is @yaml.Map(options) {
        byte_orders[owner] = parse_byte_order(options, path)
        order_owner = Some(owner)
      } else {
        order_owner = None
      }
    }
    for key in ["endian", "encoding", "bit-endian"] {
      if meta.get(key) is Some(value) {
        defaults[key] = value
      }
    }
  }
  if order_owner is Some(declaration) && declaration != owner {
    byte_orders[owner] = Inherited(declaration)
  }
  let bit_order = if schema_endian(
      defaults.get("bit-endian"),
      "meta.bit-endian",
    )
    is Some(Little) {
    "le"
  } else {
    "be"
  }
  let normalize_type = fn(value : @yaml.Yaml) {
    if value is @yaml.String(name) &&
      bit_width(name) is Some(_) &&
      !name.has_suffix("be") &&
      !name.has_suffix("le") {
      @yaml.String(name + bit_order)
    } else {
      value
    }
  }
  let result = mapping.copy()
  result["meta"] = @yaml.Map(defaults)
  let apply = fn(value) raise SchemaError {
    let field = as_mapping(value, "field").copy()
    match field.get("type") {
      Some(@yaml.Map(kind)) if kind.get("cases") is Some(@yaml.Map(cases)) => {
        let kind = kind.copy()
        let normalized = Map([])
        for key, value in cases {
          normalized[key] = normalize_type(value)
        }
        kind["cases"] = @yaml.Map(normalized)
        field["type"] = @yaml.Map(kind)
      }
      Some(value) => field["type"] = normalize_type(value)
      None => ()
    }
    let text = match field.get("type") {
      Some(@yaml.String("str" | "strz")) => true
      Some(@yaml.Map(kind)) =>
        match kind.get("cases") {
          Some(@yaml.Map(cases)) =>
            cases
            .values()
            .any(fn(value) { value is @yaml.String("str" | "strz") })
          _ => false
        }
      _ => false
    }
    if text &&
      !field.contains("encoding") &&
      defaults.get("encoding") is Some(value) {
      field["encoding"] = value
    }
    @yaml.Map(field)
  }
  if result.get("seq") is Some(@yaml.Array(fields)) {
    result["seq"] = @yaml.Array(fields.map(apply))
  }
  if result.get("instances") is Some(@yaml.Map(entries)) {
    let rewritten = Map([])
    for name, value in entries {
      rewritten[name] = apply(value)
    }
    result["instances"] = @yaml.Map(rewritten)
  }
  if result.get("types") is Some(@yaml.Map(entries)) {
    let rewritten = Map([])
    for name, value in entries {
      let external = root && imports_visibility.contains(name)
      let child = if root { name } else { owner + "_" + name }
      let defaults = if external { Map([]) } else { defaults }
      rewritten[name] = @yaml.Map(
        inherit_read_defaults(
          as_mapping(value, "types." + name),
          defaults,
          imports_visibility,
          byte_orders,
          owner=child,
          order_owner=if external { None } else { order_owner },
          root=false,
        ),
      )
    }
    result["types"] = @yaml.Map(rewritten)
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
