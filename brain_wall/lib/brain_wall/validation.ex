defmodule BrainWall.Validation do
  alias BrainWall.{Cartesian, Figure}

  def validate(problem, solution_vertices)
      when length(problem.figure.vertices) == length(solution_vertices) do
    input_vertices = problem.figure.vertices
    output_vertices = Cartesian.to_points(solution_vertices)

    problem.figure.edges
    |> Enum.map(fn {i, j} ->
      vi = Enum.at(input_vertices, i)
      vj = Enum.at(input_vertices, j)

      vi_prime = Enum.at(output_vertices, i)
      vj_prime = Enum.at(output_vertices, j)

      ratio_left =
        abs(
          Cartesian.squared_distance(vi_prime, vj_prime) / Cartesian.squared_distance(vi, vj) - 1
        )

      ratio_right = problem.epsilon / 1_000_000

      if ratio_left > ratio_right do
        IO.puts("The edge [#{i}, #{j}] was stretched too much")
        false
      else
        true
      end
    end)
    |> Enum.all?()
  end
end
