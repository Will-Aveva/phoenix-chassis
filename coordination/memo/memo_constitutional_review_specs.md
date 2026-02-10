# Constitutional Review — Chassis Specifications

**Reviewer**: Constitution Writer
**Date**: 2026-02-09
**Artifacts under review**:
- `coordination/canonical/spec_framework.md` — Framework Spec (35 invariants)
- `coordination/canonical/spec_adopter_theming.md` — Adopter Theming Spec (16 required + 11 optional properties)
**Governing law**: `coordination/canonical/constitutional_invariants.md`

---

## Articles Assessed

All 6 articles reviewed against both specs.

---

## Compliance

### Spec 1 — Framework Spec

| Article | Compliant? | Notes |
|---|---|---|
| I — Domain Boundary | ✅ | §F1 faithfully operationalizes both §1.2 (inward) and §1.3 (outward). The tests in T-1.1a through T-1.2c are falsifiable and mechanically checkable. §1.4 (boundary symmetry) is structurally honored — violations in both directions are classified identically. |
| II — Layout Tree | ✅ | §F2 correctly constrains the tree to exactly three node types. INV-2.3 (tree validity) is a valuable addition — it operationalizes the constitution's implicit requirement that rendering never encounters a malformed tree. |
| III — Theming Discipline | ✅ | §F6 is a direct transcription of Article III into testable form. INV-6.3 correctly enumerates the structural CSS carve-out from §3.4. |
| IV — Canonical Vocabulary | ✅ | §F7 maps the vocabulary table faithfully. |
| V — The Contract | ✅ | §F8 correctly formalizes the contract. INV-8.3 (spatial-only events) is a strong operationalization of §5.4 (no content callbacks). |
| VI — Constitutional Maintenance | N/A | Meta-article — not directly specifiable. Appropriate omission. |

### Spec 2 — Adopter Theming Spec

| Article | Compliant? | Notes |
|---|---|---|
| I — Domain Boundary | ✅ | §T3.3 (no shadowing inside slots) correctly respects the inward boundary — the adopter's theme stops at the slot container. |
| III — Theming Discipline | ✅ | The spec correctly derives from §3.2 (custom properties only) and §3.3 (no default theme). |
| V — The Contract | ✅ | §T4 correctly positions theming as part of the adopter's contract obligation, not Chassis's. |

---

## Violations

### V-1: INV-1.2a Freezes the Public API Prematurely (§5.2 tension)

**Article**: V — The Contract, §5.2 (Contract Stability)
**Location**: Framework Spec §F1.2, INV-1.2a

INV-1.2a enumerates the complete public API surface:

> *Chassis's public API surface consists exclusively of: `Chassis.Layout`, `Chassis.LayoutManager`, `Chassis.Shell`, CSS custom properties, JavaScript hooks*

This is a **spec clause behaving as a plan**. The constitution (§5.2) says the contract must be *explicit, minimal, and stable* — it does not say the contract is *exactly these five items*. The spec has frozen a module list that the Planner and Builder haven't ratified yet.

**Risk**: If the Builder discovers during implementation that the public API needs `Chassis.Sidebar` or `Chassis.DockPanel` (both listed in the founding memo's module structure), INV-1.2a creates a spec-level blocker that requires escalation for what should be a planning-level decision.

**Recommendation**: Replace the enumerated list with a structural invariant: *"The public API surface is documented in a single, maintained API manifest. Modules not in the manifest are internal."* The manifest is a living artifact; the spec governs that the manifest exists and is authoritative — not what's in it.

### V-2: T-T3 Prohibits Fallbacks But Constitution Doesn't (§3.3 gap)

**Article**: III — Theming Discipline, §3.3
**Location**: Adopter Theming Spec, T-T3

T-T3 states: *"`var(--chassis-tab-height, 2rem)` is prohibited — no fallback values in CSS"*

The constitution says *"Chassis MUST NOT ship a default theme"* (§3.3). A CSS fallback value (`var(--chassis-tab-height, 2rem)`) is **not a default theme** — it is a structural default that ensures the layout shell is functional before theming. The Governor explicitly decided against amending §3.3 to distinguish structural from aesthetic defaults, choosing instead to produce an adopter spec. But the spec has now re-introduced the prohibition through a test criterion that is **stricter than the constitution**.

A spec clause may not be more restrictive than its governing constitutional article without explicit constitutional authority. The constitution says "no default theme." The spec says "no fallback values of any kind." These are different claims.

**Recommendation**: Remove T-T3 or weaken it to: *"Aesthetic fallback values (colors, fonts) are prohibited. Structural fallback values (dimensions, display properties) are permitted but discouraged — the adopter spec exists to prevent reliance on them."* This respects the Governor's decision while acknowledging that a collapsed zero-height tab bar serves no one.

### V-3: §T1 Property List Is Speculative

**Article**: III — Theming Discipline, V — The Contract
**Location**: Adopter Theming Spec, §T1

The 16 required properties in §T1 are reasonable projections of what the layout shell will need, but they are **speculative** — no implementation exists yet. The Spec Writer derived them from vision and founding memo, not from a working implementation.

This is not a constitutional violation per se, but it is a **structural risk**: the Builder may discover that the actual CSS architecture requires different, fewer, or additional properties. A spec that enumerates 16 required properties before implementation is a spec that will need amendment.

**Assessment**: This is acceptable at this pipeline stage. The spec should be understood as a **draft property table** that the Builder validates during implementation. The Planner should note this as a spec-Plan coupling point. Not a violation — a constraint the Planner must account for.

---

## Amendments

### Constitutional Amendment: None Required

The constitution does not need to change. The violations are spec-level issues — the constitution correctly describes the invariants, and the specs need minor adjustment to stay within constitutional bounds.

---

## Recommendation

**Spec 1 (Framework Spec): REVISE** — Fix V-1 (replace enumerated API with manifest invariant)
**Spec 2 (Adopter Theming Spec): REVISE** — Fix V-2 (fallback prohibition exceeds constitutional authority). Note V-3 as draft status for Planner.

Both revisions are minor. The specs are well-constructed and faithfully derive from the constitution. The violations are precision errors, not direction errors.

---

**Status**: Review complete. Routing to Governor for disposition on V-1 and V-2.
