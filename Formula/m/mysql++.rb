class Mysqlxx < Formula
  desc "C++ wrapper for MySQL's C API"
  homepage "https://tangentsoft.com/mysqlpp/home"
  url "https://tangentsoft.com/mysqlpp/releases/mysql++-3.3.0.tar.gz"
  sha256 "449cbc46556cc2cc9f9d6736904169a8df6415f6960528ee658998f96ca0e7cf"
  license "LGPL-2.1-or-later"
  revision 4

  livecheck do
    url "https://tangentsoft.com/mysqlpp/releases/"
    regex(/>mysql\+\+[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01d261c5a1c1a78609d50a60fba647f2f0bbc53d168837903b796c12e6464eff"
  end

  depends_on "mariadb-connector-c"

  def install
    mariadb = Formula["mariadb-connector-c"]
    system "./configure", "--with-field-limit=40",
                          "--with-mysql=#{mariadb.opt_prefix}",
                          *std_configure_args

    # Delete "version" file incorrectly included as C++20 <version> header
    # Issue ref: https://tangentsoft.com/mysqlpp/tktview/4ea874fe67e39eb13ed4b41df0c591d26ef0a26c
    # Remove when fixed upstream
    rm "version"

    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <mysql++/cmdline.h>
      int main(int argc, char *argv[]) {
        mysqlpp::examples::CommandLine cmdline(argc, argv);
        if (!cmdline) {
          return 1;
        }
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-I#{Formula["mariadb-connector-c"].opt_include}/mariadb",
                    "-L#{lib}", "-lmysqlpp", "-o", "test"
    system "./test", "-u", "foo", "-p", "bar"
  end
end
