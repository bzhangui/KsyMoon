///|
fn relative_path(root : String, file : String) -> String raise {
  let relative = @path.Path::relative(@path.Path(file), base=@path.Path(root))
  let name = relative.0.replace_all(old="\\", new="/")
  guard !relative.is_absolute() && name != ".." && !name.has_prefix("../") else {
    raise CommandError("path leaves the project root: " + file)
  }
  name
}

///|
async fn read_import(root : String, name : String) -> String? {
  let input = @path.Path(root).join(@path.Path(name)).0
  try {
    let canonical = @fs.realpath(input[:])
    ignore(relative_path(root, canonical))
    match @fs.kind(canonical[:]) {
      Regular => Some(@fs.read_text(canonical[:]))
      _ => None
    }
  } catch {
    CommandError(_) | @os_error.OsError(NotFound | NotDirectory, ..) => None
    error => raise error
  }
}

///|
async fn compile_input(
  input : String,
  options : Options,
  generate~ : Bool,
) -> (String, String, Array[@codegen.ImportEdge]) {
  let root_arg = options.root.unwrap_or(@path.Path(input).dirname().0)
  let root = @fs.realpath(root_arg[:])
  let canonical = @fs.realpath(input[:])
  let entry = relative_path(root, canonical)
  let source = @fs.read_text(canonical[:])
  let search = []
  for dir in options.search {
    let canonical = @fs.realpath(dir[:])
    guard @fs.kind(canonical[:]) is Directory else {
      raise CommandError("not an import directory: " + dir)
    }
    search.push(relative_path(root, canonical))
  }
  search.push("")
  let imports = Map([])
  for name, path in options.imports {
    imports[name] = @fs.read_text(path[:])
  }
  let cache : Map[String, String?] = Map([(entry, Some(source))])
  // The library resolves imports synchronously. Load requested paths between
  // attempts, including missing paths, and preserve the search order on retry.
  while true {
    let pending : Map[String, Unit] = Map([])
    let edges : Array[@codegen.ImportEdge] = []
    let on_import = fn(edge) { edges.push(edge) }
    let read = fn(name) {
      match cache.get(name) {
        Some(value) => value
        None => {
          pending[name] = ()
          None
        }
      }
    }
    let result = try {
      let code = if generate {
        @codegen.generate_project(
          source,
          entry,
          search,
          read,
          imports~,
          on_import~,
        )
      } else {
        @codegen.validate_project(
          source,
          entry,
          search,
          read,
          imports~,
          on_import~,
        )
        ""
      }
      Ok(code)
    } catch {
      error => Err(error)
    }
    if pending.is_empty() {
      return match result {
        Ok(code) => (code, entry, edges)
        Err(error) => raise error
      }
    }
    for name in pending.keys() {
      cache[name] = read_import(root, name)
    }
  } nobreak {
    abort("project resolver ended unexpectedly")
  }
}

///|
async fn write_source(
  path : String,
  source : String,
  replace~ : Bool = true,
) -> Unit {
  let temporary = path + "." + @env.now().to_string() + ".tmp"
  let file = @fs.create(temporary[:], allow_existing=false)
  errdefer (@fs.remove(temporary[:]) catch { _ => () })
  {
    defer file.close()
    file.write(@utf8.encode(source[:])[:])
  }
  @fs.rename(temporary[:], path[:], replace~)
}
