///|
const USAGE =
  #| Usage:
  #|   ksymoon_native check INPUT.ksy [--json]
  #|   ksymoon_native generate INPUT.ksy --out OUTPUT.mbt
  #|   ksymoon_native deps INPUT.ksy
  #|   ksymoon_native batch --out-dir DIR INPUT.ksy [INPUT.ksy ...]
  #| All commands accept --root DIR, -I DIR, and --import NAME FILE.ksy.

///|
suberror CommandError {
  CommandError(String)
}

///|
priv struct Options {
  inputs : Array[String]
  mut output : String?
  mut root : String?
  search : Array[String]
  imports : Map[String, String]
  mut json : Bool
}

///|
fn parse_options(
  command : String,
  args : ArrayView[String],
) -> Options raise CommandError {
  let options : Options = {
    inputs: [],
    output: None,
    root: None,
    search: [],
    imports: Map([]),
    json: false,
  }
  let mut index = 0
  while index < args.length() {
    match args[index:] {
      ["--json", ..] if command == "check" && !options.json => {
        options.json = true
        index += 1
      }
      ["--out", file, ..] if command == "generate" &&
        options.output is None &&
        file.has_suffix(".mbt") => {
        options.output = Some(file)
        index += 2
      }
      ["--out-dir", dir, ..] if command == "batch" && options.output is None => {
        options.output = Some(dir)
        index += 2
      }
      ["--root", dir, ..] if options.root is None => {
        options.root = Some(dir)
        index += 2
      }
      ["-I", dir, ..] => {
        options.search.push(dir)
        index += 2
      }
      ["--import", name, path, ..] if !options.imports.contains(name) => {
        options.imports[name] = path
        index += 3
      }
      [file, ..] if !file.has_prefix("-") && file.has_suffix(".ksy") => {
        options.inputs.push(file)
        index += 1
      }
      _ => raise CommandError(USAGE)
    }
  }
  guard !options.inputs.is_empty() &&
    (command == "batch" || options.inputs.length() == 1) &&
    ((command == "check" || command == "deps") || options.output is Some(_)) else {
    raise CommandError(USAGE)
  }
  options
}

///|
fn dependency_json(entry : String, edges : Array[@codegen.ImportEdge]) -> Json {
  let dependencies = edges.map(fn(edge) {
    Json::object(
      Map([
        ("from", Json::string(edge.importer)),
        ("import_name", Json::string(edge.import_name)),
        ("to", Json::string(edge.target)),
      ]),
    )
  })
  Json::object(
    Map([
      ("entry", Json::string(entry)),
      ("dependencies", Json::array(dependencies)),
    ]),
  )
}

///|
fn diagnostic(error : Error) -> (String, String?, String) {
  match error {
    @codegen.InvalidSchema(message) =>
      match message.split_once(": ") {
        Some((path, detail)) =>
          ("invalid_schema", Some(path.to_owned()), detail.to_owned())
        None => ("invalid_schema", None, message)
      }
    CommandError(message) => ("command_error", None, message)
    _ => ("io_error", None, error.to_string())
  }
}

///|
fn print_check(input : String, problem : Error?) -> Unit {
  let diagnostics = match problem {
    None => []
    Some(error) => {
      let (code, path, message) = diagnostic(error)
      [
        Json::object(
          Map([
            ("code", Json::string(code)),
            ("schema_path", path.map(Json::string).unwrap_or(Json::null())),
            ("message", Json::string(message)),
          ]),
        ),
      ]
    }
  }
  println(
    Json::object(
      Map([
        ("file", Json::string(input)),
        ("ok", Json::boolean(problem is None)),
        ("diagnostics", Json::array(diagnostics)),
      ]),
    ).stringify(),
  )
}

///|
async fn run_batch(options : Options, directory : String) -> Unit {
  let outputs : Map[String, (String, String)] = Map([])
  for input in options.inputs {
    let basename = @path.Path(input).basename()
    let name = basename[:basename.length() - 4].to_owned()
    guard !name.is_empty() && name != "." && name != ".." else {
      raise CommandError("invalid batch output name: " + name)
    }
    let key = name.to_lower()
    guard !outputs.contains(key) else {
      raise CommandError("duplicate batch output name: " + name)
    }
    let (source, _, _) = compile_input(input, options, generate=true)
    outputs[key] = (name, source)
  }
  for _, (name, source) in outputs {
    let package_dir = @path.Path(directory).join(@path.Path(name))
    @fs.mkdir(package_dir.0[:], allow_exist=true, recursive=true)
    let manifest = package_dir.join(@path.Path("moon.pkg")).0
    let config = if source.contains("@ksy_zlib.") {
      (
        #|import { "moonbitlang/core/compress/zlib" @ksy_zlib }
        #|options("allow-experimental-packages": ["moonbitlang/core/compress/zlib"])
        #|
      )
    } else {
      ""
    }
    write_source(manifest, config, replace=false) catch {
      @os_error.OsError(AlreadyExists, ..) => ()
      error => raise error
    }
    write_source(package_dir.join(@path.Path(name + ".mbt")).0, source)
  }
}

///|
async fn run(command : String, options : Options) -> Int32 {
  match (command, options.output) {
    ("batch", Some(directory)) => run_batch(options, directory)
    ("generate", Some(output)) => {
      let (source, _, _) = compile_input(
        options.inputs[0],
        options,
        generate=true,
      )
      write_source(output, source)
    }
    ("deps", _) => {
      let (_, entry, edges) = compile_input(
        options.inputs[0],
        options,
        generate=false,
      )
      println(dependency_json(entry, edges).stringify())
    }
    ("check", _) => {
      let input = options.inputs[0]
      if options.json {
        try {
          ignore(compile_input(input, options, generate=true))
          print_check(input, None)
        } catch {
          error => {
            print_check(input, Some(error))
            return 1
          }
        }
      } else {
        ignore(compile_input(input, options, generate=true))
        println("Valid schema: " + input)
      }
    }
    _ => raise CommandError(USAGE)
  }
  0
}

///|
extern "C" fn exit_with_status(status : Int32) = "exit"

///|
async fn cli() -> Int32 {
  match @env.args()[:] {
    [_, "--help"] | [_, "-h"] => {
      println(USAGE)
      0
    }
    [_, "check" | "generate" | "deps" | "batch" as command, .. args] =>
      run(command, parse_options(command, args))
    _ => raise CommandError(USAGE)
  }
}

///|
fn main {
  let status = Ref(1)
  @async.run_async_main(async fn() {
    try {
      status.val = cli()
    } catch {
      error => {
        let (_, path, message) = diagnostic(error)
        let detail = match path {
          Some(path) => path + ": " + message
          None => message
        }
        @stdio.stderr.write(@utf8.encode(("ksymoon: " + detail + "\n")[:])[:])
      }
    }
  })
  exit_with_status(status.val)
}
