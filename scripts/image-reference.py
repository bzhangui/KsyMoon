"""Verify original image schemas against the Kaitai 0.11 Python target."""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import tempfile
import zlib

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
NUMERICS = runpy.run_path(str(ROOT / "scripts/numeric-endian-reference.py"))
parser_package = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))["parser_package"]
literal = REFERENCE["bytes_literal"]
SCHEMAS = {
    "gif": "2da551fc465428b9d6595f25347ac18381551cccfa1e24d85572ca4f276c2a8f",
    "bmp": "df83c2b9ebd16c68ac26fb6c3e2dfa27c0c718e34d6ef0211be28470ccc9c1c6",
    "png": "fcebc2b8b5d4a29d7c5e9eb2c2341da6c8c321677df802441a63b05a7085822e",
    "icc_4": "f237ddca193fe8d5752eb31f68eac9038bc09d8e600eb1ffd0ea7584f02d4348",
    "exif": "b390f61bea731072bf1bd5232f6b1b3ac83f3f698486cdb583d6925cd03c6770",
}


def gif_assertions(reference, _parser):
    image = base64.b64decode("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")
    lines = []
    accepted = 0
    for size in range(len(image) + 1):
        data = image[:size]
        try:
            screen = reference.from_bytes(data)
        except (EOFError, kaitaistruct.KaitaiStructError):
            lines.append(f"  assert_false(accepts_gif({literal(data)}))")
            continue
        accepted += 1
        descriptor = screen.logical_screen_descriptor
        codes = ", ".join(f"{block.block_type.value}L" for block in screen.blocks)
        lines.extend([
            f"  let frame_{size} = parse_gif({literal(data)})",
            f"  assert_eq(frame_{size}.logical_screen_descriptor.screen_width, {descriptor.screen_width}U)",
            f"  assert_eq(frame_{size}.logical_screen_descriptor.screen_height, {descriptor.screen_height}U)",
            f"  assert_eq(frame_{size}.blocks.map(fn(block) {{ block.block_type.to_i() }}), [{codes}])",
        ])
    assert 1 < accepted < len(image), "Expected both accepted and rejected truncated GIF inputs"
    tests = '''///|
fn accepts_gif(data : Bytes) -> Bool {
  try { ignore(parse_gif(data)); true } catch { _ => false }
}

///|
test "GIF fields and all prefixes agree with Kaitai 0.11" {
''' + "\n".join(lines) + "\n}\n"
    return tests, len(image) + 1, accepted


def prefix_assertions(name, ref, data, case):
    accepted = []
    for size in range(len(data) + 1):
        try:
            ref.from_bytes(data[:size])
        except (EOFError, kaitaistruct.KaitaiStructError, zlib.error):
            continue
        accepted.append(size)
    assert len(data) in accepted
    return f'''///|
test "{case} prefixes agree with Kaitai 0.11" {{
  let data = {literal(data)}
  let accepted : Array[Int] = {accepted}
  for size in 0..<(data.length() + 1) {{
    let actual = try {{ ignore(parse_{name}(data[:size].to_owned())); true }} catch {{ _ => false }}
    assert_eq(actual, accepted.contains(size))
  }}
}}
''', len(data) + 1, len(accepted)


def bmp_assertions(reference, _parser):
    lines = []
    inputs = accepted = 0
    for name, height in (("bottom_up", 1), ("top_down", -1)):
        data = struct.pack("<2sIHHI", b"BM", 58, 0, 0, 54)
        data += struct.pack("<IiiHHIIiiII", 40, 1, height, 1, 24, 0, 4, 2835, 2835, 0, 0)
        data += bytes.fromhex("01020300")
        expected = reference.from_bytes(data)
        header = expected.dib_info.header
        lines.append(f'''///|
test "BMP {name} offsets and DIB values agree with Kaitai 0.11" {{
  let bmp = parse_bmp({literal(data)})
  assert_eq(bmp.file_hdr.len_file, {expected.file_hdr.len_file}U)
  assert_eq(bmp.file_hdr.ofs_bitmap, {expected.file_hdr.ofs_bitmap})
  let header = bmp.dib_info.header
  guard header.image_width is Case1(width) else {{ fail("expected INFOHEADER width") }}
  assert_eq(width, {header.image_width}U)
  assert_eq(header.image_height(), {header.image_height}L)
  assert_eq(header.bits_per_pixel, {header.bits_per_pixel}U)
  assert_eq(header.bottom_up(), {str(header.bottom_up).lower()})
}}
''')
        prefix, count, passed = prefix_assertions("bmp", reference, data, "BMP " + name)
        lines.append(prefix)
        inputs += count
        accepted += passed
    profile_file = b"prix-\x80.icc\x00"
    header = struct.pack("<IiiHHIIiiII", 124, 1, 1, 1, 24, 0, 4, 2835, 2835, 0, 0)
    header += bytes(16) + struct.pack("<I", 0x4C494E4B) + bytes(48)
    header += struct.pack("<IIII", 0, 128, len(profile_file), 0)
    data = struct.pack("<2sIHHI", b"BM", 142 + len(profile_file), 0, 0, 138) + header + bytes(4) + profile_file
    profile_name = reference.from_bytes(data).dib_info.header.bitmap_v5_ext.profile_data
    assert profile_name == "prix-€.icc"
    try:
        _ = reference.from_bytes(data[:-1]).dib_info.header.bitmap_v5_ext.profile_data
    except EOFError:
        pass
    else:
        raise AssertionError("truncated linked BMP profile should fail when accessed")
    lines.append(f'''///|
test "BMP V5 linked profile uses Windows-1252 and the root stream" {{
  let bmp = parse_bmp({literal(data)})
  guard bmp.dib_info.header.bitmap_v5_ext is Some(v5) else {{ fail("expected V5 header") }}
  guard v5.profile_data() is Some(Case0(name)) else {{ fail("expected linked profile") }}
  assert_eq(name, {json.dumps(profile_name, ensure_ascii=False)})
  let truncated = parse_bmp({literal(data[:-1])})
  guard truncated.dib_info.header.bitmap_v5_ext is Some(truncated_v5) else {{ fail("expected V5 header") }}
  try truncated_v5.profile_data() catch {{
    BmpTruncated(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted truncated linked profile") }}
}}
''')
    inputs += 2
    accepted += 1
    return "\n".join(lines), inputs, accepted


