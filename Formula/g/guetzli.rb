class Guetzli < Formula
  desc "Perceptual JPEG encoder"
  homepage "https://github.com/google/guetzli"
  url "https://github.com/google/guetzli/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "e52eb417a5c0fb5a3b08a858c8d10fa797627ada5373e203c196162d6a313697"
  license "Apache-2.0"
  head "https://github.com/google/guetzli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8ce0f8465ace9da5117ed6c983ed9e208714696a2bf0a67b04dc91f13579edb"
  end

  depends_on "pkgconf" => :build
  depends_on "libpng"

  def install
    system "make"
    bin.install "bin/Release/guetzli"
  end

  test do
    system bin/"guetzli", test_fixtures("test.png"), "test.jpg"
  end
end
