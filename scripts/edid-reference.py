"""Compare the unmodified pinned EDID format against Kaitai 0.11."""

import hashlib
import importlib.metadata
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys
import tempfile

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
PARSER_PACKAGE = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))["parser_package"]
LITERAL = REFERENCE["bytes_literal"]
SCHEMA = "hardware/edid.ksy"
SCHEMA_SHA256 = "c22baa1c3d0c4b023b1cd686fe4b4f3f3f0d3571aa12e1627d4abf5b028b0648"
MAGIC = bytes.fromhex("00 ff ff ff ff ff ff 00")


def edid_block(mfg, product, serial, week, year, gamma):
    """Build a deterministic 128-byte base block carrying EDID metadata."""
    data = bytearray(128)
    data[:8] = MAGIC
    a, b, c = (ord(letter) - 0x40 for letter in mfg)
    struct.pack_into(">H", data, 8, (a << 10) | (b << 5) | c)
    struct.pack_into("<HI", data, 10, product, serial)
    data[16:25] = bytes((week, year - 1990, 1, 4, 0x80, 53, 30, gamma, 0x0a))
    data[25:35] = bytes.fromhex("ca 8c a4 57 4f 9d 24 0e 50 54")
    data[35:38] = b"\x21\x08\0"
    # The first and third standard timing entries are active; 01 01 is unused.
    data[38:54] = bytes.fromhex("a9 c0 01 01 81 8f 01 01 01 01 01 01 01 01 01 01")
    data[54:72] = b"\0\0\0\xfc\0MoonBit Panel"
    data[-1] = -sum(data[:-1]) & 0xff
    assert len(data) == 128 and sum(data) % 256 == 0
    return bytes(data)


def test_source(title, lines):
    return "\n".join(["///|", f'test "{title}" {{', *lines, "}", ""])


def maybe_number(value, suffix):
    return "None" if value is None else f"Some({value!r}{suffix})"


def field_test(name, data, reference):
    expected = reference.from_bytes(data)
    lines = [f"  let frame = parse_edid({LITERAL(data)})"]
    for field in ("mfg_bytes", "product_code", "serial", "mfg_week", "mfg_year_mod",
                  "edid_version_major", "edid_version_minor", "input_flags",
                  "screen_size_h", "screen_size_v", "gamma_mod", "features_flags"):
        lines.append(f"  assert_eq(frame.{field}, {getattr(expected, field)}U)")
    for field in ("mfg_id_ch1", "mfg_id_ch2", "mfg_id_ch3", "mfg_year"):
        lines.append(f"  assert_eq(frame.{field}(), {getattr(expected, field)}L)")
    lines.extend([
        f"  assert_eq(frame.mfg_str(), {json.dumps(expected.mfg_str)})",
        f"  assert_eq(frame.gamma(), {maybe_number(getattr(expected, 'gamma', None), '')})",
        f"  assert_eq(frame.chromacity.red_x_int(), {expected.chromacity.red_x_int}L)",
        f"  assert_eq(frame.chromacity.red_x(), {expected.chromacity.red_x!r})",
        f"  assert_eq(frame.chromacity.white_y_int(), {expected.chromacity.white_y_int}L)",
        f"  assert_eq(frame.chromacity.white_y(), {expected.chromacity.white_y!r})",
        f"  assert_eq(frame.est_timings.can_640x480px_60hz, "
        f"{json.dumps(expected.est_timings.can_640x480px_60hz)})",
        f"  assert_eq(frame.est_timings.can_1024x768px_60hz, "
        f"{json.dumps(expected.est_timings.can_1024x768px_60hz)})",
        f"  assert_eq(frame.std_timings.length(), {len(expected.std_timings)})",
    ])
    for index, timing in enumerate(expected.std_timings):
        lines.extend([
            f"  let timing = frame.std_timings[{index}]",
            f"  assert_eq(timing.bytes_lookahead().to_owned(), {LITERAL(timing.bytes_lookahead)})",
            f"  assert_eq(timing.is_used(), {json.dumps(timing.is_used)})",
            f"  assert_eq(timing.aspect_ratio.to_i(), {timing.aspect_ratio.value}L)",
            f"  assert_eq(timing.horiz_active_pixels(), {maybe_number(getattr(timing, 'horiz_active_pixels', None), 'L')})",
            f"  assert_eq(timing.refresh_rate(), {maybe_number(getattr(timing, 'refresh_rate', None), 'L')})",
        ])
    return test_source(f"EDID {name} metadata and timings agree with Kaitai", lines)


