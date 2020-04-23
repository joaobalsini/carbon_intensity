defmodule CarbonIntensity.Rabbitmq.StoreDataPublisher do
  @moduledoc """
  Publishes "store data into influxdb" requests into store_data_queue. Those requests will be later processed by the `CarbonIntensity.Rabbitmq.StoreDataConsumer`.
  """

  @behaviour GenRMQ.Publisher

  @rabbiqmq_server "amqp://rabbitmq:rabbitmq@localhost:5672"
  @store_data_exchange "store_data_exchange"
  @store_data_queue "store_data_queue"
  @publish_options [persistent: false]

  def init() do
    create_rabbitmq_resources()

    [
      exchange: "store_data_exchange",
      connection: "amqp://rabbitmq:rabbitmq@localhost:5672"
    ]
  end

  def start_link do
    GenRMQ.Publisher.start_link(__MODULE__, name: __MODULE__)
  end

  defp create_rabbitmq_resources() do
    # Setup RabbitMQ connection
    {:ok, connection} = AMQP.Connection.open(@rabbiqmq_server)
    {:ok, channel} = AMQP.Channel.open(connection)

    # Create exchange
    AMQP.Exchange.declare(channel, @store_data_exchange, :topic, durable: true)

    # Create queue
    AMQP.Queue.declare(channel, @store_data_queue, durable: true)

    # Bind queues to exchange
    AMQP.Queue.bind(channel, @store_data_queue, @store_data_exchange,
      routing_key: @store_data_queue
    )

    # Close the channel as it is no longer needed
    # GenRMQ will manage its own channel
    AMQP.Channel.close(channel)
  end

  def publish(data) do
    GenRMQ.Publisher.publish(
      __MODULE__,
      Jason.encode!(%{data: data}),
      @store_data_queue,
      @publish_options
    )
  end

  @spec queue_size :: integer
  def queue_size do
    GenRMQ.Publisher.message_count(__MODULE__, @store_data_queue)
  end

  @spec exchange_name :: binary()
  def exchange_name, do: @store_data_exchange

  @spec queue_name :: binary()
  def queue_name, do: @store_data_queue
end
