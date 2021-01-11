defmodule Buildable.Implementation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for
  `c:Buildable.new/1`, `c:Buildable.new/2`, `c:Buildable.to_empty/2`.

  To use it call `use Buildable.Implementation`.
  """

  @default [
    insert_position: nil,
    extract_position: nil,
    into_position: nil,
    reversible?: nil
  ]

  defmacro __using__(buildable_options) do
    buildable_options = Macro.expand(buildable_options, __CALLER__)

    default =
      case Keyword.get(buildable_options, :default, []) do
        [] -> @default
        default -> default
      end

    quote location: :keep,
          bind_quoted: [
            default: default
          ] do
      import Buildable.Util, only: [is_position: 1]

      ##############################################
      # Behaviour callbacks

      @impl Buildable
      def default(:extract_position), do: unquote(Keyword.fetch!(default, :extract_position))
      def default(:insert_position), do: unquote(Keyword.fetch!(default, :insert_position))
      def default(:into_position), do: unquote(Keyword.fetch!(default, :into_position))
      def default(:reversible?), do: unquote(Keyword.fetch!(default, :reversible?))

      @impl Buildable
      def new(enumerable, options \\ []) when is_list(options) do
        Build.into(unquote(__MODULE__).empty(options), enumerable)
      end

      ##############################################
      # Protocol callbacks

      @impl Buildable
      def empty() do
        unquote(__MODULE__).empty([])
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
      def reverse(buildable) do
        if default(:reversible?) do
          {:done, result} =
            Buildable.Reducible.reduce(buildable, {:cont, empty()}, fn element, acc ->
              {:cont, insert(acc, element)}
            end)

          result
        else
          buildable
        end
      end

      @impl Buildable
      def to_empty(buildable, options \\ []) do
        Buildable.impl_for(buildable).empty(options)
      end

      defoverridable empty: 0,
                     extract: 1,
                     insert: 2,
                     into: 1,
                     new: 1,
                     reverse: 1,
                     to_empty: 1,
                     to_empty: 2,
                     default: 1
    end
  end
end

defimpl Buildable, for: List do
  default = [
    insert_position: :first,
    extract_position: :first,
    into_position: :last,
    reversible?: true
  ]

  use Buildable.Implementation, default: default

  @impl true
  def empty(_options \\ []) do
    []
  end

  @impl true
  def extract([], position) when is_position(position) do
    :error
  end

  def extract([head | rest], :first) do
    {:ok, head, rest}
  end

  def extract(list, :last) do
    [head | rest] = reverse(list)
    {:ok, head, reverse(rest)}
  end

  @impl true
  def insert(list, term, :first) do
    [term | list]
  end

  def insert(list, term, :last) do
    list ++ [term]
  end

  @impl true
  def peek(list) do
    peek(list, :first)
  end

  @impl true
  def peek([head | _rest], :first) do
    {:ok, head}
  end

  def peek([_ | _] = list, :last) do
    {:ok, List.last(list)}
  end

  def peek([], position) when is_position(position) do
    :error
  end

  @impl true
  def reverse(list) do
    :lists.reverse(list)
  end
end

defimpl Buildable, for: Map do
  default = [
    insert_position: :first,
    extract_position: :first,
    into_position: :last,
    reversible?: false
  ]

  use Buildable.Implementation, default: default

  @impl true
  def empty(_options \\ []) do
    %{}
  end

  @impl true
  def extract(map, position) when map == %{} and is_position(position) do
    :error
  end

  def extract(map, :first) do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  def extract(map, :last) do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  @impl true
  def insert(map, {key, value}, position) when is_position(position) do
    Map.put(map, key, value)
  end

  @impl true
  def peek(map) do
    peek(map, :first)
  end

  @impl true
  def peek(map, position) when map == %{} and is_position(position) do
    :error
  end

  def peek(map, :first) do
    [key | _] = Map.keys(map)
    {:ok, Map.get(map, key)}
  end

  def peek(map, :last) do
    [key | _] = :lists.reverse(Map.keys(map))
    {:ok, Map.get(map, key)}
  end

  @impl true
  def reverse(map) do
    map
  end
end

defimpl Buildable, for: MapSet do
  default = [
    insert_position: :first,
    extract_position: :first,
    into_position: :last,
    reversible?: false
  ]

  use Buildable.Implementation, default: default

  @impl true
  def empty(_options \\ []) do
    %MapSet{}
  end

  @impl true
  def extract(map_set, :first) do
    extract_by_index(map_set, 0)
  end

  def extract(map_set, :last) do
    extract_by_index(map_set, -1)
  end

  defp extract_by_index(map_set, index) do
    case Enum.fetch(map_set, index) do
      {:ok, element} ->
        {:ok, element, MapSet.delete(map_set, element)}

      :error ->
        :error
    end
  end

  @impl true
  def insert(map_set, term, position) when is_position(position) do
    MapSet.put(map_set, term)
  end

  @impl true
  def peek(map_set) do
    peek(map_set, :first)
  end

  @impl true
  def peek(map_set, position) when is_position(position) do
    index =
      case position do
        :first -> 0
        :last -> -1
      end

    case Enum.fetch(map_set, index) do
      {:ok, element} ->
        {:ok, element}

      :error ->
        :error
    end
  end

  @impl true
  def reverse(map_set) do
    map_set
  end
end

defimpl Buildable, for: Tuple do
  default = [
    insert_position: :first,
    extract_position: :first,
    into_position: :last,
    reversible?: true
  ]

  use Buildable.Implementation, default: default

  @impl true
  def empty(_options \\ []) do
    {}
  end

  @impl true
  def extract({}, position) when is_position(position) do
    :error
  end

  def extract(tuple, :first) do
    element = elem(tuple, 0)
    {:ok, element, Tuple.delete_at(tuple, 0)}
  end

  def extract(tuple, :last) do
    size = tuple_size(tuple)
    element = elem(tuple, size - 1)
    {:ok, element, Tuple.delete_at(tuple, size - 1)}
  end

  @impl true
  def insert(tuple, term, :first) do
    Tuple.insert_at(tuple, 0, term)
  end

  def insert(tuple, term, :last) do
    Tuple.append(tuple, term)
  end
end
