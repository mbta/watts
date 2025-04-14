defmodule WebApi do
  use Plug.Router
  require Logger

  @ex_aws Application.compile_env!(:watts, :ex_aws_module)

  plug(Plug.Parsers, parsers: [{:json, json_decoder: Jason}])
  plug(:match)
  plug(:enforce_api_key)
  plug(:dispatch)

  post "/tts" do
    %{"text" => text, "voice_id" => voice_id} = conn.body_params
    output_format = Map.get(conn.body_params, "output_format", "mp3")

    # CAUTION: Changing the cache key may result in a large number of calls to Polly, which
    # can be costly. Be mindful of any changes made here.
    key =
      Jason.encode!(%{text: text, voice_id: voice_id, output_format: output_format})
      |> then(&:crypto.hash(:md5, &1))
      |> Base.url_encode64()
      |> then(&("audio_cache/" <> &1))

    bucket = Application.get_env(:watts, :s3_bucket)

    log_string =
      "text=#{inspect(text)} voice_id=#{voice_id} output_format=#{output_format} key=#{key}"

    case ExAws.S3.get_object(bucket, key) |> @ex_aws.request() do
      {:ok, %{body: audio}} ->
        Logger.info("cache_hit: #{log_string}")
        conn = send_resp(conn, 200, audio)

        # Copy the object to itself, which updates the timestamp, so we only expire files
        # that haven't been used in a while
        {:ok, _} =
          ExAws.S3.put_object_copy(bucket, key, bucket, key,
            metadata_directive: :REPLACE,
            meta: [{:text, text}]
          )
          |> @ex_aws.request()

        conn

      {:error, {:http_error, 404, _}} ->
        if Application.get_env(:watts, :enable_polly) do
          ExAws.Polly.synthesize_speech(text,
            voice_id: voice_id,
            engine: "neural",
            lexicon_names: ["mbtalexicon"],
            text_type: "ssml",
            output_format: output_format
          )
          |> @ex_aws.request()
        else
          filename = if(output_format == "mp3", do: "static.mp3", else: "static.pcm")
          body = :code.priv_dir(:watts) |> Path.join(filename) |> File.read!()
          {:ok, %{body: body}}
        end
        |> case do
          {:ok, %{body: audio}} ->
            Logger.info("tts_generation: #{log_string}")
            conn = send_resp(conn, 200, audio)

            {:ok, _} =
              ExAws.S3.put_object(bucket, key, audio,
                content_type:
                  case output_format do
                    "mp3" -> "audio/mpeg"
                    "pcm" -> "audio/pcm"
                    _ -> "application/octet-stream"
                  end,
                meta: [{:text, text}]
              )
              |> @ex_aws.request()

            conn

          {:error, {:http_error, 400, %{body: body}}} ->
            Logger.info("tts_error: #{log_string}")

            send_resp(conn, 400, body)
        end
    end
  end

  get "/_health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp enforce_api_key(%Plug.Conn{path_info: ["_health"]} = conn, _opts), do: conn

  defp enforce_api_key(conn, _opts) do
    api_key =
      Enum.find_value(conn.req_headers, fn {key, value} -> if(key == "x-api-key", do: value) end)

    if api_key != Application.get_env(:watts, :api_key) do
      conn |> send_resp(403, "Invalid API key") |> halt()
    else
      conn
    end
  end
end
