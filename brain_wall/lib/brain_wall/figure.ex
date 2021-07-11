defmodule BrainWall.Figure do
  defstruct [:edges, :vertices, :edge_distances]

  alias BrainWall.Cartesian

  @type t :: %__MODULE__{
          edges: [{Cartesian.edge()}],
          vertices: [Cartesian.point()],
          edge_distances: map()
        }

  @doc """
  Parses out a `Figure.t()` from a raw JSON-decoded problem map
  """
  def new(%{"figure" => %{"edges" => [_ | _], "vertices" => [_ | _]}} = problem_map) do
    figure = problem_map["figure"]

    vertices = figure["vertices"] |> Cartesian.to_points()
    edges = figure["edges"] |> Cartesian.to_edges()

    edge_distances =
      edges
      |> Enum.map(fn {from, to} ->
        p1 = Enum.at(vertices, from)
        p2 = Enum.at(vertices, to)
        distance = BrainWall.Cartesian.squared_distance(p1, p2)

        [
          {from, {to, distance}},
          {to, {from, distance}}
        ]
      end)
      |> List.flatten()
      |> Enum.group_by(fn {k, _} -> k end, fn {_, {other, distance}} ->
        {other, distance}
      end)
      |> Enum.map(fn {k, v} -> {k, Map.new(v)} end)
      |> Map.new()

    %__MODULE__{
      edges: edges,
      vertices: vertices,
      edge_distances: edge_distances
    }
  end
end
