defmodule Chassis.PersistenceBackend do
  @moduledoc """
  Behaviour defining the contract for layout state storage.

  Consuming applications implement this behaviour to provide a storage mechanism
  for persisted layout trees. The backend operates on opaque binaries produced
  by `Chassis.Persistence.save/1` — it MUST NOT interpret, parse, or transform
  the binary content (INV-9.6).

  ## Callbacks

    * `save_layout/2` — Persist serialized tree data for a composition
    * `load_layout/1` — Retrieve serialized tree data for a composition

  ## Optional Callbacks (§2.5, INV-5.5)

    * `save_weights/2` — Persist serialized weight data for a composition
    * `load_weights/1` — Retrieve serialized weight data for a composition

  Backends that omit weight callbacks degrade gracefully to equal sizing.

  ## Example

      defmodule MyApp.FileLayoutStore do
        @behaviour Chassis.PersistenceBackend

        @impl true
        def save_layout(composition, data) do
          path = Path.join("priv/layouts", "\#{composition}.bin")
          File.write(path, data)
        end

        @impl true
        def load_layout(composition) do
          path = Path.join("priv/layouts", "\#{composition}.bin")
          case File.read(path) do
            {:ok, data} -> {:ok, data}
            {:error, :enoent} -> {:error, :not_found}
          end
        end
      end
  """

  @doc "Persist serialized tree data for a composition."
  @callback save_layout(composition :: atom(), data :: binary()) ::
              :ok | {:error, term()}

  @doc "Retrieve serialized tree data for a composition."
  @callback load_layout(composition :: atom()) ::
              {:ok, binary()} | {:error, term()}

  @doc "Persist serialized weight data for a composition (optional, §2.5)."
  @callback save_weights(composition :: atom(), data :: binary()) ::
              :ok | {:error, term()}

  @doc "Retrieve serialized weight data for a composition (optional, §2.5)."
  @callback load_weights(composition :: atom()) ::
              {:ok, binary()} | {:error, term()}

  @optional_callbacks save_weights: 2, load_weights: 1
end
