# ExactSize

Resize and compress photos and signatures to exact pixel and KB targets, fully on device. Android first.

Product and technical docs live in [`docs/`](docs/): vision, roadmap, PRDs, tech plans, ADRs and task lists. See [`WORKFLOW_GUIDE.md`](WORKFLOW_GUIDE.md) for how they fit together.

## Toolchain
- Flutter **3.50.1** (pinned in `pubspec.yaml`, ADR-001), minimum Android 9 (API 28).
- Riverpod for state, get_it + injectable for dependency injection.

## Common commands
```sh
flutter pub get
dart run build_runner build   # regenerate DI config (lib/di/injection.config.dart)
flutter gen-l10n                                           # regenerate localizations (also runs on build)
flutter analyze
flutter test
flutter build apk --debug
```
