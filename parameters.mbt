///|
priv struct Parameter {
  name : String
  kind : ExprType
  range : (Int64, Int64)?
}

///|
fn parse_parameters(
  value : @yaml.Yaml?,
  path : String,
  visible : Map[String, String],
  enums : Map[String, String],
  names_in_schema : Array[String],
) -> Array[Parameter] raise SchemaError {
  let parameters = []
  let names = Map([])
  guard value is Some(value) else { return parameters }
  guard value is @yaml.Array(items) && items.length() <= 32 else {
    invalid(path, "expected a list of at most 32 parameters")
  }
  for index, item in items {
    let path = path + "[" + index.to_string() + "]"
    let spec = as_mapping(item, path)
    check_keys(spec, ["id", "type", "enum", "doc", "doc-ref"], path)
    let name = as_string(get_required(spec, "id", path), path + ".id")
    check_identifier(name, path + ".id")
    guard !names.contains(name) && !is_moonbit_keyword(name) else {
      invalid(path, "parameter name is duplicated or conflicts with MoonBit")
    }
    names[name] = true
    let type_name = as_string(get_required(spec, "type", path), path + ".type")
    let sequence = type_name.has_suffix("[]")
    let base = if sequence {
      type_name[:type_name.length() - 2].to_owned()
    } else {
      type_name
    }
    let (kind, range) = match base {
      "bool" | "b1" => (ExprType::Boolean, None)
      "str" => (ExprType::Text, None)
      "bytes" => (ExprType::Bytes, None)
      "io" => (ExprType::Stream, None)
      "struct" => (ExprType::Object(["@any"]), None)
      "u1" => (ExprType::Integer, Some((0L, 255L)))
      "u2" => (ExprType::Integer, Some((0L, 65535L)))
      "u4" => (ExprType::Integer, Some((0L, 4294967295L)))
      "s1" => (ExprType::Integer, Some((-128L, 127L)))
      "s2" => (ExprType::Integer, Some((-32768L, 32767L)))
      "s4" => (ExprType::Integer, Some((-2147483648L, 2147483647L)))
      "s8" => (ExprType::Integer, None)
      "u8" => (ExprType::WideInteger, None)
      "f4" | "f8" => (ExprType::Real, None)
      _ => {
        let target = scoped_type_name(base, visible)
        guard visible.contains(base) || (base.contains("::") && target != base) else {
          invalid(
            path + ".type",
            "unsupported parameter type '" + type_name + "'",
          )
        }
        guard names_in_schema.contains(target) else {
          invalid(
            path + ".type",
            "unknown parameter record '" + type_name + "'",
          )
        }
        (ExprType::Object([target]), None)
      }
    }
    let kind = if spec.get("enum") is Some(raw) {
      guard kind == Integer else {
        invalid(path + ".enum", "enum parameter requires an integer type")
      }
      ExprType::Enum(
        scoped_enum_name(as_string(raw, path + ".enum"), visible, enums),
      )
    } else {
      kind
    }
    parameters.push({
      name,
      kind: if sequence {
        Sequence(kind)
      } else {
        kind
      },
      range,
    })
  }
  parameters
}

///|
fn parse_type_application(
  source : String,
  path : String,
) -> Array[Expr] raise SchemaError {
  let parser : ExprParser = {
    tokens: expression_tokens(source, path),
    path,
    index: 0,
    depth: 0,
  }
  let arguments = []
  if parser.peek() != ")" {
    while true {
      guard arguments.length() < 32 else {
        invalid(path, "at most 32 type arguments are supported")
      }
      let value = parser.parse(1)
      check_expression_depth(value, 0, path)
      arguments.push(value)
      if parser.peek() != "," {
        break
      }
      parser.index += 1
    }
  }
  guard parser.peek() == ")" && parser.index + 1 == parser.tokens.length() else {
    invalid(path, "expected ')' after the type arguments")
  }
  arguments
}

///|
fn parameter_type(kind : ExprType, root : String) -> String {
  match kind {
    Boolean => "Bool"
    Text => "String"
    Integer | Enum(_) => "Int64"
    WideInteger => "UInt64"
    Real => "Double"
    Stream => root + "Reader"
    Bytes => "BytesView"
    Object(_) => "Int"
    Sequence(element) => "Array[" + parameter_type(element, root) + "]"
  }
}

///|
fn parameter_signature(parameters : Array[Parameter], root : String) -> String {
  parameters
  .map(fn(p) { ", arg_" + p.name + " : " + parameter_type(p.kind, root) })
  .join("")
}

///|
fn parameter_result_type(kind : ExprType, root : String) -> String {
  match kind {
    Enum(name) => generated_enum_type(root, name)
    Stream => root + "Stream"
    Object(_) => root + "ObjectRef"
    Sequence(element) => "Array[" + parameter_result_type(element, root) + "]"
    _ => parameter_type(kind, root)
  }
}

///|
fn parameter_result(kind : ExprType, value : String, root : String) -> String {
  match kind {
    Enum(name) => "\{generated_enum_type(root, name)}::from_code(\{value})"
    Stream => "\{root}Stream::{ reader: \{value} }"
    Object(_) => "\{root}ObjectRef::{ arena, context: \{value} }"
    Sequence(element) if parameter_result_type(element, root) !=
      parameter_type(element, root) =>
      "(\{value}).map(fn(item) { \{parameter_result(element, "item", root)} })"
    _ => value
  }
}

///|
fn parameter_input(kind : ExprType, value : String, root : String) -> String {
  match kind {
    Enum(_) => value + ".to_i()"
    Stream => value + ".reader"
    Object(_) => value + ".context"
    Sequence(element) if parameter_result_type(element, root) !=
      parameter_type(element, root) =>
      "\{value}.map(fn(item) { \{parameter_input(element, "item", root)} })"
    _ => value
  }
}

///|
fn parameter_is_stream(kind : ExprType) -> Bool {
  match kind {
    Stream => true
    Sequence(element) => parameter_is_stream(element)
    _ => false
  }
}

///|
fn parameter_is_object(kind : ExprType) -> Bool {
  match kind {
    Object(_) => true
    Sequence(element) => parameter_is_object(element)
    _ => false
  }
}

///|
fn parameter_pack(kind : ExprType, value : String, root : String) -> String {
  let variant = match kind {
    Boolean => "Flag"
    Text => "StringValue"
    Integer | Enum(_) => "Number"
    WideInteger => "Wide"
    Real => "RealValue"
    Stream => "Source"
    Bytes => "Binary"
    Object(_) => "ObjectId"
    Sequence(element) => {
      let item = parameter_pack(element, "item", root)
      return "\{root}Value::Items(\{value}.map(fn(item) { \{item} }))"
    }
  }
  "\{root}Value::\{variant}(\{value})"
}

///|
fn parameter_kind_matches(actual : ExprType, expected : ExprType) -> Bool {
  match (actual, expected) {
    (Sequence(a), Sequence(b)) => parameter_kind_matches(a, b)
    (Object(_), Object(["@any"])) => true
    _ => actual == expected
  }
}

///|
fn integer_array_cast(name : String) -> ExprType? {
  guard name.has_suffix("[]") else { return None }
  let base = name[:name.length() - 2].to_owned()
  integer_cast(base).map(fn(_) {
    if base == "u8" {
      WideInteger
    } else {
      Integer
    }
  })
}
