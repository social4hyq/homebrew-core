class Rainfrog < Formula
  desc "Database management TUI for PostgreSQL/MySQL/SQLite"
  homepage "https://github.com/achristmascarl/rainfrog"
  url "https://github.com/achristmascarl/rainfrog/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "57a11a6a2287a9cd180f72f71e5f57617ded89ee1d22ab5e7ffe59d124ab9ef3"
  license "MIT"
  head "https://github.com/achristmascarl/rainfrog.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19b6ea3e00cf54357c9da5c22a48feb7fc8db2811f249eff6a1996fcf28729a3"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # rainfrog is a TUI application
    assert_match version.to_s, shell_output("#{bin}/rainfrog --version")
  end
end
