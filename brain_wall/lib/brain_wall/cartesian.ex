defmodule BrainWall.Cartesian do
  @type point :: {integer(), integer()}
  @type edge :: {non_neg_integer(), non_neg_integer()}

  @spec get_points_in_circle(point :: point(), integer(), integer()) :: [point :: point()]
  def get_points_in_circle({x, y}, dist, epsilon) do
    # what is the longest segment possible in either the x or y direction?
    largest_segment = Kernel.trunc(:math.sqrt(dist / 2))
    e = epsilon / 1_000_000.0

    # find the lower end of the possible pairs of segment lengths that fall within
    # the desired distance & epsilon
    starting_points =
      Enum.filter(0..largest_segment, fn i ->
        # find the distance that pairs with i
        partner = Kernel.trunc(:math.sqrt(dist - i * i))

        # make sure their combined distance is within the desired epsilon
        point_dist = partner * partner + i * i
        ratio = abs(point_dist / dist - 1)
        ratio <= e
      end)

    # make a list of all the possible combinations of these segments from the
    # given x,y
    Enum.flat_map(starting_points, fn p1 ->
      p2 = Kernel.trunc(:math.sqrt(dist - p1 * p1))
      [{x - p1, y - p2}, {x - p1, y + p2}, {x + p1, y - p2}, {x + p1, y + p2}]
    end)
  end

  @spec point_in_polygon?(point :: point(), [point()]) :: boolean()
  def point_in_polygon?({px, py}, [{_, _} | _] = polygon) do
    topo_polygon = %Geo.Polygon{coordinates: [polygon]}
    topo_point = %Geo.Polygon{coordinates: [[{px, py}]]}

    Topo.contains?(topo_polygon, topo_point)
  end

  @spec line_in_polygon?(line :: {point(), point}, [point()]) :: boolean()
  def line_in_polygon?({{ax, ay}, {bx, by}}, [{_, _} | _] = polygon) do
    topo_polygon = %Geo.Polygon{coordinates: [polygon]}
    topo_line = %Geo.Polygon{coordinates: [[{ax, ay}, {bx, by}]]}

    Topo.contains?(topo_polygon, topo_line)
  end

  @spec squared_distance(point :: point(), point()) :: integer()
  def squared_distance({px, py}, {qx, qy}) do
    diff_x = px - qx
    diff_y = py - qy
    diff_x * diff_x + diff_y * diff_y
  end

  def to_edges([[x, y] | _] = list) when is_integer(x) and is_integer(y) do
    list |> Enum.map(&to_edge/1)
  end

  def to_edges([]) do
    []
  end

  @spec to_edge(list()) :: edge()
  defp to_edge([x, y]) when is_integer(x) and is_integer(y) do
    {x, y}
  end

  def to_points([[x, y] | _] = list) when is_integer(x) and is_integer(y) do
    list |> Enum.map(&to_point/1)
  end

  def to_points([]) do
    []
  end

  @spec to_point(list()) :: point()
  defp to_point([x, y]) when is_integer(x) and is_integer(y) do
    {x, y}
  end
end
