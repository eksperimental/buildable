defmodule FooNoUse do
  @moduledoc """
  Sample implementation of Buildable behaviour and protocol.
  """

  @behaviour Buildable
  @behaviour Buildable.Behaviour

  defstruct map: %{}

  @impl Buildable.Behaviour
  defdelegate default(option), to: Buildable.FooNoUse

  @impl Buildable.Behaviour
  defdelegate empty(options \\ []), to: Buildable.FooNoUse

  @impl Buildable
  defdelegate extract(buildable), to: Buildable

  @impl Buildable
  defdelegate extract(buildable, position), to: Buildable

  @impl Buildable
  defdelegate insert(buildable, term), to: Buildable

  @impl Buildable
  defdelegate insert(buildable, term, position), to: Buildable

  @impl Buildable
  defdelegate into(buildable), to: Buildable

  @impl Buildable.Behaviour
  defdelegate new(enumerable, options \\ []), to: Buildable.FooNoUse

  @impl Buildable
  defdelegate peek(buildable), to: Buildable

  @impl Buildable
  defdelegate peek(buildable, position), to: Buildable

  @impl Buildable
  defdelegate reduce(buildable, acc, reducer_function), to: Buildable

  @impl Buildable
  defdelegate reverse(buildable), to: Buildable

  @impl Buildable
  defdelegate to_empty(buildable, options \\ []), to: Buildable
end

defimpl Buildable, for: FooNoUse do
  @insert_position :first
  @extract_position :first
  @into_position :last
  @reversible? false

  @behaviour Buildable.Behaviour

  import Buildable.Util, only: [is_position: 1]

  defguard size(struct) when map_size(:erlang.map_get(:map, struct))

  ##############################################
  # Behaviour callbacks

  @impl Buildable.Behaviour
  def empty(_options), do: %Foo{}

  @impl Buildable.Behaviour
  def new(collection, options \\ []) when is_list(options) do
    Build.into(FooNoUse.empty(options), collection)
  end

  @impl Buildable.Behaviour
  def default(:insert_position), do: @insert_position
  def default(:extract_position), do: @extract_position
  def default(:into_position), do: @into_position
  def default(:reversible?), do: @reversible?

  ##############################################
  # Protocol callbacks
  @impl Buildable
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

  @impl Buildable
  def insert(%Foo{map: map} = struct, {key, value}, position) when is_position(position) do
    %{struct | map: put_in(map, [key], value)}
  end

  @impl Buildable
  def extract(buildable) do
    extract(buildable, default(:extract_position))
  end

  @impl Buildable
  def insert(buildable, term) do
    insert(buildable, term, default(:insert_position))
  end

  @impl Buildable
  defdelegate into(buildable), to: Buildable.Collectable

  @impl Buildable
  def peek(buildable) do
    peek(buildable, default(:extract_position))
  end

  @impl Buildable
  def peek(buildable, position) when is_position(position) do
    case extract(buildable, position) do
      {:ok, element, _rest_buildable} ->
        {:ok, element}

      :error ->
        :error
    end
  end

  @impl Buildable
  defdelegate reduce(buildable, acc, reducer_function), to: Buildable.Reducible

  @impl Buildable
  def to_empty(buildable, options \\ []) do
    Buildable.impl_for(buildable).empty(options)
  end

  @impl Buildable
  def reverse(buildable) do
    buildable
  end
end

defimpl Inspect, for: FooNoUse do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#FooNoUse<", to_doc(Map.to_list(struct.map), opts), ">"])
  end
end

defimpl Enumerable, for: FooNoUse do
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
