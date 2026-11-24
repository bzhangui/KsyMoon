"""Four-target differential tests for numeric representations and byte order."""
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
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
literal = REFERENCE["bytes_literal"]

SAMPLES = {
    **dict.fromkeys(("default_endian_expr_is_le", "default_endian_expr_is_be",
                     "default_endian_expr_inherited", "default_endian_expr_exception"), "endian_expr.bin"),
    **dict.fromkeys(("integers", "bits_simple", "bits_simple_le"), "fixed_struct.bin"),
    **dict.fromkeys(("bits_unaligned_b64_be", "bits_unaligned_b64_le"), "process_xor_4.bin"),
    "floating_points": "floating_points.bin",
    "bits_shift_by_b64_le": "bits_shift_by_b64_le.bin",
}
INSTANCE_FIELDS = {"inst_int", "inst_sub", "some_inst", "test_if_b1", "single_value_plus_int",
                   "single_value_plus_float", "double_value_plus_float"}
SINGLE_FIELDS = {"single_value", "single_value_be", "approximate_value"}


def member_path(node, frame):
    if isinstance(node, ast.Name) and node.id == "r":
        return "frame", frame
    if isinstance(node, ast.Attribute):
        base, value = member_path(node.value, frame)
        method = "()" if node.attr in INSTANCE_FIELDS else ""
        optional = ".unwrap()" if node.attr == "test_if_b1" else ""
        return f"{base}.{node.attr}{method}{optional}", getattr(value, node.attr)
    if isinstance(node, ast.Subscript):
        base, value = member_path(node.value, frame)
        index = ast.literal_eval(node.slice)
        return f"{base}[{index}]", value[index]
    raise ValueError(ast.dump(node))


def assertions(name, spec, frame):
    calls = sorted((call for call in ast.walk(ast.parse(spec)) if isinstance(call, ast.Call)
                    and isinstance(call.func, ast.Attribute) and call.func.attr in ("assertEqual", "assertAlmostEqual")),
                   key=lambda call: call.lineno)
    checks = []
    for call in calls:
        field, expected = member_path(call.args[0], frame)
        leaf = call.args[0].attr
        if isinstance(expected, bool):
            value = str(expected).lower()
        elif isinstance(expected, bytes):
            field += ".to_owned()"
            value = literal(expected)
        elif isinstance(expected, float):
            if leaf in SINGLE_FIELDS:
                field += ".to_double()"
            checks.append(f"  assert_true(({field} - {expected!r}).abs() < 1.0e-9)")
            continue
        else:
            if leaf.startswith("uint64") or leaf in ("byte_15_to_19", "byte_20_to_27") or (
                name == "bits_shift_by_b64_le" and leaf == "a"
            ) or (name.startswith("bits_unaligned_b64") and leaf == "b"):
                suffix = "UL"
            elif leaf.startswith("sint64") or leaf == "test_if_b1":
                suffix = "L"
            elif leaf.startswith("sint") or leaf == "normal_s2":
                suffix = ""
            else:
                suffix = "U"
            value = f"{expected}{suffix}"
        checks.append(f"  assert_eq({field}, {value})")
    return checks


def prefix_test(name, data, accepted):
    result = bytearray(not accepted(data[:cut]) for cut in range(len(data)))
    parse = f"@{name}.parse_{name}"
    force = "    ignore(frame.body.ifd0());" if name == "exif" else "    ignore(frame);"
    return [
        "///|", f'test "{name} prefixes agree with Kaitai" {{',
        f"  let data = {literal(data)}", f"  let rejected = {literal(result)}",
        "  for cut in 0..<data.length() {",
        "    let failed = try {", f"      let frame = {parse}(data[:cut].to_owned())",
        force, "      false", "    } catch { _ => true }",
        "    assert_eq(failed, rejected[cut] == 1)", "  }", "}",
    ], len(result)


def make_exif(little):
    order = "<" if little else ">"
    return ((b"II" if little else b"MM") + struct.pack(order + "HIH", 42, 8, 2)
            + struct.pack(order + "HHIHH", 0x100, 3, 1, 640, 0)
            + struct.pack(order + "HHII", 0x101, 4, 1, 480)
            + struct.pack(order + "I", 0))