def png_chunk(kind, payload):
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))


def stored_zlib(data):
    # A single final stored block keeps fixture bytes independent of the host compressor.
    assert len(data) <= 0xFFFF
    return b"\x78\x01\x01" + struct.pack("<HH", len(data), len(data) ^ 0xFFFF) + data + struct.pack(">I", zlib.adler32(data))


def png_assertions(reference, parser):
    profile = bytearray(132)
    profile[0:4] = struct.pack(">I", len(profile))
    profile[8:12] = b"\x04\x30\x00\x00"
    profile[12:24] = b"mntrRGB XYZ "
    profile[24:36] = struct.pack(">6H", 2026, 11, 24, 1, 2, 3)
    profile[36:40] = b"acsp"
    header = b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
    data = b"".join([
        header,
        png_chunk(b"iCCP", b"caf\xe9\x00\x00" + stored_zlib(profile)),
        png_chunk(b"eXIf", NUMERICS["make_exif"](True)),
        png_chunk(b"tEXt", b"Title\x00caf\xe9"),
        png_chunk(b"IDAT", stored_zlib(b"\x00\x01\x02\x03")),
        png_chunk(b"IEND", b""),
    ])
    result = reference.from_bytes(data)
    icc, exif, text = [entry.body for entry in result.chunks[:3]]
    exif_fields = exif.exif.body.ifd0.num_fields
    variants = dict((name, variant) for variant, name in re.findall(r"(Case\d+)\(Png_(\w+)\)", parser))
    kinds = [chunk.type for chunk in result.chunks]
    tests = f'''///|
test "PNG dimensions, Latin-1, ICC profile and Exif directory agree with Kaitai 0.11" {{
  let png = parse_png({literal(data)})
  assert_eq(png.ihdr.width, {result.ihdr.width}U)
  assert_eq(png.ihdr.height, {result.ihdr.height}U)
  assert_eq(png.chunks.map(fn(chunk) raise PngParseError {{ chunk.type_() }}), {json.dumps(kinds)})
  guard png.chunks[0].body is {variants["iccp_chunk"]}(profile) else {{ fail("expected iCCP") }}
  assert_eq(profile.profile_name, {json.dumps(icc.profile_name, ensure_ascii=False)})
  assert_eq(profile.profile.header.size, {icc.profile.header.size}U)
  assert_eq(profile.profile.tag_table.tag_count, {icc.profile.tag_table.tag_count}U)
  guard png.chunks[1].body is {variants["exif_chunk"]}(exif) else {{ fail("expected eXIf") }}
  assert_eq(exif.exif.body.ifd0().num_fields, {exif_fields}U)
  guard png.chunks[2].body is {variants["text_chunk"]}(text) else {{ fail("expected tEXt") }}
  assert_eq(text.text, {json.dumps(text.text, ensure_ascii=False)})
}}
'''
    prefix, count, passed = prefix_assertions("png", reference, data, "PNG with ICC and Exif")
    return tests + "\n" + prefix, count, passed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", action="store_true", help="use the published version in moon.mod")
    args = parser.parse_args()
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="image-reference-", dir=build))
    schemas = {name: WAV["verified_format"](f"image/{name}.ksy", digest, build / "kaitai-formats", work)
               for name, digest in SCHEMAS.items()}
    refs = work / "references"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--outdir", str(refs),
                    *(str(schemas[name]) for name in ("gif", "bmp", "png"))], check=True)
    sys.path.insert(0, str(refs))
    from bmp import Bmp
    from gif import Gif
    from png import Png

    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-images"\nversion = "0.1.0"\n', encoding="utf-8")
    generator, command, dependency = WAV["generator_command"](work, args.registry)
    results = {}
    for name, reference, assertions in (("gif", Gif, gif_assertions),
                                        ("bmp", Bmp, bmp_assertions), ("png", Png, png_assertions)):
        package = consumer / name
        package.mkdir()
        output = package / "parser.mbt"
        subprocess.run([*command, "generate", str(schemas[name]), "--root", str(work / "image"),
                        "--out", str(output)], cwd=generator, check=True)
        source = output.read_text(encoding="utf-8")
        (package / "moon.pkg").write_text(parser_package(source), encoding="utf-8")
        tests, inputs, accepted = assertions(reference, source)
        (package / "reference_wbtest.mbt").write_text(tests, encoding="utf-8")
        results[name] = {"inputs": inputs, "accepted": accepted, "rejected": inputs - accepted,
                         "fixture_test_sha256": hashlib.sha256(tests.encode("utf-8")).hexdigest()}
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "upstream_revision": WAV["REVISION"], "schema_sha256": SCHEMAS,
        "official_compiler": "0.11", "generator_dependency": dependency,
        "targets": WAV["TARGETS"], "formats": results,
    }
    name = "registry-image-reference-report.json" if args.registry else "image-reference-report.json"
    (build / name).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("GIF, BMP and PNG match Kaitai 0.11 on four targets: " + json.dumps(results))


if __name__ == "__main__":
    main()
