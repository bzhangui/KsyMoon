import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync } from "node:fs";
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

moon(root, "update");
moon(root, "check", "--target", "all", "--deny-warn");
moon(root, "fmt", "--check");
moon(root, "test", "--frozen", "--target", "all", "--deny-warn");

mkdirSync(buildDir, { recursive: true });
const independent = mkdtempSync(join(buildDir, "consumer-"));
console.log(`Independent consumer: ${independent}`);
for (const name of [
  "moon.mod", "moon.pkg", "main.mbt", "main_wbtest.mbt", "stl_checks.mbt", "stm32_checks.mbt",
  "wire_checks_wbtest.mbt",
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

for (const command of ["check", "build", "test"]) {
  moon(independent, command, "--frozen", "--target", "all", "--deny-warn");
}
for (const target of ["js", "wasm", "wasm-gc", "native"]) {
  console.log(`Run consumer: ${target}`);
  moon(independent, "run", "--frozen", "--target", target, "--deny-warn", ".");
}
