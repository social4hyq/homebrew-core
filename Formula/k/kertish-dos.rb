class KertishDos < Formula
  desc "Kertish Object Storage and Cluster Administration CLI"
  homepage "https://github.com/freakmaxi/kertish-dos"
  url "https://github.com/freakmaxi/kertish-dos/archive/refs/tags/v22.2.0147.tar.gz"
  version "22.2.0147-532592"
  sha256 "fe76b525762a3240e8c4bc8e6d7caedebf466aec81c1a22f8014d6881c2bdaf6"
  license "GPL-3.0-only"
  head "https://github.com/freakmaxi/kertish-dos.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "26590e822f012dfbe86c5bfcc6c163bb0e4e40b63caebd72009086d4e97d373b"
  end

  depends_on "go" => :build

  def install
    cd "fs-tool" do
      system "go", "build", *std_go_args(output: bin/"krtfs", ldflags: "-X main.version=#{version}")
    end
    cd "admin-tool" do
      system "go", "build", *std_go_args(output: bin/"krtadm", ldflags: "-X main.version=#{version}")
    end
  end

  test do
    port = free_port
    assert_match("failed.\nlocalhost:#{port}: head node is not reachable",
      shell_output("#{bin}/krtfs -t localhost:#{port} ls"))
    assert_match("localhost:#{port}: manager node is not reachable",
      shell_output("#{bin}/krtadm -t localhost:#{port} -get-clusters", 70))
  end
end
