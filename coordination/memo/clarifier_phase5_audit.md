# Clarifier Audit — Phase 5 Interactive Features

## Intent

Phase 5 completed the spatial interaction model by adding two capabilities: divider resizing and keyboard navigation. The user can now resize divisions by dragging, cycle tabs with keyboard shortcuts, and navigate between divisions with directional keys. All interactions remain content-blind — Chassis manages spatial positions, never slot content.

## Shape

### Resize System
The resize architecture uses a **parallel weights map** in LayoutManager state, keyed by `{composition, slot_id}`. This is deliberate — the layout tree's algebraic type (`division | stack | slot`) is not modified, preserving INV-2.1. The Shell reads weights and applies CSS `flex` values. The JS hook (`ChassisResize`) handles drag mechanics and pushes a ratio to the server.

**Data flow**: `mousedown → mousemove → mouseup → pushEvent("chassis:resize_division") → LayoutManager.resize/4 → get_weights/2 → Shell flex`

### Keyboard Navigation
The keyboard system follows the established pattern: JS hook captures keystrokes, pushes spatial events, server resolves targets. The hook (`ChassisKeyboard`) has zero tree knowledge — it reads `data-active-slot` from the DOM and pushes direction strings. The server-side Layout module then walks the tree to find the target.

Three Layout functions were added:
- `next_in_stack/2` — wrapping cycle forward within a stack
- `prev_in_stack/2` — wrapping cycle backward within a stack  
- `adjacent/3` — tree walk to find a neighbor in a given direction

## Constraints

- **INV-2.1 preserved**: Weights are stored parallel to the tree, not inside it. The tree remains a 3-node algebraic type.
- **INV-1.1c preserved**: Both JS hooks push spatial events only — no content identifiers, no content inspection.
- **INV-4.1 extended**: `resize/3` was added to the §F4 operation list before any code was written (WU-21a).
- **INV-4.3 preserved**: `adjacent/3` navigates by tree structure, never by slot content.

## Success Signals

- 100 tests, 0 failures (5 new integration tests + 1 sync test)
- Resize event round-trips through LiveView and produces correct `flex` in rendered HTML
- `focus_next`/`focus_prev` cycle within docked stacks
- `focus_direction` crosses division boundaries
- `data-active-slot` syncs on both click and keyboard paths (remediated desync)

## Open Questions

1. **Weight persistence**: Weights are currently ephemeral — they survive within a session but are not saved/restored via `PersistenceBackend`. Should they be? This is a design decision for the Governor.
2. **`adjacent/3` edge cases**: What should happen when a user presses Alt+Left at the leftmost division? Currently returns `nil` (no-op). Should it wrap around?
3. **Weight keying by first slot**: Weights are keyed by the first slot ID in a subtree (`first_slot_id/1`). If that slot is closed, the weight is orphaned. Does this need cleanup logic?

## Observations

### Glossary Gaps

Phase 5 introduced concepts not yet in `glossary.md`:

| New Concept | Where Used | Proposed Definition |
|---|---|---|
| **Weight** | LayoutManager, Shell | A flex ratio (float) controlling relative sizing of children within a division. Stored parallel to the tree. |
| **Divider** | Shell, ChassisResize | A draggable UI element between division children that controls their weight ratio. |
| **Active Slot** | DemoLive, Shell, ChassisKeyboard | The currently focused slot for keyboard navigation purposes. Tracked as a separate assign, not derived from the tree. |

> [!IMPORTANT]  
> These should be added to `glossary.md` to prevent term drift.

### Planning Lesson Captured

The Planner documented a planning rule from the `active_slot` desync: **"New state ⇒ audit all existing writers."** This was correctly identified during review and remediated. The lesson is recorded in `implementation_plan.md` Phase 5 Retrospective.

### Boundary Compliance

All Phase 5 changes operate within the Chassis domain boundary. No content awareness was introduced. The `ChassisKeyboard` hook's use of `String.to_existing_atom(dir_str)` for direction parsing is safe because the direction values (`left`, `right`, `up`, `down`) are atoms that exist in the Layout module at compile time.
