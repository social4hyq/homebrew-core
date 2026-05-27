class Libnsbmp < Formula
  desc "Decoding library for BMP and ICO image file formats"
  homepage "https://www.netsurf-browser.org/projects/libnsbmp/"
  url "https://download.netsurf-browser.org/libs/releases/libnsbmp-0.1.7-src.tar.gz"
  sha256 "5407a7682a122baaaa5a15b505290e2d37df54c13c5edef4b09d12c862d82293"
  license "MIT"

  livecheck do
    url :homepage
    regex(/href=.*?libnsbmp[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b152cc0287de901f6f5ff6e7eaed0f33796bc8c520905623facc06e744205bbd"
  end

  depends_on "netsurf-buildsystem" => :build

  def install
    args = %W[
      NSSHARED=#{Formula["netsurf-buildsystem"].opt_pkgshare}
      PREFIX=#{prefix}
    ]

    system "make", "install", "COMPONENT_TYPE=lib-shared", *args
    system "make", "install", "COMPONENT_TYPE=lib-static", *args

    # Also include an example, for use in test block
    inreplace "test/decode_bmp.c", "\"../include/libnsbmp.h\"", "<libnsbmp.h>"
    pkgshare.install "test/decode_ico.c"
  end

  test do
    system ENV.cc, pkgshare/"decode_ico.c", "-I#{include}", "-L#{lib}", "-lnsbmp", "-o", "decode_ico"

    expected_output = <<~EOS
      P7
      # #{test_fixtures("test.ico")}
      WIDTH 8
      HEIGHT 8
      DEPTH 4
      MAXVAL 255
      TUPLTYPE RGB_ALPHA
      ENDHDR
    EOS

    # Image is 8 x 8 = 64 px of pure blue, expressed as RGBA
    expected_output = expected_output.bytes + ([0, 0, 255, 255] * 64)
    assert_equal expected_output, shell_output("#{testpath}/decode_ico #{test_fixtures("test.ico")}").bytes
  end
end
