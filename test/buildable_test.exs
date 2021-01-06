defmodule BuildableTest do
  use ExUnit.Case
  doctest Buildable

  test "Foo basic functions" do
    assert Foo.empty() == %Foo{}
    assert Foo.empty(foo: :bar) == %Foo{}

    assert Foo.new(a: 1, b: 2, c: 3) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([a: 1, b: 2, c: 3], foo: :bar) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([], foo: :bar) == %Foo{}

    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    foo = %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Foo.default(:strategy) == nil
    assert Foo.default(:insert_position) == :first
    assert Foo.extract(foo) == Foo.extract(foo, :first)
    assert Foo.extract(foo, :first) == {:ok, {:a, 2}, %{__struct__: Foo, map: %{b: 4, c: 6}}}

    assert Foo.extract(foo, :last) == {:ok, {:c, 6}, %{__struct__: Foo, map: %{a: 2, b: 4}}}

    assert Foo.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
  end

  test "Build basic functions" do
    foo = %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
    assert Build.to_empty(foo, []) == %Foo{}

    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.into(%Foo{}, 1..3, fn v -> {:"#{v}", v * 2} end) ==
             %{__struct__: Foo, map: %{"1": 2, "2": 4, "3": 6}}

    foo = %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.extract(foo) == Build.extract(foo, :first)
    assert Build.extract(foo, :first) == {:ok, {:a, 2}, %{__struct__: Foo, map: %{b: 4, c: 6}}}

    assert Build.extract(foo, :last) == {:ok, {:c, 6}, %{__struct__: Foo, map: %{a: 2, b: 4}}}

    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
  end
end
