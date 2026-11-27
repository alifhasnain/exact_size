// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

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
    return 'इस पिक्सेल माप पर हम इस इमेज को $range तक नहीं ला पा रहे हैं। सबसे नज़दीकी: $achieved।';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'इस पिक्सेल माप पर हम इस इमेज को $max तक छोटा नहीं कर पा रहे हैं। सबसे नज़दीकी: $achieved।';
  }

  @override
  String get outcomeHintJpegWouldFit =>
      'JPEG में यह इमेज तय साइज़ में आ जाएगी।';

  @override
  String get outcomeHintTryJpeg =>
      'PNG फ़ाइल का साइज़ बढ़ाया नहीं जा सकता। अगर फ़ॉर्म JPEG स्वीकार करता है, तो JPEG आज़माएँ।';

  @override
  String get outcomeUnsupportedInput =>
      'इस डिवाइस पर यह फ़ाइल प्रकार समर्थित नहीं है।';

  @override
  String get outcomeImageTooLarge =>
      'इस पिक्सेल माप पर यह इमेज प्रोसेस करने के लिए बहुत बड़ी है। छोटा माप आज़माएँ।';

  @override
  String get outcomeOutOfMemory =>
      'आपके फ़ोन की मेमोरी कम पड़ गई। दूसरे ऐप बंद करें और फिर से कोशिश करें।';

  @override
  String get outcomeWriteFailed =>
      'हम फ़ाइल सेव नहीं कर पाए। कुछ स्टोरेज खाली करें और फिर से कोशिश करें।';

  @override
  String get outcomeCancelled => 'कंप्रेशन रद्द किया गया।';

  @override
  String get outcomeInternalError =>
      'आपकी इमेज तैयार करते समय कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।';

  @override
  String get noticeNarrowRange =>
      'यह साइज़ रेंज बहुत छोटी है। कुछ पोर्टल KB को अलग तरीके से गिनते हैं, इसलिए फ़ाइल फिर भी अस्वीकार हो सकती है।';

  @override
  String get noticePaddingAdded =>
      'न्यूनतम साइज़ तक पहुँचने के लिए फ़ाइल में पैडिंग जोड़ी गई। इमेज में कोई बदलाव नहीं हुआ है।';

  @override
  String get noticeTransparencyFlattened =>
      'JPEG में पारदर्शिता नहीं होती, इसलिए पारदर्शी हिस्से सफ़ेद कर दिए गए हैं।';

  @override
  String announceProgress(String pass, String total) {
    return 'कंप्रेस हो रहा है, $total में से चरण $pass।';
  }

  @override
  String announceSuccess(String size) {
    return 'हो गया। फ़ाइल साइज़: $size।';
  }

  @override
  String targetMaxOutOfRange(String min, String max) {
    return '$min और $max के बीच अधिकतम साइज़ डालें।';
  }

  @override
  String get targetMinNotBelowMax => 'न्यूनतम, अधिकतम से कम होना चाहिए।';

  @override
  String get targetWholeNumbersOnly => 'KB में बिना दशमलव वाली संख्या डालें।';

  @override
  String get targetInvalidNumber => 'KB में मान्य साइज़ डालें।';

  @override
  String get targetChooseJpegOrPng => 'JPEG या PNG चुनें।';

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'चौड़ाई और ऊँचाई $min और $max पिक्सेल के बीच डालें।';
  }

  @override
  String get cropTargetTooLarge =>
      'यह माप इस ऐप के लिए बहुत बड़ा है। छोटा माप चुनें।';

  @override
  String get cropSourceTooLarge =>
      'यह फ़ोटो इस डिवाइस पर खोलने के लिए बहुत बड़ी है। दूसरी फ़ोटो चुनें।';

  @override
  String get cropUnsupportedInput =>
      'इस डिवाइस पर यह फ़ाइल प्रकार समर्थित नहीं है। JPEG या PNG फ़ोटो चुनें।';

  @override
  String get cropCorruptInput =>
      'हम यह फ़ाइल नहीं पढ़ पा रहे हैं। दूसरी फ़ोटो चुनें।';

  @override
  String get cropSourceUnavailable =>
      'यह फ़ोटो अब नहीं मिल रही है। कृपया इसे फिर से चुनें।';

  @override
  String get cropOutOfMemory =>
      'यह फ़ोटो इस डिवाइस के लिए बहुत बड़ी है। छोटी फ़ोटो आज़माएँ।';

  @override
  String get cropCancelled =>
      'प्रक्रिया रद्द की गई। आपकी फ़ोटो में कोई बदलाव नहीं हुआ।';

  @override
  String cropNoticeEnlarged(String size) {
    return 'यह फ़ोटो $size पिक्सेल से छोटी है, इसलिए इसे बड़ा किया जाएगा और यह थोड़ी धुंधली दिख सकती है।';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'यह फ़ोटो ज़रूरत से बहुत छोटी है (इसे $factor× बड़ा करना पड़ेगा) और धुंधली दिख सकती है। फिर भी जारी रखें?';
  }

  @override
  String get cropNoticeAnimated =>
      'यह इमेज एनिमेटेड है। केवल पहला फ़्रेम इस्तेमाल होगा।';

  @override
  String get cropHintLimitedPrecision =>
      'स्क्रीन पर क्रॉप क्षेत्र बहुत पतला है। सटीक जगह के लिए खिसकाने और ज़ूम वाले बटन इस्तेमाल करें।';

  @override
  String get cropButtonCentre => 'बीच में लाएँ';

  @override
  String get cropButtonReset => 'रीसेट करें';

  @override
  String get cropButtonMoveLeft => 'बाएँ खिसकाएँ';

  @override
  String get cropButtonMoveRight => 'दाएँ खिसकाएँ';

  @override
  String get cropButtonMoveUp => 'ऊपर खिसकाएँ';

  @override
  String get cropButtonMoveDown => 'नीचे खिसकाएँ';

  @override
  String get cropButtonZoomIn => 'ज़ूम इन करें';

  @override
  String get cropButtonZoomOut => 'ज़ूम आउट करें';

  @override
  String get cropButtonRotateClockwise => 'घड़ी की दिशा में घुमाएँ';

  @override
  String get cropButtonRotateCounterclockwise =>
      'घड़ी की उल्टी दिशा में घुमाएँ';

  @override
  String get cropButtonContinue => 'जारी रखें';

  @override
  String get cropButtonContinueAnyway => 'फिर भी जारी रखें';

  @override
  String get cropButtonChooseAnother => 'दूसरी फ़ोटो चुनें';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'बीच का हिस्सा',
      'top': 'ऊपरी हिस्सा',
      'bottom': 'निचला हिस्सा',
      'left': 'बायाँ हिस्सा',
      'right': 'दायाँ हिस्सा',
      'topLeft': 'ऊपरी बायाँ कोना',
      'topRight': 'ऊपरी दायाँ कोना',
      'bottomLeft': 'निचला बायाँ कोना',
      'bottomRight': 'निचला दायाँ कोना',
      'other': 'एक हिस्सा',
    });
    return 'क्रॉप क्षेत्र, ज़ूम $zoom, फ़ोटो का $_temp0 दिख रहा है';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'बाएँ',
      'right': 'दाएँ',
      'top': 'ऊपरी',
      'bottom': 'निचले',
      'other': '',
    });
    return 'क्रॉप $_temp0 किनारे तक पहुँच गया।';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'ऊपरी बायाँ',
      'topRight': 'ऊपरी दायाँ',
      'bottomLeft': 'निचला बायाँ',
      'bottomRight': 'निचला दायाँ',
      'other': '',
    });
    return 'क्रॉप का माप बदलें, $_temp0 कोना';
  }

  @override
  String get cropAnnounceNoEnlargement =>
      'अब फ़ोटो को बड़ा करने की ज़रूरत नहीं है।';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'बहुत ज़्यादा बड़ा करना होगा ($factor×)। जारी रखने से पहले हम आपसे पूछेंगे।';
  }

  @override
  String get pickTakePhoto => 'फ़ोटो लें';

  @override
  String get pickChooseGallery => 'गैलरी से चुनें';

  @override
  String get pickChooseFiles => 'फ़ाइलों से चुनें';

  @override
  String get pickPrivacyNote =>
      'आपकी फ़ोटो का साइज़ आपके फ़ोन पर ही बदला जाता है। ExactSize आपकी फ़ोटो कभी अपलोड नहीं करता।';

  @override
  String get pickOpening => 'आपकी फ़ोटो खुल रही है…';

  @override
  String get pickNoCamera =>
      'इस फ़ोन पर कोई कैमरा ऐप नहीं मिला। इसकी जगह गैलरी से फ़ोटो चुनें।';

  @override
  String get pickPickerUnavailable =>
      'हम फ़ोटो चुनने की स्क्रीन नहीं खोल पाए। फिर से कोशिश करें या फ़ोटो लें।';

  @override
  String get pickCameraNoPhoto =>
      'कैमरे से कोई फ़ोटो नहीं मिली। कृपया फिर से कोशिश करें।';

  @override
  String get pickLowSpace =>
      'फ़ोटो लेने के लिए इस फ़ोन में पर्याप्त खाली जगह नहीं है। कुछ जगह खाली करें या गैलरी से फ़ोटो चुनें।';

  @override
  String get pickCaptureLost =>
      'कैमरा खुला रहने के दौरान फ़ोटो खो गई। कृपया फ़ोटो फिर से लें।';

  @override
  String get pickItemNotOpenable =>
      'हम यह आइटम नहीं खोल सकते। इसकी जगह कोई फ़ोटो चुनें।';

  @override
  String get pickSourceUnavailable =>
      'हम यह फ़ोटो नहीं खोल पाए। अगर यह क्लाउड में सेव है, तो इंटरनेट से कनेक्ट करें या इस फ़ोन में सेव की गई फ़ोटो चुनें।';

  @override
  String get targetPixelsNotWhole =>
      'पिक्सेल में बिना दशमलव वाली संख्या डालें।';

  @override
  String get targetLabelWidth => 'चौड़ाई';

  @override
  String get targetLabelHeight => 'ऊँचाई';

  @override
  String get targetLabelMin => 'न्यूनतम साइज़';

  @override
  String get targetLabelMax => 'अधिकतम साइज़';

  @override
  String get targetOptional => 'वैकल्पिक';

  @override
  String get targetUnitPx => 'पिक्सेल';

  @override
  String get targetUnitKb => 'KB';

  @override
  String get targetFormatLabel => 'फ़ॉर्मेट';

  @override
  String targetPhotoSize(String size) {
    return 'आपकी फ़ोटो: $size पिक्सेल';
  }

  @override
  String get targetUsePhotoSize => 'फ़ोटो का माप इस्तेमाल करें';

  @override
  String get targetHintVerySmall =>
      'इमेज बहुत छोटी बनेगी। अपने आवेदन फ़ॉर्म में दिया गया माप जाँचें।';

  @override
  String get exportSave => 'सेव करें';

  @override
  String get exportShare => 'शेयर करें';

  @override
  String get exportSaveAs => 'सेव करने की जगह चुनें';

  @override
  String get exportOpen => 'खोलें';

  @override
  String get exportDone => 'हो गया';

  @override
  String exportSaved(String folder, String fileName) {
    return 'फ़ाइल $folder में $fileName नाम से सेव हो गई।';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'फ़ाइल $fileName नाम से सेव हो गई।';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'यह फ़ाइल पहले ही $folder में $fileName नाम से सेव हो चुकी है।';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'यह फ़ाइल पहले ही $fileName नाम से सेव हो चुकी है।';
  }

  @override
  String get exportNoSpace =>
      'फ़ाइल सेव करने के लिए इस फ़ोन में पर्याप्त खाली जगह नहीं है। थोड़ी जगह खाली करें और फिर से कोशिश करें।';

  @override
  String get exportSaveFailed =>
      'फ़ाइल सेव नहीं हो सकी। फिर से कोशिश करें या इसके बजाय फ़ाइल शेयर करें।';

  @override
  String get exportPermissionDenied =>
      'गैलरी में सेव करने के लिए ExactSize को स्टोरेज की अनुमति चाहिए। सेटिंग में जाकर अनुमति दें। आप फ़ाइल शेयर भी कर सकते हैं या सेव करने की जगह चुन सकते हैं।';

  @override
  String get exportFileMissing =>
      'नई फ़ाइल अब नहीं मिल रही है। आपकी गैलरी की फ़ोटो में कोई बदलाव नहीं हुआ है। नई फ़ाइल बनाने के लिए फ़ोटो फिर से चुनें।';

  @override
  String get exportShareFailed =>
      'शेयर मेन्यू नहीं खुल सका। फिर से कोशिश करें या इसके बजाय फ़ाइल सेव करें।';

  @override
  String get exportNoViewer =>
      'इस फ़ोन पर ऐसा कोई ऐप नहीं है जो यह फ़ाइल खोल सके। आप फिर भी इसे शेयर कर सकते हैं।';

  @override
  String get exportPrivacy =>
      'सेव करने पर एक कॉपी आपकी गैलरी में या आपके चुने हुए फ़ोल्डर में जाती है। शेयर करने पर एक कॉपी आपके चुने हुए ऐप को मिलती है।';

  @override
  String get exportShareHint =>
      'कुछ चैट ऐप फ़ोटो को छोटा कर देते हैं। आवेदन फ़ॉर्म के लिए फ़ाइल सेव करें और अपलोड करते समय वही फ़ाइल चुनें।';

  @override
  String get exportLeaveTitle => 'सेव किए बिना वापस जाएँ?';

  @override
  String get exportLeaveBody =>
      'नई फ़ाइल हटा दी जाएगी। आपकी गैलरी की फ़ोटो में कोई बदलाव नहीं होगा।';

  @override
  String get exportStay => 'यहीं रहें';

  @override
  String get exportLeave => 'वापस जाएँ';

  @override
  String get exportSaving => 'सेव हो रही है…';

  @override
  String get checkMatches => 'फ़ाइल आपकी ज़रूरत के मुताबिक है';

  @override
  String get checkMismatch =>
      'यह फ़ाइल आपकी ज़रूरत के मुताबिक नहीं है, इसलिए इसे सेव या शेयर नहीं किया जा सकता। वापस जाएँ और फिर से कोशिश करें।';

  @override
  String get checkLabelPixels => 'पिक्सेल में माप';

  @override
  String get checkLabelFileSize => 'फ़ाइल साइज़';

  @override
  String get checkLabelFormat => 'फ़ॉर्मेट';

  @override
  String get checkTarget => 'ज़रूरी';

  @override
  String get checkThisFile => 'यह फ़ाइल';

  @override
  String get checkMeets => 'ज़रूरत के मुताबिक';

  @override
  String get checkDoesntMeet => 'ज़रूरत के मुताबिक नहीं';

  @override
  String checkUpToKb(String max) {
    return '$max तक';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height पिक्सेल';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'अगर आपका पोर्टल $kb को $bytes बाइट मानता है, तो भी फ़ाइल ज़रूरत के मुताबिक रहेगी।';
  }

  @override
  String get checkCaveat =>
      'हम पिक्सेल, KB और फ़ॉर्मेट जाँचते हैं। कुछ फ़ॉर्म फ़ोटो में चेहरा या बैकग्राउंड जैसी चीज़ें भी जाँचते हैं।';

  @override
  String get previewCaption =>
      'प्रीव्यू को आपकी स्क्रीन के अनुसार आकार बदलकर दिखाया गया है।';

  @override
  String previewAlt(String width, String height, String format) {
    return 'आपकी नई फ़ाइल का प्रीव्यू, $width × $height पिक्सेल, $format।';
  }

  @override
  String get previewUnavailable =>
      'प्रीव्यू उपलब्ध नहीं है। नीचे दी गई जाँच फिर भी मान्य है।';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: ज़रूरी $target, यह फ़ाइल $measured, $status।';
  }

  @override
  String get privacyEntry => 'आपकी फ़ोटो के साथ क्या होता है';

  @override
  String get privacyTitle => 'आपकी फ़ोटो और निजता';

  @override
  String get privacyOnPhoneTitle => 'आपके फ़ोन पर';

  @override
  String get privacyOnPhone =>
      'ExactSize आपकी फ़ोटो का साइज़ आपके फ़ोन पर ही बदलता है। ExactSize आपकी फ़ोटो कभी अपलोड नहीं करता। आपको कोई अकाउंट नहीं बनाना पड़ता।';

  @override
  String get privacyOfflineTitle => 'बिना इंटरनेट के चलता है';

  @override
  String get privacyOffline =>
      'हर स्टेप बिना इंटरनेट कनेक्शन के काम करता है। अगर कोई फ़ोटो सिर्फ़ क्लाउड में सेव है, तो पहले आपके गैलरी ऐप को उसे डाउनलोड करना होगा।';

  @override
  String get privacyKeptTitle => 'ExactSize क्या रखता है';

  @override
  String get privacyKept =>
      'ExactSize अस्थायी कॉपियाँ सिर्फ़ तब तक रखता है, जब तक आप काम करते हैं। काम पूरा होने पर या अगली बार ऐप खुलने पर वे हटा दी जाती हैं। ExactSize के लॉग में सिर्फ़ छोटे स्टेटस कोड होते हैं, आपकी फ़ोटो कभी नहीं।';

  @override
  String get privacyCopiesTitle => 'सेव या शेयर करने पर';

  @override
  String get privacyCopies =>
      'सेव करने पर एक कॉपी आपकी गैलरी में या आपके चुने हुए फ़ोल्डर में जाती है। शेयर करने पर एक कॉपी आपके चुने हुए ऐप को मिलती है। उसके बाद वह कॉपी आपकी है, और ExactSize का उस पर कोई नियंत्रण नहीं रहता।';

  @override
  String get privacyOutsideTitle => 'आपके फ़ोन के दूसरे ऐप';

  @override
  String get privacyOutside =>
      'आपकी गैलरी, आपका कीबोर्ड और जिन ऐप के साथ आप शेयर करते हैं, वे अपनी निजता नीतियों के मुताबिक काम करते हैं। उनमें से कुछ फ़ाइलों का बैकअप ले सकते हैं या उन्हें कहीं भेज सकते हैं।';

  @override
  String get privacyReadsTitle => 'ExactSize क्या देखता है';

  @override
  String get privacyReads =>
      'ExactSize सिर्फ़ वही फ़ोटो खोलता है, जो आप चुनते हैं। यह आपकी गैलरी या बाकी फ़ाइलें नहीं देखता।';

  @override
  String get presetChooseForm => 'फ़ॉर्म चुनें';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'फ़ोटो';

  @override
  String get presetKindSignature => 'हस्ताक्षर';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · $max तक · $format';
  }

  @override
  String get presetListTitle => 'फ़ॉर्म';

  @override
  String get presetSearchHint => 'फ़ॉर्म खोजें';

  @override
  String get presetNoMatch => 'कोई फ़ॉर्म नहीं मिला।';

  @override
  String get presetEnterYourself => 'चौड़ाई, ऊँचाई और फ़ाइल साइज़ ख़ुद डालें';

  @override
  String presetNoteDpi(String dpi) {
    return 'यह फ़ॉर्म $dpi DPI भी माँगता है। ExactSize DPI सेट नहीं करता।';
  }

  @override
  String get presetNoteBackground =>
      'इस फ़ॉर्म में बैकग्राउंड के लिए भी एक नियम है। ExactSize बैकग्राउंड नहीं बदलता।';

  @override
  String get presetNoteContent =>
      'इस फ़ॉर्म में इस इमेज के लिए अन्य नियम भी हैं। ExactSize उन्हें नहीं जाँचता।';

  @override
  String get presetNotAffiliated =>
      'ExactSize का इस सूची की संस्थाओं से कोई संबंध नहीं है।';

  @override
  String get presetLoadFailed =>
      'फ़ॉर्म की सूची नहीं खुल सकी। आप चौड़ाई, ऊँचाई और फ़ाइल साइज़ ख़ुद डाल सकते हैं।';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'BD': 'बांग्लादेश',
      'FR': 'फ़्रांस',
      'IN': 'भारत',
      'MX': 'मेक्सिको',
      'PK': 'पाकिस्तान',
      'SG': 'सिंगापुर',
      'US': 'अमेरिका',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'नौकरी',
      'exam_admission': 'परीक्षा और दाख़िला',
      'visa_passport': 'वीज़ा और पासपोर्ट',
      'other': 'अन्य',
    });
    return '$_temp0';
  }

  @override
  String get presetAnyPixelSize => 'पिक्सेल माप नहीं बताया गया';

  @override
  String get presetKbOnlyNote =>
      'यह फ़ॉर्म पिक्सेल माप नहीं बताता। चौड़ाई और ऊँचाई डालें या फ़ोटो का माप इस्तेमाल करें।';
}
