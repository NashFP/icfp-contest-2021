defmodule BrainWall.Solution do
  alias BrainWall.Cartesian

  defstruct [:problem, :pose_points, :score]

  @type pose_point :: %{point: Cartesian.point(), fixed: boolean()}
  @type t :: %__MODULE__{
          problem: BrainWall.Problem.t(),
          pose_points: [pose_point()],
          score: nil | non_neg_integer()
        }

  @spec new(problem :: BrainWall.Problem.t()) :: t()
  def new(problem) do
    initial_pose_points =
      problem.figure.vertices
      |> Enum.map(fn v -> %{point: v, fixed: false} end)

    %__MODULE__{
      problem: problem,
      pose_points: initial_pose_points,
      score: nil
    }
  end

  @spec fix_point(
          solution :: t(),
          vertex_index :: non_neg_integer(),
          point :: Cartesian.point()
        ) :: t()
  def fix_point(solution, vertex_index, point) do
    new_pose_points =
      List.replace_at(solution.pose_points, vertex_index, %{point: point, fixed: true})

    %__MODULE__{solution | pose_points: new_pose_points}
  end

  @spec get_fixed_points_with_indices(solution :: t()) :: [
          {Cartesian.point(), non_neg_integer()}
        ]
  def get_fixed_points_with_indices(solution) do
    solution.pose_points
    |> Enum.with_index()
    |> Enum.filter(fn {pp, _index} -> pp.fixed == true end)
    |> Enum.map(fn {pp, index} -> {pp.point, index} end)
  end

  @spec is_pose_point_at_index_fixed?(solution :: t(), index :: non_neg_integer()) :: boolean()
  def is_pose_point_at_index_fixed?(solution, index) do
    solution
    |> get_pose_point_by_index(index)
    |> Map.get(:fixed)
  end

  @spec get_pose_point_by_index(solution :: t(), index :: non_neg_integer()) :: pose_point()
  def get_pose_point_by_index(solution, index) do
    solution.pose_points
    |> Enum.at(index)
  end

  def compute_score(solution) do
    solution
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
    |> Enum.reduce(nil, fn {point, distance}, acc ->
      possible_points =
        Cartesian.get_points_in_circle(point, distance, solution.problem.episilon)
        |> MapSet.new()

      if acc == nil do
        possible_points
      else
        MapSet.intersection(acc, possible_points)
      end
    end)
  end
end
