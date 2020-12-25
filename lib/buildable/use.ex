defmodule Buildable.Use do
  @moduledoc """
  Convenience module providing the `__using__/1` macro.

  It defines the default implementations for `c:Buildable.new/1`,
  `c:Buildable.new/2`, `c:Buildable.into/2`, `c:Buildable.into/3`.

  To use it call `use Buildable.Use`.
  """
  defmacro __using__(_using_options) do
    quote do
      def new(enumerable, options \\ []) when is_list(options) do
        into(enumerable, empty(options))
      end

      def into(buildable, enumerable, transform_fun \\ &Function.identity/1)
          when is_function(transform_fun, 1) do
        Enum.into(buildable, enumerable, transform_fun)
      end

      defoverridable new: 1, new: 2, into: 2, into: 3
    end
  end
end
