///|
fn raw_uses_context(
  record : Map[String, @yaml.Yaml],
  types : Map[String, @yaml.Yaml],
  active : Array[String],
) -> Bool raise SchemaError {
  let fields = match record.get("seq") {
    Some(@yaml.Array(fields)) => fields.copy()
    _ => []
  }
  let sequence_count = fields.length()
  let instances = match record.get("instances") {
    Some(@yaml.Map(instances)) => instances
    _ => Map([])
  }
  let declarations : Map[String, @yaml.Yaml] = Map([])
  for field in fields {
    if field is @yaml.Map(properties) &&
      properties.get("id") is Some(@yaml.String(name)) {
      declarations[name] = field
    }
  }
  for name, value in instances {
    if value is @yaml.Map(properties) && properties.contains("io") {
      return true
    }
    declarations[name] = value
    fields.push(value)
  }
  let objects = []
  let text_types : Map[String, Bool] = Map([])
  let wide_fields = []
  let values : Map[String, Expr] = Map([])
  for name, declaration in declarations {
    if declaration is @yaml.Map(properties) {
      if properties.get("type") is Some(@yaml.String(kind)) {
        if types.contains(kind) {
          objects.push(name)
        }
        if kind is ("str" | "strz") {
          text_types[name] = true
        }
        if kind is ("u8" | "u8le" | "u8be") ||
          (bit_width(kind) is Some(width) && width > 32) {
          wide_fields.push(name)
        }
      }
      if properties.get("value") is Some(value) {
        values[name] = parse_expression(value, name) catch {
          _ => Expr::Integer(0L)
        }
      }
    }
  }
  let is_text = fn(expression) {
    raw_text_expression(expression, values, text_types)
  }
  for index, field in fields {
    if field is @yaml.Map(properties) {
      if properties.get("valid") is Some(value) &&
        raw_predicate_validation(properties, value) {
        return true
      }
      if properties.contains("enum") ||
        properties.contains("parent") ||
        properties.contains("process") ||
        (
          properties.get("type")
          is Some(@yaml.String("f4" | "f4le" | "f4be" | "f8" | "f8le" | "f8be")) &&
          record.contains("instances")
        ) {
        return true
      }
      let expressions = [
        "if", "pos", "size", "repeat-expr", "repeat-until", "value",
      ]
      for key in expressions {
        if properties.get(key) is Some(source) {
          let expression = parse_expression(source, key) catch {
            _ => Expr::Integer(0L)
          }
          let length = key is ("size" | "repeat-expr")
          let reads_instance = length ||
            (index < sequence_count && key is ("if" | "repeat-until"))
          if expression_needs_context(expression, is_text, fn(name) {
              wide_fields.contains(name) ||
              (reads_instance && instances.contains(name))
            }) ||
            (length && computed_read_length(expression)) ||
            (key == "value" && expression_returns_record(expression, objects)) {
            return true
          }
        }
      }
      if properties.get("type") is Some(@yaml.Map(kind)) &&
        kind.get("switch-on") is Some(source) &&
        expression_needs_context(
          parse_expression(source, "switch-on") catch {
            _ => Expr::Integer(0L)
          },
          is_text,
          fn(name) { wide_fields.contains(name) },
        ) {
        return true
      }
      let names = match properties.get("type") {
        Some(@yaml.String(name)) => {
          if name.contains("(") {
            return true
          }
          [name]
        }
        Some(@yaml.Map(kind)) =>
          match kind.get("cases") {
            Some(@yaml.Map(cases)) => {
              let names = []
              for _, value in cases {
                if value is @yaml.String(name) {
                  if name.contains("(") {
                    return true
                  }
                  names.push(name)
                }
              }
              names
            }
            _ => []
          }
        _ => []
      }
      for name in names {
        if !active.contains(name) &&
          types.get(name) is Some(@yaml.Map(nested)) &&
          raw_uses_context(nested, types, [..active, name]) {
          return true
        }
      }
    }
  }
  false
}

