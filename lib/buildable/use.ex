defmodule Buildable.Use do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for `c:Buildable.empty/2`,
  `c:Buildable.new/1`, `c:Buildable.new/2`,
  `c:Buildable.into/2`, `c:Buildable.into/3`.

  To use it call `use Buildable.Use`.
  """
  defmacro __using__(_using_options) do
    quote do
      # Behaviour callbacks

      @impl true
      def default_position(:put), do: :start
      def default_position(:pop), do: :start

      @impl true
      def empty(_buildable, options) do
        empty(options)
      end

      @impl true
      def new(enumerable, options \\ []) when is_list(options) do
        Build.into(empty(options), enumerable)
      end

      # Protocol callbacks
      @impl true
      def pop(buildable), do: pop(buildable, default_position(:pop))

      @impl true
      def put(buildable, term), do: put(buildable, term, default_position(:put))

      @impl true
      defdelegate into(buildable), to: Buildable.Collectable

      @impl true
      def into(buildable, enumerable, transform_fun \\ &Function.identity/1)
          when is_function(transform_fun, 1) do
        Build.into(buildable, enumerable, transform_fun)
      end

      defoverridable empty: 2,
                     new: 1,
                     new: 2,
                     into: 1,
                     into: 2,
                     into: 3,
                     pop: 1,
                     put: 2
    end
  end
end
