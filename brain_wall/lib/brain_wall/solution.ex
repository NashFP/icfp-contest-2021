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
    solution.pose_points
    |> Enum.at(index)
    |> Map.get(:fixed)
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
end
