"""Compare typed expressions and validation failures to the official Python target."""
import ast
import importlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
from zipfile import ZipFile

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
literal = REFERENCE["bytes_literal"]

SUCCESS = {
    "expr_array": "expr_array.bin",
    "expr_calc_array_ops": "fixed_struct.bin",
    "expr_bytes_cmp": "fixed_struct.bin",
    "expr_bytes_ops": "nav_parent_switch.bin",
    "type_int_unary_op": "fixed_struct.bin",
}
FAILURES = {
    "valid_fail_eq_bytes": "fixed_struct.bin",
    "valid_fail_eq_str": "fixed_struct.bin",
    "valid_fail_range_float": "floating_points.bin",
    "valid_fail_repeat_anyof_int": "process_coerce_bytes.bin",
    "valid_fail_repeat_expr": "bcd_user_type_be.bin",
    "valid_fail_repeat_inst": "bcd_user_type_be.bin",
    "valid_fail_range_bytes": "fixed_struct.bin",
    "valid_fail_range_str": "fixed_struct.bin",
    "valid_fail_repeat_eq_int": "bcd_user_type_be.bin",
    "valid_fail_repeat_max_int": "nav_parent_switch.bin",
    "valid_fail_repeat_min_int": "process_coerce_bytes.bin",
    "valid_fail_in_enum": "enum_0.bin",
}


def success_test(name, spec, frame, data):
    checks = []
    for call in sorted((node for node in ast.walk(ast.parse(spec)) if isinstance(node, ast.Call)
                        and isinstance(node.func, ast.Attribute)
                        and node.func.attr in ("assertEqual", "assertAlmostEqual")), key=lambda x: x.lineno):
        field = call.args[0]
        if not (isinstance(field, ast.Attribute) and isinstance(field.value, ast.Name) and field.value.id == "r"):
            continue
        key = field.attr
        value = getattr(frame, key)
        expression = "frame." + key
        if key not in ("one", "two", "value_s2", "value_s8") or name == "expr_bytes_ops" and key == "two":
            expression += "()"
        if isinstance(value, bytes):
            expression += ".to_owned()"
            expected = literal(value)
        elif isinstance(value, bool):
            expected = str(value).lower()
        elif isinstance(value, str):
            expected = json.dumps(value)
        elif isinstance(value, float):
            expected = repr(value)
        else:
            expected = str(value) + ("" if key == "value_s2" else "L")
        checks.append(f"  assert_eq({expression}, {expected})")
    return "\n".join(["///|", f'test "{name} agrees with Kaitai" {{',
                      f"  let frame = @{name}.parse_{name}({literal(data)})", *checks, "}"])


def failure_test(name, reference, data):
    try:
        reference.from_bytes(data)
    except kaitaistruct.ValidationFailedError as error:
        position = error.io.pos()
        field = "inst" if name == "valid_fail_repeat_inst" else "foo"
        assert ("instances" if field == "inst" else "/seq/0") in error.src_path
    else:
        raise AssertionError(f"{name} should fail validation")
    error_name = "".join(part.title() for part in name.split("_"))
    return "\n".join([
        "///|", f'test "{name} reports the official validation position" {{',
        f"  try @{name}.parse_{name}({literal(data)}) catch {{",
        f"    @{name}.{error_name}ValidationMismatch(field~, offset~) => {{",
        f'      assert_true(field.has_prefix("{name}.{field}"))',
        f"      assert_eq(offset, {position})", "    }",
        "    error => raise error", '  } noraise { _ => fail("accepted invalid field") }', "}",
    ])


def main():
    build = ROOT / "_build"
    work = Path(tempfile.mkdtemp(prefix="validation-", dir=build))
    formats = work / "formats"
    upstream = CORPUS["corpus_archive"]()
    CORPUS["extract_formats"](upstream, formats)
    cases = {**SUCCESS, **FAILURES}
    refs, specs, samples, consumer = (work / name for name in ("testformats", "spec", "src", "consumer"))
    for directory in (refs, specs, samples, consumer):
        directory.mkdir()
    with ZipFile(upstream) as archive:
        prefix = archive.namelist()[0]
        for name, sample in cases.items():
            (specs / f"test_{name}.py").write_bytes(archive.read(prefix + f"spec/python/spec/test_{name}.py"))
            (samples / sample).write_bytes(archive.read(prefix + f"src/{sample}"))
    sources = {name: formats / f"{name}.ksy" for name in cases}
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package",
                    "testformats", "--outdir", str(refs), *map(str, sources.values())], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    subprocess.run(["moon", "build", "--frozen", "--release", "--target", "js", "cmd/ksymoon"], cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    (consumer / "moon.mod").write_text('name = "example/ksymoon-validation"\nversion = "0.1.0"\n', encoding="utf-8")
    imports = "".join(f'  "example/ksymoon-validation/{name}",\n' for name in sources)
    (consumer / "moon.pkg").write_text(f'import {{\n{imports}}} for "wbtest"\n', encoding="utf-8")
    tests = []
    for name, source in sources.items():
        package = consumer / name
        package.mkdir()
        (package / "moon.pkg").write_text("", encoding="utf-8")
        subprocess.run(["node", str(cli), "generate", str(source), "--out", str(package / "parser.mbt")], check=True)
        reference = getattr(importlib.import_module("testformats." + name), "".join(x.title() for x in name.split("_")))
        data = (samples / cases[name]).read_bytes()
        if name in SUCCESS:
            spec = (specs / f"test_{name}.py").read_text(encoding="utf-8")
            tests.append(success_test(name, spec, reference.from_bytes(data), data))
        else:
            tests.append(failure_test(name, reference, data))
    (consumer / "validation_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "schemas": list(cases), "runtime_validation_failures_matched": len(FAILURES),
              "targets": ["js", "wasm", "wasm-gc", "native"], "tests_per_target": len(tests)}
    (build / "expression-validation-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Expressions/validation: {len(tests)} official comparisons per target, including {len(FAILURES)} expected failures")


if __name__ == "__main__":
    main()
