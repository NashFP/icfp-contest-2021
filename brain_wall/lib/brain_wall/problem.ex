defmodule BrainWall.Problem do
  defstruct [:hole, :figure, :epsilon]

  alias BrainWall.{Figure, Hole}

  @type t :: %__MODULE__{hole: Hole.t(), figure: Figure.t(), epsilon: any()}

  def get(number) do
    problem_map =
      File.read!("../problems/#{number}.json")
      |> Jason.decode!()

    %__MODULE__{
      hole: Hole.new(problem_map),
      figure: Figure.new(problem_map),
      epsilon: problem_map["epsilon"]
    }
  end
end
