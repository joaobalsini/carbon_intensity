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
    with {:ok, %{"data" => [result]}} <- load_actual() do
      parse_result(result)
    end
  end

  defp parse_result(%{"from" => from, "to" => to, "intensity" => %{"actual" => actual}}) do
    {:ok, %{from: from, to: to, actual_intensity: actual}}
  end

  defp parse_result(_other), do: {:error, :malformed}

  defp load_actual(), do: load_url(@api_url)

  defp load_url(url, actual_retry \\ 0)

  defp load_url(url, actual_retry)
       when actual_retry < @number_of_retries do
    response = Mojito.request(:get, url)

    case response do
      {:ok, %{status_code: 200, body: body}} ->
        Jason.decode(body)

      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {_, _response} ->
        load_url(url, actual_retry + 1)
    end
  end

  defp load_url(_url, actual_retry) when actual_retry == @number_of_retries,
    do: {:error, :request_error}
end
