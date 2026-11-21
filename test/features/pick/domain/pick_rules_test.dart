import 'dart:io';

import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/pick/domain/pick_rules.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:flutter_test/flutter_test.dart';

const placeholder = 'content://[PLACEHOLDER].provider/images/[PLACEHOLDER]_name.jpg';

void main() {
  test('only content URIs are accepted; an own-app share is refused', () {
    bool ok(String uri, {PickOrigin origin = PickOrigin.gallery, bool own = false}) =>
        PickRules.acceptable(Picked(uri: uri, origin: origin, fromOwnApp: own));
    expect(ok('content://media/external/images/media/1'), isTrue);
    expect(ok('file:///sdcard/Pictures/x.jpg'), isFalse);
    expect(ok('http://example.com/x.jpg'), isFalse);
    expect(ok(''), isFalse);
    expect(ok('content://'), isFalse);
    expect(ok('::not a uri::'), isFalse);
    expect(ok('content://media/x', origin: PickOrigin.share, own: true), isFalse);
    expect(ok('content://media/x', origin: PickOrigin.share), isTrue);
  });

  test('camera result needs an existing, non-empty file', () {
    expect(PickRules.captureUsable(exists: true, length: 1), isTrue);
    expect(PickRules.captureUsable(exists: true, length: 0), isFalse);
    expect(PickRules.captureUsable(exists: false, length: 10), isFalse);
  });

  test('every Reason maps to a pick message', () {
    expect({for (final r in Reason.values) r: PickRules.message(r)}, {
      Reason.invalidTargetDimensions: PickMessage.itemNotOpenable,
      Reason.unsupportedInput: PickMessage.unsupported,
      Reason.corruptInput: PickMessage.corrupt,
      Reason.sourceUnavailable: PickMessage.sourceUnavailable,
      Reason.imageTooLarge: PickMessage.tooLarge,
      Reason.outOfMemoryHandled: PickMessage.tooLarge,
      Reason.cancelled: PickMessage.itemNotOpenable,
      Reason.internalError: PickMessage.itemNotOpenable,
    });
  });

  test('camera-file delete decision', () {
    expect(PickRules.filesToDelete(accepted: false, attemptFile: 'new.jpg', previousFile: 'old.jpg'), {'new.jpg'});
    expect(PickRules.filesToDelete(accepted: false, previousFile: 'old.jpg'), isEmpty, reason: 'gallery cancel');
    expect(PickRules.filesToDelete(accepted: true, attemptFile: 'new.jpg', previousFile: 'old.jpg'), {'old.jpg'});
    expect(PickRules.filesToDelete(accepted: true, attemptFile: 'new.jpg'), isEmpty);
    expect(PickRules.filesToDelete(accepted: true, attemptFile: 'same.jpg', previousFile: 'same.jpg'), isEmpty);
  });

  test('no toString reveals a URI or file name', () {
    const info = SourceInfo(
        rawWidth: 1, rawHeight: 1, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
    final values = <Object>[
      const Picked(uri: placeholder, origin: PickOrigin.gallery),
      const Captured(uri: placeholder, fileName: '[PLACEHOLDER]_name.jpg'),
      const Cancelled(origin: PickOrigin.camera, fileName: '[PLACEHOLDER]_name.jpg'),
      const CaptureLost(fileName: '[PLACEHOLDER]_name.jpg'),
      const NotOpenable(origin: PickOrigin.files),
      const PickedImage(handle: SourceHandle(placeholder), info: info, origin: PickOrigin.camera, cameraFile: '[PLACEHOLDER]_name.jpg'),
    ];
    for (final v in values) {
      expect(v.toString(), isNot(contains('PLACEHOLDER')), reason: v.runtimeType.toString());
    }
  });

  test('domain has no Flutter, Riverpod or channel imports', () {
    for (final f in Directory('lib/features/pick/domain').listSync().whereType<File>()) {
      expect(f.readAsStringSync(), isNot(matches(RegExp(r"import 'package:(flutter|flutter_riverpod|material_ui|jni)"))), reason: f.path);
    }
  });
}
