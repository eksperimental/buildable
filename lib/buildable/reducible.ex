defprotocol Buildable.Reducible do
  @moduledoc """
  Documentation for `Buildable.Reducible`.
  """
  @type acc :: {:cont, term()} | {:halt, term()} | {:suspend, term()}
  @type continuation :: (acc -> result)
  @type reducer :: (element :: term, current_acc :: acc -> updated_acc :: acc)
  @type result ::
          {:done, term}
          | {:halted, term}
          | {:suspended, term, continuation}

  @spec reduce(t(), acc(), reducer()) :: result()
  def reduce(buildable, acc, fun)
end

defimpl Buildable.Reducible, for: List do
  @impl true
  def reduce(list, acc, fun) do
    Enumerable.List.reduce(list, acc, fun)
  end
end

defimpl Buildable.Reducible, for: Map do
  @impl true
  def reduce(_map, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(map, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(map, &1, fun)}

  def reduce(map, {:cont, acc}, fun) when map_size(map) > 0 do
    {:ok, element, map_updated} = Buildable.Map.pop(map, :start)
    reduce(map_updated, fun.(element, acc), fun)
  end

  def reduce(map, {:cont, acc}, _fun) when map_size(map) == 0 do
    {:done, acc}
  end
end

defimpl Buildable.Reducible, for: MapSet do
  @impl true
  def reduce(_map_set, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(map_set, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(map_set, &1, fun)}

  def reduce(map_set, {:cont, acc}, fun) do
    case MapSet.size(map_set) do
      0 ->
        {:done, acc}

      _ ->
        {:ok, element, map_updated} = Buildable.MapSet.pop(map_set, :start)
        reduce(map_updated, fun.(element, acc), fun)
    end
  end
end

defimpl Buildable.Reducible, for: Tuple do
  @impl true
  def reduce(_tuple, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(tuple, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(tuple, &1, fun)}

  def reduce(tuple, {:cont, acc}, fun) when tuple_size(tuple) > 0 do
    {:ok, element, tuple_updated} = Buildable.Tuple.pop(tuple, :start)
    reduce(tuple_updated, fun.(element, acc), fun)
  end

  def reduce({}, {:cont, acc}, _fun) do
    {:done, acc}
  end
end
