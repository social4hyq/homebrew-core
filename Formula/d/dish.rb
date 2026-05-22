class Dish < Formula
  desc "Lightweight monitoring service that efficiently checks socket connections"
  homepage "https://github.com/thevxn/dish"
  url "https://github.com/thevxn/dish/archive/refs/tags/v1.12.0.tar.gz"
  sha256 "4d8d18b837f03f7c3e03b6da79ffba1865256f2938f3995adafad48cb19a6b6f"
  license "MIT"
  head "https://github.com/thevxn/dish.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c031458dee23606d3bf340bd3c1a4a296bd66536b0e3a77c42f4a9726219d63"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/dish"
  end

  test do
    ouput = shell_output("#{bin}/dish https://example.com/:instance 2>&1", 3)
    assert_match "error loading socket list: failed to fetch sockets from remote source", ouput
  end
end
