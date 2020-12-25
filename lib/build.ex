defmodule Build do
  @moduledoc """
  Module for building buildables.
  """
  @type t :: Buildable.t()
  @type element :: Buildable.element()
  @type position :: Buildable.position()
  @type transform_fun :: Buildable.transform_fun()

  @spec into(t(), Enum.t(), transform_fun()) :: t()
  defdelegate into(enumerable, buildable, transform_fun \\ &Function.identity/1),
    to: Buildable

  @spec put(t(), term, position()) :: updated_buildable :: t()
  defdelegate put(buildable, term, position \\ nil), to: Buildable

  @spec pop(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  defdelegate pop(buildable, position \\ nil), to: Buildable

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  defdelegate reverse(buildable), to: Buildable
end
