defmodule PoolToy.PoolsSup do
  use DynamicSupervisor

  @name __MODULE__

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: @name)
  end

  def start_pool(args) do
    {:ok, _} = DynamicSupervisor.start_child(@name, {PoolToy.PoolSup, args})
    :ok
  end

  def stop_pool(pool_sup) do
    DynamicSupervisor.terminate_child(@name, pool_sup)
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
