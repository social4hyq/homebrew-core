class LeafMd < Formula
  desc "Terminal Markdown previewer with a GUI-like experience"
  homepage "https://leaf.rivolink.mg/"
  url "https://github.com/RivoLink/leaf/archive/refs/tags/1.28.1.tar.gz"
  sha256 "594693cf012f51963f95090b7439dfd1c5194f18f12d93293dc7ad2c8909101b"
  license "MIT"
  head "https://github.com/RivoLink/leaf.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23373fee9e6244b6a810b616ddc5351b896908d43063135521bdfa9351e112d1"
  end

  depends_on "rust" => :build

  conflicts_with "leaf", because: "both install `leaf` binaries"
  conflicts_with "leaf-proxy", because: "both install `leaf` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.md").write "# Hello\n\nThis is a **test**."
    output = shell_output("#{bin}/leaf --inline test.md")
    assert_match "Hello", output
  end
end
