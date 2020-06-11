defprotocol Bincode.Serializer do
  @moduledoc """
  Protocol responsible for serializing Elixir terms into binary representation.
  It is automatically implemented when you declare a struct with `Bincode.declare_struct`
  but you can also manually implement it for any Elixir term.
  """

  @doc """
  Serialize the given `term` to a binary representation compatible with Rust's Bincode.
  Returns `{:ok, serialized_term}` or `{:error, error_message}`.
  """
  @spec serialize(any) :: {:ok, binary} | {:error, binary}
  def serialize(term)
end
