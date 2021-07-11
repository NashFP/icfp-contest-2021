defmodule BrainWall.Solvers.MarksSolverTest do
  use ExUnit.Case

  alias BrainWall.Solvers.MarksSolver

  @tag :skip
  test "problem0" do
    hole = %BrainWall.Hole{points: [{0, 0}, {0, 100}, {100, 100}, {100, 0}]}

    figure =
      %{
        "figure" => %{
          "edges" => [[0, 1], [1, 2], [2, 0]],
          "vertices" => [[0, 0], [0, 50], [50, 0]]
        }
      }
      |> BrainWall.Figure.new()

    problem = %BrainWall.Problem{hole: hole, figure: figure, epsilon: 0}

    assert :boom == MarksSolver.solve(problem)
  end
end
