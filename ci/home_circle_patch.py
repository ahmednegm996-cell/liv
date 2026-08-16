#!/usr/bin/env python3
"""Single source of truth for Home progress circle size on the ZIP HomeScreen.

Runs AFTER ZIP extract + overlays + other patches, and AFTER any ZIP re-lock.
Touches ONLY the daily progress ring:
  SizedBox(width/height) + strokeWidth + percent fontSize
for CircularProgressIndicator(value: progress).

Does NOT:
- Touch repo-only home layouts
- Use OverflowBox
- Patch every CircularProgressIndicator
- Modify audio, AI, MainActivity, or other UI
"""
from __future__ import annotations

from pathlib import Path
import re
import sys

HOME = Path("lib/screens/home_screen.dart")

# Target proportions (from original 70/6/14 scaled ~1.29x → readable, not huge)
TARGET_SIZE = 90
TARGET_STROKE = 7
TARGET_FONT = 16


def patch(text: str) -> tuple[str, bool]:
    """Replace the progress-ring SizedBox block only. Idempotent."""

    # Match the unique progress ring: SizedBox → Stack → CircularProgressIndicator(value: progress)
    pattern = re.compile(
        r"(SizedBox\(\s*\n\s*width:\s*)(\d+)(\s*,\s*\n\s*height:\s*)(\d+)"
        r"(\s*,\s*\n\s*child:\s*Stack\(\s*\n\s*alignment:\s*Alignment\.center\s*,\s*\n\s*children:\s*\[\s*\n\s*"
        r"CircularProgressIndicator\(\s*\n\s*value:\s*progress\s*,\s*\n\s*strokeWidth:\s*)([\d.]+)"
        r"([\s\S]{0,280}?fontSize:\s*)(\d+)",
        re.MULTILINE,
    )

    m = pattern.search(text)
    if not m:
        # Fallback: slightly looser whitespace
        pattern2 = re.compile(
            r"(SizedBox\(\s*width:\s*)(\d+)(\s*,\s*height:\s*)(\d+)"
            r"(\s*,\s*child:\s*Stack\([\s\S]{0,120}?"
            r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*)([\d.]+)"
            r"([\s\S]{0,200}?fontSize:\s*)(\d+)",
            re.MULTILINE,
        )
        m = pattern2.search(text)
        if not m:
            raise SystemExit(
                "ERROR: home_circle_patch: progress circle block not found "
                "(expected SizedBox + CircularProgressIndicator value: progress)"
            )
        pattern = pattern2

    w, h, stroke, font = m.group(2), m.group(4), m.group(6), m.group(8)
    if (
        int(w) == TARGET_SIZE
        and int(h) == TARGET_SIZE
        and float(stroke) == float(TARGET_STROKE)
        and int(font) == TARGET_FONT
    ):
        print(
            f"home_circle_patch: already {TARGET_SIZE}x{TARGET_SIZE} "
            f"stroke={TARGET_STROKE} font={TARGET_FONT}"
        )
        return text, False

    def repl(mo: re.Match) -> str:
        return (
            f"{mo.group(1)}{TARGET_SIZE}{mo.group(3)}{TARGET_SIZE}"
            f"{mo.group(5)}{TARGET_STROKE}{mo.group(7)}{TARGET_FONT}"
        )

    new_text, n = pattern.subn(repl, text, count=1)
    if n != 1:
        raise SystemExit(f"ERROR: home_circle_patch expected 1 replacement, got {n}")

    print(
        f"home_circle_patch: {w}x{h} stroke={stroke} font={font} "
        f"→ {TARGET_SIZE}x{TARGET_SIZE} stroke={TARGET_STROKE} font={TARGET_FONT}"
    )
    return new_text, True


def main() -> None:
    if not HOME.exists():
        raise SystemExit(f"ERROR: {HOME} missing — run after ZIP extract")
    text = HOME.read_text(encoding="utf-8")
    if "OverflowBox" in text:
        raise SystemExit("ERROR: OverflowBox present in home_screen — refuse to patch")
    new_text, changed = patch(text)
    if changed:
        HOME.write_text(new_text, encoding="utf-8")
    # Final assert
    t = HOME.read_text(encoding="utf-8")
    m = re.search(
        r"SizedBox\(\s*width:\s*(\d+)\s*,\s*height:\s*(\d+)\s*,\s*child:\s*Stack\([\s\S]{0,250}?"
        r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*([\d.]+)",
        t,
    )
    if not m or m.group(1) != str(TARGET_SIZE) or m.group(2) != str(TARGET_SIZE):
        raise SystemExit(
            f"ERROR: final circle not {TARGET_SIZE}x{TARGET_SIZE}: "
            f"{m.groups() if m else None}"
        )
    if "OverflowBox" in t:
        raise SystemExit("ERROR: OverflowBox introduced")
    print("home_circle_patch done OK")


if __name__ == "__main__":
    main()
