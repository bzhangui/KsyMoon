"""Compare original Kaitai layouts, navigation and recursion to Kaitai 0.11."""

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

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
MOON_LITERAL = runpy.run_path(str(ROOT / "scripts/type-parameter-reference.py"))["moon_literal"]
LITERAL = REFERENCE["bytes_literal"]
TARGETS = ["js", "wasm", "wasm-gc", "native"]
CASES = (
    "docstrings", "docstrings_docref_multi", "eof_exception_sized",
    "eos_exception_sized", "meta_tags", "meta_xref", "nested_types3",
    "optional_id", "valid_optional_id", "nav_parent_false",
    "nav_parent_false2", "nav_parent_override", "nav_parent_recursive",
    "nav_root_recursive", "recursive_one", "cast_to_top",
)

# Getter calls and nullable fields are explicit in the generated MoonBit API.
FIELDS = {
    "docstrings": (("one", "one"), ("two", "two()"), ("three", "three()")),
    "nested_types3": tuple((path, path) for path in (
        "a_cc.value_cc", "a_c_d.value_d", "b.value_b", "b.a_cc.value_cc", "b.a_c_d.value_d",
    )),
    "optional_id": tuple((f"_unnamed{i}", f"_unnamed{i}") for i in range(3)),
    "valid_optional_id": tuple((f"_unnamed{i}", f"_unnamed{i}") for i in range(3)),
    "nav_parent_false": (
        ("child_size", "child_size"),
        ("element_a.foo.code", "element_a.foo.code"),
        ("element_a.foo.more", "element_a.foo.more.unwrap()"),
        ("element_a.bar.foo.code", "element_a.bar.foo.code"),
        ("element_b.foo.code", "element_b.foo.code"),
    ),
    "nav_parent_false2": (("parentless.foo", "parentless.foo"),),
    "nav_parent_override": (
        ("child_size", "child_size"),
        ("child_1.data", "child_1.data"),
        ("mediator_2.child_2.data", "mediator_2.child_2.data"),
    ),
    "nav_parent_recursive": (
        ("value", "value"),
        ("next.value", "next.unwrap().value"),
        ("next.parent_value", "next.unwrap().parent_value().unwrap()"),
    ),
    "nav_root_recursive": (
        ("value", "value"),
        ("root_value", "root_value()"),
        ("next.value", "next.unwrap().value"),
        ("next.root_value", "next.unwrap().root_value()"),
    ),
    "cast_to_top": (
        ("code", "code"),
        ("header.code", "header().code"),
        ("header_casted.code", "header_casted().code"),
    ),
}
ABSENT = {
    "nav_parent_false": (("element_a.bar.foo.more", "element_a.bar.foo.more"),
                         ("element_b.foo.more", "element_b.foo.more")),
    "nav_parent_recursive": (("next.next", "next.unwrap().next"),
                             ("parent_value", "parent_value()")),
    "nav_root_recursive": (("next.next", "next.unwrap().next"),),
}
EOF_FIELDS = {
    "eof_exception_sized": "eof_exception_sized.buf",
    "eos_exception_sized": "eos_exception_sized.envelope.buf",
}
EMPTY_ROOTS = {"docstrings_docref_multi", "meta_tags", "meta_xref"}


def field_value(frame, path):
    for name in path.split("."):
        frame = getattr(frame, name)
    return frame


def class_name(case):
    return "".join(part.title() for part in case.split("_"))


def test_source(title, lines):
    return "\n".join(["///|", f'test "{title}" {{', *lines, "}", ""])


def normal_test(case, reference, data):
    original = reference.from_bytes(data)
    body = [f"  let frame = parse_{case}({LITERAL(data)})"]
    for path, accessor in FIELDS.get(case, ()):
        expected = field_value(original, path)
        if isinstance(expected, bytes):
            accessor += ".to_owned()"
        body.append(f"  assert_eq(frame.{accessor}, {MOON_LITERAL(expected)})")
    for path, accessor in ABSENT.get(case, ()):
        owner, name = path.rsplit(".", 1) if "." in path else ("", path)
        record = field_value(original, owner) if owner else original
        assert getattr(record, name, None) is None, path
        body.append(f"  assert_true(frame.{accessor} is None)")
    if case == "recursive_one":
        # The switch binds the first three tags to the root and the fourth to fini.
        assert original.one & 3 == 0 and original.next.one & 3 == 1
        assert original.next.next.one & 3 == 3
        body.extend([
            f"  assert_eq(frame.one, {original.one}U)",
            '  guard frame.next is Case0(second) else { fail("expected recursive case 0") }',
            f"  assert_eq(second.one, {original.next.one}U)",
            '  guard second.next is Case1(third) else { fail("expected recursive case 1") }',
            f"  assert_eq(third.one, {original.next.next.one}U)",
            '  guard third.next is Case3(finisher) else { fail("expected termination case") }',
            f"  assert_eq(finisher.finisher, {original.next.next.next.finisher}U)",
        ])
    elif len(body) == 1:
        body.append("  ignore(frame)")
    return test_source(f"{case} original sample agrees with Kaitai", body)


