class Superseedr < Formula
  desc "BitTorrent Client in your Terminal"
  homepage "https://github.com/Jagalite/superseedr"
  url "https://github.com/Jagalite/superseedr/archive/refs/tags/v1.0.14.tar.gz"
  sha256 "cd6f3d31eb5064465f2bcf49260772800048f77d2ee6f54b98b23e1d6642ef14"
  license "GPL-3.0-or-later"
  head "https://github.com/Jagalite/superseedr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "148e8882acf186f7068c22f5f1cc05baeb8d4a8dee9d6512a35ece055fcf44c2"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    # jitterentropy (vendored in aws-lc-sys) requires -O0, which the compiler
    # shim overrides; opt out instead of compiling AWS-LC at -O0.
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
    system "cargo", "install", *std_cargo_args
  end

  test do
    # superseedr is a TUI application
    assert_match version.to_s, shell_output("#{bin}/superseedr --version")
  end
end
