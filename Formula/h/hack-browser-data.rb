class HackBrowserData < Formula
  desc "Command-line tool for decrypting and exporting browser data"
  homepage "https://github.com/moonD4rk/HackBrowserData"
  url "https://github.com/moonD4rk/HackBrowserData/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "80d2b77ba764aaf88bae49d7a071c0309b8fb05f45af884b407ec58183b6478c"
  license "MIT"
  head "https://github.com/moonD4rk/HackBrowserData.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f446dfbdf2e136a6e51921c7ce711c940f057c8fcb681c6262a6f882e32f7113"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.buildDate=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/hack-browser-data"

    generate_completions_from_executable(bin/"hack-browser-data", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hack-browser-data version")

    output = shell_output("#{bin}/hack-browser-data -b chrome -f json --dir #{testpath}/results 2>&1")
    assert_match "[WRN] no browsers found\n", output
  end
end
