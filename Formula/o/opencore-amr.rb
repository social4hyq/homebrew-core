class OpencoreAmr < Formula
  desc "Audio codecs extracted from Android open source project"
  homepage "https://opencore-amr.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.6.tar.gz"
  sha256 "483eb4061088e2b34b358e47540b5d495a96cd468e361050fae615b1809dc4a1"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(%r{url=.*?/opencore-amr[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ae3573c19aee051ed47a6d74b4d93841c124dd3ca87e2f75373c376de85e25e"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <opencore-amrwb/dec_if.h>
      int main(void) {
        void *s = D_IF_init();
        D_IF_exit(s);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lopencore-amrwb", "-o", "test"
    system "./test"
  end
end
