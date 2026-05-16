class Skalibs < Formula
  desc "Skarnet's library collection"
  homepage "https://skarnet.org/software/skalibs/"
  url "https://skarnet.org/software/skalibs/skalibs-2.14.5.1.tar.gz"
  sha256 "fa359c70439b480400a0a2ef68026a2736b315025a9d95df69d34601fb938f0f"
  license "ISC"
  compatibility_version 1
  head "git://git.skarnet.org/skalibs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c1e39f034c43e0c021e74402bafd09eee5aa36dfeae8e18494e88898c72ba330"
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
