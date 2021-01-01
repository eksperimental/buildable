defmodule Buildable.Use do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for `c:Buildable.empty/2`,
  `c:Buildable.new/1`, `c:Buildable.new/2`.

  To use it call `use Buildable.Use`.
  """
  defmacro __using__(_using_options) do
    quote do
      import Buildable.Util, only: [is_position: 1]

      # Behaviour callbacks

      @impl true
      def default_position(:put), do: :start
      def default_position(:pop), do: :start

      @impl true
      def new(enumerable, options \\ []) when is_list(options) do
        Build.into(empty(options), enumerable)
      end

      # Protocol callbacks
      @impl true
      def empty(_buildable, options) do
        empty(options)
      end

      @impl true
      defdelegate into(buildable), to: Buildable.Collectable

      @impl true
      def pop(buildable), do: pop(buildable, default_position(:pop))

      @impl true
      def put(buildable, term), do: put(buildable, term, default_position(:put))

      @impl true
      def reverse(buildable) do
        buildable_module = Buildable.impl_for(buildable)

        {:done, result} =
          Buildable.Reducible.reduce(buildable, {:cont, buildable_module.empty()}, fn element,
                                                                                      acc ->
            {:cont, buildable_module.put(acc, element)}
          end)

        result
      end

      defoverridable empty: 2,
                     into: 1,
                     new: 1,
                     new: 2,
                     pop: 1,
                     put: 2,
                     reverse: 1
    end
  end
end
