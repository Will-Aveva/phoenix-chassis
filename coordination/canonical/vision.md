# Vision — Chassis

*What kind of system we are building, what we believe, and why it matters.*

*For shared constitutional physics, see `common_vision.md`.*
*For governing constraints derived from this vision, see `constitutional_invariants.md`.*

---

## What This Is

A layout shell framework for Phoenix LiveView. Chassis provides the structural skeleton for multi-pane, tabbed, splittable, dockable layouts rendered in a browser. It manages spatial arrangement — nothing else.

Chassis is the frame. You bring the content.

## Where This Came From

Chassis was not designed from first principles. It was discovered inside the Seek engineering data platform, where a windowing system grew to serve a purpose that had nothing to do with engineering data. The windowing layer managed panes, tabs, splits, and docking. It didn't know what was inside the panes. It never needed to.

That ignorance was the signal. A component that manages spatial arrangement without knowing or caring what it arranges is not an application feature — it is a framework waiting to be extracted. The windowing system belonged to layout, not to Seek.

Chassis is that extraction: the windowing system given its own identity, its own bounded domain, and its own vocabulary.

## The Problem It Solves

Browser-based multi-pane layouts are common but rarely clean. The typical failure modes:

1. **Layout-content entanglement** — the layout system knows what's inside its panes. Adding a new content type requires modifying layout code. The boundary between "where things go" and "what things are" erodes until they cannot be separated.

2. **Desktop vocabulary in browser contexts** — "workspace," "window," "panel," "view" — borrowed from desktop paradigms that don't transfer. The vocabulary shapes the thinking. Desktop concepts produce desktop constraints in a medium that doesn't have them.

3. **Reimplementation per application** — every project that needs a multi-pane workbench-style layout builds one from scratch. The layout primitives — splits, tabs, dock zones, drag-drop — are identical across applications, but they're rebuilt each time because they were never extracted.

4. **Theming as opinion** — layout frameworks impose visual identity. Colors, fonts, spacing are baked in. Applications that adopt the framework inherit its aesthetic. The framework's opinion becomes the application's constraint.

---

## The Bounded Domain

Chassis manages **spatial composition**. It knows how to divide space, arrange panes, manage tabs, dock content, and respond to user rearrangement. It does not know — and must never learn — what is inside the spaces it manages.

**Inside Chassis:**
- The layout tree — a recursive data structure of divisions, stacks, and slots
- Operations on the tree — divide, stack, attach, reorder, close, focus
- Rendering — projecting the tree into DOM with tab bars, dock zones, drag targets
- State management — persisting and restoring layout arrangements
- Interaction — drag-drop, tab selection, split creation via client-side hooks

**Outside Chassis — permanently:**
- Content rendered inside slots
- Sidebar tree data (Chassis renders the structure; the application provides the nodes)
- Business logic, data models, network connections
- Application-level concepts of any kind

The contract is simple: the consuming application gives Chassis slot identifiers and a layout tree. Chassis gives back a spatial shell with tabs, splits, dock zones, and drag-drop. The application fills the slots. Chassis does not inspect, modify, or depend on what fills them.

This boundary is the most important thing about Chassis. It is not a guideline — it is the defining structural invariant. If Chassis knows what a DataGrid is, it has failed. If an application must modify Chassis source to add a new content type, Chassis has failed.

---

## The Pillars

These are the beliefs Chassis is built on. They are specific to the layout shell domain. They are not aspirational — they are structural requirements.

### I. Spatial Ignorance

Chassis does not know what occupies its slots. A slot is a position in a spatial arrangement. What renders there — a data grid, a terminal, a dashboard, an empty placeholder — is the consuming application's sole concern. Chassis provides the position; the content provides itself.

This is not a limitation. It is the feature. Spatial ignorance is what makes Chassis reusable across applications that have nothing in common except the need for multi-pane layout.

### II. The Tree Is Truth

The layout tree — a recursive structure of divisions, stacks, and slots — is the single source of truth for spatial arrangement. Rendering is a projection of the tree. Operations mutate the tree. Persistence saves and restores the tree.

There is no layout state that lives outside the tree. There is no rendering path that bypasses the tree. If the tree says slot A is in stack B at position 2, that is where slot A appears. The tree is not a model of the layout — it *is* the layout.

### III. Vocabulary as Liberation

Chassis deliberately rejects desktop-era vocabulary. "Workspace" implies a fixed, application-scoped container. "View" implies awareness of what is being viewed. "Tab group" implies a visual widget rather than a structural concept. "Split" implies a destructive operation rather than a spatial relationship.

