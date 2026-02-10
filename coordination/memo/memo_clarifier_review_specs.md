# Clarifier Review — Chassis Specifications

**Reviewer**: Clarifier
**Date**: 2026-02-09
**Charge**: Legibility — can the intended audience read these specs and know exactly what to do?
**Artifacts under review**:
- `coordination/canonical/spec_framework.md` (audience: Builder)
- `coordination/canonical/spec_adopter_theming.md` (audience: adopter application developers)

---

## Intent

These two specs serve different audiences with different needs:
- **Framework Spec** → the Builder. They need falsifiable invariants to build against.
- **Adopter Theming Spec** → application developers integrating Chassis. They need a clear, bounded obligation.

The legibility bar is different for each. The Builder is inside the governance process and has access to the full artifact chain. The adopter may have never seen the vision or constitution.

---

## Shape

Both specs follow the Spec Writer output schema (Derived From → Invariants → Boundary → Test Criteria). The structure is consistent and navigable.

---

## Observations

### O-1: Framework Spec Is Legible to Its Audience ✅

The Framework Spec reads well for a Builder who has the vision and constitution in context. The invariant naming (`INV-1.1a` through `INV-8.4`) provides unambiguous reference handles. The test criteria are mechanically checkable. No legibility issues found.

### O-2: Adopter Theming Spec Has a Legibility Gap — "Required vs. Functional" Ambiguity

§T1 is titled **"Required Theme Properties"** and states these MUST be defined *"for a functional layout shell."* But several of the "required" properties are aesthetic identifiers, not structural necessities:

| Property | Is This Structurally Required? |
|---|---|
| `--chassis-tab-height` | **Yes** — without height, the tab bar collapses |
| `--chassis-divider-size` | **Yes** — without size, the divider is ungrabable |
| `--chassis-tab-bg` | **No** — the tab bar still functions with a transparent background |
| `--chassis-tab-text` | **No** — text still renders in the browser's default color |
| `--chassis-slot-bg` | **No** — the slot still functions with no background |
| `--chassis-dock-highlight` | **Arguable** — drag-drop works, but with no visual feedback |

The spec conflates two different kinds of "required":
1. **Structurally required** — the shell literally breaks without this (tab bar collapses, divider disappears)
2. **Practically required** — the shell works but is effectively unusable (invisible tabs, no drag feedback)

An adopter reading this spec cannot distinguish which properties they *must* define on day one from which ones they can defer until polish. This matters for incremental adoption.

**Recommendation**: Split §T1 into two tiers:
- **§T1-A: Structural** — properties without which the layout shell is geometrically broken (heights, sizes, display behaviors)
- **§T1-B: Visual** — properties without which the layout shell functions but is not visually navigable (backgrounds, text colors, highlights)

This makes the adopter's path clear: define §T1-A first, get a working shell, then layer §T1-B for usability.

### O-3: The Example Theme in §T4.1 Is Excellent

The complete CSS example in §T4.1 is the single most valuable section of the adopter spec. An adopter can copy-paste this, adjust values, and have a working theme. This is good clarifier practice — anchor to the concrete, not the abstract.

### O-4: V-3 (Speculative Property List) Creates Adopter-Side Risk

The Constitution Writer noted V-3: the 16 required properties are derived from vision, not from working code. For the adopter, this is a **contract stability concern**. If they build a theme today and the Builder discovers the actual CSS needs different properties, the adopter's theme breaks.

This is not a legibility issue per se, but it should be **visible** to the adopter. The spec should note that the property table is draft status until the Builder validates it during implementation. Adopters who build themes before the Builder phase accept that risk.

**Recommendation**: Add a note to §T1:

> *This property table is draft. The authoritative property list will be validated by the Builder during implementation. Properties may be added, renamed, or removed before the first stable release.*

### O-5: §T3.3 (No Shadowing) May Confuse Adopters

§T3.3 says: *"Consuming applications MUST NOT define `--chassis-*` properties on elements inside a slot."*

An adopter might wonder: *why would I ever do that?* The answer is: to override Chassis styling for a specific slot. This is a reasonable impulse that the spec prohibits without explaining the consequence.

**Recommendation**: Add one sentence of rationale: *"Setting `--chassis-*` inside a slot would cause that slot's structural chrome (tab bar, dividers) to differ from the rest of the shell, breaking layout coherence."*

---

## Open Questions

**OQ-1**: Should the adopter theming spec eventually become a standalone document outside `coordination/canonical/`? If adopters are the audience, they won't be reading the governance pipeline. A publishing step may be needed in the Planner phase.

---

## Constraints

No clarifier constraint violations. Both specs stay within Chassis's bounded domain. No application-level concerns have leaked in. Vocabulary discipline is maintained throughout.

---

**Status**: Review complete. Two recommendations (O-2 tiered split, O-4 draft notice) and one minor enrichment (O-5 rationale). Routing to Governor for disposition.
