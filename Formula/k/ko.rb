class Ko < Formula
  desc "Build and deploy Go applications on Kubernetes"
  homepage "https://ko.build"
  url "https://github.com/ko-build/ko/archive/refs/tags/v0.19.0.tar.gz"
  sha256 "76275e4262faf2aab10507b969a50728dbc3f48511e61d138c834243f60452b1"
  license "Apache-2.0"
  head "https://github.com/ko-build/ko.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bba599512b8c5bc6f0c1dc5e2c6fccdd952bf742fd03faf5c2920ddd7c16238"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/google/ko/pkg/commands.Version=#{version}")

    generate_completions_from_executable(bin/"ko", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/ko login reg.example.com -u brew -p test 2>&1")
    assert_match "logged in via #{testpath}/.docker/config.json", output
  end
end
