defmodule Watts.Application do
  @moduledoc false

  use Application
  @port Application.compile_env!(:watts, :port)

  @impl true
  def start(_type, _args) do
    [
      {Bandit, plug: WebApi, port: @port}
    ]
    |> Supervisor.start_link(strategy: :one_for_one)
  end
end
