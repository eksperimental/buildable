positions = %{
  FIFO => [
    insert: :first,
    extract: :last
  ],
  FILO => [
    insert: :first,
    extract: :first
  ],
  LILO => [
    insert: :last,
    extract: :first
  ],
  LIFO => [
    insert: :last,
    extract: :last
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

      @impl true
      def empty(_options), do: %unquote(module){}

      ##############################################
      # Protocol callbacks
      @impl true
      def extract(%unquote(module){list: list} = struct, position) do
        case Buildable.List.extract(list, position) do
          :error ->
            :error

          {:ok, value, new_list} ->
            {:ok, value, %{struct | list: new_list}}
        end
      end

      @impl true
      def insert(%unquote(module){list: list} = struct, term, position) do
        new_list = Buildable.List.insert(list, term, position)
        %{struct | list: new_list}
      end

      @impl true
      def reverse(%unquote(module){list: list} = struct) do
        %{struct | list: Buildable.List.reverse(list)}
      end

      @impl true
      def to_empty(%unquote(module){list: list} = struct, options \\ []) do
        %{struct | list: Buildable.List.to_empty(list, options)}
      end
    end
  end
end

for {module, position} <- positions do
  defimpl Buildable, for: module do
    @derive [Buildable.List]

    use Buildable.Implementation,
      default: [
        insert_position: position[:insert],
        extract_position: position[:extract],
        reversible?: true
      ]

    use Lists.Using, unquote(module)
  end
end

defimpl Inspect, for: [FIFO, FILO, LIFO, LILO] do
  import Inspect.Algebra

  def inspect(struct, opts) do
    concat(["#" <> inspect(__MODULE__.__impl__(:for)) <> "<", to_doc(struct.list, opts), ">"])
  end
end
