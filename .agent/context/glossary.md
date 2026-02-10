# Glossary

## Terms

- **Active Constraints** — The 3–5 most dangerous rules to forget for a given role, injected by the orchestrator at prompt top.
- **Authorized Domains** — Decision envelope defining what a role may decide; injected, not self-authored.
- **Blocking Contradiction** — A halt signal emitted when artifacts conflict or the spec lacks needed constraints.
- **Completion Predicate** — The condition that must hold before a phase deliverable is considered done.
- **Conformance Review** — Upward review where a phase's output is checked against the upstream phase for deviations.
- **Executive Signal** — Decision-grade summary compressed by the Executive's Interface function for the Governor.
- **False Confidence** — Clauses with only indirect proof and no direct test; the system believes they are covered but they are not.
- **Governance Gate** — An approval checkpoint that automation must not bypass (§0.4).
- **Panel Packet** — The synthesized output of panel deliberation: agreements, disagreements, candidate resolutions.
- **Phase Output Schema** — The required heading structure for each phase's deliverable (§1.6).
- **Progress Projection** — Per-run pipeline state tracking (Constitution §13.3); distinct from macro project phase.
- **Work Unit** — An atomic partition of work: code + test + passing run.
- **Handoff** — The structured transfer of work from one role to another, comprising artifacts, phase context, binding constraints, completion criteria, and known risks (Constitution §7.1).
- **Conversation boundary** — The point at which a new agent conversation is opened for a role transition, ensuring a clean context window per §4.3.
- **Handoff queue** — The `handoff_queue.md` artifact listing pending handoff records that the Coordinator (or Governor) dispatches by opening new conversations.
- **Handoff message** — The structured text pasted into a new conversation to activate a role session.
- **Verify and commit** — The Coordinator's gate action at every phase boundary: compile, test, check artifacts, then commit with structured message. The operational expression of "handoff discipline" (Constitution §2.6).
- **Gate postcondition** — A phase-specific statement of what must be true after a Coordinator gate opens. Documented as `GATE:` annotations in the work-cycle program. Constitutional authority: §5.8.
- **Phase list** — The Executive's scoping artifact (`phase_list.md`) decomposing a project into sequential phases, each scoped for one work-cycle. Produced in project-cycle Phase 2.
- **Reconditioning** — Re-reading SKILL.md before acting within a session. The `[read skill]` notation in the work-cycle program. Constitutional authority: §4.1.

## Deprecated Terms

- `common_vision.md` → use `constitutional_invariants.md`
- `Executive Interface` (as standalone role) → use `Executive (Interface function)`

## Distinctions

| Term A | Term B | Distinction |
|---|---|---|
| Coordinator | Orchestrator | Coordinator is an organizational role (protects flow). Orchestrator is mechanical routing infrastructure. |
| Active Constraints | Authorized Domains | Active Constraints define role posture. Authorized Domains define decision envelope. Both injected, neither self-authored. |
