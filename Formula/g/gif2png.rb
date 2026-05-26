class Gif2png < Formula
  desc "Convert GIFs to PNGs"
  homepage "http://www.catb.org/~esr/gif2png/"
  url "https://gitlab.com/esr/gif2png/-/archive/3.0.3/gif2png-3.0.3.tar.bz2"
  sha256 "5d2770dce994e08ef54871ea4b0774e0ec0476aad5b3e47e21b4af59fdc8158b"
  license "BSD-2-Clause"
  head "https://gitlab.com/esr/gif2png.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2596628b32ff780331fc8c32d59034bc9cdb23dbf663040966110b72f32d3c29"
  end

  depends_on "go" => :build
  depends_on "xmlto" => :build

  uses_from_macos "python" # for web2png

  def install
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "make", "install", "prefix=#{prefix}"
  end

  test do
    pipe_output "#{bin}/gif2png -O", File.read(test_fixtures("test.gif"))
  end
end
