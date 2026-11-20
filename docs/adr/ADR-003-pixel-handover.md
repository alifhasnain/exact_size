---
id: ADR-003
title: Pixel handover FEAT-002 → FEAT-004 — in-memory native buffer with ownership transfer
status: Approved
version: 1.0
updated: 2026-11-20
links: [FEAT-002, FEAT-004, ADR-001, ADR-002]
---

# ADR-003 — Pixel handover format

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-002 hands FEAT-004 pixels at exactly W×H, 8-bit sRGB, row-major, 3 channels (opaque) or 4 channels straight alpha, plus flags [Fact](FEAT-002 prd.md section 1). FEAT-002 OQ-10 asks: in-memory buffer or app-private raw temp file? Size is W×H×channels: 2 MP ≈ 6–8 MB; 24 MP (the bound) ≈ 72–96 MB [Fact: arithmetic]. FEAT-004 reads the pixels on every encode pass (up to ~10) in a background isolate, via FFI (ADR-002). Low-end devices have ~2 GB RAM, and Android's low-memory killer can end the process without a catchable error [Fact](https://developer.android.com/topic/performance/memory-management).

## Decision drivers
- Zero or one copy of the pixels; peak memory ≤ 150 MB at 2 MP (FEAT-004 NFR-2).
- Encoder reads pixels every pass without re-reading storage (NFR-1).
- No raw personal image data on disk if avoidable; easy cleanup (FR-20, section 10).
- Usable from a background isolate and by native code.

## Options considered
### Option A — In-memory buffer in native memory (`malloc`), exposed to Dart as a `Uint8List` view; ownership moves to FEAT-004
- Good: zero copies between producer, worker isolate (address passed as an int) and the encoder (pointer passed directly) [Fact](https://api.dart.dev/dart-ffi/Uint8Pointer/asTypedList.html); no pixels on disk; FEAT-004 can flatten transparency in place (4→3 channels).
- Bad: manual lifetime; a use-after-free or leak is possible if ownership rules are broken.

### Option B — App-private raw temp file
- Good: memory can stay small if the encoder streams rows.
- Bad: every pass re-reads the file (~10× 96 MB at 24 MP) or loads it into memory anyway; write/read time on cheap storage; raw pixels of a face or signature on disk; low-storage failures; more cleanup paths.

### Option C — Dart-heap `Uint8List` (garbage collected)
- Good: no manual free.
- Bad: sending it to a worker isolate copies it unless wrapped in `TransferableTypedData`, which also copies once at creation [Fact](https://api.dart.dev/dart-isolate/TransferableTypedData-class.html); passing it to FFI without a copy needs leaf calls [Assumption: supported on the pinned Dart version]. At 24 MP the extra copy doubles peak memory.

## Decision
Recommend **Option A**. Contract:
- `PixelBuffer { width, height, channels (3|4), stride == width×channels, data (native, tightly packed), hasTransparency, upscaleFactor, cropRect, rotationApplied }`. No file name, path or EXIF.
- FEAT-002 allocates and fills it; handing it to FEAT-004 transfers ownership. FEAT-004 frees it on success, failure or cancel. The main-isolate request object keeps it alive until the worker has stopped; the worker is never killed while inside a native call (cancel is a flag checked between passes).
- Before allocating, the producer checks available memory (pixel bytes × 2 headroom against `MemAvailable`); if short, it returns `IMAGE_TOO_LARGE` instead of risking a low-memory kill. Allocation failure maps to `OUT_OF_MEMORY_HANDLED`.
- If FEAT-002's decoder produces Dart-heap bytes, it copies once into the native buffer and drops its copy before handover.
Final once the Product Owner approves.

## Consequences
- Easier: fast passes, no pixel files to clean, in-place flatten.
- Harder: ownership must be enforced in code review and tested (leak test in debug builds).
- FEAT-002's contract table is unchanged; its OQ-10 is answered by this ADR once approved.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 1.0 | 2026-11-20 | Approved by Product Owner |
