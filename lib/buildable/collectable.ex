defprotocol Buildable.Collectable do
  @moduledoc """
  A protocol to traverse data structures.

  Collectable protocol used by [`buildables`](`t:Buildable.t/0`).

  The `Build.into/2` and `Build.into/3` functions use this protocol to insert an [enumerable](`t:Enumerable.t/0`) into a [`buildable`](`t:Buildable.t/0`).
  """

  @type t :: Buildable.t()
  @type command :: {:cont, term()} | :done | :halt
  @type collector :: (term, command -> Buildable.t() | term)

  @fallback_to_any true

  @spec into(Buildable.t()) ::
          {initial_acc :: term, collector}
  def into(buildable)
end

defimpl Buildable.Collectable, for: BitString do
  @impl true
  defdelegate into(map_set), to: Collectable.BitString
end

defimpl Buildable.Collectable, for: List do
  @impl true
  def into(list) do
    buildable_module = Buildable.impl_for(list)

    fun = fn
      list_acc, {:cont, elem} ->
        [elem | list_acc]

      list_acc, :done ->
        # This is different than the Collectible.List implementation
        # We do allow inserting into non-empty lists
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

defimpl Buildable.Collectable, for: Map do
  @impl true
  defdelegate into(map), to: Collectable.Map
end

defimpl Buildable.Collectable, for: MapSet do
  @impl true
  defdelegate into(map_set), to: Collectable.MapSet
end

defimpl Buildable.Collectable, for: Any do
  import Buildable.Util, only: [invert_position: 1]

  @impl true
  def into(buildable) do
    buildable_module = Buildable.impl_for(buildable)

    reverse_result? =
      buildable_module.default(:reversible?) == true and
        buildable_module.default(:extract_position) ==
          buildable_module.default(:into_position)

    into(buildable, buildable_module, reverse_result?)
  end

  defp into(buildable, buildable_module, reverse_result?)

  defp into(buildable, buildable_module, false) do
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

  defp into(buildable, buildable_module, true) do
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
