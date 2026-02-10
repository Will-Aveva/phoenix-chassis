# Constitutional Invariants — Chassis

*The governing law of this framework. Derived from the vision. Binding on every contributor — human or agent — in every change.*

*Authored by the Constitution Writer at the direction of the Governor.*
*Source authority: `vision.md`*
*Shared physics: `common_vision.md`*

---

## Preamble

This constitution formalizes the Chassis vision into enforceable structural invariants. It does not repeat the vision — it **derives law** from it. Where the vision says *what we believe*, this document says *what is required*.

Chassis is a layout shell framework. Its constitution governs a bounded domain: spatial composition in the browser. Every article traces to a vision pillar. If a clause cannot be traced, it does not belong.

This constitution is deliberately small. The agent toolchain governs an organization of minds and needs 14 articles. Chassis governs a layout framework. Constitutional creep is itself a violation (§6.2).

---

## Article I — Domain Boundary

**Derived from**: Pillar I (Spatial Ignorance), Pillar V (The Frame Stays Silent)

*This is the most important article. If only one article survives, it must be this one.*

### §1.1 — The Boundary Is Law

Chassis manages spatial composition. It does not manage, inspect, depend on, or assume anything about what occupies its spatial positions.

### §1.2 — Inward Boundary (Content Exclusion)

No Chassis module, component, hook, or stylesheet may:
- Import, reference, or name any application-specific module, component, or type
- Inspect, validate, or transform the content rendered inside a slot
- Accept parameters that encode knowledge of what a slot contains
- Conditionally behave based on slot content type or identity

**Test**: If removing all application code from the consuming project would cause a Chassis compilation error, the boundary has been violated.

### §1.3 — Outward Boundary (Framework Containment)

Chassis must not impose concerns on consuming applications beyond the documented contract. Specifically:
- No visual opinion (colors, fonts, spacing, shadows, border radii) may be set by Chassis — only CSS custom properties (`--chassis-*`) may be exposed (see §3)
- No structural conventions may be required of the application beyond providing slot IDs and a layout tree
- No internal Chassis abstractions may leak into the public API

**Test**: If adopting Chassis forces an application to restructure its own internals, the boundary has been violated.

### §1.4 — Boundary Symmetry

The domain boundary blocks in both directions equally. Inward contamination (application concerns entering Chassis) and outward leakage (Chassis concerns entering the application) are the same class of violation and receive the same response.

Most frameworks enforce only inward boundaries. Chassis enforces both. This symmetry is constitutional.

---

## Article II — The Layout Tree

**Derived from**: Pillar II (The Tree Is Truth)

### §2.1 — Single Source of Truth

The layout tree — a recursive structure of divisions, stacks, and slots — is the sole authoritative representation of spatial arrangement. There is no layout state that exists outside the tree.

### §2.2 — Rendering Is Projection

Rendering MUST be a pure projection of the layout tree into DOM. There is no rendering path that bypasses, overrides, or supplements the tree. If the tree says slot A is in stack B at position 2, the DOM reflects exactly that.

### §2.3 — Operations Mutate the Tree

Every user-initiated layout change (divide, stack, attach, reorder, close, focus) MUST be expressed as a tree mutation. Side-effecting the DOM directly without updating the tree is a constitutional violation.

### §2.4 — Persistence Is Tree Serialization

Saving and restoring layout arrangements MUST serialize and deserialize the tree. No layout state is persisted outside the tree structure.

### §2.5 — Presentation Hints

Presentation hints that affect spatial *sizing* without altering tree *structure* (e.g., flex weight ratios between division children) MAY be stored parallel to the tree. Such hints:
- MUST NOT change which nodes exist or their parent–child relationships
- MUST NOT be required for correct rendering — the tree alone must produce a valid layout
- MAY be lost without violating structural correctness (the layout degrades to equal sizing)

This clause resolves the tension between §2.1 (tree as sole authority on arrangement) and INV-2.1 (exactly three node types). Weights control *proportion*, not *structure*.

---

## Article III — Theming Discipline

**Derived from**: Pillar IV (Theming Without Opinion)

### §3.1 — No Aesthetic Opinion

Chassis MUST NOT set values for any visual property that constitutes aesthetic opinion. This includes but is not limited to: colors, fonts, font sizes, border radii, shadows, background gradients, and animations.

### §3.2 — CSS Custom Properties Only

All visual properties that a consuming application may wish to control MUST be exposed as CSS custom properties using the `--chassis-*` namespace. Chassis stylesheets MUST reference these properties — never hard-coded values.

### §3.3 — No Default Theme

Chassis MUST NOT ship a default theme. If no consuming application sets `--chassis-*` values, the layout shell renders with browser defaults. The absence of a theme is the default.

### §3.4 — Structural CSS Only

Chassis MAY set CSS properties that are purely structural: `display`, `flex-direction`, `grid-template`, `position`, `overflow`, `resize`, `cursor` for drag operations. These are spatial arrangement concerns and belong to Chassis.

**Litmus test**: If a CSS property would cause two applications using Chassis to look the same, it is aesthetic and belongs to the application. If it would cause them to *arrange space* the same way, it is structural and belongs to Chassis.

---

## Article IV — Canonical Vocabulary

**Derived from**: Pillar III (Vocabulary as Liberation)

### §4.1 — Canonical Terms

The following terms are the constitutional vocabulary of Chassis. All code, documentation, API surfaces, and coordination artifacts MUST use these terms:

