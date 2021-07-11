defmodule BrainWall.Solvers.MarksSolver do
  alias BrainWall.Solution

  @moduledoc """
  this is what I think the logic is for placing a point:

  1)  of the edges that this point has, which edges are fixed on the other end?

  2)  for each of those edges, compute the possible places where the unfixed endpoint
      could go, treat these possible places as a set

  3)  find the intersection of those sets, these are the only places where the new
      point can be fixed

  4)  if the set is empty, backtrack to the previous point placement and try the
      next possibility

  5)  if the set is not empty, try each point, making sure that the point is within
      the hole, and that any edges that it completes do not cross any boundaries
      of the hole

  6)  if there are no more points to place, compute the score and if it is better
      than the previous score (we need to pass this up and down the call chain),
      return the score and the solution as the new best solution the logic for
      what point to try next is: for all the fixed points, get the list of points
      that they connect to that are not yet fixed, and compute the possible locations
      for those points, try fixing the point with the fewest possible locations.
      If there is a point that has 0 possible locations, we need to backtrack because
      that point can never be filled
  """

  def solve(problem) do
    solution = BrainWall.Solution.new(problem)

    fix_points = compute_initial_fix_points(solution)
    first_fixed_index = compute_first_fix_index(solution)

    fix_points
    |> Enum.reduce(solution, fn fp, acc ->
      new_solution = fix_point_and_solve(first_fixed_index, fp, acc)
      Solution.get_best_solution(acc, new_solution)
    end)
  end

  def get_points_in_hole(hole_points) do
    {{minx,_},{maxx,_}} = Enum.min_max_by(hole_points, fn {x,_y} -> x end)
    {{_,miny},{_,maxy}} = Enum.min_max_by(hole_points, fn {_x,y} -> y end)
    List.flatten(
      for x <- :lists.seq(minx, maxx, 5) do
         for y <- :lists.seq(miny, maxy, 5) do
           {x,y}
         end
        end)
  end
  def compute_initial_fix_points(solution) do
    get_points_in_hole(solution.problem.hole.points)
    |> Enum.filter(fn p -> BrainWall.Cartesian.point_in_polygon?(p, solution.problem.hole.edges) end)
  end

  def compute_first_fix_index(solution) do
    0
  end

  def fix_point_and_solve(first_fixed_index, fp, in_solution) do
    solution = Solution.fix_point(in_solution, first_fixed_index, fp)

    solution
    |> Solution.get_unfixed_point_indices_connected_to_fixed_points()
    |> case do
      [] ->
        Solution.compute_score(solution)

      unfixed ->        
        points_to_try = rank_unfixed_indices(solution, unfixed)
        points = List.first(points_to_try)
        if Enum.empty?(points) do
          solution
        else
          points
          |> Enum.reduce(solution, fn {unfixed_index, point}, acc ->
            Solution.get_best_solution(acc,
              fix_point_and_solve(unfixed_index, point, solution))
          end)
        end
    end
  end

  def rank_unfixed_indices(unfixed_indices, solution) do
    index_pairs = Enum.map(unfixed_indices, fn idx ->
      points = Solution.get_possible_fixed_point_for_unfixed_index(solution, idx)
      {idx,points}
    end)
    Enum.sort_by(index_pairs, fn {_idx1,points1}, {_idx2,points2} ->
      Enum.count(points1) < Enum.count(points2)
    end)
  end
end
