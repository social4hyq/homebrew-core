class Libvorbis < Formula
  desc "Vorbis general audio compression codec"
  homepage "https://xiph.org/vorbis/"
  url "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.xz"
  mirror "https://github.com/xiph/vorbis/releases/download/v1.3.7/libvorbis-1.3.7.tar.xz"
  sha256 "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://ftp.osuosl.org/pub/xiph/releases/vorbis/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)libvorbis[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c02ee51aeca2d0b7dded428ad9e4844cf49c97205c4c7de64aae1d219cfbe946"
  end

  head do
    url "https://gitlab.xiph.org/xiph/vorbis.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "libogg"

  resource("oggfile") do
    url "https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg"
    sha256 "f57b56d8aae4c847cf01224fb45293610d801cfdac43d932b5eeab1cd318182a"
  end

  def install
    system "./autogen.sh" if build.head?
    inreplace "configure", " -force_cpusubtype_ALL", ""
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <assert.h>
      #include "vorbis/vorbisfile.h"
      int main (void) {
        OggVorbis_File vf;
        assert (ov_open_callbacks (stdin, &vf, NULL, 0, OV_CALLBACKS_NOCLOSE) >= 0);
        vorbis_info *vi = ov_info (&vf, -1);
        printf("Bitstream is %d channel, %ldHz\\n", vi->channels, vi->rate);
        printf("Encoded by: %s\\n", ov_comment(&vf,-1)->vendor);
        return 0;
      }
    C
    testpath.install resource("oggfile")
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lvorbisfile",
                   "-o", "test"
    assert_match "2 channel, 44100Hz\nEncoded by: Lavf59.27.100",
                 shell_output("./test < Example.ogg")
  end
end
