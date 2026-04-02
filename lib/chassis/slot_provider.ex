defmodule Chassis.SlotProvider do
  @moduledoc """
  Behaviour defining the contract between Chassis and consuming applications
  for slot rendering and tab chrome.

  Consuming applications implement this behaviour to tell Chassis how to render
  each slot's content and tab appearance. Chassis invokes these callbacks with
  only the slot ID — it never inspects or branches on the return values (INV-9.2).

  ## Required Callbacks

    * `render_content/2` — Render the content area for a slot
    * `tab_label/1` — Provide the text label for a tab

  ## Optional Callbacks

    * `tab_icon/1` — Provide an icon identifier for a tab (default: `nil`)
    * `closable?/1` — Whether the user can close this tab (default: `true`)

  ## Example

      defmodule MyApp.SlotProvider do
        use Chassis.SlotProvider

        @impl true
        def render_content(:editor, assigns), do: ~H"<.code_editor />"
        def render_content(:terminal, assigns), do: ~H"<.terminal />"

        @impl true
        def tab_label(:editor), do: "Editor"
        def tab_label(:terminal), do: "Terminal"

        @impl true
        def tab_icon(:editor), do: "code"
        def tab_icon(_), do: nil
      end
  """

  @doc "Render the content area for this slot."
  @callback render_content(slot_id :: term(), assigns :: map()) ::
              Phoenix.LiveView.Rendered.t()

  @doc "Provide the text label for a tab."
  @callback tab_label(slot_id :: term(), assigns :: map()) :: String.t()

  @doc "Provide an icon identifier for a tab. Returns nil for no icon."
  @callback tab_icon(slot_id :: term()) :: String.t() | nil

  @doc "Provide the tab position."
  @callback tab_position(slot_id :: term()) :: atom()

  @doc "Whether the user can close this tab."
  @callback closable?(slot_id :: term()) :: boolean()

  @optional_callbacks [tab_icon: 1, tab_position: 1, closable?: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour Chassis.SlotProvider

      @doc false
      def tab_icon(_slot_id), do: nil

      @doc false
      def tab_position(_slot_id), do: :top

      @doc false
      def closable?(_slot_id), do: true

      defoverridable tab_icon: 1, tab_position: 1, closable?: 1
    end
  end
end