///|
fn computed_read_length(expression : Expr) -> Bool {
  match expression {
    Binary("-", Reference(_), Integer(amount)) if amount >= 0L => false
    Binary("+" | "-" | "*" | "/" | "%" | "<<" | ">>" | "&" | "|" | "^", _, _)
    | Choose(_, _, _)
    | StreamPosition
    | StreamSize => true
    _ => false
  }
}

///|
fn raw_text_expression(
  expression : Expr,
  aliases : Map[String, Expr],
  text_types : Map[String, Bool],
) -> Bool {
  match expression {
    Text(_) => true
    Reference(name) => {
      if text_types.get(name) is Some(known) {
        return known
      }
      guard aliases.get(name) is Some(value) else { return false }
      // Mark the alias before recursing. Type validation reports any cycle.
      text_types[name] = false
      let known = raw_text_expression(value, aliases, text_types)
      text_types[name] = known
      known
    }
    Binary("+", a, b) | Choose(_, a, b) =>
      raw_text_expression(a, aliases, text_types) ||
      raw_text_expression(b, aliases, text_types)
    _ => false
  }
}

///|
fn expression_needs_context(
  expression : Expr,
  is_text : (Expr) -> Bool,
  use_reference : (String) -> Bool,
) -> Bool {
  expression_any(expression, fn(value) {
    match value {
      Member(_, _)
      | Index(_, _)
      | Cast(_, _)
      | Decode(_, _)
      | ToInteger(_, _)
      | EnumLiteral(_, _)
      | ToEnum(_, _)
      | TypeSize(_, _)
      | Substring(_, _, _)
      | ArrayLiteral(_)
      | ByteLiteral(_)
      | WideLiteral(_) => true
      Reference("_root" | "_parent" | "_io" | "_sizeof" | "_bitsizeof") => true
      Reference(name) => use_reference(name)
      Binary("+" | "<" | "<=" | ">" | ">=", a, b) => is_text(a) || is_text(b)
      _ => false
    }
  })
}

///|
fn expression_returns_record(
  expression : Expr,
  objects : Array[String],
) -> Bool {
  match expression {
    Reference(name) => objects.contains(name)
    Choose(_, yes, no) =>
      expression_returns_record(yes, objects) ||
      expression_returns_record(no, objects)
    _ => false
  }
}

///|
priv struct ContextGraph {
  records : Map[String, RecordDef]
  parents : Map[String, Array[String]]
  tags : Map[String, Int32]
  type_scopes : Map[String, Map[String, String]]
  enum_scopes : Map[String, Map[String, String]]
  enums : Map[String, EnumDef]
  bits : Bool
  module_roots : Map[String, String]
  root_referenced : Bool
  mut needs_text_integer : Bool
  has_overridden_parent : Bool
  has_parent_expression : Bool
  mut object_refs : Bool
  byte_orders : Map[String, ByteOrder]
}

///|
priv struct ContextScope {
  graph : ContextGraph
  owner : String
  path : String
  active : Array[String]
  item : FieldKind?
  validated_field : String?
  index_allowed : Bool
  earlier : Int32?
}

///|
fn context_graph(schema : Schema) -> ContextGraph {
  let records = Map([])
  records["@root"] = schema.root
  let tags = Map([("@root", 0)])
  for index, record in schema.records {
    records[record.name] = record
    tags[record.name] = index + 1
  }
  let parents : Map[String, Array[String]] = Map([])
  for name, _ in records {
    parents[name] = []
  }
  let mut root_referenced = false
  let mut has_overridden_parent = false
  let explicit_parents = []
  for owner, record in records {
    let fields = record.fields.copy()
    for instance in record.instances {
      if instance.kind is Parsed(field, _) {
        fields.push(field)
      }
    }
    for field in fields {
      has_overridden_parent = has_overridden_parent ||
        !(field.parent is Implicit)
      if field.parent is Explicit(expression) {
        explicit_parents.push((owner, field, expression))
      }
      for child in kind_references(field.kind) {
        root_referenced = root_referenced || child == "@root"
        if field.parent is Implicit &&
          schema.module_roots.get(child) == schema.module_roots.get(owner) &&
          !parents[child].contains(owner) {
          parents[child].push(owner)
        }
      }
    }
  }
  let graph : ContextGraph = {
    records,
    parents,
    tags,
    type_scopes: schema.type_scopes,
    enum_scopes: schema.enum_scopes,
    enums: schema.enums,
    bits: schema_has_bits(schema),
    module_roots: schema.module_roots,
    root_referenced,
    needs_text_integer: false,
    has_overridden_parent,
    has_parent_expression: !explicit_parents.is_empty(),
    object_refs: records
    .values()
    .any(fn(record) {
      record.parameters
      .iter()
      .any(fn(parameter) { parameter_is_object(parameter.kind) })
    }),
    byte_orders: schema.byte_orders,
  }
  resolve_parent_overrides(graph, explicit_parents)
  graph
}

