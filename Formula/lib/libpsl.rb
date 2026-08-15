class Libpsl < Formula
  desc "C library for the Public Suffix List"
  homepage "https://rockdaboot.github.io/libpsl"
  url "https://github.com/rockdaboot/libpsl/releases/download/0.23.3/libpsl-0.23.3.tar.gz"
  sha256 "93941f85a1e7bd593fa94f299233cb5dfc91cd144fd9a78a6ceb75001c5b03be"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d4429eeccdb813ac9f580081c19f642ec598ee6cd3f0485ed801a7cffc4a525"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libidn2"
  depends_on "libunistring"

  def install
    system "meson", "setup", "build", "-Druntime=libidn2", "-Dbuiltin=true", *std_meson_args
    system "meson", "compile", "-C", "build"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <stdio.h>
      #include <string.h>

      #include <libpsl.h>

      int main(void)
      {
          const psl_ctx_t *psl = psl_builtin();

          const char *domain = ".eu";
          assert(psl_is_public_suffix(psl, domain));

          const char *host = "www.example.com";
          const char *expected_domain = "example.com";
          const char *actual_domain = psl_registrable_domain(psl, host);
          assert(strcmp(actual_domain, expected_domain) == 0);

          return 0;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{include}",
                   "-L#{lib}", "-lpsl"
    system "./test"
  end
end
