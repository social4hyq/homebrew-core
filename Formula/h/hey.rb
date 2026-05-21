class Hey < Formula
  desc "HTTP load generator, ApacheBench (ab) replacement"
  homepage "https://github.com/rakyll/hey"
  url "https://github.com/rakyll/hey/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "f678bc0f07c62a6513726298873940b70099aa85244efa813f6a0d925092ffe9"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d4a6a09dbb488b2cc670e751b5332092a79404bc96b95d0d095b7d2b4ba947b6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    output = "[200]	200 responses"
    assert_match output.to_s, shell_output("#{bin}/hey https://example.com")
  end
end
