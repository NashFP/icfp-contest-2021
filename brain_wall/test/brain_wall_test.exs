defmodule BrainWallTest do
  use ExUnit.Case
  doctest BrainWall

  test "greets the world" do
    assert BrainWall.hello() == :world
  end
end
