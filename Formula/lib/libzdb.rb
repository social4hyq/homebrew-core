class Libzdb < Formula
  desc "Database connection pool library"
  homepage "https://tildeslash.com/libzdb/"
  url "https://tildeslash.com/libzdb/dist/libzdb-3.5.0.tar.gz"
  sha256 "90c79bf23b0c8fcb6543634844d17c094a24a360c9d63ddf6efc3741ebec32c5"
  license "GPL-3.0-only"

  livecheck do
    url :homepage
    regex(%r{href=.*?dist/libzdb[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79937c510f73d2c114c9145cf4ea41cdefd150fbc672f04d1715e9b52a4370a4"
  end

  depends_on "libpq"
  depends_on "mariadb-connector-c"
  depends_on "sqlite"

  def install
    system "./configure", "--disable-silent-rules", "--enable-protected", "--enable-sqliteunlock", *std_configure_args
    system "make", "install"
    (pkgshare/"test").install Dir["test/*.{c,cpp}"]
  end

  test do
    cp_r pkgshare/"test", testpath
    cd "test" do
      system ENV.cc, "select.c", "-L#{lib}", "-lpthread", "-lzdb", "-I#{include}/zdb", "-o", "select"
      system "./select"
    end
  end
end
