class Qshell < Formula
  desc "Shell Tools for Qiniu Cloud"
  homepage "https://github.com/qiniu/qshell"
  url "https://github.com/qiniu/qshell/archive/refs/tags/v2.19.13.tar.gz"
  sha256 "3b9a963441475cdf3ffebcb09db9a5f60a1fea9263f2ea680a9f1c479abf2cca"
  license "MIT"
  head "https://github.com/qiniu/qshell.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d34ac538b3abd92f9d1e6d8b662a84560e46bd5c3f9feeeb659dbe7447674471"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/qiniu/qshell/v2/iqshell/common/version.version=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./main"
    generate_completions_from_executable(bin/"qshell", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output "#{bin}/qshell -v"
    assert_match "qshell version v#{version}", output

    # Test base64 encode of string "abc"
    output2 = shell_output "#{bin}/qshell b64encode abc"
    assert_match "YWJj", output2
  end
end
