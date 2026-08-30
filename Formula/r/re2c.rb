class Re2c < Formula
  desc "Generate C-based recognizers from regular expressions"
  homepage "https://re2c.org/"
  url "https://github.com/skvadrik/re2c/releases/download/4.6/re2c-4.6.tar.xz"
  sha256 "75bf2696445e831d0d44e0d9f2909eeffc18c09757f222b2fb025f7e59fe130b"
  license :public_domain

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f734ab1c1fae6e83645ff63b375b971378abafd7c28e6e5ea097b2110dd45868"
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
