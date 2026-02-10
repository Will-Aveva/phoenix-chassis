defmodule Chassis.PersistenceBackendTest do
  use ExUnit.Case, async: true

  # A test backend implementation
  defmodule TestBackend do
    @behaviour Chassis.PersistenceBackend

    @impl true
    def save_layout(_composition, _data), do: :ok

    @impl true
    def load_layout(_composition), do: {:error, :not_found}
  end

  describe "T-9.3: behaviour module is defined" do
    test "defines correct callbacks" do
      callbacks = Chassis.PersistenceBackend.behaviour_info(:callbacks)
      assert {:save_layout, 2} in callbacks
      assert {:load_layout, 1} in callbacks
      assert {:save_weights, 2} in callbacks
      assert {:load_weights, 1} in callbacks
      assert length(callbacks) == 4

      optional = Chassis.PersistenceBackend.behaviour_info(:optional_callbacks)
      assert {:save_weights, 2} in optional
      assert {:load_weights, 1} in optional
      assert length(optional) == 2
    end
  end

  describe "T-9.7: backend operates on opaque binaries" do
    test "save_layout accepts binary data" do
      # Create a real serialized tree
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      data = Chassis.Persistence.save(tree)
      assert is_binary(data)
      assert TestBackend.save_layout(:default, data) == :ok
    end

    test "load_layout returns binary data or error" do
      assert {:error, :not_found} = TestBackend.load_layout(:default)
    end
  end

  describe "round-trip through backend" do
    test "backend stores and retrieves opaque binary" do
      # Use an Agent-based backend for stateful test
      {:ok, store} = Agent.start_link(fn -> %{} end)

      tree = {:stack, :a, [:a, :b, :c]}
      data = Chassis.Persistence.save(tree)

      # Simulate save
      Agent.update(store, &Map.put(&1, :default, data))

      # Simulate load
      loaded = Agent.get(store, &Map.get(&1, :default))
      assert {:ok, ^tree} = Chassis.Persistence.restore(loaded)

      Agent.stop(store)
    end
  end
end
