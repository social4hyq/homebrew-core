class Wgo < Formula
  desc "Watch arbitrary files and respond with arbitrary commands"
  homepage "https://github.com/bokwoon95/wgo"
  url "https://github.com/bokwoon95/wgo/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "4d70bdd313600df64927928dc767c1e1ba980dcbb0da1cf03e9fa8bf4fdc5d55"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfea833dabb2ae5a1f05acaafd5417b51f44134502f7ae361cb5f1ffc86c7612"
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
