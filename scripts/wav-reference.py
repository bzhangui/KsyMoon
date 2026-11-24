"""Verify original WAV and RIFF against Kaitai 0.11, optionally with the four demo formats."""
import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile
import time
from urllib.request import urlopen

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REVISION = "30e7ad51e8c870d3a098cd618c0f4b2797efc538"
FORMATS = {
    "media/wav.ksy": "c425bf2bd43f624d1840b56c0e8791c1220e19d2aba13f14d6bcb79be6485dd8",
    "common/riff.ksy": "8e43fd273dad55ef3d654a47645477b80048b81b78648eedb8044ba7ff1cad72",
}
OVERRIDES = ["/common/riff", "common/riff.ksy"]
TARGETS = ("js", "wasm", "wasm-gc", "native")
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
literal = REFERENCE["bytes_literal"]
DEMO_FORMATS = {
    "udp": "udp_datagram.ksy",
    "stl": "stl.ksy",
    "stm32": "stm32_sample_frame.ksy",
    "ivf": "vp8_duck_ivf.ksy",
}
DEMO_SOURCES = (
    "main.mbt", "stl_checks.mbt", "stm32_checks.mbt", "main_wbtest.mbt",
    "prefix_wbtest.mbt", "ivf_wbtest.mbt",
)


def verified_format(path, digest, cache, work):
    source = cache / path
    if not source.exists():
        source.parent.mkdir(parents=True, exist_ok=True)
        url = f"https://raw.githubusercontent.com/kaitai-io/kaitai_struct_formats/{REVISION}/{path}"
        for attempt in range(3):
            try:
                with urlopen(url, timeout=45) as response:
                    data = response.read()
                break
            except OSError:
                if attempt == 2:
                    raise
                time.sleep(2)
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f"{path}: unexpected SHA-256 for upstream download")
        source.write_bytes(data)
    data = source.read_bytes()
    if hashlib.sha256(data).hexdigest() != digest:
        raise ValueError(f"{path}: unexpected SHA-256 in cache")
    output = work / path
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(data)
    return output


def chunk(tag, payload):
    return tag + struct.pack("<I", len(payload)) + payload + (b"\0" if len(payload) % 2 else b"")


def wave_form(*chunks):
    return chunk(b"RIFF", b"WAVE" + b"".join(chunks))


def wave_vectors():
    payload = b"\0\0\xff\x7f\0\x80"
    pcm = struct.pack("<HHIIHH", 1, 1, 8000, 16000, 2, 16)
    extensible = (struct.pack("<HHIIHHHHI", 0xFFFE, 2, 48000, 192000, 4, 16, 22, 16, 3)
                  + bytes.fromhex("0100000000001000800000aa00389b71"))
    return {
        "pcm": wave_form(chunk(b"fmt ", pcm), chunk(b"data", payload)),
        "pcm with unknown odd-length chunk": wave_form(chunk(b"JUNK", b"!"), chunk(b"fmt ", pcm), chunk(b"data", payload)),
        "extensible": wave_form(chunk(b"fmt ", extensible), chunk(b"data", payload + b"\0\0")),
    }


def wave_checks(label, data, reference):
    frame = reference.from_bytes(data)
    entries = frame.subchunks
    fmt_index = next(i for i, entry in enumerate(entries) if getattr(entry.chunk_id, "name", None) == "fmt")
    data_index = next(i for i, entry in enumerate(entries) if getattr(entry.chunk_id, "name", None) == "data")
    fmt = entries[fmt_index].chunk_data
    payload = entries[data_index].chunk_data.data
    code = [
        "///|", f'test "WAV {label} matches Kaitai 0.11" {{',
        f"  let wav = @wav.parse_wav({literal(data)})",
        '  guard wav.subchunks() is Some(chunks) else { fail("missing WAVE chunks") }',
        f"  assert_eq(chunks.length(), {len(entries)})",
        f'  guard chunks[{fmt_index}].chunk_data() is Case1(fmt) else {{ fail("wrong fmt branch") }}',
        f'  guard chunks[{data_index}].chunk_data() is Case6(samples) else {{ fail("wrong data branch") }}',
        f"  assert_eq(fmt.w_format_tag.to_i(), {int(fmt.w_format_tag)}L)",
        f"  assert_eq(fmt.n_samples_per_sec, {fmt.n_samples_per_sec}U)",
        f"  assert_eq(fmt.n_channels, {fmt.n_channels}U)",
        f"  assert_eq(fmt.w_bits_per_sample, {fmt.w_bits_per_sample}U)",
        f"  assert_eq(samples.data.to_owned(), {literal(payload)})",
    ]
    if label == "pcm with unknown odd-length chunk":
        code += ["  assert_true(chunks[0].chunk_data() is Unknown)",
                 f"  assert_eq(chunks[0].chunk.pad_byte.to_owned(), {literal(entries[0].chunk.pad_byte)})"]
    if label == "extensible":
        channel_mask = fmt.channel_mask_and_subformat.dw_channel_mask
        code += ['  guard fmt.channel_mask_and_subformat is Some(layout) else { fail("missing channel mask") }']
        for field, value in vars(channel_mask).items():
            if not field.startswith("_"):
                expected = str(value).lower() if isinstance(value, bool) else f"{value}U"
                code += [f"  assert_eq(layout.dw_channel_mask.{field}, {expected})"]
        code += [f"  assert_eq(layout.subformat.data1, {fmt.channel_mask_and_subformat.subformat.data1}U)"]
    return "\n".join([*code, "}"])


