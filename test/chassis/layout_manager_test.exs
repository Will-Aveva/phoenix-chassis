defmodule Chassis.LayoutManagerTest do
  use ExUnit.Case, async: true

  alias Chassis.LayoutManager

  setup do
    name = :"manager_#{System.unique_integer([:positive])}"
    {:ok, pid} = LayoutManager.start_link(name: name)
    %{server: pid}
  end

  describe "attach/3" do
    test "attaches first slot to empty tree", %{server: server} do
      :ok = LayoutManager.attach(server, :editor)
      tree = LayoutManager.get_tree(server)
      assert tree == {:slot, :editor}
    end

    test "attaches second slot creates division", %{server: server} do
      :ok = LayoutManager.attach(server, :editor)
      :ok = LayoutManager.attach(server, :terminal)
      tree = LayoutManager.get_tree(server)

      assert tree ==
               {:division, :horizontal, [{:slot, :editor}, {:slot, :terminal}]}
    end
  end

  describe "add_to_stack/4" do
    test "adds to stack containing target", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.add_to_stack(server, :a, :b)
      tree = LayoutManager.get_tree(server)
      assert tree == {:stack, :b, [:a, :b]}
    end
  end

  describe "divide/5" do
    test "splits a slot", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.divide(server, :a, :b, :vertical)
      tree = LayoutManager.get_tree(server)

      assert tree ==
               {:division, :vertical, [{:slot, :a}, {:slot, :b}]}
    end
  end

  describe "close/3" do
    test "closes a slot", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      :ok = LayoutManager.close(server, :a)
      tree = LayoutManager.get_tree(server)
      assert tree == {:slot, :b}
    end

    test "returns error for nonexistent composition", %{server: server} do
      result = LayoutManager.close(server, :a, :nonexistent)
      assert result == {:error, :no_composition}
    end
  end

  describe "focus/3" do
    test "sets active tab", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.add_to_stack(server, :a, :b)
      :ok = LayoutManager.focus(server, :a)
      tree = LayoutManager.get_tree(server)
      assert tree == {:stack, :a, [:a, :b]}
    end
  end

  describe "reorder/4" do
    test "reorders within layout", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      :ok = LayoutManager.reorder(server, :a, :b)
      tree = LayoutManager.get_tree(server)
      assert {:stack, :b, [:a, :b]} = tree
    end
  end

  describe "list_slots/2" do
    test "lists all slots", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      slots = LayoutManager.list_slots(server)
      assert slots == [:a, :b]
    end

    test "empty composition returns empty list", %{server: server} do
      assert LayoutManager.list_slots(server) == []
    end
  end

  # A divider drag. `resize/4` writes one child's weight; `resize_pair/5` is what a divider commits,
  # because a divider is a boundary between two children and moving it changes both.
  describe "resize_pair/5" do
    test "splits the pair's own share, so a third sibling is untouched", %{server: server} do
      # The bug this replaced: writing `ratio` and `1 - ratio` while the Shell defaults every other
      # child to 1. Dragging the first divider of a three-way division to 40/60 then rendered
      # `0.4 : 0.6 : 1` — both dragged children shrinking against one nobody touched.
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      :ok = LayoutManager.attach(server, :c)

      :ok = LayoutManager.resize_pair(server, :a, :b, 0.4)

      weights = LayoutManager.get_weights(server)
      assert weights[:a] == 0.8
      assert weights[:b] == 1.2
      assert weights[:a] + weights[:b] == 2.0, "the pair keeps its combined share"
      refute Map.has_key?(weights, :c), "an untouched sibling stores nothing and renders flex: 1"
    end

    test "two children reduce to the plain ratio", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)

      :ok = LayoutManager.resize_pair(server, :a, :b, 0.25)

      weights = LayoutManager.get_weights(server)
      assert weights[:a] == 0.5
      assert weights[:b] == 1.5
    end

    test "a second drag redistributes the share the first one left", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      :ok = LayoutManager.attach(server, :c)

      :ok = LayoutManager.resize_pair(server, :a, :b, 0.25)
      :ok = LayoutManager.resize_pair(server, :b, :c, 0.5)

      weights = LayoutManager.get_weights(server)
      assert weights[:a] == 0.5, "a was not part of the second drag and must not move"
      assert weights[:b] + weights[:c] == 2.5
      assert weights[:b] == weights[:c]
    end

    test "the ratio is clamped, so a child can never be dragged away entirely", %{server: server} do
      # At 0 or 1 there is no divider left to grab and the arrangement is unrecoverable. The client
      # proposes; the server bounds.
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)

      :ok = LayoutManager.resize_pair(server, :a, :b, 0.0)
      assert LayoutManager.get_weights(server)[:a] == 0.1

      :ok = LayoutManager.resize_pair(server, :a, :b, 1.0)
      weights = LayoutManager.get_weights(server)
      # In delta: `combined * (1.0 - 0.95)` is not exactly 0.1 in binary floating point, and the
      # weight is a flex ratio — nothing downstream cares about the last bit.
      assert_in_delta weights[:a], 1.9, 0.0001
      assert_in_delta weights[:b], 0.1, 0.0001
    end

    test "a ratio that is not a number is treated as an even split", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)

      :ok = LayoutManager.resize_pair(server, :a, :b, nil)

      weights = LayoutManager.get_weights(server)
      assert weights[:a] == 1.0
      assert weights[:b] == 1.0
    end

    test "weights belong to a composition, not to the manager", %{server: server} do
      :ok = LayoutManager.attach(server, :a)
      :ok = LayoutManager.attach(server, :b)
      :ok = LayoutManager.attach(server, :a, :other)
      :ok = LayoutManager.attach(server, :b, :other)

      :ok = LayoutManager.resize_pair(server, :a, :b, 0.25)

      assert LayoutManager.get_weights(server, :other) == %{}
    end
  end

  describe "multi-composition" do
    test "compositions are independent", %{server: server} do
      :ok = LayoutManager.attach(server, :a, :workspace_1)
      :ok = LayoutManager.attach(server, :b, :workspace_2)

      assert LayoutManager.get_tree(server, :workspace_1) == {:slot, :a}
      assert LayoutManager.get_tree(server, :workspace_2) == {:slot, :b}
      assert LayoutManager.get_tree(server, :default) == nil
    end
  end

  describe "no content awareness (INV-1.1b)" do
    test "state contains only tree structure, no content", %{server: server} do
      :ok = LayoutManager.attach(server, :editor)
      :ok = LayoutManager.add_to_stack(server, :editor, :terminal)

      # The manager stores only spatial structure
      tree = LayoutManager.get_tree(server)
      slots = LayoutManager.list_slots(server)

      # Tree is pure spatial data — no content, no view state
      assert tree == {:stack, :terminal, [:editor, :terminal]}
      assert slots == [:editor, :terminal]
    end
  end

  describe "persistence_backend wiring (INV-9.5)" do
    defmodule MockBackend do
      @behaviour Chassis.PersistenceBackend

      @impl true
      def save_layout(composition, data) do
        :ets.insert(:mock_backend_store, {composition, data})
        :ok
      end

      @impl true
      def load_layout(_composition) do
        {:error, :not_found}
      end
    end

    defmodule PreloadedBackend do
      @behaviour Chassis.PersistenceBackend

      @impl true
      def save_layout(_composition, _data), do: :ok

      @impl true
      def load_layout(:default) do
        tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
        {:ok, Chassis.Persistence.save(tree)}
      end

      def load_layout(_), do: {:error, :not_found}
    end

    test "T-9.4: start_link with backend loads saved tree" do
      name = :"backend_load_#{System.unique_integer([:positive])}"

      {:ok, pid} =
        LayoutManager.start_link(
          name: name,
          persistence_backend: PreloadedBackend
        )

      tree = LayoutManager.get_tree(pid)
      assert tree == {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
    end

    test "T-9.4: terminate with backend persists tree" do
      # ETS table for cross-process communication (terminate runs in GenServer process)
      table = :ets.new(:mock_backend_store, [:named_table, :public, :set])

      name = :"backend_save_#{System.unique_integer([:positive])}"

      {:ok, pid} =
        LayoutManager.start_link(
          name: name,
          persistence_backend: MockBackend
        )

      :ok = LayoutManager.attach(pid, :editor)
      GenServer.stop(pid, :normal)

      # Check ETS for persisted data
      assert [{:default, data}] = :ets.lookup(table, :default)
      assert is_binary(data)
      assert {:ok, {:slot, :editor}} = Chassis.Persistence.restore(data)

      :ets.delete(table)
    end

    test "without backend, state is ephemeral" do
      name = :"no_backend_#{System.unique_integer([:positive])}"
      {:ok, pid} = LayoutManager.start_link(name: name)
      :ok = LayoutManager.attach(pid, :x)

      # Stopping without backend doesn't crash
      GenServer.stop(pid, :normal)
    end
  end
end
