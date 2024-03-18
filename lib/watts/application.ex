defmodule Watts.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    [
      {Bandit, plug: WebApi}
    ]
    |> Supervisor.start_link(strategy: :one_for_one)
  end
end
