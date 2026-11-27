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
      'يُغيَّر حجم صورك على هاتفك. ولا يرفعها ExactSize أبدًا.';

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
  String get exportSave => 'حفظ';

  @override
  String get exportShare => 'مشاركة';

  @override
  String get exportSaveAs => 'اختيار مكان الحفظ';

  @override
  String get exportOpen => 'فتح';

  @override
  String get exportDone => 'تم';

  @override
  String exportSaved(String folder, String fileName) {
    return 'تم حفظ الملف في $folder باسم $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'تم حفظ الملف باسم $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'تم حفظ هذا الملف مسبقًا باسم $fileName في $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'تم حفظ هذا الملف مسبقًا باسم $fileName.';
  }

  @override
  String get exportNoSpace =>
      'لا توجد مساحة خالية كافية على هذا الهاتف لحفظ الملف. حرّر بعض المساحة وحاول مرة أخرى.';

  @override
  String get exportSaveFailed =>
      'تعذّر حفظ الملف. حاول مرة أخرى أو شارك الملف بدلًا من ذلك.';

  @override
  String get exportPermissionDenied =>
      'يحتاج ExactSize إلى إذن التخزين للحفظ في المعرض. انتقل إلى الإعدادات وامنح الإذن. يمكنك أيضًا مشاركة الملف أو اختيار مكان حفظه.';

  @override
  String get exportFileMissing =>
      'لم يعد الملف الذي أنشأته متاحًا. تبقى الصور في معرضك كما هي. اختر الصورة مرة أخرى لإنشاء ملف جديد.';

  @override
  String get exportShareFailed =>
      'تعذّر فتح قائمة المشاركة. حاول مرة أخرى أو احفظ الملف بدلًا من ذلك.';

  @override
  String get exportNoViewer =>
      'لا يوجد تطبيق على هذا الهاتف يمكنه فتح هذا الملف. لا يزال بإمكانك مشاركته.';

  @override
  String get exportPrivacy =>
      'عند الحفظ، توضع نسخة في معرضك أو في مجلد تختاره. وعند المشاركة، يحصل التطبيق الذي تختاره على نسخة.';

  @override
  String get exportShareHint =>
      'بعض تطبيقات الدردشة تضغط الصور. للنموذج الإلكتروني، احفظ الملف ثم اختره عند رفعه.';

  @override
  String get exportLeaveTitle => 'الرجوع دون حفظ؟';

  @override
  String get exportLeaveBody =>
      'سيُحذف الملف الذي أنشأته. تبقى الصور في معرضك كما هي.';

  @override
  String get exportStay => 'البقاء';

  @override
  String get exportLeave => 'الرجوع';

  @override
  String get exportSaving => 'جارٍ الحفظ…';

  @override
  String get checkMatches => 'الملف يطابق المطلوب';

  @override
  String get checkMismatch =>
      'هذا الملف لا يطابق المطلوب، لذا لا يمكن حفظه أو مشاركته. ارجع وحاول مرة أخرى.';

  @override
  String get checkLabelPixels => 'الأبعاد بالبكسل';

  @override
  String get checkLabelFileSize => 'حجم الملف';

  @override
  String get checkLabelFormat => 'صيغة الملف';

  @override
  String get checkTarget => 'المطلوب';

  @override
  String get checkThisFile => 'هذا الملف';

  @override
  String get checkMeets => 'مطابق';

  @override
  String get checkDoesntMeet => 'غير مطابق';

  @override
  String checkUpToKb(String max) {
    return 'حتى $max';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height بكسل';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'يُعدّ الملف مطابقًا أيضًا إذا كانت بوابتك الإلكترونية تعتبر $kb مساويًا لـ $bytes بايت.';
  }

  @override
  String get checkCaveat =>
      'نتحقق من الأبعاد بالبكسل وحجم الملف بوحدة KB وصيغته. بعض النماذج الإلكترونية تتحقق أيضًا من الصورة نفسها، مثل الوجه أو الخلفية.';

  @override
  String get previewCaption => 'تُعرض الصورة مصغّرة أو مكبّرة لتناسب شاشتك.';

  @override
  String previewAlt(String width, String height, String format) {
    return 'معاينة الملف الذي أنشأته، $width × $height بكسل، $format.';
  }

  @override
  String get previewUnavailable =>
      'المعاينة غير متاحة. نتيجة التحقق أدناه لا تزال صحيحة.';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: المطلوب $target، هذا الملف $measured، $status.';
  }

  @override
  String get privacyEntry => 'كيف تُعالَج صورك';

  @override
  String get privacyTitle => 'صورك وخصوصيتك';

  @override
  String get privacyOnPhoneTitle => 'على هاتفك';

  @override
  String get privacyOnPhone =>
      'يغيّر ExactSize حجم صورتك على هاتفك. ولا يرفع ExactSize صورك أبدًا. ولا تحتاج إلى حساب.';

  @override
  String get privacyOfflineTitle => 'يعمل دون اتصال';

  @override
  String get privacyOffline =>
      'تعمل كل خطوة دون اتصال بالإنترنت. أما إن كانت الصورة محفوظة في التخزين السحابي فقط، فيجب أن ينزّلها تطبيق المعرض أولًا.';

  @override
  String get privacyKeptTitle => 'ما يحتفظ به ExactSize';

  @override
  String get privacyKept =>
      'يحتفظ ExactSize بنسخ مؤقتة أثناء عملك فقط. وتُحذف عند انتهائك من العمل أو عند فتح التطبيق في المرة التالية. ولا تحتوي سجلات ExactSize إلا على رموز حالة قصيرة، ولا تحتوي على صورتك أبدًا.';

  @override
  String get privacyCopiesTitle => 'عند الحفظ أو المشاركة';

  @override
  String get privacyCopies =>
      'عند الحفظ، توضع نسخة في معرضك أو في مجلد تختاره. وعند المشاركة، يحصل التطبيق الذي تختاره على نسخة. ومن تلك اللحظة، تصبح النسخة لك، ولا يتحكم فيها ExactSize.';

  @override
  String get privacyOutsideTitle => 'التطبيقات الأخرى على هاتفك';

  @override
  String get privacyOutside =>
      'يتبع كلٌّ من معرضك ولوحة المفاتيح والتطبيقات التي تشارك الصور معها سياسة الخصوصية الخاصة به. وقد تنشئ بعضها نسخًا احتياطية أو ترسل ملفات.';

  @override
  String get privacyReadsTitle => 'ما يقرؤه ExactSize';

  @override
  String get privacyReads =>
      'لا يفتح ExactSize إلا الصورة التي تختارها. ولا يستعرض معرضك أو ملفاتك.';

  @override
  String get presetChooseForm => 'اختيار نموذج تقديم';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'صورة';

  @override
  String get presetKindSignature => 'توقيع';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · حتى $max · $format';
  }

  @override
  String get presetListTitle => 'نماذج التقديم';

  @override
  String get presetSearchHint => 'البحث في نماذج التقديم';

  @override
  String get presetNoMatch => 'لا توجد نماذج مطابقة.';

  @override
  String get presetEnterYourself => 'إدخال العرض والارتفاع وحجم الملف يدويًا';

  @override
  String presetNoteDpi(String dpi) {
    return 'يطلب هذا النموذج أيضًا $dpi DPI. لا يضبط ExactSize قيمة DPI.';
  }

  @override
  String get presetNoteBackground =>
      'يتضمن هذا النموذج أيضًا شرطًا يخص الخلفية. لا يغيّر ExactSize الخلفية.';

  @override
  String get presetNoteContent =>
      'يتضمن هذا النموذج أيضًا شروطًا أخرى لهذه الصورة. لا يتحقق ExactSize منها.';

  @override
  String get presetNotAffiliated =>
      'لا يتبع ExactSize أيًّا من الجهات المدرجة في هذه القائمة.';

  @override
  String get presetLoadFailed =>
      'تعذّر فتح قائمة النماذج. يمكنك إدخال العرض والارتفاع وحجم الملف يدويًا.';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {'other': '$code'});
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'التوظيف',
      'exam_admission': 'الامتحانات والقبول',
      'visa_passport': 'التأشيرات وجوازات السفر',
      'other': 'أخرى',
    });
    return '$_temp0';
  }

  @override
  String get presetAnyPixelSize => 'الأبعاد غير مذكورة';

  @override
  String get presetKbOnlyNote =>
      'لا يذكر هذا النموذج الأبعاد بالبكسل. أدخل العرض والارتفاع، أو استخدم أبعاد الصورة.';
}
