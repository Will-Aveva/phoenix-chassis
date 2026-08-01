defmodule Chassis.LayoutManager do
  @moduledoc """
  GenServer managing layout tree state.

  Wraps `Chassis.Layout` operations and broadcasts spatial events via PubSub.
  Stores only the tree structure and slot IDs — no content awareness (INV-1.1b).
  Supports multiple named compositions (INV-2.2).
  """
  use GenServer

  alias Chassis.Layout
  alias Chassis.Persistence
  alias Phoenix.PubSub

  @topic "chassis:layout"

  # ---------------------------------------------------------------------------
  # Client API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Get the layout tree for a composition."
  def get_tree(server \\ __MODULE__, composition \\ :default) do
    GenServer.call(server, {:get_tree, composition})
  end

  @doc "Attach a slot to the tree."
  def attach(server \\ __MODULE__, slot_id, composition \\ :default) do
    GenServer.call(server, {:attach, slot_id, composition})
  end

  @doc "Add a slot to the stack containing the target."
  def add_to_stack(server \\ __MODULE__, target_id, new_id, composition \\ :default) do
    GenServer.call(server, {:add_to_stack, target_id, new_id, composition})
  end

  @doc "Divide a slot with a new slot."
  def divide(server \\ __MODULE__, target_id, new_id, direction, opts \\ []) do
    composition = Keyword.get(opts, :composition, :default)
    order = Keyword.get(opts, :order, :after)
    GenServer.call(server, {:divide, target_id, new_id, direction, order, composition})
  end

  @doc "Close a slot."
  def close(server \\ __MODULE__, slot_id, composition \\ :default) do
    GenServer.call(server, {:close, slot_id, composition})
  end

  @doc "Focus a slot (set as active tab)."
  def focus(server \\ __MODULE__, slot_id, composition \\ :default) do
    GenServer.call(server, {:focus, slot_id, composition})
  end

  @doc "Reorder: move dragged slot to target's position."
  def reorder(server \\ __MODULE__, target_id, dragged_id, composition \\ :default) do
    GenServer.call(server, {:reorder, target_id, dragged_id, composition})
  end

  @doc "List all slot IDs."
  def list_slots(server \\ __MODULE__, composition \\ :default) do
    GenServer.call(server, {:list_slots, composition})
  end

  @doc "Set the flex weight for a slot within a division."
  def resize(server \\ __MODULE__, slot_id, weight, composition \\ :default) do
    GenServer.call(server, {:resize, slot_id, weight, composition})
  end

  @doc "Set the flex weight for two slots simultaneously (used when resizing division)."
  def resize_pair(server \\ __MODULE__, slot_id, next_slot_id, ratio, composition \\ :default) do
    GenServer.call(server, {:resize_pair, slot_id, next_slot_id, ratio, composition})
  end

  @doc "Get the weights map for a composition."
  def get_weights(server \\ __MODULE__, composition \\ :default) do
    GenServer.call(server, {:get_weights, composition})
  end

  # ---------------------------------------------------------------------------
  # Server callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    backend = Keyword.get(opts, :persistence_backend)

    compositions =
      if backend do
        load_from_backend(backend, :default)
      else
        %{default: nil}
      end

    weights =
      if backend && function_exported?(backend, :load_weights, 1) do
        load_weights_from_backend(backend, :default)
      else
        %{}
      end

    state = %{
      compositions: compositions,
      weights: weights,
      persistence_backend: backend
    }

    {:ok, state}
  end

  @impl true
  def terminate(_reason, %{persistence_backend: nil} = _state), do: :ok

  def terminate(_reason, %{persistence_backend: backend, compositions: compositions} = state) do
    Enum.each(compositions, fn {composition, tree} ->
      if tree do
        data = Persistence.save(tree)
        backend.save_layout(composition, data)
      end
    end)

    if function_exported?(backend, :save_weights, 2) do
      Enum.each(compositions, fn {composition, _tree} ->
        comp_weights =
          state.weights
          |> Enum.filter(fn {{comp, _slot_id}, _w} -> comp == composition end)
          |> Enum.into(%{})

        if map_size(comp_weights) > 0 do
          data = Persistence.save_weights(comp_weights)
          backend.save_weights(composition, data)
        end
      end)
    end

    :ok
  end

  def terminate(_reason, _state), do: :ok

  @impl true
  def handle_call({:get_tree, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])
    {:reply, tree, state}
  end

  @impl true
  def handle_call({:attach, slot_id, composition}, _from, state) do
    state = ensure_composition(state, composition)
    tree = get_in(state, [:compositions, composition])
    new_tree = Layout.attach(tree, slot_id)
    state = put_in(state, [:compositions, composition], new_tree)
    broadcast(:attach, composition, new_tree)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:add_to_stack, target_id, new_id, composition}, _from, state) do
    state = ensure_composition(state, composition)
    tree = get_in(state, [:compositions, composition])
    new_tree = Layout.add_to_stack(tree, target_id, new_id)
    state = put_in(state, [:compositions, composition], new_tree)
    broadcast(:add_to_stack, composition, new_tree)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:divide, target_id, new_id, direction, order, composition}, _from, state) do
    state = ensure_composition(state, composition)
    tree = get_in(state, [:compositions, composition])
    new_tree = Layout.divide(tree, target_id, new_id, direction, order)
    state = put_in(state, [:compositions, composition], new_tree)
    broadcast(:divide, composition, new_tree)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:close, slot_id, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])

    if tree do
      new_tree = Layout.close(tree, slot_id)
      state = put_in(state, [:compositions, composition], new_tree)
      broadcast(:close, composition, new_tree)
      {:reply, :ok, state}
    else
      {:reply, {:error, :no_composition}, state}
    end
  end

  @impl true
  def handle_call({:focus, slot_id, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])

    if tree do
      new_tree = Layout.focus(tree, slot_id)
      state = put_in(state, [:compositions, composition], new_tree)
      broadcast(:focus, composition, new_tree)
      {:reply, :ok, state}
    else
      {:reply, {:error, :no_composition}, state}
    end
  end

  @impl true
  def handle_call({:reorder, target_id, dragged_id, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])

    if tree do
      new_tree = Layout.reorder(tree, target_id, dragged_id)
      state = put_in(state, [:compositions, composition], new_tree)
      broadcast(:reorder, composition, new_tree)
      {:reply, :ok, state}
    else
      {:reply, {:error, :no_composition}, state}
    end
  end

  @impl true
  def handle_call({:list_slots, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])
    slots = if tree, do: Layout.list_slots(tree), else: []
    {:reply, slots, state}
  end

  # Weights are keyed by `{composition, Layout.weight_key(child)}` — the child subtree's two ends,
  # not one slot id. A slot id alone names a child and every ancestor above it on the same edge, so
  # one weight sized two different shares.
  @impl true
  def handle_call({:resize, slot_id, weight, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])

    case Layout.container_key(tree, slot_id) do
      nil ->
        {:reply, {:error, :no_such_slot}, state}

      container_key ->
        weights = Map.put(state.weights, {composition, container_key}, weight)
        state = %{state | weights: weights}
        broadcast(:resize, composition, tree)
        {:reply, :ok, state}
    end
  end

  # Both sides of a divider are written together, and their COMBINED weight is preserved.
  #
  # This used to write `%{first => ratio, second => 1.0 - ratio}` while the Shell defaults every
  # other child of the division to `1`. In a division with more than two children that is not the
  # arrangement the user dragged: at 40/60 the two dragged children render `0.4 : 0.6 : 1`, so both
  # of them shrink against a child nobody touched. Splitting the pair's own share leaves every
  # other sibling where it was, and reduces to the same numbers when the division has two children.
  #
  # The ratio is clamped rather than trusted: it arrives from a pointer drag, and a 0 or a 1 would
  # collapse a child to nothing, leaving no divider to grab and no way back without a reset.
  #
  # Correction contributed back from `Will-Aveva/demo_grid`, the shell Chassis was extracted from,
  # where this was fixed on the way in.
  @impl true
  def handle_call({:resize_pair, slot_id, next_slot_id, ratio, composition}, _from, state) do
    tree = get_in(state, [:compositions, composition])

    case Layout.divider_keys(tree, slot_id, next_slot_id) do
      nil ->
        # No division has those two as consecutive children: the divider is gone, or was never
        # there. Nothing to redistribute between.
        {:reply, {:error, :no_such_divider}, state}

      {left, right} ->
        ratio = clamp_ratio(ratio)
        key1 = {composition, left}
        key2 = {composition, right}

        combined = Map.get(state.weights, key1, 1.0) + Map.get(state.weights, key2, 1.0)

        weights =
          Map.merge(state.weights, %{key1 => combined * ratio, key2 => combined * (1.0 - ratio)})

        state = %{state | weights: weights}
        broadcast(:resize, composition, tree)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:get_weights, composition}, _from, state) do
    # Filter weights for this composition
    comp_weights =
      state.weights
      |> Enum.filter(fn {{comp, _slot_id}, _w} -> comp == composition end)
      |> Enum.map(fn {{_comp, slot_id}, w} -> {slot_id, w} end)
      |> Map.new()

    {:reply, comp_weights, state}
  end

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  # A child may never be dragged to nothing: at the extremes there is no divider left to grab, so
  # the arrangement is unrecoverable without discarding the composition. A client is not the
  # authority on that bound.
  @min_ratio 0.05
  @max_ratio 0.95

  defp clamp_ratio(ratio) when is_number(ratio) do
    ratio |> max(@min_ratio) |> min(@max_ratio) |> :erlang.float()
  end

  defp clamp_ratio(_ratio), do: 0.5

  defp ensure_composition(state, composition) do
    if get_in(state, [:compositions, composition]) == nil and
         not Map.has_key?(state.compositions, composition) do
      put_in(state, [:compositions, composition], nil)
    else
      state
    end
  end

  defp broadcast(operation, composition, tree) do
    # Spatial events only (INV-8.3) — no content information
    PubSub.broadcast(Chassis.PubSub, @topic, {:layout_changed, operation, composition, tree})
  rescue
    # PubSub may not be started in tests
    _ -> :ok
  end

  defp load_from_backend(backend, composition) do
    case backend.load_layout(composition) do
      {:ok, data} ->
        case Persistence.restore(data) do
          {:ok, tree} -> %{composition => tree}
          {:error, _} -> %{composition => nil}
        end

      {:error, _} ->
        %{composition => nil}
    end
  end

  defp load_weights_from_backend(backend, composition) do
    case backend.load_weights(composition) do
      {:ok, data} ->
        case Persistence.restore_weights(data) do
          {:ok, weights} -> weights
          {:error, _} -> %{}
        end

      {:error, _} ->
        %{}
    end
  end
end
