problem = BrainWall.Problem.get(19)

Benchee.run(%{
  "mark" => fn -> BrainWall.Solvers.MarksSolver.solve(problem) end
})
