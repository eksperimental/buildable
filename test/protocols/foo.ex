defmodule Foo do
  @moduledoc """
  Sample implementation of Buildable behaviour and protocol.
  """

  defstruct map: %{}

  @behaviour Buildable

  use Buildable.Delegation
end

defimpl Buildable, for: Foo do
  use Buildable.Implementation

  @impl true
  def empty(_options \\ []) do
    %Foo{}
  end

  # defguard size(struct)
  #          when is_struct(struct, Foo) and is_map_key(struct, :map) and
  #                 map_size(:erlang.map_get(:map, struct))
  defguard size(struct) when map_size(:erlang.map_get(:map, struct))

  # Protocol callbacks
  @impl true
  defdelegate into(buildable), to: Buildable.Collectable.Any

  @impl true
  def extract(struct, position)

  def extract(%Foo{map: map} = struct, :start)
      when size(struct) > 0 do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def extract(%Foo{map: map} = struct, :end) when size(struct) > 0 do
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

  @impl true
  def reverse(struct) do
    struct
  end
end

defimpl Inspect, for: Foo do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#Foo<", to_doc(Map.to_list(struct.map), opts), ">"])
  end
end

# BONUS: If we want to implement the Collectable protocol, we just delegate
# it to the generic implementation
defimpl Collectable, for: Foo do
  @impl true
  defdelegate into(struct), to: Buildable.Collectable
end
