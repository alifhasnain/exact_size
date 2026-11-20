import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../domain/pixel_buffer.dart';

/// [PixelBuffer] in native memory (ADR-003). FEAT-002 allocates and fills it;
/// handing it to FEAT-004 in a request moves ownership, and the runner frees
/// it on success, failure and cancel. The worker isolate only gets a
/// non-owning view at the same address, so pixels are never copied.
final class NativePixelBuffer implements PixelBuffer {
  NativePixelBuffer._(this.pointer, this.width, this.height, this.channels,
      this.hasTransparency, this.byteLength, this._owner);

  /// Allocates width × height × channels bytes (owner). Throws
  /// [OutOfMemoryError] if the allocation fails (mapped in T18).
  factory NativePixelBuffer.allocate({
    required int width,
    required int height,
    required int channels,
    required bool hasTransparency,
  }) {
    final length = width * height * channels;
    final p = malloc<Uint8>(length);
    if (p == nullptr) throw OutOfMemoryError();
    _live++;
    return NativePixelBuffer._(p, width, height, channels, hasTransparency, length, true);
  }

  /// Non-owning view at [address] (worker isolate). Never freed through this object.
  factory NativePixelBuffer.view({
    required int address,
    required int width,
    required int height,
    required int channels,
    required bool hasTransparency,
    required int byteLength,
  }) =>
      NativePixelBuffer._(Pointer<Uint8>.fromAddress(address), width, height, channels,
          hasTransparency, byteLength, false);

  /// Debug leak counter: owning buffers allocated and not yet freed (this isolate).
  static int get live => _live;
  static int _live = 0;

  final Pointer<Uint8> pointer;

  /// Size of the allocation; unchanged when alpha is removed.
  final int byteLength;
  final bool _owner;
  bool _freed = false;

  @override
  final int width, height;
  @override
  int channels;
  @override
  bool hasTransparency;

  @override
  int get stride => width * channels;

  int get address => pointer.address;

  @override
  Uint8List get bytes {
    if (_freed) throw StateError('PixelBuffer used after free');
    return pointer.asTypedList(byteLength);
  }

  @override
  void markAlphaRemoved() {
    channels = 3;
    hasTransparency = false;
  }

  /// Frees the memory once; later calls do nothing. Views never free.
  void free() {
    if (!_owner || _freed) return;
    _freed = true;
    malloc.free(pointer);
    _live--;
  }
}
