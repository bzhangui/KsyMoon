"""Compare the multi-file and byte-processing parsers with Kaitai Struct 0.11."""
import argparse
import importlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import zipfile
import zlib

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
literal = REFERENCE["bytes_literal"]
COMMON_IMPORTS = ("fixed_struct.bin", ("one", "two.one", "two.two.one"))
CASES = {
    "imports0": ("fixed_struct.bin", ("two", "hw.one", "hw_one")),
    "imports_rel_1": COMMON_IMPORTS,
    "imports_abs_abs": COMMON_IMPORTS,
    "imports_abs_rel": COMMON_IMPORTS,
    "imports_circular_a": ("fixed_struct.bin", ("code", "two.initial", "two.back_ref.code", "two.back_ref.two.initial")),
    "process_xor_const": ("process_xor_1.bin", ("key", "buf")),
    "process_xor_value": ("process_xor_1.bin", ("key", "buf")),
    "process_xor4_const": ("process_xor_4.bin", ("key", "buf")),
    "process_xor4_value": ("process_xor_4.bin", ("key", "buf")),
    "process_rotate": ("process_rotate.bin", ("buf1", "buf2", "buf3")),
    "process_to_user": ("process_rotate.bin", ("buf1.str",)),
    "process_repeat_bytes": ("process_xor_4.bin", ("bufs.0", "bufs.1")),
    "process_repeat_usertype": ("process_xor_4.bin", ("blocks.0.a", "blocks.0.b", "blocks.1.a", "blocks.1.b")),
    "zlib_surrounded": ("zlib_surrounded.bin", ("pre", "zlib.num", "post")),
    "zlib_with_header_78": ("zlib_with_header_78.bin", ("data",)),
}
LOCAL_MODULES = {
    "container": """meta: {id: container, imports: [segment]}
seq:
  - {id: outer, type: u1}
  - {id: body, type: segment, size: 3}
  - {id: stop, type: u1}
""",
    "segment": """meta: {id: segment}
seq:
  - {id: marker, type: u1}
  - {id: children, type: child, repeat: expr, repeat-expr: 2}
types:
  child:
    seq:
      - {id: number, type: u1}
    instances:
      root_marker: {value: _root.marker}
      parent_marker: {value: _parent.marker}
      root_size: {value: _root._io.size}
      shared_marker: {type: u1, pos: 0, io: _root._io}
""",
}


def invoke_cli(cli, cwd, arguments, *, diagnostic=None):
    result = subprocess.run([*cli, *map(str, arguments)], cwd=cwd,
                            text=True, encoding="utf-8", capture_output=True)
    if diagnostic is None:
        if result.returncode != 0:
            raise RuntimeError(result.stderr)
    elif result.returncode != 1 or diagnostic not in result.stderr:
        raise ValueError(f"Expected {diagnostic!r}: {result.returncode} {result.stderr}")


def field_assertion(frame, path):
    accessor = "frame"
    value = frame
    instance_fields = {"hw_one", "root_marker", "parent_marker", "shared_marker", "root_size"}
    long_fields = {"hw_one", "root_marker", "parent_marker", "root_size"}
    signed_paths = {"blocks.0.a", "blocks.0.b", "blocks.1.a", "blocks.1.b", "zlib.num"}
    for part in path.split("."):
        if part.isdigit():
            accessor += f"[{part}]"
            value = value[int(part)]
        else:
            value = getattr(value, part)
            accessor += "." + part
            if part == "back_ref":
                accessor += ".unwrap()"
            if part in instance_fields:
                accessor += "()"
    if isinstance(value, bytes):
        expected = literal(value)
        accessor += ".to_owned()"
    elif isinstance(value, str):
        expected = json.dumps(value)
    else:
        suffix = "L" if path.split(".")[-1] in long_fields else "" if path in signed_paths else "U"
        expected = f"{value}{suffix}"
    return f"  assert_eq({accessor}, {expected})"


