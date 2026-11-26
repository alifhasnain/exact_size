import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';

/// FEAT-016 explainer (FR-2, FR-3, FR-4; G1 design, t13/explainer_design.md): the notice on the
/// booth wall. Static text from the string resources only: no state, image, link, network,
/// permission, log or counter (NFR-6). The title sits in the scroll body so it wraps at 200%.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  /// Maximum line length on tablets and in landscape.
  static const maxContentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final parts = [
      (l.privacyOnPhoneTitle, l.privacyOnPhone), // (a) C1, C3
      (l.privacyOfflineTitle, l.privacyOffline), // (b) C2
      (l.privacyKeptTitle, l.privacyKept), // (c) C4, C5
      (l.privacyCopiesTitle, l.privacyCopies), // (d) C8
      (l.privacyOutsideTitle, l.privacyOutside), // (e) C9
      (l.privacyReadsTitle, l.privacyReads), // (f) C10
    ];
    return Theme(
      data: Booth.theme(Theme.of(context)),
      child: Builder(builder: (context) {
        final text = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(l.privacyTitle, style: text.headlineSmall?.copyWith(color: Booth.text)),
                      ),
                      for (final (title, body) in parts) ...[
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(title, style: text.titleMedium?.copyWith(color: Booth.text, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(body, style: text.bodyLarge?.copyWith(color: Booth.text, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
