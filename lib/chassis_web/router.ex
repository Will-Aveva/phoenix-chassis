defmodule ChassisWeb.Router do
  use ChassisWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChassisWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChassisWeb do
    pipe_through :browser

    live "/", DemoLive
    get "/home", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChassisWeb do
  #   pipe_through :api
  # end
end
