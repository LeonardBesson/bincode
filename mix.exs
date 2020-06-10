defmodule Bincode.MixProject do
  use Mix.Project

  def project do
    [
      app: :bincode,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Bincode",
      source_url: "https://github.com/LeonardBesson/bincode"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22.1"}
    ]
  end

  defp description() do
    "Binary serialization library compatible with Rust's Bincode crate. Share Rust structs with your Elixir application."
  end

  defp package() do
    [
      name: "bincode",
      licenses: ["MIT"],
      maintainers: ["Léonard Besson"],
      links: %{"GitHub" => "https://github.com/LeonardBesson/bincode"}
    ]
  end
end
