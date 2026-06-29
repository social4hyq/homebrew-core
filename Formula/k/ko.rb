class Ko < Formula
  desc "Build and deploy Go applications on Kubernetes"
  homepage "https://ko.build"
  url "https://github.com/ko-build/ko/archive/refs/tags/v0.19.1.tar.gz"
  sha256 "7accc1f4ad074285086573b084387bef5871872ef16e3f292d5818a99e4feeae"
  license "Apache-2.0"
  head "https://github.com/ko-build/ko.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "89743707f668f7f2fa02932c10f84a9f2dc0769cc80e790521e6f8d692f98b6a"
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
