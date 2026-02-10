# Chassis

Content-blind layout shell for Phoenix LiveView.

Chassis provides a spatial arrangement framework — divisions, stacks, tabs, dock zones, and drag-drop — without knowing what fills the spaces it manages.

## Installation

Add `chassis` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chassis, "~> 0.1.0"}
  ]
end
```

## Setup

### 1. Add hooks to your `app.js`

```javascript
import { ChassisHooks } from "chassis/assets/js/hooks/chassis_hooks";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...ChassisHooks }
});
```

### 2. Implement the `SlotProvider` behaviour

```elixir
defmodule MyApp.SlotProvider do
  use Chassis.SlotProvider

  @impl true
  def render_content(:editor, assigns) do
    ~H"<div>Editor content here</div>"
  end

  @impl true
  def tab_label(:editor), do: "Editor"
end
```

### 3. Add the Shell to your LiveView

```elixir
defmodule MyAppWeb.WorkspaceLive do
  use MyAppWeb, :live_view
  alias Chassis.LayoutManager
  alias ChassisWeb.Components.Shell

  def mount(_params, _session, socket) do
    {:ok, _pid} = LayoutManager.start_link(name: :my_layout)
    :ok = LayoutManager.attach(:my_layout, :editor)

    socket =
      socket
      |> assign(:tree, LayoutManager.get_tree(:my_layout))
      |> assign(:weights, LayoutManager.get_weights(:my_layout))
      |> assign(:active_slot, :editor)

    {:ok, socket}
  end

  def render(assigns) do
    ~H\"\"\"
    <Shell.layout
      tree={@tree}
      provider={MyApp.SlotProvider}
      weights={@weights}
      active_slot={@active_slot}
    />
    \"\"\"
  end
end
```

### 4. Optional: Implement `PersistenceBackend`

```elixir
defmodule MyApp.LayoutStore do
  @behaviour Chassis.PersistenceBackend

  @impl true
  def save_layout(composition, data) do
    File.write("priv/layouts/#{composition}.bin", data)
  end

  @impl true
  def load_layout(composition) do
    case File.read("priv/layouts/#{composition}.bin") do
      {:ok, data} -> {:ok, data}
      {:error, :enoent} -> {:error, :not_found}
    end
  end
end
```

Then pass it when starting the LayoutManager:

```elixir
LayoutManager.start_link(name: :my_layout, persistence_backend: MyApp.LayoutStore)
```

## Concepts

| Term | Meaning |
|---|---|
| **Composition** | A complete layout arrangement |
| **Slot** | A position content fills |
| **Stack** | Slots sharing space, one visible (tabs) |
| **Division** | Space divided between children |
| **Attach** | Join a slot to the layout |

## Theming

Chassis provides CSS variables for all visual properties. Set them in your application CSS:

```css
:root {
  --chassis-bg: #1a1a2e;
  --chassis-border-color: #333;
  --chassis-tab-bg: transparent;
  --chassis-tab-active-bg: rgba(255, 255, 255, 0.1);
  --chassis-accent-color: #4a9eff;
}
```

## License

MIT
