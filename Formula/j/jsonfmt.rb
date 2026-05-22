class Jsonfmt < Formula
  desc "Like gofmt, but for JSON files"
  homepage "https://github.com/caarlos0/jsonfmt"
  url "https://github.com/caarlos0/jsonfmt/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "07494aaec99d4c8cd7f0cea1bacd32e1d20321e541848aa6aafa64d64d89c9ab"
  license "MIT"
  head "https://github.com/caarlos0/jsonfmt.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "278e54b79cb977b808b238ea1bbb4cf0bd42ec6d4fdf58c4e59331f8ff67bd3a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jsonfmt --version")

    (testpath/"test.json").write <<~JSON
      {"foo":"bar","baz":{"qux":"quux","corge":"grault"}}
    JSON

    expected_output = <<~JSON
      {
        "foo": "bar",
        "baz": {
          "qux": "quux",
          "corge": "grault"
        }
      }
    JSON

    system bin/"jsonfmt", "--write", testpath/"test.json"
    assert_equal expected_output, (testpath/"test.json").read
  end
end
