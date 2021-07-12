defmodule BrainWall.Parallel do
  def map(enum, fun) do
    enum
    |> Enum.map(fn item -> Task.async(fn -> fun.(item) end) end)
    |> Enum.map(fn task -> Task.await(task, 120_000) end)
  end
end
