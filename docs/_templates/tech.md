---
id: FEAT-nnn-TECH
title: <Feature name> — Technical Plan
status: Proposed
version: 0.1
updated: YYYY-MM-DD
links: [FEAT-nnn]   # plus ADR IDs relied on
---

# FEAT-nnn — Technical Plan

## 1. Summary
Approach in 3–5 sentences.

## 2. Architecture impact
New or changed modules, screens, services. (Mermaid component diagram optional.)

## 3. Components
| Component | Layer (UI / state / domain / data / backend) | Responsibility | New / changed |
|---|---|---|---|

## 4. API contracts
```
METHOD /path
Request:  { … }
Response: { … }
Errors:   4xx/5xx cases
```

## 5. Data model
Entities, fields, relationships, local vs server storage, migrations.

## 6. Integrations
Third-party SDKs/services, what data leaves the device.

## 7. Security & privacy
Auth, secret storage, data at rest/in transit, PCI-DSS scope, logging (no sensitive data in logs).

## 8. Requirement coverage
| Requirement | How it is met |
|---|---|
| FR-1 | |

## 9. Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|

## 10. Decisions
ADRs this plan relies on or proposes: ADR-nnn …

## 11. Deliberately left out

## 12. Open questions

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | YYYY-MM-DD | First draft |
