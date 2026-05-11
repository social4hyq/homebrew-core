class Re2c < Formula
  desc "Generate C-based recognizers from regular expressions"
  homepage "https://re2c.org/"
  url "https://github.com/skvadrik/re2c/releases/download/4.5.1/re2c-4.5.1.tar.xz"
  sha256 "ffea067c11aa668bcb42885be6e6cd000302000b7747d2bb213299ec66b7864e"
  license :public_domain

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4231c4a6d277b6f1133d979be425bbce26698ed7b85ca7a26481664e87764c70"
  end

  uses_from_macos "python" => :build

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      unsigned int stou (const char * s)
      {
      #   define YYCTYPE char
          const YYCTYPE * YYCURSOR = s;
          unsigned int result = 0;

          for (;;)
          {
              /*!re2c
                  re2c:yyfill:enable = 0;

                  "\x00" { return result; }
                  [0-9]  { result = result * 10 + c; continue; }
              */
          }
      }
    C
    system bin/"re2c", "-is", testpath/"test.c"
  end
end
