# LIV — Source of Truth (final)

Do not assume repo files equal APK files. Trace `.github/workflows/build-apk.yml` first.

## Audio → Repository

Final copies after ZIP restore must come from the repo:

- `lib/services/audio_service.dart`
- `android/app/src/main/kotlin/com/liv/MainActivity.kt`
- `ci/sound_fix.py` only when regenerating WAVs / MainActivity

**AudioService only:** meditationVolume, playLoop, mute/unmute, setVolume, fadeIn/fadeOut, lifecycle.

**MainActivity / sound_fix only:** tick sound, button click, SoundPool, vibration, MethodChannel `liv.feedback`.

Rules:

- No extra `AudioPlayer` inside any Screen
- No double vibration (no HapticFeedback + AudioService on the same event)
- No global `tick()` → `buttonClick()` rewrite

## Home circle → ZIP HomeScreen + home_circle_patch

APK HomeScreen comes from `liv_app_full.zip`, **not** from repo `lib/screens/home_screen.dart`.

CI does `rm -rf lib` then restores lib from the ZIP. Editing only the repo home file will not change the APK.

**Single size controller:** `ci/home_circle_patch.py` (runs after ZIP re-lock, never undone).

Current intended size (progress ring) = **exact Build 246**:

- **90×90**
- strokeWidth **7**
- percent fontSize **16**

ZIP baseline before patch is 70×70 stroke 6 font 14.

Rules:

- No OverflowBox
- No forced resize from feature_patch / soundtrack_patch / sound_fix
- No blanket patch on every `CircularProgressIndicator`
- No editing repo home only to change the circle
- No other Home UI changes when only the circle is requested

To change size later: edit `TARGET_SIZE` / stroke / font in `ci/home_circle_patch.py` only.

## Patch responsibilities

| Script | Allowed | Forbidden |
|--------|---------|-----------|
| `home_circle_patch.py` | Progress ring size/stroke/font on ZIP home | Audio, AI, other UI |
| `sound_fix.py` | Native feedback WAVs + MainActivity | Home circle, meditation logic, AI |
| `soundtrack_patch.py` | Meditation asset, AudioService wiring, fadeOut, invoke feature_patch | Home circle, tick→buttonClick rewrite |
| `feature_patch.py` | AI / gemini / l10n overlays | Home circle, audio, MainActivity |

## Validation before build

- `meditation_ambient.mp3` present
- Asset listed once in pubspec
- Final AudioService from repo (`meditationVolume = 1.0`, `liv.feedback`)
- Final MainActivity has `liv.feedback` + `USAGE_MEDIA`
- WAV tick/click present under `res/raw`
- Progress circle **90×90**, no OverflowBox
- No global tick→buttonClick in patches
- AI + Onboarding use AudioService only

Workflow prints `sha256sum` for final home / AudioService / MainActivity (`VERIFY Path B OK`).

## No side changes

Do not change AI, Gemini, database, models, localization, colors, navigation, habits, dreams, or tasks unless required for a green build.

## Summary

| Concern | Source of Truth |
|---------|-----------------|
| Audio | Repo: AudioService + MainActivity/sound_fix |
| Home circle | ZIP HomeScreen + `ci/home_circle_patch.py` only |
| Onboarding / models / root_shell / period | Repo Phase 4 simplified architecture (isFemale + trackPeriod). Restored after ZIP. Obsolete ux_period_patch / period_nav_patch disabled. |

Do not merge the two in a way that breaks the current full UI from the ZIP.

## Phase 5 (CI alignment)

Path B now preserves and re-locks the Phase 4 simplified onboarding, models (isFemale/trackPeriod), root_shell (female-only Period tab), and period_screen from the repository. The old 1144-line onboarding curl and obsolete period patches are no longer applied.
