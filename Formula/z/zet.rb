class Zet < Formula
  desc "CLI utility to find the union, intersection, and set difference of files"
  homepage "https://github.com/yarrow/zet"
  url "https://github.com/yarrow/zet/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "a6f431927c16b22516e78a9ec7864d99e2676abae3acb46101df1c287e16f267"
  license any_of: ["Apache-2.0", "MIT"]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4383cff5d0c065dcc1023e4c0c3fa4a539560e3aed81b15ee3049fd8c616482b"
  end

  depends_on "rust" => :build

  # Backport fix for newer Rust
  patch do
    url "https://github.com/yarrow/zet/commit/7aba3b6016ede0b0a6b8aaff292bd7f6a0d7ac86.patch?full_index=1"
    sha256 "9fca853d07ac5a81aafe8513b64ce1ef338f1ff106d7ad2eb16add777ba2e897"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"foo.txt").write("1\n2\n3\n4\n5\n")
    (testpath/"bar.txt").write("1\n2\n4\n")
    assert_equal "3\n5\n", shell_output("#{bin}/zet diff foo.txt bar.txt")
  end
end
