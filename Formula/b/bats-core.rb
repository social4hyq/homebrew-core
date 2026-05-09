class BatsCore < Formula
  desc "Bash Automated Testing System"
  homepage "https://github.com/bats-core/bats-core"
  url "https://github.com/bats-core/bats-core/archive/refs/tags/v1.13.0.tar.gz"
  sha256 "a85e12b8828271a152b338ca8109aa23493b57950987c8e6dff97ba492772ff3"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c271895f442e72e770d9e53f71113ca28d047d6641778ef2f186d9d2a805322c"
  end

  def install
    system "./install.sh", prefix
  end

  test do
    (testpath/"test.sh").write <<~SHELL
      @test "no arguments prints message and usage instructions" {
        run bats
        [ $status -eq 1 ]
        [ "${lines[0]}" == 'Error: Must specify at least one <test>' ]
        [ "${lines[1]%% *}" == 'Usage:' ]
      }
      @test "skipped test" {
        skip
      }
    SHELL
    assert_equal <<~EOS, shell_output("#{bin}/bats test.sh")
      1..2
      ok 1 no arguments prints message and usage instructions
      ok 2 skipped test # skip
    EOS
  end
end
