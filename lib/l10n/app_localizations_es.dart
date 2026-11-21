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
      'Tus fotos se quedan en tu celular y nunca se suben a internet.';

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
}
