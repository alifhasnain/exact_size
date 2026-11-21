import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/semantics.dart' show CustomSemanticsAction, SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../compression/data/compression_runner.dart' show CancelSignal;
import '../../compression/data/native_pixel_buffer.dart';
import '../../compression/domain/pixel_buffer.dart';
import '../data/crop_renderer.dart';
import '../data/source_handle.dart';
import '../domain/crop_types.dart';
import '../domain/target_check.dart';
import 'crop_canvas.dart';
import 'crop_controller.dart';
import 'crop_messages.dart';
import 'recents_guard.dart';

/// Runs one render; replaceable in tests.
typedef CropRenderFn = Future<RenderResult> Function(RenderRequest request, CancelSignal cancel);

Future<RenderResult> _defaultRender(RenderRequest request, CancelSignal cancel) =>
    const CropRenderer().render(request, cancel: cancel);

/// The crop screen (FEAT-002; direction: the ID photo booth, surface brief in
/// .impeccable/surfaces/; gate G3). Booth cabin on top (start side in
/// landscape), then notices, the control plate, and the print slot beside
/// the flash-amber Continue key. Render, progress and errors are wired in T25.
class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({
    super.key,
    required this.src,
    required this.preview,
    required this.info,
    required this.target,
    required this.onContinue,
    required this.onChooseAnother,
    this.render = _defaultRender,
    this.recentsBinding = const AndroidRecentsBinding(),
  });

  /// The original, re-opened read-only by the render (FR-7).
  final SourceHandle src;
  final ui.Image preview;
  final SourceInfo info;
  final Target target;

  /// Hand-off of the exact W×H buffer; ownership moves to the callee
  /// (ADR-003; FEAT-004 wiring is FEAT-004-T27).
  final void Function(PixelBuffer pixels) onContinue;
  final VoidCallback onChooseAnother;
  final CropRenderFn render;
  final RecentsBinding recentsBinding;

  /// Progress shows only for renders slower than this (FR-18).
  static const progressDelay = Duration(milliseconds: 500);

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  /// A new source or target re-initialises the frame (AC-2.2).
  @override
  void didUpdateWidget(CropScreen old) {
    super.didUpdateWidget(old);
    if (!identical(old.info, widget.info) || old.target != widget.target) _start();
  }

  // Providers may not change while the tree builds.
  void _start() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) ref.read(cropControllerProvider.notifier).start(widget.info, widget.target);
  });

  var _busy = false, _showProgress = false;
  CancelSignal? _cancel;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _cancel?.cancel(); // the render frees its memory and reports CANCELLED
    super.dispose();
  }

  /// Continue (US-2): one render at a time, confirmation above 2.0 first.
  Future<void> _continue(CropSession s, CropMessages m, AppLocalizations l10n) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (s.upscaleLevel == UpscaleLevel.strong) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(m.confirmEnlarge(s.upscaleFactor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cropButtonChooseAnother)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.cropButtonContinueAnyway)),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) {
        setState(() => _busy = false);
        if (ok == false) widget.onChooseAnother();
        return;
      }
    }

    final cancel = _cancel = CancelSignal();
    _progressTimer = Timer(CropScreen.progressDelay, () {
      if (mounted) setState(() => _showProgress = true);
    });
    final r = await widget.render(
      RenderRequest(
        src: widget.src,
        info: s.info,
        cropRect: s.cropRect,
        quarterTurns: s.crop.quarterTurns,
        target: s.target,
      ),
      cancel,
    );
    _progressTimer?.cancel();
    _cancel = null;
    cancel.dispose();
    if (!mounted) {
      if (r case RenderOk(pixels: final NativePixelBuffer p)) p.free();
      return;
    }
    setState(() => _busy = _showProgress = false);
    switch (r) {
      case RenderOk(:final pixels):
        widget.onContinue(pixels);
      case RenderErr(reason: Reason.cancelled):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m.reason(Reason.cancelled))));
      case RenderErr(:final reason):
        await _showError(reason, m, l10n);
    }
  }

  /// One message and one next action per reason (PRD section 8).
  Future<void> _showError(Reason reason, CropMessages m, AppLocalizations l10n) async {
    final fixTarget = reason == Reason.invalidTargetDimensions;
    final chooseAnother = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(m.reason(reason, targetMessage: fixTarget ? checkTarget(widget.target) : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, !fixTarget),
            child: Text(fixTarget ? MaterialLocalizations.of(context).okButtonLabel : l10n.cropButtonChooseAnother),
          ),
        ],
      ),
    );
    if (chooseAnother == true && mounted) widget.onChooseAnother();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = CropMessages(l10n);
    final session = ref.watch(cropControllerProvider);
    final controller = ref.read(cropControllerProvider.notifier);
    ref.listen(cropControllerProvider, (_, next) {
      if (next == null) return;
      for (final a in next.announcements) {
        unawaited(
          SemanticsService.sendAnnouncement(View.of(context), a.text(m, next.target), Directionality.of(context)),
        );
      }
    });

    final s = session != null && identical(session.info, widget.info) && session.target == widget.target
        ? session
        : null;
    final canvas = s == null
        ? const ColoredBox(color: CropCanvas.background, child: SizedBox.expand())
        : Semantics(
            // FR-5, AC-9.1: purpose and state, plus the non-gesture actions.
            label: CropController.areaState(s).text(m, s.target),
            customSemanticsActions: {
              for (final (a, label) in [
                (CropAction.moveLeft, l10n.cropButtonMoveLeft),
                (CropAction.moveRight, l10n.cropButtonMoveRight),
                (CropAction.moveUp, l10n.cropButtonMoveUp),
                (CropAction.moveDown, l10n.cropButtonMoveDown),
                (CropAction.zoomIn, l10n.cropButtonZoomIn),
                (CropAction.zoomOut, l10n.cropButtonZoomOut),
                (CropAction.centre, l10n.cropButtonCentre),
                (CropAction.reset, l10n.cropButtonReset),
              ])
                CustomSemanticsAction(label: label): () => controller.perform(a),
            },
            child: CropCanvas(
              preview: widget.preview,
              info: s.info,
              target: s.target,
              crop: s.crop,
              onDrag: controller.drag,
              onPinch: controller.pinch,
              onHandle: controller.handle,
              handleLabel: m.handleLabel,
            ),
          );

    return RecentsGuard(
      binding: widget.recentsBinding,
      child: Theme(
        data: _Booth.theme(Theme.of(context)),
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(title: _SpecCells(m.size(widget.target))),
              body: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final landscape = box.maxWidth > box.maxHeight && box.maxWidth >= 600;
                    final panel = _Panel(
                      session: s,
                      preview: widget.preview,
                      messages: m,
                      l10n: l10n,
                      thin: CropFrameLayout.of(box.biggest, widget.target).thin,
                      onAction: controller.perform,
                      onContinue: s == null || _busy ? null : () => _continue(s, m, l10n),
                    );
                    if (landscape) {
                      return Row(
                        children: [
                          Expanded(child: canvas),
                          SizedBox(width: 340, child: SingleChildScrollView(child: panel)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: canvas),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: box.maxHeight / 2),
                          child: SingleChildScrollView(child: panel),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_showProgress) _Progress(onCancel: () => _cancel?.cancel()),
          ],
        ),
      ),
    );
  }
}

