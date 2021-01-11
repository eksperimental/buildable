# Buildable

**TODO: Add description**

`Buildable` is a protocol that allows users to build terms that implement this protocol.

The very basic version of any term type can be implemented with only three functions:
- `empty/1`: which returns the empty representation of the term;
- `insert/3`: which inserts an element into the term;
- `extract/2`: which extracts an element out of the term.

There are other two protocols that get automatically implemeneted, based on the callback implementations for `Buildable`,
which are:
- `Buildable.Collectable`: it collects elements into a buildable term. It is analog to Elixir core's `Collectable`, with a minor improvement.
- `Buildable.Reducible`: it reduces the buildable into an element. It is analog to Elixir core's `Enumerable`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `buildable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:buildable, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/buildable](https://hexdocs.pm/buildable).

