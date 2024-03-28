import Config

if config_env() != :test do
  api_key = System.get_env("WATTS_API_KEY")
  if(api_key in [nil, ""], do: raise("API key not set"))

  config :watts,
    api_key: api_key,
    polly_module:
      if(System.get_env("WATTS_ENABLE_POLLY") == "true", do: AWS.Polly, else: PollyStub),
    s3_bucket: System.get_env("WATTS_BUCKET")
end
