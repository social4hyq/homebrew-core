class Yj < Formula
  desc "CLI to convert between YAML, TOML, JSON and HCL"
  homepage "https://github.com/sclevine/yj"
  url "https://github.com/sclevine/yj/archive/refs/tags/v5.1.0.tar.gz"
  sha256 "9a3e9895181d1cbd436a1b02ccf47579afacd181c73f341e697a8fe74f74f99d"
  license "Apache-2.0"
  head "https://github.com/sclevine/yj.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b03fc4d6fcae4283ef3fc509bcb422c91e818277e9910b2bb98c1c487dc5d04f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match '{"a":1}', pipe_output("#{bin}/yj -t", "a=1")
  end
end
