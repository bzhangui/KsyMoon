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
  if record.get("instances") is Some(@yaml.Map(instances)) {
    for _, value in instances {
      if value is @yaml.Map(properties) && properties.contains("io") {
        return true
      }
      fields.push(value)
    }
  }
  let objects = []
  for field in fields {
    if field is @yaml.Map(properties) &&
      properties.get("id") is Some(@yaml.String(name)) &&
      properties.get("type") is Some(@yaml.String(kind)) &&
      types.contains(kind) {
      objects.push(name)
    }
  }
  if record.get("instances") is Some(@yaml.Map(instances)) {
    for name, value in instances {
      if value is @yaml.Map(properties) &&
        properties.get("type") is Some(@yaml.String(kind)) &&
        types.contains(kind) {
        objects.push(name)
      }
    }
  }
  for field in fields {
    if field is @yaml.Map(properties) {
      if properties.contains("enum") {
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
          if expression_needs_context(expression) ||
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
fn expression_needs_context(expression : Expr) -> Bool {
  match expression {
    Member(_, _)
    | Index(_, _)
    | Cast(_, _)
    | EnumLiteral(_, _)
    | ToEnum(_, _) => true
    Reference("_root" | "_parent" | "_io") => true
    Unary(_, value) => expression_needs_context(value)
    Binary(_, left, right) =>
      expression_needs_context(left) || expression_needs_context(right)
    Choose(condition, yes, no) =>
      expression_needs_context(condition) ||
      expression_needs_context(yes) ||
      expression_needs_context(no)
    _ => false
  }
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
}

///|
priv struct ContextScope {
  graph : ContextGraph
  owner : String
  path : String
  active : Array[String]
  item : FieldKind?
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
  for owner, record in records {
    let fields = record.fields.copy()
    for instance in record.instances {
      if instance.kind is Parsed(field, _) {
        fields.push(field)
      }
    }
    for field in fields {
      for child in kind_references(field.kind) {
        if !parents[child].contains(owner) {
          parents[child].push(owner)
        }
      }
    }
  }
  {
    records,
    parents,
    tags,
    type_scopes: schema.type_scopes,
    enum_scopes: schema.enum_scopes,
    enums: schema.enums,
  }
}

///|
fn context_scope(
  graph : ContextGraph,
  owner : String,
  path : String,
  item~ : FieldKind? = None,
  index_allowed~ : Bool = false,
  earlier~ : Int32? = None,
  active~ : Array[String] = [],
) -> ContextScope {
  { graph, owner, path, item, index_allowed, earlier, active, }
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
    Unsigned(_, _) | Signed(_, _) => Integer
    Unsigned64(_) => WideInteger
    Float32(_) => Real
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
        return Object(["@root"])
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
    Sequence(_) | Bytes if name == "length" => Integer
    Enum(_) if name == "to_i" => Integer
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
  guard visible.get(names[0]) is Some(first) else {
    invalid(scope.path, "unknown cast target '" + target + "'")
  }
  let name = [first, ..names[1:].to_owned()].join("_")
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
    EnumLiteral(name, label) => Enum(context_enum_label(scope, name, label).0)
    ToEnum(value, name) => {
      ignore(context_enum(scope, name))
      context_require(scope, value, Integer)
      Enum(name)
    }
    Cast(base, target) => {
      let name = context_cast_target(scope, target)
      let source = context_expression_type(scope, base)
      guard source is Object(owners) && owners.contains(name) else {
        invalid(
          scope.path,
          "cast target '" + target + "' is not a possible object type",
        )
      }
      Object([name])
    }
    Member(base, name) =>
      context_member_type(scope, context_expression_type(scope, base), name)
    Index(base, index) => {
      context_require(scope, index, Integer)
      guard context_expression_type(scope, base) is Sequence(element) else {
        invalid(scope.path, "index requires an array")
      }
      element
    }
    Reference("_root") => Object(["@root"])
    Reference("_parent") =>
      context_member_type(scope, Object([scope.owner]), "_parent")
    Reference("_io") => Stream
    Reference("_index") => {
      guard scope.index_allowed else {
        invalid(scope.path, "_index requires an element repetition context")
      }
      Integer
    }
    Reference(name) if name == "_" || name.has_prefix("_.") => {
      guard scope.item is Some(kind) else {
        invalid(scope.path, "current item is only available in repeat-until")
      }
      let element = context_kind_type(kind, scope.path)
      if name == "_" {
        element
      } else {
        context_member_type(scope, element, name[2:].to_owned())
      }
    }
    Reference(name) => context_attribute_type(scope, scope.owner, name)
    Choose(condition, yes, no) => {
      context_require(scope, condition, Boolean)
      context_merge(
        [
          context_expression_type(scope, yes),
          context_expression_type(scope, no),
        ],
        scope.path,
      )
    }
    Binary("==" | "!=", left, right) => {
      let kind = context_expression_type(scope, left)
      guard kind == Integer ||
        kind == Boolean ||
        kind == Text ||
        kind is Enum(_) else {
        invalid(
          scope.path,
          "comparison of this value type awaits implementation",
        )
      }
      context_require(scope, right, kind)
      Boolean
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
        context_require(scope, argument, parameters[index].kind)
      }
    }
    Enumerated(_, name) => ignore(context_enum(scope, name))
    ByteField(options) | Text(options, _) =>
      check_context_length(scope, options.length)
    Bounded(inner, options) => {
      check_context_length(scope, options.length)
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
fn check_context_length(
  scope : ContextScope,
  length : LengthExpr?,
) -> Unit raise SchemaError {
  if length is Some(Calculated(expression)) {
    context_require(scope, expression, Integer)
  }
}

///|
fn check_context_field(
  scope : ContextScope,
  field : Field,
) -> Unit raise SchemaError {
  if field.condition is Some(expression) {
    context_require(scope, expression, Boolean)
  }
  if field.count is Some(Times(Calculated(expression))) {
    context_require(scope, expression, Integer)
  }
  let item_scope = context_scope(
    scope.graph,
    scope.owner,
    scope.path,
    earlier=scope.earlier,
    index_allowed=field.count is Some(_),
  )
  check_context_kind(item_scope, field.kind)
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
            kind is Stream ||
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
