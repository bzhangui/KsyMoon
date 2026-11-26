///|
fn context_flags(schema : Schema) -> Array[String] raise SchemaError {
  let flags = []
  let add = fn(name) { if !flags.contains(name) { flags.push(name) } }
  let graph = context_graph(schema)
  for owner, record in graph.records {
    for parameter in record.parameters {
      let kind = if parameter.kind is Sequence(element) {
        add("items")
        element
      } else {
        parameter.kind
      }
      match kind {
        Text => add("text")
        Bytes => add("binary")
        Real => add("real")
        WideInteger => add("wide")
        _ => ()
      }
    }
    let fields = record.fields.copy()
    for instance in record.instances {
      match instance.kind {
        Parsed(field, _) => fields.push(field)
        Value(expression) =>
          match
            context_expression_type(
              context_scope(graph, owner, instance.name),
              expression,
            ) {
            Text => add("text")
            Bytes => add("binary")
            WideInteger => add("wide")
            Sequence(element) => {
              add("items")
              match element {
                Real => add("real")
                Text => add("text")
                Bytes => add("binary")
                WideInteger => add("wide")
                _ => ()
              }
            }
            Real => add("real")
            _ => ()
          }
      }
    }
    for field in fields {
      if field.count is Some(_) {
        add("items")
      }
      for kind in walk_kinds(field.kind) {
        if kind_processor(kind) is Some(processor) {
          add(processor_name(processor))
        }
        match kind {
          ByteField(_) | Contents(_) => add("binary")
          Text(_, _) => add("text")
          Unsigned64(_) | WideBitInteger(_, _) => add("wide")
          Float32(_) | Float64(_) => add("real")
          Switch(_, _, _, _) => add("selected")
          Bounded(Switch(_, _, _, None), _) => add("binary")
          _ => ()
        }
      }
    }
  }
  let expressions = context_all_expressions(schema)
  if expressions
    .iter()
    .any(fn(expr) {
      expression_any(expr, fn(value) { value is Cast(_, "bytes") })
    }) {
    add("binary")
  }
  if expressions
    .iter()
    .any(fn(expr) {
      expression_any(expr, fn(value) { value is Member(_, "@interpolate") })
    }) {
    add("text")
  }
  if expressions
    .iter()
    .any(fn(expr) {
      expression_any(expr, fn(value) { value is ArrayLiteral(_) })
    }) {
    add("items")
  }
  if expressions
    .iter()
    .any(fn(expr) {
      expression_any(expr, fn(value) {
        value is ArrayLiteral(items) &&
        items
        .iter()
        .any(fn(item) { expression_any(item, fn(part) { part is Text(_) }) })
      })
    }) {
    add("text")
  }
  if expressions
    .iter()
    .any(fn(expr) {
      expression_any(expr, fn(value) { value is Member(_, "min" | "max") })
    }) {
    add("sequence_extremes")
  }
  if expressions.iter().any(context_contains_endpoint) {
    flags.push("sequence_endpoints")
  }
  if expressions.iter().any(context_contains_wide_value) {
    add("wide")
  }
  flags
}

