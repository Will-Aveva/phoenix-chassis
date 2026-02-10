defmodule Chassis.PersistenceTest do
  use ExUnit.Case, async: true

  alias Chassis.{Layout, Persistence}

  describe "round-trip fidelity (INV-5.2)" do
    test "simple slot" do
      tree = Layout.slot(:a)
      assert {:ok, ^tree} = tree |> Persistence.save() |> Persistence.restore()
    end

    test "stack" do
      tree = Layout.stack(:b, [:a, :b, :c])
      assert {:ok, ^tree} = tree |> Persistence.save() |> Persistence.restore()
    end

    test "complex nested tree" do
      tree =
        {:division, :horizontal,
         [
           {:stack, :editor, [:editor, :preview]},
           {:division, :vertical,
            [
              {:slot, :terminal},
              {:slot, :output}
            ]}
         ]}

      assert {:ok, ^tree} = tree |> Persistence.save() |> Persistence.restore()
    end

    test "nil tree" do
      assert {:ok, nil} = nil |> Persistence.save() |> Persistence.restore()
    end
  end

  describe "error handling" do
    test "invalid binary" do
      assert {:error, :invalid_format} = Persistence.restore(<<0, 1, 2>>)
    end

    test "non-binary input" do
      assert {:error, :invalid_format} = Persistence.restore(:not_binary)
    end
  end

  describe "weight persistence (T-5.5)" do
    test "weight round-trip fidelity" do
      weights = %{editor: 0.7, preview: 0.3, terminal: 1.0}
      data = Persistence.save_weights(weights)
      assert {:ok, ^weights} = Persistence.restore_weights(data)
    end

    test "empty weights round-trip" do
      weights = %{}
      data = Persistence.save_weights(weights)
      assert {:ok, ^weights} = Persistence.restore_weights(data)
    end

    test "invalid binary for weights" do
      assert {:error, :invalid_format} = Persistence.restore_weights(<<0, 1, 2>>)
    end

    test "non-binary input for weights" do
      assert {:error, :invalid_format} = Persistence.restore_weights(:not_binary)
    end
  end
end
