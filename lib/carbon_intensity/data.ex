defmodule CarbonIntensity.Data do
  @moduledoc """
  Defined data structure to be passed internally between modules and functions
  """

  @derive {Jason.Encoder, only: [:from, :to, :actual]}
  defstruct [:from, :to, :actual]

  @type t() :: %CarbonIntensity.Data{
          from: NaiveDateTime.t(),
          to: NaiveDateTime.t(),
          actual: pos_integer()
        }
end