def exif_test(data, frame, text):
    labels = dict((typ, variant) for variant, typ in
                  re.findall(r"(Case\d+)\(Exif_exif_body_(shorts|longs)\)", text))
    ifd = frame.body.ifd0
    return [
        "///|", f'test "Exif {data[:2].decode()} fields and directory match Kaitai" {{',
        f"  let exif = @exif.parse_exif({literal(data)})",
        f"  assert_eq(exif.body.ofs_ifd0, {frame.body.ofs_ifd0}U)",
        "  let ifd = exif.body.ifd0()",
        f"  assert_eq(ifd.num_fields, {ifd.num_fields}U)",
        f"  assert_eq(ifd.fields[0].tag().unwrap().to_i(), {int(ifd.fields[0].tag)}L)",
        f'  guard ifd.fields[0].data() is {labels["shorts"]}(width) else {{ fail("short IFD value") }}',
        f'  guard ifd.fields[1].data() is {labels["longs"]}(height) else {{ fail("long IFD value") }}',
        f"  assert_eq(width.values[0], {ifd.fields[0].data.values[0]}U)",
        f"  assert_eq(height.values[0], {ifd.fields[1].data.values[0]}U)",
        "  assert_true(ifd.next_ifd() is None)", "}",
    ]


def main():
    build = ROOT / "_build"
    work = Path(tempfile.mkdtemp(prefix="numerics-", dir=build))
    archive_path = CORPUS["corpus_archive"]()
    formats = work / "formats"
    CORPUS["extract_formats"](archive_path, formats)
    exif = WAV["verified_format"]("image/exif.ksy",
                                 "b390f61bea731072bf1bd5232f6b1b3ac83f3f698486cdb583d6925cd03c6770",
                                 build / "kaitai-formats", work)
    refs, specs, samples, consumer = (work / name for name in ("testformats", "spec", "src", "consumer"))
    for directory in (refs, specs, samples, consumer):
        directory.mkdir()
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for name, sample in SAMPLES.items():
            (specs / f"test_{name}.py").write_bytes(archive.read(prefix + f"spec/python/spec/test_{name}.py"))
            (samples / sample).write_bytes(archive.read(prefix + f"src/{sample}"))
    sources = {name: formats / f"{name}.ksy" for name in SAMPLES}
    sources["exif"] = exif
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package",
                    "testformats", "--outdir", str(refs), *map(str, sources.values())], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    subprocess.run(["moon", "build", "--frozen", "--release", "--target", "js", "cmd/ksymoon"], cwd=ROOT, check=True)
    (consumer / "moon.mod").write_text('name = "example/ksymoon-numerics"\nversion = "0.1.0"\n', encoding="utf-8")
    imports = "".join(f'  "example/ksymoon-numerics/{name}",\n' for name in sources)
    (consumer / "moon.pkg").write_text(f'import {{\n{imports}}} for "wbtest"\n', encoding="utf-8")

    tests = []
    prefixes = 0
    for name, spec in sources.items():
        package = consumer / name
        package.mkdir()
        parser = package / "parser.mbt"
        (package / "moon.pkg").write_text("", encoding="utf-8")
        cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
        subprocess.run(["node", str(cli), "generate", str(spec), "--out", str(parser)], check=True)
        ref_class = "".join(word.title() for word in name.split("_"))
        reference = getattr(importlib.import_module("testformats." + name), ref_class)
        def accepted(data):
            try:
                parsed = reference.from_bytes(data)
                if name == "exif":
                    _ = parsed.body.ifd0
                return True
            except (EOFError, kaitaistruct.KaitaiStructError):
                return False

        vectors = [make_exif(True), make_exif(False)] if name == "exif" else [(samples / SAMPLES[name]).read_bytes()]
        for vector in vectors:
            if name == "exif":
                tests.append(exif_test(vector, reference.from_bytes(vector), parser.read_text(encoding="utf-8")))
            elif name.endswith("_exception"):
                tests.append([
                    "///|", 'test "unknown byte order is rejected after two valid documents" {',
                    f"  try @{name}.parse_{name}({literal(vector)}) catch {{",
                    f'    @{name}.{ref_class}ContextError(message~, ..) => assert_eq(message, "undecided byte order")',
                    "    error => raise error", '  } noraise { _ => fail("accepted unknown order") }', "}",
                ])
            else:
                frame = reference.from_bytes(vector)
                checks = assertions(name, (specs / f"test_{name}.py").read_text(encoding="utf-8"), frame)
                tests.append(["///|", f'test "{name} matches Kaitai" {{',
                              f"  let frame = @{name}.parse_{name}({literal(vector)})", *checks, "}"])
            prefix, count = prefix_test(name, vector, accepted)
            if name == "exif":
                prefix[1] = f'test "Exif {vector[:2].decode()} prefixes agree with Kaitai" {{'
            tests.append(prefix)
            prefixes += count
    (consumer / "numeric_wbtest.mbt").write_text("\n\n".join("\n".join(test) for test in tests) + "\n", encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "original_tests": len(SAMPLES), "targets": ["js", "wasm", "wasm-gc", "native"],
              "schemas": list(sources), "tests_per_target": len(tests), "prefixes": prefixes}
    (build / "numeric-endian-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Numerics/Exif: {len(tests)} tests per target and {prefixes} prefix comparisons")


if __name__ == "__main__":
    main()
