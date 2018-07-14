defmodule PoolToy.PoolSup do
  use Supervisor

  def start_link(args) when is_list(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    name = args |> Keyword.fetch!(:name)
    pool_size = args |> Keyword.fetch!(:size)

    children = [
      {PoolToy.PoolMan, [pool_sup: self(), name: name, size: pool_size]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
