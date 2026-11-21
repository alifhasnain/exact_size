---
name: l10n-translate
description: Translate and AI-review the app strings of one language (no native speaker available) — draft, mechanical checks, blind back-translation review, log.
disable-model-invocation: true
argument-hint: "<ar|es|hi|id|pt|pt_BR> [key ...]"
---

Localization for $ARGUMENTS. Product Owner decision 2026-11-21: no native reviewer exists, so this workflow is the only quality gate. Never claim more than "AI-reviewed".

1. **Preconditions.** Read `docs/l10n/ai-review-log.md` (create it from step 6 if missing). Variants are fixed in CLAUDE.md (Localization): pt-BR, es-419, ar MSA with Western digits; answer the vendored skills' variant question with them. For `ar`, check that number formatting in code really produces Western digits (Flutter's default `ar` locale may format Eastern digits [Hypothesis]); if not, list it as an open item. No keys given = the language's keys in `docs/l10n/untranslated_messages.json`.
2. **Draft.** Follow the vendored skill `localize-<lang>` (`pt` and `pt_BR` use `localize-pt`, variant pt-BR). Write `lib/l10n/app_<locale>.arb` using the same keys as `app_en.arb`, same placeholder names and types, same ICU structure; plural/select categories follow the target language's CLDR rules. Reuse the glossary terms already logged for this language. Short plain sentences, one next action per message.
3. **Mechanical checks** (fix until clean): key set equals English (or only the untranslated rest); placeholders identical; ICU parses; no stray English except brand names, units and logged exceptions; run `flutter gen-l10n` and `flutter analyze`. Never hand-edit `lib/l10n/app_localizations*.dart`.
4. **Blind review.** Delegate once to a fresh subagent (general-purpose, a different model than the one drafting). Brief it with the translated strings only, not the English source and not your reasoning: give a literal English back-translation of each string and flag grammar, agreement, register, unnatural phrasing, wrong or inconsistent terms, ambiguous meaning. Then compare each back-translation with the English source yourself and list meaning drift.
5. **Fix and re-check.** One revision round for every flag and drift you agree with, then step 3 again. Keys you and the reviewer still disagree on, and any you cannot judge, go to the open list. High-risk keys (consent, privacy, ads, subscription, store text, messages telling the user what to do after a failure) get a second blind review by a third model if available; list them in the log.
6. **Log.** Add or update this language's section in `docs/l10n/ai-review-log.md`: date, drafting and reviewing models, variant/digit decisions, glossary terms, high-risk keys, open list, status `AI-reviewed only (no native speaker)`. Edit the section; do not rewrite the file.
7. Report in under 150 words: keys done, flags fixed, open list. **STOP.** The Product Owner decides the open list. Do not touch other languages.
