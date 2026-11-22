import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../domain/pick_types.dart';
import 'pick_controller.dart';
import 'pick_messages.dart';

/// The pick screen's look (FEAT-001-T16 design, gate G3): the front of the ID
/// photo booth. It draws a [PickState] and reports taps; [PickScreen] wires it.
/// When a system screen or the opening step ends, focus returns to the button
/// that was used (AC-7.1, T18).
class PickView extends StatefulWidget {
  const PickView({
    super.key,
    required this.state,
    required this.onLaunch,
    required this.onCancel,
    this.showFiles = true,
  });

  final PickState state;
  final void Function(PickSource source) onLaunch;
  final VoidCallback onCancel;

  /// "Choose from files" is a Should (FR-21, T22).
  final bool showFiles;

  @override
  State<PickView> createState() => _PickViewState();
}

class _PickViewState extends State<PickView> {
  final _focus = {for (final s in PickSource.values) s: FocusNode()};

  @override
  void didUpdateWidget(PickView old) {
    super.didUpdateWidget(old);
    final source = widget.state.lastSource;
    if (old.state.phase != PickPhase.idle && widget.state.phase == PickPhase.idle && source != null) {
      // After the frame: the keys come back only now if the opening step hid them.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus[source]!.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final opening = state.phase == PickPhase.opening && state.showProgress;
    return Theme(
      data: Booth.theme(Theme.of(context)),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 56),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Semantics(
                          header: true,
                          child: BoothSpecCell(l.appTitle),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      _Cabin(
                        child: opening
                            ? _Opening(label: l.pickOpening, onCancel: widget.onCancel)
                            : _Keys(
                                state: state,
                                l: l,
                                showFiles: widget.showFiles,
                                onLaunch: widget.onLaunch,
                                focus: _focus,
                              ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      _Plaque(text: l.pickPrivacyNote, style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lit cabin window: a darker plate with the booth light falling from above.
class _Cabin extends StatelessWidget {
  const _Cabin({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    // BoxDecoration ignores color when a gradient is set: plate first, light on top.
    decoration: BoxDecoration(
      color: Booth.plate,
      borderRadius: BorderRadius.circular(24),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0x33FFE3BD), Color(0x00FFE3BD)],
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );
}

class _Keys extends StatelessWidget {
  const _Keys({
    required this.state,
    required this.l,
    required this.showFiles,
    required this.onLaunch,
    required this.focus,
  });
  final PickState state;
  final AppLocalizations l;
  final bool showFiles;
  final void Function(PickSource) onLaunch;
  final Map<PickSource, FocusNode> focus;

  @override
  Widget build(BuildContext context) {
    final message = state.message;
    final big = Theme.of(context).textTheme.titleMedium;
    const tall = Size.fromHeight(64);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null)
          Semantics(
            liveRegion: true,
            child: BoothNotice(
              icon: Icons.error_outline,
              text: message.text(l),
            ),
          ),
        FilledButton.icon(
          focusNode: focus[PickSource.camera],
          style: FilledButton.styleFrom(minimumSize: tall, textStyle: big),
          onPressed: state.cameraAvailable
              ? () => onLaunch(PickSource.camera)
              : null,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l.pickTakePhoto),
        ),
        if (!state.cameraAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Booth.text),
                Expanded(
                  child: Text(
                    l.pickNoCamera,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Booth.text),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          focusNode: focus[PickSource.gallery],
          style: FilledButton.styleFrom(minimumSize: tall, textStyle: big),
          onPressed: () => onLaunch(PickSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l.pickChooseGallery),
        ),
        if (showFiles) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            focusNode: focus[PickSource.files],
            onPressed: () => onLaunch(PickSource.files),
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(l.pickChooseFiles),
          ),
        ],
      ],
    );
  }
}

/// "Opening your photo…" with Cancel, shown after 500 ms (FR-13).
class _Opening extends StatelessWidget {
  const _Opening({required this.label, required this.onCancel});
  final String label;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      spacing: 16,
      children: [
        const SizedBox(height: 8),
        const CircularProgressIndicator(color: Booth.flash),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Booth.text),
        ),
        TextButton(
          onPressed: onCancel,
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    ),
  );
}

/// The privacy line as a small plaque on the booth front (FR-22).
class _Plaque extends StatelessWidget {
  const _Plaque({required this.text, required this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      const Icon(Icons.lock_outline, size: 18, color: Booth.text),
      Expanded(
        child: Text(
          text,
          style: style?.copyWith(color: Booth.text.withValues(alpha: 0.85)),
        ),
      ),
    ],
  );
}
