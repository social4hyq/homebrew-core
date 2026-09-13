class RushParallel < Formula
  desc "Cross-platform command-line tool for executing jobs in parallel"
  homepage "https://github.com/shenwei356/rush"
  url "https://github.com/shenwei356/rush/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "5f38d11af5ab8f3a9cc2c2d30f735bf6372276eba30e27530aa2393986f82a26"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "04d315e33c5c28c4fbc8bddff39f980ba0fdf58446b64d16917c0af05f4f4bfd"
  end

  depends_on "go" => :build

  conflicts_with "rush", because: "both install `rush` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"rush")
  end

  test do
    assert_equal <<~EOS, pipe_output("#{bin}/rush -k 'echo 0{}'", (1..4).to_a.join("\n"))
      01
      02
      03
      04
    EOS
  end
end
