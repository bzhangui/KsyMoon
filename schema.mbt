///|
/// A schema could not be loaded or uses a construct outside the supported subset.
pub suberror SchemaError {
  InvalidSchema(String)
}

///|
priv enum Endian {
  Little
  Big
}

///|
priv enum LengthExpr {
  Constant(Int64)
  EarlierField(String, Int64)
}

///|
priv enum FieldKind {
  Unsigned(Byte, Endian)
  Signed(Byte, Endian)
  Float32(Endian)
  RawBytes(LengthExpr)
  Contents(Bytes)
  Nested(String)
}

///|
priv struct Field {
  name : String
  kind : FieldKind
  count : LengthExpr?
  validation : ScalarCheck?
}

///|
priv struct ScalarCheck {
  width : Byte
  minimum : Int64
  maximum : Int64
}

///|
priv struct RecordDef {
  name : String
  fields : Array[Field]
}

///|
priv struct Schema {
  root : RecordDef
  records : Array[RecordDef]
}

///|
fn[A] invalid(path : String, message : String) -> A raise SchemaError {
  raise InvalidSchema("\{path}: \{message}")
}

///|
fn as_mapping(
  value : @yaml.Yaml,
  path : String,
) -> Map[String, @yaml.Yaml] raise SchemaError {
  match value {
    @yaml.Map(mapping) => mapping
    _ => invalid(path, "expected a mapping")
  }
}

///|
fn get_required(
  mapping : Map[String, @yaml.Yaml],
  key : String,
  path : String,
) -> @yaml.Yaml raise SchemaError {
  match mapping.get(key) {
    Some(value) => value
    None => invalid("\{path}.\{key}", "missing required key")
  }
}

///|
fn as_string(value : @yaml.Yaml, path : String) -> String raise SchemaError {
  match value {
    @yaml.String(value) => value
    _ => invalid(path, "expected a string")
  }
}

///|
fn check_keys(
  mapping : Map[String, @yaml.Yaml],
  allowed : Array[String],
  path : String,
) -> Unit raise SchemaError {
  for key, _ in mapping {
    guard allowed.contains(key) || key.has_prefix("-") else {
      invalid("\{path}.\{key}", "unsupported key")
    }
  }
}

