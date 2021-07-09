defmodule BrainWallTest do
  use ExUnit.Case
  doctest BrainWall

  test "point_in_polygon" do
    poly = [[4,1], [8,3], [5,3], [7,7], [3,8], [5,5], [1,4], [3,4]]
    refute(BrainWall.Validation.point_in_polygon([0,0], poly))
    assert(BrainWall.Validation.point_in_polygon([4,2], poly))
    refute(BrainWall.Validation.point_in_polygon([6,4], poly))
    refute(BrainWall.Validation.point_in_polygon([3,5], poly))
    refute(BrainWall.Validation.point_in_polygon([3,4], poly))
    assert(BrainWall.Validation.point_in_polygon([5,4], poly))
    refute(BrainWall.Validation.point_in_polygon([8,8], poly))
  end

end
