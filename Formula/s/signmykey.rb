class Signmykey < Formula
  desc "Automated SSH Certificate Authority"
  homepage "https://signmykey.io/"
  url "https://github.com/signmykeyio/signmykey/archive/refs/tags/v0.8.9.tar.gz"
  sha256 "106a3a3d07aa2841d280ab378ce382a2bfca10101080936e2b02c4cc4e7d7392"
  license "MIT"
  head "https://github.com/signmykeyio/signmykey.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ffac78964f9020cb524620f25626c01d47c2f25f46965d9ba96b633e0063244"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/signmykeyio/signmykey/cmd.versionString=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"signmykey", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/signmykey version")

    require "pty"
    stdout, _stdin, _pid = PTY.spawn("#{bin}/signmykey server dev -u myremoteuser")
    sleep 2
    assert_match "Starting signmykey server in DEV mode", stdout.readline
  end
end
