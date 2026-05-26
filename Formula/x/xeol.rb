class Xeol < Formula
  desc "Xcanner for end-of-life software in container images, filesystems, and SBOMs"
  homepage "https://github.com/xeol-io/xeol"
  url "https://github.com/xeol-io/xeol/archive/refs/tags/v0.10.8.tar.gz"
  sha256 "d26842a3ef75feef22270db4250d16d106e7f9d3ac5f4300ede1b6fc795cdaeb"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6a37ffa3520e462cc5663c7bb7e1f69b6713abdf6356bacd0c3e1733e76c12fa"
  end

  depends_on "go" => :build

  def install
    # Turn off homebrew specific database checks
    # Issue ref: https://github.com/xeol-io/xeol/issues/568
    inreplace "xeol/db/curator.go", "isBrewTest == \"1\"", "isBrewTest == \"999\""

    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.gitCommit=#{tap.user}
      -X main.buildDate=#{time.iso8601}
      -X main.gitDescription=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/xeol"

    generate_completions_from_executable(bin/"xeol", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xeol version")

    output = shell_output("#{bin}/xeol db update 2>&1")
    assert_match "EOL database updated to latest version!", output

    output = shell_output("#{bin}/xeol db status 2>&1")
    assert_match "Status:    valid", output

    output = shell_output("#{bin}/xeol alpine:latest 2>&1")
    assert_match "no EOL software has been found", output
  end
end
