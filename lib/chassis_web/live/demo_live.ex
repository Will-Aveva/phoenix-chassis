defmodule ChassisWeb.DemoLive do
  @moduledoc """
  Demo LiveView — integration proof for Chassis.

  Shows a Chassis shell with 3 slots in a horizontal division.
  Implements `Chassis.SlotProvider` to provide content and tab labels.
  This demonstrates that Chassis works end-to-end without content awareness.
  """
  use ChassisWeb, :live_view
  use Chassis.SlotProvider

  alias Chassis.Layout
  alias Chassis.LayoutManager
  alias ChassisWeb.Components.Shell

  # ---------------------------------------------------------------------------
  # SlotProvider callbacks (INV-9.1)
  # ---------------------------------------------------------------------------

  @impl Chassis.SlotProvider
  def render_content(slot_id, assigns) do
    assigns = Map.put(assigns, :slot_id, slot_id)

    ~H"""
    <div style="padding: 16px; flex: 1;">
      <h3 style="margin: 0 0 8px;">{@slot_id}</h3>
      
      <p style="opacity: 0.6;">This is the <strong>{@slot_id}</strong> slot.</p>
      
      <p style="opacity: 0.4; font-size: 12px;">
        Content rendered by the consuming application via SlotProvider.
      </p>
    </div>
    """
  end

  @impl Chassis.SlotProvider
  def tab_label(:editor), do: "Editor"
  def tab_label(:preview), do: "Preview"
  def tab_label(:terminal), do: "Terminal"
  def tab_label(:notes), do: "📝 Notes"
  def tab_label(:debugger), do: "🔍 Debugger"
  def tab_label(:settings), do: "⚙️ Settings"
  def tab_label(slot_id), do: to_string(slot_id)

  # tab_icon/1 and closable?/1 use defaults from __using__

  # ---------------------------------------------------------------------------
  # LiveView lifecycle
  # ---------------------------------------------------------------------------

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Start a dedicated LayoutManager for this demo session
    name = :"layout_#{inspect(self())}"
    {:ok, _pid} = LayoutManager.start_link(name: name)

    # Create :default composition — 3 slots in a horizontal division
    :ok = LayoutManager.attach(name, :editor)
    :ok = LayoutManager.divide(name, :editor, :preview, :horizontal)
    :ok = LayoutManager.divide(name, :preview, :terminal, :vertical)

    # Create :minimal composition — single editor slot
    :ok = LayoutManager.attach(name, :editor, :minimal)

    tree = LayoutManager.get_tree(name)
    weights = LayoutManager.get_weights(name)

    socket =
      socket
      |> assign(:layout_manager, name)
      |> assign(:current_composition, :default)
      |> assign(:tree, tree)
      |> assign(:weights, weights)
      |> assign(:active_slot, :editor)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="chassis-demo">
      <div class="chassis-sidebar">
        <div class="chassis-sidebar-title">Compositions</div>
        
        <button
          phx-click="chassis:switch_composition"
          phx-value-composition="default"
          class={"chassis-comp-btn #{if @current_composition == :default, do: "active"}"}
        >
          Default
        </button>
        <button
          phx-click="chassis:switch_composition"
          phx-value-composition="minimal"
          class={"chassis-comp-btn #{if @current_composition == :minimal, do: "active"}"}
        >
          Minimal
        </button>
        <div class="chassis-sidebar-title" style="margin-top: 12px;">Available Panels</div>
        
        <div
          id="sidebar-notes"
          phx-hook="ChassisSidebarItem"
          data-slot-id="notes"
          class="chassis-sidebar-item"
        >
          📝 Notes
        </div>
        
        <div
          id="sidebar-debugger"
          phx-hook="ChassisSidebarItem"
          data-slot-id="debugger"
          class="chassis-sidebar-item"
        >
          🔍 Debugger
        </div>
        
        <div
          id="sidebar-settings"
          phx-hook="ChassisSidebarItem"
          data-slot-id="settings"
          class="chassis-sidebar-item"
        >
          ⚙️ Settings
        </div>
      </div>
      
      <Shell.layout
        tree={@tree}
        provider={ChassisWeb.DemoLive}
        weights={@weights}
        active_slot={@active_slot}
      />
    </div>

    <style>
      .chassis-demo {
        width: 100vw;
        height: 100vh;
        overflow: hidden;
        display: flex;
      }
      .chassis-sidebar {
        width: 180px;
        min-width: 180px;
        display: flex;
        flex-direction: column;
        gap: 4px;
        padding: 8px;
        border-right: 1px solid var(--chassis-border-color, #333);
        background: var(--chassis-sidebar-bg, #1a1a2e);
      }
      .chassis-sidebar-title {
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        opacity: 0.5;
        margin-bottom: 4px;
      }
      .chassis-sidebar-item {
        padding: 6px 8px;
        border-radius: 4px;
        cursor: grab;
        font-size: 13px;
        user-select: none;
      }
      .chassis-sidebar-item:hover {
        background: var(--chassis-tab-hover-bg, rgba(255,255,255,0.05));
      }
      .chassis-sidebar-item.dragging {
        opacity: 0.4;
      }
      .chassis-comp-btn {
        padding: 6px 8px;
        border-radius: 4px;
        border: 1px solid var(--chassis-border-color, #333);
        background: transparent;
        color: inherit;
        cursor: pointer;
        font-size: 13px;
        text-align: left;
      }
      .chassis-comp-btn:hover {
        background: var(--chassis-tab-hover-bg, rgba(255,255,255,0.05));
      }
      .chassis-comp-btn.active {
        background: var(--chassis-tab-active-bg, rgba(255,255,255,0.1));
        border-color: var(--chassis-accent-color, #4a9eff);
      }
    </style>
    """
  end

  # Handle Chassis spatial events
  @impl Phoenix.LiveView
  def handle_event("chassis:switch_composition", %{"composition" => comp_str}, socket) do
    name = socket.assigns.layout_manager
    composition = String.to_existing_atom(comp_str)
    tree = LayoutManager.get_tree(name, composition)
    weights = LayoutManager.get_weights(name, composition)

    socket =
      socket
      |> assign(:current_composition, composition)
      |> assign(:tree, tree)
      |> assign(:weights, weights)
      |> assign(:active_slot, nil)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("chassis:close_slot", %{"slot-id" => slot_id}, socket) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id)
    :ok = LayoutManager.close(name, slot_id, comp)
    tree = LayoutManager.get_tree(name, comp)
    {:noreply, assign(socket, :tree, tree)}
  end

  @impl Phoenix.LiveView
  def handle_event("chassis:focus_slot", %{"slot_id" => slot_id}, socket) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id)
    :ok = LayoutManager.focus(name, slot_id, comp)
    tree = LayoutManager.get_tree(name, comp)
    {:noreply, socket |> assign(:tree, tree) |> assign(:active_slot, slot_id)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "chassis:reorder_slot",
        %{"target_id" => target, "dragged_id" => dragged},
        socket
      ) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    target = String.to_existing_atom(target)
    dragged = String.to_existing_atom(dragged)
    :ok = LayoutManager.reorder(name, target, dragged, comp)
    tree = LayoutManager.get_tree(name, comp)
    {:noreply, assign(socket, :tree, tree)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "chassis:dock_slot",
        %{"target_id" => target, "dragged_id" => dragged},
        socket
      ) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    target = String.to_existing_atom(target)
    dragged = String.to_atom(dragged)
    existing_slots = LayoutManager.list_slots(name, comp)

    if dragged in existing_slots do
      # Move: close from current position, add to target stack
      :ok = LayoutManager.close(name, dragged, comp)
      :ok = LayoutManager.add_to_stack(name, target, dragged, comp)
    else
      # Create: attach new slot, then add to target stack
      :ok = LayoutManager.attach(name, dragged, comp)
      :ok = LayoutManager.close(name, dragged, comp)
      :ok = LayoutManager.add_to_stack(name, target, dragged, comp)
    end

    tree = LayoutManager.get_tree(name, comp)
    {:noreply, assign(socket, :tree, tree)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "chassis:split_slot",
        %{"target_id" => target, "dragged_id" => dragged, "direction" => dir_str},
        socket
      ) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    target = String.to_existing_atom(target)
    dragged = String.to_atom(dragged)
    existing_slots = LayoutManager.list_slots(name, comp)

    {direction, order} =
      case dir_str do
        "up" -> {:vertical, :before}
        "down" -> {:vertical, :after}
        "left" -> {:horizontal, :before}
        "right" -> {:horizontal, :after}
        _ -> {:horizontal, :after}
      end

    # Remove from current position if already in tree
    if dragged in existing_slots do
      :ok = LayoutManager.close(name, dragged, comp)
    end

    :ok = LayoutManager.divide(name, target, dragged, direction, order: order, composition: comp)
    tree = LayoutManager.get_tree(name, comp)
    {:noreply, assign(socket, :tree, tree)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "chassis:resize_division",
        %{"slot_id" => slot_id_str, "ratio" => ratio},
        socket
      ) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id_str)
    :ok = LayoutManager.resize(name, slot_id, ratio, comp)
    weights = LayoutManager.get_weights(name, comp)
    {:noreply, assign(socket, :weights, weights)}
  end

  @impl Phoenix.LiveView
  def handle_event("chassis:focus_next", %{"slot_id" => slot_id_str}, socket) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id_str)
    tree = LayoutManager.get_tree(name, comp)

    case Layout.next_in_stack(tree, slot_id) do
      nil ->
        {:noreply, socket}

      next_id ->
        :ok = LayoutManager.focus(name, next_id, comp)
        tree = LayoutManager.get_tree(name, comp)
        {:noreply, socket |> assign(:tree, tree) |> assign(:active_slot, next_id)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("chassis:focus_prev", %{"slot_id" => slot_id_str}, socket) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id_str)
    tree = LayoutManager.get_tree(name, comp)

    case Layout.prev_in_stack(tree, slot_id) do
      nil ->
        {:noreply, socket}

      prev_id ->
        :ok = LayoutManager.focus(name, prev_id, comp)
        tree = LayoutManager.get_tree(name, comp)
        {:noreply, socket |> assign(:tree, tree) |> assign(:active_slot, prev_id)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event(
        "chassis:focus_direction",
        %{"slot_id" => slot_id_str, "direction" => dir_str},
        socket
      ) do
    name = socket.assigns.layout_manager
    comp = socket.assigns.current_composition
    slot_id = String.to_existing_atom(slot_id_str)
    direction = String.to_existing_atom(dir_str)
    tree = LayoutManager.get_tree(name, comp)

    case Layout.adjacent(tree, slot_id, direction) do
      nil ->
        {:noreply, socket}

      adj_id ->
        :ok = LayoutManager.focus(name, adj_id, comp)
        tree = LayoutManager.get_tree(name, comp)
        {:noreply, socket |> assign(:tree, tree) |> assign(:active_slot, adj_id)}
    end
  end
end
