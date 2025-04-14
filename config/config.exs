import Config

config :watts,
  port: 4000,
  ex_aws_module: ExAws

import_config "#{config_env()}.exs"
