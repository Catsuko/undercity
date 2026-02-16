import Config

config :elixir, ansi_enabled: true

config :logger, :default_formatter, format: "$time [$level] $message\n"

import_config "#{config_env()}.exs"