def riff_checks(data, reference):
    frame = reference.from_bytes(data)
    outer = frame.subchunks[0].chunk_data
    inner = outer.subchunks[0].chunk_data
    info, unknown = inner.subchunks
    return "\n".join([
        "///|", 'test "RIFF nested LIST, padded INFO and byte expressions match Kaitai 0.11" {',
        f"  let riff = @riff.parse_riff({literal(data)})",
        '  guard riff.subchunks() is Some(chunks) else { fail("missing RIFF children") }',
        '  guard chunks[0].chunk_data() is Case0(outer) else { fail("missing outer LIST") }',
        '  guard outer.subchunks()[0] is Default(nested) else { fail("missing nested LIST") }',
        '  guard nested.chunk_data() is Case0(inner) else { fail("missing INFO list") }',
        '  guard inner.subchunks()[0] is Case0(info) else { fail("missing INFO entry") }',
        '  guard inner.subchunks()[1] is Case0(unknown) else { fail("missing unregistered entry") }',
        f"  assert_eq(info.chunk_id_readable(), {json.dumps(info.chunk_id_readable)})",
        f"  assert_eq(info.is_unregistered_tag(), {str(info.is_unregistered_tag).lower()})",
        f"  assert_eq(unknown.chunk_id_readable(), {json.dumps(unknown.chunk_id_readable)})",
        f"  assert_eq(unknown.is_unregistered_tag(), {str(unknown.is_unregistered_tag).lower()})",
        '  guard info.chunk_data() is Case0(text) else { fail("missing INFO text") }',
        f"  assert_eq(text, {json.dumps(info.chunk_data)})",
        "  assert_true(unknown.chunk_data() is Unknown)",
        "}",
    ])


def truncated_prefix_checks(label, package, data, reference):
    expected = bytearray()
    for cut in range(len(data)):
        try:
            frame = reference.from_bytes(data[:cut])
            if frame.subchunks is not None:
                for entry in frame.subchunks:
                    _ = entry.chunk_data
        except (EOFError, UnicodeError, kaitaistruct.KaitaiStructError):
            expected.append(1)
        else:
            expected.append(0)
    return "\n".join([
        "///|", f'test "{package} {label} prefix outcomes match Kaitai 0.11" {{',
        f"  let data = {literal(data)}",
        f"  let rejected = {literal(expected)}",
        "  for cut in 0..<data.length() {",
        "    let failed = try {",
        f"      let parsed = @{package}.parse_{package}(data[:cut].to_owned())",
        "      if parsed.subchunks() is Some(chunks) { for chunk in chunks { ignore(chunk.chunk_data()) } }",
        "      false",
        "    } catch { _ => true }",
        "    assert_eq(failed, rejected[cut] == 1)", "  }", "}",
    ]), sum(expected)


def recursion_limit_check():
    nested = chunk(b"LIST", b"TEST")
    for _ in range(80):
        nested = chunk(b"LIST", b"TEST" + nested)
    data = wave_form(nested)
    return "\n".join([
        "///|", 'test "RIFF rejects nesting beyond the record depth budget" {',
        f"  let riff = @riff.parse_riff({literal(data)})",
        '  guard riff.subchunks() is Some(chunks) else { fail("missing RIFF children") }',
        "  let mut item = chunks[0]",
        "  try {",
        "    for _ in 0..<80 {",
        '      guard item.chunk_data() is Case0(list) else { fail("missing LIST") }',
        '      guard list.subchunks()[0] is Default(child) else { fail("missing child") }',
        "      item = child",
        "    }",
        "  } catch {",
        '    @riff.RiffContextError(message~, ..) => assert_eq(message, "record nesting exceeds 64")',
        "    error => raise error",
        '  } noraise { _ => fail("accepted nesting past its limit") }',
        "}",
    ])


def generator_command(work, registry):
    generator = ROOT
    command = "cmd/ksymoon"
    dependency = None
    if registry:
        manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
        version = re.search(r'^version = "([0-9]+\.[0-9]+\.[0-9]+)"$', manifest, re.M)
        if version is None:
            raise ValueError("--registry requires a stable version in moon.mod")
        dependency = f"bzhangui/ksymoon@{version[1]}"
        generator = work / "generator"
        generator.mkdir()
        (generator / "moon.mod").write_text(
            'name = "example/ksymoon-registry-generator"\nversion = "0.1.0"\n', encoding="utf-8",
        )
        for name in ("main.mbt", "moon.pkg"):
            shutil.copyfile(ROOT / "cmd/ksymoon" / name, generator / name)
        subprocess.run(["moon", "update"], cwd=generator, check=True)
        subprocess.run(["moon", "add", dependency], cwd=generator, check=True)
        subprocess.run(["moon", "tree"], cwd=generator, check=True)
        command = "."
    print(f"Generator: {dependency or 'repository source'}", flush=True)
    return generator, ["moon", "run", "--frozen", "--target", "js", "--deny-warn", command, "--"], dependency


