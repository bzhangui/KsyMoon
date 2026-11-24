///|
/// Validates a schema with explicit import names and original KSY text.
/// The keys are the names declared under meta.imports (for example "/common/riff").
pub fn validate_with_imports(
  source : String,
  imports : Map[String, String],
) -> Unit raise SchemaError {
  ignore(load_schema(source, imports~))
}

///|
/// Compiles a schema with an explicit set of imported documents.
pub fn generate_with_imports(
  source : String,
  imports : Map[String, String],
) -> String raise SchemaError {
  generate_schema(load_schema(source, imports~))
}

///|
priv struct SchemaImports {
  sources : Map[String, String]
  aliases : Map[String, String]
  modules : Map[String, @yaml.Yaml]
  visibility : Map[String, Array[String]]
  active : Array[String]
  root_id : String
}

///|
fn document_mapping(
  source : String,
  path : String,
) -> Map[String, @yaml.Yaml] raise SchemaError {
  guard load_ksy_yaml(source) is [document] else {
    invalid(path, "expected one YAML document")
  }
  as_mapping(document, path)
}

///|
fn import_names(
  mapping : Map[String, @yaml.Yaml],
  path : String,
) -> Array[String] raise SchemaError {
  match mapping.get("imports") {
    None => []
    Some(@yaml.Array(items)) => {
      guard items.length() <= 16 else {
        invalid(path, "at most 16 imports per document")
      }
      let names = []
      for value in items {
        let name = as_string(value, path)
        let segments = name
          .split("/")
          .map(fn(part) { part.to_owned() })
          .collect()
        let first = if name.has_prefix("/") { 1 } else { 0 }
        guard first < segments.length() else {
          invalid(path, "empty import name")
        }
        for index in first..<segments.length() {
          check_identifier(segments[index], path)
        }
        guard !names.contains(name) else {
          invalid(path, "duplicate import '" + name + "'")
        }
        names.push(name)
      }
      names
    }
    _ => invalid(path, "expected a sequence of import names")
  }
}

///|
fn resolve_import(
  graph : SchemaImports,
  key : String,
) -> String raise SchemaError {
  let path = "meta.imports." + key
  guard !graph.active.contains(key) else {
    invalid(path, "cyclic import: " + [..graph.active, key].join(" -> "))
  }
  if graph.aliases.get(key) is Some(name) {
    return name
  }
  guard graph.aliases.length() < 16 else {
    invalid(path, "at most 16 imported documents")
  }
  guard graph.sources.get(key) is Some(source) else {
    invalid(path, "missing imported description '" + key + "'")
  }
  let document = document_mapping(source, path)
  check_keys(
    document,
    ["meta", "types", "seq", "instances", "enums", "params", "doc", "doc-ref"],
    path,
  )
  let meta = as_mapping(get_required(document, "meta", path), path + ".meta")
  check_keys(
    meta,
    [
      "id", "endian", "bit-endian", "encoding", "imports", "title", "application",
      "file-extension", "xref", "license", "tags", "ks-version",
    ],
    path + ".meta",
  )
  let id = as_string(get_required(meta, "id", path), path + ".meta.id")
  check_identifier(id, path + ".meta.id")
  guard id != graph.root_id &&
    !graph.aliases.values().any(fn(name) { name == id }) else {
    invalid(path, "imported module has a conflicting id '" + id + "'")
  }
  graph.aliases[key] = id
  graph.active.push(key)
  defer ignore(graph.active.pop())
  let dependencies = import_names(meta, path + ".meta.imports").map(fn(
    key,
  ) raise SchemaError {
    resolve_import(graph, key)
  })
  graph.visibility[id] = dependencies
  let module_meta = Map([])
  for key in ["endian", "encoding", "bit-endian"] {
    if meta.get(key) is Some(value) {
      module_meta[key] = value
    }
  }
  let linked = document.copy()
  linked["meta"] = @yaml.Map(module_meta)
  graph.modules[id] = @yaml.Map(linked)
  id
}

///|
fn link_imports(
  root : Map[String, @yaml.Yaml],
  meta : Map[String, @yaml.Yaml],
  id : String,
  imports : Map[String, String],
) -> (Map[String, @yaml.Yaml], Map[String, Array[String]]) raise SchemaError {
  let names = import_names(meta, "meta.imports")
  if names.is_empty() {
    return (root, Map([]))
  }
  let graph : SchemaImports = {
    sources: imports,
    aliases: Map([]),
    modules: Map([]),
    visibility: Map([]),
    active: [],
    root_id: id,
  }
  graph.visibility["@root"] = names.map(fn(key) raise SchemaError {
    resolve_import(graph, key)
  })
  let types = match root.get("types") {
    Some(raw) => as_mapping(raw, "types").copy()
    None => Map([])
  }
  for name, value in graph.modules {
    guard !types.contains(name) else {
      invalid(
        "meta.imports",
        "imported module collides with local type '" + name + "'",
      )
    }
    types[name] = value
  }
  let linked = root.copy()
  linked["types"] = @yaml.Map(types)
  (linked, graph.visibility)
}
