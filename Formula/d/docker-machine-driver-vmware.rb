class DockerMachineDriverVmware < Formula
  desc "VMware Fusion & Workstation docker-machine driver"
  homepage "https://www.vmware.com/products/personal-desktop-virtualization.html"
  url "https://github.com/machine-drivers/docker-machine-driver-vmware.git",
      tag:      "v0.1.5",
      revision: "faa4b93573820340d44333ffab35e2beee3f984a"
  license "Apache-2.0"
  head "https://github.com/machine-drivers/docker-machine-driver-vmware.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "295d62bcb6d4beeae2a89b4bb1c8719abc9182f1dd787b4be7909b2e8d738a04"
  end

  depends_on "go" => :build
  depends_on "docker-machine"

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.version=#{version}")
  end

  test do
    docker_machine = Formula["docker-machine"].opt_bin/"docker-machine"
    output = shell_output("#{docker_machine} create --driver vmware -h")
    assert_match "engine-env", output
  end
end
