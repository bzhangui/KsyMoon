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
        for name in ("udp_datagram", "stl", "conditional_layout", "stream_control", "repeat_zero_progress", "reader_edges", "pure_nested_value", "pure_stream_value", "pure_repeated_value", "cross_stream_layout", "io_partial_seq", "io_partial_lazy")
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
        if "sample" not in entry or entry.get("group") in ("io", "navigation", "types"):
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


def edge_tests(references):
    data = b"\0A\0"
    frame = references["reader_edges"].from_bytes(data)
    assert frame.conditional_text is None
    for name in ("sized_text", "padded_bytes"):
        try:
            getattr(frame, name)
        except kaitaistruct.InvalidArgumentError:
            pass
        else:
            raise AssertionError("official parser accepted a negative size")
    yield "\n".join([
        "///|", 'test "Kaitai reference negative sized byte options" {',
        f"  let frame = @reader_edges.parse_reader_edges({bytes_literal(data)})",
        "  assert_true(frame.conditional_text() is None)",
        "  try frame.sized_text() catch { _ => () } noraise { _ => fail(\"negative terminated size\") }",
        "  try frame.padded_bytes() catch { _ => () } noraise { _ => fail(\"negative padded size\") }", "}",
    ])
    data = b"\0A\0|\0B\0"
    frame = references["reader_edges"].from_bytes(data)
    checks = [f"  assert_eq(frame.{name}(), {json.dumps(getattr(frame, name))})"
              for name in ("explicit_text", "explicit_strz", "explicit_sized", "unpositioned")]
    checks.append(f"  assert_eq(frame.following().to_owned(), {bytes_literal(frame.following)})")
    yield "\n".join(["///|", 'test "Kaitai reference explicit UTF16 byte terminators" {',
                     f"  let frame = @reader_edges.parse_reader_edges({bytes_literal(data)})", *checks, "}"])
    data = b"\0A\0B\0\0\0REST"
    frame = references["reader_edges"].from_bytes(data)
    yield "\n".join(["///|", 'test "Kaitai reference implicit UTF16 double byte terminator" {',
                     f"  let frame = @reader_edges.parse_reader_edges({bytes_literal(data)})",
                     f"  assert_eq(frame.implicit_strz(), {json.dumps(frame.implicit_strz)})", "}"])
    frame = references["pure_nested_value"].from_bytes(b"")
    yield "\n".join(["///|", 'test "Kaitai reference pure nested value record" {',
                     '  let frame = @pure_nested_value.parse_pure_nested_value(b"")',
                     f"  assert_eq(frame.header.number(), {frame.header.number}L)",
                     f"  assert_eq(frame.header.label(), {json.dumps(frame.header.label)})", "}"])
    for data in (b"", b"ABC"):
        frame = references["pure_stream_value"].from_bytes(data)
        checks = [f"  assert_eq(frame.peek().number(), {frame.peek.number}L)",
                  f"  assert_eq(frame.peek().stream_size(), {frame.peek.stream_size}L)"]
        if getattr(frame, "header", None) is None:
            checks.append("  assert_true(frame.header is None)")
        else:
            checks.append(f"  assert_eq(frame.header.unwrap().stream_size(), {frame.header.stream_size}L)")
        yield "\n".join(["///|", f'test "Kaitai reference pure stream input length {len(data)}" {{',
                         f"  let frame = @pure_stream_value.parse_pure_stream_value({bytes_literal(data)})", *checks, "}"])
    frame = references["pure_repeated_value"].from_bytes(b"")
    yield "\n".join(["///|", 'test "Kaitai reference pure repeated and default branch records" {',
                     '  let frame = @pure_repeated_value.parse_pure_repeated_value(b"")',
                     f"  assert_eq(frame.headers.length(), {len(frame.headers)})",
                     f"  assert_eq(frame.headers[0].number(), {frame.headers[0].number}L)",
                     f"  assert_eq(frame.single().number(), {frame.single.number}L)",
                     "  guard frame.choice() is Default(header)",
                     f"  assert_eq(header.number(), {frame.choice.number}L)", "}"])



