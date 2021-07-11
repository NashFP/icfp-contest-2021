defmodule BrainWall.SolutionTest do
  use ExUnit.Case

  alias BrainWall.Solution

  doctest Solution

  setup do
    hole = %BrainWall.Hole{points: [{0, 0}, {0, 100}, {100, 100}, {100, 0}]}
    [hole: hole]
  end

  describe "given a triangle figure" do
    setup ctx do
      figure = %BrainWall.Figure{
        edges: [{0, 1}, {1, 2}, {2, 0}],
        vertices: [{0, 0}, {0, 50}, {50, 0}]
      }

      problem = %BrainWall.Problem{hole: ctx.hole, figure: figure, epsilon: 0}
      solution = Solution.new(problem)

      [figure: figure, solution: solution]
    end

    test "fix a point", ctx do
      new_solution = Solution.fix_point(ctx.solution, 0, {5, 5})

      fixed_points = Solution.get_fixed_points_with_indices(new_solution)
      assert 1 == fixed_points |> Enum.count()

      assert {{5, 5}, 0} == fixed_points |> Enum.at(0)
    end

    test "check is_pose_point_at_index_fixed?", ctx do
      assert false == Solution.is_pose_point_at_index_fixed?(ctx.solution, 0)
      assert false == Solution.is_pose_point_at_index_fixed?(ctx.solution, 1)
      assert false == Solution.is_pose_point_at_index_fixed?(ctx.solution, 2)

      new_solution = Solution.fix_point(ctx.solution, 0, {5, 5})
      assert true == Solution.is_pose_point_at_index_fixed?(new_solution, 0)
      assert false == Solution.is_pose_point_at_index_fixed?(new_solution, 1)
      assert false == Solution.is_pose_point_at_index_fixed?(new_solution, 2)
    end

    test "get list of unfixed points connected to fixed points", ctx do
      assert [] == Solution.get_unfixed_point_indices_connected_to_fixed_points(ctx.solution)
    end

    test "fix a point and get list of unfixed points connected to fixed points", ctx do
      solution = Solution.fix_point(ctx.solution, 0, {5, 5})

      unfixed = Solution.get_unfixed_point_indices_connected_to_fixed_points(solution)

      assert 2 == unfixed |> Enum.count()
      assert [1, 2] == unfixed |> Enum.sort()
    end
  end
end
