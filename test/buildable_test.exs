defmodule BuildableTest do
  use ExUnit.Case
  doctest Buildable

  defmodule Foo do
    @behaviour Buildable

    import Buildable.Util, only: [is_position: 1]

    use Buildable.Use

    @impl true
    def empty(_options \\ []) do
      %{}
    end

    @impl true
    def put(map, {key, value}, position) when is_position(position) do
      Map.put(map, key, value)
    end

    @impl true
    def pop(map, position) when map_size(map) > 0 and position in [:start, nil] do
      [key | _] = Map.keys(map)
      {value, rest} = Map.pop(map, key)
      {:ok, {key, value}, rest}
    end

    def pop(map, :end) when map_size(map) > 0 do
      [key | _] = :lists.reverse(Map.keys(map))
      {value, rest} = Map.pop(map, key)
      {:ok, {key, value}, rest}
    end

    def pop(map, position) when map_size(map) == 0 and is_position(position) do
      :error
    end

    @impl true
    def reverse(list) do
      list
    end
  end
end
