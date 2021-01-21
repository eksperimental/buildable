defmodule Build do
  @moduledoc """
  Module for building buildables.
  """
  @type t :: Buildable.t()
  @type acc :: any()
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
  defdelegate to_empty(buildable, options \\ []), to: Buildable

  @spec peek(t()) :: {:ok, element()} | :error
  defdelegate peek(buildable), to: Buildable

  @spec peek(t(), position) :: {:ok, element()} | :error
  defdelegate peek(buildable, position), to: Buildable

  #############################
  # into/2
  @spec into(t(), t() | Range.t()) :: t()
  def into(buildable, collection)

  def into([], %Range{} = range) do
    Enum.to_list(range)
  end

  def into([], collection) do
    to_list(collection)
  end

  def into(buildable, collection)
      when is_struct(buildable) or is_struct(collection) do
    into_buildable(buildable, collection, nil)
  end

  def into(%{} = buildable, %{} = collection) do
    Map.merge(buildable, collection)
  end

  def into(%{} = buildable, collection)
      when is_list(collection) do
    Map.merge(buildable, :maps.from_list(collection))
  end

  def into(%{} = buildable, collection) do
    reduce(buildable, collection, fn {key, val}, acc ->
      Map.put(acc, key, val)
    end)
  end

  def into(buildable, collection) do
    into_buildable(buildable, collection, nil)
  end

  #############################
  # into/3

  @spec into(t(), t(), transform_fun()) :: t()
  def into(buildable, collection, transform)

  def into(list, %Range{} = range, transform)
      when is_list(list) and is_function(transform, 1) do
    list ++ Enum.map(range, transform)
  end

  def into(list, collection, transform)
      when is_list(list) and is_function(transform, 1) do
    list ++ map(collection, transform)
  end

  def into(buildable, collection, transform) when is_function(transform, 1) do
    into_buildable(buildable, collection, transform)
  end

  defp into_buildable(buildable, collection, transform) do
    {initial, fun} = Buildable.into(buildable)

    callback =
      if is_nil(transform) do
        fn entry, acc ->
          fun.(acc, {:cont, entry})
        end
      else
        fn entry, acc ->
          fun.(acc, {:cont, transform.(entry)})
        end
      end

    try do
      case collection do
        %Range{} ->
          Enum.reduce(collection, initial, callback)

        _ ->
          reduce(collection, initial, callback)
      end
    catch
      kind, reason ->
        fun.(initial, :halt)
        :erlang.raise(kind, reason, __STACKTRACE__)
    else
      acc -> fun.(acc, :done)
    end
  end

  @doc """
  Returns a new buildable where each element is the result of invoking
  `fun` on each element.

  For maps, the function expects a key-value tuple.

  ## Examples

      iex> Build.map([1, 2, 3], fn x -> x * 2 end)
      [2, 4, 6]

      iex> Build.map(%{a: 1, b: 2}, fn {k, v} -> {k, -v} end)
      %{a: -1, b: -2}

  """
  @spec map(t, (element -> any)) :: list
  def map(buildable, fun)

  def map(buildable, fun) when is_list(buildable) do
    :lists.map(fun, buildable)
  end

  def map(buildable, fun) do
    buildable_module = Buildable.impl_for(buildable)

    into_buildable(buildable_module.to_empty(buildable), buildable, fun)
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
    Buildable.reduce(buildable, {:cont, :first}, fn
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

  @spec reduce(t, acc, (element, acc -> acc)) :: acc
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
    Buildable.reduce(buildable, {:cont, acc}, fn element, acc ->
      {:cont, fun.(element, acc)}
    end)
    |> elem(1)
  end

  @spec to_list(t) :: [element]
  def to_list(buildable) when is_list(buildable), do: buildable
  def to_list(%_{} = buildable), do: do_to_list(buildable)
  def to_list(%{} = buildable), do: Map.to_list(buildable)
  def to_list(buildable), do: do_to_list(buildable)

  defp do_to_list(buildable) do
    buildable_module = Buildable.impl_for(buildable)
    result = into([], buildable)

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
