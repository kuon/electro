defmodule ElectroWeb.PartLive.Index do
  use Phoenix.LiveView,
    container: {:div, class: "max-h-full flex w-full max-w-full h-full"}

  alias ElectroWeb.Router.Helpers, as: Routes

  alias ElectroWeb.PartView
  alias Electro.Inventory
  alias Electro.Octopart

  def render(assigns), do: PartView.render("index.html", assigns)

  def init(socket) do
    assign(socket,
      results: [],
      selected_category_id: nil,
      query: nil,
      selected_part_id: nil
    )
  end

  def mount(_params, _, socket) do
    inv = Inventory.inventory()
    {:ok, assign(init(socket), inv)}
  end

  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("select_category", %{"id" => id}, socket) do
    res = Inventory.parts_in_category(id)

    {:noreply,
     assign(socket, selected_category_id: id, results: res, query: nil)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    res = Inventory.parts_with_query(q)

    {:noreply,
     assign(socket, selected_category_id: nil, results: res, query: q)}
  end

  def handle_event("select_part", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_part_id: String.to_integer(id))}
  end

  def handle_event("open_file", %{"path" => path}, socket) do
    {:ok, path} = Base.decode64(path)
    System.cmd("rifle", [path])
    {:noreply, socket}
  end

  def handle_event("add_part", _, socket) do
    path =
      Routes.part_add_path(socket, :index, socket.assigns.selected_category_id)

    {:noreply, redirect(socket, to: path)}
  end

  def handle_event("add_category", _, socket) do
    {:noreply, redirect(socket, to: "/add")}
  end
end
