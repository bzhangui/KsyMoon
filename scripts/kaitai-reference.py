"""Generate MoonBit comparison tests from the pinned Kaitai Python target."""

import hashlib
import importlib
import importlib.metadata
import kaitaistruct
import io
import json
import shutil
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
        for name in ("udp_datagram", "stl", "conditional_layout", "stream_control", "repeat_zero_progress")
    }
    schemas.update({entry["schema"]: ROOT / "fixtures" / entry["source"] for entry in manifest["fixtures"]})
    subprocess.run(
        ["java", "-cp", str(work / name / "lib" / "*"), "io.kaitai.struct.JavaMain",
         "--target", "python", "--outdir", str(work),
         *(str(path) for path in schemas.values())],
        check=True,
    )
    # Execute the unmodified upstream Python specifications against the official target.
    spec_dir = work / "spec"
    spec_dir.mkdir()
    (work / "src").mkdir()
    (work / "testformats").mkdir()
    for generated in work.glob("*.py"):
        shutil.copyfile(generated, work / "testformats" / generated.name)
    for entry in manifest["fixtures"]:
        if "sample" not in entry:
            continue
        for key in ("sample", "spec"):
            source = ROOT / "fixtures" / entry[key]
            if hashlib.sha256(source.read_bytes()).hexdigest() != entry[key + "_sha256"]:
                raise ValueError(f"Upstream {key} changed: {source}")
        shutil.copyfile(ROOT / "fixtures" / entry["sample"], work / "src" / Path(entry["sample"]).name)
        shutil.copyfile(ROOT / "fixtures" / entry["spec"], spec_dir / Path(entry["spec"]).name)
    subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", "spec"], cwd=work, check=True)
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


