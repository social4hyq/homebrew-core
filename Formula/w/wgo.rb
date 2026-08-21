class Wgo < Formula
  desc "Watch arbitrary files and respond with arbitrary commands"
  homepage "https://github.com/bokwoon95/wgo"
  url "https://github.com/bokwoon95/wgo/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "4d70bdd313600df64927928dc767c1e1ba980dcbb0da1cf03e9fa8bf4fdc5d55"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ee7e1082e3cf7fde1ab7828cf38cc1c684d93e07c04f19352fdcb791c422fc7"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = shell_output("#{bin}/wgo -exit echo testing")
    assert_match "testing", output
  end
end
