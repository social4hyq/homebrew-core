class Liblo < Formula
  desc "Lightweight Open Sound Control implementation"
  homepage "https://liblo.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/liblo/liblo/0.36/liblo-0.36.tar.gz"
  sha256 "c08d14832e8dcf8f06840405824a4f9611a0cb3daed0198946326c740941c8b6"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7f79cabb86fc753656630caa6448e54372042bb37c301a052dd32369457cd3b5"
  end

  head do
    url "https://git.code.sf.net/p/liblo/git.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "doxygen" => :build

  def install
    if build.head?
      system "./autogen.sh", *std_configure_args
    else
      system "./configure", *std_configure_args
    end

    system "make", "install"
  end

  test do
    (testpath/"lo_version.c").write <<~C
      #include <stdio.h>
      #include "lo/lo.h"
      int main() {
        char version[6];
        lo_version(version, 6, 0, 0, 0, 0, 0, 0, 0);
        printf("%s", version);
        return 0;
      }
    C
    system ENV.cc, "lo_version.c", "-I#{include}", "-L#{lib}", "-llo", "-o", "lo_version"
    assert_equal version.to_str, shell_output("./lo_version")
  end
end
