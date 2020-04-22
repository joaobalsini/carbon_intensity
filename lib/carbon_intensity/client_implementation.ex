defmodule CarbonIntensity.ClientImplementation do
  @moduledoc """
  Loads data from Carbon Intensity API

  https://api.carbonintensity.org.uk/intensity
  """

  @behaviour CarbonIntensity.Client

  @api_url "https://api.carbonintensity.org.uk/intensity"
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
          %{"from" => from, "to" => to, "intensity" => %{"actual" => actual}}
        ]
      })
      when is_integer(actual) do
    with {:ok, from_date} <- NaiveDateTime.from_iso8601(prepare_date_string_to_be_parsed(from)),
         {:ok, to_date} <- NaiveDateTime.from_iso8601(prepare_date_string_to_be_parsed(to)) do
      {:ok, %{from: from_date, to: to_date, actual_intensity: actual}}
    else
      _e ->
        {:error, :malformed}
    end
  end

  def parse_result(_other), do: {:error, :malformed}

  @spec process_response(term) ::
          {:error, CarbonIntensity.Client.query_error()} | {:ok, map()}
  def process_response({:ok, %{status_code: 200, body: body}}),
    do: Jason.decode(body)

  def process_response({:ok, %{status_code: 404}}), do: {:error, :not_found}

  def process_response(_other), do: {:error, :request_error}

  defp prepare_date_string_to_be_parsed(date_string), do: String.replace(date_string, "Z", ":00")

  defp load_actual(actual_retry \\ 0)

  defp load_actual(actual_retry) when actual_retry < @number_of_retries do
    load_url(@api_url)
    |> process_response()
    |> case do
      {:error, :request_error} -> load_actual(actual_retry + 1)
      other -> other
    end
  end

  defp load_actual(_actual_retry), do: {:error, :request_error}

  defp load_url(url), do: Mojito.request(:get, url)
end
