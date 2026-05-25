class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://raw.atomgit.com/atomgit_atomcode/atomcode/archive/refs/heads/v4.23.0.tar.gz"
  sha256 "f9fd780cd50df5857b3707a0ec2206eb49f8f7f682746fda337e271570907298"
  license "MIT"

  livecheck do
    url "https://atomgit.com/atomgit_atomcode/atomcode.git"
    strategy :git
    regex(/^v?(\d+\.\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ca948f7cb4dcd2d3f8b7790d3b14e7c9516c5c33a39b529d4b24e70cb181e9d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/atomcode-cli")
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
