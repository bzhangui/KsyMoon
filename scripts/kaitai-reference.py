"""Generate MoonBit comparison tests from the pinned Kaitai Python target."""

import hashlib
import importlib
import importlib.metadata
import io
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
from urllib.request import urlopen
import zipfile

VERSION = "0.11"
COMPILER_SHA256 = "ff89389d9dc9e770d78a24af328763cb1f8e7b31ce7766c9edf10669a060f2a2"
ROOT = Path(__file__).resolve().parents[1]


def compile_references():
    cache = ROOT / "_build" / "kaitai-reference"
    cache.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="oracle-", dir=cache))
    name = f"kaitai-struct-compiler-{VERSION}"
    archive = cache / f"{name}.zip"
    if archive.exists():
        binary = archive.read_bytes()
    else:
        url = f"https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/{VERSION}/{name}.zip"
        with urlopen(url, timeout=60) as response:
            binary = response.read()
    if hashlib.sha256(binary).hexdigest() != COMPILER_SHA256:
        raise ValueError("Kaitai compiler archive failed SHA-256 verification")
    if not archive.exists():
        archive.write_bytes(binary)
    with zipfile.ZipFile(io.BytesIO(binary)) as compiler:
        compiler.extractall(work)
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    schemas = {
        name: ROOT / "fixtures" / f"{name}.ksy"
        for name in ("udp_datagram", "stl", "conditional_layout")
    }
    schemas.update({entry["schema"]: ROOT / "fixtures" / entry["source"] for entry in manifest["fixtures"]})
    subprocess.run(
        ["java", "-cp", str(work / name / "lib" / "*"), "io.kaitai.struct.JavaMain",
         "--target", "python", "--outdir", str(work),
         *(str(path) for path in schemas.values())],
        check=True,
    )
    sys.path.insert(0, str(work))
    return {name: getattr(importlib.import_module(name), "".join(part.title() for part in name.split("_")))
            for name in schemas}


def bytes_literal(data):
    return 'b"' + "".join(f"\\x{byte:02X}" for byte in data) + '"'


def udp_test(data, reference, suffix):
    packet = reference.from_bytes(data)
    assertions = [
        *(f"  assert_eq(packet.{field}, {getattr(packet, field)}U)"
          for field in ("src_port", "dst_port", "length", "checksum")),
        f"  assert_eq(packet.body.to_owned(), {bytes_literal(packet.body)})",
    ]
    return "\n".join([
        "///|", f'test "Kaitai reference UDP {suffix}" {{',
        f"  let packet = @udp.parse_udp_datagram({bytes_literal(data)})", *assertions, "}",
    ])


def stl_test(data, reference, suffix):
    mesh = reference.from_bytes(data)
    assertions = [
        f"  assert_eq(mesh.header.to_owned(), {bytes_literal(mesh.header)})",
        f"  assert_eq(mesh.num_triangles, {mesh.num_triangles}U)",
        f"  assert_eq(mesh.triangles.length(), {len(mesh.triangles)})",
    ]
    for i, triangle in enumerate(mesh.triangles):
        base = f"mesh.triangles[{i}]"
        assertions.extend([
            f"  assert_eq({base}.abr, {triangle.abr}U)",
            f"  assert_eq({base}.vertices.length(), {len(triangle.vertices)})",
        ])
        points = [(f"{base}.normal", triangle.normal)]
        points.extend((f"{base}.vertices[{j}]", point) for j, point in enumerate(triangle.vertices))
        for path, point in points:
            for axis in ("x", "y", "z"):
                assertions.append(f"  assert_eq({path}.{axis}, {getattr(point, axis)!r})")
    return "\n".join([
        "///|", f'test "Kaitai reference STL {suffix}" {{',
        f"  let mesh = @stl.parse_stl({bytes_literal(data)})", *assertions, "}",
    ])


def optional_integer(value):
    return "None" if value is None else f"Some({value}L)"


