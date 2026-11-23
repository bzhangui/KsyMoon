///|
fn raw_uses_io(
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
  for field in fields {
    if field is @yaml.Map(properties) {
      let names = match properties.get("type") {
        Some(@yaml.String(name)) => [name]
        Some(@yaml.Map(kind)) =>
          match kind.get("cases") {
            Some(@yaml.Map(cases)) => {
              let names = []
              for _, value in cases {
                if value is @yaml.String(name) {
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
          raw_uses_io(nested, types, [..active, name]) {
          return true
        }
      }
    }
  }
  false
}

///|
priv struct ContextGraph {
  records : Map[String, RecordDef]
  parents : Map[String, Array[String]]
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
  for record in schema.records {
    records[record.name] = record
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
  { records, parents, }
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
    Nested(name) => Object([name])
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
    _ =>
      invalid(
        scope.path,
        "attribute requires an object, stream or supported collection",
      )
  }
}

///|
fn context_expression_type(
  scope : ContextScope,
  expression : Expr,
) -> ExprType raise SchemaError {
  match expression {
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
      guard kind == Integer || kind == Boolean || kind == Text else {
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
    ByteField(options) | Text(options, _) =>
      check_context_length(scope, options.length)
    Bounded(inner, options) => {
      check_context_length(scope, options.length)
      check_context_kind(scope, inner)
    }
    Switch(_, selector, cases, _) => {
      let expected = context_expression_type(scope, selector)
      for (tag, _) in cases {
        context_require(scope, tag, expected)
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
          guard kind == Integer || kind == Boolean || kind == Text else {
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
