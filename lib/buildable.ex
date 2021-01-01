defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type element :: term()
  @type position :: :start | :end
  @type options :: keyword()
  @type transform_fun :: (term() -> term())
  @type command :: {:cont, term()} | :done | :halt

  @callback empty() :: t()
  @callback empty(options) :: t()
  @callback new(Enum.t()) :: t()
  @callback new(Enum.t(), options()) :: t()
  @callback default_position(function_name :: :pop | :put) :: position()

  @optional_callbacks empty: 0, new: 1

  @spec empty(t(), options) :: t()
  def empty(buildable, options)

  @spec into(t) :: {initial_acc :: term, collector :: (term, command -> t | term)}
  def into(buildable)

  @spec into(t(), Enum.t(), transform_fun()) :: t()
  def into(buildable, term, transform_fun \\ &Function.identity/1)

  @spec pop(t()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def pop(buildable)

  @spec pop(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def pop(buildable, position)

  @spec put(t(), term) :: updated_buildable :: t()
  def put(buildable, term)

  @spec put(t(), term, position()) :: updated_buildable :: t()
  def put(buildable, term, position)

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  def reverse(buildable)
end

defimpl Buildable, for: List do
  use Buildable.Use

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
  use Buildable.Use

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
  use Buildable.Use

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
  use Buildable.Use

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
