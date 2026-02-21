ExUnit.start()

ExUnit.after_suite(fn _ ->
  Application.stop(:undercity_server)
end)
