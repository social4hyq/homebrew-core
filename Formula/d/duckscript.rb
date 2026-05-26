class Duckscript < Formula
  desc "Simple, extendable and embeddable scripting language"
  homepage "https://sagiegurari.github.io/duckscript"
  url "https://github.com/sagiegurari/duckscript/archive/refs/tags/0.11.1.tar.gz"
  sha256 "2e23b16359fb9b2c521f0bd250f6eb754bcb8ef40a7f8bf8076f87387276032a"
  license "Apache-2.0"
  head "https://github.com/sagiegurari/duckscript.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f89b0ad90433d3ca2be7b9d133d0bc09275be0224427cb7fdbf3b16910e31d5f"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  uses_from_macos "bzip2"

  on_linux do
    depends_on "openssl@3" # Uses Secure Transport on macOS
  end

  conflicts_with "duck", because: "both install `duck` binaries"

  def install
    system "cargo", "install", *std_cargo_args(path: "duckscript_cli", features: "tls-native")
  end

  test do
    (testpath/"hello.ds").write <<~EOS
      out = set "Hello World"
      echo The out variable holds the value: ${out}
    EOS
    output = shell_output("#{bin}/duck hello.ds")
    assert_match "The out variable holds the value: Hello World", output
  end
end
