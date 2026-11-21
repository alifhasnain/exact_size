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

  /// Pick screen privacy line (Should, FEAT-001 FR-22). Final copy is owned by FEAT-016; keep it short and plain.
  ///
  /// In en, this message translates to:
  /// **'Your photos stay on your phone and are never uploaded.'**
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
