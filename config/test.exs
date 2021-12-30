import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lister, ListerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "F5p4SGlAXqL/SISjdB2/BCCPvZ144hNWBQPaY9+vC57W1Hagqu9S/ZrhWJ/QRjoF",
  server: false

# In test we don't send emails.
config :lister, Lister.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
