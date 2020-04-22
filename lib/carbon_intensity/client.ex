defmodule CarbonIntensity.Client do
  @type query_error :: :not_found | :request_error | Jason.DecodeError.t()
  @type error :: query_error | :malformed
  @type data :: %{from: binary(), to: binary(), actual_intensity: pos_integer()}

  @callback actual() :: {:error, error()} | {:ok, data()}
end
