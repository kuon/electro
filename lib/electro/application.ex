defmodule Electro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ElectroWeb.Telemetry,
      # Start the PubSub system
      Electro.Inventory,
      {Phoenix.PubSub, name: Electro.PubSub},
      # Start the Endpoint (http/https)
      ElectroWeb.Endpoint
      # Start a worker by calling: Electro.Worker.start_link(arg)
      # {Electro.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Electro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElectroWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
