defmodule ChassisWeb.Components.Shell do
  @moduledoc """
  Recursive layout renderer for Chassis.

  Walks the layout tree and renders each node:
  - `division` → flex container with direction
  - `stack` → tab bar + active slot content
  - `slot` → container invoking the SlotProvider's render callback

  The Shell renders slot *containers* only. Content is provided by the consuming
  application through a `Chassis.SlotProvider` module that receives only the
  slot ID (INV-1.1d, INV-8.2, INV-9.2).
  """
  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Main entry point
  # ---------------------------------------------------------------------------

  @doc """
  Render a Chassis layout shell.

  ## Required assigns
  - `tree` — the layout tree from `Chassis.LayoutManager`
  - `provider` — a module implementing `Chassis.SlotProvider`

  ## Example
      <ChassisWeb.Components.Shell.layout
        tree={@tree}
        provider={MyApp.SlotProvider}
      />
  """
  attr :tree, :any, required: true
  attr :provider, :atom, required: true
  attr :weights, :map, default: %{}
  attr :active_slot, :any, default: nil
  attr :id, :string, default: "chassis-shell"
  attr :provider_assigns, :any, default: %{}

  def layout(assigns) do
    ~H"""
    <div
      class="chassis-shell"
      id={@id}
      phx-hook="ChassisKeyboard"
      data-active-slot={@active_slot}
    >
      <.tree_node node={@tree} provider={@provider} weights={@weights} provider_assigns={@provider_assigns} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Recursive tree walk (INV-3.2)
  # ---------------------------------------------------------------------------

  attr :node, :any, required: true
  attr :provider, :atom, required: true
  attr :weights, :map, default: %{}
  attr :provider_assigns, :any, default: %{}

  def tree_node(%{node: nil} = assigns) do
    ~H"""
    <div class="chassis-empty">No layout</div>
    """
  end

  # Bare slot → promote to stack for consistent tab bar rendering
  def tree_node(%{node: {:slot, id}} = assigns) do
    assigns = assign(assigns, :node, {:stack, id, [id]})

    ~H"""
    <.tree_node node={@node} provider={@provider} weights={@weights} provider_assigns={@provider_assigns} />
    """
  end

  # Stack → tab bar + active slot content
  def tree_node(%{node: {:stack, active_id, slot_ids}} = assigns) do
    assigns =
      assigns
      |> assign(:active_id, active_id)
      |> assign(:slot_ids, slot_ids)

    ~H"""
    <div class="chassis-stack" data-active-id={@active_id}>
      <div class="chassis-tab-bar">
        <%= for slot_id <- @slot_ids do %>
          <div
            class={"chassis-tab #{if slot_id == @active_id, do: "active", else: "inactive"}"}
            id={"chassis-tab-#{slot_id}"}
            draggable="true"
            data-slot-id={slot_id}
            data-drop-type="tab"
            phx-hook="ChassisTab"
          >
            <%= if icon = @provider.tab_icon(slot_id) do %>
              <span class="chassis-tab-icon">{icon}</span>
            <% end %>
             <span class="chassis-tab-label">{@provider.tab_label(slot_id, @provider_assigns)}</span>
            <%= if @provider.closable?(slot_id) do %>
              <button
                class="chassis-tab-close"
                phx-click="chassis:close_slot"
                phx-value-slot-id={slot_id}
              >
                ×
              </button>
            <% end %>
          </div>
        <% end %>
        
        <div class="chassis-tab-spacer"></div>
      </div>
      <div class="chassis-content-wrapper" style="position: relative; flex: 1; display: flex; flex-direction: column; overflow: hidden; min-height: 0; min-width: 0; height: 100%; width: 100%;">
        <.dock_overlay slot_id={@active_id} />
        <div class="chassis-slot-content">
          {@provider.render_content(@active_id, Map.put(@provider_assigns, :slot_id, @active_id))}
        </div>
      </div>
    </div>
    """
  end

  # Division → flex container with direction + dividers
  def tree_node(%{node: {:division, direction, children}} = assigns) do
    flex_dir = if direction == :horizontal, do: "row", else: "column"
    dir_str = if direction == :horizontal, do: "horizontal", else: "vertical"

    # Interleave children with dividers and apply weights
    indexed_children = Enum.with_index(children)

    assigns =
      assigns
      |> assign(:children, children)
      |> assign(:indexed_children, indexed_children)
      |> assign(:flex_dir, flex_dir)
      |> assign(:dir_str, dir_str)
      |> assign(:child_count, length(children))

    ~H"""
    <div class="chassis-division" style={"flex-direction: #{@flex_dir};"}>
      <%= for {child, idx} <- @indexed_children do %>
        <div style={child_flex_style(child, @weights)}>
          <.tree_node node={child} provider={@provider} weights={@weights} provider_assigns={@provider_assigns} />
        </div>
        
        <%= if idx < @child_count - 1 do %>
          <div
            class="chassis-divider"
            id={divider_id(child, Enum.at(@children, idx + 1))}
            data-slot-id={first_slot_id(child)}
            data-next-slot-id={first_slot_id(Enum.at(@children, idx + 1))}
            data-direction={@dir_str}
            phx-hook="ChassisResize"
          >
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # KNOWN BUG: this key aliases across nesting levels, so one weight can size two different shares.
  #
  # `first_slot_id/1` walks to the leftmost slot, so a division's child and that child's own first
  # child answer the same slot id. Dragging the divider between `editor` and a division
  # `[preview, terminal]` writes a weight for `preview`; the nested `preview | terminal` divider then
  # reads the same weight, and a split the user never touched resizes with it. Confirmed with a
  # browser drag against the demo, and present in `Will-Aveva/demo_grid` by the same construction.
  #
  # Unfixed here because the fix is a decision, not a typo: the key has to name a *subtree* rather
  # than a slot, and every candidate (the subtree's first+last slot, a path, a division-local index)
  # trades uniqueness against stability when the subtree's contents change.
  defp child_flex_style(child, weights) do
    slot_id = first_slot_id(child)
    weight = Map.get(weights, slot_id, 1)
    "flex: #{weight}; min-width: 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden; height: 100%;"
  end

  defp first_slot_id({:slot, id}), do: id
  defp first_slot_id({:stack, _active, [first | _]}), do: first
  defp first_slot_id({:division, _dir, [first | _]}), do: first_slot_id(first)
  defp first_slot_id(_), do: "unknown"

  # A divider names BOTH of the subtrees it separates — in its id, and in its data attributes.
  #
  # `data-next-slot-id` is what lets the server redistribute the pair's own share instead of writing
  # one weight and leaving the sibling at its default: the element carries the identity, so the
  # server never infers which children the divider sat between from DOM position, which a patch is
  # free to change.
  #
  # The id needs both for a different reason.
  #
  # `first_slot_id/1` walks to the leftmost slot, so a division and its own first child answer the
  # same slot — and a division nested as a non-last child then produced the same
  # `chassis-divider-<slot>` id at two levels of the tree. LiveView patches by id: the resize hook
  # mounts on whichever it finds first, and dragging the other divider does nothing. The pair is
  # unique because the two subtrees a divider sits between never share a leftmost slot (a slot
  # appears in exactly one place).
  defp divider_id(child, next_child) do
    "chassis-divider-#{first_slot_id(child)}-#{first_slot_id(next_child)}"
  end

  # ---------------------------------------------------------------------------
  # Dock overlay (attach zones)
  # ---------------------------------------------------------------------------

  attr :slot_id, :any, required: true

  def dock_overlay(assigns) do
    ~H"""
    <div class="chassis-dock-overlay">
      <div
        class="chassis-dock-zone top"
        id={"chassis-dock-#{@slot_id}-top"}
        data-drop-type="split-zone"
        data-direction="up"
        data-slot-id={@slot_id}
        phx-hook="ChassisDragDrop"
      >
      </div>
      
      <div
        class="chassis-dock-zone bottom"
        id={"chassis-dock-#{@slot_id}-bottom"}
        data-drop-type="split-zone"
        data-direction="down"
        data-slot-id={@slot_id}
        phx-hook="ChassisDragDrop"
      >
      </div>
      
      <div
        class="chassis-dock-zone left"
        id={"chassis-dock-#{@slot_id}-left"}
        data-drop-type="split-zone"
        data-direction="left"
        data-slot-id={@slot_id}
        phx-hook="ChassisDragDrop"
      >
      </div>
      
      <div
        class="chassis-dock-zone right"
        id={"chassis-dock-#{@slot_id}-right"}
        data-drop-type="split-zone"
        data-direction="right"
        data-slot-id={@slot_id}
        phx-hook="ChassisDragDrop"
      >
      </div>
      
      <div
        class="chassis-dock-zone center"
        id={"chassis-dock-#{@slot_id}-center"}
        data-drop-type="dock-zone"
        data-slot-id={@slot_id}
        phx-hook="ChassisDragDrop"
      >
      </div>
    </div>
    """
  end
end
