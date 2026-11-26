"""Compare original MIDI/VLQ and JPEG/Exif parsers with Kaitai 0.11 on four targets."""

import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import sys
import tempfile

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
parser_package = runpy.run_path(str(ROOT / "scripts/compatibility-report.py"))["parser_package"]
literal = REFERENCE["bytes_literal"]
SCHEMAS = {
    "media/standard_midi_file.ksy": "8207f4c45d765fd02647fe97615a4550e3016ccfc7ff3b7a32464eb2c17bcf3c",
    "common/vlq_base128_be.ksy": "c830fe9890fd98be87480c55c6e06793cb020331cea769651d5f0fffe6193a57",
    "image/jpeg.ksy": "ff2fb430afa1b717d712b64d97179491145c017050fd8ed88a37bb6785b5cf2a",
    "image/exif.ksy": "b390f61bea731072bf1bd5232f6b1b3ac83f3f698486cdb583d6925cd03c6770",
}
FORMAT_PATHS = {
    "midi": ("media/standard_midi_file.ksy", "common/vlq_base128_be.ksy"),
    "jpeg": ("image/jpeg.ksy", "image/exif.ksy"),
}


def variants(source, prefix):
    return {kind: case for case, kind in re.findall(rf"(Case\d+)\({prefix}_(\w+)\)", source)}


def rejected(reference, data, error):
    try:
        reference.from_bytes(data)
    except error:
        return
    raise AssertionError("Kaitai accepted the malformed fixture")


def prefix_test(label, name, reference, data):
    accepted = []
    for length in range(len(data) + 1):
        try:
            reference.from_bytes(data[:length])
        except (EOFError, kaitaistruct.KaitaiStructError):
            continue
        accepted.append(length)
    assert len(data) in accepted and len(accepted) < len(data) + 1, label
    test = f'''///|
test "{label} prefixes match Kaitai 0.11" {{
  let packet = {literal(data)}
  let accepted : Array[Int] = {accepted}
  for length in 0..<(packet.length() + 1) {{
    let ok = try {{ ignore(parse_{name}(packet[:length].to_owned())); true }} catch {{ _ => false }}
    assert_eq(ok, accepted.contains(length))
  }}
}}
'''
    return test, {
        "sha256": hashlib.sha256(data).hexdigest(), "inputs": len(data) + 1,
        "accepted": len(accepted), "rejected": len(data) + 1 - len(accepted),
    }


def jpeg_segment(marker, data):
    return struct.pack(">BBH", 0xff, marker, len(data) + 2) + data


def jpeg_fixture(little, external_offset=38):
    order = "<" if little else ">"
    exif = (b"II" if little else b"MM") + struct.pack(order + "HIH", 42, 8, 2)
    exif += struct.pack(order + "HHII", 0x10f, 2, 9, external_offset)
    exif += struct.pack(order + "HHIHH", 0x112, 3, 1, 6, 0)
    exif += struct.pack(order + "I", 0) + b"MoonBit!\0"
    jfif = b"JFIF\0" + struct.pack(">BBBHHBB", 1, 2, 1, 72, 144, 1, 1) + b"\x12\x34\x56"
    # One grayscale block with DC category zero and AC end of block.
    huffman = bytes([1] + [0] * 16)
    return b"".join((
        b"\xff\xd8", jpeg_segment(0xe0, jfif), jpeg_segment(0xe1, b"Exif\0\0" + exif),
        jpeg_segment(0xdb, b"\0" + bytes([1] * 64)),
        jpeg_segment(0xc0, struct.pack(">BHHBBBB", 8, 1, 1, 1, 1, 0x11, 0)),
        jpeg_segment(0xc4, b"\0" + huffman + b"\x10" + huffman),
        jpeg_segment(0xda, b"\x01\x01\x00\x00\x3f\x00"), b"\x3f\xff\xd9",
    ))


