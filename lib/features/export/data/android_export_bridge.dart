import 'package:flutter/services.dart';

import '../domain/export_outcome.dart';
import '../domain/export_types.dart';
import 'export_bridge.dart';

/// Channel wrapper for ExportBridge.kt (ADR-007, tech.md section 4.1). Unknown or malformed
/// payloads and every platform error become a failure; exception text is dropped (FR-27).
class AndroidExportBridge implements ExportBridge {
  AndroidExportBridge([this._channel = const MethodChannel('exactsize/export')]);

  final MethodChannel _channel;

  @override
  Future<BridgeSave> save({required String src, required String name, required String mime, required int bytes}) =>
      _save('save', src, name, mime, bytes);

  @override
  Future<BridgeSave> saveAs({required String src, required String name, required String mime, required int bytes}) =>
      _save('saveAs', src, name, mime, bytes);

  Future<BridgeSave> _save(String method, String src, String name, String mime, int bytes) async =>
      parseSave(await _call<Object?>(method, {'src': src, 'name': name, 'mime': mime, 'bytes': bytes}));

  @override
  Future<bool> itemExists(String ref) async => await _call<Object?>('itemExists', {'ref': ref}) == true;

  @override
  Future<bool> open(String ref, String mime) async => await _call<Object?>('open', {'ref': ref, 'mime': mime}) == 'opened';

  @override
  Future<bool> share(String path, String mime) async => await _call<Object?>('share', {'path': path, 'mime': mime}) == 'opened';

  @override
  Future<void> sweepIncomplete() => _call<Object?>('sweepIncomplete');

  /// Null on any platform error (message and details dropped).
  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static const _errors = {
    'permissionDenied': ExportOutcome.permissionDenied,
    'noSpace': ExportOutcome.noSpace,
    'failed': ExportOutcome.saveFailed,
    'fileMissing': ExportOutcome.fileMissing,
    'cancelled': ExportOutcome.saveCancelled,
  };

  /// Maps a save or save-as payload; anything unexpected is [ExportOutcome.saveFailed].
  static BridgeSave parseSave(Object? raw) {
    if (raw is! Map) return const BridgeSaveError(ExportOutcome.saveFailed);
    final name = raw['name'];
    final ref = raw['ref'];
    return switch (raw['outcome']) {
      'saved' when name is String && name.isNotEmpty && ref is String && ref.isNotEmpty => BridgeSaved(name: name, ref: ref),
      'nameTaken' => const BridgeNameTaken(),
      final String o when _errors.containsKey(o) => BridgeSaveError(_errors[o]!),
      _ => const BridgeSaveError(ExportOutcome.saveFailed),
    };
  }
}
