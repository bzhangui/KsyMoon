///|
/// Compiles one supported Kaitai Struct description to self-contained MoonBit source.
pub fn generate(source : String) -> String raise SchemaError {
  generate_schema(load_schema(source))
}

///|
fn generate_schema(schema : Schema) -> String raise SchemaError {
  let needs_context = schema.recursive ||
    !schema.byte_orders.is_empty() ||
    (
      schema.has_context &&
      (
        context_all_expressions(schema)
        .iter()
        .any(fn(value) {
          context_has_reference(value) ||
          expression_arithmetic(value) ||
          expression_any(value, fn(item) { item is Text(_) })
        }) ||
        [schema.root, ..schema.records]
        .iter()
        .any(fn(record) {
          !record.parameters.is_empty() ||
          !record.instances.is_empty() ||
          record.fields.iter().any(field_requires_context_evaluator)
        })
      )
    )
  if needs_context {
    return generate_context_schema(schema)
  }
  let output = StringBuilder()
  let id = schema.root.name
  let root_type = pascal_case(id)
  let root_record_type = root_type + "Record"
  let records = [schema.root, ..schema.records]
  let effects = read_effects(schema.records)
  let has_bits = schema_has_bits(schema)
  let mut has_numeric_fields = false
  let mut has_uint64 = false
  let mut has_repeated_fields = false
  let mut has_contents = false
  let mut has_validation = false
  let mut has_predicates = false
  let mut has_instances = false
  let mut has_positions = false
  let mut has_arithmetic = false
  let mut has_read_fields = false
  let mut has_stream_size = false
  let mut has_bounded = false
  let mut has_byte_options = false
  let mut has_strings = false
  let mut single_byte_encoding = false
  let extended_encodings = []
  let mut has_open_repeats = false
  let processors = []
  for record in records {
    has_instances = has_instances || !record.instances.is_empty()
    let fields = record.fields.copy()
    for instance in record.instances {
      if instance.condition is Some(condition) {
        has_arithmetic = has_arithmetic || expression_arithmetic(condition)
        has_stream_size = has_stream_size || expression_stream_size(condition)
      }
      match instance.kind {
        Parsed(field, position) => {
          fields.push(field)
          if position is Some(position) {
            has_positions = true
            has_arithmetic = has_arithmetic || expression_arithmetic(position)
          }
        }
        Value(expression) => {
          has_arithmetic = has_arithmetic || expression_arithmetic(expression)
          has_stream_size = has_stream_size ||
            expression_stream_size(expression)
        }
      }
    }
    for field in fields {
      has_predicates = has_predicates || field.predicate is Some(_)
      if field.condition is Some(condition) {
        has_arithmetic = has_arithmetic || expression_arithmetic(condition)
        has_stream_size = has_stream_size || expression_stream_size(condition)
      }
      has_repeated_fields = has_repeated_fields || field.count is Some(_)
      if field.count is Some(ToEnd) {
        has_open_repeats = true
        has_stream_size = true
      }
      if field.count is Some(Until(expression)) {
        has_arithmetic = has_arithmetic || expression_arithmetic(expression)
        has_stream_size = has_stream_size || expression_stream_size(expression)
      }
      for kind in walk_kinds(field.kind) {
        if kind_processor(kind) is Some(processor) {
          let name = processor_name(processor)
          if !processors.contains(name) {
            processors.push(name)
          }
        }
        if !(kind is Nested(_) ||
          kind is Switch(_, _, _, _) ||
          kind is Enumerated(_, _) ||
          kind is BitInteger(_, _) ||
          kind is WideBitInteger(_, _)) {
          has_read_fields = true
        }
        has_numeric_fields = has_numeric_fields ||
          kind is Unsigned(_, _) ||
          kind is Signed(_, _) ||
          kind is Float32(_)
        has_uint64 = has_uint64 ||
          kind is (Unsigned64(_) | Signed64(_) | Float64(_))
        has_contents = has_contents || kind is Contents(_)
        has_bounded = has_bounded || kind is Bounded(_, _)
        has_strings = has_strings || kind is Text(_, _)
        single_byte_encoding = single_byte_encoding ||
          kind is Text(_, "WINDOWS-1252" | "ISO-8859-1")
        if kind is Text(_, encoding) {
          note_extended_encoding(extended_encodings, encoding)
        }
        match kind {
          ByteField(options) | Text(options, _) | Bounded(_, options) =>
            has_byte_options = has_byte_options ||
              options.terminator is Some(_) ||
              options.padding is Some(_)
          _ => ()
        }
        if kind is Switch(_, selector, cases, _) {
          has_stream_size = has_stream_size || expression_stream_size(selector)
          has_arithmetic = has_arithmetic ||
            expression_arithmetic(selector) ||
            cases.iter().any(fn(c) { expression_arithmetic(c.0) })
        }
      }
      has_validation = has_validation || field.validation is Some(_)
    }
  }
  output.write_string("// Generated by KsyMoon from \{id}.ksy.\n\n")
  emit_enums(output, root_type, schema.enums)
  emit_switch_types(output, records, root_type)
  for record in schema.records {
    emit_record_type(
      output,
      nested_type(root_type, record.name),
      record,
      root_type,
    )
  }
  emit_record_type(output, root_record_type, schema.root, root_type)
  emit_reader(
    output,
    root_type,
    has_bounded~,
    has_byte_options~,
    has_strings~,
    single_byte_encoding~,
    extended_encodings~,
    has_open_repeats~,
    has_numeric_fields~,
    has_uint64~,
    has_repeated_fields~,
    has_contents~,
    has_validation~,
    has_predicates~,
    has_instances~,
    has_positions~,
    has_arithmetic~,
    has_read_fields~,
    has_input=has_read_fields || has_stream_size || has_positions || has_bits,
    has_bits~,
    has_narrow_bits=bit_fields(schema, wide=false),
    has_wide_bits=bit_fields(schema, wide=true),
    has_process=processors.iter().any(fn(name) { name != "process_xor_mask" }),
  )
  emit_processors(output, root_type, processors)
  for record in schema.records {
    let name = nested_reader(id, record.name)
    emit_record_reader(
      output,
      name,
      nested_type(root_type, record.name),
      record,
      id,
      root_type,
      effects,
      has_bits,
    )
  }
  emit_record_reader(
    output,
    "read_\{id}_root",
    root_record_type,
    schema.root,
    id,
    root_type,
    effects,
    has_bits,
  )
  for index, record in records {
    emit_instances(
      output,
      record,
      id,
      root_type,
      has_repeated_fields,
      effects,
      is_root=index == 0,
      has_bits~,
    )
  }
  let effect = if !schema.root.fields
    .iter()
    .any(fn(field) { field_raises(field, effects) }) {
    ""
  } else {
    " raise \{root_type}ParseError"
  }
  let input_arg = if has_read_fields ||
    has_stream_size ||
    has_positions ||
    has_bits {
    "input"
  } else {
    "_input"
  }
  output.write_string(
    "///|\npub fn parse_\{id}(\{input_arg} : Bytes) -> \{root_record_type}\{effect} {\n",
  )
  let repeat_budget = if has_repeated_fields {
    ", budget: [1_000_000]"
  } else {
    ""
  }
  let input_state = if has_read_fields ||
    has_stream_size ||
    has_positions ||
    has_bits {
    "input, "
  } else {
    ""
  }
  output.write_string(
    "  let reader : \{root_type}Reader = { \{input_state}offset: 0\{repeat_budget}\{bit_state(has_bits)} }\n",
  )
  output.write_string("  read_\{id}_root(reader, \"\{id}\")\n}\n")
  output.to_string()
}

