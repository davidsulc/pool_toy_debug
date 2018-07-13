defmodule PoolToy.PoolMan do
  use GenServer

  defmodule State do
    defstruct [
      :pool_sup, :size, :monitors, :worker_sup,
      worker_spec: Doubler, workers: []
    ]
  end

  @name __MODULE__

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def checkout() do
    GenServer.call(@name, :checkout)
  end

  def checkin(worker) do
    GenServer.cast(@name, {:checkin, worker})
  end

  def init(args) do
    sup = Keyword.fetch!(args, :pool_sup)
    size = Keyword.fetch!(args, :size)
    Process.flag(:trap_exit, true)
    send(self(), :start_worker_sup)
    monitors = :ets.new(:monitors, [:protected, :named_table])
    {:ok, %State{pool_sup: sup, size: size, monitors: monitors}}
  end

  def handle_call(:checkout, _from, %State{workers: []} = state) do
    {:reply, :full, state}
  end

  def handle_call(:checkout, {from, _}, %State{workers: [worker | rest]} = state) do
    %State{monitors: monitors} = state
    monitor(monitors, {worker, from})
    {:reply, worker, %{state | workers: rest}}
  end

  def handle_cast({:checkin, worker}, %State{monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, state |> handle_idle_worker(pid)}
      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_sup, %State{pool_sup: sup, worker_spec: spec, size: size} = state) do
    {:ok, worker_sup} = Supervisor.start_child(sup, PoolToy.WorkerSup)

    state =
      state
      |> Map.put(:worker_sup, worker_sup)
      |> start_workers()

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _, _}, %State{monitors: monitors} = state) do
    case :ets.match(monitors, {:"$0", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        {:noreply, state |> handle_idle_worker(pid)}
      [] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, %State{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, state |> handle_worker_exit(pid)}
      [] ->
        if workers |> Enum.member?(pid) do
          {:noreply, state |> handle_worker_exit(pid)}
        else
          {:noreply, state}
        end
    end
  end

  def handle_info(msg, state) do
    IO.puts("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp start_workers(%State{worker_sup: sup, worker_spec: spec, size: size} = state) do
    workers =
      for _ <- 1..size do
        new_worker(sup, spec)
      end

    %{state | workers: workers}
  end

  defp new_worker(sup, spec) do
    child_spec = Supervisor.child_spec(spec, restart: :temporary)
    {:ok, pid} = PoolToy.WorkerSup.start_worker(sup, child_spec)
    true = Process.link(pid)
    pid
  end

  defp monitor(monitors, {worker, client}) do
    ref = Process.monitor(client)
    :ets.insert(monitors, {worker, ref})
    ref
  end

  defp handle_idle_worker(%State{workers: workers} = state, idle_worker) when is_pid(idle_worker) do
    %{state | workers: [idle_worker | workers]}
  end

  defp handle_worker_exit(%State{workers: workers, worker_sup: sup, worker_spec: spec} = state, pid) do
    w = workers |> Enum.reject(& &1 == pid)
    %{state | workers: [new_worker(sup, spec) | w]}
  end
end
