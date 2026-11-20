# Changelog

Implementation changes, one line per finished task. Format: `- FEAT-nnn-Tnn: what changed`.

## [Unreleased]
- FEAT-004-T01: Flutter 3.50.1 app scaffold (Android only, minSdk 28 confirmed in merged manifest); pinned flutter_riverpod 3.5.0, get_it 9.3.0, injectable 3.0.0 (+ injectable_generator, build_runner), material_ui/cupertino_ui; gen-l10n with en, es, pt, pt_BR, hi, id, ar (localization delegates listed in app.dart because generated defaults are deprecated in 3.50); empty compression module and es_codec package; no riverpod_generator (plain providers, one less codegen step); Flutter 3.50.1 default minSdk is 24 (FlutterExtension.kt), below our 28. Placeholder applicationId com.exactsize.exact_size must be confirmed before the first Play upload.
