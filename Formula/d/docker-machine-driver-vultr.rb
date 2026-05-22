class DockerMachineDriverVultr < Formula
  desc "Docker Machine driver plugin for Vultr Cloud"
  homepage "https://github.com/vultr/docker-machine-driver-vultr"
  url "https://github.com/vultr/docker-machine-driver-vultr/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "451a6e31ab4e5fb9be2c2730b1b03f5039a8ac2b41f677824e1b8a15036ab815"
  license "MIT"
  head "https://github.com/vultr/docker-machine-driver-vultr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d36d91d0833660808fb039b4a74b1fb5ed8266e9b84983d345dddc171646b8ce"
  end

  depends_on "go" => :build
  depends_on "docker-machine"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./machine"
  end

  test do
    assert_match "--vultr-api-key",
      shell_output("#{Formula["docker-machine"].bin}/docker-machine create --driver vultr -h")
  end
end
