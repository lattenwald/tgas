import Config

config :logger, level: :info

config :tdlib,
  log_file: "tdlib.log",
  db: "/app/db"

try do
  import_config "local.exs"
catch
  _, _ -> :missing
end
