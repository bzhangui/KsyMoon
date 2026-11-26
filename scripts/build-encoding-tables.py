"""Regenerate the data-only prefix of encoding_tables.mbt from CPython 3.14.5."""

import hashlib
from pathlib import Path
import sys


if sys.implementation.name != "cpython" or sys.version_info[:3] != (3, 14, 5):
    raise SystemExit("Regeneration requires CPython 3.14.5")

ROOT = Path(__file__).resolve().parents[1]
LEADS = (*range(0x81, 0xA0), *range(0xE0, 0xF0))
TRAILS = (*range(0x40, 0x7F), *range(0x80, 0xFD))
PLACEHOLDER = "\ufffd"
LICENSE_SHA256 = "b0e25a78cffb43f4d92de8b61ccfa1f1f98ecbc22330b54b5251e7b6ba010231"


def decode_pair(lead, trail):
    try:
        char = bytes((lead, trail)).decode("shift_jis")
    except UnicodeDecodeError:
        return PLACEHOLDER
    assert len(char) == 1 and char != PLACEHOLDER and char not in "\r\n"
    return char


def moonbit_table(name, rows):
    digest = hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()
    block = "\n".join(f"    #|{row}" for row in rows)
    return (
        f"///|\n// Mapping code points in UTF-8 have SHA-256 {digest}.\n"
        f"fn {name}() -> String {{\n  let rows =\n{block}\n"
        '  rows.replace_all(old="\\n", new="")\n}\n'
    )


def license_notice():
    raw = (ROOT / "LICENSE-CPYTHON").read_bytes().replace(b"\r\n", b"\n")
    if hashlib.sha256(raw).hexdigest() != LICENSE_SHA256:
        raise ValueError("LICENSE-CPYTHON differs from the CPython v3.14.5 license")
    notice = [
        "This parser includes Shift-JIS or IBM437 lookup data derived from",
        "CPython 3.14.5. KsyMoon reorganized the character mappings for indexed lookup.",
        "Source: https://github.com/python/cpython/tree/v3.14.5",
        "",
        *raw.decode("utf-8").splitlines(),
    ]
    lines = "\n".join(("    #|// " + line).rstrip() for line in notice)
    return f"///|\nfn cpython_codec_notice() -> String {{\n  let notice =\n{lines}\n  notice\n}}\n"


shift_jis = ["".join(decode_pair(lead, trail) for trail in TRAILS) for lead in LEADS]
ibm437 = [bytes(range(start, start + 32)).decode("cp437") for start in range(128, 256, 32)]
header = """// Code-point data derived from the CPython 3.14.5 codecs. See LICENSE-CPYTHON.
// Shift-JIS: https://github.com/python/cpython/blob/v3.14.5/Modules/cjkcodecs/_codecs_jp.c
//            https://github.com/python/cpython/blob/v3.14.5/Modules/cjkcodecs/mappings_jp.h
// IBM437: https://github.com/python/cpython/blob/v3.14.5/Lib/encodings/cp437.py
// Regenerate with CPython 3.14.5: python scripts/build-encoding-tables.py
// Each Shift-JIS row is a lead byte in 81..9F or E0..EF. Columns are trails
// in 40..7E or 80..FC. U+FFFD marks an unassigned slot.
"""
text = "\n".join([
    header,
    moonbit_table("shift_jis_mapping", shift_jis),
    moonbit_table("ibm437_mapping", ibm437),
    license_notice(),
])
(ROOT / "encoding_tables.mbt").write_bytes(text.encode("utf-8"))
