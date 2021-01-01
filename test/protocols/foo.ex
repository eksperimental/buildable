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

  # @behaviour Access

  # @impl Access
  # def fetch(%Foo{map: map}, key) do
  #   Map.fetch(map, key)
  # end

  # @impl Access
  # def get_and_update(%Foo{map: map} = struct, key, fun) do
  #   {current_value, updated_map} = Map.get_and_update(map, key, fun)
  #   {current_value, %{struct | map: updated_map}}
  # end

  # @impl Access
  # def pop(%Foo{map: map} = struct, key) do
  #   {current_value, updated_map} = Map.pop(map, key)
  #   {current_value, %{struct | map: updated_map}}
  # end 
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
    # put_in(struct, [key], value)
    %{struct | map: put_in(map, [key], value)}
  end

  @impl true
  def reverse(struct) do
    struct
  end
end

defimpl Buildable.Reducible, for: Foo do
  require Buildable.Foo

  @impl true
  def reduce(_struct, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(struct, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(struct, &1, fun)}

  def reduce(struct, {:cont, acc}, fun) when Buildable.Foo.size(struct) > 0 do
    {:ok, element, struct_updated} = Buildable.Foo.pop(struct, :start)
    reduce(struct_updated, fun.(element, acc), fun)
  end

  def reduce(_struct, {:cont, acc}, _fun) do
    {:done, acc}
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

      _struct_acc, :halt ->
        :ok
    end

    {Buildable.Foo.empty(), fun}
  end
end

defimpl Inspect, for: Foo do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#Foo<", to_doc(Map.to_list(struct.map), opts), ">"])
  end
end
