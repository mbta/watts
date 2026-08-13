import Config

config :watts,
  port: 4000,
  ex_aws_module: ExAws

config :ex_aws,
  json_codec: JSON

import_config "#{config_env()}.exs"
