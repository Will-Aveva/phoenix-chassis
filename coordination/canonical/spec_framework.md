# Specification — Chassis Framework

*Falsifiable invariants governing how Chassis is built. Derived from the Chassis constitution and vision.*

*This spec governs the framework's internals. For the adopter-facing theme contract, see `spec_adopter_theming.md`.*

---

## Derived From

| Spec Section | Constitutional Article | Vision Pillar |
|---|---|---|
| §F1 — Domain Boundary | Article I | I (Spatial Ignorance), V (Frame Stays Silent) |
| §F2 — Layout Tree | Article II | II (The Tree Is Truth) |
| §F3 — Rendering | Article II (§2.2) | II (The Tree Is Truth) |
| §F4 — Operations | Article II (§2.3) | II (The Tree Is Truth) |
| §F5 — Persistence | Article II (§2.4) | II (The Tree Is Truth) |
| §F6 — Styling | Article III | IV (Theming Without Opinion) |
| §F7 — Vocabulary | Article IV | III (Vocabulary as Liberation) |
| §F8 — Contract Surface | Article V | I, V |
| §F9 — Behaviour Contracts | Article V, Article I | I, V |

---

## §F1 — Domain Boundary Invariants

### §F1.1 — Inward Boundary (Content Exclusion)

**INV-1.1a**: No module under `Chassis` or `ChassisWeb` shall import, alias, or reference any module outside the `Chassis`/`ChassisWeb` namespace, except:
- Elixir/Erlang standard library modules
- Phoenix framework modules
- LiveView modules
- Explicitly declared dependencies in `mix.exs`

**INV-1.1b**: No Chassis function shall accept a parameter whose type encodes knowledge of slot content. Slot identifiers are opaque atoms or strings. Chassis never pattern-matches on slot ID values to determine behavior.

**INV-1.1c**: No Chassis component shall use conditional logic based on what a slot contains. `if slot_id == :data_grid` is a constitutional violation regardless of where it appears.

**INV-1.1d**: No Chassis template or component shall render content inside a slot. Chassis renders the slot *container* and invokes the consuming application's render callback. The content is the application's responsibility.

### §F1.2 — Outward Boundary (Framework Containment)

**INV-1.2a**: Chassis shall maintain an **API manifest** — a single, authoritative document listing every public module, component, CSS custom property namespace, and JavaScript hook. Modules not in the manifest are internal and must not be relied upon by consuming applications. The manifest is updated by the Builder and ratified by the Planner during execution.

**INV-1.2b**: No Chassis internal data structure shall appear in the public API. The layout tree's internal representation may change without notice. The public API exposes construction functions (`division/3`, `stack/3`, `slot/1`) and query functions, not raw structs.

**INV-1.2c**: Chassis shall not require consuming applications to adopt any convention, file structure, or naming pattern beyond providing slot IDs and a layout tree.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-1.1a | No forbidden imports in Chassis modules | Static analysis: `grep -r "alias MyApp\|import MyApp\|require MyApp" lib/chassis*` returns empty |
| T-1.1b | Slot IDs are opaque | Review: no function clause matches a specific slot ID value |
| T-1.1c | No content-conditional logic | Review + grep: no `case slot_id` or `if slot_id ==` in Chassis code |
| T-1.1d | Slot rendering delegates to application | Review: Shell component calls render callback, never generates content |
| T-1.2a | Public API manifest exists | An API manifest file exists, and every `@moduledoc` public module is listed in it |
| T-1.2b | No struct leakage | `%Chassis.Layout{}` is not pattern-matched by consuming application code |
| T-1.2c | No convention imposition | A bare Phoenix project can integrate Chassis with only slot IDs and a tree |

---

## §F2 — Layout Tree Invariants

**INV-2.1**: The layout tree is a recursive algebraic data type with exactly three node types:
- `division(direction, children)` — space divided between children
- `stack(active, slots)` — slots sharing space, one visible
- `slot(id)` — leaf node, a position for content

**INV-2.2**: The layout tree is the **sole** representation of spatial arrangement. No layout state exists outside the tree. There is no secondary index, shadow state, or DOM-derived layout truth.

