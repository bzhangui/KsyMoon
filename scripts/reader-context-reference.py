"""Replay original Kaitai tests that depend on reader state during parsing."""

import hashlib
import importlib
import importlib.metadata
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
from zipfile import ZipFile

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
MOON_LITERAL = runpy.run_path(str(ROOT / "scripts/type-parameter-reference.py"))["moon_literal"]
LITERAL = REFERENCE["bytes_literal"]
TARGETS = ["js", "wasm", "wasm-gc", "native"]
SAMPLES = {
    "expr_io_pos": "expr_io_pos.bin",
    "instance_in_repeat_until": "repeat_until_s4.bin",
    "instance_in_sized": "process_rotate.bin",
    "valid_fail_inst": "fixed_struct.bin",
    "repeat_n_strz_double": "repeat_n_strz.bin",
}
FIELDS = {
    "expr_io_pos": (
        "substream1.my_str", "substream1.body", "substream1.number",
        "substream2.my_str", "substream2.body", "substream2.number",
    ),
    "instance_in_repeat_until": ("entries", "until_val"),
    "instance_in_sized": (
        "cont.seq_sized.seq_f", "cont.seq_sized.inst_invoked", "cont.seq_sized.inst_unused_by_seq",
        "cont.seq_in_stream.seq_f", "cont.seq_in_stream.inst",
        "cont.inst_in_stream.seq_f", "cont.inst_in_stream.inst",
        "cont.inst_sized.seq_f", "cont.inst_sized.inst_invoked", "cont.inst_sized.inst_unused_by_seq",
    ),
    "valid_fail_inst": ("a", "inst"),
    "repeat_n_strz_double": ("qty", "lines1", "lines2"),
}
LAZY = {"until_val", "inst_invoked", "inst_unused_by_seq", "inst", "inst_in_stream", "inst_sized"}
OPTIONAL = {"cont.seq_sized.seq_f", "cont.inst_sized.seq_f", "a"}


def field_value(frame, path):
    for member in path.split("."):
        frame = getattr(frame, member)
    return frame


def moon_accessor(path):
    return "frame." + ".".join(member + ("()" if member in LAZY else "") for member in path.split("."))


def fields_test(case, parser, data, title):
    frame = parser.from_bytes(data)
    checks = []
    for path in FIELDS[case]:
        value = field_value(frame, path)
        accessor = moon_accessor(path)
        if path in OPTIONAL:
            accessor += ".unwrap()"
        if isinstance(value, bytes):
            accessor += ".to_owned()"
        checks.append(f"  assert_eq({accessor}, {MOON_LITERAL(value)})")
    return "\n".join(["///|", f'test "{title}" {{',
                      f"  let frame = parse_{case}({LITERAL(data)})", *checks, "}", ""])


def lazy_validation_test(parser, data):
    try:
        parser.from_bytes(data)
    except kaitaistruct.ValidationNotEqualError as error:
        assert error.src_path == "/instances/inst"
        cursor, actual, expected = error.io.pos(), error.actual, error.expected
    else:
        raise AssertionError("Kaitai failed to invoke and validate the instance")
    # Kaitai reports the cursor after reading the u1. MoonBit reports the field start.
    offset = cursor - 1
    test = f'''///|
test "lazy validation rejects while selecting the sequence field" {{
  try parse_valid_fail_inst({LITERAL(data)}) catch {{
    ValidFailInstInvalidValue(field~, offset~, value~, minimum~, maximum~) => {{
      assert_eq(field, "valid_fail_inst.inst")
      assert_eq(offset, {offset})
      assert_eq(value, {actual}L)
      assert_eq(minimum, {expected}L)
      assert_eq(maximum, {expected}L)
    }}
    error => raise error
  }} noraise {{ _ => fail("accepted invalid lazy instance") }}
}}
'''
    repaired = data[:offset] + bytes([expected]) + data[cursor:]
    recovered = fields_test(
        "valid_fail_inst", parser, repaired, "successful lazy validation restores the sequence cursor",
    )
    return test + "\n" + recovered, repaired


