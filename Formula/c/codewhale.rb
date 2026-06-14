class Codewhale < Formula
  desc "Local-first agent harness for DeepSeek V4 and open models"
  homepage "https://github.com/Hmbown/CodeWhale"
  url "https://github.com/Hmbown/CodeWhale/archive/refs/tags/v0.8.59.tar.gz"
  sha256 "dc3888365b491897cf790e637bd9ab9e7b9d3378696d0faf3530f3c98af186b8"
  license "MIT"
  head "https://github.com/Hmbown/CodeWhale.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "55e2ae6be846aac9eff6426a1e3c18269d1cbdcc1d417e5dfe9f56f92ce99678"
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
