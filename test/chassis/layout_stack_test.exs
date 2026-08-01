defmodule Chassis.LayoutStackTest do
  @moduledoc """
  The stack — a tabbed window — as an algebra.

  `layout_test.exs` covers each operation once. This file covers what a stack *does* over a
  sequence of the interactions an IDE offers: click a tab, drag it, tear it out, close it, cycle
  it from the keyboard. Every assertion is on the whole tree, because the tree is the sole
  representation of the arrangement (INV-2.2) and the DOM is its projection (INV-3.1) — a test that
  matched only the part it cared about would pass while the rest of the arrangement drifted.

  Where behaviour is a *choice* rather than a consequence — which tab a close promotes, which side
  of the target a dragged tab lands on — the test says so, since `Seek.WorkspaceLayout` (the shell
  Chassis was generalized from) chose the other one in both cases and neither is wrong.
  """
  use ExUnit.Case, async: true

  alias Chassis.Layout

  # A three-pane arrangement: one slot beside a vertical pair. It is the demo's `:default`
  # composition, and it is the smallest tree with both a stack and two nested divisions.
  defp workspace do
    nil
    |> Layout.attach(:editor)
    |> Layout.divide(:editor, :preview, :horizontal)
    |> Layout.divide(:preview, :terminal, :vertical)
  end

  describe "a slot becomes a stack" do
    test "add_to_stack/3 turns a lone slot into a two-tab stack with the newcomer active" do
      # Dropping a panel on a pane's centre is how an IDE adds a tab. The newcomer is active
      # because the user just put it there.
      assert Layout.add_to_stack({:slot, :editor}, :editor, :notes) ==
               {:stack, :notes, [:editor, :notes]}
    end

    test "a stack grows at the end, wherever in the stack the drop landed" do
      # The target here is the FIRST tab, and the new tab still appends. A centre-zone drop names
      # the pane, not a position in its tab bar — `reorder/3` is the operation that positions.
      tree = {:stack, :editor, [:editor, :notes]}

      assert Layout.add_to_stack(tree, :editor, :debugger) ==
               {:stack, :debugger, [:editor, :notes, :debugger]}
    end

    test "add_to_stack/3 reaches a stack nested inside divisions" do
      tree = Layout.add_to_stack(workspace(), :terminal, :notes)

      assert tree ==
               {:division, :horizontal,
                [
                  {:slot, :editor},
                  {:division, :vertical,
                   [{:slot, :preview}, {:stack, :notes, [:terminal, :notes]}]}
                ]}
    end

    test "a target that is not in the tree falls back to attaching beside everything" do
      # Not a silent no-op: a drop that named a pane that has since gone still has to put the
      # panel somewhere the user can see it.
      tree = Layout.add_to_stack({:slot, :editor}, :gone, :notes)
      assert tree == {:division, :horizontal, [{:slot, :editor}, {:slot, :notes}]}
    end

    test "add_to_stack/3 does NOT vacate the slot's old position — the caller must" do
      # Read this as a precondition on the operation, not as a feature. Two nodes naming one slot
      # render the same DOM ids twice and LiveView patches by id, so from that point it targets
      # whichever it finds first.
      #
      # `ChassisWeb.DemoLive`'s `chassis:dock_slot` handler is what keeps this from happening: it
      # closes the dragged slot before adding it. `tabbed_stack_test.exs` holds that end of the
      # contract; this test pins the fact that the algebra does not do it for you.
      tree = {:division, :horizontal, [{:slot, :editor}, {:slot, :notes}]}
      duplicated = Layout.add_to_stack(tree, :editor, :notes)

      assert duplicated ==
               {:division, :horizontal, [{:stack, :notes, [:editor, :notes]}, {:slot, :notes}]}

      assert Layout.list_slots(duplicated) == [:editor, :notes, :notes]
    end
  end

  describe "one tab is active" do
    test "focus/2 moves the active tab and leaves the order alone" do
      # Clicking a tab must not reorder the tab bar — dragging is the gesture that reorders.
      tree = {:stack, :editor, [:editor, :notes, :debugger]}
      assert Layout.focus(tree, :debugger) == {:stack, :debugger, [:editor, :notes, :debugger]}
    end

    test "focus/2 only touches the stack that holds the slot" do
      tree =
        {:division, :horizontal,
         [{:stack, :editor, [:editor, :notes]}, {:stack, :terminal, [:terminal, :debugger]}]}

      assert Layout.focus(tree, :debugger) ==
               {:division, :horizontal,
                [
                  {:stack, :editor, [:editor, :notes]},
                  {:stack, :debugger, [:terminal, :debugger]}
                ]}
    end

    test "focusing a lone slot is a no-op on the tree" do
      # A one-tab pane has nothing to switch between. The shell still tracks it as the focused
      # pane — that lives in the consuming LiveView's `active_slot`, not in the tree.
      assert Layout.focus({:slot, :editor}, :editor) == {:slot, :editor}
    end

    test "focusing a slot that is not in the tree changes nothing" do
      tree = {:stack, :editor, [:editor, :notes]}
      assert Layout.focus(tree, :gone) == tree
    end
  end

  describe "dragging a tab" do
    test "reorder/3 lands the dragged tab BEFORE the target and activates it" do
      # A choice, and the opposite of `Seek.WorkspaceLayout.reorder_view/3`, which inserts after
      # the target. A browser drag knows where in the tab the pointer was; neither shell reads
      # that yet, so each picked a side and this is Chassis's.
      tree = {:stack, :editor, [:editor, :notes, :debugger]}

      assert Layout.reorder(tree, :editor, :debugger) ==
               {:stack, :debugger, [:debugger, :editor, :notes]}
    end

    test "a tab dragged onto a tab in another stack leaves the first stack" do
      tree =
        {:division, :horizontal,
         [{:stack, :editor, [:editor, :notes]}, {:stack, :terminal, [:terminal, :debugger]}]}

      moved = Layout.reorder(tree, :terminal, :notes)

      assert moved ==
               {:division, :horizontal,
                [{:slot, :editor}, {:stack, :notes, [:notes, :terminal, :debugger]}]}

      # Removed before re-inserted, so the slot is still in exactly one place.
      assert Layout.list_slots(moved) == [:editor, :notes, :terminal, :debugger]
    end

    test "a tab dragged onto a lone slot lands AFTER it — the opposite side from a stack's tab" do
      # An asymmetry in `reorder/3`, not a considered rule: the stack clause inserts at the
      # target's index (before it) while the bare-slot clause writes `[target, dragged]`. So the
      # same gesture puts the tab on a different side of the tab it was dropped on depending on
      # whether that pane already had two tabs. Pinned so the next change to either clause is a
      # decision instead of a surprise.
      tree = {:division, :horizontal, [{:slot, :editor}, {:slot, :notes}]}
      assert Layout.reorder(tree, :editor, :notes) == {:stack, :notes, [:editor, :notes]}

      stacked =
        {:division, :horizontal, [{:stack, :editor, [:editor, :terminal]}, {:slot, :notes}]}

      assert Layout.reorder(stacked, :editor, :notes) ==
               {:stack, :notes, [:notes, :editor, :terminal]}
    end

    test "the source stack collapses to a lone slot when the drag empties it" do
      tree =
        {:division, :horizontal, [{:stack, :editor, [:editor, :notes]}, {:slot, :terminal}]}

      # Both of the left stack's tabs end up on the right, and the left pane goes with them.
      tree = Layout.reorder(tree, :terminal, :notes)

      assert Layout.reorder(tree, :terminal, :editor) ==
               {:stack, :editor, [:editor, :terminal, :notes]}
    end
  end

  describe "tearing a tab out" do
    test "divide/5 splits the whole stack, not the tab that was named" do
      # The dragged panel arrives beside the *pane*; the pane keeps its other tabs. Naming any
      # tab of the stack names the stack.
      tree = {:stack, :editor, [:editor, :notes]}

      assert Layout.divide(tree, :notes, :debugger, :horizontal) ==
               {:division, :horizontal,
                [{:stack, :editor, [:editor, :notes]}, {:slot, :debugger}]}
    end

    test ":before puts the newcomer first, which is what a left or top edge drop means" do
      tree = {:slot, :editor}

      assert Layout.divide(tree, :editor, :notes, :horizontal, :before) ==
               {:division, :horizontal, [{:slot, :notes}, {:slot, :editor}]}

      assert Layout.divide(tree, :editor, :notes, :vertical, :before) ==
               {:division, :vertical, [{:slot, :notes}, {:slot, :editor}]}
    end

    test "tearing the second-to-last tab out leaves a one-tab stack behind, normalized to a slot" do
      tree = {:stack, :notes, [:editor, :notes]}

      # `divide/5` does not remove the dragged slot either — same precondition as add_to_stack/3.
      torn = tree |> Layout.close(:notes) |> Layout.divide(:editor, :notes, :horizontal)

      assert torn == {:division, :horizontal, [{:slot, :editor}, {:slot, :notes}]}
    end
  end

  describe "closing a tab" do
    test "closing the active tab promotes the FIRST remaining tab" do
      # Also a choice: `Seek.WorkspaceLayout` promotes the last. An IDE promotes the
      # spatially-adjacent one, which neither shell has enough information to do — the tree
      # records order, not which tab the user looked at before this one.
      tree = {:stack, :notes, [:editor, :notes, :debugger]}
      assert Layout.close(tree, :notes) == {:stack, :editor, [:editor, :debugger]}
    end

    test "closing an inactive tab leaves the active one alone" do
      tree = {:stack, :notes, [:editor, :notes, :debugger]}
      assert Layout.close(tree, :debugger) == {:stack, :notes, [:editor, :notes]}
    end

    test "closing down to one tab normalizes the stack away" do
      # There is one rendering path for tab chrome: a lone slot is re-promoted to a one-tab stack
      # at render time (INV-3.2). Keeping a one-tab stack in the tree would be a second
      # representation of the same arrangement.
      assert Layout.close({:stack, :editor, [:editor, :notes]}, :notes) == {:slot, :editor}
    end

    test "closing the last tab of a pane removes the pane and collapses its division" do
      tree = workspace()

      assert Layout.close(tree, :terminal) ==
               {:division, :horizontal, [{:slot, :editor}, {:slot, :preview}]}

      assert tree |> Layout.close(:terminal) |> Layout.close(:preview) == {:slot, :editor}

      assert tree |> Layout.close(:terminal) |> Layout.close(:preview) |> Layout.close(:editor) ==
               nil
    end

    test "an emptied tree is nil, not an empty division" do
      # `nil` is what the Shell renders its empty state from, and what persistence stores as
      # "no arrangement". A `{:division, _, []}` would render a phantom container (INV-3.3).
      assert Layout.close({:slot, :editor}, :editor) == nil
    end
  end

  describe "keyboard cycling within a stack" do
    test "next and prev wrap around the tab bar" do
      tree = {:stack, :editor, [:editor, :notes, :debugger]}

      assert Layout.next_in_stack(tree, :editor) == :notes
      assert Layout.next_in_stack(tree, :debugger) == :editor
      assert Layout.prev_in_stack(tree, :editor) == :debugger
      assert Layout.prev_in_stack(tree, :notes) == :editor
    end

    test "cycling is relative to the slot asked about, not to the active tab" do
      # The keyboard hook sends the shell's active slot, so the two normally coincide — but the
      # query answers about the slot it was given, which is what makes it reusable for a tab that
      # is merely hovered or dragged.
      tree = {:stack, :editor, [:editor, :notes, :debugger]}
      assert Layout.next_in_stack(tree, :notes) == :debugger
    end

    test "a one-tab pane has nothing to cycle to" do
      # nil rather than the slot itself: the handler treats nil as "do nothing", and answering
      # `:editor` would re-broadcast a focus change for a tab that never lost focus.
      assert Layout.next_in_stack({:slot, :editor}, :editor) == nil
      assert Layout.prev_in_stack({:slot, :editor}, :editor) == nil
    end

    test "cycling reaches stacks nested in divisions, and does not leave them" do
      tree = Layout.add_to_stack(workspace(), :preview, :notes)

      assert Layout.next_in_stack(tree, :preview) == :notes
      assert Layout.next_in_stack(tree, :notes) == :preview
      # :editor sits in its own pane; ctrl+tab there is not a way to reach another pane.
      assert Layout.next_in_stack(tree, :editor) == nil
    end
  end

  describe "spatial navigation between panes" do
    test "a direction resolves to the neighbouring pane's ACTIVE tab" do
      # Moving right must land on what that pane is *showing*. Landing on its first tab would
      # change what is visible as a side effect of moving focus.
      tree = Layout.add_to_stack(workspace(), :preview, :notes)

      assert Layout.adjacent(tree, :editor, :right) == :notes
      assert Layout.adjacent(tree, :notes, :left) == :editor
    end

    test "an inactive tab still navigates by the pane it sits in" do
      tree = Layout.add_to_stack(workspace(), :preview, :notes)
      # :preview is no longer active in its stack; down from it is still the pane below.
      assert Layout.adjacent(tree, :preview, :down) == :terminal
      assert Layout.adjacent(tree, :notes, :down) == :terminal
    end

    test "an edge answers nil, and so does an axis the pane has no sibling on" do
      tree = workspace()

      assert Layout.adjacent(tree, :editor, :left) == nil
      assert Layout.adjacent(tree, :terminal, :down) == nil
      # :editor's division is horizontal; there is nothing above or below it.
      assert Layout.adjacent(tree, :editor, :up) == nil
      assert Layout.adjacent(tree, :editor, :down) == nil
    end

    test "navigation walks out of a nested division to find a sibling on the asked-for axis" do
      tree = workspace()
      assert Layout.adjacent(tree, :preview, :left) == :editor
      assert Layout.adjacent(tree, :terminal, :left) == :editor
    end
  end

  describe "a slot appears in exactly one place" do
    test "a sequence of tab interactions never duplicates a slot" do
      # The property that makes the DOM ids unique. Asserted over a sequence rather than per
      # operation because it is the sequence that has broken it before: an operation that adds
      # without removing is only visible once something else has already placed the slot.
      final =
        workspace()
        |> Layout.add_to_stack(:editor, :notes)
        |> Layout.focus(:editor)
        |> Layout.reorder(:preview, :notes)
        |> then(&Layout.divide(Layout.close(&1, :terminal), :editor, :terminal, :vertical))
        |> Layout.reorder(:editor, :preview)

      slots = Layout.list_slots(final)
      assert Enum.sort(slots) == Enum.sort(Enum.uniq(slots))
      assert Enum.sort(slots) == [:editor, :notes, :preview, :terminal]
    end
  end
end
