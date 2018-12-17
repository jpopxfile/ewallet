defmodule EWalletConfig.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_config)

    ActivityLogger.configure(%{
      EWalletConfig.StoredSetting => "setting"
    })

    # List all child processes to be supervised
    children = [
      supervisor(EWalletConfig.Repo, []),
      supervisor(EWalletConfig.Config, [[named: true]]),
      supervisor(EWalletConfig.Vault, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletConfig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
