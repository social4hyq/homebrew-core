class Hookdeck < Formula
  desc "Forward webhook events from Hookdeck to a local server"
  homepage "https://hookdeck.com"
  url "https://github.com/hookdeck/hookdeck-cli/archive/refs/tags/v2.3.1.tar.gz"
  sha256 "0fdc0241f841795324bbfb29f93019f6ecace75bbe637bea7f677f31b01cf4a4"
  license "Apache-2.0"
  head "https://github.com/hookdeck/hookdeck-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "75feb54a38b03251076d35bdb73db9ca76277bb711cbdc5ccb1767ef6e793fa9"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/hookdeck/hookdeck-cli/pkg/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"hookdeck", "completion",
                                         shell_parameter_format: "--shell=",
                                         shells:                 [:bash, :zsh])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hookdeck --version")
    assert_match "Provide a project API key", shell_output("#{bin}/hookdeck ci 2>&1", 1)
  end
end
