class Talloc < Formula
  desc "Hierarchical, reference-counted memory pool with destructors"
  homepage "https://talloc.samba.org/"
  url "https://www.samba.org/ftp/talloc/talloc-2.4.4.tar.gz"
  sha256 "55e47994018c13743485544e7206780ffbb3c8495e704a99636503e6e77abf59"
  license "GPL-3.0-or-later"
  compatibility_version 1

  livecheck do
    url "https://www.samba.org/ftp/talloc/"
    regex(/href=.*?talloc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "15765144fb4e122914a9a1a4b4841df722c2e177c7b47482597592875f02a9a8"
  end

  uses_from_macos "python" => :build

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-rpath",
                          "--without-gettext",
                          "--disable-python"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <talloc.h>
      int main()
      {
        int ret;
        TALLOC_CTX *tmp_ctx = talloc_new(NULL);
        if (tmp_ctx == NULL) {
          ret = 1;
          goto done;
        }
        ret = 0;
      done:
        talloc_free(tmp_ctx);
        return ret;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-ltalloc", "-o", "test"
    system testpath/"test"
  end
end