def compatibility_tests(references):
    data = b"\x08\x05\xfe"
    values = references["if_values"].from_bytes(data)
    checks = [
        f"  assert_eq(frame.codes[{i}].half_opcode(), {optional_integer(code.half_opcode)})"
        for i, code in enumerate(values.codes)
    ]
    yield "\n".join([
        "///|", 'test "Kaitai reference conditional value instances" {',
        f"  let frame = @if_values.parse_if_values({bytes_literal(data)})", *checks, "}",
    ])
    never = references["if_instances"].from_bytes(b"")
    assert never.never_happens is None
    assert never._io.pos() == 0
    yield "\n".join([
        "///|", 'test "Kaitai reference false instance skips invalid seek" {',
        '  let frame = @if_instances.parse_if_instances(b"")',
        "  assert_true(frame.never_happens() is None)", "}",
    ])
    data = struct.pack("<III", 16, 2, 3) + b"PAD!abcdef"
    frame = references["instance_std_array"].from_bytes(data)
    before = frame._io.pos()
    entries = frame.entries
    assert frame._io.pos() == before == 12
    checks = [f"  assert_eq(entries[{i}].to_owned(), {bytes_literal(value)})" for i, value in enumerate(entries)]
    yield "\n".join([
        "///|", 'test "Kaitai reference positioned repeated instance" {',
        f"  let frame = @instance_std_array.parse_instance_std_array({bytes_literal(data)})",
        "  let entries = frame.entries()", f"  assert_eq(entries.length(), {len(entries)})", *checks, "}",
    ])
    data = struct.pack("<Ii", 9837, -9837)
    frame = references["expr_int_div"].from_bytes(data)
    checks = [f"  assert_eq(frame.{name}(), {getattr(frame, name)}L)"
              for name in ("div_pos_const", "div_neg_const", "div_pos_seq", "div_neg_seq")]
    yield "\n".join([
        "///|", 'test "Kaitai reference signed floor division" {',
        f"  let frame = @expr_int_div.parse_expr_int_div({bytes_literal(data)})", *checks, "}",
    ])
    for flag, data in ((0, b"\x00\xff\x7f"), (1, b"\x01\x02AB\x12\x34\x7f\x99")):
        frame = references["conditional_layout"].from_bytes(data)
        checksum = getattr(frame, "checksum", None)
        checksum_code = "None" if checksum is None else f"Some({checksum}U)"
        checks = [f"  assert_eq(frame.tail, {frame.tail}U)",
                  f"  assert_eq(frame.checksum, {checksum_code})",
                  f"  assert_eq(frame.derived(), {frame.derived}L)",
                  f"  assert_eq(frame.chained(), {frame.chained}L)"]
        if flag:
            checks.append(f"  assert_eq(frame.payload.unwrap().to_owned(), {bytes_literal(frame.payload)})")
            cursor = frame._io.pos()
            assert frame.last == 153 and frame._io.pos() == cursor
            assert frame.following == 153 and frame._io.pos() == cursor + 1
            checks.extend(["  assert_eq(frame.last(), 153U)", "  assert_eq(frame.following(), 153U)"])
        else:
            checks.append("  assert_true(frame.payload is None)")
        yield "\n".join([
            "///|", f'test "Kaitai reference conditional sequence flag {flag}" {{',
            f"  let frame = @conditional.parse_conditional_layout({bytes_literal(data)})", *checks, "}",
        ])


def main():
    consumer = Path(sys.argv[1])
    if importlib.metadata.version("kaitaistruct") != VERSION:
        raise RuntimeError(f"Install kaitaistruct=={VERSION} to run the reference check")
    references = compile_references()
    udp, stl = references["udp_datagram"], references["stl"]
    # Fixed vectors include empty payloads, signed floats, and nonzero attributes.
    triangle_a = struct.pack("<12fH", 0, 0, 1, 0, 0, 0, -1.5, 2.25, 0, 0, 3.5, 0, 0x1234)
    triangle_b = struct.pack("<12fH", 1, 0, 0, 0, 0, 0, 0, -0.5, 1, 0, 0, -4, 0xFEDC)
    header = bytes(range(80))
    tests = [
        udp_test(struct.pack(">4H", 42000, 9, 12, 0xCAFE) + b"\x00\xffA\x80", udp, "with binary body"),
        udp_test(struct.pack(">4H", 7, 65535, 8, 0), udp, "with empty body"),
        stl_test(header + struct.pack("<I", 2) + triangle_a + triangle_b, stl, "with two triangles"),
        stl_test(header + struct.pack("<I", 0), stl, "with no triangles"),
    ]
    semantic_tests = list(compatibility_tests(references))
    tests.extend(semantic_tests)
    (consumer / "kaitai_reference_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    print(f"Kaitai reference {VERSION}: generated {len(tests)} comparisons "
          f"(4 UDP/STL + {len(semantic_tests)} conditional/instance checks)", flush=True)


if __name__ == "__main__":
    main()
