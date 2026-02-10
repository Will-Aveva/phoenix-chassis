defmodule ChassisWeb.PageController do
  use ChassisWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
