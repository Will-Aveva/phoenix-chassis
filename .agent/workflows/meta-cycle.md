---
description: The meta-cognitive development cycle for Chassis — run this loop continuously while thinking and working
---

# Meta-Cycle — Chassis

> **Constitution**: `coordination/canonical/constitutional_invariants.md` (pending)
> **Vision**: `coordination/canonical/vision.md` (pending)

This is the Chassis-specific meta-cycle. It references the 8-phase pipeline, MCP tools as the execution substrate, and role-specific skills.

## The 8-Phase Pipeline

The pipeline runs in this order:

1. **clarify** → Clarifier (`.agent/skills/clarifier/SKILL.md`)
2. **spec** → Spec Writer (`.agent/skills/spec-writer/SKILL.md`)
3. **vision_review** → Visionary (`.agent/skills/visionary/SKILL.md`)
4. **plan** → Planner (`.agent/skills/planner/SKILL.md`)
5. **execute** → Builder (`.agent/skills/builder/SKILL.md`)
6. **audit** → Auditor (`.agent/skills/auditor/SKILL.md`)
7. **panel** → Panelist (`.agent/skills/panelist/SKILL.md`)
8. **executive_signal** → Executive (`.agent/skills/executive/SKILL.md`)

Routing between phases is governed by the Orchestrator (`.agent/skills/orchestrate/SKILL.md`).

## Execution Substrate — MCP Tools

All phase dispatch goes through the MCP server tools:

- `semantic_search(query, top_k)` — search the codebase semantically
- `find_symbol(name, kind)` — find symbol definitions
- `find_references(symbol, file)` — find references to a symbol
- `reindex(paths)` — reindex the codebase
- `list_declarations(file_path)` — file structure outline

## Continuous Loop

// turbo-all

### Step 1: Orient — Where are we?

Check `coordination/pipeline_state.md` for current pipeline position. Then read context files:
- `coordination/pipeline_state.md` — current phase, recent events, pending decisions
- `.agent/context/project.md` — project identity and current phase
- `.agent/context/org.md` — authority chain and protection model
- `.agent/context/glossary.md` — canonical vocabulary

### Step 2: Identify the active phase

Determine which pipeline phase is currently active. Check for:
- Incomplete deliverables from the current phase
- Blocking Contradictions that need routing upstream
- Governance gates that need Governor approval

### Step 3: Load the right skill

Read the SKILL.md for the active role from `.agent/skills/<role>/SKILL.md`. The Active Constraints in the skill define your posture for this phase.

### Step 4: Execute within constraints

Work within the role's Active Constraints. Key rules:
- Every claim must be traceable — anchor to artifacts
- A phase is not done until its completion predicate is satisfied
- Chassis manages layout, not content — stay within the bounded domain

### Step 5: Check for upstream escalation

When execution gets hard, escalate upstream rather than grinding through complexity:
- If the plan is unclear → escalate to Planner
- If the spec is ambiguous → escalate to Spec Writer
- If intent has drifted → escalate to Visionary
- If authority or structure is at risk → escalate to Executive

### Step 6: Emit deliverable or contradiction

Produce the phase deliverable per the output schema, or emit a Blocking Contradiction if you cannot proceed.

### Step 7: Update pipeline artifacts

Update `coordination/pipeline_state.md` with the phase transition. Append the routing event to `coordination/routing_log.md`. Create a handoff record in `coordination/handoff_queue.md`.

### Step 8: Route to next phase

The Orchestrator routes the deliverable to the next phase. Every routing decision is logged. Human governance gates must be respected — the Orchestrator does not bypass them.

### Step 9: Return to Step 1

The cycle is continuous. After completing a phase, re-orient and begin the next iteration.

## Upstream Escalation Paths (Chassis-specific)

| When this happens | Escalate to | Action |
|---|---|---|
| Spec clause is ambiguous or missing | Spec Writer | Route with contradiction |
| Plan doesn't match spec | Planner | Route with conformance finding |
| Vision-spec drift detected | Visionary | Route for vision review |
| System coherence at risk | Executive | Route executive signal |
| Cross-role deliberation needed | Panel | Route with panel role assignment |
| Governor approval required | Governor (human) | Surface through Executive Signal |

## Key References

- Constitution: `coordination/canonical/constitutional_invariants.md`
- Vision: `coordination/canonical/vision.md`
- Pipeline state: `coordination/pipeline_state.md`
- Routing log: `coordination/routing_log.md`
- Handoff queue: `coordination/handoff_queue.md`
