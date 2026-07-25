class Libzdb < Formula
  desc "Database connection pool library"
  homepage "https://tildeslash.com/libzdb/"
  url "https://tildeslash.com/libzdb/dist/libzdb-3.6.0.tar.gz"
  sha256 "c29712aba58ce3c428e6fcf4c96f86c853dde5449da9adfaedbe69e6116e2e17"
  license "GPL-3.0-only"

  livecheck do
    url :homepage
    regex(%r{href=.*?dist/libzdb[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d17a80fba901b20be6f7b8c4576db305299de094916bad248a1143b0f5099e11"
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
