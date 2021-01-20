defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type element :: term()
  @type options :: keyword()
  @type position :: :first | :last

  defmodule Behaviour do
    @moduledoc """
    Module that defines callbacks for the `Buildable` protocol where the first argument is not a buildable itself.
    """

    @doc """
    Defines the default options for the implementation.transform_fun

    Option can be:
    - `extract_position`: where to extract the element from the buildable. Accepted values are `:first`, and `:last`.
    - `insert_position`: where to insert a new element in the buildable. Accepted values are `:first`, and `:last`.
    - `into_position`: where to extract the element from the buildable. Accepted values are `:first`, and `:last`.
    - `reversible?`: whether the buildable can be reversed. Accepted values are `true`, and `false`.
    """
    @callback default(:extract_position) :: Buildable.position()
    @callback default(:insert_position) :: Buildable.position()
    @callback default(:into_position) :: Buildable.position()
    @callback default(:reversible?) :: boolean()

    @callback empty() :: Buildable.t()
    @callback empty(Buildable.options()) :: Buildable.t()
    @callback new(collection :: Buildable.t() | Enum.t()) :: Buildable.t()
    @callback new(collection :: Buildable.t() | Enum.t(), Buildable.options()) :: Buildable.t()

    # FIX THIS, REPORT TO ELIXIR: , to_empty: 1
    @optional_callbacks empty: 0, new: 1
  end

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

  @spec into(t) ::
          {initial_acc :: term, collector :: (term, Buildable.Collectable.command() -> t | term)}
  def into(buildable)

  @spec peek(t()) :: {:ok, element()} | :error
  def peek(buildable)

  @spec peek(t(), position) :: {:ok, element()} | :error
  def peek(buildable, position)

  @spec reverse(buildable) :: updated_buildable | buildable
        when buildable: t(), updated_buildable: t()
  def reverse(buildable)

  @spec to_empty(t(), options) :: t()
  def to_empty(buildable, options \\ [])

  @optional_callbacks extract: 1, insert: 2, peek: 1, peek: 2
end

defmodule Buildable.MissingArgumentError do
  defexception [:file, :line, :attributes, :module, :caller_module]

  @impl true
  def message(%{
        file: file,
        line: line,
        attributes: attributes,
        caller_module: caller_module,
        module: module
      }) do
    attributes = Enum.join(Enum.map(attributes, &"@#{&1}"), ", ")

    Exception.format_file_line(Path.relative_to_cwd(file), line) <>
      " attributes #{attributes} are required to be defined in #{inspect(caller_module)} before calling \"use #{inspect(module)}\""
  end
end
