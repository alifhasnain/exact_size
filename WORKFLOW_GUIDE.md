# ExactSize — How the Product Workflow Works

A plain-language guide to the commands, the documents, and the abbreviations (OQ-1, FR-3, AC-2.1 …) used in this repo.

---

## 1. The big picture

You are the **Product Owner** — you make every decision. Claude is the orchestrator and calls in three specialist helpers (subagents) when a stage needs deep work:

| Helper | Does | Used by |
|---|---|---|
| **product-researcher** | Competitor and market research on the web | `/research-competitors` |
| **product-analyst** | Feature ideas, scoring, PRDs | `/discover-features`, `/prioritize`, `/draft-prd` |
| **software-architect** | Technical plan, ADRs, task breakdown | `/tech-plan`, `/handoff` |

Every stage ends the same way: Claude shows findings → options → a recommendation → **stops and waits for you**. Nothing moves forward until you say so.

---

## 2. The stages and their commands

```
 Product-level (done once)                 Feature-level (repeat for each feature)
 ─────────────────────────                 ───────────────────────────────────────
 1 /product-brief        → /approve BRIEF
 2 /research-competitors → /approve RESEARCH
 3 /discover-features    (review the list)
 4 /prioritize           → /approve ROADMAP
                                            5 /draft-prd FEAT-xxx  → /approve FEAT-xxx
                                            6 /tech-plan FEAT-xxx  → /approve ADR-xxx (each)
                                                                   → /approve FEAT-xxx-TECH
                                            7 /handoff FEAT-xxx    → /approve FEAT-xxx-TASKS
                                            8 "implement FEAT-xxx-T01", T02, …
                                                                   → /approve FEAT-xxx implemented
```

| # | Command | What it does | Writes to | You finish it with |
|---|---|---|---|---|
| 1 | `/product-brief [notes]` | Asks you questions, fills the product vision | `docs/product/vision.md` | `/approve BRIEF` |
| 2 | `/research-competitors [focus]` | Researches competitors; tags each claim Fact or Hypothesis | `docs/research/` | `/approve RESEARCH` |
| 3 | `/discover-features [themes]` | Brainstorms candidate features into the backlog | `docs/roadmap.md` | Review, then run `/prioritize` |
| 4 | `/prioritize [adjustments]` | Scores features (RICE), buckets them (MoSCoW, release) | `docs/roadmap.md` | `/approve ROADMAP` |
| 5 | `/draft-prd FEAT-xxx` | Writes the full spec for **one** feature | `docs/features/FEAT-xxx-*/prd.md` | `/approve FEAT-xxx` |
| 6 | `/tech-plan FEAT-xxx` | Technical design + ADRs for big decisions | `tech.md`, `docs/adr/` | `/approve ADR-xxx`, then `/approve FEAT-xxx-TECH` |
| 7 | `/handoff FEAT-xxx` | Breaks the feature into small coding tasks | `tasks.md` | `/approve FEAT-xxx-TASKS` |
| 8 | "implement FEAT-xxx-T01" (plain words) | Builds one task, ticks it, adds a changelog line | app code, `docs/CHANGELOG.md` | After all tasks: `/approve FEAT-xxx implemented` |

**Order rules (each command checks these and refuses if not met):**
- `/research-competitors` needs BRIEF approved.
- `/discover-features` needs RESEARCH approved.
- `/draft-prd` needs ROADMAP approved.
- `/tech-plan` needs that feature's PRD approved.
- `/handoff` needs PRD + TECH + the linked ADRs approved.
- No code is written until PRD, TECH and TASKS are all approved.

**Feature order tip:** do upstream features first. FEAT-002 (crop/resize) produces the input for FEAT-004 (compression), so tech-plan FEAT-002 before FEAT-004.

---

## 3. `/approve` — the only gate

`/approve` is the **only** way a document's status changes to Approved, Rejected or Implemented. Claude can never do this on its own.

| You type | Result |
|---|---|
| `/approve FEAT-004` | Approved (first approval sets version 1.0) |
| `/approve FEAT-007 reject "reason"` | Rejected (kept in the table, ID never reused) |
| `/approve FEAT-004 discuss` | Back to Under Discussion |
| `/approve FEAT-004 implemented` | Implemented (only when every task is ticked) |

Before approving, it checks: no **blocking** open questions, no empty sections, and the documents it depends on are already approved. Every decision gets a row in `docs/product/decisions.md`.

**IDs you can approve:**

| ID | File |
|---|---|
| `BRIEF` | `docs/product/vision.md` |
| `RESEARCH` | `docs/research/competitors.md` |
| `ROADMAP` | `docs/roadmap.md` |
| `FEAT-004` | `docs/features/FEAT-004-*/prd.md` |
| `FEAT-004-TECH` | `docs/features/FEAT-004-*/tech.md` |
| `FEAT-004-TASKS` | `docs/features/FEAT-004-*/tasks.md` |
| `ADR-001` | `docs/adr/ADR-001-*.md` |

---

## 4. Statuses and versions

```
Proposed ──► Under Discussion ──► Approved ──► Implemented
    └──────────────┴──────────────► Rejected (final)        ADRs can also become Superseded
```

- **Drafts** are version `0.x`. The first approval makes it `1.0`.
- **Changing an approved document** (you ask for a change): version goes up (1.0 → 1.1), a Change log line is added, status goes back to *Under Discussion*, and you re-run `/approve`. This is why BRIEF went 1.0 → 1.1 → 1.2 → 1.3.
- Git keeps all history; no copies of old versions are kept.

---

## 5. Abbreviations and IDs — what OQ-1, FR-3, AC-2.1 mean

**Important:** most of these numbers are **local to one document**. "OQ-1" in the FEAT-004 PRD and "OQ-1" in the FEAT-002 PRD are different questions. Always read them as "FEAT-004 OQ-1", "FEAT-002 OQ-5", and so on.

