defmodule Foo do
  @moduledoc false

  defstruct map: %{}

  @behaviour Buildable

  @impl true
  defdelegate empty(options \\ []), to: Buildable.Foo

  @impl true
  defdelegate empty(buildable, options), to: Buildable

  @impl true
  defdelegate default_position(function_name), to: Buildable.Foo

  @impl true
  defdelegate new(enumerable, options \\ []), to: Buildable.Foo

  @impl true
  defdelegate into(buildable), to: Buildable

  @impl true
  defdelegate into(buildable, term, transform_fun \\ &Function.identity/1), to: Buildable

  @impl true
  defdelegate pop(buildable), to: Buildable

  @impl true
  defdelegate pop(buildable, position), to: Buildable

  @impl true
  defdelegate put(buildable, term), to: Buildable

  @impl true
  defdelegate put(buildable, term, position), to: Buildable

  @impl true
  defdelegate reverse(buildable), to: Buildable
end

defimpl Buildable, for: Foo do
  import Buildable.Util, only: [is_position: 1]

  use Buildable.Use

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
  def pop(struct, position)

  def pop(%Foo{map: map} = struct, :start)
      when size(struct) > 0 do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def pop(%Foo{map: map} = struct, :end) when size(struct) > 0 do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def pop(struct, position) when size(struct) == 0 and is_position(position) do
    :error
  end

  @impl true
  def put(%Foo{map: map} = struct, {key, value}, position) when is_position(position) do
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
