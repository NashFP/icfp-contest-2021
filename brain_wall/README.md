# BrainWall
```sh
iex -S mix
```
```elixir
problem_1 = BrainWall.Problem.get(1)
solution_1 = [
    [21, 28], [31, 28], [31, 87], [29, 41], [44, 43], [58, 70],
    [38, 79], [32, 31], [36, 50], [39, 40], [66, 77], [42, 29],
    [46, 49], [49, 38], [39, 57], [69, 66], [41, 70], [39, 60],
    [42, 25], [40, 35]
]

BrainWall.Validation.validate(problem_1, solution_1)
```