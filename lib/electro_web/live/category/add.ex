defmodule ElectroWeb.CategoryLive.Add do
  use Phoenix.LiveView,
    container: {:div, class: "max-h-full flex w-full max-w-full h-full"}

  alias ElectroWeb.CategoryView
  alias Electro.Inventory
  alias ElectroWeb.Router.Helpers, as: Routes

  def render(assigns), do: CategoryView.render("add.html", assigns)

  def init(socket) do
    assign(socket,
      category: nil
    )
  end

  def mount(_params, _, socket) do
    inv = Inventory.inventory()
    {:ok, assign(init(socket), inv)}
  end

  def handle_params(%{"cat_id" => cat_id}, _url, socket) do
    cat = Inventory.category(cat_id)
    {:noreply, assign(socket, category: cat)}
  end

  def handle_event("browse", _, socket) do
    path = Routes.part_index_path(socket, :index)
    {:noreply, redirect(socket, to: path)}
  end

  def handle_event("create_category", %{"category" => params}, socket) do
    cat =
      Inventory.create_category(
        socket.assigns.category,
        params["name"]
      )

    path = Routes.part_index_path(socket, :index)
    {:noreply, redirect(socket, to: path)}
  end
end
