defmodule CarbonIntensity.Rabbitmq.QueryConsumer do
  use Broadway

  require Logger

  alias Broadway.Message

  def start_link do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: CarbonIntensity.Rabbitmq.QueryPublisher.queue_name(),
           connection: [
             username: "rabbitmq",
             password: "rabbitmq"
           ]}
      ],
      processors: [
        default: [
          concurrency: 5
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
    with {:ok, %{"url" => url}} <- Jason.decode(data),
         {:ok, data_list} <-
           CarbonIntensity.Client.previous(url) do
      Logger.info(
        "LOADED QUERY FOR URL #{url} ACTUAL QUEUE SIZE: #{
          inspect(CarbonIntensity.Rabbitmq.QueryPublisher.queue_size())
        }"
      )

      Enum.each(data_list, &CarbonIntensity.Rabbitmq.StoreDataPublisher.publish/1)
    end

    message
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context), do: messages
end
