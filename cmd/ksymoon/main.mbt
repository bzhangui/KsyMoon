///|
const USAGE = "Usage:\n  ksymoon check INPUT.ksy [--import NAME FILE.ksy ...]\n  ksymoon generate INPUT.ksy --out OUTPUT.mbt [--import NAME FILE.ksy ...]"

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
) -> Unit {
  guard read_schema(input) is [source] else {
    report_error("could not read '\{input}'")
    return
  }
  try {
    match output {
      None => {
        @codegen.validate_with_imports(source, imports)
        println("Valid schema: \{input}")
      }
      Some(path) => {
        let code = @codegen.generate_with_imports(source, imports)
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
  process_file(input, output, imports)
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
