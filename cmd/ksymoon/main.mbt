///|
const USAGE = "Usage: ksymoon generate INPUT.ksy --out OUTPUT.mbt"

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
fn generate_file(input : String, output : String) -> Unit {
  guard output.has_suffix(".mbt") else {
    report_error("output path must end in .mbt")
    return
  }
  guard read_schema(input) is [source] else {
    report_error("could not read '\{input}'")
    return
  }
  let code = @codegen.generate(source) catch {
    @codegen.InvalidSchema(message) => {
      report_error("\{input}: \{message}")
      return
    }
  }
  let message = write_source(output, code)
  if !message.is_empty() {
    report_error("could not write '\{output}': \{message}")
  }
}

///|
fn main {
  match @env.args()[:] {
    [_, _, "generate", input, "--out", output] => generate_file(input, output)
    [_, _, "--help"] | [_, _, "-h"] => println(USAGE)
    _ => report_error(USAGE)
  }
}
