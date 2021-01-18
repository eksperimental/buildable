defmodule Foo do
  @moduledoc """
  Sample implementation of Buildable behaviour and protocol.
  """

  defstruct map: %{}

  @behaviour Buildable

  use Buildable.Delegation
end

defimpl Buildable, for: Foo do
  @insert_position :first
  @extract_position :first
  @into_position :last
  @reversible? false

  use Buildable.Implementation

  # defguard size(struct)
  #          when is_struct(struct, Foo) and is_map_key(struct, :map) and
  #                 map_size(:erlang.map_get(:map, struct))
  defguard size(struct) when map_size(:erlang.map_get(:map, struct))

  ##############################################
  # Behaviour callbacks

  @impl true
  def empty(_options), do: %Foo{}

  ##############################################
  # Protocol callbacks
  @impl true
  def extract(struct, position)

  def extract(%Foo{map: map} = struct, :first)
      when size(struct) > 0 do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def extract(%Foo{map: map} = struct, :last) when size(struct) > 0 do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def extract(struct, position) when size(struct) == 0 and is_position(position) do
    :error
  end

  @impl true
  def insert(%Foo{map: map} = struct, {key, value}, position) when is_position(position) do
    %{struct | map: put_in(map, [key], value)}
  end
end

defimpl Inspect, for: Foo do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#Foo<", to_doc(Map.to_list(struct.map), opts), ">"])
  end
end

defimpl Enumerable, for: Foo do
  def count(%Foo{map: map}) do
    {:ok, map_size(map)}
  end

  def member?(%Foo{map: map}, {key, value}) do
    {:ok, match?(%{^key => ^value}, map)}
  end

  def member?(_struct, _other) do
    {:ok, false}
  end

  def slice(_struct), do: {:error, __MODULE__}

  def reduce(%Foo{map: map}, acc, fun) do
    Enumerable.List.reduce(:maps.to_list(map), acc, fun)
  end
end
