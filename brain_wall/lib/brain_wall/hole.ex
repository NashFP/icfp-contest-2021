defmodule BrainWall.Hole do
  defstruct [:points]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{points: [Cartesian.point()]}

  @doc """
  Parses out a `Hole.t()` from a raw JSON-decoded problem map
  """
  def new(%{"hole" => [_ | _]} = problem_map) do
    hole = problem_map["hole"]

    %__MODULE__{
      points: hole |> Cartesian.to_points()
    }
  end
end
