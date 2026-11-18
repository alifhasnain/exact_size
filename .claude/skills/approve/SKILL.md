---
name: approve
description: Record the Product Owner's decision on a document — approve, reject, reopen for discussion, or mark implemented.
disable-model-invocation: true
argument-hint: "<ID> [reject|discuss|implemented] [\"note\"]"
---

The Product Owner typed this command. It is the only way a status becomes `Approved`, `Rejected` or `Implemented`.

Arguments: $ARGUMENTS

1. **Resolve the ID to a file:**
   - `BRIEF` → `docs/product/vision.md`
   - `RESEARCH` → `docs/research/competitors.md`
   - `ROADMAP` → `docs/roadmap.md`
   - `FEAT-nnn` → `docs/features/FEAT-nnn-*/prd.md` (if no folder yet: the feature's row in `docs/roadmap.md`)
   - `FEAT-nnn-TECH` → `tech.md`, `FEAT-nnn-TASKS` → `tasks.md` in that folder
   - `ADR-nnn` → `docs/adr/ADR-nnn-*.md`

   If nothing matches or it is ambiguous, ask and stop.
2. **Decision:** no keyword → `Approved`; `reject` → `Rejected`; `discuss` → `Under Discussion`; `implemented` → `Implemented` (only for `FEAT-nnn`, and only if every task in its `tasks.md` is ticked).
3. **Before approving**, check: no blocking open questions, no empty required sections, and the docs it depends on are already Approved. If anything fails, list it and ask whether to approve anyway. Change nothing until the user answers.
4. **Apply:** set `status` and `updated` (today) in the frontmatter. If approving a `0.x` version, set `version: 1.0`. For `FEAT-nnn`, also update its Status cell in `docs/roadmap.md`. For an ADR that replaces another, mark the old one `Superseded` and link both.
5. **Log:** append a row to `docs/product/decisions.md`: date | ID | decision | version | note.
6. Report what changed and name the next command. Do not start it.
