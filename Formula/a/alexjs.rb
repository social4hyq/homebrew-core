class Alexjs < Formula
  desc "Catch insensitive, inconsiderate writing"
  homepage "https://alexjs.com"
  url "https://github.com/get-alex/alex/archive/refs/tags/11.0.1.tar.gz"
  sha256 "0c41d5d72c0101996aecb88ae2f423d6ac7a2fc57f93384d1a193d2ce67c4ffb"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "536452d243f62a2115d7753711b2c3a8a3d1964e7ab0902e9b0c7d42a5b2e113"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.txt").write "garbageman"
    assert_match "garbage collector", shell_output("#{bin}/alex test.txt 2>&1", 1)
  end
end
