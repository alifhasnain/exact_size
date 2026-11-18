---
name: product-brief
description: Stage 1 — clarify the product concept with the Product Owner and fill docs/product/vision.md.
disable-model-invocation: true
argument-hint: "[concept notes]"
---

Stage 1 — Product Understanding. Run in this session; no subagent.

Concept notes from the user (may be empty): $ARGUMENTS

1. Read `docs/product/vision.md`.
2. Ask targeted questions in rounds of at most 5 (use AskUserQuestion when the options are clear). Cover what is still unknown:
   - problem and who has it; target user segments; primary jobs-to-be-done
   - unique value proposition; why now
   - platforms and markets (Bangladesh only? regional? global?); languages
   - monetisation; success metrics
   - constraints: budget, timeline, team, regulation
   - does it handle money, payments or personal data? (drives compliance scope)
   - explicitly out of scope
3. After each round, update the matching sections of `vision.md`. Tag guesses `[Assumption]`; keep unknowns under Open questions. Keep `status: Proposed` (or `Under Discussion` once the user is reviewing).
4. When the core sections are filled, present: a 5-line summary, assumptions, open questions, risks, and whether you think it is ready for competitor research.
5. **STOP.** Tell the user to correct anything, or run `/approve BRIEF` to sign off. Then `/research-competitors`.
