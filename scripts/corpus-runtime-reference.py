"""Run additional original Kaitai tests and replay their field checks on four targets."""

import ast
from enum import Enum
import hashlib
import importlib
import importlib.metadata
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
TYPES = runpy.run_path(str(ROOT / "scripts/type-parameter-reference.py"))
V010_CASES = """
bits_shift_by_b32_le
bits_signed_res_b32_be
bits_signed_res_b32_le
bits_signed_shift_b32_le
bits_signed_shift_b64_le
bits_unaligned_b32_be
bits_unaligned_b32_le
buffered_struct
bytes_pad_term
bytes_pad_term_empty
bytes_pad_term_equal
bytes_pad_term_roundtrip
bytes_pad_term_zero_size
default_big_endian
default_bit_endian_mod
default_endian_mod
enum_0
enum_1
enum_fancy
enum_int_range_s
enum_int_range_u
enum_invalid
enum_negative
hello_world
index_sizes
index_to_param_eos
index_to_param_expr
index_to_param_until
nested_same_name
nested_same_name2
nested_type_param
nested_types
nested_types2
position_abs
position_in_seq
position_to_end
repeat_eos_bits_b1
repeat_eos_bits_b4
repeat_eos_bytes_pad
repeat_eos_term_bytes
repeat_eos_term_struct
repeat_n_bytes
repeat_n_struct
repeat_n_term_bytes
term_bytes
""".split()
V011_CASES = """
bcd_user_type_be
bcd_user_type_le
combine_bool
expr_0
expr_3
expr_enum
expr_io_pos_bits
expr_mod
instance_in_repeat_expr
instance_std
instance_user_array
integers_min_max
js_signed_right_shift
multiple_use
non_standard
process_bytes_pad_term
process_coerce_bytes
process_repeat_usertype_dynarg_rotate
process_repeat_usertype_dynarg_xor
process_struct_pad_term
repeat_n_bytes_pad
repeat_n_bytes_pad_term
repeat_n_strz
repeat_n_term_struct
repeat_until_bytes
repeat_until_bytes_pad_term
repeat_until_term_struct
str_eos_pad_term_empty
str_eos_pad_term_equal
str_literals2
str_pad_term_roundtrip
struct_pad_term_equal
term_bytes2
term_struct3
term_u1_val
""".split()

# The Python properties for computed and parsed instances are MoonBit methods.
LAZY_MEMBERS = {
    "bcd_user_type_be": {"as_int", "as_str"},
    "bcd_user_type_le": {"as_int", "as_str"},
    "combine_bool": {"bool_calc_bit"},
    "expr_0": {"must_be_f7", "must_be_abc123"},
    "expr_3": {
        "three", "four", "is_str_eq", "is_str_ne", "is_str_lt", "is_str_gt",
        "is_str_le", "is_str_ge", "is_str_lt2", "test_not",
    },
    "expr_enum": {"const_dog", "derived_boom", "derived_dog"},
    "expr_mod": {"mod_pos_const", "mod_neg_const", "mod_pos_seq", "mod_neg_seq"},
    "instance_std": {"header"},
    "instance_user_array": {"user_entries"},
    "js_signed_right_shift": {"should_be_40000000", "should_be_a00000"},
    "multiple_use": {"second_use"},
    "position_abs": {"index"},
    "position_to_end": {"index"},
    "process_coerce_bytes": {"buf"},
    "process_repeat_usertype_dynarg_rotate": {
        "blocks_rol_0_b", "blocks_rol_1_b", "blocks_ror_0_b", "blocks_ror_1_b", "blocks_ror_2_b",
    },
    "process_repeat_usertype_dynarg_xor": {"blocks_0_b", "blocks_1_b"},
    "str_literals2": {"at_sign", "dollar1", "dollar2", "hash"},
}
PRESENT_OPTION_MEMBERS = {
    "expr_io_pos_bits": {"bar", "baz", "qux"},
    "instance_user_array": {"user_entries"},
}


def projection(node, frame, case):
    if isinstance(node, ast.Name) and node.id == "r":
        return "", frame
    if isinstance(node, ast.Attribute):
        path, owner = projection(node.value, frame, case)
        path += "." + node.attr
        value = getattr(owner, node.attr)
        if node.attr in LAZY_MEMBERS.get(case, ()):
            path += "()"
        if node.attr in PRESENT_OPTION_MEMBERS.get(case, ()):
            path += ".unwrap()"
        return path, value
    if isinstance(node, ast.Subscript):
        path, array = projection(node.value, frame, case)
        index = ast.literal_eval(node.slice)
        return f"{path}[{index}]", array[index]
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == "len":
        path, array = projection(node.args[0], frame, case)
        return path + ".length()", len(array)
    raise ValueError(f"Unsupported original assertion in {case}: {ast.dump(node)}")


