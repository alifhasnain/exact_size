---
name: prioritize
description: Stage 4 — RICE scoring and MoSCoW release bucketing of the backlog via the product-analyst subagent.
disable-model-invocation: true
argument-hint: "[score adjustments, e.g. FEAT-004 reach=2000]"
---

Stage 4 — Feature Prioritization.

1. Read `docs/roadmap.md`.
2. If `$ARGUMENTS` contains score adjustments and features are already scored, apply them yourself (edit the cells, recompute Score = R×I×C÷E, re-sort) — no subagent needed. Otherwise delegate to the **product-analyst** subagent. Brief: prioritization job on every non-rejected Backlog feature in `docs/roadmap.md`; read `docs/product/vision.md` for constraints; fill RICE, MoSCoW, Release (MVP / Next / Later) and Rationale; draft the Milestones section.
3. Present: the ranked table, the MVP cut line, borderline features and why, and which scores rest on assumptions.
4. **STOP.** The user adjusts scores or buckets (re-run `/prioritize <adjustments>`), then runs `/approve ROADMAP`. Then `/draft-prd FEAT-nnn` for the first MVP feature.
