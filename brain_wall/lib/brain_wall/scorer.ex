defmodule BrainWall.Scorer do
  alias BrainWall.Cartesian

  def dislikes(hole, pose_points) do
    hole.points
    |> Enum.map(fn {_, _} = hole_point ->
      candidates =
        for(pose_point <- pose_points, do: {hole_point, pose_point})
        |> Enum.reject(fn x -> intersects?(edges(hole.points), x) end)

      for(
        {hole_point, pose_point} <- candidates,
        do: Cartesian.squared_distance(hole_point, pose_point)
      )
      |> Enum.min()
    end)
    |> Enum.sum()
  end

  def edges([a, b | tail]) do
    [{a, b} | edges([b | tail])]
  end

  def edges([_]) do
    []
  end

  def intersects?(e, {{hx, hy}, {px, py}}) do
    e
    |> Enum.any?(fn {{x1, y1}, {x2, y2}} ->
      {_, t, _} = SegSeg.intersection({x1, y1}, {x2, y2}, {hx, hy}, {px, py})
      t == :interior
    end)
  end
end
