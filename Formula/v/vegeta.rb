class Vegeta < Formula
  desc "HTTP load testing tool and library"
  homepage "https://github.com/tsenart/vegeta"
  url "https://github.com/tsenart/vegeta/archive/refs/tags/v12.13.0.tar.gz"
  sha256 "4a360c815f5a8bdcae6db184860788696bb1c63d6999cc676e47690fc8b659e5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a118489d5a845e6454e1ae1613cdab99f8e35119da267608918cd9a5429be33a"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Date=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    input = "GET https://example.com"
    output = pipe_output("#{bin}/vegeta attack -duration=1s -rate=1", input, 0)
    report = pipe_output("#{bin}/vegeta report", output, 0)
    assert_match "Requests      [total, rate, throughput]", report
  end
end
