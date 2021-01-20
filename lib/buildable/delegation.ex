defmodule Buildable.Delegation do
  @moduledoc """
  Convenience module providing the `__using__/1` macro to defined required function
  implementations in the module that implements the `Buildable` behaviour.

  To use it call `use Buildable.Delegation`.
  """
  defmacro __using__(_using_options) do
    quote location: :keep do
      @behaviour Buildable.Behaviour

      @impl Buildable.Behaviour
      defdelegate default(option), to: Buildable.unquote(__CALLER__.module)

      @impl Buildable.Behaviour
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

      @impl Buildable.Behaviour
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
