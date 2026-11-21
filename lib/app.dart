import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

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
      home: home ?? const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).appTitle)),
    );
  }
}
