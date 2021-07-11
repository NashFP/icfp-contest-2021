defmodule BrainWall.Problem do
  defstruct [:hole, :figure, :epsilon, :problem_number]

  alias BrainWall.{Figure, Hole}

  @type t :: %__MODULE__{hole: Hole.t(), figure: Figure.t(), epsilon: any(), problem_number: integer()}

  @spec get(problem_number :: integer) :: t()
  def get(problem_number) do
    problem_map =
      File.read!("../problems/#{problem_number}.json")
      |> Jason.decode!()

    %__MODULE__{
      hole: Hole.new(problem_map),
      figure: Figure.new(problem_map),
      epsilon: problem_map["epsilon"],
      problem_number: problem_number
    }
  end
end