def io_tests(references):
    """Compare untouched upstream schemas, including lazy reads on every prefix."""
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["fixtures"]:
        if entry.get("group") != "io":
            continue
        name = entry["schema"]
        data = (ROOT / "fixtures" / entry["sample"]).read_bytes()

        def exercise(frame):
            if name == "instance_io_user":
                return [item.name for item in frame.entries]
            if name == "instance_io_user_earlier":
                return [frame.a_mid, frame.b_mid, frame.into_a.inst.last,
                        frame.into_b.inst.last, frame.sized_a.last, frame.sized_b.last,
                        frame.into_a_skipped.inst.last]
            return [tag.tag_content.content for tag in frame.tags]

        def moon_reads(base):
            if name == "instance_io_user":
                return [f"for item in {base}.entries {{ ignore(item.name()) }}"]
            if name == "instance_io_user_earlier":
                return [f"ignore({base}.{expr})" for expr in (
                    "a_mid()", "b_mid()", "into_a.inst().last()", "into_b.inst().last()",
                    "sized_a.last()", "sized_b.last()", "into_a_skipped.inst().last()")]
            tags = f"{base}.tags()" if name == "nav_parent3" else f"{base}.tags"
            return [f"for tag in {tags} {{ ignore(tag.tag_content()) }}"]

        frame = references[name].from_bytes(data)
        exercise(frame)
        checks = []
        def scalar(path, value, optional=False):
            if value is None:
                checks.append(f"  assert_eq({path}, None)")
            else:
                text = json.dumps(value, ensure_ascii=False) if isinstance(value, str) else f"{value}U"
                checks.append(f"  assert_eq({path}, {'Some(' + text + ')' if optional else text})")
        if name == "instance_io_user":
            scalar("frame.qty_entries", frame.qty_entries)
            for index, item in enumerate(frame.entries):
                scalar(f"frame.entries[{index}].name_ofs", item.name_ofs)
                scalar(f"frame.entries[{index}].value", item.value)
                scalar(f"frame.entries[{index}].name()", item.name)
                scalar(f"frame.entries[{index}].name()", item.name)
            checks.append(f"  assert_eq(frame.strings.str, {json.dumps(frame.strings.str)})")
        elif name == "instance_io_user_earlier":
            for field in ("a_mid", "b_mid"):
                scalar(f"frame.{field}()", getattr(frame, field))
            for field in ("sized_a", "sized_b"):
                slot = getattr(frame, field)
                scalar(f"frame.{field}.content", getattr(slot, "content", None), True)
                scalar(f"frame.{field}.last()", slot.last, True)
            for field in ("into_a", "into_b", "into_a_skipped"):
                foo = getattr(frame, field)
                scalar(f"frame.{field}.indicator", foo.indicator)
                scalar(f"frame.{field}.bar", getattr(foo, "bar", None), True)
                scalar(f"frame.{field}.inst().content", getattr(foo.inst, "content", None), True)
                scalar(f"frame.{field}.inst().last()", getattr(foo.inst, "last", None), True)
            scalar("frame.last_accessor.v", frame.last_accessor.v, True)
        else:
            scalar("frame.ofs_tags", frame.ofs_tags)
            scalar("frame.num_tags", frame.num_tags)
            tags = "frame.tags()" if name == "nav_parent3" else "frame.tags"
            checks.append(f"  let tags = {tags}")
            checks.append(f"  assert_eq(tags.length(), {len(frame.tags)})")
            for index, tag in enumerate(frame.tags):
                for field in ("name", "ofs", "num_items"):
                    scalar(f"tags[{index}].{field}", getattr(tag, field))
                checks.append(f'  guard tags[{index}].tag_content() is Case0(body_{index}) else {{ fail("wrong tag branch") }}')
                scalar(f"body_{index}.content", tag.tag_content.content)
        yield "\n".join(["///|", f'test "Kaitai reference cross-stream upstream {name}" {{',
                         f"  let frame = @{name}.parse_{name}({bytes_literal(data)})", *checks, "}"])
        prefix_checks = []
        for cut in range(len(data)):
            partial = data[:cut]
            try:
                exercise(references[name].from_bytes(partial))
            except (EOFError, UnicodeError, kaitaistruct.KaitaiStructError):
                prefix_checks.extend(["  try {", f"    let frame = @{name}.parse_{name}({bytes_literal(partial)})",
                                      *("    " + line for line in moon_reads("frame")), "  } catch { _ => () }",
                                      f'  noraise {{ _ => fail("accepted {name} prefix {cut}") }}'])
            else:
                prefix_checks.extend(["  {", f"    let frame = @{name}.parse_{name}({bytes_literal(partial)})",
                                      *("    " + line for line in moon_reads("frame")), "  }"])
        yield "\n".join(["///|", f'test "Kaitai reference lazy prefix outcomes {name}" {{', *prefix_checks, "}"])

    # Mixed repeat, switch, cache and conditional stream operations on one schema.
    for head in (0xAA, 0xAB):
        data = bytes([head, 16, 17, 18, 19, 32, 33, 0, 35, 85])
        frame = references["cross_stream_layout"].from_bytes(data)
        checks = []
        for expr in ("chosen", "positioned", "left.root_marker", "right.parent_marker",
                     "pair.first", "pair.second", "pair.parent_marker", "eos_items",
                     "until_items", "owner_position", "left_position", "right_position",
                     "skipped", "next_left", "next_left", "left_remaining", "raw_switch"):
            value = frame
            moon = "frame"
            for part in expr.split("."):
                value = getattr(value, part)
                moon += "." + part + ("()" if part not in ("left", "right", "first", "second") else "")
            if value is None:
                expect = "None"
            elif isinstance(value, bytes):
                if expr == "raw_switch":
                    checks.append(f'  guard {moon} is Raw(raw) else {{ fail("wrong raw branch") }}')
                    moon = "raw.to_owned()"
                else:
                    moon += ".to_owned()"
                expect = bytes_literal(value)
            elif isinstance(value, list):
                expect = "[" + ", ".join(str(item) + "U" for item in value) + "]"
            else:
                expect = str(value) + ("L" if expr.endswith("position") else "U")
            checks.append(f"  assert_eq({moon}, {expect})")
        yield "\n".join(["///|", f'test "Kaitai reference cross stream selection {head}" {{',
                         f"  let frame = @cross_stream_layout.parse_cross_stream_layout({bytes_literal(data)})", *checks, "}"])
    for name in ("io_partial_seq", "io_partial_lazy"):
        frame = references[name].from_bytes(b"\x00\x11\x01\x22")
        values = [getattr(item, "value", None) for item in frame.entries]
        tags = "frame.entries()" if name == "io_partial_lazy" else "frame.entries"
        yield "\n".join(["///|", f'test "Kaitai reference partial array {name}" {{',
                         f"  let frame = @{name}.parse_{name}(b\"\\x00\\x11\\x01\\x22\")",
                         f"  let entries = {tags}",
                         *(f"  assert_eq(entries[{i}].value, {'None' if value is None else 'Some(' + str(value) + 'U)'})" for i,value in enumerate(values)), "}"])


