defmodule CarbonIntensity.ClientImplementation do
  @moduledoc """
  Loads data from Carbon Intensity API

  https://api.carbonintensity.org.uk/intensity
  """

  @behaviour CarbonIntensity.Client

  @actual_url "https://api.carbonintensity.org.uk/intensity"
  @number_of_retries 5

  @impl true
  @spec actual ::
          {:error, CarbonIntensity.Client.error()}
          | {:ok, CarbonIntensity.Client.data()}
  def actual do
    with {:ok, query_result} <- load_actual() do
      parse_result(query_result)
    end
  end

  @spec parse_result(map()) ::
          {:error, :malformed}
          | {:ok, CarbonIntensity.Client.data()}
  def parse_result(%{
        "data" => [
          %{"from" => _from, "to" => _to, "intensity" => %{"actual" => actual}} = result
        ]
      })
      when is_integer(actual),
      do: do_parse(result)

  def parse_result(_other), do: {:error, :malformed}

  @spec parse_results(map()) ::
          {:error, :malformed}
          | {:ok, [CarbonIntensity.Client.data()]}
  def parse_results(%{
        "data" => list
      })
      when is_list(list) and length(list) > 1 do
    results =
      Enum.map(list, &do_parse/1)
      |> Enum.reject(&(&1 == {:error, :malformed}))
      |> Enum.map(&elem(&1, 1))

    {:ok, results}
  end

  defp do_parse(%{"from" => from, "to" => to, "intensity" => %{"actual" => actual}}) do
    with {:ok, from_date} <- NaiveDateTime.from_iso8601(prepare_date_string_to_be_parsed(from)),
         {:ok, to_date} <- NaiveDateTime.from_iso8601(prepare_date_string_to_be_parsed(to)) do
      {:ok, %CarbonIntensity.Data{from: from_date, to: to_date, actual: actual}}
    else
      _e ->
        {:error, :malformed}
    end
  end

  @spec process_response(term) ::
          {:error, CarbonIntensity.Client.query_error()} | {:ok, map()}
  def process_response({:ok, %{status_code: 200, body: body}}),
    do: Jason.decode(body)

  def process_response({:ok, %{status_code: 404}}), do: {:error, :not_found}

  def process_response(_other), do: {:error, :request_error}

  @impl true
  @spec previous(CarbonIntensity.Client.url()) ::
          {:error, CarbonIntensity.Client.error()}
          | {:ok, [CarbonIntensity.Client.data()]}
  def previous(query_url) do
    with {:ok, query_result} <- load_previous(query_url) do
      parse_results(query_result)
    end
  end

  defp prepare_date_string_to_be_parsed(date_string), do: String.replace(date_string, "Z", ":00")

  defp load_actual(actual_retry \\ 0)

  defp load_actual(actual_retry) when actual_retry < @number_of_retries do
    load_url(@actual_url)
    |> process_response()
    |> case do
      {:error, :request_error} -> load_actual(actual_retry + 1)
      other -> other
    end
  end

  defp load_previous(query_url, actual_retry \\ 0)

  defp load_previous(query_url, actual_retry) when actual_retry < @number_of_retries do
    query_url
    |> load_url()
    |> process_response()
    |> case do
      {:error, :request_error} -> load_previous(query_url, actual_retry + 1)
      other -> other
    end
  end

  defp load_previous(_query_url, _actual_retry), do: {:error, :request_error}

  defp load_url(url), do: Mojito.request(:get, url)
end
