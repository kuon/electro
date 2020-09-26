defmodule Electro.Inventory do
  use GenServer

  @name {:global, :electro_inventory}

  # Client (API)
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def reload() do
    GenServer.call(@name, :reload)
  end

  def inventory() do
    GenServer.call(@name, :inventory)
  end

  def category(cat_id) do
    GenServer.call(@name, {:category, cat_id})
  end

  def categories() do
    GenServer.call(@name, :categories)
  end

  def parts_in_category(cat_id) do
    GenServer.call(@name, {:parts_in_category, cat_id})
  end

  def parts_with_query(nil), do: []
  def parts_with_query(""), do: []

  def parts_with_query(query) do
    GenServer.call(@name, {:parts_with_query, query})
  end

  def part_with_id(id) when is_binary(id) do
    part_with_id(String.to_integer(id))
  end

  def part_with_id(id) do
    GenServer.call(@name, {:part_with_id, id})
  end

  def next_id() do
    GenServer.call(@name, :next_id)
  end

  def create_part(part) do
    GenServer.call(@name, {:create_part, part})
  end

  def save_part(part) do
    GenServer.call(@name, {:save_part, part})
  end

  # Server (callbacks)
  @impl true
  def init(_args) do
    {:ok, do_walk()}
  end

  @impl true
  def handle_call(:reload, _, _) do
    {:reply, :ok, do_walk()}
  end

  @impl true
  def handle_call(:inventory, _from, inventory) do
    {:reply, inventory, inventory}
  end

  @impl true
  def handle_call(:next_id, _from, inventory) do
    {:reply, inventory.next_id, inventory}
  end

  @impl true
  def handle_call(
        {:part_with_id, id},
        _from,
        %{
          part_index: part_index
        } = inventory
      ) do
    part = Map.get(part_index, id)
    {:reply, part, inventory}
  end

  @impl true
  def handle_call(
        {:category, cat_id},
        _from,
        %{
          category_index: category_index
        } = inventory
      ) do
    cat = Map.get(category_index, cat_id)
    {:reply, cat, inventory}
  end

  @impl true
  def handle_call(
        :categories,
        _from,
        %{
          category_index: category_index
        } = inventory
      ) do
        categories =
        category_index
        |> Map.values()
        |> Enum.sort_by(fn cat ->
          cat.path
        end)
    {:reply, categories, inventory}
  end

  @impl true
  def handle_call(
        {:parts_in_category, cat_id},
        _from,
        %{
          parts: parts,
          part_index: part_index
        } = inventory
      ) do
    Enum.reduce(part_index, [], fn {k, part}, res ->
      if part.category_id == cat_id do
        [part | res]
      else
        res
      end
    end)
    |> Enum.sort_by(fn p -> p.path end)
    |> (&{:reply, &1, inventory}).()
  end

  @impl true
  def handle_call(
        {:parts_with_query, query},
        _from,
        %{
          parts: parts,
          part_index: part_index
        } = inventory
      ) do
    Enum.reduce(part_index, [], fn {k, part}, res ->

      sim = 
        (
        case part.name do
          "" -> 0
          nil -> 0
          str -> FuzzyCompare.similarity(str, query)
        end
        ) +
        (
        case part.mpn do
          "" -> 0
          nil -> 0
          str -> FuzzyCompare.similarity(str, query)
        end
        ) +
        (
          if query == to_string(part.id) do
            100
          else
            0
          end
        )


      if sim > 1 do
        [{sim, part} | res]
      else
        res
      end
    end)
    |> Enum.sort_by(fn {sim, p} -> sim end)
    |> Enum.map(fn {sim, p} -> p end)
    |> Enum.reverse()
    |> (&{:reply, &1, inventory}).()
  end

  @impl true
  def handle_call({:create_part, part}, _from, inventory) do
    {:ok, inventory, part} = do_save_part(inventory, part)
    {:reply, {:ok, part}, inventory}
  end

  @impl true
  def handle_call({:save_part, part}, _from, inventory) do
    {:ok, inventory, part} = do_save_part(inventory, part)
    {:reply, {:ok, part}, inventory}
  end

  def do_save_part(inventory, part) do
    cat = Map.get(inventory.category_index, part.category_id)

    dir_path = Path.join(cat.path, escape_path(part.name))
    File.mkdir_p!(dir_path)

    toml_path = Path.join(dir_path, "part.toml")

    is_update = File.exists?(toml_path)

    part =
      if is_update do
        {:ok, toml} = Toml.decode_file(toml_path)

        Map.merge(part, %{
          id: toml["id"],
          path: toml_path
        })
      else
        Map.merge(part, %{
          path: toml_path
        })
      end
      |> do_download_documents()

    toml = Phoenix.View.render(ElectroWeb.PartView, "part.toml", part: part)

    File.write!(toml_path, toml)

    inventory =
      if is_update do
        Map.merge(inventory, %{
          part_index: Map.put(inventory.part_index, part.id, part)
        })
      else
        do_add_part(inventory, toml_path)
        |> Map.merge(%{
          next_id: inventory.next_id + 1
        })
      end

    {:ok, inventory, part}
  end

  defp do_download_documents(part) do
    docs =
      part.documents
      |> Enum.map(fn doc ->
        case doc do
          %{name: name, url: url} ->
            dir = Path.dirname(part.path)

            # TODO stream download
            HTTPoison.get(url, [], follow_redirect: true)
            |> case do
              {:ok, %{status_code: 200, body: body, headers: headers}} ->
                filename =
                  with {_, disp} when not is_nil(disp) <-
                         Enum.find(headers, fn {k, v} ->
                           k == "Content-Disposition"
                         end),
                       [_, filename] <- Regex.run(~r/filename="(.+)"/, disp) do
                    filename
                  else
                    _ -> Path.basename(url)
                  end

                path = Path.join(dir, filename)
                File.write!(path, body)
                nil

              _ ->
                nil
            end

          %{name: name, path: path} ->
            doc
        end
      end)
      |> Enum.reject(&is_nil/1)

    Map.put(part, :documents, docs)
  end

  defp do_walk() do
    inv_path = Application.get_env(:electro, :inventory_path)
    parts_path = "#{inv_path}/parts"

    Path.wildcard("#{parts_path}/**/*")
    |> Enum.reduce(
      %{
        base_depth: Path.split(parts_path) |> length,
        categories: [],
        category_index: %{},
        parts: [],
        part_index: %{}
      },
      fn path, ac ->
        rpath = Path.relative_to(path, parts_path)

        if File.dir?(path) do
          if contains_file?(path) do
            ac
          else
            do_add_category(ac, path)
          end
        else
          if Path.extname(path) == ".toml" do
            do_add_part(ac, path)
          else
            ac
          end
        end
      end
    )
    |> do_consolidate
  end

  defp contains_file?(path) do
    Path.wildcard("#{path}/*")
    |> Enum.any?(fn path ->
      File.regular?(path)
    end)
  end

  defp do_add_category(
         %{
           base_depth: base_depth,
           categories: categories,
           category_index: category_index,
           parts: parts,
           part_index: part_index
         } = ac,
         path
       ) do
    {parents, [name]} =
      Path.split(path)
      |> Enum.split(-1)

    parent = Path.join(parents)

    cat = %{
      id: path |> hash(),
      name: name,
      parent: parent,
      path: path,
      depth: length(parents) - base_depth
    }

    Map.merge(
      ac,
      %{
        category_index: Map.put(category_index, cat.id, cat),
        categories: [cat.id | categories]
      }
    )
  end

  defp do_add_part(
         %{
           categories: categories,
           category_index: category_index,
           parts: parts,
           part_index: part_index
         } = ac,
         path
       ) do
    {category, [part_name, _]} =
      Path.split(path)
      |> Enum.split(-2)

    {:ok, toml} = Toml.decode_file(path)

    toml =
      toml
      |> Enum.map(fn {key, value} ->
        {String.to_atom(key), value}
      end)
      |> Map.new()

    dir = Path.dirname(path)

    documents =
      Path.wildcard("#{dir}/*.{pdf,png,jpg,jpeg}")
      |> Enum.map(fn p ->
        %{
          path: p,
          name: Path.basename(p)
        }
      end)

    part =
      %{
        name: part_name
      }
      |> Map.merge(toml)
      |> Map.merge(%{
        path: path,
        category_id: Path.join(category) |> hash(),
        documents: documents
      })

    Map.merge(
      ac,
      %{
        part_index: Map.put(part_index, part.id, part),
        parts: [part.id | parts]
      }
    )
  end

  defp do_consolidate(
         %{
           categories: categories,
           category_index: category_index,
           parts: parts,
           part_index: part_index
         } = ac
       ) do
    next_id =
      Enum.reduce(part_index, 0, fn {_, p}, n ->
        max(n, p.id + 1)
      end)

    Map.merge(
      ac,
      %{
        categories:
          Enum.sort_by(categories, fn c -> category_index[c].path end),
        parts: Enum.sort(parts),
        next_id: next_id
      }
    )
  end

  defp hash(str) do
    :crypto.hash(:md5, str) |> Base.url_encode64(padding: false)
  end

  def escape_path(str) do
    String.replace(str, ~r([/\\]), "-")
  end
end