def compare(name, constructor, data, fields):
    frame = constructor.from_bytes(data)
    parse = f"@{name}.parse_{name}"
    checks = [field_assertion(frame, field) for field in fields]
    if name == "imports_circular_a":
        assert not hasattr(frame.two.back_ref.two, "back_ref")
        checks.append("  assert_true(frame.two.back_ref.unwrap().two.back_ref is None)")
    rejected = bytearray()
    for cut in range(len(data)):
        try:
            constructor.from_bytes(data[:cut])
        except (EOFError, UnicodeError, ValueError, zlib.error, kaitaistruct.KaitaiStructError):
            rejected.append(1)
        else:
            rejected.append(0)
    tests = [
        "///|", f'test "{name} values match Kaitai" {{',
        f"  let frame = {parse}({literal(data)})", *checks, "}",
        "", "///|", f'test "{name} prefix outcomes match Kaitai" {{',
        f"  let sample = {literal(data)}", f"  let expected = {literal(rejected)}",
        "  for cut in 0..<sample.length() {",
        f"    let rejected = try {{ ignore({parse}(sample[:cut].to_owned())); false }} catch {{ _ => true }}",
        "    assert_eq(rejected, expected[cut] == 1)",
        "  }", "}",
    ]
    if name == "imports_circular_a":
        deep = b"PA" * 33 + b"PK"
        constructor.from_bytes(deep)
        tests += [
            "", "///|", 'test "circular import reads respect the record depth limit" {',
            f"  try {parse}({literal(deep)}) catch {{",
            '    @imports_circular_a.ImportsCircularAContextError(message~, ..) => assert_eq(message, "record nesting exceeds 64")',
            "    error => raise error",
            '  } noraise { _ => fail("accepted reads beyond the depth budget") }', "}",
        ]
    if name == "zlib_with_header_78":
        corrupt = data[:-1] + bytes([data[-1] ^ 1])
        try:
            constructor.from_bytes(corrupt)
        except zlib.error:
            pass
        else:
            raise ValueError("Kaitai reference accepted a bad zlib checksum")
        tests += [
            "", "///|", 'test "zlib rejects a bad checksum at the source field" {',
            f"  try {parse}({literal(corrupt)}) catch {{",
            '    @zlib_with_header_78.ZlibWithHeader78ContextError(field~, offset~, ..) => {',
            '      assert_eq(field, "zlib_with_header_78.data")',
            "      assert_eq(offset, 0)",
            "    }",
            "    error => raise error",
            '  } noraise { _ => fail("accepted a bad checksum") }', "}",
        ]
    return "\n".join(tests), sum(rejected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", action="store_true", help="generate through the published Mooncakes module")
    args = parser.parse_args()
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="module-process-", dir=build))
    formats = work / "formats"
    upstream = CORPUS["corpus_archive"]()
    CORPUS["extract_formats"](upstream, formats)
    for name, source in LOCAL_MODULES.items():
        (formats / f"{name}.ksy").write_text(source, encoding="utf-8")
    spec = work / "spec"
    samples = work / "src"
    refs = work / "testformats"
    consumer = work / "consumer"
    for child in (spec, samples, refs, consumer):
        child.mkdir()
    with zipfile.ZipFile(upstream) as archive:
        prefix = archive.namelist()[0]
        for name, (sample, _) in CASES.items():
            (spec / f"test_{name}.py").write_bytes(archive.read(prefix + f"spec/python/spec/test_{name}.py"))
            (samples / sample).write_bytes(archive.read(prefix + f"src/{sample}"))
    dependency = None
    if args.registry:
        registry_generator = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))["generator_command"]
        generator, cli, dependency = registry_generator(work, True)
    else:
        generator = ROOT
        subprocess.run(["moon", "build", "--frozen", "--release", "--target", "js", "cmd/ksymoon"],
                       cwd=ROOT, check=True)
        cli = ["node", str(ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js")]

    sources = {name: formats / f"{name}.ksy" for name in (*CASES, "container")}
    options = ["--root", formats, "-I", formats / "ks_path"]
    escaped = formats / "outside.ksy"
    escaped.write_text("meta: {id: outside, imports: [../outside]}\n", encoding="utf-8")
    invoke_cli(cli, generator, ["check", escaped, *options], diagnostic="import path leaves the project root")
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--python-package", "testformats", "--import-path",
                    str(formats / "ks_path"), "--outdir", str(refs), *map(str, sources.values())], check=True)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
    sys.path.insert(0, str(work))

    (consumer / "moon.mod").write_text('name = "example/ksymoon-module-process"\nversion = "0.1.0"\n', encoding="utf-8")
    (consumer / "moon.pkg").write_text(
        'import {\n' + "".join(f'  "example/ksymoon-module-process/{name}",\n' for name in sources) +
        '} for "wbtest"\n', encoding="utf-8",
    )
    checks = []
    prefixes = rejected = 0
    for name, source in sources.items():
        package = consumer / name
        package.mkdir()
        output = package / "parser.mbt"
        invoke_cli(cli, generator, ["generate", source, "--out", output, *options])
        manifest = CORPUS["parser_package"](output.read_text(encoding="utf-8"))
        (package / "moon.pkg").write_text(manifest, encoding="utf-8")
        if name == "container":
            data = bytes([7, 42, 31, 63, 9])
            fields = ("outer", "body.children.0.root_marker", "body.children.0.parent_marker",
                      "body.children.0.root_size", "body.children.1.shared_marker", "stop")
        else:
            sample, fields = CASES[name]
            data = (samples / sample).read_bytes()
        constructor = getattr(importlib.import_module("testformats." + name), "".join(part.title() for part in name.split("_")))
        test, failures = compare(name, constructor, data, fields)
        checks.append(test)
        prefixes += len(data)
        rejected += failures
    (consumer / "oracle_wbtest.mbt").write_text("\n\n".join(checks) + "\n", encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    result = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "generator_dependency": dependency, "upstream_specs": len(CASES), "schemas": list(sources), "targets": ["js", "wasm", "wasm-gc", "native"],
        "tests_per_target": sum(test.count('\ntest "') for test in checks), "prefixes": prefixes, "rejected_prefixes": rejected,
    }
    report = "registry-module-process-report.json" if args.registry else "module-process-report.json"
    (build / report).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Modules/processors: {len(sources)} schemas, {prefixes} prefix outcomes ({rejected} rejected); four backends passed")


if __name__ == "__main__":
    main()
