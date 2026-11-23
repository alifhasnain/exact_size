import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/crop/presentation/crop_controller.dart';
import 'features/pick/domain/pick_types.dart';
import 'features/pick/presentation/pick_controller.dart';

/// Pick → target step → crop (FEAT-005 tech plan; OQ-4, photo first).
///
/// Leaving the target step is start-over (FEAT-001 FR-11): release the image
/// and end the crop session, but only while [image] is still current. A newer
/// pick or share closes this route with popUntil and must keep its own image
/// and camera file (R2, OQ-T5).
void openTargetStep(BuildContext context, PickedImage image) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TargetRoute(image)));
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
      // shortcut: dev-only stand-in for the target screen, not shipped; T12 replaces it.
      child: Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Target step (FEAT-005): ${image.info.rawWidth} x ${image.info.rawHeight}')),
      ),
    );
  }
}
