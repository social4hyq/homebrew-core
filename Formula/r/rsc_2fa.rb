class Rsc2fa < Formula
  desc "Two-factor authentication on the command-line"
  homepage "https://pkg.go.dev/rsc.io/2fa"
  url "https://github.com/rsc/2fa/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "d8db6b9a714c9146a4b82fd65b54f9bdda3e58380bce393f45e1ef49e4e9bee5"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62f824912b3700b13f8710483b436b83918c82c2a7fc4c662fa7ed1c8ba619de"
  end

  depends_on "go" => :build

  def install
    system "go", "build", "-mod=mod", *std_go_args(ldflags: "-s -w", output: bin/"2fa")
  end

  test do
    out = shell_output("#{bin}/2fa -help 2>&1", 2)
    assert_match(/^usage:/, out)

    out = pipe_output("#{bin}/2fa -add example 2>&1", "AAAAAAAAAAAAAAAA\n", 0)
    assert_match(/^2fa key for example:/, out)

    out = shell_output("#{bin}/2fa example")
    assert_match(/^[0-9]{6}\n$/, out)
  end
end
