---
name: tech-plan
description: Stage 6 — technical plan and ADRs for one approved feature via the software-architect subagent.
disable-model-invocation: true
argument-hint: "FEAT-nnn"
---

Stage 6 — Technical Planning for $ARGUMENTS.

1. Check `docs/features/$ARGUMENTS-*/prd.md` has `status: Approved`. If not, say so and stop.
2. Delegate to the **software-architect** subagent. Brief: tech plan job for $ARGUMENTS; read its `prd.md`, `docs/adr/`, `docs/product/vision.md`, `docs/_templates/tech.md` and `docs/_templates/adr.md`; write `tech.md` in the feature folder and a new ADR for each decision costly to reverse (propose a stack ADR first if none exists).
3. Read `tech.md` and any new ADRs. Check the plan covers every FR/NFR and that risks are concrete.
4. Present: recommended approach, the main alternative and trade-offs, top risks, and each ADR that needs a decision.
5. **STOP.** The user decides each ADR (`/approve ADR-nnn` or `/approve ADR-nnn reject "reason"`) and the plan (`/approve $ARGUMENTS-TECH`). Then `/handoff $ARGUMENTS`.
