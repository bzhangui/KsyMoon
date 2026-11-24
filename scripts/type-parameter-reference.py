"""Compare scoped enums and composite arguments with the original Kaitai corpus."""

from enum import Enum
import importlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
literal = REFERENCE["bytes_literal"]

# Pairs provide the field path on the reference object and the MoonBit accessor.
CASES = {
    "bits_enum": [(name, f".{name}.to_i()") for name in ("one", "two", "three")],
    "enum_deep": [(name, f".{name}.to_i()") for name in ("pet_1", "pet_2")],
    "enum_deep_literals": [(name, f".{name}()") for name in ("is_pet_1_ok", "is_pet_2_ok")],
    "enum_import_literals": [("pet_1_to_i", ".pet_1_to_i()"), ("pet_1_eq", ".pet_1_eq()"), ("pet_2", ".pet_2().to_i()")],
    "enum_import_seq": [(name, f".{name}.to_i()") for name in ("pet_1", "pet_2")],
    "enum_long_range_s": [(f"f{i}", f".f{i}.to_i()") for i in range(1, 8)],
    "expr_bits": [("a", ".a"), ("enum_seq", ".enum_seq.to_i()"), ("byte_size", ".byte_size"),
                  ("repeat_expr", ".repeat_expr"), ("switch_on_endian.foo", ".switch_on_endian.foo"),
                  ("enum_inst", ".enum_inst().to_i()"), ("inst_pos", ".inst_pos()")],
    "ts_packet_header": [("sync_byte", ".sync_byte"), ("pid", ".pid"),
                         ("transport_priority", ".transport_priority"), ("adaptation_field_control", ".adaptation_field_control.to_i()")],
    "params_pass_array_int": [("pass_ints.nums", ".pass_ints.nums"), ("pass_ints_calc.nums", ".pass_ints_calc.nums")],
    "params_pass_array_str": [("pass_str_array.strs", ".pass_str_array.strs"), ("pass_str_array_calc.strs", ".pass_str_array_calc.strs")],
    "params_pass_array_io": [("first.foo", ".first.foo"), ("one.buf", ".one.buf")],
    "params_pass_io": [("first.foo", ".first.foo"), ("one.buf", ".one.buf")],
    "params_pass_array_struct": [("pass_structs.structs.0.f", ".pass_structs.structs[0].as_type_foo().f"),
                                 ("pass_structs.structs.1.b", ".pass_structs.structs[1].as_type_bar().b")],
    "params_pass_array_usertype": [("pass_blocks.bar.0.foo", ".pass_blocks.bar[0].as_type_block().foo"),
                                    ("pass_blocks.bar.1.foo", ".pass_blocks.bar[1].as_type_block().foo"),
                                    ("pass_blocks.one", ".pass_blocks.one"), ("pass_blocks.two", ".pass_blocks.two")],
    "params_pass_struct": [("one.bar.qux", ".one.bar.qux"), ("one.foo.foo", ".one.foo.as_type_block().foo"),
                           ("one.bar.foo.foo", ".one.bar.foo.as_type_block().foo")],
    "params_pass_usertype": [("first.foo", ".first.foo"), ("one.buf", ".one.buf")],
    "params_pass_bool": [(f"{name}.arg", f".{name}.arg") for name in ("seq_b1", "seq_bool", "literal_b1", "literal_bool", "inst_b1", "inst_bool")],
    "params_enum": [("one", ".one.to_i()"), ("invoke_with_param.is_cat", ".invoke_with_param.is_cat()")],
    "imports_cast_to_imported": [("hw.one", ".hw.one"), ("two.hw_one", ".two.hw_one()")],
    "imports_cast_to_imported2": [("hw.one", ".hw.one"), ("two.hw.one", ".two.hw().one")],
    "imports_params_def_array_usertype_imported": [("hws.0.one", ".hws[0].one"), ("two.hw0_one", ".two.hw0_one()"), ("two.hw1_one", ".two.hw1_one()")],
    "imports_params_def_enum_imported": [("two.pet_1_param", ".two.pet_1_param.to_i()"), ("two.pet_2_param", ".two.pet_2_param.to_i()")],
    "imports_params_def_usertype_imported": [("hw.one", ".hw.one"), ("two.hw_one", ".two.hw_one()")],
    "enum_to_i_class_border_1": [("pet_1", ".pet_1.to_i()"), ("pet_2", ".pet_2.to_i()"), ("checker.is_dog", ".checker().is_dog()")],
}
HELPERS = (
    "cast_to_imported", "cast_to_imported2", "enum_to_i_class_border_2",
    "params_def_array_usertype_imported", "params_def_enum_imported", "params_def_usertype_imported",
)