| Code | Stands for | What it is | Where it lives |
|---|---|---|---|
| **FEAT-004** | Feature | One feature in the backlog. Global, never reused. | `docs/roadmap.md` |
| **US-3** | User Story | "As a [user], I want [action], so that [outcome]." | PRD section 4 |
| **AC-3.2** | Acceptance Criterion | A testable check for a story: *Given … when … then …*. AC-3.2 = 2nd check of US-3. | PRD section 4 |
| **FR-8** | Functional Requirement | Something the app **shall do** ("The system shall …"). | PRD section 6 |
| **NFR-1** | Non-Functional Requirement | **How well** it must do it: speed, memory, privacy, languages, accessibility. | PRD section 7 |
| **OQ-2** | Open Question | Something not decided yet. `[ ]` = open, `[x]` = decided. Marked **blocking** if approval must wait. | Last section of a doc |
| **ADR-001** | Architecture Decision Record | One big, hard-to-reverse technical choice (e.g. Flutter, which JPEG encoder), with options compared. | `docs/adr/` |
| **FEAT-004-T01** | Task | One small coding job (≤ 1 day, one PR) traced back to FRs. | `tasks.md` |
| **A1–A4** | Assumption tests | The brief's key assumptions, checked in research (e.g. A4 = "forms set minimum KB"). | `docs/research/competitors.md` |
| **R1** | Release 1 | The first public release (old M1 + M2 merged). | Roadmap Milestones |
| **Phase A / B** | Build phases of R1 | A = core engine in English; B = languages, ads, subscription, polish. Shipped together. | Roadmap Milestones |
| **pw** | Person-week | One week of your full-time work (with Claude Code). R1 ≈ 20.2 pw ≈ 5 months. | Roadmap |

**Claim tags** you'll see in documents:
- `[Fact](link)` — backed by a source.
- `[Hypothesis]` — a reasoned guess to be tested.
- `[Assumption]` — a working number or belief we chose (e.g. "10,000 users per quarter"); change it when real data arrives.

**Prioritisation terms:**
- **RICE** = Reach × Impact × Confidence ÷ Effort → a score for ranking. Higher = do sooner.
- **MoSCoW** = Must / Should / Could / Won't. In R1: Must = can't ship without; Should = planned, first to cut if late; Could = nice to have.

### Example: reading FEAT-004's open questions

| ID | Question | Status |
|---|---|---|
| FEAT-004 OQ-1 | Which KB rule? (1000 vs 1024 bytes) | Decided: file must satisfy both |
| FEAT-004 OQ-2 | Pad small files to reach the minimum? | Decided: yes, via JPEG comment, disclosed |
| FEAT-004 OQ-3 … OQ-11 | PNG colour reduction, decimal KB, colour profile, quality floor, min Android version … | Open — resolved in Stage 6 or later |

---

## 6. Where everything lives

```
CLAUDE.md                      Rules Claude follows in this repo (gates, IDs, privacy)
.claude/agents/                The 3 specialist helpers
.claude/skills/                The 8 commands (/product-brief … /approve)
docs/
  product/vision.md            BRIEF — what we're building and why
  product/decisions.md         Every decision you made, in order  ← best "where are we?" file
  research/competitors.md      RESEARCH summary (+ competitors/ detail files)
  roadmap.md                   ROADMAP — backlog, scores, milestones
  features/FEAT-xxx-slug/      prd.md, tech.md, tasks.md per feature
  adr/                         Architecture decisions
  _templates/                  Blank templates the helpers fill
  CHANGELOG.md                 One line per finished coding task
```

---

## 7. Everyday situations

| You want to … | Do this |
|---|---|
| Change something in an approved doc | Just ask in plain words ("change X to Y"). Claude edits, bumps the version, sets *Under Discussion*. Then `/approve <ID>`. |
| Reject a feature | `/approve FEAT-xxx reject "reason"` |
| Answer an open question | Tell Claude the answer; it ticks the OQ and logs it. |
| Re-score features | `/prioritize FEAT-015 reach=8000` (or describe it in words) |
| See where you are | Open `docs/product/decisions.md` (latest rows) and the Milestones section of `docs/roadmap.md`. |
| Save progress | Ask Claude to commit after each approval. |
| Switch computers | `git push` here → `git pull` (or clone) there → paste the resume prompt below. |

**Resume prompt for a new session or machine:**

```text
We're continuing the ExactSize product workflow in this repo. Read CLAUDE.md, docs/product/decisions.md (especially the last 10 rows), and the Milestones section of docs/roadmap.md. Give me a 5-line status summary and the next step, then wait. Don't start any stage until I run its command.
```

---

## 8. Where we are now (2026-11-19)

| Done | Status |
|---|---|
| BRIEF | Approved v1.3 |
| RESEARCH | Approved v1.0 |
| ROADMAP | Approved v1.1 (effort re-estimate deferred to Stage 6) |
| FEAT-004 PRD (min–max KB compression) | Approved v1.0 |
| FEAT-002 PRD (crop & resize) | Approved v1.0 |

**Next commands, in order:**
1. `/tech-plan FEAT-002` → approve its ADRs and `FEAT-002-TECH`
2. `/tech-plan FEAT-004` → approve its ADRs and `FEAT-004-TECH`
3. Update the roadmap effort numbers (deferred from Stage 4) → `/approve ROADMAP`
4. `/handoff FEAT-002`, `/handoff FEAT-004` → approve the TASKS
5. Start coding: "implement FEAT-002-T01"
6. Meanwhile, draft the other Phase A PRDs (FEAT-001, 005, 006, 007, 011, 014, 016, 018) with `/draft-prd`.
