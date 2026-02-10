# Memo — Founding Chassis

**From**: Clarifier (with Executive findings)
**To**: Governor
**Date**: 2026-02-09
**Re**: Chassis — a layout shell framework for Phoenix LiveView

---

## What Chassis Is

Chassis is a **layout shell framework** for Phoenix LiveView. It provides the structural skeleton for multi-pane, tabbed, splittable, dockable layouts rendered in a browser. It manages panes, not content.

Chassis does not know what's inside its slots. You can build a data explorer (Seek), an agent dashboard (the delivery surface), or anything else that needs a workbench-style layout. Chassis gives you the frame. You bring the content.

## Origin

Chassis is extracted from the windowing system built inside the Seek project (`C:\Users\alpha\source\list-demo\demo_grid`). The core primitives already exist and are production-tested:

| Seek Source | Chassis Equivalent | Purpose |
|---|---|---|
| `Seek.WorkspaceManager` | `Chassis.LayoutManager` | GenServer managing layout state + PubSub |
| `Seek.WorkspaceLayout` | `Chassis.Layout` | Recursive tree: split, stack, slot |
| `SeekWeb.Components.Workspace` | `Chassis.Shell` | Recursive layout renderer |
| `SeekWeb.Components.Sidebar` | `Chassis.Sidebar` | Tree navigation panel |
| `SeekWeb.Components.DockPanel` | `Chassis.DockPanel` | Dockable panel |
| `tab_hook.js`, `drag_drop.js` | `Chassis.Hooks` | Client-side interaction |

## Bounded Domain

**Inside Chassis:**
- **Layout tree** — recursive structure: `split(direction, children)`, `stack(active, [ids])`, `slot(id)`
- **Operations** — split, dock, stack, reorder, close, focus
- **Rendering** — project the layout tree into nested DOM with tab bars, dock zones, drag targets
- **State** — persist and restore arrangements via the LayoutManager
- **Interaction** — drag-drop, tab selection, split creation (JS hooks)

**NOT inside Chassis:**
- Content inside slots (external — the consuming application fills slots)
- Sidebar tree data (Chassis renders the tree, the app provides the nodes)
- Business logic, data models, network connections
- Application-level concepts (agents, pipelines, orgs)

## Refreshed Vocabulary

| Old (Seek) | New (Chassis) | Why |
|---|---|---|
| Workspace | Composition | "Workspace" is antiquated desktop baggage |
| View | Slot | A slot is a position in the frame — content fills it |
| Tab group | Stack | Multiple slots sharing space, one visible |
| Split | Division | Space divided between children |
| Dock | Attach | Join a slot to another's edge |

## Module Structure

```
lib/chassis/
  layout.ex              # the tree: division, stack, slot
  layout_manager.ex      # GenServer: state + PubSub

lib/chassis_web/
  components/
    shell.ex             # recursive layout renderer
    tab_bar.ex           # stack navigation
    dock_zone.ex         # drop targets
    sidebar.ex           # tree nav panel
    activity_bar.ex      # icon rail (VS Code-style)
  hooks/
    drag_drop.js
    tab_hook.js
    sidebar_item.js
    col_drag.js

assets/css/
  chassis.css            # layout-only styles, CSS variables for theming
```

## Relationship to Other Projects

```
chassis (this project)          — layout shell framework
  ↑ used by
delivery surface (TBD name)     — agent dashboard application
  ↔ connects to
cognitive_mcp                   — MCP server (pipeline tools + semantic index)
  ↔ invokes
gemini CLI                      — agent execution
```

Chassis is a **dependency** of the delivery surface project — not the same project. Clean boundary: Chassis is the Lego baseplate, the delivery surface is the build.

## Open Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Chassis name | ✅ Resolved |
| 2 | Delivery surface project name | Open — Governor |
| 3 | Backend domain name (MCP client + agent lifecycle) | Open — Governor |
| 4 | Should Chassis be a Hex package or a path dependency? | Open — affects project structure |
