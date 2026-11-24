import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/compression/presentation/compression_providers.dart';
import 'features/crop/data/crop_renderer.dart';
import 'features/crop/data/preview_decoder.dart';
import 'features/crop/presentation/crop_controller.dart';
import 'features/crop/presentation/crop_messages.dart';
import 'features/crop/presentation/crop_screen.dart';
import 'features/export/presentation/result_screen.dart';
import 'features/pick/domain/pick_types.dart';
import 'features/pick/presentation/pick_controller.dart';
import 'features/target/domain/target_spec.dart';
import 'features/target/presentation/target_screen.dart';
import 'l10n/app_localizations.dart';
import 'ui/booth.dart';

/// Pick → target step → crop → compression → result and export (FEAT-005 tech plan, OQ-4 photo first; FEAT-007 tech 4.5).

/// Seams for tests: the preview decode and the crop render.
final previewDecoderProvider = Provider<PreviewDecoder>((_) => const PreviewDecoder());
final cropRenderProvider = Provider<CropRenderFn>((_) => (request, cancel) => const CropRenderer().render(request, cancel: cancel));

/// Opens the target step for [image].
///
/// Leaving the target step is start-over (FEAT-001 FR-11): release the image
/// and end the crop session, but only while [image] is still current. A newer
/// pick or share closes this route with popUntil and must keep its own image
/// and camera file (R2, OQ-T5).
void openTargetStep(BuildContext context, PickedImage image) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TargetRoute(image)));
}

/// Opens crop for [image] at [spec] (called by the target step's Continue).
void openCropStep(BuildContext context, PickedImage image, TargetSpec spec) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _CropStep(image, spec)));
}

/// Start-over from inside the flow: release once, then back to the pick screen.
/// The target route's guard then sees no current image and releases nothing.
void _chooseAnother(BuildContext context, WidgetRef ref) {
  ref.read(pickControllerProvider.notifier).release();
  ref.read(cropControllerProvider.notifier).end();
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class _TargetRoute extends ConsumerWidget {
  const _TargetRoute(this.image);
  final PickedImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || !identical(ref.read(pickControllerProvider).current, image)) return;
        ref.read(pickControllerProvider.notifier).release();
        ref.read(cropControllerProvider.notifier).end();
      },
      child: TargetScreen(info: image.info, onContinue: (spec) => openCropStep(context, image, spec)),
    );
  }
}

/// Decodes the preview (progress after 500 ms), then shows [CropScreen]. The
/// preview belongs to this route and is disposed with it.
class _CropStep extends ConsumerStatefulWidget {
  const _CropStep(this.image, this.spec);
  final PickedImage image;
  final TargetSpec spec;

  @override
  ConsumerState<_CropStep> createState() => _CropStepState();
}

class _CropStepState extends ConsumerState<_CropStep> {
  PreviewResult? _result;
  var _showProgress = false;
  Timer? _progress;

  @override
  void initState() {
    super.initState();
    _progress = Timer(CropScreen.progressDelay, () => setState(() => _showProgress = true));
    ref.read(previewDecoderProvider).decode(widget.image.handle, widget.image.info).then((r) {
      if (!mounted) {
        if (r case PreviewOk(:final image)) image.dispose();
        return;
      }
      _progress?.cancel();
      setState(() => _result = r);
    });
  }

  @override
  void dispose() {
    _progress?.cancel();
    if (_result case PreviewOk(:final image)) image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (_result) {
      PreviewOk(:final image) => CropScreen(
          src: widget.image.handle,
          preview: image,
          info: widget.image.info,
          target: widget.spec.dimensions,
          render: ref.read(cropRenderProvider),
          onContinue: (pixels) {
            // The buffer moves to FEAT-004 with the request (ADR-003); the flow never frees it.
            ref.read(compressionControllerProvider.notifier).start(widget.spec.request(pixels));
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ResultScreen(size: widget.spec.dimensions, onStartOver: () => _chooseAnother(context, ref))));
          },
          onChooseAnother: () => _chooseAnother(context, ref),
        ),
      PreviewErr(:final reason) => _Booth(children: [
          BoothNotice(icon: Icons.error_outline, text: CropMessages(l).reason(reason)),
          FilledButton.tonal(onPressed: () => _chooseAnother(context, ref), child: Text(l.cropButtonChooseAnother)),
        ]),
      null => _Booth(children: [
          if (_showProgress) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(l.pickOpening, textAlign: TextAlign.center),
          ],
        ]),
    };
  }
}

/// Booth shell for the crop step's decode states (G1 design).
class _Booth extends StatelessWidget {
  const _Booth({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Theme(
        data: Booth.theme(Theme.of(context)).copyWith(
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Booth.text, displayColor: Booth.text),
        ),
        child: Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  liveRegion: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ),
      );
}
