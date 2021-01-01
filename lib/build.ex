defmodule Build do
  @moduledoc """
  Module for building buildables.
  """
  @type t :: Buildable.t()
  @type element :: Buildable.element()
  @type position :: Buildable.position()
  @type options :: Buildable.options()
  @type transform_fun :: (term() -> term())
  @type acc :: Buildable.Reducible.acc()

  @compile {:inline, reduce: 3, reduce_buildable: 3}

  @spec empty(t(), options) :: t()
  defdelegate empty(enumerable, options), to: Buildable

  @spec into(t(), Enum.t()) :: t()
  def into(buildable, enumerable)

  def into([], enumerable) do
    Enum.to_list(enumerable)
  end

  def into(buildable, %_{} = enumerable) do
    into_protocol(buildable, enumerable)
  end

  def into(%_{} = buildable, enumerable) do
    into_protocol(buildable, enumerable)
  end

  def into(%{} = buildable, %{} = enumerable) do
    Map.merge(enumerable, buildable)
  end

  def into(%{} = buildable, enumerable) when is_list(enumerable) do
    Map.merge(buildable, :maps.from_list(enumerable))
  end

  def into(%{} = buildable, enumerable) do
    reduce(buildable, enumerable, fn {key, val}, acc ->
      Map.put(acc, key, val)
    end)
  end

  def into(buildable, enumerable) do
    into_protocol(buildable, enumerable)
  end

  defp into_protocol(buildable, enumerable) do
    {initial, fun} = Buildable.into(buildable)

    into(initial, enumerable, fun, fn entry, acc ->
      fun.(acc, {:cont, entry})
    end)
  end

  @spec into(t(), Enum.t(), transform_fun()) :: t()
  def into(buildable, enumerable, transform) when is_list(buildable) do
    buildable ++ Enum.map(enumerable, transform)
  end

  def into(buildable, enumerable, transform) do
    {initial, fun} = Buildable.into(buildable)

    into(initial, enumerable, fun, fn entry, acc ->
      fun.(acc, {:cont, transform.(entry)})
    end)
  end

  defp into(initial, enumerable, fun, callback) do
    try do
      Enum.reduce(enumerable, initial, callback)
    catch
      kind, reason ->
        fun.(initial, :halt)
        :erlang.raise(kind, reason, __STACKTRACE__)
    else
      acc -> fun.(acc, :done)
    end
  end

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

  @spec put(t(), term) :: updated_buildable :: t()
  defdelegate put(buildable, term), to: Buildable

  @spec put(t(), term, position()) :: updated_buildable :: t()
  defdelegate put(buildable, term, position), to: Buildable

  @spec pop(t()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  defdelegate pop(buildable), to: Buildable

  @spec pop(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  defdelegate pop(buildable, position), to: Buildable

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  defdelegate reverse(buildable), to: Buildable
end

defmodule Build.EmptyError do
  defexception message: "empty error"
end
