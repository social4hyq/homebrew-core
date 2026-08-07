class Firefly < Formula
  desc "Create and manage the Hyperledger FireFly stack for blockchain interaction"
  homepage "https://hyperledger-firefly.github.io/firefly/latest/"
  url "https://github.com/hyperledger-firefly/cli/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "f9c73ca146af0e9e5ed5ef68d45c5733375f211233e5093ca060c9ddf8587f0b"
  license "Apache-2.0"
  head "https://github.com/hyperledger-firefly/cli.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "713e0450b0e8d1bc0133f5268055d67a69573eb3c7273e90913cb68201e1734b"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -X github.com/hyperledger-firefly/cli/cmd.BuildDate=#{time.iso8601}
      -X github.com/hyperledger-firefly/cli/cmd.BuildCommit=#{tap.user}
      -X github.com/hyperledger-firefly/cli/cmd.BuildVersionOverride=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./ff"

    generate_completions_from_executable(bin/"firefly", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/firefly version --short")
    assert_match "Error: an error occurred while running docker", shell_output("#{bin}/firefly start mock 2>&1", 1)
  end
end
