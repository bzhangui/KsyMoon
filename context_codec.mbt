///|
fn context_error(
  root : String,
  path : String,
  reader~ : String = "reader",
  message~ : String = "value is unavailable or has the wrong type",
) -> String {
  "raise \{root}ContextError(field=\{path}, offset=\{reader}.offset, message=\{message.escape()})"
}

///|
fn context_unpack_expression(
  kind : ExprType,
  value : String,
  root : String,
  path : String,
  reader : String,
) -> String {
  let variant = match kind {
    Integer => "Number"
    Boolean => "Flag"
    Text => "StringValue"
    Stream => "Source"
    Object(_) => "ObjectId"
    _ => abort("unsupported scalar expression type")
  }
  "(match \{value} { \{root}Value::\{variant}(value) => value; _ => { \{context_error(root, path, reader~)} } })"
}

///|
fn context_value_code(
  scope : ContextScope,
  expression : Expr,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  match expression {
    Reference("_root") => "\{root}Value::ObjectId(0)"
    Reference("_parent") =>
      "\{root}Value::ObjectId(context).attribute(arena, \"_parent\", \{path})"
    Reference("_io") => "\{root}Value::Source(\{owner_reader})"
    Reference("_index") => "\{root}Value::Number(index.to_int64())"
    Reference("_") => context_pack_kind(scope.item.unwrap(), "item", root)
    Reference(name) if name.has_prefix("_.") =>
      "\{context_pack_kind(scope.item.unwrap(), "item", root)}.attribute(arena, \{name[2:].escape()}, \{path})"
    Reference(name) => "arena.attribute(context, \{name.escape()}, \{path})"
    Member(base, name) =>
      "\{context_value_code(scope, base, root, path, owner_reader)}.attribute(arena, \{name.escape()}, \{path})"
    Index(base, index) =>
      "\{context_value_code(scope, base, root, path, owner_reader)}.element(\{context_expression_code(scope, index, root, path, owner_reader~)}, \{path}, \{owner_reader}.offset)"
    Choose(condition, yes, no) =>
      "(if \{context_expression_code(scope, condition, root, path, owner_reader~)} { \{context_value_code(scope, yes, root, path, owner_reader)} } else { \{context_value_code(scope, no, root, path, owner_reader)} })"
    _ => {
      let value = context_expression_code(
        scope,
        expression,
        root,
        path,
        owner_reader~,
      )
      let variant = match context_expression_type(scope, expression) {
        Integer => "Number"
        Boolean => "Flag"
        Text => "StringValue"
        _ => invalid(scope.path, "value expression type awaits implementation")
      }
      "\{root}Value::\{variant}(\{value})"
    }
  }
}

///|
fn context_expression_code(
  scope : ContextScope,
  expression : Expr,
  root : String,
  path : String,
  owner_reader~ : String = "reader",
) -> String raise SchemaError {
  let kind = context_expression_type(scope, expression)
  match expression {
    Reference(_) | Member(_, _) | Index(_, _) =>
      context_unpack_expression(
        kind,
        context_value_code(scope, expression, root, path, owner_reader),
        root,
        path,
        owner_reader,
      )
    Choose(condition, yes, no) =>
      "(if \{context_expression_code(scope, condition, root, path, owner_reader~)} { \{context_expression_code(scope, yes, root, path, owner_reader~)} } else { \{context_expression_code(scope, no, root, path, owner_reader~)} })"
    _ => {
      let references : Map[String, String] = Map([])
      let navigation : Array[(Expr, String)] = []
      context_expression_parts(
        scope, expression, root, path, owner_reader, references, navigation,
      )
      expression_code(
        expression,
        fn(name) { references[name] },
        path,
        navigation=Some(fn(value) {
          navigation.iter().find_first(fn(pair) { pair.0 == value }).unwrap().1
        }),
        stream_reader=owner_reader,
      )
    }
  }
}

