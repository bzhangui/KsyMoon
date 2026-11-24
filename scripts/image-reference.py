"""Verify original image schemas against the Kaitai 0.11 Python target."""

import argparse
import base64
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile

import kaitaistruct

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT / "scripts/kaitai-reference.py"))
WAV = runpy.run_path(str(ROOT / "scripts/wav-reference.py"))
literal = REFERENCE["bytes_literal"]
GIF_SHA256 = "2da551fc465428b9d6595f25347ac18381551cccfa1e24d85572ca4f276c2a8f"


def gif_assertions(reference):
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", action="store_true", help="use the published version in moon.mod")
    args = parser.parse_args()
    build = ROOT / "_build"
    build.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="image-reference-", dir=build))
    schema = WAV["verified_format"]("image/gif.ksy", GIF_SHA256, build / "kaitai-formats", work)
    refs = work / "references"
    refs.mkdir()
    subprocess.run([*REFERENCE["compiler_command"](work), "--target", "python", "--outdir", str(refs), str(schema)], check=True)
    sys.path.insert(0, str(refs))
    from gif import Gif

    consumer = work / "consumer"
    consumer.mkdir()
    (consumer / "moon.mod").write_text('name = "verification/ksymoon-images"\nversion = "0.1.0"\n', encoding="utf-8")
    (consumer / "moon.pkg").write_text("", encoding="utf-8")
    generator, command, dependency = WAV["generator_command"](work, args.registry)
    subprocess.run([*command, "generate", str(schema), "--out", str(consumer / "gif.mbt")], cwd=generator, check=True)
    tests, inputs, accepted = gif_assertions(Gif)
    (consumer / "gif_wbtest.mbt").write_text(tests, encoding="utf-8")
    for action in ("check", "build", "test"):
        subprocess.run(["moon", action, "--frozen", "--target", "all", "--deny-warn"], cwd=consumer, check=True)
    report = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "upstream_revision": WAV["REVISION"], "schema_sha256": GIF_SHA256,
        "official_compiler": "0.11", "generator_dependency": dependency,
        "targets": WAV["TARGETS"], "inputs": inputs, "accepted": accepted, "rejected": inputs - accepted,
    }
    name = "registry-image-reference-report.json" if args.registry else "image-reference-report.json"
    (build / name).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"GIF matches Kaitai 0.11 on four targets: {accepted} accepted, {inputs - accepted} rejected")


if __name__ == "__main__":
    main()
