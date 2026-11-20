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