def eof_test(case, reference, data):
    try:
        reference.from_bytes(data)
    except kaitaistruct.EndOfStreamError as error:
        needed, remaining = error.bytes_needed, error.bytes_available
    else:
        raise AssertionError(f"{case} failed to report its bounded EOF")
    return test_source(f"{case} checks the bound of an empty type", [
        f"  try parse_{case}({LITERAL(data)}) catch {{",
        f"    {class_name(case)}Truncated(field~, offset~, needed~, remaining~) => {{",
        f'      assert_eq(field, "{EOF_FIELDS[case]}")',
        "      assert_eq(offset, 0)",
        f"      assert_eq(needed, {needed}L)",
        f"      assert_eq(remaining, {remaining})",
        "    }",
        "    error => raise error",
        '  } noraise { _ => fail("accepted a truncated bounded empty record") }',
    ])


def anonymous_validation_test(reference, data):
    mutations = (
        (0, "ContentsMismatch", kaitaistruct.ValidationNotEqualError),
        (6, "InvalidValue", kaitaistruct.ValidationNotEqualError),
        (7, "ValidationMismatch", kaitaistruct.ValidationExprError),
    )
    lines = []
    for sequence_index, (offset, moon_error, oracle_error) in enumerate(mutations):
        changed = data[:offset] + bytes([data[offset] ^ 1]) + data[offset + 1:]
        try:
            reference.from_bytes(changed)
        except oracle_error as error:
            assert error.src_path == f"/seq/{sequence_index}"
        else:
            raise AssertionError(f"anonymous field {sequence_index} failed to validate")
        lines.extend([
            f"  try parse_valid_optional_id({LITERAL(changed)}) catch {{",
            f"    ValidOptionalId{moon_error}(field~, ..) =>",
            f'      assert_eq(field, "valid_optional_id._unnamed{sequence_index}")',
            "    error => raise error",
            '  } noraise { _ => fail("accepted corrupted anonymous field") }',
        ])
    return test_source("anonymous fields retain contents and value validation", lines), len(mutations)


