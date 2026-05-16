class Bkcrack < Formula
  desc "Crack legacy zip encryption with Biham and Kocher's known plaintext attack"
  homepage "https://github.com/kimci86/bkcrack"
  url "https://github.com/kimci86/bkcrack/archive/refs/tags/v1.8.1.tar.gz"
  sha256 "bb6a6d0bb1ccbb3c39cf8b3113581b5514b127023bbe0e864992c57e79346053"
  license "Zlib"
  head "https://github.com/kimci86/bkcrack.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b2118892fe8b89e7f3f7d41832b7ce21c0ac2ce6eea4f071c0452af5fd21e3b7"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/src/bkcrack"
    pkgshare.install "example"
  end

  test do
    output = shell_output("#{bin}/bkcrack -L #{pkgshare}/example/secrets.zip")
    assert_match "advice.jpg", output
    assert_match "spiral.svg", output

    assert_match version.to_s, shell_output("#{bin}/bkcrack --help")
  end
end
