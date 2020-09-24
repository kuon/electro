# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :electro, ElectroWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base:
    "YB3agzoUjNqr68DhZQsZj36juCMZQRww3mMb2NJd7hDdIg+Go2SHqEd4Vd7s+svC",
  render_errors: [
    view: ElectroWeb.ErrorView,
    accepts: ~w(html json),
    layout: false
  ],
  pubsub_server: Electro.PubSub,
  live_view: [signing_salt: "mxK7SEY0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

inventory_path =
  System.get_env("INVENTORY_PATH") ||
    raise """
    environment variable INVENTORY_PATH is missing.
    Point it to your inventory directory.
    """

config :electro,
  inventory_path: inventory_path

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
