class RushParallel < Formula
  desc "Cross-platform command-line tool for executing jobs in parallel"
  homepage "https://github.com/shenwei356/rush"
  url "https://github.com/shenwei356/rush/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "43ccc98c3c53b3995ee98fb1195ae3cdb7615c7fb8e4b2a6410c100733c764dc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dce517e39affc773ca7e4e12d21eed26c82d338a90362ed4fc39f4c4d9635cca"
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
