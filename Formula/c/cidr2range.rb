class Cidr2range < Formula
  desc "Converts CIDRs to IP ranges"
  homepage "https://ipinfo.io"
  url "https://github.com/ipinfo/cli/archive/refs/tags/cidr2range-1.2.0.tar.gz"
  sha256 "54af7600dc8c775f28d8fdc9debd86154e9293f07eb73f7372931d9c94744c81"
  license "Apache-2.0"
  head "https://github.com/ipinfo/cli.git", branch: "master"

  livecheck do
    url :stable
    regex(/^cidr2range[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e73658ac62dc9992ecdcb86694bead88a97cdc08d76483ae52d28f9f90f636d"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args, "./cidr2range"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/cidr2range --version").chomp
    assert_equal "1.1.1.0-1.1.1.3", shell_output("#{bin}/cidr2range 1.1.1.0/30").chomp
    assert_equal "0.0.0.0-255.255.255.255", shell_output("#{bin}/cidr2range 1.1.1.0/0").chomp
  end
end