///|
fn is_ascii_lower(ch : Char) -> Bool {
  ch >= 'a' && ch <= 'z'
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn check_identifier(name : String, path : String) -> Unit raise SchemaError {
  guard !name.is_empty() else {
    invalid(path, "expected a lower snake case identifier")
  }
  for index, ch in name {
    guard is_ascii_lower(ch) || (index > 0 && (is_ascii_digit(ch) || ch == '_')) else {
      invalid(path, "expected a lower snake case identifier")
    }
  }
  guard !name.has_suffix("_") && !name.contains("__") else {
    invalid(path, "expected a lower snake case identifier")
  }
}

///|
fn is_moonbit_keyword(name : String) -> Bool {
  match name {
    "as"
    | "async"
    | "break"
    | "catch"
    | "const"
    | "continue"
    | "declare"
    | "defer"
    | "derive"
    | "dyn"
    | "else"
    | "enum"
    | "enumview"
    | "errdefer"
    | "extern"
    | "extend"
    | "extenum"
    | "false"
    | "fn"
    | "for"
    | "guard"
    | "if"
    | "impl"
    | "in"
    | "is"
    | "let"
    | "lexmatch"
    | "lexscan"
    | "loop"
    | "match"
    | "mut"
    | "nobreak"
    | "noraise"
    | "open"
    | "priv"
    | "pub"
    | "raise"
    | "return"
    | "struct"
    | "suberror"
    | "test"
    | "trait"
    | "true"
    | "try"
    | "type"
    | "typealias"
    | "using"
    | "where"
    | "while" => true
    _ => false
  }
}

///|
fn parse_decimal(text : StringView, path : String) -> Int64 raise SchemaError {
  guard !text.is_empty() && text.iter().all(is_ascii_digit) else {
    invalid(path, "expected a nonnegative decimal integer")
  }
  @string.parse_int64(text) catch {
    _ => invalid(path, "integer is outside the Int64 range")
  }
}

///|
fn parse_length(
  value : @yaml.Yaml,
  earlier : Map[String, Field],
  path : String,
) -> LengthExpr raise SchemaError {
  match value {
    @yaml.Integer(value) => {
      guard value >= 0L else { invalid(path, "length cannot be negative") }
      Constant(value)
    }
    @yaml.String(expression) => {
      let expression = expression.trim()
      if !expression.is_empty() && expression.iter().all(is_ascii_digit) {
        return Constant(parse_decimal(expression, path))
      }
      let (name, subtract) = match expression.split_once("-") {
        Some((left, right)) =>
          (left.trim().to_owned(), parse_decimal(right.trim(), path))
        None => (expression.to_owned(), 0L)
      }
      match earlier.get(name) {
        Some({ kind: Unsigned(_, _), count: None, .. }) =>
          EarlierField(name, subtract)
        _ =>
          invalid(
            path, "expected an earlier scalar unsigned field, optionally minus an integer",
          )
      }
    }
    _ => invalid(path, "expected a length expression")
  }
}

///|
fn default_endian(endian : Endian?, path : String) -> Endian raise SchemaError {
  match endian {
    Some(endian) => endian
    None => invalid(path, "multibyte numeric type needs an explicit byte order")
  }
}

///|
fn parse_kind(
  type_name : String,
  endian : Endian?,
  type_names : Array[String],
  path : String,
) -> FieldKind raise SchemaError {
  match type_name {
    "u1" => Unsigned(1, Big)
    "u2" => Unsigned(2, default_endian(endian, path))
    "u2le" => Unsigned(2, Little)
    "u2be" => Unsigned(2, Big)
    "u4" => Unsigned(4, default_endian(endian, path))
    "u4le" => Unsigned(4, Little)
    "u4be" => Unsigned(4, Big)
    "s1" => Signed(1, Big)
    "s2" => Signed(2, default_endian(endian, path))
    "s2le" => Signed(2, Little)
    "s2be" => Signed(2, Big)
    "s4" => Signed(4, default_endian(endian, path))
    "s4le" => Signed(4, Little)
    "s4be" => Signed(4, Big)
    "f4" => Float32(default_endian(endian, path))
    "f4le" => Float32(Little)
    "f4be" => Float32(Big)
    name if type_names.contains(name) => Nested(name)
    _ => invalid(path, "unknown or unsupported type '\{type_name}'")
  }
}

///|
fn parse_contents(value : @yaml.Yaml, path : String) -> Bytes raise SchemaError {
  let bytes = match value {
    @yaml.String(text) => @utf8.encode(text[:])
    @yaml.Array(parts) => {
      let bytes : Array[Byte] = []
      for i, part in parts {
        match part {
          @yaml.Integer(n) if n >= 0L && n <= 255L => bytes.push(n.to_byte())
          @yaml.String(text) => bytes.append(@utf8.encode(text[:]).to_array())
          _ =>
            invalid(
              "\{path}[\{i}]",
              "expected a byte (0..255) or a UTF-8 string",
            )
        }
      }
      Bytes::from_array(bytes[:])
    }
    _ => invalid(path, "expected a UTF-8 string or an array")
  }
  guard !bytes.is_empty() else { invalid(path, "signature cannot be empty") }
  bytes
}

///|
fn constraint_integer(
  value : @yaml.Yaml,
  path : String,
) -> Int64 raise SchemaError {
  match value {
    @yaml.Integer(integer) => integer
    _ => invalid(path, "expected an integer constant")
  }
}

///|
fn parse_scalar_check(
  value : @yaml.Yaml,
  kind : FieldKind,
  path : String,
) -> ScalarCheck raise SchemaError {
  let (width, signed) = match kind {
    Unsigned(width, _) => (width, false)
    Signed(width, _) => (width, true)
    _ => invalid(path, "only scalar integers up to 32 bits support 'valid'")
  }
  let bits = width.to_int() * 8
  let limit = 1L << (if signed { bits - 1 } else { bits })
  let type_min = if signed { -limit } else { 0L }
  let type_max = limit - 1L
  let (minimum, maximum) = match value {
    @yaml.Map(keys) => {
      check_keys(keys, ["eq", "min", "max"], path)
      match (keys.get("eq"), keys.get("min"), keys.get("max")) {
        (Some(eq), None, None) => {
          let exact = constraint_integer(eq, path + ".eq")
          (exact, exact)
        }
        (None, lower, upper) if lower is Some(_) || upper is Some(_) => {
          let minimum = match lower {
            Some(value) => constraint_integer(value, path + ".min")
            None => type_min
          }
          let maximum = match upper {
            Some(value) => constraint_integer(value, path + ".max")
            None => type_max
          }
          (minimum, maximum)
        }
        _ => invalid(path, "expected 'eq' or at least one of 'min' and 'max'")
      }
    }
    value => {
      let exact = constraint_integer(value, path)
      (exact, exact)
    }
  }
  guard minimum <= maximum else { invalid(path, "minimum exceeds maximum") }
  guard minimum >= type_min && maximum <= type_max else {
    invalid(path, "constraint is outside the integer field's range")
  }
  { width, minimum, maximum, }
}

///|
fn parse_field(
  value : @yaml.Yaml,
  earlier : Map[String, Field],
  endian : Endian?,
  type_names : Array[String],
  path : String,
) -> Field raise SchemaError {
  let field = as_mapping(value, path)
  check_keys(
    field,
    [
      "id", "type", "size", "contents", "valid", "repeat", "repeat-expr", "doc",
      "doc-ref",
    ],
    path,
  )
  let name = as_string(get_required(field, "id", path), path + ".id")
  check_identifier(name, path + ".id")
  guard !is_moonbit_keyword(name) else {
    invalid(path + ".id", "field name is a MoonBit keyword")
  }
  guard !earlier.contains(name) else {
    invalid(path + ".id", "duplicate field '\{name}'")
  }
  let kind = match
    (field.get("type"), field.get("size"), field.get("contents")) {
    (Some(type_name), None, None) =>
      parse_kind(
        as_string(type_name, path + ".type"),
        endian,
        type_names,
        path + ".type",
      )
    (None, Some(size), None) =>
      RawBytes(parse_length(size, earlier, path + ".size"))
    (None, None, Some(contents)) =>
      Contents(parse_contents(contents, path + ".contents"))
    _ => invalid(path, "expected exactly one of 'type', 'size' or 'contents'")
  }
  let count = match (field.get("repeat"), field.get("repeat-expr")) {
    (None, None) => None
    (Some(@yaml.String("expr")), Some(count)) =>
      Some(parse_length(count, earlier, path + ".repeat-expr"))
    _ =>
      invalid(
        path + ".repeat",
        "only repeat: expr with repeat-expr is supported",
      )
  }
  let validation = match field.get("valid") {
    None => None
    Some(value) => {
      guard count is None else {
        invalid(path + ".valid", "only scalar fields support 'valid'")
      }
      Some(parse_scalar_check(value, kind, path + ".valid"))
    }
  }
  { name, kind, count, validation, }
}

///|
fn parse_record(
  name : String,
  value : @yaml.Yaml,
  endian : Endian?,
  type_names : Array[String],
  path : String,
) -> RecordDef raise SchemaError {
  guard value is @yaml.Array(sequence) else {
    invalid(path, "expected a sequence")
  }
  guard !sequence.is_empty() else {
    invalid(path, "expected at least one field")
  }
  let earlier : Map[String, Field] = Map([])
  let fields = []
  for i, item in sequence {
    let field = parse_field(item, earlier, endian, type_names, "\{path}[\{i}]")
    earlier[field.name] = field
    fields.push(field)
  }
  { name, fields, }
}

///|
fn collect_records(
  record : RecordDef,
  definitions : Map[String, RecordDef],
  active : Array[String],
  collected : Map[String, RecordDef],
) -> Unit raise SchemaError {
  for field in record.fields {
    if field.kind is Nested(name) {
      guard !active.contains(name) else {
        invalid("types.\{name}", "recursive type reference")
      }
      if !collected.contains(name) {
        let nested = definitions[name]
        active.push(name)
        collect_records(nested, definitions, active, collected)
        ignore(active.pop())
        collected[name] = nested
      }
    }
  }
}

///|
fn load_schema(source : String) -> Schema raise SchemaError {
  let documents = @yaml.Yaml::load_from_string(source[:]) catch {
    @yaml.YamlError(mark~, info~) => invalid("YAML line \{mark.line + 1}", info)
  }
  guard documents is [document] else {
    invalid("schema", "expected one YAML document")
  }
  let root = as_mapping(document, "schema")
  check_keys(root, ["meta", "seq", "types", "doc", "doc-ref"], "schema")
  let meta = as_mapping(get_required(root, "meta", "schema"), "meta")
  check_keys(
    meta,
    [
      "id", "endian", "title", "application", "file-extension", "xref", "license",
      "tags", "ks-version",
    ],
    "meta",
  )
  let id = as_string(get_required(meta, "id", "schema.meta"), "meta.id")
  check_identifier(id, "meta.id")
  let endian = match meta.get("endian") {
    None => None
    Some(@yaml.String("le")) => Some(Little)
    Some(@yaml.String("be")) => Some(Big)
    _ => invalid("meta.endian", "expected 'le' or 'be'")
  }
  let types = match root.get("types") {
    Some(value) => as_mapping(value, "types")
    None => Map([])
  }
  guard types.length() <= 64 else {
    invalid("types", "at most 64 nested type definitions are supported")
  }
  let names = types.keys().collect()
  let definitions : Map[String, RecordDef] = Map([])
  for name, value in types {
    let path = "types.\{name}"
    check_identifier(name, path)
    let mapping = as_mapping(value, path)
    check_keys(mapping, ["seq", "doc", "doc-ref"], path)
    definitions[name] = parse_record(
      name,
      get_required(mapping, "seq", path),
      endian,
      names,
      path + ".seq",
    )
  }
  let root_record = parse_record(
    id,
    get_required(root, "seq", "schema"),
    endian,
    names,
    "seq",
  )
  let reachable : Map[String, RecordDef] = Map([])
  collect_records(root_record, definitions, [], reachable)
  { root: root_record, records: reachable.values().collect(), }
}
