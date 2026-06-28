class Qo < Formula
  desc "Interactive minimalist TUI to query JSON, CSV, and TSV using SQL"
  homepage "https://github.com/kiki-ki/go-qo"
  url "https://github.com/kiki-ki/go-qo/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "c0fce1acfc0844c6b0c5a3ef133f861fcddb64d10b72e870c5530cdb3a2fdfb1"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8349a8cad1bd73966daa111b2126d385890c20a4f67a93874c4e220639179372"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/qo"
  end

  test do
    input = <<~CSV
      id,name,age,city
      1,Alice,30,Tokyo
      2,Bob,25,Osaka
      3,Carol,35,Kyoto
    CSV
    sql = "SELECT name FROM tmp WHERE city = 'Tokyo'"
    assert_match '"name": "Alice"', pipe_output("#{bin}/qo -i csv -q \"#{sql}\"", input)
  end
end
