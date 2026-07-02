class Rmux < Formula
  desc "Terminal multiplexer with a tmux-style CLI and daemon runtime"
  homepage "https://rmux.io"
  url "https://static.crates.io/crates/rmux/rmux-0.8.0.crate"
  sha256 "f6fe70b80deab4c6566e5be5f2d492fe5c5123168ed2655961e787cf2c33c354"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "53f7677a8917cabbf5f3b73b5cf221b7b73876243f07e4d8bddb6999653957e3"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "docs/man/rmux.1"
  end

  test do
    require "json"

    assert_match "rmux #{version}", shell_output("#{bin}/rmux -V")
    diagnostics = JSON.parse(shell_output("#{bin}/rmux diagnose --json"))
    assert_equal version.to_s, diagnostics.fetch("version")
  end
end