def prefix_test(case, reference, data):
    accepted = []
    fields = FIELDS.get(case, ())
    for length in range(len(data) + 1):
        try:
            frame = reference.from_bytes(data[:length])
            for path, _ in fields:
                field_value(frame, path)
        except (EOFError, kaitaistruct.KaitaiStructError):
            continue
        accepted.append(length)
    lines = [f"  let data = {LITERAL(data)}"]
    if case in EMPTY_ROOTS:
        assert len(accepted) == len(data) + 1
        body = [f"    ignore(parse_{case}(data[:cut].to_owned()))"]
    else:
        force = [f"      ignore(frame.{accessor})" for _, accessor in fields] or ["      ignore(frame)"]
        lines.append(f"  let accepted : Array[Int] = {accepted}")
        body = [
            "    let actual = try {",
            f"      let frame = parse_{case}(data[:cut].to_owned())",
            *force,
            "      true",
            "    } catch { _ => false }",
            "    assert_eq(actual, accepted.contains(cut))",
        ]
    code = test_source(f"{case} prefixes agree with Kaitai",
                       [*lines, "  for cut in 0..<(data.length() + 1) {", *body, "  }"])
    return code, {"inputs": len(data) + 1, "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted)}


def recursion_limit_test():
    # This limit belongs to the generated MoonBit parser, independently of Kaitai prefix parity.
    boundary = b"\xff" * 64 + b"\x2a"
    excessive = b"\xff" * 65 + b"\x2a"
    code = test_source("recursive root uses the same root at the KsyMoon depth limit", [
        f"  let mut node = parse_nav_root_recursive({LITERAL(boundary)})",
        "  for _ in 0..<64 {",
        "    node = node.next.unwrap()",
        "  }",
        "  assert_eq(node.value, 42U)",
        "  assert_eq(node.root_value(), 255L)",
        "  assert_true(node.next is None)",
        f"  try parse_nav_root_recursive({LITERAL(excessive)}) catch {{",
        "    NavRootRecursiveContextError(offset~, message~, ..) => {",
        "      assert_eq(offset, 65)",
        '      assert_eq(message, "record nesting exceeds 64")',
        "    }",
        "    error => raise error",
        '  } noraise { _ => fail("accepted a record beyond the recursion bound") }',
    ])
    return code, {"boundary_input_sha256": digest(boundary), "excessive_input_sha256": digest(excessive)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def prepare_oracle(work):
    archive_path = CORPUS["corpus_archive"]()
    formats = work / "formats"
    CORPUS["extract_formats"](archive_path, formats)
    refs, specs, samples = (work / name for name in ("testformats", "spec", "src"))
    for directory in (refs, specs, samples):
        directory.mkdir()
    cases = {}
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for case in CASES:
            spec = archive.read(prefix + f"spec/python/spec/test_{case}.py")
            matched = re.search(rb"from_file\('src/([^']+)'\)", spec)
            assert matched, f"Original Python spec does not identify a sample for {case}"
            sample = matched[1].decode("utf-8")
            data = archive.read(prefix + f"src/{sample}")
            (specs / f"test_{case}.py").write_bytes(spec)
            (samples / sample).write_bytes(data)
            cases[case] = sample, data, spec
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats",
                    "--import-path", str(formats / "ks_path"), "--outdir", str(refs),
                    *(str(formats / f"{case}.ksy") for case in cases)], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    return formats, cases


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="layout-navigation-", dir=build))
    formats, cases = prepare_oracle(work)
    subprocess.run(["moon", "build", "--frozen", "--target", "js", "--release", "--deny-warn", "cmd/ksymoon"],
                   cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-layout-navigation"\nversion = "0.1.0"\n', encoding="utf-8")
    results = {}
    for case, (sample, data, spec) in cases.items():
        package = consumer / case
        package.mkdir()
        schema = formats / f"{case}.ksy"
        parser = package / "parser.mbt"
        subprocess.run(["node", str(cli), "generate", str(schema), "--root", str(formats),
                        "-I", str(formats / "ks_path"), "--out", str(parser)], cwd=ROOT, check=True)
        (package / "moon.pkg").write_text(CORPUS["parser_package"](parser.read_text(encoding="utf-8")), encoding="utf-8")
        reference = getattr(importlib.import_module(f"testformats.{case}"), class_name(case))
        test = eof_test(case, reference, data) if case in EOF_FIELDS else normal_test(case, reference, data)
        prefix, counts = prefix_test(case, reference, data)
        test += "\n" + prefix
        invalid = 0
        limit_inputs = {}
        if case == "valid_optional_id":
            corrupted, invalid = anonymous_validation_test(reference, data)
            test += "\n" + corrupted
        if case == "nav_root_recursive":
            limit, limit_inputs = recursion_limit_test()
            test += "\n" + limit
        (package / "reference_wbtest.mbt").write_text(test, encoding="utf-8")
        results[case] = {
            "schema_sha256": digest(schema.read_bytes()), "sample": sample,
            "sample_sha256": digest(data), "spec_sha256": digest(spec),
            "fixture_test_sha256": digest(test.encode("utf-8")), "parser_sha256": digest(parser.read_bytes()),
            "prefixes_including_complete": counts, "other_invalid_inputs": invalid,
            "project_limit_tests": int(bool(limit_inputs)), "project_limit_inputs": limit_inputs,
            "tests_per_target": test.count('\ntest "'),
        }
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": CORPUS["REVISION"],
        "upstream_archive_sha256": CORPUS["ARCHIVE_SHA256"], "targets": TARGETS,
        "official_specs": len(results), "tests_per_target": sum(row["tests_per_target"] for row in results.values()),
        "prefix_inputs": sum(row["prefixes_including_complete"]["inputs"] for row in results.values()),
        "other_invalid_inputs": sum(row["other_invalid_inputs"] for row in results.values()),
        "project_limit_tests": sum(row["project_limit_tests"] for row in results.values()), "cases": results,
    }
    output = build / "layout-navigation-reference-report.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'Layout and navigation agree with Kaitai 0.11: {report["official_specs"]} original specs, '
          f'{report["tests_per_target"]} tests per target, {report["prefix_inputs"]} complete or prefix inputs')


if __name__ == "__main__":
    main()
