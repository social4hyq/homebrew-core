class R3 < Formula
  desc "High-performance URL router library"
  homepage "https://github.com/c9s/r3"
  license "MIT"
  head "https://github.com/c9s/r3.git", branch: "master"

  stable do
    url "https://github.com/c9s/r3/archive/refs/tags/1.3.4.tar.gz"
    sha256 "db1fb91e51646e523e78b458643c0250231a2640488d5781109f95bd77c5eb82"

    # Backport of https://github.com/c9s/r3/commit/c105117b40d1a7b2b9ddf1672cd08b11bd565bd9
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/7ecb03ef6d73f3ed71546fb0c34023f9a23dbd74/Patches/r3/1.3.4.patch"
      sha256 "c00d9af0b30d94d918cf438834f2ca06e1f756ee56ed0205f9f6f82bf909cb0e"
    end
  end

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1cc59a5f591eb2fd4e062adb5b881551910873fcd7a91f69c7c18dc6762348c"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "jemalloc"
  depends_on "pcre2"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-silent-rules",
                          "--with-malloc=jemalloc",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "r3.h"
      int main() {
          node * n = r3_tree_create(1);
          r3_tree_free(n);
          return 0;
      }
    CPP
    system ENV.cc, "test.cpp", "-o", "test",
                  "-L#{lib}", "-lr3", "-I#{include}/r3"
    system "./test"
  end
end
