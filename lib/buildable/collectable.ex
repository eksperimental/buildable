defprotocol Buildable.Collectable do
  @moduledoc """
  Documentation for `Buildable.Collectable`.
  """

  @type command :: {:cont, term()} | :done | :halt

  @fallback_to_any true

  @spec into(Buildable.t()) ::
          {initial_acc :: term, collector :: (term, command -> Buildable.t() | term)}
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
        buildable_module.put(acc, elem)

      acc, :done ->
        if buildable_module.default_position(:put) == :start do
          buildable_module.reverse(acc)
        else
          acc
        end

      _acc, :halt ->
        :ok
    end

    {buildable, fun}
  end
end
