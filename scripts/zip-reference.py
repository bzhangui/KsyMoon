"""Verify the original ZIP and DOS timestamp schemas against Kaitai 0.11."""

import hashlib
import importlib.metadata
from io import BytesIO
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import tempfile
from zipfile import ZipFile
import zlib

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
CORPUS = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))
literal = REFERENCE["bytes_literal"]
SCHEMAS = {
    "archive/zip.ksy": "ff3070bad639c33e93ed8df9a7833af177c15facb684da5a97e1064cb985fd54",
    "common/dos_datetime.ksy": "34e9241000b0956c93c78bbb91a8f8a678b79738eb7f3b386e515f12f199e973",
}


def make_archive(entries, comment):
    local, central = bytearray(), bytearray()
    dos_time, dos_date = (3 << 11) | (5 << 5) | 3, (46 << 9) | (1 << 5) | 2
    for name, payload, method in entries:
        name = name.encode("utf-8")
        size = len(payload)
        # Uncompressed DEFLATE block for fixture bytes that are stable across hosts.
        compressed = b"\x01" + struct.pack("<HH", size, size ^ 0xFFFF) + payload if method == 8 else payload
        crc = zlib.crc32(payload)
        fields = (20, 0x800, method, dos_time, dos_date, crc, len(compressed), size, len(name), 0)
        central += struct.pack("<4s6H3I5H2I", b"PK\x01\x02", 20, *fields, 0, 0, 0, 0, len(local)) + name
        local += struct.pack("<4s5H3I2H", b"PK\x03\x04", *fields) + name + compressed
    footer = struct.pack("<4s4H2IH", b"PK\x05\x06", 0, 0, len(entries), len(entries),
                         len(central), len(local), len(comment))
    result = bytes(local + central + footer + comment)
    with ZipFile(BytesIO(result)) as archive:
        assert archive.testzip() is None
        assert archive.namelist() == [name for name, _, _ in entries]
    return result, len(local)


def fixture_test(case, reference, data, variants, files):
    expected = reference.from_bytes(data)
    lines = ["///|", f'test "ZIP {case} fields match Kaitai 0.11" {{',
             f"  let archive = parse_zip({literal(data)})",
             f"  assert_eq(archive.sections.map(fn(section) {{ section.section_type }}), {[s.section_type for s in expected.sections]})"]
    for index in range(files):
        local = expected.sections[index].body
        entry = expected.sections[files + index].body
        header = local.header
        lines.extend([
            f'  guard archive.sections[{index}].body is {variants["local_file"]}(local_{index}) else {{ fail("expected local file") }}',
            f"  let header_{index} = local_{index}.header",
            f"  assert_eq(local_{index}.body.to_owned(), {literal(local.body)})",
            f'  guard archive.sections[{files + index}].body is {variants["central_dir_entry"]}(entry_{index}) else {{ fail("expected directory entry") }}',
            f'  guard entry_{index}.local_header().body is {variants["local_file"]}(linked_{index}) else {{ fail("expected linked local header") }}',
            f'  assert_eq(linked_{index}.header.file_name, {json.dumps(entry.local_header.body.header.file_name, ensure_ascii=False)})',
            f"  assert_eq(entry_{index}.ofs_local_header, {entry.ofs_local_header})",
        ])
        for variable, value in ((f"header_{index}", header), (f"entry_{index}", entry)):
            lines.extend([
                f"  assert_eq({variable}.file_name, {json.dumps(value.file_name, ensure_ascii=False)})",
                f"  assert_eq({variable}.compression_method.to_i(), {value.compression_method.value}L)",
            ])
            for field in ("crc32", "len_body_compressed", "len_body_uncompressed"):
                lines.append(f"  assert_eq({variable}.{field}, {getattr(value, field)}U)")
        for part, components in (("time", ("hour", "minute", "second")), ("date", ("year", "month", "day"))):
            for component in components:
                name = "padded_" + component
                value = getattr(getattr(header.file_mod_time, part), name)
                lines.append(f"  assert_eq(header_{index}.file_mod_time.{part}.{name}(), {json.dumps(value)})")
    footer = expected.sections[-1].body
    lines.append(f'  guard archive.sections[{files * 2}].body is {variants["end_of_central_dir"]}(footer) else {{ fail("expected end of central directory") }}')
    for field in ("num_central_dir_entries_total", "len_central_dir", "ofs_central_dir"):
        lines.append(f"  assert_eq(footer.{field}, {getattr(footer, field)}U)")
    lines.append(f"  assert_eq(footer.comment, {json.dumps(footer.comment, ensure_ascii=False)})")
    return "\n".join([*lines, "}", ""])


