defmodule PoolToy.PoolSup do
  use Supervisor

  def start_link(args) when is_list(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    pool_name = Keyword.fetch!(args, :name)
    {:ok, _} = Registry.register(PoolToy.Registry, pool_name, self())

    args = Keyword.put_new(args, :pool_sup, self())
    children = [
      {PoolToy.PoolMan, args}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