///|
fn context_pack_kind(
  kind : FieldKind,
  value : String,
  root : String,
  bounded~ : Bool = false,
) -> String {
  match kind {
    Unsigned(_, _) | Signed(_, _) => "\{root}Value::Number(\{value}.to_int64())"
    Unsigned64(_) => "\{root}Value::Wide(\{value})"
    Float32(_) => "\{root}Value::FloatValue(\{value})"
    Text(_, _) => "\{root}Value::StringValue(\{value})"
    ByteField(_) | Contents(_) => "\{root}Value::Binary(\{value})"
    Bounded(inner, _) => context_pack_kind(inner, value, root, bounded=true)
    Nested(_) => "\{root}Value::ObjectId(\{value}._ksy_context)"
    Switch(_, _, cases, fallback) => {
      let output = StringBuilder()
      output.write_string("(match \{value} { ")
      for index, (_, child) in cases {
        output.write_string(
          "Case\{index}(value) => \{root}Value::Selected(\{index}, \{context_pack_kind(child, "value", root)}); ",
        )
      }
      if fallback is Some(child) {
        output.write_string(
          "Default(value) => \{root}Value::Selected(-1, \{context_pack_kind(child, "value", root)}); ",
        )
      } else {
        // Only one unknown variant is emitted, depending on whether this switch is bounded.
        output.write_string(
          if bounded {
            "Raw(value) => \{root}Value::Selected(-3, \{root}Value::Binary(value)); "
          } else {
            "Unknown => \{root}Value::Selected(-2, \{root}Value::Absent); "
          },
        )
      }
      output.write_string("})")
      output.to_string()
    }
  }
}

///|
fn context_pack_field(field : Field, value : String, root : String) -> String {
  let element = fn(value) { context_pack_kind(field.kind, value, root) }
  let pack = fn(value) {
    if field.count is Some(_) {
      "\{root}Value::Items(\{value}.map(fn(item) { \{element("item")} }))"
    } else {
      element(value)
    }
  }
  if field.condition is Some(_) {
    "(match \{value} { Some(value) => \{pack("value")}; None => \{root}Value::Absent })"
  } else {
    pack(value)
  }
}

///|
fn context_unpack_kind(
  kind : FieldKind,
  value : String,
  root : String,
  path : String,
  reader~ : String = "reader",
  bounded~ : Bool = false,
) -> String {
  let error = context_error(root, path, reader~)
  let scalar = fn(variant, result) {
    "(match \{value} { \{root}Value::\{variant}(value) => \{result}; _ => { \{error} } })"
  }
  match kind {
    Unsigned(_, _) => scalar("Number", "value.to_int().reinterpret_as_uint()")
    Signed(_, _) => scalar("Number", "value.to_int()")
    Unsigned64(_) => scalar("Wide", "value")
    Float32(_) => scalar("FloatValue", "value")
    Text(_, _) => scalar("StringValue", "value")
    ByteField(_) | Contents(_) => scalar("Binary", "value")
    Nested(name) =>
      scalar("ObjectId", "hydrate_\{root}_\{name}(arena, value, \{path})")
    Bounded(inner, _) =>
      context_unpack_kind(inner, value, root, path, reader~, bounded=true)
    Switch(name, _, cases, fallback) => {
      let output = StringBuilder()
      output.write_string(
        "(match \{value} { \{root}Value::Selected(tag, payload) => match tag { ",
      )
      for index, (_, child) in cases {
        output.write_string(
          "\{index} => \{root}_switch_\{name}::Case\{index}(\{context_unpack_kind(child, "payload", root, path, reader~)}); ",
        )
      }
      if fallback is Some(child) {
        output.write_string(
          "_ => \{root}_switch_\{name}::Default(\{context_unpack_kind(child, "payload", root, path, reader~)}); ",
        )
      } else {
        output.write_string(
          if bounded {
            "-3 => \{root}_switch_\{name}::Raw((match payload { \{root}Value::Binary(bytes) => bytes; _ => { \{error} } })); _ => { \{error} }; "
          } else {
            "_ => \{root}_switch_\{name}::Unknown; "
          },
        )
      }
      output.write_string("}; _ => { \{error} } })")
      output.to_string()
    }
  }
}

///|
fn context_unpack_field(
  field : Field,
  value : String,
  root : String,
  path : String,
  reader~ : String = "reader",
) -> String {
  let unpack = fn(value) {
    if field.count is Some(_) {
      "(match \{value} { \{root}Value::Items(items) => items.map(fn(item) raise \{root}ParseError { \{context_unpack_kind(field.kind, "item", root, path, reader~)} }); _ => { \{context_error(root, path, reader~)} } })"
    } else {
      context_unpack_kind(field.kind, value, root, path, reader~)
    }
  }
  if field.condition is Some(_) {
    "(match \{value} { \{root}Value::Absent => None; value => Some(\{unpack("value")}) })"
  } else {
    unpack(value)
  }
}

