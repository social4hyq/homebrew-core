class Sqlbench < Formula
  desc "Measures and compares the execution time of one or more SQL queries"
  homepage "https://github.com/felixge/sqlbench"
  url "https://github.com/felixge/sqlbench/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "deaf4c299891ce75abff00429343eded76e8ddc8295d488938aa9ee418a7c9b3"
  license "MIT"
  head "https://github.com/felixge/sqlbench.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fe2c955f6a64271ebb24667ec53349a0448dc2674a9e94a4948a1ccdd1bfa62a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    pkgshare.install "examples"
  end

  test do
    cp_r pkgshare/"examples", testpath
    assert_match "failed to connect to",
      shell_output("#{bin}/sqlbench #{testpath}/examples/sum/*.sql 2>&1", 1)
  end
end
