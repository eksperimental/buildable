defmodule Buildable.Delegation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro to defined required function
  implementations in the module that implements the `Buildable` behaviour.

  To use it call `use Buildable.Delegation`.
  """
  defmacro __using__(_using_options) do
    quote do
      @impl Buildable
      defdelegate default(option), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate empty(options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate extract(buildable), to: Buildable

      @impl Buildable
      defdelegate extract(buildable, position), to: Buildable

      @impl Buildable
      defdelegate insert(buildable, term), to: Buildable

      @impl Buildable
      defdelegate insert(buildable, term, position), to: Buildable

      @impl Buildable
      defdelegate into(buildable), to: Buildable

      @impl Buildable
      defdelegate new(enumerable, options \\ []), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable
      defdelegate peek(buildable), to: Buildable

      @impl Buildable
      defdelegate peek(buildable, position), to: Buildable

      @impl Buildable
      defdelegate reverse(buildable), to: Buildable

      @impl Buildable
      defdelegate to_empty(buildable, options \\ []), to: Buildable
    end
  end
end
