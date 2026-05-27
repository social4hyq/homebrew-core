class Ancient < Formula
  desc "Decompression routines for ancient formats"
  homepage "https://github.com/temisu/ancient"
  url "https://github.com/temisu/ancient/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "5d1d71f0fb8c69955bb4ec01ed9ffd2b5bf546b10463030dda85d949ea422bc9"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51dab0db0cc59130256f837a5cc0ffaf57ed8f11a80d5080d7fc3b11b42dc3c8"
  end

  depends_on "autoconf" => :build
  depends_on "autoconf-archive" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <ancient/ancient.hpp>

      int main(int argc, char **argv)
      {
        std::optional<ancient::Decompressor> decompressor;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp", "-I#{include}", "-L#{lib}", "-lancient", "-o", "test"
    system "./test"
  end
end
