defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type command :: {:cont, term()} | :done | :halt
  @type element :: term()
  @type options :: keyword()
  @type position :: :first | :last | nil
  @type transform_fun :: (term() -> term())

  @doc """
  Defines the default options for the implementation.transform_fun

  Option can be:
  - `strategy`: It is the stratagy for extracting elements out of the buildable. Accepted values are:transform_fun
    - `queue`: Queue, also know as FIFO (firt in, first out), meaning when the users extract elements, they get extracted in the same order as they were inserted.
    - `stack`: Stack, also now as LIFO (last in, first out), meaning when the users extract elements, they get extracted in
      the reversed order that they were inserted. Think of it as a stack of plates. The last element inserted into the buildable, is the first one to be extracted. This is the default option if you are using `use Buildable.Implementation`.
    - `nil`: Means that no strategy is used. This is used when the buildable does not keep track of the order of ins

  - `insert_position`: where to insert a new element in the buildable. Accepted values are `:first`, `:last`, and `nil`.
    `nil` means that the buildable has not concept of inserting elements in a particular order.
  - `extract_position`: where to extract the element from the buildable. Accepted values are `:first`, `:last`, and `nil`.
    `nil` means that the buildable has not concept of inserting elements in a particular order.
  """
  @callback default(:strategy) :: :queue | :stack | nil
  @callback default(:insert_position) :: position()
  @callback default(:extract_position) :: position()
  @callback default(:reversible?) :: boolean()

  @callback empty() :: t()
  @callback empty(options()) :: t()
  @callback new(Enum.t()) :: t()
  @callback new(Enum.t(), options()) :: t()

  @optional_callbacks empty: 0, new: 1

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
  def to_empty(buildable, options)

  @optional_callbacks peek: 1, peek: 2
end
