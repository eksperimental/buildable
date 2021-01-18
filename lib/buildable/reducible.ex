defprotocol Buildable.Reducible do
  @moduledoc """
  [`Reducible`](`Buildable.Reducible`) protocol used by [`buildables`](`t:Buildable.t/0`).
  """

  @type t :: Buildable.t()
  @type acc :: {:cont, term()} | {:halt, term()} | {:suspend, term()}
  @type continuation :: (acc -> result)
  @type reducer :: (element :: term, current_acc :: acc -> updated_acc :: acc)
  @type result ::
          {:done, term}
          | {:halted, term}
          | {:suspended, term, continuation}

  @fallback_to_any true

  @doc """
  Reduces `buildable` into an element.

  It behaves the same way as `Enumerable.reduce/3`.
  """
  @spec reduce(Buildable.t(), acc(), reducer()) :: result()
  def reduce(buildable, acc, reducer_function)
end

defimpl Buildable.Reducible, for: [List, Map, MapSet] do
  @impl true
  defdelegate reduce(list, acc, reducer_function), to: Enumerable
end

defimpl Buildable.Reducible, for: [BitString, Tuple] do
  @impl true
  defdelegate reduce(buildable, acc, reducer_function),
    to: Buildable.ReducibleUtil
end

defimpl Buildable.Reducible, for: Any do
  @impl true

  def reduce(buildable, acc, reducer_function) do
    case Enumerable.impl_for(buildable) do
      nil ->
        Buildable.ReducibleUtil.reduce(buildable, acc, reducer_function)

      # We fallback to Enumerable.reduce if it is implemented for this buildable.
      enumerable_module ->
        enumerable_module.reduce(buildable, acc, reducer_function)
    end
  end
end

defmodule Buildable.ReducibleUtil do
  @moduledoc false
  def reduce(_buildable, {:halt, acc}, _reducer_function),
    do: {:halted, acc}

  def reduce(buildable, {:suspend, acc}, reducer_function),
    do: {:suspended, acc, &reduce(buildable, &1, reducer_function)}

  def reduce(buildable, {:cont, acc}, reducer_function) do
    buildable_module = Buildable.impl_for(buildable)

    case buildable_module.extract(buildable) do
      {:ok, element, buildable_updated} ->
        reduce(buildable_updated, reducer_function.(element, acc), reducer_function)

      :error ->
        {:done, acc}
    end
  end
end
