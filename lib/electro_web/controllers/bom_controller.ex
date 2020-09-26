defmodule ElectroWeb.BomController do
  use ElectroWeb, :controller
  alias Electro.Inventory

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def upload(conn, %{"file" => file}) do
    {:ok, components} = Electro.Kicad.load_file(file.path)

    groups =
      components
      |> Enum.group_by(fn cp ->
        cp.fields["IPN"]
      end)
      |> Map.delete(nil)
      |> Enum.map(fn {ipn, els} ->
        ipn = String.to_integer(ipn)
        part = Inventory.part_with_id(ipn)
        {ipn, %{
          count: length(els),
          location: part.location,
          components: els,
          name: part.name,
          mpn: part.mpn
        }}
      end)
      |> Enum.sort_by(fn {_, %{location: l}} ->
        l
      end)

    render(conn, "show.html", groups: groups)
  end
end
