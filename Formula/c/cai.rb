class Cai < Formula
  desc "CLI tool for prompting LLMs"
  homepage "https://github.com/ad-si/cai"
  url "https://github.com/ad-si/cai/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "5a2cc76aae7ebbc691ac5705749c254c95fda1c423418da9dfc869503a4229a6"
  license "ISC"
  head "https://github.com/ad-si/cai.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a372a1936aa10163d4e3c65ba4ee05bd8070d1f243e6940de94724ae47f7b4c4"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output("#{bin}/cai anthropic claude-opus Which year did the Titanic sink 2>&1", 1)
    assert_match "An API key must be provided", output

    output = shell_output("#{bin}/cai ollama llama3 Which year did the Titanic sink 2>&1", 1)
    assert_match "error sending request for url", output
  end
end
