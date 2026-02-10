---
description: Full development cycle — progress flows down, responsibility flows up
---

# work-cycle

The full recursive pipeline. Each generator produces, each reviewer checks upward coherence,
generator updates, then progress flows to the next level. Like a sort: compare, swap, advance.

## The program

```
# Phase 1: Capture — Governor's flash becomes structured intent
# The idea forms in one conversation. The pipeline runs in another.
# The memo on disk is the bridge — without it, context dies at the boundary.
# Naming: memo_<topic>.md (e.g., memo_work_cycle.md, memo_ast_editing.md)
clarity: [read skill] write memo of intent from this conversation to coordination/
coordinator: verify and commit — memo captured, dispatch pipeline in new conversation
#   GATE: memo exists on disk, faithfully represents governor's intent

# Phase 2: Vision — does the intent cohere with where we're going?
visionary: [read skill] review memo for vision coherence
clarity: [read skill] review visionary output for governor-to-vision alignment
visionary: update if clarifier flagged drift
coordinator: verify and commit — vision review
#   GATE: vision agrees with memo, all reviews resolved clean

# Phase 3: Constitution — does anything here change the law?
constitution-writer: [read skill] review memo against constitution, flag gaps or conflicts
visionary: [read skill] review constitution writer output for vision-constitution coherence
constitution-writer: update if visionary flagged drift
coordinator: verify and commit — constitution review
#   GATE: zero constitutional conflicts, gaps documented if any, all reviews clean

# Phase 4: Spec — what are the falsifiable invariants?
spec-writer: [read skill] produce or update spec from memo and constitution
visionary: [read skill] review spec for vision-spec coherence
clarity: [read skill] review spec for legibility and guidance
spec-writer: update spec, proceed if no questions for me
coordinator: verify and commit — spec produced
#   GATE: every invariant is falsifiable, all reviews resolved clean

# Phase 5: Plan — what is the work and in what order?
planner: [read skill] produce plan with tasklist from spec
spec-writer: [read skill] review plan for spec-plan coherence
clarity: [read skill] review plan for guidance and completeness
planner: update plan, proceed if no questions for me
coordinator: verify and commit — plan produced
#   GATE: plan traces to spec, every work unit maps to an invariant, all reviews clean

# Phase 6: Build — execute the plan
builder: [read skill] produce tasklist from plan
planner: [read skill] review tasklist for scope and alignment
coordinator: verify and commit — tasklist approved
#   GATE: tasklist covers plan, planner approved scope
builder: [read skill] execute tasklist
builder: produce walkthrough with proof
coordinator: verify and commit — build complete
#   GATE: compile ✅, tests ✅, walkthrough proves implementation
planner: [read skill] review build against plan
spec-writer: [read skill] review build against spec
clarity: [read skill] review build for legibility
builder: update, proceed if no questions for me
coordinator: verify and commit — build reviewed
#   GATE: build implements plan, satisfies spec, all reviews resolved clean

# Phase 7: Audit — cross-cutting verification
# Governor selects mode at dispatch:
#   simple  → auditor (governance, small changes)
#   rigorous → panel  (major builds, spec revisions)
auditor: [read skill] audit build against spec and constitution
# — or —
panelist(spec_realist): [read skill] findings on structural soundness
panelist(execution_skeptic): [read skill] findings on feasibility
panelist(audit_hawk): [read skill] findings on traceability and proof
panelist(drift_detector): [read skill] findings on vocabulary and scope drift
executive: [read skill] collate panel findings into panel_packet
# then:
clarity: [read skill] review audit findings, flag any that need escalation
coordinator: verify and commit — audit complete
#   GATE: zero blockers in findings, all high-severity items addressed

# Phase 8: Upward pass — do changes at lower levels require updates above?
spec-writer: [read skill] review build against spec, update spec if needed
constitution-writer: [read skill] review changes against constitution, flag amendments if needed
visionary: [read skill] review changes against vision, update vision if needed
clarity: [read skill] review upward chain for governor-to-vision alignment
coordinator: verify and commit — upward pass complete
#   GATE: all upstream docs coherent with downstream changes, full chain clean

# Phase 9: Close — compress and report
executive: [read skill] produce cycle report — what changed, what was tested, what needs attention
clarity: [read skill] review report with governor for completeness and next steps
coordinator: verify and commit — cycle complete
#   GATE: report covers all phases, no dangling items, governor informed
```

