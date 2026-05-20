class Skalibs < Formula
  desc "Skarnet's library collection"
  homepage "https://skarnet.org/software/skalibs/"
  url "https://skarnet.org/software/skalibs/skalibs-2.15.0.0.tar.gz"
  sha256 "7fde96e8afb4191593a15328883e9c7726c96891cf071222146821e8c87f8007"
  license "ISC"
  compatibility_version 1
  head "git://git.skarnet.org/skalibs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fabbf70e55faf4aa144213384b4c7c7b6f099ce7f17aada31a79c1014f75d6b5"
  end

  def install
    args = %w[
      --disable-silent-rules
      --enable-shared
      --enable-pkgconfig
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <skalibs/skalibs.h>
      int main() {
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lskarnet", "-o", "test"
    system "./test"
  end
end