def jpeg_fields(reference, data, label, case):
    parsed = reference.from_bytes(data)
    _, app0, app1, dqt, sof, _, scan = parsed.segments
    jfif, image = app0.data, sof.data
    exif = app1.data.body.data
    ifd = exif.body.ifd0
    make, orientation = ifd.fields
    assert orientation.data.values == [6] and make.data.value == b"MoonBit!"
    marker_codes = [item.marker.value for item in parsed.segments]
    return f'''///|
test "JPEG {label} markers and Exif match Kaitai 0.11" {{
  let jpeg = parse_jpeg({literal(data)})
  assert_eq(jpeg.segments.map(fn(segment) {{ segment.marker.to_i() }}), [{", ".join(f"{n}L" for n in marker_codes)}])
  assert_eq(jpeg.segments[0].length, None)
  guard jpeg.segments[1].data is Some({case["segment_app0"]}(jfif)) else {{ fail("expected JFIF") }}
  assert_eq(jfif.magic, {json.dumps(jfif.magic)})
  assert_eq(jfif.version_major, {jfif.version_major}U)
  assert_eq(jfif.version_minor, {jfif.version_minor}U)
  assert_eq(jfif.density_units.to_i(), {jfif.density_units.value}L)
  assert_eq(jfif.density_x, {jfif.density_x}U)
  assert_eq(jfif.density_y, {jfif.density_y}U)
  assert_eq(jfif.thumbnail.to_owned(), {literal(jfif.thumbnail)})
  assert_eq(jpeg.segments[2].length, Some({app1.length}U))
  guard jpeg.segments[2].data is Some({case["segment_app1"]}(app1)) else {{ fail("expected APP1") }}
  guard app1.body is {case["exif_in_jpeg"]}(wrapper) else {{ fail("expected Exif TIFF") }}
  assert_eq(wrapper.data.endianness, {exif.endianness}U)
  assert_eq(wrapper.data.body.ofs_ifd0, {exif.body.ofs_ifd0}U)
  let ifd = wrapper.data.body.ifd0()
  assert_eq(ifd.num_fields, {ifd.num_fields}U)
  assert_eq(ifd.ofs_next_ifd, {ifd.ofs_next_ifd}U)
  assert_eq(ifd.fields[1].tag_raw, {orientation.tag_raw}U)
  assert_true(ifd.fields[1].has_immediate_data())
  guard ifd.fields[1].data() is {case["exif_exif_body_shorts"]}(orientation) else {{ fail("expected orientation") }}
  assert_eq(orientation.values, [{orientation.data.values[0]}U])
  assert_eq(ifd.fields[0].ofs_data, Some({make.ofs_data}U))
  assert_false(ifd.fields[0].has_immediate_data())
  guard ifd.fields[0].data() is {case["exif_exif_body_ascii_string"]}(make) else {{ fail("expected camera make") }}
  assert_eq(make.value.to_owned(), {literal(make.data.value)})
  guard jpeg.segments[3].data is Some(Raw(quantization)) else {{ fail("expected raw DQT") }}
  assert_eq(quantization.to_owned(), {literal(dqt.data)})
  guard jpeg.segments[4].data is Some({case["segment_sof0"]}(frame)) else {{ fail("expected SOF0") }}
  assert_eq(frame.image_width, {image.image_width}U)
  assert_eq(frame.image_height, {image.image_height}U)
  assert_eq(frame.bits_per_sample, {image.bits_per_sample}U)
  assert_eq(frame.components[0].sampling_x(), {image.components[0].sampling_x}L)
  assert_eq(frame.components[0].sampling_y(), {image.components[0].sampling_y}L)
  assert_eq(jpeg.segments[6].length, Some({scan.length}U))
  guard jpeg.segments[6].data is Some({case["segment_sos"]}(scan)) else {{ fail("expected SOS") }}
  assert_eq(scan.end_spectral, {scan.data.end_spectral}U)
  guard jpeg.segments[6].image_data is Some(data) else {{ fail("expected scan payload") }}
  assert_eq(data.to_owned(), {literal(scan.image_data)})
}}
'''


def jpeg_tests(reference, source):
    case = variants(source, "Jpeg")
    tests, fixtures = [], {}
    for little, label in ((True, "little-endian"), (False, "big-endian")):
        data = jpeg_fixture(little)
        tests.append(jpeg_fields(reference, data, label, case))
        test, fixtures[label] = prefix_test(f"JPEG {label}", "jpeg", reference, data)
        tests.append(test)
    bad_magic = b"\x00\xd8"
    bad_length = b"\xff\xd8\xff\xe0\x00\x01"
    rejected(reference, bad_magic, kaitaistruct.ValidationNotEqualError)
    rejected(reference, bad_length, kaitaistruct.InvalidArgumentError)
    bad_offset = jpeg_fixture(True, external_offset=100)
    make = reference.from_bytes(bad_offset).segments[2].data.body.data.body.ifd0.fields[0]
    try:
        _ = make.data
    except EOFError:
        pass
    else:
        raise AssertionError("Kaitai read Exif data outside APP1")
    tests.append(f'''///|
test "JPEG rejects invalid marker signature and length like Kaitai 0.11" {{
  try parse_jpeg({literal(bad_magic)}) catch {{
    JpegContentsMismatch(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted invalid marker signature") }}
  try parse_jpeg({literal(bad_length)}) catch {{
    JpegInvalidLength(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted invalid segment length") }}
}}

///|
test "JPEG checks Exif external value against the bounded APP1 stream lazily" {{
  let jpeg = parse_jpeg({literal(bad_offset)})
  guard jpeg.segments[2].data is Some({case["segment_app1"]}(app1)) else {{ fail("expected APP1") }}
  guard app1.body is {case["exif_in_jpeg"]}(wrapper) else {{ fail("expected Exif TIFF") }}
  let make = wrapper.data.body.ifd0().fields[0]
  try make.data() catch {{
    JpegInvalidPosition(..) => ()
    JpegTruncated(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted an out-of-range Exif value") }}
}}
''')
    return tests, fixtures, 3


