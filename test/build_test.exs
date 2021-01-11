defmodule BuildTest do
  use ExUnit.Case
  doctest Buildable

  setup_all _ do
    %{
      foo: %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}
    }
  end

  test "extract", %{foo: foo} do
    assert Build.extract(foo) == Build.extract(foo, :first)
    assert Build.extract(foo, :first) == {:ok, {:a, 2}, %{__struct__: Foo, map: %{b: 4, c: 6}}}
    assert Build.extract(foo, :last) == {:ok, {:c, 6}, %{__struct__: Foo, map: %{a: 2, b: 4}}}
  end

  test "insert", %{foo: foo} do
    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
  end

  test "into/3" do
    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}
  end

  test "to_empty", %{foo: foo} do
    assert Build.to_empty(foo, []) == %Foo{}
  end
end
