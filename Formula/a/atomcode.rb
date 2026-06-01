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
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f34a669255375edad7eafe35d2918d425342141c1b79a27b301f0e36db337d7"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/atomcode-cli")
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
