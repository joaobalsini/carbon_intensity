defmodule CarbonIntensity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    dev_or_prod_children = [
      %{
        id: CarbonIntensity.Rabbitmq.StoreDataConsumer,
        start: {CarbonIntensity.Rabbitmq.StoreDataConsumer, :start_link, []}
      },
      %{
        id: CarbonIntensity.Rabbitmq.StoreDataPublisher,
        start: {CarbonIntensity.Rabbitmq.StoreDataPublisher, :start_link, []}
      },
      %{
        id: CarbonIntensity.Rabbitmq.QueryConsumer,
        start: {CarbonIntensity.Rabbitmq.QueryConsumer, :start_link, []}
      },
      %{
        id: CarbonIntensity.Rabbitmq.QueryPublisher,
        start: {CarbonIntensity.Rabbitmq.QueryPublisher, :start_link, []}
      },
      CarbonIntensity.Influxdb.Connection,
      {CarbonIntensity.ActualDataServer, []},
      {CarbonIntensity.PreviousDataServer, []}
    ]

    children =
      try do
        if Mix.env() == :test do
          []
        else
          dev_or_prod_children
        end
      rescue
        _any -> dev_or_prod_children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarbonIntensity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