def midi_file(*tracks):
    header = b"MThd" + struct.pack(">IHHH", 6, int(len(tracks) > 1), len(tracks), 480)
    return header + b"".join(b"MTrk" + struct.pack(">I", len(track)) + track for track in tracks)


def midi_tests(reference, source):
    cases = variants(source, "StandardMidiFile")
    track_name = bytes(ord("A") + index % 26 for index in range(130))
    end = b"\x00\xff\x2f\x00"
    data = midi_file(
        b"\x00\xff\x03\x81\x02" + track_name + b"\x00\xff\x51\x03\x07\xa1\x20" + end,
        b"\x00\xc2\x2a\x81\x01\x92\x3c\x64\x00\xf0\x03\x7d\x01\xf7\x81\x80\x00\x82\x3c\x40" + end,
    )
    expected = reference.from_bytes(data)
    conductor, notes = [track.events.event for track in expected.tracks]
    name, tempo, end_event = [event.meta_event_body for event in conductor]
    program, on, sysex, off, _ = notes
    assert name.len.value == 130 and on.v_time.value == 129 and off.v_time.value == 16384
    tests = [f'''///|
test "MIDI multitrack headers, VLQ lengths, channels and payloads match Kaitai 0.11" {{
  let midi = parse_standard_midi_file({literal(data)})
  assert_eq(midi.hdr.format, {expected.hdr.format}U)
  assert_eq(midi.hdr.num_tracks, {expected.hdr.num_tracks}U)
  assert_eq(midi.hdr.division, {expected.hdr.division})
  assert_eq(midi.tracks.map(fn(track) {{ track.len_events }}), {[track.len_events for track in expected.tracks]})
  let conductor = midi.tracks[0].events.event
  assert_eq(conductor.length(), {len(conductor)})
  guard conductor[0].meta_event_body is Some(name) else {{ fail("expected a track name") }}
  assert_eq(name.meta_type.to_i(), {name.meta_type.value}L)
  assert_eq(name.len.value(), {name.len.value}UL)
  assert_eq(name.body.to_owned(), {literal(name.body)})
  guard conductor[1].meta_event_body is Some(tempo) else {{ fail("expected a tempo event") }}
  assert_eq(tempo.meta_type.to_i(), {tempo.meta_type.value}L)
  assert_eq(tempo.body.to_owned(), {literal(tempo.body)})
  guard conductor[2].meta_event_body is Some(end) else {{ fail("expected end of track") }}
  assert_eq(end.meta_type.to_i(), {end_event.meta_type.value}L)
  assert_eq(end.len.value(), {end_event.len.value}UL)
  let notes = midi.tracks[1].events.event
  assert_eq(notes.length(), {len(notes)})
  guard notes[0].event_body is {cases["program_change_event"]}(program) else {{ fail("expected a program change") }}
  assert_eq(program.program, {program.event_body.program}U)
  assert_eq(notes[1].v_time.value(), {on.v_time.value}UL)
  assert_eq(notes[1].event_type(), {on.event_type}L)
  assert_eq(notes[1].channel(), Some({on.channel}L))
  guard notes[1].event_body is {cases["note_on_event"]}(on) else {{ fail("expected a note-on event") }}
  assert_eq(on.note, {on.event_body.note}U)
  assert_eq(on.velocity, {on.event_body.velocity}U)
  assert_eq(notes[2].channel(), None)
  guard notes[2].sysex_body is Some(sysex) else {{ fail("expected a SysEx event") }}
  assert_eq(sysex.len.value(), {sysex.sysex_body.len.value}UL)
  assert_eq(sysex.data.to_owned(), {literal(sysex.sysex_body.data)})
  assert_eq(notes[3].v_time.value(), {off.v_time.value}UL)
  guard notes[3].event_body is {cases["note_off_event"]}(off) else {{ fail("expected a note-off event") }}
  assert_eq(off.note, {off.event_body.note}U)
  assert_eq(off.velocity, {off.event_body.velocity}U)
}}
''']
    test, stats = prefix_test("MIDI multitrack", "standard_midi_file", reference, data)
    tests.append(test)

    bad_magic = b"X" + data[1:]
    oversized = midi_file(b"\x00\xff\x03" + b"\xff" * 7 + b"\x7f\x42", end)
    rejected(reference, bad_magic, kaitaistruct.ValidationNotEqualError)
    rejected(reference, oversized, EOFError)
    tests.append(f'''///|
test "MIDI rejects a bad header and a VLQ larger than the bounded track" {{
  try parse_standard_midi_file({literal(bad_magic)}) catch {{
    StandardMidiFileContentsMismatch(..) => ()
    error => raise error
  }} noraise {{ _ => fail("accepted invalid header") }}
  try parse_standard_midi_file({literal(oversized)}) catch {{
    StandardMidiFileTruncated(..) => ()
    error => raise error
  }} noraise {{ _ => fail("oversized length crossed the track boundary") }}
}}
''')
    return tests, {"multitrack": stats}, 2


