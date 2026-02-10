# Prompt 3 — Chassis Constitution

## Role
Constitution Writer

## Context
You are writing the **constitutional invariants** for Chassis — a layout shell framework for Phoenix LiveView. The constitution derives enforceable law from the vision. It does not repeat the vision — it formalizes it into binding constraints.

**Read these first (in order):**
1. `C:\Users\alpha\source\chassis\coordination\memo_founding_chassis.md` — founding memo: identity, bounded domain, vocabulary
2. `C:\Users\alpha\source\chassis\coordination\vision.md` — Chassis vision (must exist before this prompt runs)
3. `C:\Users\alpha\source\list-demo\common_vision.md` — shared constitutional physics
4. `C:\Users\alpha\source\cognitive_mcp\coordination\canonical\constitutional_invariants.md` — the agent toolchain constitution (reference for form and rigor, NOT for content — Chassis has its own domain)

## Instruction

Write `C:\Users\alpha\source\chassis\coordination\constitutional_invariants.md` — the Chassis constitution.

The constitution must:

1. **Derive from the Chassis vision** — every article traces to a pillar or governing principle. If a clause cannot be traced, it does not belong.
2. **Enforce the bounded domain** — constitutionalize the boundary between Chassis (layout) and application (content). This is the most important invariant. Slot content is not Chassis's concern. Application logic must not leak into the layout tree.
3. **Define the vocabulary as law** — Composition, Slot, Stack, Division, Attach are the canonical terms. The constitution should prohibit the use of deprecated terms (Workspace, View, Tab Group, Split, Dock) to prevent vocabulary drift.
4. **Protect the contract** — the API surface between Chassis and consuming applications must be explicit, minimal, and stable. The contract is: layout tree in, spatial shell out.
5. **Be minimal** — the agent toolchain constitution has 14 articles because it governs a complex organization. Chassis governs a layout framework. It should need far fewer articles. Constitutional creep is itself a violation.
6. **Respect common constitutional physics** — Chassis operates within `common_vision.md`. The constitution must not contradict shared principles.

## Key Invariants to Formalize

From the clarification session and founding memo:

- **Domain boundary**: Chassis manages layout. Content inside slots is the consuming application's sole responsibility. Chassis must not inspect, modify, or depend on slot content.
- **No content leakage**: Chassis components must not import, reference, or assume any application-specific modules. If a Chassis module mentions a DataGrid, it has violated its boundary.
- **Vocabulary discipline**: Use Composition/Slot/Stack/Division/Attach. Rejecting "Workspace" and "View" is a conscious design decision to break from desktop-era conceptual baggage.
- **Layout tree as truth**: The layout tree is the single source of truth for spatial arrangement. Rendering is a projection of the tree. Operations mutate the tree. Persistence saves the tree.
- **Theming without opinion**: Chassis provides CSS variables (`--chassis-*`) for theming. It must not impose colors, fonts, or visual identity. Visual opinion belongs to the consuming application.

## Boundary
- Do NOT write a spec, plan, or implementation — this is constitution only
- Do NOT import articles from the agent toolchain constitution — Chassis has its own domain and its own law
- Do NOT over-constitutionalize — if an article governs implementation style rather than structural invariants, it doesn't belong

## Completion Criteria
- Constitution exists at `C:\Users\alpha\source\chassis\coordination\constitutional_invariants.md`
- Every article traces to the Chassis vision
- The domain boundary invariant is the first and most prominent article
- The vocabulary table is constitutionalized with deprecated terms listed
- A developer reading it knows exactly what Chassis must never do
- The document is shorter than the agent toolchain constitution (14 articles is the upper bound, not the target)
