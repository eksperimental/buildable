defmodule Buildable.Implementation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for `c:Buildable.empty/2`,
  `c:Buildable.new/1`, `c:Buildable.new/2`.

  To use it call `use Buildable.Implementation`.
  """
  defmacro __using__(_using_options) do
    quote do
      import Buildable.Util, only: [is_position: 1]

      ##############################################
      # Behaviour callbacks

      @impl true
      def default_position(:put), do: :start
      def default_position(:pop), do: :start

      @impl true
      def new(enumerable, options \\ []) when is_list(options) do
        Build.into(empty(options), enumerable)
      end

      defoverridable default_position: 1,
                     new: 1

      ##############################################
      # Protocol callbacks

      @impl true
      def empty(_buildable, options) do
        empty(options)
      end

      @impl true
      defdelegate into(buildable), to: Buildable.Collectable

      @impl true
      def pop(buildable), do: pop(buildable, default_position(:pop))

      @impl true
      def put(buildable, term), do: put(buildable, term, default_position(:put))

      @impl true
      def reverse(buildable) do
        buildable_module = Buildable.impl_for(buildable)

        {:done, result} =
          Buildable.Reducible.reduce(buildable, {:cont, buildable_module.empty()}, fn element,
                                                                                      acc ->
            {:cont, buildable_module.put(acc, element)}
          end)

        result
      end

      defoverridable empty: 2,
                     into: 1,
                     pop: 1,
                     put: 2,
                     reverse: 1
    end
  end
end

defimpl Buildable, for: List do
  use Buildable.Implementation

  @impl true
  def empty(_options \\ []) do
    []
  end

  @impl true
  def pop([], position) when is_position(position) do
    :error
  end

  def pop([head | rest], :start) do
    {:ok, head, rest}
  end

  def pop(list, :end) do
    [head | rest] = reverse(list)
    {:ok, head, reverse(rest)}
  end

  @impl true
  def put(list, term, :start) do
    [term | list]
  end

  def put(list, term, :end) do
    list ++ [term]
  end

  @impl true
  def reverse(list) do
    :lists.reverse(list)
  end
end

defimpl Buildable, for: Map do
  use Buildable.Implementation

  @impl true
  def empty(_options \\ []) do
    %{}
  end

  @impl true
  def pop(map, position) when map == %{} and is_position(position) do
    :error
  end

  def pop(map, :start) do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  def pop(map, :end) do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  @impl true
  def put(map, {key, value}, position) when is_position(position) do
    Map.put(map, key, value)
  end

  @impl true
  def reverse(map) do
    map
  end
end

defimpl Buildable, for: MapSet do
  use Buildable.Implementation

  @impl true
  def empty(_options \\ []) do
    %MapSet{}
  end

  @impl true
  def pop(map_set, :start) do
    pop_by_index(map_set, 0)
  end

  def pop(map_set, :end) do
    pop_by_index(map_set, -1)
  end

  defp pop_by_index(map_set, index) do
    case Enum.fetch(map_set, index) do
      {:ok, element} ->
        {:ok, element, MapSet.delete(map_set, element)}

      :error ->
        :error
    end
  end

  @impl true
  def put(map_set, term, position) when is_position(position) do
    MapSet.put(map_set, term)
  end

  @impl true
  def reverse(map_set) do
    map_set
  end
end

defimpl Buildable, for: Tuple do
  use Buildable.Implementation

  @impl true
  def empty(_options \\ []) do
    {}
  end

  @impl true
  def pop({}, position) when is_position(position) do
    :error
  end

  def pop(tuple, :start) do
    element = elem(tuple, 0)
    {:ok, element, Tuple.delete_at(tuple, 0)}
  end

  def pop(tuple, :end) do
    size = tuple_size(tuple)
    element = elem(tuple, size - 1)
    {:ok, element, Tuple.delete_at(tuple, size - 1)}
  end

  @impl true
  def put(tuple, term, :start) do
    Tuple.insert_at(tuple, 0, term)
  end

  def put(tuple, term, :end) do
    Tuple.append(tuple, term)
  end
end
