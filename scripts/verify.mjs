import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const consumer = join(root, "examples", "consumer");
const buildDir = join(root, "_build");
const fixtures = [
  {
    schema: "udp_datagram",
    package: "udp",
    sha256: "ed599e447a760b85a154e2f9b0e00f7433977e75ea4f29dca4f814ae2bd1b8a2",
  },
  {
    schema: "stl",
    package: "stl",
    sha256: "bf9fac93edff1b49e795a15a4abb311d690166fe7b38b6400f6958cd72ae67cd",
  },
  { schema: "stm32_sample_frame", package: "stm32" },
  { schema: "wire_checks", package: "wire" },
];

function moon(cwd, ...args) {
  const result = spawnSync("moon", args, { cwd, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`moon ${args.join(" ")} failed in ${cwd} (${result.status ?? result.signal})`);
  }
}

function verifyCli(scratch) {
  const valid = join(scratch, "valid.ksy");
  const invalid = join(scratch, "invalid.ksy");
  const protectedOutput = join(scratch, "protected.mbt");
  copyFileSync(join(root, "fixtures", "udp_datagram.ksy"), valid);
  writeFileSync(invalid, "meta: {id: invalid}\nseq:\n  - {id: flag, type: u1, if: flag}\n");
  writeFileSync(protectedOutput, "// existing output\n");
  const filesBefore = readdirSync(scratch);

  function cli(...args) {
    const result = spawnSync("moon", [
      "run", "--frozen", "--target", "js", "--deny-warn", "cmd/ksymoon", "--", ...args,
    ], { cwd: root, encoding: "utf8" });
    if (result.error) throw result.error;
    assert.notEqual(result.status, null, result.signal);
    return result;
  }

  const accepted = cli("check", valid);
  assert.equal(accepted.status, 0, accepted.stderr);
  assert.ok(accepted.stdout.includes("Valid schema: "));
  const rejected = cli("check", invalid);
  assert.notEqual(rejected.status, 0);
  assert.ok(rejected.stderr.includes(invalid));
  assert.match(rejected.stderr, /seq\[0\]\.if: unsupported key/);
  const missing = cli("check", join(scratch, "missing.ksy"));
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /could not read .*missing\.ksy/);
  const checkWithOutput = cli("check", valid, "--out", protectedOutput);
  assert.notEqual(checkWithOutput.status, 0);
  assert.match(checkWithOutput.stderr, /Usage:/);
  const invalidGenerate = cli("generate", invalid, "--out", protectedOutput);
  assert.notEqual(invalidGenerate.status, 0);
  assert.match(invalidGenerate.stderr, /seq\[0\]\.if: unsupported key/);
  assert.equal(readFileSync(protectedOutput, "utf8"), "// existing output\n");
  assert.deepEqual(readdirSync(scratch), filesBefore);
  console.log("CLI check: valid, invalid, missing input, and protected output verified");
}

moon(root, "update");
moon(root, "check", "--target", "all", "--deny-warn");
moon(root, "fmt", "--check");
moon(root, "test", "--frozen", "--target", "all", "--deny-warn");

mkdirSync(buildDir, { recursive: true });
verifyCli(mkdtempSync(join(buildDir, "cli-check-")));
const independent = mkdtempSync(join(buildDir, "consumer-"));
console.log(`Independent consumer: ${independent}`);
for (const name of [
  "moon.mod", "moon.pkg", "main.mbt", "main_wbtest.mbt", "stl_checks.mbt", "stm32_checks.mbt",
  "wire_checks_wbtest.mbt",
  "prefix_wbtest.mbt",
]) {
  copyFileSync(join(consumer, name), join(independent, name));
}
for (const fixture of fixtures) {
  const input = join(root, "fixtures", `${fixture.schema}.ksy`);
  if (fixture.sha256) {
    const digest = createHash("sha256").update(readFileSync(input)).digest("hex");
    if (digest !== fixture.sha256) throw new Error(`Upstream fixture changed: ${input}`);
  }

  const outDir = join(independent, fixture.package);
  mkdirSync(outDir);
  copyFileSync(join(consumer, fixture.package, "moon.pkg"), join(outDir, "moon.pkg"));
  const name = `${fixture.schema}.mbt`;
  const output = join(outDir, name);
  moon(root, "run", "--frozen", "--target", "js", "--deny-warn", "cmd/ksymoon", "--",
    "generate", input, "--out", output);
  if (!readFileSync(output).equals(readFileSync(join(consumer, fixture.package, name)))) {
    throw new Error(`Generated ${name} differs from the checked-in sample`);
  }
  console.log(`Verified ${fixture.schema}.ksy and reproducible output`);
}

if (process.argv.includes("--kaitai-reference")) {
  const result = spawnSync("python", [join(root, "scripts", "kaitai-reference.py"), independent], {
    cwd: root,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error("Kaitai reference generation failed: " + result.status);
}

for (const command of ["check", "build", "test"]) {
  moon(independent, command, "--frozen", "--target", "all", "--deny-warn");
}
for (const target of ["js", "wasm", "wasm-gc", "native"]) {
  console.log(`Run consumer: ${target}`);
  moon(independent, "run", "--frozen", "--target", target, "--deny-warn", ".");
}
