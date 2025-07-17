defmodule ExAudit.CustomData do
  use GenServer

  @moduledoc """
  ETS table that stores custom data for pids
  """

  def start_link([]) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    ets = :ets.new(__MODULE__, [:public, :named_table])
    {:ok, ets}
  end

  def track(pid, data) do
    :ets.insert(__MODULE__, {pid, data})
    GenServer.cast(__MODULE__, {:store, pid, data})
  end

  def handle_cast({:store, pid, data}, ets) do
    if Process.alive?(pid)do
      Process.monitor(pid)
    else
      :ets.delete(ets, pid)
    end

    {:noreply, ets}
  end

  def get(pid \\ self()) do
    __MODULE__
    |> :ets.lookup(pid)
    |> Enum.flat_map(&elem(&1, 1))
  end

  def handle_info({:DOWN, _, :process, pid, _}, ets) do
    :ets.delete(ets, pid)
    {:noreply, ets}
  end
end
