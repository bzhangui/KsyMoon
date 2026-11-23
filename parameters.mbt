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
    check_keys(spec, ["id", "type", "doc", "doc-ref"], path)
    let name = as_string(get_required(spec, "id", path), path + ".id")
    check_identifier(name, path + ".id")
    guard !names.contains(name) && !is_moonbit_keyword(name) else {
      invalid(path, "parameter name is duplicated or conflicts with MoonBit")
    }
    names[name] = true
    let type_name = as_string(get_required(spec, "type", path), path + ".type")
    let (kind, range) = match type_name {
      "bool" => (ExprType::Boolean, None)
      "str" => (ExprType::Text, None)
      "u1" => (ExprType::Integer, Some((0L, 255L)))
      "u2" => (ExprType::Integer, Some((0L, 65535L)))
      "u4" => (ExprType::Integer, Some((0L, 4294967295L)))
      "s1" => (ExprType::Integer, Some((-128L, 127L)))
      "s2" => (ExprType::Integer, Some((-32768L, 32767L)))
      "s4" => (ExprType::Integer, Some((-2147483648L, 2147483647L)))
      "s8" => (ExprType::Integer, None)
      _ =>
        invalid(
          path + ".type",
          "unsupported parameter type '" + type_name + "'",
        )
    }
    parameters.push({ name, kind, range, })
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
fn parameter_type(parameter : Parameter) -> String {
  match parameter.kind {
    Boolean => "Bool"
    Text => "String"
    _ => "Int64"
  }
}

///|
fn parameter_signature(parameters : Array[Parameter]) -> String {
  parameters
  .map(fn(p) { ", arg_" + p.name + " : " + parameter_type(p) })
  .join("")
}

///|
fn parameter_arguments(parameters : Array[Parameter]) -> String {
  parameters.map(fn(p) { ", arg_" + p.name }).join("")
}

///|
fn parameter_pack(parameter : Parameter, root : String) -> String {
  let variant = match parameter.kind {
    Boolean => "Flag"
    Text => "StringValue"
    _ => "Number"
  }
  "\{root}Value::\{variant}(arg_\{parameter.name})"
}
