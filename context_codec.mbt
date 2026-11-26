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
  if kind is Sequence(element) {
    let item = context_unpack_expression(element, "item", root, path, reader)
    let error = context_error(root, path, reader~)
    return "(match \{value} { \{root}Value::Items(items) => items.map(fn(item) raise \{root}ParseError { \{item} }); _ => { \{error} } })"
  }
  let variant = match kind {
    Integer | Enum(_) => "Number"
    WideInteger => "Wide"
    Boolean => "Flag"
    Text => "StringValue"
    Bytes => "Binary"
    Real => "RealValue"
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
  let value = context_raw_value_code(
    scope, expression, root, path, owner_reader,
  )
  if context_may_read_selected(scope, expression) &&
    context_expression_type(scope, expression)
    is (Integer | WideInteger | Boolean | Text | Bytes | Real | Enum(_)) {
    "(match \{value} { \{root}Value::Selected(_, payload) => payload; value => value })"
  } else {
    value
  }
}

///|
fn context_may_read_selected(
  scope : ContextScope,
  expression : Expr,
) -> Bool raise SchemaError {
  let find = fn(owners : Array[String], name : String) {
    owners
    .iter()
    .any(fn(owner) {
      guard scope.graph.records.get(owner) is Some(record) else { return false }
      record.fields
      .iter()
      .any(fn(field) { field.name == name && is_switch_value(field.kind) }) ||
      record.instances
      .iter()
      .any(fn(instance) {
        instance.name == name &&
        instance.kind is Parsed(field, _) &&
        is_switch_value(field.kind)
      })
    })
  }
  match expression {
    Reference(name) if name == "_" || scope.validated_field == Some(name) =>
      scope.item is Some(kind) && is_switch_value(kind)
    Reference(name) if name.has_prefix("_.") => {
      guard scope.item is Some(kind) &&
        context_kind_type(kind, scope.path) is Object(owners) else {
        return false
      }
      find(owners, name[2:].to_owned())
    }
    Reference(name) => find([scope.owner], name)
    Member(base, name) =>
      context_expression_type(scope, base) is Object(owners) &&
      find(owners, name)
    Index(base, _) => context_may_read_selected(scope, base)
    _ => false
  }
}

///|
fn is_switch_value(kind : FieldKind) -> Bool {
  kind is (Switch(_, _, _, _) | Bounded(Switch(_, _, _, _), _))
}

