alias BrainWall.Solution

solution =
  BrainWall.Problem.get(1)
  |> Solution.new()

last_pose_point_index = (solution.pose_points |> Enum.count()) - 1

range = 0..last_pose_point_index

Benchee.run(%{
  "before" => fn ->
    range |> Enum.map(fn index -> Solution.get_pose_point_by_index(solution, index) end)
  end,
  "after" => fn ->
    range |> Enum.map(fn index -> Solution.get_pose_point_by_index_2(solution, index) end)
  end
})