///|
fn context_emit_runtime(
  output : StringBuilder,
  root : String,
  flags : Array[String],
  release : Bool,
  has_instances : Bool,
  accounting : Bool,
  rollback : Bool,
  bits : Bool,
  recursive : Bool,
  modules : Bool,
  overridden_parent : Bool,
  contextual_endian : Bool,
  index : Bool,
  objects : Bool,
  local_expressions_only : Bool,
) -> Unit {
  output.write_string(
    "///|\npriv enum \{root}Value {\n  Number(Int64)\n  Flag(Bool)\n  ObjectId(Int)\n  Source(\{root}Reader)\n  Absent\n",
  )
  for
    (name, definition) in [
      ("text", "StringValue(String)"),
      ("binary", "Binary(BytesView)"),
      ("wide", "Wide(UInt64)"),
      ("real", "RealValue(Double)"),
      ("items", "Items(Array[" + root + "Value])"),
      ("selected", "Selected(Int, " + root + "Value)"),
    ] {
    if flags.contains(name) {
      output.write_string("  \{definition}\n")
    }
  }
  output.write_string("}\n\n")
  let block =
    #|///|
    #|priv struct __ROOT__Context {
    #|  tag : Int
    #|__PARENT_FIELD__
    #|  reader : __ROOT__Reader
    #|__PATH_FIELD__
    #|  children : Array[Int]
    #|  fields : Map[String, __ROOT__Value]
    #|  cache : Map[String, __ROOT__Value]
    #|  partial : Map[String, __ROOT__Value]
    #|__BUSY_FIELD__
    #|__DEPTH_FIELD____ACCOUNT_FIELD____MODULE_FIELDS____ENDIAN_FIELD__}
    #|
    #|///|
    #|priv struct __ROOT__Arena {
    #|  frames : Array[__ROOT__Context?]
    #|  free : Array[Int]
    #|__ACCOUNT_COUNTER__}
    #|
    #|///|
    #|fn __ROOT__Arena::frame(self : __ROOT__Arena, context : Int, field : String) -> __ROOT__Context raise __ROOT__ParseError {
    #|  guard context >= 0 && self.frames.get(context) is Some(Some(frame)) else {
    #|    raise __ROOT__ContextError(field~, offset=0, message="object context is unavailable")
    #|  }
    #|  frame
    #|}
    #|
    #|///|
    #|fn __ROOT__Arena::create(self : __ROOT__Arena, tag : Int, parent : Int, reader : __ROOT__Reader, __PATH_ARG__ : String__MODULE_ARG__) -> Int__CREATE_EFFECT__ {
    #|__DEPTH_CHECK____MODULE_SETUP__  let frame : __ROOT__Context = { tag, __PARENT_INIT__reader, __PATH_INIT__children: [], fields: Map([]), cache: Map([]), partial: Map([])__BUSY_INIT____DEPTH_INIT____ACCOUNT_INIT____MODULE_INIT____ENDIAN_INIT__ }
    #|  let context = match self.free.pop() {
    #|    Some(context) => { self.frames[context] = Some(frame); context }
    #|    None => { self.frames.push(Some(frame)); self.frames.length() - 1 }
    #|  }
    #|__MODULE_ROOT__  if parent >= 0 { self.frames[parent].unwrap().children.push(context) }
    #|  context
    #|}
    #|
  let depth_check = if recursive {
    "  let depth = if parent < 0 { 0 } else { self.frames[parent].unwrap().depth + 1 }\n  guard depth <= 64 else { raise __ROOT__ContextError(field=path, offset=reader.offset, message=\"record nesting exceeds 64\") }\n"
  } else {
    ""
  }
  let block = block
    .replace_all(
      old="__PARENT_FIELD__\n",
      new=if modules && !release { "" } else { "  parent : Int\n" },
    )
    .replace_all(
      old="__PARENT_INIT__",
      new=if modules && !release { "" } else { "parent, " },
    )
    .replace_all(
      old="__DEPTH_FIELD__",
      new=if recursive { "  depth : Int\n" } else { "" },
    )
    .replace_all(old="__DEPTH_CHECK__", new=depth_check[:])
    .replace_all(
      old="__DEPTH_INIT__",
      new=if recursive { ", depth" } else { "" },
    )
    .replace_all(
      old="__CREATE_EFFECT__",
      new=if recursive { " raise __ROOT__ParseError" } else { "" },
    )
    .replace_all(
      old="__PATH_FIELD__\n",
      new=if has_instances { "  path : String\n" } else { "" },
    )
    .replace_all(
      old="__BUSY_FIELD__\n",
      new=if has_instances { "  busy : Map[String, Bool]\n" } else { "" },
    )
    .replace_all(
      old="__PATH_ARG__",
      new=if has_instances || recursive { "path" } else { "_path" },
    )
    .replace_all(
      old="__PATH_INIT__",
      new=if has_instances { "path, " } else { "" },
    )
    .replace_all(
      old="__BUSY_INIT__",
      new=if has_instances { ", busy: Map([])" } else { "" },
    )
    .replace_all(
      old="__ACCOUNT_FIELD__",
      new=if accounting { "  account : Int\n" } else { "" },
    )
    .replace_all(
      old="__ACCOUNT_COUNTER__",
      new=if accounting { "  mut next_account : Int\n" } else { "" },
    )
    .replace_all(
      old="__ACCOUNT_INIT__",
      new=if accounting {
        ", account: reader.budget[reader.budget[1] - 1]"
      } else {
        ""
      },
    )
  let block = block
    .replace_all(
      old="__ENDIAN_FIELD__",
      new=if contextual_endian { "  mut little_endian : Bool\n" } else { "" },
    )
    .replace_all(
      old="__ENDIAN_INIT__",
      new=if contextual_endian { ", little_endian: false" } else { "" },
    )
    .replace_all(
      old="__MODULE_FIELDS__",
      new=if modules {
        "  module_id : String\n  mut module_root : Int\n  logical_parent : Int\n"
      } else {
        ""
      },
    )
    .replace_all(
      old="__MODULE_ARG__",
      new=(if modules {
          ", module_id : String, module_entry : Bool"
        } else {
          ""
        }) +
        (if overridden_parent { ", parent_override : Int?" } else { "" }),
    )
    .replace_all(
      old="__MODULE_SETUP__",
      new=if modules {
        "  let same_module = parent >= 0 && self.frames[parent].unwrap().module_id == module_id\n"
      } else {
        ""
      },
    )
    .replace_all(
      old="__MODULE_INIT__",
      new=if modules {
        let default_parent = "if same_module { parent } else { -1 }"
        let logical_parent = if overridden_parent {
          "parent_override.unwrap_or(" + default_parent + ")"
        } else {
          default_parent
        }
        ", module_id, module_root: if same_module { self.frames[parent].unwrap().module_root } else { -1 }, logical_parent: " +
        logical_parent
      } else {
        ""
      },
    )
    .replace_all(
      old="__MODULE_ROOT__",
      new=if modules {
        "  if !same_module && module_entry { frame.module_root = context }\n"
      } else {
        ""
      },
    )
  write_reader_block(output, block, root)
  if release {
    let block =
      #|///|
      #|fn __ROOT__Arena::release(self : __ROOT__Arena, context : Int) -> Unit {
      #|  guard self.frames.get(context) is Some(Some(frame)) else { return }
      #|  self.frames[context] = None
      #|  for child in frame.children {
      #|    if self.frames.get(child) is Some(Some({ parent, .. })) && parent == context { self.release(child) }
      #|  }
      #|  if frame.parent >= 0 && self.frames[frame.parent] is Some(parent) {
      #|    parent.children.retain(fn(child) { child != context })
      #|  }
      #|  self.free.push(context)
      #|}
      #|
    write_reader_block(output, block, root)
    if rollback {
      let cleanup =
        #|///|
        #|fn __ROOT__Arena::release_account(self : __ROOT__Arena, account : Int) -> Unit {
        #|  for context in 0..<self.frames.length() {
        #|    if self.frames[context] is Some(frame) && frame.account == account { self.release(context) }
        #|  }
        #|}
        #|
      write_reader_block(output, cleanup, root)
    }
  }
  let block =
    #|///|
    #|__LOCAL_EXPRESSIONS_ONLY__fn __ROOT__Value::attribute(self : __ROOT__Value, arena : __ROOT__Arena, name : String, field : String) -> __ROOT__Value raise __ROOT__ParseError {
    #|  match self {
    #|    ObjectId(context) => {
    #|      let frame = arena.frame(context, field)
    #|      match name {
    #|        "_io" => Source(frame.reader)
    #|        "_root" => __LOGICAL_ROOT__
    #|        "_parent" => if frame.__LOGICAL_PARENT__ < 0 { Absent } else { ObjectId(frame.__LOGICAL_PARENT__) }
    #|        _ => arena.attribute(context, name, field)
    #|      }
    #|    }
    #|    Source(reader) => match name {
    #|      "pos" => Number(reader.offset.to_int64())
    #|      "size" => Number(reader.input.length().to_int64())
    #|      "eof" => Flag(__BIT_EOF__reader.offset == reader.input.length())
    #|      _ => Absent
    #|    }
    #|__EXTRA_CASES__    Number(value) => { ignore(value); Absent }
    #|    Flag(value) => { ignore(value); Absent }
    #|    Absent => Absent
    #|  }
    #|}
    #|
  let extra = StringBuilder()
  if flags.contains("selected") {
    extra.write_string(
      "    Selected(tag, value) => { ignore(tag); value.attribute(arena, name, field) }\n",
    )
  }
  if flags.contains("binary") {
    extra.write_string(
      "    Binary(value) if name == \"length\" => Number(value.length().to_int64())\n",
    )
  }
  if flags.contains("items") {
    extra.write_string(
      "    Items(value) if name == \"length\" => Number(value.length().to_int64())\n",
    )
  }
  if flags.contains("text") {
    extra.write_string("    StringValue(value) => { ignore(value); Absent }\n")
  }
  if flags.contains("wide") {
    extra.write_string("    Wide(value) => { ignore(value); Absent }\n")
  }
  if flags.contains("real") {
    extra.write_string("    RealValue(value) => { ignore(value); Absent }\n")
  }
  if flags.contains("binary") && flags.contains("sequence_extremes") {
    extra.write_string(
      "    Binary(bytes) if (name == \"min\" || name == \"max\") && !bytes.is_empty() => {\n      let mut best = bytes[0]\n      for byte in bytes { if (name == \"min\" && byte < best) || (name == \"max\" && byte > best) { best = byte } }\n      Number(best.to_int64())\n    }\n",
    )
  }
  if flags.contains("items") && flags.contains("sequence_extremes") {
    extra.write_string(
      "    Items(items) if name == \"min\" || name == \"max\" => self.extreme(items, name == \"min\")\n",
    )
  }
  if flags.contains("binary") {
    extra.write_string(
      if flags.contains("sequence_endpoints") {
        "    Binary(bytes) if (name == \"first\" || name == \"last\") && !bytes.is_empty() => Number(bytes[if name == \"first\" { 0 } else { bytes.length() - 1 }].to_int64())\n    Binary(_) => Absent\n"
      } else {
        "    Binary(_) => Absent\n"
      },
    )
  }
  if flags.contains("items") {
    extra.write_string(
      if flags.contains("sequence_endpoints") {
        "    Items(items) if name == \"first\" => items.get(0).unwrap_or(Absent)\n    Items(items) if name == \"last\" => items.last().unwrap_or(Absent)\n    Items(_) => Absent\n"
      } else {
        "    Items(_) => Absent\n"
      },
    )
  }
  write_reader_block(
    output,
    block
    .replace_all(
      old="__LOCAL_EXPRESSIONS_ONLY__",
      new=if local_expressions_only {
        "#warnings(\"-unused_value\")\n"
      } else {
        ""
      },
    )
    .replace_all(old="__EXTRA_CASES__", new=extra.to_string()[:])
    .replace_all(
      old="__LOGICAL_ROOT__",
      new=if modules {
        "if frame.module_root < 0 { Absent } else { ObjectId(frame.module_root) }"
      } else {
        "ObjectId(0)"
      },
    )
    .replace_all(
      old="__LOGICAL_PARENT__",
      new=if modules { "logical_parent" } else { "parent" },
    )
    .replace_all(
      old="__BIT_EOF__",
      new=if bits { "reader.bits_left == 0 && " } else { "" },
    ),
    root,
  )
  if flags.contains("items") && flags.contains("sequence_extremes") {
    emit_sequence_extremes(output, root, flags)
  }
  if objects {
    let selected = if flags.contains("selected") {
      "    Selected(_, value) => value.object_id()\n"
    } else {
      ""
    }
    output.write_string(
      "///|\nfn \{root}Value::object_id(self : \{root}Value) -> Int? {\n  match self {\n    ObjectId(id) => Some(id)\n\{selected}    _ => None\n  }\n}\n\n",
    )
  }
  if index {
    output.write_string(
      "///|\nfn \{root}Value::element(self : \{root}Value, arena : \{root}Arena, index : Int64, field : String, offset : Int) -> \{root}Value raise \{root}ParseError {\n",
    )
    let error = "raise \{root}ContextError(field~, offset~, message=\"array index is outside the available values\")"
    output.write_string(
      "  guard self.attribute(arena, \"length\", field) is Number(length) && index >= 0L && index < length else { \{error} }\n",
    )
    output.write_string("  match self {\n")
    if flags.contains("items") {
      output.write_string("    Items(items) => items[index.to_int()]\n")
    }
    if flags.contains("binary") {
      output.write_string(
        "    Binary(bytes) => Number(bytes[index.to_int()].to_int64())\n",
      )
    }
    if flags.contains("selected") {
      output.write_string(
        "    Selected(_, value) => value.element(arena, index, field, offset)\n",
      )
    }
    output.write_string("    _ => { \{error} }\n  }\n}\n\n")
  }
}