/// Render progress after 500 ms, cancellable (FR-18). Blocks the screen
/// underneath so the crop cannot change mid-render.
class _Progress extends StatelessWidget {
  const _Progress({required this.onCancel});
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xB3000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            const CircularProgressIndicator(color: _Booth.flash),
            TextButton(onPressed: onCancel, child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          ],
        ),
      ),
    ),
  );
}

/// The ID photo booth palette. Fixed in both app themes (the booth is the same
/// booth day or night); every text pair meets WCAG AA.
abstract final class _Booth {
  static const curtain = Color(0xFF5A1622);
  static const plate = Color(0xFF3E0D16);
  static const notice = Color(0xFF762838);
  static const key = Color(0xFFEFE7E2);
  static const onKey = Color(0xFF3E0D16);
  static const flash = Color(0xFFFFC547);
  static const onFlash = Color(0xFF2B1600);
  static const text = Color(0xFFFBF1F1);

  static ThemeData theme(ThemeData base) {
    final scheme = ColorScheme.fromSeed(seedColor: curtain, brightness: Brightness.dark).copyWith(
      surface: curtain,
      onSurface: text,
      primary: flash,
      onPrimary: onFlash,
      secondaryContainer: key,
      onSecondaryContainer: onKey,
    );
    final keyShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: curtain,
      appBarTheme: const AppBarTheme(backgroundColor: curtain, foregroundColor: text, scrolledUnderElevation: 0),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: keyShape)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: text, minimumSize: const Size(48, 48)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: keyShape,
          textStyle: base.textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// The target size in an outlined cell, like a booth's price display, in
/// condensed tabular figures.
class _SpecCells extends StatelessWidget {
  const _SpecCells(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: _Booth.text.withValues(alpha: 0.6), width: 1.5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'BarlowCondensed',
        fontWeight: FontWeight.w600,
        fontSize: 24,
        letterSpacing: 1.5,
        fontFeatures: [FontFeature.tabularFigures()],
        color: _Booth.text,
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.session,
    required this.preview,
    required this.messages,
    required this.l10n,
    required this.thin,
    required this.onAction,
    required this.onContinue,
  });

