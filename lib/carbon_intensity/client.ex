defmodule CarbonIntensity.Client do
  @moduledoc """
  Defined client behavior, implemented that so we are able to mock the calls on future tests.
  """

  @type query_error :: :not_found | :request_error | Jason.DecodeError.t()
  @type error :: query_error | :malformed
  @type data :: %{from: NaiveDateTime.t(), to: NaiveDateTime.t(), actual_intensity: integer()}

  @callback actual() :: {:error, error()} | {:ok, data()}
end
