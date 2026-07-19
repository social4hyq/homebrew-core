class Elio < Formula
  desc "Batteries-included terminal file manager with rich previews"
  homepage "https://github.com/elio-fm/elio"
  url "https://github.com/elio-fm/elio/archive/refs/tags/v1.11.1.tar.gz"
  sha256 "e99d3b8403a3aa77eda5ab75d88f47a5b39468a82df530059af73485c149b7ca"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b4f3ee002697860d590cb31cde77d4aae974e55df97c97bc3493059f2fb76c3"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    missing = testpath/"missing-directory"
    output = shell_output("#{bin}/elio #{missing} 2>&1", 1)
    assert_match "no such file or directory", output
  end
end
