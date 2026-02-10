---
description: Multi-phase project cycle — Executive scopes, Governor dispatches work-cycles
---

# project-cycle

For projects that span multiple phases. The Executive scopes the project into phases,
each phase gets its own work-cycle. The Governor dispatches one cycle at a time.

Use this when the intent is too large for a single work-cycle. For single-pass fixes,
use `/work-cycle` directly.

## The program

```
# Phase 0: Capture — same as work-cycle Phase 1
clarity: [read skill] write memo of intent from this conversation to coordination/
coordinator: verify and commit — memo captured

# Phase 1: Vision + Constitution — validate the intent
visionary: [read skill] review memo for vision coherence
clarity: [read skill] review visionary output for governor-to-vision alignment
visionary: update if clarifier flagged drift
constitution-writer: [read skill] review memo against constitution, flag gaps or conflicts
visionary: [read skill] review constitution writer output for vision-constitution coherence
constitution-writer: update if visionary flagged drift
coordinator: verify and commit — intent validated

# Phase 2: Spec + Phasing — parallel generation, then cross-review
# logical parallel — both read the validated memo independently
# in single-threaded execution, run sequentially; cross-review afterward
spec-writer: [read skill] produce spec from memo and constitution
executive: [read skill] scope project into phases from memo → phase_list.md
# cross-review:
spec-writer: [read skill] review phase list for invariant coverage
executive: [read skill] review spec for phasing feasibility
# reconcile:
spec-writer: update spec if phases revealed gaps
executive: update phase list if spec revealed ordering issues
clarity: [read skill] review spec + phase list for governor-to-vision alignment
spec-writer: update spec, proceed if no questions for me
executive: update phase list, proceed if no questions for me
coordinator: verify and commit — spec + phases produced
#   GATE: every invariant is falsifiable, phase list covers all invariants, all reviews clean

# Phase 3: Governor reviews phase list
# Pipeline pauses here. Governor decides:
#   - approve phase list as-is
#   - reorder or merge phases
#   - reject and re-scope

# Phase 4: Loop — one work-cycle per phase (same conversation)
# [read skill] on every line provides reconditioning between phases.
# If context degrades, split at any Coordinator gate per Conversation Limits.
# For each phase in phase_list.md:
#   1. clarity: [read skill] write memo of intent for THIS phase (scoped from phase_list.md)
#   2. coordinator: verify and commit — phase memo captured
#   3. Run /work-cycle Phases 2-9 (skip Phase 1 capture — memo already written)
#   4. Phase 9 Close marks phase complete in phase_list.md
#   5. Governor reviews cycle report, proceeds to next phase or splits conversation

# Phase 5: Project close
executive: [read skill] produce project report — all phases, cumulative changes, lessons
clarity: [read skill] review project report with governor for completeness and next steps
executive: update report, proceed if no questions for me
coordinator: verify and commit — project complete
#   GATE: report covers all phases, no dangling items, governor informed
```

## The pattern

```
executive scopes → governor approves → loop(work-cycle per phase) → executive reports
```

The Governor touches three points:
1. **Entry** — talks to Clarity, memo captured
2. **Phase gate** — reviews and approves the phase list
3. **Exit** — reads the Executive's project report

Everything else runs autonomously within each work-cycle.

## Phase list format

The Executive produces `phase_list.md` with:

```
# Phase List: <project name>

## Phase 1: <name>
- **Scope**: what this phase covers
- **Invariants**: which spec invariants this phase addresses
- **Depends on**: prior phases (if any)
- **Status**: pending | in-progress | complete

## Phase 2: <name>
...
```

Each phase's scope becomes the memo of intent for its work-cycle.

## When to use project-cycle vs work-cycle

| Situation | Program |
|---|---|
| Quick governance fix, single spec change | `/work-cycle` |
| Feature with clear scope, one build | `/work-cycle` |
| Multi-component feature, sequential builds | `/project-cycle` |
| New capability with spec + plan + build | `/project-cycle` |
| Unclear scope — needs decomposition first | `/project-cycle` |
