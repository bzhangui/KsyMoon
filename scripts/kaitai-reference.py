"""Generate MoonBit comparison tests from the pinned Kaitai Python target."""

import hashlib
import importlib
import importlib.metadata
import io
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
    subprocess.run(
        ["java", "-cp", str(work / name / "lib" / "*"), "io.kaitai.struct.JavaMain",
         "--target", "python", "--outdir", str(work),
         *(str(ROOT / "fixtures" / f"{schema}.ksy") for schema in ("udp_datagram", "stl"))],
        check=True,
    )
    sys.path.insert(0, str(work))
    return importlib.import_module("udp_datagram").UdpDatagram, importlib.import_module("stl").Stl


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


def main():
    consumer = Path(sys.argv[1])
    if importlib.metadata.version("kaitaistruct") != VERSION:
        raise RuntimeError(f"Install kaitaistruct=={VERSION} to run the reference check")
    udp, stl = compile_references()
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
    (consumer / "kaitai_reference_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    print(f"Kaitai reference {VERSION}: generated four UDP/STL field comparison tests", flush=True)


if __name__ == "__main__":
    main()
