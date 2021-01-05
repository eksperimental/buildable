defmodule Buildable.Util do
  @moduledoc false

  # @spec is_position(term) :: boolean
  defguard is_position(position) when position in [:start, :end]

  # @spec is_strategy(term) :: boolean
  defguard is_strategy(strategy) when strategy in [:fifo, :lifo]

  @spec invert_position(:start) :: :end
  @spec invert_position(:end) :: :start
  def invert_position(:start), do: :end
  def invert_position(:end), do: :start

  @spec calculate_extract_position(:fifo, :start) :: :start
  @spec calculate_extract_position(:fifo, :end) :: :end
  @spec calculate_extract_position(:lifo, :start) :: :end
  @spec calculate_extract_position(:lifo, :end) :: :start
  def calculate_extract_position(strategy, insert_position)
      when is_strategy(strategy) and is_position(insert_position) do
    case {strategy, insert_position} do
      {:fifo, position} ->
        position

      {:lifo, position} ->
        invert_position(position)
    end
  end
end
