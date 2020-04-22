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
    # this is internal data and we trust it
    {:ok, %{"data" => %{"actual_intensity" => actual_intensity, "to" => to}}} =
      Jason.decode(message.payload)

    timestamp =
      to
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix(:microsecond)

    data = %CarbonIntensity.InfluxdbSerie{}
    data = %{data | timestamp: timestamp * 1000}
    data = %{data | fields: %{data.fields | actual_value: actual_intensity}}

    CarbonIntensity.InfluxdbConnection.write(data, async: true)
  end
end
