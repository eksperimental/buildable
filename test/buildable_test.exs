defmodule BuildableTest do
  use ExUnit.Case
  doctest Buildable

  setup_all _ do
    %{
      foo: %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}
    }
  end

  test "Foo basic functions", %{foo: foo} do
    assert Foo.empty() == %Foo{}
    assert Foo.empty(foo: :bar) == %Foo{}

    assert Foo.new(a: 1, b: 2, c: 3) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([a: 1, b: 2, c: 3], foo: :bar) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([], foo: :bar) == %Foo{}

    assert Foo.default(:insert_position) == :first
    assert Foo.extract(foo) == Foo.extract(foo, :first)
    assert Foo.extract(foo, :first) == {:ok, {:a, 2}, %{__struct__: Foo, map: %{b: 4, c: 6}}}

    assert Foo.extract(foo, :last) == {:ok, {:c, 6}, %{__struct__: Foo, map: %{a: 2, b: 4}}}

    assert Foo.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
  end
end