def prefix_test(name, data, reference):
    accepted = []
    for size in range(len(data) + 1):
        try:
            frame = reference.from_bytes(data[:size])
            _ = frame.mfg_str, frame.gamma, [(timing.is_used, timing.bytes_lookahead)
                                          for timing in frame.std_timings]
        except (EOFError, kaitaistruct.KaitaiStructError):
            continue
        accepted.append(size)
    assert len(data) in accepted and 0 not in accepted
    code = test_source(f"EDID {name} prefixes agree with Kaitai", [
        f"  let data = {LITERAL(data)}",
        f"  let accepted : Array[Int] = {accepted}",
        "  for size in 0..<(data.length() + 1) {",
        "    let ok = try {",
        "      let frame = parse_edid(data[:size].to_owned())",
        "      ignore(frame.mfg_str())",
        "      ignore(frame.gamma())",
        "      for timing in frame.std_timings {",
        "        ignore(timing.is_used())",
        "        ignore(timing.bytes_lookahead())",
        "      }",
        "      true",
        "    } catch { _ => false }",
        "    assert_eq(ok, accepted.contains(size))",
        "  }",
    ])
    return code, {"inputs": len(data) + 1, "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted),
                  "first_accepted_length": accepted[0]}


def invalid_magic_test(data, reference):
    changed = b"\x02" + data[1:]
    try:
        reference.from_bytes(changed)
    except kaitaistruct.ValidationNotEqualError as error:
        assert error.src_path == "/seq/0"
    else:
        raise AssertionError("Kaitai accepted an invalid EDID signature")
    return test_source("EDID rejects an invalid signature", [
        f"  try parse_edid({LITERAL(changed)}) catch {{",
        '    EdidContentsMismatch(field~, ..) => assert_eq(field, "edid.magic")',
        "    error => raise error",
        '  } noraise { _ => fail("accepted invalid EDID signature") }',
    ])


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="edid-reference-", dir=build))
    schema = WAV["verified_format"](SCHEMA, SCHEMA_SHA256, build / "kaitai-formats", work)
    refs = work / "references"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--outdir", str(refs),
                    str(schema)], check=True)
    sys.path.insert(0, str(refs))
    from edid import Edid

    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-edid"\nversion = "0.1.0"\n', encoding="utf-8")
    parser = consumer / "parser.mbt"
    generator, command, _ = WAV["generator_command"](work, False)
    subprocess.run([*command, "generate", str(schema), "--root", str(work), "--out", str(parser)],
                   cwd=generator, check=True)
    (consumer / "moon.pkg").write_text(PARSER_PACKAGE(parser.read_text(encoding="utf-8")), encoding="utf-8")
    first = edid_block("ACM", 0x1234, 0x76543210, 10, 2020, 120)
    second = edid_block("XYZ", 0xabcd, 0xf0123456, 255, 2024, 255)
    fixtures, tests = {}, []
    for name, data in (("normal gamma", first), ("unknown gamma", second)):
        tests.append(field_test(name, data, Edid))
        prefix, counts = prefix_test(name, data, Edid)
        tests.append(prefix)
        fixtures[name] = {"sha256": digest(data), **counts}
    tests.append(invalid_magic_test(first, Edid))
    source = "\n".join(tests).encode("utf-8")
    (consumer / "reference_wbtest.mbt").write_bytes(source)
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": WAV["REVISION"],
        "schema": SCHEMA, "schema_sha256": SCHEMA_SHA256, "targets": WAV["TARGETS"],
        "tests_per_target": len(tests), "fixtures": fixtures,
        "prefix_inputs": sum(row["inputs"] for row in fixtures.values()), "other_invalid_inputs": 1,
        "parser_sha256": digest(parser.read_bytes()), "fixture_test_sha256": digest(source),
    }
    (build / "edid-reference-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f'Original EDID agrees with Kaitai 0.11: {len(tests)} tests per target, '
          f'{report["prefix_inputs"]} complete or prefix inputs')


if __name__ == "__main__":
    main()
