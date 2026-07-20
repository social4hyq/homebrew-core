class Libgit2AT18 < Formula
  desc "C library of Git core methods that is re-entrant and linkable"
  homepage "https://libgit2.org/"
  url "https://github.com/libgit2/libgit2/archive/refs/tags/v1.8.6.tar.gz"
  sha256 "c171e9c6fcc33455e3df46d422f4e1b3ea7c049a645051664c9cdbdc081208e7"
  license "GPL-2.0-only" => { with: "GCC-exception-2.0" }

  livecheck do
    url :stable
    regex(/^v?(1\.8(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1078f4561e07bbbf91ce0a3e9494e1113c4c24cb9fa75d91b199a2a406efee69"
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libssh2"

  on_linux do
    depends_on "openssl@3" # Uses SecureTransport on macOS.
    depends_on "zlib-ng-compat"
  end

  def install
    args = %w[-DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DUSE_SSH=ON -DUSE_BUNDLED_ZLIB=OFF]

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
