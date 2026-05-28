class Tracetest < Formula
  desc "Build integration and end-to-end tests"
  homepage "https://docs.tracetest.io/"
  url "https://github.com/kubeshop/tracetest/archive/refs/tags/v1.7.1.tar.gz"
  sha256 "9f2fb4edab3e469465302c70bcddf0f48517306db0004afdc1d016f30b5380e5"
  license "MIT" # MIT license for the CLI, TCL license for agent
  head "https://github.com/kubeshop/tracetest.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9414cd4f41aa507aa4080c73b51d1c8cc6a93db0c257b38bc5ae0b8c24f138f4"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/kubeshop/tracetest/cli/config.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cli"

    generate_completions_from_executable(bin/"tracetest", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tracetest version 2>&1", 1)

    assert_match "Server: Not Configured", shell_output("#{bin}/tracetest list 2>&1", 1)
  end
end
