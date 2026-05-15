class Tinycdb < Formula
  desc "Create and read constant databases"
  homepage "https://www.corpit.ru/mjt/tinycdb.html"
  url "https://www.corpit.ru/mjt/tinycdb/tinycdb-0.81.tar.gz"
  sha256 "469de2d445bf54880f652f4b6dc95c7cdf6f5502c35524a45b2122d70d47ebc2"
  license :public_domain
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?tinycdb[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fab9e7369e90296d903f48ff1e3688e2c1b699f6c4a09c6d55a47fb7d1d55d70"
  end

  def libcdb_soversion
    # This value is used only on macOS.
    # If the test block fails only on Linux, then this value likely needs updating.
    "1"
  end

  def install
    system "make"
    system "make", "install", "prefix=#{prefix}", "mandir=#{man}"

    shared_flags = ["prefix=#{prefix}"]
    shared_flags += if OS.mac?
      %W[
        SHAREDLIB=#{shared_library("$(LIBBASE)", libcdb_soversion)}
        SOLIB=#{shared_library("$(LIBBASE)")}
        LDFLAGS_SONAME=-Wl,-install_name,$(prefix)/
        LDFLAGS_VSCRIPT=
        LIBMAP=
      ]
    end.to_a

    system "make", *shared_flags, "shared"
    system "make", *shared_flags, "install-sharedlib"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <fcntl.h>
      #include <cdb.h>

      int main() {
        struct cdb_make cdbm;
        int fd;
        char *key = "test",
             *val = "homebrew";
        unsigned klen = 4,
                 vlen = 8;

        fd = open("#{testpath}/db", O_RDWR|O_CREAT);

        cdb_make_start(&cdbm, fd);
        cdb_make_add(&cdbm, key, klen, val, vlen);
        cdb_make_exists(&cdbm, key, klen);
        cdb_make_finish(&cdbm);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lcdb", "-o", "test"
    system "./test"
    return unless OS.linux?

    # Let's test whether our hard-coded `libcdb_soversion` is correct, since we don't override this on Linux.
    # If this test fails, the the value in the `libcdb_soversion` needs updating.
    versioned_libcdb_candidates = lib.glob(shared_library("libcdb", "*")).reject { |so| so.to_s.end_with?(".so") }
    assert_equal versioned_libcdb_candidates.count, 1, "expected only one versioned `libcdb`!"

    versioned_libcdb = versioned_libcdb_candidates.first.basename.to_s
    soversion = versioned_libcdb[/\.(\d+)$/, 1]
    assert_equal libcdb_soversion, soversion
  end
end
