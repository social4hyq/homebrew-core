class Imgdiff < Formula
  desc "Pixel-by-pixel image difference tool"
  homepage "https://github.com/n7olkachev/imgdiff"
  url "https://github.com/n7olkachev/imgdiff/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "e057fffbf9960caf90d69387d6bc52e4c59637d75b6ee19cbc40d8a3238877e4"
  license "MIT"
  head "https://github.com/n7olkachev/imgdiff.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6c7362e75a533e37e4c7fcd9058505337f9522153b55e2a90a48a997d97fbb1"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd"
  end

  test do
    test_image = test_fixtures("test.png")
    output = shell_output("#{bin}/imgdiff #{test_image} #{test_image}")
    assert_match "Images are equal", output
  end
end
