defmodule Foo do
  @moduledoc false

  defstruct map: %{}

  @behaviour Buildable

  import Buildable.Util, only: [is_position: 1]

  use Buildable.Use

  @impl true
  def empty(_options \\ []) do
    %__MODULE__{}
  end

  @impl true
  def put(struct, {key, value}, position) when is_position(position) do
    put_in(struct, [:map, key], value)
  end

  @impl true
  def pop(%Foo{map: map} = struct, position)
      when map_size(map) > 0 and position in [:start, nil] do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def pop(%Foo{map: map} = struct, :end) when map_size(struct) > 0 do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(struct, key)
    {:ok, {key, value}, %{struct | map: rest}}
  end

  def pop(struct, position) when map_size(struct) == 0 and is_position(position) do
    :error
  end

  @impl true
  def reverse(struct) do
    struct
  end
end

defimpl Collectable, for: Foo do
  @impl true
  def into(struct) do
    fun = fn
      struct_acc, {:cont, {key, value}} ->
        %{struct | map: Map.put(struct_acc.map, key, value)}

      struct_acc, :done ->
        struct_acc

      _map_acc, :halt ->
        :ok
    end

    {struct, fun}
  end
end