///|
fn resolve_parent_overrides(
  graph : ContextGraph,
  fields : Array[(String, Field, Expr)],
) -> Unit {
  // A parent expression can navigate an edge added by another override.
  let mut changed = true
  while changed {
    changed = false
    for item in fields {
      let (owner, field, expression) = item
      let scope = context_scope(
        graph,
        owner,
        owner + "." + field.name + ".parent",
        index_allowed=field.count is Some(_),
      )
      let result = context_expression_type(scope, expression) catch {
        _ => Object([])
      }
      if result is Object(parents) {
        for child in kind_references(field.kind) {
          for parent in parents {
            if parent != "@any" && !graph.parents[child].contains(parent) {
              graph.parents[child].push(parent)
              changed = true
            }
          }
        }
      }
    }
  }
}

///|
fn context_scope(
  graph : ContextGraph,
  owner : String,
  path : String,
  item~ : FieldKind? = None,
  validated_field~ : String? = None,
  index_allowed~ : Bool = false,
  earlier~ : Int32? = None,
  active~ : Array[String] = [],
) -> ContextScope {
  { graph, owner, path, item, validated_field, index_allowed, earlier, active, }
}

///|
fn context_merge(
  types : Array[ExprType],
  path : String,
) -> ExprType raise SchemaError {
  guard types.get(0) is Some(first) else { invalid(path, "type has no value") }
  if first is Object(_) {
    let names = []
    for kind in types {
      guard kind is Object(candidates) else {
        invalid(path, "incompatible object branches")
      }
      for name in candidates {
        if !names.contains(name) {
          names.push(name)
        }
      }
    }
    names.sort()
    Object(names)
  } else {
    guard types.iter().all(fn(kind) { kind == first }) else {
      invalid(path, "incompatible expression branches")
    }
    first
  }
}

///|
fn context_kind_type(
  kind : FieldKind,
  path : String,
) -> ExprType raise SchemaError {
  match kind {
    BitInteger(1, _) => Boolean
    Unsigned(_, _) | Signed(_, _) | Signed64(_) | BitInteger(_, _) => Integer
    Unsigned64(_) | WideBitInteger(_, _) => WideInteger
    Float32(_) | Float64(_) => Real
    Contents(_) | ByteField(_) => Bytes
    Text(_, _) => Text
    Bounded(inner, _) => context_kind_type(inner, path)
    Enumerated(_, name) => Enum(name)
    Nested(name) | Application(name, _) => Object([name])
    Switch(_, _, cases, fallback) => {
      let kinds = cases.map(fn(item) raise SchemaError {
        context_kind_type(item.1, path)
      })
      if fallback is Some(inner) {
        kinds.push(context_kind_type(inner, path))
      }
      context_merge(kinds, path)
    }
  }
}

///|
fn context_field_type(
  field : Field,
  path : String,
) -> ExprType raise SchemaError {
  let element = context_kind_type(field.kind, path)
  if field.count is Some(_) {
    Sequence(element)
  } else {
    element
  }
}

