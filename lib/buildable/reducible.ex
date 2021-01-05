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
  def reduce(buildable, acc, fun)
end

defimpl Buildable.Reducible, for: List do
  @impl true
  defdelegate reduce(list, acc, fun), to: Enumerable
end

defimpl Buildable.Reducible, for: Any do
  @impl true
  def reduce(_buildable, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(buildable, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(buildable, &1, fun)}

  def reduce(buildable, {:cont, acc}, fun) do
    buildable_module = Buildable.impl_for(buildable)

    case buildable_module.extract(buildable) do
      {:ok, element, buildable_updated} ->
        reduce(buildable_updated, fun.(element, acc), fun)

      :error ->
        {:done, acc}
    end
  end
end
