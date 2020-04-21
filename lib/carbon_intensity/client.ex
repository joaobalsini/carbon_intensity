defmodule CarbonIntensity.Client do
  @type error :: :not_found | :request_error | :malformed
  @type data :: %{from: binary(), to: binary(), actual_intensity: pos_integer()}

  @callback actual() :: {:error, error()} | {:ok, data}
end