def stream_tests(references):
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["fixtures"]:
        if "sample" not in entry:
            continue
        name = entry["schema"]
        data = (ROOT / "fixtures" / entry["sample"]).read_bytes()
        frame = references[name].from_bytes(data)
        checks = []
        counter = 0

        def visit(value, path, owner=None, field=None):
            nonlocal counter
            if field == "body" and name.startswith("switch_"):
                variant = None
                if isinstance(value, bytes):
                    variant = "Raw"
                elif value is None:
                    checks.append(f"  assert_true({path} is Unknown)")
                    return
                elif isinstance(value, int):
                    variant = f"Case{[1, 2, 4, 8].index(owner.code)}"
                else:
                    cls = type(value).__name__
                    if cls in ("Intval", "ChunkMeta"):
                        variant = "Case0"
                    elif cls in ("Strval", "ChunkDir"):
                        variant = "Case1"
                    else:
                        variant = "Default"
                variable = f"branch_{counter}"
                counter += 1
                checks.append(f'  guard {path} is {variant}({variable}) else {{ fail("wrong switch case at {path}") }}')
                path = variable
            if isinstance(value, list):
                checks.append(f"  assert_eq({path}.length(), {len(value)})")
                for index, item in enumerate(value):
                    visit(item, f"{path}[{index}]")
            elif isinstance(value, bytes):
                checks.append(f"  assert_eq({path}.to_owned(), {bytes_literal(value)})")
            elif isinstance(value, str):
                checks.append(f"  assert_eq({path}, {json.dumps(value, ensure_ascii=False)})")
            elif isinstance(value, int):
                # Compare through Int64 for all <=32-bit signed/unsigned scalars.
                if name == "switch_integers" and field == "body" and owner.code == 8:
                    checks.append(f"  assert_eq({path}, {value}UL)")
                else:
                    checks.append(f"  assert_eq({path}.to_int64(), {value}L)")
            else:
                for key, item in vars(value).items():
                    if not key.startswith("_"):
                        visit(item, f"{path}.{key}", value, key)
        visit(frame, "frame")
        yield "\n".join(["///|", f'test "Kaitai reference upstream {name}" {{',
                         f"  let frame = @{name}.parse_{name}({bytes_literal(data)})", *checks, "}"])

        prefix_checks = []
        for cut in range(len(data)):
            partial = data[:cut]
            try:
                references[name].from_bytes(partial)
            except (EOFError, UnicodeError, kaitaistruct.KaitaiStructError):
                prefix_checks.extend([
                    f"  try @{name}.parse_{name}({bytes_literal(partial)}) catch {{",
                    "    _ => ()",
                    f'  }} noraise {{ _ => fail("accepted {name} prefix {cut}") }}',
                ])
            else:
                prefix_checks.append(f"  ignore(@{name}.parse_{name}({bytes_literal(partial)}))")
        yield "\n".join(["///|", f'test "Kaitai reference prefix outcomes {name}" {{', *prefix_checks, "}"])

    # Positions inside bounded streams and laziness are additional custom regressions.
    for tag, body in ((1, b"\x78\x56\x34\x12"), (2, b"Hi\0!"), (99, b"RAW!")):
        data = b"\xaa\x10\x20\x30\x40\x55" + bytes([tag]) + body + b"A\0B\0one\0two\0"
        frame = references["stream_control"].from_bytes(data)
        assert frame.block._io.pos() == 1
        assert frame.block.at_zero == 16 and frame.block.at_end == 64
        assert frame.block._io.pos() == 1
        for _ in range(2):
            try:
                frame.block.outside
            except EOFError:
                pass
            else:
                raise AssertionError("official parser escaped a bounded stream")
            # Python 0.11 leaves a failed positioned getter at its failing cursor.
            # KsyMoon deliberately restores it for safe retry (covered separately).
            assert frame.block._io.pos() == 4
            frame.block._io.seek(1)
        checks = ["  assert_eq(frame.block.at_zero(), 16U)", "  assert_eq(frame.block.at_end(), 64U)",
                  "  assert_eq(frame.block.cursor(), 1L)", "  assert_eq(frame.block.stream_size(), 4L)",
                  f"  assert_eq(frame.tail, {frame.tail}U)", f"  assert_eq(frame.unicode, {json.dumps(frame.unicode)})",
                  f"  assert_eq(frame.lines, {json.dumps(frame.lines)})",
                  f"  assert_eq(frame.empty_steps.length(), {len(frame.empty_steps)})"]
        if tag == 1:
            checks += ['  guard frame.choice is Case0(word) else { fail("word switch") }',
                       f"  assert_eq(word.value, {frame.choice.value}U)"]
        elif tag == 2:
            checks += ['  guard frame.choice is Case1(message) else { fail("string switch") }',
                       f"  assert_eq(message.value, {json.dumps(frame.choice.value)})"]
        else:
            checks += ['  guard frame.choice is Raw(raw) else { fail("raw switch") }',
                       f"  assert_eq(raw.to_owned(), {bytes_literal(frame.choice)})"]
        yield "\n".join(["///|", f'test "Kaitai reference bounded stream tag {tag}" {{',
                         f"  let frame = @stream_control.parse_stream_control({bytes_literal(data)})", *checks, "}"])


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
    stream_comparisons = list(stream_tests(references))
    stream_output = ("// Expected values and prefix outcomes from official Kaitai Struct 0.11.\n"
                     "// Inputs, binary samples and Python specifications are pinned in fixtures/kaitai/manifest.json.\n"
                     "// Refresh: python scripts/kaitai-reference.py examples/consumer --refresh-stream-golden\n\n"
                     + "\n\n".join(stream_comparisons) + "\n")
    golden = ROOT / "examples/consumer/stream_reference_wbtest.mbt"
    if "--refresh-stream-golden" in sys.argv:
        golden.write_text(stream_output, encoding="utf-8")
    elif golden.read_text(encoding="utf-8") != stream_output:
        raise ValueError("P2 reference assertions differ from the checked-in official oracle output")
    (consumer / "stream_reference_wbtest.mbt").write_text(stream_output, encoding="utf-8")
    (consumer / "kaitai_reference_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    (consumer / "oracle-cases.json").write_text(json.dumps({
        "compiler_version": VERSION,
        "upstream_schemas": [entry["schema"] + ".ksy" for entry in manifest["fixtures"]],
        "upstream_specs": sum("spec" in entry for entry in manifest["fixtures"]),
        "upstream_proper_prefixes": sum(len((ROOT / "fixtures" / entry["sample"]).read_bytes()) for entry in manifest["fixtures"] if "sample" in entry),
        "prefixes_rejected": stream_output.count('} noraise { _ => fail("accepted '),
        "comparison_tests": len(tests) + len(stream_comparisons),
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Kaitai reference {VERSION}: verified {len(tests) + len(stream_comparisons)} comparisons "
          f"(4 UDP/STL + {len(semantic_tests)} conditional/instance + {len(stream_comparisons)} P2 stream/control checks)", flush=True)


if __name__ == "__main__":
    main()
