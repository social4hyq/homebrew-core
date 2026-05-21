class Golines < Formula
  desc "Golang formatter that fixes long lines"
  homepage "https://github.com/segmentio/golines"
  url "https://github.com/segmentio/golines/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "ec1933e0fb73cf0517fd007d325603007aa65ce430267a70fc78cfea43d9716e"
  license "MIT"
  head "https://github.com/segmentio/golines.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ce78d21de657d3b2fd38932457ea4ae16c51a453390645f74c98ced3f653811d"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/golines --version")

    (testpath/"given.go").write <<~GO
      package main

      var strings = []string{"foo", "bar", "baz"}
    GO

    (testpath/"expected.go").write <<~GO
      package main

      var strings = []string{\n\t"foo",\n\t"bar",\n\t"baz",\n}
    GO

    assert_equal (testpath/"expected.go").read, shell_output("#{bin}/golines --max-len=30 given.go")
  end
end
