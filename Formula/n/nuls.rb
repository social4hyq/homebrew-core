class Nuls < Formula
  desc "NuShell-inspired ls with colorful table output"
  homepage "https://github.com/cesarferreira/nuls"
  url "https://static.crates.io/crates/nuls/nuls-0.2.0.crate"
  sha256 "24fb69fbb3ca465f6e051d36c75867f9fbe3e358eedb931fcb65125e4946e08e"
  license "MIT"
  head "https://github.com/cesarferreira/nuls.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fbf21a24e048a1cd66d11be8b517449531c8bfa278cbeaaa274452b6a9d563c4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"foo.txt").write "hello\n"

    assert_match version.to_s, shell_output("#{bin}/nuls --version")
    assert_match "foo.txt", shell_output("#{bin}/nuls #{testpath}")
  end
end
