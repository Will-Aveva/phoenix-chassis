defmodule ChassisWeb.Components.DockPanel do
  @moduledoc """
  Collapsible dock panel component (side or bottom).

  Content is provided by the consuming application via `inner_block` slot.
  All styling via `--chassis-*` CSS custom properties.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :side, :atom, values: [:right, :bottom], required: true
  attr :title, :string, default: "Panel"
  attr :collapsed, :boolean, default: false
  attr :width, :string, default: "300px"
  attr :height, :string, default: "200px"
  attr :on_toggle, :string, required: true
  slot :inner_block, required: true

  def dock_panel(assigns) do
    ~H"""
    <div
      id={@id}
      class={"chassis-dock-panel #{@side} #{if @collapsed, do: "collapsed"}"}
      style={panel_style(@side, @collapsed, @width, @height)}
    >
      <div class="chassis-dock-header">
        <span>{@title}</span> <button phx-click={@on_toggle} title={"Close #{@title}"}>×</button>
      </div>
      
      <div class="chassis-dock-content">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  defp panel_style(:right, false, width, _), do: "width: #{width};"
  defp panel_style(:right, true, _, _), do: ""
  defp panel_style(:bottom, false, _, height), do: "height: #{height};"
  defp panel_style(:bottom, true, _, _), do: ""
end
