# Project

## Identity

Chassis is a layout shell framework for Phoenix LiveView. It provides the structural skeleton for multi-pane, tabbed, splittable, dockable layouts rendered in a browser. Chassis manages panes, not content — consuming applications fill the slots.

Chassis was extracted from the windowing system built inside the Seek project (`list-demo/demo_grid`). The core primitives (layout tree, recursive renderer, drag-drop, tab management) already exist and are production-tested.

## Non-Goals

- Not an application — Chassis is a framework. It does not know what's inside its slots.
- Not a content manager — slot content is the consuming application's sole responsibility.
- Not a design system — Chassis provides CSS variables for theming, not visual opinion.
- Not a business logic layer — application concepts (agents, pipelines, orgs) do not belong in Chassis.

## Current Phase

Pre-build. Governance scaffolding complete. Vision (prompt_02) and constitution (prompt_03) pending. Code port from Seek not yet started.

## Repositories

| Repository | Contains |
|---|---|
| `chassis` (this repo) | Layout shell framework — layout tree, recursive renderer, tab bars, dock zones, drag-drop hooks, CSS variables |
| `list-demo` | Seek application — source of the windowing primitives being ported to Chassis |
| `cognitive_mcp` | MCP server — pipeline governance tools, semantic knowledge index |