def navigation_tests(references, prefix_counts):
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["fixtures"]:
        if entry.get("group") != "navigation":
            continue
        name = entry["schema"]
        data = (ROOT / "fixtures" / entry["sample"]).read_bytes()

        def exercise(frame):
            if name == "expr_io_ternary":
                return frame.one_or_two_io_size2
            return frame.mess_up._io.size()

        rejected = bytearray()
        for cut in range(len(data)):
            try:
                exercise(references[name].from_bytes(data[:cut]))
            except (EOFError, UnicodeError, kaitaistruct.KaitaiStructError):
                rejected.append(1)
            else:
                rejected.append(0)
        prefix_counts.append(sum(rejected))
        getter = "one_or_two_io_size2()" if name == "expr_io_ternary" else "mess_up()"
        yield "\n".join([
            "///|", f'test "Kaitai reference navigation prefix outcomes {name}" {{',
            f"  let input = {bytes_literal(data)}", f"  let rejected = {bytes_literal(rejected)}",
            "  for cut in 0..<input.length() {",
            "    let failed = try {",
            f"      let frame = @{name}.parse_{name}(input[:cut].to_owned())",
            f"      ignore(frame.{getter})",
            "      false",
            "    } catch { _ => true }",
            "    assert_eq(failed, rejected[cut] == 1)",
            "  }", "}",
        ])
        if name == "io_local_var":
            f = references[name].from_bytes(data)
            yield "\n".join([
                "///|", 'test "Kaitai reference positioned cast retains the parent cursor" {',
                f"  let frame = @io_local_var.parse_io_local_var({bytes_literal(data)})",
                f"  assert_eq(frame.skip.to_owned(), {bytes_literal(f.skip)})",
                "  assert_eq(frame.always_null, None)", f"  assert_eq(frame.followup, {f.followup}U)",
                "  assert_true(frame.mess_up() is Case1(_))", "}",
            ])
        else:
            for raw in (data, bytes([0x40]) + data[1:]):
                f = references[name].from_bytes(raw)
                index = 0 if f.flag == 0x40 else 1
                branch_field = ("one", "two")[index]
                item = getattr(f.one_or_two_obj, branch_field)
                stream = f.one_or_two_io
                yield "\n".join([
                    "///|", f'test "Kaitai reference typed object and stream selection {f.flag}" {{',
                    f"  let frame = @expr_io_ternary.parse_expr_io_ternary({bytes_literal(raw)})",
                    f'  guard frame.one_or_two_obj() is Case{index}(item) else {{ fail("wrong object") }}',
                    f"  assert_eq(item.{branch_field}, {item}U)",
                    "  let stream = frame.one_or_two_io()",
                    f"  assert_eq(stream.pos(), {stream.pos()}L)",
                    f"  assert_eq(stream.size(), {stream.size()}L)",
                    f"  assert_eq(stream.eof(), {str(stream.is_eof()).lower()})",
                    f"  assert_eq(frame.one_or_two_io_size1(), {f.one_or_two_io_size1}L)",
                    f"  assert_eq(frame.one_or_two_io_size2(), {f.one_or_two_io_size2}L)",
                    f"  assert_eq(frame.one_or_two_io_size_add_3(), {f.one_or_two_io_size_add_3}L)",
                    "}",
                ])


