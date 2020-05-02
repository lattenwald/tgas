use Mix.Config

config :tdlib,
  log_file: "tdlib.log"

config :logger,
  backends: [:console, {LoggerFileBackend, :messages_log}]

config :logger, :messages_log,
  path: "messages.log",
  level: :info

import_config "secret.exs"
