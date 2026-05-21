class Simg2img < Formula
  desc "Tool to convert Android sparse images to raw images and back"
  homepage "https://github.com/anestisb/android-simg2img"
  url "https://github.com/anestisb/android-simg2img/archive/refs/tags/1.1.5.tar.gz"
  sha256 "d9e9ec2c372dbbb69b9f90b4da24c89b092689e45cd5f74f0e13003bc367f3fc"
  license "Apache-2.0"
  head "https://github.com/anestisb/android-simg2img.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b27ca094a95e1364ed75f26e78bad7d78d7f2a5cfae4b75f5375d13fca44a328"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    system "dd", "if=/dev/zero", "of=512k-zeros.img", "bs=512", "count=1024"
    assert_equal 524288, (testpath/"512k-zeros.img").size?,
                 "Could not create 512k-zeros.img with 512KiB of zeros"
    system bin/"img2simg", "512k-zeros.img", "512k-zeros.simg"
    assert_equal 44, (testpath/"512k-zeros.simg").size?,
                 "Converting 512KiB of zeros did not result in a 44 byte simg"
    system bin/"simg2img", "512k-zeros.simg", "new-512k-zeros.img"
    assert_equal 524288, (testpath/"new-512k-zeros.img").size?,
                 "Converting a 44 byte simg did not result in 512KiB"
    system "diff", "512k-zeros.img", "new-512k-zeros.img"
  end
end
