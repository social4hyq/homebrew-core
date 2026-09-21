class Tkrzw < Formula
  desc "Set of implementations of DBM"
  homepage "https://dbmx.net/tkrzw/"
  url "https://dbmx.net/tkrzw/pkg/tkrzw-1.0.34.tar.gz"
  sha256 "afe894c1532feda086b7a94672f412f801758cbe81431fd3c88514fa27ebe369"
  license "Apache-2.0"

  livecheck do
    url "https://dbmx.net/tkrzw/pkg/"
    regex(/href=.*?tkrzw[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6caafc09d65c75b2c2b358fa9d0ce6fbef4c682cafe1777b8d3a4b119fd31052"
  end

  depends_on "lz4"
  depends_on "xz"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Don't add -lstdc++ to tkrzw_build_util and tkrzw.pc
    ENV["ac_cv_lib_stdcpp_main"] = "no" if ENV.compiler == :clang

    # zstd support is needed by dependents. Other features are for indirect dependencies.
    # Also force shim path for CC/CXX as configure seems to use a different PATH
    args = %W[
      --enable-lz4
      --enable-lzma
      --enable-zlib
      --enable-zstd
      CC=#{which(ENV.cc)}
      CXX=#{which(ENV.cxx)}
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "tkrzw_dbm_hash.h"
      int main(int argc, char** argv) {
        tkrzw::HashDBM dbm;
        dbm.Open("casket.tkh", true).OrDie();
        dbm.Set("hello", "world").OrDie();
        std::cout << dbm.GetSimple("hello") << std::endl;
        dbm.Close().OrDie();
        return 0;
      }
    CPP

    cflags = shell_output("#{bin}/tkrzw_build_util config -i").chomp.split
    ldflags = shell_output("#{bin}/tkrzw_build_util config -l").chomp.split
    ldflags.unshift "-L#{HOMEBREW_PREFIX}/lib"
    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test", *cflags, *ldflags
    assert_equal "world\n", shell_output("./test")
  end
end
