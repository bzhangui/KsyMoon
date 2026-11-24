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
/// A resolved import, using project-relative paths or an @-prefixed alias.
pub(all) struct ImportEdge {
  importer : String
  import_name : String
  target : String
}

///|
/// Compiles a project using slash-separated paths relative to its root.
/// Read callbacks receive normalized in-project paths ending in .ksy.
pub fn generate_project(
  source : String,
  entry : String,
  search : Array[String],
  read : (String) -> String?,
  imports~ : Map[String, String] = Map([]),
  on_import~ : (ImportEdge) -> Unit = fn(_) { () },
) -> String raise SchemaError {
  generate_schema(
    load_schema(source, imports~, entry=Some(entry), search~, read~, on_import~),
  )
}

///|
/// Validates a project with the same import lookup used by generate_project.
pub fn validate_project(
  source : String,
  entry : String,
  search : Array[String],
  read : (String) -> String?,
  imports~ : Map[String, String] = Map([]),
  on_import~ : (ImportEdge) -> Unit = fn(_) { () },
) -> Unit raise SchemaError {
  ignore(
    load_schema(source, imports~, entry=Some(entry), search~, read~, on_import~),
  )
}

///|
priv struct SchemaImports {
  overrides : Map[String, String]
  search : Array[String]
  read : (String) -> String?
  files : Map[String, String]
  modules : Map[String, @yaml.Yaml]
  visibility : Map[String, Map[String, String]]
  root_id : String
  on_import : (ImportEdge) -> Unit
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
          let segment = segments[index]
          if segment != ".." && segment != "." {
            check_identifier(segment, path)
          }
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
fn project_path(directory : String, name : String) -> String? {
  let normalized : Array[String] = []
  for part in (directory + "/" + name).split("/") {
    match part {
      "" | "." => ()
      ".." => if normalized.pop() is None { return None }
      _ => normalized.push(part.to_owned())
    }
  }
  Some(normalized.join("/"))
}

///|
fn import_source(
  graph : SchemaImports,
  from : String?,
  key : String,
  path : String,
) -> (String, String?, String) raise SchemaError {
  if graph.overrides.get(key) is Some(source) {
    // Explicit aliases remain keyed by the name supplied by the caller.
    return ("@" + key, None, source)
  }
  if from is Some(file) {
    let (directories, requested) = if key.has_prefix("/") {
      guard project_path("", key + ".ksy") is Some(relative) else {
        invalid(path, "absolute import path leaves its search directory")
      }
      (graph.search, relative)
    } else {
      let parts = file.split("/").map(fn(part) { part.to_owned() }).collect()
      ignore(parts.pop())
      ([parts.join("/")], key + ".ksy")
    }
    for directory in directories {
      guard project_path(directory, requested) is Some(candidate) else {
        invalid(path, "import path leaves the project root")
      }
      if (graph.read)(candidate) is Some(source) {
        return (candidate, Some(candidate), source)
      }
    }
  }
  invalid(path, "missing imported description '" + key + "'")
}

///|
fn resolve_import(
  graph : SchemaImports,
  from : String?,
  key : String,
) -> (String, String) raise SchemaError {
  let path = "meta.imports." + key
  let (file, location, source) = import_source(graph, from, key, path)
  (graph.on_import)({
    importer: from.unwrap_or("@" + graph.root_id),
    import_name: key,
    target: file,
  })
  if graph.files.get(file) is Some(owner) {
    return (if owner == "@root" { graph.root_id } else { owner }, owner)
  }
  guard graph.files.length() < 17 else {
    invalid(path, "at most 16 imported documents")
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
      "id", "endian", "encoding", "bit-endian", "imports", "title", "application",
      "file-extension", "xref", "license", "tags", "ks-version",
    ],
    path + ".meta",
  )
  let id = as_string(get_required(meta, "id", path), path + ".meta.id")
  check_identifier(id, path + ".meta.id")
  guard id != graph.root_id &&
    !graph.files.values().any(fn(owner) { owner == id }) else {
    invalid(path, "imported module has a conflicting id '" + id + "'")
  }
  graph.files[file] = id
  graph.visibility[id] = import_scope(
    graph,
    meta,
    location,
    path + ".meta.imports",
  )
  let module_meta = Map([])
  for key in ["endian", "encoding", "bit-endian"] {
    if meta.get(key) is Some(value) {
      module_meta[key] = value
    }
  }
  let linked = document.copy()
  linked["meta"] = @yaml.Map(module_meta)
  graph.modules[id] = @yaml.Map(linked)
  (id, id)
}

///|
fn import_scope(
  graph : SchemaImports,
  meta : Map[String, @yaml.Yaml],
  from : String?,
  path : String,
) -> Map[String, String] raise SchemaError {
  let declarations = Map([])
  for name in import_names(meta, path) {
    let (id, owner) = resolve_import(graph, from, name)
    declarations[id] = owner
  }
  declarations
}

///|
fn link_imports(
  root : Map[String, @yaml.Yaml],
  meta : Map[String, @yaml.Yaml],
  id : String,
  imports : Map[String, String],
  entry : String?,
  search : Array[String],
  read : (String) -> String?,
  on_import : (ImportEdge) -> Unit,
) -> (Map[String, @yaml.Yaml], Map[String, Map[String, String]]) raise SchemaError {
  if import_names(meta, "meta.imports").is_empty() {
    return (root, Map([]))
  }
  let graph : SchemaImports = {
    overrides: imports,
    search,
    read,
    files: Map([(entry.unwrap_or("@entry"), "@root")]),
    modules: Map([]),
    visibility: Map([]),
    root_id: id,
    on_import,
  }
  graph.visibility["@root"] = import_scope(graph, meta, entry, "meta.imports")
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