///|
fn context_attribute_type(
  scope : ContextScope,
  owner : String,
  name : String,
) -> ExprType raise SchemaError {
  guard scope.graph.records.get(owner) is Some(record) else {
    invalid(scope.path, "parent type is not known for this attribute")
  }
  for parameter in record.parameters {
    if parameter.name == name {
      return parameter.kind
    }
  }
  for index, field in record.fields {
    if field.name == name {
      if owner == scope.owner && scope.earlier is Some(limit) && index >= limit {
        invalid(scope.path, "unknown or forward field '" + name + "'")
      }
      return context_field_type(field, scope.path)
    }
  }
  let instance = record.instances
    .iter()
    .find_first(fn(item) { item.name == name })
  guard instance is Some(instance) else {
    invalid(scope.path, "unknown field or instance '" + name + "'")
  }
  match instance.kind {
    Parsed(field, _) => context_field_type(field, scope.path)
    Value(expression) => {
      let key = owner + "." + name
      guard !scope.active.contains(key) else {
        invalid(scope.path, "cyclic instance dependency at '" + name + "'")
      }
      context_expression_type(
        context_scope(
          scope.graph,
          owner,
          scope.path,
          active=[..scope.active, key],
        ),
        expression,
      )
    }
  }
}

///|
fn context_member_type(
  scope : ContextScope,
  target : ExprType,
  name : String,
) -> ExprType raise SchemaError {
  match target {
    Stream =>
      match name {
        "pos" | "size" => Integer
        "eof" => Boolean
        _ => invalid(scope.path, "unknown stream attribute '" + name + "'")
      }
    Object(owners) => {
      if name == "_io" {
        return Stream
      }
      if name == "_root" {
        let roots = []
        for owner in owners {
          let root = scope.graph.module_roots.get(owner).unwrap_or("@root")
          guard scope.graph.records.contains(root) else {
            invalid(
              scope.path,
              "module root is unavailable for a directly imported nested type",
            )
          }
          if !roots.contains(root) {
            roots.push(root)
          }
        }
        roots.sort()
        return Object(roots)
      }
      if name == "_parent" {
        let names = []
        for owner in owners {
          for parent in scope.graph.parents.get(owner).unwrap_or([]) {
            if !names.contains(parent) {
              names.push(parent)
            }
          }
        }
        if names.is_empty() {
          guard !owners.contains("@root") else {
            invalid(scope.path, "root object has no parent")
          }
          names.push("@any")
        }
        names.sort()
        return Object(names)
      }
      // Explicit object paths may refer to later root fields for lazy instances.
      let remote = context_scope(
        scope.graph,
        scope.owner,
        scope.path,
        active=scope.active,
        item=scope.item,
        index_allowed=scope.index_allowed,
      )
      context_merge(
        owners.map(fn(owner) raise SchemaError {
          context_attribute_type(remote, owner, name)
        }),
        scope.path,
      )
    }
    Sequence(_) | Bytes if name == "length" || name == "size" => Integer
    Sequence(element) if ["first", "last", "min", "max"].contains(name) =>
      element
    Bytes if ["first", "last", "min", "max"].contains(name) => Integer
    Enum(_) | Real | Boolean | Text if name == "to_i" => Integer
    Enum(_) if name == "_in_enum" => Boolean
    Text if name == "length" => Integer
    Text if name == "reverse" => Text
    Text | Integer | WideInteger if name == "@interpolate" => Text
    Integer if name == "to_s" => Text
    _ =>
      invalid(
        scope.path,
        "attribute requires an object, stream or supported collection",
      )
  }
}

///|
fn context_cast_target(
  scope : ContextScope,
  target : String,
) -> String raise SchemaError {
  let names = target.split("::").map(fn(part) { part.to_owned() }).collect()
  let visible = scope.graph.type_scopes[scope.owner]
  guard visible.contains(names[0]) else {
    invalid(scope.path, "unknown cast target '" + target + "'")
  }
  let name = scoped_type_name(target, visible)
  guard scope.graph.records.contains(name) else {
    invalid(scope.path, "unknown cast target '" + target + "'")
  }
  name
}

