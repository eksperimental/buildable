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

defimpl Buildable.Collectable, for: List do
  @impl true
  def into(list) do
    fun = fn
      list_acc, {:cont, elem} ->
        [elem | list_acc]

      list_acc, :done ->
        # This the different than the Collectible.List implementation
        # We allow inserting into non-empty lists
        :lists.reverse(list_acc) ++ list

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
  @impl true
  def into(buildable) do
    buildable_module = Buildable.impl_for(buildable)

    fun = fn
      acc, {:cont, elem} ->
        buildable_module.insert(acc, elem)

      acc, :done ->
        done(acc, buildable_module)

      _acc, :halt ->
        :ok
    end

    {buildable, fun}
  end

  @compile {:inline, done: 2}
  defp done(acc, buildable_module) do
    # TO-DO: test this
    if buildable_module.default(:reversible?) == false do
      acc
    else
      case buildable_module.default(:extract_position) do
        :first ->
          if buildable_module.default(:insert_position) == :last do
            acc
          else
            buildable_module.reverse(acc)
          end

        :last ->
          if buildable_module.default(:insert_position) == :last do
            acc
          else
            buildable_module.reverse(acc)
          end
      end
    end
  end
end
