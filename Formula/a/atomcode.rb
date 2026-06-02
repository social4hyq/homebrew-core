class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://raw.atomgit.com/atomgit_atomcode/atomcode/archive/refs/heads/v4.24.0.tar.gz"
  sha256 "9d696c442fb9c95d623f32b1641734ec6693915eafb961d9b84185ad4a5445f4"
  license "MIT"

  livecheck do
    url "https://atomgit.com/atomgit_atomcode/atomcode.git"
    strategy :git
    regex(/^v?(\d+\.\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f199dd09dedb746bd00a0d5d6693948b0ee570e52ade02ac8129e46f27b57fea"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/atomcode-cli")
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
