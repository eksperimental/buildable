# Notes
# We need to extend the Collectable protocol, that implements,
# 
#

# Buildable
# - empty
# - append (same as into) and pop (put_end, delete_end)  / put(Collectable.t, term | {key, value}, :start | :end | nil) 
# - queue and dequeue (put_start, delete_start) / pop(Collectable.t, term | {key, value}, :start | :end | nil)
# - reverse

# Reducible:
# - reduce that keeps the original format of the collectable

defprotocol Buildable do
  @type t :: term()
  @type position :: :start | :end | nil
  @type option :: {key :: atom(), value :: any}
  @type options :: [option]

  @moduledoc """
  Documentation for `Buildable`.
  """

  @callback empty() :: t
  @callback empty(options) :: t
  @callback new(Enum.t()) :: t
  @callback new(Enum.t(), options) :: t
  @callback new_transform(Enum.t(), transform_fun :: (term() -> term())) :: t
  @callback new_transform(Enum.t(), transform_fun :: (term() -> term()), options) :: t
  @optional_callbacks new_transform: 2, new_transform: 3

  @spec put(buildable :: t(), term, position()) :: updated_buildable :: t()
  def put(buildable, term, position \\ nil)

  @spec pop(buildable :: t(), position()) ::
          {:ok, element :: t(), updated_buildable :: t()} | :error
  def pop(buildable, position \\ nil)

  @spec reverse(t) :: t
  def reverse(buildable)
end

defimpl Buildable, for: List do
  @compile {:inline, [reverse: 1, reverse: 2]}

  import Buildable.Util, only: [is_position: 1]

  use Buildable.Use

  @impl true
  def empty(_options \\ []) do
    []
  end

  @impl true
  def put(list, term, position) when position in [:start, nil] do
    [term | list]
  end

  def put(list, term, :end) do
    reverse(list, [term])
    |> reverse()
  end

  @impl true
  def pop([], position) when is_position(position) do
    :error
  end

  def pop([head | rest], position) when position in [:start, nil] do
    {:ok, head, rest}
  end

  def pop(list, :end) do
    [head | rest] = reverse(list)
    {:ok, head, reverse(rest)}
  end

  @impl true
  def reverse(list) do
    :lists.reverse(list)
  end

  defp reverse(list, term) do
    :lists.reverse(list, term)
  end
end

defimpl Buildable, for: Map do
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
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  def pop(map, :end) when map_size(map) > 0 do
    [key | _] = :lists.reverse(Map.keys(map))
    {value, rest} = Map.pop!(map, key)
    {:ok, {key, value}, rest}
  end

  def pop(map, position) when map_size(map) == 0 and is_position(position) do
    :error
  end

  @impl true
  def reverse(map) do
    map
  end
end

defimpl Buildable, for: MapSet do
  import Buildable.Util, only: [is_position: 1]

  use Buildable.Use

  @impl true
  def empty(_options \\ []) do
    %MapSet{}
  end

  @impl true
  def put(map_set, term, position) when is_position(position) do
    MapSet.put(map_set, term)
  end

  @impl true
  def pop(map_set, position) when is_position(position) do
    if MapSet.size(map_set) > 0 do
      cond do
        position in [:start, nil] ->
          pop_by_index(map_set, 0)

        position in [:end] ->
          pop_by_index(map_set, -1)
      end
    else
      :error
    end
  end

  defp pop_by_index(map_set, index) do
    element = Enum.fetch!(map_set, index)
    rest = MapSet.delete(map_set, element)
    {:ok, element, rest}
  end

  @impl true
  def reverse(map_set) do
    {:done, result} =
      Buildable.Reducible.MapSet.reduce(map_set, {:cont, %MapSet{}}, fn x, acc ->
        {:cont, Buildable.put(acc, x, :start)}
      end)

    result
  end
end

defimpl Buildable, for: Tuple do
  import Buildable.Util, only: [is_position: 1]

  use Buildable.Use

  @impl true
  def empty(_options \\ []) do
    {}
  end

  @impl true
  def put(tuple, term, position) when position in [:start, nil] do
    Tuple.insert_at(tuple, 0, term)
  end

  def put(tuple, term, :end) do
    Tuple.append(tuple, term)
  end

  @impl true
  def pop({}, position) when is_position(position) do
    :error
  end

  def pop(tuple, position) when position in [:start, nil] do
    element = elem(tuple, 0)
    {:ok, element, Tuple.delete_at(tuple, 0)}
  end

  def pop(tuple, :end) do
    size = tuple_size(tuple)
    element = elem(tuple, size - 1)
    {:ok, element, Tuple.delete_at(tuple, size - 1)}
  end

  @impl true
  def reverse(tuple) do
    tuple
    |> :erlang.tuple_to_list()
    |> :lists.reverse()
    |> :erlang.list_to_tuple()
  end
end