///|
fn context_contains_index(expression : Expr) -> Bool {
  match expression {
    Index(_, _) => true
    Member(base, _)
    | Cast(base, _)
    | Decode(base, _)
    | ToEnum(base, _)
    | Unary(_, base) => context_contains_index(base)
    Binary(_, a, b) | ToInteger(a, b) =>
      context_contains_index(a) || context_contains_index(b)
    Choose(a, b, c) | Substring(a, b, c) =>
      context_contains_index(a) ||
      context_contains_index(b) ||
      context_contains_index(c)
    _ => false
  }
}

///|
fn context_all_expressions(schema : Schema) -> Array[Expr] {
  [schema.root, ..schema.records].fold(init=[], fn(expressions, record) {
    expressions.append(context_record_expressions(record))
    expressions
  })
}

///|
fn context_record_expressions(record : RecordDef) -> Array[Expr] {
  let expressions = []
  let fields = record.fields.copy()
  for instance in record.instances {
    if instance.io is Some(value) {
      expressions.push(value)
    }
    if instance.condition is Some(value) {
      expressions.push(value)
    }
    match instance.kind {
      Value(value) => expressions.push(value)
      Parsed(field, position) => {
        fields.push(field)
        if position is Some(value) {
          expressions.push(value)
        }
      }
    }
  }
  for field in fields {
    expressions.append(context_kind_expressions(field.kind))
    if field.predicate is Some(value) && !plain_predicate(field) {
      expressions.push(value)
    }
    if field.condition is Some(value) {
      expressions.push(value)
    }
    if field.parent is Explicit(value) {
      expressions.push(value)
    }
    match field.count {
      Some(Times(Calculated(value))) => expressions.push(value)
      Some(Until(value)) if !plain_byte_until(value) => expressions.push(value)
      _ => ()
    }
  }
  expressions
}

