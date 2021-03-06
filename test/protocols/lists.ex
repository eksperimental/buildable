positions = %{
  FIFO => [
    extract: :last,
    insert: :first,
    into: :last
  ],
  FILO => [
    extract: :first,
    insert: :first,
    into: :last
  ],
  LILO => [
    extract: :first,
    insert: :last,
    into: :last
  ],
  LIFO => [
    extract: :last,
    insert: :last,
    into: :last
  ],
  ALL_FIRST => [
    extract: :first,
    insert: :first,
    into: :first
  ],
  ALL_LAST => [
    extract: :last,
    insert: :last,
    into: :last
  ]
}

for {module, position} <- positions do
  defmodule module do
    defstruct list: []

    @behaviour Buildable

    use Buildable.Delegation
  end
end

defmodule Lists.Using do
  @moduledoc false

  defmacro __using__(module) do
    quote location: :keep do
      defguard size(struct) when length(:erlang.map_get(:list, struct))

      ##############################################
      # Behaviour callbacks

      @impl Buildable.Behaviour
      def empty(_options), do: %unquote(module){}

      ##############################################
      # Protocol callbacks
      @impl Buildable
      def extract(%unquote(module){list: list} = struct, position) do
        case Buildable.List.extract(list, position) do
          :error ->
            :error

          {:ok, value, new_list} ->
            {:ok, value, %{struct | list: new_list}}
        end
      end

      @impl Buildable
      def insert(%unquote(module){list: list} = struct, term, position) do
        new_list = Buildable.List.insert(list, term, position)
        %{struct | list: new_list}
      end

      @impl Buildable
      def reverse(%unquote(module){list: list} = struct) do
        %{struct | list: Buildable.List.reverse(list)}
      end

      @impl Buildable
      def to_empty(%unquote(module){list: list} = struct, options \\ []) do
        %{struct | list: Buildable.List.to_empty(list, options)}
      end
    end
  end
end

for {module, position} <- positions do
  defimpl Buildable, for: module do
    @derive [Buildable.List]

    @insert_position position[:insert]
    @extract_position position[:extract]
    @into_position position[:into]
    @reversible? true

    use Buildable.Implementation
    use Lists.Using, unquote(module)
  end
end

defimpl Inspect, for: [FIFO, FILO, LIFO, LILO] do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#" <> inspect(__MODULE__.__impl__(:for)) <> "<", to_doc(struct.list, opts), ">"])
  end
end