///|
fn context_expression_type(
  scope : ContextScope,
  expression : Expr,
) -> ExprType raise SchemaError {
  match expression {
    ArrayLiteral(values) => {
      let kinds = values.map(fn(value) raise SchemaError {
        context_expression_type(scope, value)
      })
      let element = if kinds.iter().any(fn(kind) { kind == Real }) &&
        kinds.iter().all(fn(kind) { kind == Real || kind == Integer }) {
        Real
      } else {
        context_merge(kinds, scope.path)
      }
      Sequence(element)
    }
    Decode(bytes, _) => {
      context_require(scope, bytes, Bytes)
      Text
    }
    ToInteger(value, radix) => {
      context_require(scope, value, Text)
      context_require(scope, radix, Integer)
      Integer
    }
    Substring(value, start, end) => {
      context_require(scope, value, Text)
      context_require(scope, start, Integer)
      context_require(scope, end, Integer)
      Text
    }
    EnumLiteral(name, label) => Enum(context_enum_label(scope, name, label).0)
    ToEnum(value, name) => {
      ignore(context_enum(scope, name))
      context_require(scope, value, Integer)
      Enum(name)
    }
    Cast(base, "bytes") => {
      guard context_expression_type(scope, base)
        is (Bytes | Sequence(Integer | WideInteger)) else {
        invalid(scope.path, "byte cast needs an integer array or bytes")
      }
      Bytes
    }
    Cast(base, target) if integer_array_cast(target) is Some(kind) => {
      guard context_expression_type(scope, base) == Sequence(kind) else {
        invalid(scope.path, "array cast needs matching integer elements")
      }
      Sequence(kind)
    }
    Cast(base, target) if integer_cast(target) is Some(_) => {
      let kind = context_expression_type(scope, base)
      guard kind == Integer || kind == WideInteger else {
        invalid(scope.path, "integer cast needs an integer source")
      }
      if target == "u8" {
        WideInteger
      } else {
        Integer
      }
    }
    Cast(base, target) => {
      let name = context_cast_target(scope, target)
      let source = context_expression_type(scope, base)
      guard source is Object(owners) &&
        (owners.contains(name) || owners.contains("@any")) else {
        invalid(
          scope.path,
          "cast target '" + target + "' is not a possible object type",
        )
      }
      Object([name])
    }
    Member(_, "_sizeof" | "_bitsizeof")
    | Reference("_sizeof" | "_bitsizeof")
    | TypeSize(_, _) => {
      ignore(size_expression(scope, expression))
      Integer
    }
    Member(base, name) =>
      context_member_type(scope, context_expression_type(scope, base), name)
    Index(base, index) => {
      context_require(scope, index, Integer)
      match context_expression_type(scope, base) {
        Sequence(element) => element
        Bytes => Integer
        _ => invalid(scope.path, "index requires an array or bytes")
      }
    }
    Reference("_root") =>
      context_member_type(scope, Object([scope.owner]), "_root")
    Reference("_parent") =>
      context_member_type(scope, Object([scope.owner]), "_parent")
    Reference("_io") => Stream
    Reference("_index") => {
      guard scope.index_allowed else {
        invalid(scope.path, "_index requires an element repetition context")
      }
      Integer
    }
    Reference(name) if name == "_" ||
      scope.validated_field == Some(name) ||
      name.has_prefix("_.") => {
      guard scope.item is Some(kind) else {
        invalid(scope.path, "current item is only available in repeat-until")
      }
      let element = context_kind_type(kind, scope.path)
      if name == "_" || scope.validated_field == Some(name) {
        element
      } else {
        context_member_type(scope, element, name[2:].to_owned())
      }
    }
    Reference(name) => context_attribute_type(scope, scope.owner, name)
    Choose(condition, yes, no) => {
      context_require(scope, condition, Boolean)
      let types = (
        context_expression_type(scope, yes),
        context_expression_type(scope, no),
      )
      if types is ((Integer, Real) | (Real, Integer)) {
        Real
      } else {
        context_merge([types.0, types.1], scope.path)
      }
    }
    Unary(op, value) => {
      let kind = context_expression_type(scope, value)
      if op == "not" {
        guard kind == Boolean else {
          invalid(scope.path, "logical operand must be boolean")
        }
      } else {
        guard kind == Integer || (kind == Real && (op == "+" || op == "-")) else {
          invalid(scope.path, "unary operator needs a numeric operand")
        }
      }
      kind
    }
    Binary(op, left, right) => {
      let a = context_expression_type(scope, left)
      let b = context_expression_type(scope, right)
      if a == Real || b == Real {
        ignore(context_real_binary(scope, left, right))
        match op {
          "+" | "-" | "*" | "/" => Real
          "==" | "!=" | "<" | "<=" | ">" | ">=" => Boolean
          _ => invalid(scope.path, "operator is unsupported for real operands")
        }
      } else if mixed_integer_comparison(op, a, b) {
        Boolean
      } else {
        guard a == b else {
          if a is Enum(name) {
            invalid(scope.path, "expected enum '" + name + "'")
          }
          invalid(scope.path, "expression operands have different types")
        }
        match op {
          "and" | "or" => {
            guard a == Boolean else {
              invalid(scope.path, "logical operands must be boolean")
            }
            Boolean
          }
          "==" | "!=" => {
            guard a
              is (Integer
              | WideInteger
              | Boolean
              | Text
              | Bytes
              | Enum(_)
              | Sequence(_)) else {
              invalid(
                scope.path,
                "comparison of this value type awaits implementation",
              )
            }
            Boolean
          }
          "<" | "<=" | ">" | ">=" => {
            guard a is (Integer | WideInteger | Text | Bytes) else {
              invalid(
                scope.path,
                "ordering requires numeric, string or binary values",
              )
            }
            Boolean
          }
          "+" if a == Text => Text
          _ => {
            guard a == Integer else {
              invalid(scope.path, "operator requires integer operands")
            }
            Integer
          }
        }
      }
    }
    _ =>
      expression_type(
        expression,
        fn(name) raise SchemaError {
          context_expression_type(scope, Reference(name))
        },
        scope.path,
        navigation=Some(fn(value) raise SchemaError {
          context_expression_type(scope, value)
        }),
      )
  }
}

