class Scmpuff < Formula
  desc "Numeric file selection shortcuts for common git commands"
  homepage "https://github.com/mroth/scmpuff"
  url "https://github.com/mroth/scmpuff/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "dbff8913217f6ec0915671057933eacd692e7810bf64ded25bba63e98240b789"
  license "MIT"
  head "https://github.com/mroth/scmpuff.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b42ac75678d361be238129eac6674776e80a0390a5f12ed7d909d883ee63b79f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.builtBy=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/scmpuff --version 2>&1")

    ENV["e1"] = "abc"
    assert_equal "abc", shell_output("#{bin}/scmpuff expand 1").strip
  end
end
