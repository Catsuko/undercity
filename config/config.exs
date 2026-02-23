import Config

config :elixir, ansi_enabled: true

config :logger, :default_formatter, format: "$time [$level] $message\n"

config :undercity_core,
  action_points_max: 50,
  action_points_regen_interval: 1800

config :undercity_server,
  data_dir: "data",
  player_idle_timeout_ms: 15 * 60 * 1_000

import_config "#{config_env()}.exs"
