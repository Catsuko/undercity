import Config

config :logger, level: :warning

config :undercity_server,
  data_dir: "test/data",
  player_idle_timeout_ms: 50
