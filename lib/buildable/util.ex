defmodule Buildable.Util do
  @moduledoc false

  defguard is_position(position) when position in [:start, :end, nil]
end
