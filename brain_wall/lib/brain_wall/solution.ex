defmodule BrainWall.Solution do
  alias BrainWall.Cartesian

  defstruct [:problem, :pose_points, :score]

  @type pose_point :: %{point: Cartesian.point(), fixed: boolean()}
  @type t :: %__MODULE__{
          problem: BrainWall.Problem.t(),
          pose_points: %{required(non_neg_integer()) => pose_point()},
          score: nil | non_neg_integer()
        }

  @spec new(problem :: BrainWall.Problem.t()) :: t()
  def new(problem) do
    pose_points =
      problem.figure.vertices
      |> Enum.with_index(fn v, i -> {i, %{point: v, fixed: false}} end)
      |> Map.new()

    %__MODULE__{
      problem: problem,
      pose_points: pose_points,
      score: nil
    }
  end

  def pose_points_to_ints(solution) do
    Enum.map(solution.pose_points, fn {_k, %{point: {x, y}}} ->
      [x, y]
    end)
  end

  def save(solution) do
    File.write!(
      "../solutions/#{solution.problem.problem_number}.#{solution.score}.json",
      Jason.encode!(%{vertices: pose_points_to_ints(solution)})
    )
  end

  @spec get_best_of_solutions(solutions :: [t()], default :: t()) :: t()
  def get_best_of_solutions(solutions, default) do
    winner =
      solutions
      |> Enum.reject(fn s -> s.score == nil end)
      |> Enum.sort_by(fn s -> s.score end, :desc)
      |> Enum.at(0, default)

    if winner != nil and winner.score != nil do
      BrainWall.Scoreboard.report_score(winner)
    end

    winner
  end

  @spec get_best_solution(solution :: t(), solution :: t()) :: t()
  def get_best_solution(solution_a, solution_b) do
    winner =
      if solution_a.score == nil do
        solution_b
      else
        if solution_b.score == nil do
          solution_a
        else
          if solution_a.score < solution_b.score do
            solution_a
          else
            solution_b
          end
        end
      end

    if winner != nil and winner.score != nil do
      BrainWall.Scoreboard.report_score(winner)
    end

    winner
  end

  @spec fix_point(
          solution :: t(),
          vertex_index :: non_neg_integer(),
          point :: Cartesian.point()
        ) :: t()
  def fix_point(solution, vertex_index, point) do
    new_pose_points =
      Map.update!(solution.pose_points, vertex_index, fn pp ->
        %{pp | fixed: true, point: point}
      end)

    %__MODULE__{solution | pose_points: new_pose_points}
  end

  @spec get_fixed_points_with_indices(solution :: t()) :: [
          {Cartesian.point(), non_neg_integer()}
        ]
  def get_fixed_points_with_indices(solution) do
    solution.pose_points
    |> Enum.filter(fn {_index, pp} -> pp.fixed end)
    |> Enum.map(fn {index, pp} -> {pp.point, index} end)
  end

  @spec is_pose_point_at_index_fixed?(solution :: t(), index :: non_neg_integer()) :: boolean()
  def is_pose_point_at_index_fixed?(solution, index) do
    solution
    |> get_pose_point_by_index(index)
    |> Map.get(:fixed)
  end

  @spec get_pose_point_by_index(solution :: t(), index :: non_neg_integer()) :: pose_point()
  def get_pose_point_by_index(solution, index) do
    solution.pose_points[index]
  end

  def compute_score(solution) do
    pose_point_values = solution.pose_points |> Map.values()

    %__MODULE__{
      solution
      | score: BrainWall.Scorer.dislikes(solution.problem.hole, pose_point_values)
    }
  end

  def get_unfixed_point_indices_connected_to_fixed_points(solution) do
    solution.problem.figure.edges
    |> Enum.reduce(MapSet.new(), fn {from, to}, acc ->
      from_fixed = is_pose_point_at_index_fixed?(solution, from)
      to_fixed = is_pose_point_at_index_fixed?(solution, to)

      if from_fixed and not to_fixed do
        MapSet.put(acc, to)
      else
        if to_fixed and not from_fixed do
          MapSet.put(acc, from)
        else
          acc
        end
      end
    end)
    |> MapSet.to_list()

    # in edges: [{0, 1}, {1, 2}, {2, 0}]
    # Fixed 0
    # out -> [{0,50}}, 1}, {{50,0}, 2}] but point uneeded because they will have to change soon
    # better out -> [1, 2]
  end

  @doc """
  of the edges that this point has, which edges are fixed on the other end?
  """
  @spec get_fixed_neighbors_for_unfixed_index(solution :: t(), unfixed_index :: non_neg_integer()) ::
          [
            %{point: Cartesian.point(), distance: non_neg_integer()}
          ]
  def get_fixed_neighbors_for_unfixed_index(solution, unfixed_index) do
    neighbors = solution.problem.figure.edge_distances[unfixed_index]

    neighbors
    |> Enum.filter(fn {n, _d} -> is_pose_point_at_index_fixed?(solution, n) end)
    |> Enum.map(fn {n, d} -> %{point: get_pose_point_by_index(solution, n), distance: d} end)
  end

  def get_possible_fixed_point_for_unfixed_index(solution, unfixed_index) do
    solution
    |> get_fixed_neighbors_for_unfixed_index(unfixed_index)
    |> Enum.map(fn %{point: point, distance: distance} ->
      Cartesian.get_points_in_circle(point.point, distance, solution.problem.epsilon)
      |> Enum.filter(fn new_point ->
        Cartesian.line_in_polygon?({point.point, new_point}, solution.problem.hole.edges)
      end)
      |> MapSet.new()
    end)
    |> Enum.reduce(fn acc1, acc2 ->
      MapSet.intersection(acc1, acc2)
    end)
    |> Enum.to_list()
  end
end
