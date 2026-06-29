class CloudProviderKind < Formula
  desc "Cloud provider for KIND clusters"
  homepage "https://kubernetes-sigs.github.io/cloud-provider-kind/"
  url "https://github.com/kubernetes-sigs/cloud-provider-kind/archive/refs/tags/v0.11.1.tar.gz"
  sha256 "87a8c713be6b0635f7cd32832c40a929afd93ddffc57a03076a7574bd7dfc43c"
  license "Apache-2.0"
  head "https://github.com/kubernetes-sigs/cloud-provider-kind.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae5a9e74296b8e48e37d40e6d7660ef5786c53a6a38d6c5914e5494d5639840a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"cloud-provider-kind", shell_parameter_format: :cobra)
  end

  test do
    ENV["DOCKER_HOST"] = "unix://#{testpath}/invalid.sock"
    status_output = shell_output("#{bin}/cloud-provider-kind 2>&1", 1)
    if OS.mac?
      # Should error out as requires root on Mac
      assert_match "Error: please run this again with `sudo`", status_output
    elsif OS.linux?
      # Should error out because without docker or podman
      assert_match "no supported container runtime found", status_output
    end
  end
end
