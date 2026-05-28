class IpinfoCli < Formula
  desc "Official CLI for the IPinfo IP Address API"
  homepage "https://ipinfo.io/"
  url "https://github.com/ipinfo/cli/archive/refs/tags/ipinfo-3.3.2.tar.gz"
  sha256 "ad5464068ec370599bd7624cd69f58047ac56d8140ba8e50b468c80e06c438a1"
  license "Apache-2.0"
  head "https://github.com/ipinfo/cli.git", branch: "master"

  livecheck do
    url :stable
    regex(/^ipinfo[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81f6be7a2bd23403ee9906501a73a4b7e88959358f4d8f8e778666b81d745246"
  end

  depends_on "go" => :build

  conflicts_with "ipinfo", because: "ipinfo and ipinfo-cli install the same binaries"

  def install
    system "./ipinfo/build.sh"
    bin.install "build/ipinfo"
    generate_completions_from_executable(bin/"ipinfo", shell_parameter_format: :cobra)
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/ipinfo version").chomp
    assert_equal "1.1.1.0\n1.1.1.1\n1.1.1.2\n1.1.1.3\n", `#{bin}/ipinfo prips 1.1.1.1/30`
  end
end