def get_value(frame, path):
    for name in path.split("."):
        frame = frame[int(name)] if name.isdigit() else getattr(frame, name)
    return frame


def moon_literal(value):
    if isinstance(value, Enum):
        return f"{value.value}L"
    if isinstance(value, bytes):
        return literal(value)
    if isinstance(value, list):
        return "[" + ", ".join(moon_literal(item) for item in value) + "]"
    return json.dumps(value, ensure_ascii=False)


def create_test(name, vector, expected):
    lines = ["///|", f'test "{name} matches Kaitai" {{', f"  let frame = parse_{name}({literal(vector)})"]
    for path, accessor in CASES[name]:
        value = get_value(expected, path)
        actual = "frame" + accessor + (".to_owned()" if isinstance(value, bytes) else "")
        lines.append(f"  assert_eq({actual}, {moon_literal(value)})")
    return "\n".join([*lines, "}", ""])


def main():
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="type-parameter-", dir=build))
    archive_path = CORPUS["corpus_archive"]()
    formats = work / "formats"
    CORPUS["extract_formats"](archive_path, formats)
    refs, specs, samples, consumer = (work / name for name in ("testformats", "spec", "src", "consumer"))
    for directory in (refs, specs, samples, consumer):
        directory.mkdir()
    source_names = [*CASES, *HELPERS]
    vectors = {}
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for name in CASES:
            spec = archive.read(prefix + f"spec/python/spec/test_{name}.py")
            sample = re.search(rb"from_file\('src/([^']+)'\)", spec)[1].decode()
            vectors[name] = archive.read(prefix + f"src/{sample}")
            (specs / f"test_{name}.py").write_bytes(spec)
            (samples / sample).write_bytes(vectors[name])
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats",
                    "--import-path", str(formats / "ks_path"), "--outdir", str(refs),
                    *(str(formats / f"{name}.ksy") for name in source_names)], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    subprocess.run(["moon", "build", "--frozen", "--target", "js", "--release", "cmd/ksymoon"], cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-types"\nversion = "0.1.0"\n', encoding="utf-8")
    for name in source_names:
        package = consumer / name
        package.mkdir()
        (package / "moon.pkg").write_text("", encoding="utf-8")
        subprocess.run(["node", str(cli), "generate", str(formats / f"{name}.ksy"), "--root", str(formats),
                        "-I", str(formats / "ks_path"), "--out", str(package / "parser.mbt")], check=True)
        if name in CASES:
            reference = getattr(importlib.import_module("testformats." + name), "".join(part.title() for part in name.split("_")))
            vector = vectors[name]
            (package / "reference_wbtest.mbt").write_text(create_test(name, vector, reference.from_bytes(vector)), encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": "0.11", "upstream_revision": CORPUS["REVISION"],
        "targets": ["js", "wasm", "wasm-gc", "native"], "schemas": source_names,
        "official_tests": len(CASES), "tests_per_target": len(CASES),
    }
    (build / "type-parameter-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Types and parameters: {len(source_names)} original schemas, {len(CASES)} runtime comparisons per target")


if __name__ == "__main__":
    main()
