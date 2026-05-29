class Wgo < Formula
  desc "Watch arbitrary files and respond with arbitrary commands"
  homepage "https://github.com/bokwoon95/wgo"
  url "https://github.com/bokwoon95/wgo/archive/refs/tags/v0.6.4.tar.gz"
  sha256 "2ab2e49db58c25e424c979dddf54e1efdaeb210ce6f224a35e9eec5e52549583"
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
