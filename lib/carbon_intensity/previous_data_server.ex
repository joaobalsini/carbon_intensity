defmodule CarbonIntensity.PreviousDataServer do
  @moduledoc """
  This server is responsible for generating the queries to get previous values. The queries are added to a queue and processed one by one.
  """
  use GenServer, restart: :transient

  require Logger

  @first_date ~N[2018-01-01 00:00:00]
  # 14 days
  @max_interval_in_seconds 1_209_600
  @api_url "https://api.carbonintensity.org.uk/intensity"

  @type query :: binary()

  # Client API

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Callbacks

  @impl true
  @doc false
  def init(_) do
    # Setup loading previous values after 2 seconds to ensure we previously loaded actual value
    schedule_load_previous_values(2_000)
    {:ok, nil}
  end

  @impl true
  @doc false
  def handle_info(:get_previous, state) do
    actual_time_utc = NaiveDateTime.utc_now()
    queries = build_all_queries(actual_time_utc)

    Enum.each(queries, &CarbonIntensity.Rabbitmq.QueryPublisher.publish/1)
    {:noreply, state}
  end

  # Sets up get previous values.
  defp schedule_load_previous_values(miliseconds_from_now) do
    timeout = miliseconds_from_now
    log_get_previous_info(timeout)

    Process.send_after(self(), :get_previous, timeout)
  end

  # Logs refresh info.
  @spec log_get_previous_info(integer()) :: :ok
  defp log_get_previous_info(timeout) do
    refresh_time_in_utc =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(timeout, :millisecond)
      |> NaiveDateTime.to_iso8601()

    Logger.info("Loading previous values scheduled to start at #{refresh_time_in_utc} (UTC)")
  end

  ########
  ## INTERNAL FUNCTIONS - ONLY EXPOSED TO BE PROPERLY TESTED
  #######

  @doc """
  Returns a list of urls to be queries later from `@first_date` until `limit_date` considering `@max_interval_in_seconds`.

  The first element of the list is the most recent url (most recent date) so we give priority the more recent data when queuing it later.
  """
  @spec build_all_queries(NaiveDateTime.t()) :: list(query())
  def build_all_queries(limit_date) do
    build_queries(@first_date, limit_date, @max_interval_in_seconds)
  end

  @doc """
  Returns a list of urls to be queries later from `from_date` until `to_date` considering given `interval` in seconds`.

  The first element of the list is the most recent url (most recent date) so we give priority the more recent data when queuing it later.
  """
  @spec build_queries(
          NaiveDateTime.t(),
          NaiveDateTime.t(),
          pos_integer(),
          list(query())
        ) ::
          list(query())
  def build_queries(
        from_date,
        to_date,
        interval,
        acc \\ []
      )

  def build_queries(
        from_date,
        to_date,
        _interval,
        acc
      )
      when from_date == to_date,
      do: acc

  def build_queries(
        from_date,
        to_date,
        interval,
        acc
      ) do
    next_date = calculate_end_date(from_date, to_date, interval)
    query = build_query(from_date, next_date)
    acc = [query | acc]
    build_queries(next_date, to_date, interval, acc)
  end

  @doc """
  Adds interval in seconds to a given date returning this calculated date or `max_date` if calculated date is after `max_date`.
  """
  @spec calculate_end_date(NaiveDateTime.t(), NaiveDateTime.t(), pos_integer()) ::
          NaiveDateTime.t()
  def calculate_end_date(from_date, max_end_date, interval) do
    last_date = NaiveDateTime.add(from_date, interval, :second)

    # Returns :gt if first is later than the second
    case NaiveDateTime.compare(last_date, max_end_date) do
      :gt -> max_end_date
      _other -> last_date
    end
  end

  @doc """
  Returns the URL of the query formatted as expected by CarbonIntensity API.
  """
  @spec build_query(NaiveDateTime.t(), NaiveDateTime.t()) :: query()
  def build_query(from_date, to_date),
    do: "#{@api_url}/#{NaiveDateTime.to_iso8601(from_date)}/#{NaiveDateTime.to_iso8601(to_date)}"
end
