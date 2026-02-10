# Cross-Cutting Auditor Instructions — Phase 2+3 Build

**Prepared by**: Clarifier
**Date**: 2026-02-10
**For**: Auditor
**Subject**: Verification of Phase 2+3 additions: behaviour contracts (§F9), Shell refactor, persistence wiring, CSS remediation, and Shell component tests

---

## Scope

This audit covers code added in WU-12 through WU-17. The original Memos 1–7 remain valid for the original build surface. These new memos verify the *delta* — they should be run after confirming the original memos still pass.

**Pre-requisite**: `mix test --trace` → 80 tests, 0 failures.

---

## Memo 8: Behaviour Contract Audit (Article V, §F9)

**Constitutional authority**: Article V (The Contract), Article I (Domain Boundary)
**Spec references**: §F9 (INV-9.1 through INV-9.8)

### 8A — SlotProvider Callbacks Match Spec Table (INV-9.1)

**Method**: Review `lib/chassis/slot_provider.ex`.

```
grep -n "@callback" lib/chassis/slot_provider.ex
```

**Expected**: Exactly 4 callbacks matching the §F9.1 table:
- `render_content/2` — `(slot_id, assigns) → HEEx`
- `tab_label/1` — `(slot_id) → String.t()`
- `tab_icon/1` *(optional)* — `(slot_id) → String.t() | nil`
- `closable?/1` *(optional)* — `(slot_id) → boolean()`

**Finding trigger**: Missing callback, wrong arity, or extra callback → **CRITICAL** (contract mismatch).

### 8B — PersistenceBackend Callbacks Match Spec Table (INV-9.4)

**Method**: Review `lib/chassis/persistence_backend.ex`.

```
grep -n "@callback" lib/chassis/persistence_backend.ex
```

**Expected**: Exactly 2 callbacks:
- `save_layout/2` — `(composition, binary) → :ok | {:error, term}`
- `load_layout/1` — `(composition) → {:ok, binary} | {:error, term}`

**Finding trigger**: Missing callback, wrong arity, or extra callback → **CRITICAL**.

### 8C — Optional Callbacks Have Content-Blind Defaults (INV-9.8)

**Method**: Review the `__using__` macro in `slot_provider.ex`.

```
grep -A5 "__using__" lib/chassis/slot_provider.ex
```

**Expected**: `closable?(_) -> true`, `tab_icon(_) -> nil`. Defaults must not encode application assumptions.

**Finding trigger**: Default that references a specific slot ID or returns content-meaningful values → **CRITICAL** (content-blind violation).

### 8D — Behaviours Are Integration Surface Only (INV-9.7)

**Method**: Search for Chassis-shipped *implementations* of SlotProvider or PersistenceBackend in `lib/`.

```
grep -rn "@behaviour Chassis.SlotProvider\|@behaviour Chassis.PersistenceBackend\|use Chassis.SlotProvider\|use Chassis.PersistenceBackend" lib/chassis/ lib/chassis_web/components/
```

**Exception**: `lib/chassis_web/live/demo_live.ex` IS a consuming application and is permitted.
**Scope boundary**: only `lib/chassis/` and `lib/chassis_web/components/` — not `live/`.

**Expected**: Empty output. Chassis framework does not implement its own behaviours.

**Finding trigger**: Framework-side implementation of a behaviour → **MAJOR** (violates INV-9.7).

### 8E — Behaviour Tests Exist and Pass

**Method**: Run behaviour test files.

```
mix test test/chassis/slot_provider_test.exs test/chassis/persistence_backend_test.exs --trace
```

**Expected**: All tests pass. Verify test coverage:
- Callback definitions verified
- Optional defaults verified
- Content-blind invocation verified (slot ID only)

**Finding trigger**: Missing test dimension → **MINOR**. Failing test → **CRITICAL**.

---

## Memo 9: Shell Provider Contract Audit (Article V, §F9.1)

**Constitutional authority**: Article V (Contract Stability), §F9.1
**Spec references**: INV-9.2, INV-9.3

### 9A — Shell Accepts `provider` Attr (INV-9.3, T-9.2)

**Method**: Review Shell component attributes.

```
grep -n "attr :provider\|attr :render_slot_content" lib/chassis_web/components/shell.ex
```

**Expected**: `attr :provider, :atom, required: true` — and NO `render_slot_content` attribute.

**Finding trigger**: Old `render_slot_content` still present → **CRITICAL** (incomplete migration). Provider attr missing or wrong type → **CRITICAL**.

### 9B — Provider Invoked with Slot ID Only (INV-9.2)

**Method**: Review all `@provider.` calls in Shell.

```
grep -n "@provider\." lib/chassis_web/components/shell.ex
```

**Expected**:
- `@provider.render_content(@active_id, %{slot_id: @active_id})` — slot ID + minimal assigns
- `@provider.tab_label(slot_id)` — slot ID only
- `@provider.closable?(slot_id)` — slot ID only

Chassis MUST NOT pass tree state, stack context, or layout internals to provider callbacks.

**Finding trigger**: Provider callback receiving tree structure, composition state, or non-slot data → **CRITICAL** (boundary violation).

### 9C — Closable Gate Renders Conditionally

**Method**: Review Shell template for `closable?` gating.

```
grep -n "closable" lib/chassis_web/components/shell.ex
```

**Expected**: Close button rendered inside `<%= if @provider.closable?(slot_id) do %>` conditional.

**Finding trigger**: Close button always rendered regardless of `closable?` → **MAJOR** (contract unused).

