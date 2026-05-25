class Errcheck < Formula
  desc "Finds silently ignored errors in Go code"
  homepage "https://github.com/kisielk/errcheck"
  url "https://github.com/kisielk/errcheck/archive/refs/tags/v1.20.0.tar.gz"
  sha256 "d16b7757bf57dea5bbcfce42badd1bbfadd4c112b2da90b4ccaeb81c6c438c1e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d8a695b1b9471441dbe0b341dc6f1e3304eef0a81d3fae52408b0942eeb68a0"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args
    pkgshare.install "testdata"
  end

  test do
    system "go", "mod", "init", "brewtest"
    cp_r pkgshare/"testdata/.", testpath
    output = shell_output("#{bin}/errcheck ./...", 1)
    assert_match "main.go:", output
  end
end
