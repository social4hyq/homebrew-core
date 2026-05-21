class Pget < Formula
  desc "File download client"
  homepage "https://github.com/Code-Hex/pget"
  url "https://github.com/Code-Hex/pget/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "fa7646bec975dd3995fb45d6b1f190565d6c4fae03c46c4eda34716c83ede03e"
  license "MIT"
  head "https://github.com/Code-Hex/pget.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f652ee1e9ef5fa2916ffdef3048f752f8c36e93a65b08d403aaf892a3313bf6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/pget"
  end

  test do
    file = "https://raw.githubusercontent.com/Homebrew/homebrew-core/HEAD/README.md"
    system bin/"pget", "-p", "4", file
    assert_path_exists testpath/"README.md"

    assert_match version.to_s, shell_output("#{bin}/pget --help", 1)
  end
end
