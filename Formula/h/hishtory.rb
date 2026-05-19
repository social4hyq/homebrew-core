class Hishtory < Formula
  desc "Your shell history: synced, queryable, and in context"
  homepage "https://hishtory.dev"
  url "https://github.com/ddworken/hishtory/archive/refs/tags/v0.335.tar.gz"
  sha256 "f312acc99195ca035db7b6612408169ce3a14c170f85dba238f9a29ca7825a3d"
  license "MIT"
  head "https://github.com/ddworken/hishtory.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88a9213c4a6b397d1576a20dec87d1bfa977f0dd05e8f6a438358eea174bf620"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/ddworken/hishtory/client/lib.Version=#{version}
      -X github.com/ddworken/hishtory/client/lib.GitCommit=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"hishtory", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hishtory --version")

    output = shell_output("#{bin}/hishtory init --offline")
    assert_match "Setting secret hishtory key", output
    assert_match "Enabled: true", shell_output("#{bin}/hishtory status")
  end
end
