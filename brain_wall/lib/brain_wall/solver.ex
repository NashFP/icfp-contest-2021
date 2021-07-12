defmodule BrainWall.Solver do
  def solve(problems) when is_list(problems) do
    Enum.map(fn x ->
      {x,
       Task.start(fn ->
         BrainWall.Problem.get(x)
         |> BrainWall.Solvers.MarksSolver.solve()
       end)}
    end)
    |> Map.new()
  end
end
