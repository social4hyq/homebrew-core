class Gotop < Formula
  desc "Terminal based graphical activity monitor inspired by gtop and vtop"
  homepage "https://github.com/xxxserxxx/gotop"
  url "https://github.com/xxxserxxx/gotop/archive/refs/tags/v4.2.0.tar.gz"
  sha256 "e9d9041903acb6bd3ffe94e0a02e69eea53f1128274da1bfe00fe44331ccceb1"
  license "BSD-3-Clause"
  head "https://github.com/xxxserxxx/gotop.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7a91ee95bc9a786013ee0126021d5889a394b7ea7ff4fdf259a70128c35f0a65"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -X main.Version=#{version}
      -X main.BuildDate=#{time.strftime("%Y%m%dT%H%M%S")}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/gotop"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gotop --version").chomp

    system bin/"gotop", "--write-config"
    conf_path = if OS.mac?
      "Library/Application Support/gotop/gotop.conf"
    else
      ".config/gotop/gotop.conf"
    end
    assert_path_exists testpath/conf_path
  end
end
