defmodule Buildable.Util do
  @moduledoc false

  # @spec is_position(term) :: boolean
  defguard is_position(position) when position in [:first, :last]

  @spec invert_position(:first) :: :last
  @spec invert_position(:last) :: :first
  def invert_position(:first), do: :last
  def invert_position(:last), do: :first
end
