# Audit — Phase 2+3 Build (Memos 8–11)

**Auditor**: Chassis Build Verification
**Date**: 2026-02-10
**Constitutional Authority**: Articles I, II, III, V
**Spec References**: §F9, §F6, §T1–§T4
**Test Suite**: 82 tests, 0 failures

---

## Scope

Cross-cutting audit of Phase 2+3 additions: behaviour contracts (WU-12–13), Shell refactor (WU-14), persistence wiring (WU-15), CSS remediation (WU-16), and Shell tests (WU-17). Executes Clarifier audit memos 8–11.

---

## Method

| Memo | Dimension | Method |
|---|---|---|
| 8 | Behaviour Contracts (§F9) | Callback review, default review, implementation search |
| 9 | Shell Provider Contract | Attr review, invocation analysis, conditional rendering check |
| 10 | Persistence Wiring | Backend option flow, terminate callback, binary opacity check |
| 11 | CSS Remediation | Static analysis, fallback strategy, demo theme, spec §T2 |

Full test suite: `mix test --trace` → **80 tests, 0 failures**.

---

## Findings

### G-5: `tab_icon/1` Callback Defined But Never Invoked

- **Severity**: MINOR
- **Status**: ✅ **CLOSED** (2026-02-10)
- **Constitutional Reference**: Article V §5.3 (Contract Stability), INV-9.1
- **Resolution**: Shell template now renders `<span class="chassis-tab-icon">{icon}</span>` when `tab_icon/1` returns non-nil. Conditional omits span when nil (default). 2 tests added (icon present, icon absent).

---

## Conformance Summary

### Memo 8 — Behaviour Contracts

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| 8A: SlotProvider callbacks | 4 callbacks matching §F9.1 | 4 callbacks, correct arities | ✅ PASS |
| 8B: PersistenceBackend callbacks | 2 callbacks matching §F9.2 | 2 callbacks, correct arities | ✅ PASS |
| 8C: Optional defaults content-blind | `closable?(_) → true`, `tab_icon(_) → nil` | Matches | ✅ PASS |
| 8D: No framework implementations | Empty search in lib/chassis + components | Only self-refs in behaviour definitions | ✅ PASS |
| 8E: Behaviour tests pass | All pass | 11 tests, 0 failures | ✅ PASS |

### Memo 9 — Shell Provider Contract

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| 9A: `provider` attr, no `render_slot_content` | `attr :provider, :atom, required: true` | Present × 2 (layout + tree_node), no old attr | ✅ PASS |
| 9B: Provider invoked with slot ID only | slot_id + minimal assigns | `tab_label(slot_id)`, `closable?(slot_id)`, `render_content(active_id, %{slot_id: active_id})` | ✅ PASS |
| 9C: Closable gate conditional | `<%= if @provider.closable?(slot_id) %>` | Present at L84 | ✅ PASS |
| 9D: Shell tests cover provider | Tests for content, labels, closable gate | 12 tests, 0 failures | ✅ PASS |
| 9E: `tab_icon/1` invoked | Expected in Shell | Present at L83–85 | ✅ PASS |

### Memo 10 — Persistence Wiring

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| 10A: Backend option in init | Reads `:persistence_backend`, calls `load_layout/1` | Present at L74–78 | ✅ PASS |
| 10B: Terminate persists | Calls `save_layout/2` per composition | Present at L92–98 | ✅ PASS |
| 10C: Opaque binary flow | Binary via `Persistence.save/1` → backend | `Persistence.save(tree) → binary` at L96 | ✅ PASS |
| 10D: Tests pass | Load, persist, ephemeral | 3 tests, 0 failures | ✅ PASS |

### Memo 11 — CSS Remediation

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| 11A: Zero aesthetic hard-codes | Empty grep | Empty | ✅ PASS |
| 11B: Required properties no fallback | `var(--chassis-tab-font-size)` etc. — no comma | Correct × 3 | ✅ PASS |
| 11C: Interaction properties with fallback | `var(..., 0.15s)` etc. — with comma | Correct × 2 | ✅ PASS |
| 11D: Demo theme completeness | 3 required properties defined | 3/3 present | ✅ PASS |

---

## Verdict

**PASS** (upgraded after G-5 closure)

All findings closed. Behaviour contracts match spec. Shell provider integration complete and tested. Persistence wiring works. CSS remediation verified.

---

## Recommendations

1. ~~**G-5 (MINOR)**: `tab_icon/1` rendering~~ — ✅ CLOSED
