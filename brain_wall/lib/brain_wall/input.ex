defmodule BrainWall.Input do
  defstruct [:hole, :figure, :epsilon]

  defmodule Figure do
    defstruct [:edges, :vertices]

    def new(figure) do
      %__MODULE__{edges: figure["edges"], vertices: figure["vertices"]}
    end
  end

  def get(number) do
    input =
      File.read!("../problems/#{number}.json")
      |> Jason.decode!()

    %__MODULE__{
      hole: input["hole"],
      figure: Figure.new(input["figure"]),
      epsilon: input["epsilon"]
    }
  end
end
