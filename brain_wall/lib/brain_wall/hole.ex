defmodule BrainWall.Hole do
  defstruct [:points]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{points: [Cartesian.point()]}

  @doc """
  Given a problem map
  """

  def new(problem_map) do
    hole = problem_map["hole"]

    %__MODULE__{
      points: hole |> Cartesian.to_points()
    }
  end
end
