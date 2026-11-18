---
name: research-competitors
description: Stage 2 — competitor and market research via the product-researcher subagent.
disable-model-invocation: true
argument-hint: "[focus areas or named competitors]"
---

Stage 2 — Competitor Research.

1. Check `docs/product/vision.md` has `status: Approved`. If not, say so and stop.
2. Delegate to the **product-researcher** subagent (one run, not parallel). Brief: read `docs/product/vision.md`; focus: $ARGUMENTS; write per-competitor files and the summary in `docs/research/`.
3. Read `docs/research/competitors.md` only (not every competitor file). Check that claims are tagged and challenge weak or unsourced ones.
4. Present: a short landscape table, top gaps and opportunities, what is fact vs hypothesis, and gaps in the research. Recommend.
5. **STOP.** The user can correct, ask for deeper research on something, or run `/approve RESEARCH`. Then `/discover-features`.
