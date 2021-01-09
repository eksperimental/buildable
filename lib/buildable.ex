defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type command :: {:cont, term()} | :done | :halt
  @type element :: term()
  @type options :: keyword()
  @type position :: :first | :last
  @type transform_fun :: (term() -> term())

  @doc """
  Defines the default options for the implementation.transform_fun

  Option can be:
  - `insert_position`: where to insert a new element in the buildable. Accepted values are `:first`, `:last`, and `nil`.
    `nil` means that the buildable has not concept of inserting elements in a particular order.
  - `extract_position`: where to extract the element from the buildable. Accepted values are `:first`, `:last`, and `nil`.
    `nil` means that the buildable has not concept of inserting elements in a particular order.
  """
  @callback default(:insert_position) :: position()
  @callback default(:extract_position) :: position()
  @callback default(:reversible?) :: boolean()

  @callback empty() :: t()
  @callback empty(options()) :: t()
  @callback new(Enum.t()) :: t()
  @callback new(Enum.t(), options()) :: t()

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

  @spec peek(t()) :: {:ok, element()} | :error
  def peek(buildable)

  @spec peek(t(), position) :: {:ok, element()} | :error
  def peek(buildable, position)

  @spec to_empty(t(), options) :: t()
  def to_empty(buildable, options \\ [])

  # FIX THIS, REPORT TO ELIXIR: , to_empty: 1
  @optional_callbacks empty: 0, new: 1, extract: 1, insert: 2, peek: 1, peek: 2
end
