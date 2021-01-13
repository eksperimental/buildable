defmodule Build do
  @moduledoc """
  Module for building buildables.
  """
  @type t :: Buildable.t()
  @type acc :: Buildable.Reducible.acc()
  @type element :: Buildable.element()
  @type options :: Buildable.options()
  @type position :: Buildable.position()
  @type transform_fun :: (term() -> term())

  @compile {:inline, reduce: 3, reduce_buildable: 3}

  @spec insert(t(), term) :: updated_buildable :: t()
  defdelegate insert(buildable, term), to: Buildable

  @spec insert(t(), term, position()) :: updated_buildable :: t()
  defdelegate insert(buildable, term, position), to: Buildable

  @spec extract(t()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  defdelegate extract(buildable), to: Buildable

  @spec extract(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  defdelegate extract(buildable, position), to: Buildable

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  defdelegate reverse(buildable), to: Buildable

  @spec to_empty(t(), options) :: t()
  defdelegate to_empty(enumerable, options \\ []), to: Buildable

  #############################
  # into/2

  @spec into(t(), t() | Enum.t()) :: t()
  def into(buildable, collection) do
    cond do
      impl?(collection, Buildable) ->
        do_into(buildable, collection, {nil, Buildable.Collectable})

      impl?(collection, Enumerable) ->
        do_into(buildable, collection, {Enum, Collectable})
    end
  end

  defmacro modulify(module, {function_name, _meta, arguments}) when is_list(arguments) do
    quote do
      if unquote(module) do
        unquote(module).unquote(function_name)(unquote_splicing(arguments))
      else
        unquote(function_name)(unquote_splicing(arguments))
      end
    end
  end

  defp do_into([], collection, {module, _protocol}) do
    modulify(module, to_list(collection))
  end

  defp do_into(enumerable, collectable, {module, protocol})
       when is_struct(enumerable) or is_struct(collectable) do
    into_protocol(enumerable, collectable, {module, protocol})
  end

  defp do_into(%{} = buildable, %{} = collection, {_module, _protocol}) do
    Map.merge(buildable, collection)
  end

  defp do_into(%{} = buildable, collection, {_module, _protocol})
       when is_list(collection) do
    Map.merge(buildable, :maps.from_list(collection))
  end

  defp do_into(%{} = buildable, collection, {_module, _protocol}) do
    reduce(buildable, collection, fn {key, val}, acc ->
      Map.put(acc, key, val)
    end)
  end

  defp do_into(buildable, collection, {module, protocol}) do
    into_protocol(buildable, collection, {module, protocol})
  end

  defp into_protocol(buildable, collection, {module, protocol}) do
    {initial, fun} = Buildable.into(buildable)

    do_into(
      initial,
      collection,
      fun,
      fn entry, acc ->
        fun.(acc, {:cont, entry})
      end,
      {module, protocol}
    )
  end

  #############################
  # into/3

  @spec into(t(), t() | Enum.t(), transform_fun()) :: t()
  def into(buildable, collection, transform) do
    cond do
      impl?(collection, Buildable) ->
        into(buildable, collection, transform, {nil, Buildable})

      impl?(collection, Enumerable) ->
        into(buildable, collection, transform, {Enum, Enumerable})
    end
  end

  defp into(
         buildable,
         buildable_collection,
         transform,
         {module, _protocol}
       )
       when is_list(buildable) do
    buildable ++ modulify(module, map(buildable_collection, transform))
  end

  defp into(buildable, collection, transform, {module, protocol}) do
    {initial, fun} = Buildable.Collectable.into(buildable)

    do_into(
      initial,
      collection,
      fun,
      fn entry, acc ->
        fun.(acc, {:cont, transform.(entry)})
      end,
      {module, protocol}
    )
  end

  defp do_into(initial, collection, fun, callback, {module, _protocol}) do
    try do
      modulify(module, reduce(collection, initial, callback))
    catch
      kind, reason ->
        fun.(initial, :halt)
        :erlang.raise(kind, reason, __STACKTRACE__)
    else
      acc -> fun.(acc, :done)
    end
  end

  defp impl?(term, protocol) when is_atom(protocol) do
    if Code.ensure_loaded?(protocol) and protocol.impl_for(term) != nil do
      true
    else
      false
    end
  end

  @doc """
  Returns a list where each element is the result of invoking
  `fun` on each corresponding element of `buildable`.

  For maps, the function expects a key-value tuple.

  ## Examples

      iex> Build.map([1, 2, 3], fn x -> x * 2 end)
      [2, 4, 6]

      iex> Build.map([a: 1, b: 2], fn {k, v} -> {k, -v} end)
      [a: -1, b: -2]

  """
  @spec map(t, (element -> any)) :: list
  def map(buildable, fun)

  def map(buildable, fun) when is_list(buildable) do
    :lists.map(fun, buildable)
  end

  def map(buildable, fun) do
    reducer = fn entry, acc ->
      [fun.(entry) | acc]
    end

    reduce(buildable, [], reducer) |> reverse()
  end

  #############################
  # reduce/2

  @spec reduce(t, (element, acc -> acc)) :: acc
  def reduce(buildable, fun)

  def reduce([head | tail], fun) do
    reduce(tail, head, fun)
  end

  def reduce([], _fun) do
    raise Build.EmptyError
  end

  def reduce(buildable, fun) do
    Buildable.Reducible.reduce(buildable, {:cont, :first}, fn
      element, {:acc, acc} ->
        {:cont, {:acc, fun.(element, acc)}}

      element, :first ->
        {:cont, {:acc, element}}
    end)
    |> elem(1)
    |> case do
      :first ->
        raise Build.EmptyError

      {:acc, acc} ->
        acc
    end
  end

  #############################
  # reduce/3

  @spec reduce(t, any, (element, acc -> acc)) :: acc
  def reduce(buildable, acc, fun) when is_list(buildable) do
    :lists.foldl(fun, acc, buildable)
  end

  def reduce(%_{} = buildable, acc, fun) do
    reduce_buildable(buildable, acc, fun)
  end

  def reduce(%{} = buildable, acc, fun) do
    :maps.fold(fn k, v, acc -> fun.({k, v}, acc) end, acc, buildable)
  end

  def reduce(buildable, acc, fun) do
    reduce_buildable(buildable, acc, fun)
  end

  defp reduce_buildable(buildable, acc, fun) do
    Buildable.Reducible.reduce(buildable, {:cont, acc}, fn element, acc ->
      {:cont, fun.(element, acc)}
    end)
    |> elem(1)
  end

  @spec to_list(t) :: [element]
  def to_list(buildable) when is_list(buildable), do: buildable
  def to_list(%_{} = buildable), do: do_to_list(buildable)
  def to_list(%{} = buildable), do: Map.to_list(buildable)
  def to_list(buildable), do: do_to_list(buildable)

  def do_to_list(buildable) do
    buildable_module = Buildable.impl_for(buildable)
    result = into([], buildable, &Function.identity/1)

    if buildable_module.default(:reversible?) and
         buildable_module.default(:extract_position) == buildable_module.default(:into_position) do
      :lists.reverse(result)
    else
      result
    end
  end
end

defmodule Build.EmptyError do
  defexception message: "empty error"
end
