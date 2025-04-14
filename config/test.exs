import Config

config :watts,
  ex_aws_module: ExAws.Mock,
  api_key: "TEST_API_KEY",
  enable_polly: true,
  s3_bucket: "test-bucket"
