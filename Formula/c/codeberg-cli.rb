class CodebergCli < Formula
  desc "CLI for Codeberg"
  homepage "https://codeberg.org/Aviac/codeberg-cli"
  url "https://codeberg.org/Aviac/codeberg-cli/archive/v0.5.5.tar.gz"
  sha256 "09902e3511c24316e9aab4cbd51492d00eb978ee81429e873de80bc9a485c549"
  license "AGPL-3.0-or-later"
  head "https://codeberg.org/Aviac/codeberg-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdb4449976450f6bed51c764affc8a19b4e6a965ba771cc3733f8d4f14429c88"
  end

  deprecate! date: "2026-05-13", because: :repo_archived, replacement_formula: "forgejo-cli"
  disable! date: "2027-05-13", because: :repo_archived, replacement_formula: "forgejo-cli"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"berg", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/berg --version")

    assert_match "Successfully created berg config", shell_output("#{bin}/berg config generate")

    output = shell_output("#{bin}/berg repo info --owner-repo Aviac/codeberg-cli 2>&1", 1)
    assert_match "Couldn't find login data", output
  end
end
