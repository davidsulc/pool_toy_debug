defmodule PoolToy.PoolsMan do
  use GenServer

  @name __MODULE__

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def start_pool(args) do
    PoolToy.PoolsSup.start_pool(args)
  end

  def stop_pool(pool) do
    PoolToy.PoolsSup.stop_pool(pool)
  end

  def init(args) do
    {:ok, :ok}
  end
end
