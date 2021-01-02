defmodule Buildable.Delegation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro to defined required function
  implementations in the module that implements the `Buildable` behaviour.

  To use it call `use Buildable.Delegation`.
  """
  defmacro __using__(_using_options) do
    quote do
      @impl true
      defdelegate default_position(function_name), to: Buildable.unquote(__CALLER__.module)

      @impl true
      defdelegate empty(buildable, options), to: Buildable

      @impl true
      defdelegate empty(options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl true
      defdelegate into(buildable), to: Buildable

      @impl true
      defdelegate new(enumerable, options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl true
      defdelegate pop(buildable), to: Buildable

      @impl true
      defdelegate pop(buildable, position), to: Buildable

      @impl true
      defdelegate put(buildable, term), to: Buildable

      @impl true
      defdelegate put(buildable, term, position), to: Buildable

      @impl true
      defdelegate reverse(buildable), to: Buildable
    end
  end
end
