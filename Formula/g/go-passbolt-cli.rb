class GoPassboltCli < Formula
  desc "CLI for passbolt"
  homepage "https://www.passbolt.com/"
  url "https://github.com/passbolt/go-passbolt-cli/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "a1956f16f207ee63fa6f6373ec93c9e3e4f9fc406af6424ac3ddd6962de11d14"
  license "MIT"
  head "https://github.com/passbolt/go-passbolt-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "598de60b5c755e140c1d43bf8c4addde7d453235d66151ee4f64336f7732eeae"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"passbolt")

    generate_completions_from_executable(bin/"passbolt", shell_parameter_format: :cobra)
    mkdir "man"
    system bin/"passbolt", "gendoc", "--type", "man"
    man1.install Dir["man/*.1"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/passbolt --version")
    assert_match "Error: serverAddress is not defined", shell_output("#{bin}/passbolt list user 2>&1", 1)
  end
end