///|
fn field_requires_context_evaluator(field : Field) -> Bool {
  if !(field.parent is Implicit) {
    return true
  }
  if field.count is Some(Times(Calculated(value))) && !(value is Integer(_)) {
    return true
  }
  walk_kinds(field.kind)
  .iter()
  .any(fn(kind) {
    match kind {
      Application(_, _) => true
      ByteField(options) | Text(options, _) | Bounded(_, options) =>
        options.length is Some(Calculated(value)) && !(value is Integer(_))
      _ => false
    }
  })
}

///|
fn pascal_case(name : String) -> String {
  let output = StringBuilder()
  for segment in name.split("_") {
    let segment = segment.to_owned()
    output.write_string(segment[0:1].to_owned().to_upper())
    output.write_stringview(segment[1:])
  }
  output.to_string()
}

///|
fn nested_type(root_type : String, name : String) -> String {
  if name == "@root" {
    return root_type + "Record"
  }
  "\{root_type}_\{name}"
}

///|
fn nested_reader(id : String, name : String) -> String {
  if name == "@root" {
    return "read_" + id + "_root"
  }
  "read_\{id}_type_\{name}"
}

///|
fn field_type(kind : FieldKind, root_type : String) -> String {
  match kind {
    BitInteger(1, _) => "Bool"
    Unsigned(_, _) | BitInteger(_, _) => "UInt"
    Unsigned64(_) | WideBitInteger(_, _) => "UInt64"
    Signed(_, _) => "Int"
    Signed64(_) => "Int64"
    Float32(_) => "Float"
    Float64(_) => "Double"
    Contents(_) | ByteField(_) => "BytesView"
    Text(_, _) => "String"
    Bounded(inner, _) => field_type(inner, root_type)
    Switch(name, _, _, _) => root_type + "_switch_" + name
    Enumerated(_, name) => generated_enum_type(root_type, name)
    Nested(name) | Application(name, _) => nested_type(root_type, name)
  }
}

