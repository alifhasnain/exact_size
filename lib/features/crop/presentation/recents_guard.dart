import 'dart:io';
import 'dart:ui';

import 'package:es_codec/es_codec.dart' show androidSdkInt;
import 'package:flutter/widgets.dart';
import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

/// Platform side of [RecentsGuard], swappable in tests.
abstract interface class RecentsBinding {
  int get sdkInt;

  /// `Activity.setRecentsScreenshotEnabled(enabled)` (API 33+).
  void setRecentsScreenshotEnabled(bool enabled);
}

/// The real binding: the current Activity through jni_flutter, used in one
/// synchronous block (no stale Activity across an await).
final class AndroidRecentsBinding implements RecentsBinding {
  const AndroidRecentsBinding();

  @override
  int get sdkInt => Platform.isAndroid ? androidSdkInt() : 0;

  @override
  void setRecentsScreenshotEnabled(bool enabled) {
    final engineId = PlatformDispatcher.instance.engineId;
    if (engineId == null) return;
    final activity = androidActivity(engineId);
    if (activity == null) return;
    try {
      activity.jClass.instanceMethodId('setRecentsScreenshotEnabled', '(Z)V').call(activity, jvoid.type, [enabled]);
    } finally {
      activity.release();
    }
  }
}

/// Hides the screen below it from the recent-apps thumbnail on Android 13+
/// while it is shown (FR-26, Product Owner decision OQ-8): off when inserted,
/// back on when removed. Screenshots are not blocked (no FLAG_SECURE), and
/// older Android versions get no protection. Reference-counted (FEAT-006): with guards
/// stacked on several routes, only the first insert turns protection on and only the
/// last removal turns it off again.
class RecentsGuard extends StatefulWidget {
  const RecentsGuard({super.key, required this.child, this.binding = const AndroidRecentsBinding()});

  final Widget child;
  final RecentsBinding binding;

  /// `setRecentsScreenshotEnabled` exists from API 33 (Android 13).
  static const minSdk = 33;

  static int _depth = 0;

  @override
  State<RecentsGuard> createState() => _RecentsGuardState();
}

class _RecentsGuardState extends State<RecentsGuard> {
  late final bool _active = widget.binding.sdkInt >= RecentsGuard.minSdk;

  @override
  void initState() {
    super.initState();
    if (_active && RecentsGuard._depth++ == 0) widget.binding.setRecentsScreenshotEnabled(false);
  }

  @override
  void dispose() {
    if (_active && --RecentsGuard._depth == 0) widget.binding.setRecentsScreenshotEnabled(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