///|
fn context_require(
  scope : ContextScope,
  expression : Expr,
  expected : ExprType,
) -> Unit raise SchemaError {
  guard context_expression_type(scope, expression) == expected else {
    invalid(
      scope.path,
      if expected == Stream {
        "expected a stream expression"
      } else if expected == Boolean {
        "expected a boolean expression"
      } else if expected == Text {
        "expected a string expression"
      } else if expected is Enum(name) {
        "expected enum '" + name + "'"
      } else {
        "expected an integer expression"
      },
    )
  }
}

///|
fn check_context_kind(
  scope : ContextScope,
  kind : FieldKind,
) -> Unit raise SchemaError {
  match kind {
    Nested(name) => {
      guard scope.graph.records[name].parameters.is_empty() else {
        invalid(scope.path, "type '" + name + "' requires arguments")
      }
    }
    Application(name, arguments) => {
      let parameters = scope.graph.records[name].parameters
      guard arguments.length() == parameters.length() else {
        invalid(scope.path, "wrong number of arguments for type '" + name + "'")
      }
      for index, argument in arguments {
        let expected = parameters[index].kind
        let actual = context_expression_type(scope, argument)
        guard parameter_kind_matches(actual, expected) else {
          if expected is (Object(_) | Sequence(_)) {
            invalid(
              scope.path,
              "type mismatch for parameter '" + parameters[index].name + "'",
            )
          }
          context_require(scope, argument, expected)
          continue
        }
      }
    }
    Enumerated(_, name) => ignore(context_enum(scope, name))
    ByteField(options) | Text(options, _) =>
      check_context_byte_options(scope, options)
    Bounded(inner, options) => {
      check_context_byte_options(scope, options)
      check_context_kind(scope, inner)
    }
    Switch(_, selector, cases, _) => {
      let expected = context_expression_type(scope, selector)
      for (tag, branch) in cases {
        context_require(scope, tag, expected)
        check_context_kind(scope, branch)
      }
      if kind is Switch(_, _, _, Some(branch)) {
        check_context_kind(scope, branch)
      }
    }
    _ => ()
  }
}

