import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/injection.dart';
import '../../crop/data/preview_decoder.dart';
import '../data/spec_check_log.dart';
import '../domain/measured_output.dart';

/// Decoder for the result preview (tech section 2); a test seam apart from FEAT-002's
/// `previewDecoderProvider`, which stays in app_flow.dart.
final resultPreviewDecoderProvider = Provider<PreviewDecoder>((_) => const PreviewDecoder());

final outputMeasurerProvider = Provider<OutputMeasurer>((_) => getIt<OutputMeasurer>());
final specCheckLogProvider = Provider<SpecCheckLog>((_) => getIt<SpecCheckLog>());

/// Long-side cap of the preview decode: the screen's physical short side, at most FEAT-002's
/// 2048 (tech 4.3 step 4, T01: steady extra 10.8 MB at 2048 for a 24 MP output).
final previewMaxSideProvider = Provider<int>((_) {
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  final short = view?.physicalSize.shortestSide.round() ?? maxSide;
  return short > 0 ? min(short, maxSide) : maxSide;
});