  final CropSession? session;
  final ui.Image preview;
  final CropMessages messages;
  final AppLocalizations l10n;
  final bool thin;
  final void Function(CropAction) onAction;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final notices = <(IconData, String)>[
      if (s != null && s.upscaleLevel != UpscaleLevel.none)
        (
          s.upscaleLevel == UpscaleLevel.strong ? Icons.warning_amber_rounded : Icons.info_outline,
          messages.upscaleNotice(s.upscaleFactor, s.target)!,
        ),
      if (s != null && s.info.isAnimated) (Icons.gif_box_outlined, messages.animatedNotice),
      if (thin) (Icons.touch_app_outlined, messages.limitedPrecisionHint),
    ];
    Widget tool(CropAction a, IconData icon, String label, {bool repeat = false}) =>
        _ToolButton(icon: icon, label: label, repeat: repeat, onPressed: s == null ? null : () => onAction(a));
    void Function()? act(CropAction a) => s == null ? null : () => onAction(a);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              children: [for (final (icon, text) in notices) _Notice(icon: icon, text: text)],
            ),
          ),
          // The control plate.
          DecoratedBox(
            decoration: BoxDecoration(color: _Booth.plate, borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _Group([
                        tool(
                          CropAction.rotateCounterclockwise,
                          Icons.rotate_left,
                          l10n.cropButtonRotateCounterclockwise,
                        ),
                        tool(CropAction.rotateClockwise, Icons.rotate_right, l10n.cropButtonRotateClockwise),
                        tool(CropAction.zoomOut, Icons.zoom_out, l10n.cropButtonZoomOut, repeat: true),
                        tool(CropAction.zoomIn, Icons.zoom_in, l10n.cropButtonZoomIn, repeat: true),
                      ]),
                      // Physical directions: never mirrored in RTL (FR-23).
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: _Group([
                          tool(CropAction.moveLeft, Icons.west, l10n.cropButtonMoveLeft, repeat: true),
                          tool(CropAction.moveUp, Icons.north, l10n.cropButtonMoveUp, repeat: true),
                          tool(CropAction.moveDown, Icons.south, l10n.cropButtonMoveDown, repeat: true),
                          tool(CropAction.moveRight, Icons.east, l10n.cropButtonMoveRight, repeat: true),
                        ]),
                      ),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(onPressed: act(CropAction.centre), child: Text(l10n.cropButtonCentre)),
                      TextButton(onPressed: act(CropAction.reset), child: Text(l10n.cropButtonReset)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // The print slot beside the flash key: the exact result, then go.
          Row(
            spacing: 16,
            children: [
              if (s != null)
                ExcludeSemantics(
                  child: CropPrint(preview: preview, info: s.info, target: s.target, crop: s.crop, longSide: 56),
                ),
              Expanded(
                child: FilledButton(onPressed: onContinue, child: Text(l10n.cropButtonContinue)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _Booth.notice, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: _Booth.text),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _Booth.text)),
          ),
        ],
      ),
    );
  }
}

/// 48 dp tonal key with a tooltip and label; long-press repeats (FR-27).
class _ToolButton extends StatefulWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed, this.repeat = false});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool repeat;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  Timer? _timer;

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A repeating key keeps long-press for itself: its tooltip shows on hover
    // or focus only, and the label still reaches TalkBack.
    final button = Tooltip(
      message: widget.label,
      triggerMode: widget.repeat ? TooltipTriggerMode.manual : TooltipTriggerMode.longPress,
      child: IconButton.filledTonal(
        onPressed: widget.onPressed,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(widget.icon),
      ),
    );
    if (!widget.repeat || widget.onPressed == null) return button;
    return GestureDetector(
      onLongPressStart: (_) =>
          _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => widget.onPressed?.call()),
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: button,
    );
  }
}
