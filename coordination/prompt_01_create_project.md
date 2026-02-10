# Prompt 1 — Create Chassis Project

## Role
Builder

## Context
You are creating a new Elixir project called **Chassis** — a layout shell framework for Phoenix LiveView. Chassis provides the structural skeleton for multi-pane, tabbed, splittable, dockable layouts rendered in a browser. It manages panes, not content.

**Read these first:**
- `C:\Users\alpha\source\chassis\coordination\memo_founding_chassis.md` — founding memo with identity, bounded domain, vocabulary, and module structure

**Reference implementation (port from, do not copy blindly):**
- `C:\Users\alpha\source\list-demo\demo_grid\lib\seek\workspace_manager.ex` → becomes `Chassis.LayoutManager`
- `C:\Users\alpha\source\list-demo\demo_grid\lib\seek\workspace_layout.ex` → becomes `Chassis.Layout`
- `C:\Users\alpha\source\list-demo\demo_grid\lib\seek_web\components\workspace.ex` → becomes `Chassis.Shell` (recursive renderer)
- `C:\Users\alpha\source\list-demo\demo_grid\lib\seek_web\components\sidebar.ex` → becomes `Chassis.Sidebar`
- `C:\Users\alpha\source\list-demo\demo_grid\lib\seek_web\components\dock_panel.ex` → becomes `Chassis.DockPanel`
- `C:\Users\alpha\source\list-demo\demo_grid\assets\js\hooks\` → JS hooks for drag-drop, tabs, sidebar interaction
- `C:\Users\alpha\source\list-demo\demo_grid\assets\css\app.css` → CSS layout styles (extract layout-only styles, use `--chassis-*` CSS variables)

## Instruction

1. Create a new Phoenix LiveView project at `C:\Users\alpha\source\chassis` using `mix phx.new chassis --no-ecto --no-mailer --no-dashboard`
2. Port the windowing primitives from the Seek reference implementation into Chassis using the **refreshed vocabulary** from the founding memo:
   - `Workspace` → **Composition**
   - `View` → **Slot**
   - `Tab group` → **Stack**
   - `Split` → **Division**
   - `Dock` → **Attach**
3. The module structure must match the founding memo exactly (`lib/chassis/`, `lib/chassis_web/`)
4. Create a minimal demo page at `localhost:4000` that renders a Chassis shell with three slots in a horizontal split, proving the layout engine works
5. Port the JS hooks (drag-drop, tab, sidebar) — these are the interaction layer
6. Extract layout-only CSS from Seek's `app.css` — use `--chassis-*` CSS variables for theming, no hardcoded colors

## Boundary
- Do NOT port any Ceek backend code (coordinator, event store, auth, federation, ingestion)
- Do NOT port the DataGrid, Terminal, or Properties components — those are Seek application content, not Chassis framework
- Do NOT port the Ribbon component — that is application chrome, not layout shell
- Do NOT add business logic, data models, or application concepts

## Completion Criteria
- `mix compile --warnings-as-errors` passes
- `mix phx.server` starts and renders the demo shell at `localhost:4000`
- The demo shows three slots in a horizontal split with tab bars
- Drag-drop between slots works (tab reordering)
- Layout state persists across page refresh via LayoutManager GenServer
