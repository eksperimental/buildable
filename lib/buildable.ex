defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type command :: {:cont, term()} | :done | :halt
  @type element :: term()
  @type options :: keyword()
  @type position :: :start | :end
  @type transform_fun :: (term() -> term())

  @callback default_position(function_name :: :extract | :insert) :: position()
  @callback empty() :: t()
  @callback empty(options()) :: t()
  @callback new(Enum.t()) :: t()
  @callback new(Enum.t(), options()) :: t()

  @optional_callbacks empty: 0, new: 1

  @spec empty(t(), options) :: t()
  def empty(buildable, options)

  @spec extract(t()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def extract(buildable)

  @spec extract(t(), position()) ::
          {:ok, element(), updated_buildable :: t()} | :error
  def extract(buildable, position)

  @spec insert(t(), term) :: updated_buildable :: t()
  def insert(buildable, term)

  @spec insert(t(), term, position()) :: updated_buildable :: t()
  def insert(buildable, term, position)

  @spec into(t) :: {initial_acc :: term, collector :: (term, command -> t | term)}
  def into(buildable)

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  def reverse(buildable)
end
