"""Inventory every upstream KSY without treating schema acceptance as runtime conformance."""

import collections
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import sys
import time
from urllib.request import urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REVISION = "4108136c807f8df88df843de6571f1a7bf29c74e"
ARCHIVE_SHA256 = "3a78e2ffb3938c18b5c1d2f06f3bc8567bc72e054a8e68f0ddacbfa1406937fe"
EXPECTED_SCHEMAS = 339


def corpus_archive():
    cache = ROOT / "_build/kaitai-reference"
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / "upstream-tests-4108136.zip"
    if not archive.exists():
        url = f"https://codeload.github.com/kaitai-io/kaitai_struct_tests/zip/{REVISION}"
        for attempt in range(3):
            try:
                with urlopen(url, timeout=60) as response:
                    binary = response.read()
                break
            except OSError:
                if attempt == 2:
                    raise
                time.sleep(2)
        if hashlib.sha256(binary).hexdigest() != ARCHIVE_SHA256:
            raise ValueError("Downloaded upstream tests failed checksum verification")
        archive.write_bytes(binary)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != ARCHIVE_SHA256:
        raise ValueError("Cached upstream tests failed checksum verification")

    return archive


def extract_formats(archive, directory):
    prefix = f"kaitai_struct_tests-{REVISION}/formats/"
    with zipfile.ZipFile(archive) as source:
        names = sorted(name for name in source.namelist() if name.startswith(prefix) and name.endswith(".ksy"))
        if len(names) != EXPECTED_SCHEMAS:
            raise ValueError(f"Expected {EXPECTED_SCHEMAS} upstream schemas, got {len(names)}")
        for name in names:
            path = directory / name[len(prefix):]
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(source.read(name))
    return [directory / name[len(prefix):] for name in names]


def parser_package(source):
    if "@ksy_zlib.decompress(" in source:
        return (
            'import { "moonbitlang/core/compress/zlib" @ksy_zlib }\n'
            'options("allow-experimental-packages": ["moonbitlang/core/compress/zlib"])\n'
        )
    return ""


def main():
    archive = corpus_archive()
    subprocess.run(["moon", "build", "--frozen", "--release", "--target", "js", "cmd/ksymoon"], cwd=ROOT, check=True)
    cli = ROOT / "_build/js/release/build/cmd/ksymoon/ksymoon.js"
    if not cli.exists():
        raise FileNotFoundError(f"Expected release CLI: {cli}")
    scratch = Path(tempfile.mkdtemp(prefix="corpus-", dir=ROOT / "_build"))
    generated_module = scratch / "generated"
    generated_module.mkdir()
    (generated_module / "moon.mod").write_text(
        'name = "verification/ksymoon-corpus"\nversion = "0.1.0"\n', encoding="utf-8",
    )
    rows = []
    formats = scratch / "formats"
    for index, path in enumerate(extract_formats(archive, formats)):
        relative = path.relative_to(formats).as_posix()
        output = scratch / f"{index:03}.mbt"
        result = subprocess.run(
            ["node", str(cli), "generate", str(path), "--root", str(formats),
             "-I", str(formats / "ks_path"), "--out", str(output)],
            cwd=ROOT, text=True, encoding="utf-8", capture_output=True, timeout=10,
        )
        status = "generated" if result.returncode == 0 else "rejected"
        if result.returncode not in (0, 1) or (result.returncode and not result.stderr.startswith("ksymoon: ")):
            raise RuntimeError(f"Unexpected compiler failure for {relative}: {result.stderr}")
        rows.append({
            "schema": relative,
            "status": status,
            "diagnostic": result.stderr.strip().replace(str(path), relative),
        })
        if status == "generated":
            package = generated_module / f"case_{index:03}"
            package.mkdir()
            text = output.read_text(encoding="utf-8")
            (package / "moon.pkg").write_text(parser_package(text), encoding="utf-8")
            (package / "parser.mbt").write_bytes(output.read_bytes())

    # Accepted schemas must emit independently compilable source on every target.
    # Runtime equivalence remains a separate, smaller oracle-tested measurement.
    subprocess.run(
        ["moon", "check", "--target", "all", "--deny-warn"], cwd=generated_module, check=True,
    )
    subprocess.run(
        ["moon", "build", "--frozen", "--target", "all", "--deny-warn"], cwd=generated_module, check=True,
    )

    counts = dict(collections.Counter(row["status"] for row in rows))
    report = {
        "standard": "Kaitai Struct 0.11",
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "tracked_worktree_dirty": bool(subprocess.check_output(["git", "diff", "HEAD", "--name-only"], cwd=ROOT, text=True).strip()),
        "upstream_repository": "https://github.com/kaitai-io/kaitai_struct_tests",
        "upstream_revision": REVISION,
        "upstream_archive_sha256": ARCHIVE_SHA256,
        "total": len(rows),
        "counts": counts,
        "generated_sources_compile_and_build": True,
        "resolves_imports_from_upstream_tree": True,
        "runtime_oracle_schemas": [],
        "meaning": "generated means source emitted and independently checked/built on four targets; runtime conformance is measured separately",
        "schemas": rows,
    }
    if "--runtime-report" in sys.argv:
        runtime_path = ROOT / "_build/kaitai-runtime-report.json"
        runtime = json.loads(runtime_path.read_text(encoding="utf-8"))
        if (runtime["source_commit"] != report["source_commit"] or not runtime["official_reference_rerun"]
                or runtime["tracked_worktree_dirty"] != report["tracked_worktree_dirty"]):
            raise ValueError("Runtime evidence does not match the current source/reference run")
        report["runtime_oracle_schemas"] = runtime["upstream_schemas"]
        report["runtime_verification"] = runtime
    output = ROOT / "_build/compatibility-report.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Full corpus inventory: {len(rows)} schemas, {counts.get('generated', 0)} generated, "
          f"{counts.get('rejected', 0)} rejected; no silent exclusions", flush=True)
    print(f"Report: {output}", flush=True)


if __name__ == "__main__":
    main()
