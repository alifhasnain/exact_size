---
name: discover-features
description: Stage 3 — brainstorm and evaluate candidate features into the roadmap backlog via the product-analyst subagent.
disable-model-invocation: true
argument-hint: "[themes to focus on]"
---

Stage 3 — Feature Discovery.

1. Check `docs/research/competitors.md` has `status: Approved`. If not, say so and stop.
2. Delegate to the **product-analyst** subagent. Brief: feature discovery job; read `docs/product/vision.md`, `docs/research/competitors.md`, `docs/roadmap.md`; add 15–30 candidate features to the Backlog table (core features from the vision plus value-adds from research gaps); themes: $ARGUMENTS.
3. Read the Backlog table. Check for duplicates, features with no clear user value, and missing core features.
4. Present the candidates grouped by theme, with your view on the strongest and weakest few.
5. **STOP.** The user adds, removes, merges or rejects features (record rejections with `/approve FEAT-nnn reject "reason"`). When the list is right, the user runs `/prioritize`.
