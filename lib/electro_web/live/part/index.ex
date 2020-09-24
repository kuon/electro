defmodule ElectroWeb.PartLive.Index do
  use Phoenix.LiveView,
    container: {:div, class: "max-h-full flex w-full max-w-full h-full"}

  alias ElectroWeb.PartView

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
    inv = Electro.walk_inventory()
    {:ok, assign(init(socket), inv)}
  end

  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("select_category", %{"id" => id}, socket) do
    res = Electro.parts_in_category(socket.assigns, id)

    {:noreply,
     assign(socket, selected_category_id: id, results: res, query: nil)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    res = Electro.parts_with_query(socket.assigns, q)

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
end
