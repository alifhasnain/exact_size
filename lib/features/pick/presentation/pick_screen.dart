import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../crop/presentation/crop_controller.dart';
import '../domain/pick_types.dart';
import 'pick_controller.dart';
import 'pick_view.dart';

/// The app's start screen (OQ-4: photo first, FEAT-001 owns it). Draws
/// [PickController]'s state with the G3 design ([PickView]) and hands every
/// newly accepted image to the flow once (FR-1, FR-5, FR-13, FR-16).
class PickScreen extends ConsumerWidget {
  const PickScreen({super.key, required this.onPicked});

  /// The next step (the target step, then crop). Called once per accepted image,
  /// with this screen as the only route below it.
  final void Function(BuildContext context, PickedImage image) onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pickControllerProvider.select((s) => s.current), (previous, next) {
      if (next == null || identical(previous, next)) return;
      // A new image replaces the session: close any later step and its crop state.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.read(cropControllerProvider.notifier).end();
      onPicked(context, next);
    });
    final controller = ref.read(pickControllerProvider.notifier);
    return PickView(
      state: ref.watch(pickControllerProvider),
      onLaunch: controller.launch,
      onCancel: controller.cancelOpening,
    );
  }
}