**INV-2.3**: The tree is always valid. Operations that would produce an invalid tree (empty stack, division with one child, orphaned slot) must either normalize the tree or reject the operation. A malformed tree is never persisted or rendered.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-2.1 | Tree nodes are exactly three types | Type spec: `@type t :: division() \| stack() \| slot()` |
| T-2.2 | No external layout state | Review: no `Agent`, `ETS`, `Process dictionary`, or module attribute holds layout state outside the tree |
| T-2.3 | Invalid trees are rejected | Unit tests: `division(:horizontal, [single_child])` normalizes or raises |

---

## §F3 — Rendering Invariants

**INV-3.1**: Rendering is a pure function of the layout tree. Given the same tree, the same DOM structure is produced. There are no rendering side-effects that alter layout state.

**INV-3.2**: The Shell component walks the tree recursively. Each node type maps to a rendering clause:
- `division` → nested container with flex/grid layout
- `stack` → tab bar + active slot container
- `slot` → container that invokes the application's render callback

**INV-3.3**: No DOM element produced by the Shell shall exist that does not correspond to a node in the layout tree. Phantom DOM (decorative wrappers, hidden containers, pre-allocated slots) is prohibited.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-3.1 | Rendering is deterministic | Unit test: same tree → same HTML output (modulo attribute ordering) |
| T-3.2 | All node types render | Component test: trees containing all three node types produce correct DOM |
| T-3.3 | No phantom DOM | Review: every DOM container in Shell output traces to a tree node |

---

## §F4 — Operation Invariants

**INV-4.1**: Every user-initiated layout change is expressed as a tree transformation. The set of core operations is:
- `divide/3` — split a slot into a division
- `stack/2` — add a slot to an existing stack
- `attach/3` — join a slot to another slot's edge (creates a division)
- `close/2` — remove a slot from the tree
- `focus/2` — set the active slot in a stack
- `reorder/3` — change slot position within a stack
- `resize/3` — adjust relative sizing between siblings in a division

**INV-4.2**: Every operation takes a tree and returns a tree. No operation mutates state directly. The LayoutManager applies the returned tree as the new state.

**INV-4.3**: No operation inspects slot content. Operations manipulate spatial positions, not what occupies them.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-4.1 | Core operations exist | Module exports: all seven operations are public functions |
| T-4.2 | Operations are pure transforms | Type spec: `tree -> tree`. No side effects in operation functions |
| T-4.3 | Operations are content-blind | Unit tests: operations produce identical results regardless of slot ID values |

---

## §F5 — Persistence Invariants

**INV-5.1**: Layout persistence serializes and deserializes the tree structure. No layout information is persisted outside the tree.

**INV-5.2**: A deserialized tree is identical to the original tree. Serialization round-trips without loss.

**INV-5.3**: The persistence format is an implementation detail. The public API exposes `save/1` and `restore/1` — not the format.

**INV-5.4**: Storage backend selection is an application-level concern. Chassis defines the `Chassis.PersistenceBackend` behaviour (see §F9) but does not mandate a storage mechanism. The `Chassis.Persistence` module provides a default serialization layer; the backend determines where serialized data is stored.

**INV-5.5**: Presentation hints (§2.5) MAY be persisted via optional backend callbacks (`save_weights/2`, `load_weights/1`). These callbacks are optional — backends that do not implement them degrade gracefully to default weights. Weight data is serialized as opaque binaries, same as tree data.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-5.1 | Only tree is persisted | Review: persistence functions accept and return tree, nothing else |
| T-5.2 | Round-trip fidelity | Unit test: `tree |> save() |> restore() == tree` for all valid trees |
| T-5.3 | Format is private | The serialization format is not exposed in the public API |
| T-5.4 | Backend is pluggable | A module implementing `PersistenceBackend` can be passed to `LayoutManager.start_link/1` |
| T-5.5 | Weight persistence is optional | Backend without `save_weights/2` starts with default weights; backend with it round-trips weights |

---

## §F6 — Styling Invariants

**INV-6.1**: `chassis.css` shall contain zero hard-coded color, font-family, font-size, border-radius, box-shadow, or background-gradient values.

**INV-6.2**: Every visual property that a consuming application may wish to control shall reference a `--chassis-*` CSS custom property.

