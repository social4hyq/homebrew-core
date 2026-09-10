class Libmagic < Formula
  desc "Implementation of the file(1) command"
  homepage "https://www.darwinsys.com/file/"
  url "https://astron.com/pub/file/file-5.48.tar.gz"
  sha256 "ed14656883b23a364b4057c05595d93252da9bc473d30106519519d0da141283"
  license all_of: ["BSD-2-Clause-Darwin", "BSD-2-Clause", :public_domain]
  revision 1
  compatibility_version 1

  livecheck do
    formula "file-formula"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8ed0d6bbc8d779b7d24ce63f0ada9b9f2ea6d1a841248e441529438fc03b4fe7"
  end

  depends_on "pkgconf" => :test

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--disable-silent-rules",
                          "--enable-fsect-man5",
                          "--enable-static",
                          *std_configure_args
    system "make", "install"
    (share/"misc/magic").install Dir["magic/Magdir/*"]

    # Don't dupe this system utility
    rm bin/"file"
    rm man1/"file.1"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <stdio.h>

      #include <magic.h>

      int main(int argc, char **argv) {
          magic_t cookie = magic_open(MAGIC_MIME_TYPE);
          assert(cookie != NULL);
          assert(magic_load(cookie, NULL) == 0);
          // Prints the MIME type of the file referenced by the first argument.
          puts(magic_file(cookie, argv[1]));
      }
    C
    flags = shell_output("pkgconf --cflags --libs #{name}").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    cp test_fixtures("test.png"), "test.png"
    assert_equal "image/png", shell_output("./test test.png").chomp
  end
end
