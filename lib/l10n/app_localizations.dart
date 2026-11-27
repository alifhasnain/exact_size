import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('id'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// App name. Brand name, not translated.
  ///
  /// In en, this message translates to:
  /// **'ExactSize'**
  String get appTitle;

  /// A file size in kilobytes, for example '50 KB'. amount is an already formatted number. Keep the unit after or before the number as your language writes it.
  ///
  /// In en, this message translates to:
  /// **'{amount} KB'**
  String kbAmount(String amount);

  /// A size range in kilobytes, for example '20–50 KB'. min and max are already formatted numbers.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} KB'**
  String kbRange(String min, String max);

  /// FEAT-004 PRD section 8. The target size range can't be reached. range is a size range like '20–50 KB'; achieved is the closest size, like '61.3 KB'. Both are already formatted and wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'We can\'t reach {range} for this image at this size. Closest: {achieved}.'**
  String outcomeCantReachRange(String range, String achieved);

  /// Same as outcomeCantReachRange, for a target with only a maximum size. max is a size like '50 KB'.
  ///
  /// In en, this message translates to:
  /// **'We can\'t get this image down to {max} at this size. Closest: {achieved}.'**
  String outcomeCantReachMax(String max, String achieved);

  /// Shown under outcomeCantReachRange for a PNG that is too large, only when a JPEG would fit (FR-10). The screen adds a 'switch to JPEG' button.
  ///
  /// In en, this message translates to:
  /// **'A JPEG of this image would fit.'**
  String get outcomeHintJpegWouldFit;

  /// Shown under outcomeCantReachRange for a PNG that is below the minimum size (PRD section 9).
  ///
  /// In en, this message translates to:
  /// **'PNG can\'t be made bigger. If the form accepts JPEG, try JPEG.'**
  String get outcomeHintTryJpeg;

  /// FEAT-004 AC-5.2: the device can't decode the chosen file.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t supported on this device.'**
  String get outcomeUnsupportedInput;

  /// FEAT-004 FR-18 / AC-5.3: the target is above 24 megapixels or there isn't enough free memory.
  ///
  /// In en, this message translates to:
  /// **'This image is too large to process at this size. Try smaller dimensions.'**
  String get outcomeImageTooLarge;

  /// FEAT-004 FR-18: memory ran out during compression; nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'Your phone ran out of memory. Close other apps and try again.'**
  String get outcomeOutOfMemory;

  /// FEAT-004 WRITE_FAILED: writing the output file failed, for example low storage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the file. Free up some storage and try again.'**
  String get outcomeWriteFailed;

  /// FEAT-004 CANCELLED: the user stopped the compression.
  ///
  /// In en, this message translates to:
  /// **'Compression cancelled.'**
  String get outcomeCancelled;

  /// FEAT-004 PRD section 8: the pixels did not match the target (a programming error).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong preparing your image. Please try again.'**
  String get outcomeInternalError;

  /// FEAT-004 FR-4 / PRD section 8: shown with a success when max/min is below 1.024.
  ///
  /// In en, this message translates to:
  /// **'This range is very narrow. Some portals count KB differently, so the file may still be rejected.'**
  String get noticeNarrowRange;

  /// FEAT-004 FR-8 / AC-2.2: neutral filler was added inside the JPEG to reach the minimum size.
  ///
  /// In en, this message translates to:
  /// **'Padding was added to reach the minimum size. The picture itself is unchanged.'**
  String get noticePaddingAdded;

  /// FEAT-004 FR-12 / AC-3.4: shown before export when a transparent image becomes a JPEG.
  ///
  /// In en, this message translates to:
  /// **'JPEG has no transparency, so transparent areas are now white.'**
  String get noticeTransparencyFlattened;

  /// Screen-reader announcement during compression (NFR-5). pass and total are already formatted numbers wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'Compressing, step {pass} of {total}.'**
  String announceProgress(String pass, String total);

  /// Screen-reader announcement when the file fits the target (NFR-5). size is like '48.2 KB', already formatted and wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'Done. File size: {size}.'**
  String announceSuccess(String size);

  /// FEAT-004 PRD section 8. min is a plain number like '2'; max is a size like '10,240 KB'. Both are already formatted and wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'Enter a maximum size between {min} and {max}.'**
  String targetMaxOutOfRange(String min, String max);

  /// FEAT-004 PRD section 8.
  ///
  /// In en, this message translates to:
  /// **'Minimum must be smaller than maximum.'**
  String get targetMinNotBelowMax;

  /// FEAT-004 PRD section 8. Decimals are not allowed in R1.
  ///
  /// In en, this message translates to:
  /// **'Use whole numbers of KB.'**
  String get targetWholeNumbersOnly;

  /// FEAT-004 PRD section 8: blank, negative, zero or not a number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid size in KB.'**
  String get targetInvalidNumber;

  /// FEAT-004 PRD section 8: no output format chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose JPEG or PNG.'**
  String get targetChooseJpegOrPng;

  /// A size in pixels, for example '300×80'. width and height are already formatted numbers. Keep the × sign or use your language's usual separator.
  ///
  /// In en, this message translates to:
  /// **'{width}×{height}'**
  String pixelSize(String width, String height);

  /// FEAT-002 PRD section 8. min and max are formatted numbers wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'Enter a width and height between {min} and {max} pixels.'**
  String cropTargetSideOutOfRange(String min, String max);

  /// FEAT-002 PRD section 8: target above 24 MP.
  ///
  /// In en, this message translates to:
  /// **'That size is too large for this app. Choose a smaller size.'**
  String get cropTargetTooLarge;

  /// FEAT-002 PRD section 8: IMAGE_TOO_LARGE (source above 200 MP or not enough memory to open it).
  ///
  /// In en, this message translates to:
  /// **'This photo is too large to open on this device. Choose another photo.'**
  String get cropSourceTooLarge;

  /// FEAT-002 PRD section 8: UNSUPPORTED_INPUT.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t supported on this device. Choose a JPEG or PNG photo.'**
  String get cropUnsupportedInput;

  /// FEAT-002 PRD section 8: CORRUPT_INPUT.
  ///
  /// In en, this message translates to:
  /// **'We can\'t read this file. Choose another photo.'**
  String get cropCorruptInput;

  /// FEAT-002 PRD section 8: SOURCE_UNAVAILABLE.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find this photo anymore. Please choose it again.'**
  String get cropSourceUnavailable;

  /// FEAT-002 PRD section 8: OUT_OF_MEMORY_HANDLED during the render.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large for this device. Try a smaller photo.'**
  String get cropOutOfMemory;

  /// Shown or announced when the user cancels preparing the image (CANCELLED). Wording is an assumption, to confirm with the Product Owner.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Your photo was not changed.'**
  String get cropCancelled;

  /// FEAT-002 FR-11 notice, enlargement above 1.0 times. size is a formatted pixel size like '300×80' wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'This photo is smaller than {size} px, so it will be enlarged and may look soft.'**
  String cropNoticeEnlarged(String size);

  /// FEAT-002 FR-11 confirmation dialog, enlargement above 2.0 times. factor is a formatted number like '2.5' wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'This photo is much smaller than needed ({factor}× enlargement) and may look blurry. Continue anyway?'**
  String cropConfirmEnlarge(String factor);

  /// FEAT-002 PRD section 8: animated WebP, PNG or GIF source.
  ///
  /// In en, this message translates to:
  /// **'This image is animated. Only the first frame is used.'**
  String get cropNoticeAnimated;

  /// FEAT-002 PRD section 9 extreme ratios: the frame has a minimum thickness on screen. Wording is an assumption, to confirm with the Product Owner.
  ///
  /// In en, this message translates to:
  /// **'The frame is very thin on screen. Use the move and zoom buttons for fine positioning.'**
  String get cropHintLimitedPrecision;

  /// Button: centre the crop on the photo (FR-5).
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get cropButtonCentre;

  /// Button: back to the initial crop (FR-5).
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cropButtonReset;

  /// Button and accessibility action: move the crop toward the physical left (FR-27). Always physical left, also in right-to-left languages.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get cropButtonMoveLeft;

  /// Button and accessibility action: move the crop toward the physical right (FR-27).
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get cropButtonMoveRight;

  /// Button and accessibility action: move the crop up (FR-27).
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get cropButtonMoveUp;

  /// Button and accessibility action: move the crop down (FR-27).
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get cropButtonMoveDown;

  /// Button and accessibility action (FR-5, FR-27).
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get cropButtonZoomIn;

  /// Button and accessibility action (FR-5, FR-27).
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get cropButtonZoomOut;

  /// Button: rotate the photo 90 degrees clockwise (FR-21).
  ///
  /// In en, this message translates to:
  /// **'Rotate clockwise'**
  String get cropButtonRotateClockwise;

  /// Button: rotate the photo 90 degrees counter-clockwise (FR-21).
  ///
  /// In en, this message translates to:
  /// **'Rotate counter-clockwise'**
  String get cropButtonRotateCounterclockwise;

  /// Button: prepare the image at the target size.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cropButtonContinue;

  /// Button in the enlargement confirmation dialog (FR-11).
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get cropButtonContinueAnyway;

  /// Button: go back and pick a different photo.
  ///
  /// In en, this message translates to:
  /// **'Choose another photo'**
  String get cropButtonChooseAnother;

  /// Screen-reader label of the crop area (AC-9.1). zoom is a formatted percentage like '150%' wrapped in bidi isolates. position names the part of the photo in the frame, in physical directions.
  ///
  /// In en, this message translates to:
  /// **'Crop area, zoom {zoom}, showing {position, select, centre{the centre} top{the top} bottom{the bottom} left{the left side} right{the right side} topLeft{the top-left} topRight{the top-right} bottomLeft{the bottom-left} bottomRight{the bottom-right} other{part}} of the photo'**
  String cropAreaState(String zoom, String position);

  /// Screen-reader announcement when a move stops at the photo edge (AC-9.3). Physical directions.
  ///
  /// In en, this message translates to:
  /// **'Reached the {edge, select, left{left} right{right} top{top} bottom{bottom} other{}} edge.'**
  String cropEdgeReached(String edge);

  /// Screen-reader label of a corner handle (AC-13.7). Physical corners, also in right-to-left languages.
  ///
  /// In en, this message translates to:
  /// **'Resize crop, {corner, select, topLeft{top-left} topRight{top-right} bottomLeft{bottom-left} bottomRight{bottom-right} other{}} corner'**
  String cropHandleLabel(String corner);

  /// Screen-reader announcement when the enlargement drops back to 1.0 or less (AC-9.4). Wording is an assumption, to confirm with the Product Owner.
  ///
  /// In en, this message translates to:
  /// **'The photo no longer needs enlarging.'**
  String get cropAnnounceNoEnlargement;

  /// Screen-reader announcement when the enlargement rises above 2.0 (AC-5.4, AC-9.4). factor is a formatted number wrapped in bidi isolates. Wording is an assumption, to confirm with the Product Owner.
  ///
  /// In en, this message translates to:
  /// **'Strong enlargement ({factor}×). You will be asked to confirm before continuing.'**
  String cropAnnounceStrongEnlargement(String factor);

  /// Pick screen button: opens the phone's camera app (FEAT-001 FR-1).
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get pickTakePhoto;

  /// Pick screen button: opens the system photo picker (FEAT-001 FR-1).
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get pickChooseGallery;

  /// Pick screen button (Should): opens the system file picker for images (FEAT-001 FR-21).
  ///
  /// In en, this message translates to:
  /// **'Choose from files'**
  String get pickChooseFiles;

  /// Pick screen privacy line (FEAT-016 FR-1, Register: C1). Scoped to ExactSize: never an absolute claim such as 'never leaves your phone'. Keep it short and plain.
  ///
  /// In en, this message translates to:
  /// **'Your photos are resized on your phone. ExactSize never uploads them.'**
  String get pickPrivacyNote;

  /// Progress text shown when opening a picked photo takes over 500 ms (FEAT-001 FR-13).
  ///
  /// In en, this message translates to:
  /// **'Opening your photo…'**
  String get pickOpening;

  /// Reason shown when no camera app can take a photo; the camera button is disabled (FEAT-001 FR-5).
  ///
  /// In en, this message translates to:
  /// **'No camera app was found on this phone. Choose a photo from the gallery instead.'**
  String get pickNoCamera;

  /// Neither the photo picker nor the file picker could start (FEAT-001 FR-3).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open the photo chooser. Try again or take a photo.'**
  String get pickPickerUnavailable;

  /// The camera app returned without a usable photo (FEAT-001 FR-6).
  ///
  /// In en, this message translates to:
  /// **'The camera didn\'t return a photo. Please try again.'**
  String get pickCameraNoPhoto;

  /// Too little free space to create the camera file (FEAT-001 FR-5).
  ///
  /// In en, this message translates to:
  /// **'There isn\'t enough free space on this phone to take a photo. Free some space or choose a photo from the gallery.'**
  String get pickLowSpace;

  /// Recovery of a camera photo after the app was restarted failed (Should, FEAT-001 FR-17).
  ///
  /// In en, this message translates to:
  /// **'The photo was lost while the camera was open. Please take it again.'**
  String get pickCaptureLost;

  /// The chosen or shared item is not a photo the app may open, e.g. not a content link (FEAT-001 FR-8, FR-20).
  ///
  /// In en, this message translates to:
  /// **'We can\'t open that item. Choose a photo instead.'**
  String get pickItemNotOpenable;

  /// Pick-time variant of SOURCE_UNAVAILABLE: the photo could not be read, often an online-only photo while offline (FEAT-001 FR-14).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this photo. If it is stored online, connect to the internet or choose a photo saved on this phone.'**
  String get pickSourceUnavailable;

  /// FEAT-005 target step (PRD section 8): width or height has a decimal point or comma. Pixels are whole numbers.
  ///
  /// In en, this message translates to:
  /// **'Use whole numbers of pixels.'**
  String get targetPixelsNotWhole;

  /// FEAT-005 target step: label of the width field (pixels).
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get targetLabelWidth;

  /// FEAT-005 target step: label of the height field (pixels).
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get targetLabelHeight;

  /// FEAT-005 target step: label of the optional minimum file size field (KB).
  ///
  /// In en, this message translates to:
  /// **'Minimum size'**
  String get targetLabelMin;

  /// FEAT-005 target step: label of the required maximum file size field (KB).
  ///
  /// In en, this message translates to:
  /// **'Maximum size'**
  String get targetLabelMax;

  /// FEAT-005 target step: helper text under the minimum size field; empty means no minimum.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get targetOptional;

  /// FEAT-005 target step: unit shown after the width and height fields (pixels). Use the short form your forms use.
  ///
  /// In en, this message translates to:
  /// **'px'**
  String get targetUnitPx;

  /// FEAT-005 target step: unit shown after the file size fields (kilobytes). Use the short form your forms use.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get targetUnitKb;

  /// FEAT-005 target step: label of the JPEG / PNG choice.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get targetFormatLabel;

  /// FEAT-005 target step FR-12: oriented size of the chosen photo. size is a formatted pixel size like '4000×3000' wrapped in bidi isolates.
  ///
  /// In en, this message translates to:
  /// **'Your photo: {size} px'**
  String targetPhotoSize(String size);

  /// FEAT-005 target step FR-12: button that fills width and height with the photo's own size.
  ///
  /// In en, this message translates to:
  /// **'Use photo size'**
  String get targetUsePhotoSize;

  /// FEAT-005 target step FR-13: non-blocking notice when width or height is below the small-size hint threshold.
  ///
  /// In en, this message translates to:
  /// **'Very small image. Check the size on your form.'**
  String get targetHintVerySmall;

  /// FEAT-007 button: saves the finished file to the phone's gallery (FR-6, FR-7).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get exportSave;

  /// FEAT-007 button: opens the system share menu to send the finished file to another app (FR-17).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// FEAT-007 button (FR-10): opens the system dialog to save the file in a folder the user picks. Shown after the gallery permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save'**
  String get exportSaveAs;

  /// FEAT-007 button (FR-15): opens the saved file in a photo viewer app.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get exportOpen;

  /// FEAT-007 result screen button: leaves the result and goes back to choosing a photo.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exportDone;

  /// FEAT-007 SAVED (FR-11). folder is the gallery folder path and fileName the saved file name; both are shown left to right and never translated.
  ///
  /// In en, this message translates to:
  /// **'Saved to {folder} as {fileName}.'**
  String exportSaved(String folder, String fileName);

  /// FEAT-007 SAVED after 'Choose where to save' (FR-11): only the name is known. fileName is never translated.
  ///
  /// In en, this message translates to:
  /// **'Saved as {fileName}.'**
  String exportSavedAs(String fileName);

  /// FEAT-007 ALREADY_SAVED (FR-12): Save tapped again for the same file. folder and fileName are never translated.
  ///
  /// In en, this message translates to:
  /// **'Already saved as {fileName} in {folder}.'**
  String exportAlreadySaved(String fileName, String folder);

  /// FEAT-007 ALREADY_SAVED when the earlier save went to a folder the user picked (folder unknown). fileName is never translated.
  ///
  /// In en, this message translates to:
  /// **'Already saved as {fileName}.'**
  String exportAlreadySavedAs(String fileName);

  /// FEAT-007 NO_SPACE (FR-14): the phone's storage is full.
  ///
  /// In en, this message translates to:
  /// **'There isn\'t enough free space on this phone to save the file. Free some space and try again.'**
  String get exportNoSpace;

  /// FEAT-007 SAVE_FAILED (FR-14): saving failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file. Try again, or share it instead.'**
  String get exportSaveFailed;

  /// FEAT-007 PERMISSION_DENIED (FR-9): Android 9 storage permission refused. Keep the app name ExactSize.
  ///
  /// In en, this message translates to:
  /// **'ExactSize needs the Storage permission to save to your gallery. Turn it on in Settings. You can also share the file or choose where to save it.'**
  String get exportPermissionDenied;

  /// FEAT-007 FILE_MISSING (FR-2): the finished file was removed before it could be saved or shared.
  ///
  /// In en, this message translates to:
  /// **'The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one.'**
  String get exportFileMissing;

  /// FEAT-007 SHARE_FAILED (FR-20): the system share menu could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share menu. Try again, or save the file instead.'**
  String get exportShareFailed;

  /// FEAT-007 OPEN_NO_VIEWER (FR-15): Open was tapped but no viewer app is installed.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open this file. You can still share it.'**
  String get exportNoViewer;

  /// FEAT-007 FR-26: one plain privacy line in the export area.
  ///
  /// In en, this message translates to:
  /// **'Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose.'**
  String get exportPrivacy;

  /// FEAT-007 FR-21: hint near Share; chat apps may recompress the photo, so a form upload should use the saved file.
  ///
  /// In en, this message translates to:
  /// **'Some chat apps shrink photos. For a form, save the file and choose it in the upload window.'**
  String get exportShareHint;

  /// FEAT-007 FR-23: title of the dialog shown on Back when the file was neither saved nor shared.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get exportLeaveTitle;

  /// FEAT-007 FR-23: body of the leave dialog.
  ///
  /// In en, this message translates to:
  /// **'The new file will be deleted. Your gallery photos stay as they are.'**
  String get exportLeaveBody;

  /// FEAT-007 FR-23: leave dialog button that keeps the result screen.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get exportStay;

  /// FEAT-007 FR-23: leave dialog button that deletes the file and goes back.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get exportLeave;

  /// FEAT-007 FR-24: progress label shown when saving takes longer than half a second.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get exportSaving;

  /// FEAT-006 FR-5: headline when pixel size, file size and format all match the target. Do not say 'accepted' or 'approved': the portal decides that.
  ///
  /// In en, this message translates to:
  /// **'Matches your target'**
  String get checkMatches;

  /// FEAT-006 FR-10: shown when a field does not match (should not happen). The file has already been deleted.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t match your target, so it can\'t be saved or shared. Go back and try again.'**
  String get checkMismatch;

  /// FEAT-006 FR-5: row label for width × height.
  ///
  /// In en, this message translates to:
  /// **'Size in pixels'**
  String get checkLabelPixels;

  /// FEAT-006 FR-5: row label for the file size in KB.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get checkLabelFileSize;

  /// FEAT-006 FR-5: row label for JPEG or PNG.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get checkLabelFormat;

  /// FEAT-006 FR-5: column heading, the values the user entered.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get checkTarget;

  /// FEAT-006 FR-5: column heading, the values read from the new file.
  ///
  /// In en, this message translates to:
  /// **'This file'**
  String get checkThisFile;

  /// FEAT-006 FR-5: row status when the value matches the target. Not 'accepted'.
  ///
  /// In en, this message translates to:
  /// **'Meets'**
  String get checkMeets;

  /// FEAT-006 FR-5: row status when the value does not match the target.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t meet'**
  String get checkDoesntMeet;

  /// FEAT-006 AC-1.3: target file size when only a maximum was entered. max is an already formatted size such as '100 KB', wrapped in a bidi isolate.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String checkUpToKb(String max);

  /// FEAT-006 FR-5: a pixel size. width and height are formatted numbers that arrive inside one left-to-right isolate, so keep {width} before {height}. Keep the × sign and px unit as your language writes them.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height} px'**
  String checkPixels(String width, String height);

  /// FEAT-006 FR-8: shown under the file size when the file also passes a portal that counts 1 KB as 1,024 bytes. kb is a formatted size ('1 KB'), bytes a formatted number ('1,024').
  ///
  /// In en, this message translates to:
  /// **'Also fits if your portal counts {kb} as {bytes} bytes.'**
  String checkAlsoFits1024(String kb, String bytes);

  /// FEAT-006 FR-9: plain note on what the check does not cover.
  ///
  /// In en, this message translates to:
  /// **'We check pixels, KB and format. Some forms also check the photo itself, such as the face or background.'**
  String get checkCaveat;

  /// FEAT-006 FR-14: caption under the preview image.
  ///
  /// In en, this message translates to:
  /// **'Shown scaled to fit your screen.'**
  String get previewCaption;

  /// FEAT-006 FR-16: text for screen readers. Technical values only; never describe the person or the picture. width and height arrive inside one left-to-right isolate, so keep {width} before {height}; format is JPEG or PNG.
  ///
  /// In en, this message translates to:
  /// **'Preview of your new file, {width} × {height} px, {format}.'**
  String previewAlt(String width, String height, String format);

  /// FEAT-006 FR-14: shown instead of the preview when the phone ran out of memory for it.
  ///
  /// In en, this message translates to:
  /// **'Preview isn\'t available. The check below is still correct.'**
  String get previewUnavailable;

  /// FEAT-006 AC-8.2: one row read as a sentence by TalkBack. label is a row label, target and measured are formatted values, status is 'Meets' or 'Doesn't meet'.
  ///
  /// In en, this message translates to:
  /// **'{label}: target {target}, this file {measured}, {status}.'**
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  );

  /// FEAT-016 FR-2: labelled control on the pick screen that opens the privacy explainer.
  ///
  /// In en, this message translates to:
  /// **'How your photos are handled'**
  String get privacyEntry;

  /// FEAT-016 FR-3: title of the privacy explainer screen.
  ///
  /// In en, this message translates to:
  /// **'Your photos and privacy'**
  String get privacyTitle;

  /// FEAT-016 FR-3 part (a) heading. Register: C1, C3.
  ///
  /// In en, this message translates to:
  /// **'On your phone'**
  String get privacyOnPhoneTitle;

  /// FEAT-016 FR-3 part (a). Register: C1, C3. Scoped to ExactSize; no absolute claim.
  ///
  /// In en, this message translates to:
  /// **'ExactSize resizes your photo on your phone. ExactSize never uploads your photos. You do not need an account.'**
  String get privacyOnPhone;

  /// FEAT-016 FR-3 part (b) heading. Register: C2.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get privacyOfflineTitle;

  /// FEAT-016 FR-3 part (b). Register: C2. The second sentence is the online-album exception (AC-3.2).
  ///
  /// In en, this message translates to:
  /// **'Every step works without an internet connection. A photo stored only online must first be downloaded by your gallery app.'**
  String get privacyOffline;

  /// FEAT-016 FR-3 part (c) heading. Register: C4, C5.
  ///
  /// In en, this message translates to:
  /// **'What ExactSize keeps'**
  String get privacyKeptTitle;

  /// FEAT-016 FR-3 part (c). Register: C4, C5.
  ///
  /// In en, this message translates to:
  /// **'ExactSize keeps temporary copies only while you work. They are deleted when you finish, or the next time the app starts. Logs hold only short status codes, never your photo.'**
  String get privacyKept;

  /// FEAT-016 FR-3 part (d) heading. Register: C8.
  ///
  /// In en, this message translates to:
  /// **'When you save or share'**
  String get privacyCopiesTitle;

  /// FEAT-016 FR-3 part (d). Register: C8. Must agree with exportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Save puts a copy in your gallery or a folder you pick. Share gives a copy to the app you choose. From then on, that copy is yours, and ExactSize does not control it.'**
  String get privacyCopies;

  /// FEAT-016 FR-3 part (e) heading. Register: C9.
  ///
  /// In en, this message translates to:
  /// **'Other apps on your phone'**
  String get privacyOutsideTitle;

  /// FEAT-016 FR-3 part (e). Register: C9. Names what ExactSize cannot control.
  ///
  /// In en, this message translates to:
  /// **'Your gallery, keyboard and the apps you share with follow their own privacy rules. Some of them may back up or send files.'**
  String get privacyOutside;

  /// FEAT-016 FR-3 part (f) heading. Register: C10.
  ///
  /// In en, this message translates to:
  /// **'What ExactSize reads'**
  String get privacyReadsTitle;

  /// FEAT-016 FR-3 part (f). Register: C10.
  ///
  /// In en, this message translates to:
  /// **'ExactSize opens only the photo you choose. It does not browse your gallery or your files.'**
  String get privacyReads;

  /// FEAT-011 FR-5, FR-13: label of the target-step row that opens the form list, shown while no preset is applied.
  ///
  /// In en, this message translates to:
  /// **'Choose a form'**
  String get presetChooseForm;

  /// FEAT-011 FR-13: target-step row while a preset is applied. form is the form name as published (data, already in a bidi isolate; never translate it); kind is presetKindPhoto or presetKindSignature.
  ///
  /// In en, this message translates to:
  /// **'{form} · {kind}'**
  String presetApplied(String form, String kind);

  /// FEAT-011 FR-3: kind of upload a spec row is for: the applicant's photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get presetKindPhoto;

  /// FEAT-011 FR-3: kind of upload a spec row is for: the applicant's signature image.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get presetKindSignature;

  /// FEAT-011 FR-6: summary of a spec row with a minimum and maximum file size. pixels is checkPixels, size is kbRange, format is JPEG or PNG; each arrives already in a bidi isolate.
  ///
  /// In en, this message translates to:
  /// **'{pixels} · {size} · {format}'**
  String presetSpecRange(String pixels, String size, String format);

  /// FEAT-011 FR-6: summary of a spec row with only a maximum file size. pixels is checkPixels, max is kbAmount, format is JPEG or PNG; each arrives already in a bidi isolate.
  ///
  /// In en, this message translates to:
  /// **'{pixels} · up to {max} · {format}'**
  String presetSpecUpTo(String pixels, String max, String format);

  /// FEAT-011 FR-6: title of the form list screen.
  ///
  /// In en, this message translates to:
  /// **'Forms'**
  String get presetListTitle;

  /// FEAT-011 FR-8: hint in the search field of the form list.
  ///
  /// In en, this message translates to:
  /// **'Search forms'**
  String get presetSearchHint;

  /// FEAT-011 FR-8: empty state when the search matches no form.
  ///
  /// In en, this message translates to:
  /// **'No form matches.'**
  String get presetNoMatch;

  /// FEAT-011 FR-8: button under the empty state; it closes the list and returns to the manual size fields.
  ///
  /// In en, this message translates to:
  /// **'Enter sizes yourself'**
  String get presetEnterYourself;

  /// FEAT-011 FR-14: note on a spec whose form also states a DPI. dpi is an already formatted whole number in a bidi isolate. Keep DPI as is.
  ///
  /// In en, this message translates to:
  /// **'This form also asks for {dpi} DPI. ExactSize does not set DPI.'**
  String presetNoteDpi(String dpi);

  /// FEAT-011 FR-14: note on a spec whose form also states a background rule. Never name a colour.
  ///
  /// In en, this message translates to:
  /// **'This form also has a background rule. ExactSize does not change backgrounds.'**
  String get presetNoteBackground;

  /// FEAT-011 FR-14: note on a spec whose form also has content rules such as face position.
  ///
  /// In en, this message translates to:
  /// **'This form also has other photo rules. ExactSize does not check them.'**
  String get presetNoteContent;

  /// FEAT-011 FR-15: fixed footer line at the end of the form list. Never use words like official, approved or guaranteed.
  ///
  /// In en, this message translates to:
  /// **'ExactSize is not affiliated with the organisations listed.'**
  String get presetNotAffiliated;

  /// FEAT-011 FR-16, AC-6.1: shown instead of the Choose a form row when the bundled form list cannot be read. Do not mention the internet or a connection: nothing is downloaded.
  ///
  /// In en, this message translates to:
  /// **'Forms could not be loaded. You can enter the sizes yourself.'**
  String get presetLoadFailed;

  /// FEAT-011 FR-6: country section heading in the form list. code is an ISO 3166-1 country code; each case gives the country name. Cases are added with the form data; other shows the code.
  ///
  /// In en, this message translates to:
  /// **'{code, select, other{{code}}}'**
  String presetCountry(String code);

  /// FEAT-011 FR-2: category of a form, shown in the form list and searched. Translate each case; keep the case names.
  ///
  /// In en, this message translates to:
  /// **'{category, select, job{Jobs} exam_admission{Exams and admissions} visa_passport{Visa and passport} other{Other}}'**
  String presetCategory(String category);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'hi',
    'id',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
