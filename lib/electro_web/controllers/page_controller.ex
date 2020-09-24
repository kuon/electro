defmodule ElectroWeb.PageController do
  use ElectroWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