///|
fn context_raw_value_code(
  scope : ContextScope,
  expression : Expr,
  root : String,
  path : String,
  owner_reader : String,
) -> String raise SchemaError {
  match expression {
    Member(_, "_sizeof" | "_bitsizeof")
    | Reference("_sizeof" | "_bitsizeof")
    | TypeSize(_, _) =>
      "\{root}Value::Number(\{size_expression(scope, expression)}L)"
    ArrayLiteral(values) => {
      let kind = context_expression_type(scope, expression)
      let items = values.map(fn(value) raise SchemaError {
        if kind == Sequence(Real) &&
          context_expression_type(scope, value) == Integer {
          let code = context_expression_code(
            scope,
            value,
            root,
            path,
            owner_reader~,
          )
          "\{root}Value::RealValue((\{code}).to_double())"
        } else {
          context_value_code(scope, value, root, path, owner_reader)
        }
      })
      "\{root}Value::Items([\{items.join(", ")}])"
    }
    Reference("_root") if scope.graph.module_roots.is_empty() &&
      !scope.graph.object_refs => "\{root}Value::ObjectId(0)"
    Reference("_parent") =>
      "\{root}Value::ObjectId(context).attribute(arena, \"_parent\", \{path})"
    Reference("_io") => "\{root}Value::Source(\{owner_reader})"
    Reference("_index") => "\{root}Value::Number(index.to_int64())"
    Reference(name) if name == "_" || scope.validated_field == Some(name) =>
      context_pack_kind(scope.item.unwrap(), "item", root)
    Reference(name) if name.has_prefix("_.") =>
      "\{context_pack_kind(scope.item.unwrap(), "item", root)}.attribute(arena, \{name[2:].escape()}, \{path})"
    Reference(name) =>
      "\{root}Value::ObjectId(context).attribute(arena, \{name.escape()}, \{path})"
    Cast(base, target) if integer_array_cast(target) is Some(_) =>
      context_value_code(scope, base, root, path, owner_reader)
    Cast(base, target) if integer_cast(target) is Some((bits, signed)) => {
      let code = context_expression_code(scope, base, root, path, owner_reader~)
      let value = if context_expression_type(scope, base) == WideInteger {
        code + ".reinterpret_as_int64()"
      } else {
        code
      }
      if bits == 64 {
        if signed {
          "\{root}Value::Number(\{value})"
        } else {
          "\{root}Value::Wide((\{value}).reinterpret_as_uint64())"
        }
      } else {
        let mask = (1L << bits) - 1L
        let narrowed = "(\{value} & \{mask}L)"
        if signed {
          "\{root}Value::Number((\{narrowed} << \{64 - bits}) >> \{64 - bits})"
        } else {
          "\{root}Value::Number(\{narrowed})"
        }
      }
    }
    Cast(base, target) => {
      let name = context_cast_target(scope, target)
      let tag = scope.graph.tags[name]
      let source = context_value_code(scope, base, root, path, owner_reader)
      let error = context_error(
        root,
        path,
        reader=owner_reader,
        message="record is not of type " + target,
      )
      "(match \{source}.object_id() { Some(object) => { guard arena.frame(object, \{path}).tag == \{tag} else { \{error} }; \{root}Value::ObjectId(object) }; None => { \{error} } })"
    }
    Decode(base, encoding) => {
      let value = context_value_code(scope, base, root, path, owner_reader)
      let error = context_error(
        root,
        path,
        reader=owner_reader,
        message="expected bytes for decoding",
      )
      "\{root}Value::StringValue(\{owner_reader}.decode_text((match \{value} { \{root}Value::Binary(bytes) => bytes; _ => { \{error} } }), \{encoding.escape()}, \{path}, \{owner_reader}.offset))"
    }
    EnumLiteral(name, label) => {
      let (_, value) = context_enum_label(scope, name, label)
      "\{root}Value::Number(\{value}L)"
    }
    ToEnum(value, _) =>
      context_value_code(scope, value, root, path, owner_reader)
    Member(base, "size") if context_expression_type(scope, base)
      is (Sequence(_) | Bytes) =>
      "\{context_value_code(scope, base, root, path, owner_reader)}.attribute(arena, \"length\", \{path})"
    Member(base, "to_i") if context_expression_type(scope, base) is Enum(_) =>
      context_value_code(scope, base, root, path, owner_reader)
    Member(base, "length") if context_expression_type(scope, base) == Text =>
      "\{root}Value::Number(\{context_expression_code(scope, base, root, path, owner_reader~)}.to_array().length().to_int64())"
    Substring(_, _, _) =>
      "\{root}Value::StringValue(\{context_expression_code(scope, expression, root, path, owner_reader~)})"
    Member(_, "_in_enum") =>
      "\{root}Value::Flag(\{context_expression_code(scope, expression, root, path, owner_reader~)})"
    Member(base, "to_s") if context_expression_type(scope, base) is Integer =>
      "\{root}Value::StringValue(\{context_expression_code(scope, base, root, path, owner_reader~)}.to_string())"
    Member(base, name) =>
      "\{context_value_code(scope, base, root, path, owner_reader)}.attribute(arena, \{name.escape()}, \{path})"
    Index(base, index) =>
      "\{context_value_code(scope, base, root, path, owner_reader)}.element(arena, \{context_expression_code(scope, index, root, path, owner_reader~)}, \{path}, \{owner_reader}.offset)"
    Choose(_, _, _) if context_expression_type(scope, expression) == Real =>
      "\{root}Value::RealValue(\{context_expression_code(scope, expression, root, path, owner_reader~)})"
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
        Integer | Enum(_) => "Number"
        WideInteger => "Wide"
        Boolean => "Flag"
        Text => "StringValue"
        Bytes => "Binary"
        Real => "RealValue"
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
    Substring(value, start, end) => {
      let value = context_expression_code(
        scope,
        value,
        root,
        path,
        owner_reader~,
      )
      let start = context_expression_code(
        scope,
        start,
        root,
        path,
        owner_reader~,
      )
      let end = context_expression_code(scope, end, root, path, owner_reader~)
      let error = context_error(
        root,
        path,
        reader=owner_reader,
        message="substring index is out of range",
      )
      "{ let chars = (\{value}).to_array(); let begin = \{start}; let end = \{end}; guard begin >= 0L && end >= begin && end <= chars.length().to_int64() else { \{error} }; String::from_array(chars[begin.to_int():end.to_int()]) }"
    }
    Member(base, "_in_enum") => {
      guard context_expression_type(scope, base) is Enum(name) else {
        invalid(scope.path, "in-enum requires an enum field")
      }
      let codes = context_enum(scope, name).labels
        .map(fn(item) { "\{item.0}L" })
        .join(" | ")
      let raw = context_expression_code(scope, base, root, path, owner_reader~)
      "(\{raw} is (\{codes}))"
    }
    Member(_, "_sizeof" | "_bitsizeof")
    | Reference("_sizeof" | "_bitsizeof")
    | TypeSize(_, _) => "\{size_expression(scope, expression)}L"
    Reference(_)
    | Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | Decode(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _)
    | ArrayLiteral(_) =>
      context_unpack_expression(
        kind,
        context_value_code(scope, expression, root, path, owner_reader),
        root,
        path,
        owner_reader,
      )
    Unary(op, child) if kind == Real =>
      "(\{op}\{context_expression_code(scope, child, root, path, owner_reader~)})"
    Binary(op, left, right) if lexical_binary(scope, op, left) =>
      context_lexical_code(scope, op, left, right, root, path, owner_reader)
    Binary(op, left, right) if context_real_binary(scope, left, right) =>
      context_real_code(scope, op, left, right, root, path, owner_reader)
    Binary(op, left, right) if context_mixed_integer_comparison(
        scope, op, left, right,
      ) =>
      context_mixed_integer_code(
        scope, op, left, right, root, path, owner_reader,
      )
    Binary("+", left, right) if kind == Text => {
      let a = context_expression_code(scope, left, root, path, owner_reader~)
      let b = context_expression_code(scope, right, root, path, owner_reader~)
      "(\{a} + \{b})"
    }
    Choose(condition, yes, no) => {
      let branch = fn(value) raise SchemaError {
        let code = context_expression_code(
          scope,
          value,
          root,
          path,
          owner_reader~,
        )
        if kind == Real && context_expression_type(scope, value) == Integer {
          "(\{code}).to_double()"
        } else {
          code
        }
      }
      "(if \{context_expression_code(scope, condition, root, path, owner_reader~)} { \{branch(yes)} } else { \{branch(no)} })"
    }
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
        lowered=Some(fn(value) {
          navigation
          .iter()
          .find_first(fn(pair) { pair.0 == value })
          .map(fn(pair) { pair.1 })
        }),
        stream_reader=owner_reader,
        bit_stream=scope.graph.bits,
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
    BitInteger(1, _) => "\{root}Value::Flag(\{value})"
    Unsigned(_, _) | Signed(_, _) | BitInteger(_, _) =>
      "\{root}Value::Number(\{value}.to_int64())"
    Enumerated(_, _) => "\{root}Value::Number(\{value}.to_i())"
    Unsigned64(_) | WideBitInteger(_, _) => "\{root}Value::Wide(\{value})"
    Signed64(_) => "\{root}Value::Number(\{value})"
    Float32(_) => "\{root}Value::RealValue(\{value}.to_double())"
    Float64(_) => "\{root}Value::RealValue(\{value})"
    Text(_, _) => "\{root}Value::StringValue(\{value})"
    ByteField(_) | Contents(_) => "\{root}Value::Binary(\{value})"
    Bounded(inner, _) => context_pack_kind(inner, value, root, bounded=true)
    Nested(_) | Application(_, _) =>
      "\{root}Value::ObjectId(\{value}._ksy_context)"
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
    BitInteger(1, _) => scalar("Flag", "value")
    Unsigned(_, _) | BitInteger(_, _) =>
      scalar("Number", "value.to_int().reinterpret_as_uint()")
    Signed(_, _) => scalar("Number", "value.to_int()")
    Enumerated(_, name) =>
      scalar("Number", generated_enum_type(root, name) + "::from_code(value)")
    Unsigned64(_) | WideBitInteger(_, _) => scalar("Wide", "value")
    Signed64(_) => scalar("Number", "value")
    Float32(_) => scalar("RealValue", "Float::from_double(value)")
    Float64(_) => scalar("RealValue", "value")
    Text(_, _) => scalar("StringValue", "value")
    ByteField(_) | Contents(_) => scalar("Binary", "value")
    Nested(name) | Application(name, _) =>
      scalar(
        "ObjectId",
        "\{context_hydrate_name(root, name)}(arena, value, \{path})",
      )
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
    Value(expression) => {
      let scope = context_scope(graph, owner, instance.name)
      match context_expression_type(scope, expression) {
        Integer => "Int64"
        Boolean => "Bool"
        Text => "String"
        Bytes => "BytesView"
        WideInteger => "UInt64"
        Real => "Double"
        Sequence(element) => parameter_result_type(Sequence(element), root)
        Stream => root + "Stream"
        Enum(name) => generated_enum_type(root, name)
        Object([name]) => context_type_name(root, name)
        Object(_) => context_choice_type(root, owner, instance.name)
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
fn context_choice_type(root : String, owner : String, name : String) -> String {
  let scope = if owner == "@root" { "root" } else { "type_" + owner }
  root + "_choice_" + scope + "_" + name
}

///|
fn context_hydrate_name(root : String, name : String) -> String {
  if name == "@root" {
    "hydrate_" + root + "_root_record"
  } else {
    "hydrate_" + root + "_" + name
  }
}

///|
fn context_decode_value(
  scope : ContextScope,
  expression : Expr,
  root : String,
  instance : String,
) -> String raise SchemaError {
  match context_expression_type(scope, expression) {
    Stream =>
      "(\{root}Stream::{ reader: \{context_unpack_expression(Stream, "value", root, "field", "reader")} })"
    Object(names) => {
      let error = context_error(root, "field")
      let object = "(match value.object_id() { Some(object) => object; None => { \{error} } })"
      if names is [name] {
        "\{context_hydrate_name(root, name)}(arena, \{object}, field)"
      } else {
        let output = StringBuilder()
        let result = context_choice_type(root, scope.owner, instance)
        output.write_string(
          "{ let object = \{object}; match arena.frame(object, field).tag { ",
        )
        for index, name in names {
          let tag = scope.graph.tags[name]
          output.write_string(
            "\{tag} => \{result}::Case\{index}(\{context_hydrate_name(root, name)}(arena, object, field)); ",
          )
        }
        output.write_string("_ => { \{error} } } }")
        output.to_string()
      }
    }
    Enum(name) =>
      "\{generated_enum_type(root, name)}::from_code(\{context_unpack_expression(Enum(name), "value", root, "field", "reader")})"
    kind =>
      parameter_result(
        kind,
        context_unpack_expression(kind, "value", root, "field", "reader"),
        root,
      )
  }
}

///|
fn context_has_reference(expression : Expr) -> Bool {
  match expression {
    Reference(_)
    | Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | Decode(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _)
    | ArrayLiteral(_)
    | WideLiteral(_) => true
    TypeSize(_, _) | Substring(_, _, _) => true
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
      effects[owner] = schema.recursive ||
        graph.byte_orders.contains(owner) ||
        context_record_raises(record, effects)
    }
  }
  effects
}

///|
fn context_record_raises(
  record : RecordDef,
  effects : Map[String, Bool],
) -> Bool {
  record.parameters.iter().any(fn(p) { p.range is Some(_) }) ||
  record.fields
  .iter()
  .any(fn(field) {
    field.count is Some(_) ||
    field.validation is Some(_) ||
    field.predicate is Some(_) ||
    (
      field.condition is Some(value) &&
      (context_has_reference(value) || expression_arithmetic(value))
    ) ||
    context_kind_raises(field.kind, effects)
  })
}

///|
fn context_kind_raises(kind : FieldKind, effects : Map[String, Bool]) -> Bool {
  match kind {
    Nested(name) => effects[name]
    Application(name, args) =>
      effects[name] ||
      args
      .iter()
      .any(fn(arg) { context_has_reference(arg) || expression_arithmetic(arg) })
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
    Binary(op, left, right) if lexical_binary(scope, op, left) =>
      navigation.push(
        (
          expression,
          context_lexical_code(scope, op, left, right, root, path, reader),
        ),
      )
    Binary(op, left, right) if context_real_binary(scope, left, right) =>
      navigation.push(
        (
          expression,
          context_real_code(scope, op, left, right, root, path, reader),
        ),
      )
    Binary(op, left, right) if context_mixed_integer_comparison(
        scope, op, left, right,
      ) =>
      navigation.push(
        (
          expression,
          context_mixed_integer_code(scope, op, left, right, root, path, reader),
        ),
      )
    Binary("+", _, _) if context_expression_type(scope, expression) == Text =>
      navigation.push(
        (
          expression,
          context_expression_code(
            scope,
            expression,
            root,
            path,
            owner_reader=reader,
          ),
        ),
      )
    Unary("+" | "-", child) if context_expression_type(scope, child) == Real =>
      navigation.push(
        (
          expression,
          context_expression_code(
            scope,
            expression,
            root,
            path,
            owner_reader=reader,
          ),
        ),
      )
    Reference(name) =>
      references[name] = context_unpack_expression(
        context_expression_type(scope, expression),
        context_value_code(scope, expression, root, path, reader),
        root,
        path,
        reader,
      )
    Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | Decode(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _)
    | TypeSize(_, _)
    | Substring(_, _, _)
    | ArrayLiteral(_) =>
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
      Application(_, args) => expressions.append(args)
      ByteField(options) | Text(options, _) | Bounded(_, options) => {
        if options.length is Some(Calculated(value)) {
          expressions.push(value)
        }
        if options.processor is Some(Xor(value, _) | Rotate(value, _)) &&
          (context_has_reference(value) || expression_arithmetic(value)) {
          expressions.push(value)
        }
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
) -> ((Expr, String?) -> String) raise SchemaError {
  let expressions = context_kind_expressions(field.kind)
  if field.predicate is Some(value) {
    expressions.push(value)
  }
  if field.condition is Some(value) {
    expressions.push(value)
  }
  match field.count {
    Some(Times(Calculated(value))) | Some(Until(value)) =>
      expressions.push(value)
    _ => ()
  }
  let codes = expressions.map(fn(value) raise SchemaError {
    let scope = if field.predicate == Some(value) {
      { ..scope, validated_field: Some(field.name), }
    } else {
      scope
    }
    (
      value,
      context_expression_code(scope, value, root, path, owner_reader=reader),
      context_expression_type(scope, value),
    )
  })
  fn(value, length_path) {
    let (_, code, kind) = codes
      .iter()
      .find_first(fn(pair) { pair.0 == value })
      .unwrap()
    if kind == WideInteger && length_path is Some(field) {
      let error = context_error(
        root,
        field,
        message="unsigned length exceeds the Int64 range",
      )
      "({ let length = \{code}; guard length <= 9223372036854775807UL else { \{error} }; length.reinterpret_as_int64() })"
    } else {
      code
    }
  }
}

///|
fn context_instance_read_raises(
  field : Field,
  position : Expr?,
  effects : Map[String, Bool],
) -> Bool {
  position is Some(_) ||
  field.count is Some(_) ||
  context_kind_raises(field.kind, effects)
}
