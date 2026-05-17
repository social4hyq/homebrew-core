class Libconfini < Formula
  desc "Yet another INI parser"
  homepage "https://madmurphy.github.io/libconfini/"
  url "https://github.com/madmurphy/libconfini/releases/download/1.16.4/libconfini-1.16.4-with-configure.tar.gz"
  sha256 "f4ba881e68d0d14f4f11f27c7dd9a9567c549f1bf155f4f8158119fb9bc9efd6"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ba69160fb6db73ca3332df722dabfa84aa11eda802fa39a461e8938201eaace"
  end

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    (testpath/"test.ini").write "[users]\nknown_users = alice, bob, carol\n"
    (testpath/"test.c").write <<~C
      #include <confini.h>

      static int callback (IniDispatch * disp, void * v_other) {
        #define IS_KEY(SECTION, KEY) \
          (ini_array_match(SECTION, disp->append_to, '.', disp->format) && \
          ini_string_match_ii(KEY, disp->data, disp->format))
        if (disp->type == INI_KEY) {
          if (IS_KEY("users", "known_users")) {
            printf("Known Users: %s\\n", disp->value);
          }
        }
        #undef IS_KEY
        return 0;
      }

      int main () {
        if (load_ini_path("test.ini", INI_DEFAULT_FORMAT, NULL, callback, NULL)) {
          fprintf(stderr, "Error while loading test.ini\\n");
          return 1;
        }
        return 0;
      }
    C

    system ENV.cc, testpath/"test.c", "-I#{include}", "-L#{lib}", "-lconfini", "-o", "test"
    assert_match "Known Users: alice, bob, carol", shell_output(testpath/"test").chomp
  end
end
