defmodule BuildTest do
  use ExUnit.Case
  doctest Build

  setup_all _ do
    %{
      foo: %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}},
      map: %{a: 2, b: 4, c: 6}
    }
  end

  test "extract", %{foo: foo, map: map} do
    assert Build.extract(foo) == Build.extract(foo, :first)
    assert Build.extract(foo, :first) == {:ok, {:a, 2}, %{__struct__: Foo, map: %{b: 4, c: 6}}}
    assert Build.extract(foo, :last) == {:ok, {:c, 6}, %{__struct__: Foo, map: %{a: 2, b: 4}}}

    assert Build.extract(map) == {:ok, {:a, 2}, %{b: 4, c: 6}}
  end

  test "insert", %{foo: foo} do
    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
    assert Build.insert(foo, {:d, 8}) == %{__struct__: Foo, map: %{a: 2, b: 4, c: 6, d: 8}}
  end

  test "into/2", %{foo: foo} do
    assert Build.into([], 1..5) == [1, 2, 3, 4, 5]
    assert Build.into(%{}, a: 1, b: 2) == %{a: 1, b: 2}
    assert Build.into(%{c: 3}, a: 1, b: 2) == %{a: 1, b: 2, c: 3}
    assert Build.into([], %{a: 1, b: 2}) == [a: 1, b: 2]
    assert Build.into([], 1..3) == [1, 2, 3]
    assert Build.into("", ["H", "i"]) == "Hi"

    assert Build.into(foo, a: 1, b: 2, x: 100) == %{
             __struct__: Foo,
             map: %{a: 1, b: 2, c: 6, x: 100}
           }
  end

  test "into/3", %{foo: foo} do
    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.into(%Foo{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}}

    assert Build.into([], 1..5, fn x -> x * 2 end) == [2, 4, 6, 8, 10]
    assert Build.into("numbers: ", 1..3, &to_string/1) == "numbers: 123"

    assert Build.into([], [1, 2, 3], fn x -> x * 2 end) == [2, 4, 6]
    assert Build.into("numbers: ", [1, 2, 3], &to_string/1) == "numbers: 123"

    assert_raise FunctionClauseError, fn ->
      Build.into(%{a: 1}, [2, 3], & &1)

      assert Build.into(foo, a: 1, b: 2, x: 100) == Build.into(foo, [a: 1, b: 2, x: 100], & &1)
    end
  end

  test "reduce/3", %{foo: foo} do
    # here we rely delegate to the implementation of Enumerable.Foo
    assert Build.reduce(foo, Foo.empty(), &Build.insert(&2, &1)) == foo
  end

  test "to_empty", %{foo: foo} do
    assert Build.to_empty(foo, []) == %Foo{}
  end
end
