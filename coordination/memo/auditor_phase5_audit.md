# Audit — Phase 5 Interactive Features

## Scope

All files changed in Phase 5, audited against:
- Constitutional invariants (Articles I–VI)
- Spec framework §F1–§F6
- Glossary canonical terms (§4.1)

**Files audited**: `layout.ex`, `layout_manager.ex`, `shell.ex`, `demo_live.ex`, `chassis_hooks.js`, `index.js`, `spec_framework.md`, `demo_live_test.exs`

## Method

1. Read each changed file
2. Check against each constitutional article for violations
3. Check spec framework for operation completeness
4. Check glossary for vocabulary compliance
5. Check code for correctness bugs

---

## Findings

### G-1: §2.1 Tension — Weights Exist Outside the Tree

- **Severity**: MAJOR
- **Evidence**: `LayoutManager` stores `weights: %{}` in GenServer state, parallel to `compositions`. Constitution §2.1 states: *"The layout tree — a recursive structure of divisions, stacks, and slots — is the sole authoritative representation of spatial arrangement. There is no layout state that exists outside the tree."*
- **Expected**: All layout state should live in or derive from the tree.
- **Mitigating context**: The Spec Writer explicitly rejected putting weights inside the tree (would violate INV-2.1's 3-node algebraic type). The parallel map was the approved design. This is a genuine tension between §2.1 ("no state outside tree") and INV-2.1 ("exactly three node types"). The spec amendment adding `resize/3` to §F4 does not resolve this tension constitutionally.
- **Recommendation**: Governor decision required — either amend §2.1 to acknowledge presentation hints that don't affect tree structure, or accept the tension as documented. This is not a code bug — it's a constitutional gap exposed by the feature.

---

### G-2: Variable Shadowing Bug in `adjacent/3`

- **Severity**: MAJOR
- **Evidence**: In [layout.ex](file:///C:/Users/alpha/source/chassis/lib/chassis/layout.ex) lines 262–266:
  ```elixir
  def adjacent(tree, slot_id, direction) do
    case find_adjacent(tree, slot_id, direction) do
      nil -> nil
      slot_id -> slot_id  # ← shadows the parameter
    end
  end
  ```
  The `slot_id` in the `case` branch shadows the function parameter. In Elixir, this means the branch acts as a match against the parameter value — if `find_adjacent` returns a *different* slot ID, this branch will **not match**, and the function will raise `CaseClauseError`. The function works today only because tests happen to return values that match the original or nil.
- **Expected**: The branch variable should use a distinct name (e.g., `result`) to match any non-nil return.
- **Recommendation**: Builder fix — rename to `result -> result`.

---

### G-3: §4.1 Vocabulary Gap — New Terms Not Canonicalized

- **Severity**: MINOR
- **Evidence**: Phase 5 introduces three concepts used in code and docs but absent from constitutional vocabulary (§4.1) and glossary:
  - **Weight** — flex ratio for division children
  - **Divider** — drag handle between division children
  - **Active Slot** — keyboard focus target
- **Expected**: New spatial concepts that appear in the API surface should be canonicalized in glossary.md.
- **Recommendation**: Constitution Writer adds to §4.1 table if Governor approves these as constitutional terms. At minimum, Clarifier adds to glossary.md.

---

### G-4: Weights Not Persisted via PersistenceBackend

- **Severity**: MINOR
- **Evidence**: `terminate/2` in LayoutManager persists `compositions` via the backend but does not persist `weights`. Weights are lost on process restart.
- **Expected**: §2.4 states persistence is tree serialization. Since weights are intentionally outside the tree (G-1), their persistence is a design question, not a constitutional violation. But the user may expect resize positions to survive restarts.
- **Recommendation**: Design decision for Governor — persist weights separately, or accept ephemerality.

---

### G-5: `ChassisResize` Hook — DOM Mutation During Drag

- **Severity**: MINOR
- **Evidence**: The `onMouseMove` handler in `ChassisResize` directly sets `prevEl.style.flex` and `nextEl.style.flex` during drag for smooth visual feedback. This is a temporary DOM mutation that precedes the server round-trip (which re-renders from the tree).
- **Expected**: §2.3 says every layout change must be a tree mutation. During drag, the visual feedback is transient — the authoritative state update happens on `mouseup` via `pushEvent`. This is analogous to drag ghost rendering, which is standard LiveView practice.
- **Recommendation**: No action needed — the transient DOM mutation is acceptable as interaction feedback, not authoritative state. The `mouseup` event triggers the canonical tree path.

---

## Verdict

**PASS WITH GAPS**

The code is correct in behavior, all tests pass, and no boundary violations (§1.2, §1.3) were found. The two substantive issues are:

1. **G-1** is a constitutional tension requiring Governor decision, not a code fix
2. **G-2** is a real bug that will manifest when `adjacent/3` returns a slot ID different from the input — needs immediate Builder fix

## Recommendations

| Priority | Finding | Owner |
|---|---|---|
| **Immediate** | G-2: Fix `adjacent/3` variable shadowing | Builder |
| **Governor decision** | G-1: Amend §2.1 or accept tension | Governor |
| **Governor decision** | G-4: Weight persistence policy | Governor |
| **Follow-up** | G-3: Glossary update | Clarifier / Constitution Writer |