def vlq_tests(reference, _source):
    vectors = [b"\x00", b"\x7f"]
    vectors.extend(b"\x81" + b"\x80" * (width - 2) + b"\0" for width in range(2, 8))
    vectors.append(b"\xff" * 7 + b"\x7f")
    fields = []
    for raw in vectors:
        result = reference.from_bytes(raw)
        fields.extend([
            f"  let code = parse_vlq_base128_be({literal(raw)})",
            f"  assert_eq(code.groups.length(), {len(result.groups)})",
            f"  assert_eq(code.value(), {result.value}UL)",
        ])
    values = '\n'.join(['///|', 'test "VLQ one through eight bytes match Kaitai 0.11" {', *fields, '}', ''])
    prefix, stats = prefix_test("VLQ eight groups", "vlq_base128_be", reference, vectors[-1])
    return [values, prefix], {"eight_groups": stats}, 0


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--format", choices=FORMAT_PATHS, help="run one format suite")
    arguments = cli.parse_args()
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise ValueError("Expected Kaitai Python runtime 0.11")

    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="midi-jpeg-", dir=build))
    selected = (arguments.format,) if arguments.format else tuple(FORMAT_PATHS)
    schemas = {name: SCHEMAS[name] for suite in selected for name in FORMAT_PATHS[suite]}
    paths = {name: WAV["verified_format"](name, digest, build / "kaitai-formats", work)
             for name, digest in schemas.items()}
    refs = work / "references"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--import-path",
                    str(work), "--outdir", str(refs), *(str(path) for path in paths.values())], check=True)
    sys.path.insert(0, str(refs))

    jobs = []
    if "midi" in selected:
        from standard_midi_file import StandardMidiFile
        from vlq_base128_be import VlqBase128Be
        jobs.extend([
            ("media/standard_midi_file.ksy", StandardMidiFile, midi_tests),
            ("common/vlq_base128_be.ksy", VlqBase128Be, vlq_tests),
        ])
    if "jpeg" in selected:
        from jpeg import Jpeg
        jobs.append(("image/jpeg.ksy", Jpeg, jpeg_tests))

    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-midi-jpeg"\nversion = "0.1.0"\n', encoding="utf-8")
    generator, command, _ = WAV["generator_command"](work, False)
    results = {}
    for key, reference, test_builder in jobs:
        package = consumer / paths[key].stem
        package.mkdir()
        output = package / "parser.mbt"
        subprocess.run([*command, "generate", str(paths[key]), "--root", str(work), "--out", str(output)],
                       cwd=generator, check=True)
        source = output.read_text(encoding="utf-8")
        (package / "moon.pkg").write_text(parser_package(source), encoding="utf-8")
        tests, fixtures, invalid_inputs = test_builder(reference, source)
        test = "\n".join(tests)
        (package / "reference_wbtest.mbt").write_text(test, encoding="utf-8")
        results[package.name] = {
            "fixtures": fixtures, "other_invalid_inputs": invalid_inputs,
            "tests_per_target": test.count('\ntest "'),
            "fixture_test_sha256": hashlib.sha256(test.encode("utf-8")).hexdigest(),
            "parser_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        }
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler": REFERENCE["VERSION"], "upstream_revision": WAV["REVISION"],
        "schemas": schemas, "targets": WAV["TARGETS"], "formats": results,
    }
    output = build / f"{arguments.format or 'midi-jpeg'}-reference-report.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("Original MIDI/VLQ and JPEG/Exif checks against Kaitai 0.11: " + json.dumps(results))


if __name__ == "__main__":
    main()
