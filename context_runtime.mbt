///|
fn context_flags(schema : Schema) -> Array[String] raise SchemaError {
  let flags = []
  let add = fn(name) { if !flags.contains(name) { flags.push(name) } }
  let graph = context_graph(schema)
  for owner, record in graph.records {
    for parameter in record.parameters {
      if parameter.kind == Text {
        add("text")
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
          Unsigned64(_) => add("wide")
          Float32(_) => add("float")
          Switch(_, _, _, _) => add("selected")
          Bounded(Switch(_, _, _, None), _) => add("binary")
          _ => ()
        }
      }
    }
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
  index : Bool,
  objects : Bool,
) -> Unit {
  output.write_string(
    "///|\npriv enum \{root}Value {\n  Number(Int64)\n  Flag(Bool)\n  ObjectId(Int)\n  Source(\{root}Reader)\n  Absent\n",
  )
  for
    (name, definition) in [
      ("text", "StringValue(String)"),
      ("binary", "Binary(BytesView)"),
      ("wide", "Wide(UInt64)"),
      ("float", "FloatValue(Float)"),
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
    #|  parent : Int
    #|  reader : __ROOT__Reader
    #|__PATH_FIELD__
    #|  children : Array[Int]
    #|  fields : Map[String, __ROOT__Value]
    #|  cache : Map[String, __ROOT__Value]
    #|  partial : Map[String, __ROOT__Value]
    #|__BUSY_FIELD__
    #|__DEPTH_FIELD____ACCOUNT_FIELD____MODULE_FIELDS__}
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
    #|__DEPTH_CHECK____MODULE_SETUP__  let frame : __ROOT__Context = { tag, parent, reader, __PATH_INIT__children: [], fields: Map([]), cache: Map([]), partial: Map([])__BUSY_INIT____DEPTH_INIT____ACCOUNT_INIT____MODULE_INIT__ }
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
      old="__MODULE_FIELDS__",
      new=if modules {
        "  module_id : String\n  mut module_root : Int\n  logical_parent : Int\n"
      } else {
        ""
      },
    )
    .replace_all(
      old="__MODULE_ARG__",
      new=if modules { ", module_id : String, module_entry : Bool" } else { "" },
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
        ", module_id, module_root: if same_module { self.frames[parent].unwrap().module_root } else { -1 }, logical_parent: if same_module { parent } else { -1 }"
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
    #|fn __ROOT__Value::attribute(self : __ROOT__Value, arena : __ROOT__Arena, name : String, field : String) -> __ROOT__Value raise __ROOT__ParseError {
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
  if flags.contains("float") {
    extra.write_string("    FloatValue(value) => { ignore(value); Absent }\n")
  }
  if flags.contains("binary") {
    extra.write_string("    Binary(_) => Absent\n")
  }
  if flags.contains("items") {
    extra.write_string("    Items(_) => Absent\n")
  }
  write_reader_block(
    output,
    block
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
    Binary(_, a, b) => context_contains_index(a) || context_contains_index(b)
    Choose(a, b, c) =>
      context_contains_index(a) ||
      context_contains_index(b) ||
      context_contains_index(c)
    _ => false
  }
}

///|
fn context_all_expressions(schema : Schema) -> Array[Expr] {
  let expressions = []
  for record in [schema.root, ..schema.records] {
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
      if field.condition is Some(value) {
        expressions.push(value)
      }
      match field.count {
        Some(Times(Calculated(value))) | Some(Until(value)) =>
          expressions.push(value)
        _ => ()
      }
    }
  }
  expressions
}

///|
fn context_contains_cast(expression : Expr) -> Bool {
  match expression {
    Cast(_, _) => true
    Member(base, _) | Decode(base, _) | ToEnum(base, _) | Unary(_, base) =>
      context_contains_cast(base)
    Index(base, index) | Binary(_, base, index) =>
      context_contains_cast(base) || context_contains_cast(index)
    Choose(a, b, c) =>
      context_contains_cast(a) ||
      context_contains_cast(b) ||
      context_contains_cast(c)
    _ => false
  }
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
  match expression {
    Decode(_, _) => true
    Member(base, _) | Cast(base, _) | ToEnum(base, _) | Unary(_, base) =>
      context_contains_decode(base)
    Binary(_, a, b) | Index(a, b) =>
      context_contains_decode(a) || context_contains_decode(b)
    Choose(a, b, c) =>
      context_contains_decode(a) ||
      context_contains_decode(b) ||
      context_contains_decode(c)
    _ => false
  }
}
