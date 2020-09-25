defmodule Electro.Octopart do
  require Logger

  @api_url "https://octopart.com/api/v4/endpoint"

  def api_query(q, limit) do
    """
    query {
      search(q: "#{q}", limit: #{limit}) {
        results {
          part {
            mpn
            manufacturer {
              name
            }
            descriptions {
              text
            }
            document_collections {
              name
              documents {
                url
                name
              }
            }
            specs {
              display_value
              attribute {
                name
              }
            }
          }
        }
      }
    }
    """
  end

  def search(""), do: {:ok, []}
  def search(nil), do: {:ok, []}

  def search(query, limit \\ 5) do
    token = Application.get_env(:electro, :octopart_token)

    if token == nil || token == "" do
      {:error, :no_token}
    else
      query = Jason.encode!(%{query: api_query(query, limit)})

      headers = [
        {"Token", token},
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ]

      HTTPoison.post(@api_url, query, headers)
      |> case do
        {:ok, %{status_code: 200, body: body}} ->
          body = Jason.decode!(body)
          {:ok, map_results(body)}

        {:ok, res} ->
          Logger.error("Invalid API result")
          Logger.error(inspect(res))
          {:error, :invalid_result}

        {:error, err} = res ->
          Logger.error("HTTP error")
          Logger.error(inspect(err))
          {:error, :http_error}
      end
    end
  end

  defp map_results(%{"data" => %{"search" => %{"results" => results}}}) do
    results
    |> Enum.map(fn %{"part" => part} ->
      %{
        mpn: part["mpn"],
        name: part["mpn"],
        description: part["descriptions"] |> Enum.map(& &1["text"]) |> hd,
        manufacturer: part["manufacturer"]["name"],
        specs:
          part["specs"]
          |> Enum.map(fn %{
                           "attribute" => %{"name" => key},
                           "display_value" => value
                         } ->
            {key, value}
          end)
          |> Map.new(),
        documents:
          [part["best_datasheet"]]
          |> Enum.reject(&is_nil/1)
          |> Enum.map(fn %{"name" => name, "url" => url} ->
            %{name: name, url: url}
          end)
      }
    end)
  end

  defp map_results(_), do: []
end
