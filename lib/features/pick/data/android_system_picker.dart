import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/pick_types.dart';
import 'system_picker.dart';

/// Channel wrapper for the Kotlin bridge in MainActivity (ADR-006). Never logs:
/// payloads hold URIs and file names (FR-19).
class AndroidSystemPicker implements SystemPicker {
  AndroidSystemPicker([this._channel = const MethodChannel('exactsize/system_picker')]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'resultReady') _ready.add(null);
    });
  }

  final MethodChannel _channel;
  final _ready = StreamController<void>.broadcast();

  /// Camera file names are ours: 32 hex characters from SecureRandom plus .jpg. Anything else
  /// is dropped, so a name can never point outside the camera folder when Dart deletes it.
  static final _cameraName = RegExp(r'^[0-9a-f]{32}\.jpg$');

  @override
  Stream<void> get resultReady => _ready.stream;

  @override
  Future<bool> cameraAvailable() async => await _call<bool>('cameraAvailable') ?? false;

  @override
  Future<LaunchOutcome> launch(PickSource source) async =>
      LaunchOutcome.values.asNameMap()[await _call<String>('launch', {'source': source.name})] ??
      LaunchOutcome.unavailable;

  @override
  Future<SystemPickResult?> takeResult() async => parse(await _call<Object?>('takeResult'));

  @override
  Future<String?> pendingCaptureName() async => _name(await _call<Object?>('pendingCaptureName'));

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw PlatformException(code: e.code); // message and details dropped (FR-19)
    }
  }

  static String? _name(Object? v) => v is String && _cameraName.hasMatch(v) ? v : null;

  /// Maps a bridge payload to a result; anything unexpected becomes [NotOpenable].
  static SystemPickResult? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return const NotOpenable(origin: PickOrigin.gallery);
    final origin = PickOrigin.values.asNameMap()[raw['origin']];
    final uri = raw['uri'] is String && (raw['uri'] as String).isNotEmpty ? raw['uri'] as String : null;
    final name = _name(raw['fileName']);
    return switch ((raw['outcome'], origin)) {
      ('picked', final PickOrigin o) when o != PickOrigin.camera && uri != null =>
        Picked(uri: uri, origin: o, fromOwnApp: raw['fromOwnApp'] == true),
      ('captured', PickOrigin.camera) when uri != null && name != null => Captured(uri: uri, fileName: name),
      ('cancelled', final PickOrigin o) => Cancelled(origin: o, fileName: name),
      ('captureLost', PickOrigin.camera) => CaptureLost(fileName: name),
      ('notOpenable', final PickOrigin o) => NotOpenable(origin: o),
      _ => NotOpenable(origin: origin ?? PickOrigin.gallery),
    };
  }
}