**INV-6.3**: Chassis CSS MAY set structural properties without custom properties. The permitted structural property categories are:
- **Layout mode**: `display`, `flex-direction`, `flex-grow`, `flex-shrink`, `flex`, `grid-template-*`, `align-items`, `justify-content`
- **Spatial constraints**: `position`, `inset`, `top`, `left`, `right`, `bottom`, `width`, `height`, `min-width: 0`, `min-height: 0`, `z-index`
- **Overflow**: `overflow`, `overflow-x`, `overflow-y`
- **Interaction affordance**: `cursor`, `pointer-events`, `user-select`, `resize`
- **Text overflow**: `white-space`, `text-overflow`, `overflow: hidden` (for label truncation only)

Properties NOT in this list are either aesthetic (must use `--chassis-*`) or require Governor approval to add.

**INV-6.4**: The `--chassis-*` namespace is reserved for Chassis. Applications set the values; Chassis reads them.

**INV-6.5**: Interaction feedback properties (`transition`, `opacity` for hover/reveal states, `animation`) are aesthetic and MUST reference `--chassis-*` custom properties. Two applications using Chassis must be able to have different transition speeds, hover opacities, and reveal animations.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-6.1 | No aesthetic values | Static analysis: grep `chassis.css` for color literals, `font-family`, `font-size`, `border-radius`, `box-shadow`, `background` — all absent or reference `--chassis-*` |
| T-6.2 | Custom properties used | Every `var(--chassis-*)` reference in CSS has a corresponding entry in the theming spec |
| T-6.3 | Structural properties are legitimate | Review: each non-variable CSS property in `chassis.css` is spatial, not decorative |
| T-6.4 | Namespace reserved | No CSS custom property outside `--chassis-*` is defined by Chassis |

---

## §F7 — Vocabulary Invariants

**INV-7.1**: All Chassis module names, function names, type names, and documentation use the canonical vocabulary:

| Term | Permitted In |
|---|---|
| Composition | Module names, function names, documentation |
| Slot | Module names, function names, type names, documentation |
| Stack | Module names, function names, type names, documentation |
| Division | Module names, function names, type names, documentation |
| Attach | Function names, documentation |
| Layout Tree | Documentation, type names |
| Shell | Module names, documentation |
| Provider | Module names, documentation — a module implementing a Chassis behaviour contract |

**INV-7.2**: The following terms shall not appear in Chassis code, types, or documentation: `workspace`, `view` (as a layout concept), `tab_group`, `split` (as a noun for division), `dock`, `window`, `panel` (except in `DockPanel`).

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-7.1 | Canonical terms used | Review: module and function names align with vocabulary table |
| T-7.2 | Prohibited terms absent | Static analysis: `grep -ri "workspace\|tab_group\|split_view" lib/` returns empty (excluding comments explaining the port) |

---

## §F8 — Contract Surface Invariants

**INV-8.1**: The contract between Chassis and consuming applications is:
- **Input**: slot identifiers (opaque) + layout tree (constructed via public API) + a `SlotProvider` module (see §F9)
- **Output**: spatial shell with tab bars, dock zones, drag-drop, and slot containers

**INV-8.2**: Consuming applications provide a module implementing the `Chassis.SlotProvider` behaviour (see §F9). Chassis invokes the provider's callbacks, passing only the slot ID. It never passes layout-internal state. The provider returns opaque content (HEEx, label strings, icon identifiers) that Chassis renders without inspection.

**INV-8.3**: Chassis events exposed to consuming applications carry only spatial information:
- Permitted event data: slot ID, position, direction, stack index
- Prohibited event data: content type, content state, application-specific metadata

**INV-8.4**: The contract API must be sufficient for integration without reading Chassis source. The `SlotProvider` behaviour definition, `PersistenceBackend` behaviour definition, and `API_MANIFEST.md` together constitute the complete integration contract.

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-8.1 | Contract is documented | A standalone document describes integration without referencing internals |
| T-8.2 | Provider callbacks receive only slot ID | Type spec: all `SlotProvider` callbacks accept `slot_id :: term()` as first argument |
| T-8.3 | Events are spatial-only | Review: all PubSub event payloads contain spatial data, no content data |
| T-8.4 | Integration without source reading | Integration test: a minimal Phoenix app integrates Chassis using only `SlotProvider` + public API |

---

## §F9 — Behaviour Contract Invariants

