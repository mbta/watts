defmodule WebApiTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn
  import Mox

  @opts WebApi.init([])

  setup :verify_on_exit!

  test "cache hit" do
    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :get} ->
      {:ok, %{body: "data"}}
    end)

    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :put} -> {:ok, nil} end)

    assert %{status: 200, resp_body: "data"} =
             make_conn(%{}) |> add_api_key() |> WebApi.call(@opts)
  end

  test "mp3 generation" do
    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :get} ->
      {:error, {:http_error, 404, nil}}
    end)

    expect(ExAws.Mock, :request, fn %ExAws.Operation.RestQuery{body: %{"OutputFormat" => "mp3"}} ->
      {:ok, %{body: "data"}}
    end)

    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :put} -> {:ok, nil} end)

    assert %{status: 200, resp_body: "data"} =
             make_conn(%{}) |> add_api_key() |> WebApi.call(@opts)
  end

  test "pcm generation" do
    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :get} ->
      {:error, {:http_error, 404, nil}}
    end)

    expect(ExAws.Mock, :request, fn %ExAws.Operation.RestQuery{body: %{"OutputFormat" => "pcm"}} ->
      {:ok, %{body: "data"}}
    end)

    expect(ExAws.Mock, :request, fn %ExAws.Operation.S3{http_method: :put} -> {:ok, nil} end)

    assert %{status: 200, resp_body: "data"} =
             make_conn(%{output_format: "pcm"}) |> add_api_key() |> WebApi.call(@opts)
  end

  test "rejects invalid key" do
    assert %{status: 403} =
             make_conn(%{}) |> put_req_header("x-api-key", "INVALID") |> WebApi.call(@opts)
  end

  defp add_api_key(conn), do: put_req_header(conn, "x-api-key", "TEST_API_KEY")

  defp make_conn(params) do
    body = Map.merge(%{text: "<speak>hello</speak>", voice_id: "Matthew"}, params)

    conn(:post, "/tts", Jason.encode!(body))
    |> put_req_header("content-type", "application/json")
  end
end
