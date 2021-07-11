defmodule BrainWall.Figure do
  defstruct [:edges, :vertices]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{edges: [{Cartesian.edge()}], vertices: [Cartesian.point()]}

  @doc """
  Parses out a `Figure.t()` from a raw JSON-decoded problem map
  """
  def new(%{"figure" => %{"edges" => [_ | _], "vertices" => [_ | _]}} = problem_map) do
    figure = problem_map["figure"]

    %__MODULE__{
      edges: figure["edges"] |> Cartesian.to_edges(),
      vertices: figure["vertices"] |> Cartesian.to_points()
    }
  end
end
