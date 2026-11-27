// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
    return 'No podemos llegar a $range con esta imagen en estas dimensiones. Lo más cercano: $achieved.';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'No podemos reducir esta imagen a $max en estas dimensiones. Lo más cercano: $achieved.';
  }

  @override
  String get outcomeHintJpegWouldFit => 'En JPEG, esta imagen sí cabría.';

  @override
  String get outcomeHintTryJpeg =>
      'No se puede aumentar el tamaño de archivo de un PNG. Si el formulario acepta JPEG, prueba con JPEG.';

  @override
  String get outcomeUnsupportedInput =>
      'Este tipo de archivo no es compatible con este dispositivo.';

  @override
  String get outcomeImageTooLarge =>
      'Esta imagen es demasiado grande para procesarla en estas dimensiones. Prueba con dimensiones más pequeñas.';

  @override
  String get outcomeOutOfMemory =>
      'Tu celular se quedó sin memoria. Cierra otras apps e inténtalo de nuevo.';

  @override
  String get outcomeWriteFailed =>
      'No pudimos guardar el archivo. Libera espacio de almacenamiento e inténtalo de nuevo.';

  @override
  String get outcomeCancelled => 'Compresión cancelada.';

  @override
  String get outcomeInternalError =>
      'Algo salió mal al preparar tu imagen. Inténtalo de nuevo.';

  @override
  String get noticeNarrowRange =>
      'Este rango es muy estrecho. Algunos portales calculan los KB de otra forma, así que podrían rechazar el archivo.';

  @override
  String get noticePaddingAdded =>
      'Se agregó relleno para alcanzar el tamaño mínimo. La imagen en sí no cambió.';

  @override
  String get noticeTransparencyFlattened =>
      'JPEG no admite transparencia, así que las zonas transparentes ahora son blancas.';

  @override
  String announceProgress(String pass, String total) {
    return 'Comprimiendo, paso $pass de $total.';
  }

  @override
  String announceSuccess(String size) {
    return 'Listo. Tamaño del archivo: $size.';
  }

  @override
  String targetMaxOutOfRange(String min, String max) {
    return 'Ingresa un tamaño máximo entre $min y $max.';
  }

  @override
  String get targetMinNotBelowMax => 'El mínimo debe ser menor que el máximo.';

  @override
  String get targetWholeNumbersOnly => 'Usa números enteros de KB.';

  @override
  String get targetInvalidNumber => 'Ingresa un tamaño válido en KB.';

  @override
  String get targetChooseJpegOrPng => 'Elige JPEG o PNG.';

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'Ingresa un ancho y un alto entre $min y $max píxeles.';
  }

  @override
  String get cropTargetTooLarge =>
      'Esas dimensiones son demasiado grandes para esta app. Elige dimensiones más pequeñas.';

  @override
  String get cropSourceTooLarge =>
      'Esta foto es demasiado grande para abrirla en este dispositivo. Elige otra foto.';

  @override
  String get cropUnsupportedInput =>
      'Este tipo de archivo no es compatible con este dispositivo. Elige una foto JPEG o PNG.';

  @override
  String get cropCorruptInput =>
      'No podemos leer este archivo. Elige otra foto.';

  @override
  String get cropSourceUnavailable =>
      'Ya no encontramos esta foto. Vuelve a elegirla.';

  @override
  String get cropOutOfMemory =>
      'Esta foto es demasiado grande para este dispositivo. Prueba con una foto más pequeña.';

  @override
  String get cropCancelled => 'Preparación cancelada. Tu foto no se modificó.';

  @override
  String cropNoticeEnlarged(String size) {
    return 'Esta foto mide menos de $size px, así que se ampliará y podría verse poco nítida.';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'Esta foto es mucho más pequeña de lo necesario (ampliación de $factor×) y podría verse borrosa. ¿Continuar de todos modos?';
  }

  @override
  String get cropNoticeAnimated =>
      'Esta imagen es animada. Solo se usa el primer fotograma.';

  @override
  String get cropHintLimitedPrecision =>
      'El área de recorte se ve muy delgada en la pantalla. Usa los botones de movimiento y zoom para ajustar la posición con precisión.';

  @override
  String get cropButtonCentre => 'Centrar';

  @override
  String get cropButtonReset => 'Restablecer';

  @override
  String get cropButtonMoveLeft => 'Mover a la izquierda';

  @override
  String get cropButtonMoveRight => 'Mover a la derecha';

  @override
  String get cropButtonMoveUp => 'Mover hacia arriba';

  @override
  String get cropButtonMoveDown => 'Mover hacia abajo';

  @override
  String get cropButtonZoomIn => 'Acercar';

  @override
  String get cropButtonZoomOut => 'Alejar';

  @override
  String get cropButtonRotateClockwise => 'Girar en sentido horario';

  @override
  String get cropButtonRotateCounterclockwise => 'Girar en sentido antihorario';

  @override
  String get cropButtonContinue => 'Continuar';

  @override
  String get cropButtonContinueAnyway => 'Continuar de todos modos';

  @override
  String get cropButtonChooseAnother => 'Elegir otra foto';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'el centro',
      'top': 'la parte superior',
      'bottom': 'la parte inferior',
      'left': 'el lado izquierdo',
      'right': 'el lado derecho',
      'topLeft': 'la esquina superior izquierda',
      'topRight': 'la esquina superior derecha',
      'bottomLeft': 'la esquina inferior izquierda',
      'bottomRight': 'la esquina inferior derecha',
      'other': 'una parte',
    });
    return 'Área de recorte, zoom $zoom, mostrando $_temp0 de la foto';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'izquierdo',
      'right': 'derecho',
      'top': 'superior',
      'bottom': 'inferior',
      'other': '',
    });
    return 'Se alcanzó el borde $_temp0.';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'superior izquierda',
      'topRight': 'superior derecha',
      'bottomLeft': 'inferior izquierda',
      'bottomRight': 'inferior derecha',
      'other': '',
    });
    return 'Cambiar tamaño del recorte, esquina $_temp0';
  }

  @override
  String get cropAnnounceNoEnlargement => 'La foto ya no necesita ampliarse.';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'Ampliación grande ($factor×). Tendrás que confirmar antes de continuar.';
  }

  @override
  String get pickTakePhoto => 'Tomar una foto';

  @override
  String get pickChooseGallery => 'Elegir de la galería';

  @override
  String get pickChooseFiles => 'Elegir de los archivos';

  @override
  String get pickPrivacyNote =>
      'Tus fotos se redimensionan en tu celular. ExactSize nunca las sube.';

  @override
  String get pickOpening => 'Abriendo tu foto…';

  @override
  String get pickNoCamera =>
      'No se encontró ninguna app de cámara en este celular. Elige una foto de la galería.';

  @override
  String get pickPickerUnavailable =>
      'No pudimos abrir el selector de fotos. Inténtalo de nuevo o toma una foto.';

  @override
  String get pickCameraNoPhoto =>
      'La cámara no devolvió ninguna foto. Inténtalo de nuevo.';

  @override
  String get pickLowSpace =>
      'No hay suficiente espacio libre en este celular para tomar una foto. Libera espacio o elige una foto de la galería.';

  @override
  String get pickCaptureLost =>
      'La foto se perdió mientras la cámara estaba abierta. Vuelve a tomarla.';

  @override
  String get pickItemNotOpenable =>
      'No podemos abrir ese elemento. Elige una foto.';

  @override
  String get pickSourceUnavailable =>
      'No pudimos abrir esta foto. Si está guardada en la nube, conéctate a internet o elige una foto guardada en este celular.';

  @override
  String get targetPixelsNotWhole => 'Usa números enteros de píxeles.';

  @override
  String get targetLabelWidth => 'Ancho';

  @override
  String get targetLabelHeight => 'Alto';

  @override
  String get targetLabelMin => 'Tamaño mínimo';

  @override
  String get targetLabelMax => 'Tamaño máximo';

  @override
  String get targetOptional => 'Opcional';

  @override
  String get targetUnitPx => 'px';

  @override
  String get targetUnitKb => 'KB';

  @override
  String get targetFormatLabel => 'Formato';

  @override
  String targetPhotoSize(String size) {
    return 'Tu foto: $size px';
  }

  @override
  String get targetUsePhotoSize => 'Usar las dimensiones de la foto';

  @override
  String get targetHintVerySmall =>
      'La imagen quedará muy pequeña. Revisa las dimensiones que pide tu formulario.';

  @override
  String get exportSave => 'Guardar';

  @override
  String get exportShare => 'Compartir';

  @override
  String get exportSaveAs => 'Elegir dónde guardar';

  @override
  String get exportOpen => 'Abrir';

  @override
  String get exportDone => 'Listo';

  @override
  String exportSaved(String folder, String fileName) {
    return 'Se guardó en $folder como $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'Se guardó como $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'Ya se guardó como $fileName en $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'Ya se guardó como $fileName.';
  }

  @override
  String get exportNoSpace =>
      'No hay suficiente espacio libre en este celular para guardar el archivo. Libera espacio e inténtalo de nuevo.';

  @override
  String get exportSaveFailed =>
      'No pudimos guardar el archivo. Inténtalo de nuevo o compártelo.';

  @override
  String get exportPermissionDenied =>
      'ExactSize necesita el permiso de Almacenamiento para guardar en tu galería. Actívalo en Configuración. También puedes compartir el archivo o elegir dónde guardarlo.';

  @override
  String get exportFileMissing =>
      'El archivo nuevo ya no está disponible. Las fotos de tu galería no se modificaron. Vuelve a elegir la foto para crear el archivo otra vez.';

  @override
  String get exportShareFailed =>
      'No pudimos abrir el menú para compartir. Inténtalo de nuevo o guarda el archivo.';

  @override
  String get exportNoViewer =>
      'Ninguna app de este celular puede abrir este archivo. Aún puedes compartirlo.';

  @override
  String get exportPrivacy =>
      'Al guardar, se crea una copia en tu galería o en la carpeta que elijas. Al compartir, la app que elijas recibe una copia.';

  @override
  String get exportShareHint =>
      'Algunas apps de chat comprimen las fotos. Para un formulario, guarda el archivo y elígelo en el selector de archivos.';

  @override
  String get exportLeaveTitle => '¿Salir sin guardar?';

  @override
  String get exportLeaveBody =>
      'Se eliminará el archivo nuevo. Las fotos de tu galería no se modifican.';

  @override
  String get exportStay => 'Quedarse';

  @override
  String get exportLeave => 'Salir';

  @override
  String get exportSaving => 'Guardando…';

  @override
  String get checkMatches => 'Cumple con tus requisitos';

  @override
  String get checkMismatch =>
      'Este archivo no cumple con tus requisitos, así que no se puede guardar ni compartir. Regresa e inténtalo de nuevo.';

  @override
  String get checkLabelPixels => 'Dimensiones en píxeles';

  @override
  String get checkLabelFileSize => 'Tamaño de archivo';

  @override
  String get checkLabelFormat => 'Formato';

  @override
  String get checkTarget => 'Requisito';

  @override
  String get checkThisFile => 'Este archivo';

  @override
  String get checkMeets => 'Cumple';

  @override
  String get checkDoesntMeet => 'No cumple';

  @override
  String checkUpToKb(String max) {
    return 'Hasta $max';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height px';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'El archivo también cabe si tu portal considera que $kb son $bytes bytes.';
  }

  @override
  String get checkCaveat =>
      'Verificamos los píxeles, los KB y el formato. Algunos formularios también verifican la foto en sí, como la cara o el fondo.';

  @override
  String get previewCaption => 'Imagen ajustada para caber en tu pantalla.';

  @override
  String previewAlt(String width, String height, String format) {
    return 'Vista previa de tu archivo nuevo, $width × $height px, $format.';
  }

  @override
  String get previewUnavailable =>
      'La vista previa no está disponible. La verificación de abajo sigue siendo correcta.';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: requisito $target, este archivo $measured, $status.';
  }

  @override
  String get privacyEntry => 'Cómo se manejan tus fotos';

  @override
  String get privacyTitle => 'Tus fotos y tu privacidad';

  @override
  String get privacyOnPhoneTitle => 'En tu celular';

  @override
  String get privacyOnPhone =>
      'ExactSize redimensiona tu foto en tu celular. ExactSize nunca sube tus fotos. No necesitas una cuenta.';

  @override
  String get privacyOfflineTitle => 'Funciona sin conexión';

  @override
  String get privacyOffline =>
      'Cada paso funciona sin conexión a internet. Si una foto solo está guardada en la nube, tu app de galería tiene que descargarla primero.';

  @override
  String get privacyKeptTitle => 'Qué conserva ExactSize';

  @override
  String get privacyKept =>
      'ExactSize conserva copias temporales solo mientras trabajas. Se eliminan cuando terminas o la próxima vez que se abra la app. Los registros solo contienen códigos de estado breves, nunca tu foto.';

  @override
  String get privacyCopiesTitle => 'Cuando guardas o compartes';

  @override
  String get privacyCopies =>
      'Al guardar, se crea una copia en tu galería o en la carpeta que elijas. Al compartir, la app que elijas recibe una copia. A partir de ese momento, esa copia es tuya y ExactSize ya no la controla.';

  @override
  String get privacyOutsideTitle => 'Otras apps de tu celular';

  @override
  String get privacyOutside =>
      'Tu galería, tu teclado y las apps con las que compartes siguen sus propias reglas de privacidad. Algunos pueden hacer copias de seguridad o enviar archivos.';

  @override
  String get privacyReadsTitle => 'Qué lee ExactSize';

  @override
  String get privacyReads =>
      'ExactSize abre solo la foto que eliges. No explora tu galería ni tus archivos.';

  @override
  String get presetChooseForm => 'Elegir un formulario';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'Foto';

  @override
  String get presetKindSignature => 'Firma';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · hasta $max · $format';
  }

  @override
  String get presetListTitle => 'Formularios';

  @override
  String get presetSearchHint => 'Buscar formularios';

  @override
  String get presetNoMatch => 'No se encontraron formularios.';

  @override
  String get presetEnterYourself => 'Ingresar los valores manualmente';

  @override
  String presetNoteDpi(String dpi) {
    return 'Este formulario también pide $dpi DPI. ExactSize no ajusta los DPI.';
  }

  @override
  String get presetNoteBackground =>
      'Este formulario también tiene una regla sobre el fondo. ExactSize no cambia el fondo.';

  @override
  String get presetNoteContent =>
      'Este formulario también tiene otras reglas para esta imagen. ExactSize no las verifica.';

  @override
  String get presetNotAffiliated =>
      'ExactSize no tiene ninguna afiliación con las organizaciones de esta lista.';

  @override
  String get presetLoadFailed =>
      'No se pudieron cargar los formularios. Puedes ingresar los valores manualmente.';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {'other': '$code'});
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'Empleo',
      'exam_admission': 'Exámenes y admisiones',
      'visa_passport': 'Visa y pasaporte',
      'other': 'Otros',
    });
    return '$_temp0';
  }
}
