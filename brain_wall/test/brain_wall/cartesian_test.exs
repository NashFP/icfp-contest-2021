defmodule BrainWall.CartesianTest do
  use ExUnit.Case

  alias BrainWall.Cartesian

  doctest Cartesian

  test "simple point in polygon?" do
    poly = [{0, 0}, {0, 100}, {100, 100}, {100, 0}]

    assert(Cartesian.point_in_polygon?({50, 50}, poly))
    assert(Cartesian.point_in_polygon?({0, 0}, poly))
    assert(Cartesian.point_in_polygon?({100, 0}, poly))
    assert(Cartesian.point_in_polygon?({100, 100}, poly))
    assert(Cartesian.point_in_polygon?({100, 0}, poly))

    refute(Cartesian.point_in_polygon?({200, 200}, poly))
    refute(Cartesian.point_in_polygon?({200, 50}, poly))
    refute(Cartesian.point_in_polygon?({50, 200}, poly))
  end

  test "complex point in polygon?" do
    poly = [{4, 1}, {8, 3}, {5, 3}, {7, 7}, {3, 8}, {5, 5}, {1, 4}, {3, 4}]
    refute(Cartesian.point_in_polygon?({0, 0}, poly))
    assert(Cartesian.point_in_polygon?({4, 2}, poly))
    refute(Cartesian.point_in_polygon?({6, 4}, poly))
    refute(Cartesian.point_in_polygon?({3, 5}, poly))
    assert(Cartesian.point_in_polygon?({3, 4}, poly))
    assert(Cartesian.point_in_polygon?({5, 4}, poly))
    refute(Cartesian.point_in_polygon?({8, 8}, poly))
  end

  test "line in polygon" do
    poly = [{0, 0}, {0, 100}, {100, 100}, {100, 0}]

    assert Cartesian.line_in_polygon?({{10, 10}, {90, 90}}, poly)
    assert Cartesian.line_in_polygon?({{0, 0}, {100, 100}}, poly)
    refute(Cartesian.line_in_polygon?({{120, 120}, {150, 150}}, poly))
    refute(Cartesian.line_in_polygon?({{50, 50}, {150, 150}}, poly))
    refute(Cartesian.line_in_polygon?({{150, 50}, {50, 150}}, poly))
    refute(Cartesian.line_in_polygon?({{50, 50}, {50, 150}}, poly))
  end

  test "Check min distance" do
    point = {50, 100}
    assert 0 == Cartesian.squared_distance(point, {50, 100})
    assert 1 == Cartesian.squared_distance(point, {50, 99})
    assert 4 == Cartesian.squared_distance(point, {50, 98})
    assert 2 == Cartesian.squared_distance(point, {49, 99})
    assert 8 == Cartesian.squared_distance(point, {48, 98})
  end
end
