defmodule CarbonIntensity.Rabbitmq.StoreDataPublisher do
  @behaviour GenRMQ.Publisher

  def init() do
    [
      exchange: "store_data_exchange",
      connection: "amqp://rabbitmq:rabbitmq@localhost:5672"
    ]
  end

  def start_link do
    GenRMQ.Publisher.start_link(__MODULE__, name: __MODULE__)
  end
end
