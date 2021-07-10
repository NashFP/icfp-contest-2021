defmodule BrainWall.Figure do
  defstruct [:edges, :vertices]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{edges: [Cartesian.point()], vertices: [Cartesian.point()]}

  @doc """
  Given a problem map
  """

  def new(problem_map) do
    figure = problem_map["figure"]

    %__MODULE__{
      edges: figure["edges"] |> Cartesian.to_points(),
      vertices: figure["vertices"] |> Cartesian.to_points()
    }
  end
end
