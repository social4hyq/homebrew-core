class ConsulBackinator < Formula
  desc "Consul backup and restoration application"
  homepage "https://github.com/myENA/consul-backinator"
  url "https://github.com/myENA/consul-backinator/archive/refs/tags/v1.6.6.tar.gz"
  sha256 "b668801ca648ecf888687d7aa69d84c3f2c862f31b92076c443fdea77c984c58"
  license "MPL-2.0"
  head "https://github.com/myENA/consul-backinator.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6420e6217329baf1097fbf52c9f09c837dfd58ab665a85b724d29f37001d723c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.appVersion=#{version}")
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/consul-backinator --version 2>&1").strip

    assert_match "[Error] Failed to backup key data:",
      shell_output("#{bin}/consul-backinator backup 2>&1", 1)
  end
end
