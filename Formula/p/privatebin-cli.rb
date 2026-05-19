class PrivatebinCli < Formula
  desc "CLI for creating and managing PrivateBin pastes"
  homepage "https://github.com/gearnode/privatebin"
  url "https://github.com/gearnode/privatebin/archive/refs/tags/v2.2.1.tar.gz"
  sha256 "cf11851f5e76d7b8d2b90dd662eb0a3dd03cd71f10cad01fb2f81ecf23d303b2"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6e2373864138abe76afee4865c6a5cffa25c89331a11300cc5e912bb08cfba0"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"privatebin"), "./cmd/privatebin"

    generate_completions_from_executable(bin/"privatebin", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/privatebin --version")

    assert_match "Error: no privatebin instance configured", shell_output("#{bin}/privatebin create foo 2>&1", 1)
  end
end
