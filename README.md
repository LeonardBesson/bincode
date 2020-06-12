# Bincode

<p>
  <a href="https://hex.pm/packages/bincode">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/bincode.svg">
  </a>
  <a href="https://hexdocs.pm/bincode">
    <img alt="Hex Docs" src="http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat">
  </a>
</p>
<p>
  <a href="https://github.com/LeonardBesson/bincode/actions">
    <img alt="CI" src="https://github.com/LeonardBesson/bincode/workflows/ci/badge.svg">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://img.shields.io/hexpm/l/bincode">
  </a>
</p>

Bincode allows you to share data between Elixir and Rust using
  Rust's [Bincode](https://github.com/servo/bincode) binary format.

  You can implement your custom serialization manually, but for most use cases
  you can simply declare the Rust structs and enums using `Bincode.declare_struct/3` and
  `Bincode.declare_enum/3`

  ## Supported types

  Most Rust types are supported, plus user defined structs and enums.

  | Rust                   | Bincode notation          | Elixir typespec                  |
  |------------------------|---------------------------|----------------------------------|
  | `u8`                   | `:u8`                     | `non_neg_integer`                |
  | ...                    | ...                       | ...                              |
  | `u128`                 | `:u128`                   | `non_neg_integer`                |
  | `i8`                   | `:i8`                     | `integer`                        |
  | ...                    | ...                       | ...                              |
  | `i128`                 | `:i128`                   | `integer`                        |
  | `f32`                  | `:f32`                    | `float`                          |
  | `f64`                  | `:f64`                    | `float`                          |
  | `bool`                 | `:bool`                   | `boolean`                        |
  | `String`               | `:string`                 | `binary`                         |
  | `(u32, String)`        | `{:u32, :string}`         | `{non_neg_integer, binary}`      |
  | `Option<f32>`          | `{:option, :f32}`         | `float \| nil`                   |
  | `Vec<String>`          | `{:list, :string}`        | `[binary]`                       |
  | `HashMap<i64, String>` | `{:map, {:i64, :string}}` | `%{required(integer) => binary}` |
  | `HashSet<u8>`          | `{:set, :u8}`             | `MapSet.t(non_neg_integer)`      |

  The endianness is little since that's the default used by Bincode.
  Tuples are implemented for a max size of 12 by default. That should be enough for
  most practical cases but if you need to serialize tuples with more elements you can
  set `max_tuple_size` in the mix config, like so: `config :bincode, max_tuple_size: 23`

  ## Examples

  Consider the typical example were we want to send data structures across the network.
  Here with a Rust client and Elixir server:

  ```rust
  #[derive(Serialize, Deserialize)]
  pub struct PacketSendMessage {
    pub from: u64,
    pub to: u64,
    pub content: String,
  }

  pub fn send_message(sender_id: u64, receiver_id: u64) {
    let message = PacketSendMessage {
        from: sender_id,
        to: receiver_id,
        content: "hello!".to_owned()
    };
    let encoded: Vec<u8> = bincode::serialize(&message).unwrap();

    // now send "encoded" to Elixir app
  }
  ```

  On the Elixir side you can simply declare the same packet struct and deserialize the received data:

  ```elixir
  defmodule Packets do
    import Bincode

    declare_struct(PacketSendMessage,
      from: :u64,
      to: :u64,
      content: :string
    )
  end

  alias Packets.PacketSendMessage

  # Receive "data" from the network
  {:ok, {%PacketSendMessage{} = message, rest}} = PacketSendMessage.deserialize(data)
  Logger.info("Received message packet #{inspect(message)}")
  ```
  


## Installation

Add `bincode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bincode, "~> 0.2.0"}
  ]
end
```

## Documentation

[https://hexdocs.pm/bincode](https://hexdocs.pm/bincode).
