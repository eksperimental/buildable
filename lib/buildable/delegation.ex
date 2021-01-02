defmodule Buildable.Delegation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro to defined required function
  implementations in the module that implements the `Buildable` behaviour.

  To use it call `use Buildable.Delegation`.
  """
  defmacro __using__(_using_options) do
    quote do
      @impl Buildable
      defdelegate default_position(function_name), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate empty(buildable, options), to: Buildable

      @impl Buildable
      defdelegate empty(options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate into(buildable), to: Buildable

      @impl Buildable
      defdelegate new(enumerable, options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate pop(buildable), to: Buildable

      @impl Buildable
      defdelegate pop(buildable, position), to: Buildable

      @impl Buildable
      defdelegate put(buildable, term), to: Buildable

      @impl Buildable
      defdelegate put(buildable, term, position), to: Buildable

      @impl Buildable
      defdelegate reverse(buildable), to: Buildable
    end
  end
end
