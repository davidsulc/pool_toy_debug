defmodule PoolToy.PoolsMan do
  use GenServer

  @name __MODULE__

  defmodule State do
    defstruct []
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def start_pool(args) do
    GenServer.call(@name, {:start_pool, args})
  end

  def stop_pool(pool) do
    PoolToy.PoolsSup.stop_pool(pool)
  end

  def init(args) do
    {:ok, %State{}}
  end

  def handle_call({:start_pool, args}, _from, %State{} = state) do
    result = PoolToy.PoolsSup.start_pool(args)
    {:reply, result, state}
  end
end
