// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
    return 'Não conseguimos chegar a $range com esta imagem nestas dimensões. O mais próximo: $achieved.';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'Não conseguimos reduzir esta imagem para $max nestas dimensões. O mais próximo: $achieved.';
  }

  @override
  String get outcomeHintJpegWouldFit =>
      'Em JPEG, esta imagem caberia no tamanho pedido.';

  @override
  String get outcomeHintTryJpeg =>
      'Não é possível aumentar o tamanho de arquivo de um PNG. Se o formulário aceitar JPEG, tente JPEG.';

  @override
  String get outcomeUnsupportedInput =>
      'Este tipo de arquivo não é compatível com este dispositivo.';

  @override
  String get outcomeImageTooLarge =>
      'Esta imagem é grande demais para processar nestas dimensões. Tente dimensões menores.';

  @override
  String get outcomeOutOfMemory =>
      'Seu celular ficou sem memória. Feche outros apps e tente novamente.';

  @override
  String get outcomeWriteFailed =>
      'Não conseguimos salvar o arquivo. Libere espaço de armazenamento e tente novamente.';

  @override
  String get outcomeCancelled => 'Compressão cancelada.';

  @override
  String get outcomeInternalError =>
      'Algo deu errado ao preparar sua imagem. Tente novamente.';

  @override
  String get noticeNarrowRange =>
      'Esta faixa de tamanho é muito estreita. Alguns portais calculam os KB de outra forma, então o arquivo ainda pode ser recusado.';

  @override
  String get noticePaddingAdded =>
      'Foi adicionado preenchimento para atingir o tamanho mínimo. A imagem em si não mudou.';

  @override
  String get noticeTransparencyFlattened =>
      'JPEG não tem transparência, então as áreas transparentes agora são brancas.';

  @override
  String announceProgress(String pass, String total) {
    return 'Comprimindo, etapa $pass de $total.';
  }

  @override
  String announceSuccess(String size) {
    return 'Pronto. Tamanho do arquivo: $size.';
  }

  @override
  String targetMaxOutOfRange(String min, String max) {
    return 'Insira um tamanho máximo entre $min e $max.';
  }

  @override
  String get targetMinNotBelowMax => 'O mínimo deve ser menor que o máximo.';

  @override
  String get targetWholeNumbersOnly => 'Use números inteiros de KB.';

  @override
  String get targetInvalidNumber => 'Insira um tamanho válido em KB.';

  @override
  String get targetChooseJpegOrPng => 'Escolha JPEG ou PNG.';

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'Insira largura e altura entre $min e $max pixels.';
  }

  @override
  String get cropTargetTooLarge =>
      'Essas dimensões são grandes demais para este app. Escolha dimensões menores.';

  @override
  String get cropSourceTooLarge =>
      'Esta foto é grande demais para abrir neste dispositivo. Escolha outra foto.';

  @override
  String get cropUnsupportedInput =>
      'Este tipo de arquivo não é compatível com este dispositivo. Escolha uma foto JPEG ou PNG.';

  @override
  String get cropCorruptInput =>
      'Não conseguimos ler este arquivo. Escolha outra foto.';

  @override
  String get cropSourceUnavailable =>
      'Não encontramos mais esta foto. Escolha a foto novamente.';

  @override
  String get cropOutOfMemory =>
      'Esta foto é grande demais para este dispositivo. Tente uma foto menor.';

  @override
  String get cropCancelled =>
      'Preparação cancelada. Sua foto não foi alterada.';

  @override
  String cropNoticeEnlarged(String size) {
    return 'Esta foto é menor que $size px, então será ampliada e pode ficar pouco nítida.';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'Esta foto é muito menor do que o necessário (ampliação de $factor×) e pode ficar borrada. Continuar mesmo assim?';
  }

  @override
  String get cropNoticeAnimated =>
      'Esta imagem é animada. Apenas o primeiro quadro é usado.';

  @override
  String get cropHintLimitedPrecision =>
      'A área de corte está muito estreita na tela. Use os botões de movimento e zoom para ajustar a posição com precisão.';

  @override
  String get cropButtonCentre => 'Centralizar';

  @override
  String get cropButtonReset => 'Redefinir';

  @override
  String get cropButtonMoveLeft => 'Mover para a esquerda';

  @override
  String get cropButtonMoveRight => 'Mover para a direita';

  @override
  String get cropButtonMoveUp => 'Mover para cima';

  @override
  String get cropButtonMoveDown => 'Mover para baixo';

  @override
  String get cropButtonZoomIn => 'Aumentar zoom';

  @override
  String get cropButtonZoomOut => 'Diminuir zoom';

  @override
  String get cropButtonRotateClockwise => 'Girar no sentido horário';

  @override
  String get cropButtonRotateCounterclockwise =>
      'Girar no sentido anti-horário';

  @override
  String get cropButtonContinue => 'Continuar';

  @override
  String get cropButtonContinueAnyway => 'Continuar mesmo assim';

  @override
  String get cropButtonChooseAnother => 'Escolher outra foto';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'o centro',
      'top': 'a parte de cima',
      'bottom': 'a parte de baixo',
      'left': 'o lado esquerdo',
      'right': 'o lado direito',
      'topLeft': 'o canto superior esquerdo',
      'topRight': 'o canto superior direito',
      'bottomLeft': 'o canto inferior esquerdo',
      'bottomRight': 'o canto inferior direito',
      'other': 'uma parte',
    });
    return 'Área de corte, zoom $zoom, mostrando $_temp0 da foto';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'esquerda',
      'right': 'direita',
      'top': 'superior',
      'bottom': 'inferior',
      'other': '',
    });
    return 'Borda $_temp0 alcançada.';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'superior esquerdo',
      'topRight': 'superior direito',
      'bottomLeft': 'inferior esquerdo',
      'bottomRight': 'inferior direito',
      'other': '',
    });
    return 'Redimensionar corte, canto $_temp0';
  }

  @override
  String get cropAnnounceNoEnlargement =>
      'A foto não precisa mais ser ampliada.';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'Ampliação acentuada ($factor×). Você precisará confirmar antes de continuar.';
  }

  @override
  String get pickTakePhoto => 'Tirar uma foto';

  @override
  String get pickChooseGallery => 'Escolher da galeria';

  @override
  String get pickChooseFiles => 'Escolher dos arquivos';

  @override
  String get pickPrivacyNote =>
      'Suas fotos ficam no seu celular e nunca são enviadas para a internet.';

  @override
  String get pickOpening => 'Abrindo sua foto…';

  @override
  String get pickNoCamera =>
      'Nenhum app de câmera foi encontrado neste celular. Escolha uma foto da galeria.';

  @override
  String get pickPickerUnavailable =>
      'Não conseguimos abrir o seletor de fotos. Tente novamente ou tire uma foto.';

  @override
  String get pickCameraNoPhoto =>
      'A câmera não retornou nenhuma foto. Tente novamente.';

  @override
  String get pickLowSpace =>
      'Não há espaço livre suficiente neste celular para tirar uma foto. Libere espaço ou escolha uma foto da galeria.';

  @override
  String get pickCaptureLost =>
      'A foto se perdeu enquanto a câmera estava aberta. Tire a foto novamente.';

  @override
  String get pickItemNotOpenable =>
      'Não conseguimos abrir esse item. Escolha uma foto.';

  @override
  String get pickSourceUnavailable =>
      'Não conseguimos abrir esta foto. Se ela estiver salva na nuvem, conecte-se à internet ou escolha uma foto salva neste celular.';

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
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'ExactSize';
}
