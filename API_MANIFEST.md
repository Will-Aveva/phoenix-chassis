# Chassis API Manifest

*Per INV-1.2a — This document defines the public surface of the Chassis framework.*

---

## Elixir Modules

### `Chassis.Layout`

Pure functional core for layout trees.

| Function | Signature | Description |
|---|---|---|
| `slot/1` | `(slot_id) → {:slot, id}` | Create a slot (leaf node) |
| `stack/2` | `(active_id, [slot_id]) → {:stack, active, ids}` | Create a stack (tabbed group) |
| `division/2` | `(direction, [tree_node]) → tree_node` | Create a division (spatial split) |
| `attach/2` | `(tree_node, slot_id) → tree_node` | Attach a slot to the tree |
| `add_to_stack/3` | `(tree_node, target_id, new_id) → tree_node` | Add slot to target's stack |
| `divide/5` | `(tree_node, target_id, new_id, direction, order) → tree_node` | Split a slot with a new slot |
| `close/2` | `(tree_node, slot_id) → tree_node` | Remove a slot from the tree |
| `focus/2` | `(tree_node, slot_id) → tree_node` | Set active tab in stack |
| `reorder/3` | `(tree_node, target_id, dragged_id) → tree_node` | Move slot to target's position |
| `list_slots/1` | `(tree_node) → [slot_id]` | List all slot IDs |

**Types:**
- `slot_id` — `atom() | String.t()`
- `direction` — `:horizontal | :vertical`
- `tree_node` — `{:slot, id} | {:stack, active, ids} | {:division, dir, children} | nil`

---

### `Chassis.LayoutManager`

GenServer wrapping Layout operations with PubSub broadcasting.

| Function | Signature | Description |
|---|---|---|
| `start_link/1` | `(opts) → {:ok, pid}` | Start the manager (opts: `name`, `persistence_backend`) |
| `get_tree/2` | `(server, composition) → tree_node` | Get current tree |
| `attach/3` | `(server, slot_id, composition) → :ok` | Attach a slot |
| `add_to_stack/4` | `(server, target, new_id, composition) → :ok` | Add to stack |
| `divide/5` | `(server, target, new_id, direction, opts) → :ok` | Divide a slot |
| `close/3` | `(server, slot_id, composition) → :ok | {:error, atom}` | Close a slot |
| `focus/3` | `(server, slot_id, composition) → :ok | {:error, atom}` | Focus a slot |
| `reorder/4` | `(server, target, dragged, composition) → :ok | {:error, atom}` | Reorder |
| `list_slots/2` | `(server, composition) → [slot_id]` | List slots |

**PubSub topic:** `"chassis:layout"`
**Broadcast payload:** `{:layout_changed, operation, composition, tree}`

---

### `Chassis.Persistence`

Tree serialization (private format).

| Function | Signature | Description |
|---|---|---|
| `save/1` | `(tree_node) → binary` | Serialize tree |
| `restore/1` | `(binary) → {:ok, tree_node} | {:error, atom}` | Deserialize tree |

---

## Phoenix Components

### `ChassisWeb.Components.Shell`

| Component | Required Assigns | Description |
|---|---|---|
| `layout/1` | `tree`, `provider` | Render the full shell from a layout tree |

**`provider`**: A module implementing `Chassis.SlotProvider` — the behaviour-based contract between Chassis and your application (INV-9.3).

---

## Behaviours

### `Chassis.SlotProvider`

Contract for slot rendering and tab chrome. Use `use Chassis.SlotProvider` for optional callback defaults.

| Callback | Signature | Required? |
|---|---|---|
| `render_content/2` | `(slot_id, assigns) → HEEx` | Yes |
| `tab_label/1` | `(slot_id) → String.t()` | Yes |
| `tab_icon/1` | `(slot_id) → String.t() \| nil` | No (default: `nil`) |
| `closable?/1` | `(slot_id) → boolean()` | No (default: `true`) |

### `Chassis.PersistenceBackend`

Contract for layout state storage. Operates on opaque binaries.

