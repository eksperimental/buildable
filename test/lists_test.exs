defmodule ListsTest do
  use ExUnit.Case

  test "FIFO" do
    struct = %{__struct__: FIFO, list: [2, 4, 6]}

    assert FIFO.insert(struct, 0) == %{__struct__: FIFO, list: [0, 2, 4, 6]}
    assert FIFO.extract(struct) == {:ok, 6, %{__struct__: FIFO, list: [2, 4]}}
    assert FIFO.reverse(struct) == %{__struct__: FIFO, list: [6, 4, 2]}
    assert FIFO.to_empty(struct) == %FIFO{}

    assert Build.into(%FIFO{}, [1, 2, 3], fn v -> v * 2 end) ==
             %{__struct__: FIFO, list: [2, 4, 6]}

    assert Build.into(%FIFO{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: FIFO, list: [a: 2, b: 4, c: 6]}

    assert Build.into(%FIFO{}, 1..3, fn v -> v * 2 end) ==
             %{__struct__: FIFO, list: [2, 4, 6]}
  end

  test "FILO" do
    assert Build.into(%FILO{}, [1, 2, 3], fn v -> v * 2 end) ==
             %{__struct__: FILO, list: [2, 4, 6]}

    struct = %{__struct__: FILO, list: [2, 4, 6]}

    assert FILO.insert(struct, 0) == %{__struct__: FILO, list: [0, 2, 4, 6]}
    assert FILO.extract(struct) == {:ok, 2, %{__struct__: FILO, list: [4, 6]}}
    assert FILO.reverse(struct) == %{__struct__: FILO, list: [6, 4, 2]}
  end

  test "LIFO" do
    assert Build.into(%LIFO{}, [1, 2, 3], fn v -> v * 2 end) ==
             %{__struct__: LIFO, list: [2, 4, 6]}

    struct = %{__struct__: LIFO, list: [2, 4, 6]}

    assert LIFO.insert(struct, 8) == %{__struct__: LIFO, list: [2, 4, 6, 8]}
    assert LIFO.extract(struct) == {:ok, 6, %{__struct__: LIFO, list: [2, 4]}}
    assert LIFO.reverse(struct) == %{__struct__: LIFO, list: [6, 4, 2]}
  end

  test "LILO" do
    assert Build.into(%LILO{}, [1, 2, 3], fn v -> v * 2 end) ==
             %{__struct__: LILO, list: [2, 4, 6]}

    struct = %{__struct__: LILO, list: [2, 4, 6]}

    assert LILO.insert(struct, 8) == %{__struct__: LILO, list: [2, 4, 6, 8]}
    assert LILO.extract(struct) == {:ok, 2, %{__struct__: LILO, list: [4, 6]}}
    assert LILO.reverse(struct) == %{__struct__: LILO, list: [6, 4, 2]}
  end

  test "Build basic functions" do
    fifo = %{__struct__: FIFO, list: [2, 4, 6]}

    assert Build.insert(fifo, 0) == %{__struct__: FIFO, list: [0, 2, 4, 6]}
    assert Build.extract(fifo) == {:ok, 6, %{__struct__: FIFO, list: [2, 4]}}
    assert Build.to_empty(fifo) == %FIFO{}

    assert Build.into(%FIFO{}, [a: 1, b: 2, c: 3], fn {k, v} -> {k, v * 2} end) ==
             %{__struct__: FIFO, list: [a: 2, b: 4, c: 6]}

    assert Build.into(%FIFO{}, 1..3, fn v -> v * 2 end) ==
             %{__struct__: FIFO, list: [2, 4, 6]}
  end
end
