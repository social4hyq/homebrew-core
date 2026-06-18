class Rmux < Formula
  desc "Terminal multiplexer with a tmux-style CLI and daemon runtime"
  homepage "https://rmux.io"
  url "https://static.crates.io/crates/rmux/rmux-0.6.1.crate"
  sha256 "0dbcc917c881d1ceed1bd93caa218b59d192a48248aafc7fd9bf87fbc541a19f"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5621f21c94a9e5f41782f10f8bc6141528163cf9460579c964bb3de2e9109e58"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "rmux.1"
  end

  test do
    require "json"

    assert_match "rmux #{version}", shell_output("#{bin}/rmux -V")
    diagnostics = JSON.parse(shell_output("#{bin}/rmux diagnose --json"))
    assert_equal version.to_s, diagnostics.fetch("version")
  end
end
