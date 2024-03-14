defmodule WebApi do
  use Plug.Router
  require Logger

  plug(Plug.Parsers, parsers: [{:json, json_decoder: Jason}])
  plug(:match)
  plug(:enforce_api_key)
  plug(:dispatch)

  post "/tts" do
    %{"text" => text, "lang" => lang} = conn.body_params

    voice_id =
      case lang do
        "en-US" -> "Matthew"
        "es-US" -> "Pedro"
      end

    key =
      Jason.encode!([text, voice_id])
      |> then(&:crypto.hash(:md5, &1))
      |> Base.url_encode64()
      |> then(&("audio_cache/" <> &1))

    client = AWS.Client.create()
    bucket = Application.get_env(:watts, :s3_bucket)
    polly_module = Application.get_env(:watts, :polly_module)

    case AWS.S3.get_object(client, bucket, key) do
      {:ok, %{"Body" => audio}, _} ->
        Logger.info("cache_hit: text=#{inspect(text)} lang=#{lang} key=#{key}")
        conn = send_resp(conn, 200, audio)

        # Copy the object to itself, which updates the timestamp, so we only expire files
        # that haven't been used in a while
        {:ok, _, _} =
          AWS.S3.copy_object(client, bucket, key, %{
            "CopySource" => URI.encode("#{bucket}/#{key}"),
            "MetadataDirective" => "REPLACE"
          })

        conn

      {:error, {:unexpected_response, %{status_code: 404}}} ->
        case polly_module.synthesize_speech(
               client,
               %{
                 "Engine" => "neural",
                 "OutputFormat" => "mp3",
                 "Text" => text,
                 "TextType" => "ssml",
                 "VoiceId" => voice_id
               },
               receive_body_as_binary?: true
             ) do
          {:ok, %{"Body" => audio, "ContentType" => content_type}, _} ->
            Logger.info("tts_generation: text=#{inspect(text)} lang=#{lang} key=#{key}")
            conn = send_resp(conn, 200, audio)

            {:ok, _, _} =
              AWS.S3.put_object(client, bucket, key, %{
                "Body" => audio,
                "ContentType" => content_type
              })

            conn

          {:error, {:unexpected_response, %{status_code: 400, body: body}}} ->
            Logger.info("tts_error: text=#{inspect(text)} lang=#{lang} key=#{key}")
            send_resp(conn, 400, body)
        end
    end
  end

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
