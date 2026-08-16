#!/usr/bin/env python3
"""Single source of truth for Home progress circle size on the ZIP HomeScreen.

Runs AFTER ZIP extract + overlays + other patches, and AFTER any ZIP re-lock.
Touches ONLY the daily progress ring (value: progress):
  SizedBox width/height, strokeWidth, percent fontSize.

Does NOT use OverflowBox, touch other UI, audio, AI, or MainActivity.
"""
from __future__ import annotations

from pathlib import Path
import re
import sys

HOME = Path("lib/screens/home_screen.dart")

TARGET_SIZE = 90
TARGET_STROKE = "7"
TARGET_FONT = "16"

# Exact block as shipped in liv_app_full.zip (and after idempotent re-runs).
OLD_BLOCK = """                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: accent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: accent),
                        ),
                      ],
                    ),
                  )"""

NEW_BLOCK = f"""                  SizedBox(
                    width: {TARGET_SIZE},
                    height: {TARGET_SIZE},
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: {TARGET_STROKE},
                          backgroundColor: accent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                        Text(
                          '${{(progress * 100).round()}}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: {TARGET_FONT},
                              color: accent),
                        ),
                      ],
                    ),
                  )"""

# Already-patched block (idempotent)
DONE_BLOCK = NEW_BLOCK


def main() -> None:
    if not HOME.exists():
        raise SystemExit(f"ERROR: {HOME} missing — run after ZIP extract")
    text = HOME.read_text(encoding="utf-8")
    if "OverflowBox" in text:
        raise SystemExit("ERROR: OverflowBox present — refuse to patch")

    if DONE_BLOCK in text and OLD_BLOCK not in text:
        print(
            f"home_circle_patch: already {TARGET_SIZE}x{TARGET_SIZE} "
            f"stroke={TARGET_STROKE} font={TARGET_FONT}"
        )
    elif OLD_BLOCK in text:
        text = text.replace(OLD_BLOCK, NEW_BLOCK, 1)
        HOME.write_text(text, encoding="utf-8")
        print(
            f"home_circle_patch: 70x70 stroke=6 font=14 "
            f"→ {TARGET_SIZE}x{TARGET_SIZE} stroke={TARGET_STROKE} font={TARGET_FONT}"
        )
    else:
        # Flexible fallback for minor whitespace drift
        pattern = re.compile(
            r"SizedBox\(\s*width:\s*(\d+)\s*,\s*height:\s*(\d+)\s*,\s*"
            r"child:\s*Stack\(\s*alignment:\s*Alignment\.center\s*,\s*"
            r"children:\s*\[\s*"
            r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*"
            r"strokeWidth:\s*([\d.]+)([\s\S]{0,350}?fontSize:\s*)(\d+)",
            re.MULTILINE,
        )
        m = pattern.search(text)
        if not m:
            raise SystemExit(
                "ERROR: progress circle block not found "
                "(SizedBox + CircularProgressIndicator value: progress)"
            )
        if (
            m.group(1) == str(TARGET_SIZE)
            and m.group(2) == str(TARGET_SIZE)
            and m.group(3) == TARGET_STROKE
            and m.group(5) == TARGET_FONT
        ):
            print(f"home_circle_patch: already at target via flexible match")
        else:

            def repl(mo: re.Match) -> str:
                return (
                    f"SizedBox(\n                    width: {TARGET_SIZE},\n                    height: {TARGET_SIZE},\n                    "
                    f"child: Stack(\n                      alignment: Alignment.center,\n                      "
                    f"children: [\n                        CircularProgressIndicator(\n                          value: progress,\n                          "
                    f"strokeWidth: {TARGET_STROKE}{mo.group(4)}{TARGET_FONT}"
                )

            # Safer: only replace width/height/stroke/font via group surgery
            def repl2(mo: re.Match) -> str:
                full = mo.group(0)
                full = re.sub(r"width:\s*\d+", f"width: {TARGET_SIZE}", full, count=1)
                full = re.sub(r"height:\s*\d+", f"height: {TARGET_SIZE}", full, count=1)
                full = re.sub(
                    r"strokeWidth:\s*[\d.]+", f"strokeWidth: {TARGET_STROKE}", full, count=1
                )
                full = re.sub(r"fontSize:\s*\d+", f"fontSize: {TARGET_FONT}", full, count=1)
                return full

            text2, n = pattern.subn(repl2, text, count=1)
            if n != 1:
                raise SystemExit(f"ERROR: flexible replace count={n}")
            HOME.write_text(text2, encoding="utf-8")
            print(
                f"home_circle_patch (flex): {m.group(1)}x{m.group(2)} → {TARGET_SIZE}x{TARGET_SIZE}"
            )

    # Assert final state
    t = HOME.read_text(encoding="utf-8")
    m = re.search(
        r"SizedBox\(\s*width:\s*(\d+)\s*,\s*height:\s*(\d+)\s*,\s*child:\s*Stack\([\s\S]{0,250}?"
        r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*([\d.]+)",
        t,
    )
    if not m or m.group(1) != str(TARGET_SIZE) or m.group(2) != str(TARGET_SIZE):
        raise SystemExit(
            f"ERROR: final circle not {TARGET_SIZE}x{TARGET_SIZE}: {m.groups() if m else None}"
        )
    if "OverflowBox" in t:
        raise SystemExit("ERROR: OverflowBox introduced")
    print("home_circle_patch done OK")


if __name__ == "__main__":
    main()
