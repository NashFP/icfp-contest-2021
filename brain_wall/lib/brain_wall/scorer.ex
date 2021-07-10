defmodule BrainWall.Scorer do
  def dislikes(hole, pose) do
    for h <- hole.points do
      candidates =
        for(p <- pose, do: {h, p})
        |> Enum.reject(fn x -> intersects?(edges(hole.points), x) end)

      for({h, p} <- candidates, do: BrainWall.Validation.squared_distance(h, p)) |> Enum.min()
    end
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
    |> Enum.any?(fn {[x1, y1], [x2, y2]} ->
      {_, t, _} = SegSeg.intersection({x1, y1}, {x2, y2}, {hx, hy}, {px, py})
      t == :interior
    end)
  end
end
