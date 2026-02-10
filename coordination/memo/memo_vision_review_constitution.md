# Vision Review — Chassis Constitutional Invariants

**Reviewer**: Visionary
**Date**: 2026-02-09
**Artifact under review**: `coordination/canonical/constitutional_invariants.md`
**Governing source**: `coordination/canonical/vision.md`

---

## Coherence Assessment

The constitution is **strongly coherent** with the vision. Every article traces to a pillar, and the traceability matrix in Schedule B is honest — no false mappings, no stretched connections. The Constitution Writer understood the assignment: derive law from vision, don't repeat vision.

**Article-by-article coherence:**

| Article | Vision Source | Coherent? | Notes |
|---|---|---|---|
| I — Domain Boundary | Pillars I, V | ✅ | Correctly identified as "most important article." §1.4 (boundary symmetry) formalizes what the vision states in Pillar V without over-engineering it. The **test** clauses in §1.2 and §1.3 are excellent — they convert belief into falsifiable assertion. |
| II — Layout Tree | Pillar II | ✅ | Faithful translation. "Rendering is projection" (§2.2) directly formalizes "The Tree Is Truth." No drift. |
| III — Theming Discipline | Pillar IV | ✅ | §3.4 (structural CSS carve-out) is a smart addition — the vision doesn't explicitly address structural vs. aesthetic CSS, but the constitution correctly derives that spatial arrangement properties belong to Chassis. The litmus test is well-crafted. |
| IV — Canonical Vocabulary | Pillar III | ✅ | §4.3 (vocabulary boundary) is a mature clause — it prevents Chassis's vocabulary discipline from leaking outward as a demand on consuming applications. This respects Pillar V without needing a cross-reference. |
| V — The Contract | Pillars I, V | ✅ | §5.4 (no content callbacks) catches a subtle violation vector the vision doesn't explicitly name. This is appropriate constitutional derivation — the vision implies it, the constitution makes it law. |
| VI — Constitutional Maintenance | *(meta)* | ✅ | §6.3 (no foreign import) is correctly strict. Prevents the common failure mode of growing a framework's constitution by importing concerns from the organization that uses it. |

---

## Drift Detected

### 1. Narrowing: §3.3 — "No Default Theme" May Be Too Strict

The vision says *"It does not ship a default theme. It has no aesthetic."* The constitution formalizes this as §3.3: *"Chassis MUST NOT ship a default theme. If no consuming application sets `--chassis-*` values, the layout shell renders with browser defaults."*

**Concern**: "Browser defaults" for unstyled flex containers and tab bars will produce a broken-looking layout. This is not an aesthetic opinion — it's a usability floor. A consuming application that forgets to define `--chassis-tab-height` shouldn't get a zero-height tab bar.

**Vision coherence**: The vision says *"no aesthetic"* — it does not say *"no sensible structural defaults."* Setting `--chassis-tab-height: 2rem` as a default is structural (the tab bar needs a height to exist), not aesthetic (it doesn't opine on how the tab bar should look).

**Recommendation**: The Constitution Writer should consider distinguishing between **structural defaults** (dimensions, exhibit behavior, spacing for functionality) and **aesthetic defaults** (colors, fonts, decoration). The vision's Pillar IV prohibits aesthetic opinion; it does not prohibit structural viability. This distinction should be made explicit in §3.3 or §3.4. Without it, the constitution may produce a framework that is technically compliant but practically unusable until fully themed.

### 2. Absence: The Vision's "Lineage" Section Has No Constitutional Echo

The vision dedicates a section to Chassis's origin in Seek. The constitution has no article governing lineage — how Seek-era code must be handled during the port, how deprecated Seek identifiers must not persist in Chassis code, or how the boundary between "ported code" and "Chassis-native code" is maintained.

**Assessment**: This is correct omission, not drift. Lineage is a one-time migration concern, not a structural invariant. It does not belong in the constitution. The founding memo and the Builder's prompt (prompt_01) handle this adequately. No amendment needed.

### 3. Absence: No Persistence Invariant Beyond Tree Serialization

The vision says *"State management — persisting and restoring layout arrangements"* is inside Chassis. The constitution says in §2.4 that persistence serializes the tree. But it says nothing about persistence format, location, or ownership.

**Assessment**: This is appropriately absent. Persistence *format* is an implementation concern, not a constitutional one. The invariant — "persistence is tree serialization" — is sufficient. If the constitution specified JSON, localStorage, or database schemas, it would be over-constitutionalizing.

---

## Amendments

### Vision Amendment: None Required

The constitution does not require changes to the vision. The vision's pillars remain intact and correctly sourced.

### Constitution Amendment: One Recommended

**§3.3 / §3.4 — Structural vs. Aesthetic Defaults**

The constitution should explicitly permit structural defaults while prohibiting aesthetic defaults. Suggested language for §3.3:

> *Chassis MUST NOT ship a default theme. However, Chassis MAY provide structural defaults — minimum dimensions, display behaviors, and spatial relationships required for the layout shell to function. Structural defaults ensure a layout shell is usable before theming; they do not constitute aesthetic opinion.*
>
> *Litmus test: A structural default makes the layout shell functional. An aesthetic default makes it look a particular way. Only the former is permitted.*

This preserves the vision's anti-opinion stance while preventing a technically-correct-but-unusable framework.

---

## Recommendation

**APPROVE with one revision.**

The constitution is well-crafted, appropriately minimal (6 articles vs. agent toolchain's 14), and faithfully derived from the vision. The traceability matrix is honest. The violation classification is practical. The vocabulary discipline respects the outward boundary (§4.3). The boundary symmetry principle is correctly constitutionalized (§1.4).

The one revision (structural defaults carve-out in §3.3/§3.4) strengthens the constitution by resolving an ambiguity that would otherwise surface during the Builder phase. Better to disambiguate now than to have the Builder escalate mid-build asking whether `min-height: 1.5rem` on a tab bar is a constitutional violation.

---

**Status**: Review complete. Routing to Governor for final disposition.
