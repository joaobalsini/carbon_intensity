use Mix.Config

config :carbon_intensity, :client, CarbonIntensity.ClientImplementation

case Mix.env() do
  :test -> import_config "test.exs"
  _other -> nil
end
