class Hookdeck < Formula
  desc "Forward webhook events from Hookdeck to a local server"
  homepage "https://hookdeck.com"
  url "https://github.com/hookdeck/hookdeck-cli/archive/refs/tags/v2.5.0.tar.gz"
  sha256 "16b421f3af652ebbea24e445815a750cae51584bc8bd069c2ffaad718b69076c"
  license "Apache-2.0"
  head "https://github.com/hookdeck/hookdeck-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "39a2c052fc0376ce32ad6e0552a22fa6b25fedae4fe0ba70b2091efbe6307990"
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
