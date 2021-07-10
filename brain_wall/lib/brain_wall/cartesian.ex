defmodule BrainWall.Cartesian do
  @type point :: {integer(), integer()}

  def to_points([[x, y] | _] = list) when is_integer(x) and is_integer(y) do
    list |> Enum.map(&to_point/1)
  end

  def to_points([]) do
    []
  end

  def to_point([x, y]) when is_integer(x) and is_integer(y) do
    {x, y}
  end
end