///|
fn emit_record_type(
  output : StringBuilder,
  type_name : String,
  record : RecordDef,
  root_type : String,
) -> Unit raise SchemaError {
  output.write_string("///|\npub struct \{type_name} {\n")
  for field in record.fields {
    let type_name = field_result_type(field, root_type)
    output.write_string(
      "  \{generated_member_name(field.name)} : \{type_name}\n",
    )
  }
  if !record.instances.is_empty() {
    output.write_string(
      "  priv _ksy_reader : \{root_type}Reader\n  priv _ksy_path : String\n",
    )
    for instance in record.instances {
      let type_name = instance_result_type(record, instance, root_type)
      output.write_string(
        "  priv mut _ksy_cache_\{instance.name} : \{type_name}?\n",
      )
      output.write_string("  priv mut _ksy_busy_\{instance.name} : Bool\n")
    }
  }
  output.write_string("}\n\n")
}

///|
fn length_code(
  expression : LengthExpr,
  path : String,
  in_instance~ : Bool = false,
  evaluate~ : ((Expr, String?) -> String)? = None,
) -> String {
  let prefix = if in_instance { "self." } else { "v_" }
  match expression {
    Constant(value) => "\{value}L"
    Remaining => "(reader.input.length() - reader.offset).to_int64()"
    Calculated(Integer(value)) => "\{value}L"
    Calculated(value) => evaluate.unwrap()(value, Some(path))
    EarlierField(name, 0L) => "\{prefix}\{name}.to_int64()"
    EarlierField(name, subtract) => "\{prefix}\{name}.to_int64() - \{subtract}L"
  }
}

///|
fn endian_flag(endian : Endian) -> String {
  match endian {
    Little => "true"
    Big => "false"
    SelectedOrder => "arena.frames[context].unwrap().little_endian"
  }
}

