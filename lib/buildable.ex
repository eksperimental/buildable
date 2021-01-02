defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type element :: term()
  @type position :: :start | :end
  @type options :: keyword()
  @type transform_fun :: (term() -> term())
  @type command :: {:cont, term()} | :done | :halt

  @callback empty() :: t()
  @callback empty(options()) :: t()
  @callback new(Enum.t()) :: t()
  @callback new(Enum.t(), options()) :: t()
  @callback default_position(function_name :: :pop | :put) :: position()

  @optional_callbacks empty: 0, new: 1

  @spec empty(t(), options) :: t()
  def empty(buildable, options)

  @spec into(t) :: {initial_acc :: term, collector :: (term, command -> t | term)}
  def into(buildable)

  @spec pop(t()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def pop(buildable)

  @spec pop(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def pop(buildable, position)

  @spec put(t(), term) :: updated_buildable :: t()
  def put(buildable, term)

  @spec put(t(), term, position()) :: updated_buildable :: t()
  def put(buildable, term, position)

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  def reverse(buildable)
end
