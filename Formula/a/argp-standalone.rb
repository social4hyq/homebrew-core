class ArgpStandalone < Formula
  desc "Standalone version of arguments parsing functions from GLIBC"
  homepage "https://github.com/argp-standalone/argp-standalone"
  url "https://github.com/argp-standalone/argp-standalone/archive/refs/tags/1.5.0.tar.gz"
  sha256 "c29eae929dfebd575c38174f2c8c315766092cec99a8f987569d0cad3c6d64f6"
  license all_of: [
    "LGPL-2.1-or-later",
    "LGPL-2.0-or-later", # argp.h, argp-parse.c
    :public_domain,      # mempcpy.c, strchrnul.c
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f33353a122ef2b7335708a79a0475fb4ef03d0451fa96f516a06225d373b8960"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <argp.h>

      int main(int argc, char ** argv)
      {
        return argp_parse(0, argc, argv, 0, 0, 0);
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-largp", "-lintl", "-o", "test"
    system "./test"
  end
end
