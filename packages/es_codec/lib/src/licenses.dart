// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _base = 'packages/es_codec/third_party/libjpeg-turbo';
const _stb = 'packages/es_codec/third_party/stb';

/// Adds the licences of the native code bundled in es_codec (libjpeg-turbo:
/// IJG, Modified BSD, zlib; its bundled libspng and zlib; stb_image_resize2,
/// MIT option of its MIT / public-domain licence) to Flutter's licence
/// registry, so they appear on the app's licence page. Pub packages are added
/// by Flutter itself. Call once at app start.
void registerEsCodecLicenses() {
  LicenseRegistry.addLicense(() async* {
    Future<String> load(String path) => rootBundle.loadString('$_base/$path');
    yield LicenseEntryWithLineBreaks(
      ['libjpeg-turbo'],
      [await load('LICENSE.md'), await load('README.ijg')].join('\n\n'),
    );
    yield LicenseEntryWithLineBreaks(
      ['libspng (bundled with libjpeg-turbo)'],
      [await load('src/spng/LICENSE'), await load('src/spng/libpng-LICENSE.txt')].join('\n\n'),
    );
    yield LicenseEntryWithLineBreaks(
      ['zlib (bundled with libjpeg-turbo)'],
      await load('src/spng/zlib/LICENSE'),
    );
    yield LicenseEntryWithLineBreaks(
      ['stb_image_resize2'],
      await rootBundle.loadString('$_stb/LICENSE'),
    );
  });
}
