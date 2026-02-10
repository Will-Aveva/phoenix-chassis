defmodule ChassisWeb.Components.Sidebar do
  @moduledoc """
  Structural sidebar component.

  Provides an activity bar and sidebar panel structure.
  Content is provided by the consuming application via slots — no content awareness.
  All styling via `--chassis-*` CSS custom properties.
  """
  use Phoenix.Component

  @doc """
  Render a sidebar with activity bar and content panel.

  ## Slots
  - `activity_bar` — items for the vertical icon bar
  - `inner_block` — content for the sidebar panel
  """
  slot :activity_bar
  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="chassis-sidebar">
      <div class="chassis-activity-bar">{render_slot(@activity_bar)}</div>
      
      <div class="chassis-sidebar-panel">{render_slot(@inner_block)}</div>
    </div>
    """
  end
end
