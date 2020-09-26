defmodule ElectroWeb.ExecController do
  use ElectroWeb, :controller
  alias Electro.Inventory

  def reload(conn, _params) do
    :ok = Inventory.reload()
    redirect(conn, to: "/")
  end
end
