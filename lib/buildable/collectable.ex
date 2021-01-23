defprotocol Buildable.Collectable do
  @moduledoc """
  A protocol to traverse data structures.

  Collectable protocol used by [`buildables`](`t:Buildable.t/0`).

  The `Build.into/2` and `Build.into/3` functions use this protocol to insert an [buildable](`t:Buildable.t/0`) or a [range](`t:Range.t/0`) into a [`buildable`](`t:Buildable.t/0`).
  """

  @type t :: Buildable.t()
  @type collector :: (term, command -> Buildable.t() | term)
  @type command :: {:cont, term()} | :done | :halt

  @fallback_to_any true

  @spec into(Buildable.t()) ::
          {initial_acc :: term, collector}
  def into(buildable)
end

defimpl Buildable.Collectable, for: [BitString, Map, MapSet] do
  @impl true
  defdelegate into(buildable), to: Collectable
end

defimpl Buildable.Collectable, for: List do
  @impl true
  def into(list) do
    buildable_module = Buildable.impl_for(list)

    fun = fn
      list_acc, {:cont, elem} ->
        [elem | list_acc]

      list_acc, :done ->
        # This implementation is different than the one in Collectible.List.
        # Here we do allow inserting into non-empty lists
        if buildable_module.default(:into_position) == :last do
          :lists.reverse(list_acc) ++ list
        else
          list_acc ++ list
        end

      _list_acc, :halt ->
        :ok
    end

    {[], fun}
  end
end

defimpl Buildable.Collectable, for: Any do
  import Build.Util, only: [invert_position: 1]

  @impl true
  def into(buildable) do
    buildable_module = Buildable.impl_for(buildable)

    reverse_result? =
      buildable_module.default(:reversible?) == true and
        buildable_module.default(:extract_position) ==
          buildable_module.default(:into_position)

    into_any(buildable, buildable_module, reverse_result?)
  end

  defp into_any(buildable, buildable_module, reverse_result?)

  defp into_any(buildable, buildable_module, false) do
    fun = fn
      acc, {:cont, elem} ->
        buildable_module.insert(acc, elem, buildable_module.default(:into_position))

      acc, :done ->
        acc

      _acc, :halt ->
        :ok
    end

    {buildable, fun}
  end

  defp into_any(buildable, buildable_module, true) do
    inverted_into_position = invert_position(buildable_module.default(:into_position))

    fun = fn
      acc, {:cont, elem} ->
        buildable_module.insert(acc, elem, inverted_into_position)

      acc, :done ->
        buildable_module.reverse(acc)

      _acc, :halt ->
        :ok
    end

    {buildable_module.reverse(buildable), fun}
  end
end
