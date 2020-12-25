defmodule BuildableTest do
  use ExUnit.Case
  doctest Buildable

  test "basic functions" do
    assert Foo.new(a: 1, b: 2, c: 3) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}

    assert Foo.into([a: 1, b: 2, c: 3], %Foo{}, fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}
  end
end
