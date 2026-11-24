///|
const USAGE = "Usage:\n  ksymoon check INPUT.ksy [--root DIR] [-I DIR ...] [--import NAME FILE.ksy ...]\n  ksymoon generate INPUT.ksy --out OUTPUT.mbt [--root DIR] [-I DIR ...] [--import NAME FILE.ksy ...]"

///|
extern "js" fn read_schema(path : String) -> FixedArray[String] =
  #|function(path) {
  #|  try {
  #|    return [require("node:fs").readFileSync(path, "utf8")];
  #|  } catch (_) {
  #|    return [];
  #|  }
  #|}

///|
extern "js" fn input_directory(path : String) -> String =
  #|function(path) { return require("node:path").dirname(path); }

///|
// Resolve symlinks before returning a path relative to the chosen project root.
extern "js" fn path_in_project(
  root : String,
  candidate : String,
) -> FixedArray[String] =
  #|function(root, candidate) {
  #|  try {
  #|    const fs = require("node:fs");
  #|    const path = require("node:path");
  #|    const rel = path.relative(fs.realpathSync(root), fs.realpathSync(candidate));
  #|    if (path.isAbsolute(rel) || rel === ".." || rel.startsWith(".." + path.sep)) return [];
  #|    return [rel.split(path.sep).join("/")];
  #|  } catch (_) {
  #|    return [];
  #|  }
  #|}

///|
extern "js" fn read_project_file(
  root : String,
  name : String,
) -> FixedArray[String] =
  #|function(root, name) {
  #|  try {
  #|    const fs = require("node:fs");
  #|    const path = require("node:path");
  #|    const base = fs.realpathSync(root);
  #|    const file = fs.realpathSync(path.join(base, name));
  #|    const rel = path.relative(base, file);
  #|    if (path.isAbsolute(rel) || rel === ".." || rel.startsWith(".." + path.sep)) return [];
  #|    if (!fs.statSync(file).isFile()) return [];
  #|    return [fs.readFileSync(file, "utf8")];
  #|  } catch (_) {
  #|    return [];
  #|  }
  #|}

///|
extern "js" fn write_source(path : String, source : String) -> String =
  #|function(path, source) {
  #|  const fs = require("node:fs");
  #|  const temp = path + "." + require("node:crypto").randomUUID() + ".tmp";
  #|  let created = false;
  #|  try {
  #|    const fd = fs.openSync(temp, "wx");
  #|    created = true;
  #|    try {
  #|      fs.writeFileSync(fd, source, "utf8");
  #|    } finally {
  #|      fs.closeSync(fd);
  #|    }
  #|    fs.renameSync(temp, path);
  #|    return "";
  #|  } catch (error) {
  #|    if (created) {
  #|      try { fs.unlinkSync(temp); } catch (_) {}
  #|    }
  #|    return String(error);
  #|  }
  #|}

///|
extern "js" fn report_error(message : String) -> Unit =
  #|function(message) {
  #|  console.error("ksymoon: " + message);
  #|  process.exitCode = 1;
  #|}

///|
fn process_file(
  input : String,
  output : String?,
  imports : Map[String, String],
  project : String,
  dirs : Array[String],
) -> Unit {
  guard read_schema(input) is [source] else {
    report_error("could not read '\{input}'")
    return
  }
  guard path_in_project(project, input) is [entry] else {
    report_error("input is outside the project root")
    return
  }
  let search = []
  for dir in dirs {
    guard path_in_project(project, dir) is [relative] else {
      report_error("invalid import directory '" + dir + "'")
      return
    }
    search.push(relative)
  }
  search.push("")
  let read = fn(name) {
    match read_project_file(project, name) {
      [text] => Some(text)
      _ => None
    }
  }
  try {
    match output {
      None => {
        @codegen.validate_project(source, entry, search, read, imports~)
        println("Valid schema: \{input}")
      }
      Some(path) => {
        let code = @codegen.generate_project(
          source,
          entry,
          search,
          read,
          imports~,
        )
        let message = write_source(path, code)
        if !message.is_empty() {
          report_error("could not write '\{path}': \{message}")
        }
      }
    }
  } catch {
    @codegen.InvalidSchema(message) => report_error("\{input}: \{message}")
  }
}

///|
fn run_command(
  input : String,
  arguments : ArrayView[String],
  generates : Bool,
) -> Unit {
  let imports = Map([])
  let mut output = None
  let mut root = None
  let dirs = []
  let mut index = 0
  while index < arguments.length() {
    match arguments[index:] {
      ["--out", path, ..] if generates && output is None => {
        if !path.has_suffix(".mbt") {
          report_error("output path must end in .mbt")
          return
        }
        output = Some(path)
        index += 2
      }
      ["--root", dir, ..] if root is None => {
        root = Some(dir)
        index += 2
      }
      ["-I", dir, ..] => {
        dirs.push(dir)
        index += 2
      }
      ["--import", key, path, ..] if !imports.contains(key) => {
        guard read_schema(path) is [source] else {
          report_error("could not read import '\{path}'")
          return
        }
        imports[key] = source
        index += 3
      }
      _ => {
        report_error(USAGE)
        return
      }
    }
  }
  if generates && output is None {
    report_error(USAGE)
    return
  }
  process_file(
    input,
    output,
    imports,
    root.unwrap_or(input_directory(input)),
    dirs,
  )
}

///|
fn main {
  match @env.args()[:] {
    [_, _, "check", input, .. args] => run_command(input, args, false)
    [_, _, "generate", input, .. args] => run_command(input, args, true)
    [_, _, "--help"] | [_, _, "-h"] => println(USAGE)
    _ => report_error(USAGE)
  }
}