def type_tests(references, prefix_counts):
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["fixtures"]:
        if entry.get("group") != "types":
            continue
        name = entry["schema"]
        data = (ROOT / "fixtures" / entry["sample"]).read_bytes()
        args = ", 5L, true" if name == "params_def" else ""

        def parse(raw):
            ref = references[name]
            if name == "params_def":
                return ref(5, True, kaitaistruct.KaitaiStream(io.BytesIO(raw)))
            return ref.from_bytes(raw)

        rejected = bytearray()
        for cut in range(len(data)):
            try:
                parse(data[:cut])
            except (EOFError, UnicodeError, kaitaistruct.KaitaiStructError):
                rejected.append(1)
            else:
                rejected.append(0)
        prefix_counts.append(sum(rejected))
        yield "\n".join([
            "///|", f'test "Kaitai reference typed schema prefixes {name}" {{',
            f"  let input = {bytes_literal(data)}", f"  let rejected = {bytes_literal(rejected)}",
            "  for cut in 0..<input.length() {",
            "    let failed = try {",
            f"      ignore(@{name}.parse_{name}(input[:cut].to_owned(){args}))",
            "      false",
            "    } catch { _ => true }",
            "    assert_eq(failed, rejected[cut] == 1)",
            "  }", "}",
        ])

        def scalar(expr, value):
            if isinstance(value, bool):
                return f"  assert_eq({expr}, {str(value).lower()})"
            if isinstance(value, str):
                return f"  assert_eq({expr}, {json.dumps(value, ensure_ascii=False)})"
            return f"  assert_eq({expr}, {int(value)}L)"

        for label, raw in ([("upstream", data), ("unknown codes", b"\xFF\xFE\xFD")]
                           if name == "enum_if" else [("upstream", data)]):
            frame = parse(raw)
            checks = []
            if name == "enum_if":
                for index in range(1, 4):
                    base = f"frame.op{index}"
                    obj = getattr(frame, f"op{index}")
                    checks.append(scalar(f"{base}.opcode.to_i()", obj.opcode))
                    if label == "unknown codes":
                        checks.append(f"  assert_true({base}.opcode is UnknownCode({obj.opcode}L))")
                    for member, fields in (("arg_str", ("str",)), ("arg_tuple", ("num1", "num2"))):
                        value = getattr(obj, member, None)
                        if value is None:
                            checks.append(f"  assert_true({base}.{member} is None)")
                        else:
                            var = f"value_{member}_{index}"
                            checks.append(f'  guard {base}.{member} is Some({var}) else {{ fail("missing {member}") }}')
                            for field in fields:
                                suffix = "" if field == "str" else ".to_int64()"
                                checks.append(scalar(f"{var}.{field}{suffix}", getattr(value, field)))
            elif name.startswith("enum_"):
                for field in ("pet_1", "pet_2"):
                    checks.append(scalar(f"frame.{field}.to_i()", getattr(frame, field)))
                if name == "enum_of_value_inst":
                    for field in ("pet_3", "pet_4"):
                        checks.append(scalar(f"frame.{field}().to_i()", getattr(frame, field)))
                else:
                    for field in ("pet_1_i", "pet_1_i_to_s", "pet_1_mod", "one_lt_two", "pet_1_eq_int", "pet_2_eq_int"):
                        checks.append(scalar(f"frame.{field}()", getattr(frame, field)))
            elif name == "params_def":
                for field in ("len", "has_trailer", "buf"):
                    checks.append(scalar(f"frame.{field}", getattr(frame, field)))
                checks.append(f"  assert_eq(frame.trailer, Some({frame.trailer}U))")
            else:
                for field in ("buf1", "buf2"):
                    if hasattr(frame, field):
                        item = getattr(frame, field)
                        for member in ("len", "body", "has_trailer"):
                            if hasattr(item, member):
                                checks.append(scalar(f"frame.{field}.{member}", getattr(item, member)))
                        if hasattr(item, "trailer"):
                            checks.append(f"  assert_eq(frame.{field}.trailer, Some({item.trailer}U))")
            yield "\n".join([
                "///|", f'test "Kaitai reference typed schema {name} {label}" {{',
                f"  let frame = @{name}.parse_{name}({bytes_literal(raw)}{args})",
                *checks, "}",
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
    extra_prefix_rejections = []
    stream_comparisons = [*stream_tests(references), *edge_tests(references), *io_tests(references),
                          *navigation_tests(references, extra_prefix_rejections),
                          *type_tests(references, extra_prefix_rejections)]
    stream_output = ("// Expected values and prefix outcomes from official Kaitai Struct 0.11.\n"
                     "// Inputs, binary samples and Python specifications are pinned in fixtures/kaitai/manifest.json.\n"
                     "// Refresh: python scripts/kaitai-reference.py examples/consumer --refresh-stream-golden\n\n"
                     + "\n\n".join(stream_comparisons) + "\n")
    golden = ROOT / "examples/consumer/stream_reference_wbtest.mbt"
    if "--refresh-stream-golden" in sys.argv:
        golden.write_text(stream_output, encoding="utf-8")
    elif golden.read_text(encoding="utf-8") != stream_output:
        raise ValueError("Checked-in reference assertions differ from the checked-in official oracle output")
    (consumer / "stream_reference_wbtest.mbt").write_text(stream_output, encoding="utf-8")
    (consumer / "kaitai_reference_wbtest.mbt").write_text("\n\n".join(tests) + "\n", encoding="utf-8")
    manifest = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))
    (consumer / "oracle-cases.json").write_text(json.dumps({
        "compiler_version": VERSION,
        "upstream_schemas": [entry["schema"] + ".ksy" for entry in manifest["fixtures"]],
        "upstream_specs": sum("spec" in entry for entry in manifest["fixtures"]),
        "upstream_proper_prefixes": sum(len((ROOT / "fixtures" / entry["sample"]).read_bytes()) for entry in manifest["fixtures"] if "sample" in entry),
        "prefixes_rejected": stream_output.count('fail("accepted ') + sum(extra_prefix_rejections),
        "comparison_tests": len(tests) + len(stream_comparisons),
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Kaitai reference {VERSION}: verified {len(tests) + len(stream_comparisons)} comparisons "
          f"(4 UDP/STL + {len(semantic_tests)} conditional/instance + {len(stream_comparisons)} stream, navigation and type checks)", flush=True)


if __name__ == "__main__":
    main()
