import 'package:material_ui/material_ui.dart';

// The ID photo booth world (FEAT-002-T22 direction, extended to the pick
// screen in FEAT-001-T16): palette, theme, spec cell and notice line.

/// The ID photo booth palette. Fixed in both app themes (the booth is the same
/// booth day or night); every text pair meets WCAG AA.
abstract final class Booth {
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
class BoothSpecCell extends StatelessWidget {
  const BoothSpecCell(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Booth.text.withValues(alpha: 0.6), width: 1.5),
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
        color: Booth.text,
      ),
    ),
  );
}

/// A notice line: icon plus text on the notice tone (never colour alone).
class BoothNotice extends StatelessWidget {
  const BoothNotice({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Booth.notice, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: Booth.text),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Booth.text)),
          ),
        ],
      ),
    );
  }
}
