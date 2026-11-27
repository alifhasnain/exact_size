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
      'Suas fotos são redimensionadas no seu celular. O ExactSize nunca as envia para a internet.';

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
  String get targetPixelsNotWhole => 'Use números inteiros de pixels.';

  @override
  String get targetLabelWidth => 'Largura';

  @override
  String get targetLabelHeight => 'Altura';

  @override
  String get targetLabelMin => 'Tamanho mínimo';

  @override
  String get targetLabelMax => 'Tamanho máximo';

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
    return 'Sua foto: $size px';
  }

  @override
  String get targetUsePhotoSize => 'Usar as dimensões da foto';

  @override
  String get targetHintVerySmall =>
      'A imagem ficará muito pequena. Confira as dimensões que seu formulário pede.';

  @override
  String get exportSave => 'Salvar';

  @override
  String get exportShare => 'Compartilhar';

  @override
  String get exportSaveAs => 'Escolher onde salvar';

  @override
  String get exportOpen => 'Abrir';

  @override
  String get exportDone => 'Concluído';

  @override
  String exportSaved(String folder, String fileName) {
    return 'Arquivo salvo em $folder como $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'Arquivo salvo como $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'Este arquivo já foi salvo como $fileName em $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'Este arquivo já foi salvo como $fileName.';
  }

  @override
  String get exportNoSpace =>
      'Não há espaço livre suficiente neste celular para salvar o arquivo. Libere espaço e tente novamente.';

  @override
  String get exportSaveFailed =>
      'Não foi possível salvar o arquivo. Tente novamente ou compartilhe-o.';

  @override
  String get exportPermissionDenied =>
      'O ExactSize precisa da permissão de Armazenamento para salvar na galeria. Ative-a nas Configurações. Você também pode compartilhar o arquivo ou escolher onde salvá-lo.';

  @override
  String get exportFileMissing =>
      'O novo arquivo não está mais disponível. As fotos da sua galeria continuam como estão. Escolha a foto novamente para criar o arquivo outra vez.';

  @override
  String get exportShareFailed =>
      'Não foi possível abrir o menu de compartilhamento. Tente novamente ou salve o arquivo.';

  @override
  String get exportNoViewer =>
      'Nenhum app neste celular consegue abrir este arquivo. Você ainda pode compartilhá-lo.';

  @override
  String get exportPrivacy =>
      'Ao salvar, uma cópia vai para sua galeria ou para uma pasta que você escolher. Ao compartilhar, o app que você escolher recebe uma cópia.';

  @override
  String get exportShareHint =>
      'Alguns apps de chat comprimem as fotos. Para enviar em um formulário, salve o arquivo e selecione-o no seletor de arquivos.';

  @override
  String get exportLeaveTitle => 'Sair sem salvar?';

  @override
  String get exportLeaveBody =>
      'O novo arquivo será excluído. As fotos da sua galeria não serão alteradas.';

  @override
  String get exportStay => 'Ficar';

  @override
  String get exportLeave => 'Sair';

  @override
  String get exportSaving => 'Salvando…';

  @override
  String get checkMatches => 'Atende aos seus requisitos';

  @override
  String get checkMismatch =>
      'Este arquivo não atende aos seus requisitos, então não pode ser salvo nem compartilhado. Volte e tente de novo.';

  @override
  String get checkLabelPixels => 'Dimensões em pixels';

  @override
  String get checkLabelFileSize => 'Tamanho de arquivo';

  @override
  String get checkLabelFormat => 'Formato';

  @override
  String get checkTarget => 'Requisito';

  @override
  String get checkThisFile => 'Este arquivo';

  @override
  String get checkMeets => 'Atende';

  @override
  String get checkDoesntMeet => 'Não atende';

  @override
  String checkUpToKb(String max) {
    return 'Até $max';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height px';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'O arquivo também atende se o seu portal contar $kb como $bytes bytes.';
  }

  @override
  String get checkCaveat =>
      'Verificamos pixels, KB e formato. Alguns formulários também verificam a própria foto, como o rosto ou o fundo.';

  @override
  String get previewCaption => 'Imagem ajustada para caber na sua tela.';

  @override
  String previewAlt(String width, String height, String format) {
    return 'Pré-visualização do seu novo arquivo, $width × $height px, $format.';
  }

  @override
  String get previewUnavailable =>
      'A pré-visualização não está disponível. A verificação abaixo continua válida.';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: requisito $target, este arquivo $measured, $status.';
  }

  @override
  String get privacyEntry => 'Como suas fotos são tratadas';

  @override
  String get privacyTitle => 'Suas fotos e sua privacidade';

  @override
  String get privacyOnPhoneTitle => 'No seu celular';

  @override
  String get privacyOnPhone =>
      'O ExactSize redimensiona sua foto no seu celular. O ExactSize nunca envia suas fotos para a internet. Você não precisa de uma conta.';

  @override
  String get privacyOfflineTitle => 'Funciona sem internet';

  @override
  String get privacyOffline =>
      'Todas as etapas funcionam sem conexão com a internet. Se uma foto estiver salva só na nuvem, o app de galeria precisa baixá-la primeiro.';

  @override
  String get privacyKeptTitle => 'O que o ExactSize guarda';

  @override
  String get privacyKept =>
      'O ExactSize guarda cópias temporárias só enquanto você trabalha. Elas são excluídas quando você termina ou na próxima vez que o app for aberto. Os registros contêm apenas códigos de status curtos, nunca sua foto.';

  @override
  String get privacyCopiesTitle => 'Ao salvar ou compartilhar';

  @override
  String get privacyCopies =>
      'Ao salvar, uma cópia vai para sua galeria ou para uma pasta que você escolher. Ao compartilhar, o app que você escolher recebe uma cópia. A partir daí, essa cópia é sua, e o ExactSize não tem controle sobre ela.';

  @override
  String get privacyOutsideTitle => 'Outros apps do seu celular';

  @override
  String get privacyOutside =>
      'Sua galeria, seu teclado e os apps com que você compartilha seguem as próprias regras de privacidade. Alguns deles podem fazer backup ou enviar arquivos.';

  @override
  String get privacyReadsTitle => 'O que o ExactSize lê';

  @override
  String get privacyReads =>
      'O ExactSize abre só a foto que você escolhe. Ele não percorre sua galeria nem seus arquivos.';

  @override
  String get presetChooseForm => 'Escolher um formulário';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'Foto';

  @override
  String get presetKindSignature => 'Assinatura';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · até $max · $format';
  }

  @override
  String get presetListTitle => 'Formulários';

  @override
  String get presetSearchHint => 'Buscar formulários';

  @override
  String get presetNoMatch => 'Nenhum formulário encontrado.';

  @override
  String get presetEnterYourself => 'Inserir os valores manualmente';

  @override
  String presetNoteDpi(String dpi) {
    return 'Este formulário também pede $dpi DPI. O ExactSize não ajusta o DPI.';
  }

  @override
  String get presetNoteBackground =>
      'Este formulário também tem uma regra para o fundo. O ExactSize não altera o fundo.';

  @override
  String get presetNoteContent =>
      'Este formulário também tem outras regras para esta imagem. O ExactSize não as verifica.';

  @override
  String get presetNotAffiliated =>
      'O ExactSize não tem nenhuma afiliação com as organizações desta lista.';

  @override
  String get presetLoadFailed =>
      'Não foi possível abrir a lista de formulários. Você pode inserir os valores manualmente.';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'BD': 'Bangladesh',
      'FR': 'França',
      'IN': 'Índia',
      'MX': 'México',
      'PK': 'Paquistão',
      'SG': 'Singapura',
      'US': 'Estados Unidos',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'Emprego',
      'exam_admission': 'Provas e ingresso em cursos',
      'visa_passport': 'Visto e passaporte',
      'other': 'Outros',
    });
    return '$_temp0';
  }

  @override
  String get presetAnyPixelSize => 'Dimensões não indicadas';

  @override
  String get presetKbOnlyNote =>
      'Este formulário não indica dimensões em pixels. Insira a largura e a altura ou use as dimensões da foto.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'ExactSize';
}