def prefix_test(case, parser, data):
    accepted = []
    for length in range(len(data) + 1):
        try:
            frame = parser.from_bytes(data[:length])
            for field in FIELDS[case]:
                field_value(frame, field)
        except (EOFError, kaitaistruct.KaitaiStructError):
            continue
        accepted.append(length)
    # Force the same lazy fields on both sides before deciding whether a prefix works.
    force = [f"      ignore({moon_accessor(field)})" for field in FIELDS[case]]
    test = [
        "///|", f'test "{case} prefixes agree with Kaitai" {{',
        f"  let data = {LITERAL(data)}", f"  let accepted : Array[Int] = {accepted}",
        "  for cut in 0..<(data.length() + 1) {", "    let actual = try {",
        f"      let frame = parse_{case}(data[:cut].to_owned())", *force,
        "      true", "    } catch { _ => false }",
        "    assert_eq(actual, accepted.contains(cut))", "  }", "}", "",
    ]
    return "\n".join(test), {"inputs": len(data) + 1, "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="reader-context-", dir=build))
    archive_path = CORPUS["corpus_archive"]()
    formats = work / "formats"
    CORPUS["extract_formats"](archive_path, formats)
    refs, specs, samples, consumer = (work / name for name in ("testformats", "spec", "src", "consumer"))
    for directory in (refs, specs, samples, consumer):
        directory.mkdir()
    cases = {}
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for name, sample_name in SAMPLES.items():
            spec = archive.read(prefix + f"spec/python/spec/test_{name}.py")
            data = archive.read(prefix + f"src/{sample_name}")
            (specs / f"test_{name}.py").write_bytes(spec)
            (samples / sample_name).write_bytes(data)
            cases[name] = spec, data
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats",
                    "--import-path", str(formats / "ks_path"), "--outdir", str(refs),
                    *(str(formats / f"{case}.ksy") for case in cases)], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    subprocess.run(["moon", "build", "--frozen", "--target", "js", "--release", "--deny-warn", "cmd/ksymoon"],
                   cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-reader-context"\nversion = "0.1.0"\n', encoding="utf-8")
    results = {}
    for case, (spec, data) in cases.items():
        package = consumer / case
        package.mkdir()
        schema = formats / f"{case}.ksy"
        parser = package / "parser.mbt"
        subprocess.run(["node", str(cli), "generate", str(schema), "--root", str(formats),
                        "-I", str(formats / "ks_path"), "--out", str(parser)], cwd=ROOT, check=True)
        (package / "moon.pkg").write_text(CORPUS["parser_package"](parser.read_text(encoding="utf-8")), encoding="utf-8")
        reference = getattr(importlib.import_module("testformats." + case), "".join(part.title() for part in case.split("_")))
        variants = {}
        if case == "valid_fail_inst":
            test, repaired = lazy_validation_test(reference, data)
            variants["repaired"] = digest(repaired)
        else:
            test = fields_test(case, reference, data, f"{case} fields agree with Kaitai")
        if case == "repeat_n_strz_double":
            odd_count = b"\x03\x00\x00\x00" + data[4:]
            test += "\n" + fields_test(case, reference, odd_count, "computed repeat count uses floor division")
            variants["odd_count"] = digest(odd_count)
        prefix_check, outcomes = prefix_test(case, reference, data)
        test += "\n" + prefix_check
        (package / "reference_wbtest.mbt").write_text(test, encoding="utf-8")
        results[case] = {
            "schema_sha256": digest(schema.read_bytes()), "sample": SAMPLES[case], "sample_sha256": digest(data),
            "spec_sha256": digest(spec), "fixture_test_sha256": digest(test.encode("utf-8")),
            "parser_sha256": digest(parser.read_bytes()), "variants": variants, "prefixes_including_complete": outcomes,
            "tests_per_target": test.count('\ntest "'),
        }
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": CORPUS["REVISION"],
        "upstream_archive_sha256": CORPUS["ARCHIVE_SHA256"], "targets": TARGETS,
        "official_specs": len(results), "tests_per_target": sum(case["tests_per_target"] for case in results.values()),
        "prefix_inputs": sum(case["prefixes_including_complete"]["inputs"] for case in results.values()), "cases": results,
    }
    output = build / "reader-context-reference-report.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'Reader context agrees with Kaitai 0.11: {report["official_specs"]} original specs, '
          f'{report["tests_per_target"]} tests per target, {report["prefix_inputs"]} complete or prefix inputs')


if __name__ == "__main__":
    main()
