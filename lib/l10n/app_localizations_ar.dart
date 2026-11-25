// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
    return 'تعذّر الوصول إلى $range لهذه الصورة بهذه الأبعاد. أقرب نتيجة: $achieved.';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'تعذّر تقليل حجم ملف هذه الصورة إلى $max بهذه الأبعاد. أقرب نتيجة: $achieved.';
  }

  @override
  String get outcomeHintJpegWouldFit =>
      'بصيغة JPEG، ستناسب هذه الصورة الحجم المطلوب.';

  @override
  String get outcomeHintTryJpeg =>
      'لا يمكن زيادة حجم ملف PNG. إذا كان النموذج الإلكتروني يقبل JPEG، فجرّب JPEG.';

  @override
  String get outcomeUnsupportedInput =>
      'نوع الملف هذا غير مدعوم على هذا الجهاز.';

  @override
  String get outcomeImageTooLarge =>
      'هذه الصورة كبيرة جدًا لمعالجتها بهذه الأبعاد. جرّب أبعادًا أصغر.';

  @override
  String get outcomeOutOfMemory =>
      'نفدت ذاكرة هاتفك. أغلق التطبيقات الأخرى وحاول مرة أخرى.';

  @override
  String get outcomeWriteFailed =>
      'تعذّر حفظ الملف. حرّر بعض مساحة التخزين وحاول مرة أخرى.';

  @override
  String get outcomeCancelled => 'أُلغي ضغط الصورة.';

  @override
  String get outcomeInternalError =>
      'حدث خطأ أثناء تجهيز صورتك. يُرجى المحاولة مرة أخرى.';

  @override
  String get noticeNarrowRange =>
      'نطاق الحجم هذا ضيق جدًا. بعض البوابات الإلكترونية تحسب KB بطريقة مختلفة، لذا قد يُرفض الملف رغم ذلك.';

  @override
  String get noticePaddingAdded =>
      'أُضيفت بيانات حشو إلى الملف للوصول إلى الحد الأدنى للحجم. لم تتغير الصورة نفسها.';

  @override
  String get noticeTransparencyFlattened =>
      'لا يدعم JPEG الشفافية، لذا أصبحت المناطق الشفافة بيضاء.';

  @override
  String announceProgress(String pass, String total) {
    return 'جارٍ ضغط الصورة، الخطوة $pass من $total.';
  }

  @override
  String announceSuccess(String size) {
    return 'تم. حجم الملف: $size.';
  }

  @override
  String targetMaxOutOfRange(String min, String max) {
    return 'أدخل حدًا أقصى للحجم بين $min و$max.';
  }

  @override
  String get targetMinNotBelowMax =>
      'يجب أن يكون الحد الأدنى أصغر من الحد الأقصى.';

  @override
  String get targetWholeNumbersOnly => 'أدخل عددًا صحيحًا بوحدة KB.';

  @override
  String get targetInvalidNumber => 'أدخل حجمًا صالحًا بوحدة KB.';

  @override
  String get targetChooseJpegOrPng => 'اختر JPEG أو PNG.';

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'أدخل عرضًا وارتفاعًا بين $min و$max بكسل.';
  }

  @override
  String get cropTargetTooLarge =>
      'هذه الأبعاد كبيرة جدًا على هذا التطبيق. اختر أبعادًا أصغر.';

  @override
  String get cropSourceTooLarge =>
      'هذه الصورة كبيرة جدًا لفتحها على هذا الجهاز. اختر صورة أخرى.';

  @override
  String get cropUnsupportedInput =>
      'نوع الملف هذا غير مدعوم على هذا الجهاز. اختر صورة بصيغة JPEG أو PNG.';

  @override
  String get cropCorruptInput => 'تعذّرت قراءة هذا الملف. اختر صورة أخرى.';

  @override
  String get cropSourceUnavailable =>
      'تعذّر العثور على هذه الصورة. يُرجى اختيارها مرة أخرى.';

  @override
  String get cropOutOfMemory =>
      'هذه الصورة كبيرة جدًا على هذا الجهاز. جرّب صورة أصغر.';

  @override
  String get cropCancelled => 'أُلغيت العملية. لم تتغير صورتك.';

  @override
  String cropNoticeEnlarged(String size) {
    return 'هذه الصورة أصغر من $size بكسل، لذا ستُكبَّر وقد تبدو أقل وضوحًا.';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'هذه الصورة أصغر بكثير من الحجم المطلوب (تكبير $factor×) وقد تبدو ضبابية. هل تريد المتابعة على أي حال؟';
  }

  @override
  String get cropNoticeAnimated =>
      'هذه الصورة متحركة. يُستخدم الإطار الأول فقط.';

  @override
  String get cropHintLimitedPrecision =>
      'منطقة الاقتصاص ضيقة جدًا على الشاشة. استخدم أزرار التحريك والتقريب لضبط الموضع بدقة.';

  @override
  String get cropButtonCentre => 'توسيط';

  @override
  String get cropButtonReset => 'إعادة الضبط';

  @override
  String get cropButtonMoveLeft => 'تحريك لليسار';

  @override
  String get cropButtonMoveRight => 'تحريك لليمين';

  @override
  String get cropButtonMoveUp => 'تحريك لأعلى';

  @override
  String get cropButtonMoveDown => 'تحريك لأسفل';

  @override
  String get cropButtonZoomIn => 'تقريب';

  @override
  String get cropButtonZoomOut => 'تبعيد';

  @override
  String get cropButtonRotateClockwise => 'تدوير باتجاه عقارب الساعة';

  @override
  String get cropButtonRotateCounterclockwise => 'تدوير عكس اتجاه عقارب الساعة';

  @override
  String get cropButtonContinue => 'متابعة';

  @override
  String get cropButtonContinueAnyway => 'متابعة على أي حال';

  @override
  String get cropButtonChooseAnother => 'اختيار صورة أخرى';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'الجزء الأوسط',
      'top': 'الجزء العلوي',
      'bottom': 'الجزء السفلي',
      'left': 'الجانب الأيسر',
      'right': 'الجانب الأيمن',
      'topLeft': 'الزاوية العلوية اليسرى',
      'topRight': 'الزاوية العلوية اليمنى',
      'bottomLeft': 'الزاوية السفلية اليسرى',
      'bottomRight': 'الزاوية السفلية اليمنى',
      'other': 'جزءًا',
    });
    return 'منطقة الاقتصاص، مستوى التقريب $zoom، تعرض $_temp0 من الصورة';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'اليسرى',
      'right': 'اليمنى',
      'top': 'العلوية',
      'bottom': 'السفلية',
      'other': '',
    });
    return 'بلغت منطقة الاقتصاص الحافة $_temp0.';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'العلوية اليسرى',
      'topRight': 'العلوية اليمنى',
      'bottomLeft': 'السفلية اليسرى',
      'bottomRight': 'السفلية اليمنى',
      'other': '',
    });
    return 'تغيير حجم منطقة الاقتصاص، الزاوية $_temp0';
  }

  @override
  String get cropAnnounceNoEnlargement => 'لم تعد الصورة بحاجة إلى تكبير.';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'تكبير مفرط ($factor×). سيُطلب منك التأكيد قبل المتابعة.';
  }

  @override
  String get pickTakePhoto => 'التقاط صورة';

  @override
  String get pickChooseGallery => 'الاختيار من المعرض';

  @override
  String get pickChooseFiles => 'الاختيار من الملفات';

  @override
  String get pickPrivacyNote =>
      'تبقى صورك على هاتفك ولا تُرفع إلى الإنترنت أبدًا.';

  @override
  String get pickOpening => 'جارٍ فتح صورتك…';

  @override
  String get pickNoCamera =>
      'لم يُعثر على تطبيق كاميرا على هذا الهاتف. اختر صورة من المعرض بدلًا من ذلك.';

  @override
  String get pickPickerUnavailable =>
      'تعذّر فتح أداة اختيار الصور. حاول مرة أخرى أو التقط صورة.';

  @override
  String get pickCameraNoPhoto =>
      'لم تلتقط الكاميرا أي صورة. يُرجى المحاولة مرة أخرى.';

  @override
  String get pickLowSpace =>
      'لا توجد مساحة خالية كافية على هذا الهاتف لالتقاط صورة. حرّر بعض المساحة أو اختر صورة من المعرض.';

  @override
  String get pickCaptureLost =>
      'فُقدت الصورة بينما كانت الكاميرا مفتوحة. يُرجى التقاطها مرة أخرى.';

  @override
  String get pickItemNotOpenable =>
      'تعذّر فتح هذا العنصر. اختر صورة بدلًا من ذلك.';

  @override
  String get pickSourceUnavailable =>
      'تعذّر فتح هذه الصورة. إذا كانت محفوظة في التخزين السحابي، فاتصل بالإنترنت أو اختر صورة محفوظة على هذا الهاتف.';

  @override
  String get targetPixelsNotWhole => 'أدخل عددًا صحيحًا بوحدة البكسل.';

  @override
  String get targetLabelWidth => 'العرض';

  @override
  String get targetLabelHeight => 'الارتفاع';

  @override
  String get targetLabelMin => 'الحد الأدنى للحجم';

  @override
  String get targetLabelMax => 'الحد الأقصى للحجم';

  @override
  String get targetOptional => 'اختياري';

  @override
  String get targetUnitPx => 'بكسل';

  @override
  String get targetUnitKb => 'KB';

  @override
  String get targetFormatLabel => 'صيغة الملف';

  @override
  String targetPhotoSize(String size) {
    return 'صورتك: $size بكسل';
  }

  @override
  String get targetUsePhotoSize => 'استخدام أبعاد الصورة';

  @override
  String get targetHintVerySmall =>
      'ستكون الصورة صغيرة جدًا. تحقّق من الأبعاد المطلوبة في النموذج الإلكتروني.';

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