Chassis uses:
- **Composition** — a complete layout arrangement
- **Slot** — a position content fills
- **Stack** — slots sharing space, one visible
- **Division** — space divided between children
- **Attach** — joining a slot to an edge

This vocabulary was chosen because it describes spatial arrangement without importing assumptions from other paradigms. The words shape the thinking. Better words produce cleaner design.

### IV. Theming Without Opinion

Chassis provides CSS variables (`--chassis-*`) for every visual property the consuming application might want to control. It does not set colors, fonts, border radii, or shadows. It does not ship a default theme. It has no aesthetic.

The consuming application owns all visual opinion. Chassis provides the hooks to express that opinion. This separation ensures that adopting Chassis does not mean adopting Chassis's taste.

### V. The Frame Stays Silent

Chassis must not impose layout concerns outward beyond its contract. A consuming application that adopts Chassis should not find Chassis opinions leaking into its architecture. The API surface is explicit, minimal, and stable.

Inward: no application concepts leak into Chassis.
Outward: no framework concepts leak beyond the documented contract.

The boundary is symmetrical. Pollution flows in neither direction.

---

## Lineage

Chassis inherits from the Seek windowing system but does not inherit Seek's identity. The Seek components that became Chassis are:

| Seek Origin | Chassis Successor |
|---|---|
| `Seek.WorkspaceManager` | `Chassis.LayoutManager` |
| `Seek.WorkspaceLayout` | `Chassis.Layout` |
| `SeekWeb.Components.Workspace` | `Chassis.Shell` |
| `SeekWeb.Components.Sidebar` | `Chassis.Sidebar` |
| `SeekWeb.Components.DockPanel` | `Chassis.DockPanel` |
| JS hooks (tab, drag-drop, sidebar) | `Chassis.Hooks` |

The port is not a copy. It is a re-founding — new names, new vocabulary, new bounded domain. The code moves; the identity does not.

---

## Relationship to the Ecosystem

Chassis operates within the shared constitutional physics from `common_vision.md`. Specifically:

- **Projections Over Assertions** (Common Vision §5) — the layout tree is truth; rendering is a projection of it
- **Context Isolation** (Common Vision §6) — Chassis isolates layout concerns from content concerns, passing structured data across the boundary, not assumptions
- **Reversibility** (Common Vision §7) — layout operations are undoable; the tree can be restored from any persisted state
- **Mechanical Enforcement Over Social Compliance** (Common Vision §8) — the domain boundary is enforced by structure (the contract API), not by developer discipline

Chassis is a **dependency** of applications built on it — not a peer. It sits below the application layer:

```
chassis                         — layout shell framework
  ↑ used by
application (e.g., Seek, agent dashboard) — fills slots with content
```

Chassis does not know which application uses it. It does not know the agent toolchain exists. It does not know about the delivery surface. It provides spatial arrangement to anyone who asks, under the same contract, with the same ignorance.

---

## What Success Looks Like

- **A developer integrates Chassis in an afternoon** — the contract is simple enough that adding Chassis to a Phoenix project requires understanding slots, stacks, and divisions, not Chassis internals
- **A new content type requires zero Chassis changes** — the application registers a slot ID and renders content into it; Chassis never needs to know
- **The layout survives application evolution** — as applications add features, remove features, and restructure, the layout shell remains untouched because it never knew what was inside
- **Multiple unrelated applications share the same Chassis** — Seek and the agent dashboard use identical Chassis code with different themes and different slot content
- **The vocabulary is natural within a week** — developers stop reaching for "workspace" and "view" because Composition, Slot, Stack, Division, and Attach describe what they mean more precisely
- **Visual identity is entirely the application's** — two applications using Chassis look nothing alike, because Chassis contributed no opinion

---

## What Chassis Will Never Become

- **An application framework** — Chassis manages layout. It will never manage routing, data fetching, authentication, or application state.
- **A design system** — Chassis provides spatial structure and theming hooks. It will never provide component libraries, typography scales, or color palettes.
- **A content manager** — Chassis does not know what content is. It will never inspect, validate, or transform slot content.
- **A platform** — Chassis is a dependency, not a foundation. Applications are not "built on Chassis" in the way they are "built on Phoenix." Chassis is one layer in the stack — the spatial layer — and it stays in its lane.

---

## Founding Intent

Build a layout shell that is so cleanly bounded it disappears. The best Chassis is the one developers forget is there — because it manages space so quietly that they only think about what fills it.
