defmodule Electro do
  @moduledoc """
  Electro keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def parts_in_category(
        %{
          parts: parts,
          part_index: part_index
        } = ac,
        id
      ) do
    Enum.reduce(part_index, [], fn {k, part}, res ->
      if part.category_id == id do
        [part | res]
      else
        res
      end
    end)
    |> Enum.sort_by(fn p -> p.path end)
    |> Enum.map(fn p -> p.id end)
  end

  def parts_with_query(_ac, nil), do: []
  def parts_with_query(_ac, ""), do: []

  def parts_with_query(
        %{
          parts: parts,
          part_index: part_index
        } = ac,
        query
      ) do
    Enum.reduce(part_index, [], fn {k, part}, res ->
      sim = case part.name do
        "" -> 0
        nil -> 0
        str -> FuzzyCompare.similarity(str, query)
      end

      if sim > 0.6 do
        [{sim, part} | res]
      else
        res
      end
    end)
    |> Enum.sort_by(fn {sim, p} -> sim end)
    |> Enum.map(fn {sim, p} -> p.id end)
    |> Enum.reverse()
  end

  def walk_inventory() do
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
            add_category(ac, path)
          end
        else
          if Path.extname(path) == ".toml" do
            add_part(ac, path)
          else
            ac
          end
        end
      end
    )
    |> consolidate
  end

  def contains_file?(path) do
    Path.wildcard("#{path}/*")
    |> Enum.any?(fn path ->
      File.regular?(path)
    end)
  end

  def add_category(
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

  def add_part(
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

    toml = toml
           |> Enum.map(fn {key, value} ->
             {String.to_atom(key), value}
           end)
           |> Map.new

    dir = Path.dirname(path)

    attachements = Path.wildcard("#{dir}/*.{pdf,png,jpg,jpeg}")
                   |> Enum.map(fn p ->
                     %{
                       path: p,
                       name: Path.basename(p)
                     }
                   end)

    part =
      %{
        name: part_name,
      }
      |> Map.merge(toml)
      |> Map.merge(%{
        path: path,
        category_id: Path.join(category) |> hash(),
        attachements: attachements
      })

    Map.merge(
      ac,
      %{
        part_index: Map.put(part_index, part.id, part),
        parts: [part.id | parts]
      }
    )
  end

  def consolidate(
        %{
          categories: categories,
          category_index: category_index,
          parts: parts,
          part_index: part_index
        } = ac
      ) do

    next_id = Enum.reduce(part_index, 0, fn {_, p}, n ->
      max(n, p.id)
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
    :crypto.hash(:sha256, str) |> Base.encode16()
  end
end
