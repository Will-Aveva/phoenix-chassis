# Spec Review — Chassis Build Plan

**Reviewer**: Spec Writer
**Date**: 2026-02-09
**Artifact under review**: `coordination/canonical/plan_framework_build.md` (11 Work Units)
**Governing specs**: `spec_framework.md` (35 invariants), `spec_adopter_theming.md` (15 required properties)

---

## Coverage Matrix

Mapping every framework spec invariant to its covering Work Unit.

### §F1 — Domain Boundary (7 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-1.1a (no forbidden imports) | WU-5 (Shell), WU-8 (Sidebar/DockPanel) | ✅ Covered |
| INV-1.1b (slot IDs opaque) | WU-2 (types), WU-3 (operations) | ✅ Covered |
| INV-1.1c (no content-conditional logic) | WU-5 (Shell), WU-7 (hooks) | ✅ Covered |
| INV-1.1d (no content rendering) | WU-5 (Shell — render callback) | ✅ Covered |
| INV-1.2a (API manifest) | WU-11 | ✅ Covered |
| INV-1.2b (no struct leakage) | WU-2 (types), WU-4 (manager API) | ✅ Covered |
| INV-1.2c (no convention imposition) | WU-10 (demo proves minimal integration) | ✅ Covered |

### §F2 — Layout Tree (3 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-2.1 (three node types) | WU-2 | ✅ Covered |
| INV-2.2 (sole representation) | WU-4 (manager stores only tree) | ✅ Covered |
| INV-2.3 (tree validity) | WU-2 (normalization) | ✅ Covered |

### §F3 — Rendering (3 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-3.1 (deterministic) | WU-5 | ✅ Covered |
| INV-3.2 (recursive walk) | WU-5 | ✅ Covered |
| INV-3.3 (no phantom DOM) | WU-5 | ✅ Covered |

### §F4 — Operations (3 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-4.1 (6 core operations) | WU-3 | ✅ Covered |
| INV-4.2 (pure transforms) | WU-3 (tree→tree), WU-4 (manager applies) | ✅ Covered |
| INV-4.3 (content-blind) | WU-3 | ✅ Covered |

### §F5 — Persistence (3 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-5.1 (tree serialization) | WU-9 | ✅ Covered |
| INV-5.2 (round-trip fidelity) | WU-9 | ✅ Covered |
| INV-5.3 (format private) | WU-9 | ✅ Covered |

### §F6 — Styling (4 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-6.1 (zero aesthetic values) | WU-6 | ✅ Covered |
| INV-6.2 (custom properties) | WU-6 | ✅ Covered |
| INV-6.3 (structural CSS) | WU-6 | ✅ Covered |
| INV-6.4 (namespace reserved) | WU-6 | ✅ Covered |

### §F7 — Vocabulary (2 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-7.1 (canonical terms) | WU-2, WU-3, WU-4, WU-5 (all modules) | ✅ Covered |
| INV-7.2 (prohibited terms) | All WUs (negative test) | ✅ Covered |

### §F8 — Contract Surface (4 invariants)

| Invariant | Covered By | Status |
|---|---|---|
| INV-8.1 (input/output contract) | WU-5 (Shell), WU-10 (demo proves it) | ✅ Covered |
| INV-8.2 (render callback, slot ID only) | WU-5 | ✅ Covered |
| INV-8.3 (spatial-only events) | WU-4 (PubSub), WU-7 (hooks) | ✅ Covered |
| INV-8.4 (self-sufficient docs) | WU-11 (API manifest) | ⚠️ Partial |

**All 35 invariants covered. One partial.**

---

## Findings

### S-1: INV-8.4 (Self-Sufficient Docs) Is Partially Covered ⚠️

INV-8.4 states: *"The contract API must be sufficient for integration without reading Chassis source."*

WU-11 produces an API manifest — a list of public modules and functions. But the test criterion T-8.4 requires: *"Integration test: a minimal Phoenix app integrates Chassis using only public API."*  WU-10's demo page proves integration works, but it doesn't prove the *docs* are sufficient — the demo developer (the Builder) has full access to internals.

**Assessment**: This is an audit-phase concern, not a build-phase concern. The Auditor should validate INV-8.4 by attempting integration using only the API manifest. The plan correctly defers this. **No plan change needed** — but the Auditor should note this as a test item.

### S-2: WU-9 Should Wire Into WU-4

WU-9 (Persistence) depends only on WU-2 (types). This is correct for the serialization logic itself. However, the completion test in prompt_01 says: *"Layout state persists across page refresh via LayoutManager GenServer."*

This means WU-4 (LayoutManager) must *use* WU-9's persistence functions. The plan doesn't make this coupling explicit. WU-4's description says "GenServer managing layout tree state" but doesn't mention persistence integration.

**Recommendation**: Add a note to WU-4 or WU-10 that LayoutManager integrates WU-9's persistence on init/terminate. This doesn't change the dependency graph (WU-9 still only depends on WU-2), but WU-10's completion predicate ("layout persists across page refresh") requires WU-9 to be wired into WU-4 before demo verification.

### S-3: Adopter Theming Spec §T1 Property Validation Not Explicitly Assigned

The plan notes that the property table is draft and says the Builder validates during WU-6. But WU-6 doesn't have an explicit step for: *"Compare actual CSS `var(--chassis-*)` references against Adopter Theming Spec §T1 and §T2. Report any mismatches to the Spec Writer."*

**Recommendation**: Add to WU-6's work description: *"Validate that all `var(--chassis-*)` references in `chassis.css` align with the Adopter Theming Spec property tables. If any property is added, renamed, or removed, escalate to Spec Writer for spec amendment."*

### S-4: Vocabulary Verification Has No Dedicated Gate

INV-7.2 (prohibited terms) is listed as covered by "all WUs" — but there's no gating test in any specific WU's completion predicate that runs the prohibited-term grep across the entire codebase.

**Recommendation**: Add to WU-10's completion predicate (the integration gate): *"grep -ri 'workspace\|tab_group\|split_view' lib/ returns empty."* This is a project-wide gate that belongs at the integration WU.

---

## Recommendation

**APPROVE with 3 enrichments** (S-2, S-3, S-4). No structural changes needed. All 35 invariants are covered. The plan correctly partitions work into atomic WUs with clear dependencies.

The enrichments are minor additions to existing WU descriptions and completion predicates — not new WUs or dependency changes.

---

**Status**: Review complete. Routing to Governor for disposition.
