import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'features/pick/domain/pick_types.dart';
import 'features/pick/presentation/pick_controller.dart';
import 'features/pick/presentation/pick_screen.dart';
import 'l10n/app_localizations.dart';

class ExactSizeApp extends StatelessWidget {
  const ExactSizeApp({super.key, this.locale, this.home});

  /// Forces a locale (tests); null follows the device locale.
  final Locale? locale;

  /// Replaces the home screen (tests and demos).
  final Widget? home;

  /// Placeholder seed: no brand colours yet (PRODUCT.md). Every colour comes
  /// from a Material role, so a brand only changes this value.
  static const _seed = Color(0xFF00696B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)),
      locale: locale,
      // Not AppLocalizations.localizationsDelegates: gen-l10n still emits the
      // deprecated flutter_localizations Material/Cupertino delegates, which
      // material_ui's MaterialApp does not accept.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home ?? const PickScreen(onPicked: _openNextStep),
    );
  }
}

/// Pick → target step → crop (OQ-4, photo first).
void _openNextStep(BuildContext context, PickedImage image) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _NextStepPlaceholder(image)));
}

// shortcut: dev-only stand-in for the target step, not shipped; replace when
// FEAT-005/FEAT-011 build it. Leaving it is start-over: release() (FR-11).
class _NextStepPlaceholder extends ConsumerWidget {
  const _NextStepPlaceholder(this.image);
  final PickedImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(pickControllerProvider.notifier).release();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Target step (FEAT-005/011): ${image.info.rawWidth} x ${image.info.rawHeight}')),
      ),
    );
  }
}
