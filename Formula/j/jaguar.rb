class Jaguar < Formula
  desc "Live reloading for your ESP32"
  homepage "https://toitlang.org/"
  url "https://github.com/toitlang/jaguar/archive/refs/tags/v1.67.0.tar.gz"
  sha256 "187630eaeb918ff7c9bdeff24c0910ae6e8fa30d795fe612473fee3245ea6671"
  license "MIT"
  head "https://github.com/toitlang/jaguar.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79d51e01239adb1db7f634f323159ea327b0f4b7ab2d0b95a93f7b251fbdca29"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.buildDate=#{time.iso8601}
      -X main.buildMode=release
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"jag"), "./cmd/jag"

    generate_completions_from_executable(bin/"jag", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Version:\t v#{version}", shell_output("#{bin}/jag --no-analytics version 2>&1")

    (testpath/"hello.toit").write <<~TOIT
      main:
        print "Hello, world!"
    TOIT

    # Cannot do anything without installing SDK to $HOME/.cache/jaguar/
    assert_match "You must setup the SDK", shell_output("#{bin}/jag run #{testpath}/hello.toit 2>&1", 1)
  end
end
