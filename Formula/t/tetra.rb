class Tetra < Formula
  desc "Tetragon CLI to observe, manage and troubleshoot Tetragon instances"
  homepage "https://tetragon.io/"
  url "https://github.com/cilium/tetragon/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "ccccbe870b880212a86f959ce6f3f9f2d378646ad314100862ea6db5cb5f0a2b"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aae7e8657ca41de0c55da185ab49ba0a01abd51a7d4f436894066b560aabc143"
  end

  depends_on "go" => :build

  # Add missing darwin stub for bpfProbes function, upstream pr ref, https://github.com/cilium/tetragon/pull/4933
  patch do
    url "https://github.com/cilium/tetragon/commit/c99f6bc0b8bebb40cf3cdaf1216e62c8717d85cc.patch?full_index=1"
    sha256 "1a09f1f9324394a117a3f09a995ef56a5d7d4633169b9a8fe103425fabc840f3"
  end

  def install
    ldflags = "-s -w -X github.com/cilium/tetragon/pkg/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"tetra"), "./cmd/tetra"

    generate_completions_from_executable(bin/"tetra", shell_parameter_format: :cobra)
  end

  test do
    assert_match "CLI version: #{version}", shell_output("#{bin}/tetra version --build")
    assert_match "{}", pipe_output("#{bin}/tetra getevents", "invalid_event")
  end
end
