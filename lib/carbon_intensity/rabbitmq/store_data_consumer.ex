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
          concurrency: 10
        ]
      ],
      batchers: [
        default: [
          batch_size: 50,
          batch_timeout: 10_000,
          concurrency: 10
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Message{} = message, _context) do
    Message.update_data(message, fn data ->
      # this is internal data and we trust it
      {:ok, %{"data" => %{"actual" => actual, "to" => to, "from" => from}}} = Jason.decode(data)
      to = NaiveDateTime.from_iso8601!(to)
      from = NaiveDateTime.from_iso8601!(from)
      %CarbonIntensity.Data{to: to, from: from, actual: actual}
    end)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    messages
    |> Enum.map(fn %Message{data: %CarbonIntensity.Data{} = data} ->
      data
    end)
    |> CarbonIntensity.Influxdb.Client.store_multiple()

    Logger.info(
      "INSERTING DATA FOR INTO INFLUXDB. ACTUAL QUEUE SIZE: #{
        inspect(CarbonIntensity.Rabbitmq.StoreDataPublisher.queue_size())
      }"
    )

    messages
  end
end
