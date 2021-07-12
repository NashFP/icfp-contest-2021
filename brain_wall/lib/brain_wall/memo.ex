defmodule BrainWall.Memo do
  use GenServer

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def clear() do
    GenServer.cast(__MODULE__, :clear)
  end

  def memoize({m, f, args}) do
    {m, f, args}
    |> get()
    |> case do
      :no_memo ->
        result = apply(m, f, args)
        put({m, f, args}, result)

      memoized_result ->
        memoized_result
    end
  end

  def get(key) do
    case :ets.lookup(:memo_table, key) do
      [{^key, value}] -> value
      [] -> :no_memo
    end
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
    value
  end

  ## Server callbacksreco

  @impl true
  def init(_) do
    :ets.new(:memo_table, [:named_table, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    :ets.insert(:memo_table, {key, value})
    {:noreply, state}
  end

  def handle_cast(:clear, state) do
    :ets.delete(:memo_table)
    :ets.new(:memo_table, [:named_table, read_concurrency: true])

    {:noreply, state}
  end
end
