class Htmltest < Formula
  desc "HTML validator written in Go"
  homepage "https://github.com/wjdp/htmltest"
  url "https://github.com/wjdp/htmltest/archive/refs/tags/v0.17.0.tar.gz"
  sha256 "2c89e56c837f4d715db9816942e007c973ba58de53d249abc80430c4b7e72f88"
  license "MIT"
  head "https://github.com/wjdp/htmltest.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a23d2424066d7163cc18ac2e6ef24f67ea18f7f8bd12c726b48d68ecdc9d32d4"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -X main.date=#{time.iso8601}
      -X main.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"test.html").write <<~HTML
      <!DOCTYPE html>
      <html>
        <body>
          <nav>
          </nav>
          <article>
            <p>Some text</p>
          </article>
        </body>
      </html>
    HTML
    assert_match "htmltest started at", shell_output("#{bin}/htmltest test.html")
  end
end