def prefix_test(case, reference, data):
    accepted = []
    for size in range(len(data) + 1):
        try:
            reference.from_bytes(data[:size])
        except (EOFError, kaitaistruct.KaitaiStructError):
            continue
        accepted.append(size)
    assert accepted[-1] == len(data) and len(accepted) < len(data)
    return f'''///|
test "ZIP {case} prefixes match Kaitai 0.11" {{
  let archive = {literal(data)}
  let accepted : Array[Int] = {accepted}
  for size in 0..<(archive.length() + 1) {{
    let actual = try {{ ignore(parse_zip(archive[:size].to_owned())); true }} catch {{ _ => false }}
    assert_eq(actual, accepted.contains(size))
  }}
}}
''', {"inputs": len(data) + 1, "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted)}


def malformed_tests(reference, data, central_start, central_variant):
    bad_magic = b"X" + data[1:]
    try:
        reference.from_bytes(bad_magic)
    except kaitaistruct.ValidationNotEqualError:
        pass
    else:
        raise AssertionError("Kaitai accepted invalid ZIP magic")

    invalid_offset = bytearray(data)
    struct.pack_into("<i", invalid_offset, central_start + 42, len(data))
    reference_entry = reference.from_bytes(invalid_offset).sections[2].body
    try:
        _ = reference_entry.local_header
    except EOFError:
        pass
    else:
        raise AssertionError("Kaitai accepted an out-of-range local header")

    return f'''///|
test "ZIP rejects invalid section magic" {{
  try parse_zip({literal(bad_magic)}) catch {{
    _ => ()
  }} noraise {{ _ => fail("accepted invalid magic") }}
}}

///|
test "ZIP local header offset is checked lazily" {{
  let archive = parse_zip({literal(invalid_offset)})
  guard archive.sections[2].body is {central_variant}(entry) else {{ fail("expected directory entry") }}
  try entry.local_header() catch {{
    ZipTruncated(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted invalid local header offset") }}
}}
'''


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="zip-reference-", dir=build))
    paths = {path: WAV["verified_format"](path, digest, build / "kaitai-formats", work)
             for path, digest in SCHEMAS.items()}
    schema = paths["archive/zip.ksy"]
    refs = work / "references"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python",
                    "--import-path", str(work), "--outdir", str(refs), str(schema)], check=True)
    sys.path.insert(0, str(refs))
    from zip import Zip

    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-zip"\nversion = "0.1.0"\n', encoding="utf-8")
    output = consumer / "parser.mbt"
    generator, command, _ = WAV["generator_command"](work, False)
    subprocess.run([*command, "generate", str(schema), "--root", str(work), "--out", str(output)],
                   cwd=generator, check=True)
    source = output.read_text(encoding="utf-8")
    (consumer / "moon.pkg").write_text(CORPUS["parser_package"](source), encoding="utf-8")
    variants = {name: variant for variant, name in re.findall(r"(Case\d+)\(Zip_(\w+)\)", source)}

    entries = [("readme.txt", b"MoonBit\n", 0), ("采样.bin", bytes(range(8)), 8)]
    regular, central_start = make_archive(entries, "验收".encode("utf-8"))
    empty, _ = make_archive([], b"")
    tests, results = [], {}
    for case, data, files in (("stored-and-deflated", regular, len(entries)), ("empty", empty, 0)):
        tests.append(fixture_test(case, Zip, data, variants, files))
        prefix, counts = prefix_test(case, Zip, data)
        tests.append(prefix)
        results[case] = {"sha256": hashlib.sha256(data).hexdigest(), **counts}
    tests.append(malformed_tests(Zip, regular, central_start, variants["central_dir_entry"]))
    test = "\n".join(tests)
    (consumer / "reference_wbtest.mbt").write_text(test, encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": WAV["REVISION"],
        "schemas": SCHEMAS, "targets": ["js", "wasm", "wasm-gc", "native"],
        "tests_per_target": test.count('\ntest "'), "fixtures": results,
        "fixture_test_sha256": hashlib.sha256(test.encode("utf-8")).hexdigest(),
        "parser_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    }
    (build / "zip-reference-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'ZIP against Kaitai 0.11: {report["tests_per_target"]} tests per target, '
          f'{sum(item["inputs"] for item in results.values())} prefix and complete inputs')


if __name__ == "__main__":
    main()