def create_test(case, spec, data, reference):
    frame = reference.from_bytes(data)
    assertions = sorted(
        (node for node in ast.walk(ast.parse(spec))
         if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
         and isinstance(node.func.value, ast.Name) and node.func.value.id == "self"
         and node.func.attr.startswith("assert")),
        key=lambda node: node.lineno,
    )
    assert assertions, f"{case} has no original field assertions"
    lines = ["///|", f'test "{case} matches the original Kaitai assertions" {{',
             f'  let frame = parse_{case}({REFERENCE["bytes_literal"](data)})']
    for assertion in assertions:
        if assertion.func.attr != "assertEqual" or len(assertion.args) != 2:
            raise ValueError(f"Unsupported original assertion in {case}: {ast.dump(assertion)}")
        path, value = projection(assertion.args[0], frame, case)
        if isinstance(value, Enum):
            path += ".to_i()"
        elif isinstance(value, bytes):
            path += ".to_owned()"
        elif case == "enum_invalid" and path == ".pet_2":
            lines.append(f'  guard frame.pet_2 is UnknownCode({value}L) else {{ fail("expected unknown enum code") }}')
            path += ".to_i()"
            lines.append(f"  assert_eq(frame{path}, {value}L)")
            continue
        lines.append(f'  assert_eq(frame{path}, {TYPES["moon_literal"](value)})')
    return "\n".join([*lines, "}", ""]), len(assertions)


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    cases = V010_CASES + V011_CASES
    if len(cases) != len(set(cases)):
        raise ValueError("Duplicate runtime corpus cases")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="extended-runtime-", dir=build))
    archive_path = CORPUS["corpus_archive"]()
    formats = work / "formats"
    CORPUS["extract_formats"](archive_path, formats)
    refs, specs, consumer = (work / name for name in ("testformats", "spec", "consumer"))
    for directory in (refs, specs, consumer):
        directory.mkdir()
    vectors = {}
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for case in cases:
            spec = archive.read(prefix + f"spec/python/spec/test_{case}.py")
            match = re.search(rb"from_file\('src/([^']+)'\)", spec)
            sample = match[1].decode()
            vector = archive.read(prefix + f"src/{sample}")
            (specs / f"test_{case}.py").write_bytes(spec)
            sample_file = work / "src" / sample
            sample_file.parent.mkdir(parents=True, exist_ok=True)
            sample_file.write_bytes(vector)
            vectors[case] = spec, vector, sample
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats",
                    "--import-path", str(formats / "ks_path"), "--outdir", str(refs),
                    *(str(formats / f"{case}.ksy") for case in cases)], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    subprocess.run(["moon", "build", "--frozen", "--target", "js", "--release", "--deny-warn", "cmd/ksymoon"],
                   cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-extended"\nversion = "0.1.0"\n', encoding="utf-8")
    rows = []
    for case in cases:
        package = consumer / case
        package.mkdir()
        schema = formats / f"{case}.ksy"
        output = package / "parser.mbt"
        subprocess.run(["node", str(cli), "generate", str(schema), "--root", str(formats),
                        "-I", str(formats / "ks_path"), "--out", str(output)], cwd=ROOT, check=True)
        (package / "moon.pkg").write_text(CORPUS["parser_package"](output.read_text(encoding="utf-8")), encoding="utf-8")
        reference = getattr(importlib.import_module("testformats." + case), "".join(part.title() for part in case.split("_")))
        spec, data, sample = vectors[case]
        test, count = create_test(case, spec, data, reference)
        (package / "reference_wbtest.mbt").write_text(test, encoding="utf-8")
        rows.append({
            "schema": schema.name, "sample": sample, "assertions": count,
            "schema_sha256": hashlib.sha256(schema.read_bytes()).hexdigest(),
            "sample_sha256": hashlib.sha256(data).hexdigest(),
            "spec_sha256": hashlib.sha256(spec).hexdigest(),
            "fixture_test_sha256": hashlib.sha256(test.encode("utf-8")).hexdigest(),
        })
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": CORPUS["REVISION"],
        "upstream_archive_sha256": CORPUS["ARCHIVE_SHA256"],
        "targets": ["js", "wasm", "wasm-gc", "native"],
        "official_tests": len(rows), "tests_per_target": len(rows),
        "assertions_per_target": sum(row["assertions"] for row in rows),
        "v011_added_tests": len(V011_CASES),
        "v011_added_assertions_per_target": sum(row["assertions"] for row in rows[len(V010_CASES):]),
        "v011_added_schemas": [f"{case}.ksy" for case in V011_CASES],
        "schemas": rows,
    }
    (build / "extended-runtime-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'Extended runtime corpus: {len(rows)} original schemas, {report["assertions_per_target"]} Kaitai field assertions per target')
    print(f'v0.11.0 additions: {len(V011_CASES)} original schemas, '
          f'{report["v011_added_assertions_per_target"]} added field assertions per target')


if __name__ == "__main__":
    main()
