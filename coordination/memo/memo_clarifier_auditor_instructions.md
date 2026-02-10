# Cross-Cutting Auditor Instructions — Chassis Build

**Prepared by**: Clarifier
**Date**: 2026-02-09
**For**: Auditor
**Subject**: Post-build verification of the Chassis framework against constitutional invariants and specifications

---

## Purpose

These memos provide the Auditor with **structured, mechanically executable instructions** for verifying the Chassis build output. Each memo covers one cross-cutting audit dimension — a concern that spans multiple modules and cannot be checked by examining a single file.

The memos are organized by the constitutional article they verify, and each includes:

1. **What to verify** — the invariant claim
2. **How to verify** — the exact method (grep, test, review)
3. **What constitutes a finding** — the trigger condition
4. **Severity** — per Schedule A of the constitution

---

## Memo 1: Domain Boundary Audit (Article I)

**Constitutional authority**: Article I (§1.1–§1.4)
**Spec references**: §F1 (INV-1.1a through INV-1.2c)

### 1A — Inward Boundary: No Application Imports (INV-1.1a)

**Method**: Static analysis across all Chassis source files.

```
# Run in project root
grep -rn "alias MyApp\|import MyApp\|require MyApp" lib/chassis* lib/chassis_web*
grep -rn "alias .*App\." lib/chassis/ lib/chassis_web/
```

**Expected**: Empty output. No module under `Chassis` or `ChassisWeb` imports anything outside the Chassis/ChassisWeb namespace, Phoenix framework, or Elixir/Erlang stdlib.

**Exception list** (permitted imports): `Phoenix.*`, `Plug.*`, `Jason`, `:erlang`, `:crypto`, `Gettext`.

**Finding trigger**: Any import from a non-permitted namespace → **CRITICAL** (boundary violation, inward).

### 1B — Inward Boundary: Opaque Slot IDs (INV-1.1b)

**Method**: Code review of all function clauses in `Chassis.Layout`, `Chassis.LayoutManager`, `ChassisWeb.Components.Shell`.

Search for pattern matches on specific slot ID values:

```
grep -rn "slot_id == :" lib/chassis/ lib/chassis_web/
grep -rn "case slot_id" lib/chassis/ lib/chassis_web/
grep -rn ":editor\|:terminal\|:preview\|:data_grid" lib/chassis/ lib/chassis_web/
```

**Expected**: No function clause pattern-matches on a specific slot ID value. Slot IDs are opaque atoms or strings.

**Note**: The `demo_live.ex` file IS expected to reference specific slot IDs (`:editor`, `:preview`, `:terminal`) since it is a consuming application, not framework code. The audit boundary is `lib/chassis/` and `lib/chassis_web/components/`.

**Finding trigger**: A Chassis framework function that branches on a specific slot ID value → **CRITICAL**.

### 1C — Inward Boundary: No Content-Conditional Logic (INV-1.1c)

**Method**: Review Shell component for any conditional rendering based on what a slot contains.

```
grep -rn "if slot_id\|case slot_id\|when slot_id" lib/chassis_web/components/
```

**Expected**: Shell renders identically regardless of what slot ID is passed.

**Finding trigger**: Conditional rendering based on slot identity → **CRITICAL**.

### 1D — Outward Boundary: Render Callback Contract (INV-1.1d, INV-8.2)

**Method**: Review the Shell component's render callback invocation.

1. Open `lib/chassis_web/components/shell.ex`
2. Find where `render_slot_content` is invoked
3. Verify it passes ONLY the slot ID — no tree state, no layout internals, no stack context

**Expected**: The invocation is `@render_slot_content.(@active_id)` — a single slot ID argument.

**Finding trigger**: Any additional argument passed to the render callback → **CRITICAL** (contract violation).

### 1E — API Manifest Exists (INV-1.2a)

**Method**: Verify `API_MANIFEST.md` exists and lists every public module.

1. Check file exists: `API_MANIFEST.md`
2. Cross-reference: every module with `@moduledoc` in `lib/chassis/` and `lib/chassis_web/components/` is listed
3. Verify components, CSS properties, and hooks are documented

**Finding trigger**: Public module missing from manifest → **MAJOR**.

---

## Memo 2: Layout Tree Integrity Audit (Article II)

**Constitutional authority**: Article II (§2.1–§2.4)
**Spec references**: §F2 (INV-2.1 through INV-2.3)

### 2A — Exactly Three Node Types (INV-2.1)

**Method**: Review type spec in `lib/chassis/layout.ex`.

**Expected**: The `tree_node` type is `{:slot, id} | {:stack, active, ids} | {:division, dir, children} | nil`.

**Finding trigger**: Additional node types → **MAJOR**.

### 2B — No External Layout State (INV-2.2)

**Method**: Search for state-holding mechanisms outside the tree.

```
grep -rn "Agent\.\|:ets\.\|Process\.put\|:persistent_term\|@layout" lib/chassis/ lib/chassis_web/
```

