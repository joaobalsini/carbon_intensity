defmodule CarbonIntensity.Influxdb.Client do
  @moduledoc """
  Manages data storing into the Influxdb database
  """

  @spec store(CarbonIntensity.Data.t()) :: term()
  def store(%CarbonIntensity.Data{} = data) do
    data
    |> create_influxdb_data()
    |> CarbonIntensity.Influxdb.Connection.write()
  end

  @spec store_multiple([CarbonIntensity.Data.t()]) :: term()
  def store_multiple(list) do
    list
    |> Enum.map(&create_influxdb_data/1)
    |> CarbonIntensity.Influxdb.Connection.write()
  end

  defp create_influxdb_data(%CarbonIntensity.Data{to: time, actual: actual_value}) do
    timestamp =
      time
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix(:microsecond)

    data = %CarbonIntensity.Influxdb.Serie{}

    # convert timestamp to nanosecond
    data = %{data | timestamp: timestamp * 1000}
    %{data | fields: %{data.fields | actual_value: actual_value}}
  end
end
