# Prompt 2 — Chassis Vision

## Role
Visionary

## Context
You are writing the **vision document** for Chassis — a layout shell framework for Phoenix LiveView. Chassis provides the structural skeleton for multi-pane applications. It manages panes, not content.

**Read these first (in order):**
1. `C:\Users\alpha\source\chassis\coordination\memo_founding_chassis.md` — founding memo: identity, bounded domain, vocabulary, module structure
2. `C:\Users\alpha\source\list-demo\common_vision.md` — shared constitutional physics across all projects in this ecosystem
3. `C:\Users\alpha\source\list-demo\vision.md` — the Seek project vision (Chassis was extracted from Seek's windowing layer)
4. `C:\Users\alpha\source\cognitive_mcp\coordination\canonical\coordinated_agents_vision.md` — the agent toolchain vision (Chassis will be used to build the agent dashboard delivery surface)

## Instruction

Write `C:\Users\alpha\source\chassis\coordination\vision.md` — the Chassis vision document.

The vision must:

1. **Define what Chassis is for** — what problem it solves, what it believes, what makes it different from existing layout systems
2. **Establish the bounded domain clearly** — layout management and spatial composition. Not content, not business logic, not application semantics
3. **Articulate the pillars** — the beliefs Chassis is built on (equivalent to the agent toolchain's 8 pillars, but for a layout framework)
4. **Describe what success looks like** — when Chassis is working well, what does a developer experience?
5. **Acknowledge the lineage** — Chassis was discovered inside Seek's windowing system, extracted because it deserved its own identity and bounded purpose
6. **Respect the common vision** — Chassis operates within the shared constitutional physics from `common_vision.md`

## Key Insights to Incorporate

These are findings from the clarification session that produced the Chassis identity:

- **"Workspace" is antiquated** — Chassis uses Composition, Slot, Stack, Division, Attach. Not desktop-era vocabulary.
- **Chassis is a Lego baseplate** — you snap content into slots. The frame doesn't know what you're building.
- **The bounded domain is layout and nothing else** — what's inside a slot is the consuming application's concern.
- **The contract**: you give it slot IDs and a layout tree. It gives you a spatial shell with tabs, splits, dock zones, and drag-drop. You fill the slots.
- **Clean boundary prevents pollution** — Chassis must not leak application concepts inward, and must not impose layout concepts outward beyond the contract.

## Boundary
- Do NOT write a spec, plan, or constitution — this is vision only
- Do NOT propose implementation details — vision describes *what* and *why*, not *how*
- Do NOT collapse Chassis's identity into the agent dashboard or any specific application

## Completion Criteria
- Vision document exists at `C:\Users\alpha\source\chassis\coordination\vision.md`
- It clearly distinguishes Chassis (the framework) from applications built on it
- Pillars are minimal and specific to layout shell concerns
- A new developer reading it understands what Chassis is for and what it will never become