///|
fn context_contains_cast(expression : Expr) -> Bool {
  expression_any(expression, fn(value) {
    value is Cast(_, target) &&
    target != "bytes" &&
    integer_cast(target) is None &&
    integer_array_cast(target) is None
  })
}

///|
fn context_emit_stream_value(
  output : StringBuilder,
  root : String,
  bits : Bool,
) -> Unit {
  let block =
    #|///|
    #|pub struct __ROOT__Stream {
    #|  priv reader : __ROOT__Reader
    #|}
    #|
    #|///|
    #|pub fn __ROOT__Stream::pos(self : __ROOT__Stream) -> Int64 {
    #|  self.reader.offset.to_int64()
    #|}
    #|
    #|///|
    #|pub fn __ROOT__Stream::size(self : __ROOT__Stream) -> Int64 {
    #|  self.reader.input.length().to_int64()
    #|}
    #|
    #|///|
    #|pub fn __ROOT__Stream::eof(self : __ROOT__Stream) -> Bool {
    #|  __BIT_EOF__self.reader.offset == self.reader.input.length()
    #|}
    #|
  write_reader_block(
    output,
    block.replace_all(
      old="__BIT_EOF__",
      new=if bits { "self.reader.bits_left == 0 && " } else { "" },
    ),
    root,
  )
}

///|
fn context_contains_decode(expression : Expr) -> Bool {
  expression_any(expression, fn(part) { part is Decode(_, _) })
}