| Term | Meaning |
|---|---|
| **Composition** | A complete layout arrangement |
| **Slot** | A position in the spatial frame where content is rendered |
| **Stack** | Multiple slots sharing the same space, one visible at a time |
| **Division** | Space divided between children along a direction |
| **Attach** | Join a slot to another slot's edge, creating a new division |
| **Layout Tree** | The recursive data structure: division, stack, slot |
| **Shell** | The recursive renderer that projects the tree into DOM |

### §4.2 — Prohibited Terms

The following terms are prohibited in Chassis code, API surfaces, and documentation. Their use indicates vocabulary drift toward deprecated paradigms:

| Prohibited | Canonical Replacement | Rationale |
|---|---|---|
| Workspace | Composition | Desktop-era container assumption |
| View | Slot | Implies content awareness |
| Tab Group | Stack | Implies visual widget, not structural concept |
| Split | Division | Implies destructive operation, not spatial relationship |
| Dock | Attach | Desktop-era metaphor |
| Window | *(none — not a Chassis concept)* | Desktop paradigm that does not exist in Chassis |
| Panel | *(context-dependent)* | Ambiguous; use Slot, Sidebar, or DockPanel as appropriate |

### §4.3 — Vocabulary Boundary

Vocabulary discipline applies to Chassis's own surface. Chassis does not govern how consuming applications name their own concepts. An application may internally call its content "views" — Chassis will not know or care, per §1.1.

---

## Article V — The Contract

**Derived from**: Pillar V (The Frame Stays Silent), Pillar I (Spatial Ignorance)

### §5.1 — Contract Definition

The contract between Chassis and consuming applications is:

**Input**: Slot identifiers + a layout tree
**Output**: A spatial shell with tab bars, dock zones, drag-drop, and positions for slot content

The application fills the slots. Chassis does not inspect what fills them.

### §5.2 — Contract Stability

The contract API surface MUST be:
- **Explicit** — no implicit behavior, no convention-over-configuration magic
- **Minimal** — the smallest surface that enables the contract
- **Stable** — breaking changes require Governor authorization and constitutional review

### §5.3 — Contract Completeness

The contract MUST be sufficient for a consuming application to integrate Chassis without reading Chassis internals. If an application developer must understand Chassis's internal tree-walking logic to use it correctly, the contract is incomplete.

### §5.4 — No Content Callbacks

Chassis MUST NOT provide hooks, callbacks, or events that expose slot content identity or type to the layout layer. Events about spatial arrangement (slot focused, tab reordered, division resized) are permitted. Events about what is *inside* a slot are not.

---

## Article VI — Constitutional Maintenance

**Derived from**: Common Vision §8 (Mechanical Enforcement Over Social Compliance)

### §6.1 — Amendment Authority

Only the Governor may authorize constitutional amendments. The Constitution Writer drafts; the Governor ratifies.

### §6.2 — Constitutional Creep Prohibition

This constitution must remain minimal and specific to Chassis's bounded domain. Warning signals of creep:
- Articles that govern implementation style rather than structural invariants
- Clauses that duplicate or paraphrase the vision without adding enforceable constraint
- Articles imported from other project constitutions without domain justification

Response: compress, merge, or remove. Strong constitutions are small.

### §6.3 — No Foreign Import

Chassis's constitution governs Chassis's domain. Articles from the agent toolchain constitution, the Seek constitution, or any other project's constitution MUST NOT be imported wholesale. If a shared principle applies to Chassis, it enters through `common_vision.md` — not through cross-constitution copying.

---

## Schedules

### Schedule A — Violation Classification

| Class | Description | Example | Response |
|---|---|---|---|
| **Boundary violation (inward)** | Application concepts entering Chassis | A Chassis component imports `MyApp.DataGrid` | Code rejected; import removed |
| **Boundary violation (outward)** | Chassis concerns leaking to application | Chassis CSS sets `font-family: Inter` | Style removed; custom property substituted |
| **Tree bypass** | Layout state or rendering outside the tree | DOM manipulation without tree mutation | Code rejected; tree operation required |
| **Vocabulary violation** | Prohibited term in code or API | Function named `split_workspace` | Renamed to canonical terms |
| **Theming violation** | Aesthetic values hard-coded in Chassis | `background-color: #1e1e2e` in chassis.css | Value removed; `--chassis-*` property used |
| **Contract violation** | Content identity exposed to layout layer | Event payload includes slot content type | Payload stripped to spatial data only |
| **Creep violation** | Constitution expanded without Governor authorization | New article added without traceability to vision | Amendment rejected |

### Schedule B — Traceability Matrix

| Article | Vision Pillar | Common Vision Physics |
|---|---|---|
| I — Domain Boundary | I (Spatial Ignorance), V (Frame Stays Silent) | §6 (Context Isolation) |
| II — Layout Tree | II (The Tree Is Truth) | §5 (Projections Over Assertions) |
| III — Theming Discipline | IV (Theming Without Opinion) | §6 (Context Isolation) |
| IV — Canonical Vocabulary | III (Vocabulary as Liberation) | — |
| V — The Contract | V (Frame Stays Silent), I (Spatial Ignorance) | §8 (Mechanical Enforcement) |
| VI — Constitutional Maintenance | *(meta)* | §8 (Mechanical Enforcement) |

---

*This constitution is a living document under the sole amendment authority of the Governor. It governs a layout framework — not an organization, not a platform, not an application. If it grows beyond what a layout framework's domain requires, it has failed its own test.*
