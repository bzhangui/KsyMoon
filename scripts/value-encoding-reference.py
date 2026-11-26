"""Replay unmodified Kaitai cases for value conversions and text encodings."""

import ast
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
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
LITERAL = REFERENCE["bytes_literal"]
CASES = (
    "expr_ops_parens", "expr_str_ops", "expr_to_i_trailing", "float_to_i",
    "expr_bytes_non_literal", "expr_fstring_0", "str_literals", "str_literals_latin1",
    "expr_str_encodings", "str_encodings", "str_encodings_default", "valid_eq_str_encodings",
)
EXPECTED_FAILURES = ("str_encodings_escaping_enc", "str_encodings_escaping_to_s")
SEQUENCE_MEMBERS = {
    "expr_str_ops": {"one"},
    "float_to_i": {"single_value", "double_value", "single_value_if", "double_value_if"},
    "expr_fstring_0": {"seq_str", "seq_int"},
    "str_encodings": {"str1", "str2", "str3", "str4"},
    "str_encodings_default": {"rest", "str1", "str2", "str3", "str4"},
    "valid_eq_str_encodings": {"str1", "str2", "str3", "str4"},
    "str_encodings_escaping_enc": {"str1", "str2", "str3", "str4"},
}
OPTIONAL_MEMBERS = {"single_value_if", "double_value_if"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def class_name(case):
    return "".join(part.title() for part in case.split("_"))


def projection(node, case):
    """Translate a supported upstream assertion without executing its test source."""
    if isinstance(node, ast.Name) and node.id == "r":
        return "frame", lambda frame: frame
    if isinstance(node, ast.Attribute):
        base, resolve = projection(node.value, case)
        member = node.attr
        method = "" if member in SEQUENCE_MEMBERS.get(case, ()) else "()"
        optional = ".unwrap()" if member in OPTIONAL_MEMBERS else ""
        return f"{base}.{member}{method}{optional}", lambda frame: getattr(resolve(frame), member)
    if isinstance(node, ast.Subscript):
        base, resolve = projection(node.value, case)
        index = ast.literal_eval(node.slice)
        # The original subscript assertions in this suite index a byte string.
        return f"{base}[{index}].to_int()", lambda frame: resolve(frame)[index]
    if isinstance(node, ast.Call) and len(node.args) == 1:
        if isinstance(node.func, ast.Name) and node.func.id == "len":
            base, resolve = projection(node.args[0], case)
            return base + ".length()", lambda frame: len(resolve(frame))
        if isinstance(node.func, ast.Attribute) and node.func.attr == "str_to_arr":
            base, resolve = projection(node.args[0], case)
            return base + ".to_array().map(fn(c) { c.to_int() })", lambda frame: list(map(ord, resolve(frame)))
    raise ValueError(f"Unsupported upstream projection in {case}: {ast.dump(node)}")


def test_source(title, lines):
    return "\n".join(["///|", f'test "{title}" {{', *lines, "}", ""])


def normal_checks(case, tree, frame):
    lines = []
    # This original spec asserts successful validation by parsing without an exception.
    if case == "valid_eq_str_encodings":
        return [f"  assert_eq(frame.str{i}, {json.dumps(getattr(frame, f'str{i}'), ensure_ascii=False)})"
                for i in range(1, 5)]
    if case in EXPECTED_FAILURES:
        return lines
    for call in sorted((node for node in ast.walk(tree) if isinstance(node, ast.Call)
                        and isinstance(node.func, ast.Attribute)
                        and node.func.attr in ("assertEqual", "assertAlmostEqual")), key=lambda node: node.lineno):
        accessor, resolve = projection(call.args[0], case)
        actual = resolve(frame)
        expected = ast.literal_eval(call.args[1])
        if call.func.attr == "assertAlmostEqual":
            places = ast.literal_eval(call.args[2])
            assert round(abs(actual - expected), places) == 0
            if call.args[0].attr in ("single_value", "single_value_if"):
                accessor += ".to_double()"
            lines.append(f"  assert_true(({accessor} - {actual!r}).abs() < {0.5 * 10**(-places):.1e})")
        else:
            assert actual == expected, (case, accessor, actual, expected)
            lines.append(f"  assert_eq({accessor}, {json.dumps(actual, ensure_ascii=False)})")
    assert lines, case
    return lines


def failure_checks(case, tree, frame):
    lines = []
    failure_count = 0
    for block in sorted((node for node in ast.walk(tree) if isinstance(node, ast.With)), key=lambda node: node.lineno):
        context = block.items[0].context_expr
        if not (isinstance(context, ast.Call) and isinstance(context.func, ast.Attribute)
                and context.func.attr == "assertRaises"):
            continue
        error_name = context.args[0].id
        statement, = block.body
        assert isinstance(statement, ast.Assign)
        accessor, resolve = projection(statement.value, case)
        field = case + "." + accessor[len("frame."):].replace("()", "")
        if error_name == "ValueError":
            try:
                resolve(frame)
            except ValueError:
                pass
            else:
                raise AssertionError(f"Kaitai accepted invalid integer text at {field}")
            variant = "ContextError(field~, message~, ..)"
            expected = 'assert_eq(message, "invalid integer text")'
        elif error_name == "LookupError":
            try:
                resolve(frame)
            except LookupError as error:
                prefix = "unknown encoding: "
                assert str(error).startswith(prefix), str(error)
                label = str(error)[len(prefix):]
            else:
                raise AssertionError(f"Kaitai accepted unknown encoding at {field}")
            variant = "InvalidEncoding(field~, encoding~, ..)"
            expected = f"assert_eq(encoding, {json.dumps(label, ensure_ascii=False)})"
        else:
            raise ValueError(f"Unexpected original exception in {case}: {error_name}")
        lines.extend([
            f"  try {accessor} catch {{",
            f"    {class_name(case)}{variant} => {{",
            f'      assert_eq(field, "{field}")',
            f"      {expected}",
            "    }",
            "    error => raise error",
            f'  }} noraise {{ _ => fail("accepted invalid value at {field}") }}',
        ])
        failure_count += 1
    return lines, failure_count


def prefix_test(case, data, reference, source):
    accepted = []
    for size in range(len(data) + 1):
        try:
            reference.from_bytes(data[:size])
        except (EOFError, kaitaistruct.KaitaiStructError, UnicodeError):
            continue
        accepted.append(size)
    lines = [f"  let data = {LITERAL(data)}"]
    raises = re.search(rf"^pub fn parse_{case}[^\n]*\braise\b", source, re.MULTILINE)
    if raises:
        lines.extend([
            f"  let accepted : Array[Int] = {accepted}",
            "  for size in 0..<(data.length() + 1) {",
            f"    let ok = try {{ ignore(parse_{case}(data[:size].to_owned())); true }} catch {{ _ => false }}",
            "    assert_eq(ok, accepted.contains(size))",
            "  }",
        ])
    else:
        assert len(accepted) == len(data) + 1, case
        lines.extend([
            "  for size in 0..<(data.length() + 1) {",
            f"    ignore(parse_{case}(data[:size].to_owned()))",
            "  }",
        ])
    return test_source(f"{case} prefix parsing agrees with Kaitai", lines), {
        "inputs": len(data) + 1, "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted),
    }


def prepare_oracle(work):
    archive_path = CORPUS["corpus_archive"]()
    formats, refs, specs, samples = (work / path for path in ("formats", "testformats", "spec", "src"))
    CORPUS["extract_formats"](archive_path, formats)
    for directory in (refs, specs, samples):
        directory.mkdir()
    vectors = {}
    with ZipFile(archive_path) as archive:
        prefix = archive.namelist()[0]
        for case in CASES + EXPECTED_FAILURES:
            spec = archive.read(prefix + f"spec/python/spec/test_{case}.py")
            match = re.search(rb"from_file\('src/([^']+)'\)", spec)
            assert match, case
            sample = match[1].decode("utf-8")
            data = archive.read(prefix + f"src/{sample}")
            (specs / f"test_{case}.py").write_bytes(spec)
            (samples / sample).write_bytes(data)
            vectors[case] = sample, data, spec
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats",
                    "--import-path", str(formats / "ks_path"), "--outdir", str(refs),
                    *(str(formats / f"{case}.ksy") for case in vectors)], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))
    return formats, vectors


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="value-encoding-", dir=build))
    formats, vectors = prepare_oracle(work)
    subprocess.run(["moon", "build", "--frozen", "--target", "js", "--release", "--deny-warn", "cmd/ksymoon"],
                   cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-values"\nversion = "0.1.0"\n', encoding="utf-8")
    rows = {}
    for case, (sample, data, spec) in vectors.items():
        package = consumer / case
        package.mkdir()
        schema = formats / f"{case}.ksy"
        parser = package / "parser.mbt"
        subprocess.run(["node", str(cli), "generate", str(schema), "--root", str(formats),
                        "-I", str(formats / "ks_path"), "--out", str(parser)], cwd=ROOT, check=True)
        source = parser.read_text(encoding="utf-8")
        (package / "moon.pkg").write_text(CORPUS["parser_package"](source), encoding="utf-8")
        reference = getattr(importlib.import_module(f"testformats.{case}"), class_name(case))
        frame = reference.from_bytes(data)
        tree = ast.parse(spec)
        assertions = normal_checks(case, tree, frame)
        errors, failures = failure_checks(case, tree, frame)
        check = test_source(f"{case} matches Kaitai values and expected errors",
                            [f"  let frame = parse_{case}({LITERAL(data)})", *assertions, *errors])
        prefix, counts = prefix_test(case, data, reference, source)
        tests = (check + "\n" + prefix).encode("utf-8")
        (package / "reference_wbtest.mbt").write_bytes(tests)
        rows[case] = {
            "schema_sha256": digest(schema.read_bytes()), "sample": sample,
            "sample_sha256": digest(data), "spec_sha256": digest(spec),
            "fixture_test_sha256": digest(tests), "parser_sha256": digest(parser.read_bytes()),
            "expected_failure_spec": case in EXPECTED_FAILURES,
            "value_assertions": len(assertions), "expected_runtime_errors": failures,
            "prefixes_including_complete": counts, "tests_per_target": tests.count(b'\ntest "'),
        }
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": CORPUS["REVISION"],
        "upstream_archive_sha256": CORPUS["ARCHIVE_SHA256"], "targets": WAV["TARGETS"],
        "official_specs": len(CASES), "expected_failure_specs": len(EXPECTED_FAILURES),
        "value_assertions": sum(row["value_assertions"] for row in rows.values()),
        "expected_runtime_errors": sum(row["expected_runtime_errors"] for row in rows.values()),
        "tests_per_target": sum(row["tests_per_target"] for row in rows.values()),
        "prefix_inputs": sum(row["prefixes_including_complete"]["inputs"] for row in rows.values()), "cases": rows,
    }
    (build / "value-encoding-reference-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'Values and encodings agree with Kaitai 0.11: {report["official_specs"]} original specs, '
          f'{report["expected_failure_specs"]} original expected-failure specs, '
          f'{report["tests_per_target"]} tests per target, {report["prefix_inputs"]} complete or prefix inputs')


if __name__ == "__main__":
    main()
