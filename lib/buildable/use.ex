defmodule Buildable.Use do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for `c:Buildable.new/1`, `c:Buildable.new/2`, `c:Buildable.new_transform/3`. 

  To use it call `use Buildable.Use`.
  """
  defmacro __using__(_using_options) do
    quote do
      @impl true
      def new(enumerable, options \\ []) when is_list(options) do
        Enum.into(enumerable, empty(options))
      end

      @impl true
      def new_transform(enumerable, transform_fun, options)
          when is_function(transform_fun, 1) and is_list(options) do
        Enum.into(enumerable, empty(options), transform_fun)
      end

      defoverridable new: 1, new: 2, new_transform: 3
    end
  end
end