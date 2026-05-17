class Xurls < Formula
  desc "Extract urls from text"
  homepage "https://github.com/mvdan/xurls"
  url "https://github.com/mvdan/xurls/archive/refs/tags/v2.6.0.tar.gz"
  sha256 "476d92a0416fee965f928180a950691b85dbb8d11efc3dc7f795ecc106c76075"
  license "BSD-3-Clause"
  head "https://github.com/mvdan/xurls.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81ee42e795e9b5bd73a203c927dad456541c0334fc1c415fef5a8cd0a16f5a61"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/xurls"
  end

  test do
    output = pipe_output(bin/"xurls", "Brew test with https://brew.sh.")
    assert_equal "https://brew.sh", output.chomp

    output = pipe_output("#{bin}/xurls --fix", "Brew test with http://brew.sh.")
    assert_equal "Brew test with https://brew.sh/.", output.chomp
  end
end
