defmodule Buildable.Util do
  @moduledoc false

  defguard is_position(position) when position in [:first, :last]

  @spec invert_position(:first) :: :last
  @spec invert_position(:last) :: :first
  def invert_position(:first), do: :last
  def invert_position(:last), do: :first
end
