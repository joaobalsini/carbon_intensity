defmodule CarbonIntensity.PreviousDataServerTest do
  use ExUnit.Case

  alias CarbonIntensity.PreviousDataServer

  setup_all do
    api_url = "https://api.carbonintensity.org.uk/intensity"

    {:ok, api_url: api_url}
  end

  describe "build_all_queries/1" do
    test "Build queries list correctly considering static parameters @start_date and @max_interval_in_seconds",
         %{api_url: api_url} do
      end_date = ~N[2018-01-30 00:00:00]

      assert PreviousDataServer.build_all_queries(end_date) == [
               "#{api_url}/2018-01-29T00:00:00/2018-01-30T00:00:00",
               "#{api_url}/2018-01-15T00:00:00/2018-01-29T00:00:00",
               "#{api_url}/2018-01-01T00:00:00/2018-01-15T00:00:00"
             ]
    end
  end

  describe "build_queries/4" do
    test "returns list of query between two dates considering query interval", %{api_url: api_url} do
      two_days_in_seconds = 2 * 24 * 60 * 60

      start_date = ~N[2020-01-01 00:00:00]
      end_date = ~N[2020-01-10 00:00:00]

      assert PreviousDataServer.build_queries(start_date, end_date, two_days_in_seconds, []) == [
               "#{api_url}/2020-01-09T00:00:00/2020-01-10T00:00:00",
               "#{api_url}/2020-01-07T00:00:00/2020-01-09T00:00:00",
               "#{api_url}/2020-01-05T00:00:00/2020-01-07T00:00:00",
               "#{api_url}/2020-01-03T00:00:00/2020-01-05T00:00:00",
               "#{api_url}/2020-01-01T00:00:00/2020-01-03T00:00:00"
             ]
    end
  end

  describe "calculate_end_date/3" do
    test "Calculates end date correctly" do
      # 2 days * 24 hours * 60 minutes * 60 seconds
      two_days_in_seconds = 2 * 24 * 60 * 60

      start_date = ~N[2020-01-01 00:00:00]
      max_date = ~N[2020-01-10 00:00:00]

      assert PreviousDataServer.calculate_end_date(start_date, max_date, two_days_in_seconds) ==
               ~N[2020-01-03 00:00:00]
    end

    test "Returns max_date if calculated date is after max_date" do
      # 10 days * 24 hours * 60 minutes * 60 seconds
      ten_days_in_seconds = 10 * 24 * 60 * 60

      start_date = ~N[2020-01-01 00:00:00]
      max_date = ~N[2020-01-10 00:00:00]

      assert PreviousDataServer.calculate_end_date(start_date, max_date, ten_days_in_seconds) ==
               max_date
    end
  end

  describe "build_query/2" do
    test "Writes query correctly", %{api_url: api_url} do
      start_date = ~N[2020-01-01 00:00:00]
      end_date = ~N[2020-01-02 00:00:00]

      assert PreviousDataServer.build_query(start_date, end_date) ==
               "#{api_url}/2020-01-01T00:00:00/2020-01-02T00:00:00"

      start_date = ~N[2020-01-01 00:00:30]
      end_date = ~N[2020-01-02 01:00:00]

      assert PreviousDataServer.build_query(start_date, end_date) ==
               "#{api_url}/2020-01-01T00:00:30/2020-01-02T01:00:00"
    end
  end
end
