defmodule Buildable.Util do
  @moduledoc false

  # @spec is_position(term) :: boolean
  defguard is_position(position) when position in [:first, :last]

  # @spec is_strategy(term) :: boolean
  defguard is_strategy(strategy) when strategy in [:queue, :stack, nil]

  @spec invert_position(:first) :: :last
  @spec invert_position(:last) :: :first
  def invert_position(:first), do: :last
  def invert_position(:last), do: :first

  @spec calculate_extract_position(nil, :first | :last) :: :first
  @spec calculate_extract_position(:queue, :first) :: :first
  @spec calculate_extract_position(:queue, :last) :: :last
  @spec calculate_extract_position(:stack, :first) :: :last
  @spec calculate_extract_position(:stack, :last) :: :first
  def calculate_extract_position(strategy, insert_position)
      when is_strategy(strategy) and is_position(insert_position) do
    case {strategy, insert_position} do
      {nil, _} ->
        :first

      {:queue, position} ->
        position

      {:stack, position} ->
        invert_position(position)
    end
  end
end