///|
fn context_instance_result(
  graph : ContextGraph,
  owner : String,
  instance : Instance,
  root : String,
) -> String raise SchemaError {
  let result = match instance.kind {
    Parsed(field, _) => field_result_type(field, root)
    Value(expression) =>
      match
        context_expression_type(
          context_scope(graph, owner, instance.name),
          expression,
        ) {
        Integer => "Int64"
        Boolean => "Bool"
        Text => "String"
        _ => invalid(instance.name, "value instance type awaits implementation")
      }
  }
  if instance.condition is Some(_) {
    "Option[\{result}]"
  } else {
    result
  }
}

///|
fn context_has_reference(expression : Expr) -> Bool {
  match expression {
    Reference(_) | Member(_, _) | Index(_, _) => true
    Unary(_, child) => context_has_reference(child)
    Binary(_, a, b) => context_has_reference(a) || context_has_reference(b)
    Choose(a, b, c) =>
      context_has_reference(a) ||
      context_has_reference(b) ||
      context_has_reference(c)
    _ => false
  }
}

///|
fn context_read_effects(schema : Schema) -> Map[String, Bool] {
  let graph = context_graph(schema)
  let effects : Map[String, Bool] = Map([])
  for owner, _ in graph.records {
    effects[owner] = false
  }
  for _ in 0..<graph.records.length() {
    for owner, record in graph.records {
      effects[owner] = record.fields
        .iter()
        .any(fn(field) {
          field.count is Some(_) ||
          field.validation is Some(_) ||
          (
            field.condition is Some(value) &&
            (context_has_reference(value) || expression_arithmetic(value))
          ) ||
          context_kind_raises(field.kind, effects)
        })
    }
  }
  effects
}

///|
fn context_kind_raises(kind : FieldKind, effects : Map[String, Bool]) -> Bool {
  match kind {
    Nested(name) => effects[name]
    Switch(_, expression, cases, fallback) =>
      (
        !cases.is_empty() &&
        (context_has_reference(expression) || expression_arithmetic(expression))
      ) ||
      cases.iter().any(fn(item) { context_kind_raises(item.1, effects) }) ||
      (fallback is Some(child) && context_kind_raises(child, effects))
    _ => true
  }
}

///|
fn context_expression_parts(
  scope : ContextScope,
  expression : Expr,
  root : String,
  path : String,
  reader : String,
  references : Map[String, String],
  navigation : Array[(Expr, String)],
) -> Unit raise SchemaError {
  match expression {
    Reference(name) =>
      references[name] = context_unpack_expression(
        context_expression_type(scope, expression),
        context_value_code(scope, expression, root, path, reader),
        root,
        path,
        reader,
      )
    Member(_, _) | Index(_, _) =>
      navigation.push(
        (
          expression,
          context_unpack_expression(
            context_expression_type(scope, expression),
            context_value_code(scope, expression, root, path, reader),
            root,
            path,
            reader,
          ),
        ),
      )
    Unary(_, child) =>
      context_expression_parts(
        scope, child, root, path, reader, references, navigation,
      )
    Binary(_, left, right) => {
      context_expression_parts(
        scope, left, root, path, reader, references, navigation,
      )
      context_expression_parts(
        scope, right, root, path, reader, references, navigation,
      )
    }
    Choose(a, b, c) => {
      context_expression_parts(
        scope, a, root, path, reader, references, navigation,
      )
      context_expression_parts(
        scope, b, root, path, reader, references, navigation,
      )
      context_expression_parts(
        scope, c, root, path, reader, references, navigation,
      )
    }
    _ => ()
  }
}

///|
fn context_kind_expressions(kind : FieldKind) -> Array[Expr] {
  let expressions = []
  for kind in walk_kinds(kind) {
    match kind {
      ByteField(options) | Text(options, _) | Bounded(_, options) =>
        if options.length is Some(Calculated(value)) {
          expressions.push(value)
        }
      Switch(_, selector, cases, _) => {
        expressions.push(selector)
        for (tag, _) in cases {
          expressions.push(tag)
        }
      }
      _ => ()
    }
  }
  expressions
}

///|
fn context_field_evaluator(
  scope : ContextScope,
  field : Field,
  root : String,
  path : String,
  reader~ : String = "reader",
) -> ((Expr) -> String) raise SchemaError {
  let expressions = context_kind_expressions(field.kind)
  if field.condition is Some(value) {
    expressions.push(value)
  }
  match field.count {
    Some(Times(Calculated(value))) | Some(Until(value)) =>
      expressions.push(value)
    _ => ()
  }
  let codes = expressions.map(fn(value) raise SchemaError {
    (
      value,
      context_expression_code(scope, value, root, path, owner_reader=reader),
    )
  })
  fn(value) { codes.iter().find_first(fn(pair) { pair.0 == value }).unwrap().1 }
}
