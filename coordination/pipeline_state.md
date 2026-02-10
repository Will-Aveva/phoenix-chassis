# Pipeline State — Chassis

**Pipeline**: Chassis Founding
**Started**: 2026-02-09
**Scope**: Establish governance infrastructure, write vision and constitution, port windowing primitives from Seek, build framework through 6 phases.

---

## Phase Status

| Phase | Status | Role | Artifact |
|---|---|---|---|
| clarify | ✅ complete | Clarifier | [memo_founding_chassis.md](file:///C:/Users/alpha/source/chassis/coordination/memo/memo_founding_chassis.md) |
| vision | ✅ complete | Visionary | [vision.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/vision.md) |
| constitution | ✅ complete | Constitution Writer | [constitutional_invariants.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/constitutional_invariants.md) |
| spec | ✅ complete | Spec Writer | [spec_framework.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/spec_framework.md), [spec_adopter_theming.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/spec_adopter_theming.md) |
| plan | ✅ complete | Planner | [plan_framework_build.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/plan_framework_build.md) |
| execute (Phase 1) | ✅ complete | Builder | WU-1 Phoenix scaffold |
| execute (Phase 2) | ✅ complete | Builder | WU-2 Layout types, WU-3 Layout ops, WU-4 LayoutManager, WU-5 Shell |
| execute (Phase 3) | ✅ complete | Builder | WU-6..WU-9 (CSS, hooks, persistence, theme spec), WU-10 demo page, WU-11 API manifest |
| audit (Phase 2-3) | ✅ complete | Auditor | Constitutional compliance verified, glossary gaps fixed |
| execute (Phase 4) | ✅ complete | Builder | Integration tests: Shell rendering, drag-drop, tab cycling |
| execute (Phase 5) | ✅ complete | Builder | WU-12 SlotProvider, WU-13 DockPanel, WU-14 Shell refactor, WU-15 LayoutManager wiring, WU-16 CSS remediation, WU-17 Shell tests |
| audit (Phase 5) | ✅ complete | Auditor | §2.5 Presentation Hints amendment, adjacent/3 bug fix, glossary updates |
| execute (Phase 6) | ✅ complete | Builder | WU-24 weight persistence, WU-25 sidebar, WU-26 multi-composition, WU-27 Hex packaging |
| audit (Phase 6) | ⚠️ partial | Auditor | Inline reviews passed; skill-loaded deep reviews pending for Auditor, Constitution Writer, Visionary |
| verify (Phase 6) | 🔲 pending | Builder | WU-28 browser verification |

---

## Events

| Timestamp | Phase | Event |
|---|---|---|
| 2026-02-09 | clarify | Clarifier produced founding memo: identity, bounded domain, vocabulary, module structure |
| 2026-02-09 | setup | Governance scaffolding created: .agent/context, skills, workflows, coordination structure |
| 2026-02-09 | vision | Visionary wrote 5 pillars. Governor reviewed. |
| 2026-02-09 | constitution | Constitution Writer wrote 6 articles. Governor reviewed. |
| 2026-02-09 | spec | Spec Writer produced framework spec (35 INVs) and adopter theming spec. |
| 2026-02-09 | plan | Planner produced build plan: 11 WUs. |
| 2026-02-10 | execute | Phase 1-3 built: scaffolding through demo page. 78 tests passing. |
| 2026-02-10 | audit | Phase 2-3 audited: constitutional compliance verified, glossary updated. |
| 2026-02-10 | execute | Phase 4 built: integration tests added. |
| 2026-02-10 | execute | Phase 5 built: SlotProvider, DockPanel, Shell refactor, LayoutManager wiring. 100 tests passing. |
| 2026-02-10 | audit | Phase 5 audited: §2.5 amendment ratified, adjacent/3 bug fixed. |
| 2026-02-10 | execute | Phase 6 built: WU-24 weight persistence, WU-25 sidebar, WU-26 multi-composition (9/9 handlers), WU-27 Hex packaging. 104 tests passing. |
| 2026-02-10 | audit | Phase 6 inline reviews: Planner, Clarifier, Auditor, Constitution Writer, Visionary — all passed. Deep skill-loaded reviews flagged as pending. |

---

## Pending Decisions

- [ ] Governor: **Approve Phase 6 audit completion** — run Auditor, Constitution Writer, and Visionary with skill-loaded protocols
- [ ] Governor: **WU-28 browser verification** — requires `mix phx.server` and manual testing
- [ ] Governor: **Delivery surface project name** (open decision #2 from founding memo)
- [ ] Governor: **Backend domain name** (open decision #3 from founding memo)
- [ ] Governor: **Hex package vs path dependency** (open decision #4 from founding memo)

---

## Injected Constraints

| Source | Constraint | Target |
|---|---|---|
| Founding Memo | Chassis manages layout, not content. Domain boundary is the primary invariant. | All roles |
| Founding Memo | Use canonical vocabulary: Composition, Slot, Stack, Division, Attach. Deprecated terms prohibited. | All roles |
| Phase 5 Audit | §2.5 Presentation Hints: weights MAY be stored parallel to tree. Must not alter structure. | Builder, Spec Writer |
