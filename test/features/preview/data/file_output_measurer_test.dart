import 'dart:io';
import 'dart:typed_data';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/preview/data/file_output_measurer.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../../test_support/golden_cases.dart';
import '../../../../test_support/synthetic_images.dart';

/// FEAT-006-T03: the measurer reads the file itself (FR-2, FR-11, AC-1.2, AC-3.4, OQ-T2).
/// Synthetic fixtures only.
void main() {
  late Directory tmp;
  const m = FileOutputMeasurer();
  setUp(() => tmp = Directory.systemTemp.createTempSync('measurer_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  var n = 0;
  String write(List<int> bytes, {String ext = 'jpg'}) => (File('${tmp.path}/${n++}.$ext')..writeAsBytesSync(bytes)).path;
  Future<MeasureResult> measure(List<int> bytes, {int delta = 0, String ext = 'jpg'}) =>
      m.measure(write(bytes, ext: ext), expectedBytes: bytes.length + delta);

  img.Image photo(int w, int h, {int channels = 3}) =>
      img.Image.fromBytes(width: w, height: h, bytes: syntheticPhoto(w, h, channels: channels).buffer, numChannels: channels);
  final jpeg = img.encodeJpg(photo(320, 240), quality: 80);
  final png = img.encodePng(photo(200, 150));
  final pngAlpha = img.encodePng(photo(64, 48, channels: 4));

  void expectMeasured(MeasureResult r, List<int> bytes, OutputFormat f, {bool alpha = false}) {
    expect(r, isA<Measured>());
    final o = (r as Measured).output;
    final oracle = img.decodeImage(Uint8List.fromList(bytes))!;
    expect((o.bytes, o.width, o.height, o.format, o.hasAlpha), (bytes.length, oracle.width, oracle.height, f, alpha));
  }

  test('FR-2: JPEG and PNG give length, width, height and format equal to the oracle and File.length', () async {
    expectMeasured(await measure(jpeg), jpeg, OutputFormat.jpeg);
    expectMeasured(await measure(png, ext: 'png'), png, OutputFormat.png);
    expectMeasured(await measure(pngAlpha, ext: 'png'), pngAlpha, OutputFormat.png, alpha: true);
  });

  test('AC-1.2: a file swapped after the result was built gives the swapped file\'s values', () async {
    final path = write(jpeg);
    final other = img.encodeJpg(photo(100, 80));
    File(path).writeAsBytesSync(other);
    expectMeasured(await m.measure(path, expectedBytes: other.length), other, OutputFormat.jpeg);
  });

  test('a .jpg name holding PNG bytes gives PNG', () async {
    expectMeasured(await measure(png), png, OutputFormat.png);
  });

  test('AC-3.4: missing, empty, truncated, bad CRC, length ± 1, WebP, GIF and HEIF give Unreadable', () async {
    expect(await m.measure('${tmp.path}/missing.jpg', expectedBytes: 10), isA<Unreadable>());
    expect(await measure(<int>[]), isA<Unreadable>());
    expect(await measure(jpeg.sublist(0, jpeg.length - 2)), isA<Unreadable>(), reason: 'JPEG without EOI');
    expect(await measure(png.sublist(0, png.length - 12), ext: 'png'), isA<Unreadable>(), reason: 'PNG without IEND');
    final badCrc = Uint8List.fromList(png);
    badCrc[60] ^= 0xff; // inside the first IDAT
    expect(await measure(badCrc, ext: 'png'), isA<Unreadable>(), reason: 'bad CRC');
    expect(await measure(jpeg, delta: 1), isA<Unreadable>());
    expect(await measure(jpeg, delta: -1), isA<Unreadable>());
    for (final name in ['animated.webp', 'animated.gif', 'orient_1.heic']) {
      expect(await measure(File('test_support/crop_fixtures/$name').readAsBytesSync()), isA<Unreadable>(), reason: name);
    }
  });

  group('real FEAT-004 outputs (tech risk 2: no false "doesn\'t match")', () {
    final outputs = <(String, ReadyToWrite)>[];
    setUpAll(() async {
      for (final c in goldenCases) {
        final px = NativePixelBuffer.allocate(width: c.width, height: c.height, channels: c.channels, hasTransparency: c.channels == 4);
        px.bytes.setAll(0, c.pixels());
        final plan = await const CompressionRunner()
            .run(CompressionRequest(pixels: px, minKb: c.minKb, maxKb: c.maxKb, format: c.format, dpi: c.dpi));
        if (plan is ReadyToWrite) outputs.add((c.name, plan));
      }
    });

    test('every golden case output measures with its case size and format; JPEGs padded with COM 4 B and 65,537 B too', () async {
      expect(outputs.length, greaterThan(20));
      expect(outputs.where((o) => o.$2.paddingBytes > 0), isNotEmpty, reason: 'a padded case is included');
      for (final (name, out) in outputs) {
        final c = goldenCases.firstWhere((c) => c.name == name);
        final r = await measure(out.bytes, ext: out.format.name);
        expect(r, isA<Measured>(), reason: name);
        final o = (r as Measured).output;
        expect((o.bytes, o.width, o.height, o.format), (out.bytes.length, c.width, c.height, out.format), reason: name);
        if (out.format == OutputFormat.jpeg) {
          for (final com in [4, 65537]) {
            final padded = _insertCom(out.bytes, com);
            final p = await measure(padded);
            expect(p, isA<Measured>(), reason: '$name + COM $com');
            expect((p as Measured).output.bytes, out.bytes.length + com);
          }
        }
      }
    });

    test('PRD section 9: outputs hold no APP1 segment and no eXIf chunk', () {
      for (final (name, out) in outputs) {
        final b = out.bytes;
        if (out.format == OutputFormat.jpeg) {
          expect(_jpegMarkers(b), isNot(contains(0xe1)), reason: name);
        } else {
          expect(_pngChunks(b), isNot(contains('eXIf')), reason: name);
        }
      }
    });
  });
}

/// Inserts a COM segment of [total] bytes (marker and length included) after APP0.
Uint8List _insertCom(Uint8List jpeg, int total) {
  assert(jpeg[2] == 0xff && jpeg[3] == 0xe0);
  final at = 4 + (jpeg[4] << 8 | jpeg[5]);
  final len = total - 2;
  return Uint8List.fromList([...jpeg.sublist(0, at), 0xff, 0xfe, len >> 8, len & 0xff, ...List.filled(len - 2, 0x20), ...jpeg.sublist(at)]);
}

/// Marker bytes of the segments before the first SOS.
List<int> _jpegMarkers(Uint8List b) {
  final out = <int>[];
  var o = 2;
  while (o + 4 <= b.length && b[o] == 0xff) {
    final m = b[o + 1];
    out.add(m);
    if (m == 0xda) break;
    o += 2 + (b[o + 2] << 8 | b[o + 3]);
  }
  return out;
}

List<String> _pngChunks(Uint8List b) {
  final out = <String>[];
  final d = ByteData.sublistView(b);
  for (var o = 8; o + 8 <= b.length;) {
    out.add(String.fromCharCodes(b, o + 4, o + 8));
    o += 12 + d.getUint32(o);
  }
  return out;
}
