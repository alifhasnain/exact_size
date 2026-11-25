import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../crop/data/preview_decoder.dart';

/// Decoder for the result preview (tech section 2); a test seam apart from FEAT-002's
/// `previewDecoderProvider`, which stays in app_flow.dart.
final resultPreviewDecoderProvider = Provider<PreviewDecoder>((_) => const PreviewDecoder());
