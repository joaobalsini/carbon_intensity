defmodule CarbonIntensity.Rabbitmq.QueryPublisher do
  @behaviour GenRMQ.Publisher

  @rabbiqmq_server "amqp://rabbitmq:rabbitmq@localhost:5672"
  @queries_exchange "queries_exchange"
  @queries_queue "queries_queue"
  @publish_options [persistent: false]

  def init() do
    create_rabbitmq_resources()

    [
      exchange: @queries_exchange,
      connection: @rabbiqmq_server
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
    AMQP.Exchange.declare(channel, @queries_exchange, :topic, durable: true)

    # Create queue
    AMQP.Queue.declare(channel, @queries_queue, durable: true)

    # Bind queues to exchange
    AMQP.Queue.bind(channel, @queries_queue, @queries_exchange, routing_key: @queries_queue)

    # Close the channel as it is no longer needed
    # GenRMQ will manage its own channel
    AMQP.Channel.close(channel)
  end

  def publish(url) do
    GenRMQ.Publisher.publish(
      __MODULE__,
      Jason.encode!(%{url: url}),
      @queries_queue,
      @publish_options
    )
  end

  @spec queue_size :: integer
  def queue_size do
    GenRMQ.Publisher.message_count(__MODULE__, @queries_queue)
  end

  @spec exchange_name :: binary()
  def exchange_name, do: @queries_exchange

  @spec queue_name :: binary()
  def queue_name, do: @queries_queue
end
