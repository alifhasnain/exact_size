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
      'Your photos are resized on your phone. ExactSize never uploads them.';

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

  @override
  String get targetPixelsNotWhole => 'Use whole numbers of pixels.';

  @override
  String get targetLabelWidth => 'Width';

  @override
  String get targetLabelHeight => 'Height';

  @override
  String get targetLabelMin => 'Minimum size';

  @override
  String get targetLabelMax => 'Maximum size';

  @override
  String get targetOptional => 'Optional';

  @override
  String get targetUnitPx => 'px';

  @override
  String get targetUnitKb => 'KB';

  @override
  String get targetFormatLabel => 'Format';

  @override
  String targetPhotoSize(String size) {
    return 'Your photo: $size px';
  }

  @override
  String get targetUsePhotoSize => 'Use photo size';

  @override
  String get targetHintVerySmall =>
      'Very small image. Check the size on your form.';

  @override
  String get exportSave => 'Save';

  @override
  String get exportShare => 'Share';

  @override
  String get exportSaveAs => 'Choose where to save';

  @override
  String get exportOpen => 'Open';

  @override
  String get exportDone => 'Done';

  @override
  String exportSaved(String folder, String fileName) {
    return 'Saved to $folder as $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'Saved as $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'Already saved as $fileName in $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'Already saved as $fileName.';
  }

  @override
  String get exportNoSpace =>
      'There isn\'t enough free space on this phone to save the file. Free some space and try again.';

  @override
  String get exportSaveFailed =>
      'Couldn\'t save the file. Try again, or share it instead.';

  @override
  String get exportPermissionDenied =>
      'ExactSize needs the Storage permission to save to your gallery. Turn it on in Settings. You can also share the file or choose where to save it.';

  @override
  String get exportFileMissing =>
      'The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one.';

  @override
  String get exportShareFailed =>
      'Couldn\'t open the share menu. Try again, or save the file instead.';

  @override
  String get exportNoViewer =>
      'No app on this phone can open this file. You can still share it.';

  @override
  String get exportPrivacy =>
      'Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose.';

  @override
  String get exportShareHint =>
      'Some chat apps shrink photos. For a form, save the file and choose it in the upload window.';

  @override
  String get exportLeaveTitle => 'Leave without saving?';

  @override
  String get exportLeaveBody =>
      'The new file will be deleted. Your gallery photos stay as they are.';

  @override
  String get exportStay => 'Stay';

  @override
  String get exportLeave => 'Leave';

  @override
  String get exportSaving => 'Saving…';

  @override
  String get checkMatches => 'Matches your target';

  @override
  String get checkMismatch =>
      'This file doesn\'t match your target, so it can\'t be saved or shared. Go back and try again.';

  @override
  String get checkLabelPixels => 'Size in pixels';

  @override
  String get checkLabelFileSize => 'File size';

  @override
  String get checkLabelFormat => 'Format';

  @override
  String get checkTarget => 'Target';

  @override
  String get checkThisFile => 'This file';

  @override
  String get checkMeets => 'Meets';

  @override
  String get checkDoesntMeet => 'Doesn\'t meet';

  @override
  String checkUpToKb(String max) {
    return 'Up to $max';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height px';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'Also fits if your portal counts $kb as $bytes bytes.';
  }

  @override
  String get checkCaveat =>
      'We check pixels, KB and format. Some forms also check the photo itself, such as the face or background.';

  @override
  String get previewCaption => 'Shown scaled to fit your screen.';

  @override
  String previewAlt(String width, String height, String format) {
    return 'Preview of your new file, $width × $height px, $format.';
  }

  @override
  String get previewUnavailable =>
      'Preview isn\'t available. The check below is still correct.';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: target $target, this file $measured, $status.';
  }

  @override
  String get privacyEntry => 'How your photos are handled';

  @override
  String get privacyTitle => 'Your photos and privacy';

  @override
  String get privacyOnPhoneTitle => 'On your phone';

  @override
  String get privacyOnPhone =>
      'ExactSize resizes your photo on your phone. ExactSize never uploads your photos. You do not need an account.';

  @override
  String get privacyOfflineTitle => 'Works offline';

  @override
  String get privacyOffline =>
      'Every step works without an internet connection. A photo stored only online must first be downloaded by your gallery app.';

  @override
  String get privacyKeptTitle => 'What ExactSize keeps';

  @override
  String get privacyKept =>
      'ExactSize keeps temporary copies only while you work. They are deleted when you finish, or the next time the app starts. Logs hold only short status codes, never your photo.';

  @override
  String get privacyCopiesTitle => 'When you save or share';

  @override
  String get privacyCopies =>
      'Save puts a copy in your gallery or a folder you pick. Share gives a copy to the app you choose. From then on, that copy is yours, and ExactSize does not control it.';

  @override
  String get privacyOutsideTitle => 'Other apps on your phone';

  @override
  String get privacyOutside =>
      'Your gallery, keyboard and the apps you share with follow their own privacy rules. Some of them may back up or send files.';

  @override
  String get privacyReadsTitle => 'What ExactSize reads';

  @override
  String get privacyReads =>
      'ExactSize opens only the photo you choose. It does not browse your gallery or your files.';

  @override
  String get presetChooseForm => 'Choose a form';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'Photo';

  @override
  String get presetKindSignature => 'Signature';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · up to $max · $format';
  }

  @override
  String get presetListTitle => 'Forms';

  @override
  String get presetSearchHint => 'Search forms';

  @override
  String get presetNoMatch => 'No form matches.';

  @override
  String get presetEnterYourself => 'Enter sizes yourself';

  @override
  String presetNoteDpi(String dpi) {
    return 'This form also asks for $dpi DPI. ExactSize does not set DPI.';
  }

  @override
  String get presetNoteBackground =>
      'This form also has a background rule. ExactSize does not change backgrounds.';

  @override
  String get presetNoteContent =>
      'This form also has other rules for this image. ExactSize does not check them.';

  @override
  String get presetNotAffiliated =>
      'ExactSize is not affiliated with the organisations listed.';

  @override
  String get presetLoadFailed =>
      'Forms could not be loaded. You can enter sizes yourself.';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {'other': '$code'});
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'Jobs',
      'exam_admission': 'Exams and admissions',
      'visa_passport': 'Visa and passport',
      'other': 'Other',
    });
    return '$_temp0';
  }
}
