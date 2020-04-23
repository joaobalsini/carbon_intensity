defmodule CarbonIntensity.Rabbitmq.StoreDataConsumer do
  @moduledoc """
  Processes "store data into influxdb" requests from store_data_queue.
  """

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
    {:ok, %{"data" => %{"actual" => actual, "to" => to, "from" => from}}} = Jason.decode(data)

    to = NaiveDateTime.from_iso8601!(to)
    from = NaiveDateTime.from_iso8601!(from)

    structured_data = %CarbonIntensity.Data{to: to, from: from, actual: actual}

    Logger.info(
      "INSERTING DATA FOR DATE #{to} INTO INFLUXDB. ACTUAL QUEUE SIZE: #{
        inspect(CarbonIntensity.Rabbitmq.StoreDataPublisher.queue_size())
      }"
    )

    CarbonIntensity.Influxdb.Client.store(structured_data)

    message
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context), do: messages
end
