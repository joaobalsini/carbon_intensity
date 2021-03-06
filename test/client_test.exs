defmodule CarbonIntensity.ClientTest do
  use ExUnit.Case

  alias CarbonIntensity.Client

  describe "process_response/1" do
    test "should convert the json response into a map if received status code 200 together with valid body" do
      response =
        {:ok,
         %{
           status_code: 200,
           body:
             "{ \r\n  \"data\":[{ \r\n    \"from\": \"2020-04-21T23:00Z\",\r\n    \"to\": \"2020-04-21T23:30Z\",\r\n    \"intensity\": {\r\n      \"forecast\": 87,\r\n      \"actual\": 87,\r\n      \"index\": \"low\"\r\n    }\r\n  }]\r\n}"
         }}

      assert Client.process_response(response) ==
               {:ok,
                %{
                  "data" => [
                    %{
                      "from" => "2020-04-21T23:00Z",
                      "to" => "2020-04-21T23:30Z",
                      "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
                    }
                  ]
                }}
    end

    test "should return Jason decode error if received status code 200 together with malformed json body" do
      response =
        {:ok,
         %{
           status_code: 200,
           body: "{ \r\n  \"data\":[{ \r\n    }"
         }}

      assert {:error, %Jason.DecodeError{}} = Client.process_response(response)
    end

    test "should return {:error, :not_found} if status code is 404" do
      response =
        {:ok,
         %{
           status_code: 404
         }}

      assert Client.process_response(response) ==
               {:error, :not_found}
    end

    test "should return {:error, :request_error} if status code not 200 or 404" do
      assert Client.process_response({:ok, %{status_code: 500}}) ==
               {:error, :request_error}

      assert Client.process_response(:error) == {:error, :request_error}
    end
  end

  describe "parse_result/1" do
    test "should return a casted map if receive valid response" do
      response = %{
        "data" => [
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          }
        ]
      }

      assert Client.parse_result(response) ==
               {:ok,
                %CarbonIntensity.Data{
                  from: ~N[2020-04-21 23:00:00],
                  to: ~N[2020-04-21 23:30:00],
                  actual: 87
                }}
    end

    test "should return {:error, :malformed} if received a different input" do
      assert Client.parse_result(%{
               "data" => %{}
             }) ==
               {:error, :malformed}

      assert Client.parse_result(%{
               "data" => %{
                 "from" => "2020-04-21T23:00Z",
                 "to" => "2020-04-21T23:30Z",
                 "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
               }
             }) ==
               {:error, :malformed}

      assert Client.parse_result(%{
               "data" => [%{}]
             }) ==
               {:error, :malformed}

      assert Client.parse_result(%{
               "data" => [
                 %{
                   "from" => "2020-04-21T23:00Z",
                   "to" => "2020-04-21T23:30Z",
                   "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
                 },
                 %{
                   "from" => "2020-04-21T23:00Z",
                   "to" => "2020-04-21T23:30Z",
                   "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
                 }
               ]
             }) ==
               {:error, :malformed}
    end

    test "should return {:error, :malformed} if received a correct map but with invalid parameters" do
      response = %{
        "data" => [
          %{
            "from" => "2020-04-21",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          }
        ]
      }

      assert Client.parse_result(response) == {:error, :malformed}

      response = %{
        "data" => [
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          }
        ]
      }

      assert Client.parse_result(response) == {:error, :malformed}

      response = %{
        "data" => [
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21",
            "intensity" => %{"forecast" => 87, "actual" => "87", "index" => "low"}
          }
        ]
      }

      assert Client.parse_result(response) == {:error, :malformed}
    end
  end

  describe "parse_results/1" do
    test "should parse results and return a list of data" do
      response = %{
        "data" => [
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          },
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          }
        ]
      }

      assert Client.parse_results(response) ==
               {:ok,
                [
                  %CarbonIntensity.Data{
                    from: ~N[2020-04-21 23:00:00],
                    to: ~N[2020-04-21 23:30:00],
                    actual: 87
                  },
                  %CarbonIntensity.Data{
                    from: ~N[2020-04-21 23:00:00],
                    to: ~N[2020-04-21 23:30:00],
                    actual: 87
                  }
                ]}
    end

    test "should reject invalid results and return a list of data" do
      response = %{
        "data" => [
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          },
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => 87, "index" => "low"}
          },
          %{
            "from" => "2020-04-21T23:00Z",
            "to" => "2020-04-21T23:30Z",
            "intensity" => %{"forecast" => 87, "actual" => nil, "index" => "low"}
          },
          %{},
          "a"
        ]
      }

      assert Client.parse_results(response) ==
               {:ok,
                [
                  %CarbonIntensity.Data{
                    from: ~N[2020-04-21 23:00:00],
                    to: ~N[2020-04-21 23:30:00],
                    actual: 87
                  },
                  %CarbonIntensity.Data{
                    from: ~N[2020-04-21 23:00:00],
                    to: ~N[2020-04-21 23:30:00],
                    actual: 87
                  }
                ]}
    end
  end
end
