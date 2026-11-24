///|
priv enum ByteOrder {
  ChooseOrder(Expr, Array[(Expr, Endian)], Endian?)
  Inherited(String)
}

///|
fn byte_endian(raw : @yaml.Yaml?, path : String) -> Endian? raise SchemaError {
  match raw {
    Some(@yaml.Map(_)) => Some(SelectedOrder)
    _ => schema_endian(raw, path)
  }
}

///|
fn parse_byte_order(
  options : Map[String, @yaml.Yaml],
  path : String,
) -> ByteOrder raise SchemaError {
  check_keys(options, ["switch-on", "cases"], path)
  let selector = parse_expression(
    get_required(options, "switch-on", path),
    path,
  )
  let raw = as_mapping(get_required(options, "cases", path), path + ".cases")
  let cases = []
  let mut fallback = None
  let keys = raw.keys().collect()
  keys.sort()
  for key in keys {
    let endian = schema_endian(Some(raw[key]), path + ".cases").unwrap()
    if key == "_" {
      fallback = Some(endian)
    } else {
      let tag = parse_expression(@yaml.String(key), path + ".cases")
      guard tag is Integer(_) ||
        tag is Unary("-", Integer(_)) ||
        tag is Text(_) ||
        tag is Boolean(_) ||
        tag is EnumLiteral(_, _) ||
        tag is ByteLiteral(_) else {
        invalid(path, "byte order case must be a scalar or byte-array constant")
      }
      cases.push((tag, endian))
    }
  }
  ChooseOrder(selector, cases, fallback)
}

///|
fn byte_literal_code(bytes : Bytes) -> String {
  let values = bytes.to_array().map(fn(b) { b.to_int().to_string() })
  "Bytes::from_array([" + values.join(", ") + "])[:]"
}

///|
fn select_byte_order(
  output : StringBuilder,
  graph : ContextGraph,
  owner : String,
  root : String,
) -> Unit raise SchemaError {
  let choice = match graph.byte_orders.get(owner) {
    None => return
    Some(Inherited(declaration)) => {
      guard graph.tags.get(declaration) is Some(tag) else {
        invalid(owner, "declaring byte order type is not reachable")
      }
      "arena.inherit_order(parent, \{tag}, path, reader.offset)"
    }
    Some(ChooseOrder(selector, cases, fallback)) => {
      let scope = context_scope(
        graph,
        owner,
        owner + ".meta.endian",
        earlier=Some(0),
      )
      let select = context_expression_code(scope, selector, root, "path")
      let choice = StringBuilder()
      choice.write_string("{ let ksy_order = \{select}; ")
      if cases.is_empty() {
        choice.write_string("ignore(ksy_order); ")
      }
      for (tag, order) in cases {
        let tag = context_expression_code(scope, tag, root, "path")
        choice.write_string(
          "if ksy_order == \{tag} { \{endian_flag(order)} } else ",
        )
      }
      let unselected = match fallback {
        Some(order) => endian_flag(order)
        None => context_error(root, "path", message="undecided byte order")
      }
      if cases.is_empty() {
        choice.write_string("\{unselected} }")
      } else {
        choice.write_string("{ \{unselected} } }")
      }
      choice.to_string()
    }
  }
  output.write_string(
    "  arena.frames[context].unwrap().little_endian = \{choice}\n",
  )
}

///|
fn emit_endian_inheritance(
  output : StringBuilder,
  root : String,
  graph : ContextGraph,
) -> Unit {
  if !graph.byte_orders.values().any(fn(order) { order is Inherited(_) }) {
    return
  }
  let code =
    #|///|
    #|fn __ROOT__Arena::inherit_order(self : __ROOT__Arena, parent : Int, tag : Int, field : String, offset : Int) -> Bool raise __ROOT__ParseError {
    #|  let mut index = parent
    #|  while index >= 0 {
    #|    let frame = self.frame(index, field)
    #|    if frame.tag == tag { return frame.little_endian }
    #|    index = frame.parent
    #|  }
    #|  raise __ROOT__ContextError(field~, offset~, message="inherited byte order is unavailable")
    #|}
    #|
  write_reader_block(output, code, root)
}
