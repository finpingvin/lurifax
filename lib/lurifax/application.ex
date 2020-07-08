defmodule Lurifax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LurifaxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lurifax.PubSub},
      # Start the Endpoint (http/https)
      LurifaxWeb.Endpoint,
      # Start a worker by calling: Lurifax.Worker.start_link(arg)
      # {Lurifax.Worker, arg}
      # TODO: Make dealer a supervisor that supervises both dealer and registry
      {Poker.Dealer, name: Poker.Dealer},
      {Registry, name: Poker.Dealer.Registry, keys: :duplicate},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lurifax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LurifaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
