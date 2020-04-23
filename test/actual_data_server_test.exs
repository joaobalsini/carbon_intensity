defmodule CarbonIntensity.ActualDataServerTest do
  use ExUnit.Case

  describe "calculate_next_refresh/2" do
    test "Calculates next refresh correctly" do
      {:ok, base_date} = NaiveDateTime.new(2020, 01, 01, 0, 30, 30)
      interval = 30

      # the interval should be 30 minutes times 60_000 miliseconds
      assert CarbonIntensity.ActualDataServer.calculate_next_refresh(base_date, interval) ==
               30 * 60_000

      {:ok, base_date} = NaiveDateTime.new(2020, 01, 01, 0, 30, 0)
      interval = 30

      # the interval should be 30 minutes times 60_000 miliseconds + 30_000 miliseconds (30 seconds we add to avoid clock sync issues)
      assert CarbonIntensity.ActualDataServer.calculate_next_refresh(base_date, interval) ==
               30 * 60_000 + 30_000

      {:ok, base_date} = NaiveDateTime.new(2020, 01, 01, 0, 30, 0)
      interval = 15

      # the interval should be 30 minutes times 60_000 miliseconds + 30_000 miliseconds (30 seconds we add to avoid clock sync issues)
      assert CarbonIntensity.ActualDataServer.calculate_next_refresh(base_date, interval) ==
               15 * 60_000 + 30_000
    end
  end
end
