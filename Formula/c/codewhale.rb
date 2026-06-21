class Codewhale < Formula
  desc "Local-first agent harness for DeepSeek V4 and open models"
  homepage "https://github.com/Hmbown/CodeWhale"
  url "https://github.com/Hmbown/CodeWhale/archive/refs/tags/v0.8.63.tar.gz"
  sha256 "11f85c9a680ba37e59c6fa6a3c492e00dc7b4c73f065676ae15752f5eac2ebfe"
  license "MIT"
  head "https://github.com/Hmbown/CodeWhale.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de52d8819bb3589baaa576da09c6019018545c7e1c6e1c831bc553bcec14d7dc"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/cli")
    system "cargo", "install", *std_cargo_args(path: "crates/tui")
  end

  test do
    assert_match "codewhale", shell_output("#{bin}/codewhale --version 2>&1")
  end
end
