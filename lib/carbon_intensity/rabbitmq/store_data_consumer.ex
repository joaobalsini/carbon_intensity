defmodule CarbonIntensity.Rabbitmq.StoreDataConsumer do
  @behaviour GenRMQ.Consumer

  def init() do
    [
      queue: "store_data_queue",
      exchange: "store_data_exchange",
      routing_key: "#",
      prefetch_count: "10",
      connection: "amqp://rabbitmq:rabbitmq@localhost:5672",
      retry_delay_function: fn attempt -> :timer.sleep(2000 * attempt) end
    ]
  end

  def start_link do
    GenRMQ.Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  def consumer_tag() do
    "store_data_consumer"
  end

  def handle_message(message) do
    IO.inspect(message)
  end
end
