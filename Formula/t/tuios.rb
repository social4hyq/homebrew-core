class Tuios < Formula
  desc "Terminal UI OS (Terminal Multiplexer)"
  homepage "https://github.com/Gaurav-Gosain/tuios"
  url "https://github.com/Gaurav-Gosain/tuios/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "a803c947890abf8f82f77f287eabe360d4f4aa25dc13059d4264d626a9771daf"
  license "MIT"
  head "https://github.com/Gaurav-Gosain/tuios.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3cfaf11cfcec02d31f923123af9c6133f6eb1ffd2dcbc3b4475307a2b68b7ff6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601} -X main.builtBy=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/tuios"

    generate_completions_from_executable(bin/"tuios", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tuios --version")

    assert_match "git_hub_dark", shell_output("#{bin}/tuios --list-themes")
  end
end