**Expected**: No layout state stored in ETS, Agent, process dictionary, or module attributes. Only `LayoutManager` GenServer state holds the tree.

**Finding trigger**: Layout state outside the tree → **CRITICAL** (tree bypass).

### 2C — Normalization Enforced (INV-2.3)

**Method**: Run the existing test suite and verify normalization tests pass.

```
mix test test/chassis/layout_test.exs --trace
```

Check that tests for single-child division normalization and empty tree normalization exist and pass.

**Finding trigger**: Missing normalization test → **MAJOR**. Failing normalization test → **CRITICAL**.

---

## Memo 3: Rendering Audit (Article II, §2.2)

**Constitutional authority**: Article II (§2.2)
**Spec references**: §F3 (INV-3.1 through INV-3.3)

### 3A — Shell Covers All Node Types (INV-3.2)

**Method**: Review `lib/chassis_web/components/shell.ex` for function clauses.

**Expected**: Separate rendering clauses for:
- `nil` → empty state
- `{:slot, id}` → promotes to stack (or renders directly)
- `{:stack, active, ids}` → tab bar + content
- `{:division, dir, children}` → flex container with recursive children

**Finding trigger**: Missing node type clause → **CRITICAL**.

### 3B — No Phantom DOM (INV-3.3)

**Method**: Review Shell component output. Every DOM element must trace to a tree node.

Permitted non-node DOM:
- Tab bar elements (tabs, close buttons, spacer) — these are sub-elements of a stack node
- Dock overlay zones — these are sub-elements of a stack node
- The root `.chassis-shell` wrapper — this is the frame

**Finding trigger**: DOM elements that exist but correspond to no tree node and serve no structural purpose → **MAJOR**.

### 3C — Shell Component Tests (Planner Finding P-3)

**Method**: Check for dedicated Shell component test file.

```
ls test/chassis_web/components/shell_test.exs
```

**Expected**: File exists with tests for each node type rendering.

**Note**: The Planner flagged this as missing. If absent, record as **MINOR** — Shell is tested transitively through the demo page but lacks isolated component tests.

---

## Memo 4: Theming Discipline Audit (Article III)

**Constitutional authority**: Article III (§3.1–§3.4)
**Spec references**: §F6 (INV-6.1 through INV-6.4) + Adopter Theming Spec (§T1–§T4)

### 4A — Zero Aesthetic Hard-Coded Values (INV-6.1)

**Method**: Static analysis of `chassis.css`.

```
# Check for color literals
grep -n "#[0-9a-fA-F]" assets/css/chassis.css
grep -n "rgb\|hsl\|rgba\|hsla" assets/css/chassis.css

# Check for font values
grep -n "font-family\|font-size\|border-radius\|box-shadow\|background-gradient" assets/css/chassis.css
```

**Expected**: All empty. No color, font, or decorative values in `chassis.css`.

**Exception**: CSS comments may reference colors for documentation purposes.

**Finding trigger**: Any hard-coded aesthetic value → **CRITICAL** (theming violation per Schedule A).

### 4B — All Properties Reference CSS Custom Properties (INV-6.2)

**Method**: Cross-reference `var(--chassis-*)` references in `chassis.css` against the Adopter Theming Spec §T1 property table.

1. Extract all `var(--chassis-*)` from `chassis.css`
2. Extract all properties from `spec_adopter_theming.md` §T1-A and §T1-B
3. Verify bidirectional coverage:
   - Every §T1 property appears as a `var()` reference in CSS ✓
   - Every `var()` reference in CSS appears in the spec ✓

**Finding trigger**: Property in CSS but not in spec → **MAJOR** (undocumented contract). Property in spec but not in CSS → **MAJOR** (unused contract).

### 4C — No Aesthetic Fallback Values (T-T3)

**Method**: Search for fallback values in `var()` calls that encode aesthetics.

```
grep -n "var(--chassis-.*," assets/css/chassis.css
```

**Expected**: Structural fallbacks (e.g., `var(--chassis-tab-height, 2rem)`) are permitted. Aesthetic fallbacks (e.g., `var(--chassis-tab-bg, #1e1e2e)`) are prohibited.

**Finding trigger**: Aesthetic fallback value → **MAJOR** (violates §3.3 — No Default Theme).

### 4D — Demo Theme Completeness (T-T6)

**Method**: Verify `demo_theme.css` sets all §T1 required properties.

1. Open `assets/css/demo_theme.css`
2. Check each §T1-A and §T1-B property is defined

**Finding trigger**: Missing required property in demo theme → **MINOR** (demo is illustrative, not contractual).

---

## Memo 5: Vocabulary Audit (Article IV)

**Constitutional authority**: Article IV (§4.1–§4.3)
**Spec references**: §F7 (INV-7.1, INV-7.2)

### 5A — Prohibited Terms Absent (INV-7.2)

**Method**: Static analysis across ALL Chassis source (excluding test files testing this).

