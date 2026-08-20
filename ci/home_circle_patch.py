#!/usr/bin/env python3
"""Single source for Home progress circle size on the ZIP HomeScreen.

Apply AFTER ZIP extract + overlays + ZIP re-lock.
Edits ONLY the daily progress ring (value: progress): outer SizedBox size + stroke.
Percent font stays at ZIP original (14) — do NOT scale internal text with diameter.
No OverflowBox. No other UI / audio / AI changes.
"""
from pathlib import Path
import re
import sys

HOME = Path("lib/screens/home_screen.dart")
TARGET_SIZE = 160
TARGET_STROKE = "7"
TARGET_FONT = "14"


def main() -> None:
    if not HOME.exists():
        raise SystemExit(f"ERROR: {HOME} missing — run after ZIP extract")
    text = HOME.read_text(encoding="utf-8")
    if "OverflowBox" in text:
        raise SystemExit("ERROR: OverflowBox present — refuse to patch")

    marker = "CircularProgressIndicator(\n                          value: progress,"
    idx = text.find(marker)
    if idx < 0:
        m = re.search(
            r"CircularProgressIndicator\(\s*value:\s*progress\s*,",
            text,
        )
        if not m:
            raise SystemExit("ERROR: progress CircularProgressIndicator not found")
        idx = m.start()

    start = text.rfind("SizedBox(", 0, idx)
    if start < 0:
        raise SystemExit("ERROR: SizedBox before progress indicator not found")

    end_token = (
        "color: accent),\n"
        "                        ),\n"
        "                      ],\n"
        "                    ),\n"
        "                  ),"
    )
    end = text.find(end_token, idx)
    if end < 0:
        end = text.find("],\n                    ),\n                  ),", idx)
        if end < 0:
            raise SystemExit("ERROR: end of progress circle block not found")
        end = end + len("],\n                    ),\n                  ),")
    else:
        end = end + len(end_token)

    block = text[start:end]
    if "value: progress" not in block:
        raise SystemExit("ERROR: extracted block missing value: progress")

    mw = re.search(r"width:\s*(\d+)", block)
    mh = re.search(r"height:\s*(\d+)", block)
    ms = re.search(r"strokeWidth:\s*([\d.]+)", block)
    mf = re.search(r"fontSize:\s*(\d+)", block)
    if not all([mw, mh, ms, mf]):
        raise SystemExit("ERROR: could not parse width/height/stroke/font in block")

    w, h, stroke, font = mw.group(1), mh.group(1), ms.group(1), mf.group(1)
    if (
        w == str(TARGET_SIZE)
        and h == str(TARGET_SIZE)
        and stroke == TARGET_STROKE
        and font == TARGET_FONT
    ):
        print(
            f"home_circle_patch: already {TARGET_SIZE}x{TARGET_SIZE} "
            f"stroke={TARGET_STROKE} font={TARGET_FONT}"
        )
        return

    new_block = block
    new_block = re.sub(r"width:\s*\d+", f"width: {TARGET_SIZE}", new_block, count=1)
    new_block = re.sub(r"height:\s*\d+", f"height: {TARGET_SIZE}", new_block, count=1)
    new_block = re.sub(
        r"strokeWidth:\s*[\d.]+", f"strokeWidth: {TARGET_STROKE}", new_block, count=1
    )
    new_block = re.sub(r"fontSize:\s*\d+", f"fontSize: {TARGET_FONT}", new_block, count=1)

    text = text[:start] + new_block + text[end:]
    HOME.write_text(text, encoding="utf-8")
    print(
        f"home_circle_patch: {w}x{h} stroke={stroke} font={font} "
        f"→ {TARGET_SIZE}x{TARGET_SIZE} stroke={TARGET_STROKE} font={TARGET_FONT}"
    )

    t = HOME.read_text(encoding="utf-8")
    m2 = re.search(
        r"SizedBox\(\s*width:\s*(\d+)\s*,\s*height:\s*(\d+)\s*,\s*child:\s*Stack\([\s\S]{0,250}?"
        r"CircularProgressIndicator\(\s*value:\s*progress\s*,\s*strokeWidth:\s*([\d.]+)",
        t,
    )
    if not m2 or m2.group(1) != str(TARGET_SIZE) or m2.group(2) != str(TARGET_SIZE):
        raise SystemExit(
            f"ERROR: final circle not {TARGET_SIZE}x{TARGET_SIZE}: "
            f"{m2.groups() if m2 else None}"
        )
    if "OverflowBox" in t:
        raise SystemExit("ERROR: OverflowBox introduced")
    if "${(progress * 100).round()}%" not in t:
        raise SystemExit("ERROR: percent label corrupted")
    print("home_circle_patch done OK")


if __name__ == "__main__":
    main()
