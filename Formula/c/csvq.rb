class Csvq < Formula
  desc "SQL-like query language for csv"
  homepage "https://mithrandie.github.io/csvq"
  url "https://github.com/mithrandie/csvq/archive/refs/tags/v1.18.1.tar.gz"
  sha256 "69f98d0d26c055cbe4ebfe2cedf79c744bebafac604ea55fb0081826b1ac7b74"
  license "MIT"
  head "https://github.com/mithrandie/csvq.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84228c64927ec7b9b6d51088aec24d73b2e049fa1ace2e67d36b2050a16c6a8f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    system bin/"csvq", "--version"

    (testpath/"test.csv").write <<~CSV
      a,b,c
      1,2,3
    CSV
    expected = <<~CSV
      a,b
      1,2
    CSV
    result = shell_output("#{bin}/csvq --format csv 'SELECT a, b FROM `test.csv`'")
    assert_equal expected, result
  end
end
