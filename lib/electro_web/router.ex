defmodule ElectroWeb.Router do
  use ElectroWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {ElectroWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElectroWeb do
    pipe_through :browser

    live "/", PartLive.Index, :index
    live "/c/:cat_id/add", PartLive.Add, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElectroWeb do
  #   pipe_through :api
  # end
end
