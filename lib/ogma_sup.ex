defmodule Ogma.Sup do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    children = [
      worker(Ogma, [], restart: :temporary)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
