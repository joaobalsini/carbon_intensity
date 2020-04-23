defmodule CarbonIntensity.Rabbitmq.StoreDataConsumer do
  use Broadway

  require Logger

  alias Broadway.Message

  def start_link do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: CarbonIntensity.Rabbitmq.StoreDataPublisher.queue_name(),
           connection: [
             username: "rabbitmq",
             password: "rabbitmq"
           ]}
      ],
      processors: [
        default: [
          concurrency: 100
        ]
      ],
      batchers: [
        default: [
          batch_size: 1,
          batch_timeout: 10_000,
          concurrency: 1
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Message{data: data} = message, _context) do
    # this is internal data and we trust it
    {:ok, %{"data" => %{"actual_intensity" => actual_intensity, "to" => to}}} = Jason.decode(data)

    timestamp =
      to
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix(:microsecond)

    data = %CarbonIntensity.InfluxdbSerie{}

    # convert timestamp to nanosecond
    data = %{data | timestamp: timestamp * 1000}
    data = %{data | fields: %{data.fields | actual_value: actual_intensity}}

    Logger.info(
      "INSERTING DATA FOR DATE #{to} INTO INFLUXDB. ACTUAL QUEUE SIZE: #{
        inspect(CarbonIntensity.Rabbitmq.StoreDataPublisher.queue_size())
      }"
    )

    CarbonIntensity.InfluxdbConnection.write(data)

    message
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context), do: messages
end
