defmodule CarbonIntensity.InfluxdbSerie do
  use Instream.Series

  series do
    database("carbon_intensity")
    measurement("actual_value")

    field(:actual_value)
  end
end
