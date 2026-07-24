class Oxker < Formula
  desc "Terminal User Interface (TUI) to view & control docker containers"
  homepage "https://github.com/mrjackwills/oxker"
  url "https://github.com/mrjackwills/oxker/archive/refs/tags/v0.13.3.tar.gz"
  sha256 "e58c061519d4b5baade0651d18a0c0b7165dcaecf87db00f1d11c582e2dbea45"
  license "MIT"
  head "https://github.com/mrjackwills/oxker.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7e6fbe92e40529cf491a9f45314f4ae5faccadfb413cb1f6be7b1d43574be7e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oxker --version")

    assert_match "a value is required for '--host <HOST>' but none was supplied",
      shell_output("#{bin}/oxker --host 2>&1", 2)
  end
end
