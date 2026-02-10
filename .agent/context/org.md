# Organization

## Governing Law

[constitutional_invariants.md](file:///C:/Users/alpha/source/chassis/coordination/canonical/constitutional_invariants.md)

## Deployment

Chassis — layout shell framework for Phoenix LiveView. Provides the structural skeleton for multi-pane, tabbed, splittable, dockable layouts. Manages panes, not content.

## Protection Model

| Role | Protects | Filled By | Substrate |
|---|---|---|---|
| Governor | Authority — the right to decide who decides | [name] | human |
| Executive | Momentum — what gets built, in what order, with what team | [name] | human |
| Visionary | Direction — what the system is for and what matters | [assigned] | agent |
| Clarifier | Legibility — the human's ability to understand the system | [assigned] | agent |
| Coordinator | Flow — artifacts reaching the right role at the right time | [name] | human |
| Spec Writer | Truth — falsifiable invariants derived from vision | [assigned] | agent |
| Planner | Structure — the partition of work into coherent, testable units | [assigned] | agent |
| Builder | Reality — working code that matches the plan | [assigned] | agent |
| Panel | Coherence — independent verification through focused specialists | [assigned] | agent |

## Authority Chain

Governor → Executive → role-specific grants.

The Governor is the sole source of organizational authority. The Executive operates under delegated authority from the Governor. All other roles receive task-scoped grants from the Executive.

## Pipeline

```
clarification → intent lock → normalization → lowering → verification
(clarifier)     (spec+visionary) (plan)        (execute)   (audit)
```
