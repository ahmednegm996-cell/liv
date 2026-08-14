#!/usr/bin/env python3
"""Wire release/debug signing + ndkVersion into android/app/build.gradle."""
from pathlib import Path
import re
import sys

f = Path("android/app/build.gradle")
if not f.exists():
    print("No build.gradle — skip")
    sys.exit(0)

t = f.read_text(encoding="utf-8")
use_release = Path("android/app/liv-release.keystore").exists()

# Force NDK version required by plugins
if re.search(r"ndkVersion\s*=", t):
    t = re.sub(r'ndkVersion\s*=\s*[^\n]+', 'ndkVersion = "26.1.10909125"', t)
else:
    t = re.sub(r'(android\s*\{)', r'\1\n    ndkVersion = "26.1.10909125"', t, count=1)

# 1) Remove any existing signingConfigs { ... } block
t = re.sub(
    r"\n[ \t]*signingConfigs[ \t]*\{(?:[^{}]|\{[^{}]*\})*\}[ \t]*\n",
    "\n",
    t,
    count=1,
)

# 2) Remove any signingConfig = ... lines
t = re.sub(
    r"[ \t]*signingConfig[ \t]*=[ \t]*signingConfigs\.\w+[ \t]*\n",
    "",
    t,
)

# 3) Inject signingConfigs after android {
if use_release:
    block = (
        "\n"
        "    signingConfigs {\n"
        "        release {\n"
        "            def keystoreProperties = new Properties()\n"
        "            def keystorePropertiesFile = rootProject.file('key.properties')\n"
        "            if (keystorePropertiesFile.exists()) {\n"
        "                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "                keyAlias keystoreProperties['keyAlias']\n"
        "                keyPassword keystoreProperties['keyPassword']\n"
        "                storeFile file(keystoreProperties['storeFile'])\n"
        "                storePassword keystoreProperties['storePassword']\n"
        "            }\n"
        "        }\n"
        "    }\n"
    )
    t = re.sub(r"(android[ \t]*\{)", r"\1" + block, t, count=1)

    m = re.search(r"(buildTypes[ \t]*\{[^{}]*release[ \t]*\{)", t, re.S)
    if m:
        t = t[: m.end()] + "\n            signingConfig = signingConfigs.release" + t[m.end() :]
        print("Injected signingConfig into buildTypes.release")
    else:
        m2 = re.search(r"buildTypes[ \t]*\{", t)
        if m2:
            m3 = re.search(r"release[ \t]*\{", t[m2.end() :])
            if m3:
                pos = m2.end() + m3.end()
                t = t[:pos] + "\n            signingConfig = signingConfigs.release" + t[pos:]
                print("Injected signingConfig (fallback)")
        else:
            print("WARNING: could not find buildTypes.release")
else:
    m = re.search(r"(buildTypes[ \t]*\{[^{}]*release[ \t]*\{)", t, re.S)
    if m:
        t = t[: m.end()] + "\n            signingConfig = signingConfigs.debug" + t[m.end() :]
    print("Using debug signing for release")

# minify off
t = re.sub(r"minifyEnabled[ \t]+[^\n]+", "minifyEnabled false", t)
t = re.sub(r"shrinkResources[ \t]+[^\n]+", "shrinkResources false", t)
if "minifyEnabled" not in t:
    m = re.search(r"buildTypes[ \t]*\{[^{}]*release[ \t]*\{", t, re.S)
    if m:
        t = (
            t[: m.end()]
            + "\n            minifyEnabled false\n            shrinkResources false"
            + t[m.end() :]
        )

f.write_text(t, encoding="utf-8")
print("--- relevant lines ---")
for i, line in enumerate(f.read_text().splitlines(), 1):
    low = line.lower()
    if any(k in low for k in ("signing", "release", "minify", "shrink", "buildtypes", "ndk")):
        print(f"{i}: {line}")
print("fix_signing.py done")
