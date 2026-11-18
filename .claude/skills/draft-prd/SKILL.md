---
name: draft-prd
description: Stage 5 — write a modular PRD for one prioritized feature via the product-analyst subagent.
disable-model-invocation: true
argument-hint: "FEAT-nnn"
---

Stage 5 — Feature Documentation for $ARGUMENTS (one feature per run).

1. Check `docs/roadmap.md` has `status: Approved` and contains $ARGUMENTS (not Rejected). If not, say so and stop.
2. If `docs/features/$ARGUMENTS-*/prd.md` already exists, this is a revision: ask the user what to change and edit only those sections, following the change rules in CLAUDE.md.
3. Otherwise delegate to the **product-analyst** subagent. Brief: PRD job for $ARGUMENTS; read its Backlog row in `docs/roadmap.md`, `docs/product/vision.md`, relevant parts of `docs/research/competitors.md`, and `docs/_templates/prd.md`; create `docs/features/$ARGUMENTS-<short-slug>/prd.md`.
4. Read the PRD. Check that requirements are testable, every story has acceptance criteria, and the Compliance & Data Privacy section is real.
5. Present: a short summary, the requirement list, notable edge cases, open questions.
6. **STOP.** The user edits or runs `/approve $ARGUMENTS`. Then `/tech-plan $ARGUMENTS`.
