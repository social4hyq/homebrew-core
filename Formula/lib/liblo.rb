class Liblo < Formula
  desc "Lightweight Open Sound Control implementation"
  homepage "https://liblo.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/liblo/liblo/0.35/liblo-0.35.tar.gz"
  sha256 "9acc4f7e5a24f33472e9acd7e409b7bd6810a46f0a1f3cfeecea22d60f3aae13"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "64d5e03f690f0c0edef77e9ebdacbc245063b440612ccb33aad74a7bdc02541d"
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
