# Audit — Chassis Build (Memos 1–7)

**Auditor**: Chassis Build Verification
**Date**: 2026-02-09
**Constitutional Authority**: Articles I–VI
**Spec References**: §F1–§F8, §T1–§T4
**Test Suite**: 80 tests, 0 failures (post Phase 3)

---

## Scope

Full cross-cutting audit of the Chassis framework build output, executing all 7 Clarifier audit memos sequentially. Covers: Domain Boundary (Article I), Layout Tree Integrity (Article II), Rendering (Article II §2.2), Theming Discipline (Article III), Vocabulary (Article IV), Contract Surface (Article V), and Persistence (Article II §2.4).

---

## Method

| Memo | Dimension | Method |
|---|---|---|
| 1 | Domain Boundary | Static analysis (grep), code review |
| 2 | Layout Tree | Type spec review, state mechanism search |
| 3 | Rendering | Shell clause review, phantom DOM review |
| 4 | Theming | CSS static analysis, cross-reference with spec |
| 5 | Vocabulary | Prohibited term scan across all lib/ |
| 6 | Contract | PubSub payload review, API manifest review, JS hook review |
| 7 | Persistence | Test execution, public API review |

Full test suite executed: `mix test --trace` → **54 tests, 0 failures**.

---

## Findings

### G-1: Hard-Coded Aesthetic Values in `chassis.css`

- **Severity**: MAJOR
- **Status**: ✅ **CLOSED** — Phase 2, WU-16 (2026-02-09)
- **Constitutional Reference**: Article III §3.1, INV-6.1
- **Resolution**: All 3 values replaced with `--chassis-*` custom properties without fallbacks. Properties added to Adopter Theming Spec §T2 as required. T-6.1 static analysis confirms zero aesthetic hard-codes.

---

### G-2: Additional Hard-Coded Values (Borderline Structural)

- **Severity**: MINOR
- **Status**: ✅ **CLOSED** — Phase 2, WU-16 (2026-02-09)
- **Constitutional Reference**: Article III §3.4
- **Resolution**: `transition: opacity 0.15s` and `opacity: 0.6` replaced with `var(--chassis-transition-speed, 0.15s)` and `var(--chassis-tab-close-hover-opacity, 0.6)` respectively. Padding/gap values classified as structural per Planner review (INV-6.3).

---

### G-3: No Dedicated Shell Component Tests

- **Severity**: MINOR
- **Status**: ✅ **CLOSED** — Phase 3, WU-17 (2026-02-10)
- **Reference**: Planner finding P-3
- **Resolution**: Created `test/chassis_web/components/shell_test.exs` with 12 tests covering all node types, provider integration, closable gating, and deterministic rendering.

---

### G-4: Persistence Wiring Deferred (S-2)

- **Severity**: Documented deviation (not a violation)
- **Status**: ✅ **CLOSED** — Phase 2, WU-13 + WU-15 (2026-02-09)
- **Reference**: Planner finding P-2, enrichment S-2
- **Resolution**: `Chassis.PersistenceBackend` behaviour created (WU-13). `LayoutManager` accepts `persistence_backend` option, calls `load_layout/1` on init and `save_layout/2` on terminate (WU-15). 3 tests verify wiring.

---

## Conformance Summary

| Memo | Article | Invariants Checked | Verdict |
|---|---|---|---|
| 1 — Domain Boundary | I | INV-1.1a, 1.1b, 1.1c, 1.1d, 1.2a, 1.2b, 1.2c | ✅ PASS |
| 2 — Layout Tree | II | INV-2.1, 2.2, 2.3 | ✅ PASS |
| 3 — Rendering | II §2.2 | INV-3.1, 3.2, 3.3 | ✅ PASS |
| 4 — Theming | III | INV-6.1, 6.2, 6.3, 6.4, 6.5 | ✅ PASS |
| 5 — Vocabulary | IV | INV-7.1, 7.2 | ✅ PASS |
| 6 — Contract | V | INV-8.1, 8.2, 8.3, 8.4 | ✅ PASS |
| 7 — Persistence | II §2.4 | INV-5.1, 5.2, 5.3 | ✅ PASS |
| 8 — Behaviours | V, I | INV-9.1–9.8 | ✅ PASS |

---

## Verdict

**PASS** (upgraded from PASS WITH GAPS after Phase 2 remediation)

All MAJOR and MINOR findings from the original audit have been remediated. G-1 (hard-coded aesthetics) and G-2 (borderline interaction values) are closed. G-4 (persistence wiring) is closed. The one remaining item is G-3 (Shell component tests) — tracked for Phase 3.

---

## Recommendations

1. ~~**G-1 (MAJOR)**: Replace hard-coded values~~ — ✅ CLOSED

2. ~~**G-2 (MINOR)**: Expose transition/opacity as custom properties~~ — ✅ CLOSED

3. ~~**G-3 (MINOR)**: Create `shell_test.exs`~~ — ✅ CLOSED

4. ~~**G-4 (Deviation)**: No action needed~~ — ✅ CLOSED
