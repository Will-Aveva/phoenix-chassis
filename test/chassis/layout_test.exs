defmodule Chassis.LayoutTest do
  use ExUnit.Case, async: true

  alias Chassis.Layout

  # ---------------------------------------------------------------------------
  # WU-2: Constructors
  # ---------------------------------------------------------------------------

  describe "slot/1" do
    test "creates a slot node" do
      assert Layout.slot(:editor) == {:slot, :editor}
    end

    test "accepts string IDs" do
      assert Layout.slot("panel-1") == {:slot, "panel-1"}
    end
  end

  describe "stack/2" do
    test "creates a stack node" do
      assert Layout.stack(:a, [:a, :b]) == {:stack, :a, [:a, :b]}
    end
  end

  describe "division/2" do
    test "creates a horizontal division" do
      result = Layout.division(:horizontal, [Layout.slot(:a), Layout.slot(:b)])
      assert result == {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
    end

    test "creates a vertical division" do
      result = Layout.division(:vertical, [Layout.slot(:a), Layout.slot(:b)])
      assert result == {:division, :vertical, [{:slot, :a}, {:slot, :b}]}
    end

    test "normalizes single-child division to the child (INV-2.3)" do
      result = Layout.division(:horizontal, [Layout.slot(:a)])
      assert result == {:slot, :a}
    end

    test "normalizes empty division to nil" do
      result = Layout.division(:horizontal, [])
      assert result == nil
    end
  end

  # ---------------------------------------------------------------------------
  # WU-3: Operations
  # ---------------------------------------------------------------------------

  describe "attach/2" do
    test "attaches to nil tree" do
      assert Layout.attach(nil, :a) == {:slot, :a}
    end

    test "attaches to existing slot" do
      tree = Layout.slot(:a)
      result = Layout.attach(tree, :b)
      assert result == {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
    end

    test "attaches to existing division" do
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      result = Layout.attach(tree, :c)

      assert result ==
               {:division, :horizontal, [{:slot, :a}, {:slot, :b}, {:slot, :c}]}
    end
  end

  describe "add_to_stack/3" do
    test "converts bare slot to stack" do
      tree = Layout.slot(:a)
      result = Layout.add_to_stack(tree, :a, :b)
      assert result == {:stack, :b, [:a, :b]}
    end

    test "adds to existing stack" do
      tree = Layout.stack(:a, [:a, :b])
      result = Layout.add_to_stack(tree, :a, :c)
      assert result == {:stack, :c, [:a, :b, :c]}
    end

    test "falls back to attach if target not found" do
      tree = Layout.slot(:a)
      result = Layout.add_to_stack(tree, :nonexistent, :b)
      assert result == {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
    end
  end

  describe "divide/5" do
    test "splits a slot horizontally" do
      tree = Layout.slot(:a)
      result = Layout.divide(tree, :a, :b, :horizontal)

      assert result ==
               {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
    end

    test "splits a slot vertically before" do
      tree = Layout.slot(:a)
      result = Layout.divide(tree, :a, :b, :vertical, :before)

      assert result ==
               {:division, :vertical, [{:slot, :b}, {:slot, :a}]}
    end

    test "splits a stack" do
      tree = Layout.stack(:a, [:a, :b])
      result = Layout.divide(tree, :a, :c, :horizontal)

      assert result ==
               {:division, :horizontal, [{:stack, :a, [:a, :b]}, {:slot, :c}]}
    end

    test "splits nested slot" do
      tree =
        {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}

      result = Layout.divide(tree, :b, :c, :vertical)

      assert result ==
               {:division, :horizontal,
                [{:slot, :a}, {:division, :vertical, [{:slot, :b}, {:slot, :c}]}]}
    end
  end

  describe "close/2" do
    test "closes a slot" do
      tree = Layout.slot(:a)
      assert Layout.close(tree, :a) == nil
    end

    test "closes slot from division, normalizes" do
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      assert Layout.close(tree, :a) == {:slot, :b}
    end

    test "closes slot from stack" do
      tree = Layout.stack(:a, [:a, :b, :c])
      result = Layout.close(tree, :a)
      assert result == {:stack, :b, [:b, :c]}
    end

    test "closing last slot from stack yields nil" do
      tree = Layout.stack(:a, [:a])
      assert Layout.close(tree, :a) == nil
    end

    test "closing nonexistent slot is a no-op" do
      tree = Layout.slot(:a)
      assert Layout.close(tree, :nonexistent) == {:slot, :a}
    end
  end

  describe "focus/2" do
    test "sets active tab in stack" do
      tree = Layout.stack(:a, [:a, :b, :c])
      result = Layout.focus(tree, :c)
      assert result == {:stack, :c, [:a, :b, :c]}
    end

    test "focus on slot not in stack is a no-op" do
      tree = Layout.stack(:a, [:a, :b])
      result = Layout.focus(tree, :nonexistent)
      assert result == {:stack, :a, [:a, :b]}
    end

    test "focus works through nested structure" do
      tree =
        {:division, :horizontal, [{:stack, :a, [:a, :b]}, {:slot, :c}]}

      result = Layout.focus(tree, :b)

      assert result ==
               {:division, :horizontal, [{:stack, :b, [:a, :b]}, {:slot, :c}]}
    end
  end

  describe "reorder/3" do
    test "reorders within stack" do
      tree = Layout.stack(:a, [:a, :b, :c])
      result = Layout.reorder(tree, :a, :c)
      # c is inserted at a's position
      assert {:stack, :c, ids} = result
      assert :c in ids
      assert :a in ids
    end

    test "reorder to bare slot creates stack" do
      tree =
        {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}

      result = Layout.reorder(tree, :a, :b)
      # b removed from division, docked to a's position
      assert {:stack, :b, [:a, :b]} = result
    end
  end

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  describe "list_slots/1" do
    test "lists slots from division" do
      tree =
        {:division, :horizontal, [{:slot, :a}, {:stack, :b, [:b, :c]}, {:slot, :d}]}

      assert Layout.list_slots(tree) == [:a, :b, :c, :d]
    end

    test "empty tree" do
      assert Layout.list_slots(nil) == []
    end
  end

  # ---------------------------------------------------------------------------
  # Content-blindness (INV-4.3 / T-4.3)
  # ---------------------------------------------------------------------------

  describe "content-blindness" do
    test "operations produce identical structure regardless of slot ID values" do
      tree_1 = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      tree_2 = {:division, :horizontal, [{:slot, :x}, {:slot, :y}]}

      result_1 = Layout.divide(tree_1, :a, :c, :vertical)
      result_2 = Layout.divide(tree_2, :x, :z, :vertical)

      # Structure is identical — only IDs differ
      assert match?(
               {:division, :horizontal,
                [{:division, :vertical, [{:slot, _}, {:slot, _}]}, {:slot, _}]},
               result_1
             )

      assert match?(
               {:division, :horizontal,
                [{:division, :vertical, [{:slot, _}, {:slot, _}]}, {:slot, _}]},
               result_2
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Vocabulary (INV-7.2)
  # ---------------------------------------------------------------------------

  describe "vocabulary" do
    test "module uses canonical terms only" do
      source = File.read!(Path.join([__DIR__, "..", "..", "lib", "chassis", "layout.ex"]))

      # Prohibited terms from Chassis glossary
      refute source =~ ~r/\bworkspace\b/i
      refute source =~ ~r/\btab_group\b/i
      refute source =~ ~r/\bsplit_view\b/i
      refute source =~ ~r/\b:view\b/
      refute source =~ ~r/\b:tabs\b/
      refute source =~ ~r/\b:split\b/
    end
  end
end
