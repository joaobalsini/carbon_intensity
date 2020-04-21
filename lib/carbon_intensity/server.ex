defmodule CarbonIntensity.Server do
  @moduledoc """
  Server is responsible for loading actual data at periodic times and store the latest value until it's saved on the database.
  """
  use GenServer, restart: :transient

  require Logger

  alias __MODULE__, as: State

  def api_client, do: Application.get_env(:carbon_intensity, :client)

  @doc false
  defstruct [:from, :to, :actual]

  @typedoc false
  @type state :: %State{
          from: binary(),
          to: binary(),
          actual: pos_integer()
        }
  # Client API

  @doc """
  Starts refresher for getting data periodically.
  """
  def start_link(_) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init(%State{} = state) do
    setup_data_refresh(1_000)
    {:ok, state}
  end

  @impl true
  def handle_info(:get, %State{} = state) do
    actual_time_utc = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()

    case api_client().actual() do
      {:ok, data} ->
        Logger.info("#{actual_time_utc} (UTC) - Successfully loaded data: #{inspect(data)}")
        state = Map.put(state, :data, data)
        setup_data_refresh(calculate_next_refresh())
        {:noreply, state}

      {:error, error_atom} when error_atom in [:malformed, :request_error] ->
        Logger.info(
          "#{actual_time_utc} (UTC) - Error loading data #{inspect(error_atom)} - Retrying in 10 seconds"
        )

        # try again in 10 seconds
        setup_data_refresh(10_000)

        {:noreply, state}

      {:error, other} ->
        Logger.info("#{actual_time_utc} (UTC) - Error loading data #{inspect(other)} ")
        {:noreply, state}
    end
  end

  # returns the difference, in milliseconds, between current time and next refresh
  defp calculate_next_refresh(interval_in_minutes \\ 30) do
    # gets current time
    now = NaiveDateTime.utc_now()

    # adds 30 minutes, so we let the library to handle new hours/days/months/years
    updated_date = NaiveDateTime.add(now, interval_in_minutes * 60)

    # floor number of minutes
    updated_minutes = floor(updated_date.minute / interval_in_minutes) * interval_in_minutes

    # Create new_refresh based on updated date with 'floored' minutes and 30 seconds
    {:ok, next_refresh} =
      NaiveDateTime.new(
        updated_date.year,
        updated_date.month,
        updated_date.day,
        updated_date.hour,
        updated_minutes,
        30
      )

    # returns the difference between actual time and next refresh
    NaiveDateTime.diff(next_refresh, now, :millisecond)
  end

  # Sets up refresh data.
  defp setup_data_refresh(miliseconds_from_now) do
    timeout = miliseconds_from_now
    log_refresh_info(timeout)

    Process.send_after(self(), :get, timeout)
  end

  # Logs refresh info.
  @spec log_refresh_info(integer()) :: :ok
  defp log_refresh_info(timeout) do
    refresh_time_in_utc =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(timeout, :millisecond)
      |> NaiveDateTime.to_iso8601()

    Logger.info("Data refresh is scheduled at #{refresh_time_in_utc} (UTC)")
  end
end
