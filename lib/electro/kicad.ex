defmodule Electro.Kicad do
  def load_file(file_path) do
    with {:ok, data} <- File.read(file_path) do
      load(data)
    else
      err -> err
    end
  end

  def load(data) do
    {components, _} =
      data
      |> String.split("\n")
      |> Enum.reduce({[], nil}, fn line, {components, current} ->
        case line do
          "$Comp" ->
            {components, %{fields: %{}}}

          "$EndComp" ->
            {[current | components], current}

          "F " <> field ->
            {components, parse_field(current, field)}

          _ ->
            {components, current}
        end
      end)

    {:ok, components}
  end

  defp parse_field(cpmt, field) do
    [field]
    |> Stream.map(& &1)
    |> CSV.decode(separator: ?\s)
    |> Enum.to_list()
    |> Enum.filter(fn {res, _} -> res == :ok end)
    |> Enum.reduce([], fn {:ok, els}, fields ->
      {_, field} =
        els
        |> Enum.reject(fn el -> el == "" end)
        |> Enum.reduce(
          {[
             :n,
             :txt,
             :orientation,
             :x,
             :y,
             :dimension,
             :visibility,
             :justify,
             :style,
             :name
           ], %{}},
          fn val, {names, field} ->
            [n | names] = names

            {names, Map.put(field, n, val)}
          end
        )

      [field | fields]
    end)
    |> Enum.reduce(cpmt, fn field, cpmt ->
      name =
        case field.n do
          "0" -> :ref
          "1" -> :val
          "2" -> :footprint
          "3" -> :user
          n -> field[:name] || n
        end

      fields =
        cpmt.fields
        |> Map.put(name, field.txt)

      Map.put(cpmt, :fields, fields)
    end)
  end
end
