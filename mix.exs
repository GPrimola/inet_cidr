defmodule InetCidr.Mixfile do
  use Mix.Project

  @source_url "https://github.com/cobenian/inet_cidr"

  def project do
    [
      app: :inet_cidr,
      version: "1.0.9",
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      # docs
      name: "InetCidr",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false, warn_if_outdated: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp dialyzer do
    [
      plt_local_path: "priv/plts/project.plt",
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end

  defp docs do
    [
      main: "InetCidr",
      extras: ["README.md", "LICENSE", "CHANGELOG.md", "Cheatsheet.cheatmd"],
      authors: ["Bryan Weber"]
    ]
  end

  defp description do
    """
    Classless Inter-Domain Routing (CIDR) library for Elixir.

    Compatible with Erlang's :inet module and support for IPv4 and IPv6
    """
  end

  defp package do
    [
      contributors: ["Bryan Weber"],
      maintainers: ["Bryan Weber"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/inet_cidr/changelog.html",
        "Cheatsheet" => "https://hexdocs.pm/inet_cidr/cheatsheet.html"
      }
    ]
  end
end
