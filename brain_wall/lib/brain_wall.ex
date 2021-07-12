defmodule BrainWall do
  @moduledoc """
  Documentation for `BrainWall`.
  """

  def main(args \\ []) do
    p = BrainWall.Problem.get(args |> Enum.at(0))
    _ = BrainWall.Solvers.MarksSolver.solve(p)
  end
end