## The pattern

```
generator produces → reviewer checks upward → generator updates → coordinator gate
```

Every level follows this. The Coordinator gate has two exits:

| Exit | Condition | Action |
|---|---|---|
| **Clean** | Compile ✅ Tests ✅ Artifacts ✅ No pending decisions | Commit and advance |
| **Escalate** | Any role flagged an open question for Governor | Commit state, Executive produces report, pipeline pauses until Governor decides |

Progress only advances when coherence holds AND no decisions are pending.

## Responsibility map

| Role | Generates | Reviews (upward) |
|---|---|---|
| clarity | memos, guidance | governor↔vision, spec guidance, build guidance, audit triage |
| visionary | vision determinations | vision↔constitution, vision↔spec |
| constitution-writer | constitutional updates | — (reviewed by visionary) |
| spec-writer | specs, invariants | spec↔plan, spec↔build |
| planner | plans, tasklists | plan↔build |
| builder | code, tests, walkthroughs | — (reviewed by everyone above) |
| coordinator | clean commits | compile + test + commit at every gate |
| auditor | audit findings | build↔spec, build↔constitution |
| executive | cycle report | signal compression — decision-grade summary for Governor |

## Running in Antigravity

Single-threaded execution: paste each line as a prompt in sequence.
The Governor dispatches — each line is one conversation turn.
Skip phases that don't apply (e.g., no constitution change needed → skip Phase 3).

## Conversation Limits

A full cycle with rigorous audit is 50+ turns. Context degradation is expected beyond ~30 turns in a single conversation. Mitigations:

1. **Split at Coordinator gates.** Every `coordinator: verify and commit` is a safe split point — state is committed, the next phase can start in a fresh conversation.
2. **Mandatory split before Phase 6 Build.** Phases 1-5 are governance. Phase 6 is execution. Split here to give the Builder a clean context window.
3. **Split at escalations.** If a gate escalates, the Governor's decision happens in a new conversation anyway.

Rule of thumb: governance phases (1-5, 7-9) can share a conversation. Build phase (6) gets its own.

## Progress Report — SPEC[PT-1]

Each role outputs at the end of its turn:

```
- **Current line**: Phase N, Line M — `role: action`
- **Phase**: N of 9 (Phase Name)
- **Next line**: Phase N, Line M+1 — `role: next action`
```

This is the progress projection for single-thread execution. The Governor reads it to know where the cycle is.

## Context Isolation — SPEC[CI-1]

When multiple roles execute within a single conversation, context isolation is maintained by:

1. **Skill read first** — every role invocation begins by reading `.agent/skills/<role>/SKILL.md`. This is not optional. The read IS the conditioning. Without it, the agent runs on memory of the role instead of the actual constraints.
2. **Role invocation by name** — each program line begins with the role name, treated as a conditioning frame switch
3. **Artifact-mediated handoff** — each turn produces a written artifact; the next turn reads that artifact
4. **Scope declaration** — each turn begins by stating what it is reviewing and what its boundaries are

The Coordinator gate runs between phases, not between every role switch. Within a phase, rule 1 is behavioral — the agent must self-enforce. Between phases, the conversation split (see Conversation Limits) provides natural conditioning reset.

This is a partial mitigation. Full isolation requires separate sessions. The Governor accepts the tradeoff while the legislature is being built.

## Notes

- The Governor remains outside the program — reached only through escalation
- `proceed if no questions for me` = autonomous authority with exception path
- Clarity appears at every phase boundary — the capture mechanism is continuous
- The Coordinator validates its own commit message contains Reviewed/Decided/Changed/Next before committing
