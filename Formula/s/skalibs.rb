class Skalibs < Formula
  desc "Skarnet's library collection"
  homepage "https://skarnet.org/software/skalibs/"
  url "https://skarnet.org/software/skalibs/skalibs-2.15.1.0.tar.gz"
  sha256 "f9c905e74935c6fe911c7e344e3e89d5fbd2014c1a04650b524b15ce9b5635d1"
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
