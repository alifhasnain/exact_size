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
      'आपकी फ़ोटो आपके फ़ोन पर ही रहती हैं और कभी इंटरनेट पर अपलोड नहीं होतीं।';

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
  String exportReady(String width, String height, String size, String format) {
    return 'Ready: $width × $height px, $size, $format';
  }

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
}
