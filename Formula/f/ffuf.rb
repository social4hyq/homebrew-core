class Ffuf < Formula
  desc "Fast web fuzzer written in Go"
  homepage "https://github.com/ffuf/ffuf"
  url "https://github.com/ffuf/ffuf/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "cdb2e58259f380862850eba587f71a9dc1738fb5edc1ea60414fae30fd0ed4f2"
  license "MIT"
  head "https://github.com/ffuf/ffuf.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "222769e0eb8e565c79835d3bdab7574681b612f4ac2eccd29499b4ac3e9e9fbd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"words.txt").write <<~EOS
      dog
      cat
      horse
      snake
      ape
    EOS

    output = shell_output("#{bin}/ffuf -u https://example.org/FUZZ -w words.txt 2>&1")
    assert_match %r{:: Progress: \[5/5\].*Errors: 0 ::$}, output
  end
end
