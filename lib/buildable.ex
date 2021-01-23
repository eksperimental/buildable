defprotocol Buildable do
  @moduledoc """
  Documentation for `Buildable`.
  """
  @type t :: term()
  @type element :: term()
  @type options :: keyword()
  @type position :: :first | :last

  @required_attributes [
    :extract_position,
    :insert_position,
    :into_position,
    :reversible?
  ]

  @doc false
  Kernel.def required_attributes() do
    @required_attributes
  end

  defmodule Behaviour do
    @moduledoc """
    A module that extends the protocol `Buildable` defining callbacks where the first argument is not a buildable.
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
    @callback new(collection :: Buildable.t() | Range.t()) :: Buildable.t()
    @callback new(collection :: Buildable.t() | Range.t(), Buildable.options()) :: Buildable.t()

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

  @spec reduce(t(), Buildable.Reducible.acc(), Buildable.Reducible.reducer()) ::
          Buildable.Reducible.result()
  def reduce(buildable, acc, reducer_function)

  @spec to_empty(t(), options) :: t()
  def to_empty(buildable, options \\ [])

  @optional_callbacks extract: 1, insert: 2, peek: 1, peek: 2
end

defmodule Buildable.CompileError do
  defexception [:file, :line, :attributes, :module, :caller_module]

  @impl true
  def message(%{
        file: file,
        line: line,
        attributes: attributes,
        caller_module: caller_module,
        module: module
      }) do
    attributes = Enum.map(attributes, &"@#{&1}")

    Exception.format_file_line(Path.relative_to_cwd(file), line) <>
      pluralize_attributes(attributes) <>
      " required to be defined in #{inspect(caller_module)} before calling \"use #{inspect(module)}\""
  end

  defp pluralize_attributes([attribute]) do
    "attribute #{attribute} is"
  end

  defp pluralize_attributes([_ | _] = attributes) do
    attributes = Enum.join(attributes, ", ")

    "attributes #{attributes} are"
  end
end
