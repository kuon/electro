defmodule ElectroWeb.PartLive.Add do
  use Phoenix.LiveView,
    container: {:div, class: "max-h-full flex w-full max-w-full h-full"}

  alias ElectroWeb.PartView
  alias Electro.Inventory
  alias Electro.Octopart
  alias ElectroWeb.Router.Helpers, as: Routes

  def render(assigns), do: PartView.render("add.html", assigns)

  def init(socket) do
    assign(socket,
      category: nil,
      query: nil,
      results: [],
      selected_idx: nil,
      new_part: %{},
      page: :search
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
    if socket.assigns.page == :search do
      path = Routes.part_index_path(socket, :index)
      {:noreply, redirect(socket, to: path)}
    else
      {:noreply, assign(socket, page: :search)}
    end
  end

  def handle_event("search", %{"q" => q} = params, socket) do
    {:ok, res} = Octopart.search(q)
    {:noreply, assign(socket, results: res, query: q)}
  end

  def handle_event("set_query", %{"q" => q}, socket) do
    {:noreply, assign(socket, query: q)}
  end

  def handle_event("new_part", _, socket) do
    {:noreply,
     assign(socket,
       page: :form,
       new_part:
         Map.merge(new_part(), %{
           name: socket.assigns.query,
           mpn: socket.assigns.query
         })
     )}
  end

  def handle_event("select", %{"idx" => idx}, socket) do
    {:noreply, assign(socket, selected_idx: String.to_integer(idx))}
  end

  def handle_event("use_part", _, socket) do
    {:noreply,
     assign(socket,
       page: :form,
       new_part:
         Map.merge(
           new_part(),
           socket.assigns.results
           |> Enum.at(socket.assigns.selected_idx)
         )
     )}
  end

  def handle_event("create_part", %{"part" => params}, socket) do
    part =
      socket.assigns.new_part
      |> Map.merge(%{
        category_id: socket.assigns.category.id,
        name: params["name"],
        mpn: params["mpn"],
        location: params["location"],
        description: params["description"],
        stock: params["stock"]
      })

    {:ok, part} = Inventory.create_part(part)

    Electro.Pdf.print_label(part)

    path = Routes.part_index_path(socket, :index)
    {:noreply, redirect(socket, to: path)}
  end

  defp new_part() do
    %{
      id: Inventory.next_id(),
      name: "",
      mpn: "",
      location: "",
      description: "",
      stock: ""
    }
  end
end