///|
fn check_context_byte_options(
  scope : ContextScope,
  options : ByteOptions,
) -> Unit raise SchemaError {
  check_context_length(scope, options.length)
  match options.processor {
    Some(Xor(key, mask)) =>
      context_require(scope, key, if mask { Bytes } else { Integer })
    Some(Rotate(count, _)) => context_require(scope, count, Integer)
    _ => ()
  }
}

///|
fn check_context_length(
  scope : ContextScope,
  length : LengthExpr?,
) -> Unit raise SchemaError {
  if length is Some(Calculated(expression)) {
    guard context_expression_type(scope, expression) is (Integer | WideInteger) else {
      invalid(scope.path, "expected an integer expression")
    }
  }
}

///|
fn check_context_field(
  scope : ContextScope,
  field : Field,
) -> Unit raise SchemaError {
  if field.parent is Explicit(expression) {
    let scope = { ..scope, index_allowed: field.count is Some(_), }
    guard context_expression_type(scope, expression) is Object(_) else {
      invalid(scope.path + ".parent", "expected an object expression")
    }
  }
  if field.condition is Some(expression) {
    context_require(scope, expression, Boolean)
  }
  if field.count is Some(Times(count)) {
    check_context_length(scope, Some(count))
  }
  let item_scope = context_scope(
    scope.graph,
    scope.owner,
    scope.path,
    earlier=scope.earlier,
    index_allowed=field.count is Some(_),
  )
  check_context_kind(item_scope, field.kind)
  if field.predicate is Some(predicate) {
    context_require(
      context_scope(
        scope.graph,
        scope.owner,
        scope.path,
        earlier=scope.earlier,
        item=Some(field.kind),
        validated_field=Some(field.name),
        index_allowed=field.count is Some(_),
      ),
      predicate,
      Boolean,
    )
  }
  if field.count is Some(Until(expression)) {
    context_require(
      context_scope(
        scope.graph,
        scope.owner,
        scope.path,
        earlier=scope.earlier,
        item=Some(field.kind),
        index_allowed=true,
      ),
      expression,
      Boolean,
    )
  }
}

///|
fn check_context_schema(schema : Schema) -> Unit raise SchemaError {
  let graph = context_graph(schema)
  for owner, record in graph.records {
    if graph.byte_orders.get(owner) is Some(ChooseOrder(selector, cases, _)) {
      let scope = context_scope(
        graph,
        owner,
        owner + ".meta.endian",
        earlier=Some(0),
      )
      let kind = context_expression_type(scope, selector)
      for (tag, _) in cases {
        context_require(scope, tag, kind)
      }
    }
    for index, field in record.fields {
      check_context_field(
        context_scope(
          graph,
          owner,
          owner + ".seq." + field.name,
          earlier=Some(index),
        ),
        field,
      )
    }
    for instance in record.instances {
      let scope = context_scope(
        graph,
        owner,
        owner + ".instances." + instance.name,
        active=[owner + "." + instance.name],
      )
      if instance.condition is Some(expression) {
        context_require(scope, expression, Boolean)
      }
      if instance.io is Some(expression) {
        context_require(scope, expression, Stream)
      }
      match instance.kind {
        Value(expression) => {
          let kind = context_expression_type(scope, expression)
          guard kind == Integer ||
            kind == Boolean ||
            kind == Text ||
            kind == Bytes ||
            kind == WideInteger ||
            kind == Real ||
            kind is Stream ||
            kind is Sequence(_) ||
            kind is Object(_) ||
            kind is Enum(_) else {
            invalid(scope.path, "value instance type awaits implementation")
          }
        }
        Parsed(field, position) => {
          if position is Some(expression) {
            context_require(scope, expression, Integer)
          }
          check_context_field(scope, field)
        }
      }
    }
  }
}
