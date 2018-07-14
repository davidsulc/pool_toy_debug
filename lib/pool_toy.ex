defmodule PoolToy do
  defdelegate start_pool(args), to: PoolToy.PoolsMan
  defdelegate stop_pool(pool_sup_pid), to: PoolToy.PoolsMan

  defdelegate checkout(pool), to: PoolToy.PoolMan
  defdelegate checkin(pool, worker), to: PoolToy.PoolMan
end
