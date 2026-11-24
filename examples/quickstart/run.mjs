import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));
const sample = fileURLToPath(new URL("./", import.meta.url));
const build = join(root, "_build");
const fromSource = process.argv.includes("--source");
const allTargets = process.argv.includes("--all-targets");
const version = "0.9.0";
function moon(cwd, ...args) {
  const run = spawnSync("moon", args, { cwd, stdio: "inherit" });
  if (run.error) throw run.error;
  assert.equal(run.status, 0, "moon " + args.join(" "));
}

mkdirSync(build, { recursive: true });
const work = mkdtempSync(join(build, "quickstart-"));
const consumer = join(work, "consumer");
mkdirSync(consumer);
writeFileSync(join(consumer, "moon.mod"), 'name = "example/ksymoon-quickstart"\nversion = "0.1.0"\n');
copyFileSync(join(sample, "moon.pkg.in"), join(consumer, "moon.pkg"));
copyFileSync(join(sample, "main.mbt.in"), join(consumer, "main.mbt"));

let generator = root;
let command = "cmd/ksymoon";
if (!fromSource) {
  generator = join(work, "generator");
  mkdirSync(generator);
  writeFileSync(join(generator, "moon.mod"), 'name = "example/ksymoon-registry-generator"\nversion = "0.1.0"\n');
  moon(generator, "update");
  moon(generator, "add", "bzhangui/ksymoon@" + version);
  const cli = join(generator, ".mooncakes", "bzhangui", "ksymoon", "cmd", "ksymoon");
  copyFileSync(join(cli, "main.mbt"), join(generator, "main.mbt"));
  copyFileSync(join(cli, "moon.pkg"), join(generator, "moon.pkg"));
  command = ".";
}
console.log("Generator:", fromSource ? "repository source" : "Mooncakes bzhangui/ksymoon@" + version);
console.log("Fresh consumer:", consumer);
for (const [name, input, reference] of [
  ["udp", "udp_datagram.ksy", "udp/udp_datagram.mbt"],
  ["names", "kaitai/instance_io_user.ksy", "instance_io_user/instance_io_user.mbt"],
]) {
  const pkg = join(consumer, name);
  mkdirSync(pkg);
  writeFileSync(join(pkg, "moon.pkg"), "");
  const output = join(pkg, "parser.mbt");
  moon(generator, "run", "--frozen", "--target", "js", "--deny-warn", command, "--",
    "generate", join(root, "fixtures", input), "--out", output);
  if (fromSource) {
    assert.deepEqual(readFileSync(output), readFileSync(join(root, "examples", "consumer", reference)));
  }
}

const targets = allTargets ? ["js", "wasm", "wasm-gc", "native"] : ["js"];
for (const target of targets) {
  for (const action of ["check", "build", "test", "run"]) {
    moon(consumer, action, "--frozen", "--target", target, "--deny-warn", ...(action === "run" ? ["."] : []));
  }
}
