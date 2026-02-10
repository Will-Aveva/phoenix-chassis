# Audit — Domain Boundary (Article I)

**Auditor**: Chassis Build Verification
**Date**: 2026-02-09
**Scope**: Memo 1 of the Clarifier's Cross-Cutting Auditor Instructions
**Constitutional Authority**: Article I (§1.1–§1.4)
**Spec References**: §F1 (INV-1.1a through INV-1.2c)

---

## Scope

Audit of all Chassis framework source files (`lib/chassis/`, `lib/chassis_web/components/`) for compliance with the Domain Boundary invariants. The demo application (`lib/chassis_web/live/demo_live.ex`) is a consuming application and is excluded from inward boundary checks but included for outward boundary assessment.

---

## Method

Five checks executed per Clarifier's Memo 1:

| Check | Method | INV |
|---|---|---|
| 1A — No Application Imports | `grep` for `import`, `alias`, `require`, `use` across framework code | INV-1.1a |
| 1B — Opaque Slot IDs | `grep` for `slot_id == :`, `case slot_id`, specific slot names | INV-1.1b |
| 1C — No Content-Conditional Logic | `grep` for `if slot_id`, `when slot_id`, `case slot_id` in components | INV-1.1c |
| 1D — Render Callback Contract | Manual review of Shell render_slot_content invocation | INV-1.1d, INV-8.2 |
| 1E — API Manifest Completeness | Cross-reference `@moduledoc` modules against `API_MANIFEST.md` | INV-1.2a |

---

## Findings

### Check 1A — No Application Imports (INV-1.1a): ✅ PASS

**Evidence**: All `alias`, `import`, `require`, and `use` statements in framework code were enumerated:

| File | Statement | Permitted? |
|---|---|---|
| `layout_manager.ex` | `alias Chassis.Layout` | ✅ Same namespace |
| `layout_manager.ex` | `alias Phoenix.PubSub` | ✅ Phoenix framework |
| `layout_manager.ex` | `use GenServer` | ✅ Elixir stdlib |
| `application.ex` | `use Application` | ✅ Elixir stdlib |
| `shell.ex` | `use Phoenix.Component` | ✅ Phoenix framework |
| `sidebar.ex` | `use Phoenix.Component` | ✅ Phoenix framework |
| `dock_panel.ex` | `use Phoenix.Component` | ✅ Phoenix framework |
| `core_components.ex` | `alias Phoenix.LiveView.JS` | ✅ Phoenix framework |
| `core_components.ex` | `use Gettext` | ✅ Permitted dependency |

**No application-specific imports found.** Zero violations.

---

### Check 1B — Opaque Slot IDs (INV-1.1b): ✅ PASS

**Evidence**: Searched all framework code (`lib/chassis/` and `lib/chassis_web/components/`) for:
- `slot_id == :` — **0 results**
- `case slot_id` — **0 results**
- `:editor`, `:terminal`, `:preview`, `:data_grid` — **0 results in framework code**

No function clause in framework code pattern-matches on a specific slot ID value. All slot ID handling is opaque.

**Note**: `demo_live.ex` (consuming application) correctly references specific slot IDs — this is expected and permitted.

---

### Check 1C — No Content-Conditional Logic (INV-1.1c): ✅ PASS

**Evidence**: One match found in Shell component:

```elixir
# shell.ex:77
class={"chassis-tab #{if slot_id == @active_id, do: "active", else: "inactive"}"}
```

**Assessment**: This is a **spatial comparison** — it determines which tab is currently active by comparing two opaque IDs. It does not inspect what the slot *contains*. The comparison operates on positional state (which tab is focused), not content state (what the tab renders). This is core layout functionality required by Article II (§2.2) — rendering must reflect the tree, and the tree records which slot in a stack is active.

**Verdict on this match**: **Not a violation.** Correctly classified as spatial logic.

---

### Check 1D — Render Callback Contract (INV-1.1d, INV-8.2): ✅ PASS

**Evidence**: The render callback is invoked at exactly one location in Shell:

```elixir
# shell.ex:98
<div class="chassis-slot-content">{@render_slot_content.(@active_id)}</div>
```

**Arguments passed**: `@active_id` — a single slot ID (opaque atom or string).

**Arguments NOT passed**: No tree state, no stack context, no layout internals, no sibling information, no position data.

The callback signature matches the documented contract: `(slot_id) → HEEx`.

---

### Check 1E — API Manifest Completeness (INV-1.2a): ✅ PASS

**Evidence**: Cross-reference of all modules with public `@moduledoc` against `API_MANIFEST.md`:

| Module | Is Framework API? | In Manifest? | Status |
|---|---|---|---|
| `Chassis.Layout` | ✅ Yes | ✅ Yes | Covered |
| `Chassis.LayoutManager` | ✅ Yes | ✅ Yes | Covered |
| `Chassis.Persistence` | ✅ Yes | ✅ Yes | Covered |
| `ChassisWeb.Components.Shell` | ✅ Yes | ✅ Yes | Covered |
| `ChassisWeb.Components.Sidebar` | ✅ Yes | ✅ Yes | Covered |
| `ChassisWeb.Components.DockPanel` | ✅ Yes | ✅ Yes | Covered |
| `ChassisWeb.Components.Layouts` | ❌ Phoenix scaffold internal | Not listed | Correct exclusion |
| `ChassisWeb.Components.CoreComponents` | ❌ Phoenix scaffold | Not listed | Correct exclusion |
| `ChassisWeb.DemoLive` | ❌ Demo app, not framework | Not listed | Correct exclusion |
| `Chassis.Application` | ❌ `@moduledoc false` | Not listed | Correct exclusion |

The manifest also documents:
- ✅ 15 CSS custom properties
- ✅ 3 JavaScript hooks
- ✅ 5 LiveView events
- ✅ Integration code example

No public module is missing from the manifest.

---

## Observations

### O-1: `core_components.ex` Contains Phoenix Scaffold Code

`ChassisWeb.CoreComponents` is an auto-generated Phoenix scaffold file containing general-purpose UI components (buttons, inputs, tables, modals). None of these are Chassis framework API — they are Phoenix boilerplate. However, this file:
- Contains hard-coded CSS classes and visual opinions (via Phoenix generators)
- Is 500+ lines of non-Chassis code

This does not violate Article I because `CoreComponents` is not part of Chassis's public API surface (it's not in the manifest). However, for a framework that claims no visual opinion, shipping a large opinionated component file could cause confusion for adopters.

**Recommendation**: Consider either (a) removing `core_components.ex` and the default Phoenix template system if they are not needed by Chassis, or (b) adding a note in documentation that these are Phoenix scaffold files, not Chassis components. **Not a finding — an observation only.**

### O-2: Boundary Symmetry (§1.4) Verified

The outward boundary was also checked via the API manifest review. Chassis does not expose internal data structures (`traverse_replace`, `normalize`, `do_close`) in the public API — these are all either `@doc false` or private functions. The manifest documents only construction functions and query functions, per INV-1.2b.

---

## Verdict

**PASS**

All five Domain Boundary checks pass with zero violations. The inward boundary (no application imports, opaque slot IDs, no content-conditional logic, render callback passes only slot ID) and outward boundary (API manifest complete, no internal leakage) are both intact and mechanically verified.

No CRITICAL, MAJOR, or MINOR findings.

---

## Recommendations

1. **O-1 (CoreComponents)**: Track as a cleanup item for a future housekeeping WU. Not blocking.
2. **Proceed to Memo 2**: Layout Tree Integrity Audit (Article II).
