defmodule CarbonIntensity.Influxdb.Connection do
  @moduledoc """
  Defines the connection to InfluxDB
  """

  use Instream.Connection, otp_app: :carbon_intensity
end
