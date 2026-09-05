class Blocky < Formula
  desc "Fast and lightweight DNS proxy as ad-blocker for local network"
  homepage "https://0xerr0r.github.io/blocky/"
  url "https://github.com/0xerr0r/blocky/archive/refs/tags/v0.35.0.tar.gz"
  sha256 "c5874e2790aa21def45dd0ed9bd932ef2666ad412839f307c93c6a1bd94c20f5"
  license "Apache-2.0"
  head "https://github.com/0xerr0r/blocky.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bb40bc698e937d75fc8fac7e40ad0f73e4cf41a698fdcfe7099be852548c553e"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/0xERR0R/blocky/util.Version=#{version}
      -X github.com/0xERR0R/blocky/util.BuildTime=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:, output: sbin/"blocky")

    pkgetc.install "docs/config.yml"

    generate_completions_from_executable(sbin/"blocky", shell_parameter_format: :cobra)
  end

  service do
    run [opt_sbin/"blocky", "--config", etc/"blocky/config.yml"]
    keep_alive true
    require_root true
  end

  test do
    # client
    assert_match "Version: #{version}", shell_output("#{sbin}/blocky version")

    # server
    assert_match "NOT OK", shell_output("#{sbin}/blocky healthcheck", 1)
  end
end
