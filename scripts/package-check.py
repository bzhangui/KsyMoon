"""Inspect the real local archive, with a canary for an untracked proposal."""

import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PROPOSAL = ROOT / "项目申报书.md"
CANARY = b"KsyMoon packaging exclusion canary\n"


def main():
    created = not PROPOSAL.exists()
    if created:
        PROPOSAL.write_bytes(CANARY)
    before = hashlib.sha256(PROPOSAL.read_bytes()).hexdigest()
    try:
        manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
        name = re.search(r'^name\s*=\s*"([^"\n]+)"', manifest, re.M)[1]
        version = re.search(r'^version\s*=\s*"([^"\n]+)"', manifest, re.M)[1]
        subprocess.run(
            ["moon", "package", "--frozen", "--list"], cwd=ROOT,
            text=True, encoding="utf-8", capture_output=True, check=True,
        )
        archive = ROOT / "_build/publish" / (name.replace("/", "-") + "-" + version + ".zip")
        with zipfile.ZipFile(archive) as package:
            files = sorted(name.replace("\\", "/") for name in package.namelist())
            fixtures = json.loads((ROOT / "fixtures/kaitai/manifest.json").read_text(encoding="utf-8"))["fixtures"]
            for fixture in fixtures:
                for key, digest in [("source", "sha256"), ("sample", "sample_sha256"), ("spec", "spec_sha256")]:
                    if key in fixture:
                        path = "fixtures/" + fixture[key]
                        assert path in files, f"Missing upstream input: {path}"
                        assert hashlib.sha256(package.read(path)).hexdigest() == fixture[digest], f"Changed upstream input: {path}"
        forbidden = {"项目申报书.md", "examples/consumer/kaitai_reference_wbtest.mbt", "examples/consumer/oracle-cases.json"}
        assert not forbidden.intersection(files), "Local submission or oracle sidecar entered package"
        assert all(not name.startswith(("_build/", ".mooncakes/", ".git/", "target/")) for name in files)
        required = {path.name for path in ROOT.glob("*.mbt")}
        required.update({"moon.mod", "moon.pkg", "LICENSE", "README.md", "cmd/ksymoon/main.mbt", "cmd/ksymoon/moon.pkg", "fixtures/kaitai/LICENSE"})
        required.update({
            "scripts/wav-reference.py", "scripts/kaitai-reference.py", "scripts/module-process-reference.py",
            "fixtures/udp_datagram.ksy", "fixtures/stl.ksy", "fixtures/stm32_sample_frame.ksy",
            "fixtures/vp8_duck_ivf.ksy",
        })
        assert required.issubset(files), f"Missing source, fixture or license: {required.difference(files)}"
        assert all(not path.endswith(("/wav.ksy", "/riff.ksy")) for path in files), "WAV/RIFF descriptions should be fetched on demand"
        assert before == hashlib.sha256(PROPOSAL.read_bytes()).hexdigest(), "Proposal was modified"
        report = {
            "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            "module": name, "version": version,
            "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "file_count": len(files), "files": files,
            "proposal_canary_used": created, "proposal_excluded": True,
            "local_sidecars_excluded": True, "required_source_and_licenses_present": True,
            "upstream_inputs_hash_verified": True, "published": False,
        }
        (ROOT / "_build/package-content-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Package check: {len(files)} files; local proposal/sidecars excluded; source and licenses present; no publication")
    finally:
        if created and PROPOSAL.exists() and PROPOSAL.read_bytes() == CANARY:
            PROPOSAL.unlink()


if __name__ == "__main__":
    main()
