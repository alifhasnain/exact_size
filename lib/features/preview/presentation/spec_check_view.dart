import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/presentation/outcome_messages.dart';
import '../../crop/presentation/crop_canvas.dart' show paintCheckerboard;
import '../../target/domain/target_spec.dart';
import '../domain/measured_output.dart';
import '../domain/spec_check.dart';
import 'check_messages.dart';
import 'spec_check_controller.dart';

/// FR-14: the preview fits at most this share of the screen height (portrait)...
const kPreviewMaxHeightFraction = 0.4;

/// ...and is enlarged by at most this many device pixels per image pixel.
const kPreviewMaxDevicePxPerPx = 4.0;

/// The matching result (G1 design t10/check_design.md): preview stage, headline, spec slip,
/// notices and caveat, in FR-7 order. The result screen adds the export panel and Done below.
class SpecCheckView extends StatelessWidget {
  const SpecCheckView({super.key, required this.spec, required this.state});

  final TargetSpec spec;
  final CheckMeets state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: Booth.text);
    final outcome = OutcomeMessages(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _PreviewStage(measured: state.measured, image: state.preview),
        // The verdict is announced once (NFR-2); it never claims a portal will accept the file (FR-7).
        Semantics(
          container: true,
          liveRegion: true,
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.check_circle, size: 28, color: Booth.flash),
              Expanded(
                child: Text(l.checkMatches, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Booth.text)),
              ),
            ],
          ),
        ),
        SpecSlip(spec: spec, measured: state.measured, check: state.check, showAlsoFits: !state.check.window.narrow),
        for (final n in Notice.values)
          if (state.success.notices.contains(n))
            BoothNotice(icon: n == Notice.narrowRange ? Icons.warning_amber : Icons.info_outline, text: outcome.notice(n)),
        Text(l.checkCaveat, style: small),
      ],
    );
  }
}

/// The three rows in fixed order (FR-5), each one semantics node read as a sentence (AC-8.2).
/// Shared with the mismatch state, which passes [showAlsoFits] false (G1 decision 3).
class SpecSlip extends StatelessWidget {
  const SpecSlip({super.key, required this.spec, required this.measured, required this.check, required this.showAlsoFits});

  final TargetSpec spec;
  final MeasuredOutput measured;
  final SpecCheck check;
  final bool showAlsoFits;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = CheckMessages(l);
    final divider = Divider(height: 24, thickness: 1, color: Booth.text.withValues(alpha: 0.2));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(context, m, l.checkLabelPixels, m.pixels(spec.width, spec.height), m.pixels(measured.width, measured.height), check.pixels),
          divider,
          _row(context, m, l.checkLabelFileSize, m.targetSize(spec), m.measuredSize(measured, check), check.size,
              extra: showAlsoFits ? m.alsoFits() : null),
          divider,
          _row(context, m, l.checkLabelFormat, m.format(spec.format), m.format(measured.format), check.format),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, CheckMessages m, String label, String target, String measuredText, bool meets, {String? extra}) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final small = text.bodySmall?.copyWith(color: Booth.text);
    Widget cell(String caption, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(caption, style: small), Text(value, style: _value)],
        );
    return Semantics(
      container: true,
      label: m.rowSentence(label, target, measuredText, meets),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          // Wrap, so at a large font the status drops under the label instead of clipping.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [Text(label, style: text.titleSmall?.copyWith(color: Booth.text)), _Status(meets: meets, text: m.status(meets))],
          ),
          Wrap(spacing: 24, runSpacing: 8, children: [cell(l.checkTarget, target), cell(l.checkThisFile, measuredText)]),
          if (extra != null) Text(extra, style: small),
        ],
      ),
    );
  }

  static const _value = TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Booth.text,
  );
}

/// Icon plus word, never colour alone (NFR-2).
class _Status extends StatelessWidget {
  const _Status({required this.meets, required this.text});
  final bool meets;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: Booth.text);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(meets ? Icons.check_circle : Icons.cancel, size: 20, color: meets ? Booth.flash : Booth.text),
        Flexible(child: Text(text, style: style)),
      ],
    );
    if (meets) return content;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Booth.notice, borderRadius: BorderRadius.circular(8)),
      child: content,
    );
  }
}

/// The print on the plate: sized from the measured W×H (not the bitmap), whole image, aspect kept,
/// no filter, overlay or gesture (FR-13, FR-14, FR-17). Null image: the FR-14 placeholder.
class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.measured, required this.image});
  final MeasuredOutput measured;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: Booth.text);
    final img = image;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
      child: img == null
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  const Icon(Icons.image_not_supported_outlined, size: 32, color: Booth.text),
                  Text(l.previewUnavailable, style: small, textAlign: TextAlign.center),
                ],
              ),
            )
          : LayoutBuilder(builder: (context, c) {
              final box = previewBoxSize(
                measured.width,
                measured.height,
                maxWidth: c.maxWidth - 2, // the hairline frame
                screenHeight: MediaQuery.sizeOf(context).height,
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
              );
              return Column(
                spacing: 12,
                children: [
                  Semantics(
                    container: true,
                    image: true,
                    label: CheckMessages(l).previewAlt(measured.width, measured.height, measured.format),
                    child: Container(
                      // The border's own width is the inset: the frame sits outside the image.
                      decoration: BoxDecoration(border: Border.all(color: Booth.text.withValues(alpha: 0.3))),
                      child: SizedBox.fromSize(
                        size: box,
                        child: CustomPaint(
                          painter: measured.hasAlpha ? const _Checkerboard() : null,
                          child: RawImage(image: img, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                        ),
                      ),
                    ),
                  ),
                  Text(l.previewCaption, style: small, textAlign: TextAlign.center),
                ],
              );
            }),
    );
  }
}

/// FR-14 box for a [width]×[height] output: fits [maxWidth] and the height share, enlarged by at
/// most [kPreviewMaxDevicePxPerPx] device pixels per image pixel.
Size previewBoxSize(int width, int height, {required double maxWidth, required double screenHeight, required double devicePixelRatio}) {
  final scale = [
    maxWidth / width,
    kPreviewMaxHeightFraction * screenHeight / height,
    kPreviewMaxDevicePxPerPx / devicePixelRatio,
  ].reduce(math.min);
  return Size(width * scale, height * scale);
}

class _Checkerboard extends CustomPainter {
  const _Checkerboard();
  @override
  void paint(Canvas canvas, Size size) => paintCheckerboard(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(_Checkerboard oldDelegate) => false;
}
