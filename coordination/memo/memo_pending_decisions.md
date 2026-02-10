# Vision Artifact — Pending Decision Resolution

**From**: Clarifier
**To**: Governor
**Date**: 2026-02-10
**Re**: Resolving five open decisions blocking project close

---

## Intent

The Governor has five open decisions accumulated across the Chassis build. This project-cycle resolves them so the pipeline can close cleanly. Each decision is scoped below with Clarifier observations anchored to existing artifacts.

---

## Shape

Five decisions, each independent. No phasing required — these are naming and packaging choices, not architectural ones. The Governor can resolve them in a single pass.

---

## Constraints

- Chassis manages layout, not content. Names must not imply content ownership. (Founding Memo §Bounded Domain)
- Vocabulary discipline: canonical terms are Composition, Slot, Stack, Division, Attach. (Founding Memo §Refreshed Vocabulary)
- Chassis is a dependency, not a platform. (Vision §What Chassis Will Never Become)

---

## Decision 1: Phase 6 Audit Completion

**Pipeline ref**: `pipeline_state.md` — Pending Decision line 1
**Question**: Approve running Auditor, Constitution Writer, and Visionary with skill-loaded protocols for deep Phase 6 review.

**Clarifier observation**: Inline reviews already passed (pipeline_state.md, event 2026-02-10 audit). The deep reviews are a thoroughness measure, not a gate for broken things. The Governor chooses whether the inline pass is sufficient or whether full skill-loaded discipline is warranted before project close.

**Options**:
- **A — Run deep reviews**: Full conformance pass. Higher confidence. Cost: 3 additional role invocations.
- **B — Accept inline pass**: Inline reviews found no issues. Ship with what we have. Risk: latent drift undetected.

---

## Decision 2: Delivery Surface Project Name — EXCLUDED BY DESIGN

**Pipeline ref**: Founding Memo, Open Decision #2

**Governor ruling**: This is not a Chassis decision. Chassis is a membrane for ease of interface between disparate domains — it is not bound to any other project in this stack exclusively. There are multiple delivery surfaces, not one. Naming them is their own founding concern.

**Resolution**: Removed from Chassis pending decisions. This belongs in each consumer project's own founding memo.

---

## Decision 3: Backend Domain Name — EXCLUDED BY DESIGN

**Pipeline ref**: Founding Memo, Open Decision #3

**Governor ruling**: Same principle as Decision 2. There are multiple backends. Chassis does not name or bind to its consumers. The founding memo's framing of a single delivery surface → backend chain was accurate at inception but underspecified Chassis's actual role as a domain membrane.

**Resolution**: Removed from Chassis pending decisions.

---

## Decision 4: Hex Package vs Path Dependency

**Pipeline ref**: Founding Memo, Open Decision #4

**Governor ruling**: Path dependency for now. Hex infrastructure is prepared (WU-27). Publish when a second consumer materializes or the release posture demands it.

**Resolution**: Path dependency. Hex deferred but infrastructure ready.

---

## Decision 5: WU-28 Browser Verification

**Pipeline ref**: `pipeline_state.md` — Pending Decision line 2

**Governor ruling**: Browser verification runs at the very end, after the full process has flowed. Not a decision — a sequencing choice.

**Resolution**: Scheduled as the final step of project close.

---

## Success Signals

- All 5 decisions have a recorded resolution
- Pipeline state shows no pending decisions
- Project-cycle can proceed to close

## Open Questions

None — these are the open questions. Resolving them is the point.

## Observations

- Decisions 2 and 3 (project names) don't affect Chassis at all. They can be deferred without blocking Chassis project close.
- Decision 4 (Hex vs path) has a natural "both" answer that defers ceremony.
- Decision 1 (deep audit) and Decision 5 (browser verify) are the only ones that produce pipeline artifacts.