### 9D — Shell Component Tests Cover Provider Integration

**Method**: Review `test/chassis_web/components/shell_test.exs`.

```
mix test test/chassis_web/components/shell_test.exs --trace
```

**Expected**: Tests exist for:
- Provider content rendering
- Tab label from provider
- Closable = true → close button present
- Closable = false → close button absent
- Deterministic rendering

**Finding trigger**: Missing test dimension → **MINOR**. Failing test → **CRITICAL**.

---

## Memo 10: Persistence Wiring Audit (Article II §2.4, §F9.2)

**Constitutional authority**: Article II (§2.4), Article V (The Contract)
**Spec references**: INV-9.5, INV-9.6

### 10A — LayoutManager Accepts Backend Option (INV-9.5)

**Method**: Review `LayoutManager.init/1`.

```
grep -n "persistence_backend\|backend" lib/chassis/layout_manager.ex
```

**Expected**: `init/1` reads `:persistence_backend` from opts. When provided, calls `backend.load_layout/1`. When absent, state is ephemeral (same as before Phase 2).

**Finding trigger**: Backend always required (no ephemeral mode) → **MAJOR**. Backend option ignored → **MAJOR**.

### 10B — Terminate Persists State (INV-9.5)

**Method**: Review `LayoutManager.terminate/2`.

**Expected**: When backend is present, `terminate/2` calls `backend.save_layout/2` for each composition. When backend is nil/absent, terminate is a no-op.

**Finding trigger**: Missing terminate callback → **MAJOR**. Terminate crash when no backend → **CRITICAL**.

### 10C — Backend Operates on Opaque Binaries (INV-9.6)

**Method**: Review the data flow from LayoutManager to PersistenceBackend.

**Expected**: LayoutManager calls `Persistence.save(tree)` → passes resulting binary to `backend.save_layout/2`. On load, receives binary from `backend.load_layout/1` → passes to `Persistence.restore/1`. The backend never sees tree structures directly.

**Finding trigger**: Tree passed directly to backend (not serialized) → **CRITICAL** (format leak).

### 10D — Persistence Wiring Tests Pass

```
mix test test/chassis/layout_manager_test.exs --trace
```

**Expected**: Tests for:
- Backend loads saved tree on init
- Backend persists on terminate
- Ephemeral mode works without backend

**Finding trigger**: Missing test → **MINOR**. Failing test → **CRITICAL**.

---

## Memo 11: CSS Remediation Verification (Article III)

**Constitutional authority**: Article III (§3.1–§3.4)
**Spec references**: INV-6.1, INV-6.5, G-1 closure, G-2 closure

### 11A — Zero Aesthetic Hard-Codes (G-1 Closure Verification)

**Method**: Re-run T-6.1 static analysis.

```
grep -n "font-size\|border-radius\|box-shadow\|font-family\|background-gradient" assets/css/chassis.css | grep -v "var("
```

**Expected**: Empty output. All aesthetic values use `--chassis-*` custom properties.

**Finding trigger**: Any remaining hard-coded aesthetic value → **CRITICAL** (G-1 regression).

### 11B — Required Properties Have No Fallbacks (INV-6.1, §3.3)

**Method**: Verify G-1 properties have no fallback values.

```
grep -n "chassis-tab-font-size\|chassis-tab-close-radius\|chassis-tab-close-size" assets/css/chassis.css
```

**Expected**: These appear as `var(--chassis-tab-font-size)` — no comma, no fallback value.

**Finding trigger**: Fallback value on a required aesthetic property → **MAJOR** (violates §3.3 No Default Theme).

### 11C — Interaction Properties Have Fallbacks (INV-6.5)

**Method**: Verify G-2 properties retain fallback values.

```
grep -n "chassis-transition-speed\|chassis-tab-close-hover-opacity" assets/css/chassis.css
```

**Expected**: These appear as `var(--chassis-transition-speed, 0.15s)` and `var(--chassis-tab-close-hover-opacity, 0.6)` — with fallbacks.

**Finding trigger**: Missing fallback on interaction property → **MINOR** (functional regression risk).

### 11D — Demo Theme Completeness

**Method**: Verify `demo_theme.css` defines all required properties.

```
grep -c "chassis-tab-font-size\|chassis-tab-close-radius\|chassis-tab-close-size" assets/css/demo_theme.css
```

**Expected**: Count ≥ 3 (all required properties present).

**Finding trigger**: Missing required property in demo theme → **MAJOR** (demo broken without fallbacks).

### 11E — Spec §T2 Updated

**Method**: Review `spec_adopter_theming.md` §T2 tables.

**Expected**: New properties documented with correct Required? status and Framework Fallback values.

**Finding trigger**: Property in CSS but not in spec → **MAJOR** (undocumented contract).

---

## Execution Order

Run memos 8→11 sequentially. Memo 8 (Behaviour Contracts) is the highest priority — if the behaviour definitions don't match the spec, all dependent work (Shell, persistence) is built on false assumptions.

**Pre-flight**: Run `mix test --trace` first. If any test fails, stop and report before proceeding with memos.

---

## Output Format

Same as Memos 1–7. Append findings to the existing `audit_full_build.md` or produce a supplementary report `audit_phase2_build.md`.

```
## Findings
### G-N: [Finding Title]
- Severity: CRITICAL / MAJOR / MINOR
- Constitutional Reference: [Article, INV-X.X]
- Evidence: [what was found]
- Expected: [what should have been]
```
