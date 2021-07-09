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

  defp squared_distance([px, py], [qx, qy]) do
    diff_x = px - qx
    diff_y = py - qy
    diff_x * diff_x + diff_y * diff_y
  end
end
