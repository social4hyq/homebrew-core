class Tetra < Formula
  desc "Tetragon CLI to observe, manage and troubleshoot Tetragon instances"
  homepage "https://tetragon.io/"
  url "https://github.com/cilium/tetragon/archive/refs/tags/v1.7.1.tar.gz"
  sha256 "d4de499f97899855329b5ab8d7fc9fed5be349abd6e45b673c70554e4918bd2a"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71d7ce52a8cb7c3419134938098934172b649d4c629da6dde24bac3c7792709f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-X github.com/cilium/tetragon/pkg/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"tetra"), "./cmd/tetra"

    generate_completions_from_executable(bin/"tetra", shell_parameter_format: :cobra)
  end

  test do
    assert_match "CLI version: #{version}", shell_output("#{bin}/tetra version --build")
    assert_match "{}", pipe_output("#{bin}/tetra getevents", "invalid_event")
  end
end
