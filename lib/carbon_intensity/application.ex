defmodule CarbonIntensity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: CarbonIntensity.Rabbitmq.StoreDataConsumer,
        start: {CarbonIntensity.Rabbitmq.StoreDataConsumer, :start_link, []}
      },
      %{
        id: CarbonIntensity.Rabbitmq.StoreDataPublisher,
        start: {CarbonIntensity.Rabbitmq.StoreDataPublisher, :start_link, []}
      },
      CarbonIntensity.InfluxdbConnection,
      {CarbonIntensity.Server, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarbonIntensity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
