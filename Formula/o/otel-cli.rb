class OtelCli < Formula
  desc "Tool for sending events from shell scripts & similar environments"
  homepage "https://github.com/equinix-labs/otel-cli"
  url "https://github.com/equinix-labs/otel-cli/archive/refs/tags/v0.4.5.tar.gz"
  sha256 "331a76783974318a31d9ab06e3f05af488e0ede3cce989f8d1b634450a345536"
  license "Apache-2.0"
  head "https://github.com/equinix-labs/otel-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7f2c1b610037fecd98017ab50f0b4abab393929ad9ce4f98a75f53ebfe59d610"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"otel-cli", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/otel-cli status")
    assert_equal "otel-cli", JSON.parse(output)["config"]["service_name"]
  end
end