///|
fn read_code(
  kind : FieldKind,
  id : String,
  path : String,
  in_instance~ : Bool = false,
  reference~ : (String) -> String = fn(name) { "v_\{name}.to_int64()" },
  evaluate~ : ((Expr, String?) -> String)? = None,
  parent_context~ : String? = None,
  bits~ : Bool = false,
) -> String {
  match kind {
    BitInteger(width, endian) => {
      let code = "reader.read_bit_integer(\{width}, \{endian is Little}, \{path})"
      if width == 1 {
        "(\{code} != 0U)"
      } else {
        code
      }
    }
    Unsigned(width, endian) =>
      "reader.read_bits(\{width.to_int()}, \{endian_flag(endian)}, \{path})"
    WideBitInteger(width, endian) =>
      "reader.read_wide_bit_integer(\{width}, \{endian is Little}, \{path})"
    Unsigned64(endian) =>
      "reader.read_uint64_bits(8, \{endian_flag(endian)}, \{path})"
    Signed64(endian) =>
      "reader.read_uint64_bits(8, \{endian_flag(endian)}, \{path}).reinterpret_as_int64()"
    Float64(endian) =>
      "reader.read_uint64_bits(8, \{endian_flag(endian)}, \{path}).reinterpret_as_double()"
    Signed(width, endian) => {
      let bits = "reader.read_bits(\{width.to_int()}, \{endian_flag(endian)}, \{path})"
      let shift = (4 - width.to_int()) * 8
      if shift == 0 {
        "\{bits}.reinterpret_as_int()"
      } else {
        "((\{bits} << \{shift}).reinterpret_as_int() >> \{shift})"
      }
    }
    Float32(endian) =>
      "Float::reinterpret_from_uint(reader.read_bits(4, \{endian_flag(endian)}, \{path}))"
    Contents(bytes) => {
      let values = bytes
        .iter()
        .map(fn(byte) { byte.to_int().to_string() })
        .collect()
      "reader.read_contents(Bytes::from_array([\{values.join(", ")}]), \{path})"
    }
    Enumerated(inner, name) => {
      let code = match inner {
        BitInteger(1, endian) =>
          "reader.read_bit_integer(1, \{endian is Little}, \{path}).to_int64()"
        Signed64(_) =>
          read_code(
            inner,
            id,
            path,
            in_instance~,
            reference~,
            evaluate~,
            parent_context~,
            bits~,
          )
        _ =>
          read_code(
            inner,
            id,
            path,
            in_instance~,
            reference~,
            evaluate~,
            parent_context~,
            bits~,
          ) +
          ".to_int64()"
      }
      "\{generated_enum_type(pascal_case(id), name)}::from_code(\{code})"
    }
    Application(name, arguments) => {
      let values = arguments
        .map(fn(expression) { ", " + evaluate.unwrap()(expression, None) })
        .join("")
      "\{nested_reader(id, name)}(reader, \{path}, arena, \{parent_context.unwrap()}\{values})"
    }
    Nested(name) => {
      let extra = match parent_context {
        Some(context) => ", arena, " + context
        None => ""
      }
      "\{nested_reader(id, name)}(reader, \{path}\{extra})"
    }
    ByteField(options) => byte_read_code(options, path, in_instance, evaluate~)
    Text(options, encoding) => {
      let bytes = byte_read_code(
        options,
        path,
        in_instance,
        unit=if options.implicit_terminator && encoding.has_prefix("UTF-16") {
          2
        } else {
          1
        },
        big_endian=encoding == "UTF-16BE",
        evaluate~,
      )
      "{ let text_start = reader.offset; let text_bytes = \{bytes}; reader.decode_text(text_bytes, \{encoding.escape()}, \{path}, text_start) }"
    }
    Bounded(inner, options) => {
      let bytes = byte_read_code(options, path, in_instance, evaluate~)
      let call = match inner {
        Switch(_, _, _, _) =>
          switch_read_code(
            inner,
            id,
            path,
            reference,
            true,
            in_instance,
            selector_override=Some("ksy_selector"),
            evaluate~,
            parent_context~,
            bits~,
          )
        _ =>
          read_code(
            inner,
            id,
            path,
            in_instance~,
            reference~,
            evaluate~,
            parent_context~,
            bits~,
          )
      }
      let selection = match inner {
        Switch(_, selector, cases, _) if !cases.is_empty() =>
          "let ksy_selector = " +
          (match evaluate {
            Some(evaluate) => evaluate(selector, None)
            None => expression_code(selector, reference, path)
          }) +
          "; "
        _ => ""
      }
      "{ \{selection}let substream = reader.substream(\{bytes}); let reader = substream; \{call} }"
    }
    Switch(_, _, _, _) =>
      switch_read_code(
        kind,
        id,
        path,
        reference,
        false,
        in_instance,
        evaluate~,
        parent_context~,
        bits~,
      )
  }
}

///|
fn emit_record_reader(
  output : StringBuilder,
  reader_name : String,
  type_name : String,
  record : RecordDef,
  id : String,
  root_type : String,
  effects : Map[String, Bool],
  bits : Bool,
) -> Unit {
  if record.fields.is_empty() && record.instances.is_empty() {
    output.write_string(
      "///|\nfn \{reader_name}(reader : \{root_type}Reader, _path : String) -> \{type_name} {\n  ignore(reader.offset)\n  \{type_name}::{}\n}\n\n",
    )
    return
  }
  let effect = if !record.fields
    .iter()
    .any(fn(field) { field_raises(field, effects) }) {
    ""
  } else {
    " raise \{root_type}ParseError"
  }
  output.write_string(
    "///|\nfn \{reader_name}(reader : \{root_type}Reader, path : String) -> \{type_name}\{effect} {\n",
  )
  for field in record.fields {
    let name = field.name
    let field_path = "path_\{name}"
    output.write_string("  let \{field_path} = path + \".\{name}\"\n")
    if field.condition is Some(condition) {
      let predicate = expression_code(
        condition,
        fn(name) { record_reference(record, name, false) },
        field_path,
      )
      output.write_string("  let v_\{name} = if \{predicate} {\n")
    }
    emit_field_read(
      output,
      field,
      "v_" + name,
      id,
      field_path,
      fn(name) { record_reference(record, name, false) },
      false,
      bits~,
    )
    if field.condition is Some(_) {
      output.write_string("    Some(v_\{name})\n  } else { None }\n")
    }
  }
  output.write_string("  {\n")
  for field in record.fields {
    output.write_string(
      "    \{generated_member_name(field.name)}: v_\{field.name},\n",
    )
  }
  if !record.instances.is_empty() {
    output.write_string("    _ksy_reader: reader,\n    _ksy_path: path,\n")
    for instance in record.instances {
      output.write_string("    _ksy_cache_\{instance.name}: None,\n")
      output.write_string("    _ksy_busy_\{instance.name}: false,\n")
    }
  }
  output.write_string("  }\n}\n\n")
}
