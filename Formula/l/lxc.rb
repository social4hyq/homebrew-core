class Lxc < Formula
  desc "CLI client for interacting with LXD"
  homepage "https://ubuntu.com/lxd"
  url "https://github.com/canonical/lxd/releases/download/lxd-6.9/lxd-6.9.tar.gz"
  sha256 "c13dff67aa400d3cc4ef3a20344a500fa691263132ad9de843c5485caffe47dd"
  license "AGPL-3.0-only"
  head "https://github.com/canonical/lxd.git", branch: "main"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e744505d400e8b34a5b31dd8bd2cf1619f313473af70786df2f5c0e6b2e1977a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./lxc"

    generate_completions_from_executable(bin/"lxc", shell_parameter_format: :cobra)
  end

  test do
    output = JSON.parse(shell_output("#{bin}/lxc remote list --format json"))
    assert_equal "https://cloud-images.ubuntu.com/releases/", output["ubuntu"]["Addr"]

    assert_match version.to_s, shell_output("#{bin}/lxc --version")
  end
end
