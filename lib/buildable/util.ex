defmodule Buildable.Util do
  @moduledoc false

  defguard is_position(position) when position in [:first, :last]

  @spec invert_position(:first) :: :last
  @spec invert_position(:last) :: :first
  def invert_position(:first), do: :last
  def invert_position(:last), do: :first

  defmacro __before_compile__(_env) do
    quote location: :keep,
          bind_quoted: [
            required_attributes: Buildable.required_attributes(),
            caller: Macro.escape(__CALLER__),
            module: __CALLER__.module
          ] do
      missing_attributes =
        for attribute <- required_attributes,
            Module.get_attribute(module, attribute, :undefined) == :undefined,
            do: attribute

      if missing_attributes != [] do
        raise Buildable.CompileError,
          attributes: missing_attributes,
          caller_module: module,
          file: caller.file,
          line: caller.line,
          module: Buildable.Implementation
      end
    end
  end
end
