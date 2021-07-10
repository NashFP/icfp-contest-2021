defmodule BrainWall.Cartesian do
  @type point :: {integer(), integer()}

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

  @spec point_in_polygon?(point :: point(), [point()]) :: boolean()
  def point_in_polygon?({px, py}, [{_, _} | _] = polygon) do
    topo_polygon = %Geo.Polygon{coordinates: [polygon]}
    topo_point = %Geo.Polygon{coordinates: [[{px, py}]]}

    Topo.contains?(topo_polygon, topo_point)
  end

  @spec squared_distance(point :: point(), point()) :: integer()
  def squared_distance({px, py}, {qx, qy}) do
    diff_x = px - qx
    diff_y = py - qy
    diff_x * diff_x + diff_y * diff_y
  end
end
