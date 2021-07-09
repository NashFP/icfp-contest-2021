defmodule BrainWallTest do
  use ExUnit.Case
  doctest BrainWall

  test "greets the world" do
    assert BrainWall.hello() == :world
  end

  test "Scorer" do
    problem = BrainWall.Problem.get(1)
    solution = [[21, 28], [31, 28], [31, 87], [29, 41], [44, 43], [58, 70],[38, 79], [32, 31], [36, 50], [39, 40], [66, 77], [42, 29],[46, 49], [49, 38], [39, 57], [69, 66], [41, 70], [39, 60],[42, 25], [40, 35]]
    assert BrainWall.Scorer.dislikes(problem.hole, solution) == 1
  end

  test "Score 1-pixel-off fit to a triangle" do
    hole = [[50,100], [100,0], [0,0]]
    solution = [[49,99], [99,1], [1,1]]
    assert BrainWall.Scorer.dislikes(hole, solution) == 6
  end

  test "Score perfect fit to a triangle" do
    hole = [[50,100], [100,0], [0,0]]
    solution = [[50,100], [100,0], [0,0]]
    assert BrainWall.Scorer.dislikes(hole, solution) == 0
  end

  test "Check min distance" do
    solution = [[50,100], [100,0], [0,0]]
    assert (for p <- solution, do: BrainWall.Validation.squared_distance([50,100], p)) |> Enum.min() == 0
  end
end