def create_consumer(work, include_demos):
    consumer = work / "consumer"
    consumer.mkdir()
    module = "example/ksymoon-wav"
    (consumer / "moon.mod").write_text(f'name = "{module}"\nversion = "0.1.0"\n', encoding="utf-8")
    packages = f'import {{\n  "{module}/wav",\n  "{module}/riff",\n'
    if include_demos:
        packages += f'  "{module}/ivf",\n'
        for name in DEMO_SOURCES:
            shutil.copyfile(ROOT / "examples/consumer" / name, consumer / name)
    packages += '} for "wbtest"\n'
    if include_demos:
        packages += 'import {\n' + "".join(f'  "{module}/{name}",\n' for name in ("udp", "stl", "stm32"))
        packages += '}\n\npkgtype(kind: "executable")\n'
    (consumer / "moon.pkg").write_text(packages, encoding="utf-8")
    print(f"Fresh consumer: {consumer}", flush=True)
    return consumer


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all-scenarios", action="store_true", help="also regenerate and test UDP, STL, STM32, IVF")
    parser.add_argument("--registry", action="store_true", help="install the current release from Mooncakes and test all six formats")
    args = parser.parse_args()
    include_demos = args.all_scenarios or args.registry
    if importlib.metadata.version("kaitaistruct") != REFERENCE["VERSION"]:
        raise RuntimeError("Install kaitaistruct==0.11 to run this check")
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="wav-reference-", dir=build))
    inputs = {name: verified_format(name, sha, build / "kaitai-formats", work) for name, sha in FORMATS.items()}
    generator, cli, dependency = generator_command(work, args.registry)
    consumer = create_consumer(work, include_demos)
    refs = work / "python"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--import-path",
                    str(work), "--outdir", str(refs), *map(str, inputs.values())], check=True)
    sys.path.insert(0, str(refs))
    from riff import Riff
    from wav import Wav

    scenarios = {"wav": inputs["media/wav.ksy"], "riff": inputs["common/riff.ksy"]}
    if include_demos:
        scenarios.update({name: ROOT / "fixtures" / spec for name, spec in DEMO_FORMATS.items()})
    for name, source in scenarios.items():
        package = consumer / name
        package.mkdir()
        (package / "moon.pkg").write_text("", encoding="utf-8")
        extra = ["--import", OVERRIDES[0], str(inputs[OVERRIDES[1]])] if name == "wav" else []
        subprocess.run([*cli, "check", str(source), *extra], cwd=generator, check=True)
        subprocess.run([*cli, "generate", str(source), "--out", str(package / "parser.mbt"), *extra], cwd=generator, check=True)

    tests = []
    prefixes = rejected = 0
    for label, data in wave_vectors().items():
        tests.append(wave_checks(label, data, Wav))
        test, failed = truncated_prefix_checks(label, "wav", data, Wav)
        tests.append(test)
        prefixes += len(data)
        rejected += failed
    data = wave_form(chunk(b"LIST", b"TEST" + chunk(b"LIST", b"INFO" + chunk(b"INAM", b"Demo\0") + chunk(b"abcd", b"x"))))
    tests.append(riff_checks(data, Riff))
    test, failed = truncated_prefix_checks("nested list", "riff", data, Riff)
    tests.append(test)
    prefixes += len(data)
    rejected += failed
    (consumer / "reference_wbtest.mbt").write_text("\n\n".join([*tests, recursion_limit_check()]) + "\n", encoding="utf-8")
    for command in ("check", "build", "test"):
        subprocess.run(["moon", command, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    result = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "official_compiler_version": REFERENCE["VERSION"],
        "upstream_revision": REVISION, "upstream_hashes": FORMATS,
        "targets": TARGETS, "comparisons": len(tests), "resource_limit_tests": 1, "prefixes": prefixes,
        "rejected_prefixes": rejected, "check_build_test": True,
        "generator_dependency": dependency, "scenarios": list(scenarios),
        "schema_sha256": {name: hashlib.sha256(source.read_bytes()).hexdigest() for name, source in scenarios.items()},
        "parser_sha256": {
            name: hashlib.sha256((consumer / name / "parser.mbt").read_bytes()).hexdigest() for name in scenarios
        },
    }
    report = "registry-scenarios-report.json" if args.registry else "wav-reference-report.json"
    (build / report).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"WAV/RIFF: {len(tests)} official comparisons, {prefixes} prefix outcomes ({rejected} rejected), depth limit checked; four backends passed")


if __name__ == "__main__":
    main()