```
grep -rin "workspace\b" lib/
grep -rin "tab_group\b" lib/
grep -rin "split_view\b" lib/
grep -rin "\bsplit\b" lib/  # as a noun — ignore "split" in comments about porting
grep -rin "\bdock\b" lib/   # except DockPanel and dock_panel which are canonical
grep -rin "\bview\b" lib/   # except LiveView, view_file, review — only prohibited as layout concept
grep -rin "\bwindow\b" lib/ # except Phoenix.LiveView references
```

**Expected**: No prohibited terms in module names, function names, type names, or variable names.

**Permitted exceptions**:
- `DockPanel` / `dock_panel` — canonical (§4.2 table, "Panel" note)
- `LiveView` / `live_view` — Phoenix framework term, not Chassis vocabulary
- Comments explaining porting from Seek vocabulary — acceptable if clearly annotated

**Finding trigger**: Prohibited term in a function name, type name, or variable name → **MAJOR** (vocabulary violation per Schedule A).

### 5B — Canonical Terms Used (INV-7.1)

**Method**: Verify module and function names align with the vocabulary table.

| Canonical Term | Expected Usage |
|---|---|
| Slot | Function names: `slot/1`, `list_slots/1`; type: `slot_id` |
| Stack | Function name: `stack/2`; type used in tree |
| Division | Function name: `division/2`; type used in tree |
| Attach | Function name: `attach/2` |
| Shell | Module name: `ChassisWeb.Components.Shell` |
| Composition | Parameter name in LayoutManager |

**Finding trigger**: Core function using non-canonical name → **MAJOR**.

---

## Memo 6: Contract Surface Audit (Article V)

**Constitutional authority**: Article V (§5.1–§5.4)
**Spec references**: §F8 (INV-8.1 through INV-8.4)

### 6A — PubSub Events Are Spatial-Only (INV-8.3)

**Method**: Review the `broadcast/3` function in `LayoutManager`.

**Expected**: The event payload is `{:layout_changed, operation, composition, tree}`. The operation is a spatial verb (`:attach`, `:close`, `:divide`, `:focus`, `:reorder`, `:add_to_stack`). No field carries content identity.

```
grep -n "broadcast\|PubSub" lib/chassis/layout_manager.ex
```

**Finding trigger**: Event payload containing content type, content state, or application metadata → **CRITICAL** (contract violation).

### 6B — API Manifest Is Integration-Sufficient (INV-8.4)

**Method**: Read `API_MANIFEST.md` and answer: *Could a developer integrate Chassis using ONLY this document, without reading source code?*

Check that the manifest documents:
- [ ] How to start LayoutManager
- [ ] How to create a layout tree
- [ ] How to render the Shell
- [ ] What the render callback signature is
- [ ] How to register hooks
- [ ] What CSS properties to set
- [ ] What events to handle

**Finding trigger**: Missing integration step → **MAJOR** (contract incompleteness per §5.3).

### 6C — JS Hooks Are Content-Blind (INV-1.1c, INV-8.3)

**Method**: Review `assets/js/hooks/chassis_hooks.js`.

**Expected**: Hooks push events containing only spatial data (`slot_id`, `target_id`, `dragged_id`, `direction`). No hook reads, inspects, or transmits slot content.

**Finding trigger**: Hook event containing content data → **CRITICAL**.

---

## Memo 7: Persistence Audit (Article II, §2.4)

**Constitutional authority**: Article II (§2.4)
**Spec references**: §F5 (INV-5.1 through INV-5.3)

### 7A — Round-Trip Fidelity (INV-5.2)

**Method**: Run persistence tests.

```
mix test test/chassis/persistence_test.exs --trace
```

**Expected**: All round-trip tests pass for slot, stack, nested division, and nil trees.

### 7B — Format Is Private (INV-5.3)

**Method**: Review `Persistence` module's public API.

**Expected**: Only `save/1` and `restore/1` are public. The serialization format (currently `term_to_binary`) is not exposed or documented in the API manifest.

**Finding trigger**: Format details in public API or manifest → **MAJOR**.

### 7C — Persistence Wiring (S-2 Enrichment)

**Method**: Check if LayoutManager's `init/0` and `terminate/2` call Persistence functions.

**Expected**: Per the Planner's review (P-2), this was deliberately deferred. The Auditor should record the current state but NOT flag as a violation — the deviation was approved as a scope boundary decision.

**Recording**: Note in findings as "documented deviation, accepted by Planner."

---

## Execution Order

The Auditor should execute these memos in order 1→7. Memo 1 (Domain Boundary) is the highest priority — if the boundary is violated, all other findings are secondary.

Early termination: If Memo 1 produces any CRITICAL finding, the Auditor should still complete all memos (other violations may exist independently) but the build verdict must be **FAIL** regardless of other results.

---

## Output Format

The Auditor should produce a single audit report per the Auditor skill's output schema:

```
# Audit — Chassis Build
## Scope
## Method
## Findings
### G-N: [Finding Title]
- Severity: CRITICAL / MAJOR / MINOR
- Evidence: [what was found]
- Expected: [what should have been]
## Verdict
## Recommendations
```
