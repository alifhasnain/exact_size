// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ExactSize';

  @override
  String kbAmount(String amount) {
    return '$amount KB';
  }

  @override
  String kbRange(String min, String max) {
    return '$min–$max KB';
  }

  @override
  String outcomeCantReachRange(String range, String achieved) {
    return 'We can\'t reach $range for this image at this size. Closest: $achieved.';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'We can\'t get this image down to $max at this size. Closest: $achieved.';
  }

  @override
  String get outcomeHintJpegWouldFit => 'A JPEG of this image would fit.';

  @override
  String get outcomeHintTryJpeg =>
      'PNG can\'t be made bigger. If the form accepts JPEG, try JPEG.';

  @override
  String get outcomeUnsupportedInput =>
      'This file type isn\'t supported on this device.';

  @override
  String get outcomeImageTooLarge =>
      'This image is too large to process at this size. Try smaller dimensions.';

  @override
  String get outcomeOutOfMemory =>
      'Your phone ran out of memory. Close other apps and try again.';

  @override
  String get outcomeWriteFailed =>
      'We couldn\'t save the file. Free up some storage and try again.';

  @override
  String get outcomeCancelled => 'Compression cancelled.';

  @override
  String get outcomeInternalError =>
      'Something went wrong preparing your image. Please try again.';

  @override
  String get noticeNarrowRange =>
      'This range is very narrow. Some portals count KB differently, so the file may still be rejected.';

  @override
  String get noticePaddingAdded =>
      'Padding was added to reach the minimum size. The picture itself is unchanged.';

  @override
  String get noticeTransparencyFlattened =>
      'JPEG has no transparency, so transparent areas are now white.';

  @override
  String targetMaxOutOfRange(String min, String max) {
    return 'Enter a maximum size between $min and $max.';
  }

  @override
  String get targetMinNotBelowMax => 'Minimum must be smaller than maximum.';

  @override
  String get targetWholeNumbersOnly => 'Use whole numbers of KB.';

  @override
  String get targetInvalidNumber => 'Enter a valid size in KB.';

  @override
  String get targetChooseJpegOrPng => 'Choose JPEG or PNG.';
}
