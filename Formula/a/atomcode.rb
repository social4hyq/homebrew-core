class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://raw.atomgit.com/atomgit_atomcode/atomcode/archive/refs/heads/v4.23.1.tar.gz"
  sha256 "ca655016393cd31780f92fe37a9ada89164584cf776d218d8c42e6898562b229"
  license "MIT"

  livecheck do
    url "https://atomgit.com/atomgit_atomcode/atomcode.git"
    strategy :git
    regex(/^v?(\d+\.\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7da32997c1e0a0ac64325df04508a5a793c9c9000d2b95e2c694dc4da8eba0db"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/atomcode-cli")
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
