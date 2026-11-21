import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/crop_types.dart';
import 'crop_canvas.dart';
import 'crop_controller.dart';
import 'crop_messages.dart';

/// The crop screen (FEAT-002; design: t22/crop_screen_design.md, gate G3).
/// Canvas on top (start side in landscape), notice, tool rows, then Centre,
/// Reset and Continue. Render, progress and errors are wired in T25.
class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({
    super.key,
    required this.preview,
    required this.info,
    required this.target,
    required this.onContinue,
    required this.onChooseAnother,
  });

  final ui.Image preview;
  final SourceInfo info;
  final Target target;
  final void Function(CropSession session) onContinue;
  final VoidCallback onChooseAnother;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  @override
  void initState() {
    super.initState();
    // Providers may not change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cropControllerProvider.notifier).start(widget.info, widget.target);
    });
  }

  Future<void> _continue(CropSession s, CropMessages m, AppLocalizations l10n) async {
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
      if (ok == null || !mounted) return;
      if (!ok) return widget.onChooseAnother();
    }
    widget.onContinue(s);
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
        unawaited(SemanticsService.sendAnnouncement(View.of(context), a.text(m, next.target), Directionality.of(context)));
      }
    });

    final s = session != null && identical(session.info, widget.info) && session.target == widget.target ? session : null;
    final canvas = s == null
        ? const ColoredBox(color: CropCanvas.background, child: SizedBox.expand())
        : CropCanvas(
            preview: widget.preview,
            info: s.info,
            target: s.target,
            crop: s.crop,
            onDrag: controller.drag,
            onPinch: controller.pinch,
          );

    return Scaffold(
      appBar: AppBar(title: Text(m.size(widget.target))),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, box) {
          final landscape = box.maxWidth > box.maxHeight && box.maxWidth >= 600;
          final panel = _Panel(
            session: s,
            messages: m,
            l10n: l10n,
            thin: CropFrameLayout.of(box.biggest, widget.target).thin,
            onAction: controller.perform,
            onContinue: s == null ? null : () => _continue(s, m, l10n),
          );
          if (landscape) {
            return Row(children: [
              Expanded(child: canvas),
              SizedBox(width: 320, child: SingleChildScrollView(child: panel)),
            ]);
          }
          return Column(children: [
            Expanded(child: canvas),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight / 2),
              child: SingleChildScrollView(child: panel),
            ),
          ]);
        }),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.session,
    required this.messages,
    required this.l10n,
    required this.thin,
    required this.onAction,
    required this.onContinue,
  });

  final CropSession? session;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(children: [for (final (icon, text) in notices) _Notice(icon: icon, text: text)]),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _Group([
                tool(CropAction.rotateCounterclockwise, Icons.rotate_left, l10n.cropButtonRotateCounterclockwise),
                tool(CropAction.rotateClockwise, Icons.rotate_right, l10n.cropButtonRotateClockwise),
              ]),
              _Group([
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
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: s == null ? null : () => onAction(CropAction.centre), child: Text(l10n.cropButtonCentre)),
                TextButton(onPressed: s == null ? null : () => onAction(CropAction.reset), child: Text(l10n.cropButtonReset)),
              ]),
              FilledButton(onPressed: onContinue, child: Text(l10n.cropButtonContinue)),
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
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
        Icon(icon, size: 20, color: scheme.onSecondaryContainer),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer)),
        ),
      ]),
    );
  }
}

/// 48 dp tonal icon button with a tooltip and label; long-press repeats
/// (FR-27).
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
    final button = IconButton.filledTonal(
      onPressed: widget.onPressed,
      tooltip: widget.label,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(widget.icon),
    );
    if (!widget.repeat || widget.onPressed == null) return button;
    return GestureDetector(
      onLongPressStart: (_) => _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => widget.onPressed?.call()),
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: button,
    );
  }
}
