class Restish < Formula
  desc "CLI tool for interacting with REST-ish HTTP APIs"
  homepage "https://rest.sh/"
  url "https://github.com/rest-sh/restish/archive/refs/tags/v2.1.1.tar.gz"
  sha256 "28bb590d518c17ff51f6c07ad3cbbd417fb22a2cdbe122052f16b95cac652121"
  license "MIT"
  head "https://github.com/rest-sh/restish.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "492399c9c598183ddd32cdfb3b9dcd1370c426a5d25c29058cc0588dcdc9cdd3"
  end

  depends_on "go" => :build

  def install
    # Workaround to avoid patchelf corruption when cgo is required (for crypto11)
    if OS.linux? && Hardware::CPU.arch == :arm64
      ENV["CGO_ENABLED"] = "1"
      ENV["GO_EXTLINK_ENABLED"] = "1"
      ENV.append "GOFLAGS", "-buildmode=pie"
    end

    ldflags = "-s -w -X github.com/rest-sh/restish/v2/internal/cli.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/restish"

    generate_completions_from_executable(bin/"restish", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/restish --version")

    output = shell_output("#{bin}/restish https://httpbin.org/json")
    assert_match "slideshow", output

    output = shell_output("#{bin}/restish https://httpbin.org/get?foo=bar")
    assert_match '"foo": "bar"', output
  end
end
