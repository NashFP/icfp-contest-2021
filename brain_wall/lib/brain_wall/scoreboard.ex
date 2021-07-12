defmodule BrainWall.Scoreboard do
  use GenServer

  require Logger

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def report_score(solution) do
    GenServer.call(__MODULE__, {:report_score, solution})
  end

  def init(_) do
    {:ok, %{problem_leaders: %{}, problem_generations: %{}}}
  end

  def handle_call({:report_score, solution}, _, state) do
    problem_number = solution.problem.problem_number

    current_leader = Map.get(state.problem_leaders, problem_number)

    new_state =
      if current_leader == nil or current_leader.score > solution.score do
        new_state =
          state
          |> Map.update!(:problem_leaders, fn current ->
            Map.put(current, problem_number, solution)
          end)
          |> Map.update!(:problem_generations, fn current ->
            Map.update(current, problem_number, 1, fn cg ->
              BrainWall.Solution.save(solution)

              cg + 1
            end)
          end)

        Logger.info("New leader for #{problem_number}: #{solution.score}")
        new_state
      else
        state
      end

    {:reply, :ok, new_state}
  end
end
