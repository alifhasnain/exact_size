---
name: handoff
description: Stage 7 — implementation-ready task breakdown with requirement traceability via the software-architect subagent.
disable-model-invocation: true
argument-hint: "FEAT-nnn"
---

Stage 7 — Development Handoff for $ARGUMENTS.

1. Check that `prd.md` and `tech.md` in `docs/features/$ARGUMENTS-*/` are both `Approved`, and every ADR that `tech.md` links to is `Approved`. If not, list what is missing and stop.
2. Delegate to the **software-architect** subagent. Brief: handoff job for $ARGUMENTS; read its `prd.md`, `tech.md`, linked ADRs and `docs/_templates/tasks.md`; write `tasks.md` in the feature folder with ordered tasks and the traceability table.
3. Read `tasks.md`. Check every FR/NFR maps to a task, each task has a verifiable "Done when", and the order respects dependencies.
4. Present: milestone summary, task count and order, anything that could not be traced.
5. **STOP.** The user runs `/approve $ARGUMENTS-TASKS`. After that, implementation goes one task at a time: "implement $ARGUMENTS-T01".
