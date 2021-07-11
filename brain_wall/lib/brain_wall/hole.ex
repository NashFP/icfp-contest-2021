defmodule BrainWall.Hole do
  defstruct [:points, :edges]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{points: [Cartesian.point()]}

  def make_circular(points) do
    Enum.concat(points, [List.first(points)])
  end

  def make_edges(points) do
    circ = make_circular(points)
    Enum.zip(circ, Enum.drop(circ,1))
  end

  @doc """
  Parses out a `Hole.t()` from a raw JSON-decoded problem map
  """
  def new(%{"hole" => [_ | _]} = problem_map) do
    hole = problem_map["hole"]

    %__MODULE__{
      points: hole |> Cartesian.to_points(),
      edges: make_edges(Cartesian.to_points(hole))
    }
  end
end