**Derived from**: Article V (The Contract), Article I (Domain Boundary)

Chassis defines two Elixir behaviours as the formal adopter integration surface. Behaviours provide compiler-enforced contracts that guide adopters and maintain the content-blindness boundary.

### §F9.1 — `Chassis.SlotProvider`

**INV-9.1**: The `Chassis.SlotProvider` behaviour defines the contract between Chassis and consuming applications for slot rendering and tab chrome:

| Callback | Signature | Purpose |
|---|---|---|
| `render_content/2` | `(slot_id, assigns) → HEEx` | Render the content area for a slot |
| `tab_label/1` | `(slot_id) → String.t()` | Provide the text label for a tab |
| `tab_icon/1` *(optional)* | `(slot_id) → String.t() \| nil` | Provide an icon identifier for a tab |
| `closable?/1` *(optional)* | `(slot_id) → boolean()` | Whether the user can close this tab |

**INV-9.2**: Chassis invokes `SlotProvider` callbacks with only the slot ID (and assigns for rendering). The `assigns` argument to `render_content/2` is `%{slot_id: slot_id}` — it contains the slot identifier and no layout-internal state. Chassis never inspects, pattern-matches, or conditionally branches on the return values. The returned content is rendered opaquely.

**INV-9.3**: The Shell component accepts a `provider` attribute (a module implementing `SlotProvider`) instead of a bare render function. This replaces the previous `render_slot_content` function attribute.

### §F9.2 — `Chassis.PersistenceBackend`

**INV-9.4**: The `Chassis.PersistenceBackend` behaviour defines the contract for layout state storage:

| Callback | Signature | Purpose |
|---|---|---|
| `save_layout/2` | `(composition, binary) → :ok \| {:error, term}` | Persist serialized tree data |
| `load_layout/1` | `(composition) → {:ok, binary} \| {:error, term}` | Retrieve serialized tree data |

**INV-9.5**: `LayoutManager` accepts an optional `persistence_backend` option. When provided, `init/1` calls `backend.load_layout/1` and `terminate/2` calls `backend.save_layout/2`. When omitted, no persistence occurs — state is ephemeral.

**INV-9.6**: The `PersistenceBackend` callbacks operate on opaque binaries produced by `Chassis.Persistence.save/1`. The backend never interprets, parses, or transforms the binary content. It is a pass-through storage layer.

### §F9.3 — Behaviour Boundaries

**INV-9.7**: Behaviours are the integration surface, not the implementation surface. Chassis defines the callbacks; consuming applications implement them. Chassis MUST NOT ship default implementations that encode application-level assumptions, except for optional callback defaults as specified in INV-9.8.

**INV-9.8**: Optional callbacks (`tab_icon/1`, `closable?/1`) MUST have sensible structural defaults provided via a `__using__` macro or `@optional_callbacks`. The defaults must be content-blind (e.g., `closable?(_) -> true`, `tab_icon(_) -> nil`).

### Test Criteria

| ID | Test | Method |
|---|---|---|
| T-9.1 | `SlotProvider` behaviour is defined | Module exists with `@callback` declarations matching the table above |
| T-9.2 | Shell accepts `provider` attribute | Component spec: `attr :provider, :atom, required: true` |
| T-9.3 | `PersistenceBackend` behaviour is defined | Module exists with `@callback` declarations matching the table above |
| T-9.4 | `LayoutManager` accepts backend option | `start_link([persistence_backend: MyBackend])` wires init/terminate |
| T-9.5 | Optional callbacks have defaults | A module using `SlotProvider` that omits `tab_icon/1` compiles without warnings |
| T-9.6 | Provider callbacks receive only slot ID | Type spec: no callback accepts layout-internal state |
| T-9.7 | Backend operates on opaque binaries | Type spec: `save_layout/2` accepts `binary()`, never `tree_node()` |

---

## Boundary

This spec governs **Chassis framework internals** — how the framework is built, tested, and maintained. It does NOT govern:
- How consuming applications use Chassis (see Adopter Theming Spec)
- How consuming applications implement `SlotProvider` or `PersistenceBackend` callbacks
- Implementation choices (data structures, algorithms, Phoenix component patterns)
- Development workflow or tooling
- Deployment or packaging