| Callback | Signature | Description |
|---|---|---|
| `save_layout/2` | `(composition, binary) → :ok \| {:error, term}` | Persist serialized tree |
| `load_layout/1` | `(composition) → {:ok, binary} \| {:error, term}` | Retrieve serialized tree |

### `ChassisWeb.Components.Sidebar`

| Component | Slots | Description |
|---|---|---|
| `sidebar/1` | `activity_bar`, `inner_block` | Activity bar + panel structure |

### `ChassisWeb.Components.DockPanel`

| Component | Attrs | Description |
|---|---|---|
| `dock_panel/1` | `id`, `side`, `title`, `collapsed`, `width`, `height`, `on_toggle` | Collapsible side/bottom panel |

---

## CSS Custom Properties

All visual properties must be set by the adopter theme. Chassis has zero default aesthetic values.

### Structural (`--chassis-*`)

| Property | Default | Description |
|---|---|---|
| `--chassis-tab-height` | `2rem` | Tab bar height |
| `--chassis-divider-size` | `4px` | Divider thickness |
| `--chassis-dock-opacity` | — | Dock zone highlight opacity |

### Visual (`--chassis-*`)

| Property | Description |
|---|---|
| `--chassis-shell-bg` | Shell background |
| `--chassis-slot-bg` | Slot/panel background |
| `--chassis-slot-border` | Slot border color |
| `--chassis-tab-bg` | Tab bar background |
| `--chassis-tab-text` | Inactive tab text color |
| `--chassis-tab-active-bg` | Active tab background |
| `--chassis-tab-active-text` | Active tab text color |
| `--chassis-tab-gap` | Gap between tab elements |
| `--chassis-tab-padding` | Tab horizontal padding |
| `--chassis-dock-highlight` | Dock zone highlight color |
| `--chassis-divider-bg` | Divider background |
| `--chassis-divider-hover-bg` | Divider hover highlight |
| `--chassis-tab-font-size` | Tab label font size (required — no fallback) |
| `--chassis-tab-close-radius` | Close button border radius (required — no fallback) |
| `--chassis-tab-close-size` | Close button icon size (required — no fallback) |
| `--chassis-transition-speed` | Opacity/reveal transition duration (optional — fallback: `0.15s`) |
| `--chassis-tab-close-hover-opacity` | Close button hover opacity (optional — fallback: `0.6`) |

---

## JavaScript Hooks

Import and register with your LiveSocket:

```javascript
import { ChassisHooks } from "chassis/assets/js/hooks/index";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...ChassisHooks }
});
```

| Hook | HTML Attribute | Description |
|---|---|---|
| `ChassisTab` | `phx-hook="ChassisTab"` | Tab drag, click to focus, close |
| `ChassisDragDrop` | `phx-hook="ChassisDragDrop"` | Dock zone detection, split/attach drops |
| `ChassisSidebarItem` | `phx-hook="ChassisSidebarItem"` | Sidebar drag source |

---

## LiveView Events

Events pushed by hooks — handle in your LiveView:

| Event | Payload | Description |
|---|---|---|
| `chassis:close_slot` | `%{"slot-id" => id}` | Close a slot |
| `chassis:focus_slot` | `%{"slot_id" => id}` | Focus a slot |
| `chassis:reorder_slot` | `%{"target_id" => id, "dragged_id" => id}` | Reorder tabs |
| `chassis:dock_slot` | `%{"target_id" => id, "dragged_id" => id}` | Add to stack |
| `chassis:split_slot` | `%{"target_id" => id, "dragged_id" => id, "direction" => dir}` | Split at edge |

---

## CSS Classes (Internal)

The following classes are generated by Shell and styled by `chassis.css`. Adopters should not reference these directly.

`chassis-shell`, `chassis-division`, `chassis-stack`, `chassis-tab-bar`, `chassis-tab`, `chassis-tab-label`, `chassis-tab-close`, `chassis-tab-spacer`, `chassis-slot-content`, `chassis-dock-overlay`, `chassis-dock-zone`, `chassis-divider`, `chassis-empty`, `chassis-sidebar`, `chassis-activity-bar`, `chassis-sidebar-panel`, `chassis-dock-panel`, `chassis-dock-header`, `chassis-dock-content`
