class Libgit2AT17 < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.org/"
  url "https://github.com/libgit2/libgit2/archive/refs/tags/v1.7.2.tar.gz"
  sha256 "de384e29d7efc9330c6cdb126ebf88342b5025d920dcb7c645defad85195ea7f"
  license "GPL-2.0-only" => { with: "GCC-exception-2.0" }
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b04bdde2a25d8a67489aa4395d5987cc2cd9c5663d863a2ac24dd13a0af159da"
  end

  keg_only :versioned_formula

  # https://github.com/libgit2/libgit2/?tab=security-ov-file
  deprecate! date: "2025-01-08", because: :unsupported
  disable! date: "2026-01-08", because: :unsupported

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libssh2"
  depends_on "openssl@3"

  def install
    args = %w[-DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON]

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install "build-static/libgit2.a"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <git2.h>
      #include <assert.h>

      int main(int argc, char *argv[]) {
        int options = git_libgit2_features();
        assert(options & GIT_FEATURE_SSH);
        return 0;
      }
    C
    libssh2 = Formula["libssh2"]
    flags = %W[
      -I#{include}
      -I#{libssh2.opt_include}
      -L#{lib}
      -lgit2
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
