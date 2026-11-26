"""Compare typed expressions and validation failures to the official Python target."""
import ast
import importlib
import json
from pathlib import Path
import re
import runpy
import struct
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
WIDE_VALIDATIONS = dict.fromkeys(("valid_long", "valid_short"), "fixed_struct.bin")
COMPARISONS = {"eq": "==", "ne": "!=", "lt": "<", "le": "<=", "gt": ">", "ge": ">="}
WIDE_COMPARISON = """meta: {id: wide_comparison, endian: le}
seq:
  - {id: unsigned, type: u8}
  - {id: signed, type: s8}
instances:
""" + "".join(
    f"  {name}_{order}: {{value: '{left} {op} {right}'}}\n"
    for name, op in COMPARISONS.items()
    for order, (left, right) in enumerate((("unsigned", "signed"), ("signed", "unsigned")))
)
WIDE_LENGTH = """meta: {id: wide_length, endian: le}
seq:
  - {id: len_data, type: u8}
  - {id: data, size: len_data}
  - {id: num_items, type: u8}
  - {id: items, type: u1, repeat: expr, repeat-expr: num_items}
"""


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


def wide_validation_test(name, reference, data):
    frame = reference.from_bytes(data)
    assert frame.uint64 == 2**64 - 1
    damaged = data[:24] + struct.pack("<Q", frame.uint64 - 1) + data[32:]
    try:
        reference.from_bytes(damaged)
    except kaitaistruct.ValidationNotEqualError as error:
        offset = error.io.pos()
        assert error.src_path == "/seq/6"
    else:
        raise AssertionError(f"{name} accepted the wrong UInt64")
    error_type = "".join(part.title() for part in name.split("_"))
    return f'''///|
test "{name} preserves the full unsigned integer literal" {{
  assert_eq(@{name}.parse_{name}({literal(data)}).uint64, {frame.uint64}UL)
  try @{name}.parse_{name}({literal(damaged)}) catch {{
    @{name}.{error_type}ValidationMismatch(field~, offset~) => {{
      assert_eq(field, "{name}.uint64")
      assert_eq(offset, {offset})
    }}
    error => raise error
  }} noraise {{ _ => fail("accepted the wrong UInt64") }}
}}'''


def wide_comparison_test(reference):
    checks = []
    max_signed = 2**63 - 1
    max_unsigned = 2**64 - 1
    pairs = ((0, -1), (1, 2), (1, 1), (max_signed + 1, max_signed), (max_unsigned, -1))
    for index, (unsigned, signed) in enumerate(pairs):
        data = struct.pack("<Qq", unsigned, signed)
        frame = reference.from_bytes(data)
        checks.append(f"  let frame{index} = @wide_comparison.parse_wide_comparison({literal(data)})")
        for name in (f"{op}_{order}" for op in COMPARISONS for order in range(2)):
            checks.append(f"  assert_eq(frame{index}.{name}(), {str(getattr(frame, name)).lower()})")
    return "\n".join(["///|", 'test "mixed UInt64 comparisons agree with Kaitai in both orders" {', *checks, "}"])


def wide_length_test(reference):
    def packed(length, count, data=b"", values=b""):
        return struct.pack("<Q", length) + data + struct.pack("<Q", count) + values

    data = packed(2, 2, b"xy", bytes((1, 9)))
    frame = reference.from_bytes(data)
    assert frame.data == b"xy" and frame.items == [1, 9]
    parser = "@wide_length.parse_wide_length"
    return f'''///|
test "UInt64 byte lengths and repeat counts preserve valid values" {{
  let frame = {parser}({literal(data)})
  assert_eq(frame.data.to_owned(), {literal(frame.data)})
  assert_eq(frame.items, {frame.items})
}}

///|
test "UInt64 lengths and counts reject overflow before narrowing" {{
  try {parser}({literal(packed(2**63, 0))}) catch {{
    @wide_length.WideLengthContextError(field~, offset~, message~) => {{
      assert_eq(field, "wide_length.data")
      assert_eq(offset, 8)
      assert_eq(message, "unsigned length exceeds the Int64 range")
    }}
    error => raise error
  }} noraise {{ _ => fail("accepted an unrepresentable length") }}
  try {parser}({literal(packed(0, 2**64 - 1))}) catch {{
    @wide_length.WideLengthContextError(field~, offset~, ..) => {{
      assert_eq(field, "wide_length.items")
      assert_eq(offset, 16)
    }}
    error => raise error
  }} noraise {{ _ => fail("accepted an unrepresentable count") }}
}}

///|
test "representable UInt64 values still obey the stream and repeat bounds" {{
  try {parser}({literal(packed(2**63 - 1, 0))}) catch {{
    @wide_length.WideLengthTruncated(needed~, remaining~, ..) => {{
      assert_eq(needed, 9223372036854775807L)
      assert_eq(remaining, 8)
    }}
    error => raise error
  }} noraise {{ _ => fail("accepted more bytes than remain") }}
  try {parser}({literal(packed(0, 1_000_001))}) catch {{
    @wide_length.WideLengthRepeatLimit(count~, ..) => assert_eq(count, 1000001L)
    error => raise error
  }} noraise {{ _ => fail("accepted a count exceeding the repeat budget") }}
}}'''


def main():
    build = ROOT / "_build"
    work = Path(tempfile.mkdtemp(prefix="validation-", dir=build))
    formats = work / "formats"
    upstream = CORPUS["corpus_archive"]()
    CORPUS["extract_formats"](upstream, formats)
    cases = {**SUCCESS, **FAILURES, **WIDE_VALIDATIONS}
    refs, specs, samples, consumer = (work / name for name in ("testformats", "spec", "src", "consumer"))
    for directory in (refs, specs, samples, consumer):
        directory.mkdir()
    with ZipFile(upstream) as archive:
        prefix = archive.namelist()[0]
        for name, sample in cases.items():
            (specs / f"test_{name}.py").write_bytes(archive.read(prefix + f"spec/python/spec/test_{name}.py"))
            (samples / sample).write_bytes(archive.read(prefix + f"src/{sample}"))
    sources = {name: formats / f"{name}.ksy" for name in cases}
    for name, schema in (("wide_comparison", WIDE_COMPARISON), ("wide_length", WIDE_LENGTH)):
        sources[name] = work / f"{name}.ksy"
        sources[name].write_text(schema, encoding="utf-8")
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
        if name == "wide_comparison":
            tests.append(wide_comparison_test(reference))
        elif name == "wide_length":
            tests.append(wide_length_test(reference))
        elif name in WIDE_VALIDATIONS:
            tests.append(wide_validation_test(name, reference, (samples / cases[name]).read_bytes()))
        elif name in SUCCESS:
            data = (samples / cases[name]).read_bytes()
            spec = (specs / f"test_{name}.py").read_text(encoding="utf-8")
            tests.append(success_test(name, spec, reference.from_bytes(data), data))
        else:
            tests.append(failure_test(name, reference, (samples / cases[name]).read_bytes()))
    (consumer / "validation_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    count = sum(test.count('\ntest "') for test in tests)
    report = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "schemas": list(cases), "runtime_validation_failures_matched": len(FAILURES) + len(WIDE_VALIDATIONS),
              "project_schemas": ["wide_comparison", "wide_length"],
              "targets": ["js", "wasm", "wasm-gc", "native"], "tests_per_target": count}
    (build / "expression-validation-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Expressions/validation: {count} tests per target, including {len(WIDE_VALIDATIONS)} original UInt64 validations")


if __name__ == "__main__":
    main()
