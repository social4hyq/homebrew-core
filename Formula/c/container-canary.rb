class ContainerCanary < Formula
  desc "Test and validate container requirements against versioned manifests"
  homepage "https://github.com/NVIDIA/container-canary"
  url "https://github.com/NVIDIA/container-canary/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "3f0ceab899931d221f4d88ca01783d98446198a04ce56c8065a111a78872cff6"
  license "Apache-2.0"
  head "https://github.com/NVIDIA/container-canary.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34a11af77427b166f1dc68b6784ecd3246633595ca65669e4a379fe2b2087bd8"
  end

  depends_on "go" => :build
  depends_on "docker" => :test

  def install
    ldflags = %W[
      -s -w
      -X github.com/nvidia/container-canary/internal.Version=#{version}
      -X github.com/nvidia/container-canary/internal.Buildtime=#{time.iso8601}
      -X github.com/nvidia/container-canary/internal.Commit=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"canary")

    generate_completions_from_executable(bin/"canary", shell_parameter_format: :cobra)
  end

  test do
    ENV["DOCKER_HOST"] = "unix://#{testpath}/invalid.sock"

    resource "awesome_validator" do
      url "https://raw.githubusercontent.com/NVIDIA/container-canary/refs/heads/main/examples/awesome.yaml"
      sha256 "7f5e2f78df709d4179c1ae1b549669f80a4307c4f698080fac27efae96b02a42"
    end

    assert_match version.to_s, shell_output("#{bin}/canary version 2>&1")

    testpath.install resource("awesome_validator")
    test_image = "busybox:latest"
    output = shell_output("#{bin}/canary validate --file awesome.yaml #{test_image} 2>&1", 1)
    assert_match "Error: Docker requires root privileges to run", output
  end
end
