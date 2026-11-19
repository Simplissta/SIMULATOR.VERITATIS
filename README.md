# Simulator Veritatis

Android-first Flutter starter for an offline-friendly social reality simulator.

## Current prototype
- Character roster with local persistence
- Portrait selection and local copy
- Editable description, talent and goal
- 100+ attributes grouped by category (0–100)
- Basic randomized event feed (placeholder narrative engine; not an LLM)
- Accent/text/background HEX color settings and text alignment
- Clear local saved data
- GitHub Actions APK build workflow

## Build with GitHub Actions
1. Upload this folder's contents to a GitHub repository (root should contain `pubspec.yaml`, `lib/`, and `.github/`).
2. Open Actions and run **Build Android APK** (or push to main/master).
3. Download artifact `simulator-veritatis-debug-apk` from the workflow run.

## Build locally
Install Flutter, then run `flutter pub get` and `flutter build apk --debug`.

## Important
This is an early functional starter, not a finished simulator. Narrative generation is placeholder/randomized and there is no real LLM integration yet. GitHub Actions generates Android scaffolding with `flutter create` before building.
