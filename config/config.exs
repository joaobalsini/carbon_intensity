use Mix.Config

config :carbon_intensity, :client, CarbonIntensity.ClientImplementation

config :carbon_intensity, CarbonIntensity.Influxdb.Connection,
  database: "carbon_intensity",
  host: "localhost",
  auth: [method: :basic, username: "influxdb", password: "influxdb"],
  # , proxy: "http://company.proxy"],
  http_opts: [insecure: true],
  pool: [max_overflow: 10, size: 50],
  port: 8086,
  scheme: "http",
  writer: Instream.Writer.Line

case Mix.env() do
  :test -> import_config "test.exs"
  _other -> nil
end
