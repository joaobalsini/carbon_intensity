# Carbon Intensity

## Demo

This demo shows one graphic being plotted as the past data is being loaded. Current data loading is not that fun, it loads a value when server starts and whenever minute is equal to 0 or 30.
![](./carbon_intensity_loader.gif)

## About

This application loads current `actual intensity` and past `actual intensity` from [Carbon Intensity API](https://carbon-intensity.github.io/api-definitions/#carbon-intensity-api-v2-0-0).

The field that is read is shown below (with an arrow).
```
{
  "data":[
    {
    "from": "2018-01-20T12:00Z",
    "to": "2018-01-20T12:30Z",
    "intensity": {
      "forecast": 266,
--->  "actual": 263,
      "index": "moderate"
    }
  }]
}
```


The API publishes data for the previous 30 minutes. The API also let you query any other "30 minutes" average since April 2017.

**Example** 
Current time is 14:06 (UTC).
When querying the API you will get data from 13:30 to 14:00.


This application is divided in two clearly defined parts:

1) Current `actual data` loader
2) Previous `actual data` loader

### Current `actual data` loader
Relies on a simple genserver `CarbonIntensity.ActualDataServer` to load data when application starts and for each half an hour. There is a function that calculates the next request time and schedules it.

So, if current time is 14:06, it will get the current data (from 13:30 to 14:00) and it will schedule a query for 14:30. After the 14:30 query is properly loaded and processed, another query is scheduled for 15:00, and so on.

The query is performed by `CarbonIntensity.Client.actual/0`. If the query fails, it will retry automatically 5 times and, after that, the genserver itself retries each 10 seconds. I've experienced that the API sometimes have actual = null, and retrying solves that problem.

It stores the good data on an InfluxDB database.

### Previous `actual data` loader
Relies on a genserver `CarbonIntensity.PreviousDataServer` to add queries to a queue when application starts.
The queries are queued on a RabbitMQ instance and then processed by Broadway in module `CarbonIntensity.Rabbitmq.QueryConsumer`. Each query is performed and processed by `CarbonIntensity.Client.previous/1`. The result of each query is a list of data to be stored on InfluxDB. 

Since there are a lot of data to be stored on each query (up to 672 points), this data is added into another queue on RabbitMQ to be processed by another Broadway instance in module `CarbonIntensity.Rabbitmq.StoreDataConsumer`. This data is batched (batch size 50) and batch inserted in InfluxDB.

The following diagram explains the data flow:
```
+--------------+        +-------------+      +-----------------+
|              |        |             |      |     RabbitMQ    |
|   Previous   |  URLS  |             | URLS |                 |
|     Data     +-------->    Query    +----->+   query_queue   |
|    Server    |        |  Publisher  |      |                 |
|              |        |             |      |                 |
|              |        |             |      |                 |
|              |        |             |      |                 |
+--------------+        +-------------+      +-----------------+
                                                      |U
                                                      |R
                                                      |L
                                                      |S
+--------------+        +-------------+      +--------v--------+
|              |        |             |      |                 |
|              |        |    Client   |      |                 |
|     Store    |PROCESSD|  Performs   | URLS |    Broadway     |
|     Data     +<-------+     and     <------+                 |
|   Publisher  |  DATA  |  processes  |      |     Query       |
|              |        |    query    |      |    Consumer     |
|              |        |             |      |                 |
+------+-------+        +-------------+      +-----------------+
       |
   PROCESSED
      DATA
       |
+------v-------+        +-------------+      +----------------+
|              |        |             |      |                |
|              |        |             |      |                |
|   RabbitMQ   |PROCESSD|  Broadway   |BATCHD|                |
|              +-------->             | ----->    InfluxDB    |
|  store_data  |  DATA  |  StoreData  | DATA |                |
|    _queue    |        |  Consumer   |      |                |
|              |        |             |      |                |
+--------------+        +-------------+      +----------------+

```

It loads data from 2018 up to current date. 

## Installation and Usage

Clone the application using ssh: `git clone git@github.com:joaobalsini/carbon_intensity.git`

Enter directory: `cd carbon_intensity`

Download libraries: `mix deps.get`

Start a new shell and start containers: `docker-compose up`

Wait a bit until everything starts

Start application with iex: `iex -S mix`

### Running tests

Simply run `mix test`.

Comments: Tests don't test the genservers or the pipeline. The untested code is quite simple and basically call other libraries (that are tested). The functions "around" untested code are tested properly.

### Running on production (with mix release)

Run `MIX_ENV=prod mix release`

And `_build/prod/rel/carbon_intensity/bin/carbon_intensity start`

### Seeing the results

On the docker compose file we also start Chronograph, an application to inspect data on InfluxDB. You can create a diagram based on the data. You can see the diagram on the video above.

To access chronograph go to: http://localhost:8888/ and use login:password influxdb:influxdb.

### Cleaning docker data

To stop docker-compose simply run: `docker-compose down`

To clean saved data, after docker-compose down, simply run: `docker volume prune`.

## Other comments

Credentials are stored inside the code and in dockerfile to make it simpler to run. In production please take proper care of replacing those with environment variables.

Even if data is already stored, whenever we restart the application it will query and save all data again. InfluxDB will simply overwrite the data that already exists.

## Next steps

- Stop `PreviousDataServer` as soon as all urls are queued in RabbitMQ.
- Add environment variable to disable previous data loading when we want (so we don't start `PreviousDataServer`).
- Add Grafana provisioning on docker-compose so we have something to show when we start.
- Discover a way to test the whole pipeline using Broadway.
