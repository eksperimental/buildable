defmodule BuildableTest do
  use ExUnit.Case
  doctest Buildable

  setup_all _ do
    %{
      foo: %{__struct__: Foo, map: %{a: 2, b: 4, c: 6}},
      map: %{a: 2, b: 4, c: 6}
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

  test "Map basic functions", %{map: map} do
    assert Foo.empty() == %Foo{}
    assert Foo.empty(map: :bar) == %Foo{}

    assert Foo.new(a: 1, b: 2, c: 3) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([a: 1, b: 2, c: 3], map: :bar) == %{__struct__: Foo, map: %{a: 1, b: 2, c: 3}}
    assert Foo.new([], map: :bar) == %Foo{}

    assert Foo.default(:insert_position) == :first
    assert Foo.extract(map) == Foo.extract(map, :first)
    assert Foo.extract(map, :first) == {:ok, {:a, 2}, %{b: 4, c: 6}}

    assert Foo.extract(map, :last) == {:ok, {:c, 6}, %{a: 2, b: 4}}

    assert Foo.insert(map, {:d, 8}) == %{a: 2, b: 4, c: 6, d: 8}
  end

  test "failing implementation" do
    import ExUnit.CaptureIO

    msg =
      ~r/attributes @extract_position, @reversible\? are required to be defined in Buildable.Bogus before calling "use Buildable.Implementation"/

    ast =
      quote do
        defmodule Bogus do
          @moduledoc false
          @behaviour Buildable
          defstruct map: %{}
          use Buildable.Delegation
        end

        defimpl Buildable, for: Bogus do
          @insert_position :first
          # @extract_position :first
          @into_position :last
          # @reversible? false

          use Buildable.Implementation

          def empty(_options), do: %Bogus{}
          def extract(struct, _position), do: {:ok, :foo, struct}
          def insert(struct, {_key, _value}, _position), do: struct
        end
      end

    assert_raise Buildable.CompileError,
                 msg,
                 fn ->
                   capture_io(:stderr, fn -> Code.eval_quoted(ast) end)
                 end
  end
end
