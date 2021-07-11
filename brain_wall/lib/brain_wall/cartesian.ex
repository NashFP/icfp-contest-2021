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

  def point_on_line?({px,py}, {{p1x,p1y},{p2x,p2y}}) do
    if orientation({px,py}, {p1x,p1y}, {p2x,p2y}) == 0 do
      px >= min(p1x,p2x) and px <= max(p1x,p2x) and
      py >= min(p1y,p2y) and py <= max(p1y,p2y)
    else
      false
    end
  end

  @spec point_in_polygon?(point :: point(), [{point(),point()}]) :: boolean()
  def point_in_polygon?({px, py}, polygon) do
    Enum.any?(polygon, fn {p1,p2} ->
      point_on_line?({px,py}, {p1,p2})
    end) or
    Enum.reduce(polygon, false, fn {{p1x,p1y},p2}, crossed ->
      if intersects?({{px,py},{9999999999,py}}, {{p1x,p1y},p2}, true) and
         p1y != py do
           not crossed
      else
        crossed
      end
    end)
  end

  def on_segment?({px,py}, {qx,qy}, {rx,ry}) do
    qx <= max(px,rx) && qx >= min(px,rx) && qy <= max(py,ry) && qy >= min(py,ry)
  end

  def orientation({px,py}, {qx,qy}, {rx,ry}) do
    val = (qy-py) * (rx-qx) - (qx-px) * (ry-qy)
    if val == 0 do
      0
    else
      if val > 0 do
        1
      else
        2
      end
    end
  end

  def intersects?({p1,q1},{p2,q2}, allow_colinear) do
    o1 = orientation(p1, q1, p2)
    o2 = orientation(p1, q1, q2)
    o3 = orientation(p2, q2, p1)
    o4 = orientation(p2, q2, q1)

    # if you want to consider lines intersecting if an endpoint of one lies
    # on the other line, use this:
    # if o1 != o2 and o3 != o4 do
    #   true
    # else
    #   (o1 == 0 and on_segment?(p1, p2, q1)) ||
    #   (o2 == 0 and on_segment?(p1, q2, q1)) ||
    #   (o3 == 0 and on_segment?(p2, p1, q2)) ||
    #   (o4 == 0 and on_segment?(p2, q1, q2))
    # end

    # for our purposes, though, we consider the endpoints being co-linear to mean
    # no intersection
    o1 != o2 and o3 != o4 and (allow_colinear or (o1 != 0 and o2 != 0 and o3 != 0 and o4 != 0))
  end

  @spec line_in_polygon?(line :: {point(), point}, [{point(),point()}]) :: boolean()
  def line_in_polygon?({{ax, ay}, {bx, by}}, polygon) do
    point_in_polygon?({ax,ay}, polygon) and point_in_polygon?({bx,by}, polygon) and
    Enum.all?(polygon, fn {p1,q1} ->
      not intersects?({p1,q1},{{ax,ay},{bx,by}}, false)
    end)
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
