defmodule BrainWall.Validation do
  def validate(problem, solution_vertices)
      when length(problem.figure.vertices) == length(solution_vertices) do
    input_vertices = List.to_tuple(problem.figure.vertices)
    output_vertices = List.to_tuple(solution_vertices)

    for [i, j] <- problem.figure.edges do
      vi = elem(input_vertices, i)
      vj = elem(input_vertices, j)

      vi_prime = elem(output_vertices, i)
      vj_prime = elem(output_vertices, j)

      ratio_left = abs(squared_distance(vi_prime, vj_prime) / squared_distance(vi, vj) - 1)
      ratio_right = problem.epsilon / 1_000_000

      if ratio_left > ratio_right do
        IO.puts("The edge [#{i}, #{j}] was stretched too much")
      end
    end

    :todo
  end

  def squared_distance([px, py], [qx, qy]) do
    diff_x = px - qx
    diff_y = py - qy
    diff_x * diff_x + diff_y * diff_y
  end

  def point_in_polygon([px, py], hole) do
    hole_vertices = List.to_tuple(hole)

    Enum.reduce(0..(tuple_size(hole_vertices) - 1), false, fn v, inside ->
      [p1x, p1y] = elem(hole_vertices, v)
      [p2x, p2y] = elem(hole_vertices, rem(v + 1, tuple_size(hole_vertices)))

      if py > min(p1y, p2y) and py <= max(p1y, p2y) and px <= max(p1x, p2x) and p1y != p2y do
        inters = (py - p1y) * (p2x - p1x) / (p2y - p1y) + p1x

        if p1x == p2x or px <= inters do
          not inside
        else
          inside
        end
      else
        inside
      end
    end)
  end
end
