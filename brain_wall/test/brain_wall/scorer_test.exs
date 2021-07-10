defmodule BrainWall.ScorerTest do
  use ExUnit.Case

  alias BrainWall.Scorer

  doctest Scorer

  test "Scorer" do
    problem = BrainWall.Problem.get(1)

    solution = [
      {21, 28},
      {31, 28},
      {31, 87},
      {29, 41},
      {44, 43},
      {58, 70},
      {38, 79},
      {32, 31},
      {36, 50},
      {39, 40},
      {66, 77},
      {42, 29},
      {46, 49},
      {49, 38},
      {39, 57},
      {69, 66},
      {41, 70},
      {39, 60},
      {42, 25},
      {40, 35}
    ]

    expected = 3704
    assert expected == BrainWall.Scorer.dislikes(problem.hole, solution)
  end

  test "Score 1-pixel-off fit to a triangle" do
    problem = %{hole: %BrainWall.Hole{points: [{50, 100}, {100, 0}, {0, 0}]}}

    solution = [{49, 99}, {99, 1}, {1, 1}]
    assert BrainWall.Scorer.dislikes(problem.hole, solution) == 6
  end

  test "Score perfect fit to a triangle" do
    problem = %{hole: %BrainWall.Hole{points: [{50, 100}, {100, 0}, {0, 0}]}}

    solution = [{50, 100}, {100, 0}, {0, 0}]
    assert BrainWall.Scorer.dislikes(problem.hole, solution) == 0
  end
end
