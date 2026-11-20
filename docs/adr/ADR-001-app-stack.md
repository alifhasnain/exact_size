---
id: ADR-001
title: App stack — Flutter (Dart) on Android, native C via Dart FFI only where needed
status: Approved
version: 1.0
updated: 2026-11-20
links: [BRIEF, FEAT-004, FEAT-002, ADR-002, ADR-003]
---

# ADR-001 — App stack

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
No code and no stack ADR exist yet. The brief fixes Flutter, Android first, iOS-ready but unplanned, on-device and offline, no backend, solo developer, ~20 person-weeks to first release [Fact](docs/product/vision.md). The brief asks Stage 6 to record "platform-specific code only where needed" as an ADR. FEAT-004 needs fast, deterministic JPEG/PNG encoding with fine control (quality, chroma subsampling, Huffman tables, comment segments) [Fact](FEAT-004 FR-5, FR-8, FR-15). FEAT-002 needs HEIC/WebP decode and region decode.

Flutter 3.50.x declares FFIgen and JNIgen production-ready. They let Dart call C and Java/Kotlin APIs through generated bindings, so no platform-channel plugin is needed. The `record_use` package tree-shakes unused native bindings [Assumption](Flutter 3.50 release notes as supplied by the Product Owner; verify against the official notes at project scaffold).

## Decision drivers
- One codebase, iOS-ready without planned iOS work.
- Image pipeline performance on low-end Android (FEAT-004 NFR-1: ≤ 3 s median at 2 MP).
- Determinism and control over encoder settings (FEAT-004 FR-15, FR-21, FR-8).
- Solo developer: smallest amount of platform code and tooling.
- Minimum Android version: Android 9 (API 28), a Product Owner decision made on 2026-11-20.

## Options considered
### Option A — Flutter + Dart; native C libraries via Dart FFI (FFIgen bindings) for the image codec; Android APIs via JNIgen
- Good: one UI and domain codebase. The C codec code compiles for iOS later unchanged (iOS-ready). FFI calls have no message-copy overhead, unlike platform channels [Fact](https://dart.dev/interop/c-interop). FFIgen generates the libjpeg-turbo bindings instead of hand-written ones. JNIgen calls the few Android APIs needed (`ImageDecoder`, MediaStore, memory info) directly from Dart, so there is no Kotlin platform-channel plugin to maintain. `record_use` keeps unused bindings out of the APK.
- Bad: NDK/CMake build for 3 ABIs; native memory managed by hand; Google Play 16 KB page-size rule applies to bundled `.so` files [Fact](https://developer.android.com/guide/practices/page-sizes). JNIgen does not remove the rule from ADR-003: large pixel buffers stay in native memory and never cross JNI as Java arrays.

### Option B — Flutter UI + Kotlin image pipeline via platform channels (Android `Bitmap`/`ImageDecoder`)
- Good: no NDK; uses the OS decoders and encoders directly.
- Bad: large pixel buffers cross the channel by copy (~96 MB at 24 MP). The OS encoder gives no chroma/Huffman/COM control, and its bytes can change with OS updates (see ADR-002). The pipeline must be rewritten in Swift for iOS.

### Option C — Native Android (Kotlin + Jetpack Compose)
- Good: best platform access, no bridge.
- Bad: contradicts the brief's Flutter decision; iOS would be a full rewrite of UI and domain. The codec is C under every option, so going native saves no codec work. Reconsidered on 2026-11-20 at the Product Owner's request and still not recommended.

## Sub-decisions (part of this ADR)
| Topic | Decision / proposal | Alternative |
|---|---|---|
| Flutter version | **Flutter 3.50.x stable**, exact patch pinned in the repo (FVM config or documented version) so builds and determinism goldens are reproducible | Float on stable (breaks determinism goldens without notice) |
| Native interop | **FFIgen** for C bindings (`packages/es_codec/`); **JNIgen** for Android API calls; `record_use` enabled for tree shaking | Hand-written `dart:ffi` bindings and a Kotlin platform-channel plugin |
| minSdk | **28 (Android 9)**, Product Owner decision 2026-11-20. The platform decodes HEIC/HEIF on every supported device [Fact](https://developer.android.com/media/platform/supported-formats). `UNSUPPORTED_INPUT` stays only for corrupt or unusual files, for example some 10-bit or HDR HEIC variants [Hypothesis]. Devices on Android 7.0–8.1 can't install the app [Assumption: a small share of the target market; check Play Console distribution data before release] | minSdk 24: reaches older low-end devices, but HEIC is unsupported below API 28 |
| targetSdk | Whatever Google Play requires at release time [Fact](https://developer.android.com/google/play/requirements/target-sdk) | — |
| State management | **Riverpod** (`flutter_riverpod`, version pinned), Product Owner decision 2026-11-20. Providers handle dependency injection and test overrides. Domain logic stays in pure Dart with no Riverpod imports, so it can be unit-tested on its own (FEAT-004 NFR-9). Whether to use `riverpod_generator` is decided at scaffold | Flutter built-ins (`ChangeNotifier`/`ValueNotifier`) |
| Module layout | `lib/features/<feature>/{domain,data,presentation}`; native codec in a local FFI plugin package `packages/es_codec/` | One flat `lib/` |
| Localisation | Flutter `gen-l10n` with ARB files and ICU placeholders (6 languages, RTL) | Third-party i18n package |

## Decision
Recommend **Option A** with the sub-decisions above. It keeps one codebase, gives the encoder control FEAT-004 needs, and the C code carries over to iOS. FFIgen and JNIgen lower its platform-code cost. Option B is the main alternative if the NDK build proves too costly in the ADR-002 spike. Final once the Product Owner approves.

## Consequences
- Easier: one language for UI and domain; pure-Dart domain is unit-testable (FEAT-004 NFR-9); no hand-written bindings or Kotlin plugin; HEIC works on every supported device.
- Harder: native build (CMake, 3 ABIs: arm64-v8a, armeabi-v7a, x86_64), 16 KB page alignment, third-party licence notices in the app; Riverpod adds a package and its concepts to learn.
- Follow-up: the project scaffold (Flutter 3.50.x, Riverpod, lints, CI) is a prerequisite task shared by all features. At scaffold, confirm that Flutter 3.50.x's own minimum Android version is ≤ API 28 and that the FFIgen/JNIgen claims match the official release notes. FEAT-002's tech plan decides decoders within this stack.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 0.2 | 2026-11-20 | Flutter 3.50.x pinned; FFIgen and JNIgen replace hand-written bindings and the Kotlin plugin; `record_use` added; minSdk 28 (Product Owner); Riverpod for state management (Product Owner); native Option C reconsidered and still not recommended |
| 1.0 | 2026-11-20 | Approved by Product Owner |
