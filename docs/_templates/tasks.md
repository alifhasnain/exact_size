---
id: FEAT-nnn-TASKS
title: <Feature name> — Implementation Tasks
status: Proposed
version: 0.1
updated: YYYY-MM-DD
links: [FEAT-nnn, FEAT-nnn-TECH]
---

# FEAT-nnn — Implementation Tasks

Milestone: <name from roadmap>. Work top to bottom, one task at a time.

## Tasks

### - [ ] FEAT-nnn-T01 — <short title>
- **Implements:** FR-1, NFR-2 · **ADRs:** ADR-nnn
- **Depends on:** — 
- **Size:** S / M (≤1 day, one PR)
- **Scope:** files / modules to touch
- **Done when:** verifiable check (test passes, screen shows X, API returns Y)

### - [ ] FEAT-nnn-T02 — …

## Traceability
| Requirement | Tasks |
|---|---|
| FR-1 | T01 |

Every FR/NFR in the PRD must appear here.

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and the linked ADRs before starting a task.
- Implement only the current task; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- If a requirement is unclear or wrong, stop and propose a PRD change.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | YYYY-MM-DD | First draft |
