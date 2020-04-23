defmodule CarbonIntensity.Influxdb.Client do
  @moduledoc """
  Manages data storing into the Influxdb database
  """

  @spec store(CarbonIntensity.Data.t()) :: term()
  def store(%CarbonIntensity.Data{to: time, actual: actual_value}) do
    timestamp =
      time
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix(:microsecond)

    data = %CarbonIntensity.Influxdb.Serie{}

    # convert timestamp to nanosecond
    data = %{data | timestamp: timestamp * 1000}
    data = %{data | fields: %{data.fields | actual_value: actual_value}}

    CarbonIntensity.Influxdb.Connection.write(data)
  end
end
