defmodule Chassis.Layout do
  @moduledoc """
  Pure functional core for managing layout trees.

  A Chassis layout tree is an algebraic type with three node kinds:

    * `{:slot, id}` — a leaf node representing a content container
    * `{:stack, active_id, slot_ids}` — a tabbed group of slots
    * `{:division, direction, children}` — a spatial split (horizontal or vertical)

  All operations are pure transforms: `tree -> tree`.
  The tree is the single source of truth (INV-2.2).
  Operations are content-blind — they manipulate spatial positions only (INV-4.3).
  """

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  @type slot_id :: atom() | String.t()
  @type direction :: :horizontal | :vertical
  @type tree_node ::
          {:slot, slot_id()}
          | {:stack, slot_id(), [slot_id()]}
          | {:division, direction(), [tree_node()]}
          | nil

  # ---------------------------------------------------------------------------
  # Constructors
  # ---------------------------------------------------------------------------

  @doc "Create a slot (leaf node)."
  @spec slot(slot_id()) :: {:slot, slot_id()}
  def slot(id), do: {:slot, id}

  @doc "Create a stack (tabbed group). The first slot is active by default."
  @spec stack(slot_id(), [slot_id()]) :: {:stack, slot_id(), [slot_id()]}
  def stack(active, slot_ids) when is_list(slot_ids), do: {:stack, active, slot_ids}

  @doc "Create a division (spatial split). Direction is :horizontal or :vertical."
  @spec division(direction(), [tree_node()]) ::
          {:division, direction(), [tree_node()]} | tree_node()
  def division(direction, children)
      when direction in [:horizontal, :vertical] and is_list(children) do
    normalize({:division, direction, children})
  end

  # ---------------------------------------------------------------------------
  # Operations (INV-4.1)
  # ---------------------------------------------------------------------------

  @doc """
  Attach a new slot to the tree. If the tree is nil, the slot becomes the root.
  Otherwise, appends to the root division or wraps in a new horizontal division.
  """
  @spec attach(tree_node(), slot_id()) :: tree_node()
  def attach(nil, id), do: slot(id)

  def attach({:division, dir, children}, id) do
    normalize({:division, dir, children ++ [slot(id)]})
  end

  def attach(existing, id) do
    normalize({:division, :horizontal, [existing, slot(id)]})
  end

  @doc """
  Add a slot to the stack containing the target slot.
  If the target is a bare slot, converts it to a stack.
  """
  @spec add_to_stack(tree_node(), slot_id(), slot_id()) :: tree_node()
  def add_to_stack(tree, target_id, new_id) do
    new_tree =
      traverse_replace(tree, fn
        {:slot, ^target_id} ->
          {:stack, new_id, [target_id, new_id]}

        {:stack, active, ids} ->
          if target_id in ids do
            {:stack, new_id, ids ++ [new_id]}
          else
            {:stack, active, ids}
          end

        other ->
          other
      end)

    # If no replacement happened, fall back to attach
    if new_tree == tree, do: attach(tree, new_id), else: new_tree
  end

  @doc """
  Divide a slot by splitting it with a new slot in the given direction.
  Order can be :before or :after (default).
  """
  @spec divide(tree_node(), slot_id(), slot_id(), direction(), :before | :after) :: tree_node()
  def divide(tree, target_id, new_id, direction, order \\ :after) do
    traverse_replace(tree, fn
      {:slot, ^target_id} = node ->
        children =
          case order do
            :before -> [slot(new_id), node]
            :after -> [node, slot(new_id)]
          end

        {:division, direction, children}

      {:stack, _active, ids} = node ->
        if target_id in ids do
          children =
            case order do
              :before -> [slot(new_id), node]
              :after -> [node, slot(new_id)]
            end

          {:division, direction, children}
        else
          node
        end

      other ->
        other
    end)
  end

  @doc """
  Close (remove) a slot from the tree.
  """
  @spec close(tree_node(), slot_id()) :: tree_node()
  def close(tree, id) do
    tree
    |> do_close(id)
    |> normalize()
  end

  defp do_close({:slot, id}, id), do: nil
  defp do_close({:slot, _} = node, _), do: node

  defp do_close({:stack, active, ids}, id) do
    new_ids = List.delete(ids, id)

    case new_ids do
      [] -> nil
      _ -> {:stack, if(active == id, do: hd(new_ids), else: active), new_ids}
    end
  end

  defp do_close({:division, dir, children}, id) do
    new_children =
      children
      |> Enum.map(&do_close(&1, id))
      |> Enum.reject(&is_nil/1)

    case new_children do
      [] -> nil
      _ -> {:division, dir, new_children}
    end
  end

  defp do_close(nil, _), do: nil

  @doc """
  Set the active tab in the stack containing the given slot.
  """
  @spec focus(tree_node(), slot_id()) :: tree_node()
  def focus(tree, id) do
    traverse_replace(tree, fn
      {:stack, _active, ids} = node ->
        if id in ids, do: {:stack, id, ids}, else: node

      other ->
        other
    end)
  end

  @doc """
  Reorder: move a slot to the position of a target slot within its stack.
  If they are in different stacks, removes from source and docks to target's stack.
  """
  @spec reorder(tree_node(), slot_id(), slot_id()) :: tree_node()
  def reorder(tree, target_id, dragged_id) do
    # Remove dragged_id first
    tree_minus = close(tree, dragged_id)

    # Insert dragged_id at target's position
    traverse_replace(tree_minus, fn
      {:stack, _active, ids} = node ->
        if target_id in ids do
          idx = Enum.find_index(ids, &(&1 == target_id))
          new_ids = List.insert_at(ids, idx, dragged_id)
          {:stack, dragged_id, new_ids}
        else
          node
        end

      {:slot, ^target_id} ->
        {:stack, dragged_id, [target_id, dragged_id]}

      other ->
        other
    end)
  end

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  @doc """
  List all slot IDs in the tree.
  """
  @spec list_slots(tree_node()) :: [slot_id()]
  def list_slots(tree), do: do_list_slots(tree, []) |> Enum.reverse()

  defp do_list_slots({:slot, id}, acc), do: [id | acc]
  defp do_list_slots({:stack, _, ids}, acc), do: Enum.reverse(ids) ++ acc

  defp do_list_slots({:division, _, children}, acc) do
    Enum.reduce(children, acc, fn child, a -> do_list_slots(child, a) end)
  end

  defp do_list_slots(nil, acc), do: acc

  @doc """
  Return the next slot ID within the same stack, wrapping around.
  Returns nil if the slot is not in a stack or is the only slot.
  """
  @spec next_in_stack(tree_node(), slot_id()) :: slot_id() | nil
  def next_in_stack(tree, slot_id) do
    case find_containing_stack(tree, slot_id) do
      {:stack, _active, ids} when length(ids) > 1 ->
        idx = Enum.find_index(ids, &(&1 == slot_id))
        Enum.at(ids, rem(idx + 1, length(ids)))

      _ ->
        nil
    end
  end

  @doc """
  Return the previous slot ID within the same stack, wrapping around.
  Returns nil if the slot is not in a stack or is the only slot.
  """
  @spec prev_in_stack(tree_node(), slot_id()) :: slot_id() | nil
  def prev_in_stack(tree, slot_id) do
    case find_containing_stack(tree, slot_id) do
      {:stack, _active, ids} when length(ids) > 1 ->
        idx = Enum.find_index(ids, &(&1 == slot_id))
        Enum.at(ids, rem(idx - 1 + length(ids), length(ids)))

      _ ->
        nil
    end
  end

  @doc """
  Find the first slot in an adjacent division sibling in the given direction.
  Direction is :left, :right, :up, or :down.
  Returns nil if no adjacent slot exists in that direction.
  """
  @spec adjacent(tree_node(), slot_id(), :left | :right | :up | :down) :: slot_id() | nil
  def adjacent(tree, slot_id, direction) do
    case find_adjacent(tree, slot_id, direction) do
      nil -> nil
      result -> result
    end
  end

  @doc """
  The first slot of a subtree — the leading container's first slot.

  `nil` for a node that holds no slot. Callers key sizing hints by `weight_key/1`, not by this.
  """
  @spec first_slot_id(tree_node()) :: slot_id() | nil
  def first_slot_id({:slot, id}), do: id
  def first_slot_id({:stack, _active, [first | _]}), do: first
  def first_slot_id({:division, _dir, [first | _]}), do: first_slot_id(first)
  def first_slot_id(_node), do: nil

  @doc """
  The last slot of a subtree — the trailing container's **first** slot.

  Its first slot rather than its last, for the same reason `first_slot_id/1` uses one: a container's
  identity must not move when the user adds or closes a slot inside it.
  """
  @spec last_slot_id(tree_node()) :: slot_id() | nil
  def last_slot_id({:slot, id}), do: id
  def last_slot_id({:stack, _active, [first | _]}), do: first
  def last_slot_id({:division, _dir, children}), do: children |> List.last() |> last_slot_id()
  def last_slot_id(_node), do: nil

  @doc """
  The identity of a division's child, for keying its flex weight (INV-2.5): the containers at its
  two ends.

  A division's children are subtrees, and one slot id is not a name for one. `first_slot_id/1` walks
  to the leading slot, so a division and its own first child answer the *same* slot: keyed on that
  alone, one weight sized two different shares, and dragging an outer divider resized a nested
  division nobody touched.

  The pair is unique. An ancestor and its first child agree on the first slot but never on the last,
  since the ancestor holds at least one more subtree after that child; and two unrelated subtrees
  hold disjoint slots, so they cannot agree on both ends.

  A key that stops matching — because the subtree's ends changed — falls back to an even share,
  which is visible and recoverable. A key that matched the *wrong* child would silently hand a
  container somebody else's size.
  """
  @spec weight_key(tree_node()) :: {slot_id() | nil, slot_id() | nil}
  def weight_key(node), do: {first_slot_id(node), last_slot_id(node)}

  @doc """
  The weight keys of the two children a divider sits between, located by the pair of first slot ids
  the divider names.

  `nil` when no division has those as consecutive children — a divider that is no longer there,
  which costs the drag and nothing else.
  """
  @spec divider_keys(tree_node(), slot_id(), slot_id()) :: {tuple(), tuple()} | nil
  def divider_keys(tree, slot_id, next_slot_id)

  def divider_keys({:division, _dir, children}, slot_id, next_slot_id) do
    consecutive =
      children
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.find(fn [left, right] ->
        first_slot_id(left) == slot_id and first_slot_id(right) == next_slot_id
      end)

    case consecutive do
      [left, right] -> {weight_key(left), weight_key(right)}
      nil -> Enum.find_value(children, &divider_keys(&1, slot_id, next_slot_id))
    end
  end

  def divider_keys(_node, _slot_id, _next_slot_id), do: nil

  @doc """
  The weight key of the container holding a slot — the leaf a `resize/3` names.

  `nil` when the slot is not in the tree.
  """
  @spec container_key(tree_node(), slot_id()) :: tuple() | nil
  def container_key({:slot, id}, slot_id) when id == slot_id, do: {id, id}

  def container_key({:stack, _active, ids} = stack, slot_id) do
    if slot_id in ids, do: weight_key(stack), else: nil
  end

  def container_key({:division, _dir, children}, slot_id) do
    Enum.find_value(children, &container_key(&1, slot_id))
  end

  def container_key(_node, _slot_id), do: nil

  # Find the stack containing a slot ID
  defp find_containing_stack({:stack, _active, ids} = stack, slot_id) do
    if slot_id in ids, do: stack, else: nil
  end

  defp find_containing_stack({:division, _dir, children}, slot_id) do
    Enum.find_value(children, fn child -> find_containing_stack(child, slot_id) end)
  end

  defp find_containing_stack({:slot, id}, slot_id) do
    # A bare slot promoted to stack has one tab
    if id == slot_id, do: {:stack, id, [id]}, else: nil
  end

  defp find_containing_stack(_, _), do: nil

  # Find adjacent slot by walking the tree
  defp find_adjacent(tree, slot_id, direction) do
    # Find the division that contains the slot, then get the sibling
    axis = if direction in [:left, :right], do: :horizontal, else: :vertical
    seek = if direction in [:right, :down], do: :next, else: :prev

    find_sibling_in_division(tree, slot_id, axis, seek)
  end

  defp find_sibling_in_division({:division, dir, children}, slot_id, axis, seek) do
    if dir == axis do
      # This division's axis matches — look for the slot among children
      child_idx = Enum.find_index(children, fn child -> contains_slot?(child, slot_id) end)

      if child_idx do
        target_idx = if seek == :next, do: child_idx + 1, else: child_idx - 1

        if target_idx >= 0 and target_idx < length(children) do
          first_slot_in(Enum.at(children, target_idx))
        else
          nil
        end
      else
        nil
      end
    else
      # Wrong axis — recurse into children
      Enum.find_value(children, fn child ->
        find_sibling_in_division(child, slot_id, axis, seek)
      end)
    end
  end

  defp find_sibling_in_division(_, _, _, _), do: nil

  defp contains_slot?({:slot, id}, slot_id), do: id == slot_id
  defp contains_slot?({:stack, _active, ids}, slot_id), do: slot_id in ids

  defp contains_slot?({:division, _dir, children}, slot_id) do
    Enum.any?(children, fn child -> contains_slot?(child, slot_id) end)
  end

  defp contains_slot?(_, _), do: false

  defp first_slot_in({:slot, id}), do: id
  defp first_slot_in({:stack, active, _}), do: active
  defp first_slot_in({:division, _dir, [first | _]}), do: first_slot_in(first)
  defp first_slot_in(_), do: nil

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  @doc false
  def traverse_replace(node, mapper) do
    case mapper.(node) do
      ^node ->
        case node do
          {:division, dir, children} ->
            {:division, dir, Enum.map(children, &traverse_replace(&1, mapper))}

          {:stack, active, ids} ->
            {:stack, active, ids}

          _ ->
            node
        end

      replaced ->
        replaced
    end
  end

  @doc false
  def normalize(nil), do: nil
  def normalize({:slot, _} = node), do: node

  def normalize({:stack, _, [single_id]}), do: {:slot, single_id}
  def normalize({:stack, _, []}), do: nil
  def normalize({:stack, active, ids}), do: {:stack, active, ids}

  def normalize({:division, _, []}), do: nil
  def normalize({:division, _, [single]}), do: normalize(single)

  def normalize({:division, dir, children}) do
    normalized = Enum.map(children, &normalize/1) |> Enum.reject(&is_nil/1)

    case normalized do
      [] -> nil
      [single] -> single
      _ -> {:division, dir, normalized}
    end
  end

  def normalize(other), do: other
end
