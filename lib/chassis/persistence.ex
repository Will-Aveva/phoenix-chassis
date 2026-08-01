defmodule Chassis.Persistence do
  @moduledoc """
  Tree serialization and deserialization.

  Saves layout trees to an opaque format and restores them.
  The serialization format is private — not part of the public API (INV-5.3).
  Round-trip fidelity is guaranteed (INV-5.2).
  """

  @doc """
  Serialize a layout tree to an opaque binary format.
  """
  @spec save(Chassis.Layout.tree_node()) :: binary()
  def save(tree) do
    tree
    |> :erlang.term_to_binary()
  end

  @doc """
  Restore a layout tree from the serialized format.
  Returns `{:ok, tree}` or `{:error, reason}`.
  """
  @spec restore(binary()) :: {:ok, Chassis.Layout.tree_node()} | {:error, atom()}
  def restore(data) when is_binary(data) do
    tree = :erlang.binary_to_term(data, [:safe])
    {:ok, tree}
  rescue
    ArgumentError -> {:error, :invalid_format}
  end

  def restore(_), do: {:error, :invalid_format}

  @doc """
  Serialize a weights map to an opaque binary format.

  The map is keyed by `Chassis.Layout.weight_key/1` — a division child's two ends — rather than by a
  slot id, since one slot id names a child and every ancestor above it on the same edge.
  """
  @spec save_weights(map()) :: binary()
  def save_weights(weights) when is_map(weights) do
    :erlang.term_to_binary(weights)
  end

  @doc """
  Restore a weights map from the serialized format.
  Returns `{:ok, weights}` or `{:error, reason}`.
  """
  @spec restore_weights(binary()) :: {:ok, map()} | {:error, atom()}
  def restore_weights(data) when is_binary(data) do
    weights = :erlang.binary_to_term(data, [:safe])
    {:ok, weights}
  rescue
    ArgumentError -> {:error, :invalid_format}
  end

  def restore_weights(_), do: {:error, :invalid_format}
end
