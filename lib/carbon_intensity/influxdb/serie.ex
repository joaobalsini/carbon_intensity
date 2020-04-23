defmodule CarbonIntensity.Influxdb.Serie do
  @moduledoc """
  Serie definition for storing data correctly on InfluxDB
  """

  use Instream.Series

  series do
    database("carbon_intensity")
    measurement("actual_value")

    field(:actual_value)
  end
end
