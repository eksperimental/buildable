defmodule Buildable.Implementation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for
  `c:Buildable.Behaviour.new/1`, `c:Buildable.Behaviour.new/2`, `c:Buildable.to_empty/2`.

  To use it call `use Buildable.Implementation`.
  """

  @default_options [
    :extract_position,
    :insert_position,
    :into_position,
    :reversible?
  ]

  defmacro __using__(_buildable_options) do
    # buildable_options = Macro.expand(buildable_options, __CALLER__)

    quote location: :keep,
          bind_quoted: [
            default_options: @default_options,
            caller: Macro.escape(__CALLER__),
            module: __CALLER__.module
          ] do
      import Buildable.Util, only: [is_position: 1]

      @behaviour Buildable.Behaviour

      missing_attributes =
        for option <- default_options,
            Module.get_attribute(module, option, :undefined) == :undefined,
            do: option

      if missing_attributes != [] do
        raise Buildable.MissingArgumentError,
          attributes: missing_attributes,
          caller_module: module,
          file: caller.file,
          line: caller.line,
          module: Buildable.Implementation
      end

      ##############################################
      # Behaviour callbacks

      @impl Buildable.Behaviour
      for option <- default_options do
        def default(unquote(option)) do
          unquote(Module.get_attribute(module, option, nil))
        end
      end

      @impl Buildable.Behaviour
      def empty() do
        unquote(__MODULE__).empty([])
      end

      @impl Buildable.Behaviour
      def new(collection, options \\ []) when is_list(options) do
        Build.into(unquote(__MODULE__).empty(options), collection)
      end

      ##############################################
      # Protocol callbacks

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
      if Module.get_attribute(module, :reversible?, true) do
        def reverse(buildable) do
          {:done, result} =
            Buildable.Reducible.reduce(buildable, {:cont, empty()}, fn element, acc ->
              {:cont, insert(acc, element)}
            end)

          result
        end
      else
        def reverse(buildable) do
          buildable
        end
      end

      defoverridable default: 1,
                     empty: 0,
                     extract: 1,
                     insert: 2,
                     into: 1,
                     new: 1,
                     new: 2,
                     peek: 1,
                     peek: 2,
                     reverse: 1,
                     to_empty: 1,
                     to_empty: 2
    end
  end
end

defimpl Buildable, for: BitString do
  @extract_position :first
  @insert_position :last
  @into_position :last
  @reversible? true

  import Buildable.Util, only: [is_position: 1]

  use Buildable.Implementation

  @impl Buildable.Behaviour
  def empty(_options \\ []) do
    ""
  end

  @impl Buildable
  def extract("", position) when is_position(position) do
    :error
  end

  def extract(binary, :first) when is_binary(binary) do
    {first, rest} = String.split_at(binary, 1)
    {:ok, first, rest}
  end

  def extract(<<first, rest>>, :first) do
    {:ok, first, rest}
  end

  def extract(binary, :last) when is_binary(binary) do
    {rest, last} = String.split_at(binary, -1)
    {:ok, last, rest}
  end

  def extract(bitstring, :last) do
    {last, rest} = extract_last(bitstring)
    {:ok, last, rest}
  end

  defp extract_last(bitstring, acc \\ "")

  defp extract_last(<<head, rest::bitstring>>, acc) do
    extract_last(rest, <<acc::bitstring, head>>)
  end

  defp extract_last(<<last>>, acc) do
    {last, acc}
  end

  @impl Buildable
  def insert(binary, term, position) when is_binary(binary) and is_position(position) do
    insert_in_binary(binary, term, position)
  end

  def insert(bitstring, term, position) when is_position(position) do
    insert_in_bitstring(bitstring, term, position)
  end

  defp insert_in_binary(binary, term, :first) when is_integer(term),
    do: <<term::integer, binary::binary>>

  defp insert_in_binary(binary, term, :first) when is_float(term),
    do: <<term::float, binary::binary>>

  defp insert_in_binary(binary, term, :first) when is_binary(term),
    do: <<term::binary, binary::binary>>

  defp insert_in_binary(binary, term, :first) when is_bitstring(term),
    do: <<term::bitstring, binary::binary>>

  defp insert_in_binary(binary, term, :last) when is_integer(term),
    do: <<binary::binary, term::integer>>

  defp insert_in_binary(binary, term, :last) when is_float(term),
    do: <<binary::binary, term::float>>

  defp insert_in_binary(binary, term, :last) when is_binary(term),
    do: <<binary::binary, term::binary>>

  defp insert_in_binary(binary, term, :last) when is_bitstring(term),
    do: <<binary::binary, term::bitstring>>

  defp insert_in_bitstring(bitstring, term, :first) when is_integer(term),
    do: <<term::integer, bitstring::bitstring>>

  defp insert_in_bitstring(bitstring, term, :first) when is_float(term),
    do: <<term::float, bitstring::bitstring>>

  defp insert_in_bitstring(bitstring, term, :first) when is_binary(term),
    do: <<term::binary, bitstring::bitstring>>

  defp insert_in_bitstring(bitstring, term, :first) when is_bitstring(term),
    do: <<term::bitstring, bitstring::bitstring>>

  defp insert_in_bitstring(bitstring, term, :last) when is_integer(term),
    do: <<bitstring::bitstring, term::integer>>

  defp insert_in_bitstring(bitstring, term, :last) when is_float(term),
    do: <<bitstring::bitstring, term::float>>

  defp insert_in_bitstring(bitstring, term, :last) when is_binary(term),
    do: <<bitstring::bitstring, term::binary>>

  defp insert_in_bitstring(bitstring, term, :last) when is_bitstring(term),
    do: <<bitstring::bitstring, term::bitstring>>

  @impl Buildable
  def peek(<<>>, position) when is_position(position),
    do: :error

  def peek(binary, position) when is_binary(binary) and is_position(position) do
    case position do
      :first ->
        {:ok, String.first(binary)}

      :last ->
        {:ok, String.last(binary)}
    end
  end

  def peek(<<first, _rest::bitstring>>, :first) do
    {:ok, first}
  end

  def peek(bitstring, :last) do
    {_rest, last} = extract_last(bitstring)
    {:ok, last}
  end
end

defimpl Buildable, for: List do
  @extract_position :first
  @insert_position :first
  @into_position :last
  @reversible? true

  use Buildable.Implementation

  @impl Buildable.Behaviour
  def empty(_options \\ []) do
    []
  end

  @impl Buildable
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

  @impl Buildable
  def insert(list, term, :first) do
    [term | list]
  end

  def insert(list, term, :last) do
    list ++ [term]
  end

  @impl Buildable
  def peek([head | _rest], :first) do
    {:ok, head}
  end

  def peek([_ | _] = list, :last) do
    {:ok, List.last(list)}
  end

  def peek([], position) when is_position(position) do
    :error
  end

  @impl Buildable
  def reverse(list) do
    :lists.reverse(list)
  end
end

defimpl Buildable, for: Map do
  @extract_position :first
  @insert_position :first
  @into_position :last
  @reversible? false

  use Buildable.Implementation

  @impl Buildable.Behaviour
  def empty(_options \\ []) do
    %{}
  end

  @impl Buildable
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

  @impl Buildable
  def insert(map, {key, value}, position) when is_position(position) do
    Map.put(map, key, value)
  end

  @impl Buildable
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

  @impl Buildable
  def reverse(map) do
    map
  end
end

defimpl Buildable, for: MapSet do
  @extract_position :first
  @insert_position :first
  @into_position :last
  @reversible? false

  use Buildable.Implementation

  @impl Buildable.Behaviour
  def empty(_options \\ []) do
    %MapSet{}
  end

  @impl Buildable
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

  @impl Buildable
  def insert(map_set, term, position) when is_position(position) do
    MapSet.put(map_set, term)
  end

  @impl Buildable
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

  @impl Buildable
  def reverse(map_set) do
    map_set
  end
end

defimpl Buildable, for: Tuple do
  @extract_position :first
  @insert_position :first
  @into_position :last
  @reversible? true

  use Buildable.Implementation

  @impl Buildable.Behaviour
  def empty(_options \\ []) do
    {}
  end

  @impl Buildable
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

  @impl Buildable
  def insert(tuple, term, :first) do
    Tuple.insert_at(tuple, 0, term)
  end

  def insert(tuple, term, :last) do
    Tuple.append(tuple, term)
  end

  @impl Buildable
  def peek({}, position) when is_position(position) do
    :error
  end

  def peek(tuple, :first) do
    {:ok, elem(tuple, 0)}
  end

  def peek(tuple, :last) do
    size = tuple_size(tuple) - 1
    {:ok, elem(tuple, size)}
  end
end
