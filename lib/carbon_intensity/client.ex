defmodule CarbonIntensity.Client do
  @moduledoc """
  Defined client behavior, implemented that so we are able to mock the calls on future tests.
  """

  @type query_error :: :not_found | :request_error | Jason.DecodeError.t()
  @type error :: query_error | :malformed
  @type data :: CarbonIntensity.Data.t()
  @type url :: binary()

  @callback actual() :: {:error, error()} | {:ok, data()}
  @callback previous(url()) :: {:error, error()} | {:ok, [data()]}
end
