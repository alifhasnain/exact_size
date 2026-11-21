// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String announceProgress(String pass, String total) {
    return 'Compressing, step $pass of $total.';
  }

  @override
  String announceSuccess(String size) {
    return 'Done. File size: $size.';
  }

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

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'Enter a width and height between $min and $max pixels.';
  }

  @override
  String get cropTargetTooLarge =>
      'That size is too large for this app. Choose a smaller size.';

  @override
  String get cropSourceTooLarge =>
      'This photo is too large to open on this device. Choose another photo.';

  @override
  String get cropUnsupportedInput =>
      'This file type isn\'t supported on this device. Choose a JPEG or PNG photo.';

  @override
  String get cropCorruptInput =>
      'We can\'t read this file. Choose another photo.';

  @override
  String get cropSourceUnavailable =>
      'We can\'t find this photo anymore. Please choose it again.';

  @override
  String get cropOutOfMemory =>
      'This photo is too large for this device. Try a smaller photo.';

  @override
  String get cropCancelled => 'Cancelled. Your photo was not changed.';

  @override
  String cropNoticeEnlarged(String size) {
    return 'This photo is smaller than $size px, so it will be enlarged and may look soft.';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'This photo is much smaller than needed ($factor× enlargement) and may look blurry. Continue anyway?';
  }

  @override
  String get cropNoticeAnimated =>
      'This image is animated. Only the first frame is used.';

  @override
  String get cropHintLimitedPrecision =>
      'The frame is very thin on screen. Use the move and zoom buttons for fine positioning.';

  @override
  String get cropButtonCentre => 'Centre';

  @override
  String get cropButtonReset => 'Reset';

  @override
  String get cropButtonMoveLeft => 'Move left';

  @override
  String get cropButtonMoveRight => 'Move right';

  @override
  String get cropButtonMoveUp => 'Move up';

  @override
  String get cropButtonMoveDown => 'Move down';

  @override
  String get cropButtonZoomIn => 'Zoom in';

  @override
  String get cropButtonZoomOut => 'Zoom out';

  @override
  String get cropButtonRotateClockwise => 'Rotate clockwise';

  @override
  String get cropButtonRotateCounterclockwise => 'Rotate counter-clockwise';

  @override
  String get cropButtonContinue => 'Continue';

  @override
  String get cropButtonContinueAnyway => 'Continue anyway';

  @override
  String get cropButtonChooseAnother => 'Choose another photo';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'the centre',
      'top': 'the top',
      'bottom': 'the bottom',
      'left': 'the left side',
      'right': 'the right side',
      'topLeft': 'the top-left',
      'topRight': 'the top-right',
      'bottomLeft': 'the bottom-left',
      'bottomRight': 'the bottom-right',
      'other': 'part',
    });
    return 'Crop area, zoom $zoom, showing $_temp0 of the photo';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'left',
      'right': 'right',
      'top': 'top',
      'bottom': 'bottom',
      'other': '',
    });
    return 'Reached the $_temp0 edge.';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'top-left',
      'topRight': 'top-right',
      'bottomLeft': 'bottom-left',
      'bottomRight': 'bottom-right',
      'other': '',
    });
    return 'Resize crop, $_temp0 corner';
  }

  @override
  String get cropAnnounceNoEnlargement =>
      'The photo no longer needs enlarging.';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'Strong enlargement ($factor×). You will be asked to confirm before continuing.';
  }

  @override
  String get pickTakePhoto => 'Take a photo';

  @override
  String get pickChooseGallery => 'Choose from gallery';

  @override
  String get pickChooseFiles => 'Choose from files';

  @override
  String get pickPrivacyNote =>
      'Your photos stay on your phone and are never uploaded.';

  @override
  String get pickOpening => 'Opening your photo…';

  @override
  String get pickNoCamera =>
      'No camera app was found on this phone. Choose a photo from the gallery instead.';

  @override
  String get pickPickerUnavailable =>
      'We couldn\'t open the photo chooser. Try again or take a photo.';

  @override
  String get pickCameraNoPhoto =>
      'The camera didn\'t return a photo. Please try again.';

  @override
  String get pickLowSpace =>
      'There isn\'t enough free space on this phone to take a photo. Free some space or choose a photo from the gallery.';

  @override
  String get pickCaptureLost =>
      'The photo was lost while the camera was open. Please take it again.';

  @override
  String get pickItemNotOpenable =>
      'We can\'t open that item. Choose a photo instead.';

  @override
  String get pickSourceUnavailable =>
      'We couldn\'t open this photo. If it is stored online, connect to the internet or choose a photo saved on this phone.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'ExactSize';
}
