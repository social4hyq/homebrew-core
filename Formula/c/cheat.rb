class Cheat < Formula
  desc "Create and view interactive cheat sheets for *nix commands"
  homepage "https://github.com/cheat/cheat"
  url "https://github.com/cheat/cheat/archive/refs/tags/5.1.0.tar.gz"
  sha256 "5ef8864dacb5b37268d7d26cd01f74b99a33b2e5eb5b290e4221358410c99db4"
  license "MIT"
  head "https://github.com/cheat/cheat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ff6a7008f8acef5f9c0c70efb205567994ae1d773e17a1574be562659434b06"
  end

  depends_on "go" => :build

  conflicts_with "bash-snippets", because: "both install a `cheat` executable"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/cheat"

    generate_completions_from_executable(bin/"cheat", "--completion", shells: [:bash, :zsh, :fish, :pwsh])

    man1.install "doc/cheat.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cheat --version")

    output = shell_output("#{bin}/cheat --init 2>&1")
    assert_match "cheatpaths:", output
  end
end
